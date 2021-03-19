/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// File: contracts\farming\util\DFOHub.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IDoubleProxy {
    function proxy() external view returns (address);
}

interface IMVDProxy {
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns (address);
    function getStateHolderAddress() external view returns(address);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
}

interface IMVDFunctionalitiesManager {
    function getFunctionalityData(string calldata codeName) external view returns(address, uint256, string memory, address, uint256);
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: contracts\farming\dfo\DFOBasedFarmExtensionFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;


contract DFOBasedFarmExtensionFactory {

    address public doubleProxy;

    address public model;

    event ExtensionCloned(address indexed extensionAddress, address indexed sender);

    constructor(address doubleProxyAddress, address modelAddress) {
        doubleProxy = doubleProxyAddress;
        model = modelAddress;
    }

    function setDoubleProxy(address doubleProxyAddress) public onlyDFO {
        doubleProxy = doubleProxyAddress;
    }

    function setModel(address modelAddress) public onlyDFO {
        model = modelAddress;
    }

    function cloneModel() public returns(address clonedExtension) {
        emit ExtensionCloned(clonedExtension = _clone(model), msg.sender);
    }

    function _clone(address original) private returns (address copy) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(original, 0x1000000000000000000)
                )
            )
            copy := create(0, 0, 32)
            switch extcodesize(copy)
                case 0 {
                    invalid()
                }
        }
    }

    modifier onlyDFO() {
        require(IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized.");
        _;
    }
}