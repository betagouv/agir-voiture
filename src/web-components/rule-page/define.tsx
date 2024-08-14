import React, { Suspense } from "react"
import { Root, createRoot } from "react-dom/client"
import Engine from "publicodes"

const RulePage = React.lazy(() => import("./RulePage"))

const reactRootId = "react-root"

export function defineCustomElementWith(engine: Engine, app: any) {
    window.customElements.define(
        "publicodes-rule-page",
        class extends HTMLElement {
            reactRoot: Root
            engine: Engine
            app: any

            static observedAttributes = [
                "rule",
                "documentationPath",
                "situation",
            ]

            constructor() {
                super()
                this.reactRoot = createRoot(
                    document.getElementById(reactRootId) as HTMLElement
                )
                this.engine = engine
                this.app = app
                this.renderElement()
            }

            connectedCallback() {
                this.renderElement()
            }

            attributeChangedCallback() {
                this.renderElement()
            }

            renderElement() {
                const rulePath = this.getAttribute("rule") ?? ""
                const documentationPath =
                    this.getAttribute("documentationPath") ?? ""

                if (!rulePath || !documentationPath) {
                    return null
                }

                this.reactRoot.render(
                    <Suspense
                        fallback={
                            <div className="flex flex-col items-center justify-center mb-8 w-full">
                                <div className="loading loading-lg text-primary mt-4"></div>
                            </div>
                        }
                    >
                        <RulePage
                            app={this.app}
                            engine={this.engine}
                            rulePath={rulePath}
                            documentationPath={documentationPath}
                        />
                    </Suspense>
                )
            }
        }
    )
}
