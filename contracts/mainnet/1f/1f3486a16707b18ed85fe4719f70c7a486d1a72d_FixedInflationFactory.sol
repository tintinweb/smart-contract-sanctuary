/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: contracts\fixed-inflation\util\DFOHub.sol

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

// File: contracts\fixed-inflation\IFixedInflationFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface IFixedInflationFactory {

    function fixedInflationDefaultExtension() external view returns (address);

    function feePercentageInfo() external view returns (uint256, address);
}

// File: contracts\fixed-inflation\FixedInflationFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;



contract FixedInflationFactory is IFixedInflationFactory {

    // fixed inflation contract implementation address
    address public fixedInflationImplementationAddress;

    // fixed inflation default extension
    address public override fixedInflationDefaultExtension;

    // double proxy address of the linked DFO
    address public _doubleProxy;

    // linked DFO exit fee
    uint256 private _feePercentage;

    // event that tracks fixed inflation contracts deployed
    event FixedInflationDeployed(address indexed fixedInflationAddress, address indexed sender, bytes fixedInflationInitResultData);

    // event that tracks logic contract address change
    event FixedInflationLogicSet(address indexed newAddress);

    // event that tracks default extension contract address change
    event FixedInflationDefaultExtensionSet(address indexed newAddress);

    // event that tracks wallet changes
    event FeePercentageSet(uint256 newFeePercentage);

    constructor(address doubleProxy, address _fixedInflationImplementationAddress, address _fixedInflationDefaultExtension, uint256 feePercentage) {
        _doubleProxy = doubleProxy;
        emit FixedInflationLogicSet(fixedInflationImplementationAddress = _fixedInflationImplementationAddress);
        emit FixedInflationDefaultExtensionSet(fixedInflationDefaultExtension = _fixedInflationDefaultExtension);
        emit FeePercentageSet(_feePercentage = feePercentage);
    }

    /** PUBLIC METHODS */

    function feePercentageInfo() public override view returns (uint256, address) {
        return (_feePercentage, IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDWalletAddress());
    }

    /** @dev allows the DFO to update the double proxy address.
      * @param newDoubleProxy new double proxy address.
    */
    function setDoubleProxy(address newDoubleProxy) public onlyDFO {
        _doubleProxy = newDoubleProxy;
    }

    /** @dev change the fee percentage
     * @param feePercentage new fee percentage.
     */
    function updateFeePercentage(uint256 feePercentage) public onlyDFO {
        emit FeePercentageSet(_feePercentage = feePercentage);
    }

    /** @dev allows the factory owner to update the logic contract address.
     * @param _fixedInflationImplementationAddress new fixed inflation implementation address.
     */
    function updateLogicAddress(address _fixedInflationImplementationAddress) public onlyDFO {
        emit FixedInflationLogicSet(fixedInflationImplementationAddress = _fixedInflationImplementationAddress);
    }

    /** @dev allows the factory owner to update the extension contract address.
     * @param _fixedInflationDefaultExtension new fixed inflation extension address.
     */
    function updateDefaultExtensionAddress(address _fixedInflationDefaultExtension) public onlyDFO {
        emit FixedInflationDefaultExtensionSet(fixedInflationDefaultExtension = _fixedInflationDefaultExtension);
    }

    /** @dev this function deploys a new FixedInflation contract and calls the encoded function passed as data.
     * @param data encoded initialize function for the fixed inflation contract (check FixedInflation contract code).
     * @return contractAddress new fixed inflation contract address.
     * @return initResultData new fixed inflation contract call result.
     */
    function deploy(bytes memory data) public returns (address contractAddress, bytes memory initResultData) {
        initResultData = _call(contractAddress = _clone(fixedInflationImplementationAddress), data);
        emit FixedInflationDeployed(contractAddress, msg.sender, initResultData);
    }

    /** PRIVATE METHODS */

    /** @dev clones the input contract address and returns the copied contract address.
     * @param original address of the original contract.
     * @return copy copied contract address.
     */
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

    function _call(address location, bytes memory payload) private returns(bytes memory returnData) {
        assembly {
            let result := call(gas(), location, 0, add(payload, 0x20), mload(payload), 0, 0)
            let size := returndatasize()
            returnData := mload(0x40)
            mstore(returnData, size)
            let returnDataPayloadStart := add(returnData, 0x20)
            returndatacopy(returnDataPayloadStart, 0, size)
            mstore(0x40, add(returnDataPayloadStart, size))
            switch result case 0 {revert(returnDataPayloadStart, size)}
        }
    }

    /** @dev onlyDFO modifier used to check for unauthorized accesses. */
    modifier onlyDFO() {
        require(IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized.");
        _;
    }
}