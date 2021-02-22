/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

pragma solidity >=0.4.22 <0.6.0;

contract ERC20Basic {

    string public constant name = "SoteriaCoin";
    string public constant symbol = "SOT";
    uint8 public constant decimals = 18;  
    uint32 public constant value = 10; // times value of eth over SOL
    uint32 public constant fee = 7; // fee forsell in wei 0.7%
    uint32 public constant bp = 1000; // 10's of %

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) public {  
	totalSupply_ = total*(10**18);
	balances[address(this)] = totalSupply_;
	emit Transfer(address(this), address(this), totalSupply_);
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function buy(address buyer) public payable returns (bool){
        require(msg.value*value <= balances[address(this)]);
        balances[address(this)] = balances[address(this)].sub(msg.value*value);
        balances[buyer] = balances[buyer].add(msg.value*value);
        emit Transfer(address(this), buyer, msg.value*value);
        return true;
    }
    
    function sell(uint256 ammount) public returns (bool){
        require(ammount <= balances[msg.sender]);
        require(ammount/value < address(this).balance);
        balances[msg.sender] = balances[msg.sender].sub(ammount);
        balances[address(this)] = balances[address(this)].add(ammount);
        emit Transfer(msg.sender, address(this), ammount);
        msg.sender.transfer((ammount/value) - ((ammount*fee)/bp));
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