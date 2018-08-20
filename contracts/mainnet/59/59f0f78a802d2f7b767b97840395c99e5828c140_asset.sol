/**
 * Copyright (C) 2017-2018 Hashfuture Inc. All rights reserved.
 */

pragma solidity ^0.4.22;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice&#39;s text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }
    
    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    
    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }
    
    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }
    
    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }
    
}

contract owned {
    address public holder;

    constructor() public {
        holder = msg.sender;
    }

    modifier onlyHolder {
        require(msg.sender == holder, "This func only can be calle by holder");
        _;
    }
}

contract asset is owned {
    using strings for *;
    /*Asset Struct*/
    struct data {
        //link URL of the original information for storing data
        //     null means undisclosed
        string link;
        //The encryption method of the original data, such as SHA-256
        string encryptionType;
        //Hash value
        string hashValue;
    }

    data[] dataArray;
    uint dataNum;

    //The validity of the contract
    bool public isValid;
    
    //The init status
    bool public isInit;
    
    //The tradeable status of asset
    bool public isTradeable;
    uint public price;

    //Some notes
    string public remark1;

    //Other notes, holder can be written
    //Reservations for validation functions
    string public remark2;

    /** constructor */
    constructor() public {
        isValid = true;
        isInit = false;
        isTradeable = false;
        price = 0;
        dataNum = 0;
    }

    /**
     * Initialize a new asset
     * @param dataNumber The number of data array
     * @param linkSet The set of URL of the original information for storing data, if null means undisclosed
     *          needle is " "
     * @param encryptionTypeSet The set of encryption method of the original data, such as SHA-256
     *          needle is " "
     * @param hashValueSet The set of hashvalue
     *          needle is " "
     */
    function initAsset(
        uint dataNumber,
        string linkSet,
        string encryptionTypeSet,
        string hashValueSet) public onlyHolder {
        // split string to array
        var links = linkSet.toSlice();
        var encryptionTypes = encryptionTypeSet.toSlice();
        var hashValues = hashValueSet.toSlice();
        var delim = " ".toSlice();
        
        dataNum = dataNumber;
        
        // after init, the initAsset function cannot be called
        require(isInit == false, "The contract has been initialized");

        //check data
        require(dataNumber >= 1, "The dataNumber should bigger than 1");
        require(dataNumber - 1 == links.count(delim), "The uumber of linkSet error");
        require(dataNumber - 1 == encryptionTypes.count(delim), "The uumber of encryptionTypeSet error");
        require(dataNumber - 1 == hashValues.count(delim), "The uumber of hashValues error");
        
        isInit = true;
        
        var empty = "".toSlice();
        
        for (uint i = 0; i < dataNumber; i++) {
            var link = links.split(delim);
            var encryptionType = encryptionTypes.split(delim);
            var hashValue = hashValues.split(delim);
            
            //require data not null
            // link can be empty
            require(!encryptionType.empty(), "The encryptionTypeSet data error");
            require(!hashValue.empty(), "The hashValues data error");
            
            dataArray.push(
                data(link.toString(), encryptionType.toString(), hashValue.toString())
                );
        }
    }
    
     /**
     * Get base asset info
     */
    function getAssetBaseInfo() public view returns (uint _price,
                                                 bool _isTradeable,
                                                 uint _dataNum,
                                                 string _remark1,
                                                 string _remark2) {
        require(isValid == true, "contract is invaild");
        _price = price;
        _isTradeable = isTradeable;
        _dataNum = dataNum;
        _remark1 = remark1;
        _remark2 = remark2;
    }
    
    /**
     * Get data info by index
     * @param index index of dataArray
     */
    function getDataByIndex(uint index) public view returns (string link, string encryptionType, string hashValue) {
        require(isValid == true, "contract is invaild");
        require(index >= 0, "The idx smaller than 0");
        require(index < dataNum, "The idx bigger than dataNum");
        link = dataArray[index].link;
        encryptionType = dataArray[index].encryptionType;
        hashValue = dataArray[index].hashValue;
    }

    /**
     * set the price of asset
     * @param newPrice price of asset
     * Only can be called by holder
     */
    function setPrice(uint newPrice) public onlyHolder {
        require(isValid == true, "contract is invaild");
        price = newPrice;
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
     * Modify the link of the indexth data to be url
     * @param index index of assetInfo
     * @param url new link
     * Only can be called by holder
     */
    function setDataLink(uint index, string url) public onlyHolder {
        require(isValid == true, "contract is invaild");
        require(index >= 0, "The index smaller than 0");
        require(index < dataNum, "The index bigger than dataNum");
        dataArray[index].link = url;
    }

    /**
     * cancel contract
     * Only can be called by holder
     */
    function cancelContract() public onlyHolder {
        isValid = false;
    }
    
    /**
     * Get the number of assetInfo
     */
    function getDataNum() public view returns (uint num) {
        num = dataNum;
    }

    /**
     * Transfer holder
     */
    function transferOwnership(address newHolder, bool status) public onlyHolder {
        holder = newHolder;
        isTradeable = status;
    }
}