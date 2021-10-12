/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Tangle, a token implementation using EIP-2535: Multi-Facet Proxy
/// @author Brad Brown
/// @notice Pieces of this contract can be updated without needing to redeploy
/// the entire contract
/// @dev implements IDiamondCut and IDiamondLoupe
contract Tangle {

    mapping(bytes4 => address) private selectorToAddress;
    /// @notice The owner of this contract
    address public owner;

    enum FacetCutAction {Add, Replace, Remove}
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    address[] private addresses;
    mapping(address => uint) private addressIndex;
    mapping(address => bytes4[]) private addressToSelectors;
    mapping(bytes4 => uint) private selectorIndex;

    /// @notice Records all functions added, replaced, or removed from this
    /// contract
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice set owner to deployer
    constructor() {
        owner = msg.sender;
    }

    /// @notice payable fallback, does nothing
    receive() external payable {}

    /// @notice executes calldata via delegatecall to address if
    /// calldata's selector is assigned
    /// @dev Input is calldata
    /// @return bytes response from delegatecall
    fallback (bytes calldata) external payable returns (bytes memory) {
        address address_ = selectorToAddress[msg.sig];
        require(address_ != address(0), "zero facet");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                address_,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 { revert(0, returndatasize()) }
                default { return (0, returndatasize()) }
        }
    }

    /// @notice checks if an address is in use as a facet
    /// @param address_ an address to a facet
    /// @return bool whether the address is in use or not
    function facetAddressExists(address address_)
        internal
        view
        returns
        (bool)
    {
        if (addresses.length == 0)
            return false;
        if (addresses[0] != address_ && addressIndex[address_] == 0)
            return false;
        return true;
    }

    /// @notice assigns a selector to an address, revert if selector already
    /// assigned
    /// @param selector an 8 byte function selector
    /// @param facetAddress_ an address to a facet
    function addSelector(
        bytes4 selector,
        address facetAddress_
    ) internal {
        address currentFacetAddress = selectorToAddress[selector];
        require(currentFacetAddress == address(0), "selector add");
        selectorToAddress[selector] = facetAddress_;
        selectorIndex[selector] = addressToSelectors[facetAddress_].length;
        addressToSelectors[facetAddress_].push(selector);
    }

    /// @notice removes a selector from an address, revert if selector isn't
    /// assigned
    /// @param selector an 8 byte function selector
    /// @param facetAddress_ an address to a facet
    function removeSelector(
        bytes4 selector,
        address facetAddress_
    ) internal {
        address currentFacetAddress = selectorToAddress[selector];
        require(currentFacetAddress != address(0), "selector remove");
        bytes4[] memory selectors = addressToSelectors[facetAddress_];
        bytes4 lastSelector = selectors[selectors.length - 1];
        if (lastSelector != selector) {
            selectorIndex[lastSelector] = selectorIndex[selector];
            selectors[selectorIndex[selector]] = lastSelector;
        }
        if (selectors.length > 0) {
            assembly {
                mstore(selectors, sub(mload(selectors), 1))
            }
            addressToSelectors[facetAddress_] = selectors;
        }
        if (selectors.length == 0) {
            address lastAddress = addresses[addresses.length - 1];
            if (lastAddress != facetAddress_) {
                addressIndex[lastAddress] = addressIndex[facetAddress_];
                addresses[addressIndex[facetAddress_]] = lastAddress;
            }
            addresses.pop();
            addressIndex[facetAddress_] = 0;
        }
        selectorToAddress[selector] = address(0);
    }

    /// @notice reassigns a selector to an address, revert if no change in
    /// selector address
    /// @param selector an 8 byte function selector
    /// @param facetAddress_ an address to a facet
    function replaceSelector(
        bytes4 selector,
        address facetAddress_
    ) internal {
        address currentFacetAddress = selectorToAddress[selector];
        require(currentFacetAddress != facetAddress_, "selector replace");
        bytes4[] memory selectors = addressToSelectors[currentFacetAddress];
        bytes4 lastSelector = selectors[selectors.length - 1];
        if (lastSelector != selector) {
            selectorIndex[lastSelector] = selectorIndex[selector];
            selectors[selectorIndex[selector]] = lastSelector;
        }
        if (selectors.length > 0) {
            assembly {
                mstore(selectors, sub(mload(selectors), 1))
            }
            addressToSelectors[currentFacetAddress] = selectors;
        }
        if (selectors.length == 0) {
            address lastAddress = addresses[addresses.length - 1];
            if (lastAddress != currentFacetAddress) {
                addressIndex[lastAddress] = addressIndex[currentFacetAddress];
                addresses[addressIndex[currentFacetAddress]] = lastAddress;
            }
            addresses.pop();
            addressIndex[currentFacetAddress] = 0;
        }
        selectorToAddress[selector] = facetAddress_;
        selectorIndex[selector] = addressToSelectors[facetAddress_].length;
        addressToSelectors[facetAddress_].push(selector);
    }

    /// @notice Add/replace/remove any number of functions and optionally
    /// execute a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and
    /// arguments _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {
        require(msg.sender == owner, "not owner");
        bool changesMade = false;
        for (uint i = 0; i < _diamondCut.length; i++) {
            FacetCut memory facetCut = _diamondCut[i];
            address facetAddress_ = _diamondCut[i].facetAddress;
            if (!facetAddressExists(facetAddress_)) {
                addressIndex[facetAddress_] = addresses.length;
                addresses.push(facetCut.facetAddress);
            }
            for (uint j = 0; j < facetCut.functionSelectors.length; j++) {
                bytes4 selector = facetCut.functionSelectors[j];
                if (facetCut.action == FacetCutAction.Add) {
                    addSelector(selector, facetAddress_);
                    if (!changesMade) changesMade = true;
                }
                if (facetCut.action == FacetCutAction.Replace) {
                    replaceSelector(selector, facetAddress_);
                    if (!changesMade) changesMade = true;
                }
                if (facetCut.action == FacetCutAction.Remove) {
                    removeSelector(selector, facetAddress_);
                    if (!changesMade) changesMade = true;
                }
            }
        }
        if (_init != address(0)) {
            require(_calldata.length > 0, "empty calldata");
            (bool success,) = _init.delegatecall(_calldata);
            require(success, "call unsuccessful");
        }
        if (changesMade) emit DiamondCut(_diamondCut, _init, _calldata);
    }

    /// @notice Gets all facet addresses and their four byte function
    /// selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory) {
        Facet[] memory facets_ = new Facet[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            Facet memory facet;
            facet.facetAddress = addresses[i];
            facet.functionSelectors = addressToSelectors[addresses[i]];
            facets_[i] = facet;
        }
        return facets_;
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    )
        external
        view
        returns
        (bytes4[] memory)
    {
        return addressToSelectors[_facet];
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns
        (address[] memory)
    {
        return addresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns
        (address)
    {
        return selectorToAddress[_functionSelector];
    }

}