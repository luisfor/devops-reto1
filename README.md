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

Este reto explora el despliegue del trabajo a través de arquitecturas multi-nodo, liberando de carga al nodo principal de Jenkins (*Master* o *Built-In Node*) al delegar las tareas pesadas a agentes adicionales configurados local y remotamente.

### 2.1 Configuración de Conexiones TCP y Creación del Agente
1. **Apertura de puerto TCP:** Por defecto, Jenkins cierra sus puertos para esclavos. Desde `Manage Jenkins > Security`, habilitamos un puerto fijo (`50000`) en la sección *TCP port for inbound agents*.
2. **Creación del Nodo (Agente):** En `Manage Jenkins > Nodes`, dimos de alta un nuevo "Permanent Agent" bautizado como `agente-mac`.
   *   Se le asignó el directorio remoto exclusivo: `/Users/luis/Desktop/DDEVOPS 2026/Git DevOps/jenkins-agente`.
   *   Se le asignó el label `agente-mac`.
   *   Se eligió la conexión *"Launch agent by connecting it to the controller"*.
3. **Lanzar el Agente:** Desde la terminal local en macOS, simulamos otra instancia descargando y ejecutando el agente oficial de Jenkins (`agent.jar`) con la clave secreta proporcionada para iniciar el hilo WebSocket:
   ```bash
   curl -sO http://localhost:8080/jnlpJars/agent.jar
   java -jar agent.jar -url http://localhost:8080/ -secret [CLAVE_SECRETA] -name "agente-mac" -webSocket -workDir "/Users/luis/Desktop/DDEVOPS 2026/Git DevOps/jenkins-agente"
   ```
   *(La conexión fue exitosa obteniendo un estado "INFO: Connected").*

### 2.2 Estrategia de Workspaces (stash y unstash)
Dado que los pipelines distribuidos no comparten disco duro o variables entre Nodos, el código del **Jenkinsfile** tuvo que reescribirse para dividir las responsabilidades y asegurar la persistencia de datos del proyecto (`helloworld`) de una computadora a otra.

*   **Etapa 1 (En el Nodo Master):** Se conecta a Github, descarga el proyecto y se utiliza el comando `stash` para comprimir/guardar toda la carpeta subiéndola virtualmente al gerente central de Jenkins.
*   **Etapa 2 (En el Agente Mac):** El agente recibe la confirmación de inicio, solicita los datos a Jenkins mediante el comando `unstash` para descargar el código, compilarlo y ejecutar todas nuestras pruebas de Pytest.

### 2.3 Variables de Entorno y Buenas Prácticas de Limpieza
Para evidenciar claramente en los logs cómo Jenkins salta entre el *Master* y el *Agente*, introducimos en ambas etapas del Pipeline los siguientes comandos exigidos:
```groovy
sh 'whoami'
sh 'hostname'
sh 'echo ${WORKSPACE}'
```
Esto garantizó que en los logs de Jenkins figurara en qué ubicación técnica (`Built-In node` vs `agente-mac`) y ruta física operaba cada etapa.

Finalmente, para evitar la saturación de archivos tras compilaciones largas (y como buena práctica DevOps prioritaria), agregamos la función `cleanWs()` al final de las etapas o dentro de la estrofa `post { always { } }`, garantizando una eliminación sistemática y recursiva del área de trabajo (workspace) una vez Jenkins finaliza sus pruebas en ese nodo.

**Resultado Final:** La consola de log del *Build* exhibió los saltos de Nodo y concluyó de manera magistral validando el desarrollo multi-agente (`Finished: SUCCESS`).
