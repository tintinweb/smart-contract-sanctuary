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
    
        while (p < num)
        {
            if (prime(i, primes))
            {
                primes[p] = i;
                p += 1;
            }

            i += 2;
        }
        
        last_prime = primes[num - 1];
    }

    function prime(uint i, uint[] memory primes) private pure returns (bool) {
        uint c = 0;
        
        while (i % primes[c] != 0 && primes[c] * primes[c] <= i)
            c += 1;

        if (i % primes[c] != 0)
            return true;
        else
            return false;
    }
    
    function getPrimes() public view returns (uint) {
        return last_prime;
    }
}