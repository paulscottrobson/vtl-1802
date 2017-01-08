#
#	Expression Evaluator - non recursive stack based left to right expression evaluator.
#
#	
import re

class Evaluator:
	def __init__(self,expression,result = None):
		self.stack = [ ] 																# calculation stack
		self.parenthesisDepth = 0 														# parenthesis count.
		self.expression = expression.replace(" ","").lower()+")" 						# expression, add ending parenthesis
		self.completed = False 															# true when completed.
		self.newExpression() 															# push 0+ onto stack.
		while not self.completed:

			done = False 																# do .... while self.getTerm()
			while not done: 															# keeps looping while open parenthesis
				done = not self.getTerm() 												

			done = False 																# do ... while self.nextOperator()
			while not done:  															# keep looping while close parenthesis
				self.completePendingArithmetic()
				done = not self.nextOperator()

		self.debug() 																	# show stack
		if result is not None: 															# validate result.
			assert result == self.stack[0]
			assert len(self.stack) == 1

	def debug(self):
		print(self.stack,'"'+self.expression+'"',self.parenthesisDepth)

	def newExpression(self,operator = '+'):
		self.stack.append(0)															# start a new evaluate, 0+
		self.stack.append(operator)

	def getTerm(self):
		parenthesis = False
		if self.expression[0] == '(':													# Parenthesis here
			self.newExpression() 														# start a new expression.
			self.expression = self.expression[1:] 										# lose (
			self.parenthesisDepth += 1 											 		# bump parenthesis counter.
			parenthesis = True															# causes get a new term.

		elif self.expression[0] == ':':													# :<expr>) array element.
			self.newExpression('@')
			self.expression = self.expression[1:] 										# lose (
			self.parenthesisDepth += 1 											 		# bump parenthesis counter.
			parenthesis = True															# causes get a new term.

		else:
			m = re.match("^(\\d+)(.*)$",self.expression) 								# rip digits out.
			assert m is not None,"Bad expression "+self.expression
			self.nextTerm = int(m.group(1))												# save term.
			self.expression = m.group(2)												# remainder of expression.

		return parenthesis 																# true if was open brackets.

	def completePendingArithmetic(self):
		if self.stack[-1] == '+': 														# do the appropriate sum.
			self.stack[-2] = self.stack[-2] + self.nextTerm
		elif self.stack[-1] == '-': 							
			self.stack[-2] = self.stack[-2] - self.nextTerm
		elif self.stack[-1] == '*': 							
			self.stack[-2] = self.stack[-2] * self.nextTerm
		elif self.stack[-1] == '/': 							
			self.stack[-2] = self.stack[-2] / self.nextTerm
		elif self.stack[-1] == '@': 													# array operator.			
			self.stack[-2] = 100000 + self.nextTerm 									# <a> @ <b> = memory[b]
		else:
			assert False,self.stack
		self.stack = self.stack[0:-1]													# remove top of stack operator.

	def nextOperator(self):
		unstacking = False 																# true if closing parenthesis

		if "+-*/@".find(self.expression[0]) >= 0:										# known operator.
			self.stack.append(self.expression[0])										# push it on the stack
			self.expression = self.expression[1:]										# remove from input
		elif self.expression[0] == ')':													# close bracket.
			if self.parenthesisDepth > 0: 												# check and decrement parenthesis count
				self.parenthesisDepth -= 1
				self.expression = self.expression[1:] 									# remove bracket
				self.nextTerm = self.stack[-1] 											# pop next term off top of stack.
				self.stack = self.stack[0:-1]
				unstacking = True
			else:
				self.completed = True
		else: 																			# done
			assert self.expression != "","Unclosed parenthesis" 						# check all brackets closed.
			self.completed = True
		return unstacking

n = Evaluator(":2+(4*2))")
n = Evaluator(":0-1)")
if True:
	n = Evaluator("42-(2*(7-3))",34)
	n = Evaluator("2*((2+3)*(4+5))*2",180)
	n = Evaluator("1+(2*3)",7)
	n = Evaluator("1+2*3",9)
	n = Evaluator("1+(2*3)*4",28)
	n = Evaluator("(1-2)*(4+3)*5",-35)
	n = Evaluator("((1+2)*3)+4",13)
	n = Evaluator("2+(2)",4)
