/**
 *Submitted for verification at polygonscan.com on 2021-09-22
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Game is IERC20 {

    string public constant name = "GameToken";
    string public constant symbol = "GAME";
    uint8 public constant decimals = 18;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;   // Total Supply = 20000000000000000000000000000000000000000000000000000000000000000

    using SafeMath for uint256;


   constructor(uint256 total) public {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
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


contract vault {
    
    event BuyEggsDB(uint pointt, address account);
    address public token = 0xb6BdB9ABC8e2544Fcf21Bed8354E79169314ee5c;
    
    function BuyEggs(uint amount) external {
        
        IERC20(token).approve(msg.sender, amount);
        IERC20(token).transferFrom(msg.sender, address(this) , amount);
        uint eggs = amount;
        emit BuyEggsDB(eggs, msg.sender);
        
    }
    
    function SellEggs(uint _eggs) external {
        uint amount = _eggs;
        IERC20(token).transfer(msg.sender, amount);
        
    }
    // event BuyPoin(uint pointt, address account);
    // uint public 
    // function BuyPoint(uint amount) external {
    //     address token = 0x1DcE373be8E900bC045f53bcF0b4C9771Be2493f;
    //     IERC20(token).approve(token, amount);
    //     IERC20(token).transferFrom(msg.sender, address(this) , amount);
    //     uint points = amount;
    //     emit BuyPoin(points, msg.sender);
    // }
    
    // function SellPoint(uint _point) external {
    //     address token = 0x1DcE373be8E900bC045f53bcF0b4C9771Be2493f;
    //     uint amount = _point;
    //     IERC20(token).transfer(msg.sender, amount);
    // }
}