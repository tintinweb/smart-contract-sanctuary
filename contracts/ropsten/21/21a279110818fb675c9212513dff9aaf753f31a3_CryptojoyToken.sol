pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/// @dev A standard ERC20 token (with 18 decimals) contract with manager
 /// @dev Tokens are initally minted in the contract address
contract standardToken is EIP20Interface, Ownable {
    using SafeMath for uint;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    uint8 public constant decimals = 18;  

    string public name;                    
    string public symbol;                
    uint public totalSupply;

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender. *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns(bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender. *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        return true;
    }
}

/// @dev A standard token that is linked to another pairToken.
/// @dev The total supply of these two tokens should be the same.
/// @dev Sending one token to any of these two contract address
/// @dev using transfer method will result a receiving of 1:1 another token. 
contract pairToken is standardToken {
    using SafeMath for uint;

    address public pairAddress;

    bool public pairInitialized = false;

    /// @dev Set the pair token contract, can only excute once
    function initPair(address _pairAddress) public onlyOwner() {
        require(!pairInitialized, "Pair already initialized");
        pairAddress = _pairAddress;
        pairInitialized = true;
    }

    /// @dev Override
    /// @dev A special transfer function that, if the target is either this contract
    /// @dev or the pair token contract, the token will be sent to this contract, and
    /// @dev 1:1 pair tokens are sent to the sender.
    /// @dev When the target address are other than the two paired token address,
    /// @dev this function behaves exactly the same as in a standard ERC20 token.
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        if (_to == pairAddress || _to == address(this)) {
            balances[address(this)] = balances[address(this)].add(_value);
            pairToken(pairAddress).pairTransfer(msg.sender, _value);
            emit Exchange(msg.sender, address(this), _value);
        } else {
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        }
        return true;
    } 

    /// @dev Function called by pair token to excute 1:1 exchange of the token.
    function pairTransfer(address _to, uint _value) external returns (bool success) {
        require(msg.sender == pairAddress, "Only token pairs can transfer");
        balances[address(this)] = balances[address(this)].sub(_value);
        balances[_to] = balances[_to].add(_value);
        return true;
    }

    event Exchange(address indexed _from, address _tokenAddress, uint _value);
}

/// @dev A pair token that can be mint by sending ether into this contract.
/// @dev The price of the token follows price = a*log(t)+b, where a and b are
/// @dev two parameters to be set, and t is the current round depends on current
/// @dev block height.
contract CryptojoyToken is pairToken {
    using SafeMath for uint;

    string public name = "cryptojoy token";                    
    string public symbol = "CJT";                
    uint public totalSupply = 10**10 * 10**18; // 1 billion
    uint public miningSupply; // minable part

    uint constant MAGNITUDE = 10**6;
    uint constant LOG1DOT5 = 405465; // log(1.5) under MAGNITUDE
    uint constant THREE_SECOND= 15 * MAGNITUDE / 10; // 1.5 under MAGNITUDE
    uint constant MINING_INTERVAL = 365; // number of windows that the price is fixed

    uint public a; // paremeter a of the price fuction price = a*log(t)+b, 18 decimals
    uint public b; // paremeter b of the price fuction price = a*log(t)+b, 18 decimals
    uint public blockInterval; // number of blocks where the token price is fixed
    uint public startBlockNumber; // The starting block that the token can be mint.

    address public platform;
    uint public lowerBoundaryETH; // Refuse incoming ETH lower than this value
    uint public upperBoundaryETH; // Refuse incoming ETH higher than this value

    uint public supplyPerInterval; // miningSupply / MINING_INTERVAL
    uint public tokenMint = 0;

    bool paraInitialized = false;

    /// @param _beneficiary Address to send the remaining tokens
    /// @param _miningSupply Amount of tokens of mining
    constructor(
        address _beneficiary, 
        uint _miningSupply)
        public {
        require(_miningSupply < totalSupply, "Insufficient total supply");
        miningSupply = _miningSupply;
        uint _amount = totalSupply.sub(_miningSupply);
        balances[address(this)] = miningSupply;
        balances[_beneficiary] = _amount;
        supplyPerInterval = miningSupply / MINING_INTERVAL;
    }


    /// @dev sets boundaries for incoming tx
    /// @dev from FoMo3Dlong
    modifier isWithinLimits(uint _eth) {
        require(_eth >= lowerBoundaryETH, "pocket lint: not a valid currency");
        require(_eth <= upperBoundaryETH, "no vitalik, no");
        _;
    }

    /// @dev Initialize the token mint parameters
    /// @dev Can only be excuted once.
    function initPara(
        uint _a, 
        uint _b, 
        uint _blockInterval, 
        uint _startBlockNumber,
        address _platform,
        uint _lowerBoundaryETH,
        uint _upperBoundaryETH) 
        public 
        onlyOwner {
        require(!paraInitialized, "Parameters are already set");
        require(_lowerBoundaryETH < _upperBoundaryETH, "Lower boundary is larger than upper boundary!");
        a = _a;
        b = _b;
        blockInterval = _blockInterval;
        startBlockNumber = _startBlockNumber;

        platform = _platform;
        lowerBoundaryETH = _lowerBoundaryETH;
        upperBoundaryETH = _upperBoundaryETH;

        paraInitialized = true;
    }

    /// @dev Mint token based on the current token price.
    /// @dev The token number is limited during each interval.
    function buy() public isWithinLimits(msg.value) payable {
        uint currentStage = getCurrentStage(); // from 1 to MINING_INTERVAL
        require(tokenMint < currentStage.mul(supplyPerInterval), "No token avaiable");
        uint currentPrice = calculatePrice(currentStage); // 18 decimal
        uint amountToBuy = msg.value.mul(10**uint(decimals)).div(currentPrice);
        
        if(tokenMint.add(amountToBuy) > currentStage.mul(supplyPerInterval)) {
            amountToBuy = currentStage.mul(supplyPerInterval).sub(tokenMint);
            balances[address(this)] = balances[address(this)].sub(amountToBuy);
            balances[msg.sender] = balances[msg.sender].add(amountToBuy);
            tokenMint = tokenMint.add(amountToBuy);
            uint refund = msg.value.sub(amountToBuy.mul(currentPrice).div(10**uint(decimals)));
            msg.sender.transfer(refund);          
            platform.transfer(msg.value.sub(refund)); 
        } else {
            balances[address(this)] = balances[address(this)].sub(amountToBuy);
            balances[msg.sender] = balances[msg.sender].add(amountToBuy);
            tokenMint = tokenMint.add(amountToBuy);
            platform.transfer(msg.value);
        }
        emit Buy(msg.sender, amountToBuy);
    }

    function() public payable {
        buy();
    }

    function withdraw(address _to, uint _value) external onlyOwner {
        require(_value <= address(this).balance);
        _to.transfer(_value);
    }

    /// @dev Shows the remaining token of the current token mint phase
    function tokenRemain() public view returns (uint) {
        uint currentStage = getCurrentStage();
        return currentStage * supplyPerInterval - tokenMint;
    }

    /// @dev Get the current token mint phase between 1 and MINING_INTERVAL
    function getCurrentStage() public view returns (uint) {
        require(block.number >= startBlockNumber, "Not started yet");
        uint currentStage = (block.number.sub(startBlockNumber)).div(blockInterval) + 1;
        if (currentStage <= MINING_INTERVAL) {
            return currentStage;
        } else {
            return MINING_INTERVAL;
        }
    }

    /// @dev Return the price of one token during the nth stage
    /// @param stage Current stage from 1 to 365
    /// @return Price per token
    function calculatePrice(uint stage) public view returns (uint) {
        return a.mul(log(stage.mul(MAGNITUDE))).div(MAGNITUDE).add(b);
    }

    /// @dev Return the e based logarithm of x demonstrated by Vitalik
    /// @param input The actual input (>=1) times MAGNITUDE
    /// @return result The actual output times MAGNITUDE
    function log(uint input) internal pure returns (uint) {
        uint x = input;
        require(x >= MAGNITUDE);
        if (x == MAGNITUDE) {
            return 0;
        }
        uint result = 0;
        while (x >= THREE_SECOND) {
            result += LOG1DOT5;
            x = x * 2 / 3;
        }
        
        x = x - MAGNITUDE;
        uint y = x;
        uint i = 1;
        while (i < 10) {
            result = result + (y / i);
            i += 1;
            y = y * x / MAGNITUDE;
            result = result - (y / i);
            i += 1;
            y = y * x / MAGNITUDE;
        }
        
        return result;
    }

    event Buy(address indexed _buyer, uint _value);
}

contract CryptojoyStock is pairToken {


    string public name = "cryptojoy stock";                    
    string public symbol = "CJS";                
    uint public totalSupply = 10**10 * 10**18;

    constructor() public {
        balances[address(this)] = totalSupply;
    } 

}