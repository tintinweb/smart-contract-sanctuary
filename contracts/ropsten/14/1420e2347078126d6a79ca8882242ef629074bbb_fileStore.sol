/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

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
        string key;
        string value;
    }
    
    string[] public allFiles;
    mapping (string => Items) public userFiles;
    /*
     * init
    */
    constructor() public {

    }

    /*Add file*/
    function keyvalue(string memory key, string memory value) public onlyOwner {
        userFiles[key].value = value;
        userFiles[key].value = value;
    }

}