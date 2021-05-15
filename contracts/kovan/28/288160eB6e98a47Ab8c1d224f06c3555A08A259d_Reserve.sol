/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity 0.8.4;

interface Contract {
    function f(uint i_) external returns(bool);
}

contract Reserve {
    uint public note;
    Contract token;
    
    constructor() {
        token = Contract(address(this));
    }
    
    function f(uint i_) external returns(bool) {
        if(i_ == 1) {
            require(1 != 1, "I is 1");
            return true;
        }
        else if(i_ == 2) {
            token.f(3);
            return true;
        }
        else if(i_ == 3) {
            token.f(4);
            return true;
        }
        else if(i_ == 4) {
            token.f(4);
            require(i_ != 4, "I is 4");
            return true;
        }
        else if(i_ == 5) {
            token.f(3);
        }
    }
}