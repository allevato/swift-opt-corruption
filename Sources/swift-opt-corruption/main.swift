import SwiftSyntax

enum Token {
  case syntax(String)
  case open
  case close
  case contextualBreakingStart
  case contextualBreakingEnd
}

final class TokenStreamCreator: SyntaxVisitor {
  private var tokens = [Token]()
  private var beforeMap = [TokenSyntax: [Token]]()
  private var afterMap = [TokenSyntax: [[Token]]]()
  private var preVisitedExprs = [ExprSyntax]()

  func makeStream(from node: Syntax) -> [Token] {
    self.walk(node)
    return tokens
  }

  func before(_ token: TokenSyntax?, tokens: Token...) {
    before(token, tokens: tokens)
  }

  func before(_ token: TokenSyntax?, tokens: [Token]) {
    guard let tok = token else { return }
    beforeMap[tok, default: []] += tokens
  }

  func after(_ token: TokenSyntax?, tokens: Token...) {
    after(token, tokens: tokens)
  }

  func after(_ token: TokenSyntax?, tokens: [Token]) {
    guard let tok = token else { return }
    afterMap[tok, default: []].append(tokens)
  }

  override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    preVisitInsertingContextualBreaks(node)
    return .visitChildren
  }

  override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
    if let before = beforeMap[token] {
      before.forEach(appendToken)
    }

    appendToken(.syntax(token.text))

    let afterGroups = afterMap[token] ?? []
    for after in afterGroups.reversed() {
      after.forEach(appendToken)
    }
    return .skipChildren
  }

  private func appendToken(_ token: Token) {
    // Print the tokens as they are appended so that we can see the corruption.
    print("+ Token.\(token)")
    tokens.append(token)
  }

  private func preVisitInsertingContextualBreaks<T: ExprSyntaxProtocol & Equatable>(_ expr: T) {
    if !hasPreVisited(expr) {
      let (visited, _, _) = insertContextualBreaks(ExprSyntax(expr), isTopLevel: true)
      preVisitedExprs.append(contentsOf: visited)
    }
  }

  private func hasPreVisited<T: ExprSyntaxProtocol & Equatable>(_ expr: T) -> Bool {
    for item in preVisitedExprs {
      if item == ExprSyntax(expr) { return true }
    }
    return false
  }

  private func insertContextualBreaks(_ expr: ExprSyntax, isTopLevel: Bool) -> (
    [ExprSyntax], hasCompoundExpression: Bool, hasMemberAccess: Bool
  ) {
    if let callingExpr = expr.as(FunctionCallExprSyntax.self) {
      let calledExpression = callingExpr.calledExpression
      let (children, hasCompoundExpression, hasMemberAccess) =
        insertContextualBreaks(calledExpression, isTopLevel: false)

      // ******
      // BUG IS HERE
      // ******
      // The bug will go away if you do either of the following:
      //
      // 1. Uncomment the `print` statement after `let beforeTokens: ...`.
      // 2. Comment out the following three `let` statements and uncomment the alternative set
      //    below.

      let shouldGroup = hasMemberAccess && (hasCompoundExpression || !isTopLevel)

      let beforeTokens: [Token] =
        shouldGroup ? [.contextualBreakingStart, .open] : [.contextualBreakingStart]
      // ******
      // Uncomment this line and the bug goes away. This only works if it is *immediately after* the
      // the assignment to `beforeTokens`. If it is moved below, to `afterTokens`, the bug manifests
      // differently.
      //
      // print(beforeTokens)

      let afterTokens: [Token] =
        shouldGroup ? [.contextualBreakingEnd, .close] : [.contextualBreakingEnd]

      // ******
      // Alternatively, comment out the three statements above and uncomment these two, and the bug
      // goes away.
      //
      // let beforeTokens: [Token] = [.contextualBreakingStart]
      // let afterTokens: [Token] = [.contextualBreakingEnd]

      before(expr.firstToken, tokens: beforeTokens)
      after(expr.lastToken, tokens: afterTokens)
      return ([expr] + children, true, hasMemberAccess)
    }

    before(expr.firstToken, tokens: .contextualBreakingStart)
    after(expr.lastToken, tokens: .contextualBreakingEnd)
    let hasCompoundExpression = !expr.is(IdentifierExprSyntax.self)
    return ([expr], hasCompoundExpression, false)
  }
}

let source = "P()"
let node = try! SyntaxParser.parse(source: source)
print(TokenStreamCreator().makeStream(from: Syntax(node)))
