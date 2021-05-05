/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;
    
contract Whitelist {
    
    address public owner;
    uint public totalWhitelisted;
    uint public totalAmount;
    uint public batchIDs;
    uint public batchSize;
    
    struct User {
        bool isWhitelisted;
        uint amount;
    }
    
    struct Batch {
        uint nonce;
        address[] users;
    }
    
    mapping(address => User) private _users;
    mapping(uint => Batch) private _batches;
    
    event NewWhitelist(address user, uint amount);
    event NewBatchCreated(uint indexed ID);

    constructor(address _owner, uint _batchSize) {
        owner = _owner;
        batchSize = _batchSize;
    }
    
    modifier onlyOwner() {
        
        require(msg.sender == owner, "only owner can do this");
        _;
    }
    
    function _whitelist(address _user, uint _amount) internal {
        
        User storage user = _users[_user];
        user.isWhitelisted = true;
        user.amount = _amount;
        
        totalWhitelisted++;
        totalAmount + _amount;
        
        if (batchIDs == 0 || _batches[batchIDs].nonce == batchSize) {
            batchIDs++;
            emit NewBatchCreated(batchIDs);
        }
        
        _batches[batchIDs].nonce++;
        _batches[batchIDs].users.push(_user);
        
        emit NewWhitelist(_user, _amount);
    }
    
    function batchWhitelist(address[] memory _user, uint[] memory _amount) external onlyOwner returns(bool) {
        
        require(_user.length == _amount.length, "user and min entry must have the same length");
        
        for (uint i = 0; i < _user.length; i++) {
            require(!_users[_user[i]].isWhitelisted, "user already whitelisted"); 
            _whitelist(_user[i], _amount[i]);
        }
        return true;
    }
    
    function whitelist(address _user, uint _amount) external onlyOwner returns(bool){
        
        require(!_users[_user].isWhitelisted, "user already whitelisted");
        
        _whitelist(_user, _amount);
        return true;
    }
    
    function isWhitelisted(address _user) external view returns(bool) {
        
        return _users[_user].isWhitelisted == true;
    }
    
    function getAmount(address _user) external view returns(uint) {
        
        return _users[_user].amount;
    }
    
    function getBatch(uint _batchId) external view returns(address[] memory batchList) {
        
        if(_batchId == 0 || _batchId > batchIDs) revert("invalid batch ID");
        return _batches[_batchId].users;
    }

}