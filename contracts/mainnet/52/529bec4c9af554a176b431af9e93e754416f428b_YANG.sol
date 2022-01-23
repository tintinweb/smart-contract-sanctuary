// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yangyangicecream
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    ~""""~""~"!~""~"~""~""~~"~""~""~"~M#M0M0MM0M00N0NNBBMN#Q0N#B#00#B0MMMM0NR00000M    //
//                                      "0N#N00NN&###B#M0&MM0M0#0#QM00MM0B0N0N00&00#M    //
//                                  -    O#0&MWQN#00N&00#M&&#N000&0MM#&0N#000000000&B    //
//                                       MQ0MM#000NKM00M&M#0#M0Q0000M00BM#0M0#00000M0    //
//                                       *#MMN&MN#MMB000#0N00#0M#MM0Q#M0NQ00NN0R0#0N0    //
//           -                           ##M00MN00RMMMNMR00#&#N000D#N00M00MM0M0B0000M    //
//              -                       yp0W0N0B#NRQ000M0#Q##N##M0N0MN0R#M0BNMN&NN&00    //
//            -                      ,(T~#&Q0NMMM0M0M&000WMM#N#00M#0QN0#MM#0Q#0NK0N0M    //
//                                 m~dgg#&0M00Q0N0BMNMMMM&MMM#MQNMQ&0AM#N#0B#0&BQ0#0#    //
//     -                       _p-  0M000BNN00M#EN#00M000N00M#NM#0#0NM00M&R0#Q##MN#0#    //
//                            ^    :b00##MN0BM&#Q0000NMM#0#[email protected]$0MN#[email protected]&NM#    //
//                               aMTN00N0K&0QMMMM00B#N#BMM#M#0BM#&[email protected]##0*A#r0M&#    //
//             -                  \M#Q0M0M#&M#BMR0Q00MQ&#MM&00NBM#Q0$9s%^MmhMMM&&&&&&    //
//          -                     4NMQBMQQN000M0N&M&0M0MKMM&0##G&9&&&&--  "\~:Wd--&--    //
//    ;                         m\j0#BKMM00M00NMMMMgMM0Q00M#8m&d&&^^3E S  E  O.   ~-*    //
//    0                       -&CB&[email protected]#000#N00NMEE%3m  % ~   --0T    -~      //
//    ML                ,  ,zz&#&B0000M###R0000M0#BD&#g80M8FxZ^xE                 - -    //
//    F4                4%%!,yAWR#MMMB00##0MB00B00#&0&Q&YXM,M-    ~        \    \s  -    //
//    M&V             \\MhQp&&##[email protected]#M&E%^       )  \   -      \       //
//    M0f           {E"6m&0MM#B0#B#0#K##B00B#0M#00b&0KQ&&t~~ ~           -    -    \     //
//    M~         /-W~%EggKN#0#0N#KMQB00#00M0M0#QN&QW&rmM ~1 -                   -        //
//              r4b~dEE0M&##K#&0Q0Q&#R0#0000MNM0#QDE$\/ZO                  -             //
//              "-&%&6DFN#F RBgp0N&000NM#M0NM#MND#WQ-#H~                ~                //
//           tT^0~~      3QNN0M0#M#0#0M00&0##NN#0Nr9^4% r             \-                 //
//                     %[email protected]#QN0QQ##NMNNQ0M&AMM:~#                          -        //
//         -             NSw0Q#000M00M00M00#MM0EFaO  &                -                  //
//                  (    16~0N#NQ#M&M0#N00#000&3rw~  I                                   //
//           {  "  /~     &=#MNM0#BA#M0#M####C&&&\  \Z                    \    m         //
//           ^ \         w!xQN0#0#0N00#M#00M#8FFKE   $                                   //
//     \  \   - -         Tr##0MN#B00N#00R0NDQ&&~    F                                   //
//    ,  ~\               #$M80Q&QM0M#MM0M#MAQQ} \  w:~                                  //
//                        0&NMK0M0#N#MNM0Q00Q#E~                              ^  ^       //
//                        &DMM#MD00&00###RR0W:       ~-                          ^       //
//                       -#h$M#00#B0#0#0MMQ09                               \            //
//                   -    39070MM0NM&BKMM0A&-                                            //
//                    -   dMg3Q0#NN000#0000h                              - -            //
//                   t5% (&7MQM0#N00W#8N0&&                              \       ,       //
//                    {"p#g%%BN00##N00M0M&}           : \ - \,         \                 //
//                    ^ENF0G%gQM000NRMMN#M        $QNMt&&&&#QAp&#qg       %        ^+    //
//                     g/#mb;Z$MM#M000#KNE      yMMKK##Q0g&MN0QMMNMM&#,sEE{.             //
//                   = &#QAgQ00#M0QR&0B0&D     m#00M'~7D!P9K0MM00M&MMD0$FFFG  \     ^    //
//                    ,900K8#M#MM0MN0M0QNr     ~\/. -      ^ {&&&MDNZKWE0\w ^S    "r     //
//                   zB&MMW&GN##[email protected]                -   h\ar&&&&NFF^,m     3 \     //
//                \ ^:0N00F#EB&p00MM&#M0Mm               \/-Qmam&~&&m"$:1   -     .-/    //
//                   RZM0M#0BQ6#MMR#M#B0D              Lx*&&3&Q&&mmy/~-&/\~ \      z~    //
//         -         #&AMMM0MNN0#NN#0#NN0$           $EEEpg#000NN&Q&e% m  {   -          //
//               1  -r4*#NM0Q0N#&NBBN0BM&m      \  w&&&g0M~Q0F#0M0000pTaS%\         &    //
//                  - ~#AMNMR0#W0Q0&&M0N0~        m$#B00M" 0Q0#M00#D8CMG%( \       --    //
//                    -,EDM##R#M000#00WMM1         ~~$DEM%,{BQMM00B&&D9$/-          "    //
//      =              *Z/Mr,NW#BK00MM0N0r      = \  dO:T&wb~~#K9#E#0#:#           ~     //
//        \            -::r_;&#M#Q0NQN##&6-         -  ^{r -  ""~~Z~#1 ~            \    //
//                .      T~T~?M00##&#QM0NH \                -   {"0^^               ~    //
//                      \   "}-&&NZD0B&N0E   \    \            S                         //
//                             m&-~LB&0NMAr         -         ^  \                       //
//                       \        m"00&N#b-    -                 \                  t    //
//                  \           Sf;MQp#&M0-   s\\                                        //
//              /   \          %dg0##D&&&#S       ~                                      //
//              -   \    .    {N#MMEEQD#MQr                                              //
//          \        \ --     mmR&K,D~&&B0&                                              //
//                    \  ~  ~M00QB-:0d3EpMA \                                            //
//         ~\z  ^  \  -~^  ^[9 \ - ~~:(pFNW \  .                                    ~    //
//    \ ~O ~w      ~  ^       t*\,+a5  IB#0p  -                    \    -                //
//       -w:       ^ \    \\ :~  \  \  d+*E& -                    ~          ^           //
//    ^   &          ~       :. ^ _   " ,T%:@ \               \      -        -          //
//    ~ r-                 \ \m x  "}\   \wM%                        -              :    //
//                           - }    - -    "$                              9F:Z~  ~ &    //
//                       ~   ~       ~      F               -                \\^  wm9    //
//                                  -   - =  \%           _ \                    \  ~    //
//                          }         -   ( ~~,                                     \    //
//                           `      -  ~/ ~ {r6-  \  ~                              t    //
//                              \          -  :W\             - m6m           \          //
//                        "  -  \        ~   r&$Eq             [email protected]~\M%!pa&f&r,E&ggr##    //
//                        -                 \ ) Cmq          -  {     "B3&W#$M&M&N&N#    //
//                             ^-       -   / -:@04D,           -    -  "W0000T&Z0MU#    //
//                                        -  *L  &&Q$m                     {-&&&&&&BE    //
//                 \ ,       .              %\ " \&NS&W                        - ^\%9    //
//                            \\         ^\ \Ea   ^$W#\                        ~ \~^     //
//                                            \  -Q"0?                            \      //
//                    \   -              - ^- "}  mN% ^    -                             //
//                 -                         \x  gE\          \                          //
//                    -               - { -%\ mmL% ^                                     //
//                                  ,    -{ -m0#~\                                       //
//                                  ^  w -:)aT                                           //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract YANG is ERC721Creator {
    constructor() ERC721Creator("yangyangicecream", "YANG") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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