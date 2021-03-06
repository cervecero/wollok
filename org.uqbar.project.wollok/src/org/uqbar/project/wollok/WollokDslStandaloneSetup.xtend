/*
 * generated by Xtext
 */
package org.uqbar.project.wollok

import com.google.inject.Binder
import com.google.inject.Guice
import com.google.inject.Module

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class WollokDslStandaloneSetup extends WollokDslStandaloneSetupGenerated implements Module {

	override createInjector() {
		return Guice.createInjector(new WollokDslRuntimeModule(),this)
	}
	
	override configure(Binder binder) {
	}
	
}
