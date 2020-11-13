interface PermittedAddressesInterface {
  function permittedAddresses(address _address) external view returns(bool);
  function addressesTypes(address _address) external view returns(string memory);
  function isMatchTypes(address _address, uint256 addressType) external view returns(bool);
}
interface SmartFundERC20LightFactoryInterface {
  function createSmartFundLight(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _permittedAddresses,
    address _coinAddress,
    bool    _isRequireTradeVerification
  )
  external
  returns(address);
}
interface SmartFundETHLightFactoryInterface {
  function createSmartFundLight(
    address _owner,
    string  memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _permittedAddresses,
    bool    _isRequireTradeVerification
  )
  external
  returns(address);
}
interface SmartFundERC20FactoryInterface {
  function createSmartFund(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _defiPortal,
    address _permittedAddresses,
    address _coinAddress,
    bool    _isRequireTradeVerification
  )
  external
  returns(address);
}
interface SmartFundETHFactoryInterface {
  function createSmartFund(
    address _owner,
    string  memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _defiPortal,
    address _permittedAddresses,
    bool    _isRequireTradeVerification
  )
  external
  returns(address);
}
pragma solidity ^0.6.12;












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
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/*
* The SmartFundRegistry is used to manage the creation and permissions of SmartFund contracts
*/
contract SmartFundRegistry is Ownable {
  address[] public smartFunds;

  // The Smart Contract which stores the addresses of all the authorized address
  PermittedAddressesInterface public permittedAddresses;

  // Addresses of portals
  address public poolPortalAddress;
  address public exchangePortalAddress;
  address public defiPortalAddress;

  // Default maximum success fee is 3000/30%
  uint256 public maximumSuccessFee = 3000;

  // Address of stable coin can be set in constructor and changed via function
  address public stableCoinAddress;

  // Address of CoTrader coin be set in constructor
  address public COTCoinAddress;

  // Factories
  SmartFundETHFactoryInterface public smartFundETHFactory;
  SmartFundERC20FactoryInterface public smartFundERC20Factory;
  SmartFundETHLightFactoryInterface public smartFundETHLightFactory;
  SmartFundERC20LightFactoryInterface public smartFundERC20LightFactory;

  // Enum for detect fund type in create fund function
  // NOTE: You can add a new type at the end, but do not change this order
  enum FundType { ETH, USD, COT }

  event SmartFundAdded(address indexed smartFundAddress, address indexed owner);

  /**
  * @dev contructor
  *
  * @param _exchangePortalAddress        Address of the initial ExchangePortal contract
  * @param _poolPortalAddress            Address of the initial PoolPortal contract
  * @param _stableCoinAddress            Address of the stable coin
  * @param _COTCoinAddress               Address of Cotrader coin
  * @param _smartFundETHFactory          Address of smartFund ETH factory
  * @param _smartFundERC20Factory        Address of smartFund USD factory
  * @param _smartFundETHLightFactory     Address of smartFund ETH factory
  * @param _smartFundERC20LightFactory   Address of smartFund USD factory
  * @param _defiPortalAddress            Address of defiPortal contract
  * @param _permittedAddresses           Address of permittedAddresses contract
  */
  constructor(
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _stableCoinAddress,
    address _COTCoinAddress,
    address _smartFundETHFactory,
    address _smartFundERC20Factory,
    address _smartFundETHLightFactory,
    address _smartFundERC20LightFactory,
    address _defiPortalAddress,
    address _permittedAddresses
  ) public {
    exchangePortalAddress = _exchangePortalAddress;
    poolPortalAddress = _poolPortalAddress;
    stableCoinAddress = _stableCoinAddress;
    COTCoinAddress = _COTCoinAddress;
    smartFundETHFactory = SmartFundETHFactoryInterface(_smartFundETHFactory);
    smartFundERC20Factory = SmartFundERC20FactoryInterface(_smartFundERC20Factory);
    smartFundETHLightFactory = SmartFundETHLightFactoryInterface(_smartFundETHLightFactory);
    smartFundERC20LightFactory = SmartFundERC20LightFactoryInterface(_smartFundERC20LightFactory);
    defiPortalAddress = _defiPortalAddress;
    permittedAddresses = PermittedAddressesInterface(_permittedAddresses);
  }

  /**
  * @dev Creates a new Full SmartFund
  *
  * @param _name                        The name of the new fund
  * @param _successFee                  The fund managers success fee
  * @param _fundType                    Fund type enum number
  * @param _isRequireTradeVerification  If true fund can buy only tokens,
  *                                     which include in Merkle Three white list
  */
  function createSmartFund(
    string memory _name,
    uint256       _successFee,
    uint256       _fundType,
    bool          _isRequireTradeVerification
  ) public {
    // Require that the funds success fee be less than the maximum allowed amount
    require(_successFee <= maximumSuccessFee);

    address smartFund;

    // ETH case
    if(_fundType == uint256(FundType.ETH)){
      // Create ETH Fund
      smartFund = smartFundETHFactory.createSmartFund(
        msg.sender,
        _name,
        _successFee, // manager and platform fee
        exchangePortalAddress,
        poolPortalAddress,
        defiPortalAddress,
        address(permittedAddresses),
        _isRequireTradeVerification
      );

    }
    // ERC20 case
    else{
      address coinAddress = getERC20AddressByFundType(_fundType);
      // Create ERC20 based fund
      smartFund = smartFundERC20Factory.createSmartFund(
        msg.sender,
        _name,
        _successFee, // manager and platform fee
        exchangePortalAddress,
        poolPortalAddress,
        defiPortalAddress,
        address(permittedAddresses),
        coinAddress,
        _isRequireTradeVerification
      );
    }

    smartFunds.push(smartFund);
    emit SmartFundAdded(smartFund, msg.sender);
  }

  /**
  * @dev Creates a new Light SmartFund
  *
  * @param _name                        The name of the new fund
  * @param _successFee                  The fund managers success fee
  * @param _fundType                    Fund type enum number
  * @param _isRequireTradeVerification  If true fund can buy only tokens,
  *                                     which include in Merkle Three white list
  */
  function createSmartFundLight(
    string memory _name,
    uint256       _successFee,
    uint256       _fundType,
    bool          _isRequireTradeVerification
  ) public {
    // Require that the funds success fee be less than the maximum allowed amount
    require(_successFee <= maximumSuccessFee);

    address smartFund;

    // ETH case
    if(_fundType == uint256(FundType.ETH)){
      // Create ETH Fund
      smartFund = smartFundETHLightFactory.createSmartFundLight(
        msg.sender,
        _name,
        _successFee, // manager and platform fee
        exchangePortalAddress,
        address(permittedAddresses),
        _isRequireTradeVerification
      );

    }
    // ERC20 case
    else{
      address coinAddress = getERC20AddressByFundType(_fundType);
      // Create ERC20 based fund
      smartFund = smartFundERC20LightFactory.createSmartFundLight(
        msg.sender,
        _name,
        _successFee, // manager and platform fee
        exchangePortalAddress,
        address(permittedAddresses),
        coinAddress,
        _isRequireTradeVerification
      );
    }

    smartFunds.push(smartFund);
    emit SmartFundAdded(smartFund, msg.sender);
  }


  function getERC20AddressByFundType(uint256 _fundType) private view returns(address coinAddress){
    // Define coin address dependse of fund type
    coinAddress = _fundType == uint256(FundType.USD)
    ? stableCoinAddress
    : COTCoinAddress;
  }

  function totalSmartFunds() public view returns (uint256) {
    return smartFunds.length;
  }

  function getAllSmartFundAddresses() public view returns(address[] memory) {
    address[] memory addresses = new address[](smartFunds.length);

    for (uint i; i < smartFunds.length; i++) {
      addresses[i] = address(smartFunds[i]);
    }

    return addresses;
  }

  /**
  * @dev Owner can set a new default ExchangePortal address
  *
  * @param _newExchangePortalAddress    Address of the new exchange portal to be set
  */
  function setExchangePortalAddress(address _newExchangePortalAddress) external onlyOwner {
    // Require that the new exchange portal is permitted by permittedAddresses
    require(permittedAddresses.permittedAddresses(_newExchangePortalAddress));

    exchangePortalAddress = _newExchangePortalAddress;
  }

  /**
  * @dev Owner can set a new default Portal Portal address
  *
  * @param _poolPortalAddress    Address of the new pool portal to be set
  */
  function setPoolPortalAddress(address _poolPortalAddress) external onlyOwner {
    // Require that the new pool portal is permitted by permittedAddresses
    require(permittedAddresses.permittedAddresses(_poolPortalAddress));

    poolPortalAddress = _poolPortalAddress;
  }

  /**
  * @dev Allows the fund manager to connect to a new permitted defi portal
  *
  * @param _newDefiPortalAddress    The address of the new permitted defi portal to use
  */
  function setDefiPortal(address _newDefiPortalAddress) public onlyOwner {
    // Require that the new defi portal is permitted by permittedAddresses
    require(permittedAddresses.permittedAddresses(_newDefiPortalAddress));

    defiPortalAddress = _newDefiPortalAddress;
  }

  /**
  * @dev Owner can set maximum success fee for all newly created SmartFunds
  *
  * @param _maximumSuccessFee    New maximum success fee
  */
  function setMaximumSuccessFee(uint256 _maximumSuccessFee) external onlyOwner {
    maximumSuccessFee = _maximumSuccessFee;
  }

  /**
  * @dev Owner can set new stableCoinAddress
  *
  * @param _stableCoinAddress    New stable address
  */
  function setStableCoinAddress(address _stableCoinAddress) external onlyOwner {
    require(permittedAddresses.permittedAddresses(_stableCoinAddress));
    stableCoinAddress = _stableCoinAddress;
  }


  /**
  * @dev Owner can set new smartFundETHFactory
  *
  * @param _smartFundETHFactory    address of ETH factory contract
  */
  function setNewSmartFundETHFactory(address _smartFundETHFactory) external onlyOwner {
    smartFundETHFactory = SmartFundETHFactoryInterface(_smartFundETHFactory);
  }


  /**
  * @dev Owner can set new smartFundERC20Factory
  *
  * @param _smartFundERC20Factory    address of ERC20 factory contract
  */
  function setNewSmartFundERC20Factory(address _smartFundERC20Factory) external onlyOwner {
    smartFundERC20Factory = SmartFundERC20FactoryInterface(_smartFundERC20Factory);
  }


  /**
  * @dev Owner can set new smartFundETHLightFactory
  *
  * @param _smartFundETHLightFactory    address of ETH factory contract
  */
  function setNewSmartFundETHLightFactory(address _smartFundETHLightFactory) external onlyOwner {
      smartFundETHLightFactory = SmartFundETHLightFactoryInterface(_smartFundETHLightFactory);
  }

  /**
  * @dev Owner can set new smartFundERC20LightFactory
  *
  * @param _smartFundERC20LightFactory    address of ERC20 factory contract
  */
  function setNewSmartFundERC20LightFactory(address _smartFundERC20LightFactory) external onlyOwner {
    smartFundERC20LightFactory = SmartFundERC20LightFactoryInterface(_smartFundERC20LightFactory);
  }

  /**
  * @dev Allows withdarw tokens from this contract if someone will accidentally send tokens here
  *
  * @param _tokenAddress    Address of the token to be withdrawn
  */
  function withdrawTokens(address _tokenAddress) external onlyOwner {
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  /**
  * @dev Allows withdarw ETH from this contract if someone will accidentally send tokens here
  */
  function withdrawEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  // Fallback payable function in order to receive ether when fund manager withdraws their cut
  fallback() external payable {}

}