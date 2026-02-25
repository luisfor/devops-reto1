# Caso Práctico 1: Reto 1 - Pipeline CI

Este documento detalla el paso a paso de la resolución del "Reto 1 - Pipeline CI", desde la instalación de los prerrequisitos en macOS hasta la ejecución exitosa de un Pipeline automatizado en Jenkins.

---

## 🚀 1. Instalación de Prerrequisitos en macOS

Antes de comenzar a trabajar con el código, fue necesario preparar el entorno local instalando las herramientas solicitadas por la guía del caso práctico.

### 1.1 Verificación e Instalación de Python y Java
Primero, comprobamos la existencia de Java y Python:
- **Java (JDK):** Verificamos con `java -version`. Nuestro sistema cuenta con *OpenJDK 21.0.7 LTS*.
- **Python:** Verificamos con `python3 --version`. Se cuenta con *Python 3.14.2*.

### 1.2 Instalación de Dependencias (pytest y flask)
Usando el manejador de paquetes de Python (`pip`), instalamos globalmente los módulos necesarios para ejecutar las pruebas.
Dado el control de entornos en macOS modernos, utilizamos la bandera `--break-system-packages`:
```bash
python3 -m pip install --break-system-packages pytest flask
```

### 1.3 Instalación y Ejecución de Jenkins
Instalamos Jenkins utilizando el gestor de paquetes Homebrew y lo iniciamos como servicio de fondo:
```bash
brew install jenkins-lts
brew services start jenkins-lts
```
Una vez iniciado, Jenkins es accesible en `http://localhost:8080`.

### 1.4 Descarga de Wiremock
Wiremock se utilizará como contenedor para simular respuestas de servicios externos. Descargamos la versión estable más reciente y compatible:
```bash
curl -sSL -o wiremock-standalone-3.12.0.jar https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.12.0/wiremock-standalone-3.12.0.jar
```

---

## ⚙️ 2. Preparación del Repositorio y Entorno Local

### 2.1 Configuración del Mocking (Wiremock Mappings)
De acuerdo a las instrucciones, la aplicación buscará acceder a la ruta `/calc/sqrt/64`. Para "engañar" a las pruebas, creamos una respuesta automatizada:
1. Creamos la carpeta `test/wiremock` y dentro la carpeta `mappings`.
2. Creamos el archivo `test/wiremock/mappings/sqrt64.json` con el siguiente contenido:
```json
{
    "request": {
        "method": "GET",
        "url": "/calc/sqrt/64"
    },
    "response": {
        "status": 200,
        "body": "8",
        "headers": {
            "Content-Type": "text/plain",
            "Access-Control-Allow-Origin": "*"
        }
    }
}
```

### 2.2 Clonación y Enlace con Repositorio Propio
A continuación, vinculamos el código fuente inicial (proporcionado por el profesor) a nuestro propio repositorio en la nube de GitHub.

1. Clonamos el repositorio original en local:
   ```bash
   git clone https://github.com/anieto-unir/helloworld.git
   cd helloworld
   ```
2. Desvinculamos nuestra carpeta del proyecto del profesor:
   ```bash
   git remote remove origin
   ```
3. Creamos un nuevo repositorio vacío en nuestra cuenta de Github (`https://github.com/luisfor/devops-reto1.git`).
4. Vinculamos la carpeta local a nuestro nuevo origen y subimos (`push`) los archivos a la rama principal (`master`):
   ```bash
   git remote add origin https://github.com/luisfor/devops-reto1.git
   git push -u origin master
   ```

---

## 🧪 3. Ejecución Manual de Pruebas Unitarias y de Integración

Antes de automatizar, validamos que el código funciona y que el entorno responde correctamente.

### 3.1 Ajustes para macOS
El puerto `5000` predeterminado de Flask presentaba conflictos con servicios nativos de Mac (AirPlay Receiver). Modificamos el archivo `test/rest/api_test.py` cambiando la URL base a `5001`:
```python
BASE_URL = "http://localhost:5001"
# ... resto del archivo
```

### 3.2 Script de Pruebas Locales (run_tests.sh)
Creamos un script bash ejecutable en la raíz del proyecto llamado `run_tests.sh` para arrancar Wiremock, iniciar Flask en el puerto `5001`, correr `pytest`, y luego cerrar los servicios de manera ordenada.

Lanzamos el script desde la terminal:
```bash
# Otorgamos permisos de ejecución primero si es necesario
bash run_tests.sh
```

**Resultado Esperado:** 12 pruebas completadas con éxito, mostradas en la pantalla con el texto en verde (12 passed).

---

## 🦊 4. Configuración del Pipeline Automatizado en Jenkins

Con las pruebas locales funcionando, el siguiente objetivo principal era conectar GitHub con Jenkins para automatizar todo este flujo.

### 4.1 Configuración Inicial de Jenkins ("Jenkins 1" y "Jenkins 2")
1. Accedimos al panel de Jenkins (`http://localhost:8080`).
2. Introdujimos la Password de Administrador inicial extraída de `/Users/luis/.jenkins/secrets/initialAdminPassword`.
3. Seleccionamos **"Install suggested plugins"** (Instalar complementos sugeridos), lo que integró herramientas fundamentales como la conectividad con Git y Github.
4. Creamos por nuestra cuenta un primer proyecto de prueba "Freestyle" donde construimos y echamos a correr un sencillo comando *Execute Shell* confirmando el manejo básico operativo de la interfaz.

### 4.2 Automatización Total con Jenkinsfile (El Pipeline Final)
Al repositorio original le faltaba la instrucción principal (el `Jenkinsfile`). Nosotros redactamos, integramos en el repositorio de Github, y configuramos desde Jenkins la automatización completa:

1. **El Jenkinsfile**: Creamos un archivo llamado `Jenkinsfile` en el root del proyecto.
   ```groovy
   pipeline {
       agent any
       stages {
           stage('Checkout Repo') {
               steps {
                   checkout scm
               }
           }
           stage('Run Tests (Flask & Wiremock)') {
               steps {
                   sh 'bash run_tests.sh'
               }
           }
       }
   }
   ```
2. Hicimos `git add`, `git commit` y `git push` para subir este archivo y el de `run_tests.sh` a Github.
3. **Jenkins**: En el panel, creamos un nuevo proyecto eligiendo el tipo **"Pipeline"**.
4. En la configuración de ese Pipeline fuimos a la sección inferior (Definition) y seleccionamos **Pipeline script from SCM**.
5. Colocamos nuestro repositorio: `https://github.com/luisfor/devops-reto1.git`.
6. Arreglamos el campo "Branches to build" cambiándolo para que apuntara a `*/master` (y no a `main`).
7. Guardamos y presionamos **Build Now**.

**Nota sobre la ruta en Mac (PATH):** Hubo un error inicial en Jenkins debido a que leía la instancia genérica de Python del sistema y no la versión de Homebrew donde estaba instalado *pytest*. Se solventó agregando `export PATH="/opt/homebrew/bin:$PATH"` dentro de nuestro `run_tests.sh`.

### 🏆 Resultado de Satisfacción
Al concluir todos los pasos, la ejecución del Pipeline en Jenkins muestra una consola limpia pasando satisfactoriamente todas las directivas de pruebas del script, arrojando el anhelado título final:
`Finished: SUCCESS`.


---

## 🌐 Reto 2: Distribución de Agentes y Roles

El objetivo principal del Reto 2 consistió en implementar una arquitectura distribuida (Master-Agent) dentro de Jenkins para no sobrecargar el nodo principal. 

Para lograrlo, creamos un nuevo Agente local en el entorno de la Mac. Configuramos el Pipeline automatizado (`Jenkinsfile`) de manera inteligente usando `stash` y `unstash` para trasladar el código fuente entre el *Gerente* (Master) y el *Empleado* (Agente), y comprobamos las ejecuciones verificando las variables de entorno.

### 2.1 Habilitar Conexiones TCP en el Servidor Master
Para que un Agente externo pueda conversar con Jenkins, se requiere abrir un puerto de red.
1. Ingresamos a la interfaz de Jenkins: `http://localhost:8080/`
2. Navegamos a **Manage Jenkins > Security**.
3. En la sección "Agents", configuramos el apartado **TCP port for inbound agents** seleccionando la opción **"Fixed"** y estableciendo el puerto a `50000`.
4. Guardamos los cambios. Esto habilitó la puerta de entrada para nuestro futuro esclavo.

### 2.2 Alta del Nuevo Agente en Jenkins
Necesitábamos indicarle al Master que habría un nuevo computador disponible.
1. Navegamos a **Manage Jenkins > Nodes**.
2. Hicimos clic en el botón azul **"+ New Node"**.
3. Nombramos nuestro nodo como `agente-mac` y seleccionamos el tipo **Permanent Agent**.
4. En el formulario de configuración llenamos los siguientes datos clave:
   *   **Number of executors:** `1` (una tarea concurrente a la vez).
   *   **Remote root directory:** Le asignamos explícitamente la carpeta que creamos en nuestro escritorio de trabajo: `/Users/luis/Desktop/DDEVOPS 2026/Git DevOps/jenkins-agente`. (Es vital que esta carpeta física exista antes de encender el agente).
   *   **Labels:** `agente-mac` (Esta etiqueta será utilizada en el Pipeline de Groovy para llamarlo).
   *   **Launch method:** Elegimos la opción *"Launch agent by connecting it to the controller"*.
5. Guardamos la configuración. Al volver a la lista de Nodos, apareció con una "X" roja indicando que estaba "Offline".

### 2.3 Conexión y Ejecución del Agente mediante Terminal
Al dar clic sobre el nuevo `agente-mac` (marcado en rojo), Jenkins nos proporciona la clave secreta generada encriptada y el comando exacto en Java (`agent.jar`) para iniciar la comunicación.

1. Abrimos una nueva ventana permanente en la **Terminal** de macOS.
2. Navegamos al directorio raíz de nuestro curso local:
   ```bash
   cd "/Users/luis/Desktop/DDEVOPS 2026/Git DevOps/jenkins-agente"
   ```
3. Ejecutamos el primer bloque para descargar la vestimenta oficial del agente:
   ```bash
   curl -sO http://localhost:8080/jnlpJars/agent.jar
   ```
4. Ejecutamos el comando principal de conexión (copiado de la interfaz):
   ```bash
   java -jar agent.jar -url http://localhost:8080/ -secret 9b7bde0cd5ebe32b5aca5aa3afbc6b7d47771cc405044911ff164cb7fde46c85 -name "agente-mac" -webSocket -workDir "/Users/luis/Desktop/DDEVOPS 2026/Git DevOps/jenkins-agente"
   ```
5. Tras unos segundos, la terminal nos devolvió el texto **"INFO: Connected"**. Al refrescar la interfaz gráfica de Jenkins, la "X" roja desapareció, confirmando que nuestro nodo `agente-mac` estaba online y sincronizado de manera óptima.

### 2.4 Reescritura del Jenkinsfile (Pipeline Multi-Agente)
Dado que un Agente no puede leer físicamente el disco duro del Master (Workspace), no sirven las clonaciones simples. Modificamos todo nuestro archivo `Jenkinsfile` de Github para organizar la coreografía requerida por el Reto 2:

```groovy
pipeline {
    // Desactivamos el agente global por defecto
    agent none 

    stages {
        // ETAPA 1: Liderada por el Master
        stage('Checkout Repo (En el Master)') {
            agent { label 'built-in' }
            steps {
                echo "=== INFORMACIÓN DEL NODO MASTER ==="
                sh 'whoami'
                sh 'hostname'
                sh 'echo ${WORKSPACE}'

                // 1. Clonar el repositorio Github original
                checkout scm

                // 2. Empaquetar todo el código recién descargado creando un STASH temporal
                stash includes: '**', name: 'codigo-fuente'
                
                // 3. Limpiar la carpeta (workspace) del master para preservar almacenamiento  
                cleanWs()
            }
        }
        
        // ETAPA 2: Liderada por el Agente
        stage('Run Tests (En el Agente Mac)') {
            agent { label 'agente-mac' }
            steps {
                echo "=== INFORMACIÓN DEL NODO AGENTE ==="
                sh 'whoami'
                sh 'hostname'
                sh 'echo ${WORKSPACE}'

                // 1. Jenkins le envía nuestro stash (el zip), el agente lo abre localmente
                unstash 'codigo-fuente'

                // 2. Le damos permisos y corremos el test con éxito.
                sh 'chmod +x run_tests.sh'
                sh 'bash run_tests.sh'
            }
            post {
                always {
                    // 3. Pase lo que pase, borrar todos los archivos resultantes al terminar.
                    cleanWs()
                }
            }
        }
    }
}
```

### 2.5 Ejecución Final y Buenas Prácticas Ocultas
Una vez redactado el código, fuimos a nuestra interfaz gráfica "Jenkins 1" y presionamos **Build Now**. La ejecución del Pipeline evidenció exitosamente que:
1. Las etapas saltaron entre computadoras ("Running on Jenkins / built-in" y luego "Running on agente-mac").
2. Las variables locales ejecutadas por consola (`whoami`, `hostname`, y mostrar la carpeta oculta `${WORKSPACE}`) confirmaron visualmente que mientras el primer proceso se corrió en un directorio `.jenkins` profundo interno, el segundo proceso mutó hacia la ruta del escritorio que construimos al vuelo en VS Code.
3. Comodidad Visual en IDE: Se creó de manera preventiva un nivel superior de control (`.gitignore`) que bloqueó para siempre de nuestro VS Code la saturación visual resultante de los `agent.jar` instalados por el TCP Local, garantizando la higiene en repositorios serios de código fuente.
4. Y con un sublime texto verde final de **`Finished: SUCCESS`** cerramos majestuosamente la automatización distribuida de laboratorios.
