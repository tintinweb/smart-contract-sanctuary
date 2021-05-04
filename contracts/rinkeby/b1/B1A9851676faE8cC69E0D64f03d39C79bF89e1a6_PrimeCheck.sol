/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: GPL-3.0

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract PrimeCheck {

    uint256 Number;

    function is_prime(uint256 num) private returns(bool){
        for(uint256 i = 2; i < num; i++)
            if(num % i == 0) return false;
        if(num > 1) return true;
        else return false;
    }


    function check(uint256 num) public returns (bool){
        Number = num;
        return is_prime(Number);
    }
}