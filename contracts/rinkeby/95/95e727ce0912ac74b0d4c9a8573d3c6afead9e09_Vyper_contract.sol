mag: public(uint256[49])

@external
def magic_square (num : uint256):
    a: uint256[49] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    b: uint256[49] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    used: uint256[9] = [0,0,0,0,0,0,0,0,0]
    use: uint256[9] = [0,0,0,0,0,0,0,0,0]
    m: uint256[49] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    i: uint256 = 0
    j: uint256 = 0
    s: uint256 = 0
    k: uint256 = 0
    t: uint256 = 0
    p: uint256 = 0
    back: bool = False
    b_o: uint256 = 0

    t = (num - 1) / 2
    k = num - 1
    
    for x in range(8):
        if i < num:
        	if num % 2 == 0:
        		t = i

        	s = i * num + j
        	p = i * num + k
        	a[s] = t
        	b[p] = t
        	i = i + 1
        	j = j + 1
        	if k > 0:
        		k = k - 1
        else:
            break

    i = num - 1
    j = 0
    p = 0
    k = 0
    t = (num - 1) / 2

    if num % 2 == 1:
    	used[t] = 1
    	m[t * num + t] = 1

    for z in range(8):
    	if j < num:
	    	if i == j and num != 1:
	    		if i > 0:	
	    			i = i - 1
	    		j = j + 1
	    		p = p + 1

	    	s = i * num + j

	    	if num % 2 == 1:
	    		for y in range(8):
	    			if used[k] == 1:
	    				k = k + 1
	    			else:
	    				break
	    	else:
	    		for y in range(8):
	    			if used[k] == 1 or k == i or k == j:
	    				k = k + 1
	    			else:
	    				break

	    	a[s] = k
	    	used[k] = 1

	    	s = k * num + b[s]
	    	m[s] = 1

	    	s = p * num + j
	    	b[s] = k

	    	s = a[s] * num + k
	    	m[s] = 1

	    	if i > 0:
	    		i = i - 1
	    	j = j + 1
	    	p = p + 1
	    	k = 0
    	else:
    		break

    used = [0,0,0,0,0,0,0,0,0]
    i = 0
    j = 0
    k = 0


    self.mag = a