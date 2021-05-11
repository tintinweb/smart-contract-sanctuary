/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File: contracts/WeightCalculator08.sol

pragma solidity ^0.8.0;


contract WeightCalculator is Initializable{
string [] labels;
string ipfsHash;

function initialize (string [] memory _labels) external initializer {
        labels = _labels;
    }
    
    
function mapWeights(uint [] memory values) external view returns (string memory){
    
    string  memory inital = "";
     
    
    for (uint i=0; i<values.length; i++) {
       inital = append(inital,labels[i], ":" ,values[i], ";");
     
}
return inital;
    
}

function setLabels(string [] memory _labels) external  {
      labels = _labels ;
  }
  
function getLabels() external view returns (string [] memory){
    return labels;
}

function append(string memory inital, string memory lab, string memory sep, uint256  value, string memory end) internal pure returns (string memory) {
    
    return string(abi.encodePacked(inital,lab, sep, uint2str(value), end));

}

   function getIpfsHash() external view returns (string memory){
       return ipfsHash;
   }
   
  function setIpfsHash(string memory _hash ) public  {
      ipfsHash = _hash ;
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