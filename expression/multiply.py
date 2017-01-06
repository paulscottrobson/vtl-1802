# 1. Clear result High word (Bytes 2 and 3) 
# 2. Load Loop counter with 16. 
# 3. Shift multiplier right 
# 4.  If  carry  (previous  bit  0  of  multiplier  Low  byte)  set,  add  multiplicand  to  result  High  word. 
# 5. Shift right result High word into result Low word/multiplier. 
# 6. Shift right Low word/multiplier. 
# 7. Decrement Loop counter. 
# 8. If Loop counter not zero, go to Step 4. 

#
#	Heavily rewritten !
#
import random

class Multiplier:
	def __init__(self):
		random.seed(42)

	def multiply(self,m1,m2):
		result = 0 														# step 1. clear result

		for i in range(0,16):
			carry = m1 & 1 												# step 3. shift multiplier right
			m1 = m1 >> 1

			if carry != 0:												# if carry set, add multiplicand to result
				result = result + m2
			result = (result >> 1) | ((result & 1) << 15) 				# rotate result right.

		self.result = result

	def checkMultiply(self,m1,m2):
		self.multiply(m1,m2)
		result = (m1 * m2) & 0xFFFF
		#print("{0} x {1} = {2} ({3})".format(m1,m2,self.result,result))
		errorMsg = "{0} * {1}".format(m1,m2)		
		assert result == self.result,errorMsg

	def checkRandom(self):
		ok = False
		while not ok:
			r1 = random.randint(0,65535)
			r2 = random.randint(0,65535)
			if random.randint(0,1) == 0:
				r1 = int(r1 / 1000)
			if random.randint(0,1) == 0:
				r2 = int(r2 / 1000)
			ok = (r1 * r2) <= 65535
		self.checkMultiply(r1,r2)

d = Multiplier()
d.checkMultiply(133,8)
d.checkMultiply(44,328)
d.checkMultiply(0,12)
d.checkMultiply(123,0)
for i in range(0,1000*1000*10):
	if i % 10000 == 0:
		print("Done ",i)
	d.checkRandom()