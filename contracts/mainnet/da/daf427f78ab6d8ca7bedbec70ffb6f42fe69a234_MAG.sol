/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MAG


pragma solidity =0.8.4;






contract SafeMath {
    
    
        function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    
       function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


       function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;
            return c;
        }


        function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    
      function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }
        
    
    
    
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract ERC20Interface {
    function owner() public view  virtual returns (address);
    function totalSupply() public view virtual returns (uint);
    function soldtokensvalue()  public view virtual returns (uint);
    function balanceOf(address tokenOwner) public view virtual returns (uint balance);
    function allowance(address tokenOwner, address spender) public view virtual returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    // event Transfer(address indexed from, address indexed to, uint tokens);
    // event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract Ownable  {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor ()  {
   
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
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

contract MAG is ERC20Interface, SafeMath ,Ownable,Context{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint  soldtokens;
    bool lock;
    
    

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    constructor ()  {
        symbol = "MAG";
        name = "Mutual Alliance Global";
        decimals = 18;
        _totalSupply = 1000000000 *1e18;
        balances[msg.sender] = _totalSupply; 
      
        
    }
         /**
   * @dev can act as protection for reentracy style attacks 
   * .
   */
    
        modifier reentrancygaurd {
            require(!lock,"reentracy");
            lock = true;
            _;
            lock = false;
    }
    
      /**
   * @dev can view soldtokens 
   * Can only be called by the current owner.
   */
    
    function soldtokensvalue()public  override view returns(uint){
        return soldtokens;
    }
    
         /**
   * @dev can view totalSupply of tokens 
   */
    
    function totalSupply() public override view returns (uint256) {
      return _totalSupply;
    }

  function owner() public override  view returns (address) {
    return _owner;
  }


         /**
   * @dev can transfer tokens to specific address 
   * function reverts back if sender addresss is invalid or address is zero
   */
    function transfer(address to, uint tokens) public reentrancygaurd override returns (bool success) {
        require(to != address(0), "invalid reciever address");
       
        require(balances[msg.sender] >= tokens && safeAdd (balances[to],tokens) >= balances[to]);
         
         
         
          require (to!=msg.sender && tokens>0,"cannot send to self address or zero amount");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
         if(msg.sender==_owner){
            soldtokens=safeAdd(soldtokens,tokens);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
             /**
   * @dev can approve tokens for another account to sell
   * function reverts back if sender addresss is invalid or address is zero
   */

    function approve(address spender, uint tokens) public override returns (bool success) {
         require(spender != address(0), "invalid spender address");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // function balanceOf(address _user) public override view returns (uint256 balance) {
    //     return balances[owner];
    // }
    
    
      function balanceOf(address user) public override view returns (uint256 balance) {
        return balances[user];
    }

             /**
   * @dev can transfer tokens from specific address to specific address if having enough token allowances
   * function reverts back if sender addresss is invalid or address is zero
   */
    function transferFrom(address from, address to, uint tokens) public reentrancygaurd override returns (bool success) {
         require(from != address(0), "invalid sender address");
         require(to != address(0), "invalid reciever address");
          require(balances[from] >= tokens &&  safeAdd( balances[to],tokens) >= balances[to],"insufficient funds");
           allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);

           require(tokens>0 && from !=to,"connot send to self address or zero balance");
            balances[from] = safeSub(balances[from], tokens);
           
            balances[to] = safeAdd(balances[to], tokens);
               if(from==_owner){
                soldtokens=safeAdd(soldtokens,tokens);
            }
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


    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}