/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-01
*/

pragma solidity >=0.4.22 <0.6.0;

contract DEMO_Token {

    string public constant name = "Test token";
    string public constant symbol = "TESTTOKEN";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_ = 10 ** (8 + 18);
	uint256 preMine_ = 2 * (10 ** (7 + 18));
	uint airdropSize_ = 10 ** (6 + 18);
	
	address payable owner_;

    using SafeMath for uint256;


   constructor() public {  
		
		require(preMine_ <= totalSupply_);
		
		owner_ = msg.sender;
		
		balances[address(this)] = totalSupply_.sub(preMine_);
		balances[owner_] = preMine_;
		
    }  


    function totalSupply() external view returns (uint256) {
		return totalSupply_;
    }
    
    
    function balanceOf(address tokenOwner) external view returns (uint) {
        return balances[tokenOwner];
    }


    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }


    function approve(address delegate, uint numTokens) external returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }


    function allowance(address owner, address delegate) external view returns (uint) {
        return allowed[owner][delegate];
    }


    function transferFrom(address owner, address buyer, uint numTokens) external returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
	
	
	function airdropTokens(address receiver) external {
		require(msg.sender == owner_);
		require(airdropSize_ <= balances[address(this)]);
		
		this.transfer(receiver, airdropSize_);
	}


	function releaseBNB() external {
		require(msg.sender == owner_);
		owner_.transfer(address(this).balance);
	}
	
	
	function() external payable {}
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