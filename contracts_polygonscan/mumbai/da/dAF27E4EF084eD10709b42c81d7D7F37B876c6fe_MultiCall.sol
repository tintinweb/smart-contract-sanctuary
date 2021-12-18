/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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


// File contracts/interface/IChainlinkAggregator.sol


pragma solidity ^0.8.0;

interface IChainlinkAggregator {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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


// File contracts/interface/IERC20Extented.sol


pragma solidity ^0.8.0;
interface IERC20Extented is IERC20 {
    function decimals() external view returns(uint8);
}


// File contracts/interface/IAssetToken.sol


pragma solidity ^0.8.0;
interface IAssetToken is IERC20Extented {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function owner() external view;
}


// File contracts/interface/IAsset.sol



pragma solidity ^0.8.2;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
struct IPOParams{
    uint mintEnd;
    uint preIPOPrice;
    // >= 1000
    uint16 minCRatioAfterIPO;
}

struct AssetConfig {
    IAssetToken token;
    IChainlinkAggregator oracle;
    uint16 auctionDiscount;
    uint16 minCRatio;
    uint16 targetRatio;
    uint endPrice;
    uint8 endPriceDecimals;
    // is in preIPO stage
    bool isInPreIPO;
    IPOParams ipoParams;
    // is it been delisted
    bool delisted;
    // the Id of the pool in ShortStaking contract.
    uint poolId;
    // if it has been assined
    bool assigned;
}

// Collateral Asset Config
struct CAssetConfig {
    IERC20Extented token;
    IChainlinkAggregator oracle;
    uint16 multiplier;
    // if it has been assined
    bool assigned;
}

interface IAsset {
    function asset(address nToken) external view returns(AssetConfig memory);
    function cAsset(address token) external view returns(CAssetConfig memory);
    function isCollateralInPreIPO(address cAssetToken) external view returns(bool);
}


// File contracts/interface/IPositions.sol



pragma solidity ^0.8.2;
struct Position{
    uint id;
    address owner;
    // collateral asset token.
    IERC20Extented cAssetToken;
    uint cAssetAmount;
    // nAsset token.
    IAssetToken assetToken;
    uint assetAmount;
    // if is it short position
    bool isShort;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

interface IPositions {
    function openPosition(
        address owner,
        IERC20Extented cAssetToken,
        uint cAssetAmount,
        IAssetToken assetToken,
        uint assetAmount,
        bool isShort
    ) external returns(uint positionId);

    function updatePosition(Position memory position_) external;

    function removePosition(uint positionId) external;

    function getPosition(uint positionId) external view returns(Position memory);
    function getNextPositionId() external view returns(uint);
    function getPositions(address ownerAddr, uint startAt, uint limit) external view returns(Position[] memory);
}


// File contracts/interface/IShortLock.sol



pragma solidity ^0.8.2;
struct PositionLockInfo {
    uint positionId;
    address receiver;
    IERC20 lockedToken; // address(1) means native token, such as ETH or MITIC.
    uint lockedAmount;
    uint unlockTime;
    bool assigned;
}

interface IShortLock {
    function lock(uint positionId, address receiver, address token, uint amount) external payable;
    function unlock(uint positionId) external;
    function release(uint positionId) external;
    function lockInfoMap(uint positionId) external view returns(PositionLockInfo memory);
}


// File contracts/interface/IStakingToken.sol


pragma solidity ^0.8.0;
interface IStakingToken is IERC20Extented {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function owner() external view returns (address);
}


// File contracts/interface/IShortStaking.sol



pragma solidity ^0.8.2;
interface IShortStaking {
    function pendingNSDX(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount, address _realUser) external;
    function withdraw(uint256 _pid, uint256 _amount, address _realUser) external;
    function poolLength() external view returns (uint256);
}


// File contracts/MultiCall.sol


pragma solidity ^0.8.2;
contract MultiCall is Ownable {

    struct PositionInfo {
        Position position;
        AssetConfig assetConfig;
        CAssetConfig cAssetConfig;
        PositionLockInfo lockInfo;
        uint shortReward;
    }

    address public asset;
    address public positionContract;
    address public mint;
    address public lock;
    address public staking;

    constructor(
        address asset_,
        address positionContract_,
        address mint_,
        address lock_,
        address staking_
    ) {
        asset = asset_;
        positionContract = positionContract_;
        mint = mint_;
        lock = lock_;
        staking = staking_;
    }

    function getPositionInfo(uint positionId) external view returns(PositionInfo memory) {
        Position memory position = IPositions(positionContract).getPosition(positionId);
        AssetConfig memory assetConfig = IAsset(asset).asset(address(position.assetToken));
        CAssetConfig memory cAssetConfig = IAsset(asset).cAsset(address(position.cAssetToken));
        PositionLockInfo memory lockInfo;
        uint reward = 0;
        if (position.isShort) {
            // assetConfig.rootPid
            lockInfo = IShortLock(lock).lockInfoMap(positionId);
            reward = IShortStaking(staking).pendingNSDX(assetConfig.poolId, position.owner);
        }

        return PositionInfo(
            position,
            assetConfig,
            cAssetConfig,
            lockInfo,
            reward
        );
    }

    function setAsset(address asset_) external {
        asset = asset_;
    }

    function setPosition(address positionContract_) external {
        positionContract = positionContract_;
    }

    function setMint(address mint_) external {
        mint = mint_;
    }

    function setLock(address lock_) external {
        lock = lock_;
    }

    function setStaking(address staking_) external {
        staking = staking_;
    }
}