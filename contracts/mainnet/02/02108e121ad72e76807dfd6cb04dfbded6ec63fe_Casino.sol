/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.0;

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
  function transferOwnership(address  _newOwner) external;
  function balanceOf(address tokenOwner) external returns (uint balance);
  function transfer(address recipient, uint256 amount) external returns (bool);
}


contract Casino {
    
    address public owner;
    event OwnershipTransferred(address indexed from, address indexed to);
    
    constructor() {
        owner = msg.sender;
    }
    
    // transfer ownership to other address
    function transferOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
    
    function withdraw(address payable _to, uint _amount) public payable {
        require( msg.sender == owner);
        _to.transfer(_amount);
    }
    
    function withdrawERC20Token(address tokenAddr, address payable _to, uint amount) public  {
        uint balance = IToken(tokenAddr).balanceOf(address(this));
        require( msg.sender == owner );
        require ( balance >= amount );
        IToken(tokenAddr).transfer( _to, amount);
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    receive() external payable {}

}