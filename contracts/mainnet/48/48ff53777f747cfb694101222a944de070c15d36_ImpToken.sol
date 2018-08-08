pragma solidity ^0.4.17;

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

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) constant returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      /* prefix might be needed for geth and parity
      * https://github.com/ethereum/go-ethereum/issues/3731
      */
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      hash = sha3(prefix, hash);
      return ecrecover(hash, v, r, s);
    }
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
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until 
   * the first transaction is mined)
   * From MonolithDAO ImpToken.sol
   */
  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
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













contract ValidationUtil {
    function requireNotEmptyAddress(address value){
        require(isAddressNotEmpty(value));
    }

    function isAddressNotEmpty(address value) internal returns (bool result){
        return value != 0;
    }
}












/**
 * Контракт ERC-20 токена
 */

contract ImpToken is StandardToken, Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    bool public isDistributed;
    uint public distributedAmount;

    event UpdatedTokenInformation(string name, string symbol);

    /**
     * Конструктор
     *
     * @param _name - имя токена
     * @param _symbol - символ токена
     * @param _totalSupply - со сколькими токенами мы стартуем
     * @param _decimals - кол-во знаков после запятой
     */
    function ImpToken(string _name, string _symbol, uint _totalSupply, uint _decimals) {
        require(_totalSupply != 0);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _totalSupply;
    }

    /**
     * Владелец должен вызвать эту функцию, чтобы сделать начальное распределение токенов
     */
    function distribute(address toAddress, uint tokenAmount) external onlyOwner {
        require(!isDistributed);

        balances[toAddress] = tokenAmount;

        distributedAmount = distributedAmount.add(tokenAmount);

        require(distributedAmount <= totalSupply);
    }

    function closeDistribution() external onlyOwner {
        require(!isDistributed);

        isDistributed = true;
    }

    /**
     * Владелец может обновить инфу по токену
     */
    function setTokenInformation(string newName, string newSymbol) external onlyOwner {
        name = newName;
        symbol = newSymbol;

        // Вызываем событие
        UpdatedTokenInformation(name, symbol);
    }

    /**
     * Владелец может поменять decimals
     */
    function setDecimals(uint newDecimals) external onlyOwner {
        decimals = newDecimals;
    }
}






contract ImpCore is Ownable, ValidationUtil {
    using SafeMath for uint;
    using ECRecovery for bytes32;

    /* Токен, с которым работаем */
    ImpToken public token;

    /* Мапа адрес получателя токенов - nonce, нужно для того, чтобы нельзя было повторно запросить withdraw */
    mapping (address => uint) private withdrawalsNonce;

    event Withdraw(address receiver, uint tokenAmount);
    event WithdrawCanceled(address receiver);

    function ImpCore(address _token) {
        requireNotEmptyAddress(_token);

        token = ImpToken(_token);
    }

    function withdraw(uint tokenAmount, bytes signedData) external {
        uint256 nonce = withdrawalsNonce[msg.sender] + 1;

        bytes32 validatingHash = keccak256(msg.sender, tokenAmount, nonce);

        // Подписывать все транзакции должен owner
        address addressRecovered = validatingHash.recover(signedData);

        require(addressRecovered == owner);

        // Делаем перевод получателю
        require(token.transfer(msg.sender, tokenAmount));

        withdrawalsNonce[msg.sender] = nonce;

        Withdraw(msg.sender, tokenAmount);
    }

    function cancelWithdraw() external {
        withdrawalsNonce[msg.sender]++;

        WithdrawCanceled(msg.sender);
    }


}