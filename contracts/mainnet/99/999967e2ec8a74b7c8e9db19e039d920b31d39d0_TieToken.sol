/*************************************************************************
 * This contract has been merged with solidify
 * https://github.com/tiesnetwork/solidify
 *************************************************************************/
 
 /*
 * Tie Token smart contract
 *
 * Supports ERC20, ERC223 stadards
 *
 * The TieToken is mintable during Token Sale. On Token Sale finalization it
 * will be minted up to the cap and minting will be finished forever
 *
 * @author Dmitry Kochin <<span class="__cf_email__" data-cfemail="0a614a7e636f7924646f7e7d657861">[email&#160;protected]</span>>
 */


pragma solidity ^0.4.14;


/*************************************************************************
 * import "./include/MintableToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "zeppelin/contracts/token/StandardToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./BasicToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./ERC20Basic.sol" : start
 *************************************************************************/


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/*************************************************************************
 * import "./ERC20Basic.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../math/SafeMath.sol" : start
 *************************************************************************/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/*************************************************************************
 * import "../math/SafeMath.sol" : end
 *************************************************************************/


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
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}
/*************************************************************************
 * import "./BasicToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./ERC20.sol" : start
 *************************************************************************/





/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/*************************************************************************
 * import "./ERC20.sol" : end
 *************************************************************************/


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}
/*************************************************************************
 * import "zeppelin/contracts/token/StandardToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "zeppelin/contracts/ownership/Ownable.sol" : start
 *************************************************************************/


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
/*************************************************************************
 * import "zeppelin/contracts/ownership/Ownable.sol" : end
 *************************************************************************/

/**
 * Mintable token
 */

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address private minter;

    modifier onlyMinter(){
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) onlyMinter {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }
}
/*************************************************************************
 * import "./include/MintableToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./include/ERC23PayableToken.sol" : start
 *************************************************************************/



/*************************************************************************
 * import "./ERC23.sol" : start
 *************************************************************************/




/*
 * ERC23
 * ERC23 interface
 * see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC23 is ERC20Basic {
    function transfer(address to, uint value, bytes data);

    event TransferData(address indexed from, address indexed to, uint value, bytes data);
}
/*************************************************************************
 * import "./ERC23.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./ERC23PayableReceiver.sol" : start
 *************************************************************************/

/*
* Contract that is working with ERC223 tokens
*/

contract ERC23PayableReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) payable;
}/*************************************************************************
 * import "./ERC23PayableReceiver.sol" : end
 *************************************************************************/

/**  https://github.com/Dexaran/ERC23-tokens/blob/master/token/ERC223/ERC223BasicToken.sol
 *
 */
contract ERC23PayableToken is BasicToken, ERC23{
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address to, uint value, bytes data){
        transferAndPay(to, value, data);
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address to, uint value) returns (bool){
        bytes memory empty;
        transfer(to, value, empty);
        return true;
    }

    function transferAndPay(address to, uint value, bytes data) payable {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        if(codeLength>0) {
            ERC23PayableReceiver receiver = ERC23PayableReceiver(to);
            receiver.tokenFallback.value(msg.value)(msg.sender, value, data);
        }else if(msg.value > 0){
            to.transfer(msg.value);
        }

        Transfer(msg.sender, to, value);
        if(data.length > 0)
            TransferData(msg.sender, to, value, data);
    }
}/*************************************************************************
 * import "./include/ERC23PayableToken.sol" : end
 *************************************************************************/


contract TieToken is MintableToken, ERC23PayableToken {
    string public constant name = "TieToken";
    string public constant symbol = "TIE";
    uint public constant decimals = 18;

    bool public transferEnabled = false;

    //The cap is 200 mln TIEs
    uint private constant CAP = 200*(10**6)*(10**decimals);

    function mint(address _to, uint _amount){
        require(totalSupply.add(_amount) <= CAP);
        super.mint(_to, _amount);
    }

    function TieToken(address multisigOwner) {
        //Transfer ownership on the token to multisig on creation
        transferOwnership(multisigOwner);
    }

    /**
    * Overriding all transfers to check if transfers are enabled
    */
    function transferAndPay(address to, uint value, bytes data) payable{
        require(transferEnabled);
        super.transferAndPay(to, value, data);
    }

    function enableTransfer(bool enabled) onlyOwner{
        transferEnabled = enabled;
    }

}