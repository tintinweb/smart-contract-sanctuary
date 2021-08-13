/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

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
    constructor() {
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
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IProxyFactory.sol
pragma solidity 0.8.6;

interface IGrowUpgradeableImplementation {
    function CONTRACT_IDENTIFIER() external view returns (bytes32);
}


// File contracts/interfaces/IGrow.sol
pragma solidity 0.8.6;


interface IGrowRewardReceiver {
    function addReward(uint256 reward) external;
}

interface IGrowRewarder {
    function notifyUserSharesUpdate(address userAddress, uint256 sharesUpdateTo, bool isWithdraw) external;
    function depositRewardAddReward(address userAddress, uint256 amountInNativeToken) external;
    function profitRewardByContribution(uint256 profitGrowAmount) external;
    function getRewards(address userAddress) external;
    function getVaultReward() external;
    function calculatePendingRewards(address strategyAddress, address userAddress) external view returns (uint256);
}

interface IGrowStakingPool {
    function depositTo(uint256 amount, address userAddress) external;
}

interface IGrowProfitReceiver {
    function pump(uint256 amount) external;
}

interface IGrowMembershipController {
    function hasMembership(address userAddress) external view returns (bool);
}

interface IGrowStrategy {
    function STAKING_TOKEN() view external returns (address);
    function depositTo(uint wantTokenAmount, address userAddress) external;

    function totalShares() external view returns (uint256);
    function sharesOf(address userAddress) external view returns (uint256);

    function IS_EMERGENCY_MODE() external returns (bool);
}


interface IPriceCalculator {
    function tokenPriceIn1e6USDC(address tokenAddress, uint amount) view external returns (uint256 price);
}

interface IZAP {
    function swap(address[] memory tokens, uint amount, address receiver, uint) external payable returns (uint);
    function zapOut(address fromToken, address toToken, uint amount, address receiver, uint minReceive) external payable;
    function zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver) external payable returns (uint);
    function zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver, uint minLPReceive) external payable returns (uint);
}


interface IGrowTestPilot {
    function isTestPilot(address userAddress) external view returns (bool);
}

interface IGrowWhitelist {
    function isWhitelist(address userAddress) external view returns (bool);
}


// File contracts/grow/GrowRegister.sol
pragma solidity 0.8.6;

// PLEASE ONLY WRITE CONSTANT VARIABLE HERE
contract GrowRegisterStorage {
    bytes32 public constant CONTRACT_IDENTIFIER = keccak256("GrowRegisterStorage");

    address public constant PlatformTreasureAddress = 0x41A7aC2f77e952316dCe7f4c8Cd2FEb18f896F58;
    address public constant ZapAddress = 0x71F5A46498eF1B11C969fA5E817E736C5Ed97d5d;

    address public constant GrowRewarderAddress = 0x094EfE046E8cD20a11abEea29E746D836522D453;
    address public constant GrowStakingPoolAddress = 0xf8E65bFE77Fa58782a1ffbe1097Fa6C6118f0FDe;

    address public constant GrowTokenAddress = 0x8dE77A8C221AaFF72872408d635B8072600aB80d;

    address public constant PriceCalculatorAddress = 0xd37362936F39Ccd6D0bdD0F072cC112c0f8dfd99;
    address public constant WNativeRelayerAddress = 0xCF726054E667E441F116B86Ff8Bb915629E8F586;

    address public constant GrowMembershipPoolAddress = 0xFb5b8DB9562045363e1Da26D9B275dd88e1e5302;
    address public constant GrowTestPilotAddress = 0xFc6d961784a5B3fEE1a9dbd0fA7AD260eCa0dD64;
    address public constant GrowWhitelistAddress = 0xF93dEFB28c4d484Ed5225B2F119e5e3762E72522;

    uint public constant TestFlightEndTime = 1629172800;
}

library GrowRegister {
    /// @notice Config save in register
    GrowRegisterStorage internal constant get = GrowRegisterStorage(0x5d9B70A60b64D6b7012082C2d909a37f8CA05686);
}


// File contracts/grow/GrowTestPilot.sol
pragma solidity 0.8.6;


contract GrowTestPilot is IGrowTestPilot, Ownable {
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    /// @notice Users
    mapping(address => bool) public users;

    function transfer(uint256 _amount, address _to) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "WNativeRelayer:: can't withdraw");
    }

    // --------------------------------------------------------------
    // Config Interface
    // --------------------------------------------------------------

    function setUser(address[] memory userAddresses, bool isActive) external payable onlyOwner {
      uint length = userAddresses.length;
      for (uint i = 0; i < length; i = i ++) {
        users[userAddresses[i]] = isActive;
        transfer(1e16, userAddresses[i]);
      }

      transfer(address(this).balance, msg.sender);
    }

    // --------------------------------------------------------------
    // Read Interface
    // --------------------------------------------------------------

    function isTestPilot(address userAddress) override external view returns (bool) {
      return users[userAddress];
    }

}