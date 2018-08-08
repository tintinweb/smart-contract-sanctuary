pragma solidity 0.4.19;

// File: contracts/NokuPricingPlan.sol

/**
* @dev The NokuPricingPlan contract defines the responsibilities of a Noku pricing plan.
*/
interface NokuPricingPlan {
    /**
    * @dev Pay the fee for the service identified by the specified name.
    * The fee amount shall already be approved by the client.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @param client The client of the target service.
    * @return true if fee has been paid.
    */
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

    /**
    * @dev Get the usage fee for the service identified by the specified name.
    * The returned fee amount shall be approved before using #payFee method.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @return The amount to approve before really paying such fee.
    */
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/NokuTokenBurner.sol

contract BurnableERC20 is ERC20 {
    function burn(uint256 amount) public returns (bool burned);
}

/**
* @dev The NokuTokenBurner contract has the responsibility to burn the configured fraction of received
* ERC20-compliant tokens and distribute the remainder to the configured wallet.
*/
contract NokuTokenBurner is Pausable {
    using SafeMath for uint256;

    event LogNokuTokenBurnerCreated(address indexed caller, address indexed wallet);
    event LogBurningPercentageChanged(address indexed caller, uint256 indexed burningPercentage);

    // The wallet receiving the unburnt tokens.
    address public wallet;

    // The percentage of tokens to burn after being received (range [0, 100])
    uint256 public burningPercentage;

    // The cumulative amount of burnt tokens.
    uint256 public burnedTokens;

    // The cumulative amount of tokens transferred back to the wallet.
    uint256 public transferredTokens;

    /**
    * @dev Create a new NokuTokenBurner with predefined burning fraction.
    * @param _wallet The wallet receiving the unburnt tokens.
    */
    function NokuTokenBurner(address _wallet) public {
        require(_wallet != address(0));
        
        wallet = _wallet;
        burningPercentage = 100;

        LogNokuTokenBurnerCreated(msg.sender, _wallet);
    }

    /**
    * @dev Change the percentage of tokens to burn after being received.
    * @param _burningPercentage The percentage of tokens to be burnt.
    */
    function setBurningPercentage(uint256 _burningPercentage) public onlyOwner {
        require(0 <= _burningPercentage && _burningPercentage <= 100);
        require(_burningPercentage != burningPercentage);
        
        burningPercentage = _burningPercentage;

        LogBurningPercentageChanged(msg.sender, _burningPercentage);
    }

    /**
    * @dev Called after burnable tokens has been transferred for burning.
    * @param _token THe extended ERC20 interface supported by the sent tokens.
    * @param _amount The amount of burnable tokens just arrived ready for burning.
    */
    function tokenReceived(address _token, uint256 _amount) public whenNotPaused {
        require(_token != address(0));
        require(_amount > 0);

        uint256 amountToBurn = _amount.mul(burningPercentage).div(100);
        if (amountToBurn > 0) {
            assert(BurnableERC20(_token).burn(amountToBurn));
            
            burnedTokens = burnedTokens.add(amountToBurn);
        }

        uint256 amountToTransfer = _amount.sub(amountToBurn);
        if (amountToTransfer > 0) {
            assert(BurnableERC20(_token).transfer(wallet, amountToTransfer));

            transferredTokens = transferredTokens.add(amountToTransfer);
        }
    }
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

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

// File: zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: contracts/NokuCustomERC20.sol

/**
* @dev The NokuCustomERC20Token contract is a custom ERC20-compliant token available in the Noku Service Platform (NSP).
* The Noku customer is able to choose the token name, symbol, decimals, initial supply and to administer its lifecycle
* by minting or burning tokens in order to increase or decrease the token supply.
*/
contract NokuCustomERC20 is Ownable, DetailedERC20, MintableToken, BurnableToken {
    using SafeMath for uint256;

    event LogNokuCustomERC20Created(
        address indexed caller,
        string indexed name,
        string indexed symbol,
        uint8 decimals,
        address pricingPlan,
        address serviceProvider
    );
    event LogTransferFeePercentageChanged(address indexed caller, uint256 indexed transferFeePercentage);
    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The entity acting as Custom token service provider i.e. Noku
    address public serviceProvider;

    // The pricing plan determining the fee to be paid in NOKU tokens by customers for using Noku services
    address public pricingPlan;

    // The fee percentage for Custom token transfer or zero if transfer is free of charge
    uint256 public transferFeePercentage;

    bytes32 public constant CUSTOM_ERC20_BURN_SERVICE_NAME = "NokuCustomERC20.burn";
    bytes32 public constant CUSTOM_ERC20_MINT_SERVICE_NAME = "NokuCustomERC20.mint";

    /**
    * @dev Modifier to make a function callable only by service provider i.e. Noku.
    */
    modifier onlyServiceProvider() {
        require(msg.sender == serviceProvider);
        _;
    }

    function NokuCustomERC20(
        string _name,
        string _symbol,
        uint8 _decimals,
        address _pricingPlan,
        address _serviceProvider
    )
    DetailedERC20 (_name, _symbol, _decimals) public
    {
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        require(_pricingPlan != 0);
        require(_serviceProvider != 0);

        pricingPlan = _pricingPlan;
        serviceProvider = _serviceProvider;

        LogNokuCustomERC20Created(
            msg.sender,
            _name,
            _symbol,
            _decimals,
            _pricingPlan,
            _serviceProvider
        );
    }

    function isCustomToken() public pure returns(bool isCustom) {
        return true;
    }

    /**
    * @dev Change the transfer fee percentage to be paid in Custom tokens.
    * @param _transferFeePercentage The fee percentage to be paid for transfer in range [0, 100].
    */
    function setTransferFeePercentage(uint256 _transferFeePercentage) public onlyOwner {
        require(0 <= _transferFeePercentage && _transferFeePercentage <= 100);
        require(_transferFeePercentage != transferFeePercentage);

        transferFeePercentage = _transferFeePercentage;

        LogTransferFeePercentageChanged(msg.sender, _transferFeePercentage);
    }

    /**
    * @dev Change the pricing plan of service fee to be paid in NOKU tokens.
    * @param _pricingPlan The pricing plan of NOKU token to be paid, zero means flat subscription.
    */
    function setPricingPlan(address _pricingPlan) public onlyServiceProvider {
        require(_pricingPlan != 0);
        require(_pricingPlan != pricingPlan);

        pricingPlan = _pricingPlan;

        LogPricingPlanChanged(msg.sender, _pricingPlan);
    }

    /**
    * @dev Get the fee to be paid for the transfer of NOKU tokens.
    * @param _value The amount of NOKU tokens to be transferred.
    */
    function transferFee(uint256 _value) public view returns (uint256 usageFee) {
        return _value.mul(transferFeePercentage).div(100);
    }

    /**
    * @dev Override #transfer for optionally paying fee to Custom token owner.
    */
    function transfer(address _to, uint256 _value) public returns (bool transferred) {
        if (transferFeePercentage == 0) {
            return super.transfer(_to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transfer(owner, usageFee);
            bool netValueTransferred = super.transfer(_to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

    /**
    * @dev Override #transferFrom for optionally paying fee to Custom token owner.
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool transferred) {
        if (transferFeePercentage == 0) {
            return super.transferFrom(_from, _to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transferFrom(_from, owner, usageFee);
            bool netValueTransferred = super.transferFrom(_from, _to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

    /**
    * @dev Burn a specific amount of tokens, paying the service fee.
    * @param _amount The amount of token to be burned.
    */
    function burn(uint256 _amount) public {
        require(_amount > 0);

        super.burn(_amount);

        assert(NokuPricingPlan(pricingPlan).payFee(CUSTOM_ERC20_BURN_SERVICE_NAME, _amount, msg.sender));
    }

    /**
    * @dev Mint a specific amount of tokens, paying the service fee.
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool minted) {
        require(_to != 0);
        require(_amount > 0);

        super.mint(_to, _amount);

        assert(NokuPricingPlan(pricingPlan).payFee(CUSTOM_ERC20_MINT_SERVICE_NAME, _amount, msg.sender));

        return true;
    }
}

// File: contracts/NokuCustomERC20Service.sol

/**
* @dev The NokuCustomERC2Service contract .
*/
contract NokuCustomERC20Service is Pausable {
    event LogNokuCustomERC20ServiceCreated(address caller, address indexed pricingPlan);
    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers for using Noku services
    address public pricingPlan;

    bytes32 public constant CUSTOM_ERC20_CREATE_SERVICE_NAME = "NokuCustomERC20.create";

    function NokuCustomERC20Service(address _pricingPlan) public {
        require(_pricingPlan != 0);

        pricingPlan = _pricingPlan;

        LogNokuCustomERC20ServiceCreated(msg.sender, _pricingPlan);
    }

    function setPricingPlan(address _pricingPlan) public onlyOwner {
        require(_pricingPlan != 0);
        require(_pricingPlan != pricingPlan);
        
        pricingPlan = _pricingPlan;

        LogPricingPlanChanged(msg.sender, _pricingPlan);
    }

    function createCustomToken(string _name, string _symbol, uint8 _decimals)
    public returns(address customTokenAddress)
    {
        NokuCustomERC20 customToken = new NokuCustomERC20(_name, _symbol, _decimals, pricingPlan, owner);

        // Transfer NokuCustomERC20 ownership to the client
        customToken.transferOwnership(msg.sender);

        NokuPricingPlan(pricingPlan).payFee(CUSTOM_ERC20_CREATE_SERVICE_NAME, 1, msg.sender);

        return address(customToken);
    }
}