// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../../../Core/OlaPlatform/Factories/PeripheryMinistryFactory.sol";

interface ISingleAssetDynamicRainMakeDeployer {
    function deploy(address comptroller, address admin) external returns (address);
}

interface IWhitelistBouncerDeployer {
    function deploy(address comptroller, address admin) external returns (address);
}

contract PeripheralFactory is IPeripheryMinistryFactory {

//    bytes32 constant public SingleAssetRainMakerContractHash = keccak256("SingleAssetRainMaker");
    bytes32 constant public SingleAssetDynamicRainMakerContractHash = keccak256("SingleAssetDynamicRainMaker");
    bytes32 constant public WhiteListBouncerContractHash = keccak256("WhiteListBouncer");


    ISingleAssetDynamicRainMakeDeployer singleAssetDynamicRainMakerDeployer;
    IWhitelistBouncerDeployer whitelistBouncerDeployer;

    constructor(address _ministry, address _singleAssetDynamicRainMakerDeployer, address _whitelistBouncerDeployer) BaseMinistryFactory(_ministry) {
        singleAssetDynamicRainMakerDeployer = ISingleAssetDynamicRainMakeDeployer(_singleAssetDynamicRainMakerDeployer);
        whitelistBouncerDeployer = IWhitelistBouncerDeployer(_whitelistBouncerDeployer);
    }

    function deployPeripheryContract(bytes32 contractNameHash, address _comptroller, address _admin, bytes calldata params) external override returns (address) {
        require(isSupportedContract(contractNameHash), "Unsupported contract name hash");

        if (contractNameHash == SingleAssetDynamicRainMakerContractHash) {
            return singleAssetDynamicRainMakerDeployer.deploy(_comptroller, _admin);
        } else if (contractNameHash == WhiteListBouncerContractHash) {
            return whitelistBouncerDeployer.deploy(_comptroller, _admin);
        }

        // This is here as a safety mechanism that will fail when given a bad address
        require(1==2, "Emergency safety");
        return address(0);
    }

    function isSupportedContract(bytes32 contractNameHash) public pure returns (bool) {
        return (contractNameHash == SingleAssetDynamicRainMakerContractHash || contractNameHash == WhiteListBouncerContractHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./BaseMinistryFactory.sol";

abstract contract IPeripheryMinistryFactory is BaseMinistryFactory {
    function deployPeripheryContract(bytes32 contractNameHash, address _comptroller, address _admin, bytes calldata params) external virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @title Ola Base Ministry Factory
/// @notice Manages access to factory to only allow calls from the Ministry.
contract BaseMinistryFactory {
    address public ministry;

    constructor(address _ministry) {
        ministry = _ministry;
    }

    function isFromMinistry() internal view returns (bool) {
        return msg.sender == ministry;
    }
}