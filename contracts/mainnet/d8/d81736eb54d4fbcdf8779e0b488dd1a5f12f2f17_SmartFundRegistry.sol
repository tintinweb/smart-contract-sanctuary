/**
 *Submitted for verification at Etherscan.io on 2020-05-12
*/

pragma solidity ^0.6.0;

interface PermittedConvertsInterface {
  function permittedAddresses(address _address) external view returns(bool);
}
interface PermittedStablesInterface {
  function permittedAddresses(address _address) external view returns(bool);
}
interface PermittedPoolsInterface {
  function permittedAddresses(address _address) external view returns(bool);
}
interface PermittedExchangesInterface {
  function permittedAddresses(address _address) external view returns(bool);
}
interface SmartFundUSDFactoryInterface {
  function createSmartFund(
    address _owner,
    string  calldata _name,
    uint256 _successFee,
    uint256 _platformFee,
    address _platfromAddress,
    address _exchangePortalAddress,
    address _permittedExchanges,
    address _permittedPools,
    address _permittedStabels,
    address _poolPortalAddress,
    address _stableCoinAddress,
    address _cEther,
    address _permittedConvertsAddress
    )
  external
  returns(address);
}
interface SmartFundETHFactoryInterface {
  function createSmartFund(
    address _owner,
    string  calldata _name,
    uint256 _successFee,
    uint256 _platformFee,
    address _platfromAddress,
    address _exchangePortalAddress,
    address _permittedExchanges,
    address _permittedPools,
    address _poolPortalAddress,
    address _cEther,
    address _permittedConvertsAddress
    )
  external
  returns(address);
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

  // The Smart Contract which stores the addresses of all the authorized Exchange Portals
  PermittedExchangesInterface public permittedExchanges;
  // The Smart Contract which stores the addresses of all the authorized Pool Portals
  PermittedPoolsInterface public permittedPools;
  // The Smart Contract which stores the addresses of all the authorized stable coins
  PermittedStablesInterface public permittedStables;
  // The Smart Contract which stores the addresses of all the authorized Converts portal
  PermittedConvertsInterface public permittedConverts;

  // Addresses of portals
  address public poolPortalAddress;
  address public exchangePortalAddress;
  address public convertPortalAddress;

  // platForm fee is out of 10,000, e.g 2500 is 25%
  uint256 public platformFee;

  // Default maximum success fee is 3000/30%
  uint256 public maximumSuccessFee = 3000;

  // Address of stable coin can be set in constructor and changed via function
  address public stableCoinAddress;

  // Addresses for Compound platform
  address public cEther;

  // Factories
  SmartFundETHFactoryInterface public smartFundETHFactory;
  SmartFundUSDFactoryInterface public smartFundUSDFactory;

  event SmartFundAdded(address indexed smartFundAddress, address indexed owner);

  /**
  * @dev contructor
  *
  * @param _convertPortalAddress         address of convert portal contract
  * @param _platformFee                  Initial platform fee
  * @param _permittedExchangesAddress    Address of the permittedExchanges contract
  * @param _exchangePortalAddress        Address of the initial ExchangePortal contract
  * @param _permittedPoolAddress         Address of the permittedPool contract
  * @param _poolPortalAddress            Address of the initial PoolPortal contract
  * @param _permittedStables             Address of the permittesStabels contract
  * @param _stableCoinAddress            Address of the stable coin
  * @param _smartFundETHFactory          Address of smartFund ETH factory
  * @param _smartFundUSDFactory          Address of smartFund USD factory
  * @param _cEther                       Address of Compound ETH wrapper
  * @param _permittedConvertsAddress     Address of the permittedConverts contract
  */
  constructor(
    address _convertPortalAddress,
    uint256 _platformFee,
    address _permittedExchangesAddress,
    address _exchangePortalAddress,
    address _permittedPoolAddress,
    address _poolPortalAddress,
    address _permittedStables,
    address _stableCoinAddress,
    address _smartFundETHFactory,
    address _smartFundUSDFactory,
    address _cEther,
    address _permittedConvertsAddress
  ) public {
    convertPortalAddress = _convertPortalAddress;
    platformFee = _platformFee;
    exchangePortalAddress = _exchangePortalAddress;
    permittedExchanges = PermittedExchangesInterface(_permittedExchangesAddress);
    permittedPools = PermittedPoolsInterface(_permittedPoolAddress);
    permittedStables = PermittedStablesInterface(_permittedStables);
    poolPortalAddress = _poolPortalAddress;
    stableCoinAddress = _stableCoinAddress;
    smartFundETHFactory = SmartFundETHFactoryInterface(_smartFundETHFactory);
    smartFundUSDFactory = SmartFundUSDFactoryInterface(_smartFundUSDFactory);
    cEther = _cEther;
    permittedConverts = PermittedConvertsInterface(_permittedConvertsAddress);
  }

  /**
  * @dev Creates a new SmartFund
  *
  * @param _name               The name of the new fund
  * @param _successFee         The fund managers success fee
  * @param _isStableBasedFund  true for USD base fund, false for ETH base
  */
  function createSmartFund(
    string memory _name,
    uint256 _successFee,
    bool _isStableBasedFund
  ) public {
    // Require that the funds success fee be less than the maximum allowed amount
    require(_successFee <= maximumSuccessFee);

    address owner = msg.sender;
    address smartFund;

    if(_isStableBasedFund){
      // Create USD Fund
      smartFund = smartFundUSDFactory.createSmartFund(
        owner,
        _name,
        _successFee,
        platformFee,
        exchangePortalAddress,
        address(permittedExchanges),
        address(permittedPools),
        address(permittedStables),
        poolPortalAddress,
        stableCoinAddress,
        convertPortalAddress,
        cEther,
        address(permittedConverts)
      );
    }else{
      // Create ETH Fund
      smartFund = smartFundETHFactory.createSmartFund(
        owner,
        _name,
        _successFee,
        platformFee,
        exchangePortalAddress,
        address(permittedExchanges),
        address(permittedPools),
        poolPortalAddress,
        convertPortalAddress,
        cEther,
        address(permittedConverts)
      );
    }

    smartFunds.push(smartFund);
    emit SmartFundAdded(smartFund, owner);
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
  * @dev Sets a new default ExchangePortal address
  *
  * @param _newExchangePortalAddress    Address of the new exchange portal to be set
  */
  function setExchangePortalAddress(address _newExchangePortalAddress) public onlyOwner {
    // Require that the new exchange portal is permitted by permittedExchanges
    require(permittedExchanges.permittedAddresses(_newExchangePortalAddress));

    exchangePortalAddress = _newExchangePortalAddress;
  }

  /**
  * @dev Sets a new default Portal Portal address
  *
  * @param _poolPortalAddress    Address of the new pool portal to be set
  */
  function setPoolPortalAddress (address _poolPortalAddress) external onlyOwner {
    // Require that the new pool portal is permitted by permittedPools
    require(permittedPools.permittedAddresses(_poolPortalAddress));

    poolPortalAddress = _poolPortalAddress;
  }


  /**
  * @dev Sets a new default Convert Portal address
  *
  * @param _convertPortalAddress    Address of the new convert portal to be set
  */
  function setConvertPortalAddress(address _convertPortalAddress) external onlyOwner {
    // Require that the new convert portal is permitted by permittedConverts
    require(permittedConverts.permittedAddresses(_convertPortalAddress));

    convertPortalAddress = _convertPortalAddress;
  }

  /**
  * @dev Sets maximum success fee for all newly created SmartFunds
  *
  * @param _maximumSuccessFee    New maximum success fee
  */
  function setMaximumSuccessFee(uint256 _maximumSuccessFee) external onlyOwner {
    maximumSuccessFee = _maximumSuccessFee;
  }

  /**
  * @dev Sets platform fee for all newly created SmartFunds
  *
  * @param _platformFee    New platform fee
  */
  function setPlatformFee(uint256 _platformFee) external onlyOwner {
    platformFee = _platformFee;
  }


  /**
  * @dev Sets new stableCoinAddress
  *
  * @param _stableCoinAddress    New stable address
  */
  function setStableCoinAddress(address _stableCoinAddress) external onlyOwner {
    require(permittedStables.permittedAddresses(_stableCoinAddress));
    stableCoinAddress = _stableCoinAddress;
  }

  /**
  * @dev Allows platform to withdraw tokens received as part of the platform fee
  *
  * @param _tokenAddress    Address of the token to be withdrawn
  */
  function withdrawTokens(address _tokenAddress) external onlyOwner {
    IERC20 token = IERC20(_tokenAddress);

    token.transfer(owner(), token.balanceOf(address(this)));
  }

  /**
  * @dev Allows platform to withdraw ether received as part of the platform fee
  */
  function withdrawEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  // Fallback payable function in order to receive ether when fund manager withdraws their cut
  fallback() external payable {}

}