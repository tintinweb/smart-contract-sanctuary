// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: House of Lobkowicz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                              BBU                                                                             //
//                                                                            [email protected]@B                                                                           //
//                                                                            G:uBirk                                                                           //
//                                                                             :[email protected]                                                                            //
//                                                            .. [email protected] JX       @5   MB      ,qr [email protected] ,.                                                           //
//                                                           :[email protected] 1BN @[email protected]  :[email protected] [email protected]:[email protected] @[email protected]                                                           //
//                                                        [email protected]::[email protected] OBZ   [email protected]@Br   @BU [email protected]@B                                                        //
//                                                         [email protected] ,[email protected] :BZ:;iiiiiBB  [email protected] ,[email protected]                                                        //
//                                                       [email protected] @@  [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@BN:  @B [email protected]                                                      //
//                                                       :Pv @7 @@@@[email protected]@[email protected]@@1 [email protected]@G [email protected]@[email protected]@@[email protected]@B [email protected] SS.                                                      //
//                                                        @@[email protected]@[email protected]@@@[email protected]@@[email protected]: B7 ZB [email protected]@[email protected]@[email protected]@[email protected];@LFBE                                                       //
//                                                        NBi [email protected]@@[email protected]@[email protected]@[email protected]@ @@[email protected] @[email protected]@[email protected]@[email protected]@[email protected] [email protected]                                                       //
//                                                         [email protected]@[email protected]@[email protected]@[email protected]@B rJLu. @@[email protected]@@@@[email protected]@@@:[email protected]                                                         //
//                                                          F5i:[email protected]@[email protected]::[email protected] vBJii:[email protected]@[email protected]:7ku                                                         //
//                                                            @Bu LvUq rMBOL :@@@[email protected]@@  uBBG, ZJLr @[email protected]                                                           //
//                                                             .  BBj [email protected]@@@[email protected]@: [email protected]@[email protected]@@@  [email protected]  ,                                                            //
//                                               7;               :[email protected]@B0  [email protected]@Br [email protected]@[email protected] [email protected]@[email protected]                v:                                              //
//                                              [email protected]               @[email protected]@[email protected]@@[email protected]@[email protected]@@@@@[email protected]@               ,[email protected]                                             //
//                                             OM   JGOF7:.   ..::[email protected]:,   .B   .:[email protected]:,.    ,:LPM07   @u                                            //
//                                            BZ       .:iu52jvLv7:.             @             ..:iL2XSSUYi,       @P                                           //
//                                           BS         .7.             7v       B              LSL                 BO                                          //
//                                          BL         2BB  [email protected]@@[email protected]@   @B      @            :@[email protected]:                EM                                         //
//                                         BU          [email protected]@[email protected]@@[email protected]@[email protected]@@@      B    :[email protected]@B: kB   Bk ,[email protected]@@:         @B                                        //
//                                         :Bi        ..:[email protected]@@[email protected]@[email protected]@@@@EL..     @    [email protected]@[email protected] r   r [email protected]@[email protected]       uM.                                        //
//                                           BY       [email protected]@[email protected]@@@[email protected]@B.    B   [email protected]@[email protected]@7:,.  ,:[email protected]@[email protected]@r      GO                                          //
//                                            @L        ;qU5O,J [email protected] L:B7q5,      @   .BrBrM7 [email protected]@[email protected]@@@q 7MrBrB      ZG                                           //
//                                             B,           @[email protected]@BqBBBr          B    B87Gr [email protected]@[email protected]@@Bq [email protected]     LB                                            //
//                                       . UL  .B            @@@[email protected]@BL           @     @LJ [email protected]@[email protected] [email protected]      @   Pi .                                      //
//                                       [email protected]: . @r           ;@[email protected]@[email protected]            B      @ [email protected] u:.:u [email protected] @      N5   [email protected]                                      //
//                                       F5  @@ :@            BU   Ou            @       [email protected] :M1u1M: [email protected]       @  BP  M7                                      //
//                                     [email protected]  @ZE  B           [email protected]    ,@.           B      @B J7 @@@[email protected]@ 7J [email protected]     ,B  [email protected] [email protected]                                    //
//                                   [email protected]    @           .EYu2Y15            @      ::   [email protected]@[email protected]   :,     7M    [email protected]@@@8u                                   //
//                                   [email protected] [email protected]     M:                              B  . .      [email protected]@[email protected]@M          11     [email protected] [email protected]                                  //
//                                  0r: LEi      [email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@@@[email protected]@@@[email protected]@Br      rM: 775                                 //
//                                 [email protected] [email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@[email protected]  7B. @Ev [email protected]@@@[email protected]@[email protected]@[email protected] [email protected]@                                 //
//                                 [email protected] [email protected] ;[email protected] @[email protected]@[email protected]@[email protected]@[email protected] 7:[email protected]:[email protected] [email protected]:[email protected] [email protected]@Bv        [email protected]                                //
//                              .jFB  Y:         [email protected]@i    [email protected] [email protected]@[email protected]@[email protected]@[email protected],@B.M2vEi OBu   @58:k   @M Y [email protected]         7r  BJL                              //
//                               [email protected]  ,B,         @[email protected]  ,[email protected],  [email protected]@j          @ [email protected]@[email protected] [email protected]  :[email protected],   [email protected]: [email protected]         vB  :B,                              //
//                               :L  B7i        [email protected]@@[email protected]@[email protected]@@@[email protected]@@Bj          B .vO,[email protected] [email protected]@: 8:     qB :[email protected]         ;2B  5                               //
//                               @[email protected] [email protected]@[email protected]@BqB  @[email protected]@@@[email protected]          @    :  Z5 [email protected]@@@B       B:7.B [email protected] [email protected]@@                              //
//                              [email protected]@E          @@@[email protected]@[email protected] [email protected]@[email protected],rri:i,,.;B     .S,v OBX ir        @Ei,i: [email protected]          @@BM1k                             //
//                              Mu iJL         [email protected]@[email protected]@[email protected] [email protected]@[email protected]@q.::vU:M2v:@@@[email protected]@[email protected]@[email protected] [email protected]@L:  [email protected] ,@[email protected]@.         uJ  PZ                             //
//                             Lj: vM          @@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected] [email protected] [email protected]@[email protected]@[email protected]@[email protected]@Bu.   B   v7 :@@[email protected]         :M: 7U;                            //
//                             [email protected] [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@  @[email protected] @[email protected]@[email protected]@@@[email protected]@[email protected] [email protected] [email protected]  :[email protected]@@j        ,[email protected]:                            //
//                             ,@[email protected] [email protected]@[email protected]@[email protected]@@@U  [email protected]@[email protected]@@[email protected] [email protected]: [email protected]@@@[email protected]@[email protected]: :[email protected] [email protected]@@@[email protected]@@:        [email protected]@                             //
//                             .M  M        [email protected]@[email protected],@[email protected] [email protected]@B:[email protected]@0 :[email protected],:B        [email protected]@@Bi   [email protected]@@7 :[email protected]@[email protected]@[email protected]       :N  @                             //
//                            JB8  [email protected] [email protected]@@[email protected]@,   BB1      [email protected]   ,@[email protected] . EPrB      [email protected]@[email protected] [email protected]@@j   [email protected]@@[email protected]@@[email protected]@:     [email protected]  @Br                           //
//                             :B  @.     [email protected]@[email protected]      :        ,      [email protected]@M::   @   [email protected]@@@[email protected]@[email protected]@[email protected], [email protected]@[email protected]@[email protected]@[email protected]     rq  B                             //
//                              Oj1BY   [email protected]@[email protected]@@: :ii:    ,:ii:    .::[email protected]@@@@@[email protected]@[email protected]@@@@@@@@[email protected]@[email protected]@@@[email protected]@[email protected]@@[email protected]@@@@Br   8G1J8                             //
//                             ,[email protected]@M   [email protected];  ...:[email protected]@[email protected]:i;:@[email protected]:i:[email protected]@u.:[email protected]                           ... .    [email protected]  ,@@[email protected]                             //
//                             7u; :Oi    Mi          @[email protected]    @@[email protected]    @[email protected]    B @0.         :E:.          [email protected]       jq    JN. rk:                            //
//                              0M  5L     @S         [email protected]@@J    @@@@J    [email protected]@7    @  [email protected]@[email protected]@: [email protected]@@B:  [email protected]@[email protected]@B       B0     JS  @u                             //
//                              kYuE8B      @v        @[email protected] [email protected]@L    @[email protected]    @ ,  ,[email protected] [email protected] [email protected]@B87,  :     OM      BZEY5J                             //
//                               @[email protected]@       @        [email protected]@j    @[email protected] [email protected]@v    @ [email protected]@@[email protected] .  [email protected] [email protected]@[email protected]    :@      [email protected]@BB                              //
//                               .k  qN:.    P8       @[email protected]@u    [email protected]@L    @[email protected]    B    :[email protected]@[email protected]@[email protected]@B05u7:     @i    ,,@r .k                               //
//                                @q  [email protected]      B       [email protected]@@j    @[email protected] [email protected]@v    @  [email protected]@[email protected]@r [email protected]@BBL     @      @O  @0                               //
//                               r8B7 :J      @       @[email protected]@u    @@[email protected]    @[email protected]    B     ,[email protected]: [email protected] [email protected]      U  SB8:                              //
//                                 :[email protected]@.    Bk   [email protected]@j    @[email protected] [email protected]@v    @     7uu:   [email protected]@@[email protected]:  r:  rOi.   @P    :[email protected]                                 //
//                                  [email protected]:    vXXq2i,@@@Bu    [email protected]@L    @[email protected]    B         ,[email protected]@[email protected]@[email protected]  @:75PXSr    [email protected]                                 //
//                                  ,Gr  O2:          [email protected]@@J    @[email protected]    @@@@v    @    [email protected]@[email protected]@B.X Lr:P @i          iXS .;M                                  //
//                                    @X ,YB.          [email protected] [email protected]@Y    @[email protected]@L    B    7BG:51 u  @B:  r1   @v          7B7  MG                                   //
//                                    [email protected]@N           ,@B    @[email protected] [email protected]@v    @     v        [email protected]@BG  [email protected]:          :[email protected]@EP.                                   //
//                                      MBr :BBF          NBr  @@@@L    @[email protected]@L    B           [email protected]@FB    rBX          [email protected] [email protected]                                     //
//                                        SL  BS           [email protected]@BJ    @@[email protected]    @         @[email protected]   .uMu            @q  EL                                       //
//                                        @BN  [email protected],           :[email protected]@P    @[email protected]    B         Y    ijG1:           :[email protected] [email protected]                                       //
//                                        . [email protected]              iqXu: @@[email protected]    @          :uXPv,            :[email protected]@5N: .                                       //
//                                            @BL  kLS:              :[email protected]@@BL    B      :uZPY,              7uSL .YBM                                           //
//                                             [email protected], [email protected] :               [email protected]   @   iXG2i             ., ,[email protected] [email protected]                                            //
//                                               [email protected] @[email protected]                .kMi B LBF:                [email protected] [email protected]                                              //
//                                                 :FFii  77JZ7:               [email protected]              .:L8ru,  7:0u.                                                //
//                                                    :Bq8  @[email protected]    :        :        :    [email protected];@[email protected] :[email protected]@.                                                   //
//                                                     5.:[email protected]:  [email protected]:   [email protected]   :[email protected];:  [email protected],,u                                                    //
//                                                          [email protected]@@ :  X:  [email protected]@k [email protected]  7F  . @[email protected]:                                                         //
//                                                              rLkBrU8.7v  [email protected]:[email protected]@7  Ui:B7uMSvi                                                             //
//                                                                    [email protected] [email protected]@[email protected]@7 :YLB,                                                                   //
//                                                                           [email protected] [email protected]                                                                          //
//                                                                             2: j:                                                                            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Lobkowicz is ERC721Creator {
    constructor() ERC721Creator("House of Lobkowicz", "Lobkowicz") {}
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