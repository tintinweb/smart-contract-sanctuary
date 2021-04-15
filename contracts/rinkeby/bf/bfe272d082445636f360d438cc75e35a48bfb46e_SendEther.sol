/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
  function transferOwnership(address  _newOwner) external;
  function balanceOf(address tokenOwner) external returns (uint balance);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract SendEther {
    
    IERC20 public token;
    IToken public _token;

    address public owner;
    event OwnershipTransferred(address indexed from, address indexed to);
    event TokenOwnershipTransferred(address _newOwner);
    
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
    
     // transfer token ownership to other address
    function transferTokenOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == owner);
        _token.transferOwnership(_newOwner);
    }
    
    function withdraw(address payable _to, uint _amount) public payable {
        require( msg.sender == owner);
        _to.transfer(_amount);
    }
    
    function withdrawERC20Token(address token_,address _to, uint amount) public payable {
         require( msg.sender == owner );
         require ( token.balanceOf(address(this)) >= amount );
         IERC20(token_).transferFrom(msg.sender, _to, amount);
    }
    
     function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    receive() external payable {}

}