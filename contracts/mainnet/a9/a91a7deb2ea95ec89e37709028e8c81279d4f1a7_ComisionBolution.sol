pragma solidity >=0.4.22 <0.7.0;
// SPDX-License-Identifier: MIT

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ComisionBolution {
    
    address public owner;
    
    using SafeMath for uint256;
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("ONLY_OWNER_ALLOWED");
        }
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transfer(address payable _to, uint256 _amount, uint256 _comision) public payable returns(bool){
        require(_to != msg.sender, "NOT_ALLOWED_AUTO_TRANSFER");
        require(_amount.add(_comision) == msg.value, "INSUFFICIENT_VALUE_TO_TRANSFER_WITH_COMISION");
        _to.transfer(_amount);
        return true;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner returns(bool) {
        owner = _newOwner;
        return true;
    }
    
    function withdraw() public onlyOwner returns (bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }
    
}