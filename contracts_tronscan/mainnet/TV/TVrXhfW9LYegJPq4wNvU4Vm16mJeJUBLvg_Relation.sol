//SourceUnit: 100_relation.sol

pragma solidity ^0.5.8;

interface IRelation {
    function getUserInfo(address addr) external view returns (uint256, address, uint256, uint256, uint256);
    function getAddrByUid(uint256 uid) external view returns (address);
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call.value(amount)("");
        require(success);
    }
}

contract Ownable {
    using Address for address;
    address payable public Owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(Owner, _newOwner);
        Owner = _newOwner.toPayable();
    }
}

library Objects {
    struct User {
        address addr;
        uint uid;
        uint pid;
        uint TSC;
        uint TSS;
    }
}

contract Relation is Ownable {
    using Address for address;
    using SafeMath for uint;

    IRelation oldRelation = IRelation(0x41439a5590e92be4477c31f41ff8f4f4e5a9262100); 

    constructor() public {
        newUser(msg.sender, 0);
    }

    mapping(address => uint) addr2uid_;
    mapping(uint => Objects.User) public uid2User_;
    
    mapping(address => bool) mgr_;
    
    uint public userCnt_;
    
    modifier onlyMgr() {
        require(msg.sender == Owner || mgr_[msg.sender] == true);
        _;
    }
    
    function setMgr(address addr, bool flag) public onlyOwner returns (bool) {
        mgr_[addr] = flag;
        return true;
    }
    
    function newUser(address addr, uint pid) internal returns (uint) {
        uint uid = addr2uid_[addr];
        if (uid > 0) {
            return uid;
        }

        userCnt_ = userCnt_ + 1;
        uid = userCnt_;
        
        if (pid == uid) {
            pid = 1;
        }
        if (uid == 1) {
            pid = 0;
        }
        uid2User_[uid].addr = addr;
        uid2User_[uid].uid = uid;
        uid2User_[uid].pid = pid;
        addr2uid_[addr] = uid;
        return uid;
    }

    function getUID(address addr) public view returns (uint) {
        return addr2uid_[addr];
    }
    
    function getAddrByUid(uint uid) public view returns (address) {
        return uid2User_[uid].addr;
    }
    
    function getRewardInfo(address addr) public view returns (uint TSC, uint TSS) {
        uint uid = addr2uid_[addr];
        return (
            uid2User_[uid].TSC,
            uid2User_[uid].TSS
        );
    }
    
    function getUserParent(address addr) public view returns (address parent, address grandParent) {
        uint uid = addr2uid_[addr];
        return (
            uid2User_[uid2User_[uid].pid].addr, 
            uid2User_[uid2User_[uid2User_[uid].pid].pid].addr
        );
    }

    function setRelation(uint inviterID, address sender) public onlyMgr returns (bool) {
        require(oldUidConvert, "old convert should be true");

        if (inviterID == 0 || inviterID > userCnt_) {
            inviterID = 1;
        }

        uint uid = getUID(sender);
        if (0 == uid) {
            uid = newUser(sender, inviterID);
        }

        return true;
    }

    function incTsc(address addr, uint amount) public onlyMgr returns (bool) {
        uint uid = addr2uid_[addr];
        uid2User_[uid].TSC = uid2User_[uid].TSC + amount;
    }

    function incTss(address addr, uint amount) public onlyMgr returns (bool) {
        uint uid = addr2uid_[addr];
        uid2User_[uid].TSS = uid2User_[uid].TSS + amount;
    }

    bool public oldUidConvert;
    function getOldDataa(uint startID, uint cnt) public onlyOwner returns (uint) {
        require(oldUidConvert == false, "old convert should be false");
        uint uid = userCnt_;

        if(cnt < 10) {
            cnt = 10;
        }
        
        uint endID = startID + cnt;
        if (startID < uid) {
            startID = uid;
        }
        if (uid > endID) {
            endID = uid + cnt;
        }

        address addr;
        uint newUid;
        for ( uid = startID; uid < endID; uid = uid + 1) {
            addr = oldRelation.getAddrByUid(uid);
            if (address(0) == addr) {
                oldUidConvert = true;
                break;
            }
            (uint uidOld, address uaddr, uint uamount, uint pid, uint gpid) = oldRelation.getUserInfo(addr);
            newUid = newUser(addr, pid);
            require(newUid == uidOld, "new uid != old uid");
        }
        return uid;
    }

}