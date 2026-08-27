<%@page import="java.io.BufferedReader"%>
<%@page import="java.io.InputStream"%>
<%@page import="java.io.InputStreamReader"%>
<%@page import="java.io.OutputStream"%>
<%@page import="java.net.HttpURLConnection"%>
<%@page import="java.net.URL"%>
<%@page contentType="application/json" pageEncoding="UTF-8"%>
<%
    // Proxy local: Tomcat llama a la API para evitar el bloqueo CORS del navegador.
    String apiKey = request.getHeader("x-api-key");
    String difficulty = request.getParameter("difficulty");
    if (apiKey == null || apiKey.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"error\":\"Falta la API key\"}");
        return;
    }
    if (!"easy".equals(difficulty) && !"medium".equals(difficulty) && !"hard".equals(difficulty)) {
        difficulty = "medium";
    }

    HttpURLConnection connection = null;
    try {
        // URL canónica: sin "www" o con la barra final, el servicio responde 308.
        connection = (HttpURLConnection) new URL("https://www.youdosudoku.com/api").openConnection();
        connection.setRequestMethod("POST");
        connection.setConnectTimeout(10000);
        connection.setReadTimeout(15000);
        connection.setDoOutput(true);
        connection.setRequestProperty("Content-Type", "application/json");
        connection.setRequestProperty("Accept", "application/json");
        connection.setRequestProperty("x-api-key", apiKey.trim());

        String json = "{\"difficulty\":\"" + difficulty
                + "\",\"solution\":true,\"array\":true}";
        byte[] bytes = json.getBytes("UTF-8");
        connection.setFixedLengthStreamingMode(bytes.length);
        try (OutputStream stream = connection.getOutputStream()) {
            stream.write(bytes);
        }

        int status = connection.getResponseCode();
        response.setStatus(status);
        InputStream source = status >= 400 ? connection.getErrorStream() : connection.getInputStream();
        if (source == null) {
            out.print("{\"error\":\"La API no devolvió contenido\"}");
            return;
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(source, "UTF-8"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                out.print(line);
            }
        }
    } catch (Exception ex) {
        response.setStatus(502);
        out.print("{\"error\":\"No se pudo conectar con YouDoSudoku\"}");
    } finally {
        if (connection != null) connection.disconnect();
    }
%>
