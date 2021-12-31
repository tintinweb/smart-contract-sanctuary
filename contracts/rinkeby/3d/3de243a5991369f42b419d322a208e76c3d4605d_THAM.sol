// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thaa Mann
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [size=9px][font=monospace][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                              //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄[/color][color=#416d31]▄[/color][color=#3c5c29]▄████▄▄░[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#477936]▄[/color][color=#26411d]█[/color][color=#0f170a]█▓▓▓▓▓▓█[/color][color=#010100]██[/color][color=#713b1b]▓[/color][color=#623318]▓██▄[/color][color=#63a84c]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                       //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#38602b]▄[/color][color=#060a05]█[/color][color=#000000]██[/color][color=#542c15]▓[/color][color=#723c1c]▓▓▓▓▓▓▓╣█▓▓▓▓▓██[/color][color=#63a84c]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                              //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄[/color][color=#0a1108]█[/color][color=#000000]██[/color][color=#5b3016]▓[/color][color=#703b1b]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#61a64a]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                     //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#467836]▄[/color][color=#1f1108]█[/color][color=#2d180b]███[/color][color=#6e3a1b]▓▓▓█[/color][color=#5e4637]▀▀█▓▓▓▓▓▓▓▓▓█▓▓▓▌[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                              //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#477a37]▐[/color][color=#331b0d]█[/color][color=#5d3117]▓▓█▓▓▓▓▓▓[/color][color=#633f29]▓▓╣▓▓▓▓▓▓▓[/color][color=#654a3a]▓▓▓▓▓[/color][color=#130a05]█▓▓[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                       //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#391f0f]█[/color][color=#613318]▓▓▓█▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓█▓▓▓▓▓▓█[/color][color=#456e31]▄[/color][color=#64aa4c]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                            //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#271b0d]█[/color][color=#713b1b]▓[/color][color=#723c1c]▓▓▓▓▓██▓▀▓▀▀▀▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▄[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                            //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#213216]█[/color][color=#6d391a]▓▓▓▓▓▓▓╣████[/color][color=#606060]∞[/color][color=#6d6d6d]⌐√,  [/color][color=#303030]█[/color][color=#323232]▌   [/color][color=#616060]`[/color][color=#5c5754]▐[/color][color=#4f443e]▓[/color][color=#38271d]█[/color][color=#412210]█▓▓▓▓▓▌[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░░[/color]    //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░▐[/color][color=#442411]█[/color][color=#723c1c]▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#625046]▄[/color][color=#65605d]▄, ,▌,▄D▄[/color][color=#412c1f]█[/color][color=#462512]█▓▓▓▓▓▓▓▓▓[/color][color=#4b8039]▌[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░[/color]                                                                                                //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#1f2e15]█[/color][color=#703a1b]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░░░░░░░░░░░░░░░░[/color][color=#406e31]▄[/color][color=#2f4a21]█[/color][color=#2f3217]███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄[/color][color=#599844]░[/color][color=#67b04f]░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                            //
//    [color=#67b04f]░░░░░░░░░░░░░░░▄[/color][color=#2f4c22]█[/color][color=#2c2410]██╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄[/color][color=#65ac4d]░[/color][color=#67b04f]░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░░░░░░░░░[/color][color=#467836]▄[/color][color=#2e411d]█[/color][color=#34210f]█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄[/color][color=#60a349]░[/color][color=#67b04f]░░░░░░░░░░[/color]                                                                                                                                                                                            //
//    [color=#67b04f]░░░░░░░░░░[/color][color=#304e23]█[/color][color=#331f0e]█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#60a54a]░[/color][color=#67b04f]░░░░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░░░░░[/color][color=#2f4f24]█[/color][color=#3c200f]█▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄[/color][color=#67b04f]░[/color][color=#67b04f]░░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░░░░[/color][color=#223417]█[/color][color=#5c3016]▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#5c9e47]░[/color][color=#67b04f]░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░░░[/color][color=#223518]█[/color][color=#623318]╣▓▓▓▓▓▓▓▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#559241]░[/color][color=#67b04f]░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░░[/color][color=#2a4720]█[/color][color=#5d3117]▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#66af4e]░[/color][color=#67b04f]░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░▐[/color][color=#422310]█[/color][color=#723c1c]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#5fa349]░[/color][color=#67b04f]░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░░[/color][color=#221a0c]█[/color][color=#713b1b]▓[/color][color=#723c1c]▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#30190c]█▓[/color][color=#2e180b]█▓[/color][color=#723c1c]▓[/color][color=#6f3a1b]▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#67b04f]░[/color][color=#67b04f]░░░[/color]                                                                                                //
//    [color=#67b04f]░░░[/color][color=#29451f]█[/color][color=#673619]╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓██▓▓▓████╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓███▓▓█▓▓[/color][color=#569141]░[/color][color=#67b04f]░░░[/color]                                                                                                                                                                                                                   //
//    [color=#67b04f]░░░[/color][color=#1c1108]█[/color][color=#723c1c]▓[/color][color=#723c1c]▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#62a74b]░[/color][color=#67b04f]░░[/color]                                                                                                                                                                                            //
//    [color=#67b04f]░░░[/color][color=#335626]▐[/color][color=#6a371a]▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#311a0c]█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌[/color][color=#67b04f]░[/color][color=#67b04f]░[/color]                                                                                                                                                                                            //
//    [color=#67b04f]░░░░[/color][color=#4b2712]▌[/color][color=#723c1c]▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#67b04f]░[/color][color=#67b04f]░[/color]                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [/font][/size]                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THAM is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x442f2d12f32B96845844162e04bcb4261d589abf;
        Address.functionDelegateCall(
            0x442f2d12f32B96845844162e04bcb4261d589abf,
            abi.encodeWithSignature("initialize()")
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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