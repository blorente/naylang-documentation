
Introducción
=========

Naylang es un intérprete REPL, entorno de ejecución y depurador para el lenguaje de programación Grace, implementado totalmente en C++14.

Actualmente, implementa un subconjunto de Grace (descrito a continuación), pero a medida que el proyecto evolucione tenderá hacia una mayor compatibilidad con el lenguaje.

Motivación
-------

Grace es un lenguaje diseñado para ayudar a nuevos estudiantes a adquirir los conceptos fundamentales de la programación. Como tal, provee de seguridad y flexibilidad en su diseño.

Sin embargo, el coste de esta flexibilidad es que muchas de las actuales implemetaciones de Grace son opacas y difíciles de abordar. Grace es un lenguaje abierto, y por lo tanto sus implementaciones también son abiertas. Esta falta de claridad en la implementación hace que la apertura de su código se devalúe ya que, aunque las posibles entidades contribuyentes tengan acceso al código fuente, éste es difícil de entender y por supuesto de modificar, dañando severamente las oportunidades de crecimiento y expansión del lenguaje.

Objetivos
------

Naylang tiene como primer objectivo servir como ejercicio en la construcción de intérpretes de lenguajes, tanto para los creadores, como para cualquier futuro contribuyente al código. Como consecuencia, el proyecto presenta los siguientes objetivos primordiales:

- Proveer una implementación **sólida** de un **subconjunto relevante** de Grace.
- Ser tan **amigable** como sea posible para los **usuarios finales** (estudiantes de programación) y para posibles futuras **contribuciones**.
- Ser en sí misma una **herramienta** para **aprender sobre la implementación** de lenguajes tan flexibles como Grace.

Metodología
-------

El proyecto se rige por la disciplina del Desarrollo Basado en Tests (TDD), por la cual tests unitarios se escriben en paralelo al código (muchas veces antes que éste), en iteraciones muy cortas. Se ha elegido este modelo de desarrollo por varias razones:

En primer lugar, contar con una cobertura extensa de tests provee una forma fácil y automática de verificar qué partes del proyecto están funcionando como deberían. Por lo tanto, nuevos contribuyentes al proyecto sabrán con exactitud qué subsistemas afectan los cambios que hagan y de qué forma, lo que  permitirá hacer cambios con mayor rapidez y seguridad.

En segundo lugar, los tests unitarios en sí mismos sirven también como _documentación_ del proyecto, dado que proveen **ejemplos funcionales** del uso de cada parte del código. Esto resulta en una facilidad mucho mayor a la hora de entender las interacciones y el funcionamiento de los diferentes subsistemas. Como beneficio añadido, los tests unitarios se mantienen por defecto siempre actualizados con el código, por lo que no es necesario redactar una documentación por separado.

El desarrollo de Naylang será llevado a cabo en iteraciones cortas, muchas veces de menos de una semana de duración. El objetivo es explorar las diferentes arquitecturas de las posibles soluciones a los problemas presentados por la construcción de intérpretes. Así, se consigue maximizar el beneficio que brinda la completa cobertura de tests interando sobre los diseños sin miedo a una regresión en la funcionalidad.

Compromisos
--------

Dado que Naylang está diseñado como un caso de estudio, la claridad en el código y las buenas prácticas toman precedencia sobre la eficiencia a la hora de hacer decisiones de implementación. En concreto, si existe una implementación simple y robusta para algún componente ésta tomará predecencia por encima de otras más eficientes pero más oscuras.

Sin embargo, el diseño modular, desacoplado y robusto resultante de la disciplina TDD hace que sea relativamente sencillo para futuras contribuciones intercambiar uno de los componentes menos eficientes por una implementación más eficiente con funcionalidad similar.

En resumen, este proyecto pretende optimizar sus decisiones para maximizar su **claridad** y **extensibilidad**, en lugar de maximizar parámetros como **tiempo de ejecución** ó **uso de memoria**.
