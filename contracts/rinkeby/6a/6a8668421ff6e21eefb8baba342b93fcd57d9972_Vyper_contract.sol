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

    for w in range(4000):
    	if i < num - 1 or j < num - 1:
    		t = i + j

    		if i == j or t == num - 1:
    			if back == False:
    				if j < num - 1:
    					j = j + 1
    				else:
    					i = i + 1
    					j = 0
    			else:
    				if j > 0:
    					j = j - 1
    				else:
    					i = i - 1
    					j = num - 1
    		else:
    			k = 0

    			for v in range(8):
    				if k < num:
    					if k != j:
    						s = i * num + k

    						if k < j or (i == k or i + k == num - 1):
    							p = a[s]
    							used[p] = 1
    							p = b[s]
    							use[p] = 1

    					if k != i:
    						s = k * num + j

    						if k < i or (k == j or k + j == num - 1):
    							p = a[s]
    							used[p] = 1
    							p = b[s]
    							use[p] = 1

    					k = k + 1
    				else:
    					break

    			if i == 1 and j == 0:
    				k = 0

    				if num % 2 == 0:
    					t = num / 2
    				else:
    					t = num - 1

    				for u in range(7):
    					if k < t:
    						used[k] = 1
    						k = k + 1
    					else:
    						break

    			if i == 1 and j == 2:
    				k = 0

    				t = num / 2 - 1

    				for uu in range(4):
    					if k < t:
    						use[k] = 1
    						k = k + 1
    					else:
    						break

    			if i == 1 and j == 3:
    				k = 0
    				t = 3

    				for uuu in range(4):
    					if k < t:
    						use[k] = 1
    						k = k + 1
    					else:
    						break

    			if back == True:
    				s = i * num + j
    				k = a[s]
    				t = b[s]
    				a[s] = num
    				b[s] = num

    				s = k * num + t
    				m[s] = 0

    				if b_o == 2:
    					k = k + 1
    					t = t + 1
    				else:
    					if b_o == 1:
    						k = k + 1
    						t = 0
    					else:
    						t = t + 1

    			else:
    				k = 0
    				t = 0
    				b_o = 0

    			for kk in range(8):
    				if used[k] == 1:
    					k = k + 1
    				else:
    					break

    			for tt in range(8):
    				if use[t] == 1:
    					t = t + 1
    				else:
    					break

    			if (k < num and t < num) or (back == True and k < num):
    				if t >= num:
    					t = 0
    					k = k + 1

    				back = False

    				for qq in range(49):
    					if k < num and back == False:
    						for kk in range(8):
    							if used[k] == 1:
    								k = k + 1
    							else:
    								break

			    			for tt in range(8):
			    				if use[t] == 1:
			    					t = t + 1
			    				else:
			    					break

			    			if t >= num or k >= num:
			    				k = k + 1
			    				t = 0
			    			else:
			    				s = k * num + t

			    				if m[s] != 1:
			    					m[s] = 1
			    					s = i * num + j
			    					a[s] = k
			    					b[s] = t

			    					back = True
			    				else:
			    					t = t + 1

			    					if t >= num:
			    						k = k + 1
			    						t = 0

			    		else:
			    			break

			    	if back == True:
			    		if j < num - 1:
			    			j = j + 1
			    		else:
			    			i = i + 1
			    			j = 0
			    		
			    		back = False
			    	else:
			    		if j > 0:
			    			j = j - 1
			    		else:
			    			i = i - 1
			    			j = num - 1

			    		back = True
			    		b_o = 1

    			else:
			    	if back == False:
			    		if k >= num and t >= num:
			    			b_o = 2
			    		else:
			    			if k >= num:
			    				b_o = 1
			    			else:
			    				b_o = 0
			    	else:
			    		b_o = 0

			    	if j > 0:
			    		j = j - 1
			    	else:
			    		i = i - 1
			    		j = num - 1

			    	back = True

    			k = 0
    			used = [0,0,0,0,0,0,0,0,0]
    			use = [0,0,0,0,0,0,0,0,0]

    	else:
    		break

    m = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    i = 0
    j = 0

    for fin in range(49):
    	if i < num:
    		s = i * num + j
    		t = a[s]
    		k = b[s]
    		p = t * num + k + 1
    		m[s] = p

    		if j < num - 1:
    			j = j + 1
    		else:
    			i = i + 1
    			j = 0
    	else:
    		break

    self.mag = m