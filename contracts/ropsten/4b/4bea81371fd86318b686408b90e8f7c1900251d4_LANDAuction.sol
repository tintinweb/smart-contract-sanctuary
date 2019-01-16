pragma solidity ^0.4.24;

// File: zos-lib/contracts/Initializable.sol

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
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
  function initialize(address sender) public initializer {
    _owner = sender;
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

  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
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

// File: openzeppelin-eth/contracts/utils/Address.sol

/**
 * Utility library of inline functions on addresses
 */
library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/libs/SafeERC20.sol

/**
* @dev Library to perform safe calls to standard method for ERC20 tokens.
* Transfers : transfer methods could have a return value (bool), revert for insufficient funds or
* unathorized value.
*
* Approve: approve method could has a return value (bool) or does not accept 0 as a valid value (BNB token).
* The common strategy used to clean approvals.
*/
library SafeERC20 {
    /**
    * @dev Transfer token for a specified address
    * @param _token erc20 The address of the ERC20 contract
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    */
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        require(prevBalance >= _value, "Insufficient funds");

        bool success = address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _value)
        );

        if (!success) {
            return false;
        }

        require(prevBalance - _value == _token.balanceOf(address(this)), "Transfer failed");

        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _token erc20 The address of the ERC20 contract
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    */
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to, 
        uint256 _value
    ) internal returns (bool) 
    {
        uint256 prevBalance = _token.balanceOf(_from);

        require(prevBalance >= _value, "Insufficient funds");
        require(_token.allowance(_from, address(this)) >= _value, "Insufficient allowance");

        bool success = address(_token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value)
        );

        if (!success) {
            return false;
        }

        require(prevBalance - _value == _token.balanceOf(_from), "Transfer failed");

        return true;
    }

   /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * 
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function safeApprove(IERC20 _token, address _spender, uint256 _value) internal returns (bool) {
        bool success = address(_token).call(
            abi.encodeWithSignature("approve(address,uint256)",_spender, _value)
        ); 

        if (!success) {
            return false;
        }

        require(_token.allowance(address(this), _spender) == _value, "Approve failed");

        return true;
    }

   /** 
   * @dev Clear approval
   * Note that if 0 is not a valid value it will be set to 1.
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   */
    function clearApprove(IERC20 _token, address _spender) internal returns (bool) {
        bool success = safeApprove(_token, _spender, 0);

        if (!success) {
            return safeApprove(_token, _spender, 1);
        }

        return true;
    }
}

// File: contracts/dex/ITokenConverter.sol

contract ITokenConverter {    
    using SafeMath for uint256;

    /**
    * @dev Makes a simple ERC20 -> ERC20 token trade
    * @param _srcToken - IERC20 token
    * @param _destToken - IERC20 token 
    * @param _srcAmount - uint256 amount to be converted
    * @param _destAmount - uint256 amount to get after conversion
    * @return uint256 for the change. 0 if there is no change
    */
    function convert(
        IERC20 _srcToken,
        IERC20 _destToken,
        uint256 _srcAmount,
        uint256 _destAmount
        ) external returns (uint256);

    /**
    * @dev Get exchange rate and slippage rate. 
    * Note that these returned values are in 18 decimals regardless of the destination token&#39;s decimals.
    * @param _srcToken - IERC20 token
    * @param _destToken - IERC20 token 
    * @param _srcAmount - uint256 amount to be converted
    * @return uint256 of the expected rate
    * @return uint256 of the slippage rate
    */
    function getExpectedRate(IERC20 _srcToken, IERC20 _destToken, uint256 _srcAmount) 
        public view returns(uint256 expectedRate, uint256 slippageRate);
}

// File: contracts/auction/LANDAuctionStorage.sol

/**
* @title ERC20 Interface with burn
* @dev IERC20 imported in ItokenConverter.sol
*/
contract ERC20 is IERC20 {
    function burn(uint256 _value) public;
}


/**
* @title Interface for contracts conforming to ERC-721
*/
contract LANDRegistry {
    function assignMultipleParcels(int[] x, int[] y, address beneficiary) external;
}


contract LANDAuctionStorage {
    uint256 constant public PERCENTAGE_OF_TOKEN_BALANCE = 5;
    uint256 constant public MAX_DECIMALS = 18;

    enum Status { created, finished }

    struct Func {
        uint256 slope;
        uint256 base;
        uint256 limit;
    }

    struct Token {
        uint256 decimals;
        bool shouldBurnTokens;
        bool shouldForwardTokens;
        address forwardTarget;
        bool isAllowed;
    }

    uint256 public conversionFee = 105;
    uint256 public totalBids = 0;
    Status public status;
    uint256 public gasPriceLimit;
    uint256 public landsLimitPerBid;
    ERC20 public manaToken;
    LANDRegistry public landRegistry;
    ITokenConverter public dex;
    mapping (address => Token) public tokensAllowed;
    uint256 public totalManaBurned = 0;
    uint256 public totalLandsBidded = 0;
    uint256 public startTime;
    uint256 public endTime;

    Func[] internal curves;
    uint256 internal initialPrice;
    uint256 internal endPrice;
    uint256 internal duration;

    event AuctionCreated(
      address indexed _caller,
      uint256 _startTime,
      uint256 _duration,
      uint256 _initialPrice,
      uint256 _endPrice
    );

    event BidConversion(
      uint256 _bidId,
      address indexed _token,
      uint256 _requiredManaAmountToBurn,
      uint256 _amountOfTokenConverted,
      uint256 _requiredTokenBalance
    );

    event BidSuccessful(
      uint256 _bidId,
      address indexed _beneficiary,
      address indexed _token,
      uint256 _pricePerLandInMana,
      uint256 _manaAmountToBurn,
      int[] _xs,
      int[] _ys
    );

    event AuctionFinished(
      address indexed _caller,
      uint256 _time,
      uint256 _pricePerLandInMana
    );

    event TokenBurned(
      uint256 _bidId,
      address indexed _token,
      uint256 _total
    );

    event TokenTransferred(
      uint256 _bidId,
      address indexed _token,
      address indexed _to,
      uint256 _total
    );

    event LandsLimitPerBidChanged(
      address indexed _caller,
      uint256 _oldLandsLimitPerBid, 
      uint256 _landsLimitPerBid
    );

    event GasPriceLimitChanged(
      address indexed _caller,
      uint256 _oldGasPriceLimit,
      uint256 _gasPriceLimit
    );

    event DexChanged(
      address indexed _caller,
      address indexed _oldDex,
      address indexed _dex
    );

    event TokenAllowed(
      address indexed _caller,
      address indexed _address,
      uint256 _decimals,
      bool _shouldBurnTokens,
      bool _shouldForwardTokens,
      address indexed _forwardTarget
    );

    event TokenDisabled(
      address indexed _caller,
      address indexed _address
    );

    event ConversionFeeChanged(
      address indexed _caller,
      uint256 _oldConversionFee,
      uint256 _conversionFee
    );
}

// File: contracts/auction/LANDAuction.sol

contract LANDAuction is Ownable, LANDAuctionStorage {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;

    /**
    * @dev Constructor of the contract.
    * Note that the last value of _xPoints will be the total duration and
    * the first value of _yPoints will be the initial price and the last value will be the endPrice
    * @param _xPoints - uint256[] of seconds
    * @param _yPoints - uint256[] of prices
    * @param _startTime - uint256 timestamp in seconds when the auction will start
    * @param _landsLimitPerBid - uint256 LAND limit for a single bid
    * @param _gasPriceLimit - uint256 gas price limit for a single bid
    * @param _manaToken - address of the MANA token
    * @param _landRegistry - address of the LANDRegistry
    * @param _dex - address of the Dex to convert ERC20 tokens allowed to MANA
    */
    constructor(
        uint256[] _xPoints, 
        uint256[] _yPoints, 
        uint256 _startTime,
        uint256 _landsLimitPerBid,
        uint256 _gasPriceLimit,
        ERC20 _manaToken,
        LANDRegistry _landRegistry,
        address _dex
    ) public {
        require(
            PERCENTAGE_OF_TOKEN_BALANCE == 5, 
            "Balance of tokens required should be equal to 5%"
        );
        // Initialize owneable
        Ownable.initialize(msg.sender);

        // Schedule auction
        require(_startTime > block.timestamp, "Started time should be after now");
        startTime = _startTime;

        // Set LANDRegistry
        require(
            address(_landRegistry).isContract(),
            "The LANDRegistry token address must be a deployed contract"
        );
        landRegistry = _landRegistry;

        setDex(_dex);

        // Set MANAToken
        allowToken(
            address(_manaToken), 
            18,
            true, 
            false, 
            address(0)
        );
        manaToken = _manaToken;

        // Set total duration of the auction
        duration = _xPoints[_xPoints.length - 1];
        require(duration > 1 days, "The duration should be greater than 1 day");

        // Set Curve
        _setCurve(_xPoints, _yPoints);

        // Set limits
        setLandsLimitPerBid(_landsLimitPerBid);
        setGasPriceLimit(_gasPriceLimit);
        
        // Initialize status
        status = Status.created;      

        emit AuctionCreated(
            msg.sender,
            startTime,
            duration,
            initialPrice, 
            endPrice
        );
    }

    /**
    * @dev Make a bid for LANDs
    * @param _xs - uint256[] x values for the LANDs to bid
    * @param _ys - uint256[] y values for the LANDs to bid
    * @param _beneficiary - address beneficiary for the LANDs to bid
    * @param _fromToken - token used to bid
    */
    function bid(
        int[] _xs, 
        int[] _ys, 
        address _beneficiary, 
        ERC20 _fromToken
    )
        external 
    {
        _validateBidParameters(
            _xs, 
            _ys, 
            _beneficiary, 
            _fromToken
        );
        
        uint256 bidId = _getBidId();
        uint256 bidPriceInMana = _xs.length.mul(getCurrentPrice());
        uint256 manaAmountToBurn = bidPriceInMana;

        if (address(_fromToken) != address(manaToken)) {
            require(
                address(dex).isContract(), 
                "Paying with other tokens has been disabled"
            );
            // Convert from the other token to MANA. The amount to be burned might be smaller
            // because 5% will be burned or forwarded without converting it to MANA.
            manaAmountToBurn = _convertSafe(bidId, _fromToken, bidPriceInMana);
        } else {
            // Transfer MANA to this contract
            require(
                _fromToken.safeTransferFrom(msg.sender, address(this), bidPriceInMana),
                "Insuficient balance or unauthorized amount (transferFrom failed)"
            );
        }

        // Process funds (burn or forward them)
        _processFunds(bidId, _fromToken);

        // Assign LANDs to the beneficiary user
        landRegistry.assignMultipleParcels(_xs, _ys, _beneficiary);

        emit BidSuccessful(
            bidId,
            _beneficiary,
            _fromToken,
            getCurrentPrice(),
            manaAmountToBurn,
            _xs,
            _ys
        );  

        // Update stats
        _updateStats(_xs.length, manaAmountToBurn);        
    }

    /** 
    * @dev Validate bid function params
    * @param _xs - int[] x values for the LANDs to bid
    * @param _ys - int[] y values for the LANDs to bid
    * @param _beneficiary - address beneficiary for the LANDs to bid
    * @param _fromToken - token used to bid
    */
    function _validateBidParameters(
        int[] _xs, 
        int[] _ys, 
        address _beneficiary, 
        ERC20 _fromToken
    ) internal view 
    {
        require(startTime <= block.timestamp, "The auction has not started");
        require(
            status == Status.created && 
            block.timestamp.sub(startTime) <= duration, 
            "The auction has finished"
        );
        require(tx.gasprice <= gasPriceLimit, "Gas price limit exceeded");
        require(_beneficiary != address(0), "The beneficiary could not be the 0 address");
        require(_xs.length > 0, "You should bid for at least one LAND");
        require(_xs.length <= landsLimitPerBid, "LAND limit exceeded");
        require(_xs.length == _ys.length, "X values length should be equal to Y values length");
        require(tokensAllowed[address(_fromToken)].isAllowed, "Token not allowed");
        for (uint256 i = 0; i < _xs.length; i++) {
            require(
                -150 <= _xs[i] && _xs[i] <= 150 && -150 <= _ys[i] && _ys[i] <= 150,
                "The coordinates should be inside bounds -150 & 150"
            );
        }
    }

    /**
    * @dev Current LAND price. 
    * Note that if the auction has not started returns the initial price and when
    * the auction is finished return the endPrice
    * @return uint256 current LAND price
    */
    function getCurrentPrice() public view returns (uint256) { 
        // If the auction has not started returns initialPrice
        if (startTime == 0 || startTime >= block.timestamp) {
            return initialPrice;
        }

        // If the auction has finished returns endPrice
        uint256 timePassed = block.timestamp - startTime;
        if (timePassed >= duration) {
            return endPrice;
        }

        return _getPrice(timePassed);
    }

    /**
    * @dev Convert allowed token to MANA and transfer the change in the original token
    * Note that we will use the slippageRate cause it has a 3% buffer and a deposit of 5% to cover
    * the conversion fee.
    * @param _bidId - uint256 of the bid Id
    * @param _fromToken - ERC20 token to be converted
    * @param _bidPriceInMana - uint256 of the total amount in MANA
    * @return uint256 of the total amount of MANA to burn
    */
    function _convertSafe(
        uint256 _bidId,
        ERC20 _fromToken,
        uint256 _bidPriceInMana
    ) internal returns (uint256 requiredManaAmountToBurn)
    {
        requiredManaAmountToBurn = _bidPriceInMana;
        Token memory fromToken = tokensAllowed[address(_fromToken)];

        uint256 bidPriceInManaPlusSafetyMargin = _bidPriceInMana.mul(conversionFee).div(100);

        // Get rate
        uint256 tokenRate = getRate(manaToken, _fromToken, bidPriceInManaPlusSafetyMargin);

        // Check if contract should burn or transfer some tokens
        uint256 requiredTokenBalance = 0;
        
        if (fromToken.shouldBurnTokens || fromToken.shouldForwardTokens) {
            requiredTokenBalance = _calculateRequiredTokenBalance(requiredManaAmountToBurn, tokenRate);
            requiredManaAmountToBurn = _calculateRequiredManaAmount(_bidPriceInMana);
        }

        // Calculate the amount of _fromToken to be converted
        uint256 tokensToConvertPlusSafetyMargin = bidPriceInManaPlusSafetyMargin
            .mul(tokenRate)
            .div(10 ** 18);

        // Normalize to _fromToken decimals
        if (MAX_DECIMALS > fromToken.decimals) {
            requiredTokenBalance = _normalizeDecimals(
                fromToken.decimals, 
                requiredTokenBalance
            );
            tokensToConvertPlusSafetyMargin = _normalizeDecimals(
                fromToken.decimals,
                tokensToConvertPlusSafetyMargin
            );
        }

        // Retrieve tokens from the sender to this contract
        require(
            _fromToken.safeTransferFrom(msg.sender, address(this), tokensToConvertPlusSafetyMargin),
            "Transfering the totalPrice in token to LANDAuction contract failed"
        );
        
        // Calculate the total tokens to convert
        uint256 finalTokensToConvert = tokensToConvertPlusSafetyMargin.sub(requiredTokenBalance);

        // Approve amount of _fromToken owned by contract to be used by dex contract
        require(_fromToken.safeApprove(address(dex), finalTokensToConvert), "Error approve");

        // Convert _fromToken to MANA
        uint256 change = dex.convert(
                _fromToken,
                manaToken,
                finalTokensToConvert,
                requiredManaAmountToBurn
        );

       // Return change in _fromToken to sender
        if (change > 0) {
            // Return the change of src token
            require(
                _fromToken.safeTransfer(msg.sender, change),
                "Transfering the change to sender failed"
            );
        }

        // Remove approval of _fromToken owned by contract to be used by dex contract
        require(_fromToken.clearApprove(address(dex)), "Error clear approval");

        emit BidConversion(
            _bidId,
            address(_fromToken),
            requiredManaAmountToBurn,
            tokensToConvertPlusSafetyMargin.sub(change),
            requiredTokenBalance
        );
    }

    /**
    * @dev Get exchange rate
    * @param _srcToken - IERC20 token
    * @param _destToken - IERC20 token 
    * @param _srcAmount - uint256 amount to be converted
    * @return uint256 of the rate
    */
    function getRate(
        IERC20 _srcToken, 
        IERC20 _destToken, 
        uint256 _srcAmount
    ) public view returns (uint256 rate) 
    {
        (rate,) = dex.getExpectedRate(_srcToken, _destToken, _srcAmount);
    }

    /** 
    * @dev Calculate the amount of tokens to process
    * @param _totalPrice - uint256 price to calculate percentage to process
    * @param _tokenRate - rate to calculate the amount of tokens
    * @return uint256 of the amount of tokens required
    */
    function _calculateRequiredTokenBalance(
        uint256 _totalPrice,
        uint256 _tokenRate
    ) 
    internal pure returns (uint256) 
    {
        return _totalPrice.mul(_tokenRate)
            .div(10 ** 18)
            .mul(PERCENTAGE_OF_TOKEN_BALANCE)
            .div(100);
    }

    /** 
    * @dev Calculate the total price in MANA
    * Note that PERCENTAGE_OF_TOKEN_BALANCE will be always less than 100
    * @param _totalPrice - uint256 price to calculate percentage to keep
    * @return uint256 of the new total price in MANA
    */
    function _calculateRequiredManaAmount(
        uint256 _totalPrice
    ) 
    internal pure returns (uint256)
    {
        return _totalPrice.mul(100 - PERCENTAGE_OF_TOKEN_BALANCE).div(100);
    }

    /**
    * @dev Burn or forward the MANA and other tokens earned
    * Note that as we will transfer or burn tokens from other contracts.
    * We should burn MANA first to avoid a possible re-entrancy
    * @param _bidId - uint256 of the bid Id
    * @param _token - ERC20 token
    */
    function _processFunds(uint256 _bidId, ERC20 _token) internal {
        // Burn MANA
        _burnTokens(_bidId, manaToken);

        // Burn or forward token if it is not MANA
        Token memory token = tokensAllowed[address(_token)];
        if (_token != manaToken) {
            if (token.shouldBurnTokens) {
                _burnTokens(_bidId, _token);
            }
            if (token.shouldForwardTokens) {
                _forwardTokens(_bidId, token.forwardTarget, _token);
            }   
        }
    }

    /**
    * @dev LAND price based on time
    * Note that will select the function to calculate based on the time
    * It should return endPrice if _time < duration
    * @param _time - uint256 time passed before reach duration
    * @return uint256 price for the given time
    */
    function _getPrice(uint256 _time) internal view returns (uint256) {
        for (uint256 i = 0; i < curves.length; i++) {
            Func storage func = curves[i];
            if (_time < func.limit) {
                return func.base.sub(func.slope.mul(_time));
            }
        }
        revert("Invalid time");
    }

    /** 
    * @dev Burn tokens
    * @param _bidId - uint256 of the bid Id
    * @param _token - ERC20 token
    */
    function _burnTokens(uint256 _bidId, ERC20 _token) private {
        uint256 balance = _token.balanceOf(address(this));

        // Check if balance is valid
        require(balance > 0, "Balance to burn should be > 0");
        
        _token.burn(balance);

        emit TokenBurned(_bidId, address(_token), balance);

        // Check if balance of the auction contract is empty
        balance = _token.balanceOf(address(this));
        require(balance == 0, "Burn token failed");
    }

    /** 
    * @dev Forward tokens
    * @param _bidId - uint256 of the bid Id
    * @param _address - address to send the tokens to
    * @param _token - ERC20 token
    */
    function _forwardTokens(uint256 _bidId, address _address, ERC20 _token) private {
        uint256 balance = _token.balanceOf(address(this));

        // Check if balance is valid
        require(balance > 0, "Balance to burn should be > 0");
        
        _token.safeTransfer(_address, balance);

        emit TokenTransferred(
            _bidId, 
            address(_token), 
            _address,balance
        );

        // Check if balance of the auction contract is empty
        balance = _token.balanceOf(address(this));
        require(balance == 0, "Transfer token failed");
    }

    /**
    * @dev Set conversion fee rate
    * @param _fee - uint256 for the new conversion rate
    */
    function setConversionFee(uint256 _fee) external onlyOwner {
        require(_fee < 200 && _fee >= 100, "Conversion fee should be >= 100 and < 200");
        emit ConversionFeeChanged(msg.sender, conversionFee, _fee);
        conversionFee = _fee;
    }

    /**
    * @dev Finish auction 
    */
    function finishAuction() public onlyOwner {
        require(status != Status.finished, "The auction is finished");

        uint256 currentPrice = getCurrentPrice();

        status = Status.finished;
        endTime = block.timestamp;

        emit AuctionFinished(msg.sender, block.timestamp, currentPrice);
    }

    /**
    * @dev Set LAND for the auction
    * @param _landsLimitPerBid - uint256 LAND limit for a single id
    */
    function setLandsLimitPerBid(uint256 _landsLimitPerBid) public onlyOwner {
        require(_landsLimitPerBid > 0, "The LAND limit should be greater than 0");
        emit LandsLimitPerBidChanged(msg.sender, landsLimitPerBid, _landsLimitPerBid);
        landsLimitPerBid = _landsLimitPerBid;
    }

    /**
    * @dev Set gas price limit for the auction
    * @param _gasPriceLimit - uint256 gas price limit for a single bid
    */
    function setGasPriceLimit(uint256 _gasPriceLimit) public onlyOwner {
        require(_gasPriceLimit > 0, "The gas price should be greater than 0");
        emit GasPriceLimitChanged(msg.sender, gasPriceLimit, _gasPriceLimit);
        gasPriceLimit = _gasPriceLimit;
    }

    /**
    * @dev Set dex to convert ERC20
    * @param _dex - address of the token converter
    */
    function setDex(address _dex) public onlyOwner {
        require(_dex != address(dex), "The dex is the current");
        if (_dex != address(0)) {
            require(_dex.isContract(), "The dex address must be a deployed contract");
        }
        emit DexChanged(msg.sender, dex, _dex);
        dex = ITokenConverter(_dex);
    }

    /**
    * @dev Allow ERC20 to to be used for bidding
    * Note that if _shouldBurnTokens and _shouldForwardTokens are false, we 
    * will convert the total amount of the ERC20 to MANA
    * @param _address - address of the ERC20 Token
    * @param _decimals - uint256 of the number of decimals
    * @param _shouldBurnTokens - boolean whether we should burn funds
    * @param _shouldForwardTokens - boolean whether we should transferred funds
    * @param _forwardTarget - address where the funds will be transferred
    */
    function allowToken(
        address _address,
        uint256 _decimals,
        bool _shouldBurnTokens,
        bool _shouldForwardTokens,
        address _forwardTarget
    ) 
    public onlyOwner 
    {
        require(
            _address.isContract(),
            "Tokens allowed should be a deployed ERC20 contract"
        );
        require(
            _decimals > 0 && _decimals <= MAX_DECIMALS,
            "Decimals should be greather than 0 and less or equal to 18"
        );
        require(
            !(_shouldBurnTokens && _shouldForwardTokens),
            "The token should be either burned or transferred"
        );
        require(
            !_shouldForwardTokens || 
            (_shouldForwardTokens && _forwardTarget != address(0)),
            "The token should be transferred to a deployed contract"
        );
        require(
            _forwardTarget != address(this) && _forwardTarget != _address, 
            "The forward target should be different from  this contract and the erc20 token"
        );
        
        require(!tokensAllowed[_address].isAllowed, "The ERC20 token is already allowed");

        tokensAllowed[_address] = Token({
            decimals: _decimals,
            shouldBurnTokens: _shouldBurnTokens,
            shouldForwardTokens: _shouldForwardTokens,
            forwardTarget: _forwardTarget,
            isAllowed: true
        });

        emit TokenAllowed(
            msg.sender, 
            _address, 
            _decimals,
            _shouldBurnTokens,
            _shouldForwardTokens,
            _forwardTarget
        );
    }

    /**
    * @dev Disable ERC20 to to be used for bidding
    * @param _address - address of the ERC20 Token
    */
    function disableToken(address _address) public onlyOwner {
        require(
            tokensAllowed[_address].isAllowed,
            "The ERC20 token is already disabled"
        );
        delete tokensAllowed[_address];
        emit TokenDisabled(msg.sender, _address);
    }

    /** 
    * @dev Create a combined function.
    * note that we will set N - 1 function combinations based on N points (x,y)
    * @param _xPoints - uint256[] of x values
    * @param _yPoints - uint256[] of y values
    */
    function _setCurve(uint256[] _xPoints, uint256[] _yPoints) internal {
        uint256 pointsLength = _xPoints.length;
        require(pointsLength == _yPoints.length, "Points should have the same length");
        for (uint256 i = 0; i < pointsLength - 1; i++) {
            uint256 x1 = _xPoints[i];
            uint256 x2 = _xPoints[i + 1];
            uint256 y1 = _yPoints[i];
            uint256 y2 = _yPoints[i + 1];
            require(x1 < x2, "X points should increase");
            require(y1 > y2, "Y points should decrease");
            (uint256 base, uint256 slope) = _getFunc(
                x1, 
                x2, 
                y1, 
                y2
            );
            curves.push(Func({
                base: base,
                slope: slope,
                limit: x2
            }));
        }

        initialPrice = _yPoints[0];
        endPrice = _yPoints[pointsLength - 1];
    }

    /**
    * @dev Calculate base and slope for the given points
    * It is a linear function y = ax - b. But The slope should be negative.
    * As we want to avoid negative numbers in favor of using uints we use it as: y = b - ax
    * Based on two points (x1; x2) and (y1; y2)
    * base = (x2 * y1) - (x1 * y2) / (x2 - x1)
    * slope = (y1 - y2) / (x2 - x1) to avoid negative maths
    * @param _x1 - uint256 x1 value
    * @param _x2 - uint256 x2 value
    * @param _y1 - uint256 y1 value
    * @param _y2 - uint256 y2 value
    * @return uint256 for the base
    * @return uint256 for the slope
    */
    function _getFunc(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1, 
        uint256 _y2
    ) internal pure returns (uint256 base, uint256 slope) 
    {
        base = ((_x2.mul(_y1)).sub(_x1.mul(_y2))).div(_x2.sub(_x1));
        slope = (_y1.sub(_y2)).div(_x2.sub(_x1));
    }

    /**
    * @dev Return bid id
    * @return uint256 of the bid id
    */
    function _getBidId() private view returns (uint256) {
        return totalBids;
    }

    /** 
    * @dev Normalize to _fromToken decimals
    * @param _decimals - uint256 of _fromToken decimals
    * @param _value - uint256 of the amount to normalize
    */
    function _normalizeDecimals(
        uint256 _decimals, 
        uint256 _value
    ) 
    internal pure returns (uint256 _result) 
    {
        _result = _value.div(10**MAX_DECIMALS.sub(_decimals));
    }

    /** 
    * @dev Update stats. It will update the following stats:
    * - totalBids
    * - totalLandsBidded
    * - totalManaBurned
    * @param _landsBidded - uint256 of the number of LAND bidded
    * @param _manaAmountBurned - uint256 of the amount of MANA burned
    */
    function _updateStats(uint256 _landsBidded, uint256 _manaAmountBurned) private {
        totalBids = totalBids.add(1);
        totalLandsBidded = totalLandsBidded.add(_landsBidded);
        totalManaBurned = totalManaBurned.add(_manaAmountBurned);
    }
}