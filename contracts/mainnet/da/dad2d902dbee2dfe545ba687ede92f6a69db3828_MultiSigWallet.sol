/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;


// File: contracts/interfaces/multiOwned/IMultiOwnedEvents.sol
/// @title MultiOwned 事件接口定义
interface IMultiOwnedEvents {
    /// @notice 签名时，触发该事件
    event Confirmation(address owner, uint txId);

    /// @notice 撤销签名时触发该事件
    event Revoke(address owner, uint txId);

    /// @notice owner移交时，触发该事件
    event OwnerChanged(address oldOwner, address newOwner);

    /// @notice 添加新的owner时，触发该事件
    event OwnerAdded(address newOwner);

    /// @notice 移除owner时，触发该事件
    event OwnerRemoved(address oldOwner);

    /// @notice 最小签名数量发生改变时，触发该事件
    event RequirementChanged(uint newRequirement);
}

// File: contracts/interfaces/multiOwned/IMultiOwnedState.sol
/// @title MultiOwned 状态变量及只读函数
interface IMultiOwnedState {
    /// @notice 最小需要的签名数量
    function requiredNum() external view returns(uint);

    /// @notice 所有owner个数
    function ownerNums() external view returns(uint);

    /// @notice 查询某个pending交易的状态
    /// @param txId 交易索引号
    /// @return yetNeeded 还需要签名的数量, ownersDone 已经签名的owners;
    function pendingOf(uint txId) external view returns(uint yetNeeded, uint ownersDone);

    /// @notice 下一个pending队列交易号
    function nextPendingTxId() external view returns(uint);

    /// @notice 查询某个owner地址
    /// @dev Gets an owner by 0-indexed position (using numOwners as the count)
    function getOwner(uint ownerIndex) external view returns (address);

    /// @notice 地址是否为owner
    function isOwner(address addr) external view returns (bool);
    
    /// @notice owner是否已经签名交易
    /// @param txId 交易索引号
    /// @param owner owner地址
    function hasConfirmed(uint txId, address owner) external view returns (bool);
}

// File: contracts/interfaces/multiOwned/IMultiOwnedActions.sol
/// @title MultiOwned 操作接口定义
interface IMultiOwnedActions {
    /// @notice 撤销某笔pending交易的签名
    /// @dev This function can only be called by owner
    /// @param txId 交易号
    function revoke(uint txId) external;

    /// @notice 修改owner为其它地址
    /// @dev This function can only be called by self
    /// @param from 源地址
    /// @param to 目标地址
    function changeOwner(address from, address to) external;

    /// @notice 添加新的owner
    /// @dev This function can only be called by self
    /// @param newOwner 新的owner地址
    function addOwner(address newOwner) external;

    /// @notice 移除owner
    /// @dev This function can only be called by self
    /// @param owner owner地址
    function removeOwner(address owner) external;

    /// @notice 修改最小签名数
    /// @dev This function can only be called by self
    /// @param newRequired 新的最小签名数
    function changeRequirement(uint newRequired) external;
}

// File: contracts/interfaces/IMultiOwned.sol
/// @title MultiOwned接口
/// @notice 接口定义分散在多个接口文件
interface IMultiOwned is 
    IMultiOwnedEvents, 
    IMultiOwnedState, 
    IMultiOwnedActions
{    
}

// File: contracts/base/MultiOwned.sol
contract MultiOwned is IMultiOwned {
    /// @inheritdoc IMultiOwnedState
    uint public override requiredNum;
    /// @inheritdoc IMultiOwnedState
    uint public override ownerNums;
    
    // list of owners
    uint public constant MAX_OWNERS = 16;
    address[MAX_OWNERS + 1] owners;
    mapping(address => uint) ownerIndexOf;

    /// @inheritdoc IMultiOwnedState
    mapping(uint => PendingState) public override pendingOf;
    /// @inheritdoc IMultiOwnedState
    uint public override nextPendingTxId = 1;

    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
    }

    // self call function modifier.
    modifier onlySelfCall() {
        require(msg.sender == address(this), "OSC");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        uint nums = _owners.length + 1;
        require(MAX_OWNERS >= nums, "MAX");
        require(_required <= nums && _required > 0, "REQ");
        
        ownerNums = nums;
        owners[1] = msg.sender;
        ownerIndexOf[msg.sender] = 1;
        for (uint i = 0; i < _owners.length; ++i) {
            require(_owners[i] != address(0), "ZA");
            require(!isOwner(_owners[i]), "ISO");
            owners[2 + i] = _owners[i];
            ownerIndexOf[_owners[i]] = 2 + i;
        }
        requiredNum = _required;
    }
    
    /// @inheritdoc IMultiOwnedActions
    function revoke(uint txId) external override {
        uint ownerIndex = ownerIndexOf[msg.sender];
        require(ownerIndex != 0, "OC");

        uint ownerIndexBit = 2**ownerIndex;
        PendingState storage pending = pendingOf[txId];
        require(pending.ownersDone & ownerIndexBit > 0, "OD");

        pending.yetNeeded++;
        pending.ownersDone -= ownerIndexBit;
        emit Revoke(msg.sender, txId);
    }
    

    /// @inheritdoc IMultiOwnedActions
    function changeOwner(address from, address to) onlySelfCall external override {
        uint ownerIndex = ownerIndexOf[from];
        require(ownerIndex > 0, "COF");
        require(!isOwner(to) && to != address(0), "COT");

        clearPending();
        owners[ownerIndex] = to;
        ownerIndexOf[from] = 0;
        ownerIndexOf[to] = ownerIndex;
        emit OwnerChanged(from, to);
    }
    
    /// @inheritdoc IMultiOwnedActions
    function addOwner(address newOwner) onlySelfCall external override {
        require(!isOwner(newOwner), "AON");
        require(ownerNums < MAX_OWNERS, "AOM");
        
        clearPending();
        ownerNums++;
        owners[ownerNums] = newOwner;
        ownerIndexOf[newOwner] = ownerNums;
        emit OwnerAdded(newOwner);
    }
    
    /// @inheritdoc IMultiOwnedActions
    function removeOwner(address owner) onlySelfCall external override {
        uint ownerIndex = ownerIndexOf[owner];
        require(ownerIndex > 0, "ROI");
        require(requiredNum <= ownerNums - 1, "RON");

        owners[ownerIndex] = address(0);
        ownerIndexOf[owner] = 0;
        clearPending();
        reorganizeOwners(); 
        emit OwnerRemoved(owner);
    }
    
    /// @inheritdoc IMultiOwnedActions
    function changeRequirement(uint newRequired) onlySelfCall external override {
        require(newRequired <= ownerNums && newRequired > 0, "CR");

        requiredNum = newRequired;
        clearPending();
        emit RequirementChanged(newRequired);
    }

    /// @inheritdoc IMultiOwnedState
    function getOwner(uint ownerIndex) external override view returns (address) {
        return address(owners[ownerIndex + 1]);
    }

    /// @inheritdoc IMultiOwnedState
    function isOwner(address addr) public override view returns (bool) {
        return ownerIndexOf[addr] > 0;
    }
    
    /// @inheritdoc IMultiOwnedState
    function hasConfirmed(uint txId, address owner) external override view returns (bool) {
        PendingState storage pending = pendingOf[txId];
        uint ownerIndex = ownerIndexOf[owner];
        if (ownerIndex == 0) return false;
        
        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        return (pending.ownersDone & ownerIndexBit > 0);
    }
    

    function confirmAndCheck(uint txId, uint ownerIndex) internal returns (bool) {
        PendingState storage pending = pendingOf[txId];
        // if we're not yet working on this operation, switch over and reset the confirmation status.
        if (pending.yetNeeded == 0) {
            // reset count of confirmations needed.
            pending.yetNeeded = requiredNum;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            nextPendingTxId = txId + 1;
        }
        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        // make sure we (the message sender) haven't confirmed this operation previously.
        if (pending.ownersDone & ownerIndexBit == 0) {
            emit Confirmation(msg.sender, txId);
            // ok - check if count is enough to go ahead.
            if (pending.yetNeeded <= 1) {
                // enough confirmations: reset and run interior.
                delete pendingOf[txId];
                return true;
            } else {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
        return false;
    }

    function reorganizeOwners() private {
        uint free = 1;
        while (free < ownerNums) {
            while (free < ownerNums && owners[free] != address(0)) free++;
            while (ownerNums > 1 && owners[ownerNums] == address(0)) ownerNums--;
            if (free < ownerNums && owners[ownerNums] != address(0) && owners[free] == address(0)) {
                owners[free] = owners[ownerNums];
                ownerIndexOf[owners[free]] = free;
                owners[ownerNums] = address(0);
            }
        }
    }
    
    function clearPending() virtual internal {
        uint length = nextPendingTxId;
        for (uint i = 1; i < length; ++i)
            if (pendingOf[i].yetNeeded != 0) delete pendingOf[i];
        nextPendingTxId = 1;
    }
}

// File: contracts/interfaces/IMultiSigWallet.sol
/// @title MultiSigWallet 接口
interface IMultiSigWallet {    
    /// @notice 执行一笔多签交易时，触发该事件
    event MultiTransact(address owner, uint txId, uint value, address to, bytes data);
    
     /// @notice 创建完一笔还需要签名的交易时，触发该事件
    event ConfirmationNeeded(uint txId, address initiator, uint value, address to, bytes data);


    /// @notice 查询某个pending交易的数据
    /// @param txId 交易索引号
     function txsOf(uint txId) external view returns(
        address to,
        uint value,
        bytes memory data
    );


    /// @notice 创建待签名的交易
    /// @dev This function can only be called by owner
    /// @param to 目标地址
    /// @param value eth数量
    /// @param data 调用目标方法的msg.data
    /// @return txId 交易号
    function execute(address to, uint value, bytes memory data) external returns (uint txId);

    /// @notice 签名pending交易
    /// @dev This function can only be called by owner
    /// @param txId 交易号
    /// @return success 是否执行成功
    function confirm(uint txId) external returns (bool success);
}

// File: contracts/MultiSigWallet.sol
contract MultiSigWallet is IMultiSigWallet, MultiOwned {
    /// @inheritdoc IMultiSigWallet
    mapping (uint => Transaction) public override txsOf;

    struct Transaction {
        address to;
        uint value;
        bytes data;
    }

    constructor(address[] memory _owners, uint _required)
            MultiOwned(_owners, _required) {
    }
    
    function kill(address payable to) onlySelfCall external {
        selfdestruct(to);
    }

    receive() external payable {

    }
    
    /// @inheritdoc IMultiSigWallet
    function execute(address to, uint value, bytes memory data) override external returns (uint txId) {
        uint ownerIndex = ownerIndexOf[msg.sender];
        require(ownerIndex != 0, "OC");
        require(to != address(0), "EXT");

        if(requiredNum <= 1){
            (bool success, ) = to.call{value:value}(data);
            require(success, "EXC");
            emit MultiTransact(msg.sender, txId, value, to, data);
            return 0;
        }
        
        txId = nextPendingTxId;
        confirmAndCheck(txId, ownerIndex);
        txsOf[txId].to = to;
        txsOf[txId].value = value;
        txsOf[txId].data = data;
        emit ConfirmationNeeded(txId, msg.sender, value, to, data);
    }
    
    /// @inheritdoc IMultiSigWallet
    function confirm(uint txId) override external returns (bool success) {
        uint ownerIndex = ownerIndexOf[msg.sender];
        require(ownerIndex != 0, "OC");

        address to = txsOf[txId].to;
        uint value = txsOf[txId].value;
        bytes memory data = txsOf[txId].data;
        require(to != address(0), "TXI"); 
        if(!confirmAndCheck(txId, ownerIndex)) return true;

        (success, ) = to.call{value:value}(data);
        emit MultiTransact(msg.sender, txId, value, to, data);
        
        if (to != address(this)) delete txsOf[txId];
    }
    
    function clearPending() override internal {
        uint length = nextPendingTxId;
        for (uint i = 1; i < length; ++i)
            if (txsOf[i].to != address(0)) delete txsOf[i];
        super.clearPending();
    }
}