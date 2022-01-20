/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.1;

contract Counter
{
    uint public count = 0;

    event Increment(uint value);
    event Decrement(uint value);

    function getCount()view public returns(uint){
        return count;
    }

    function increment() public
    {
        count += 1;
        emit Increment(count);
    }
    function decrement() public
    {
        count -=1;
        emit Decrement(count);
    }

}