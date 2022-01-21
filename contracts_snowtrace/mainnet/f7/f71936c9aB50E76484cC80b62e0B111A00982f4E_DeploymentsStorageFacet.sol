// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(
        FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC173} from "../interfaces/IERC173.sol";

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

library LibDiamond {
    // Diamond Storage

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("bleakers.dead.bird");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;

        assembly
        {
            ds.slot := position
        }
    }

    // IERC173 (Diamond Ownership)

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner)
        internal
    {
        DiamondStorage storage ds = diamondStorage();

        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner()
        internal
        view
        returns (address contractOwner_)
    {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner()
        internal
        view
    {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    // Diamond Cut

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    )
        internal
    {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++)
        {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;

            if (action == IDiamondCut.FacetCutAction.Add)
            {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            }
            else if (action == IDiamondCut.FacetCutAction.Replace)
            {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            }
            else if (action == IDiamondCut.FacetCutAction.Remove)
            {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            }
            else
            {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    )
        internal
    {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );

        DiamondStorage storage ds = diamondStorage();

        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );

        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

        // add new facet address if it does not exist
        if (selectorPosition == 0)
        {
            addFacet(ds, _facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++)
        {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );

            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    )
        internal
    {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );

        DiamondStorage storage ds = diamondStorage();

        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );

        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

        // add new facet address if it does not exist
        if (selectorPosition == 0)
        {
            addFacet(ds, _facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++)
        {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );

            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    )
        internal
    {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );

        DiamondStorage storage ds = diamondStorage();

        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++)
        {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addBaseDiamondFacets(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    )
        internal
    {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        diamondCut(cut, address(0), "");
    }

    function addFacet(
        DiamondStorage storage ds,
        address _facetAddress
    )
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );

        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }


    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    )
        internal
    {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    )
        internal
    {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );

        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );

        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;

        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition)
        {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }

        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0)
        {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;

            if (facetAddressPosition != lastFacetAddressPosition)
            {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }

            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    )
        internal
    {
        if (_init == address(0))
        {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        }
        else
        {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );

            if (_init != address(this))
            {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }

            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success)
            {
                if (error.length > 0)
                {
                    // bubble up the error
                    revert(string(error));
                }
                else
                {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    )
        internal
        view
    {
        uint256 contractSize;

        assembly
        {
            contractSize := extcodesize(_contract)
        }

        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Types} from "../lib/Types.sol";
import {IDeploymentsStorage} from "../interfaces/IDeploymentsStorage.sol";

import {LibDiamond} from "../diamond/lib/LibDiamond.sol";


contract DeploymentsStorageFacet is IDeploymentsStorage {
    using Types for Types.NetworkDeployments;

    uint256 internal NUM_CHAINS = 0;

    uint256[] internal CHAINS_LIST;

    mapping(uint256 => Types.NetworkDeployments) internal NETWORK_DEPLOYMENTS;

    function getDeploymentForChain(
        uint256 chainId,
        Types.DeploymentType deploymentType
    )
        external
        view
        returns (address)
    {
        return NETWORK_DEPLOYMENTS[chainId].getDeploymentAddress(deploymentType);
    }

    function getAllDeploymentsForChain(uint256 chainId)
        external
        view
        returns (Types.NetworkDeployments memory)
    {
        return NETWORK_DEPLOYMENTS[chainId];
    }

    function getDeploymentAllChains(Types.DeploymentType deploymentType)
        external
        view
        returns (Types.NetworkDeployment[] memory deployments)
    {
        deployments = new Types.NetworkDeployment[](NUM_CHAINS);

        for (uint i = 0; i < NUM_CHAINS; i++) {
            uint256 chainId = CHAINS_LIST[i];
            deployments[i] = NETWORK_DEPLOYMENTS[chainId].getDeployment(deploymentType);
        }
    }

    function getAllDeploymentsAllChains()
        external
        view
        returns (Types.NetworkDeployments[] memory deployments)
    {
        deployments = new Types.NetworkDeployments[](NUM_CHAINS);

        for (uint i = 0; i < NUM_CHAINS; i++) {
            uint256 chainId = CHAINS_LIST[i];
            deployments[i] = NETWORK_DEPLOYMENTS[chainId];
        }
    }

    function setDeploymentForChain(
        uint256 chainId,
        Types.DeploymentType deploymentType,
        address deploymentAddress
    )
        external
    {
        _setDeploymentForChain(chainId, deploymentType, deploymentAddress, true);
    }

    function setSomeDeploymentsForChain(
        uint256 chainId,
        Types.NetworkDeployment[] calldata deployments
    )
        external
    {
        _setSomeDeploymentsForChain(chainId, deployments);
    }

    function setAllDeploymentsForChain(
        uint256 chainId,
        Types.NetworkDeployments calldata deployments
    )
        external
    {
        _setAllDeploymentsForChain(chainId, deployments);
    }

    function _setDeploymentForChain(
        uint256 chainId,
        Types.DeploymentType deploymentType,
        address deploymentAddress,
        bool checkAddChain
    )
        internal
    {
        if (checkAddChain) {
            checkAddNewChain(chainId);
        }

        NETWORK_DEPLOYMENTS[chainId].setDeploymentAddress(deploymentType, deploymentAddress);

        emit ChainDeploymentSet(chainId, deploymentType, deploymentAddress);
    }

    function _setSomeDeploymentsForChain(
        uint256 chainId,
        Types.NetworkDeployment[] calldata deployments
    )
        internal
    {
        checkAddNewChain(chainId);

        for (uint i = 0; i < deployments.length; i++) {
            Types.NetworkDeployment memory dep = deployments[i];

            _setDeploymentForChain(chainId, dep.deploymentType, dep.deploymentAddress, false);
        }
    }

    function _setAllDeploymentsForChain(
        uint256 chainId,
        Types.NetworkDeployments calldata deployments
    )
        internal
    {
        NETWORK_DEPLOYMENTS[chainId] = deployments;
        NETWORK_DEPLOYMENTS[chainId].setChainId(chainId);

        emit AllChainDeploymentsSet(
            chainId,
            deployments.bridge,
            deployments.zapBridge,
            deployments.swap
        );
    }


    function checkAddNewChain(uint256 chainId)
        internal
    {
        if (checkChainInStorage(chainId)) {
            return;
        }

        CHAINS_LIST.push(chainId);
        NUM_CHAINS += 1;
        NETWORK_DEPLOYMENTS[chainId].setChainId(chainId);

        emit ChainAdded(chainId);

        return;
    }

    function checkChainInStorage(uint256 chainId)
        internal
        view
        returns (bool inStorage)
    {
        inStorage = false;

        for (uint i = 0; i < NUM_CHAINS; i++) {
            if (CHAINS_LIST[i] == chainId) {
                inStorage = true;
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Types} from "../lib/Types.sol";

interface IDeploymentsStorage {
    // view functions
    function getDeploymentForChain(uint256 chainId, Types.DeploymentType deploymentType) external view returns (address);

    function getAllDeploymentsForChain(uint256 chainId) external view returns (Types.NetworkDeployments memory);

    function getDeploymentAllChains(Types.DeploymentType deploymentType) external view returns (Types.NetworkDeployment[] memory);

    function getAllDeploymentsAllChains() external view returns (Types.NetworkDeployments[] memory);

    // setter functions
    function setDeploymentForChain(
        uint256 chainId,
        Types.DeploymentType deploymentType,
        address deploymentAddress
    ) external;

    function setSomeDeploymentsForChain(
        uint256 chainId,
        Types.NetworkDeployment[] calldata deployments
    ) external;

    function setAllDeploymentsForChain(
        uint256 chainId,
        Types.NetworkDeployments calldata deployments
    ) external;

    // events
    event ChainAdded(uint256 chainId);

    event ChainDeploymentSet(
        uint256 indexed chainId,
        Types.DeploymentType indexed deploymentType,
        address deploymentAddress
    );

    event AllChainDeploymentsSet(
        uint256 indexed chainId,
        address bridge,
        address bridgeZap,
        address swap
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Types {
    enum DeploymentType {
        Bridge,
        ZapBridge,
        Swap
    }

    struct NetworkDeployment {
        address        deploymentAddress;
        uint256        chainId;
        DeploymentType deploymentType;
    }

    struct NetworkDeployments {
        address bridge;
        address zapBridge;
        address swap;
        uint256 chainId;
    }

    function setChainId(NetworkDeployments storage self, uint256 chainId)
        internal
    {
        self.chainId = chainId;
    }

    function getDeployment(NetworkDeployments storage self, DeploymentType deploymentType)
        internal
        view
        returns (NetworkDeployment memory)
    {
        NetworkDeployment memory deployment;
        deployment.chainId = self.chainId;
        deployment.deploymentType = deploymentType;

        if (deploymentType == DeploymentType.Bridge) {
            deployment.deploymentAddress = self.bridge;
        } else if (deploymentType == DeploymentType.ZapBridge) {
            deployment.deploymentAddress = self.zapBridge;
        } else if (deploymentType == DeploymentType.Swap) {
            deployment.deploymentAddress = self.swap;
        }

        return deployment;
    }

    function getDeploymentAddress(NetworkDeployments storage self, DeploymentType deploymentType)
        internal
        view
        returns (address deploymentAddr)
    {
        deploymentAddr = address(0);

        if (deploymentType == DeploymentType.Bridge) {
            deploymentAddr = self.bridge;
        } else if (deploymentType == DeploymentType.ZapBridge) {
            deploymentAddr = self.zapBridge;
        } else if (deploymentType == DeploymentType.Swap) {
            deploymentAddr = self.swap;
        }
    }

    function setDeploymentAddress(
        NetworkDeployments storage self,
        DeploymentType deploymentType,
        address deploymentAddress
    )
        internal
    {
        if (deploymentType == DeploymentType.Bridge) {
            self.bridge = deploymentAddress;
        } else if (deploymentType == DeploymentType.ZapBridge) {
            self.zapBridge = deploymentAddress;
        } else if (deploymentType == DeploymentType.Swap) {
            self.swap = deploymentAddress;
        }
    }
}