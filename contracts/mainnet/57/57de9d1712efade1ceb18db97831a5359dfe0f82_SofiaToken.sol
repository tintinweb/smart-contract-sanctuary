pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

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

contract Controlled {
    address public controller;
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    // @notice Constructor
    constructor() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

// ERC Token Standard #20 Interface
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SofiaToken is ERC20Interface,Controlled {

    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /*
     * @notice &#39;constructor()&#39; initiates the Token by setting its funding
       parameters
     * @param _totalSupply Total supply of tokens
     */
    constructor(uint _totalSupply) public {
      symbol = "SFX";
      name = "Sofia Token";
      decimals = 18;
      totalSupply = _totalSupply.mul(1 ether);
      balances[msg.sender] = totalSupply; //transfer all Tokens to contract creator
      emit Transfer(address(0),controller,totalSupply);
    }

    /*
     * @notice ERC20 Standard method to return total number of tokens
     */
    function totalSupply() public view returns (uint){
      return totalSupply;
    }

    /*
     * @notice ERC20 Standard method to return the token balance of an address
     * @param tokenOwner Address to query
     */
    function balanceOf(address tokenOwner) public view returns (uint balance){
       return balances[tokenOwner];
    }

    /*
     * @notice ERC20 Standard method to return spending allowance
     * @param tokenOwner Owner of the tokens, who allows
     * @param spender Token spender
     */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
      if (allowed[tokenOwner][spender] < balances[tokenOwner]) {
        return allowed[tokenOwner][spender];
      }
      return balances[tokenOwner];
    }

    /*
     * @notice ERC20 Standard method to tranfer tokens
     * @param to Address where the tokens will be transfered to
     * @param tokens Number of tokens to be transfered
     */
    function transfer(address to, uint tokens) public  returns (bool success){
      return doTransfer(msg.sender,to,tokens);
    }

    /*
     * @notice ERC20 Standard method to transfer tokens on someone elses behalf
     * @param from Address where the tokens are held
     * @param to Address where the tokens will be transfered to
     * @param tokens Number of tokens to be transfered
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
      if(allowed[from][msg.sender] > 0 && allowed[from][msg.sender] >= tokens)
      {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return doTransfer(from,to,tokens);
      }
      return false;
    }

    /*
     * @notice method that does the actual transfer of the tokens, to be used by both transfer and transferFrom methods
     * @param from Address where the tokens are held
     * @param to Address where the tokens will be transfered to
     * @param tokens Number of tokens to be transfered
     */
    function doTransfer(address from,address to, uint tokens) internal returns (bool success){
        if( tokens > 0 && balances[from] >= tokens){
            balances[from] = balances[from].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from,to,tokens);
            return true;
        }
        return false;
    }

    /*
     * @notice ERC20 Standard method to give a spender an allowance
     * @param spender Address that wil receive the allowance
     * @param tokens Number of tokens in the allowance
     */
    function approve(address spender, uint tokens) public returns (bool success){
      if(balances[msg.sender] >= tokens){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
      }
      return false;
    }

    /*
     * @notice revert any incoming ether
     */
    function () public payable {
        revert();
    }

  /*
   * @notice a specific amount of tokens. Only controller can burn tokens
   * @param _value The amount of token to be burned.
   */
  function burn(uint _value) public onlyController{
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }

  /*
   * Events
   */
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Burn(address indexed burner, uint value);
}