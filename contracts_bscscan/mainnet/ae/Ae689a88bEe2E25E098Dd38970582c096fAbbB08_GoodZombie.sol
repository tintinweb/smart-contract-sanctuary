// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./access/Ownable.sol";
import "./interfaces/IGraveStakingToken.sol";
import "./interfaces/IPriceConsumerV3.sol";

/**
 * @title GoodZombie
 * @author Nams
 * Improves security of DrFrankenstein's functions
 */

interface IDrFrankenstein {
    struct PoolInfo {
        IGraveStakingToken lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accZombiePerShare;
        uint256 minimumStakingTime;
        bool isGrave;
        bool requiresRug;
        IGraveStakingToken ruggedToken;
        address nft;
        uint256 unlockFee;
        uint256 minimumStake;
        uint256 nftRevivalTime;
        uint256 unlocks;
    }

    function massUpdatePools() external;
    function poolLength() external returns(uint256);
    function poolInfo(uint256) external returns(PoolInfo memory);
}

interface IRugZombieNft {
    function implementsReviveRug() external pure returns(bool);
}

interface ISafeOwner {
    function updateMultiplier(uint256 multiplierNumber) external;

    function addPool(uint _allocPoint, IGraveStakingToken _lpToken, uint _minimumStakingTime, bool _withUpdate) external;

    function addGrave(
        uint256 _allocPoint,
        IGraveStakingToken _lpToken,
        uint256 _minimumStakingTime,
        IGraveStakingToken _ruggedToken,
        address _nft,
        uint256 _minimumStake,
        uint256 _unlockFee,
        uint256 _nftRevivalTime,
        bool _withUpdate
    ) external;

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

    function setGraveNft(uint _pid, address _nft) external;

    function setUnlockFee(uint _pid, uint _unlockFee) external;

    function setGraveMinimumStake(uint _pid, uint _minimumStake) external;

    function setPriceConsumer(IPriceConsumerV3 _priceConsumer) external;

    function setPancakeRouter(address _pancakeRouter) external;

    function drFrankenstein() external returns(address);

}

contract GoodZombie is Ownable {
    ISafeOwner public safeOwner;
    IDrFrankenstein public drFrankenstein;
    address public teamMultiSig;
    uint256 maxMultiplier;
    uint256 minUnlockFee;
    mapping (address => bool) public routerWhitelist;
    mapping (address => bool) public priceConsumerWhitelist;
    // mapping that stores pool lpTokens. This way we can check which LPs are in use without iterating all pools.
    mapping (address => bool) public poolLpExists;

    // all GoodZombie functions indirectly call the respective funtion on DrFrankenstein through the SafeOwner contract
    constructor(ISafeOwner _safeOwner, address _teamMultisig) {
        safeOwner = _safeOwner;
        teamMultiSig = _teamMultisig;
        maxMultiplier = 5;
        minUnlockFee = 10000;
        drFrankenstein = IDrFrankenstein(safeOwner.drFrankenstein());

            // backfill poolLpExists with lpTokens from existing graves
            for(uint256 x = 0; x < drFrankenstein.poolLength(); x++) {
                poolLpExists[address(drFrankenstein.poolInfo(x).lpToken)] = true;
            }
    }

    // updateMultiplier limits the max multiplierNumber that can be set on DrFrankenstein and calls #massUpdatePools
    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        require(multiplierNumber <= maxMultiplier, "updateMultiplier: multiplier cannot be set greater than maxMultiplier");
        safeOwner.updateMultiplier(multiplierNumber);
        drFrankenstein.massUpdatePools();
    }

    // addPool prevents the creation of pools containing duplicate lpTokens
    function addPool(uint _allocPoint, IGraveStakingToken _lpToken, uint _minimumStakingTime, bool _withUpdate) public onlyOwner {
        require(poolLpExists[address(_lpToken)] == false, 'addPool: lpToken is used in an existing pool.');
        safeOwner.addPool(_allocPoint, _lpToken, _minimumStakingTime, _withUpdate);
        poolLpExists[address(_lpToken)] = true;
    }

    // addPool prevents the creation of pools containing duplicate lpTokens
    function addGrave(
        uint256 _allocPoint,
        IGraveStakingToken _lpToken,
        uint256 _minimumStakingTime,
        IGraveStakingToken _ruggedToken,
        address _nft,
        uint256 _minimumStake,
        uint256 _unlockFee,
        uint256 _nftRevivalTime,
        bool _withUpdate
    ) public onlyOwner {
        require(poolLpExists[address(_lpToken)] == false, 'addPool: lpToken is used in an existing pool.');
        require(IRugZombieNft(_nft).implementsReviveRug() == true, 'addGrave: nft does not have reviveRug function');
        safeOwner.addGrave(_allocPoint, _lpToken, _minimumStakingTime, _ruggedToken, _nft, _minimumStake, _unlockFee, _nftRevivalTime, _withUpdate);
        poolLpExists[address(_lpToken)] = true;
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        safeOwner.set(_pid, _allocPoint, _withUpdate);
    }

    function setGraveNft(uint _pid, address _nft) public onlyOwner {
        require(IRugZombieNft(_nft).implementsReviveRug());
        safeOwner.setGraveNft(_pid, _nft);
    }

    function setUnlockFee(uint _pid, uint _unlockFee) public onlyOwner {
        require(_unlockFee > minUnlockFee, 'setUnlockFee: new unlockFee must be >= minUnlockFee');
        safeOwner.setUnlockFee(_pid, _unlockFee);
    }

    function setGraveMinimumStake(uint _pid, uint _minimumStake) public onlyOwner {
        safeOwner.setGraveMinimumStake(_pid, _minimumStake);
    }

    // setPriceConsumer requires a new priceConsumer is whitelisted before being set
    function setPriceConsumer(IPriceConsumerV3 _priceConsumer) public onlyOwner {
        require(priceConsumerWhitelist[address(_priceConsumer)] == true, 'setPriceConsumer: new priceConsumer must be whitelisted');
        safeOwner.setPriceConsumer(_priceConsumer);
    }

    // setPancakeRouter requires a new router is whitelisted before being set
    function setPancakeRouter(address _pancakeRouter) public onlyOwner {
        require(routerWhitelist[_pancakeRouter] == true, 'setPancakeRouter: new router must be whitelisted');
        safeOwner.setPancakeRouter(_pancakeRouter);
    }

    /**
     * whitelistRouter enables / disables a dex router from being usable in #setPancakeRouter
     * this can only be called by the teamMultiSig address so under the event the contract owner is compromised
     * the router can only be set to a safe router whitelisted by the RugZombie team.
     */
    function whitelistRouter(address _router, bool _isWhitelisted) public {
        require(address(msg.sender) == teamMultiSig, 'whitelistRouter: must be teamMultiSig');
        routerWhitelist[_router] = _isWhitelisted;
    }

    /**
     * whitelistPriceConsumer enables / disables a bnb price consumer contract from being usable in #setPriceConsumer
     * this can only be called by the teamMultiSig address so under the event the contract owner is compromised
     * the priceConsumer can only be set to a safe contract whitelisted by the RugZombie team.
     */
    function whitelistPriceConsumer(address _priceConsumer, bool _isWhitelisted) public {
        require(address(msg.sender) == teamMultiSig, 'whitelistPriceConsumer: must be teamMultiSig');
        priceConsumerWhitelist[_priceConsumer] = _isWhitelisted;
    }

    function setTeamMultisig(address _newTeamMultisig) public {
        require(address(msg.sender) == teamMultiSig, 'setTeamMultisig: must be teamMultiSig');
        teamMultiSig = _newTeamMultisig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../utils/Context.sol";
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
    constructor()  {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IGraveStakingToken {

    /**
    * @dev Mints the amount of tokens to the address specified.
    */
    function mint(address _to, uint256 _amount) external;

    /**
    * @dev Mints the amount of tokens to the caller's address.
    */
    function mint(uint _amount) external;

    /**
    * @dev Burns the amount of tokens from the msg.sender.
    */
    function burn(uint256 _amount) external;

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (uint);
    function unlockFeeInBnb(uint) external view returns (uint);
    function usdToBnb(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

