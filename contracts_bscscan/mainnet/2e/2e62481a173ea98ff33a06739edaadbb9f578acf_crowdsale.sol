/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract tokenContract {    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
}
    
contract crowdsale {
    struct generalConfig {
        uint256 rate;
        address tokenContractAddress;
        address admin;
        address owner;
        uint256 maxLimit;
        uint256 sold;
        uint256 refCom;
        uint256 refPaid;
        uint256 funded;
        uint256 balance;
        bool refStatus;
        bool paused;
    }

    struct UserDetails {
        address refAdd;
        uint256 refPaid;
        uint256 refCount;
        address[] refList;        
    }    
    
    generalConfig _general;
    
    mapping(address =>  UserDetails) private _user;
    
    constructor () {
        _general.tokenContractAddress = 0xA42db191C071f34c9dcA3a88E3639b46d9296a66;
        _general.admin = payable(msg.sender);
        _general.owner = 0x6D8ea267360686F374dA6AF5B9939842951c218d;
        _general.rate =  1e15;
        _general.maxLimit = 1e25;
        _general.refCom = 10;
        _general.paused = true;
        _general.refStatus = false;
    }
    
    function generalDetails() public view returns (generalConfig memory) {
        generalConfig memory genConf = _general;
        genConf.balance = address(this).balance;
        return genConf;
    }
    
    function userDetails(address account) public view returns (UserDetails memory) {
        return _user[account];
    }    
    
    function buy(address refAdd) public payable virtual returns (bool) {
        require(!_general.paused, "Sales not active/paused");
        require(msg.value > 0, "Send payment greater than Zero");
        uint256 token = (msg.value * 1e18) / _general.rate;
        uint256 refAmount = (token * _general.refCom)/100;
        require(token <= (_general.maxLimit - (_general.sold + _general.refPaid)), "Your purchase is greater than allowed limit");
        if(_general.refStatus){
            if(_user[payable(msg.sender)].refAdd == address(0) && refAdd != address(0) && refAdd != payable(msg.sender)){
                _user[payable(msg.sender)].refAdd = refAdd;
                _user[refAdd].refList.push(payable(msg.sender));
                _user[refAdd].refCount = _user[refAdd].refCount + 1;
            } 
            if(_user[payable(msg.sender)].refAdd != address(0)){
                require(_general.sold < _general.maxLimit && (token + refAmount) <= (_general.maxLimit - (_general.sold + _general.refPaid)), "Your purchase is greater than allowed limit");
                _general.refPaid = _general.refPaid + refAmount;
                _user[_user[payable(msg.sender)].refAdd].refPaid = _user[_user[payable(msg.sender)].refAdd].refPaid + refAmount;
                tokenContract(_general.tokenContractAddress).transferFrom(_general.owner, refAdd, refAmount);            
            }
        }
        tokenContract(_general.tokenContractAddress).transferFrom(_general.owner, payable(msg.sender), token);
        _general.sold = _general.sold + token;
        _general.funded = _general.funded + msg.value;
        return true;
    }
    
    function claimFunding() public virtual returns (bool) {
        require(payable(msg.sender) == _general.owner, "Only Owner can claim");
        payable(_general.owner).transfer(address(this).balance);
        return true;
    }
    
    function update(uint256 rate, uint256 maxLimit, uint256 refCom, uint256 refStatus, uint256 paused, address owner) public virtual returns (bool) {
        require(payable(msg.sender) == _general.admin, "Only admin can update");
        _general.rate = (rate != 0)?rate:_general.rate;
        _general.maxLimit = (maxLimit != 0)?maxLimit:_general.maxLimit;
        _general.refCom = (refCom != 0)?refCom:_general.refCom;
        if(owner != address(0)){
            _general.owner = owner;
        }
        if(refStatus > 0){
            _general.refStatus = (refStatus == 1)?true:false;
        }
        if(paused > 0){
            _general.paused = (paused == 1)?true:false;
        }
        return true;
    }
    
}