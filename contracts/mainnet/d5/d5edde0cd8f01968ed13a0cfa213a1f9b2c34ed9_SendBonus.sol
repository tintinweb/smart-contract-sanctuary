/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

//this is the Smart Contract for QFP to send QOB Bonus for:
//1. QOB Bonus for Reservation Period;
//2. QOB Bonus for Early Bird of Genesis Period;
//3. Extra QOB Bonus for referee of QPass, for Extra QOB purchase;
//4. QOB Bonus for Genesis reference;

pragma solidity ^0.4.18;

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract SendBonus is Owned {

    function batchSend(address _tokenAddr, address[] _to, uint256[] _value) returns (bool _success) {
        require(_to.length == _value.length);
        require(_to.length <= 200);
        
        for (uint8 i = 0; i < _to.length; i++) {
            (Token(_tokenAddr).transfer(_to[i], _value[i]));
        }
        
        return true;
    }
}