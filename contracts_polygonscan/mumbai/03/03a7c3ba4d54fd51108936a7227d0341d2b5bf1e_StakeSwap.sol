pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./token/IStake.sol";
import "./token/IVotedToken.sol";

contract StakeSwap is Initializable, OwnableUpgradeable{

    struct Swap {
        uint256 deposit;  // 质押的数量
        uint256 fromblock;  // 结算块数
    }

    struct Record {
        uint256 deposit;  // 质押的数量
        uint256 fromblock;  // 结算块数
    }

    struct Claim {
        uint256 deposit;  // 质押的数量
        uint256 gons;  // 分红
        uint256 fromblock;  // 结算块数
        uint256 id;
        uint256 stakeRecordStart;
        uint256 stakeRecordEnd;
        bool lock;
    }

    mapping (address => address) internal _delegates;
    mapping (address => Swap) internal delegatorSwap;
    mapping (address => mapping(uint256 => uint256)) internal delegatorGons;
    mapping (address => mapping(address => Claim)) internal accountStakeTotal;
    mapping (uint256 => mapping(uint256 => Record)) internal accountStakeRecord;
    uint256 internal ClaimId;

    function initialize() initializer public {
        __Ownable_init();
    }

    function delegates(address delegator)
    external
    view
    returns (address)
    {
        return _delegates[delegator];
    }

    function delegate(address delegator, address delegatee)
    external
    onlyOwner
    {
        _delegates[delegator] = delegatee;
        uint256 blockNumber = block.number;
        delegatorSwap[delegator] = Swap(0,blockNumber);
        delegatorGons[delegator][blockNumber] = 0;
    }

    function stake( uint _amount, address _recipient ) external returns ( bool ) {
        // 触发rebase函数重新计算费率及发质押奖励
        rebase(_recipient);
        // 调用OHM主合约函数，将属于StakingHelper合约的钱转到当前Staking合约
        IStake( _recipient ).stake(msg.sender, address(this), _amount );
        // 构造Claim信息
        Claim memory info = accountStakeTotal[msg.sender][_recipient];
        require( !info.lock, "Deposits for account are locked" );
        if(info.id == 0){
            ClaimId += 1;
            info.id = ClaimId;
        }
        accountStakeRecord[info.id][info.stakeRecordEnd] = Record(_amount, block.number);
        info.stakeRecordEnd += 1;
        delegatorSwap[_recipient].deposit += _amount;
        // 写入accountStakeTotal内存
        accountStakeTotal[msg.sender][_recipient] = Claim ({
        deposit: info.deposit += _amount,
        // 调用sOHM合约gonsForBalance获取此刻sOHM和gons的转换结果
        gons: info.gons,
        fromblock: delegatorSwap[_recipient].fromblock,
        id: info.id,
        stakeRecordStart: info.stakeRecordStart,
        stakeRecordEnd: info.stakeRecordEnd,
        lock: false
        });
        // 调用sOHM合约方法，向StakingWarmup合约转sOHM（实际是gons）
        IVotedToken( _delegates[_recipient] ).deposit(msg.sender, _amount );
        return true;
    }

    function rebase(address delegator) public {
        require( _delegates[delegator] != address(0), "SS::001" );
        uint256 blockNumber = block.number;
        if(delegatorSwap[delegator].deposit == 0){
            delegatorSwap[delegator].fromblock = blockNumber;
            return ;
        }
        if(delegatorSwap[delegator].deposit > 0 && delegatorSwap[delegator].fromblock < blockNumber){
            for(uint256 i = delegatorSwap[delegator].fromblock; i < blockNumber; i+=260){
                delegatorGons[delegator][i] = swapAward(delegatorSwap[delegator].deposit);
                delegatorSwap[delegator].fromblock = i;
            }
        }

        Claim memory accountAward = accountStakeTotal[msg.sender][delegator];
        if(accountAward.deposit > 0 && accountAward.fromblock < blockNumber){
            for(uint256 i = accountAward.fromblock; i < blockNumber; i+=260){
                accountAward.gons += delegatorGons[delegator][i] * accountAward.deposit / delegatorSwap[delegator].deposit;
            }
            accountAward.fromblock = delegatorSwap[delegator].fromblock;
        }
        accountStakeTotal[msg.sender][delegator] = accountAward;
    }

    function swapAward(uint256 total) public returns (uint256){
        return total / 10;
    }

    function extract( uint _amount, address _recipient ) external returns ( bool ) {
        // 触发rebase函数重新计算费率及发质押奖励
        rebase(_recipient);
        // 构造Claim信息
        Claim memory info = accountStakeTotal[msg.sender][_recipient];
        require( !info.lock, "Deposits for account are locked" );
        require( info.deposit >= _amount, "SS::002" );
        require( IVotedToken( _delegates[_recipient] ).withdraw(msg.sender, _amount),
            "SS::003" );

        uint256 extractFree = 0;
        uint256 extractAmount = _amount;
        for(uint256 i = info.stakeRecordStart; i < info.stakeRecordEnd; i++){
            if(accountStakeRecord[info.id][i].deposit < extractAmount){
                extractAmount -= accountStakeRecord[info.id][i].deposit;
                extractFree += LiquidatedDamages( accountStakeRecord[info.id][i].deposit, accountStakeRecord[info.id][i].fromblock);
                delete accountStakeRecord[info.id][i];
            }else{
                accountStakeRecord[info.id][i].deposit -= extractAmount;
                extractFree += LiquidatedDamages(extractAmount,
                    accountStakeRecord[info.id][i].fromblock);
                info.stakeRecordStart = i;
                break;
            }
        }

        uint256 gons = info.gons * _amount / info.deposit;
        // 写入warmupInfo内存
        accountStakeTotal[msg.sender][ _recipient ] = Claim ({
        deposit: info.deposit -= _amount,
        // 调用sOHM合约gonsForBalance获取此刻sOHM和gons的转换结果
        gons: info.gons -= gons,
        fromblock: delegatorSwap[_recipient].fromblock,
        id: info.id,
        stakeRecordStart: info.stakeRecordStart,
        stakeRecordEnd: info.stakeRecordEnd,
        lock: false
        });
        IStake( _recipient ).stake(address(this), msg.sender, tip(_amount + gons - extractAmount) );
        return true;
    }

    function LiquidatedDamages(uint256 total, uint256 blockNumber) public view returns (uint256){
        return total / 100 * 2;
    }

    function tip(uint256 total) internal returns (uint256){
        return total / 100 * 98;
    }

    function getStakeInfo(address account, address delegator) external view returns ( uint256 deposit, uint256 gons,
        uint256 fromblock, uint256 id, uint256 stakeRecordStart, uint256 stakeRecordEnd){
        Claim memory info = accountStakeTotal[account][delegator];
        return (info.deposit, info.gons, info.fromblock, info.id, info.stakeRecordStart, info.stakeRecordEnd);
    }

    function getStakeRecord(uint256 claimId, uint256 index) external view returns ( uint256 deposit, uint256 fromblock){
        Record memory record = accountStakeRecord[claimId][index];
        return (record.deposit, record.fromblock);
    }

    function getTipFree(uint256 total) public view returns (uint256){
        return total / 100 * 98;
    }

    function getExtractFree(uint _amount, address account, address _recipient) public view returns (uint256){
        uint256 extractFree = 0;
        uint256 extractAmount = _amount;
        Claim memory info = accountStakeTotal[account][_recipient];
        for(uint256 i = info.stakeRecordStart; i < info.stakeRecordEnd; i++){
            if(accountStakeRecord[info.id][i].deposit < extractAmount){
                extractAmount -= accountStakeRecord[info.id][i].deposit;
                extractFree += LiquidatedDamages( accountStakeRecord[info.id][i].deposit, accountStakeRecord[info.id][i].fromblock);
            }else{
                extractFree += LiquidatedDamages(extractAmount,
                    accountStakeRecord[info.id][i].fromblock);
                break;
            }
        }
        return extractFree;
    }

    function reLoad() public  {
        delete accountStakeTotal[address(0x25af24C4B2c0695b1694f1248143b6D7a7C63B9C)][address(0x36eE32E83c00266319928e5e355C17501e4AaE12)];
        delete accountStakeRecord[3][5];
        delete accountStakeRecord[3][4];
    }
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

pragma solidity ^0.8.2;

interface IStake {
    function stake(address from, address to, uint256 amount) external  returns (bool);
}

pragma solidity ^0.8.2;

interface IVotedToken {
    function getCurrentVotes(uint256 tokenId, uint256 checkVoted) external view returns (uint256);
    function deposit(address user, uint256 amount) external returns (bool);
    function withdraw(address user, uint256 amount) external returns (bool);
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