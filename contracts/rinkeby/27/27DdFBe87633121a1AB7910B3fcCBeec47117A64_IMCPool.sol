/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

pragma solidity ^0.5.2;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// 奖池记录合约
// ----------------------------------------------------------------------------
contract IMCPool is Owned{

    // 奖池记录添加日志
    event PoolRecordAdd(bytes32 _chainId, bytes32 _hash, uint _depth, string _data, string _fileFormat, uint _stripLen);

    // Token奖池统计记录
    struct RecordInfo {
        bytes32 chainId; // 上链ID
        bytes32 hash; // hash值
        uint depth; // 层级
        string data; // 竞价数据
        string fileFormat; // 上链存证的文件格式
        uint stripLen; // 上链存证的文件分区
    }

    // 执行者地址
    address public executorAddress;
    
    // 奖此记录
    mapping(bytes32 => RecordInfo) public poolRecord;
    
    constructor() public{
        // 初始化合约执行者
        executorAddress = msg.sender;
    }
    
    /**
     * 修改executorAddress，只有owner能够修改
     * @param _addr address 地址
     */
    function modifyExecutorAddr(address _addr) public onlyOwner {
        executorAddress = _addr;
    }
    
     
    /**
     * 奖池记录添加
     * @param _chainId bytes32 上链ID
     * @param _hash bytes32 hash值
     * @param _depth uint 上链阶段:1 加密上链，2结果上链
     * @param _data string 竞价数据
     * @param _fileFormat string 上链存证的文件格式
     * @param _stripLen uint 上链存证的文件分区
     * @return success 添加成功
     */
    function poolRecordAdd(bytes32 _chainId, bytes32 _hash, uint _depth, string memory _data, string memory _fileFormat, uint _stripLen) public returns (bool) {
        // 调用者需和Owner设置的执行者地址一致
        require(msg.sender == executorAddress);
        // 防止重复记录
        require(poolRecord[_chainId].chainId != _chainId);

        // 记录解锁信息
        poolRecord[_chainId] = RecordInfo(_chainId, _hash, _depth, _data, _fileFormat, _stripLen);

        // 解锁日志记录
        emit PoolRecordAdd(_chainId, _hash, _depth, _data, _fileFormat, _stripLen);
        
        return true;
        
    }

}