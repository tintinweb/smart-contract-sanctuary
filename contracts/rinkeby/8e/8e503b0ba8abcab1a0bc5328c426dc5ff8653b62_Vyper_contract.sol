primes: public(uint256)
s: public(HashMap[uint256, uint256])

@external
def n_primes (num : uint256):
	p: uint256 = 1
	i: uint256 = 3
	c: uint256 = 0

	for y in range(8000):
		if p < num:
			for z in range(150):
				if self.s[c] != 0 and i % self.s[c] != 0 and self.s[c] * self.s[c] <= i:
					c += 1
				else:
					break
			
			if i % self.s[c] != 0:
				self.s[p] = i
				p += 1

			c = 0

			i += 2
		else:
			break
    
	if num <= 1:
		self.primes = 2
	else:
		self.primes = i - 2