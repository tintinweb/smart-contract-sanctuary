/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
}

contract fileStore is owned {
    
    using SafeMath for uint256;

    /*
     * vars
    */
    struct Items {
        string dev_id;
        string ts;
        string seq_no;
        string sensor_data;
        string data_size;
        string dhash;
    }
    string[] public allFiles;
    mapping (string => Items) public userFiles;
    /*
     * init
    */
    constructor() public {}
    /*Add file*/
    function uploadCert(string memory _id, string memory _seq_no, string memory _ts, string memory _dev_id, string memory _sensor_data, string memory _data_size, string memory _dhash) public onlyOwner {
        userFiles[_id].dev_id = _dev_id;
        userFiles[_id].ts = _ts;
        userFiles[_id].seq_no = _seq_no;
        userFiles[_id].sensor_data = _sensor_data;
        userFiles[_id].data_size = _data_size;
        userFiles[_id].dhash = _dhash;
        allFiles.push(_id);
    }
    /*Transfer file*/
}