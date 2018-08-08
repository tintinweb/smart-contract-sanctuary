/*
 * Etherus Token smart contract
 *
 * Supports ERC20 standard
 *
 * The EtherusToken is mintable during Token Sale. On Token Sale finalization it
 * will be minted up to the cap and minting will be finished forever
 *
 */


pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}







/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * Mintable token
 */

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address private minter;
    bool public mintingEnabled = true;

    modifier onlyMinter() {
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) public onlyMinter {
        require(mintingEnabled);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }

    function stopMinting() public onlyMinter {
        mintingEnabled = false;
    }
}










/*
 * ERC23
 * ERC23 interface
 * see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC23 is ERC20Basic {
    function transfer(address to, uint value, bytes data) public;

    event TransferData(address indexed from, address indexed to, uint value, bytes data);
}



/*
* Contract that is working with ERC223 tokens
*/

contract ERC23PayableReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public payable;
}


/**  https://github.com/Dexaran/ERC23-tokens/blob/master/token/ERC223/ERC223BasicToken.sol
 *
 */
contract ERC23PayableToken is BasicToken, ERC23 {
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address to, uint value, bytes data) public {
        transferAndPay(to, value, data);
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address to, uint value) public returns (bool) {
        bytes memory empty;
        transfer(to, value, empty);
        return true;
    }

    function transferAndPay(address to, uint value, bytes data) public payable {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        if (codeLength > 0) {
            ERC23PayableReceiver receiver = ERC23PayableReceiver(to);
            receiver.tokenFallback.value(msg.value)(msg.sender, value, data);
        }else if (msg.value > 0) {
            to.transfer(msg.value);
        }

        Transfer(msg.sender, to, value);
        if (data.length > 0)
            TransferData(msg.sender, to, value, data);
    }
}


contract EtherusToken is MintableToken, ERC23PayableToken {
    string public constant name = "EtherusToken";
    string public constant symbol = "ETR";
    uint public constant decimals = 18;

    bool public transferEnabled = false;

    //The cap is 15 mln ETR
    uint private constant CAP = 15*(10**6)*(10**decimals);

    function EtherusToken(address multisigOwner) public {
        //Transfer ownership on the token to multisig on creation
        transferOwnership(multisigOwner);
    }

    function mint(address _to, uint _amount) public {
        require(totalSupply.add(_amount) <= CAP);
        super.mint(_to, _amount);
    }

    /**
    * Overriding all transfers to check if transfers are enabled
    */
    function transferAndPay(address to, uint value, bytes data) public payable {
        require(transferEnabled);
        super.transferAndPay(to, value, data);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        return super.transferFrom(_from, _to, _value);
    }

    function enableTransfer(bool enabled) public onlyOwner {
        transferEnabled = enabled;
    }

    //Take Ether instead of tokens
    function withdrawFrom(address from) private {
        uint tokens = balanceOf(from);
        require(tokens > 0);
        balances[from] = 0;
        totalSupply = totalSupply.sub(tokens);
        from.transfer(tokens);
        Transfer(from, 0, tokens);
    }

    function withdraw() public {
        withdrawFrom(msg.sender);
    }

    function withdrawFor(address to) public onlyOwner {
        withdrawFrom(to);
    }

    function withdrawForMany(address[] tos) public onlyOwner {
        for(uint i=0; i<tos.length; ++i){
            withdrawFrom(tos[i]);
        }
    }

    function () public payable {
        //We should accept Ether to make withdraw possible
    }
}