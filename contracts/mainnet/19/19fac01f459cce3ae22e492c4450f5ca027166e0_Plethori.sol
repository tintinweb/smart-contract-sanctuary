/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity ^0.4.19;

contract Plethori {
    // @dev enter the value for each data required
    // Token details would need to be inputed in the required fields makred "*"
    // Note: only strings need the double quotation, uint details should be entered without the quotation marks
    // Once the values have been set and contract deloyed, they cannot be changed
    //Token totalSupply must have an additional 18 zeros because solidity does not make provision for decimals in code


    // Token details
    string public constant name = "Plethori";
    string public constant symbol = "PLE";
    uint8 public constant decimals = 18;  
    uint256 public totalSupply = 100000000000000000000000000;
    address public owner;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    

    using SafeMath for uint256;


    // The constructor sets the admin/owner which manages the tokens
   constructor() public {  
	balances[msg.sender] = totalSupply;
    }  

    
    //Restricts select functions to onlyOwner
    modifier onlyOwner(){
    require(owner == msg.sender, "You are not the owner");
        _;
    }

    // Functions
    function totalSupply() external view returns (uint256) {
	return totalSupply;
    }

    // *balanceOf reads the balance of the specified address
    function balanceOf(address tokenOwner) external view returns (uint) {
        return balances[tokenOwner];
    }


    // allows a delegated smartcontract spend a specified amount of tokens on behalf of admin/owner
    function transfer(address receiver, uint numTokens) external returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }


    // approves a delegated smartcontract to spend a specified amount of tokens on behalf of admin/owner
    function approve(address delegate, uint numTokens) external returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address _owner, address delegate) external view returns (uint) {
        return allowed[_owner][delegate];
    }


    // allows a delegated smartcontract spend a specified amount of tokens on behalf of admin/owner
    function transferFrom(address _owner, address buyer, uint numTokens) external returns (bool) {
        require(numTokens <= balances[_owner]);    
        require(numTokens <= allowed[_owner][msg.sender]);
    
        balances[_owner] = balances[owner].sub(numTokens);
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(_owner, buyer, numTokens);
        return true;
    }
    
    }
    //SafeMath corrects overflow
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