/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
   function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
   function balanceOf(address owner) external view returns (uint256 balance);

}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
    function substring(string memory str, uint startIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    uint endIndex=strBytes.length;
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
}
    
}

contract test is  Ownable {
    
    function aaaaa(uint256 i)
      public  pure returns (string memory)
    {
   //
    //require(success,"not success");
    //if (returndata.length > 0) {
            string memory tokenuri='data:application/json;base64,eyJuYW1lIjogIkZveCAjMjMiLCAiZGVzY3JpcHRpb24iOiAiVGhlIG1ldGF2ZXJzZSBtYWlubGFuZCBpcyBmdWxsIG9mIGNyZWF0dXJlcy4gQXJvdW5kIHRoZSBGYXJtLCBhbiBhYnVuZGFuY2Ugb2YgUmFiYml0cyBzY3VycnkgdG8gaGFydmVzdCBDQVJST1QuIEFsb25nc2lkZSBGYXJtZXJzLCB0aGV5IGV4cGFuZCB0aGUgZmFybSBhbmQgbXVsdGlwbHkgdGhlaXIgZWFybmluZ3MuIFRoZXJlJ3Mgb25seSBvbmUgc21hbGwgcHJvYmxlbSAtLSB0aGUgZmFybSBoYXMgZ3Jvd24gdG9vIGJpZyBhbmQgYSBuZXcgdGhyZWF0IG9mIG5hdHVyZSBoYXMgZW50ZXJlZCB0aGUgZ2FtZS4iLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTVRBd0pTSWdhR1ZwWjJoMFBTSXhNREFsSWlCMlpYSnphVzl1UFNJeExqRWlJSFpwWlhkQ2IzZzlJakFnTUNBME1DQTBNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JaUI0Yld4dWN6cDRiR2x1YXowaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1UazVPUzk0YkdsdWF5SStQR2x0WVdkbElIZzlJalFpSUhrOUlqUWlJSGRwWkhSb1BTSXpNaUlnYUdWcFoyaDBQU0l6TWlJZ2FXMWhaMlV0Y21WdVpHVnlhVzVuUFNKd2FYaGxiR0YwWldRaUlIQnlaWE5sY25abFFYTndaV04wVW1GMGFXODlJbmhOYVdSWlRXbGtJaUI0YkdsdWF6cG9jbVZtUFNKa1lYUmhPbWx0WVdkbEwzQnVaenRpWVhObE5qUXNhVlpDVDFKM01FdEhaMjlCUVVGQlRsTlZhRVZWWjBGQlFVTm5RVUZCUVc5Q1FVMUJRVUZDS3pCTFZtVkJRVUZCU1ZaQ1RWWkZWVUZCUVVGQlFVRkVkV2xUWW05YVoxaHVlamRhUkZGclJqTmhiVU5HVTJoQ05GaEZaRkpQZVhCTVVGUkdTVkpYYkhCQlFVRkJRVmhTVTFSc1RVRlJUMkpaV21kQlFVRlFVa3BTUlVaVlMwMHZWakJNUm5oM2VrRk5RbFpDY0VFd1MydGFZbVZGYzNkQ1JreDVRV1JHTUdsb1NYRlhURGhPZVhGVmNUQjFRekpUUW14S2JsTnZSMUZpWjAwNFRFZEJWalU1ZHpkRlNqRnRPVlkxYmtoNGJGVklNMmhwVUdFMEx6RkRiMlJSTVhFM1dFZEJTRUZRYlVkTFNGZEpPRGxUY21GNFdXcElaVUpNY0ZGTE1uaFdTMmN3Vld3NVJVZFlOSGRHVTBSVFZrYzRSVXh0VVVad1pHRllhRkpCWVhkdlZ6RmtVVzU0TDNjNEx6QnRTR2d4YmxCaGNYTXJXbGM0Um5ReVQxbzRSbXM1WVVabVNWQnZaRUo1ZFV3emF6YzVSVWxDUzI4Mk5TOUdXRFIyY2t0a2JGSnZlWGtyV201alN6WjNlbEpuUVVreE1EaFpVbVZKVVVKVEszVkNhRGt2V0VwRmQwZGtZelF5TTJoQ2QwNWhTakJzUkV0T2FFUkNka2N4T0dkcVFtTnhjak40U0d0a09YZDNSMGxzZWxVelFTOVdVWEZ1UjJaaVZHWk5UWEpQVERBMGNHMTBMM2xZVVVGQlFVRkJVMVZXVDFKTE5VTlpTVWs5SWk4K1BHbHRZV2RsSUhnOUlqUWlJSGs5SWpRaUlIZHBaSFJvUFNJek1pSWdhR1ZwWjJoMFBTSXpNaUlnYVcxaFoyVXRjbVZ1WkdWeWFXNW5QU0p3YVhobGJHRjBaV1FpSUhCeVpYTmxjblpsUVhOd1pXTjBVbUYwYVc4OUluaE5hV1JaVFdsa0lpQjRiR2x1YXpwb2NtVm1QU0prWVhSaE9tbHRZV2RsTDNCdVp6dGlZWE5sTmpRc2FWWkNUMUozTUV0SFoyOUJRVUZCVGxOVmFFVlZaMEZCUVVOblFVRkJRVzlDUVUxQlFVRkNLekJMVm1WQlFVRkJSbFpDVFZaRlZVRkJRVUZCUVVGRFdGZDVLMWhqYkdadWVqZGFiVTlCY0V4UVZFWkVNVkZYU1VGQlFVRkJXRkpUVkd4TlFWRlBZbGxhWjBGQlFVeHdTbEpGUmxWTFRTOVdNSE5GVG5kNVFVMUNaRUpyUVN0NVVVRlpRWFZSU0RSWWNVMUpRMDlYVTBOVGRERXZhRUpMWTFOMmJqQXhSMUF2UVdGUmJrbDRka1U0UmpsNGRFWnVSMk5ITmtWVE5uWlNWRXhwUjFrd01GQjRhV2RwTW0xSFNsSXlOa1ZuZW1Rd2FFZFFSRTFFUW1scFVrZGFWVmxEV1d0Q01XSlJPV0Y0YjJ0Nlp6ZzNORUZ5ZVdaMWFGTnhUSEJhZGxSelNuVjZjVnBDVm1KWlpEZHNTbTkyZEVaMGVVNUJTRkprV1ZWS1dsVlliM05CTldWclRXeEZWVXgxZGxka2QwWldaVU01YmpkTE5tRXlkVUpsY1RCWmNtaG5UVFEyT1c4d1VTOVRaVFUzU1dZeWJXWkVjSGN6ZUcweVdHVmtkRkJtUVU5VlVGTlJaVEJSTTFScFowRkJRVUZDU2xKVk5VVnlhMHBuWjJjOVBTSXZQanhwYldGblpTQjRQU0kwSWlCNVBTSTBJaUIzYVdSMGFEMGlNeklpSUdobGFXZG9kRDBpTXpJaUlHbHRZV2RsTFhKbGJtUmxjbWx1WnowaWNHbDRaV3hoZEdWa0lpQndjbVZ6WlhKMlpVRnpjR1ZqZEZKaGRHbHZQU0o0VFdsa1dVMXBaQ0lnZUd4cGJtczZhSEpsWmowaVpHRjBZVHBwYldGblpTOXdibWM3WW1GelpUWTBMR2xXUWs5U2R6QkxSMmR2UVVGQlFVNVRWV2hGVldkQlFVRkRaMEZCUVVGdlFXZE5RVUZCUkhoclJrUXJRVUZCUVVOV1FrMVdSVlZCUVVGQmVrMXFUR2hHZUdWMVVIWjZTa0ZCUVVGQldGSlRWR3hOUVZGUFlsbGFaMEZCUVVKYVNsSkZSbFZIVGs1cVIwRldSRUZEVVhkTlMyaEJiVk5HWjNoQlFVRkVha0ZDVEZoTGFVMXZORUZCUVVGQlUxVldUMUpMTlVOWlNVazlJaTgrUEdsdFlXZGxJSGc5SWpRaUlIazlJalFpSUhkcFpIUm9QU0l6TWlJZ2FHVnBaMmgwUFNJek1pSWdhVzFoWjJVdGNtVnVaR1Z5YVc1blBTSndhWGhsYkdGMFpXUWlJSEJ5WlhObGNuWmxRWE53WldOMFVtRjBhVzg5SW5oTmFXUlpUV2xrSWlCNGJHbHVhenBvY21WbVBTSmtZWFJoT21sdFlXZGxMM0J1Wnp0aVlYTmxOalFzYVZaQ1QxSjNNRXRIWjI5QlFVRkJUbE5WYUVWVlowRkJRVU5uUVVGQlFXOUJVVTFCUVVGRE1rMURiM1ZCUVVGQlFURkNUVlpGVlVGQlFVTnVaV296WVVGQlFVRkJXRkpUVkd4TlFWRlBZbGxhWjBGQlFVRjBTbEpGUmxWRFRtUnFSMGRGUVVGQlJIZEJRVVpQYkdScVprRkJRVUZCUld4R1ZHdFRkVkZ0UTBNaUx6NDhhVzFoWjJVZ2VEMGlOQ0lnZVQwaU5DSWdkMmxrZEdnOUlqTXlJaUJvWldsbmFIUTlJak15SWlCcGJXRm5aUzF5Wlc1a1pYSnBibWM5SW5CcGVHVnNZWFJsWkNJZ2NISmxjMlZ5ZG1WQmMzQmxZM1JTWVhScGJ6MGllRTFwWkZsTmFXUWlJSGhzYVc1ck9taHlaV1k5SW1SaGRHRTZhVzFoWjJVdmNHNW5PMkpoYzJVMk5DeHBWa0pQVW5jd1MwZG5iMEZCUVVGT1UxVm9SVlZuUVVGQlEyZEJRVUZCYjBGblRVRkJRVVI0YTBaRUswRkJRVUZEVmtKTlZrVlZRVUZCUVVGQlFVUnVOR1IwTlhGMVdWVkJRVUZCUVZoU1UxUnNUVUZSVDJKWldtZEJRVUZDVWtwU1JVWlZSMDVPYWtkS2JFRk9RVVJQVmtaQ1owZEpTVUZCU0hKMFFVdGlhMWQxUldsQlFVRkJRVVZzUmxSclUzVlJiVU5ESWk4K1BHbHRZV2RsSUhnOUlqUWlJSGs5SWpRaUlIZHBaSFJvUFNJek1pSWdhR1ZwWjJoMFBTSXpNaUlnYVcxaFoyVXRjbVZ1WkdWeWFXNW5QU0p3YVhobGJHRjBaV1FpSUhCeVpYTmxjblpsUVhOd1pXTjBVbUYwYVc4OUluaE5hV1JaVFdsa0lpQjRiR2x1YXpwb2NtVm1QU0prWVhSaE9tbHRZV2RsTDNCdVp6dGlZWE5sTmpRc2FWWkNUMUozTUV0SFoyOUJRVUZCVGxOVmFFVlZaMEZCUVVOblFVRkJRVzlDUVUxQlFVRkNLekJMVm1WQlFVRkJSREZDVFZaRlZVRkJRVUZCUVVGRUx5OHZLMHgyY25CQldERXhSRVZNY1ZOQlFVRkJRVmhTVTFSc1RVRlJUMkpaV21kQlFVRkNPVXBTUlVaVlMwMDVha2RCVjJ0QlJWbG5lRUZCYVVGcFNVTkhRWEZXUWxsUlZrZFZZa0pUUVVWQldVdzRRWE0yUmxkdE1FVkJRVUZCUVZOVlZrOVNTelZEV1VsSlBTSXZQand2YzNablBnPT0iLCAiYXR0cmlidXRlcyI6W3sidHJhaXRfdHlwZSI6IlRhaWwiLCJ2YWx1ZSI6IkFscGhhIn0seyJ0cmFpdF90eXBlIjoiRnVyIiwidmFsdWUiOiJCcm93biBGb3gifSx7InRyYWl0X3R5cGUiOiJGZWV0IiwidmFsdWUiOiJTbmVha2VyaGVhZCJ9LHsidHJhaXRfdHlwZSI6Ik5lY2siLCJ2YWx1ZSI6IkJhcmUgTmVjayJ9LHsidHJhaXRfdHlwZSI6Ik1vdXRoIiwidmFsdWUiOiJDaGlsbCJ9LHsidHJhaXRfdHlwZSI6IkV5ZXMiLCJ2YWx1ZSI6IlRyaWFuZ2xlIn0seyJ0cmFpdF90eXBlIjoiQ3VubmluZyBTY29yZSIsInZhbHVlIjoiNSJ9LHsidHJhaXRfdHlwZSI6IkdlbmVyYXRpb24iLCJ2YWx1ZSI6IkdFTiAwIn0seyJ0cmFpdF90eXBlIjoiVHlwZSIsInZhbHVlIjoiRm94In1dfQ==';
            string memory base64=Base64.substring(tokenuri,i);
            return base64;
            // string memory json=string(Base64.decode(base64));
            // bytes memory whereBytes = bytes (json);
            // bytes memory   whatBytes= bytes (find);

            // bool found = false;
            // for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            //     bool flag = true;
            //     for (uint j = 0; j < whatBytes.length; j++)
            //         if (whereBytes [i + j] != whatBytes [j]) {
            //             flag = false;
            //             break;
            //         }
            //     if (flag) {
            //         found = true;
            //         break;
            //     }
            // }
            // require (found,"isFasdish");
            //     return true;
            //(bool isSheep)=abi.decode(returndata, (bool));
            //require(isSheep,"noWhale");
            //return true;
      //  }else{return false;}
    }
}