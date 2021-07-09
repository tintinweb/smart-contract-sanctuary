primes: public(uint256)

@external
def n_primes (num : uint256):
	p: uint256 = 1
	i: uint256 = 3
	x: uint256 = 3

	for y in range(8000):
		if p < num:
			for z in range(150):
				if i % x != 0 and x * x <= i:
					x += 2
				else:
					break
			
			if i % x != 0 or i == 3:
				p += 1

			x = 3

			i += 2
		else:
			break

    
	if num <= 1:
		self.primes = 2
	else:
		self.primes = i - 2