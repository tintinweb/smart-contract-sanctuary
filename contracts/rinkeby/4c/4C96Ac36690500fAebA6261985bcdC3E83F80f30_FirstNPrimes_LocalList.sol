/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.5.0;


contract FirstNPrimes_LocalList {
    
    uint[] primes;

    function n_primes(uint num) public {
        uint[] memory local_primes = new uint[](num);
        local_primes[0] = 2;
        
        uint p = 1;
        uint i = 3;
    
        while (p < num)
        {
            if(prime(i))
            {
                local_primes[p] = i;
                p += 1;
            }
            
            i += 2;
        }

        primes = local_primes;
    }

    function prime(uint i) private pure returns (bool){
        uint u = 0;
        uint x = 3;
        
        if (i % 2 == 0)
            u = 1;
        else
            while ((x * x <= i + 1) && (i % x != 0))
                x += 2;
    
        if ((i % x == 0) && (i != 3))
            u = 1;
    
        if (u == 0)
            return true;
        else
            return false;
        
    }
    
    function getPrimes() public view returns (uint[] memory) {
        return primes;
    }
}