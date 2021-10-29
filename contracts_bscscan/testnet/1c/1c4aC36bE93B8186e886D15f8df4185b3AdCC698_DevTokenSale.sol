/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// File: devtoken.sol


pragma solidity 0.7.0;

contract DevToken{
  // name
  string public name = "Croco Token";
  // Symbol or Ticker
  string public symbol = "CCCTS";
  // decimal 
  uint256 public decimals = 18;
  // totalsupply
  uint256 public totalSupply;
  
  // transfer event
  event Transfer(address indexed sender,address indexed to,uint256 amount);

  // Approval
  event Approval(address indexed From , address indexed spender, uint256 amount);
  
 // balance mapping  
  mapping (address => uint256) public balanceOf;
  
  // allowance mapping
  mapping(address => mapping(address => uint256)) public allowance;
//   allowance[msg.sender][_spender] = amount
//  a[msg.sender][_spenderaddres ] = 1000;
  
  constructor(uint256 _totalsupply)  {
      totalSupply = _totalsupply; 
      balanceOf[msg.sender] = _totalsupply;
  }
  
  // transfer function
  function transfer(address _to,uint256 _amount) public returns(bool success){
  // the user that is transferring must have suffiecent balance
  require(balanceOf[msg.sender] >= _amount , 'you have not enough balance');
  // subtracnt the amount from sender
  balanceOf[msg.sender] -= _amount;
  // add the amount to the user transfered
  balanceOf[_to] += _amount;
  emit Transfer(msg.sender,_to,_amount);
  return true;
  }

  // approve function
  function approve(address _spender,uint256 _amount) public returns(bool success){
  // increase allownce
  allowance[msg.sender][_spender] += _amount;
  // emit allownce event
  emit Approval(msg.sender,_spender,_amount);
  return true;
  }
  
  // transferFrom function
  function transferFrom(address _from,address _to,uint256 _amount) public returns(bool success){
  // check the balance of from user
  require(balanceOf[_from] >= _amount,'the user from which money has to deducted doesnt have enough balance');
  // check the allownce of the msg.sender
  require(allowance[_from][msg.sender] >= _amount,'the spender doest have required allownce');
  // subtract the amount from user
  balanceOf[_from] -= _amount;
  // add the amount to user
  balanceOf[_to] += _amount;
  // decrese the allownce
  allowance[_from][msg.sender] -= _amount;
  // emit transfer
  emit Transfer(_from,_to,_amount);
  return true;
  }
 
  
}
// File: crowdsale.sol


pragma solidity =0.7.0;


contract DevTokenSale {
    // address of admin
    address payable public  admin;
    // define the instance of DevToken
    DevToken public devtoken;
    // token price variable
    uint256 public tokenprice;
    // count of token sold vaariable
    uint256 public totalsold; 
     
    event Sell(address sender,uint256 totalvalue); 
   
    // constructor 
    constructor(address _tokenaddress,uint256 _tokenvalue){
        admin  = msg.sender;
        tokenprice = _tokenvalue;
        devtoken  = DevToken(_tokenaddress);
    }
   
    // buyTokens function
    function buyTokens() public payable{
    // check if the contract has the tokens or not
    require(devtoken.balanceOf(address(this)) >= msg.value*tokenprice,'the smart contract dont hold the enough tokens');
    // transfer the token to the user
    devtoken.transfer(msg.sender,msg.value*tokenprice);
    // increase the token sold
    totalsold += msg.value*tokenprice;
    // emit sell event for ui
     emit Sell(msg.sender, msg.value*tokenprice);
    }

    // end sale
    function endsale() public{
    // check if admin has clicked the function
    require(msg.sender == admin , ' you are not the admin');
    // transfer all the remaining tokens to admin
    devtoken.transfer(msg.sender,devtoken.balanceOf(address(this)));
    // transfer all the etherum to admin and self selfdestruct the contract
    selfdestruct(admin);
    }
}