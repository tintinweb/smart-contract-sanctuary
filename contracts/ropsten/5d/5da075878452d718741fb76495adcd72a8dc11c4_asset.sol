/**
 * Copyright (C) 2017-2018 Hashfuture Inc. All rights reserved.
 */

pragma solidity ^0.4.22;

contract owned {
    address public holder;

    constructor() public {
        holder = msg.sender;
    }

    modifier onlyHolder {
        require(msg.sender == holder, "This function can be called by holder only");
        _;
    }
}

contract asset is owned {

    //Asset Struct
    struct data {
        //link URL of the original information for storing data
        //     null means undisclosed
        string link;
        //The hash type of the original data, such as SHA-256
        string hashType;
        //Hash value
        string hashValue;
    }

    data public assetFile;
    data public legalFile;

    /**
     * The price of asset
     * if the contract is valid and tradeable,
     * others can get asset by transfer assetPrice ETH to contract
     */
    uint public assetPrice;

    //The price which creator plege
    uint public pledgePrice;

    //The contract start time
    string public startTime;

    //The contract expiration time
    string public endTime;

    //The token id
    uint id;

    /**
     * signatures
     * Used to verify that if the contract is protected by hashworld and other organizations
     */
    mapping(address => string) public signatures;

    //The validity of the contract
    bool public isValid;

    //The tradeable status of asset
    bool public isTradeable;

    //Some notes
    string public remark1;

    /**
     * Other notes, holder can be written
     * Reservations for validation functions
     */
    string public remark2;


    /**
     * The asset update events
     */
    event TokenUpdateEvent (
        string assetFileLink,
        string legalFileLink,
        address holder,
        uint assetPrice,
        bool isValid,
        bool isTradeable
    );


    /**
     * constructor
     * @param _assetFileUrl The url of asset file
     * @param _assetFileHashType The hash type of asset file
     * @param _assetFileHashValue The hash value of asset file
     * @param _legalFileUrl The url of legal file
     * @param _legalFileHashType The hash type of legal file
     * @param _legalFileHashValue The hash value of legal file
     * @param _pledgePrice The price which creator plege
     * @param _assetPrice The price of asset
     * @param _startTime The contract start time
     * @param _endTime The contract expiration time
     * @param _id Token id
     * @param _holder initial holder
     */
    constructor(
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue,
        uint _pledgePrice,
        uint _assetPrice,
        string _startTime,
        string _endTime,
        uint _id,
        address _holder
        ) public {
        isValid = true;
        isTradeable = false;
        assetPrice = 0;
        pledgePrice = _pledgePrice;
        assetPrice = _assetPrice;
        startTime = _startTime;
        endTime = _endTime;
        id = _id;
        holder = _holder;
        initAssetFile(_assetFileUrl, _assetFileHashType, _assetFileHashValue, _legalFileUrl, _legalFileHashType, _legalFileHashValue);
    }

    /**
     * Initialize asset file and legal file
     * @param _assetFileUrl The url of asset file
     * @param _assetFileHashType The hash type of asset file
     * @param _assetFileHashValue The hash value of asset file
     * @param _legalFileUrl The url of legal file
     * @param _legalFileHashType The hash type of legal file
     * @param _legalFileHashValue The hash value of legal file
     */
    function initAssetFile(
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue
        ) internal {
        assetFile = data(_assetFileUrl, _assetFileHashType, _assetFileHashValue);
        legalFile = data(_legalFileUrl, _legalFileHashType, _legalFileHashValue);
    }

     /**
     * Get base asset info
     */
    function getAssetBaseInfo() public view returns (uint _assetPrice,
                                                uint _pledgePrice,
                                                 bool _isTradeable,
                                                 string _startTime,
                                                 string _endTime,
                                                 uint _id,
                                                 string _remark1,
                                                 string _remark2) {
        require(isValid == true, "contract is invaild");
        _assetPrice = assetPrice;
        _pledgePrice = pledgePrice;
        _isTradeable = isTradeable;
        _startTime = startTime;
        _endTime = endTime;
        _id = id;
        _remark1 = remark1;
        _remark2 = remark2;
    }

    /**
     * set the price of asset
     * @param newAssetPrice new price of asset
     * Only can be called by holder
     */
    function setassetPrice(uint newAssetPrice) public onlyHolder {
        require(isValid == true, "contract is invaild");
        assetPrice = newAssetPrice;
        emit TokenUpdateEvent (
            assetFile.link,
            legalFile.link,
            holder,
            assetPrice,
            isValid,
            isTradeable
        );
    }

    /**
     * set the tradeable status of asset
     * @param status status of isTradeable
     * Only can be called by holder
     */
    function setTradeable(bool status) public onlyHolder {
        require(isValid == true, "contract is invaild");
        isTradeable = status;
        emit TokenUpdateEvent (
            assetFile.link,
            legalFile.link,
            holder,
            assetPrice,
            isValid,
            isTradeable
        );
    }

    /**
     * set the remark1
     * @param content new content of remark1
     * Only can be called by holder
     */
    function setRemark1(string content) public onlyHolder {
        require(isValid == true, "contract is invaild");
        remark1 = content;
    }

    /**
     * set the remark2
     * @param content new content of remark2
     * Only can be called by holder
     */
    function setRemark2(string content) public onlyHolder {
        require(isValid == true, "contract is invaild");
        remark2 = content;
    }

    /**
     * Modify the link of the asset file
     * @param url new link
     * Only can be called by holder
     */
    function setAssetFileLink(string url) public onlyHolder {
        require(isValid == true, "contract is invaild");
        assetFile.link = url;
        emit TokenUpdateEvent (
            assetFile.link,
            legalFile.link,
            holder,
            assetPrice,
            isValid,
            isTradeable
        );
    }

    /**
     * Modify the link of the legal file
     * @param url new link
     * Only can be called by holder
     */
    function setLegalFileLink(string url) public onlyHolder {
        require(isValid == true, "contract is invaild");
        legalFile.link = url;
        emit TokenUpdateEvent (
            assetFile.link,
            legalFile.link,
            holder,
            assetPrice,
            isValid,
            isTradeable
        );
    }

    /**
     * cancel contract
     * Only can be called by holder
     */
    function cancelContract() public onlyHolder {
        isValid = false;
        emit TokenUpdateEvent (
            assetFile.link,
            legalFile.link,
            holder,
            assetPrice,
            isValid,
            isTradeable
        );
    }

    /**
     * sign Token
     */
    function sign(string signature) public {
        signatures[msg.sender] = signature;
    }

    /**
     * get signature by address
     */
    function getSignature(address from) public view returns (string signature){
        signature = signatures[from];
    }

    /**
     * Transfer holder
     * @param newHolder new holder
     * @param tradeableStatus tradeable status after transfer holder
     */
    function transferOwnership(address newHolder, bool tradeableStatus) public onlyHolder {
        holder = newHolder;
        isTradeable = tradeableStatus;
        emit TokenUpdateEvent (
            assetFile.link,
            legalFile.link,
            holder,
            assetPrice,
            isValid,
            isTradeable
        );
    }

    /**
     * Transfer holder
     * @param newHolder new holder
     * @param status tradeable status after transfer holder
     */
    function _transferHolder(address newHolder, bool status, uint _assetPrice) internal {
        holder = newHolder;
        isTradeable = status;
        emit TokenUpdateEvent (
            assetFile.link,
            legalFile.link,
            holder,
            assetPrice,
            isValid,
            isTradeable
        );
    }

    /**
     * Buy asset
     */
    function buy(bool status) public payable {
        require(isTradeable == true, "contract is tradeable");
        require(isValid == true, "contract is invaild");
        require(msg.value >= assetPrice, "assetPrice not match");
        holder.transfer(assetPrice);
        _transferHolder(msg.sender, status, msg.value);
    }
}