/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.5.0;


contract FirstNPrimes_V2 {
    
    uint primes;

    function n_primes(uint num) public {
        uint[] memory local_primes = new uint[](num);
        local_primes[0] = 2;
        
        uint p = 1;
        uint i = 3;
        uint x = 3;
    
        while (p < num)
        {
            while ((i % x != 0) && (x * x <= i))
                x += 2;

            if ((i % x != 0) || (i == 3))
            {
                local_primes[p] = i;
                p += 1;
            }
            
            i += 2;
        }
        
        primes = local_primes[num - 1];
    }
    
    function getPrimes() public view returns (uint) {
        return primes;
    }
}