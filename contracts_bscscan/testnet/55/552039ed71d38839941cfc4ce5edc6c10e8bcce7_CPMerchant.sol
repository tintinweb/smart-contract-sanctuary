// SPDX-License-Identifier: No License
pragma solidity >=0.8.6;

import './IMerchant.sol';
import './Authorization.sol';
import './ReentrancyGuard.sol';
contract CPMerchant is IMerchant, Authorization, ReentrancyGuard{
    string public _name;
    function init(string memory name, address owner)external override onlyAutorizedContract{
        _name = name;
        transferOwnership(owner);
        setAuthorizedCaller(msg.sender);
    }
    function getMerchantOwner() external view override returns(address ownerAddress){
        
    }
    function getName() external override returns(string memory){
        
    }
    function getCollectionAddress(string calldata stationId) external override returns(address){
        
    }
    function addMemberhip(address newMember, string calldata membershipCode)external override{
        
    }
    function execute(address member, uint256 amount, string calldata promoCode)external override{
        
    }
    function executeReward(address member, uint256 amount, string calldata promoCode)external override{
        
    }
    function executeMembership(address member, uint256 amount, string calldata promoCode)external override{
        
    }
    function addStation(string calldata stationId, string calldata stationMeta, address collectionAddress, address acceptedAsset)external override{
        
    }
    function setRouter(PaymentRouter router)external override{
        
    }
    function setPayee(address payeeAddress)external override {
        
    }
    function getPayee()external override returns(address payeeAddress){
        
    }
}