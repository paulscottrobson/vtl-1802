#
# 1. Clear remainder and carry. 
# 2. Load Loop counter with 17. 
# 3. Shift left dividend into carry  
# 4. Decrement Loop counter. 
# 5. If Loop counter = 0, return. 
# 6. Shift left carry (from dividend/result) into remainder 
# 7. Subtract divisor from remainder. 
# 8. If result negative, add back divisor, clear carry and go to Step 3. 
# 9. Set carry and go to Step 3. 
#
import random

class Divider:
	def __init__(self):
		random.seed(42)

	def divide(self,dividend,divisor):
		remainder = 0 													# step 1. Clear remainder/carry
		carry = 0		

		loopCounter = 17 												# step 2. LoopCtr := 17

		while True:														# step 3. Main Loop
			dividend = (dividend << 1) | carry 							# shift left dividend into carry
			carry = (dividend >> 16) 									# (shifting carry in)
			dividend = dividend & 0xFFFF

			loopCounter = loopCounter - 1 								# step 4. Decrement loop counter
			if loopCounter == 0: 										# step 5. exit loop is loopcounter zero
				break

			remainder = (remainder << 1) | carry 						# step 6. shift left carry into remainder


			if remainder >= divisor:									# step 8. if result < 0
				remainder = remainder - divisor 						# add back divisor
				carry = 1												# set carry
			else:
				carry = 0 												# clear carry and loop

		self.remainder = remainder
		self.result = dividend

	def checkDivide(self,dividend,divisor):
		self.divide(dividend,divisor)
		# print("{0}/{1} = {2} r {3}".format(dividend,divisor,self.result,self.remainder))
		result = int(dividend/divisor) if divisor != 0 else 0xFFFF
		remainder = dividend % divisor if divisor != 0 else dividend

		errorMsg = "{0} / {1}".format(dividend,divisor)		
		assert result == self.result and remainder == self.remainder,errorMsg

	def checkRandom(self):
		r1 = random.randint(0,65535)
		if random.randint(0,3) > 0:
			r1 = r1 % 333
		self.checkDivide(random.randint(0,65535),r1)

d = Divider()
d.checkDivide(133,8)
d.checkDivide(44133,32888)
d.checkDivide(0,12)
d.checkDivide(123,0)
for i in range(0,1000*1000*10):
	if i % 100000 == 0:
		print("Done ",i)
	d.checkRandom()
