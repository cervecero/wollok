package org.uqbar.project.wollok.typesystem.constraints.strategies

import org.eclipse.xtend.lib.annotations.Accessors
import org.uqbar.project.wollok.typesystem.constraints.TypeVariable
import org.uqbar.project.wollok.typesystem.constraints.TypeVariablesRegistry

abstract class AbstractInferenceStrategy {
	@Accessors
	var Boolean changed

	@Accessors
	var extension TypeVariablesRegistry registry

	def run() {
		println('''Running strategy: «class.simpleName»''')
		var globalChanged = false

		do {
			changed = false
			allVariables.forEach[if (!it.hasErrors) it.analiseVariable]
			globalChanged = globalChanged || changed
		} while (changed)

		globalChanged
	}

	abstract def void analiseVariable(TypeVariable tvar)
}
