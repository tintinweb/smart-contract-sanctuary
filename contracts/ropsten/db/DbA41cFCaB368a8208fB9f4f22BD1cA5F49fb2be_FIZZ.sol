/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity =0.4.22;


contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



contract ERC20Interface {
    function owner() public view returns (address);
    function totalSupply() public constant returns (uint);
    function soldtokensvalue()  public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract Ownable  {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
   
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }


  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }


  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract FIZZ is ERC20Interface, SafeMath ,Ownable{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint  soldtokens;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    

    //FizzCoin", "FIZZ", 
    constructor () public {
        symbol = "FIZZ";
        name = "FizzCoin";
        decimals = 18;
        _totalSupply = 10000000000 *1e18;
        balances[msg.sender] = _totalSupply; 
      
        
    }
    
      /**
   * @dev can view soldtokens 
   * Can only be called by the current owner.
   */
    
    function soldtokensvalue()public  view returns(uint){
        return soldtokens;
    }
    
         /**
   * @dev can view totalSupply of tokens 
   */
    
    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }


         /**
   * @dev can transfer tokens to specific address 
   * function reverts back if sender addresss is invalid or address is zero
   */
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0), "invalid reciever address");
        if(msg.sender==_owner){
            soldtokens=safeAdd(soldtokens,tokens);
        }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
             /**
   * @dev can approve tokens for another account to sell
   * function reverts back if sender addresss is invalid or address is zero
   */

    function approve(address spender, uint tokens) public returns (bool success) {
         require(spender != address(0), "invalid spender address");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

             /**
   * @dev can transfer tokens from specific address to specific address if having enough token allowances
   * function reverts back if sender addresss is invalid or address is zero
   */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
         require(from != address(0), "invalid sender address");
         require(from != address(0), "invalid reciever address");
            if(msg.sender==_owner){
            soldtokens=safeAdd(soldtokens,tokens);
        }
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
     //to check owner ether balance 
     function getOwneretherBalance()public  view returns (uint) {
        return _owner.balance;
    }
    
    //to check the user etherbalance
     function etherbalance(address _account)public  view returns (uint) {
        return _account.balance;
    }


    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}