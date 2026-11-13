---
name: python-oop-clean-architecture
description: "Programación orientada a objetos y Clean Architecture en Python: fail fast, separación de I/O, lógica de negocio y presentación, PEP 8, type hints y docstrings estilo Google. Úsala al diseñar, escribir o refactorizar clases y módulos Python."
---

# **SKILL: Python Object-Oriented Engineering & Clean Architecture**

## **1. Rol y Misión del Agente / Programador**

Eres un **Ingeniero de Software Senior especializado en Python y Arquitectura de Software**. Tu objetivo es diseñar, estructurar, escribir y refactorizar código bajo el paradigma de **Programación Orientada a Objetos (POO)** combinado con **Clean Architecture**.

Todo código generado o auditado debe ser:

> * **Robusto y Preventivo:** Falla de forma temprana (*Fail Fast*) y nunca permite estados inconsistentes.  
> * **Modular y Desacoplado:** Separa estrictamente la adquisición (I/O), la lógica de negocio y la presentación.  
> * **Pythonic y Estandarizado:** Cumple rigurosamente con PEP 8, anotaciones de tipos (*Type Hints*) y documentación con Google-Style Docstrings.

## **2. Los Pilares de POO Aplicados**

### **A. Encapsulamiento Real**

> * **Agrupa datos y comportamientos:** No utilices clases como meras estructuras de datos pasivas sobre las cuales funciones externas operan de forma procedimental. Si una acción modifica o calcula sobre el estado de un objeto, debe pertenecer a la clase en forma de **método**.  
> * **Acceso controlado:** El estado interno del objeto se manipula a través de su interfaz pública.

### **B. Herencia Responsable ("Is-a Relationship")**

> * Aplica herencia solo cuando exista una estricta relación *"es-un"* (ej. SavingsAccount *es una* BankAccount).  
> * **Reutilización sin duplicación:** En clases hijas, delega siempre la inicialización común a la clase padre mediante super().\_\_init\_\_(...) o ParentClass.\_\_init\_\_(self, ...).  
> * **Aumento (*Augmenting*):** Al sobrescribir un método, extiende la funcionalidad llamando a la implementación base en lugar de reescribirla por completo.

### **C. Polimorfismo e Integridad de Interfaz**

> * Mantén consistencia en las firmas de los métodos heredados. Si una clase hija altera drásticamente los parámetros requeridos de un método heredado, rompe la interoperabilidad polimórfica y el principio de sustitución.

## **3. Anatomía Segura de Clases y Gestión de Estado**

### **A. Centralización en el Constructor \_\_init\_\_**

> * **Regla Inviolable:** Todos los atributos de instancia **deben** inicializarse dentro del método constructor \_\_init\_\_.  
> * ❌ **Prohibido:** Crear atributos dinámicamente llamando métodos sueltos como set\_name() o set\_salary(). Esto produce AttributeError en tiempo de ejecución si se accede a un dato antes de invocar su método asignador.  
> * **El constructor es un contrato de fabricación:** Un objeto jamás debe poder instanciarse en un estado incompleto o nulo.

### **B. Manejo Seguro de Argumentos y Memoria**

> * **Prohibido argumentos mutables por defecto:** Jamás uses def \_\_init\_\_(self, items=\[\]): o colecciones mutables directas como parámetros por defecto. Al ser evaluadas una sola vez en tiempo de carga, todas las instancias compartirán la misma lista en memoria física.  
> * ✔️ **Patrón Canónico:** Usa None como valor por defecto y asigna la estructura dentro del cuerpo:

def \_\_init\_\_(self, items=None):  
&nbsp;&nbsp;&nbsp;&nbsp;self.items \= list(items) if items is not None else \[\]

### **C. Estándares de Nomenclatura (PEP 8\)**

> * **Clases:** CamelCase (ej. BankAccount, MarkmapConverter).  
> * **Métodos y Atributos de Instancia:** lower\_snake\_case (ej. compute\_interest, account\_balance).  
> * **Constantes y Atributos de Clase:** UPPER\_CASE\_SNAKE (ej. MIN\_SALARY, MAX\_RETRIES).  
> * **Referencia de Instancia:** Usa obligatoriamente la convención self como primer argumento en métodos de instancia.  
> * **Referencia de Clase:** Usa obligatoriamente la convención cls como primer argumento en métodos decorados con @classmethod.

## **4. Alcance: Instancia vs. Clase y Métodos de Clase**

### **A. Atributos de Clase**

> * Decláralos directamente en el cuerpo de la clase (fuera de métodos).  
> * Úsalos para:  
  1. Constantes y umbrales globales de la entidad (ej. MIN\_SALARY \= 30000).  
  2. Configuraciones compartidas que aplican a todos los objetos (ej. DEFAULT\_TIMEOUT \= 5.0).  
> * **Acceso:** Accede a ellos explícitamente mediante ClassName.ATTR o cls.ATTR para evitar ambigüedades.  
> * **Evita el sombreado accidental (*Shadowing*):** Si asignas instancia.CONSTANTE \= valor, Python creará un atributo local en esa instancia concreta sin alterar el valor de la clase ni del resto de objetos. Para modificar el valor global, hazlo siempre sobre la clase: ClassName.CONSTANTE \= nuevo\_valor.

### **B. Métodos de Clase (@classmethod)**

> * Se vinculan a la clase y no a un objeto en particular. No tienen acceso a self.  
> * **Casos de Uso Principales:**  
  1. **Constructores Alternativos (*Alternative Constructors*):** Python no soporta sobrecarga de constructores múltiples. Emplea @classmethod para instanciar objetos desde formatos alternativos (ej. from\_file, from\_json, from\_birth\_year), retornando cls(...).  
  2. Métodos utilitarios que operan exclusivamente sobre constantes o configuraciones de la clase.

@classmethod  
def from\_birth\_year(cls, name: str, birth\_year: int) \-\> "Person":  
&nbsp;&nbsp;&nbsp;&nbsp;current\_year \= 2026  
&nbsp;&nbsp;&nbsp;&nbsp;age \= current\_year \- birth\_year  
&nbsp;&nbsp;&nbsp;&nbsp;return cls(name=name, age=age)

## **5. Sobrecarga de Operadores y Representación Técnica**

### **A. Igualdad Segura con \_\_eq\_\_**

> * Por defecto, el operador \== en Python compara las direcciones de memoria de los objetos (id(a) \== id(b)).  
> * Al implementar \_\_eq\_\_(self, other):  
  1. **Validación estricta de tipo:** Verifica siempre si type(self) \== type(other) o isinstance(other, ClassName) antes de comparar datos. Evita evaluar como iguales dos objetos de clases totalmente distintas que compartan casualmente un nombre de atributo (ej. Phone.number vs BankAccount.number).  
  2. Retorna obligatoriamente un booleano (True o False).

def \_\_eq\_\_(self, other: object) \-\> bool:  
&nbsp;&nbsp;&nbsp;&nbsp;if not isinstance(other, Customer):  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return False  
&nbsp;&nbsp;&nbsp;&nbsp;return (self.account\_id \== other.account\_id) and (self.name \== other.name)

### **B. Representación Técnica Inequívoca: \_\_repr\_\_ vs \_\_str\_\_**

> * **\_\_repr\_\_(self) (Obligatorio para desarrolladores):**  
  * Muestra una representación explícita y reproducible (idealmente el código que recrearía el objeto).  
  * Actúa como respaldo (*fallback*) automático de print() si \_\_str\_\_ no existe.  
  * Ejemplo: f"Customer('{self.name}', {self.balance})"  
> * **\_\_str\_\_(self) (Para usuarios finales):**  
  * Formato legible, amigable o multilínea para visualización limpia en consola o logs.

## **6. Manejo Profesional de Errores y Excepciones Personalizadas**

### **A. Principio Fail Fast en Constructores**

> * **Nunca crees objetos con estado corrupto:** Si los parámetros recibidos en \_\_init\_\_ son inválidos (ej. saldo inicial negativo, sueldo menor al mínimo legal), **lanza una excepción de inmediato con raise**.  
> * ❌ **Antipatrón:** Imprimir un mensaje en consola con print("Error") y setear el saldo a 0. Esto permite que el programa continúe ejecutándose silenciosamente con datos distorsionados.  
> * ✔️ **Patrón:** Dejar que el constructor falle con una excepción semántica para impedir la creación de la instancia inválida.

### **B. Jerarquías de Excepciones Semánticas**

> * Modela errores de negocio mediante clases que hereden de Exception o de tipos nativos como ValueError:

class DomainError(Exception):  
&nbsp;&nbsp;&nbsp;&nbsp;"""Base exception for application business errors."""  
&nbsp;&nbsp;&nbsp;&nbsp;pass

class BalanceError(DomainError):  
&nbsp;&nbsp;&nbsp;&nbsp;"""Raised when an account balance operation violates domain constraints."""  
&nbsp;&nbsp;&nbsp;&nbsp;pass

### **C. Bloques try-except-finally Específicos**

> * Captura únicamente las excepciones que tu bloque sabe manejar de forma deliberada.  
> * ❌ **Prohibido:** except: genérico o vacío (*bare except*), el cual silencia bugs reales y detenciones de sistema (KeyboardInterrupt).  
> * Usa finally para garantizar la liberación de recursos (archivos, conexiones, bloqueos).

## **7. Clean Architecture: Desacoplamiento y Responsabilidad Única**

### **A. Principio Do One Thing (SRP)**

> * Desacopla radicalmente:  
  1. **I/O y Adquisición:** Lectura de disco, peticiones HTTP, conexión a base de datos.  
  2. **Procesamiento y Negocio:** Clases de dominio, parseo, cálculo, transformaciones.  
  3. **Visualización y Salida:** Escritura en pantalla, guardado de archivos, emisión de logs.  
> * ❌ **Antipatrón monolítico:** Un método cargar\_parsear\_y\_graficar().  
> * ✔️ **Patrón modular:** Métodos o clases independientes coordinados por un orquestador.

### **B. Google-Style Docstrings Obligatorios**

Todo módulo, clase y método público debe incluir documentación en la primera línea de su cuerpo:

> * **Resumen:** Verbo en imperativo ("Create a new customer...", "Compute monthly interest...").  
> * **Args:** Cada parámetro con tipo, descripción y valor por defecto si aplica.  
> * **Returns:** Tipo y significado del valor devuelto.  
> * **Raises:** Excepciones lanzadas explícitamente y la condición detonante.

### **C. Aislamiento de Ejecución**

> * Protege los scripts ejecutables mediante la guarda:

if \_\_name\_\_ \== "\_\_main\_\_":  
&nbsp;&nbsp;&nbsp;&nbsp;\# Orquestación de prueba o ejecución principal

## **8. Plantilla Canónica de Referencia**

A continuación se expone la implementación de una clase modelo que reúne todos los principios del skill:

"""Module defining bank account entities and domain operations."""

from typing import Optional

class AccountError(ValueError):  
&nbsp;&nbsp;&nbsp;&nbsp;"""Base exception for domain errors in account operations."""  
&nbsp;&nbsp;&nbsp;&nbsp;pass

class MinimumBalanceError(AccountError):  
&nbsp;&nbsp;&nbsp;&nbsp;"""Raised when an account violates minimum balance thresholds."""  
&nbsp;&nbsp;&nbsp;&nbsp;pass

class BankAccount:  
&nbsp;&nbsp;&nbsp;&nbsp;"""Represent an individual bank account entity within the core system.

&nbsp;&nbsp;&nbsp;&nbsp;Attributes:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;MIN\_INITIAL\_BALANCE (float): Minimum required deposit to open an account.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;bank\_code (str): Shared financial institution routing code.  
&nbsp;&nbsp;&nbsp;&nbsp;"""

&nbsp;&nbsp;&nbsp;&nbsp;MIN\_INITIAL\_BALANCE: float \= 100.0  
&nbsp;&nbsp;&nbsp;&nbsp;BANK\_CODE: str \= "BK-9901"

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(self, account\_id: str, owner: str, balance: float \= 100.0) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Initialize a new BankAccount instance.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Args:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;account\_id (str): Unique identifier for the account.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;owner (str): Full name of the account holder.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;balance (float, optional): Initial deposit amount. Defaults to 100.0.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Raises:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;MinimumBalanceError: If \`balance\` is below \`MIN\_INITIAL\_BALANCE\`.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if balance \< self.MIN\_INITIAL\_BALANCE:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise MinimumBalanceError(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;f"Initial balance {balance} is below minimum {self.MIN\_INITIAL\_BALANCE}."  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\# Centralización de todos los atributos de instancia  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.account\_id: str \= account\_id  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.owner: str \= owner  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.balance: float \= balance

&nbsp;&nbsp;&nbsp;&nbsp;@classmethod  
&nbsp;&nbsp;&nbsp;&nbsp;def from\_csv\_record(cls, record\_line: str) \-\> "BankAccount":  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Instantiate an account parsing a delimited text row.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Args:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;record\_line (str): Comma-separated string in the format 'id,owner,balance'.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Returns:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;BankAccount: A newly constructed BankAccount instance.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Raises:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ValueError: If record\_line does not contain the required 3 fields.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;parts \= \[p.strip() for p in record\_line.split(",")\]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if len(parts) \!= 3:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise ValueError("CSV record must contain exactly 3 fields: id, owner, balance.")

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;acc\_id, owner\_name, raw\_balance \= parts  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return cls(account\_id=acc\_id, owner=owner\_name, balance=float(raw\_balance))

&nbsp;&nbsp;&nbsp;&nbsp;def deposit(self, amount: float) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Credit funds to the account balance.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Args:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;amount (float): Positive numeric amount to add.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Raises:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ValueError: If \`amount\` is less than or equal to zero.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if amount \<= 0:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise ValueError("Deposit amount must be strictly positive.")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.balance \+= amount

&nbsp;&nbsp;&nbsp;&nbsp;def withdraw(self, amount: float) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Debit funds from the account balance.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Args:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;amount (float): Amount to deduct.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Raises:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;MinimumBalanceError: If the withdrawal exceeds available balance.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if amount \> self.balance:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;raise MinimumBalanceError("Insufficient funds for withdrawal.")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.balance \-= amount

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_eq\_\_(self, other: object) \-\> bool:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Compare equality based on account type and unique identifier."""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if type(self) is not type(other):  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return False  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return self.account\_id \== other.account\_id

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_repr\_\_(self) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Produce a reproducible technical string representation."""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return (  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;f"BankAccount(account\_id='{self.account\_id}', "  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;f"owner='{self.owner}', balance={self.balance})"  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_str\_\_(self) \-\> str:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Produce a human-friendly multi-line description."""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return f"Account \[{self.account\_id}\] \- Owner: {self.owner} | Balance: ${self.balance:.2f}"

class SavingsAccount(BankAccount):  
&nbsp;&nbsp;&nbsp;&nbsp;"""Specialized savings account accruing periodic interest."""

&nbsp;&nbsp;&nbsp;&nbsp;def \_\_init\_\_(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;account\_id: str,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;owner: str,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;balance: float \= 100.0,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;interest\_rate: float \= 0.05  
&nbsp;&nbsp;&nbsp;&nbsp;) \-\> None:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Initialize a SavingsAccount inheriting core state and adding rate metrics.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Args:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;account\_id (str): Unique identifier.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;owner (str): Full name of the owner.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;balance (float, optional): Initial deposit. Defaults to 100.0.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;interest\_rate (float, optional): Yield multiplier. Defaults to 0.05.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\# Reutilización del constructor base  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;super().\_\_init\_\_(account\_id=account\_id, owner=owner, balance=balance)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.interest\_rate: float \= interest\_rate

&nbsp;&nbsp;&nbsp;&nbsp;def apply\_interest(self) \-\> float:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""Calculate interest accrued and credit it back to the account.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Returns:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;float: The amount of interest added.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"""  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;accrued \= self.balance \* self.interest\_rate  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.deposit(accrued)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return accrued

if \_\_name\_\_ \== "\_\_main\_\_":  
&nbsp;&nbsp;&nbsp;&nbsp;try:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;acc \= BankAccount.from\_csv\_record("ACC-101, Maryam Azar, 350.0")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;print(f"Instancia creada: {acc\!r}")  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;print(acc)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;savings \= SavingsAccount("ACC-102, John Doe, 500.0", "John Doe", 500.0, 0.08)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;print(f"¿Son iguales? {acc \== savings}")  \# Evaluará False de forma segura por tipo  
&nbsp;&nbsp;&nbsp;&nbsp;except AccountError as err:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;print(f"Error de dominio bancario: {err}")

## **9. Checklist de Auditoría Rápida para el Agente**

Antes de dar un desarrollo en Python por completado, verifica los siguientes puntos:

> 1. \[ \] **¿Atributos en \_\_init\_\_?** Todos los atributos de la instancia están creados dentro del constructor; ninguno nace de forma sorpresiva en métodos secundarios.  
> 2. \[ \] **¿Sin mutables por defecto?** No hay \[\] ni {} en cabeceras de funciones o métodos; se usó None como centinela.  
> 3. \[ \] **¿Validación Fail Fast?** Los valores fuera de rango lanzan excepciones personalizadas y detienen la instanciación de objetos erróneos.  
> 4. \[ \] **¿Uso correcto de self y cls?** Métodos de instancia usan self, métodos @classmethod usan cls y no intentan acceder a estado de instancia.  
> 5. \[ \] **¿Prevención de Shadowing?** Los atributos de clase se consultan y modifican vía ClassName.CONSTANTE y no mediante reasignaciones sobre la instancia.  
> 6. \[ \] **¿Sobrecarga segura?** Si se definió \_\_eq\_\_, se valida el tipo del operando derecho (other) antes de inspeccionar atributos.  
> 7. \[ \] **¿Doble representación?** La clase cuenta con al menos \_\_repr\_\_ reproducible y, de ser conveniente para el usuario, \_\_str\_\_.  
> 8. \[ \] **¿Separación de I/O?** Ningún método de lógica de negocio o entidad se encarga simultáneamente de abrir archivos de red/disco y formatear texto de salida.  
> 9. \[ \] **¿Documentación y Tipado?** Métodos y clases cuentan con Type Hints y Google-Style Docstrings completos.
