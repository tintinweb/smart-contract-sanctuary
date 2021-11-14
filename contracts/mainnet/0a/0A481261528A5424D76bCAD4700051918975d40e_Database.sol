// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import {Tytanid} from "./Tytanid.sol";
import "./AggregatorV3Interface.sol";

contract Database is Tytanid {
    struct Contract {
        address contractAddress;
        address owner;
        Asset asset;
        Currency currency;
        uint24 participantsLong;
        uint24 participantsShort;
        uint32 biddingEndDate;
        uint32 maturityDate;
        uint strikePrice;
        uint longAmount;
        uint shortAmount;
        bool isMarketHasAnyBids;
        uint24 status;
    }

    mapping(uint48 => Contract) contracts;

    mapping(address => uint48) addressToContractId;

    struct Admin {
        bool isAdmin;
    }

    mapping(address => Admin) admins;

    struct TytanidWallet {
        address commissionAddress;
    }

    mapping(string => Asset) assets;
    string[] assetsIndices;

    mapping(string => Currency) currencies;
    string[] currenciesIndices;

    uint48 nextId = 1;

    Activity[] activities;

    address sourceContract;

    constructor(){
        admins[msg.sender].isAdmin = true;

        commissions.createMarketStake = 2;
        commissions.joinMarketStake = 1;
        commissions.exitMarketStake = 5;
        commissions.joinMarketTytanidRatio = 90;
        commissions.exitMarketTytanidRatio = 80;
    }

    function getSettings(
    ) public view returns (
        Asset[] memory,
        Currency[] memory,
        int[] memory,
        Commissions memory
    ){
        Asset[] memory assetsData = new Asset[](assetsIndices.length);
        Currency[] memory currenciesData = new Currency[](currenciesIndices.length);
        int[] memory currenciesPrices = new int[](currenciesIndices.length);
        AggregatorV3Interface currencyFeed;

        for (uint48 i = 0; i < assetsIndices.length; i++) {
            assetsData[i] = assets[assetsIndices[i]];
        }

        for (uint48 i = 0; i < currenciesIndices.length; i++) {
            currenciesData[i] = currencies[currenciesIndices[i]];
            currencyFeed = AggregatorV3Interface(currencies[currenciesIndices[i]].chainlinkAddress);
            (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
            ) = currencyFeed.latestRoundData();
            currenciesPrices[i] = price;
        }

        return (assetsData, currenciesData, currenciesPrices, getCommissions());
    }

    function getAssetsData(
    ) public view returns (
        int[] memory
    ){
        int[] memory assetsPrices = new int[](assetsIndices.length);
        AggregatorV3Interface assetFeed;

        for (uint48 i = 0; i < assetsIndices.length; i++) {
            assetFeed = AggregatorV3Interface(assets[assetsIndices[i]].chainlinkAddress);
            (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
            ) = assetFeed.latestRoundData();
            assetsPrices[i] = price;
        }

        return assetsPrices;
    }

    function getAssetsHistoryDay(
    ) public view returns (
        int[][] memory,
        uint[][] memory
    ){
        int[][] memory assetsHistory = new int[][](assetsIndices.length);
        uint[][] memory assetsTimestamps = new uint256[][](assetsIndices.length);
        int[200] memory assetHistory;
        uint[200] memory assetTimestamps;
        AggregatorV3Interface assetFeed;
        uint final_timestamp = 0;
        uint roundID;
        int price;
        uint startedAt;
        uint timeStamp;
        uint80 answeredInRound;
        uint currentAssetMax;

        for (uint48 i = 0; i < assetsIndices.length; i++) {
            currentAssetMax = 1;
            assetFeed = AggregatorV3Interface(assets[assetsIndices[i]].chainlinkAddress);
            (
            roundID,
            price,
            startedAt,
            timeStamp,
            answeredInRound
            ) = assetFeed.latestRoundData();
            assetHistory[0] = price;
            assetTimestamps[0] = timeStamp;

            final_timestamp = timeStamp-86400;

            for(uint48 j = 1; j < 200 && timeStamp>final_timestamp; j++){
                currentAssetMax++;
                assetFeed = AggregatorV3Interface(assets[assetsIndices[i]].chainlinkAddress);
                (
                roundID,
                price,
                startedAt,
                timeStamp,
                answeredInRound
                ) = assetFeed.getRoundData(uint80(roundID - j));
                assetHistory[j] = price;
                assetTimestamps[j] = timeStamp;
            }

            assetsHistory[i] = new int[](currentAssetMax);
            assetsTimestamps[i] = new uint[](currentAssetMax);
            for(uint48 j = 0; j < currentAssetMax; j++){
                assetsHistory[i][j] = assetHistory[j];
                assetsTimestamps[i][j] = assetTimestamps[j];
            }
        }

        return (assetsHistory, assetsTimestamps);
    }

    function getAll(
    ) public view returns (
        Contract[] memory
    ){
        Contract[] memory ret = new Contract[](nextId);
        for (uint48 i = 0; i < nextId; i++) {
            ret[i] = contracts[i];
        }
        return ret;
    }

    function getPage(
        uint48 _page
    ) public view returns (
        Contract[] memory
    ){
        Contract[] memory ret = new Contract[](1000);
        uint48 counter = 0;
        for (uint48 i = (_page * 1000); i < nextId && i < ((_page + 1) * 1000); i++) {
            ret[counter] = contracts[i];
            counter++;
        }
        return ret;
    }

    function getActivity(
    ) public view returns (
        Activity[] memory
    ){
        Activity[] memory ret = new Activity[](activities.length);
        for (uint48 i = 0; i < activities.length; i++) {
            ret[i] = activities[i];
        }
        return ret;
    }

    function getActivityPage(
        uint48 _page
    ) public view returns (
        Activity[] memory
    ){
        Activity[] memory ret = new Activity[](1000);
        for (uint48 i = (_page * 1000); i < activities.length && i < ((_page + 1) * 1000); i++) {
            ret[i-(_page * 1000)] = activities[i];
        }
        return ret;
    }

    function getLastActivity(
    ) public view returns (
        Activity[] memory
    ){
        Activity[] memory ret = new Activity[](1000);
        uint counter = 0;
        for (uint48 i = uint48(activities.length); i > 0; i--) {
            if(activities[i-1].activityTime < (uint32(block.timestamp) - 86400) || counter == 1000){
                break;
            }
            ret[counter] = activities[i-1];
            counter++;
        }
        return ret;
    }

    function getUserActivity(
        address _address
    ) public view returns (
        Activity[] memory
    ){
        Activity[] memory ret = new Activity[](1000);
        uint counter = 0;
        for (uint48 i = uint48(activities.length); i > 0; i--) {
            if(counter == 1000){
                break;
            }
            if(activities[i-1].bidderAddress == _address){
                ret[counter] = activities[i-1];
                counter++;
            }
        }
        return ret;
    }

    function getUserActivityPage(
        address _address,
        uint48 _page
    ) public view returns (
        Activity[] memory
    ){
        Activity[] memory ret = new Activity[](1000);
        uint counter = 0;
        uint index = 0;
        for (uint48 i = uint48(activities.length); i > 0; i--) {
            if(counter == ((_page+1) * 1000)){
                break;
            }
            if(activities[i-1].bidderAddress == _address){
                if(counter >= (_page * 1000)){
                    ret[index] = activities[i-1];
                    index++;
                }
                counter++;
            }
        }
        return ret;
    }

    function getCommissions(
    ) public view returns (
        Commissions memory
    ){
        return commissions;
    }

    function insertContract(
        address _owner,
        Asset memory _asset,
        Currency memory _currency,
        uint _strikePrice,
        uint32 _biddingEndDate,
        uint32 _maturityDate,
        uint _longAmount,
        uint _shortAmount
    ) public
    {
        contracts[nextId] = Contract({
        contractAddress : msg.sender,
        owner : _owner,
        asset : _asset,
        strikePrice : _strikePrice,
        currency : _currency,
        biddingEndDate : _biddingEndDate,
        maturityDate : _maturityDate,
        longAmount : _longAmount,
        shortAmount : _shortAmount,
        participantsLong : (_longAmount > 0 ? 1 : 0),
        participantsShort : (_shortAmount > 0 ? 1 : 0),
        isMarketHasAnyBids : true,
        status : 0
        });
        addressToContractId[msg.sender] = nextId;
        nextId++;

        if(_longAmount > 0){
            activities.push(
                Activity({
            bidderAddress : _owner,
            marketAddress : msg.sender,
            activityType : ActivityType.BID,
            side : Side.LONG,
            amount : _longAmount,
            activityTime : uint32(block.timestamp)
            })
            );
        }
        if(_shortAmount > 0){
            activities.push(
                Activity({
            bidderAddress : _owner,
            marketAddress : msg.sender,
            activityType : ActivityType.BID,
            side : Side.SHORT,
            amount : _shortAmount,
            activityTime : uint32(block.timestamp)
            })
            );
        }
    }

    function updateContract(
        uint _longAmount,
        uint _shortAmount,
        uint24 _participantsLong,
        uint24 _participantsShort,
        Activity memory _activity,
        bool _isMarketHasAnyBids
    ) public onlyTytanidContracts
    {
        uint48 id = addressToContractId[msg.sender];
        contracts[id].longAmount = _longAmount;
        contracts[id].shortAmount = _shortAmount;
        contracts[id].participantsLong = _participantsLong;
        contracts[id].participantsShort = _participantsShort;
        contracts[id].isMarketHasAnyBids = _isMarketHasAnyBids;

        activities.push(_activity);
    }

    function getAsset(
        string memory _assetName
    ) public view returns (
        Asset memory
    ){
        require(assets[_assetName].chainlinkAddress != 0x0000000000000000000000000000000000000000 && assets[_assetName].status == AssetStatus.ACTIVE, "Asset is not active!");
        return assets[_assetName];
    }

    function getCurrency(
        string memory _currencyName
    ) public view returns (
        Currency memory
    ){
        require(currencies[_currencyName].chainlinkAddress != 0x0000000000000000000000000000000000000000 && currencies[_currencyName].status == CurrencyStatus.ACTIVE, "Currency is not active!");
        return currencies[_currencyName];
    }

    function changeMarketStatus(
        address _address,
        uint24 _status
    ) public onlyAdmin
    {
        uint48 id = addressToContractId[_address];
        contracts[id].status = _status;
    }

    function upsertAsset(
        string memory _assetName,
        string memory _fullName,
        Category _category,
        string memory _referenceTo,
        address _chainLinkAddress,
        AssetStatus _status,
        uint8 _decimals,
        LogoType _logoType
    ) public onlyAdmin
    {
        bool isNew = assets[_assetName].chainlinkAddress == 0x0000000000000000000000000000000000000000;
        assets[_assetName] = Asset({
        name : _assetName,
        fullName: _fullName,
        category: _category,
        referenceTo : _referenceTo,
        chainlinkAddress : _chainLinkAddress,
        status : _status,
        decimals : _decimals,
        logoType : _logoType
        });
        if (isNew) {
            assetsIndices.push(_assetName);
        }
        delete isNew;
    }

    function upsertCurrency(
        string memory _currencyName,
        string memory _fullName,
        string memory _referenceTo,
        address _chainLinkAddress,
        CurrencyStatus _status,
        uint8 _decimals
    ) public onlyAdmin
    {
        bool isNew = currencies[_currencyName].chainlinkAddress == 0x0000000000000000000000000000000000000000;
        currencies[_currencyName] = Currency({
        name : _currencyName,
        fullName: _fullName,
        referenceTo : _referenceTo,
        chainlinkAddress : _chainLinkAddress,
        status : _status,
        decimals : _decimals
        });
        if (isNew) {
            currenciesIndices.push(_currencyName);
        }
        delete isNew;
    }

    function addAdmin(
        address _address
    ) public onlyAdmin
    {
        admins[_address].isAdmin = true;
    }

    function removeAdmin(
        address _address
    ) public onlyAdmin
    {
        if(_address != msg.sender){
            admins[_address].isAdmin = false;
        }
    }

    function setSourceContract(
        address _address
    ) public onlyAdmin
    {
        sourceContract = _address;
    }

    modifier onlyAdmin(
    ){
        require(isAdmin(msg.sender), "Permission denied");
        _;
    }

    function isAdmin(
        address _address
    ) private view returns (
        bool
    ){
        return admins[_address].isAdmin == true;
    }

    modifier onlyTytanidContracts(
    ){
        require(isTytanidContract(msg.sender), "Permission denied");
        _;
    }

    function isTytanidContract(
        address _address
    ) private view returns (
        bool
    ){
        return keccak256(sourceContract.code) == keccak256(_address.code);
    }
}