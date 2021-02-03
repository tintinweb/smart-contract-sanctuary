/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: contracts\liquidity-mining\util\DFOHub.sol

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

// File: contracts\liquidity-mining\ILiquidityMiningFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface ILiquidityMiningFactory {

    event ExtensionCloned(address indexed);

    function feePercentageInfo() external view returns (uint256, address);
    function liquidityMiningDefaultExtension() external view returns(address);
    function cloneLiquidityMiningDefaultExtension() external returns(address);
    function getLiquidityFarmTokenCollectionURI() external view returns (string memory);
    function getLiquidityFarmTokenURI() external view returns (string memory);
}

// File: contracts\liquidity-mining\LiquidityMiningFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;



contract LiquidityMiningFactory is ILiquidityMiningFactory {

    // liquidity mining contract implementation address
    address public liquidityMiningImplementationAddress;
    // liquidity mining default extension
    address public override liquidityMiningDefaultExtension;
    // double proxy address of the linked DFO
    address public _doubleProxy;
    // linked DFO exit fee
    uint256 private _feePercentage;
    // liquidity mining collection uri
    string public liquidityFarmTokenCollectionURI;
    // liquidity mining farm token uri
    string public liquidityFarmTokenURI;
    // event that tracks liquidity mining contracts deployed
    event LiquidityMiningDeployed(address indexed liquidityMiningAddress, address indexed sender, bytes liquidityMiningInitResultData);
    // event that tracks logic contract address change
    event LiquidityMiningLogicSet(address indexed newAddress);
    // event that tracks default extension contract address change
    event LiquidityMiningDefaultExtensionSet(address indexed newAddress);
    // event that tracks wallet changes
    event FeePercentageSet(uint256 newFeePercentage);

    constructor(address doubleProxy, address _liquidityMiningImplementationAddress, address _liquidityMiningDefaultExtension, uint256 feePercentage, string memory liquidityFarmTokenCollectionUri, string memory liquidityFarmTokenUri) {
        _doubleProxy = doubleProxy;
        liquidityFarmTokenCollectionURI = liquidityFarmTokenCollectionUri;
        liquidityFarmTokenURI = liquidityFarmTokenUri;
        emit LiquidityMiningLogicSet(liquidityMiningImplementationAddress = _liquidityMiningImplementationAddress);
        emit LiquidityMiningDefaultExtensionSet(liquidityMiningDefaultExtension = _liquidityMiningDefaultExtension);
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
     * @param _liquidityMiningImplementationAddress new liquidity mining implementation address.
     */
    function updateLogicAddress(address _liquidityMiningImplementationAddress) public onlyDFO {
        emit LiquidityMiningLogicSet(liquidityMiningImplementationAddress = _liquidityMiningImplementationAddress);
    }

    /** @dev allows the factory owner to update the default extension contract address.
     * @param _liquidityMiningDefaultExtensionAddress new liquidity mining extension address.
     */
    function updateDefaultExtensionAddress(address _liquidityMiningDefaultExtensionAddress) public onlyDFO {
        emit LiquidityMiningDefaultExtensionSet(liquidityMiningDefaultExtension = _liquidityMiningDefaultExtensionAddress);
    }

    /** @dev allows the factory owner to update the liquidity farm token collection uri.
     * @param liquidityFarmTokenCollectionUri new liquidity farm token collection uri.
     */
    function updateLiquidityFarmTokenCollectionURI(string memory liquidityFarmTokenCollectionUri) public onlyDFO {
        liquidityFarmTokenCollectionURI = liquidityFarmTokenCollectionUri;
    }

    /** @dev allows the factory owner to update the liquidity farm token collection uri.
     * @param liquidityFarmTokenUri new liquidity farm token collection uri.
     */
    function updateLiquidityFarmTokenURI(string memory liquidityFarmTokenUri) public onlyDFO {
        liquidityFarmTokenURI = liquidityFarmTokenUri;
    }

    /** @dev returns the liquidity farm token collection uri.
      * @return liquidity farm token collection uri.
     */
    function getLiquidityFarmTokenCollectionURI() public override view returns (string memory) {
        return liquidityFarmTokenCollectionURI;
    }

    /** @dev returns the liquidity farm token uri.
      * @return liquidity farm token uri.
     */
    function getLiquidityFarmTokenURI() public override view returns (string memory) {
        return liquidityFarmTokenURI;
    }

    /** @dev utlity method to clone default extension
     * @return clonedExtension the address of the actually-cloned liquidity mining extension
     */
    function cloneLiquidityMiningDefaultExtension() public override returns(address clonedExtension) {
        emit ExtensionCloned(clonedExtension = _clone(liquidityMiningDefaultExtension));
    }

    /** @dev this function deploys a new LiquidityMining contract and calls the encoded function passed as data.
     * @param data encoded initialize function for the liquidity mining contract (check LiquidityMining contract code).
     * @return contractAddress new liquidity mining contract address.
     * @return initResultData new liquidity mining contract call result.
     */
    function deploy(bytes memory data) public returns (address contractAddress, bytes memory initResultData) {
        initResultData = _call(contractAddress = _clone(liquidityMiningImplementationAddress), data);
        emit LiquidityMiningDeployed(contractAddress, msg.sender, initResultData);
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