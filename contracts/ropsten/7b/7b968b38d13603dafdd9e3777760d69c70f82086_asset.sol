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

    /*
    * Asset Struct
    */
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

    //The holder transfer event
    //_from the holder before transfer
    //_to the holder after transfer
    //assetPrice the price of asset
    //transferType the type of holder transfer. 0 means transfer ownership actively and 1 means others buy the asset
    event holderTransfer (
        address _from,
        address _to,
        uint assetPrice,
        uint transferType
    );

    //The validity of the contract
    bool public isValid;
    
    //The tradeable status of asset
    bool public isTradeable;
    
    /* The price of asset
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
    
    //Some notes
    string public remark1;

    //Other notes, holder can be written
    //Reservations for validation functions
    string public remark2;
    
    //signature
    //Used to verify that if the contract is protected by hashworld
    string public signature;

    /*
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
     * @param _signature Signature by hashowrld
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
        string _signature
        ) public {
        isValid = true;
        isTradeable = false;
        assetPrice = 0;
        pledgePrice = _pledgePrice;
        assetPrice = _assetPrice;
        startTime = _startTime;
        endTime = _endTime;
        signature = _signature;
        initAssetFile(_assetFileUrl, _assetFileHashType, _assetFileHashValue, _legalFileUrl, _legalFileHashType, _legalFileHashValue);
    }

    /*
     * Initialize asset file
     * @param assetFileUrl The url of asset file
     * @param assetFileHashType The hash type of asset file
     * @param assetFileHashValue The hash value of asset file
     * @param legalFileUrl The url of legal file
     * @param legalFileHashType The hash type of legal file
     * @param legalFileHashValue The hash value of legal file
     */
    function initAssetFile(
        string assetFileUrl,
        string assetFileHashType,
        string assetFileHashValue,
        string legalFileUrl,
        string legalFileHashType,
        string legalFileHashValue
        ) internal onlyHolder {
        assetFile = data(assetFileUrl, assetFileHashType, assetFileHashValue);
        legalFile = data(legalFileUrl, legalFileHashType, legalFileHashValue);
    }
    
     /**
     * Get base asset info
     */
    function getAssetBaseInfo() public view returns (uint _assetPrice,
                                                uint _pledgePrice,
                                                 bool _isTradeable,
                                                 string _startTime,
                                                 string _endTime,
                                                 string _signature,
                                                 string _remark1,
                                                 string _remark2) {
        require(isValid == true, "contract is invaild");
        _assetPrice = assetPrice;
        _pledgePrice = pledgePrice;
        _isTradeable = isTradeable;
        _startTime = startTime;
        _endTime = endTime;
        _signature = signature;
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
    }

    /**
     * set the tradeable status of asset
     * @param status status of isTradeable
     * Only can be called by holder
     */
    function setTradeable(bool status) public onlyHolder {
        require(isValid == true, "contract is invaild");
        isTradeable = status;
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
    }
    
    /**
     * Modify the link of the legal file
     * @param url new link
     * Only can be called by holder
     */
    function setLegalFileLink(string url) public onlyHolder {
        require(isValid == true, "contract is invaild");
        legalFile.link = url;
    }

    /**
     * cancel contract
     * Only can be called by holder
     */
    function cancelContract() public onlyHolder {
        isValid = false;
    }

    /**
     * Transfer holder
     * @param newHolder new holder
     * @param status tradeable status after transfer holder
     */
    function transferOwnership(address newHolder, bool status) public onlyHolder {
        emit holderTransfer(holder, newHolder, 0, 0);
        holder = newHolder;
        isTradeable = status;
    }

    /**
     * Transfer holder
     * @param newHolder new holder
     * @param status tradeable status after transfer holder
     */
    function _transferHolder(address newHolder, bool status, uint _assetPrice) internal {
        emit holderTransfer(holder, newHolder, _assetPrice, 1);
        holder = newHolder;
        isTradeable = status;
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