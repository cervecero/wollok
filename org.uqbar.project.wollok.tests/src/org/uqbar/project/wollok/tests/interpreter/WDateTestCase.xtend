package org.uqbar.project.wollok.tests.interpreter

import org.uqbar.project.wollok.tests.interpreter.AbstractWollokInterpreterTestCase
import org.junit.Test

/**
 * 
 * @author dodain
 */
class WDateTestCase extends AbstractWollokInterpreterTestCase {

	
	@Test
	def void unDateNoTieneTiempoEntoncesDosNowEnMomentosDistintosSonIguales() {
		'''program a {
			const ahora1 = new WDate()
			const ahora2 = new WDate() 
			assert.that(ahora1.equals(ahora2))
		}
		'''.interpretPropagatingErrors
	}
	
}	
