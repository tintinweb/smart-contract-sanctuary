// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../FuseFeeDistributor.sol";

/**
 * @title FuseFeeDistributorArbitrum
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice FuseFeeDistributorArbitrum controls and receives protocol fees from Fuse pools and relays admin actions to Fuse pools on Arbitrum.
 */
contract FuseFeeDistributorArbitrum is FuseFeeDistributor {
    /**
     * @dev Deploys a `CEtherDelegator`.
     * @param constructorData `CEtherDelegator` ABI-encoded constructor data.
     */
    function deployCEther(bytes calldata constructorData) external override returns (address) {
        // ABI decode constructor data
        (address comptroller, , , , address implementation, , , ) = abi.decode(constructorData, (address, address, string, string, address, bytes, uint256, uint256));

        // Check implementation whitelist
        require(cEtherDelegateWhitelist[address(0)][implementation][false], "CEtherDelegate contract not whitelisted.");

        // Make sure comptroller == msg.sender
        require(comptroller == msg.sender, "Comptroller is not sender.");

        // Deploy Unitroller using msg.sender, underlying, and block.number as a salt
        bytes memory cEtherDelegatorCreationCode = hex"608060405234801561001057600080fd5b50604051610785380380610785833981810160405261010081101561003457600080fd5b8151602083015160408085018051915193959294830192918464010000000082111561005f57600080fd5b90830190602082018581111561007457600080fd5b825164010000000081118282018810171561008e57600080fd5b82525081516020918201929091019080838360005b838110156100bb5781810151838201526020016100a3565b50505050905090810190601f1680156100e85780820380516001836020036101000a031916815260200191505b506040526020018051604051939291908464010000000082111561010b57600080fd5b90830190602082018581111561012057600080fd5b825164010000000081118282018810171561013a57600080fd5b82525081516020918201929091019080838360005b8381101561016757818101518382015260200161014f565b50505050905090810190601f1680156101945780820380516001836020036101000a031916815260200191505b506040818152602083015192018051929491939192846401000000008211156101bc57600080fd5b9083019060208201858111156101d157600080fd5b82516401000000008111828201881017156101eb57600080fd5b82525081516020918201929091019080838360005b83811015610218578181015183820152602001610200565b50505050905090810190601f1680156102455780820380516001836020036101000a031916815260200191505b5060405260200180519060200190929190805190602001909291905050506103ba8489898989878760405160240180876001600160a01b03166001600160a01b03168152602001866001600160a01b03166001600160a01b031681526020018060200180602001858152602001848152602001838103835287818151815260200191508051906020019080838360005b838110156102ed5781810151838201526020016102d5565b50505050905090810190601f16801561031a5780820380516001836020036101000a031916815260200191505b50838103825286518152865160209182019188019080838360005b8381101561034d578181015183820152602001610335565b50505050905090810190601f16801561037a5780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b03908116631e70b25560e21b1790915290995061049c16975050505050505050565b5061048e848560008660405160240180846001600160a01b03166001600160a01b031681526020018315151515815260200180602001828103825283818151815260200191508051906020019080838360005b8381101561042557818101518382015260200161040d565b50505050905090810190601f1680156104525780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b039081166350d85b7360e01b1790915290955061049c169350505050565b50505050505050505061055e565b606060006060846001600160a01b0316846040518082805190602001908083835b602083106104dc5780518252601f1990920191602091820191016104bd565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d806000811461053c576040519150601f19603f3d011682016040523d82523d6000602084013e610541565b606091505b50915091506000821415610556573d60208201fd5b949350505050565b6102188061056d6000396000f3fe60806040526004361061001e5760003560e01c80635c60da1b146100e1575b6000546040805160048152602481019091526020810180516001600160e01b031663076de25160e21b17905261005d916001600160a01b031690610112565b50600080546040516001600160a01b0390911690829036908083838082843760405192019450600093509091505080830381855af49150503d80600081146100c1576040519150601f19603f3d011682016040523d82523d6000602084013e6100c6565b606091505b505090506040513d6000823e8180156100dd573d82f35b3d82fd5b3480156100ed57600080fd5b506100f66101d4565b604080516001600160a01b039092168252519081900360200190f35b606060006060846001600160a01b0316846040518082805190602001908083835b602083106101525780518252601f199092019160209182019101610133565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d80600081146101b2576040519150601f19603f3d011682016040523d82523d6000602084013e6101b7565b606091505b509150915060008214156101cc573d60208201fd5b949350505050565b6000546001600160a01b03168156fea265627a7a7231582080d36dfc16f2b75d4da188aa983cd8c9d6d990a3dfadcda4c9afa32284ba80dc64736f6c63430005110032";
        cEtherDelegatorCreationCode = abi.encodePacked(cEtherDelegatorCreationCode, constructorData);
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, address(0), block.number));
        address proxy;

        assembly {
            proxy := create2(0, add(cEtherDelegatorCreationCode, 32), mload(cEtherDelegatorCreationCode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, "Failed to deploy CEther.")
            }
        }

        return proxy;
    }

    /**
     * @dev Deploys a `CErc20Delegator`.
     * @param constructorData `CErc20Delegator` ABI-encoded constructor data.
     */
    function deployCErc20(bytes calldata constructorData) external override returns (address) {
        // ABI decode constructor data
        (address underlying, address comptroller, , , , address implementation, , , ) = abi.decode(constructorData, (address, address, address, string, string, address, bytes, uint256, uint256));

        // Check implementation whitelist
        require(cErc20DelegateWhitelist[address(0)][implementation][false], "CErc20Delegate contract not whitelisted.");

        // Make sure comptroller == msg.sender
        require(comptroller == msg.sender, "Comptroller is not sender.");

        // Deploy CErc20Delegator using msg.sender, underlying, and block.number as a salt
        bytes memory cErc20DelegatorCreationCode = hex"608060405234801561001057600080fd5b506040516107f53803806107f5833981810160405261012081101561003457600080fd5b81516020830151604080850151606086018051925194969395919493918201928464010000000082111561006757600080fd5b90830190602082018581111561007c57600080fd5b825164010000000081118282018810171561009657600080fd5b82525081516020918201929091019080838360005b838110156100c35781810151838201526020016100ab565b50505050905090810190601f1680156100f05780820380516001836020036101000a031916815260200191505b506040526020018051604051939291908464010000000082111561011357600080fd5b90830190602082018581111561012857600080fd5b825164010000000081118282018810171561014257600080fd5b82525081516020918201929091019080838360005b8381101561016f578181015183820152602001610157565b50505050905090810190601f16801561019c5780820380516001836020036101000a031916815260200191505b506040818152602083015192018051929491939192846401000000008211156101c457600080fd5b9083019060208201858111156101d957600080fd5b82516401000000008111828201881017156101f357600080fd5b82525081516020918201929091019080838360005b83811015610220578181015183820152602001610208565b50505050905090810190601f16801561024d5780820380516001836020036101000a031916815260200191505b50604081815260208381015193909101516001600160a01b03808e1660248501908152818e166044860152908c16606485015260c4840185905260e4840182905260e0608485019081528b516101048601528b519597509195506103b59489948f948f948f948f948f948d948d949260a4830192610124019189019080838360005b838110156102e75781810151838201526020016102cf565b50505050905090810190601f1680156103145780820380516001836020036101000a031916815260200191505b50838103825286518152865160209182019188019080838360005b8381101561034757818101518382015260200161032f565b50505050905090810190601f1680156103745780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b0390811663a0b0d28960e01b17909152909a506104981698505050505050505050565b50610489848560008660405160240180846001600160a01b03166001600160a01b031681526020018315151515815260200180602001828103825283818151815260200191508051906020019080838360005b83811015610420578181015183820152602001610408565b50505050905090810190601f16801561044d5780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b039081166350d85b7360e01b17909152909550610498169350505050565b5050505050505050505061055a565b606060006060846001600160a01b0316846040518082805190602001908083835b602083106104d85780518252601f1990920191602091820191016104b9565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d8060008114610538576040519150601f19603f3d011682016040523d82523d6000602084013e61053d565b606091505b50915091506000821415610552573d60208201fd5b949350505050565b61028c806105696000396000f3fe60806040526004361061001e5760003560e01c80635c60da1b1461011e575b341561005b5760405162461bcd60e51b81526004018080602001828103825260378152602001806102216037913960400191505060405180910390fd5b6000546040805160048152602481019091526020810180516001600160e01b031663076de25160e21b17905261009a916001600160a01b03169061014f565b50600080546040516001600160a01b0390911690829036908083838082843760405192019450600093509091505080830381855af49150503d80600081146100fe576040519150601f19603f3d011682016040523d82523d6000602084013e610103565b606091505b505090506040513d6000823e81801561011a573d82f35b3d82fd5b34801561012a57600080fd5b50610133610211565b604080516001600160a01b039092168252519081900360200190f35b606060006060846001600160a01b0316846040518082805190602001908083835b6020831061018f5780518252601f199092019160209182019101610170565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d80600081146101ef576040519150601f19603f3d011682016040523d82523d6000602084013e6101f4565b606091505b50915091506000821415610209573d60208201fd5b949350505050565b6000546001600160a01b03168156fe43457263323044656c656761746f723a66616c6c6261636b3a2063616e6e6f742073656e642076616c756520746f2066616c6c6261636ba265627a7a72315820fc5fcc16235ee4edd9b1c0ecaf05a926cd9474cdf4a7678b9c4f511421cf2ac364736f6c63430005110032";
        cErc20DelegatorCreationCode = abi.encodePacked(cErc20DelegatorCreationCode, constructorData);
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, underlying, block.number));
        address proxy;

        assembly {
            proxy := create2(0, add(cErc20DelegatorCreationCode, 32), mload(cErc20DelegatorCreationCode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, "Failed to deploy CErc20.")
            }
        }

        return proxy;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

/**
 * @title FuseFeeDistributor
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice FuseFeeDistributor controls and receives protocol fees from Fuse pools and relays admin actions to Fuse pools.
 */
contract FuseFeeDistributor is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Initializer that sets initial values of state variables.
     * @param _defaultInterestFeeRate The default proportion of Fuse pool interest taken as a protocol fee (scaled by 1e18).
     */
    function initialize(uint256 _defaultInterestFeeRate) public initializer {
        require(_defaultInterestFeeRate <= 1e18, "Interest fee rate cannot be more than 100%.");
        __Ownable_init();
        defaultInterestFeeRate = _defaultInterestFeeRate;
        maxSupplyEth = uint256(-1);
        maxUtilizationRate = uint256(-1);
    }

    /**
     * @notice The proportion of Fuse pool interest taken as a protocol fee (scaled by 1e18).
     */
    uint256 public defaultInterestFeeRate;

    /**
     * @dev Sets the default proportion of Fuse pool interest taken as a protocol fee.
     * @param _defaultInterestFeeRate The default proportion of Fuse pool interest taken as a protocol fee (scaled by 1e18).
     */
    function _setDefaultInterestFeeRate(uint256 _defaultInterestFeeRate) external onlyOwner {
        require(_defaultInterestFeeRate <= 1e18, "Interest fee rate cannot be more than 100%.");
        defaultInterestFeeRate = _defaultInterestFeeRate;
    }

    /**
     * @dev Withdraws accrued fees on interest.
     * @param erc20Contract The ERC20 token address to withdraw. Set to the zero address to withdraw ETH.
     */
    function _withdrawAssets(address erc20Contract) external {
        if (erc20Contract == address(0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No balance available to withdraw.");
            (bool success, ) = owner().call{value: balance}("");
            require(success, "Failed to transfer ETH balance to msg.sender.");
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(erc20Contract);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "No token balance available to withdraw.");
            token.safeTransfer(owner(), balance);
        }
    }

    /**
     * @dev Minimum borrow balance (in ETH) per user per Fuse pool asset (only checked on new borrows, not redemptions).
     */
    uint256 public minBorrowEth;

    /**
     * @dev Maximum supply balance (in ETH) per user per Fuse pool asset.
     * No longer used as of `Rari-Capital/compound-protocol` version `fuse-v1.1.0`.
     */
    uint256 public maxSupplyEth;

    /**
     * @dev Maximum utilization rate (scaled by 1e18) for Fuse pool assets (only checked on new borrows, not redemptions).
     * No longer used as of `Rari-Capital/compound-protocol` version `fuse-v1.1.0`.
     */
    uint256 public maxUtilizationRate;

    /**
     * @dev Sets the proportion of Fuse pool interest taken as a protocol fee.
     * @param _minBorrowEth Minimum borrow balance (in ETH) per user per Fuse pool asset (only checked on new borrows, not redemptions).
     * @param _maxSupplyEth Maximum supply balance (in ETH) per user per Fuse pool asset.
     * @param _maxUtilizationRate Maximum utilization rate (scaled by 1e18) for Fuse pool assets (only checked on new borrows, not redemptions).
     */
    function _setPoolLimits(uint256 _minBorrowEth, uint256 _maxSupplyEth, uint256 _maxUtilizationRate) external onlyOwner {
        minBorrowEth = _minBorrowEth;
        maxSupplyEth = _maxSupplyEth;
        maxUtilizationRate = _maxUtilizationRate;
    }

    /**
     * @dev Receives ETH fees.
     */
    receive() external payable { }

    /**
     * @dev Sends data to a contract.
     * @param targets The contracts to which `data` will be sent.
     * @param data The data to be sent to each of `targets`.
     */
    function _callPool(address[] calldata targets, bytes[] calldata data) external onlyOwner {
        require(targets.length > 0 && targets.length == data.length, "Array lengths must be equal and greater than 0.");
        for (uint256 i = 0; i < targets.length; i++) targets[i].functionCall(data[i]);
    }

    /**
     * @dev Sends data to a contract.
     * @param targets The contracts to which `data` will be sent.
     * @param data The data to be sent to each of `targets`.
     */
    function _callPool(address[] calldata targets, bytes calldata data) external onlyOwner {
        require(targets.length > 0, "No target addresses specified.");
        for (uint256 i = 0; i < targets.length; i++) targets[i].functionCall(data);
    }

    /**
     * @dev Deploys a `CEtherDelegator`.
     * @param constructorData `CEtherDelegator` ABI-encoded constructor data.
     */
    function deployCEther(bytes calldata constructorData) external virtual returns (address) {
        // ABI decode constructor data
        (address comptroller, , , , address implementation, , , ) = abi.decode(constructorData, (address, address, string, string, address, bytes, uint256, uint256));

        // Check implementation whitelist
        require(cEtherDelegateWhitelist[address(0)][implementation][false], "CEtherDelegate contract not whitelisted.");

        // Make sure comptroller == msg.sender
        require(comptroller == msg.sender, "Comptroller is not sender.");

        // Deploy Unitroller using msg.sender, underlying, and block.number as a salt
        bytes memory cEtherDelegatorCreationCode = hex"608060405234801561001057600080fd5b50604051610785380380610785833981810160405261010081101561003457600080fd5b8151602083015160408085018051915193959294830192918464010000000082111561005f57600080fd5b90830190602082018581111561007457600080fd5b825164010000000081118282018810171561008e57600080fd5b82525081516020918201929091019080838360005b838110156100bb5781810151838201526020016100a3565b50505050905090810190601f1680156100e85780820380516001836020036101000a031916815260200191505b506040526020018051604051939291908464010000000082111561010b57600080fd5b90830190602082018581111561012057600080fd5b825164010000000081118282018810171561013a57600080fd5b82525081516020918201929091019080838360005b8381101561016757818101518382015260200161014f565b50505050905090810190601f1680156101945780820380516001836020036101000a031916815260200191505b506040818152602083015192018051929491939192846401000000008211156101bc57600080fd5b9083019060208201858111156101d157600080fd5b82516401000000008111828201881017156101eb57600080fd5b82525081516020918201929091019080838360005b83811015610218578181015183820152602001610200565b50505050905090810190601f1680156102455780820380516001836020036101000a031916815260200191505b5060405260200180519060200190929190805190602001909291905050506103ba8489898989878760405160240180876001600160a01b03166001600160a01b03168152602001866001600160a01b03166001600160a01b031681526020018060200180602001858152602001848152602001838103835287818151815260200191508051906020019080838360005b838110156102ed5781810151838201526020016102d5565b50505050905090810190601f16801561031a5780820380516001836020036101000a031916815260200191505b50838103825286518152865160209182019188019080838360005b8381101561034d578181015183820152602001610335565b50505050905090810190601f16801561037a5780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b03908116631e70b25560e21b1790915290995061049c16975050505050505050565b5061048e848560008660405160240180846001600160a01b03166001600160a01b031681526020018315151515815260200180602001828103825283818151815260200191508051906020019080838360005b8381101561042557818101518382015260200161040d565b50505050905090810190601f1680156104525780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b039081166350d85b7360e01b1790915290955061049c169350505050565b50505050505050505061055e565b606060006060846001600160a01b0316846040518082805190602001908083835b602083106104dc5780518252601f1990920191602091820191016104bd565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d806000811461053c576040519150601f19603f3d011682016040523d82523d6000602084013e610541565b606091505b50915091506000821415610556573d60208201fd5b949350505050565b6102188061056d6000396000f3fe60806040526004361061001e5760003560e01c80635c60da1b146100e1575b6000546040805160048152602481019091526020810180516001600160e01b031663076de25160e21b17905261005d916001600160a01b031690610112565b50600080546040516001600160a01b0390911690829036908083838082843760405192019450600093509091505080830381855af49150503d80600081146100c1576040519150601f19603f3d011682016040523d82523d6000602084013e6100c6565b606091505b505090506040513d6000823e8180156100dd573d82f35b3d82fd5b3480156100ed57600080fd5b506100f66101d4565b604080516001600160a01b039092168252519081900360200190f35b606060006060846001600160a01b0316846040518082805190602001908083835b602083106101525780518252601f199092019160209182019101610133565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d80600081146101b2576040519150601f19603f3d011682016040523d82523d6000602084013e6101b7565b606091505b509150915060008214156101cc573d60208201fd5b949350505050565b6000546001600160a01b03168156fea265627a7a723158208e3e63485e5f7ae8cba3fa394e12885c029940469c7a173b8ff7745fabdad3b364736f6c63430005110032";
        cEtherDelegatorCreationCode = abi.encodePacked(cEtherDelegatorCreationCode, constructorData);
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, address(0), block.number));
        address proxy;

        assembly {
            proxy := create2(0, add(cEtherDelegatorCreationCode, 32), mload(cEtherDelegatorCreationCode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, "Failed to deploy CEther.")
            }
        }

        return proxy;
    }

    /**
     * @dev Deploys a `CErc20Delegator`.
     * @param constructorData `CErc20Delegator` ABI-encoded constructor data.
     */
    function deployCErc20(bytes calldata constructorData) external virtual returns (address) {
        // ABI decode constructor data
        (address underlying, address comptroller, , , , address implementation, , , ) = abi.decode(constructorData, (address, address, address, string, string, address, bytes, uint256, uint256));

        // Check implementation whitelist
        require(cErc20DelegateWhitelist[address(0)][implementation][false], "CErc20Delegate contract not whitelisted.");

        // Make sure comptroller == msg.sender
        require(comptroller == msg.sender, "Comptroller is not sender.");

        // Deploy CErc20Delegator using msg.sender, underlying, and block.number as a salt
        bytes memory cErc20DelegatorCreationCode = hex"608060405234801561001057600080fd5b506040516107f53803806107f5833981810160405261012081101561003457600080fd5b81516020830151604080850151606086018051925194969395919493918201928464010000000082111561006757600080fd5b90830190602082018581111561007c57600080fd5b825164010000000081118282018810171561009657600080fd5b82525081516020918201929091019080838360005b838110156100c35781810151838201526020016100ab565b50505050905090810190601f1680156100f05780820380516001836020036101000a031916815260200191505b506040526020018051604051939291908464010000000082111561011357600080fd5b90830190602082018581111561012857600080fd5b825164010000000081118282018810171561014257600080fd5b82525081516020918201929091019080838360005b8381101561016f578181015183820152602001610157565b50505050905090810190601f16801561019c5780820380516001836020036101000a031916815260200191505b506040818152602083015192018051929491939192846401000000008211156101c457600080fd5b9083019060208201858111156101d957600080fd5b82516401000000008111828201881017156101f357600080fd5b82525081516020918201929091019080838360005b83811015610220578181015183820152602001610208565b50505050905090810190601f16801561024d5780820380516001836020036101000a031916815260200191505b50604081815260208381015193909101516001600160a01b03808e1660248501908152818e166044860152908c16606485015260c4840185905260e4840182905260e0608485019081528b516101048601528b519597509195506103b59489948f948f948f948f948f948d948d949260a4830192610124019189019080838360005b838110156102e75781810151838201526020016102cf565b50505050905090810190601f1680156103145780820380516001836020036101000a031916815260200191505b50838103825286518152865160209182019188019080838360005b8381101561034757818101518382015260200161032f565b50505050905090810190601f1680156103745780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b0390811663a0b0d28960e01b17909152909a506104981698505050505050505050565b50610489848560008660405160240180846001600160a01b03166001600160a01b031681526020018315151515815260200180602001828103825283818151815260200191508051906020019080838360005b83811015610420578181015183820152602001610408565b50505050905090810190601f16801561044d5780820380516001836020036101000a031916815260200191505b5060408051601f198184030181529190526020810180516001600160e01b039081166350d85b7360e01b17909152909550610498169350505050565b5050505050505050505061055a565b606060006060846001600160a01b0316846040518082805190602001908083835b602083106104d85780518252601f1990920191602091820191016104b9565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d8060008114610538576040519150601f19603f3d011682016040523d82523d6000602084013e61053d565b606091505b50915091506000821415610552573d60208201fd5b949350505050565b61028c806105696000396000f3fe60806040526004361061001e5760003560e01c80635c60da1b1461011e575b341561005b5760405162461bcd60e51b81526004018080602001828103825260378152602001806102216037913960400191505060405180910390fd5b6000546040805160048152602481019091526020810180516001600160e01b031663076de25160e21b17905261009a916001600160a01b03169061014f565b50600080546040516001600160a01b0390911690829036908083838082843760405192019450600093509091505080830381855af49150503d80600081146100fe576040519150601f19603f3d011682016040523d82523d6000602084013e610103565b606091505b505090506040513d6000823e81801561011a573d82f35b3d82fd5b34801561012a57600080fd5b50610133610211565b604080516001600160a01b039092168252519081900360200190f35b606060006060846001600160a01b0316846040518082805190602001908083835b6020831061018f5780518252601f199092019160209182019101610170565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d80600081146101ef576040519150601f19603f3d011682016040523d82523d6000602084013e6101f4565b606091505b50915091506000821415610209573d60208201fd5b949350505050565b6000546001600160a01b03168156fe43457263323044656c656761746f723a66616c6c6261636b3a2063616e6e6f742073656e642076616c756520746f2066616c6c6261636ba265627a7a7231582005c7822f7294a2303680b0d2b051bee472cd65b928fd92bacf345e29e5b26c9f64736f6c63430005110032";
        cErc20DelegatorCreationCode = abi.encodePacked(cErc20DelegatorCreationCode, constructorData);
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, underlying, block.number));
        address proxy;

        assembly {
            proxy := create2(0, add(cErc20DelegatorCreationCode, 32), mload(cErc20DelegatorCreationCode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, "Failed to deploy CErc20.")
            }
        }

        return proxy;
    }

    /**
     * @dev Whitelisted Comptroller implementation contract addresses for each existing implementation.
     */
    mapping(address => mapping(address => bool)) public comptrollerImplementationWhitelist;

    /**
     * @dev Adds/removes Comptroller implementations to the whitelist.
     * @param oldImplementations The old `Comptroller` implementation addresses to upgrade from for each `newImplementations` to upgrade to.
     * @param newImplementations Array of `Comptroller` implementations to be whitelisted/unwhitelisted.
     * @param statuses Array of whitelist statuses corresponding to `implementations`.
     */
    function _editComptrollerImplementationWhitelist(address[] calldata oldImplementations, address[] calldata newImplementations, bool[] calldata statuses) external onlyOwner {
        require(newImplementations.length > 0 && newImplementations.length == oldImplementations.length && newImplementations.length == statuses.length, "No Comptroller implementations supplied or array lengths not equal.");
        for (uint256 i = 0; i < newImplementations.length; i++) comptrollerImplementationWhitelist[oldImplementations[i]][newImplementations[i]] = statuses[i];
    }

    /**
     * @dev Whitelisted CErc20Delegate implementation contract addresses and `allowResign` values for each existing implementation.
     */
    mapping(address => mapping(address => mapping(bool => bool))) public cErc20DelegateWhitelist;

    /**
     * @dev Adds/removes CErc20Delegate implementations to the whitelist.
     * @param oldImplementations The old `CErc20Delegate` implementation addresses to upgrade from for each `newImplementations` to upgrade to.
     * @param newImplementations Array of `CErc20Delegate` implementations to be whitelisted/unwhitelisted.
     * @param allowResign Array of `allowResign` values corresponding to `newImplementations` to be whitelisted/unwhitelisted.
     * @param statuses Array of whitelist statuses corresponding to `newImplementations`.
     */
    function _editCErc20DelegateWhitelist(address[] calldata oldImplementations, address[] calldata newImplementations, bool[] calldata allowResign, bool[] calldata statuses) external onlyOwner {
        require(newImplementations.length > 0 && newImplementations.length == oldImplementations.length && newImplementations.length == allowResign.length && newImplementations.length == statuses.length, "No CErc20Delegate implementations supplied or array lengths not equal.");
        for (uint256 i = 0; i < newImplementations.length; i++) cErc20DelegateWhitelist[oldImplementations[i]][newImplementations[i]][allowResign[i]] = statuses[i];
    }

    /**
     * @dev Whitelisted CEtherDelegate implementation contract addresses and `allowResign` values for each existing implementation.
     */
    mapping(address => mapping(address => mapping(bool => bool))) public cEtherDelegateWhitelist;

    /**
     * @dev Adds/removes CEtherDelegate implementations to the whitelist.
     * @param oldImplementations The old `CEtherDelegate` implementation addresses to upgrade from for each `newImplementations` to upgrade to.
     * @param newImplementations Array of `CEtherDelegate` implementations to be whitelisted/unwhitelisted.
     * @param allowResign Array of `allowResign` values corresponding to `newImplementations` to be whitelisted/unwhitelisted.
     * @param statuses Array of whitelist statuses corresponding to `newImplementations`.
     */
    function _editCEtherDelegateWhitelist(address[] calldata oldImplementations, address[] calldata newImplementations, bool[] calldata allowResign, bool[] calldata statuses) external onlyOwner {
        require(newImplementations.length > 0 && newImplementations.length == oldImplementations.length && newImplementations.length == allowResign.length && newImplementations.length == statuses.length, "No CEtherDelegate implementations supplied or array lengths not equal.");
        for (uint256 i = 0; i < newImplementations.length; i++) cEtherDelegateWhitelist[oldImplementations[i]][newImplementations[i]][allowResign[i]] = statuses[i];
    }

    /**
     * @dev Latest Comptroller implementation for each existing implementation.
     */
    mapping(address => address) internal _latestComptrollerImplementation;

    /**
     * @dev Latest Comptroller implementation for each existing implementation.
     */
    function latestComptrollerImplementation(address oldImplementation) external view returns (address) {
        return _latestComptrollerImplementation[oldImplementation] != address(0) ? _latestComptrollerImplementation[oldImplementation] : oldImplementation;
    }

    /**
     * @dev Sets the latest `Comptroller` upgrade implementation address.
     * @param oldImplementation The old `Comptroller` implementation address to upgrade from.
     * @param newImplementation Latest `Comptroller` implementation address.
     */
    function _setLatestComptrollerImplementation(address oldImplementation, address newImplementation) external onlyOwner {
        _latestComptrollerImplementation[oldImplementation] = newImplementation;
    }

    struct CDelegateUpgradeData {
        address implementation;
        bool allowResign;
        bytes becomeImplementationData;
    }

    /**
     * @dev Latest CErc20Delegate implementation for each existing implementation.
     */
    mapping(address => CDelegateUpgradeData) public _latestCErc20Delegate;

    /**
     * @dev Latest CEtherDelegate implementation for each existing implementation.
     */
    mapping(address => CDelegateUpgradeData) public _latestCEtherDelegate;

    /**
     * @dev Latest CErc20Delegate implementation for each existing implementation.
     */
    function latestCErc20Delegate(address oldImplementation) external view returns (address, bool, bytes memory) {
        CDelegateUpgradeData memory data = _latestCErc20Delegate[oldImplementation];
        bytes memory emptyBytes;
        return data.implementation != address(0) ? (data.implementation, data.allowResign, data.becomeImplementationData) : (oldImplementation, false, emptyBytes);
    }

    /**
     * @dev Latest CEtherDelegate implementation for each existing implementation.
     */
    function latestCEtherDelegate(address oldImplementation) external view returns (address, bool, bytes memory) {
        CDelegateUpgradeData memory data = _latestCEtherDelegate[oldImplementation];
        bytes memory emptyBytes;
        return data.implementation != address(0) ? (data.implementation, data.allowResign, data.becomeImplementationData) : (oldImplementation, false, emptyBytes);
    }

    /**
     * @dev Sets the latest `CEtherDelegate` upgrade implementation address and data.
     * @param oldImplementation The old `CEtherDelegate` implementation address to upgrade from.
     * @param newImplementation Latest `CEtherDelegate` implementation address.
     * @param allowResign Whether or not `resignImplementation` should be called on the old implementation before upgrade.
     * @param becomeImplementationData Data passed to the new implementation via `becomeImplementation` after upgrade.
     */
    function _setLatestCEtherDelegate(address oldImplementation, address newImplementation, bool allowResign, bytes calldata becomeImplementationData) external onlyOwner {
        _latestCEtherDelegate[oldImplementation] = CDelegateUpgradeData(newImplementation, allowResign, becomeImplementationData);
    }

    /**
     * @dev Sets the latest `CErc20Delegate` upgrade implementation address and data.
     * @param oldImplementation The old `CErc20Delegate` implementation address to upgrade from.
     * @param newImplementation Latest `CErc20Delegate` implementation address.
     * @param allowResign Whether or not `resignImplementation` should be called on the old implementation before upgrade.
     * @param becomeImplementationData Data passed to the new implementation via `becomeImplementation` after upgrade.
     */
    function _setLatestCErc20Delegate(address oldImplementation, address newImplementation, bool allowResign, bytes calldata becomeImplementationData) external onlyOwner {
        _latestCErc20Delegate[oldImplementation] = CDelegateUpgradeData(newImplementation, allowResign, becomeImplementationData);
    }

    /**
     * @notice Maps Unitroller (Comptroller proxy) addresses to the proportion of Fuse pool interest taken as a protocol fee (scaled by 1e18).
     * @dev A value of 0 means unset whereas a negative value means 0.
     */
    mapping(address => int256) public customInterestFeeRates;

    /**
     * @notice Returns the proportion of Fuse pool interest taken as a protocol fee (scaled by 1e18).
     */
    function interestFeeRate() external view returns (uint256) {
        (bool success, bytes memory data) = msg.sender.staticcall(abi.encodeWithSignature("comptroller()"));

        if (success && data.length == 32) {
            (address comptroller) = abi.decode(data, (address));
            int256 customRate = customInterestFeeRates[comptroller];
            if (customRate > 0) return uint256(customRate);
            if (customRate < 0) return 0;
        }

        return defaultInterestFeeRate;
    }

    /**
     * @dev Sets the proportion of Fuse pool interest taken as a protocol fee.
     * @param comptroller The Unitroller (Comptroller proxy) address.
     * @param rate The proportion of Fuse pool interest taken as a protocol fee (scaled by 1e18).
     */
    function _setCustomInterestFeeRate(address comptroller, int256 rate) external onlyOwner {
        require(rate <= 1e18, "Interest fee rate cannot be more than 100%.");
        customInterestFeeRates[comptroller] = rate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}