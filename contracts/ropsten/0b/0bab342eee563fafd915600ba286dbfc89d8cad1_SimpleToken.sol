/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.6.0;

interface ERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    
}

contract SimpleToken is ERC20 {

    string public  name ;
    string public  symbol;
    uint8 public  decimals;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    event onTokenPurchase(address indexed customerAddress,uint256 incomingEthereum);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
   
    uint256 totalSupply_;
    address secondholder;
    using SafeMath for uint256;


   constructor(string  memory _name,string memory  _symbol,uint8  _decimals,uint256 total) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply_ = total;
    balances[msg.sender] = totalSupply_*1e18;
    
    
    }
    
    function issuetoken(address _secondholder,uint256 numTokens) public {
        secondholder =_secondholder;
        emit Transfer(msg.sender, secondholder, numTokens);
    }
    
  function buyTokens(address _beneficiary,uint256 numTokens) public payable {
    require(_beneficiary != address(0));
    require(msg.value != 0);
    emit Transfer(secondholder,_beneficiary, numTokens);
  }
  
  function SellTokens(uint256 numTokens) public payable {
    require(msg.value != 0);
    emit Transfer(msg.sender,secondholder, numTokens);
  }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
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

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}