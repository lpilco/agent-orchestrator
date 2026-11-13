---
name: gsap-animation-architecture
description: "Animación web con GSAP (timelines, ScrollTrigger, Observer, matchMedia) con arquitectura limpia: desacoplada del DOM, 60-120 FPS, limpieza con gsap.context() y respeto a prefers-reduced-motion. Úsala al crear, auditar o refactorizar animaciones de landing pages y aplicaciones web."
---

# SKILL: GSAP Enterprise Animation & Clean Frontend Architecture

> **Rol del Agente / Desarrollador:** Actúas como un **Senior Creative Technologist y Arquitecto de Software Frontend** especializado en **GSAP (GreenSock Animation Platform)**. Cada fragmento de código que diseñes, audites o refactorices para landing pages y aplicaciones web debe cumplir estrictamente con los principios de Clean Architecture, desacoplamiento del DOM, rendimiento a $60\text{--}120\text{ FPS}$, gestión determinista de memoria y documentación técnica rigurosa.

---

## 1. Propósito y Misión del Skill

El código de animación en el desarrollo web suele degradarse rápidamente en scripts procedimentales difíciles de mantener, acoplados a clases de CSS estéticas y propensos a fugas de memoria (*memory leaks*). 

El objetivo de este skill es garantizar que toda implementación de GSAP sea:
* **Defensiva y Resiliente (*Fail Fast*):** Verifica la existencia de nodos del DOM y plugins antes de instanciar cualquier animación, evitando errores silenciosos o *ScrollTriggers* huérfanos.
* **Desacoplada y Modular (SRP):** Separa estrictamente la **preparación del DOM**, la **fábrica de coreografías (*Timelines*)** y la **vinculación de disparadores (*ScrollTrigger / Observer*)**.
* **Eficiente en Hardware y Memoria:** Garantiza aceleración por GPU y una limpieza impecable del ciclo de vida mediante `gsap.context()` y `gsap.matchMedia()`.

---

## 2. Los 8 Mandamientos de Calidad de Código en GSAP

1. **Cero *Hardcoding* (Tokens de Movimiento Centralizados):** Queda estrictamente prohibido dispersar "números mágicos" (duraciones arbitrarias como `0.73`, desfases sueltos o curvas `ease` repetidas) o selectores de estilo CSS (`.btn-primary`) dentro de las funciones de animación. Todo parámetro global reside en un objeto inmutable `ANIMATION_CONFIG` y todo selector usa atributos de datos dedicados (`data-animate="..."`).
2. **Principio *Fail Fast* y Consulta Defensiva del DOM:** Jamás pases un selector de texto directo a `gsap.to(".elemento")` sin validar su existencia en el alcance (*scope*) actual. Si un nodo requerido no existe, la función debe abortar limpiamente mediante una cláusula de guarda (*guard clause*) o lanzar un error semántico si es crítico.
3. **Principio *Do One Thing* (Responsabilidad Única - SRP):** Una función no puede consultar el DOM, dividir texto, crear un timeline, atarlo a un `ScrollTrigger` y registrar eventos de ratón al mismo tiempo. Desacopla la **creación del movimiento** de su **controlador de ejecución**.
4. **Principio DRY mediante *Animation Factories*:** Prohibido copiar y pegar bloques `gsap.from(..., { y: 40, opacity: 0 })` a lo largo del proyecto. Abstrae patrones repetitivos en funciones fábrica (*Factory Methods*) o efectos globales con `gsap.registerEffect()`.
5. **Encapsulamiento de Ciclo de Vida y Limpieza (`gsap.context` & `revert`):** Toda animación debe crearse dentro de un contexto acotado (`gsap.context()` en Vanilla JS o `useGSAP()` en React). Todo módulo debe exponer un método `.destroy()` o `.revert()` que restaure el DOM a su estado original y elimine cualquier `ScrollTrigger` o `SplitText` activo.
6. **Responsividad y Accesibilidad Mandatoria (`gsap.matchMedia`):** Ninguna animación compleja (`pin`, `scrub`, `SplitText`) debe ejecutarse de forma ciega en todos los dispositivos. Es obligatorio gestionar *breakpoints* y respetar la preferencia del sistema operativo `prefers-reduced-motion` mediante `gsap.matchMedia()`.
7. **Exclusividad de Composición por GPU ($60\text{--}120\text{ FPS}$):** Prohibido animar propiedades que disparen *Reflow/Layout* (`top`, `left`, `width`, `height`, `margin`, `padding`). Utiliza exclusivamente transformaciones matriciales y opacidad (`x`, `y`, `xPercent`, `yPercent`, `scale`, `rotation`, `autoAlpha`, `force3D`). Para cambios de estructura o layout, es obligatorio utilizar el plugin **`Flip`**.
8. **Documentación Google-Style JSDoc y Tipado Estricto:** Toda clase, fábrica de timelines o función pública debe incluir un bloque `/** ... */` JSDoc especificando propósito en modo imperativo, `@param` con tipos estrictos (`HTMLElement`, `gsap.core.Timeline`, `Object`), `@returns` y `@throws`.

---

## 3. Guía Operativa y Patrones de Implementación (Los 20 Keywords Esenciales)

### Regla 1: Cero Hardcoding y Tokens de Movimiento (`ease`, `duration`, `CustomEase`)

* **Desacoplamiento CSS vs. JS:** Las clases de CSS son para estilos (`.card-header`); los atributos `data-*` son contratos para JavaScript (`[data-gsap="hero-title"]`). Así, un cambio de diseño en Tailwind o CSS nunca rompe las animaciones.
* **Centralización:** Agrupa duraciones, curvas (`ease`) y *breakpoints* en un diccionario congelado (`Object.freeze`).

```javascript
/**
 * Global immutable configuration for motion design tokens and breakpoints.
 * @constant {Object}
 */
export const MOTION_TOKENS = Object.freeze({
  DURATION: {
    FAST: 0.3,
    BASE: 0.8,
    SLOW: 1.4,
  },
  EASE: {
    OUT: "power3.out",
    IN_OUT: "expo.inOut",
    ELASTIC: "elastic.out(1, 0.5)",
  },
  STAGGER: {
    TIGHT: 0.05,
    NORMAL: 0.15,
  },
  BREAKPOINTS: {
    DESKTOP: "(min-width: 1024px)",
    MOBILE: "(max-width: 1023px)",
    REDUCED_MOTION: "(prefers-reduced-motion: reduce)",
  },
});
```

---

### Regla 2: Principio *Do One Thing* y *Factory Pattern* (`gsap.timeline`, `gsap.to`, `gsap.from`, `gsap.set`, `stagger`, `position parameter`)

* ❌ **Antipatrón Monolítico:** Una función `initLanding()` de 300 líneas que mezcla selectores globales, configuraciones iniciales y triggers.
* ✔️ **Patrón Modular (Factory):** Funciones puras que reciben nodos del DOM ya validados y devuelven una instancia de `gsap.core.Timeline` desacoplada de cómo o cuándo se reproduce.
* **Uso de `autoAlpha` sobre `opacity`:** Prefiere `autoAlpha` (combina `opacity` y `visibility: hidden`) para evitar que elementos invisibles intercepten clics del usuario.

```javascript
/**
 * Build a reusable staggered reveal timeline for a collection of DOM elements.
 *
 * @param {HTMLElement[]} targets - Array of validated DOM nodes to animate.
 * @param {Object} [options={}] - Optional configuration overrides.
 * @param {number} [options.yOffset=40] - Initial vertical translation in pixels.
 * @param {number} [options.stagger=MOTION_TOKENS.STAGGER.NORMAL] - Cascade delay between items.
 * @returns {gsap.core.Timeline} Constructed GSAP timeline ready for composition or triggering.
 * @throws {TypeError} If `targets` is not a valid array of elements.
 */
export function createStaggerRevealTimeline(targets, options = {}) {
  if (!Array.isArray(targets) || targets.length === 0) {
    throw new TypeError("createStaggerRevealTimeline requires a non-empty array of DOM elements.");
  }

  const {
    yOffset = 40,
    stagger = MOTION_TOKENS.STAGGER.NORMAL,
  } = options;

  const tl = gsap.timeline({
    defaults: {
      duration: MOTION_TOKENS.DURATION.BASE,
      ease: MOTION_TOKENS.EASE.OUT,
      force3D: true,
    },
  });

  // 1. Preparación instantánea de estado (gsap.set)
  gsap.set(targets, { autoAlpha: 0, y: yOffset });

  // 2. Definición de animación con stagger y position parameter
  tl.to(targets, {
    autoAlpha: 1,
    y: 0,
    stagger: stagger,
  }, 0); // Position parameter explícito al segundo 0

  return tl;
}
```

---

### Regla 3: Orquestación Desacoplada con `ScrollTrigger` (`ScrollTrigger`, `scrub`, `pin`, `toggleActions`)

* **Inyección de Timelines:** Primero construye el `timeline` mediante su función fábrica, y luego vincúlalo a `ScrollTrigger.create({ animation: tl, ... })`. Esto permite probar la animación en aislamiento sin depender del scroll.
* **`invalidateOnRefresh: true`:** Obligatorio cuando los valores de la animación dependen de dimensiones dinámicas del viewport (funciones como `x: () => -(container.scrollWidth - window.innerWidth)`).

```javascript
/**
 * Bind a pre-built timeline to a pinned ScrollTrigger controller.
 *
 * @param {HTMLElement} triggerElement - Section element to pin and monitor.
 * @param {gsap.core.Timeline} animationTimeline - Timeline driven by scroll progress.
 * @param {string} [scrollDistance="+=200%"] - Scroll distance while pinned.
 * @returns {ScrollTrigger} Created ScrollTrigger instance.
 */
export function attachPinnedScrollTrigger(triggerElement, animationTimeline, scrollDistance = "+=200%") {
  if (!(triggerElement instanceof HTMLElement)) {
    throw new TypeError("Valid HTMLElement required for ScrollTrigger binding.");
  }

  return ScrollTrigger.create({
    trigger: triggerElement,
    animation: animationTimeline,
    pin: true,
    scrub: 1, // Suavizado de 1s vinculado a la barra de scroll
    start: "top top",
    end: scrollDistance,
    invalidateOnRefresh: true,
    toggleActions: "play none none reverse",
  });
}
```

---

### Regla 4: Efectos Avanzados de Layout y Tipografía (`Flip`, `SplitText`, `Observer`, `MorphSVG`)

* **Transiciones de Estado con `Flip` (Cero Layout Thrashing):** Cuando un elemento cambia de contenedor flexbox/grid, o un acordeón/tarjeta se expande, sigue estrictamente el protocolo de 3 pasos:
  1. **Capture:** `const state = Flip.getState(targets);`
  2. **Mutate DOM:** Cambia clases o atributos DOM instantáneamente.
  3. **Invert & Play:** `Flip.from(state, { duration, ease, absolute: true });`
* **Limpieza de `SplitText`:** `SplitText` envuelve palabras y letras en nodos `<div>` o `<span>`. Siempre debe ejecutarse `splitInstance.revert()` al redimensionar o desmontar para mantener la accesibilidad de lectores de pantalla (`aria-label`).

---

### Regla 5: Gestión de Memoria, Responsividad y Accesibilidad (`gsap.context`, `gsap.matchMedia`, `kill`, `revert`)

* **El Patrón de Controlador por Sección (OOP):** Encapsula la lógica de una página o sección dentro de una clase que centralice sus referencias en el constructor, inicialice las animaciones dentro de `gsap.matchMedia()` (que incluye `gsap.context()` internamente) y provea un método `.destroy()` infalible.

---

## 4. Plantilla Canónica de Referencia (Arquitectura Completa)

A continuación se presenta la implementación modelo de un controlador de animaciones para una Landing Page (ej. *Orbit*), cumpliendo con todos los principios del Skill:

```javascript
/**
 * @fileoverview Enterprise GSAP Animation Controller for Landing Pages.
 * Implements Clean Architecture, SRP, Factory Pattern, and deterministic memory cleanup.
 */

import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { Flip } from "gsap/Flip";
import { SplitText } from "gsap/SplitText";
import { Observer } from "gsap/Observer";

// Registro centralizado e idempotente de plugins
gsap.registerPlugin(ScrollTrigger, Flip, SplitText, Observer);

/**
 * Custom domain error for missing or invalid DOM animation targets.
 */
class AnimationDOMError extends Error {
  /**
   * @param {string} message - Error description.
   */
  constructor(message) {
    super(message);
    this.name = "AnimationDOMError";
  }
}

/**
 * Immutable motion design tokens.
 * @constant {Object}
 */
export const MOTION_CONFIG = Object.freeze({
  DURATION: { FAST: 0.35, BASE: 0.85, SLOW: 1.2 },
  EASE: {
    PRIMARY: "power3.out",
    LAYOUT: "expo.inOut",
  },
  STAGGER: { CHARS: 0.02, CARDS: 0.15 },
  QUERIES: {
    DESKTOP: "(min-width: 1024px)",
    MOBILE: "(max-width: 1023px)",
    NO_MOTION: "(prefers-reduced-motion: reduce)",
  },
});

/**
 * Orchestrate and manage the lifecycle of all GSAP animations within a landing page scope.
 */
export class LandingAnimationController {
  /**
   * Initialize the controller and validate the root scope container.
   *
   * @param {HTMLElement|string} rootSelector - Root DOM element or selector scoping all queries.
   * @throws {AnimationDOMError} If the root container does not exist in the document.
   */
  constructor(rootSelector) {
    const resolvedRoot =
      typeof rootSelector === "string"
        ? document.querySelector(rootSelector)
        : rootSelector;

    if (!(resolvedRoot instanceof HTMLElement)) {
      throw new AnimationDOMError(
        `Root container '${rootSelector}' not found in the DOM. Fail fast triggered.`
      );
    }

    /** @private @type {HTMLElement} */
    this._root = resolvedRoot;

    /** @private @type {gsap.MatchMedia} */
    this._mm = gsap.matchMedia();

    /** @private @type {SplitText[]} */
    this._splitInstances = [];
  }

  /**
   * Initialize responsive animations and accessibility fallbacks within the root scope.
   *
   * @returns {void}
   */
  init() {
    this._mm.add(
      {
        isDesktop: MOTION_CONFIG.QUERIES.DESKTOP,
        isMobile: MOTION_CONFIG.QUERIES.MOBILE,
        reduceMotion: MOTION_CONFIG.QUERIES.NO_MOTION,
      },
      (context) => {
        const { isDesktop, reduceMotion } = context.conditions;

        // 1. Respeto estricto a accesibilidad: revelar todo sin movimiento
        if (reduceMotion) {
          gsap.set("[data-gsap]", { autoAlpha: 1, clearProps: "transform" });
          return;
        }

        // 2. Orquestación modular por responsabilidad
        this._initHeroAnimation();
        this._initCardsReveal();
        this._initFilterableLayoutFlip();

        // 3. Pinning complejo reservado únicamente para Desktop
        if (isDesktop) {
          this._initPinnedStorySection();
        }

        // Cleanup hook automático ejecutado por matchMedia al cambiar de breakpoint o destruir
        return () => {
          this._revertSplitText();
        };
      },
      this._root // Scope estricto: ningún selector afectará elementos fuera de this._root
    );
  }

  /**
   * Build and play the hero entrance choreography using SplitText and position parameters.
   *
   * @private
   * @returns {gsap.core.Timeline|null} The executed timeline or null if elements are absent.
   */
  _initHeroAnimation() {
    const title = this._root.querySelector('[data-gsap="hero-title"]');
    const cta = this._root.querySelector('[data-gsap="hero-cta"]');

    if (!title) return null;

    const split = new SplitText(title, { type: "lines,words,chars" });
    this._splitInstances.push(split);

    const tl = gsap.timeline({
      defaults: { ease: MOTION_CONFIG.EASE.PRIMARY, force3D: true },
    });

    gsap.set(title, { autoAlpha: 1 });

    tl.from(split.chars, {
      yPercent: 100,
      autoAlpha: 0,
      duration: MOTION_CONFIG.DURATION.BASE,
      stagger: MOTION_CONFIG.STAGGER.CHARS,
    });

    if (cta) {
      // Position parameter "<+=0.3": inicia 0.3s después del comienzo de la animación anterior
      tl.from(
        cta,
        {
          scale: 0.9,
          autoAlpha: 0,
          duration: MOTION_CONFIG.DURATION.FAST,
        },
        "<+=0.3"
      );
    }

    return tl;
  }

  /**
   * Animate feature cards on scroll entry using batching / stagger.
   *
   * @private
   * @returns {void}
   */
  _initCardsReveal() {
    const cardsSection = this._root.querySelector('[data-gsap="cards-section"]');
    const cards = gsap.utils.toArray('[data-gsap="card-item"]', this._root);

    if (!cardsSection || cards.length === 0) return;

    gsap.set(cards, { autoAlpha: 0, y: 50 });

    gsap.to(cards, {
      scrollTrigger: {
        trigger: cardsSection,
        start: "top 80%",
        toggleActions: "play none none reverse",
      },
      autoAlpha: 1,
      y: 0,
      duration: MOTION_CONFIG.DURATION.BASE,
      stagger: MOTION_CONFIG.STAGGER.CARDS,
      ease: MOTION_CONFIG.EASE.PRIMARY,
      force3D: true,
    });
  }

  /**
   * Create a pinned horizontal storytelling sequence driven by scroll scrub.
   *
   * @private
   * @returns {void}
   */
  _initPinnedStorySection() {
    const pinWrapper = this._root.querySelector('[data-gsap="pin-wrapper"]');
    const track = this._root.querySelector('[data-gsap="horizontal-track"]');

    if (!pinWrapper || !track) return;

    const getScrollAmount = () => -(track.scrollWidth - window.innerWidth);

    const tween = gsap.to(track, {
      x: getScrollAmount,
      ease: "none",
      force3D: true,
    });

    ScrollTrigger.create({
      trigger: pinWrapper,
      start: "top top",
      end: () => `+=${track.scrollWidth - window.innerWidth}`,
      pin: true,
      animation: tween,
      scrub: 1,
      invalidateOnRefresh: true,
    });
  }

  /**
   * Bind layout transition animations using GSAP Flip plugin (View Transitions equivalent).
   *
   * @private
   * @returns {void}
   */
  _initFilterableLayoutFlip() {
    const toggleButtons = gsap.utils.toArray('[data-gsap="flip-trigger"]', this._root);
    const flipTargets = gsap.utils.toArray('[data-gsap="flip-item"]', this._root);

    if (toggleButtons.length === 0 || flipTargets.length === 0) return;

    toggleButtons.forEach((btn) => {
      btn.addEventListener("click", () => {
        // 1. Capturar estado geométrico inicial
        const state = Flip.getState(flipTargets);

        // 2. Aplicar mutación estructural en el DOM
        const filterValue = btn.getAttribute("data-filter");
        flipTargets.forEach((item) => {
          const matches = filterValue === "all" || item.dataset.category === filterValue;
          item.classList.toggle("is-hidden", !matches);
        });

        // 3. Animar transición de layout por GPU sin reflow visual
        Flip.from(state, {
          duration: MOTION_CONFIG.DURATION.FAST,
          ease: MOTION_CONFIG.EASE.LAYOUT,
          scale: true,
          absolute: true,
          stagger: 0.04,
          onEnter: (elements) =>
            gsap.fromTo(elements, { autoAlpha: 0, scale: 0.8 }, { autoAlpha: 1, scale: 1 }),
          onLeave: (elements) =>
            gsap.to(elements, { autoAlpha: 0, scale: 0.8 }),
        });
      });
    });
  }

  /**
   * Revert all SplitText DOM mutations back to clean semantic HTML.
   *
   * @private
   * @returns {void}
   */
  _revertSplitText() {
    this._splitInstances.forEach((instance) => instance.revert());
    this._splitInstances = [];
  }

  /**
   * Clean up all GSAP timelines, ScrollTriggers, MatchMedia listeners, and inline styles.
   * Must be called on page unmount or SPA route transition.
   *
   * @returns {void}
   */
  destroy() {
    this._revertSplitText();
    this._mm.revert();
  }
}
```

---

## 5. Matriz de Autoevaluación y Checklist de Auditoría para el Agente

Antes de entregar cualquier implementación con GSAP, el agente o desarrollador debe verificar el cumplimiento estricto de esta matriz:

| Criterio de Ingeniería | Pregunta de Control | Estado Requerido |
| :--- | :--- | :--- |
| **Cero Hardcoding** | ¿Todas las duraciones, curvas `ease` y *breakpoints* provienen de una constante congelada (`MOTION_CONFIG`)? | **SÍ** |
| **Selectores Desacoplados** | ¿Se usaron atributos `data-gsap="..."` en lugar de clases estéticas de CSS/Tailwind (`.flex`, `.text-xl`)? | **SÍ** |
| **Validación *Fail Fast*** | ¿Se comprueba que los nodos del DOM existan (`if (!el) return;`) antes de instanciar `gsap.to` o `ScrollTrigger`? | **SÍ** |
| **Responsabilidad Única (SRP)** | ¿Están separadas la creación de coreografías (`timeline`) de sus disparadores (`ScrollTrigger`)? | **SÍ** |
| **Exclusividad GPU ($60+\text{ FPS}$)** | ¿Se animan únicamente transformaciones (`x`, `y`, `scale`, `autoAlpha`) y se usa `Flip` para cambios de layout? | **SÍ** |
| **Responsividad & A11y** | ¿Se encapsuló todo en `gsap.matchMedia()` contemplando `(prefers-reduced-motion: reduce)`? | **SÍ** |
| **Recolección de Basura** | ¿Existe un método `.destroy()` que invoque `.revert()` sobre el contexto/`matchMedia` y sobre `SplitText`? | **SÍ** |
| **Recálculo Dinámico** | Si hay cálculos dependientes de `window.innerWidth` en `ScrollTrigger`, ¿se usaron funciones `() => ...` junto con `invalidateOnRefresh: true`? | **SÍ** |
| **Documentación Técnica** | ¿Todas las clases y métodos cuentan con bloques JSDoc en modo imperativo con `@param`, `@returns` y `@throws`? | **SÍ** |
