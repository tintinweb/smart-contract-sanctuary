/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2019-07-03
*/

pragma solidity ^0.5.10;

contract Owned {
    address public owner;

    constructor() public {
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

    function batchSend(address _tokenAddr, address[] memory _to, uint256[] memory _value) public returns (bool _success) {
        require(_to.length == _value.length);
        require(_to.length <= 200);
        
        for (uint8 i = 0; i < _to.length; i++) {
            (Token(_tokenAddr).transfer(_to[i], _value[i]));
        }
        
        return true;
    }
}