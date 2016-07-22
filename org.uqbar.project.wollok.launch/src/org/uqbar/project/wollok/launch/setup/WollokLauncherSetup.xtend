package org.uqbar.project.wollok.launch.setup

import com.google.inject.Binder
import com.google.inject.Guice
import com.google.inject.name.Names
import org.eclipse.xtext.parser.antlr.Lexer
import org.eclipse.xtext.ui.LexerUIBindings
import org.uqbar.project.wollok.WollokDslStandaloneSetup
import org.uqbar.project.wollok.interpreter.WollokInterpreterEvaluator
import org.uqbar.project.wollok.interpreter.api.XInterpreterEvaluator
import org.uqbar.project.wollok.launch.WollokLauncherParameters
import org.uqbar.project.wollok.parser.antlr.internal.InternalWollokDslLexer
import org.uqbar.project.wollok.interpreter.WollokInterpreter
import org.uqbar.project.wollok.interpreter.WollokREPLInterpreterEvaluator
import org.uqbar.project.wollok.interpreter.WollokREPLInterpreter

/**
 * @author tesonep
 */
class WollokLauncherSetup extends WollokDslStandaloneSetup {

	val WollokLauncherParameters params 

	new(WollokLauncherParameters params) {
		this.params = params
	}
	
	new(){
		this.params = new WollokLauncherParameters
	}

	override createInjector() {
		return Guice.createInjector(new WollokLauncherModule(params), this);
	}

	override configure(Binder binder) {
		super.configure(binder)
		binder.bind(WollokLauncherParameters).toInstance(params)

		if(params.hasRepl){
			binder.bind(WollokInterpreter).to(WollokREPLInterpreter)
		}
		
		// for testing refactors
		binder.bind(Lexer).annotatedWith(Names.named(LexerUIBindings.HIGHLIGHTING)).to(InternalWollokDslLexer)
	}
	
}
