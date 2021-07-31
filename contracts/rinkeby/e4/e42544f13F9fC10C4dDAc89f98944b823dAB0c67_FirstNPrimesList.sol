/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

pragma solidity ^0.5.0;


contract FirstNPrimesList {
    
    uint last_prime;

    function n_primes(uint num) public {
        uint[] memory primes = new uint[](num);
        primes[0] = 2;
        
        uint p = 1;
        uint i = 3;
        uint c = 0;
        uint ch = 0;
    
        while (p < num)
        {
            while (c < p)
            {
                if (i % primes[c] == 0)
                    ch = 1;
                
                c += 1;
            }
            
            if (ch == 0)
            {
                primes[p] = i;
                p += 1;
            }
                
            c = 0;
            ch = 0;
            
            i += 2;
        }
        
        if (num <= 1)
            last_prime = 2;
        else
            last_prime = i - 2;
    }
    
    function getPrimes() public view returns (uint) {
        return last_prime;
    }
}