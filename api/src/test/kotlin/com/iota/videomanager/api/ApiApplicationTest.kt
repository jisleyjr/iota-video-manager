package com.iota.videomanager.api

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.springframework.boot.builder.SpringApplicationBuilder
import org.springframework.boot.web.server.context.WebServerApplicationContext
import org.springframework.jdbc.core.JdbcTemplate
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import org.testcontainers.mysql.MySQLContainer
import tools.jackson.databind.json.JsonMapper
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

@Testcontainers
class ApiApplicationTest {
    companion object {
        @Container
        @JvmStatic
        val mysql = MySQLContainer("mysql:8.4")
            .withDatabaseName("iota_video_manager")
            .withUsername("iota")
            .withPassword("test-password")
    }

    private val client = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(5))
        .build()
    private val json = JsonMapper.builder().build()

    @Test
    fun `foundation restarts with the same schema and reports database outages`() {
        repeat(2) { startup ->
            SpringApplicationBuilder(ApiApplication::class.java).run(
                "--server.port=0",
                "--spring.datasource.url=${mysql.jdbcUrl}",
                "--spring.datasource.username=${mysql.username}",
                "--spring.datasource.password=${mysql.password}",
                "--spring.datasource.hikari.connection-timeout=1000",
                "--spring.datasource.hikari.validation-timeout=1000",
            ).use { context ->
                val port = requireNotNull((context as WebServerApplicationContext).webServer).port
                val jdbc = context.getBean(JdbcTemplate::class.java)
                val tables = jdbc.queryForList(
                    "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()",
                    String::class.java,
                )
                assertThat(tables).containsExactlyInAnyOrder("DATABASECHANGELOG", "DATABASECHANGELOGLOCK")
                assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM DATABASECHANGELOG", Long::class.java))
                    .isZero()

                assertHealth(port, "", 200, "UP")
                assertHealth(port, "/liveness", 200, "UP")
                assertHealth(port, "/readiness", 200, "UP")
                assertThat(get(port, "/actuator/env").statusCode()).isEqualTo(404)
                assertThat(get(port, "/api/youtube/videos").statusCode()).isEqualTo(404)

                if (startup == 1) {
                    mysql.stop()
                    assertHealth(port, "/readiness", 503, "DOWN")
                    assertHealth(port, "/liveness", 200, "UP")
                }
            }
        }
    }

    private fun assertHealth(port: Int, path: String, statusCode: Int, status: String) {
        val response = get(port, "/actuator/health$path")
        assertThat(response.statusCode()).isEqualTo(statusCode)
        val expected = if (path.isEmpty()) {
            "{\"status\":\"$status\",\"groups\":[\"liveness\",\"readiness\"]}"
        } else {
            "{\"status\":\"$status\"}"
        }
        assertThat(json.readTree(response.body())).isEqualTo(json.readTree(expected))
    }

    private fun get(port: Int, path: String): HttpResponse<String> = client.send(
        HttpRequest.newBuilder(URI("http://localhost:$port$path"))
            .timeout(Duration.ofSeconds(15))
            .GET()
            .build(),
        HttpResponse.BodyHandlers.ofString(),
    )
}
