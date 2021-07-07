/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.5.0;


contract FirstNPrimes_V3 {
    
    uint primes;

    function n_primes(uint num) public {
        
        uint p = 1;
        uint i = 3;
        uint x = 3;
    
        while (p < num)
        {
            while ((i % x != 0) && (x * x <= i))
                x += 2;

            if ((i % x != 0) || (i == 3))
                p += 1;
            
            x = 3;
            
            i += 2;
        }
        
        if (num <= 1)
            primes = 2;
        else
            primes = i - 2;
    }
    
    function getPrimes() public view returns (uint) {
        return primes;
    }
}