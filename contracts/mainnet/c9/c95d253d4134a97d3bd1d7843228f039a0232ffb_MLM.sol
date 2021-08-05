/**
 *Submitted for verification at Etherscan.io on 2020-07-19
*/

pragma solidity ^0.6.10;
// SPDX-License-Identifier: MIT
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        require(c >= a, "overflow error");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "overflow error");
        uint256 c = a - b;
        return c;
    }
    
    function inc(uint a) internal pure returns(uint) {
        return(add(a, 1));
    }

    function dec(uint a) internal pure returns(uint) {
        return(sub(a, 1));
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
}

contract MLM {
    using SafeMath for uint;
//****************************************************************************    
//* Data
//****************************************************************************    
    struct Tx {
        uint fr;
        uint to;
        uint value;
    }
    struct User {
        address payable parent;
        address payable ldirect;
        address payable mdirect;
        address payable rdirect;
        uint level;
        mapping(uint => Tx) txs;
        uint txCount;
        uint uid;
        uint poolShare;
    }
    address payable[] directUsers;
    mapping(address => User) users;
    mapping(uint => address) uids;
    address payable[] usersArray;
    uint[] portions;
    uint share;
    uint directShare;
    address owner;
    address payable beneficiary; //wallet owner
    bool maintainance;
    uint maxDirectRegister;
    uint directRegisterCount;
    uint uidPrecision = 1e4;
    uint maxLevel = 0;
    uint pool = 0;
    uint autoPoolShare;
//****************************************************************************    
//* Events
//****************************************************************************    
    event UserRegistered(address payable parent, address payable child, uint level);
    event PoolDischarged(uint poolValue, uint usersCount, uint time);
//****************************************************************************    
//* Modifiers
//****************************************************************************    
    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    modifier maintainanceOn {
        require(maintainance);
        _;
    }
    
    modifier maintainanceOff {
        require(! maintainance);
        _;
    }
    
    modifier notRegistered {
        require(users[msg.sender].uid == 0);
        _;
    }
    
    modifier registered(address payable _member) {
        require(users[_member].uid > 0);
        _;
    }
    
    modifier shareSet {
        require(share > 0 && directShare > 0);
        _;
    }
    
    modifier isNode(address node) {
        require(users[node].uid > 0); 
        _;
    }

//****************************************************************************    
//* Functions
//****************************************************************************    
    constructor() public {
        maintainance = true;
        owner = msg.sender;
        beneficiary = msg.sender;
        portions.push(0);
        maxDirectRegister = 1;
    }
    
    function withdrawMyPoolShare() public {
        require(users[msg.sender].poolShare > 0);
        msg.sender.transfer(users[msg.sender].poolShare);
        users[msg.sender].poolShare = 0;
    }
    
    function dischargePool() public isOwner {
        require(pool > 0);
        uint poolShare = pool/usersArray.length;
        for (uint i = 0; i < usersArray.length; i = i.inc()) {
            users[usersArray[i]].txs[users[usersArray[i]].txCount] = Tx({
                fr: 0,
                to: users[usersArray[i]].uid,
                value: poolShare
            });
            pool = pool.sub(poolShare);
            users[usersArray[i]].txCount = users[usersArray[i]].txCount.inc();
            users[usersArray[i]].poolShare = users[usersArray[i]].poolShare.add(poolShare);
        }
        emit PoolDischarged(pool, usersArray.length, now);
    }
    
    function getUsersCount() public view returns(uint) {
        return(usersArray.length);    
    }
    
    function getPoolValue() public view returns(uint) {
        return(pool);
    }
    
    function getMyPoolShare() public view returns(uint) {
        require(users[msg.sender].uid > 0);
        return(users[msg.sender].poolShare);
    }
    
    function changeMaxDirectRegister(uint _maxDirectRegister) public isOwner {
        require(_maxDirectRegister != maxDirectRegister);
        require(_maxDirectRegister >= getDirectRegisterCount());
        maxDirectRegister = _maxDirectRegister;
    }
    
    function getMaxDirectRegister() public view isOwner returns(uint) {
        return(maxDirectRegister);
    }
    
    function getDirectRegisterCount() public view isOwner returns(uint) {
        return(directRegisterCount);
    }
    
    function getDirectRegister(uint _index) public view returns(address payable) {
        require((msg.sender == owner) || (msg.sender == beneficiary));
        return(directUsers[_index.dec()]);
    }
    
    function getRemainedDirectRegister() public view returns(uint) {
        return(maxDirectRegister.sub(directRegisterCount));
    }
    
    function changeOwner(address _owner) public isOwner {
        require(owner != _owner);
        owner = _owner;
    }
    
    function setPoolShare(uint _poolShare) public isOwner maintainanceOn {
        require(autoPoolShare != _poolShare);
        autoPoolShare = _poolShare;
    }
    
    function getPoolShare() public view returns(uint) {
        return(autoPoolShare);
    }
    
    function setActive() public isOwner maintainanceOn shareSet {
        uint portionsSum = autoPoolShare;
        for (uint l = 1; l < portions.length; l = l.inc()) {
            portionsSum = portionsSum.add(portions[l]);
        }
        require(portionsSum < share);
        maintainance = false;
    }
    
    function setInactive() public isOwner maintainanceOff {
        maintainance = true;
    }
    
    function setShare(uint _share) public isOwner maintainanceOn {
        require(_share > 0);
        require(share != _share);
        share = _share;
    }

    function getShare() public view returns(uint) {
        return(share);
    }
    
    function setDirectShare(uint _share) public isOwner maintainanceOn {
        require(_share > 0);
        require(directShare != _share);
        directShare = _share;
    }

    function getDirectShare() public view returns(uint) {
        return(directShare);
    }

    function setBeneficiary(address payable _beneficiary) public isOwner {
        require(_beneficiary != beneficiary);
        beneficiary = _beneficiary;
    }
    
    function setPortion(uint _level, uint _portion) public isOwner maintainanceOn {
        require(_level > 0);
        uint currentLevel = portions.length.dec();
        if (_level > currentLevel) {
            for (uint l = currentLevel.inc(); l < _level; l = l.inc()) {
                portions.push(0);
            }
            portions.push(_portion);
        }
        else {
            portions[_level] = _portion;
        }
    }
    
    function getPortion(uint _level) public view returns(uint) {
        require(_level < portions.length);
        return(portions[_level]);
    }

    function getPortionCount() public view returns(uint) {
        return(portions.length);
    }

    function getDirectChildsCount(address _node) public view isNode(_node) returns(uint) {
        uint childs = 0;
        if (users[_node].ldirect != address(0))
            childs = childs.inc();
        if (users[_node].mdirect != address(0))
            childs = childs.inc();
        if (users[_node].rdirect != address(0))
            childs = childs.inc();
        return(childs);
    }
    
    function getDirectChilds(address _node) public view isNode(_node) returns(address, address, address) {
        return(users[_node].ldirect, users[_node].mdirect, users[_node].rdirect);
    }
    
    function getDirectChildsUid(uint _uid) public view returns(uint, uint, uint) {
        require(uids[_uid] != address(0));
        return(
            users[users[uids[_uid]].ldirect].uid, 
            users[users[uids[_uid]].mdirect].uid, 
            users[users[uids[_uid]].rdirect].uid
            );
    }
    
    function getChildsCount(address _node) public view isNode(_node) returns(uint) {
        if (_node == address(0))
            return(0);
        uint childs = getDirectChildsCount(_node);
        if (users[_node].ldirect != address(0))
            childs = childs.add(getChildsCount(users[_node].ldirect));
        if (users[_node].mdirect != address(0))
            childs = childs.add(getChildsCount(users[_node].mdirect));
        if (users[_node].rdirect != address(0))
            childs = childs.add(getChildsCount(users[_node].rdirect));
        return(childs);
    }
    
    function withdraw(uint value) public isOwner {
        beneficiary.transfer(value);
    }
    
    function getParent(address node) public view isNode(node) returns(address) {
        return(users[node].parent);
    }
    
    function findParentInLevel(address payable _referral, uint _level) private view returns(address payable) {
        if (_level == 1) {
            if (getDirectChildsCount(_referral) < 3)
                return(_referral);
            else
                return(address(0));
        }
        else {
            address payable ldirect = findParentInLevel(users[_referral].ldirect, _level.dec());
            if (ldirect == address(0)) {
                address payable mdirect = findParentInLevel(users[_referral].mdirect, _level.dec());
                if (mdirect == address(0)) {
                    address payable rdirect = findParentInLevel(users[_referral].rdirect, _level.dec());
                    return(rdirect);
                }
                else
                    return(mdirect);
            }
            else
                return(ldirect);
        }
    }
    
    function getNearestParent(address payable _referral) private view returns(address payable) {
        if (_referral == address(0))
            return(address(0));
        uint _level = 1;
        bool _found = false;
        address payable _parent;
        while (! _found) {
            _parent = findParentInLevel(_referral, _level);
            if (_parent == address(0))
                _level = _level.inc();
            else
                _found = true;
        }
        return(_parent);
    }
    
    function generateUid() private returns(uint) {
        if (getUsersCount() >= (uidPrecision / 10))
            uidPrecision *= 10;
        int time = - int(now);
        uint uid = uint(msg.sender) ^ uint(address(this)) ^ uint(time) ^ uint(blockhash(block.number-1));
        if (uid == 0)
            uid = 1;
        while (uid > uidPrecision)
            uid = uid / 10;
        while (users[uids[uid]].uid >0) {
            if (uid == (uidPrecision.dec()))
                uid = 1;
            else
                uid = uid.inc();
        }
        return(uid);
    }
    
    function registerDirect() public payable maintainanceOff notRegistered {
        require(maxDirectRegister > directRegisterCount);
        address payable _referral = address(0);
        directRegisterCount = directRegisterCount.inc();
        directUsers.push(msg.sender);
        doRegister(_referral, directShare);
    }
    
    function registerNoReferral() public payable maintainanceOff notRegistered {
        address payable minLevelParent = getNearestParent(directUsers[0]);
        uint minLevel = users[minLevelParent].level;
        for(uint i = 1; i < directUsers.length; i = i.inc()) {
            address payable parent = getNearestParent(directUsers[i]);
            uint level = users[parent].level;
            if (level < minLevel) {
                minLevel = level;
                minLevelParent = parent;
            }
        }
        doRegister(minLevelParent, share);
    }
    
    function registerReferral(address payable _referral) public payable maintainanceOff notRegistered {
        require(_referral != address(0));
        _referral = getNearestParent(_referral);
        doRegister(_referral, share);
    }
    
    function doRegister(address payable _referral, uint _share) private {
        require(users[msg.sender].uid == 0);
        doRegisterData(_referral, msg.sender, _share);
        doRegisterPayment(msg.sender, _share);
    }
    
    function doRegisterData(address payable _referral, address payable _child, uint _share) private {
        uint _level;
        uint _uid = generateUid();
        if (_referral == address(0))
            _level = 1;
        else
            _level = users[_referral].level.inc();
        if (_level > maxLevel)
            maxLevel = _level;
        users[_child] = User({
            parent: _referral,
            level: _level,
            txCount: 1,
            ldirect: address(0),
            mdirect: address(0),
            rdirect: address(0),
            uid: _uid,
            poolShare: 0
        });
        users[_child].txs[0] = Tx({
            fr: users[_child].uid,
            to: 0,
            value: _share
        });
        uids[_uid] = _child;
        usersArray.push(_child);
        if (_referral != address(0)) {
            if (users[_referral].ldirect == address(0))
                users[_referral].ldirect = _child;
            else if (users[_referral].mdirect == address(0))
                users[_referral].mdirect = _child;
            else if (users[_referral].rdirect == address(0))
                users[_referral].rdirect = _child;
            else
                revert();
        }
        emit UserRegistered(_referral, _child, _level);
    }
    
    function doRegisterPayment(address payable _child, uint _share) private {
        address payable node = _child;
        uint value = msg.value;
        require(value >= _share);
        uint portionsSum = 0;
        for (uint l = 1; l < portions.length; l = l.inc()) {
            node = users[node].parent;
            if (portions[l] > 0) {
                if (node != address(0)) {
                    portionsSum = portionsSum.add(portions[l]);
                    node.transfer(portions[l]);
                    users[node].txs[users[node].txCount] = Tx({
                        fr: users[_child].uid,
                        to: users[node].uid,
                        value: portions[l]
                    });
                    users[node].txCount = users[node].txCount.inc();
                }
            }
        }
        pool = pool.add(autoPoolShare);
        uint beneficiaryShare = _share.sub(portionsSum).sub(autoPoolShare);
        beneficiary.transfer(beneficiaryShare);
        uint remainedValue = value.sub(_share);
        if (remainedValue > 0)
            _child.transfer(remainedValue);
    }
    
    function doRegisterTx(address payable _child) private {
        address payable node = _child;
        for (uint l = 1; l < portions.length; l = l.inc()) {
            node = users[node].parent;
            if (portions[l] > 0) {
                if (node != address(0)) {
                    users[node].txs[users[node].txCount] = Tx({
                        fr: users[_child].uid,
                        to: users[node].uid,
                        value: portions[l]
                    });
                    users[node].txCount = users[node].txCount.inc();
                }
            }
        }
    }
    
    function getOwner() public view returns(address) {
        return(owner);
    }
    
    function getBeneficiary() public view returns(address) {
        return(beneficiary);
    }
    
    function getBalance() public view isOwner returns(uint) {
        return(address(this).balance);
    }
    
    function getMaintainance() public view returns(bool) {
        return(maintainance);
    }
    
    function getAddress(uint _uid) public view returns(address payable) {
        require(uids[_uid] != address(0));
        return(payable(uids[_uid]));
    }
    
    function getUid(address payable _address) public view returns(uint) {
        require(users[_address].uid > 0);
        return(users[_address].uid);
    }
    
    function getMyUid() public view returns(uint) {
        return(getUid(msg.sender));
    }
    
    function isMember(address payable _address) public view returns(bool) {
        return(users[_address].uid > 0);
    }
    
    function isMemberByUid(uint _uid) public view returns(bool) {
        return(uids[_uid] != address(0));
    }
    
    function getTxCount(address payable _address) public view registered(_address) returns(uint) {
        return(users[_address].txCount);
    }
    
    function getTx(address payable _address, uint _index) public view registered(_address) returns(uint, uint, uint, uint, uint) {
        require(_index < users[_address].txCount);
        uint uid = getUid(_address);
        return(_index, uid, users[_address].txs[_index].fr, users[_address].txs[_index].to, users[_address].txs[_index].value);
    }
    
    function getPaid(address payable _address) public view registered(_address) returns(uint) {
        return(users[_address].txs[0].value);
    }

    function getEarned(address payable _address) public view registered(_address) returns(uint) {
        uint sum;
        for (uint i = 1; i < users[_address].txCount; i= i.inc())
            sum = sum.add(users[_address].txs[i].value);
        return(sum);
    }
    
    function getLevel(address payable _address) public view registered(_address) returns(uint) {
        return(users[_address].level);
    }
    
    function initialize(address payable _parent, address payable _child) public maintainanceOn {
        require((msg.sender == owner) || (msg.sender == beneficiary));
        require(_parent != address(0));
        require(_child != address(0));
        require(users[_parent].uid > 0);
        require(users[_child].uid == 0);
        doRegisterData(_parent, _child, share);
        doRegisterTx(_child);
    }
    
    function initializeDirect(address payable _direct) public maintainanceOn {
        require((msg.sender == owner) || (msg.sender == beneficiary));
        require(maxDirectRegister > directRegisterCount);
        require(_direct != address(0));
        require(users[_direct].uid == 0);
        directRegisterCount = directRegisterCount.inc();
        directUsers.push(msg.sender);
        doRegisterData(address(0), _direct, directShare);
    }
    
    function getMaxLevel() public view isOwner returns(uint) {
        return(maxLevel);
    }
    
    function getAddressById(uint _id) public view returns(address payable) {
        require((msg.sender == owner) || (msg.sender == beneficiary));
        return(usersArray[_id]);
    }
    
    function getUidById(uint _id) public view returns(uint) {
        require((msg.sender == owner) || (msg.sender == beneficiary));
        return(users[usersArray[_id]].uid);
    }
}