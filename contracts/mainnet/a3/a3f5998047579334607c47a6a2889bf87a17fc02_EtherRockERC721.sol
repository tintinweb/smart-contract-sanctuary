/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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

/**
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata { // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
    
    using Address for address;
    using Strings for uint256;
    
    mapping(uint => string) private hashes;
    
    // Token name
    string private _name = "Wrapped Ether Rock";

    // Token symbol
    string private _symbol = "WER";
    
    uint private _totalSupply;
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function addIPFShashes() internal {
        hashes[0] = "QmS5Pb4i72JfSsip3PPCELf9Bu3ygce9D2kGS2BEx9PPGy";
        hashes[1] = "QmfWRhjNqyXyqEnarRRq5whaBmTm9sKJU7TxWPD39NX4TP";
        hashes[2] = "QmX2tgEKCBgRYHPnUAm8AdNFzDJGhjRZ4ZkvQZNmgKUe2p";
        hashes[3] = "QmSeAU7SynbUPNPNWeu8wTyV5nJGLSFk1VdequQxbvLggg";
        hashes[4] = "QmapgjCNbJmXm1bRNFiQh5ozhMTEBwmhpukpHBiqWFMdDa";
        hashes[5] = "QmeYh9ZkRe6ZvdFkRaTjqkdBUF6FwCtEJgAnihXj4j3v13";
        hashes[6] = "QmQRk4TozeBtPWnHMtq3Am36LMf33PsJQyzNPTaBWHKNFS";
        hashes[7] = "QmUSXJRyhTRxz6TA6MseGqBERXPPid3x8PVkkh99NoFv9S";
        hashes[8] = "QmSEwpg5C2dfgxywDeCmtUVaUdKiLFKXQK8d9KCku3SF2Y";
        hashes[9] = "QmcQJrWyt1TUjsbjZSjcD4Vz8nKsy4VseJsB8N7EvhSUPJ";
        hashes[10] = "QmPb12GN3pcvL78NVQ6FK9AE252ChBK8gQMCzUjez7prC7";
        hashes[11] = "QmfGXgopgkAiERmtt2inMuwvaajKv8uUow2WjVuJd8n8Cg";
        hashes[12] = "QmRpt7sGKRSxcdpnkdLEdrQZyuMyYgoqez6mYumTdAkmbo";
        hashes[13] = "QmSqE8AjqsiHx5baZ2M4p6mjC5Va35F65yDbkRebFaHGZu";
        hashes[14] = "QmQ6wZHRCaFHafhyqGAK3638biAk6tz56DCAK2BLQKPTct";
        hashes[15] = "QmT8ezQ4nuESWYMzcfbb6kcfESDDyeK2CBYp1uaRQo9xLd";
        hashes[16] = "QmZr1z7cCTXRqYWvPSatcGZwJqSt8j6hsMxLUJBQMbnVnr";
        hashes[17] = "QmTSuh4gznWdw3STbBVG1Ve1jynHHLpfFcdgFwJi4nqktD";
        hashes[18] = "QmRpCGbX5eFbtDehnhatdtp7a1kzmgnkAZSJubsD5Hx7Hh";
        hashes[19] = "QmUUDST3T2oHHrf7Sm4AbVxsh46Mt42XyV6S1AMVgFWM88";
        hashes[20] = "QmY62Pt1923mPKaJkSLyYoSWCGYbLiyxWQoZYaMHPE8FNF";
        hashes[21] = "QmZdDjcsxzS7vQkQiiRmtfDC5S5CAvHRELyMsAF1cPrF3Q";
        hashes[22] = "QmQRZ6emrZyepPGSFfGXUAiHJYVRJaKU83Qyr7KcXfNsbf";
        hashes[23] = "QmfCDeQvQJ2CwKA5VNie6LC5Ny63VdL7uy7UaZwmoJ5Cmu";
        hashes[24] = "QmV585E22k9gJjcBeZNtYdDmoi6yfr36M9yVLdiQP3LxAD";
        hashes[25] = "QmeNqqxdMN5AutjZWeqLQFJzfM6Vxvyi9mBHHKyEWv5r31";
        hashes[26] = "QmX9ZoDYo5ut3icFft1UugnmkyPbZhuYYpg8yPMJzYFftU";
        hashes[27] = "QmRJJLP1ZvPLkyenD7jx7eC798ndeFQyv22rsCaSViLN6k";
        hashes[28] = "QmRbt7LFyAAuCMnv9sAhKRtUrUMSrSQYuFPtPNhpSsjgmq";
        hashes[29] = "QmQNy8Y83KonKfB59kzhvr9eQ4DjC77mJEjuPUpNRKTiKK";
        hashes[30] = "QmZiUEGNKZwQZqrKnDV698hjxT2E4vLuq16Ps3potVDAo8";
        hashes[31] = "QmQUxDwfRXyErr8pUcfKaxjCJwUj7SiE9DLrrJHqL9wCxa";
        hashes[32] = "QmWrkTnGULvc9m7hUub5ss6H1oTfixfixjdgkbrbvxpKNr";
        hashes[33] = "Qmd8eNduEprDi1JX8NUwDXDBDuXcGPmBM3fa1xH5yuMf8d";
        hashes[34] = "QmYKXfA6LsVa28Xn2fLz435Smzm4N6FeJ1k3oVhrmvnAJF";
        hashes[35] = "Qmf6xbzaQ1P6StboKGApSkuDoXeB5cZ61wotLT5Lz1UR9G";
        hashes[36] = "QmZVE4KyoFViMApkgjrqFDnh15HEmXrmXcT9fBnNwhrByo";
        hashes[37] = "QmPWihwusF9ZwtPiXAf87MWD9cA9gENjjVAHPMtLvDBC12";
        hashes[38] = "QmXB34jHAPb7QfRVVnXqpynWaLsGMT1u5a4ZyJWwPRFE7e";
        hashes[39] = "QmZPSj78qzByt6UCFcamUtFJV52yhT5zBnWH63drhFDftf";
        hashes[40] = "QmVVKjGCh1xjTC9dq3ZUJnZLeJJoQrRJhbT2Jfb52NnsA7";
        hashes[41] = "QmauiTLCD6ZBBqZnG1XnkEtgvxfxSAN3YaKtGX9Y4xmNvN";
        hashes[42] = "QmVu9UaQ6HzMRSNh4kH3Chn1yr7zXEg3yrfDaAwJKfvynA";
        hashes[43] = "QmexUh6jw2ThRr7T8c4DkAhU9QYRzdH8AqAQHxiFrvf9Wi";
        hashes[44] = "QmPqpQBWWTb8DP6bmXWgZsXUUh6Lqj2ShMXHC2rudgzzDQ";
        hashes[45] = "QmSdPufB8nFjNnexJmkmNva4HrtwNHLDR5LmzkvWA5755d";
        hashes[46] = "QmYebUrncSKgvoGXmWo4WyYqnd7B2sE7fgeTj81s8hKann";
        hashes[47] = "QmPmFrB8afYZoq2EL3tQ71FiauxkKke5ELDtxNEAXbBe3U";
        hashes[48] = "QmQ5NiJuZNoyv6xVm7wZEpvNanqLgajknz1s2EdnEh5YDt";
        hashes[49] = "QmaCj77AeNV7F3YE8KTLk6ijXJkqLRZrqoomAcpks1ZpC1";
        hashes[50] = "QmUtFQ2NaA1zoBHoASwgaFsn2DED2ZjSR4D3wvt3Y1kTcG";
        hashes[51] = "QmZB4qQD4d2uBiSZoUQWpFSRf63FQvkMaSjFzP6CnNgTH1";
        hashes[52] = "QmQrm4mw4tYzsNMHd2wvhyqJfZ4u1FosYTr2Fmc9v1KUzt";
        hashes[53] = "QmX9ANT6HZGXegt9p5fWRfzv6Bzve2agNGA7LtDzngTJAg";
        hashes[54] = "QmczFxFCZEWAsiFCPdsdovKWMqrhAk1zfXM6HS66zFzA4P";
        hashes[55] = "QmQDceMyrYftARLBr4QANf4L1Wi4DnCAzrck6JnJ5cKLs2";
        hashes[56] = "QmQogFCB14WgPJyoPpmPScRLNynRpGAK9GpbK25Uh9u7pf";
        hashes[57] = "QmPGdKY1W7XzCasRyQ6ePyzM2vWjwbHqvUGnZY5BhZus5C";
        hashes[58] = "QmaAbvGDB22Ycw7Xn1hapGuYDESvs91jWQdqLGJDiZTLvy";
        hashes[59] = "QmbqsPb7SdUbm1TdvgWeh1HytT6ioitJ9mkzKZRsZt1iMU";
        hashes[60] = "QmPqpQBWWTb8DP6bmXWgZsXUUh6Lqj2ShMXHC2rudgzzDQ";
        hashes[61] = "QmVbZHhThcDrM37P3yge9PyzTVpeuD5EZBzwzqJukuW9CX";
        hashes[62] = "QmRruwFh2qGP4vZYsYRgDgScUBzBSWSf61XsrLBi2Y7LZi";
        hashes[63] = "QmTjUE74LVF5eUEhSmh4yVSLUwzHdwD1RwhE6MeouXzksn";
        hashes[64] = "QmTFS2tozPcH6BApzwhRW1bCVmsLPFFVcMRKHfaTADH87T";
        hashes[65] = "QmRgYA3poAMcfDa1qwW9ZbUpy5qSKEk6DYTMwtvStuSM4y";
        hashes[66] = "QmZ5eRoQ5qVTAmu41WQkjBemk4yS6nSXJjRDAeG8QmZWjJ";
        hashes[67] = "QmcK2YWM3cN7MbcDcL1Wa3uvHhdkeY3gUQjAGfqDpvZSuR";
        hashes[68] = "QmX7RSKvKDBKBLJ1zY3ohAwpsCkxp9bwejmKTdE8Lx83eQ";
        hashes[69] = "QmWgU93KrKzw7JUBzgt5zmNEfwGrwxud6nS5dZTBPnTcLZ";
        hashes[70] = "QmfEpi6bvcaHYgDcvGEBdqavgqvctg8NsVxY6bkfA4d8EE";
        hashes[71] = "QmX9ANT6HZGXegt9p5fWRfzv6Bzve2agNGA7LtDzngTJAg";
        hashes[72] = "QmPz7X7YwS2HDqTtEa4LqaUQF3geEvmgfQd3LvdaEw6zFH";
        hashes[73] = "QmfLa3r4J5DzZ85KzQRbX2sxDLqTcxiTR6gkjp5Chz3KSr";
        hashes[74] = "QmYeW9C2zLxoB3imWXLxXKXaRqopWvCbN8WhakAPauE3TK";
        hashes[75] = "QmV4CPhqmmyssCqxLU6f6i4jxhaxbkzoiojNkPgZf79Hra";
        hashes[76] = "QmP8Ckrb9BvDWXLXoZKoRJvfRhs5U4fS8NaTbEhvvGKzhV";
        hashes[77] = "QmcK2YWM3cN7MbcDcL1Wa3uvHhdkeY3gUQjAGfqDpvZSuR";
        hashes[78] = "QmTHLruP6iHriHqqw6oPX6Tsy4hiVzT7MQsUpoaubAqsij";
        hashes[79] = "QmcCaMjtstUhrv5Utm52NQikLhT4FLu9DWsA6vWTcwSakp";
        hashes[80] = "QmYKoXs9hHJy2aZn3dF35BFhmNzr9fz1YhfcgQRs46SynK";
        hashes[81] = "QmP8Ckrb9BvDWXLXoZKoRJvfRhs5U4fS8NaTbEhvvGKzhV";
        hashes[82] = "QmPqpQBWWTb8DP6bmXWgZsXUUh6Lqj2ShMXHC2rudgzzDQ";
        hashes[83] = "QmW1kvaXxDERZcBYyc1ZtzVVTno1iHr5sWGLHPEv6VnRM2";
        hashes[84] = "QmYuL7t35d6UZgqeFhXsueFm7V5KQEeyuLcEVgmr11i1Kb";
        hashes[85] = "QmP8Ckrb9BvDWXLXoZKoRJvfRhs5U4fS8NaTbEhvvGKzhV";
        hashes[86] = "QmZGTsrecqQyNWzh2SSVhsqJsGHwVT2sVEBFcNMnwV73df";
        hashes[87] = "QmX9ANT6HZGXegt9p5fWRfzv6Bzve2agNGA7LtDzngTJAg";
        hashes[88] = "QmS5Pb4i72JfSsip3PPCELf9Bu3ygce9D2kGS2BEx9PPGy";
        hashes[89] = "QmT5J37y58QSqDAJhtfT3NKfh2dxmdgDweBrcpLiedkPEH";
        hashes[90] = "QmTRCus34ftngddGLpx3e3gEzWvzoF3NHrK2rc89LNWTyc";
        hashes[91] = "QmatWTce4vojinsc5vt7U7woeqYQ87Lhn1NABHx1MYmnNZ";
        hashes[92] = "QmeNqqxdMN5AutjZWeqLQFJzfM6Vxvyi9mBHHKyEWv5r31";
        hashes[93] = "QmS8q36mainSQneGonX9fFrWB15B7A9HC8o3vkwkCSrqUA";
        hashes[94] = "QmWG3mGDQLFuVmajqsiT2nCvmEeU2qgCCCQyG3f4E53svi";
        hashes[95] = "QmXMfHnX7MgLcA7Bbj4Bpawe4b5EPg7B1McLaf4XHamq1z";
        hashes[96] = "QmS5Pb4i72JfSsip3PPCELf9Bu3ygce9D2kGS2BEx9PPGy";
        hashes[97] = "QmQJbKHjvhZtbiaFWJiJ1DxGQ6gyxZxTzKp6VxR95sTXUY";
        hashes[98] = "QmV4Bvz7URJa3Rzfp5sBmMQt4FFmWE6Dsuvg6neWpRsEBe";
        hashes[99] = "QmX4WEC3Y41mFV4sNNiV6QyTqkRhmu1NnF8ZcQBHZiFVED";
    }
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < 100, "Enter a tokenId from 0 to 99. Only 100 rocks.");

        string memory baseURI = _baseURI();
        string memory tokenHash = _hash(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenHash)) : ""; // returns for example 'ipfs://QmS5Pb4i72JfSsip3PPCELf9Bu3ygce9D2kGS2BEx9PPGy' for rockId 0
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "ipfs://";
    }
    
    function _hash(uint tokenId) internal view virtual returns (string memory) {
        return hashes[tokenId];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        
        _totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        
        _totalSupply -= 1;

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        // ownerRecords[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    
}

contract EtherRockOG {
    struct Rock {
        address owner;
        bool currentlyForSale;
        uint price;
        uint timesSold;
    }
    mapping (uint => Rock) public rocks;
    // function buyRock(uint256 rockNumber) public payable {} // not used
    // function sellRock(uint256 rockNumber, uint256 price) public {} // not used
    function dontSellRock(uint256 rockNumber) public {}
    function giftRock(uint256 rockNumber, address receiver) public {}
}

contract EtherRockERC721 is ERC721 {

    mapping(uint => address) private ownerRecords;
    
    function checkOwnerRecord(uint tokenId) public view returns (address) {
        return ownerRecords[tokenId];
    }
    
    EtherRockOG etherrock;
    
    address OGaddress;
    
    constructor() {
        OGaddress = 0x41f28833Be34e6EDe3c58D1f597bef429861c4E2;
        etherrock = EtherRockOG(OGaddress);
        for (uint tokenId = 0; tokenId < 100; tokenId++) {
            (address ownerInOGContract, , , ) = getRockInfo(tokenId);
            ownerRecords[tokenId] = ownerInOGContract;
        }
        addIPFShashes();
    }
    
    // pull rock info from OG contract: owner, currentlyForSale, price, timesSold
    function getRockInfo(uint tokenId) public view returns (address, bool, uint, uint) {
        return(etherrock.rocks(tokenId));
    }
    
    function checkIfUpdateRequired(uint tokenId) public view returns (bool updateRequired) {
        (address ownerInOGContract, , , ) = getRockInfo(tokenId);
        if (ownerInOGContract != ownerRecords[tokenId] && ownerInOGContract != address(this)) {
            updateRequired = true;
        } else {
            updateRequired = false;
        }
        return(updateRequired);
    }
    
    function update(uint tokenId) public {
        (address ownerInOGContract, , , ) = getRockInfo(tokenId);
        if (ownerInOGContract != ownerRecords[tokenId] && ownerInOGContract != address(this)) {
            ownerRecords[tokenId] = ownerInOGContract;
        }
    }
    
    function updateAll() public {
        for (uint tokenId = 0; tokenId < 100; tokenId++) {
            update(tokenId);
        }
    }
    
    function wrap(uint tokenId) public {
        (address ownerInOGContract, bool currentlyForSale, , ) = getRockInfo(tokenId);
        require(ownerInOGContract == address(this), "Wrapper contract doesn't own rock in OG contract. Before wrapping a rock, you first have to send it to the wrapper contract by calling giftRock() in the OG contract.");
        require(msg.sender == ownerRecords[tokenId], "You are not recorded as the owner of this rock.");
        
        _safeMint(msg.sender, tokenId);
        
        if (currentlyForSale) {
            etherrock.dontSellRock(tokenId);
        }
    }
    
    // if someone gifts a rock to this wrapper contract while it's listed for sale, and someone buys it before wrap() is called (unlikely but possible), ether will get sent to this contract and receive() will get called. Revert to stop the transaction.
    receive() external payable {
        revert();
    }
    
    function unwrap(uint tokenId) public {
        require(_exists(tokenId), "This rock has not been wrapped.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved.");
        
        ownerRecords[tokenId] = msg.sender;
        
        etherrock.giftRock(tokenId, msg.sender);
        
        _burn(tokenId);
    }
    
}