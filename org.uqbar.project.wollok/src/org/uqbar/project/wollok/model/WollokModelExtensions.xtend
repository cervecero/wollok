package org.uqbar.project.wollok.model

import java.util.List
import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.nodemodel.INode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.resource.XtextResource
import org.uqbar.project.wollok.WollokConstants
import org.uqbar.project.wollok.interpreter.WollokClassFinder
import org.uqbar.project.wollok.interpreter.WollokRuntimeException
import org.uqbar.project.wollok.interpreter.core.WollokObject
import org.uqbar.project.wollok.scoping.WollokGlobalScopeProvider
import org.uqbar.project.wollok.visitors.ParameterUsesVisitor
import org.uqbar.project.wollok.visitors.VariableAssignmentsVisitor
import org.uqbar.project.wollok.visitors.VariableUsesVisitor
import org.uqbar.project.wollok.wollokDsl.Import
import org.uqbar.project.wollok.wollokDsl.WAssignment
import org.uqbar.project.wollok.wollokDsl.WBinaryOperation
import org.uqbar.project.wollok.wollokDsl.WBlockExpression
import org.uqbar.project.wollok.wollokDsl.WBooleanLiteral
import org.uqbar.project.wollok.wollokDsl.WCatch
import org.uqbar.project.wollok.wollokDsl.WClass
import org.uqbar.project.wollok.wollokDsl.WClosure
import org.uqbar.project.wollok.wollokDsl.WCollectionLiteral
import org.uqbar.project.wollok.wollokDsl.WConstructor
import org.uqbar.project.wollok.wollokDsl.WConstructorCall
import org.uqbar.project.wollok.wollokDsl.WExpression
import org.uqbar.project.wollok.wollokDsl.WFeatureCall
import org.uqbar.project.wollok.wollokDsl.WFile
import org.uqbar.project.wollok.wollokDsl.WFixture
import org.uqbar.project.wollok.wollokDsl.WIfExpression
import org.uqbar.project.wollok.wollokDsl.WMemberFeatureCall
import org.uqbar.project.wollok.wollokDsl.WMethodContainer
import org.uqbar.project.wollok.wollokDsl.WMethodDeclaration
import org.uqbar.project.wollok.wollokDsl.WMixin
import org.uqbar.project.wollok.wollokDsl.WNamed
import org.uqbar.project.wollok.wollokDsl.WNamedObject
import org.uqbar.project.wollok.wollokDsl.WNullLiteral
import org.uqbar.project.wollok.wollokDsl.WNumberLiteral
import org.uqbar.project.wollok.wollokDsl.WObjectLiteral
import org.uqbar.project.wollok.wollokDsl.WPackage
import org.uqbar.project.wollok.wollokDsl.WParameter
import org.uqbar.project.wollok.wollokDsl.WProgram
import org.uqbar.project.wollok.wollokDsl.WReferenciable
import org.uqbar.project.wollok.wollokDsl.WReturnExpression
import org.uqbar.project.wollok.wollokDsl.WSelf
import org.uqbar.project.wollok.wollokDsl.WSelfDelegatingConstructorCall
import org.uqbar.project.wollok.wollokDsl.WStringLiteral
import org.uqbar.project.wollok.wollokDsl.WSuite
import org.uqbar.project.wollok.wollokDsl.WSuperDelegatingConstructorCall
import org.uqbar.project.wollok.wollokDsl.WSuperInvocation
import org.uqbar.project.wollok.wollokDsl.WTest
import org.uqbar.project.wollok.wollokDsl.WThrow
import org.uqbar.project.wollok.wollokDsl.WTry
import org.uqbar.project.wollok.wollokDsl.WUnaryOperation
import org.uqbar.project.wollok.wollokDsl.WVariable
import org.uqbar.project.wollok.wollokDsl.WVariableDeclaration
import org.uqbar.project.wollok.wollokDsl.WVariableReference
import org.uqbar.project.wollok.wollokDsl.WollokDslPackage
import wollok.lang.Exception

import static org.uqbar.project.wollok.scoping.root.WollokRootLocator.*

import static extension org.uqbar.project.wollok.model.WMethodContainerExtensions.*
import static extension org.uqbar.project.wollok.utils.XTextExtensions.*

/**
 * Extension methods to Wollok semantic model.
 *
 * @author jfernandes
 * @author npasserini
 * @author tesonep
 */
class WollokModelExtensions {

	def static implicitPackage(EObject it) {
		file.implicitPackage
	}
	
	def static implicitPackage(Resource it){
		if (it === null || it.URI === null || it.URI.toString === null) {
			return null
		}
		if (URI.toString.startsWith("classpath:/"))
			URI.trimFileExtension.segments.join(".")
		else
			fullPackageName(it)
	}
	
	def static file(EObject it) { eResource }

	def static boolean isException(WClass it) { fqn == Exception.name || (parent !== null && parent.exception) }

	def static dispatch name(EObject it) { null }
	def static dispatch name(WNamed it) { name }
	def static dispatch name(WObjectLiteral it) { "anonymousObject" }
	def static dispatch name(WSuite it) { name }

	def static dispatch fqn(WClass it) { nameWithPackage }
	def static dispatch fqn(WNamedObject it) { nameWithPackage }
	def static dispatch fqn(WMixin it) { nameWithPackage }
	def static dispatch fqn(WSuite it) { nameWithPackage }

	/** 
	 * This method is intended to univocally identify every WMethodContainer
	 * (original requirement for static diagram), so it can be decoupled
	 * from <i>fqn</i>.
	 */
	def static dispatch identifier(EObject it) { name }
	def static dispatch identifier(WMethodContainer it) { 
		try {
			return fqn
		} catch (NullPointerException e) {
			// Yeah, shameful! But I must find a workaround while user is writing in Static Diagram
			return name
		}
	}
	
	def static getMethodContainer(EObject it){
		method.declaringContext
	}
	def static getPackageName(WMethodContainer it) { implicitPackage + if (package !== null) "." + package.name  else ""}
	def static getNameWithPackage(WMethodContainer it) {
		getPackageName + "." + name
	}

	def static dispatch fqn(WObjectLiteral it) {
		//TODO: make it better (show containing class /object / package + linenumber ?)
		implicitPackage + "." + "anonymousObject"
	}

	// this doesn't work for object literals, although it could !
	def static WPackage getPackage(WMethodContainer it) { if(eContainer instanceof WPackage) eContainer as WPackage else null }

	def static boolean isSuperTypeOf(WClass a, WClass b) {
		a.fqn == b.fqn || (b.parent !== null && a.isSuperTypeOf(b.parent))
	}

	// *******************
	// ** WReferenciable
	// *******************
	def static dispatch isModifiableFrom(WVariable v, WAssignment from) { v.declaration.writeable || from.initializesInstanceValueFromConstructor(v) }
	def static dispatch isModifiableFrom(WParameter v, WAssignment from) { false }
	def static dispatch isModifiableFrom(WReferenciable v, WAssignment from) { true }

	def static boolean initializesInstanceValueFromConstructor(WAssignment a, WVariable v) {
		v.declaration.right === null && a.isWithinConstructor
	}

	def static boolean isWithinConstructor(EObject e) {
		e.eContainer !== null && (e.eContainer.isAConstructor || e.eContainer.isWithinConstructor)
	}

	def static dispatch boolean isAConstructor(EObject it) { false }
	def static dispatch boolean isAConstructor(WConstructor it) { true }
	def static dispatch boolean isAConstructor(WFixture it) { true	}
	 
	/*
	 * Uses of a Variable
	 */
	def static uses(WVariable variable) { VariableUsesVisitor.usesOf(variable, variable.declarationContext) }
	
	def static isUsed(WParameter parameter) {
		!ParameterUsesVisitor.usesOf(parameter, parameter.declarationContext).isEmpty
	}

	def static assignments(WVariable variable) {
		VariableAssignmentsVisitor.assignmentOf(variable, variable.declarationContext)
	}

	def static declaration(WVariable variable) {
		variable.eContainer as WVariableDeclaration
	}

	def static dispatch declarationContext(WVariable variable) { variable.declaration.eContainer }
	def static dispatch declarationContext(WParameter parameter) { parameter.eContainer }

	// **********************
	// ** access containers
	// **********************

	def static WClass getWollokClass(EObject it) { EcoreUtil2.getContainerOfType(it, WClass) }

	def static dispatch WBlockExpression block(WBlockExpression b) { b }
	def static dispatch WBlockExpression block(EObject b) { b.eContainer.block }

	def static dispatch WExpression firstExpressionInContext(EObject e) {
		if (e.eContainer === null) return null 
		e.eContainer.firstExpressionInContext
	}
	def static dispatch WExpression firstExpressionInContext(WProgram p) { p.elements.head }
	def static dispatch WExpression firstExpressionInContext(WBlockExpression b) { b.expressions.head } 
	def static dispatch WExpression firstExpressionInContext(WTest t) {	t.elements.head	}
	
	def static first(WBlockExpression it, Class<?> type) { expressions.findFirst[ type.isInstance(it) ] }

	def static closure(WParameter p) { p.eContainer as WClosure }

	// ojo podría ser un !ObjectLiteral
	def static declaringContext(WMethodDeclaration m) {	m.eContainer as WMethodContainer } //

	def static dispatch constructorsFor(WSelfDelegatingConstructorCall dc, WClass c) {	c.constructors }
	def static dispatch constructorsFor(WSuperDelegatingConstructorCall dc, WClass c) { c.parent.constructors }
	
	def static dispatch constructorName(WConstructor c, WSelfDelegatingConstructorCall dc) {
		constructorName(c, "self")
	}
	
	def static dispatch constructorName(WConstructor c, WSuperDelegatingConstructorCall dc) {
		constructorName(c, "super")
	}
	
	def static constructorName(WConstructor c, String constructorCall) {
		(constructorCall ?: "constructor") + "(" + c.parameters.map [ name ].join(",") + ")"
	}
	
	def static constructorParameters(WClass c) {
		c.constructors.map[ constructorName("") ].join(", ")
	}
	
	def static methodName(WMethodDeclaration d) {
		d.declaringContext.name + "." + d.messageName
	}

	def static messageName(WMethodDeclaration d) {
		d.name + "(" + d.parameters.map[name].join(", ") + ")"
	}
	
	def static void addMembersTo(WMethodContainer cl, WollokObject wo) { cl.members.forEach[wo.addMember(it)] }

	// se puede ir ahora que esta bien la jerarquia de WReferenciable (?)
	def dispatch messagesSentTo(WVariable v) { v.allMessageSent }
	def dispatch messagesSentTo(WParameter p) { p.allMessageSent }

	def static Iterable<WMemberFeatureCall> allMessageSent(WReferenciable r) { r.eContainer.allMessageSentTo(r) + r.allMessagesToRefsWithSameNameAs}

	def static List<WMemberFeatureCall> allMessageSentTo(EObject context, WReferenciable ref) {
		context.allCalls.filter[c|c.isCallOnVariableRef && (c.memberCallTarget as WVariableReference).ref == ref].toList
	}

	// heuristic: add's messages sent to other parameters with the same name
	def static dispatch Iterable<WMemberFeatureCall> allMessagesToRefsWithSameNameAs(WParameter ref) {
		ref.declaringContext.methods.map[ parameters ].flatten.filter[ name == ref.name && it != ref ].map[ eContainer.allMessageSentTo(it) ].flatten
	}
	def static dispatch Iterable<WMemberFeatureCall> allMessagesToRefsWithSameNameAs(WReferenciable it) { #[] }

	def static allCalls(EObject context) { context.eAllContents.filter(WMemberFeatureCall) }

	def static isCallOnVariableRef(WMemberFeatureCall c) { c.memberCallTarget instanceof WVariableReference }

	def static isCallOnThis(WMemberFeatureCall c) { c.memberCallTarget instanceof WSelf }

	def static WMethodDeclaration resolveMethod(WMemberFeatureCall it, WollokClassFinder finder) {
		if (isCallOnThis)
			method.declaringContext.findMethod(it)
		else if (isCallToWellKnownObject)
			resolveWKO(finder).findMethod(it)
		else
		 // TODO: call to super (?)
		 	null
	}

	def static isCallToWellKnownObject(WMemberFeatureCall c) { c.memberCallTarget.isWellKnownObject	}

	def static dispatch boolean isWellKnownObject(EObject it) { false }
	def static dispatch boolean isWellKnownObject(WVariableReference it) { ref.isWellKnownObject }
	def static dispatch boolean isWellKnownObject(WNamedObject it) { true }
	def static dispatch boolean isWellKnownObject(WReferenciable it) { false }

	def static isValidCallToWKObject(WMemberFeatureCall it, WollokClassFinder finder) {
		resolveWKO(finder).isValidCall(it, finder)
	}

	def static resolveWKO(WMemberFeatureCall it, WollokClassFinder finder) {
		(memberCallTarget as WVariableReference).ref as WNamedObject
	}

	def static isValidMessage(WMethodDeclaration it, WMemberFeatureCall call) {
		matches(call.feature, call.memberCallArguments)
	}

	def static isValidConstructorCall(WConstructorCall c) {
		c.classRef.hasConstructorForArgs(c.numberOfParameters)
	}

	def static numberOfParameters(WConstructorCall c) { if(c.arguments === null) 0 else c.arguments.size }

	def static hasConstructorDefinitions(WClass c) { c.constructors !== null && c.constructors.size > 0 }

	def static hasConstructorForArgs(WClass c, int nrOfArgs) {
		(nrOfArgs == 0 && !c.hasConstructorDefinitions) || c.allConstructors.exists[matches(nrOfArgs)]
	}

	def static EList<WConstructor> allConstructors(WClass c) {
		if (c.hasConstructorDefinitions || c.parent === null) 
			c.constructors
		else
			c.parent.allConstructors
	}

	def static dispatch getConstructors(EObject o) { newArrayList }
	def static dispatch getConstructors(WClass c) { c.allConstructors }
	
	def static matches(WConstructor it, int nrOfArgs) {
		if (hasVarArgs)
			nrOfArgs >= parameters.filter[!isVarArg].size
		else
			nrOfArgs == parameters.size
	}

	def static dispatch hasVarArgs(WConstructor it) { parameters.exists[isVarArg] }
	def static dispatch hasVarArgs(WMethodDeclaration it) { parameters.exists[isVarArg] }

	def static superClassRequiresNonEmptyConstructor(WClass it) { parent !== null && !parent.hasEmptyConstructor }
	def static superClassRequiresNonEmptyConstructor(WNamedObject it) { parent !== null && !parent.hasEmptyConstructor }

	def static hasEmptyConstructor(WClass c) { !c.hasConstructorDefinitions || c.hasConstructorForArgs(0) }

	// For objects or classes
	def static declaredVariables(WMethodContainer obj) { obj.members.filter(WVariableDeclaration).map[variable] }

	def static dispatch WMethodDeclaration method(Void it) { null }
	def static dispatch WMethodDeclaration method(EObject it) { null }
	def static dispatch WMethodDeclaration method(WMethodDeclaration it) { it }
	def static dispatch WMethodDeclaration method(WExpression it) {	eContainer.method }
	def static dispatch WMethodDeclaration method(WParameter it) { eContainer.method }

	def static isInMixin(EObject e) { e.declaringContext instanceof WMixin }

	// ****************************
	// ** transparent containers (in terms of debugging -maybe also could be used for visualizing, like outline?-)
	// ****************************
	// containers
	def static dispatch isTransparent(EObject o) { false }
	def static dispatch isTransparent(WTry o) { true }
	def static dispatch isTransparent(WBlockExpression o) { true }
	def static dispatch isTransparent(WIfExpression o) { true }
	// literals or leafs
	def static dispatch isTransparent(WSelf o) { true }
	def static dispatch isTransparent(WNumberLiteral o) { true }
	def static dispatch isTransparent(WStringLiteral o) { true }
	def static dispatch isTransparent(WBooleanLiteral o) { true }
	
	def static dispatch isTransparent(WObjectLiteral o) { true }
	def static dispatch isTransparent(WNamedObject o) { true }
	
	def static dispatch isTransparent(WCollectionLiteral o) { true }
	def static dispatch isTransparent(WVariableReference o) { true }
	def static dispatch isTransparent(WBinaryOperation o) { true }

	def static IFile getIFile(EObject obj) {
		val platformString = obj.eResource.URI.toPlatformString(true)
		if (platformString === null) {
			// could be a synthetic file
			return null;
		}
		ResourcesPlugin.workspace.root.getFile(new Path(platformString))
	}

	// ******************************
	// ** is duplicated impl
	// ******************************

	def static boolean isDuplicated(WReferenciable reference) {
		reference.eContainer.isDuplicated(reference)
	}

	// Root objects (que no tiene acceso a variables fuera de ellos)
	def static dispatch boolean isDuplicated(WFile f, WNamedObject o) { f.elements.existsMoreThanOne(o) }
	def static dispatch boolean isDuplicated(WFile f, WClass c) { f.elements.existsMoreThanOne(c) }

	def static dispatch boolean isDuplicated(WProgram p, WReferenciable v) {  p.variables.existsMoreThanOne(v) }
	def static dispatch boolean isDuplicated(WPackage it, WNamedObject r) { namedObjects.existsMoreThanOne(r) }
	def static dispatch boolean isDuplicated(WTest p, WReferenciable v) { p.variables.existsMoreThanOne(v) }
	def static dispatch boolean isDuplicated(WSuite p, WReferenciable v) {
		p.tests.exists [ (it.variables + p.variables).existsMoreThanOne(v) ]
	}

	// classes, objects and mixins
	def static dispatch boolean isDuplicated(WMethodContainer c, WReferenciable v) { c.variables.existsMoreThanOne(v) }

	def static dispatch boolean isDuplicated(WMethodDeclaration it, WReferenciable v) { parameters.existsMoreThanOne(v) || declaringContext.isDuplicated(v) }
	def static dispatch boolean isDuplicated(WBlockExpression it, WReferenciable v) { expressions.existsMoreThanOne(v) || eContainer.isDuplicated(v) }
	def static dispatch boolean isDuplicated(WClosure it, WReferenciable r) { parameters.existsMoreThanOne(r) || eContainer.isDuplicated(r) }
	def static dispatch boolean isDuplicated(WConstructor it, WReferenciable r) { parameters.existsMoreThanOne(r) || eContainer.isDuplicated(r) }
	// default case is to delegate up to container
	def static dispatch boolean isDuplicated(EObject it, WReferenciable r) { eContainer.isDuplicated(r) }

	def static dispatch existsMoreThanOne(Iterable<?> exps, WReferenciable ref) {
		exps.filter(WReferenciable).exists[it != ref && name == ref.name]
	}

	def static dispatch existsMoreThanOne(Iterable<?> exps, WNamed named) {
		exps.filter(WReferenciable).exists[it != named && name == named.name]
	}

	def static dispatch boolean isInConstructor(EObject obj) { obj.eContainer !== null && obj.eContainer.inConstructor }
	def static dispatch boolean isInConstructor(WConstructor obj) { true }
	def static dispatch boolean isInConstructor(WClass obj){ false }
	def static dispatch boolean isInConstructor(WMethodDeclaration obj) { false }

	def static dispatch boolean isInConstructorBody(EObject obj) { obj.eContainer !== null && obj.eContainer.isInConstructorBody }
	def static dispatch boolean isInConstructorBody(WBlockExpression obj) { obj.isInConstructor }

	// *****************************
	// ** valid return
	// *****************************


	def static dispatch boolean returnsOnAllPossibleFlows(WMethodDeclaration it, boolean returnsOnSuperExpression) { expressionReturns || expression.returnsOnAllPossibleFlows(returnsOnSuperExpression) }
	def static dispatch boolean returnsOnAllPossibleFlows(WReturnExpression it, boolean returnsOnSuperExpression) { true }
	def static dispatch boolean returnsOnAllPossibleFlows(WThrow it, boolean returnsOnSuperExpression) { returnsOnSuperExpression }
	def static dispatch boolean returnsOnAllPossibleFlows(WBlockExpression it, boolean returnsOnSuperExpression) { expressions.last.returnsOnAllPossibleFlows(returnsOnSuperExpression) }
	def static dispatch boolean returnsOnAllPossibleFlows(WIfExpression it, boolean returnsOnSuperExpression) { then.returnsOnAllPossibleFlows(returnsOnSuperExpression) && ^else !== null && ^else.returnsOnAllPossibleFlows(returnsOnSuperExpression) }
	def static dispatch boolean returnsOnAllPossibleFlows(WTry it, boolean returnsOnSuperExpression) { expression.returnsOnAllPossibleFlows(returnsOnSuperExpression) && catchBlocks.forall[c | c.returnsOnAllPossibleFlows(returnsOnSuperExpression) ] }
	def static dispatch boolean returnsOnAllPossibleFlows(WCatch it, boolean returnsOnSuperExpression) { expression.returnsOnAllPossibleFlows(returnsOnSuperExpression) }
	def static dispatch boolean returnsOnAllPossibleFlows(Void it, boolean returnsOnSuperExpression) { false } // ?
	def static dispatch boolean returnsOnAllPossibleFlows(WExpression it, boolean returnsOnSuperExpression) { false }


	def static tri(WCatch it) { eContainer as WTry }
	def static catchesBefore(WCatch it) { tri.catchBlocks.subList(0, tri.catchBlocks.indexOf(it)) }

	// *******************************
	// ** Boolean evaluation
	// *******************************
	
	def static dispatch isBooleanOrUnknownType(EObject it) { true }
	def static dispatch isBooleanOrUnknownType(WBooleanLiteral it) { true }
	def static dispatch isBooleanOrUnknownType(WNullLiteral it) { false }
	def static dispatch isBooleanOrUnknownType(WNumberLiteral it) { false }
	def static dispatch isBooleanOrUnknownType(WStringLiteral it) { false }
	def static dispatch isBooleanOrUnknownType(WConstructorCall it) { false }
	def static dispatch isBooleanOrUnknownType(WCollectionLiteral it) { false }
	def static dispatch isBooleanOrUnknownType(WObjectLiteral it) { false }
	def static dispatch isBooleanOrUnknownType(WClosure it) { false }
	def static dispatch isBooleanOrUnknownType(WUnaryOperation it) { isNotOperation }
	def static dispatch isBooleanOrUnknownType(WVariableReference it) { !(ref instanceof WNamedObject) }
	
	def static isBooleanExpression(WBinaryOperation it) { feature.isBooleanOperand }
	def static isBooleanOperand(String it) { WollokConstants.OP_BOOLEAN.contains(it) }

	def static isAndExpression(WBinaryOperation it) { WollokConstants.OP_BOOLEAN_AND.contains(feature) }
	def static isOrExpression(WBinaryOperation it) { WollokConstants.OP_BOOLEAN_OR.contains(feature) }
	def static isNotOperation(WUnaryOperation it) { WollokConstants.OP_UNARY_BOOLEAN.contains(feature) }

	// *******************************
	// ** variables
	// *******************************
	
	def static isLocalToMethod(WVariableDeclaration it) { EcoreUtil2.getContainerOfType(it, WMethodDeclaration) !== null }

	def static onlyUsedInReturn(WVariableDeclaration it) {
		val visitor = new VariableUsesVisitor
		visitor.lookedFor = variable
		visitor.visit(EcoreUtil2.getContainerOfType(it, WMethodDeclaration))
		visitor.uses.length == 1 && visitor.uses.get(0).isReturnOrInReturn
	}
	
	def static boolean isReturnOrInReturn(EObject e) { e instanceof WReturnExpression || e.isInReturn }
	def static boolean isInReturn(EObject e) { e.eContainer !== null && e.eContainer.isReturnOrInReturn }

	// *******************************
	// ** imports
	// *******************************

	def static importedNamespaceWithoutWildcard(Import it) { if (importedNamespace.endsWith(".*")) importedNamespace.substring(0, importedNamespace.length - 2) else importedNamespace }
	def static toFQN(String string) { QualifiedName.create(string.split("\\.")) }
	// hack uses another grammar ereference to any
	def static getScope(Import it, WollokGlobalScopeProvider scopeProvider) { scopeProvider.getScope(eResource, WollokDslPackage.Literals.WCLASS__PARENT) }
	def static upTo(Import it, String segment) { importedNamespace.substring(0, importedNamespace.indexOf(segment) + segment.length) }
	
	/**
	 * Returns all the imports in the context.
	 **/
	def static Iterable<Import> allImports(EObject e){
		synchronized (e) {
			val locals = e.eContents.filter(Import)
			if(e.eContainer !== null) e.eContainer.allImports() + locals else locals
		} 
	}
	
	// unused
	def static Iterable<String> allFQNImports(EObject e){
		synchronized (e) {
			val constructors = e.eAllContents.filter(WConstructorCall).toSet
			constructors
				.map[ NodeModelUtils.findNodesForFeature(it,WollokDslPackage.Literals.WCONSTRUCTOR_CALL__CLASS_REF)	]
				.flatten
				.map[NodeModelUtils.getTokenText(it)]
				.filter[it.contains(".")].toSet
			
			#{}
		}
	}
	
	// *******************************
	// ** refactoring
	// *******************************
	def static dispatch List<String> semanticElementsAllowedToRefactor(EObject e) { #[e.class.name] }
	def static dispatch List<String> semanticElementsAllowedToRefactor(WNamedObject e) { #["WNamedObject", "WVariableReference"] }
	def static dispatch List<String> semanticElementsAllowedToRefactor(WClass e) { #["WClass", "WVariableReference"] }
	def static dispatch List<String> semanticElementsAllowedToRefactor(WVariable v) { #["WVariable", "WVariableReference", "WVariableDeclaration"] }
	def static dispatch List<String> semanticElementsAllowedToRefactor(WParameter p) { #["WParameter", "WVariableReference"] }

	def static dispatch boolean doApplyRenameTo(EObject e, EObject e2) { true }
	def static dispatch boolean doApplyRenameTo(WVariable v, WVariableReference reference) {
		reference.ref.equals(v)	
	}
	
	def static boolean applyRenameTo(EObject e, INode node) {
		val semanticsElements = e.semanticElementsAllowedToRefactor
		val rootNodeName = e.name.trim
		node.text.trim.equals(rootNodeName) && semanticsElements.contains(node.semanticElement.eClass.name) && doApplyRenameTo(e, node.semanticElement)
	}
	
	def static dispatch expectsExpression(EObject e) { false }
	def static dispatch expectsExpression(WBinaryOperation op) { true }
	def static dispatch expectsExpression(WUnaryOperation op) { true }
	def static dispatch expectsExpression(WReturnExpression r) { true }
	def static dispatch expectsExpression(WVariableDeclaration v) { true }
	def static dispatch expectsExpression(WMemberFeatureCall c) { true }
	
	def static redefinesSendingOnlySuper(WMethodDeclaration m) {
		val methodBody = m.expression.eContents
	 	m.overridenMethod !== null && ((methodBody.size == 1 && methodBody.head.callsToSuperWith(m)) || m.expression.callsToSuperWith(m))
	}
	
	def static dispatch boolean callsToSuperWith(EObject e, WMethodDeclaration m) {	false }
	def static dispatch boolean callsToSuperWith(WSuperInvocation s, WMethodDeclaration m) {
		val methodParamsSize = m.parameters.size
		if (methodParamsSize != s.memberCallArguments.size) return false;
		if (methodParamsSize == 0 && s.memberCallArguments.size == 0) return true;
		(0..methodParamsSize - 1).forall [ i |
			m.parameters.get(i).matchesParam(s.memberCallArguments.get(i))
		]
	}
	
	def static dispatch boolean callsToSuperWith(WReturnExpression ret, WMethodDeclaration m) {
		ret.expression.callsToSuperWith(m)
	}
	
	def static dispatch matchesParam(WParameter p, EObject e) { false }
	def static dispatch matchesParam(WParameter p, WVariableReference ref) { p === ref.getRef }
	def static dispatch matchesParam(WParameter p, WParameter p2) { p === p2 }
	
	def static <T extends EObject> Iterable<T> getAllOfType(XtextResource it, Class<T> type) {
		if (contents.empty) #[]
		else (contents.get(0) as WFile).eAllContents.filter(type).toList
	}

	def static getAllElements(XtextResource it) { getAllOfType(WMethodContainer) }
	def static getMixins(XtextResource it) { getAllOfType(WMixin) }
	def static getClasses(XtextResource it) { getAllOfType(WClass) }
	def static getNamedObjects(XtextResource it) { getAllOfType(WNamedObject) }

	def static getImportedClasses(XtextResource it, WollokClassFinder finder) {
		val imports = getAllOfType(Import)
		imports.fold(newArrayList)[l, i |
			try {
				l.add(finder.getCachedClass(i, i.importedNamespace))
			}
			catch(ClassCastException e) {
				// Temporarily user is writing another import
			}
			catch(WollokRuntimeException e) { }
			l
		]
	}
	
	def static fullMessage(String methodName, int argumentsSize) {
		var args = ""
		val argsSize = argumentsSize
		if (argsSize > 0) {
			args = (1..argsSize).map [ "param" + it ].join(', ')
		}
		methodName + "(" + args + ")"
	}
	
	def static fullMessage(WFeatureCall call) {
		'''«call.feature»(«call.memberCallArguments.map[sourceCode].join(', ')»)'''
	}

	// ************************************************************************
	// ** Compound assignments (+=, -=, *=, /=)
	// ************************************************************************
	
	public static def isMultiOpAssignment(WBinaryOperation it) { feature.isMultiOpAssignment }
	public static def isMultiOpAssignment(String operator) { operator.matches(WollokConstants.MULTIOPS_REGEXP) }
	
	public static def operator(WBinaryOperation it) { 
		if (isMultiOpAssignment) feature.substring(0, 1)
		else throw new UnsupportedOperationException("Binary operation is not a compound assignment.")
	}
	
	def static dispatch isASuite(EObject o) { false }
	def static dispatch isASuite(WFile it) { tests.empty && suite !== null }
}
