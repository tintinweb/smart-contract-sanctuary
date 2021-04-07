/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: none
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



contract SatoPayErcBridge {
  address public admin;
  IToken public token;
  uint public nonce;
  address public feepayer;
  mapping(uint => bool) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );
event OwnershipTransferred(address indexed _from, address indexed _to);


  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
    
  }


   // transfer Ownership to other address
    function transferOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == admin);
        emit OwnershipTransferred(admin,_newOwner);
        admin = _newOwner;
    }
    
 // transfer Ownership to other address
    function transferTokenOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == admin);
        token.transferOwnership(_newOwner);
    }    
    
 
    receive() payable external {
        
        
    }
    
    function transferAnyERC20Token(address _token,address to,uint amount) external{
         require(msg.sender == admin, 'only admin');
         require(token.balanceOf(address(this))>=amount);
         IToken(_token).transfer(to,amount);
    }

  function vtransfer(address to, uint amount, uint otherChainNonce) external {
     address selfAddress =  address(this);
    require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    require(token.balanceOf(selfAddress)>=amount);
    processedNonces[otherChainNonce] = true;
    token.transfer(to,amount);
    emit Transfer(
      selfAddress,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
  }
}