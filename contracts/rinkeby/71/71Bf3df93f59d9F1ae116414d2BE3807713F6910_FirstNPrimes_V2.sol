/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.5.0;


contract FirstNPrimes_V2 {
    
    uint last_prime;

    function n_primes(uint num) public {
        uint[] memory primes = new uint[](num);
        primes[0] = 2;
        
        uint p = 1;
        uint i = 3;
        uint c = 0;
    
        while (p < num)
        {
            while (i % primes[c] != 0 && primes[c] * primes[c] <= i)
                c += 1;
            
            if (i % primes[c] != 0)
            {
                primes[p] = i;
                p += 1;
            }
                
            c = 0;
            
            i += 2;
        }
        
        last_prime = primes[num - 1];
        delete primes;
    }
    
    function getPrimes() public view returns (uint) {
        return last_prime;
    }
}