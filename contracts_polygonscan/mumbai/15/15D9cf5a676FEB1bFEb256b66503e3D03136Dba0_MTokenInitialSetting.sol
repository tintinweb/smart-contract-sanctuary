/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/MTokenInitialSettingInterface.sol


pragma solidity 0.8.0;



/// @title MTokenInitialSettingInterface
/// @dev Contract providing initial setting for creation of MToken contracts
interface MTokenInitialSettingInterface {

  /**
  * @dev Event emited when MToken creation price change
  * @param newPrice new price of MToken creation
  * @param oldPrice old price of MToken creation
  */
  event CreationPriceChanged(uint256 newPrice, uint256 oldPrice);

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newInitialSupplyOfReserveCurrency new amount of initial supply of reserve currency
  * @param oldInitialSupplyOfReserveCurrency old amount of initial supply of reserve currency
  */
  event ReserveCurrencyInitialSupplyChanged(uint256 newInitialSupplyOfReserveCurrency, uint256 oldInitialSupplyOfReserveCurrency);

  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getCreationPrice() 
    external
    view
    returns (uint256 creationPrice);

  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getReserveCurrencyInitialSupply() 
    external
    view
    returns (uint256 reserveCurrencyInitialSupply);
}

// File: contracts/MTokenInitialSetting.sol


pragma solidity 0.8.0;



/// @title MTokenInitialSetting
/// @dev Contract providing initial setting for creation of MToken contracts
contract MTokenInitialSetting is Ownable, MTokenInitialSettingInterface {


    string internal constant ERROR_PRICE_CAN_NOT_BE_ZERO = 'ERROR_PRICE_CAN_NOT_BE_ZERO';
    string internal constant ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO = 'ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO';
    string internal constant ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO = 'ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO';
    string internal constant ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO = 'ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO';
    string internal constant ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO = 'ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO';
    string internal constant ERROR_FEE_ABOVE_LIMIT = 'ERROR_FEE_ABOVE_LIMIT';
    string internal constant ERROR_FEE_LIMIT_ABOVE_OR_EQAULS_TO_HUNDRED_PERCENT = 'ERROR_FEE_LIMIT_ABOVE_OR_EQAULS_TO_HUNDRED_PERCENT';
    string internal constant ERROR_RESERVE_CURRENCY_WEIGHT_IS_ABOVE_MAX = 'ERROR_RESERVE_CURRENCY_WEIGHT_IS_ABOVE_MAX';

    uint16 internal constant ONE_HUNDRED_PERCENT = 10000;
    uint32 internal constant MAX_RESERVE_CURRENCY_WEIGHT = 1000000;

  /** 
  * @dev Structure what hold MToken initial settings
  * @param mTokenCreationPrice Price of mToken creation/registration
  * @param mTokenInitialSupply Amount of initial supply of newly created
  * @param mTokenInitialFee initial fee to set for newly created mToken
  * @param mTokenInitialFeeLimit initial fee limit to set for newly created mToken
  * @param mTokenReserveCurrencyInitialSupply Amount of reserve currency to be transfered to newly created contract as initial reserve currency supply  
  * @param reserveCurrencyWeight weight of reserve currency compared to created mTokens
  * (creationPrice, initialSupply, fee, feeLimit, reserveCurrencyWeight, reserveCurrencyInitialSupply)
  */
  struct MTokenSetting {
    uint256 creationPrice;
    uint256 initialSupply;
    uint16 fee;
    uint16 feeLimit;
    uint32 reserveCurrencyWeight;
    uint256 reserveCurrencyInitialSupply;
  }

  MTokenSetting public mTokenSetting;

  /**
  * @dev modifier Throws when value is not above zero
  */
  modifier aboveZero(uint256 _value, string memory _error) {
    require(_value > 0, _error);
    _;
  }

  /**
  * @dev modifier Throws when provided _fee is above fee limit property
  */
  modifier feeSmallerThanLimit(uint16 _fee, uint16 _feeLimit) {
    require(_fee < _feeLimit, ERROR_FEE_ABOVE_LIMIT);
    _;
  }

  /**
  * @dev modifier Throws when provided _feeLimit is above fee limit property
  */
  modifier feeLimitSmallerThanHundredPercent(uint16 _feeLimit) {
    require(_feeLimit < ONE_HUNDRED_PERCENT, ERROR_FEE_LIMIT_ABOVE_OR_EQAULS_TO_HUNDRED_PERCENT);
    _;
  }

  /**
  * @dev modifier Throws when provided _feeLimit is above fee limit property
  */
  modifier reserveCurrencyWeightBelowMax(uint32 _reserveCurrencyWeight) {
    require(_reserveCurrencyWeight <= MAX_RESERVE_CURRENCY_WEIGHT, ERROR_RESERVE_CURRENCY_WEIGHT_IS_ABOVE_MAX);
    _;
  }

  constructor(    
    uint256 _creationPrice,
    uint256 _initialSupply,
    uint16 _fee,
    uint16 _feeLimit,
    uint32 _reserveCurrencyWeight,
    uint256 _reserveCurrencyInitialSupply
  ) {
    MTokenSetting memory _mTokenSetting = MTokenSetting(
      _creationPrice,
      _initialSupply,
      _fee,
      _feeLimit,
      _reserveCurrencyWeight,
      _reserveCurrencyInitialSupply
    );

    checkCosntructorRequirements(_mTokenSetting);

    mTokenSetting = _mTokenSetting;
  }

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newInitialSupply new amount of initial supply
  * @param oldInitialSupply old amount of initial supply
  */
  event InitialSupplyChanged(uint256 newInitialSupply, uint256 oldInitialSupply);

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newFee new amount of initial supply
  * @param oldFee old amount of initial supply
  */
  event InitialFeeChanged(uint256 newFee, uint256 oldFee);

  /**
  * @dev Event emited when MToken initial reserve currency changed
  * @param newFeeLimit new amount of initial supply
  * @param oldFeeLimit old amount of initial supply
  */
  event InitialFeeLimitChanged(uint256 newFeeLimit, uint256 oldFeeLimit);


  /**
  * @dev Weight of reserve currency compared to printed mToken coins
  * @param newWeight new weight
  * @param oldWeight old weight
  */
  event ReserveCurrencyWeightChanged(uint32 newWeight, uint32 oldWeight);  


  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getMTokenInitialSetting() 
    public
    view
    returns (MTokenSetting memory currentSetting)
  {
    return mTokenSetting;
  }


  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getCreationPrice() 
    public
    view
    override
    returns (uint256 creationPrice)
  {
    return mTokenSetting.creationPrice;
  }

  /**
  * @dev Explicit method returing MTokenSetting structure
  */
  function getReserveCurrencyInitialSupply() 
    public
    view
    override
    returns (uint256 creationPrice)
  {
    return mTokenSetting.reserveCurrencyInitialSupply;
  }


  /**
  * @dev Sets new price for creation MToken contracts
  * @param _price new price for MToken creation
  */
  function setCreationPrice(uint256 _price)
    public
    onlyOwner
    aboveZero(_price, ERROR_PRICE_CAN_NOT_BE_ZERO)
  {
    uint256 oldPrice = mTokenSetting.creationPrice;

    mTokenSetting.creationPrice = _price;

    emit CreationPriceChanged(mTokenSetting.creationPrice, oldPrice);
  }

  /**
  * @dev Sets initial supply of reseve currency transfered to newly created mToken.
  * @param _mTokenReserveCurrencyInitialSupply amount of reserve currency as initial supply
  */
  function setReserveCurrencyInitialSupply(uint256 _mTokenReserveCurrencyInitialSupply)
    public
    onlyOwner
    aboveZero(_mTokenReserveCurrencyInitialSupply, ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO)
  {
    uint256 oldMTokenInitialReserveCurrencySupply = mTokenSetting.reserveCurrencyInitialSupply;

    mTokenSetting.reserveCurrencyInitialSupply = _mTokenReserveCurrencyInitialSupply;

    emit ReserveCurrencyInitialSupplyChanged(mTokenSetting.reserveCurrencyInitialSupply, oldMTokenInitialReserveCurrencySupply);
  }

  /**
  * @dev Sets initial supply of newly created MToken contract.
  * @param _mTokenInitialSupply amount of initial supply
  */
  function setInitialSupply(uint256 _mTokenInitialSupply)
    public
    onlyOwner
    aboveZero(_mTokenInitialSupply, ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO)
  {
    uint256 oldMTokenInitialSupply = mTokenSetting.initialSupply;

    mTokenSetting.initialSupply = _mTokenInitialSupply;

    emit InitialSupplyChanged(mTokenSetting.initialSupply, oldMTokenInitialSupply);
  }

  /**
  * @dev Sets mToken initial buy/sale fee.
  * @param _fee initial fee of newly created mToken
  */
  function setInitialFee(uint16 _fee)
    public
    onlyOwner
    feeSmallerThanLimit(_fee, mTokenSetting.feeLimit)
  {
    uint16 oldFee = mTokenSetting.fee;

    mTokenSetting.fee = _fee;

    emit InitialFeeChanged(mTokenSetting.fee, oldFee);
  }

  /**
  * @dev Sets mToken initial buy/sale fee limit.
  * @param _feeLimit initial fee of newly created mToken
  */
  function setInitialFeeLimit(uint16 _feeLimit)
    public
    onlyOwner
    aboveZero(_feeLimit, ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO)
    feeLimitSmallerThanHundredPercent(_feeLimit)
  {
    uint16 oldFeeLimit = mTokenSetting.feeLimit;

    mTokenSetting.feeLimit = _feeLimit;

    emit InitialFeeLimitChanged(mTokenSetting.feeLimit, oldFeeLimit);
  }

  /**
  * @dev Sets weight of reserve currency compared to mToken coins
  * @param _weight hit some heavy numbers !! :)
  */
  function setReserveCurrencyWeight(uint32 _weight)
    public
    onlyOwner
    aboveZero(_weight, ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO)
    reserveCurrencyWeightBelowMax(_weight)
  {
    uint32 oldReserveCurrencyWeight = mTokenSetting.reserveCurrencyWeight;

    mTokenSetting.reserveCurrencyWeight = _weight;

    emit ReserveCurrencyWeightChanged(mTokenSetting.reserveCurrencyWeight, oldReserveCurrencyWeight);
  }


  /**
  * @dev modifiers evaluating constructor requirements moved over here to avoid "Stack Too Deep" error
  */
  function checkCosntructorRequirements(MTokenSetting memory _mTokenSetting)
    private
    aboveZero(_mTokenSetting.creationPrice, ERROR_PRICE_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.initialSupply, ERROR_INITIAL_SUPPLY_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.reserveCurrencyWeight, ERROR_RESERVE_CURRENCY_WEIGHT_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.reserveCurrencyInitialSupply, ERROR_RESERVE_CURRENCY_SUPPLY_CAN_NOT_BE_ZERO)
    aboveZero(_mTokenSetting.feeLimit, ERROR_FEE_LIMIT_CAN_NOT_BE_ZERO)
    feeLimitSmallerThanHundredPercent(_mTokenSetting.feeLimit)
    feeSmallerThanLimit(_mTokenSetting.fee, _mTokenSetting.feeLimit)
    reserveCurrencyWeightBelowMax(_mTokenSetting.reserveCurrencyWeight)
  { }
}