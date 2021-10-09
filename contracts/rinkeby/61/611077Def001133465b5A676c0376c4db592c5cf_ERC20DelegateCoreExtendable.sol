pragma solidity ^0.8.0;

import {ERC20Core} from "../implementation/core/ERC20Core.sol";
import {ERC20DelegateCore} from "../implementation/core/ERC20DelegateCore.sol";
import {ERC20CoreExtendableBase} from "./ERC20CoreExtendableBase.sol";
import {ERC20ExtendableLib} from "./ERC20ExtendableLib.sol";
import {IERC20Extension, TransferData} from "../../../extensions/IERC20Extension.sol";
import {LibDiamond} from "./diamond/LibDiamond.sol";


contract ERC20DelegateCoreExtendable is ERC20CoreExtendableBase, ERC20DelegateCore {

    function registerExtension(address extension) public override confirmContext returns (bool) {
        bool result = super.registerExtension(extension);

        if (result) {
            _registerExtensionFunctions(extension);
        }

        return result;
    }

    function removeExtension(address extension) public override(ERC20CoreExtendableBase) confirmContext returns (bool) {
        bool result = super.removeExtension(extension);

        if (result) {
            _removeExtensionFunctions(extension);
        }

        return true;
    }
    
    function _registerExtensionFunctions(address extensionAddress) internal {
        IERC20Extension extension = IERC20Extension(extensionAddress);

        //First register the function selectors with the diamond
        bytes4[] memory externalFunctions = extension.externalFunctions();

        if (externalFunctions.length > 0) {
            LibDiamond.FacetCut[] memory cut = new LibDiamond.FacetCut[](1);
            cut[0] = LibDiamond.FacetCut({
                facetAddress: extensionAddress, 
                action: LibDiamond.FacetCutAction.Add, 
                functionSelectors: externalFunctions
            });
            LibDiamond.diamondCut(cut, extensionAddress, abi.encodeWithSelector(IERC20Extension.initalize.selector));
        }
    }

    function _removeExtensionFunctions(address extensionAddress) internal {
        IERC20Extension extension = IERC20Extension(extensionAddress);

        //First register the function selectors with the diamond
        bytes4[] memory externalFunctions = extension.externalFunctions();

        if (externalFunctions.length > 0) {
            LibDiamond.FacetCut[] memory cut = new LibDiamond.FacetCut[](1);
            cut[0] = LibDiamond.FacetCut({
                facetAddress: extensionAddress, 
                action: LibDiamond.FacetCutAction.Remove, 
                functionSelectors: externalFunctions
            });

            //Dont call initalize when removing functions
            LibDiamond.diamondCut(cut, address(0), "");
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address caller,
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Core, ERC20CoreExtendableBase) {
        TransferData memory data = TransferData(
            address(this),
            msg.data,
            0x00000000000000000000000000000000,
            caller,
            from,
            to,
            amount,
            "",
            ""
        );

        require(ERC20ExtendableLib._delegatecallValidateTransfer(data), "Extension failed validation of transfer");
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address caller,
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Core, ERC20CoreExtendableBase) {
        TransferData memory data = TransferData(
            address(this),
            msg.data,
            0x00000000000000000000000000000000,
            caller,
            from,
            to,
            amount,
            "",
            ""
        );

        require(ERC20ExtendableLib._delegatecallAfterTransfer(data), "Extension failed execution of post-transfer");
    }

    function _getStorageLocation() internal override(ERC20DelegateCore, ERC20Core) pure returns (bytes32) {
        return ERC20DelegateCore._getStorageLocation();
    }

    function _confirmContext() internal override(ERC20DelegateCore, ERC20Core) view returns (bool) {
        return ERC20DelegateCore._confirmContext();
    }
}

pragma solidity ^0.8.0;

interface IERC20Storage {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    function changeCurrentWriter(address newWriter) external;

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

        /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function setAllowance(address owner, address spender, uint256 amount) external returns (bool);

    function setBalance(address owner, uint256 amount) external returns (bool);

    function decreaseTotalSupply(uint256 amount) external returns (bool);

    function increaseTotalSupply(uint256 amount) external returns (bool);

    function setTotalSupply(uint256 amount) external returns (bool);

    function increaseBalance(address owner, uint256 amount) external returns (bool);

    function allowWriteFrom(address source) external view returns (bool);
}

interface IERC20Core {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address caller, address recipient, uint256 amount) external returns (bool);

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
    function approve(address caller, address spender, uint256 amount) external returns (bool);

    /**

    */
    function mint(address caller, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address caller,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address caller, address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address caller, address spender, uint256 subtractedValue) external returns (bool);
}

pragma solidity ^0.8.0;

import {ERC20Core} from "./ERC20Core.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IERC20Storage} from "../../storage/IERC20Storage.sol";

/**
* @dev Contract to be used with an ERC20DelegateProxy. This contract assumes it will be delegatecall'ed 
* by the ERC20DelegateProxy and as such will reference the same storage pointer the ERC20DelegateProxy uses
* for the ERC20Storage contract. This contract will confirm the correct context by ensuring this storage 
* pointer exists (has a value that is non-zero) and that the ERC20Storage address it points to accepts
* us as a writer
*/
contract ERC20DelegateCore is ERC20Core {
    bytes32 constant ERC20_STORAGE_ADDRESS = keccak256("erc20.proxy.storage.address");

    constructor() ERC20Core(ZERO_ADDRESS, ZERO_ADDRESS) { }

    function _getStorageLocation() internal override virtual pure returns (bytes32) {
        return ERC20_STORAGE_ADDRESS;
    }

    function _confirmContext() internal override virtual view returns (bool) {
        IERC20Storage store = _getStorageContract();
        return address(store) != ZERO_ADDRESS && store.allowWriteFrom(address(this));
    }
}

pragma solidity ^0.8.0;

import {IERC20Storage} from "../../storage/IERC20Storage.sol";
import {IERC20Core} from "./IERC20Core.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IERC20Storage} from "../../storage/IERC20Storage.sol";

/**
* @dev Contract to be used with along with an ERC20Proxy and an ERC20Storage. This contract requires
* you to provide the address of the ERC20Proxy and the ERC20Storage contract to use. This contract
* will confirm the correct context by ensuring the caller of this contract is the proxy set,
* there is a valid storage contract and that the ERC20Storage address it points to accepts
* us as a writer
*
* This contract implements the core logic for an ERC20 token, storing the results in a
* corrasponding ERC20Storage contract.
*
* NOTE: If there is no ERC20Proxy provided, then 
*/
contract ERC20Core is IERC20Core {
    bytes32 constant ERC20_STORAGE_ADDRESS_DEFAULT = keccak256("erc20.core.storage.address");
    bytes32 constant ERC20_PROXY_ADDRESS = keccak256("erc20.core.proxy.address");
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    constructor(address proxy, address store) {
        _initalize(proxy, store);
    }

    function _initalize(address proxy, address store) internal {
        //Don't write if value is zero
        if (store != ZERO_ADDRESS) {
            StorageSlot.getAddressSlot(_getStorageLocation()).value = store;
        }
        
        if (proxy != ZERO_ADDRESS) {
            StorageSlot.getAddressSlot(ERC20_PROXY_ADDRESS).value = proxy;
        }
    }

    modifier confirmContext {
        require(_confirmContext(), "This function is being executed in the incorrect context");
        _;
    }

    function _getStorageLocation() internal virtual pure returns (bytes32) {
        return ERC20_STORAGE_ADDRESS_DEFAULT;
    }

    function _getStorageContract() internal virtual view returns (IERC20Storage) {
        return IERC20Storage(
            StorageSlot.getAddressSlot(_getStorageLocation()).value
        );
    }

    function _getProxyAddress() internal virtual view returns (address) {
        return StorageSlot.getAddressSlot(ERC20_PROXY_ADDRESS).value;
    }

    function _confirmContext() internal virtual view returns (bool) {
        return msg.sender == _getProxyAddress() && _getStorageContract().allowWriteFrom(address(this));
    }

    function _balanceOf(address account) internal virtual view returns (uint256) {
        return _getStorageContract().balanceOf(account);
    }

    function _setBalance(address owner, uint256 amount) internal virtual returns (bool) {
       return _getStorageContract().setBalance(owner, amount);
    }

    function _increaseBalance(address owner, uint256 amount) internal virtual returns (bool) {
        return _getStorageContract().increaseBalance(owner, amount);
    }

    function _allowance(address owner, address spender) internal virtual view returns (uint256) {
        return _getStorageContract().allowance(owner, spender);
    }

    function _increaseTotalSupply(uint256 amount) internal virtual returns (bool) {
        return _getStorageContract().increaseTotalSupply(amount);
    }

    function _decreaseTotalSupply(uint256 amount) internal virtual returns (bool) {
        return _getStorageContract().decreaseTotalSupply(amount);
    }

    function _setAllowance(address owner, address spender, uint256 amount) internal virtual returns (bool) {
        return _getStorageContract().setAllowance(owner, spender, amount);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address caller, address recipient, uint256 amount) external override confirmContext returns (bool) {
        _transfer(caller, caller, recipient, amount);
        return true;
    }

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
    function approve(address caller, address spender, uint256 amount) external override confirmContext returns (bool) {
        _approve(caller, caller, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address caller, 
        address sender,
        address recipient,
        uint256 amount
    ) external override confirmContext returns (bool) {
        _transfer(caller, sender, recipient, amount);

        uint256 currentAllowance = _allowance(sender, caller);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        unchecked {
            _approve(caller, sender, caller, currentAllowance - amount);
        }

        return true;
    }

     /** 
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address caller, address spender, uint256 addedValue) public override confirmContext returns (bool) {
        _approve(caller, caller, spender, _allowance(caller, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address caller, address spender, uint256 subtractedValue) public override confirmContext returns (bool) {
        uint256 currentAllowance = _allowance(caller, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(caller, caller, spender, currentAllowance - subtractedValue);

        return true;
    }

    function mint(address caller, address recipient, uint256 amount) external override returns (bool) {
        _mint(caller, recipient, amount);

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address caller,
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(caller, sender, recipient, amount);

        uint256 senderBalance = _balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(_setBalance(sender, senderBalance - amount), "ERC20: Set balance of sender failed");
        require(_increaseBalance(recipient, amount), "ERC20: Increase balance of recipient failed");

        _afterTokenTransfer(caller, sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address caller, address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(caller, address(0), account, amount);
        
        require(_increaseTotalSupply(amount), "ERC20: increase total supply failed");
        require(_increaseBalance(account, amount), "ERC20: increase balance failed");

        _afterTokenTransfer(caller, address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address caller, address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(caller, account, address(0), amount);

        uint256 accountBalance = _getStorageContract().balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        require(_setBalance(account, accountBalance - amount), "ERC20: Set balance of account failed");
        require(_decreaseTotalSupply(amount), "ERC20: Decrease of total supply failed");

        _afterTokenTransfer(caller, account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address caller,
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(_setAllowance(owner, spender, amount), "ERC20: approve write failed");
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address caller,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address caller,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
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

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20Extension} from "../../../extensions/IERC20Extension.sol";
import {ERC20CoreExtendableBase} from "./ERC20CoreExtendableBase.sol";
import {TransferData} from "../../../extensions/IERC20Extension.sol";


library ERC20ExtendableLib {
    bytes32 constant ERC20_EXTENSION_LIST_LOCATION = keccak256("erc20.core.storage.address");
    uint8 constant EXTENSION_NOT_EXISTS = 0;
    uint8 constant EXTENSION_ENABLED = 1;
    uint8 constant EXTENSION_DISABLED = 2;

    struct ERC20ExtendableData {
        address[] registeredExtensions;
        mapping(address => uint8) extensionStateCache;
        mapping(address => uint256) extensionIndexes;
    }

    function extensionStorage() private pure returns (ERC20ExtendableData storage ds) {
        bytes32 position = ERC20_EXTENSION_LIST_LOCATION;
        assembly {
            ds.slot := position
        }
    }

    function _registerExtension(address extension) internal {
        ERC20ExtendableData storage extensionData = extensionStorage();
        require(extensionData.extensionStateCache[extension] == EXTENSION_NOT_EXISTS, "The extension must not already exist");

        //First we need to verify this is a valid contract
        IERC165 ext165 = IERC165(extension);
        
        require(ext165.supportsInterface(0x01ffc9a7), "The extension must support IERC165");
        require(ext165.supportsInterface(type(IERC20Extension).interfaceId), "The extension must support IERC20Extension interface");

        //Interface has been validated, add it to storage
        extensionData.extensionIndexes[extension] = extensionData.registeredExtensions.length;
        extensionData.registeredExtensions.push(extension);
        extensionData.extensionStateCache[extension] = EXTENSION_ENABLED;
    }

    function _disableExtension(address extension) internal {
        ERC20ExtendableData storage extensionData = extensionStorage();
        require(extensionData.extensionStateCache[extension] == EXTENSION_ENABLED, "The extension must be enabled");

        extensionData.extensionStateCache[extension] = EXTENSION_DISABLED;
    }

    function _enableExtension(address extension) internal {
        ERC20ExtendableData storage extensionData = extensionStorage();
        require(extensionData.extensionStateCache[extension] == EXTENSION_DISABLED, "The extension must be enabled");

        extensionData.extensionStateCache[extension] = EXTENSION_ENABLED;
    }

    function _allExtensions() internal view returns (address[] memory) {
        ERC20ExtendableData storage extensionData = extensionStorage();
        return extensionData.registeredExtensions;
    }

    function _removeExtension(address extension) internal {
        ERC20ExtendableData storage extensionData = extensionStorage();
        require(extensionData.extensionStateCache[extension] != EXTENSION_NOT_EXISTS, "The extension must exist (either enabled or disabled)");

        // To prevent a gap in the extensions array, we store the last extension in the index of the extension to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastExtensionIndex = extensionData.registeredExtensions.length - 1;
        uint256 extensionIndex = extensionData.extensionIndexes[extension];

        // When the extension to delete is the last extension, the swap operation is unnecessary. However, since this occurs so
        // rarely that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement
        address lastExtension = extensionData.registeredExtensions[lastExtensionIndex];

        extensionData.registeredExtensions[extensionIndex] = lastExtension;
        extensionData.extensionIndexes[lastExtension] = extensionIndex;

        delete extensionData.extensionIndexes[extension];
        extensionData.registeredExtensions.pop();

        extensionData.extensionStateCache[extension] = EXTENSION_NOT_EXISTS;
    }

    function _invokeExtensionDelegateCall(address extension, bytes memory _calldata) private returns (bool) {
        address ext = address(extension);
        (bool success, bytes memory data) = ext.delegatecall(_calldata);
        if (!success) {
            if (data.length > 0) {
                // bubble up the error
                revert(string(data));
            } else {
                revert("ERC20ExtendableLib: delegatecall to extension reverted");
            }
        }

        return data[0] == 0x01;
    }

    function _callValidateTransfer(TransferData memory data) internal returns (bool) {
        return _validateTransfer(data, false);
    }

    
    function _delegatecallValidateTransfer(TransferData memory data) internal returns (bool) {
        return _validateTransfer(data, true);
    }

    function _callAfterTransfer(TransferData memory data) internal returns (bool) {
        return _executeAfterTransfer(data, false);
    }

    function _delegatecallAfterTransfer(TransferData memory data) internal returns (bool) {
        return _executeAfterTransfer(data, true);
    }


    function _validateTransfer(TransferData memory data, bool useDelegateCall) private returns (bool) {
        //Go through each extension, if it's enabled execute the validate function
        //If any extension returns false, halt and return false
        //If they all return true (or there are no extensions), then return true

        ERC20ExtendableData storage extensionData = extensionStorage();

        for (uint i = 0; i < extensionData.registeredExtensions.length; i++) {
            address extension = extensionData.registeredExtensions[i];

            if (extensionData.extensionStateCache[extension] == EXTENSION_DISABLED) {
                continue; //Skip if the extension is disabled
            }

            //Execute the validate function
            IERC20Extension ext = IERC20Extension(extension);

            if (useDelegateCall) {
                bytes memory cdata = abi.encodeWithSelector(IERC20Extension.validateTransfer.selector, data);
                if (!_invokeExtensionDelegateCall(extension, cdata)) {
                    return false;
                }
            } else {
                if (!ext.validateTransfer(data)) {
                    return false;
                }
            }
        }

        return true;
    }

    function _executeAfterTransfer(TransferData memory data, bool useDelegateCall) private returns (bool) {
        //Go through each extension, if it's enabled execute the onTransferExecuted function
        //If any extension returns false, halt and return false
        //If they all return true (or there are no extensions), then return true

        ERC20ExtendableData storage extensionData = extensionStorage();

        for (uint i = 0; i < extensionData.registeredExtensions.length; i++) {
            address extension = extensionData.registeredExtensions[i];

            if (extensionData.extensionStateCache[extension] == EXTENSION_DISABLED) {
                continue; //Skip if the extension is disabled
            }

            //Execute the validate function
            IERC20Extension ext = IERC20Extension(extension);

            if (useDelegateCall) {
                bytes memory cdata = abi.encodeWithSelector(IERC20Extension.onTransferExecuted.selector, data);
                if (!_invokeExtensionDelegateCall(extension, cdata)) {
                    return false;
                }
            } 
            else {
                if (!ext.onTransferExecuted(data)) {
                  return false;
                }
            }
        }

        return true;
    }
}

pragma solidity ^0.8.0;

import {ERC20Core} from "../implementation/core/ERC20Core.sol";
import {ERC20ExtendableLib} from "./ERC20ExtendableLib.sol";
import {IERC20Extension, TransferData} from "../../../extensions/IERC20Extension.sol";


abstract contract ERC20CoreExtendableBase is ERC20Core {

    function registerExtension(address extension) public virtual confirmContext returns (bool) {
        ERC20ExtendableLib._registerExtension(extension);

        return true;
    }

    function removeExtension(address extension) public virtual confirmContext returns (bool) {
        ERC20ExtendableLib._removeExtension(extension);

        return true;
    }

    function disableExtension(address extension) external virtual confirmContext returns (bool) {
        ERC20ExtendableLib._disableExtension(extension);

        return true;
    }

    function enableExtension(address extension) external virtual confirmContext returns (bool) {
        ERC20ExtendableLib._enableExtension(extension);

        return true;
    }

    function allExtension() external view confirmContext returns (address[] memory) {
        return ERC20ExtendableLib._allExtensions();
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address caller,
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        TransferData memory data = TransferData(
            _getProxyAddress(),
            msg.data,
            0x00000000000000000000000000000000,
            caller,
            from,
            to,
            amount,
            "",
            ""
        );

        require(ERC20ExtendableLib._callValidateTransfer(data), "Extension failed validation of transfer");
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address caller,
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        TransferData memory data = TransferData(
            _getProxyAddress(),
            msg.data,
            0x00000000000000000000000000000000,
            caller,
            from,
            to,
            amount,
            "",
            ""
        );

        require(ERC20ExtendableLib._callAfterTransfer(data), "Extension failed execution of post-transfer");
    }
}

pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
* @dev Verify if a token transfer can be executed or not, on the validator's perspective.
* @param token Token address that is executing this extension. If extensions are being called via delegatecall then address(this) == token
* @param payload The full payload of the initial transaction.
* @param partition Name of the partition (left empty for ERC20 transfer).
* @param operator Address which triggered the balance decrease (through transfer or redemption).
* @param from Token holder.
* @param to Token recipient for a transfer and 0x for a redemption.
* @param value Number of tokens the token holder balance is decreased by.
* @param data Extra information (if any).
* @param operatorData Extra information, attached by the operator (if any).
*/
struct TransferData {
    address token;
    bytes payload;
    bytes32 partition;
    address operator;
    address from;
    address to;
    uint value;
    bytes data;
    bytes operatorData;
}

interface IERC20Extension is IERC165 {

    function initalize() external;

    function validateTransfer(TransferData memory data) external view returns (bool);

    function onTransferExecuted(TransferData memory data) external returns (bool);

    function externalFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: MIT

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

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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