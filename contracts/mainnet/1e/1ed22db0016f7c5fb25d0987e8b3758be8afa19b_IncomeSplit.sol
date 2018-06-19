///@title Simple Organisation Management
///@author bsm - moonmission
///@version 0.4
///@date 11 Sep 2017
///@licence: MIT

pragma solidity ^0.4.15;

contract IncomeSplit {
    
    struct Member {
        uint memberIndex;
        uint memberShares;
        uint memberBalance;
    }
    
    /// Variables declarations
    // Address of the contract owner. 
    // The owner is the only account which can add/update/remove a member to the organisation.
    // The owner can also trigger fund withdrawals on behalf of another member.
    // The owner is not a member by default.
    // Can be changed using the changeOwner function.
    address OWNER = 0x00cf7440B6E554EC5EeCfA8306761EBc5Bf412b8;
    // We assign the Member structure to each address.
    mapping (address => Member) private Members;
    address[] private index;
    uint totalShares;
    

    modifier onlyBy(address _user) {
        require(msg.sender == _user);
        _;
    }

    modifier isUser(address _user) {
        require(index[Members[_user].memberIndex] == _user);
        _;
    }

    event LogIncomeAllocation(address _address, uint _amount);
    event LogWithdrawal(address _address, uint _amount);
    event LogNewOwner(address _address);

    function changeOwner(address _newOwner) onlyBy(OWNER) returns(bool success) {
        OWNER = _newOwner;
        LogNewOwner(_newOwner);
        return true;
    }
    
    function getTotalShares() public constant returns(uint) {
        return totalShares;
    }

    function getMember(address _address) public constant returns(uint _index, uint _shares, uint _balance) {
        _index = Members[_address].memberIndex;
        _shares = Members[_address].memberShares;
        _balance = Members[_address].memberBalance;

        return(_index, _shares, _balance);
    }

    function getMemberCount() public constant returns(uint) {
        return index.length;
    }

    function getMemberAtIndex(uint _index) public constant returns(address) {
        return index[_index];
    }
    
    function addMember(address _address, uint _shares) onlyBy(OWNER) returns(bool success) {
        Members[_address].memberShares = _shares;
        Members[_address].memberIndex = index.push(_address) - 1;
        totalShares += _shares;
        return true;
    }

    function updateMember(address _address, uint _shares) onlyBy(OWNER) isUser(_address) returns(bool success) {
        uint oldShares = Members[_address].memberShares;
        Members[_address].memberShares = _shares;
        totalShares += (_shares - oldShares);
        return true;
    }

    function deleteMember(address _address) onlyBy(OWNER) isUser(_address) returns(bool success) {
        uint rowToDelete = Members[_address].memberIndex;
        address keyToMove = index[index.length - 1];
        index[rowToDelete] = keyToMove;
        Members[keyToMove].memberIndex = rowToDelete;
        index.length--;
        return true;
    }
    
    function incomeAllocation() payable {
        uint toBeAllocated = msg.value;
        for (uint i = 0; i < index.length; i++) {
            uint allocationRatio = Members[index[i]].memberShares * 1000000000 / totalShares;
            Members[index[i]].memberBalance += (toBeAllocated * allocationRatio / 1000000000);
            LogIncomeAllocation(index[i], Members[index[i]].memberBalance);
        }

    }

    function selfWithdrawBalance() isUser(msg.sender) returns(bool success) {
        uint amount = Members[msg.sender].memberBalance;
        Members[msg.sender].memberBalance = 0;
        msg.sender.transfer(amount);
        LogWithdrawal(msg.sender, amount);
        return true;
    }
    
    function withdrawBalance(address _address) onlyBy(OWNER) isUser(_address) returns(bool success) {
        uint amount = Members[_address].memberBalance;
        Members[msg.sender].memberBalance = 0;
        _address.transfer(amount);
        LogWithdrawal(_address, amount);
        return true;
    }
    
    function() payable {
        if (msg.value == 0) {
            selfWithdrawBalance();
        } else {
            incomeAllocation();
        }
        
    }
}