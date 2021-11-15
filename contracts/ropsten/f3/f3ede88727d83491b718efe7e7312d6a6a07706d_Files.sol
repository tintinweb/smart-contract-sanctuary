//SPDX-License-Identifier: Unlicense
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

contract Files {

    struct Metadata {
		bytes8 separator;
        bytes32 fileNumber;
		bytes32 title;
		bytes32 album;
		bytes32 website;
		bytes32[2] ipfsHash;
		bytes32 comment;
		bytes32 copyright;
        bytes8 submissionDate;
		bytes8 blockchainDate;
        bytes32 mdHash;
    }

    uint256 public size;

    mapping(uint256 => Metadata) filesMetadata;


    constructor() {
        size = 0;
    }

    function addFile(string[] memory _metadata) public returns (uint256){


        filesMetadata[size].separator = dataConvert8(_metadata[0]);
        filesMetadata[size].fileNumber = dataConvert(_metadata[1]);
        filesMetadata[size].title = dataConvert(_metadata[2]);
        filesMetadata[size].album = dataConvert(_metadata[3]);
        filesMetadata[size].website = dataConvert(_metadata[4]);
        filesMetadata[size].comment = dataConvert(_metadata[6]);
        filesMetadata[size].copyright = dataConvert(_metadata[7]);
        filesMetadata[size].submissionDate = dataConvert8(_metadata[8]);
        filesMetadata[size].mdHash = dataConvert(_metadata[9]);

        (filesMetadata[size].ipfsHash[0], filesMetadata[size].ipfsHash[1]) = splitIpfsHash(bytes(_metadata[5]));



        (uint year, uint month, uint day) = timestampToDate(block.timestamp);
        filesMetadata[size].blockchainDate  = dataConvert8(concat( convertVaalue(day),  ".",  convertVaalue(month), ".", convertVaalue(year) ));



        size = size + 1;

        return size;

    }

    ////////////////////////////////////////////////////////////////////

    function splitIpfsHash(bytes memory _ipfsHash) private pure returns (bytes32 _part1, bytes32 _part2){
        require(_ipfsHash.length>=32);
        bytes memory _temp1 = new bytes(32);
        for(uint i=0;i<32;i++){
            _temp1[i] = _ipfsHash[i];
        }
        assembly {
            _part1 := mload(add(_temp1, 32))
        }
        bytes memory _temp2 = new bytes(32);
        for(uint i=32;i<_ipfsHash.length;i++){
            _temp2[i-32] = _ipfsHash[i];
        }
        assembly {
            _part2 := mload(add(_temp2, 32))
        }
    }



    ///////////////////////////////////////////////////////////////////


	function concat(string memory a, string memory b) private pure returns (string memory) {
		return string(abi.encodePacked(a, b));
	}

    
	function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / (24 * 60 * 60));
    }


    function convertVaalue(uint _value) internal pure returns (string memory value) {
        if( _value <10) {
            value = concat("0", uint2str(_value));
        } else {
            value = uint2str(_value);
        }
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + 2440588;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
        _year = _year % 100;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

	function concat(string memory a, string memory b, string memory c, string memory d, string memory e) private pure returns (string memory) {
		return string(abi.encodePacked(a, b, c, d, e));
    }



    function dataConvert(string memory _str) private pure returns (bytes32 _value){
        bytes memory _temp = bytes(_str);
        require(_temp.length<=32);
        bytes memory __temp = new bytes(32);
        for(uint i=0;i<_temp.length;i++){
            __temp[i] = _temp[i];
        }
        assembly {
            _value := mload(add(__temp, 32))
        }
    }

    function dataConvert8(string memory _str) private pure returns (bytes8 _value){
        bytes memory _temp = bytes(_str);
        require(_temp.length<=8);
        bytes memory __temp = new bytes(8);
        for(uint i=0;i<_temp.length;i++){
            __temp[i] = _temp[i];
        }
        assembly {
            _value := mload(add(__temp, 32))
        }
    }



    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}

