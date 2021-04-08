/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

contract AppCoinsTracker {

    ///////// STRUCTS /////////
    struct CampaignLaunchedInformation {
        bytes32 bidId;
        string packageName;
        string endPoint;
        uint[3] countries;
        uint price;
        uint budget;
        uint startDate;
        uint endDate;
    }

    struct BulkPoaInformation {
        bytes32 bidId;
        bytes rootHash;
        bytes signature;
        uint256 newHashes;
    }

    struct OffChainBuyInformation {
        address wallet;
        bytes32 rootHash;
    }
    ///////// END: STRUCTS /////////

    ///////// EVENTS /////////
    event CampaignLaunched(
        address owner,
        bytes32 bidId,
        string packageName,
        uint[3] countries,
        uint price,
        uint budget,
        uint startDate,
        uint endDate,
        string endPoint
    );

    event CampaignCancelled(
        address owner,
        bytes32 bidId
    );

    event BulkPoARegistered(
        address owner,
        bytes32 bidId,
        bytes rootHash,
        bytes signature,
        uint256 newHashes
    );

    event OffChainBuy(
        address _wallet,
        bytes32 _rootHash
    );
    ///////// END: EVENTS /////////

    /**
    @notice Emits events informing the launch of campaigns.
    @dev For each CampaignLaunchedInformation passed as argument is emited in
         a CampaignedLaunched event.
    @param _campaigns_launched_information List of CampaignLaunchedInformation
           containing the information of campaigns that have been lauched.
    */
    function createCampaigns (CampaignLaunchedInformation[] memory
                _campaigns_launched_information)public {
        for(uint i = 0; i < _campaigns_launched_information.length; i++){
            emit CampaignLaunched(
                msg.sender,
                _campaigns_launched_information[i].bidId,
                _campaigns_launched_information[i].packageName,
                _campaigns_launched_information[i].countries,
                _campaigns_launched_information[i].price,
                _campaigns_launched_information[i].budget,
                _campaigns_launched_information[i].startDate,
                _campaigns_launched_information[i].endDate,
                _campaigns_launched_information[i].endPoint
            );
        }
    }

    /**
    @notice Emits events informing the cancelation of campaigns.
    @dev For each bidId passed as argument is emited in a CampaignedCancel event.
    @param _bidIdList List of bidId of campaigns that have been cancelled.
    */
    function cancelCampaigns (bytes32[] memory _bidIdList) public {
        for(uint i = 0; i < _bidIdList.length; i++) {
            emit CampaignCancelled(msg.sender, _bidIdList[i]);
        }
    }

    /**
    @notice Emits events registering the root hash of the proof-of-attentions
            transactions of a multiple blockchain_events.
    @dev For each BulkPoaInformation passed as argument is emited in a
         BulkPoARegistered event.
    @param _bulks_poa_information List of BulkPoaInformation of campaigns that
                                  have PoA that haven't been registered.
    */
    function bulkRegisterPoaOfMultipleCampaigns
                (BulkPoaInformation[] memory _bulks_poa_information) public {
        for(uint i = 0; i < _bulks_poa_information.length; i++) {
            emit BulkPoARegistered(
                msg.sender,
                _bulks_poa_information[i].bidId,
                _bulks_poa_information[i].rootHash,
                _bulks_poa_information[i].signature,
                _bulks_poa_information[i].newHashes
            );
        }
    }

    /**
    @notice Emits events informing offchain transactions for in-app-billing
    @dev For each OffChainBuyInformation passed as argument is emited in a OffChainBuyInformation
         event.
    @param _off_chain_buys List of OffChainBuyInformation - wallets and rootHashes - for
                           which a OffChainBuyInformation event will be issued.
    */
    function informOffChainBuys(OffChainBuyInformation[] memory
                _off_chain_buys) public {
        for(uint i = 0; i < _off_chain_buys.length; i++){
            emit OffChainBuy(_off_chain_buys[i].wallet,
                             _off_chain_buys[i].rootHash);
        }
    }
}