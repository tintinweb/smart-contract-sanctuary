// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ArbitrumInbox  {

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

}

interface OVMLayer1Messenger{
    function xDomainMessageSender() external view returns (address);
}

contract BondingContract{
    address sourceAddress;
    address destinationAddress;
    address owner;
    ArbitrumInbox messenger;
    uint256 maxGas = 3000000;
    uint256 gasPriceBid = 10;
    bytes4 sourceSelector = bytes4(0x81b24111);
    OVMLayer1Messenger ovmMessenger;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function updateDestinationAddress(address destAddress) public onlyOwner{
        destinationAddress = destAddress;
    }
    function updateSourceAddress(address SourceAddress) public onlyOwner{
        sourceAddress = SourceAddress;
    }

    function updateInboxAddress(address inboxAddress) public onlyOwner{
        messenger = ArbitrumInbox(inboxAddress);
    }
    function updateOVMMessengerAddress(address ovmAddress) public onlyOwner{
        ovmMessenger = OVMLayer1Messenger(ovmAddress);
    }
    function updateSourceSelector(bytes4 selector) public onlyOwner{
        sourceSelector = selector;
    }

    modifier fromDestinationContract(){
        require(
            msg.sender == address(ovmMessenger)
            && ovmMessenger.xDomainMessageSender() == destinationAddress
        );
        _;
    }

    function passData(bytes32[] memory rewardHashList) public fromDestinationContract {
      
        bytes memory data = abi.encodeWithSelector(
            sourceSelector,
            rewardHashList
        );
        messenger.sendContractTransaction(
            maxGas,
            gasPriceBid,
            sourceAddress,
            0,
            data
        );
    }

}