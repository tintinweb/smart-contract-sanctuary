// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interface/IApeKing.sol";
import "./interface/IPeach.sol";

contract YieldGenerator is Initializable, OwnableUpgradeable {
    uint256 public BASE_RATE;
    uint256 public INITIAL_ISSUANCE;
    uint256 public REWARD_END;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    uint8[] public rarityBoost;

    uint16 public ogBoost;
    uint16 public genesisBoost;
    uint16 public specialBoost;

    uint16 public BASE_BOOST;
    uint8 public BASE_RARITY;

    IApeKing public apeKing;
    IPeach public peach;

    bool public paused;

    event RewardPaid(address indexed user, uint256 reward);

    function initialize(address _rak, address _peach) public initializer {
        apeKing = IApeKing(_rak);
        peach = IPeach(_peach);
        __Ownable_init();

        INITIAL_ISSUANCE = 200 ether;
        BASE_RATE = 10 ether;

        ogBoost = 12000;
        specialBoost = 12500;
        genesisBoost = 11000;

        BASE_BOOST = 10000;
        BASE_RARITY = 100;

        paused = false;

        REWARD_END = 1762365781; // Wed Nov 05 2025 18:03:01 GMT+0000
    }

    function registerRarityBoost(uint8[] calldata _rarities) external onlyOwner {
        for (uint16 i = 0; i < _rarities.length; i++) rarityBoost.push(_rarities[i]);
    }

    function updateRarityBoost(uint16[] calldata _ids, uint8[] calldata _rarities) external onlyOwner {
        for (uint16 i = 0; i < _ids.length; i++) rarityBoost[_ids[i]] = _rarities[i];
    }

    function setApeKing(address _rak) external onlyOwner {
        apeKing = IApeKing(_rak);
    }

    function setRewardEnd(uint256 _end) external onlyOwner {
        REWARD_END = _end;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setPeachToken(address _peach) external onlyOwner {
        peach = IPeach(_peach);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function getRarity(uint256 _tokenId) public view returns (uint256) {
        return rarityBoost.length > _tokenId ? rarityBoost[_tokenId] : BASE_RARITY;
    }

    function getRewardRate(address _user) public view returns (uint256 _rate) {
        uint256[] memory _tokenIds = apeKing.tokensOfOwner(_user);
        if (_tokenIds.length == 0) return 0;

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint256 _rarityRate = getRarity(_tokenIds[i]);
            if (_tokenIds[i] < 3000) _rate += _rarityRate * ogBoost;
            else if (_tokenIds[i] < 6000) _rate += _rarityRate * genesisBoost;
            else if (_tokenIds[i] < 10000) _rate += _rarityRate * BASE_BOOST;
            else _rate += _rarityRate * specialBoost;
        }

        _rate = _rate / _tokenIds.length / BASE_RARITY;
    }

    function updateRewardonMint(
        address _user,
        uint256 /*_tokenId*/
    ) external {
        require(msg.sender == address(apeKing), "not allowed");
        uint256 _timestamp = min(block.timestamp, REWARD_END);
        uint256 _lastUpdate = lastUpdate[_user];

        if (_lastUpdate > 0)
            rewards[_user] +=
                ((getRewardRate(_user) * BASE_RATE * (_timestamp - _lastUpdate)) / 86400 / BASE_BOOST) +
                INITIAL_ISSUANCE;
        else rewards[_user] += INITIAL_ISSUANCE;

        lastUpdate[_user] = _timestamp;
    }

    function updateReward(
        address _from,
        address _to,
        uint256 /*_tokenId*/
    ) external {
        require(msg.sender == address(apeKing), "not allowed");

        if (_from != address(0)) {
            _updatePendingReward(_from);
        }
        if (_to != address(0)) {
            _updatePendingReward(_to);
        }
    }

    function _updatePendingReward(address _user) internal {
        uint256 _timestamp = min(block.timestamp, REWARD_END);
        uint256 _lastUpdate = lastUpdate[_user];
        if (_lastUpdate > 0)
            rewards[_user] += (getRewardRate(_user) * BASE_RATE * (_timestamp - _lastUpdate)) / 86400 / BASE_BOOST;
        lastUpdate[_user] = _timestamp;
    }

    function claimReward() external {
        require(paused == false, "paused!");

        _updatePendingReward(msg.sender);
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            peach.mint(msg.sender, _reward);
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 _timestamp = min(block.timestamp, REWARD_END);
        uint256 pending = (getRewardRate(_user) * BASE_RATE * (_timestamp - lastUpdate[_user])) / 86400 / BASE_BOOST;
        return rewards[_user] + pending;
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

interface IApeKing {
    function tokensOfOwner(address) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPeach {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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