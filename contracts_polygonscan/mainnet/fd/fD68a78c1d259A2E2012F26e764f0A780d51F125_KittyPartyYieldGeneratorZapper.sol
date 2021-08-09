// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IKittyPartyYieldGenerator.sol";


contract KittyPartyYieldGeneratorZapper is Initializable, IKittyPartyYieldGenerator, OwnableUpgradeable {
    address private _treasuryContract;
    address payable public ZapInContract;
    address payable public ZapOutContract;

    uint256 public constant MASK = type(uint128).max;

    mapping(address => IKittyPartyYieldGenerator.KittyPartyYieldInfo) public kittyPartyYieldInfo;

    event KittyPartyReadyToYield(address kittyparty, uint256 amountPerRound);

    function __KittyPartyYieldGeneratorZapper_init(address treasuryContractParam) public initializer {
      _treasuryContract = treasuryContractParam;
      __Ownable_init(); //Later remove onlyOwner and change to only kitty party
    }

    function setAllowanceZapIn() public onlyOwner{
        address sellToken = kittyPartyYieldInfo[msg.sender].sellTokenAddress;
        require(IERC20Upgradeable(sellToken).approve(ZapInContract, MASK), "Not able to set allowance");
    }

    function setAllowanceZapOut() public onlyOwner{
        address lpTokenAddress = kittyPartyYieldInfo[msg.sender].lpTokenAddress;
        require(IERC20Upgradeable(lpTokenAddress).approve(ZapOutContract, MASK), "Not able to set allowance");
    }
     
     /**
     * @dev See IKittyPartyYieldGenerator.sol
     */
    function createLockedValue(bytes calldata zapCallData) external override
    onlyOwner //Later this will be all controllers but upto a specific amount
    payable // Must attach ETH equal to the `value` field from the API response.
    returns (uint256  vaultTokensRec)
    {
        address sellToken = kittyPartyYieldInfo[msg.sender].sellTokenAddress;
        address lpToken = kittyPartyYieldInfo[msg.sender].lpTokenAddress;
        require(IERC20Upgradeable(sellToken).approve(ZapInContract, MASK), "Not enough allowance");
        // Check this contract's initial balance
        uint256 initialBalance = IERC20Upgradeable(lpToken).balanceOf(address(this));

        (bool success,) = ZapInContract.call{value: msg.value}(zapCallData);
        require(success, 'Zap In Failed');

        vaultTokensRec = IERC20Upgradeable(lpToken).balanceOf(address(this)) - initialBalance;
        kittyPartyYieldInfo[msg.sender].lockedAmount = vaultTokensRec;
    }
 
    /**
     * @dev See IKittyPartyYieldGenerator.sol, This contract unlocks value and sends it to the treasury contract
     */
    function unwindLockedValue(address kittyParty, bytes calldata zapCallData) external override 
    returns (uint256 tokensRec)
    {
        // bytes memory payload = abi.encodeWithSignature("stage()");
        // (bool successStage, bytes memory returnData) = address(kittyParty).staticcall(payload);
        // require(successStage, "Not a valid kitty party");
        // (uint stage) = abi.decode(returnData, (uint256));
        // require(stage == 3, "Not in unwind stage");


        //Get funds back in the same token that we sold in  DAI, since for now the treasury only releases DAI
        address lpToken = kittyPartyYieldInfo[kittyParty].sellTokenAddress;
        address sellToken = kittyPartyYieldInfo[kittyParty].lpTokenAddress;
        require(IERC20Upgradeable(sellToken).approve(ZapOutContract, MASK), "Not enough allowance");
        // Check this contract's initial balance
        uint256 initialBalance = lpToken == address(0)
        ? address(this).balance
        : IERC20Upgradeable(lpToken).balanceOf(address(this));
        // Call the encoded Zap Out function call on the contract at `ZapOutContract`,
        (bool success,) = ZapOutContract.call(zapCallData);
        require(success, 'Zap Out Failed');
        uint256 finalBalance = lpToken == address(0)
        ? address(this).balance
        : IERC20Upgradeable(lpToken).balanceOf(address(this));
        tokensRec = finalBalance - initialBalance;
        kittyPartyYieldInfo[kittyParty].yieldGeneratedInLastRound = tokensRec;
        //Send the tokens to the treasury
        IERC20Upgradeable(lpToken).transfer(_treasuryContract , finalBalance);
    }

    /**
     * @dev See IKittyPartyYieldGenerator.sol
     */
    function treasuryAddress() external view override returns (address treasuryContractAddress){
      return _treasuryContract;
    }

    /**
     * @dev See IKittyPartyYieldGenerator.sol
     */
    function lockedAmount(address kittyParty) external view override returns (uint256 totalLockedValue) {
      return kittyPartyYieldInfo[kittyParty].lockedAmount;
    }

    /**
     * @dev See IKittyPartyYieldGenerator.sol
     */
    function yieldGenerated(address kittyParty) external view override returns (uint256 yieldGeneratedInLastRound) {
      return kittyPartyYieldInfo[kittyParty].yieldGeneratedInLastRound;
    }

    /**
     * @dev See IKittyPartyYieldGenerator.sol
     */
    function lockedPool(address kittyParty) external view override returns (address) {
      return kittyPartyYieldInfo[kittyParty].poolAddress;
    }

    /**
    * @dev See IKittyPartyYieldGenerator.sol
    */
    function setZapInContractAddress(address payable _zapContract) external onlyOwner {
        ZapInContract = _zapContract;
    }

        /**
    * @dev See IKittyPartyYieldGenerator.sol
    */
    function setZapOutContractAddress(address payable _zapOutContract) external onlyOwner {
        ZapOutContract = _zapOutContract;
    }

    function setPartyInfo(address _sellTokenAddress, address _lpTokenAddress ) external {
      //TODO: here check that the party has not yet started to be able to set info for a party
      kittyPartyYieldInfo[msg.sender].sellTokenAddress = _sellTokenAddress;
      kittyPartyYieldInfo[msg.sender].lpTokenAddress = _lpTokenAddress;
    }

    function withdraw(IERC20Upgradeable token, address recipient, uint256 amount) public onlyOwner {
        token.transfer(recipient, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Kitty Party Yield Generator
 */
interface IKittyPartyYieldGenerator {
  struct KittyPartyYieldInfo { 
    uint256 lockedAmount;
    uint256 yieldGeneratedInLastRound;
    address sellTokenAddress;
    address poolAddress;
    address lpTokenAddress;
  }
    /**
     * @dev Create a new LockedValue in the pool
     */
    function createLockedValue(bytes calldata) external payable returns (uint256);
 
    /**
     * @dev Unwind a LockedValue in the pool
     */
    function unwindLockedValue(address kittyParty, bytes calldata) external returns (uint256);

    /**
     * @dev Returns the address of the treasury contract
     */
    function treasuryAddress() external view returns (address);

    /**
     * @dev Returns the amount of tokens staked for a specific kitty party.
     */
    function lockedAmount(address kittyParty) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens staked for a specific kitty party.
     */
    function yieldGenerated(address kittyParty) external view returns (uint256);

    /**
     * @dev Returns the pool in which the kitty party tokens were staked
     */
    function lockedPool(address kittyParty) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}