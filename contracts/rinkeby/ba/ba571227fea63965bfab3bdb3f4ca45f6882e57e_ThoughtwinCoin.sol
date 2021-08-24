/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

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



contract ThoughtwinCoin is IERC20  {
    
    string public constant name = "ThoughtwinCoin";
    string public constant symbol = "TOW";
    uint8 public constant decimals = 2;
    
    
    event _Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event _Transfer(address indexed from, address indexed to, uint256 tokens);

//   using SafeMath for uint;
   uint totalSupply_;
   mapping(address => uint256) balances ;
   mapping(address => mapping(address => uint256)) allowed ;
   
   constructor(uint256 total) public {
       totalSupply_ = total;
       balances[msg.sender] = totalSupply_;
   }
   
    function totalSupply() public override view returns (uint256) {
      return totalSupply_;
    }

   
   function balanceOf(address tokenowner)  public override view  returns(uint256) {
       return balances[tokenowner];
   }
   
   function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-(numTokens);
        balances[receiver] = balances[receiver] +(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
    require(numTokens <= balances[owner]);
    require(numTokens <= allowed[owner][msg.sender]);

    balances[owner] = balances[owner]-(numTokens);
    allowed[owner][msg.sender] = allowed[owner][msg.sender]-(numTokens);
    balances[buyer] = balances[buyer]+(numTokens);
    emit Transfer(owner, buyer, numTokens);
    return true;
}
}