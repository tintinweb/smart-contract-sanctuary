// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vera Conley Fine Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                   {__         {__{________{_______          {_                                               //
//                    {__       {__ {__      {__    {__       {_ __                                             //
//                     {__     {__  {__      {__    {__      {_  {__                                            //
//                      {__   {__   {______  {_ {__         {__   {__                                           //
//                       {__ {__    {__      {__  {__      {______ {__                                          //
//                         {___     {__      {__    {__   {__       {__                                         //
//                         {__      {________{__      {__{__         {__                                        //
//                                                                                                              //
//                                                                                                              //
//    7IIIII?+++====~~~:::::::::::::::::::::::::::::::,:,:::::::::~~~~~~~~~~~~~~~~~~~=                          //
//    III????++~~~~~~::::::::::::I:I:7:?::,,,,,,,:::::::::::,,:::::::::::::::::::::::~                          //
//    II????+++==+==~~::::::::~Z8DNNZ888+MNZD~+,D7O8I7,,,,:::::::::::,,,,,,...,,,,,,,,                          //
//    I???++++=======~~~~~:,:O778+DO88DDO8D$NNDDN88NDN8I,,,,,,,,.......,,,,,......,,,,                          //
//    ?????+++==~~~:::::::+D8ND?$DO$NDON8NDDONMDNODDNN88D=.,.....,.,,,,,...,,,,,,,,:,,                          //
//    ???+++++==~~~~~~~=:?N$DN8Z8DI8Z8Z8NMNNDD$MMDN8Z88DDNN:,,,,,,,,,,...,,,,,,,,,,,,:                          //
//    ?+++==+======~~~ID8N8ZM7+7?Z8$88DDM8DO$ODNNNNN87NO8878+:I::::::::::::::::~~:~:::                          //
//    ?+++++======~~=8ZIO8DOO+ZO$$88DDNDNNDDNDNNNDIM888NDD8MZ7DND~~~~~~~~~::~~~~~~~~~~                          //
//    ++++++=======ZZ7?ONND7DZOM+7$~+M$M7$++7N$+IDNNMMDDDM8D8Z8D$~~~~~~~~~~~~~~~~~:~::                          //
//    +++++++==N88MD$8MN~ZD7D$=7NNO8INN::D=:$ODZNN7ODN$DND88MMNNNNN8~~~~~~~~~:~~~~~~~:                          //
//    +++++=N$NDMNDNNOO8ZO8MNIO$7MD8ONNI:N::MNO7IZI7NNN8DDDMNODMN8N7:~::~~~::::::~~~~~                          //
//    ++++=7NDNN7NDMOOII=M:8N8ION8$DMDDD8MOM8MNN$?MND8D$MNINMMMNNND8ODZ$:::::,,,,,,,,,                          //
//    +++==ON8NDNMDDM88~~MM:?Z7DOMON8D:N8MNDOO$ZN8NNNODNMN=MDNNDODD8ODDZ~=.........,,,                          //
//    +++==78D8$8D,ODDN8MNNNN$D?N:NM::N7$$$=DZD?D8I7+$NOO8,$DD8NDDNN8DD=Z8......,,.,,,                          //
//    ++++=$N+OM7O~D~88DO8DNDNNNNNMMMNDNMZ78:I,OMMNNMNNO88NNM$MNMN8NN8~D7,,,,,,,::::::                          //
//    ++++$7N$MOZIMNMNNO:=O:=ND777Z+?:MMM?7II+87OOZ8ZIO+=MNMDNDIOIMOIDN78,,,,,,,,:::::                          //
//    ?++77D=~=ON$?+D:?~7:~:D:::,.,:7NN?Z8?DDO88DMND$:O~?:?.D7MO88D8DDNZ8I8:::::::::::                          //
//    +++++8N8D77=====8~~~~D~~:$O7$?++~?7$N+NO78OO?D~Z7::::,N.~N,O.8Z7D+8MDNZ,,.......                          //
//    ++++++=+=======~~~~~~~~~:IZOO878Z+$~+ZOMZNM78DD7,,..:N.OZ?NDN~ZDZ8DNDND.,,,,,,,,                          //
//    ++++==========~~~~~~~$:~$$7ZDD~I?NO=~D$II7ONMN~N,:::N88$IINMO88NNNMND7N8D,..,,.,                          //
//    ++=====~~==~~~~~~+~~~+:~=8II7NO$DD$8NNMID?ZDNMMN?DZDINNZ$NDDNZ8MMNNNMDDN8NZ~~~~~                          //
//    ++++========~~~~~~=?==I8~:I8?+M~I~~8O~I~I7$ZN~~~~~:$Z$D+D:,$$ZNNN8M8DDNDNDN~....                          //
//    ++++========~~~~+78=D$DO=~~~~~~~~~~~~~~~~:+8N::::::I8$8MMZNNMNN+Z8$8$8DND,O:~~~~                          //
//    ~~=========~~~:~N::::,::,,::,::~~~~~~:::~:IZN~:::?87$$D8NDN$7$7MMNNNDDDN::~~~~~~                          //
//    :~~~:~:=====~~~~~~~~~~~~~~~~~~~~~~~~~::::~?ON:::::I::::I,?ZZ7OO?$O$MO8+7::D~~~~~                          //
//    ~===~~~~~~~~~~~~::~~~:::::::::::~::~::~~:~7IN7~::::,$:,,::,~,~Z$O$Z+O8$8O:::::~~                          //
//    =====~=~~~~:::::::,,,,,:::::::::::::::::::$8NN~:::::::::,:,,$$8ZDZDD8ZN.,..,,,,,                          //
//    ==========~~~~~~~~~::::::::::,,,,::::::::?ZINN::::::::::,++7N?D?,=8D8N+,,,,,,,::                          //
//    ?+++==========~~~~::::::::::::::::~~~~~~~IZ8MM:::::::::::~$7ID$?7NZO,:,,,$OZ,:::                          //
//    ++++=======~~~:~~~~~~~~~~~~~~~~~~~~~,:~~~II$MM~~~~::::::::$$Z++,+OI$N~,,++88N$,:                          //
//    DZNOZ8ZI8$OO8N$NMZNID8O$+NZIZOZ7O$$O$88$778ODZ$ODODD?$Z7+?+I8Z+O78I$8D87O77O$$OO                          //
//    ND7D$D7OZN77I?O$$78D8ZOZ7IO8ONZ8$N787$DOD$ODN$DDDDN8OOND$D8OD$DDOZNN77NZ8~DIZO8$                          //
//    O8O88N?O788888O8ZO7I7ZOD8$O?ZZ$?$878D$$N$O$Z$$OO7OOON$DZZD$+O?$IDO$7NDDDDONDZ8DO                          //
//    MNZD$IM$MNMDNMNDN8NDND8ZO7ODDDDOOOD8D888DD7OO?=8O$ZD$Z$NDDND7$7NDODNM++MNNNI7NND                          //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VERA is ERC721Creator {
    constructor() ERC721Creator("Vera Conley Fine Art", "VERA") {}
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