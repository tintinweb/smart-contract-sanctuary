/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0 <0.9.0;

contract Arts{
    
    using Counters for Counters.Counter;
    Counters.Counter private _artsTracker;   
    string[] public arts;
    
    
    function getArts() public view returns(string[] memory){
        return arts;
    }    
    
    function storeArt(string memory _art) public {
        arts.push(_art);
        _artsTracker.increment();
        
    }
    
}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
            counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
            counter._value = value - 1;
        
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}