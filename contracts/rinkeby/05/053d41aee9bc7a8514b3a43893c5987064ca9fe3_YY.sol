// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yangyang
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                              //
//                                                                                                                                              //
//    -             -      -                                         -     --                                                                   //
//                                                   -WgR000DXH8r0mM#                                                                           //
//                                              gDQ00N0&M0&0N5jm0                                                                               //
//                                            qB0#[email protected]&0$##@m00N                                                                               //
//                                           yN&QN#NMW#0N0&KyB$Q0                                                                               //
//                                          00MN0###000&00N0B0DN&                                                                               //
//                                         j0N0M0ME000N0N&8#L8Ng&                                                                               //
//                                        K#0N0M8BMM0#000BMTgEQMZ                                                                               //
//                                       yQ#M0B#00QNM0EMQ&&[email protected]#Z                                                                               //
//                                 ,d&&pg0WMNR#&[email protected]#M#&h#0M&97                                                                               //
//                           amQ&QM##MQ&0QK#&N#0#@0NB0QNMM3XZk2KU                                                                               //
//                         gMM0#Q&0N0M0NF0&WRN0D00#MQNN0&T0R#N&KM                                                                               //
//                       ,Q0AB0N00RB0&@000M00&NBN00MNNN0N9DMM#}M!                                                                               //
//                      y&@QQNN#0N0NN00N0N000&0QQ0#0M&#B2BBRMYQMQ                                                                               //
//                     yE0Q0MN#MQ000QMM00N&NKN0N0&#&&MM##0K0MONU                                                                                //
//                    j&QB#Q&#Q0MMBM! MM&N0D#0M#B&B&#0&EEDMTN0#T"                                                                               //
//                   g#00000N0MNMN00-4NN0MMQNM0M0##M&0#W:##gE#\&6                                                                               //
//                  .Q0MME0N#0#M0N#0 4000##&M0M0GMMQ0#DE X\#'SM%                                                                                //
//                  #0AQQ00BNMMN00M# W#&M#Q#M00#&#BMM##@ ~Ti#Wt-                                                                                //
//                 p&00&4#0###NMQ00# 5M00&[email protected] . aFp "                                                                                 //
//                 #&0B&B0BNN#00MB$M  4M#M#[email protected]&MQN#&&&-! \^f ^                                                                                 //
//                jM#00N0NB&M0NM#BM0n &N#NBg0#&@NQ0Q#::         \                                                                               //
//               _MB#BMBMM0MB0##00&#f=0M#UZ4BM#BQ#MK:^^                                                                                         //
//               &QMNNM&M&#0&N0WNM#[email protected] #008#&B0jN#M##;&\                                                                                         //
//              pW0QM&#0M00MD#MMNMM&Ba0K0MH&MAD###0NQmhm_,                                                                                      //
//             lN00MNM00#MN0#QB00N##0&M0qpa#[email protected]~"7F)MWN&g                                                                                    //
//            4&Q0KK0KK#B000QBN##0M0M0N&9WR##MA"^         ~T_                                                                                   //
//           QWNN000N0000#BBM0Q0#000MN&B BB00%F       \t,                                                                                       //
//          4#$0#Q0&00#M00M0M#0N0#[email protected]&-    _*M0Q8O0-                                                                                    //
//          #0#080&##NMNKNN#MMMNN#NMRN0Mp#BME\   1BE (7gE&~d                                                                                    //
//         n0&#NNMMNN&M&0N0#E#MM00M0M0MQ& gE/       ~\##W .#m                                                                                   //
//        [email protected]&000MM00##MN0&M#006B#   -                                                                                                //
//       )QZ8lB00B#MNN&&NM0#000MKM0M&00N0&#K                                                                                                    //
//       QM0Y#00000M#MM4&NMN#NDM#M0M##MM0M#`                                                                                                    //
//       [email protected]'YMM&QMMR0#&#N0MQ0QB0##NMM#0MQ0          -                                                                                          //
//      LQjgMB#00&N#R#00RM&M0N0MB&00#MKNMM0                                                                                                     //
//       Xi&KMR00NBQ#N0#NDB0#MKW0#MNN00#MK&                                                                                                     //
//      r&#070N0##0M00NNNMMM0MNMNB#MM0NQ00Q$                                                                                                    //
//      b&&H44BBM#MMMMM0QD#E#M0QN#MQ&N0MND0~                -                                                                                   //
//      ]0#0MN000#00MM&M00NM0RBM&Q#0Q00000# T                                                                                                   //
//       #WQ#N0#00&Q&N#00BMB0NWN80M#W0MMNNF                                                                                                     //
//       7#HQ00#####&MM0M&MD&#&00#B&M#M0&M                                                                                                      //
//       #W4#M#0M&M&Q0B0&#[email protected]##Q#0#AQ0N#MY    \        &L_                                                                                      //
//       #0BM0#NM#DM&0K8#RN0M&R#&M#KMMN#M             -E&0W~^!xQM                                                                               //
//       Y#0#0MM00#W&00#QQQ00D0M0MM&0K#M              \  hNE                                                                                    //
//       G&Q#B#0ND0MQN0MMBBM00#&00N0000'                  [email protected],,                                                                               //
//       40N0BN&QN0MXN#[email protected]##           \      - [email protected]                                                                               //
//      ]NQMM0DM00#&0&Q0#MM000#0M000MMP            ~         ^~D0                                                                               //
//      KQ&B#&0QN&00QM#MDMB0N0Q00##B##f            ~ ^          "                                                                               //
//      SB#0C#NMK0#M0MBN#Q0N#N0NN0M0B&I               m                                                                                         //
//       M&]1=4&M0B0N0MMQ000&B#0N0MQ#0f     i           z-                                                                                      //
//       M#R  00N0MMMQ#M0MM#K&00&0#M#R!     !         -"QS                                                                                      //
//      *#Qi  "MMM0M00N#0MNM#MM0MN#00M&     ]       \ ~~"^a-                                                                                    //
//      2NN#   MKMB00M000#BMBMN#N00#B&-      +_       %1a   0~                                                                                  //
//      N0HQ  - M0NNQN0NM000B00000NN0B       &n\     ~ r\6:9Z                                                                                   //
//       MN!    "M0#W#0N00Q00000RM0B0#)       :u,- \^ (-6 ~"                                                                                    //
//      - Il    ~D000MMNM000##80QQ0MM0A\      `E \-    / :E~                                                                                    //
//         [_    )000##0000M#QMQDMM000Q6 /      ~  ,$ S^ ,1}                                                                                    //
//         |`    _NNQQNN0N#00BN#0&[email protected]        %    w,StE\\                                                                                   //
//              ~~QMM0&00M#0#N#M0&R#M6K0`   -     -b  ~w {-&z                                                                                   //
//                &NM0MM&0N0Q#0BMM0NM6Q0  `        ~~$m~Ww:00~                                                                                  //
//             - (BNQ0MMM0Q0MM00NMMN&fa&"             .E%%ZZ/D                                                                                  //
//       -       ~iM&&0KQMNM#[email protected]!jlW    -  -          ~ ^^                                                                                 //
//                QjBM0QNUM0M0M#Q#MM ']3!                                                                                                       //
//               -*N0M###[email protected]   =]  -                                                                                                    //
//                ~0#NM00N00NM#NMMB     +                                                                                                       //
//              t ]&0N&00M0000&NNQ'          -            -                                                                                     //
//                R000000NN0#MM00&                       -                                                                                      //
//               rpNMM0N&##B00M&&                                                                                                               //
//     -    -    qN0#B00000000K8X              -                                                                                                //
//               4BMQQMB0#N0&MB0                                                                                                                //
//               T8#00NN#B000QN                              -                                                                                  //
//               MMMR0NMBq0N#0&                                                                                                                 //
//               aNM#QQQ#M0BF^                                                                                                                  //
//              -#BB#BM#00A9   -                                                                                                                //
//              +QM0M0000D0d                         - -                                                                                        //
//              TDN#000&A0`                                -                                                                                    //
//              )&0Q0N0NM0                               -                                                                                      //
//         \    E00#QM0MHM                                                                                                                      //
//             ~*N0##K^$f                                  -                                                                                    //
//              #&MNM~                       -             -                                                                                    //
//             YNQN$^                                     --                                                                                    //
//            O70WF                             -                                                                                               //
//            "O~"                                                                                                                              //
//               ~                                                                                                                              //
//                                                                                                                                              //
//                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YY is ERC721Creator {
    constructor() ERC721Creator("yangyang", "YY") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
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