
Conclusión
=============

Habiendo llegado al final del periodo de desarrollo para este projecto, es necesario revisar el resultado y compararlo con los objetivos propuestos. 

Este capítulo explica las principales dificultades encontradas a la hora de implementar Naylang, una revisión de qué objetivos fueron cumplidos (y cuales no), y un breve sumario de las posibles vías de trabajo futuro.

Desafíos
--------

Esta sección detalla los principales obstáculos para el desarrollo de Naylang. Afortunadamente, muchos de estos obstáculos fueron superados, y sirvieron como experiencias de aprendizaje.

### C++ Moderno

El lenguaje elegido para este proyecto fue la última versión estable de C++ (C++14). Habiendo trabajado extensamente con otras versiones de C++, la elección de lenguaje parecía ser la mejor. Sin embargo, las nuevas versiones de C++ resultaron ser substancialmente diferentes a las anteriores, con una miríada de nuevas funcionalidades vitales para el correcto uso de éstas. Esto introdujo un alto grado de dificultad adicional al desarrollo del proyecto, ya que las neuvas funcionalidades debían ser estudiadas **al mismo tiempo** que se desarrollaba el proyecto. Esto resultó en grandes partes del código teniendo que ser reescritas más de una vez, a medida que se descubrían nuevas y mejores formas de aproximar un problema.

Como resultado, más de la mitad del tiempo de depuración de este proyecto se usó intentando integrar estas nuevas funcionalidades, en lugar de arreglando fallos del Naylang.

### Representación Abstracta

La especificación de Grace ofrece información limitada sobre el comportamiento deseado de ciertas operaciones (como la asignación, especialmente en lo que respecta a su estructura y representación abstracta. Siendo éste el caso, el diseño del Arbol de Sintaxis Abstracta requirió muchas iteraciones y un alto grado de interpretación de la especificación.

Por ejemplo, una de las primeras aproximaciones fué introducir operadores lógicos y aritméticos explícitamente en la sintaxis abstracta, lo que se tuvo que descartar más adelante cuando se descubrió el modelo de ejecución basado en _requests_.

Estas iteraciones sobre la representación abstracta probaron ser sencillas pero muy costosas en tiempo de desarrollo, dado que modificar el banco de tests y el código principal son operaciones extremadamente tediosas.

### Modelo de Dispatch y Requests

Este problema está atado al anterior en tanto en cuanto a que resulta de las particularidades de Grace. Dado que los métodos son una parte integral de los objectos en Grace y pueden contener tanto código arbitrario o funcionalidad predefinida, el modelo de ejecución y dispatch presentó un gran desafío. De hecho, la funcionalidad de dispatch y ejecución de métodos está repartida en al menos tres subsistemas.

### Depurador Desacoplado

El problema de integrar la depuración en Naylang _sin modificar_ el motor básico de evaluación llevó a cierto grado de investigación y, finalmente, al desarrollo del Patrón del Visitante Modular descrito anteriormente.

Revisión de Objetivos
---------

Esta sección incluye una evaluación de los objetivos impuestos en la introducción, detallando cuáles han sido conseguidos y cuáles no.

### Objetivos de Implementación

Naylang tenía la intención de ser un intérprete y depurador para un _subconjunto_ de Grace, suficientemente extenso como para pode enseñar los conceptos básicos de la Informática a estudiantes totalmente nuevos en la materia. 

Mientras que es, de hecho, un _depurador muy potente_ e implementa un subconjunto sustancial de Grace, muchas de las características importantes del lenguaje fueron dejadas a un lado, lo que limita lo que un estudiante puede aprender con Naylang.

Sin embargo, al no incluir estas funciones directamente en el núcleo de evaluación, surge la posibilidad de **usar Naylang como proyecto de investigación** para estudiar la viabilidad del Patrón del Visitante Modular, usándolo para implementar estas nuevas características.

### Objetivos de Educación

El segundo objetivo vital de Naylang era ser **amigable** para cualquier estudiante interesado en aprender sobre implementación de lenguajes, or cualquier futuro contribuyente al proyecto. En este aspecto Naylang ha sido un éxito, ya que cuenta con una extensa cobertura de tests, lo que proporciona cientos de casos de uso y una gran modularidad en sus componentes.

Trabajo Futuro
--------

Aunque el trabajo realizado en Naylang sea razonablemente satisfactorio, aún hay muchas áreas que podrían beneficiarse de trabajo futuro. Completar estas tareas podría hacer de Naylang un herramienta increíblemente útil para la educación en Informática.

### Visitante Modular

El Patrón del Visitante Modular es probablemente el área que merece mayor atención en futuros desarrollos, dado que demuestra el potencial de introducir una **inmensa flexibilidad** en el desarrollo de intérpretes para nuevos lenguajes, e incluso nuevos lenguajes. Si se cumpliese el potencial que promete, incluso el desarrollo de lenguajes "a la carta" se convertiría en un trabajo mucho más sencillo, llevado a cabo por la recombinación de módulos funcionales desarrollados de forma independiente.

### Funciones del Lenguaje

Muchas de las características de Grace fueron dejadas a parte en Naylang. Mientras que Naylang ya _no pretenderá_ implementar todas estas características, puede y deberá implementar algunas de las áreas más necesarias para la educaión, como el sistema de clases y tipos.

Estas implementaciones estárian conducidas por la exploración del patrón anteriormente mencionado, y deberán ser implementadas como módulos de evaúación separados.

### Frontend Web

Una de las fallas en el uso de Naylang en un entorno educativo es la **distribución de binarios** para los ejecutables a los usuarios finales. Para programadores novatos, la instalación y la interfaz podrían resultar poco amigables en un principio.

La solución perfecta a este problema sería descartar el modelo de ejecución local, y tener una interfaz basada en web para interactuar con Naylang desde cualquier navegador. Aunque cierto trabajo ha sido realizado con resultados prometedores, el desarrollos de esta interfaz fué descartado del proyecto por razones de tiempo.