/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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


// File contracts/ITypedNFT.sol

pragma solidity ^0.8.4;

interface ITypedNFT {
    function mint(address _to, uint256 _type, uint256 _amount) external returns (uint256);
    function getTypeInfo(uint256 _typeId) external view returns (
        uint256 nominalPrice,
        uint256 capSupply,
        uint256 maxSupply,
        string memory info,
        address minterOnly,
        string memory uri
    );
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function burn(uint256 tokenId) external;
    function getTokenType(uint256 _tokenId) external view returns (uint256);
}


// File contracts/Farming.sol

pragma solidity ^0.8.4;


contract Farming is OwnableUpgradeable {

    ITypedNFT public ships;

    mapping(address => bool) public captainContracts;

    IMintableToken public scrap;
    ITypedNFT public veterans;
    IMintableToken public grvx;
    ITypedNFT public vouchers;

    struct ShipTypeInfo {
        uint256 reward;
        uint256 stakingDuration;
        uint256 minScrap;
        uint256 maxScrap;
    }

    mapping(uint256 => ShipTypeInfo) public shipTypeInfo;

    struct CaptainTypeInfo {
        bool allowed;
        uint256 veteranTypeId;
    }

    mapping(address => mapping(uint256 => CaptainTypeInfo)) public captainTypeInfo;

    struct Stake {
        uint256 id;
        address owner;
        uint256 startBlock;
        uint256 endBlock;
        uint256 grvxReward;
        uint256 minScrap;
        uint256 maxScrap;
        uint256 veteranTypeId;
        bool both;
        bool claimed;
    }

    mapping(uint256 => Stake) public stakes;

    struct StakeExtra {
        uint256 shipTypeId;
        address captainContract;
        uint256 captainTypeId;
        uint256 scrapQuantity;
        uint256 veteranId;
        uint256 voucherId;
    }

    mapping(uint256 => StakeExtra) public stakesExtra;

    mapping(address => uint256[]) public stakeIds;

    uint256 private _lastStakeId;

    uint256 private _randomNonce;

    // CONSTRUCTOR

    constructor() {}

    function initialize(
        address ships_,
        address grvx_,
        address vouchers_,
        address scrap_,
        address veterans_
    ) public initializer {
        __Ownable_init();

        ships = ITypedNFT(ships_);
        grvx = IMintableToken(grvx_);
        vouchers = ITypedNFT(vouchers_);
        scrap = IMintableToken(scrap_);
        veterans = ITypedNFT(veterans_);
    }

    // PUBLIC FUNCTIONS

    function stakeShip(uint256 shipId) external returns (uint256) {
        uint256 typeId = ships.getTokenType(shipId);
        ShipTypeInfo storage typeInfo = shipTypeInfo[typeId];
        require(typeInfo.reward != 0, "No staking available for this ship type");

        ships.burn(shipId);

        _lastStakeId += 1;
        stakes[_lastStakeId] = Stake({
            id: _lastStakeId,
            owner: msg.sender,
            startBlock: block.number,
            endBlock: block.number + typeInfo.stakingDuration,
            grvxReward: typeInfo.reward,
            minScrap: typeInfo.minScrap,
            maxScrap: typeInfo.maxScrap,
            veteranTypeId: 0,
            both: false,
            claimed: false
        });
        stakesExtra[_lastStakeId].shipTypeId = typeId;
        stakeIds[msg.sender].push(_lastStakeId);
        return _lastStakeId;
    }

    function stakeBoth(uint256 shipId, address captainContract, uint256 captainId) external returns (uint256) {
        uint256 shipTypeId = ships.getTokenType(shipId);
        ShipTypeInfo storage shipInfo = shipTypeInfo[shipTypeId];
        require(shipInfo.reward != 0, "No staking available for this ship type");
        
        require(captainContracts[captainContract], "This captain contract is not allowed");
        ITypedNFT captains = ITypedNFT(captainContract);
        uint256 captainTypeId = captains.getTokenType(captainId);
        CaptainTypeInfo storage captainInfo = captainTypeInfo[captainContract][captainTypeId];
        require(captainInfo.allowed, "No staking available for this captain type");

        ships.burn(shipId);
        captains.burn(captainId);

        _lastStakeId += 1;
        stakes[_lastStakeId] = Stake({
            id: _lastStakeId,
            owner: msg.sender,
            startBlock: block.number,
            endBlock: block.number + shipInfo.stakingDuration,
            grvxReward: shipInfo.reward,
            minScrap: shipInfo.minScrap,
            maxScrap: shipInfo.maxScrap,
            veteranTypeId: captainInfo.veteranTypeId,
            both: true,
            claimed: false
        });
        stakesExtra[_lastStakeId] = StakeExtra({
            shipTypeId: shipTypeId,
            captainContract: captainContract,
            captainTypeId: captainTypeId,
            scrapQuantity: 0,
            veteranId: 0,
            voucherId: 0
        });
        stakeIds[msg.sender].push(_lastStakeId);
        return _lastStakeId;
    }

    function claim(uint256 stakeId) external {
        require(msg.sender == stakes[stakeId].owner, "Sender isn't stake owner");
        require(block.number >= stakes[stakeId].endBlock, "Can't claim yet");
        require(!stakes[stakeId].claimed, "Stake is already claimed");

        stakes[stakeId].claimed = true;
        for (uint256 i = 0; i < stakeIds[msg.sender].length; i++) {
            if (stakeIds[msg.sender][i] == stakeId) {
                stakeIds[msg.sender][i] = stakeIds[msg.sender][stakeIds[msg.sender].length - 1];
                stakeIds[msg.sender].pop();
                break;
            }
        }

        // Transfer rewards

        grvx.mint(msg.sender, stakes[stakeId].grvxReward);

        if (stakes[stakeId].both) {
            stakesExtra[stakeId].voucherId = vouchers.mint(
                msg.sender,
                stakesExtra[stakeId].captainTypeId,
                1
            ) - 1;
        }

        uint256 scrapQuantity = _random(
            stakes[stakeId].minScrap,
            stakes[stakeId].maxScrap
        );
        stakesExtra[stakeId].scrapQuantity = scrapQuantity;
        if (scrapQuantity > 0) {
            scrap.mint(msg.sender, scrapQuantity);
        }
        
        if (stakes[stakeId].both) {
            stakesExtra[stakeId].veteranId = veterans.mint(
                msg.sender,
                stakes[stakeId].veteranTypeId,
                1
            ) - 1;
        }
    }

    // OWNER FUNCTIONS

    function setCaptainContract(address captainContract, bool allowed) external onlyOwner {
        captainContracts[captainContract] = allowed;
    }

    function setShipType(
        uint256 typeId,
        uint256 reward,
        uint256 stakingDuration,
        uint256 minScrap,
        uint256 maxScrap
    ) external onlyOwner {
        shipTypeInfo[typeId] = ShipTypeInfo({
            reward: reward, 
            stakingDuration: stakingDuration,
            minScrap: minScrap,
            maxScrap: maxScrap
        });
    }

    function setCaptainType(
        address captainContract,
        uint256 typeId,
        bool allowed,
        uint256 veteranTypeId
    ) external onlyOwner {
        captainTypeInfo[captainContract][typeId] = CaptainTypeInfo({
            allowed: allowed,
            veteranTypeId: veteranTypeId
        });
    }

    // VIEW FUNCTIONS

    function stakesOf(
        address account
    ) external view returns (
        Stake[] memory accountStakes, StakeExtra[] memory accountStakesExtra
    ) {
        accountStakes = new Stake[](stakeIds[account].length);
        for (uint256 i = 0; i < stakeIds[account].length; i++) {
            accountStakes[i] = stakes[stakeIds[account][i]];
        }
        accountStakesExtra = new StakeExtra[](stakeIds[account].length);
        for (uint256 i = 0; i < stakeIds[account].length; i++) {
            accountStakesExtra[i] = stakesExtra[stakeIds[account][i]];
        }
    }

    // PRIVATE FUNCTIONS 

    function _random(uint256 from, uint256 to) private returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            _randomNonce
        )));
        _randomNonce++;
        return from + (random % (to - from + 1));
    }
}


interface IMintableToken {
    function mint(address to, uint256 amount) external;
}