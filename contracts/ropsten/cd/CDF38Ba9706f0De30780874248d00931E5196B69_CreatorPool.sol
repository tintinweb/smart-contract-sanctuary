// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract CreatorPool {

    address public nftFactoryManager;

    struct Pool {
        address creator;
        uint poolValue;

        uint numberOfContributors;

        // storing pool contributors
        mapping(uint => address) contributors;
        // Contributor address => whether the person has interacted with the pool at least once.
        mapping(address => bool) contributorOfPool;
        // contributor => value added to the pool as a result of this moment's sale
        mapping(address => uint) contributionToPool;
    }

    uint public protocolReserves;
    // Address of creator => Creator pool
    mapping(address => Pool) public creatorPool;
    // Address of creator => Whether the creator pool exists
    mapping(address => bool) public poolStatus;
    

    function setFactoryManager(address _newManager) public {
        require(nftFactoryManager == address(0) || nftFactoryManager == msg.sender, "Only the factor manager can call the factory");
        nftFactoryManager = _newManager;
    }

    modifier OnlyFactoryManager(address _caller) {
        require(_caller == nftFactoryManager, "Only the factor manager can call the factory");
        _;
    }

    function getPoolStatus(address _creator) external view returns (bool status) {
        status = poolStatus[_creator];
    }

    function initPool(address _creator) external OnlyFactoryManager(msg.sender) {
        poolStatus[_creator] = true;
        creatorPool[_creator].creator = _creator;
    }

    function onPackPurchase(
        uint _packValue, 
        address payable _creator, 
        address _newPackOwner
    ) external payable OnlyFactoryManager(msg.sender) {
        require(msg.value == _packValue, "Must send the pack value to call the function.");
        payCreatorOnPackPurchase(_packValue, _creator);
        payPoolOnPackPurchase(_packValue, _creator, _newPackOwner);
    }

    function payCreatorOnPackPurchase(uint _packValue, address payable _creator) internal view {
        uint amountToPay = getCreatorCutOnPackPurchase(_packValue);
        _creator.call{value: amountToPay};
    }

    function payPoolOnPackPurchase(uint _packValue, address _creator, address _newPackOwner) internal {
        uint amount = getCommunityCutOnPackPurchase(_packValue);

        creatorPool[_creator].poolValue += amount;

        if(!creatorPool[_creator].contributorOfPool[_newPackOwner]) addContributorToPool(_creator, _newPackOwner);
        creatorPool[_creator].contributionToPool[_newPackOwner] += amount;
    }

    function onMomentPurchase(
        uint _momentValue,
        address payable _creator,
        address payable _prevOwner,
        address _newOwner
    ) external payable OnlyFactoryManager(msg.sender) {
        require(msg.value == _momentValue, "Must send the moment value to call the function.");
        
        uint feeValue = getResaleTransactionFee(_momentValue);

        payPrevOwnerOnMomentPurchase(_momentValue - feeValue, _prevOwner);
        payCreatorOnMomentPurchase(feeValue, _creator);
        payPoolOnMomentPurchase(feeValue, _creator, _prevOwner, _newOwner);
        payProtocolOnMomentPurchase(feeValue);
    }

    function payPrevOwnerOnMomentPurchase(uint _valueToPay, address _prevOwner) internal pure {
        _prevOwner.call{value: _valueToPay};
    } 

    function payCreatorOnMomentPurchase(uint _feeValue, address payable _creator) internal view {
        uint amount = getCreatorCutOfTransactionFee(_feeValue);
        _creator.call{value: amount};
    }

    function payPoolOnMomentPurchase(
        uint _feeValue,
        address payable _creator,
        address payable _prevOwner,
        address _newOwner
    ) internal {

        // Setup
        uint amount = getCommunityCutOfTransactionFee(_feeValue);
        
        if(!creatorPool[_creator].contributorOfPool[_newOwner]) addContributorToPool(_creator, _newOwner);

        creatorPool[_creator].poolValue += amount;
        creatorPool[_creator].contributionToPool[_prevOwner] += amount;
        creatorPool[_creator].contributionToPool[_newOwner] += amount;
    }

    function payProtocolOnMomentPurchase(uint _feeValue) internal {
        protocolReserves += getProtocolCutOfTransactionFee(_feeValue);
    }

    function addContributorToPool(address _creator, address _contributor) internal {
        creatorPool[_creator].contributorOfPool[_contributor] = true;
        creatorPool[_creator].numberOfContributors += 1;
        creatorPool[_creator].contributors[creatorPool[_creator].numberOfContributors] = _contributor;
    }

    // Withraw functions

    function withdrawFromPool(address _creator, uint _amount) external {
        require(creatorPool[_creator].contributorOfPool[msg.sender], "Only contributors of pool can withdraw their share.");
        require(
            creatorPool[_creator].contributionToPool[msg.sender] >= _amount, 
            "Can't withdraw more than what you're contribution's worth."
        );
        
        creatorPool[_creator].poolValue -= _amount; 
        creatorPool[_creator].contributionToPool[msg.sender] -= _amount;

        msg.sender.call{value: _amount};
    }

    // Distribution parameters

    uint public creatorCutOnPackPurchase; // 0.8
    uint public communityCutOnPackPurchase; // 0.2

    uint public resaleTransactionFee; // 0.01
    uint public creatorCutOfTransactionFee; // 0.5 of the 0.01
    uint public communityCutOfTransactionFee; // 0.25 of 0.01
    uint public protocolCutOfTransactionFee; // 0.25 of 0.01

    uint public creatorShareInPool; // 0.5
    uint public communityShareInPool; // 0.5

    // Getters
    function getCreatorCutOnPackPurchase(uint _value) public view returns (uint valueToPay) {
        valueToPay = _value * creatorCutOnPackPurchase/100;
    }

    function getCommunityCutOnPackPurchase(uint _value) public view returns (uint valueToPay) {
        valueToPay = _value * communityCutOnPackPurchase/100;
    }

    function getResaleTransactionFee(uint _value) public view returns (uint valueToPay) {
        valueToPay = _value * resaleTransactionFee/100;
    }

    function getCreatorCutOfTransactionFee(uint _value) public view returns (uint valueToPay) {
        valueToPay = _value * creatorCutOfTransactionFee/100;
    }

    function getCommunityCutOfTransactionFee(uint _value) public view returns (uint valueToPay) {
        valueToPay = _value * communityCutOfTransactionFee/100;
    }

    function getProtocolCutOfTransactionFee(uint _value) public view returns (uint valueToPay) {
        valueToPay = _value * protocolCutOfTransactionFee/100;
    }

    function getPoolValue(address _creator) public view returns (uint value) {
        value = creatorPool[_creator].poolValue;
    }  

    function getContributorShareInPool(address _creator, address _contributor) public view returns (uint share) {
        uint poolValue = creatorPool[_creator].poolValue;
        uint contribution = creatorPool[_creator].contributionToPool[_contributor];

        share = (poolValue * communityShareInPool/100) * (contribution/poolValue);
    }

    function getCreatorShareInPool(address _creator) public view returns (uint share) {
        share = creatorPool[_creator].poolValue * creatorShareInPool/100;
    }      

    // Setters (caller whitelist / other restrictions not set)
    function setSharesOfPackSale(uint _newCreatorCut, uint _newCommunityCut) public {
        require(_newCreatorCut + _newCommunityCut <= 100, "Cuts must add up to a 100 percent.");
        creatorCutOnPackPurchase = _newCreatorCut;
        communityCutOnPackPurchase = _newCommunityCut;
    }

    function setResaleTransactionFee(uint _newTransactionFee) public {
        require(_newTransactionFee <= 100, "Cannot take more than 100 percent as transaction fee.");
        resaleTransactionFee = _newTransactionFee;
    }

    function setSharesOfTransactionFees(
        uint _newCreatorCut,
        uint _newCommunityCut,
        uint _newProtocolCut
    ) public {
        require(_newCreatorCut + _newCommunityCut + _newProtocolCut <= 100, "Cuts must add up to a 100 percent.");

        creatorCutOfTransactionFee = _newCreatorCut;
        communityCutOfTransactionFee = _newCommunityCut;
        protocolCutOfTransactionFee = _newProtocolCut;        
    }

    function setSharesOfPool(uint _newCreatorShare, uint _newCommunityShare) public {
        require(_newCommunityShare + _newCreatorShare <= 100, "Shares must add up to at most 100 percent.");
        creatorShareInPool = _newCreatorShare;
        communityShareInPool = _newCommunityShare;
    }
    
}