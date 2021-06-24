/**
 *Submitted for verification at Etherscan.io on 2021-06-23
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

// File: contracts\farming\IFarmFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface IFarmFactory {

    event ExtensionCloned(address indexed);

    function feePercentageInfo() external view returns (uint256, address);
    function farmDefaultExtension() external view returns(address);
    function cloneFarmDefaultExtension() external returns(address);
    function getFarmTokenCollectionURI() external view returns (string memory);
    function getFarmTokenURI() external view returns (string memory);
}

// File: contracts\farming\FarmFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;



contract FarmFactory is IFarmFactory {

    // farm contract implementation address
    address public farmMainImplAddress;
    // farming default extension
    address public override farmDefaultExtension;
    // double proxy address of the linked DFO
    address public _doubleProxy;
    // linked DFO exit fee
    uint256 private _feePercentage;
    // collection uri
    string public farmTokenCollectionURI;
    // farm token uri
    string public farmTokenURI;

    // event that tracks farm main contracts deployed
    event FarmMainDeployed(address indexed farmMainAddress, address indexed sender, bytes initResultData);
    // event that tracks logic contract address change
    event FarmMainLogicSet(address indexed newAddress);
    // event that tracks default extension contract address change
    event FarmDefaultExtensionSet(address indexed newAddress);
    // event that tracks wallet changes
    event FeePercentageSet(uint256 newFeePercentage);

    constructor(address doubleProxy, address _farmMainImplAddress, address _farmDefaultExtension, uint256 feePercentage, string memory farmTokenCollectionUri, string memory farmTokenUri) {
        _doubleProxy = doubleProxy;
        farmTokenCollectionURI = farmTokenCollectionUri;
        farmTokenURI = farmTokenUri;
        emit FarmMainLogicSet(farmMainImplAddress = _farmMainImplAddress);
        emit FarmDefaultExtensionSet(farmDefaultExtension = _farmDefaultExtension);
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
     * @param _implAddress new farm logic implementation address.
     */
    function updateLogicAddress(address _implAddress) public onlyDFO {
        emit FarmMainLogicSet(farmMainImplAddress = _implAddress);
    }

    /** @dev allows the factory owner to update the default extension contract address.
     * @param _farmDefaultExtensionAddress new farm extension address.
     */
    function updateDefaultExtensionAddress(address _farmDefaultExtensionAddress) public onlyDFO {
        emit FarmDefaultExtensionSet(farmDefaultExtension = _farmDefaultExtensionAddress);
    }

    /** @dev allows the factory owner to update the farm token collection uri.
     * @param farmTokenCollectionUri new farm token collection uri.
     */
    function updateFarmTokenCollectionURI(string memory farmTokenCollectionUri) public onlyDFO {
        farmTokenCollectionURI = farmTokenCollectionUri;
    }

    /** @dev allows the factory owner to update the farm token uri.
     * @param farmTokenUri new farm token collection uri.
     */
    function updateFarmTokenURI(string memory farmTokenUri) public onlyDFO {
        farmTokenURI = farmTokenUri;
    }

    /** @dev returns the farm token collection uri.
      * @return farm token collection uri.
     */
    function getFarmTokenCollectionURI() public override view returns (string memory) {
        return farmTokenCollectionURI;
    }

    /** @dev returns the farm token uri.
      * @return farm token uri.
     */
    function getFarmTokenURI() public override view returns (string memory) {
        return farmTokenURI;
    }

    /** @dev utlity method to clone default extension
     * @return clonedExtension the address of the actually-cloned farming extension
     */
    function cloneFarmDefaultExtension() public override returns(address clonedExtension) {
        emit ExtensionCloned(clonedExtension = _clone(farmDefaultExtension));
    }

    /** @dev this function deploys a new Farming contract and calls the encoded function passed as data.
     * @param data encoded initialize function for the farming contract (check Farming contract code).
     * @return contractAddress new farming contract address.
     * @return initResultData new farming contract call result.
     */
    function deploy(bytes memory data) public returns (address contractAddress, bytes memory initResultData) {
        initResultData = _call(contractAddress = _clone(farmMainImplAddress), data);
        emit FarmMainDeployed(contractAddress, msg.sender, initResultData);
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

    /** @dev calls the contract at the given location using the given payload and returns the returnData.
      * @param location location to call.
      * @param payload call payload.
      * @return returnData call return data.
     */
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