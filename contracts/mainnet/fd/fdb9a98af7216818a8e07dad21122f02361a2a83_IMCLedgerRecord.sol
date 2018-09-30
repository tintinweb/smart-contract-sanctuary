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
// 账本记录合约
// ----------------------------------------------------------------------------
contract IMCLedgerRecord is Owned{

    // 账本记录添加日志
    event LedgerRecordAdd(uint _date, bytes32 _hash, uint _depth, string _fileFormat, uint _stripLen, bytes32 _balanceHash, uint _balanceDepth);

    // Token解锁统计记录
    struct RecordInfo {
        uint date;  // 记录日期（解锁ID）
        bytes32 hash;  // 文件hash
        uint depth; // 深度
        string fileFormat; // 上链存证的文件格式
        uint stripLen; // 上链存证的文件分区
        bytes32 balanceHash;  // 余额文件hash
        uint balanceDepth;  // 余额深度
    }
    
    // 账本记录
    mapping(uint => RecordInfo) public ledgerRecord;
    
    constructor() public{

    }
    
     
    /**
     * 账本记录添加
     * @param _date uint 记录日期（解锁ID）
     * @param _hash bytes32 文件hash
     * @param _depth uint 深度
     * @param _fileFormat string 上链存证的文件格式
     * @param _stripLen uint 上链存证的文件分区
     * @param _balanceHash bytes32 余额文件hash
     * @param _balanceDepth uint 余额深度
     * @return success 添加成功
     */
    function ledgerRecordAdd(uint _date, bytes32 _hash, uint _depth, string _fileFormat, uint _stripLen, bytes32 _balanceHash, uint _balanceDepth) public onlyOwner returns (bool) {
        
        // 防止重复记录
        require(!(ledgerRecord[_date].date > 0));

        // 记录解锁信息
        ledgerRecord[_date] = RecordInfo(_date, _hash, _depth, _fileFormat, _stripLen, _balanceHash, _balanceDepth);

        // 解锁日志记录
        emit LedgerRecordAdd(_date, _hash, _depth, _fileFormat, _stripLen, _balanceHash, _balanceDepth);
        
        return true;
        
    }

}