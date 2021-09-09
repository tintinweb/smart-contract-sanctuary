/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract myTokenERC20 is IERC20
{
    uint _totalSupply;
    uint _tokenCap;
    uint8 _decimal;
    string _tokenName;
    string _tokenSymbol;
    address _contractOwner;
    mapping (address => uint) _balances; 
    mapping (address => mapping(address => uint256)) _allowances;
    
    
constructor(uint256 initialSupply,uint8 decimal, string memory tokenName, string memory tokenSymbol) 
    {
   _totalSupply = initialSupply*10**decimal;
   _tokenName = tokenName;
   _tokenSymbol = tokenSymbol;
   _contractOwner=msg.sender;
   _balances[msg.sender] = _totalSupply;
    _tokenCap=_totalSupply*2;
    
     }
     
    // modifier to check whether given address is _contractOwner or not?
     modifier isOwner {
        if(msg.sender == _contractOwner) {
        _;
        }
    }
    
    function totalSupply() override external view returns (uint)
    {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) override external view returns (uint) {
    return _balances[tokenOwner];
     }
     
     function transfer(address receiver,uint numTokens) override external returns(bool)
      {
      require(numTokens <= _balances[msg.sender],"you don't have enough tokens to transfer");
     _balances[msg.sender] = _balances[msg.sender] - numTokens; // 100 -12 =88
     _balances[receiver] = _balances[receiver] + numTokens;   //0 + 12= 12
      emit Transfer(msg.sender, receiver, numTokens);
       return true;
      }
      
      function allowance(address owner,address delegate) override public view returns (uint) {
       return _allowances[owner][delegate];
        }
      
      function approve(address delegate,uint numTokens) override external returns (bool) {
     _allowances[msg.sender][delegate] = numTokens;
     emit Approval(msg.sender, delegate, numTokens);
      return true;
       }
       
       function transferFrom(address owner, address buyer,uint numTokens) override public returns (bool) {
       require(numTokens <= _balances[owner],"insufficient balance of owner");
       require(numTokens <= _allowances[owner][msg.sender],"Allowance for delegate owner is not sufficient"); 
       require(buyer != address(0),"account should not be zeor address");
       _balances[owner] = _balances[owner] - numTokens;
       _allowances[owner][msg.sender] = _allowances[owner][msg.sender] - numTokens;
       _balances[buyer] = _balances[buyer] + numTokens;
       emit Transfer(owner, buyer, numTokens);
       return true;
       }
      
     // 3A     1) anyone can get the token by paying against ether
     
     //  purchasing from owner    
    uint tokenRate=1 ether;
    function buyToken() public payable returns (bool) {
    uint tokenQuantity=msg.value/tokenRate;   // 8 ether  8/1 ->8 tokens
     _balances[_contractOwner]=_balances[_contractOwner]-tokenQuantity;   // 100 -8
     _balances[msg.sender]=_balances[msg.sender]+tokenQuantity;  //0+8=8
      return true;
        }
        
        // 3A 2) 
        
         receive() payable external
    {
        buyToken();
    }
     
    // 3A   3. There should be an additional method to adjust the price that allows the owner to adjust the price.
    function setPrice(uint newPrice) public isOwner returns(uint rate){
          tokenRate = newPrice;
          return(tokenRate);
      }
     
     
     
    
}