/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: none

pragma solidity ^0.6.0;

interface IUpgradedPS {
    struct userData {
        bool isApproved;
        uint256 totalPurchased;
    }
    function setWhitelist(uint groupid, address account, bool status) external returns(bool);
}
contract Ownable {
    /***
     * Configurator Crowdsale Contract
     */
    address payable internal owner;
    address payable internal admin;

    struct userData {
        bool isApproved;
        uint256 totalPurchased;
    }
    struct admins {
        address account;
        bool isApproved;
    }

    mapping (uint256 => mapping (address => userData)) public userInfo;
    mapping (address => admins) private roleAdmins;

    modifier onlyOwner {
        require(msg.sender == owner, 'Litedex: Only Owner'); 
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == roleAdmins[msg.sender].account && roleAdmins[msg.sender].isApproved == true || msg.sender == owner, 'Litedex: Only Owner or Admin');
        _;
    }
    
    /**
     * Event for Transfer Ownership
     * @param previousOwner : owner Crowdsale contract
     * @param newOwner : New Owner of Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 time);
    

    function setAdmin(address payable account, bool status) external onlyOwner returns(bool){
        require(account != address(0), 'Litedex: account is zero address');
        roleAdmins[account].account = account;
        roleAdmins[account].isApproved = status;
    }
    /**
     * Function to change Crowdsale contract Owner
     * Only Owner who could access this function
     * 
     * return event OwnershipTransferred
     */
    
    function transferOwnership(address payable _owner) onlyOwner external returns(bool) {
        owner = _owner;
        
        emit OwnershipTransferred(msg.sender, _owner, block.timestamp);
        return true;
    }

    constructor() internal{
        owner = msg.sender;
    }
}
contract whitelister is Ownable {
    
    struct members{
        bool isWhitelist;
    }
    address[] private member;
    uint256 private notSet;
    IUpgradedPS sc;
    
    mapping(uint256 => mapping(address=>members)) private m;
    
    constructor(address _sc) public{
        sc = IUpgradedPS(_sc);
        owner = msg.sender;
    }
    function get(uint nim)external view returns(address){
        return member[nim];
    }
    function addBatchWhitelist(address[] memory account) external onlyAdmin returns(bool){
        for(uint i=0;i<account.length;i++){
            member.push(account[i]);
            notSet += i;
        }
    }
    function getTempWhitelist(uint256 gid, bool status) external view returns(address[] memory){
        address[] memory temp;
        for(uint _i=0; _i<member.length;_i++){
            if(m[gid][member[_i]].isWhitelist == status){
                temp[_i] = member[_i];
            }
        }
        return temp;
    }
    function getAllWhitelist() external view returns(address[] memory){
        return member;
    }
    function setWhitelists(uint groupid) external onlyAdmin returns(bool){
        require(notSet >0, 'Litedex: addBatchWhitelist first!');
        for(uint _i=0; _i<member.length;_i++){
            if(m[groupid][member[_i]].isWhitelist == false){
                sc.setWhitelist(groupid, member[_i], true);
                m[groupid][member[_i]].isWhitelist = true;
            }
        }
        notSet = 0;
        return true;
    }
    function changeSmartContract(address _sc) external onlyOwner returns(bool){
        sc = IUpgradedPS(_sc);
        return true;
    }
}