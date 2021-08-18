/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.5.0;


contract NQueens {

    uint[] q;

    function n_queens(uint num) public {
        uint[] memory m = new uint[](num);
        uint[] memory used = new uint[](num);
        uint count = 0;
        uint k = 0;
        uint d = 0;
        uint v = 0;
        bool back = false;
        
        if (num == 1 || num >= 4)
        {
            while (count < num)
            {
                if (count == 0)
                {
                    if (back == false)
                        m[count] = 0;
                    else
                    {
                        m[count] += 1;
                        
                        back = false;
                    }
                
                    count += 1;
                }
                else
                {
                    while (k < count)
                    {
                        v = m[k];
                        used[v] = 1;
                        d = count - k;
                        int dv = int (v - d);
                        
                        if (v + d < num)
                            used[v + d] = 1;
                            
                        if (dv >= 0)
                            used[uint (dv)] = 1;
                            
                        k += 1;
                    }
                    
                    if (back == true)
                    {
                        v = m[count];
                        k = 0;
                        
                        while (k < (v + 1))
                        {
                            used[k] = 1;
                            k += 1;
                        }
                        
                        back = false;
                    }
                    
                    k = 0;
                    
                    while (k < num && used[k] == 1)
                        k += 1;
                        
                    if (k >= num)
                    {
                        back = true;
                        count -= 1;
                    }
                    else
                    {
                        m[count] = k;
                        count += 1;
                    }
                    
                    k = 0;
                    used = new uint[](num);
                }
            }
        }
        
        q = m;
    }
    
    function getPositions() public view returns (uint[] memory) {
        return q;
    }
}