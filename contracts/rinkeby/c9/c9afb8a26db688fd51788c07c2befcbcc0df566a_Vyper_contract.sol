queens: public(uint256[15])

@external
def n_queens (num : uint256):
    m: uint256[15] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    used: uint256[15] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    count: uint256 = 0
    k: uint256 = 0
    d: uint256 = 0
    v: uint256 = 0
    back: bool = False
    
    if num == 1 or num >= 4:
        for x in range(4000):
            if count < num:
                if count == 0:
                    if back == False:
                        m[count] = 0
                    else:
                        m[count] += 1
                        back = False

                    count += 1
                else:
                    for y in range(15):
                        if k < count:
                            v = m[k]
                            used[v] = 1
                            d = count - k
                            
                            if v + d < num:
                                used[v + d] = 1
                            
                            if v >= d:
                                used[v - d] = 1
                            
                            k += 1
                        else:
                            break
                        
                    if back == True:
                        v = m[count]
                        k = 0
                        
                        for z in range(15):
                            if k < v + 1:
                                used[k] = 1
                                k += 1
                            else:
                                break
                        
                        back = False
                        
                    k = 0
                    
                    for a in range(15):
                        if k < num and used[k] == 1:
                            k += 1
                        else:
                            break
                        
                    if k >= num:
                        back = True
                        count -= 1
                    else:
                        m[count] = k
                        count += 1
                        
                    k = 0
                    used = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            else:
                break

    self.queens = m