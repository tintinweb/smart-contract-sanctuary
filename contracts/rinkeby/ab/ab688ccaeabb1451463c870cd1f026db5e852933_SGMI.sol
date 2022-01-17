// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Santa Gonna Make It
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::::~==?I7I7I7I7O$I7?+=+::::::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::::=+77$ZZ$$IZZZOZZ87Z$$$Z7+:::::::::::::::::::::::::::::::::    //
//    ::::::::::::::::::::+$ZOZOZZOZO$Z7OZZO$DZOOZ$$O$?++:,:::::::::::::::::::::::::::    //
//    :::::::::::::::::=?$ZOZZ888O8Z78OZ$OOZOIOOOOZZO$77I+=?~=::::::::::::::::::::::::    //
//    :::::::::::::::+$ZOO88888DD8$7$$Z88$Z8ZOZ8D$O88ZZ$7I?7?~::::::::::::::::::::::::    //
//    :::::::::::::~7ZOO88ODD8DD87O$OO8O8OZO8DZ$DZNDOOOZ$$$7?7=:::::,,,,::::::::::::::    //
//    ::::::::::=7$IZZOZ88OD8OO8$ZZO88DDDD8OO8O$8OO8O88OZZ$$$7I==+::,,,,,:::::::::::::    //
//    :::::::::::I7$ZOO8888OO88DO8O888DDDDD8O8ZOO8O88OOZZZZZZOZ$7+I+:,,,,:::::::::::::    //
//    :::::::::=~$ZOO88O8OZOOO8OOOO88888D88O8OOOOOO8ZOZOZOZ$OOOOOOOO$I~,,:::::::::::::    //
//    :::::::::~IIZOOOOZ$Z$$ZZ$ZOZZZZOO8OOOOOZZZZ$$777777I77$Z88O$77I?I:,,::::::::::::    //
//    :::::::::~7OOOOZ77IIII7III777$$ZZZZZ$Z$$777IIIIIII?IIII7ZOOOZZ$I~:::::::::::::::    //
//    :::::::~+77ZZO7I????????????IIII7$777II????????????????I7ZOZZZ$$=:::::::::::::::    //
//    ~~~:::::=?ZZO7??++???????????????III????????????????????I7Z8OZ$7=~::::::::::::::    //
//    ~~~~~:::~$ZZI+=+++?+?????????????????????????????????????I$ZOZ$7I~:::~~~~~~~~~~~    //
//    ~~~~::::=$Z7===+++?????????????????????????????????????++?IZZ7$$I~~~~~~~~~~~~~~~    //
//    ==~~~:::~7$+===?+?????????????????????????????????????+++?I7$$77+=~~~~~~========    //
//    ==~~~:::~$I====++?????????????????+???????????????I???++++?I7$77I~=~============    //
//    ==~~~:::+7+=~=++???????????????????????????????I??II??++=+?I$7$I$~~=============    //
//    ==~~~~::77+===++????????????????????????????????I?I???++=+??777+?+============~~    //
//    ====~~~~77?==+++???II?????????????????????????????????+++=??$$$II?~==========~~~    //
//    ========7II==+++?????????????????????????????????II???+++=+?7ZI7I?==============    //
//    ++++++++77?+++??????????????????????+??????????????????+===?I7777?:=============    //
//    ++++====77I++++???????????????????????????????????????+++===?$$7I$+=============    //
//    ++++====I$I?+++?????????????????????????????????????I?++=====?7$7?I=============    //
//    ++++====$7I?+=++???????I???????II??????IIIIIIII77$Z$$7I?+~===?I7$77==========+==    //
//    +++++===7$?++++?++????IIIIIIIIIIIIIIIIII7$Z8DD8OODDNNNDD8DDZ~~?7$7I============+    //
//    ===+++++7$+++==+?III7$ZZOZZ$777IIIIII7$Z87NNNDDDDDDDZZZZ$$IINZ=7:.7~==========++    //
//    ~~~~====I7++==7OZ8O$$ZO8DDDO$$OZ$Z$O88ONDDDDDDDDDDDDDDDI8OOZN??$OO7IIII=+++=====    //
//    :~~~~===77++?MNDDDNNNDDDDDDDDDDD8ZI?7O8DDDDDDDDDDDDDDDD8888OD?==$I77OOZ7===+++++    //
//    ~~~~====I$:8ODDDDDNDDDDNNDDDDDDNNI???ZNDDDDDDDDDDDDDDDD8888OD+==?II$ZZZ$++++++++    //
//    =========DNOO8DDDDDDDDNNNNDDDDDDNI???$ZDDDDDDDDDDDDDD88888OOD+===II7IZZ$======++    //
//    ===+====+ZIO8DDDDDDDDNDDDDDDDDDDO????I88DDDDDDDDDDDD88888OOOI?+==7$77$Z$=======+    //
//    ~~======ZI:O8D8DDDDDDDDDDDDDDDDD?????I78NDDDDDDDDDD888888OON??+==?ZZ$?7=========    //
//    ~~~~====Z?+N88OO88DDDDDDDDDDDDDMI?+??III$NDDDDDDDDDD8DDD8NI???+=+=IO$?7~=~~~~~~~    //
//    ~~~=====I7=7OOOO888DDDDDDDDDDDD7I++???III78DDDDDDDDDD8D8I????+===+?7$?7~=~~~~~~~    //
//    ~~~===~~~?==N8O8888DDDDDDDDDDDI7+++???III?IIZ8DDD8OOI?I??????++~=Z+I?II~~~~~~~~~    //
//    ~~~~~~~~~?~++?N888DDDDDDDDDDD+II?+++???I???????????????????????~+??I?II==~~~~~~~    //
//    ::~::::::==?I++?IZ8DDDDDOZIIIII?++????????I7III????????????????=?II???+==~======    //
//    :::::::::~$?+=+++????????III7I+++???????+??I777777IIIII???????+=+I$I++==========    //
//    ~~~~~::::~I+?+++???????IIII7I++???????II7I??II7$$$777IIIIII???+++I7$I?======++++    //
//    ====~~~~~=I???+?????IIII777III777IIII778N8$7IIII77$Z$7IIIIII?I?+?$7ZZ===+=+=++++    //
//    ====~~~~~~7+I????IIII777$$III$88Z77$$$$ZZOZZ7777777$$$7IIIIII7I??I78OO7+++++++++    //
//    ::::::::::?$7??IIII777$ZO$77$ZO8888888888888Z$ZZZZZZ$$$7IIIII777IIIDDNDDZ+++++++    //
//    ,,,,,,,,,,+$7?III777$ZOOOOOOZOO8888DD88888O8OOZZOOOOZ$Z7IIII7$7I+?I8NDDDDD8I++++    //
//    ......,,,,,:OIIII77$O8Z$888OO88O88O888OOOZOO8OOOOO888OZ7III77Z$$77IDDDDDDDDDD?++    //
//    ....,,=?~,::I77II7$$8Z8DD8OZOOZZOO8888OOOZZZ$ZOODDDD8OO777ZZ$7$7ZZZDDDDDDDDDDD7?    //
//    ,,:I7$$$$O87O$$7777$888888ZZZ$$$Z$$777III7$$ZZOZ77ZO8O$7$O8ZZZ87OZN88888888888OO    //
//    $8OZZZO88888Z$Z$$777ZOO8OZZ88OOOZ$$$$$$$$$$7I?IIII7Z8O7$$O8ZZ$OZZZI8D88888O8OO8O    //
//    8OOOOO8888OOZ8$$OO$77$OZ7IIII???++++??????????IIII7$OZ$ZOOZOZ78OO$7DD8888OOO8888    //
//    ZOOOO8888OOODO$OZO$$77$Z7IIIII++??++++??I??I?IIIII7OOOZO8O8OOO8Z7I7DDD8888888888    //
//    O888888OOO888D8OOOZZZZOZ$II?IIII7I$ZZ$$Z$777IIII?IZ7$ZZOOZO8O8Z777$DD8888888888D    //
//    8888888O8888O88OZZOOOOO8$$77?II7$$OOZZOZZZ$77II?I$ZZ$OZOOO888$77778DD88888888888    //
//    888888888DO8888DO8ZZ8O8888O7???I$ZOOOOOZZ$$III??II$$7OO8OO8D$7777$DD888888888D88    //
//    ODD8888888O88888D88888O8O8O$7I??I7OZO8OO$7III?II$$OZOO8888O$7777$OD8888888888D88    //
//    DDD888888O888888DDD88OOZ8OOZ$7IIIIII7Z7ZII7$77$7$Z8ZD$OO8Z$7777$O8D88888888DDD88    //
//    8D888888O8888888DDDDO8O88O$O77I7?$$I$77II?7I7$7$ZZO888D8Z$$7$$$Z8D8888888888D888    //
//    8888888888888888DDDD77O88O$Z$7$7I77$$$7?7I7IIZ77ZZDZ8DOZ$$$77$ZOD888888888888888    //
//    8888888888888888DDDD$II7$88OZO$$$$$$ZZI7$7O7?7+ZOO888ZZ$$$$$$ZZ88888888888888888    //
//    888888O888888888DDDD8III77OZ8DOOZZO8OOOZ$ZOZ$OZOD88OZZ$$$$$$ZZO888888888888DD888    //
//    8888888888888888DDDDD77II777ODN8D888888$ZOZDZ8888OZZZZ$$$$$ZZZ8888888888888DD888    //
//    88888888888888888DDDD$7II77777Z8DDNDDDDD8ODD88OZZZZZZZ$$$$ZZZODD8888888888DDDD88    //
//    88888888888888888DDDDD7III$$$$$ZZZ8D8888888OOZZZZZZZ$$$$$$ZZO8D8888888888DDDD888    //
//    888888888888888888DDDN$7III7$$ZZZOOOOOOOOOOOZZZZZZ$Z$$$$$$ZZZDD8888888888DDD8DDD    //
//    888888888888888888DDDDO7IIIII77$ZZOOOZOOOOOOZZ$ZZZ$$$$$$$ZZZOD8888888888DDDD8DDD    //
//    888888888888888D8DDDDDD$7IIIIII77$$$$$$$$Z$$$$$$$$$$$$$$$ZZZDD8888888888DDD8DDD8    //
//    888888888888888DDDDDD88O777IIIII777777$$$$$$Z$$$$$$$$$$$$ZZOD88888888888DDDDDD88    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract SGMI is ERC1155Creator {
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