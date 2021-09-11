/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-01
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
  function changeOwnership(address  _newOwner) external;
  function transferFrom(address _from,address _to,uint256 _amount) external;
}


contract MaticBridge {
  address public admin;
  IToken public token;
  uint public nonce;
  address public feepayer;
  mapping(uint => bool) public processedNonces;
  uint public feePercent;
  address public feeAddress;

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


  constructor(address _token, address _feeAddr) {
    admin = msg.sender;
    token = IToken(_token);
    feePercent = 1;
    feeAddress = _feeAddr;
  }


   // transfer Ownership to other address
    function transferOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == admin);
        emit OwnershipTransferred(admin,_newOwner);
        admin = _newOwner;
    }
    
 // transfer token Ownership to other address
    function transferTokenOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == admin);
        token.changeOwnership(_newOwner);
    }    
    
  function burn(uint amount) external {
      
   uint feeAmt;
   if(feePercent == 0){
      feeAmt = 0;
      }
    else{
       feeAmt = amount * feePercent / 100; 
    }
   uint burnAmt = amount - feeAmt;
   token.transferFrom(msg.sender, feeAddress, feeAmt);
    token.burn(msg.sender, burnAmt);
    emit Transfer(
      msg.sender,
      address(0x0),
      amount,
      block.timestamp,
      nonce,
      Step.Burn
    );
    
  }
  


  function mint(address to, uint amount, uint otherChainNonce) external {
    require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    token.mint(to, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
  }
  
  // Set fee percent 
  function setFeePercent(uint _percent) public {
      require(msg.sender == admin, "Only admin");
      feePercent = _percent;
  }
  
  // Set fee address 
  function setFeeAddress(address _addr) public {
      require(msg.sender == admin, "Only admin");
      feeAddress = _addr;
  }
}