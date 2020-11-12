pragma solidity ^0.4.26;

contract AdoreCoin{
    
    /*=====================================
    =           EVENTS                    =
    =====================================*/
    
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Adore Coin";
    string public symbol = "ADR";
    uint256 constant public totalSupply_ = 51000000;
    uint256 constant public decimals = 0;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    /*=====================================
    =            FUNCTIONS                =
    =====================================*/
    constructor() public
    {
        balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public pure returns (uint256) {
      return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
      return balances[tokenOwner];
    }

    function transfer(address receiver,uint numTokens) public returns (bool) {
      require(numTokens <= balances[msg.sender]);
      balances[msg.sender] = SafeMath.sub(balances[msg.sender],numTokens);
      balances[receiver] = SafeMath.add(balances[receiver],numTokens);
      emit Transfer(msg.sender, receiver, numTokens);
      return true;
    }
    
    
    function approve(address delegate,
                uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }
    
    function allowance(address owner,
                  address delegate) public view returns (uint) {
      return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer,
                     uint numTokens) public returns (bool) {
      require(numTokens <= balances[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      balances[owner] = SafeMath.sub(balances[owner],numTokens);
      allowed[owner][msg.sender] =SafeMath.sub(allowed[owner][msg.sender],numTokens);
      balances[buyer] = balances[buyer] + numTokens;
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}