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
contract whitelister {
    
    struct members{
        bool isWhitelist;
    }
    address[] private member=[
        0x850e88b454eF6332cC51D21f3D203066238FD14B,
        0xB3D3E70e4477d354BB0A77b3F817068ECC5f2FB0
        ];
    IUpgradedPS sc;
    address payable private owner;
    
    mapping(uint256 => mapping(address=>members)) private m;
    
    constructor(address _sc) public{
        sc = IUpgradedPS(_sc);
        owner = msg.sender;
    }
    function get(uint nim)external view returns(address){
        return member[nim];
    }
    function addBatchWhitelist(address[] memory account) external returns(bool){
        require(msg.sender == owner, 'you are not owner');
        for(uint i=0;i<account.length;i++){
            member.push(account[i]);
        }
    }
    function setWhitelists(uint groupid) external returns(bool){
        require(msg.sender == owner, 'you are not owner');
        for(uint _i=0; _i<member.length;_i++){
            if(m[groupid][member[_i]].isWhitelist == false){
                sc.setWhitelist(groupid, member[_i], true);
                m[groupid][member[_i]].isWhitelist = true;
            }
        }
        return true;
    }
    function changeSmartContract(address _sc) external returns(bool){
        require(msg.sender == owner, 'you are not owner');
        sc = IUpgradedPS(_sc);
        return true;
    }
}