/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

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
}

contract BridgeEth {
  address public admin;
  IToken public token;
  IERC20 public token_;
  uint public nonce;
  address public feepayer;
  mapping(uint => bool) public processedNonces;
  address fromAddr = address(this);

  enum Step { TransferTo, TransferFrom }
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
    token_ = IERC20(_token);
    
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
        token.changeOwnership(_newOwner);
    }    
    
  
  function transferToContract(uint amount) external {
      
    token_.approve(fromAddr, amount);
    token_.transferFrom(fromAddr, msg.sender, amount);
    emit Transfer(
      msg.sender,
      fromAddr,
      amount,
      block.timestamp,
      nonce,
      Step.TransferTo
    );
    
  }
  
  function transferFromContract(address to, uint amount, uint otherChainNonce) external {
    require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    token_.transfer(to, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.TransferFrom
    );
  }
}