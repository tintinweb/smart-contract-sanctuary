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

contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to purchase tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);
    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
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

contract SofiaToken is ERC20Interface,Controlled {

    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor(uint _totalSupply) public {
      symbol = &quot;SFX&quot;;
      name = &quot;SofiaToken&quot;;
      decimals = 18;
      totalSupply = _totalSupply;
      balances[msg.sender] = _totalSupply;
      emit Transfer(address(0),controller,_totalSupply);
    }

    function totalSupply() public view returns (uint){
      return totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance){
       return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
      if (allowed[tokenOwner][spender] < balances[tokenOwner]) {
        return allowed[tokenOwner][spender];
      }
      return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public  returns (bool success){
      return doTransfer(msg.sender,to,tokens);
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success){
      if(allowed[from][msg.sender] > 0 && allowed[from][msg.sender] >= tokens)
      {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return doTransfer(from,to,tokens);
      }
      return false;
    }

    function doTransfer(address from,address to, uint tokens) public  returns (bool success){
        if( tokens > 0 && balances[from] >= tokens){
            balances[from] = balances[from].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from,to,tokens);
            return true;
        }
        return false;
    }
    function approve(address spender, uint tokens) public returns (bool success){
      if(balances[msg.sender] >= tokens){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
      }
      return false;
    }

   function approveAndCall(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        //ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}