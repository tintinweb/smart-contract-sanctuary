pragma solidity 0.4.24;
/**
 * Math operations with safety checks
 * By OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/contracts/SafeMath.sol
 */
library SafeMath {
  
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

}


 contract ContractReceiver{
    function tokenFallback(address _from, uint256 _value, bytes  _data) external;
}


//Basic ERC23 token, backward compatible with ERC20 transfer function.
//Based in part on code by open-zeppelin: https://github.com/OpenZeppelin/zeppelin-solidity.git
contract ERC23BasicToken  {
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function tokenFallback(address _from, uint256 _value, bytes  _data) external {
        throw;
    }

    function transfer(address _to, uint256 _value, bytes _data) returns  (bool success) {
        require(_to != address(0));
        //Standard ERC23 transfer function

        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) {
        require(_to != address(0));
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons

        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) internal {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
    }

    function transferToContract(address _to, uint256 _value, bytes _data) internal {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub( _value);
        balances[_to] = balances[_to].add( _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) returns (bool is_contract) {
          uint256 length;
          assembly {
              //retrieve the size of the code on target address, this needs assembly
              length := extcodesize(_addr)
          }
          if(length>0) {
              return true;
          }
          else {
              return false;
          }
    }
}


 // Standard ERC23 token, backward compatible with ERC20 standards.
 // Based on code by open-zeppelin: https://github.com/OpenZeppelin/zeppelin-solidity.git
contract ERC23StandardToken is ERC23BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
    event Approval (address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address _from, address _to, uint256 _value) {
    require (_value > 0);
    require(_to != address(0));
    require(_from != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require (_value > 0);
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public admin;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
    admin=owner;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender==admin);
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  /**
   * @dev Allows the current owner to transfer control of the contract to a newAdmin.
   * @param newAdmin The address to transfer admin to.
   */
  function transferAdmin(address newAdmin) onlyOwner public {
    require(newAdmin != address(0));
    emit OwnershipTransferred(admin, newAdmin);
    admin = newAdmin;
  }
  
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is ERC23StandardToken,Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(_amount>0);
    require(_to != address(0));

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract ANDToken is MintableToken { 
  string public name="AND TOKEN";
  string public symbol="AND";
  uint8 public decimals=18;
  uint256 public tradeStartTime;

  function tradeStarttime(uint256 _startTime)public onlyOwner{
       tradeStartTime=_startTime.add(1 years);
   }
   
   function hasTrade() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp>tradeStartTime;
  }
   function transfer(address _to,uint256 _value) public{
       require(hasTrade());
       require(_to != address(0));

        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons

        bytes memory empty;
        if(isContract(_to)) {
             transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
    }
    
     function transfer(address _to, uint256 _value, bytes _data)public  returns (bool success)  {
        require(hasTrade());
        //Standard ERC23 transfer function
        require(_to != address(0));

        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }
 
 function transferFrom(address _from, address _to, uint256 _value) {
    require(hasTrade());
    require (_value > 0);
    require(_to != address(0));
    require(_from != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    }
}