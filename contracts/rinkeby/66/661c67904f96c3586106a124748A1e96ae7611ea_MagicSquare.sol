/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.5.0;


contract MagicSquare {

    uint[] mag;

    function magic_square(uint num) public {
        uint[] memory a = new uint[](num*num);
        uint[] memory b = new uint[](num*num);
        uint[] memory m = new uint[](num*num);
        
        if (num == 1 || num == 2)
        {
            a = new uint[]((num+1)*(num+1));
            b = new uint[]((num+1)*(num+1));
            m = new uint[]((num+1)*(num+1));
        }
        
        uint[] memory used = new uint[](num + 3);
        uint[] memory use = new uint[](num + 3);
        uint i = 0;
        uint j = 0;
        uint s = 0;
        uint k = 0;
        uint t = 0;
        uint p = 0;
        bool back = false;
        uint b_o = 0;
        
        t = (num - 1) / 2;
        k = (num - 1);
        
        while (i < num)
        {
            if (num % 2 == 0)
                t = i;
            
            s = i * num + j;
            p = i * num + k;
            a[s] = t;
            b[p] = t;
            i = i + 1;
            j = j + 1;
            k = k - 1;
        }
        
        i = num - 1;
        j = 0;
        k = 0;
        t = (num - 1) / 2;
        
        if (num % 2 == 1) 
        {
            used[t] = 1;
            p = t * num + t;
            m[p] = 1;
        }
        
        p = 0;
        
        while (j < num)
        {
            if (i == j && num != 1)
            {
                i = i - 1;
                j = j + 1;
                p = p + 1;
            }
            
            s = i * num + j;
            
            if (num % 2 == 1)
            {
                while (used[k] == 1)
                    k = k + 1;
            }
            else
            {
                while (used[k] == 1 || k == i || k == j)
                    k = k + 1;
            }
            
            a[s] = k;
            used[k] = 1;
            
            s = k * num + b[s];
            m[s] = 1;
            
            s = p * num + j;
            b[s] = k;
            
            s = a[s] * num + k;
            m[s] = 1;
            
            i = i - 1;
            j = j + 1;
            p = p + 1;
            k = 0;
        }
        
        used = new uint[](num + 3);
        i = 0;
        j = 0;
        k = 0;
        
        
        while (i < (num - 1) || j < (num - 1))
        {
            t = i + j;
            
            if (i == j || t == (num - 1))
            {
                if (back == false)
                {
                    if (j < (num - 1))
                        j = j + 1;
                    else
                    {
                        i = i + 1;
                        j = 0;
                    }
                }
                else
                {
                    if (j > 0)
                        j = j - 1;
                    else
                    {
                        i = i - 1;
                        j = num - 1;
                    }
                }
            }
            else
            {
                k = 0;
                
                while (k < num)
                {
                    if (k != j)
                    {
                        s = i * num + k;
                        
                        if (k < j || (i == k || (i + k) == (num - 1)))
                        {
                            p = a[s];
                            used[p] = 1;
                        }
                        
                        if (k < j || (i == k || (i + k) == (num - 1)))
                        {
                            p = b[s];
                            use[p] = 1;
                        }
                    }
                    
                    if (k != i)
                    {
                        s = k * num + j;
                        
                        if (k < i || (k == j || (k + j) == (num - 1)))
                        {
                            p = a[s];
                            used[p] = 1;
                        }
                        
                        if (k < i || (k == j || (k + j) == (num - 1)))
                        {
                            p = b[s];
                            use[p] = 1;
                        }
                    }
                    
                    k = k + 1;
                }
                
                if (i == 1 && j == 0)
                {
                    k = 0;
                    
                    if (num % 2 == 0)
                        t = num / 2;
                    else
                        t = num - 1;
                        
                    while (k < t)
                    {
                        used[k] = 1;
                        k = k + 1;
                    }
                }
                
                if (i == 1 && j == 2)
                {
                    k = 0;
                    
                    t = (num / 2) - 1;
                    
                    while (k < t)
                    {
                        use[k] = 1;
                        k = k + 1;
                    }
                }
                
                if (i == 1 && j == 3)
                {
                    k = 0;
                    t = 3;
                    
                    while (k < t)
                    {
                        use[k] = 1;
                        k = k + 1;
                    }
                }
                
                if (back == true)
                {
                    s = i * num + j;
                    k = a[s];
                    t = b[s];
                    a[s] = num;
                    b[s] = num;
                    
                    s = k * num + t;
                    m[s] = 0;
                    
                    if (b_o == 2)
                    {
                        k = k + 1;
                        t = t + 1;
                    }
                    else
                    {
                        if (b_o == 1)
                        {
                            k = k + 1;
                            t = 0;
                        }
                        else
                            t = t + 1;
                    }
                }
                else
                {
                    k = 0;
                    t = 0;
                    b_o = 0;
                }
                
                while (used[k] == 1)
                    k = k + 1;
                    
                while (use[t] == 1)
                    t = t + 1;
                
            
                if ((k < num && t < num) || (back == true && k < num))
                {
                    if (t >= num)
                    {
                        t = 0;
                        k = k + 1;
                    }
                    
                    back = false;
                    
                    while (k < num && back == false)
                    {
                        while (used[k] == 1)
                            k = k + 1;
                        
                        while (use[t] == 1)
                            t = t + 1;
                            
                        if (t >= num || k >= num)
                        {
                            k = k + 1;
                            t = 0;
                        }
                        else
                        {
                            s = k * num + t;
                            
                            if (m[s] != 1)
                            {
                                m[s] = 1;
                                s = i * num + j;
                                a[s] = k;
                                b[s] = t;
                                
                                back = true;
                            }
                            else
                            {
                                t = t + 1;
                                
                                if (t >= num)
                                {
                                    k = k + 1;
                                    t = 0;
                                }
                            }
                        }
                    }
                    
                    if (back == true)
                    {
                        if (j < (num - 1))
                            j = j + 1;
                        else
                        {
                            i = i + 1;
                            j = 0;
                        }
                        
                        back = false;
                    }
                    else
                    {
                        if (j > 0)
                            j = j - 1;
                        else
                        {
                            i = i - 1;
                            j = num - 1;
                        }
                        
                        back = true;
                        b_o = 1;
                    }
                }
                else
                {
                    if (back == false)
                    {
                        if (k >= num && t >= num)
                            b_o = 2;
                        else
                        {
                            if (k >= num)
                                b_o = 1;
                            else
                                b_o = 0;
                        }
                    }
                    else
                        b_o = 0;
                        
                    if (j > 0)
                        j = j - 1;
                    else
                    {
                        i = i - 1;
                        j = num - 1;
                    }
                    
                    back = true;
                }
                
                k = 0;
                used = new uint[](num + 3);
                use = new uint[](num + 3);
            }
        }
        
        m = new uint[](num*num);
        i = 0;
        j = 0;
        
        while (i < num)
        {
            s = i * num + j;
            t = a[s];
            k = b[s];
            p = t * num + k + 1;
            m[s] = p;
            
            if (j < (num - 1))
                j = j + 1;
            else
            {
                i = i + 1;
                j = 0;
            }
        }
        
        mag = m;
    }
    
    function getPositions() public view returns (uint[] memory) {
        return mag;
    }
}