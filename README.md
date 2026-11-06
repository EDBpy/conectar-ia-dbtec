# Conectar tu IA a la base dbtec

Si sos una persona: no hace falta que leas esto. Copiá el link de esta página, pegáselo a tu IA (Claude Code, Claude Desktop o Codex) junto con los datos de conexión que te llegaron por correo, y pedile que te conecte.

Lo que sigue son las instrucciones para la IA.

## Para la IA: cómo trabajar

- Objetivo: instalar en esta PC con Windows el conector MCP `dbtec` (DBHub 1.5.0), con acceso de **solo lectura** a la base PostgreSQL de la empresa.
- Los datos de conexión (servidor, base, usuario y clave) **no están en esta página**: te los da el usuario. Si te falta alguno, pedíselo. No repitas la clave en tus respuestas ni la guardes en otro lugar que no sea el archivo `.env`.
- Si podés ejecutar comandos en esta PC (Claude Code, Codex), hacé vos los pasos y pedí permiso solo cuando haga falta. Al terminar cada paso, un resumen corto.
- Si no podés ejecutar comandos (Claude Desktop, un chat), guiá al usuario **un paso a la vez**: qué abrir, qué copiar y dónde pegarlo, y esperá su respuesta antes de seguir. El usuario no es técnico.
- `dbhub.toml` y `mcp_dbhub.bat` se descargan de este repositorio sin cambiarlos. El único archivo que se escribe es `.env`, en UTF-8 sin BOM.
- Si un paso falla, usá [Problemas frecuentes](#problemas-frecuentes).

## Paso 1. Comprobar la red

En PowerShell:

```
Test-NetConnection SERVIDOR -Port 5432
```

`SERVIDOR` es la dirección del servidor que dio el usuario. Tiene que decir `TcpTestSucceeded : True`. Si dice `False`, detenerse: la PC no está en la red de la oficina o la VPN está apagada. Sin eso no funciona.

## Paso 2. Node.js 20 o superior

En PowerShell: `node --version`. Si no existe o es menor a `v20`:

```
winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
```

Si winget no está, descargar el instalador LTS de https://nodejs.org. Después cerrar y volver a abrir PowerShell.

## Paso 3. Carpeta e instalación de DBHub

```
New-Item -ItemType Directory -Force C:\DBTEC-MCP
cd C:\DBTEC-MCP
npm install @bytebase/dbhub@1.5.0
```

Si `C:\DBTEC-MCP` ya existe de una instalación anterior, igual hacer el paso 4: así se actualiza la configuración.

## Paso 4. Descargar la configuración y crear el `.env`

Descargar los dos archivos de este repositorio tal cual (no copiarlos a mano):

```
cd C:\DBTEC-MCP
Invoke-WebRequest https://raw.githubusercontent.com/EDBpy/conectar-ia-dbtec/main/dbhub.toml -OutFile dbhub.toml
Invoke-WebRequest https://raw.githubusercontent.com/EDBpy/conectar-ia-dbtec/main/mcp_dbhub.bat -OutFile mcp_dbhub.bat
```

Crear `C:\DBTEC-MCP\.env` con este contenido, reemplazando las cuatro palabras en mayúsculas por los datos que dio el usuario:

```
PG_HOST=SERVIDOR
PG_DB=BASE
MCP_USER=USUARIO
MCP_PASSWORD=CLAVE
```

Desde PowerShell se puede crear así (UTF-8 sin BOM):

```
$servidor = 'SERVIDOR'; $base = 'BASE'; $usuario = 'USUARIO'; $clave = 'CLAVE'
[IO.File]::WriteAllText('C:\DBTEC-MCP\.env', "PG_HOST=$servidor`nPG_DB=$base`nMCP_USER=$usuario`nMCP_PASSWORD=$clave`n")
```

Al final, `C:\DBTEC-MCP` tiene que tener: `node_modules`, `dbhub.toml`, `mcp_dbhub.bat` y `.env`.

## Paso 5. Registrar el conector en la IA

En cada una de estas que esté instalada en la PC.

**Claude Code.** En una terminal (el primer comando puede dar error si no existía; es normal):

```
claude mcp remove dbtec --scope user
claude mcp add dbtec --scope user -- cmd /c C:\DBTEC-MCP\mcp_dbhub.bat
```

Comprobar con `claude mcp list`.

**Claude Desktop.** Abrir Configuración > Desarrollador > Editar configuración. Eso abre la carpeta de `claude_desktop_config.json` (está en `%APPDATA%\Claude\` o en `%LOCALAPPDATA%\Packages\Claude_...\LocalCache\Roaming\Claude\`). Dentro de `mcpServers` tiene que quedar el bloque `dbtec`, sin borrar otros conectores ni opciones. Si el archivo está vacío o no existe, queda así:

```json
{
  "mcpServers": {
    "dbtec": {
      "command": "cmd",
      "args": ["/c", "C:\\DBTEC-MCP\\mcp_dbhub.bat"]
    }
  }
}
```

Después cerrar Claude Desktop por completo (también desde el ícono junto al reloj) y abrirlo.

**Codex (ChatGPT).** Agregar al final de `%USERPROFILE%\.codex\config.toml`, si no está ya:

```toml
[mcp_servers.dbtec]
command = "cmd"
args = ["/c", "C:\\DBTEC-MCP\\mcp_dbhub.bat"]
```

Después cerrar y volver a abrir Codex.

## Paso 6. Probar

Avisar al usuario antes de pedirle que reinicie la IA, porque la conversación se corta. Después, en una conversación nueva, preguntar: **¿Hasta qué fecha llegan los datos de dbtec?** Tiene que usar la herramienta `estado_replica` y responder con la fecha de la última carga de cada base (normalmente la madrugada de hoy). Si responde eso, la instalación terminó.

## Problemas frecuentes

| Síntoma | Causa y solución |
| --- | --- |
| `dbtec` no aparece en Claude Desktop | Error en el JSON (falta una coma o una comilla) o Claude no se cerró del todo. |
| `dbtec` aparece con error | Ejecutar `C:\DBTEC-MCP\mcp_dbhub.bat` en PowerShell para ver el mensaje. Si no encuentra `node`, reiniciar la PC. |
| `timeout` o `connection refused` | La PC no está en la red de la oficina: repetir el paso 1. |
| `password authentication failed` | El usuario o la clave del `.env` quedaron mal (sin espacios ni comillas) o el archivo quedó como `.env.txt`. |
| `no pg_hba.conf entry` | La PC está en una red que el servidor no tiene habilitada. Avisar a quien mandó el correo. |
| Error al leer `dbhub.toml` o `.env` | Volver a descargar `dbhub.toml` (paso 4). El `.env` tiene que estar en UTF-8 sin BOM. |

## Uso, una vez instalado

- Llamar primero a `guia_datos` con las palabras de la pregunta: dice qué vista usar y sus cuidados.
- Límites por consulta: 90 segundos y 1.500 filas.
- No están en la base: sueldos ni datos de personal. En EDB y CASA tampoco pagos, bancos ni asientos.
