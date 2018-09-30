pragma solidity ^0.4.24;

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
// 解锁记录合约
// ----------------------------------------------------------------------------
contract IMCUnlockRecord is Owned{

    // 解锁记录添加日志
    event UnlockRecordAdd(uint _date, bytes32 _hash, string _data, string _fileFormat, uint _stripLen);

    // Token解锁统计记录
    struct RecordInfo {
        uint date;  // 记录日期（解锁ID）
        bytes32 hash;  // 文件hash
        string data; // 统计数据
        string fileFormat; // 上链存证的文件格式
        uint stripLen; // 上链存证的文件分区
    }
    
    // 解锁记录
    mapping(uint => RecordInfo) public unlockRecord;
    
    constructor() public{

    }
    
     
    /**
     * 解锁记录添加
     * @param _date uint 记录日期（解锁ID）
     * @param _hash bytes32 文件hash
     * @param _data string 统计数据
     * @param _fileFormat string 上链存证的文件格式
     * @param _stripLen uint 上链存证的文件分区
     * @return success 添加成功
     */
    function unlockRecordAdd(uint _date, bytes32 _hash, string _data, string _fileFormat, uint _stripLen) public onlyOwner returns (bool) {
        
        // 防止重复记录
        require(!(unlockRecord[_date].date > 0));

        // 记录解锁信息
        unlockRecord[_date] = RecordInfo(_date, _hash, _data, _fileFormat, _stripLen);

        // 解锁日志记录
        emit UnlockRecordAdd(_date, _hash, _data, _fileFormat, _stripLen);
        
        return true;
        
    }

}