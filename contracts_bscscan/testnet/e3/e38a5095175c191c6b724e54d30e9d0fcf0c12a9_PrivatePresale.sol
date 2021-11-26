/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.3;

contract PrivatePresale {
    uint256 TokensPrice = 1 ether;
    address owner;
    mapping (address => uint256) public PrivateHolders;
    
    constructor() {
        owner = msg.sender;
    }
    
    function buyTokens(address _user, uint256 _amount) payable public{
        require(msg.value >= TokensPrice * _amount);
        addTokens(_user, _amount);
    }
    
    function addTokens(address _user, uint256 _amount) internal {
        PrivateHolders[_user] = PrivateHolders[_user] + _amount;
    }
    
    function subTokens(address _user, uint256 _amount) internal {
        require(PrivateHolders[_user] >= _amount, "You Do Not Have Enough Tokens");
        PrivateHolders[_user] = PrivateHolders[_user] - _amount;
    }
    
    function withdraw() public {
        require(msg.sender == owner, "You are not the owner.");
        payable(msg.sender).transfer(address(this).balance);
    }
}