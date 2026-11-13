---
name: python-oop-enterprise
description: "POO intermedia y avanzada en Python a nivel empresarial: tipado estricto, propiedades y descriptores, herencia con MRO, sobrecarga de operadores, protocolo de iteradores, clases abstractas (ABC) y Factory Method. Úsala al modelar jerarquías de clases, contratos o interfaces en Python."
---

# **SKILL: Enterprise Object-Oriented Programming in Python (Intermediate OOP)**

## **1. Identidad y Propósito del Skill**

Este skill define el conjunto de reglas, directrices de arquitectura y mejores prácticas para diseñar y escribir código Python profesional (*enterprise-grade*), desacoplado, modular y escalable. Está fundamentado en los principios del curso *Intermediate Object-Oriented Programming in Python* de Jake Roach.

Cualquier agente o desarrollador que active este skill debe adherirse estrictamente a los lineamientos de tipado estricto, encapsulamiento mediante descriptores, herencia controlada con MRO, sobrecarga idiomática de operadores, protocolo de iteradores, contratos formales (ABCs/Interfaces) y patrones creacionales (Factory Method).

## **2. Los 7 Mandamientos de Calidad de Código**

> 1. **Tipado Obligatorio (*Enterprise-Grade Typing*):** Todo atributo, parámetro y retorno de método debe tener *type hints* explícitos. Si un método no retorna nada, debe declararse explícitamente \-\> None.  
> 2. **Contratos Explícitos:** Toda clase base compartida debe heredar de abc.ABC y definir sus métodos abstractos con @abstractmethod. No uses interfaces implícitas si requieres cumplimiento en tiempo de ejecución.  
> 3. **Encapsulamiento con Propiedades:** Nunca expongas mutaciones directas de datos sensibles o que requieran validación; utiliza el decorador @property junto con sus variantes .setter y .deleter, almacenando el estado en variables internas prefijadas con guion bajo (self.\_attribute).  
> 4. **Respeto al MRO y C3:** Al modelar herencia múltiple y multinivel, verifica el orden de precedencia local y llama siempre a los constructores correspondientes utilizando super().\_\_init\_\_(...) o la delegación explícita adecuada sin romper la cadena.  
> 5. **Sobrecarga Idiomática:** Implementa métodos dunder (\_\_eq\_\_, \_\_add\_\_, etc.) para otorgar naturalidad matemática y semántica a las entidades del dominio, garantizando que retornen nuevas instancias cuando aplique.  
> 6. **Iteración Segura:** Todo generador o flujo de datos personalizado debe cumplir formalmente el protocolo de iterador (\_\_iter\_\_ y \_\_next\_\_), asegurando siempre el lanzamiento de StopIteration para evitar bucles infinitos.  
> 7. **Desacoplamiento Creacional:** Evita cadenas de if/elif/else acopladas a la instanciación de clases concretas dentro de métodos de negocio; abstrae la creación usando el patrón *Factory Method* prefijado por convención con \_.

## **3. Guía Operativa y Patrones de Implementación**

### **Regla 1: Tipado Estático y Métodos de Fábrica de Tipos**

> * **Uso:** Utiliza tipos nativos (int, str, float, bool) y el módulo typing (List, Dict, Tuple, Optional, Callable, Iterator, Any).  
> * **Clases Propias:** Utiliza los nombres de clases existentes como tipos válidos para documentar y restringir entradas/salidas.

from typing import List, Dict, Optional

class Course:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, course\_code: str, credits: int) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.course\_code: str \= course\_code  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.credits: int \= credits

class Student:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, name: str, student\_id: int, tuition\_balance: float) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.name: str \= name  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.student\_id: int \= student\_id  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.tuition\_balance: float \= tuition\_balance  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.courses: List\[Course\] \= \[\]

&nbsp;&nbsp;&nbsp;&nbsp;def enroll(self, course: Course) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.courses.append(course)

&nbsp;&nbsp;&nbsp;&nbsp;def get\_schedule(self) \-\> Dict\[str, int\]:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return {c.course\_code: c.credits for c in self.courses}

### **Regla 2: Descriptores y Encapsulamiento con @property**

> * **Getter:** @property para transformar, formatear o enmascarar la lectura.  
> * **Setter:** @\<attr\>.setter para validar tipos, formatos o rangos antes de guardar en self.\_\<attr\>.  
> * **Deleter:** @\<attr\>.deleter para prevenir borrados no autorizados (raise AttributeError) o limpiar recursos.

class SensitiveRecord:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, identifier: str, ssn: str) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.identifier: str \= identifier  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.ssn: str \= ssn  \# Invoca el setter automáticamente

&nbsp;&nbsp;&nbsp;&nbsp;@property  
&nbsp;&nbsp;&nbsp;&nbsp;def ssn(self) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Devuelve el SSN ofuscado mostrando únicamente los últimos 4 dígitos."""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return f"XXX-XX-{self.\_ssn\[-4:\]}"

&nbsp;&nbsp;&nbsp;&nbsp;@ssn.setter  
&nbsp;&nbsp;&nbsp;&nbsp;def ssn(self, new\_ssn: str) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if not isinstance(new\_ssn, str) or len(new\_ssn) \!= 11:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise ValueError("El SSN debe tener un formato válido de 11 caracteres (XXX-XX-XXXX).")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.\_ssn: str \= new\_ssn

&nbsp;&nbsp;&nbsp;&nbsp;@ssn.deleter  
&nbsp;&nbsp;&nbsp;&nbsp;def ssn(self) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise AttributeError("Operación denegada: No está permitido eliminar el atributo SSN.")

### **Regla 3: Intercepción Dinámica de Atributos (\_\_getattr\_\_ y \_\_setattr\_\_)**

> * \_\_getattr\_\_(self, name): Se ejecuta **únicamente** cuando se intenta acceder a un atributo que **no existe** en el *namespace* del objeto. Sirve para placeholders o valores dinámicos por defecto.  
> * \_\_setattr\_\_(self, name, value): Intercepta **todas** las asignaciones de atributos.  
> * **Peligro Crítico:** Dentro de \_\_setattr\_\_, **nunca** uses self.name \= value (generaría recursión infinita). Usa siempre self.\_\_dict\_\_\[name\] \= value.

from typing import Any

class DynamicEntity:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, entity\_type: str) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.\_\_dict\_\_\["entity\_type"\] \= entity\_type

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_getattr\_\_(self, name: str) \-\> Any:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\# Crea un placeholder en lugar de lanzar AttributeError  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.\_\_setattr\_\_(name, None)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return None

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_setattr\_\_(self, name: str, value: Any) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\# Validación global o transformación  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if value is not None and not isinstance(value, (str, int, float, bool)):  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise TypeError(f"El valor asignado a '{name}' debe ser de tipo primitivo.")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.\_\_dict\_\_\[name\] \= value

### **Regla 4: Herencia Múltiple, Multinivel y Orden de Resolución (MRO)**

> * Modela relaciones estrictas de identidad ("es-un").  
> * Respeta el algoritmo de linealización C3:  
  1. Las clases hijas se evalúan antes que las clases padre.  
  2. Los padres se evalúan de izquierda a derecha según la declaración en la firma: class Child(ParentA, ParentB).  
> * Consulta el MRO cuando depures colisiones de métodos usando Clase.mro() o Clase.\_\_mro\_\_.

class Employee:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, employee\_id: str, department: str, \*\*kwargs: Any) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;super().\_\_init\_\_(\*\*kwargs)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.employee\_id: str \= employee\_id  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.department: str \= department

&nbsp;&nbsp;&nbsp;&nbsp;def introduce(self) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return f"Empleado ID: {self.employee\_id} ({self.department})"

class Student:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, university: str, \*\*kwargs: Any) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;super().\_\_init\_\_(\*\*kwargs)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.university: str \= university

&nbsp;&nbsp;&nbsp;&nbsp;def introduce(self) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return f"Estudiante de {self.university}"

\# Herencia múltiple: Employee tiene precedencia sobre Student en MRO  
class Intern(Employee, Student):  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, employee\_id: str, department: str, university: str, mentor: str) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;super().\_\_init\_\_(employee\_id=employee\_id, department=department, university=university)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.mentor: str \= mentor

&nbsp;&nbsp;&nbsp;&nbsp;def introduce(self) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\# Sobrescritura personalizada extendiendo la funcionalidad  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;parent\_intro \= super().introduce()  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return f"{parent\_intro}, mentor asignado: {self.mentor}"

### **Regla 5: Sobrecarga de Operadores (Magic Methods)**

> * Implementa métodos mágicos para dotar de semántica natural a los objetos de dominio.  
> * \_\_eq\_\_(self, other): Compara por atributos de estado, asegurando tipado booleano de retorno.  
> * \_\_add\_\_(self, other): Puede fusionar colecciones homogéneas o generar una nueva abstracción compuesta (p. ej., Employee \+ Employee \-\> Team).

from typing import Any, List

class Team:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, members: List\[str\]) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.members: List\[str\] \= members

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_add\_\_(self, other: "Team") \-\> "Team":  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if not isinstance(other, Team):  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise TypeError("Solo se pueden sumar instancias de tipo Team.")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return Team(self.members \+ other.members)

class Developer:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, name: str, role: str) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.name: str \= name  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.role: str \= role

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_eq\_\_(self, other: Any) \-\> bool:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if not isinstance(other, Developer):  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return False  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return self.name \== other.name and self.role \== other.role

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_add\_\_(self, other: "Developer") \-\> Team:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if not isinstance(other, Developer):  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise TypeError("Un Developer solo puede unirse con otro Developer para formar un Team.")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return Team(\[self.name, other.name\])

### **Regla 6: Protocolo de Iteradores Personalizados**

Para crear una secuencia eficiente o generador de datos bajo demanda:

> 1. \_\_iter\_\_(self) \-\> self: Retorna la referencia del iterador.  
> 2. \_\_next\_\_(self): Incrementa el estado o genera el siguiente ítem. Cuando la condición de fin se cumple, debe disparar obligatoriamente raise StopIteration.

from typing import Iterator

class BatchProcessor:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, total\_items: int, batch\_size: int) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.total\_items: int \= total\_items  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.batch\_size: int \= batch\_size  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.\_current\_index: int \= 0

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_iter\_\_(self) \-\> "BatchProcessor":  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return self

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_next\_\_(self) \-\> Tuple\[int, int\]:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if self.\_current\_index \>= self.total\_items:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise StopIteration  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;start \= self.\_current\_index  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end \= min(self.\_current\_index \+ self.batch\_size, self.total\_items)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.\_current\_index \= end  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return (start, end)

### **Regla 7: Clases Base Abstractas (ABCs) vs. Interfaces Formales**

> * **Clase Base Abstracta (ABC \- "is-a"):** Actúa como plantilla. Puede combinar métodos abstractos (@abstractmethod) con métodos concretos ya implementados que heredarán todas las subclases.  
> * **Interfaz Formal ("must-do"):** Define un contrato puro. Hereda de ABC y **únicamente** contiene métodos decorados con @abstractmethod que contienen pass. Ninguna subclase puede instanciarse sin definir todos sus métodos.

from abc import ABC, abstractmethod

\# Interfaz Formal: Contrato estricto  
class Notifier(ABC):  
&nbsp;&nbsp;&nbsp;&nbsp;@abstractmethod  
&nbsp;&nbsp;&nbsp;&nbsp;def send(self, recipient: str, message: str) \-\> bool:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Contrato formal: todos los notificadores deben implementar send."""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pass

\# Implementación concreta del contrato  
class EmailNotifier(Notifier):  
&nbsp;&nbsp;&nbsp;&nbsp;def send(self, recipient: str, message: str) \-\> bool:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;print(f"Enviando correo a {recipient}: {message}")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return True

### **Regla 8: Patrón de Diseño Factory Method**

> * **Problema:** Métodos sobrecargados con bifurcaciones if/elif/else que instancian clases directamente.  
> * **Solución:** Aislar la instanciación en un método de fábrica (convención \_get\_\<entidad\>), retornando objetos que compartan una misma Interfaz/ABC (el *Product*).

from abc import ABC, abstractmethod  
from typing import Dict, Any

\# Producto (Interfaz)  
class ReportGenerator(ABC):  
&nbsp;&nbsp;&nbsp;&nbsp;@abstractmethod  
&nbsp;&nbsp;&nbsp;&nbsp;def build\_report(self, data: Dict\[str, Any\]) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pass

\# Productos Concretos  
class PDFReport(ReportGenerator):  
&nbsp;&nbsp;&nbsp;&nbsp;def build\_report(self, data: Dict\[str, Any\]) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return f"\[PDF Format\] Reporte con {len(data)} registros."

class CSVReport(ReportGenerator):  
&nbsp;&nbsp;&nbsp;&nbsp;def build\_report(self, data: Dict\[str, Any\]) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return f"\[CSV Format\] Reporte con {len(data)} registros."

\# Cliente desacoplado con Factory Method  
class AnalyticsService:  
&nbsp;&nbsp;&nbsp;&nbsp;def \_create\_report\_generator(self, format\_type: str) \-\> ReportGenerator:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Factory Method para instanciar el generador según el formato requerido."""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;format\_lower \= format\_type.lower()  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if format\_lower \== "pdf":  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return PDFReport()  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;elif format\_lower \== "csv":  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return CSVReport()  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise ValueError(f"Formato no soportado: {format\_type}")

&nbsp;&nbsp;&nbsp;&nbsp;def generate(self, format\_type: str, dataset: Dict\[str, Any\]) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\# El método de negocio desconoce la clase concreta; solo depende de la interfaz  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;generator: ReportGenerator \= self.\_create\_report\_generator(format\_type)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return generator.build\_report(dataset)

## **4. Matriz de Autoevaluación para Agentes y Desarrolladores**

Antes de entregar código producido bajo este skill, valida cada uno de los siguientes puntos:

| Criterio | Pregunta de Control | Estado Requerido |
| :---- | :---- | :---- |
| **Type Hints** | ¿Todos los parámetros y retornos tienen anotación (def m(self, x: int) \-\> None:)? | **SÍ** |
| **Encapsulamiento** | ¿Los atributos críticos usan @property y self.\_variable? | **SÍ** |
| **Recursión en \_\_setattr\_\_** | Si se usa \_\_setattr\_\_, ¿se muta a través de self.\_\_dict\_\_ para evitar recursión? | **SÍ** |
| **MRO / Jerarquía** | En herencia múltiple, ¿el orden de clases en la firma respeta la prioridad de resolución? | **SÍ** |
| **Dunder Methods** | ¿Los métodos mágicos (\_\_eq\_\_, \_\_add\_\_) validan el tipo del operando other? | **SÍ** |
| **Iteradores** | ¿La clase iterador implementa tanto \_\_iter\_\_ como \_\_next\_\_ y lanza StopIteration? | **SÍ** |
| **ABCs e Interfaces** | ¿Las clases abstractas heredan de ABC y usan @abstractmethod sin implementar lógica de contrato? | **SÍ** |
| **Factory Method** | ¿Se separó la lógica de creación de instancias de la lógica de procesamiento principal? | **SÍ** |

&nbsp;
