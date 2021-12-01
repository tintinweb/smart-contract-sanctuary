/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

pragma solidity ^0.8.3;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
    unchecked {
        counter._value += 1;
    }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
        counter._value = value - 1;
    }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () { }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _checker;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _checker = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function checker() public view returns (address) {
        return _checker;
    }

    function setChecker(address newChecker) public onlyOwner returns (bool) {
        _checker = newChecker;
        return true;
    }

    modifier onlyChecker(){
        require(_checker == _msgSender(), "Ownable: caller is not the checker");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SpaceHelp is Context,Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bool isOpen; //开启：可申请 关闭：不可申请
    mapping(uint256 => ApplyItem) idToApplyItemMap; //id映射对象
    mapping(address => uint256) addrToIdMap; //地址映射id

    Counters.Counter private applyIdCounter; //申请ID计数器

    struct ApplyItem {
        uint256 applyId; //申请ID
        address applyer; //申请人
        uint256 applyTime; //申请时间
        uint256 expAmount; //体验金
        bool status; //拒绝 通过
        bool isCheck; //待审核 已审核
        uint256 checkTime; //审核时间
    }

    constructor() {
        isOpen = true;
    }

    //查询活动状态
    function getOpenStatus() public view returns (bool) {
        return isOpen;
    }

    //设置活动状态
    function setOpenStatus(bool _status) public onlyChecker returns (bool) {
        isOpen = _status;
        return true;
    }

    //申请体验金
    function applyExperience() public returns (bool) {
        require(isOpen == true, "receive channel is closed");
        require(_msgSender() != address(0), "submission address cannot be zero address");
        require(_msgSender() == address(tx.origin), "submission address cannot be contract address");
        //判断是否已申请
        uint256 oldApplyId = addrToIdMap[_msgSender()];
        require(oldApplyId == 0, "you have applied once and cannot apply again");

        applyIdCounter.increment();
        uint256 newApplyId = applyIdCounter.current();
        idToApplyItemMap[newApplyId] = ApplyItem(newApplyId, _msgSender(), block.timestamp, 0, false, false, 0);
        addrToIdMap[_msgSender()] = newApplyId;

        return true;
    }

    //单个审核(通过、拒绝)
    function checkApplyItem(uint256 _applyId, bool _status, uint256 _amount) public onlyChecker returns (bool) {
        require(_amount >= 0, "amount cannot be less than 0");

        ApplyItem storage item = idToApplyItemMap[_applyId];
        require(item.applyId > 0, "relevant application records cannot be queried");

        item.expAmount = _status == false ? 0 : _amount;
        item.status = _status;
        item.isCheck = true;
        item.checkTime = block.timestamp;

        return true;
    }

    //批量审核所有待审批(通过)
    function checkApplyAll(uint256 _amount) public onlyChecker returns (bool) {
        require(_amount >= 0, "amount cannot be less than 0");

        uint256 totalItemCount = applyIdCounter.current();
        require(totalItemCount > 0, "no application records to be approved");

        for (uint256 i = 1; i <= totalItemCount; i++) {
            if (idToApplyItemMap[i].isCheck == false){
                ApplyItem storage item = idToApplyItemMap[i];
                item.expAmount = _amount;
                item.status = true;
                item.isCheck = true;
                item.checkTime = block.timestamp;
            }
        }

        return true;
    }

    //_queryType查询1待审批、2已审批、3全部
    function getApplyList(uint256 _queryType) public view returns (ApplyItem[] memory) {
        uint256 itemCount = 0;
        uint256 totalItemCount = applyIdCounter.current();
        uint currentIndex = 0;

        if (_queryType == 3) {
            itemCount = totalItemCount;
        }else if(totalItemCount > 0) {
            for (uint256 i = 1; i <= totalItemCount; i++) {
                if (_queryType == 1 && idToApplyItemMap[i].isCheck == false) {
                    itemCount++;
                }else if (_queryType == 2 && idToApplyItemMap[i].isCheck == true) {
                    itemCount++;
                }
            }
        }

        ApplyItem[] memory items = new ApplyItem[](itemCount);
        if(itemCount > 0) {
            for (uint256 i = 1; i <= totalItemCount; i++) {
                if (_queryType == 1 && idToApplyItemMap[i].isCheck == false) {
                    items[currentIndex] = idToApplyItemMap[i];
                    currentIndex++;
                }else if (_queryType == 2 && idToApplyItemMap[i].isCheck == true) {
                    items[currentIndex] = idToApplyItemMap[i];
                    currentIndex++;
                }else if (_queryType == 3) {
                    items[currentIndex] = idToApplyItemMap[i];
                    currentIndex++;
                }
            }
        }

        return items;
    }

    //根据账户地址查询申请信息
    function getApplyInfoByAddress(address _address) public view returns (ApplyItem memory) {
        uint256 applyId = addrToIdMap[_address];
        ApplyItem memory item = idToApplyItemMap[applyId];
        return item;
    }

    //根据申请Id查询申请信息
    function getApplyInfoById(uint256 _applyId) public view returns (ApplyItem memory) {
        ApplyItem memory item = idToApplyItemMap[_applyId];
        return item;
    }

}