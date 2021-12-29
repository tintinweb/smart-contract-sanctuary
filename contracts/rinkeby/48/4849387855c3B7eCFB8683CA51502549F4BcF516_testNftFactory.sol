/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// File: base/IGameEngine.sol

pragma solidity ^0.8.0;

interface GameEngine{
    function stake ( uint tokenId ) external;
    function alertStake (uint tokenId, uint8 tokenType) external;
}
// File: base/IERC721Receiver.sol


pragma solidity ^0.8.0;

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
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: base/IERC165.sol



pragma solidity ^0.8.0;
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
// File: base/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function restrictedChangeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) external;
    function tokenOwnerCall(uint tokenId) external view  returns (address);
    function burnNFT(uint tokenId) external;
    function getToken(uint256 _tokenId) external view returns(uint8, uint8, bool, uint,uint, uint);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    //function nftStatus (uint tokenId) external view returns (uint,uint,bool,uint,uint);

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

// File: base/IERC721Enumerable.sol


pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint index)
    external
    view
    returns (uint tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint index) external view returns (uint);
}
// File: base/IERC721Metadata.sol


pragma solidity ^0.8.0;

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
    function tokenURI(uint tokenId) external view returns (string memory);
}

// File: base/ERC165.sol



pragma solidity ^0.8.0;


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
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File: base/Strings.sol



pragma solidity ^0.8.0;
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint value, uint length)
    internal
    pure
    returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: base/Address.sol



pragma solidity ^0.8.0;
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
        target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
// File: base/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

    function burn(uint256 amount) external returns (bool);

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

// File: metadata/SurvivorMetadata.sol


pragma solidity ^0.8.0;

/// @title SurvivorMetadata
/// @author Elmontos
/// @notice Provides metadata information for survivors
library SurvivorMetadata {
    
    function getShoes() public pure returns (string[28] memory) {
        return ["Shoes 1","Shoes 2","Shoes 3","Shoes 4","Shoes 5","Shoes 6","Shoes 7","Shoes 8","Shoes 9","Shoes 10","Shoes 11","Shoes 12","Shoes 13","Shoes 14","Shoes 15","Shoes 16","Shoes 17","Shoes 18","Shoes 19","Shoes 20","Shoes 21","Shoes 22","Shoes 23","Shoes 24","Shoes 25","Shoes 26","Shoes 27","Shoes 28"];
    }

    function getPants() public pure returns (string[20] memory) {
        return ["Pants 1","Pants 2","Pants 3","Pants 4","Pants 5","Pants 6","Pants 7","Pants 8","Pants 9","Pants 10","Pants 11","Pants 12","Pants 13","Pants 14","Pants 15","Pants 16","Pants 17","Pants 18","Pants 19","Pants 20"];
    }

    function getBody() public pure returns (string[25] memory) {
        return ["Body 1","Body 2","Body 3","Body 4","Body 5","Body 6","Body 7","Body 8","Body 9","Body 10","Body 11","Body 12","Body 13","Body 14","Body 15","Body 16","Body 17","Body 18","Body 19","Body 20","Body 21","Body 22","Body 23","Body 24","Body 25"];
    }

    function getBeard() public pure returns (string[44] memory) {
        return  ["Beard 1","Beard 2","Beard 3","Beard 4","Beard 5","Beard 6","Beard 7","Beard 8","Beard 9","Beard 10","Beard 11","Beard 12","Beard 13","Beard 14","Beard 15","Beard 16","Beard 17","Beard 18","Beard 19","Beard 20","Beard 21","Beard 22","Beard 23","Beard 24","Beard 25","Beard 26","Beard 27","Beard 28","Beard 29","Beard 30","Beard 31","Beard 32","Beard 33","Beard 34","Beard 35","Beard 36","Beard 37","Beard 38","Beard 39","Beard 40","Beard 41","None","None","None"];
    }

    function getHair() public pure returns (string[44] memory) {
        return ["Hair 1","Hair 2","Hair 3","Hair 4","Hair 5","Hair 6","Hair 7","Hair 8","Hair 9","Hair 10","Hair 11","Hair 12","Hair 13","Hair 14","Hair 15","Hair 16","Hair 17","Hair 18","Hair 19","Hair 20","Hair 21","Hair 22","Hair 23","Hair 24","Hair 25","Hair 26","Hair 27","Hair 28","Hair 29","Hair 30","Hair 31","Hair 32","Hair 33","Hair 34","Hair 35","Hair 36","Hair 37","Hair 38","Hair 39","None","None","None","None","None"];
    }

    function getHead() public pure returns (string[44] memory) {
        return ["Hat 1","Hat 2","Hat 3","Hat 4","Hat 5","Hat 6","Hat 7","Hat 8","Sunglasses 1","Sunglasses 2","Face Marking 1","Face Marking 2","Face Marking 3","Hat 9","Sunglasses 3","Sunglasses 4","Sunglasses 5","Sunglasses 6","Sunglasses 7","Sunglasses 8","Sunglasses 9","Sunglasses 10","Face Marking 4","Sunglasses 11","Sunglasses 12","Sunglasses 13","Sunglasses 14","Sunglasses 15","Sunglasses 16","Sunglasses 17","Sunglasses 18","Hat 10","Hat 11","Hat 12","Hat 13","Hat 14","Hat 15","Hat 16","Hat 17","Hat 18","None","None","None","None"];
    }

    function getShirts() public pure returns (string[32] memory) {
        return ["Shirts 1","Shirts 2","Shirts 3","Shirts 4","Shirts 5","Shirts 6","Shirts 7","Shirts 8","Shirts 9","Shirts 10","Shirts 11","Shirts 12","Shirts 13","Shirts 14","Shirts 15","Shirts 16","Shirts 17","Shirts 18","Shirts 19","Shirts 20","Shirts 21","Shirts 22","Shirts 23","Shirts 24","Shirts 25","Shirts 26","Shirts 27","Shirts 28","Shirts 29","Shirts 30","Shirts 31","Shirts 32"];
    }

    function getChestArmorLevel5() public pure returns (string[13] memory) {
        return ["Chest Armor 1","Chest Armor 2","Chest Armor 3","Chest Armor 4","Chest Armor 5","Chest Armor 6","Chest Armor 7","Chest Armor 8","Chest Armor 9","Chest Armor 10","Chest Armor 11","Chest Armor 12","Chest Armor 13"];
    }

    function getShoulderArmorLevel4() public pure returns (string[8] memory) {
        return ["Shoulder Armor 1","Shoulder Armor 2","Shoulder Armor 3","Shoulder Armor 4","Shoulder Armor 5","Shoulder Armor 6","Shoulder Armor 7","Shoulder Armor 8"];
    }

    function getShoulderArmorLevel5() public pure returns (string[8] memory) {
        return ["Shoulder Armor 9","Shoulder Armor 10","Shoulder Armor 11","Shoulder Armor 12","Shoulder Armor 13","Shoulder Armor 14","Shoulder Armor 15","Shoulder Armor 16"];
    }

    function getLegArmorLevel4() public pure returns (string[8] memory) {
        return ["Leg Armor 1","Leg Armor 2","Leg Armor 3","Leg Armor 4","Leg Armor 5","Leg Armor 6","Leg Armor 7","Leg Armor 8"];
    }

    function getRightWeaponLevel1() public pure returns (string[8] memory) {
        return ["Level 1 Right Weapon 1","Level 1 Right Weapon 2","Level 1 Right Weapon 3","Level 1 Right Weapon 4","Level 1 Right Weapon 5","Level 1 Right Weapon 6","Level 1 Right Weapon 7","Level 1 Right Weapon 8"];
    }

    function getRightWeaponLevel2() public pure returns (string[11] memory) {
        return ["Level 2 Right Weapon 1","Level 2 Right Weapon 2","Level 2 Right Weapon 3","Level 2 Right Weapon 4","Level 2 Right Weapon 5","Level 2 Right Weapon 6","Level 2 Right Weapon 7","Level 2 Right Weapon 8","Level 2 Right Weapon 9","Level 2 Right Weapon 10","Level 2 Right Weapon 11"];
    }

    function getLeftWeaponLevel3() public pure returns (string[9] memory) {
        return ["Level 3 Left Weapon 1","Level 3 Left Weapon 2","Level 3 Left Weapon 3","Level 3 Left Weapon 4","Level 3 Left Weapon 5","Level 3 Left Weapon 6","Level 3 Left Weapon 7","Level 3 Left Weapon 8","Level 3 Left Weapon 9"];
    }

    function getLeftWeaponLevel4() public pure returns (string[7] memory) {
        return ["Level 4 Left Weapon 1","Level 4 Left Weapon 2","Level 4 Left Weapon 3","Level 4 Left Weapon 4","Level 4 Left Weapon 5","Level 4 Left Weapon 6","Level 4 Left Weapon 7"];
    }

    function getLeftWeaponLevel5() public pure returns (string[8] memory) {
        return ["Level 5 Left Weapon 1","Level 5 Left Weapon 2","Level 5 Left Weapon 3","Level 5 Left Weapon 4","Level 5 Left Weapon 5","Level 5 Left Weapon 6","Level 5 Left Weapon 7","Level 5 Left Weapon 8"];
    }
}
// File: metadata/SurvivorFactory.sol




pragma solidity ^0.8.0;

/// @title SurvivorFactory
/// @author Elmontos
/// @notice Provides metadata information for survivors
library SurvivorFactory {
    
    enum SurvivorTrait { Shoes, Pants, Body, Beard, Hair, Head, Shirt, ChestArmor, ShoulderArmor, LegArmor, RightWeapon, LeftWeapon }

    //SHOES

    function survivorShoesTraitCount() internal pure returns (uint8) { return 28; }
    function survivorShoesTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getShoes()[traitNumber - 1]; 
    }
    function survivorShoesSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //PANTS
    function survivorPantsTraitCount() internal pure returns (uint8) { return 28; }
    function survivorPantsTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getPants()[traitNumber - 1]; 
    }
    function survivorPantsSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //BODY
    function survivorBodyTraitCount() internal pure returns (uint8) { return 25; }
    function survivorBodyTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getBody()[traitNumber - 1];
    }
    function survivorBodySVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //BEARD
    function survivorBeardTraitCount() internal pure returns (uint8) { return 44; }
    function survivorBeardTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getBeard()[traitNumber - 1];  
    }
    function survivorBeardSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //HAIR
    function survivorHairTraitCount() internal pure returns (uint8) { return 44; }
    function survivorHairTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getHair()[traitNumber - 1];  
    }
    function survivorHairSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //HEAD
    function survivorHeadTraitCount() internal pure returns (uint8) { return 44; }
    function survivorHeadTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getHead()[traitNumber - 1];
    }
    function survivorHeadSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //SHIRTS
    function survivorShirtTraitCount() internal pure returns (uint8) { return 32; }
    function survivorShirtTrait(uint8 traitNumber) internal pure returns (string memory) {
        return SurvivorMetadata.getShirts()[traitNumber - 1];
    }
    function survivorShirtSVG(uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //CHESTARMOR
    function survivorChestArmorTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 5) return 13;
        else return 0;
    }
    function survivorChestArmorTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 5) {
            return SurvivorMetadata.getChestArmorLevel5()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorChestArmorSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //SHOULDERARMOR
    function survivorShoulderArmorTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 4) return 8;
        if(level == 5) return 8;
        else return 0;
    }
    function survivorShoulderArmorTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 4) {
            return SurvivorMetadata.getShoulderArmorLevel4()[traitNumber - 1];
        }  if(level == 5) {
            return SurvivorMetadata.getShoulderArmorLevel5()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorShoulderArmorSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //LEGARMOR
    function survivorLegArmorTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level >= 4) return 8;
        else return 0;
    }
    function survivorLegArmorTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level >= 4) {
            return SurvivorMetadata.getLegArmorLevel4()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorLegArmorSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //RIGHTWEAPON
    function survivorRightWeaponTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 8;
        else if(level >= 2) return 11;
        else return 0;
    }
    function survivorRightWeaponTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            return SurvivorMetadata.getRightWeaponLevel1()[traitNumber - 1];
        } else if(level >= 2) {
            return SurvivorMetadata.getRightWeaponLevel2()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorRightWeaponSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    //LEFTWEAPON
    function survivorLeftWeaponTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 3) return 9;
        else if(level == 4) return 7;
        else if(level == 5) return 8;
        else return 0;
    }
    function survivorLeftWeaponTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 3) {
            return  SurvivorMetadata.getLeftWeaponLevel3()[traitNumber - 1];
        } else if(level == 4) {
            return  SurvivorMetadata.getLeftWeaponLevel4()[traitNumber - 1];
        }  else if(level == 5) {
            return  SurvivorMetadata.getLeftWeaponLevel5()[traitNumber - 1];
        } else {
            return "None";
        }
    }
    function survivorLeftWeaponSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function survivorTrait(SurvivorTrait trait, uint8 level, uint8 traitNumber) external pure returns (string memory) {
        if(trait == SurvivorTrait.Shoes) return survivorShoesTrait(traitNumber);
        if(trait == SurvivorTrait.Pants) return survivorPantsTrait(traitNumber);
        if(trait == SurvivorTrait.Body) return survivorBodyTrait(traitNumber);
        if(trait == SurvivorTrait.Beard) return survivorBeardTrait(traitNumber);
        if(trait == SurvivorTrait.Hair) return survivorHairTrait(traitNumber);
        if(trait == SurvivorTrait.Head) return survivorHeadTrait(traitNumber);
        if(trait == SurvivorTrait.Shirt) return survivorShirtTrait(traitNumber);

        if(trait == SurvivorTrait.ChestArmor) return survivorChestArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.ShoulderArmor) return survivorShoulderArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.LegArmor) return survivorLegArmorTrait(level, traitNumber);
        if(trait == SurvivorTrait.RightWeapon) return survivorRightWeaponTrait(level, traitNumber);
        if(trait == SurvivorTrait.LeftWeapon) return survivorLeftWeaponTrait(level, traitNumber);
        else return "None";
    }

    function survivorSVG(uint8 level, uint8[] memory traits) external pure returns (bytes memory) {
        string memory shoesSVG = survivorShoesSVG(traits[0]);
        string memory pantsSVG = survivorPantsSVG(traits[1]);
        string memory bodySVG = survivorBodySVG(traits[2]);
        string memory beardSVG = survivorBeardSVG(traits[3]);
        string memory hairSVG = survivorHairSVG(traits[4]);
        string memory headSVG = survivorHeadSVG(traits[5]);
        string memory shirtSVG = survivorShirtSVG(traits[6]);

        string memory chestArmorSVG = survivorChestArmorSVG(level, traits[7]);
        string memory shoulderArmorSVG = survivorShoulderArmorSVG(level, traits[8]);
        string memory LegArmorSVG = survivorLegArmorSVG(level, traits[9]);
        string memory rightWeaponSVG = survivorRightWeaponSVG(level, traits[10]);
        string memory leftWeaponSVG = survivorLeftWeaponSVG(level, traits[11]);

        return bytes(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 7 8" shape-rendering="crispEdges">',
                shoesSVG,
                pantsSVG,
                bodySVG,
                beardSVG,
                hairSVG,
                headSVG,
                shirtSVG,
                chestArmorSVG,
                shoulderArmorSVG,
                LegArmorSVG,
                rightWeaponSVG,
                leftWeaponSVG,
                '</svg>'
            )
        );
    }
}
// File: metadata/ZombieMetadata.sol


pragma solidity ^0.8.0;

/// @title ZombieMetadata
/// @author Elmontos
/// @notice Provides metadata information for zombies
library ZombieMetadata {
    
    enum ZombieTrait { Torso, LeftArm, RightArm, Legs, Head }

    function zombieTorsoTraitCount(uint8 level) internal pure returns (uint8) { if(level > 0) { return 10; } else { return 0; } }
    function zombieTorsoTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[10] memory TORSO_L1 = ["Level 1 Torso 1","Level 1 Torso 2","Level 1 Torso 3","Level 1 Torso 4","Level 1 Torso 5","Level 1 Torso 6","Level 1 Torso 7","Level 1 Torso 8","Level 1 Torso 9","Level 1 Torso 10"];
            return TORSO_L1[traitNumber - 1];
        } else if(level == 2) {
            string[10] memory TORSO_L2 = ["Level 2 Torso 1","Level 2 Torso 2","Level 2 Torso 3","Level 2 Torso 4","Level 2 Torso 5","Level 2 Torso 6","Level 2 Torso 7","Level 2 Torso 8","Level 2 Torso 9","Level 2 Torso 10"];
            return TORSO_L2[traitNumber - 1];
        } else if(level == 3) {
            string[10] memory TORSO_L3 = ["Level 3 Torso 1","Level 3 Torso 2","Level 3 Torso 3","Level 3 Torso 4","Level 3 Torso 5","Level 3 Torso 6","Level 3 Torso 7","Level 3 Torso 8","Level 3 Torso 9","Level 3 Torso 10"];
            return TORSO_L3[traitNumber - 1];
        } else if(level == 4) {
            string[10] memory TORSO_L3 = ["Level 4 Torso 1","Level 4 Torso 2","Level 4 Torso 3","Level 4 Torso 4","Level 4 Torso 5","Level 4 Torso 6","Level 4 Torso 7","Level 4 Torso 8","Level 4 Torso 9","Level 4 Torso 10"];
            return TORSO_L3[traitNumber - 1];
        } else if(level == 5) {
            string[10] memory TORSO_L3 = ["Level 5 Torso 1","Level 5 Torso 2","Level 5 Torso 3","Level 5 Torso 4","Level 5 Torso 5","Level 5 Torso 6","Level 5 Torso 7","Level 5 Torso 8","Level 5 Torso 9","Level 5 Torso 10"];
            return TORSO_L3[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieTorsoSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieLeftArmTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 12;
        else if(level == 2) return 8;
        else if(level == 3) return 9;
        else if(level == 4) return 9;
        else if(level == 5) return 9;
        else return 0;
    }
    function zombieLeftArmTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[12] memory LEFTARM_L1 = ["Level 1 Left Arm 1","Level 1 Left Arm 2","Level 1 Left Arm 3","Level 1 Left Arm 4","Level 1 Left Arm 5","Level 1 Left Arm 6","Level 1 Left Arm 7","Level 1 Left Arm 8","Level 1 Left Arm 9","Level 1 Left Arm 10","Level 1 Left Arm 11","Level 1 Left Arm 12"];
            return LEFTARM_L1[traitNumber - 1];
        } else if(level == 2) {
            string[8] memory LEFTARM_L2 = ["Level 2 Left Arm 1","Level 2 Left Arm 2","Level 2 Left Arm 3","Level 2 Left Arm 4","Level 2 Left Arm 5","Level 2 Left Arm 6","Level 2 Left Arm 7","Level 2 Left Arm 8"];
            return LEFTARM_L2[traitNumber - 1];
        } else if(level == 3) {
            string[9] memory LEFTARM_L3 = ["Level 3 Left Arm 1","Level 3 Left Arm 2","Level 3 Left Arm 3","Level 3 Left Arm 4","Level 3 Left Arm 5","Level 3 Left Arm 6","Level 3 Left Arm 7","Level 3 Left Arm 8","Level 3 Left Arm 9"];
            return LEFTARM_L3[traitNumber - 1];
        } else if(level == 4) {
            string[9] memory LEFTARM_L4 = ["Level 4 Left Arm 1","Level 4 Left Arm 2","Level 4 Left Arm 3","Level 4 Left Arm 4","Level 4 Left Arm 5","Level 4 Left Arm 6","Level 4 Left Arm 7","Level 4 Left Arm 8","Level 4 Left Arm 9"];
            return LEFTARM_L4[traitNumber - 1];
        } else if(level == 5) {
            string[9] memory LEFTARM_L5 = ["Level 5 Left Arm 1","Level 5 Left Arm 2","Level 5 Left Arm 3","Level 5 Left Arm 4","Level 5 Left Arm 5","Level 5 Left Arm 6","Level 5 Left Arm 7","Level 5 Left Arm 8","Level 5 Left Arm 9"];
            return LEFTARM_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieLeftArmSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieRightArmTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 15;
        else if(level == 2) return 6;
        else if(level == 3) return 8;
        else if(level == 4) return 9;
        else if(level == 5) return 7;
        else return 0;
    }
    function zombieRightArmTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[15] memory RIGHTARM_L1 = ["Level 1 Right Arm 1","Level 1 Right Arm 2","Level 1 Right Arm 3","Level 1 Right Arm 4","Level 1 Right Arm 5","Level 1 Right Arm 6","Level 1 Right Arm 7","Level 1 Right Arm 8","Level 1 Right Arm 9","Level 1 Right Arm 10","Level 1 Right Arm 11","Level 1 Right Arm 12","Level 1 Right Arm 13","Level 1 Right Arm 14","Level 1 Right Arm 15"];
            return RIGHTARM_L1[traitNumber - 1];
        } else if(level == 2) {
            string[6] memory RIGHTARM_L2 = ["Level 2 Right Arm 1","Level 2 Right Arm 2","Level 2 Right Arm 3","Level 2 Right Arm 4","Level 2 Right Arm 5","Level 2 Right Arm 6"];
            return RIGHTARM_L2[traitNumber - 1];
        } else if(level == 3) {
            string[8] memory RIGHTARM_L3 = ["Level 3 Right Arm 1","Level 3 Right Arm 2","Level 3 Right Arm 3","Level 3 Right Arm 4","Level 3 Right Arm 5","Level 3 Right Arm 6","Level 3 Right Arm 7","Level 3 Right Arm 8"];
            return RIGHTARM_L3[traitNumber - 1];
        } else if(level == 4) {
            string[9] memory RIGHTARM_L4 = ["Level 4 Right Arm 1","Level 4 Right Arm 2","Level 4 Right Arm 3","Level 4 Right Arm 4","Level 4 Right Arm 5","Level 4 Right Arm 6","Level 4 Right Arm 7","Level 4 Right Arm 8","Level 4 Right Arm 9"];
            return RIGHTARM_L4[traitNumber - 1];
        } else if(level == 5) {
            string[7] memory RIGHTARM_L5 = ["Level 5 Right Arm 1","Level 5 Right Arm 2","Level 5 Right Arm 3","Level 5 Right Arm 4","Level 5 Right Arm 5","Level 5 Right Arm 6","Level 5 Right Arm 7"];
            return RIGHTARM_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieRightArmSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieLegsTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 12;
        else if(level == 2) return 12;
        else if(level == 3) return 8;
        else if(level == 4) return 10;
        else if(level == 5) return 9;
        else return 0;
    }
    function zombieLegsTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[12] memory LEGS_L1 = ["Level 1 Legs 1","Level 1 Legs 2","Level 1 Legs 3","Level 1 Legs 4","Level 1 Legs 5","Level 1 Legs 6","Level 1 Legs 7","Level 1 Legs 8","Level 1 Legs 9","Level 1 Legs 10","Level 1 Legs 11","Level 1 Legs 12"];
            return LEGS_L1[traitNumber - 1];
        } else if(level == 2) {
            string[12] memory LEGS_L2 = ["Level 2 Legs 1","Level 2 Legs 2","Level 2 Legs 3","Level 2 Legs 4","Level 2 Legs 5","Level 2 Legs 6","Level 2 Legs 7","Level 2 Legs 8","Level 2 Legs 9","Level 2 Legs 10","Level 2 Legs 11","Level 2 Legs 12"];
            return LEGS_L2[traitNumber - 1];
        } else if(level == 3) {
            string[8] memory LEGS_L3 = ["Level 3 Legs 1","Level 3 Legs 2","Level 3 Legs 3","Level 3 Legs 4","Level 3 Legs 5","Level 3 Legs 6","Level 3 Legs 7","Level 3 Legs 8"];
            return LEGS_L3[traitNumber - 1];
        } else if(level == 4) {
            string[10] memory LEGS_L4 = ["Level 4 Legs 1","Level 4 Legs 2","Level 4 Legs 3","Level 4 Legs 4","Level 4 Legs 5","Level 4 Legs 6","Level 4 Legs 7","Level 4 Legs 8","Level 4 Legs 9","Level 4 Legs 10"];
            return LEGS_L4[traitNumber - 1];
        } else if(level == 5) {
            string[9] memory LEGS_L5 = ["Level 5 Legs 1","Level 5 Legs 2","Level 5 Legs 3","Level 5 Legs 4","Level 5 Legs 5","Level 5 Legs 6","Level 5 Legs 7","Level 5 Legs 8","Level 5 Legs 9"];
            return LEGS_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieLegsSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieHeadTraitCount(uint8 level) internal pure returns (uint8) { 
        if(level == 1) return 16;
        else if(level == 2) return 10;
        else if(level == 3) return 11;
        else if(level == 4) return 9;
        else if(level == 5) return 10;
        else return 0;
    }
    function zombieHeadTrait(uint8 level, uint8 traitNumber) internal pure returns (string memory) {
        if(level == 1) {
            string[16] memory HEAD_L1 = ["Level 1 Head 1","Level 1 Head 2","Level 1 Head 3","Level 1 Head 4","Level 1 Head 5","Level 1 Head 6","Level 1 Head 7","Level 1 Head 8","Level 1 Head 9","Level 1 Head 10","Level 1 Head 11","Level 1 Head 12","Level 1 Head 13","Level 1 Head 14","Level 1 Head 15","Level 1 Head 16"];
            return HEAD_L1[traitNumber - 1];
        } else if(level == 2) {
            string[10] memory HEAD_L2 = ["Level 2 Head 1","Level 2 Head 2","Level 2 Head 3","Level 2 Head 4","Level 2 Head 5","Level 2 Head 6","Level 2 Head 7","Level 2 Head 8","Level 2 Head 9","Level 2 Head 10"];
            return HEAD_L2[traitNumber - 1];
        } else if(level == 3) {
            string[11] memory HEAD_L3 = ["Level 3 Head 1","Level 3 Head 2","Level 3 Head 3","Level 3 Head 4","Level 3 Head 5","Level 3 Head 6","Level 3 Head 7","Level 3 Head 8","Level 3 Head 9","Level 3 Head 10","Level 3 Head 11"];
            return HEAD_L3[traitNumber - 1];
        } else if(level == 4) {
            string[9] memory HEAD_L4 = ["Level 4 Head 1","Level 4 Head 2","Level 4 Head 3","Level 4 Head 4","Level 4 Head 5","Level 4 Head 6","Level 4 Head 7","Level 4 Head 8","Level 4 Head 9"];
            return HEAD_L4[traitNumber - 1];
        } else if(level == 5) {
            string[10] memory HEAD_L5 = ["Level 5 Head 1","Level 5 Head 2","Level 5 Head 3","Level 5 Head 4","Level 5 Head 5","Level 5 Head 6","Level 5 Head 7","Level 5 Head 8","Level 5 Head 9","Level 5 Head 10"];
            return HEAD_L5[traitNumber - 1];
        } else {
            return "";
        }
    }
    function zombieHeadSVG(uint8 level, uint8 traitNumber) internal pure returns(string memory) {
        //TBA
        return "";
    }

    function zombieTrait(ZombieTrait trait, uint8 level, uint8 traitNumber) external pure returns (string memory) {
        if(trait == ZombieTrait.Torso) return zombieTorsoTrait(level, traitNumber);
        else if(trait == ZombieTrait.LeftArm) return zombieLeftArmTrait(level, traitNumber);
        else if(trait == ZombieTrait.RightArm) return zombieRightArmTrait(level, traitNumber);
        else if(trait == ZombieTrait.Legs) return zombieLegsTrait(level, traitNumber);
        else if(trait == ZombieTrait.Head) return zombieHeadTrait(level, traitNumber);
        else return "None";
    }

    function zombieSVG(uint8 level, uint8[] memory traits) external pure returns (bytes memory) {
        string memory torsoSVG = zombieTorsoSVG(level, traits[0]);
        string memory leftArmSVG = zombieTorsoSVG(level, traits[1]);
        string memory rightArmSVG = zombieTorsoSVG(level, traits[2]);
        string memory legsSVG = zombieTorsoSVG(level, traits[3]);
        string memory headSVG = zombieTorsoSVG(level, traits[4]);

        return bytes(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 7 8" shape-rendering="crispEdges">',
                torsoSVG,
                leftArmSVG,
                rightArmSVG,
                legsSVG,
                headSVG,
                '</svg>'
            )
        );
    }
}
// File: base/Base64.sol



pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
// File: metadata/MetadataFactory.sol






pragma solidity ^0.8.0;

/// @title MetadataFactory
/// @author Elmontos
/// @notice Provides metadata utility functions for creation
library MetadataFactory {
    
    struct nftMetadata {
        uint8 nftType;//0->Zombie 1->Survivor
        uint8[] traits;
        uint8 level;
    //    uint nftCreationTime;
        bool canClaim;
        uint stakedTime;
        uint lastClaimTime;
    }

    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) public pure returns(nftMetadata memory) {
        nftMetadata memory nft;
        nft.nftType = nftType;
        nft.traits = traits;
        nft.level = level;
        nft.canClaim = canClaim;
        nft.stakedTime = stakedTime;
        nft.lastClaimTime = lastClaimTime;
        return nft;
    }

    function buildMetadata(MetadataFactory.nftMetadata memory nft, bool survivor) public pure returns(string memory) {

        if(survivor) {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(survivorMetadataBytes(nft))));
        } else {
            return string(abi.encodePacked(
                    'data:application/json;base64,', Base64.encode(zombieMetadataBytes(nft))));
        }
    }

    function createRandomMetadata(uint8 level, uint8 tokenType) public pure returns(nftMetadata memory) {

        uint8[] memory traits;
        bool canClaim;
        uint stakedTime;
        uint lastClaimTime;
        //uint8 nftType = 0;//implement random here between 0 and 1

        if(tokenType == 0) {
            (traits, level, canClaim, stakedTime, lastClaimTime) = createRandomZombie(level);
        } else {
            (traits, level, canClaim, stakedTime, lastClaimTime) = createRandomSurvivor(level);
        }

        return constructNft(tokenType, traits, level, canClaim, stakedTime, lastClaimTime);
    }

    function createRandomZombie(uint8 level) public pure returns(uint8[] memory, uint8, bool, uint, uint) {
        return (
            randomZombieTraits(level),
            level,
            false,
            0,
            0
        );
    }

    function randomZombieTraits(uint8 level) public pure returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](5);

        uint8 torsoTrait = 0; //random number between 1 and ZombieMetadata.zombieTorsoTraitCount(level)
        traits[0] = torsoTrait;
        uint8 leftArmTrait = 0; //random number between 1 and ZombieMetadata.zombieLeftArmTraitCount(level)
        traits[1] = leftArmTrait;
        uint8 rightArmTrait = 0; //random number between 1 and ZombieMetadata.zombieRightArmTraitCount(level)
        traits[2] = rightArmTrait;
        uint8 legsTrait = 0; //random number between 1 and ZombieMetadata.zombieLegsTraitCount(level)
        traits[3] = legsTrait;
        uint8 headTrait = 0; //random number between 1 and ZombieMetadata.zombieHeadTraitCount(level)
        traits[4] = headTrait;

        return traits;
    }

    function createRandomSurvivor(uint8 level) public pure returns(uint8[] memory, uint8, bool, uint, uint) {
        return (
            randomSurvivorTraits(level),
            level,
            false,
            0,
            0
        );
   }

   function randomSurvivorTraits(uint8 level) public pure returns(uint8[] memory) {
       uint8[] memory traits = new uint8[](12);

        uint8 shoesTrait = 0; //random number between 1 and ZombieMetadata.survivorShoesTraitCount()
        traits[0] = shoesTrait;
        uint8 pantsTrait = 0; //random number between 1 and ZombieMetadata.survivorPantsTraitCount()
        traits[1] = pantsTrait;
        uint8 bodyTrait = 0; //random number between 1 and ZombieMetadata.survivorBodyTraitCount()
        traits[2] = bodyTrait;
        uint8 beardTrait = 0; //random number between 1 and ZombieMetadata.survivorBeardTraitCount()
        traits[3] = beardTrait;
        uint8 hairTrait = 0; //random number between 1 and ZombieMetadata.survivorHairTraitCount()
        traits[4] = hairTrait;
        uint8 headTrait = 0; //random number between 1 and ZombieMetadata.survivorHeadTraitCount()
        traits[5] = headTrait;
        uint8 shirtTrait = 0; //random number between 1 and ZombieMetadata.survivorShirtTraitCount()
        traits[6] = shirtTrait;

        uint8 chestArmorTrait = 0; //random number between 1 and ZombieMetadata.survivorChestArmorTraitCount(level)
        traits[7] = chestArmorTrait;
        uint8 shoulderArmorTrait = 0; //random number between 1 and ZombieMetadata.survivorShoulderArmorTraitCount(level)
        traits[8] = shoulderArmorTrait;
        uint8 legArmorTrait = 0; //random number between 1 and ZombieMetadata.survivorLegArmorTraitCount(level)
        traits[9] = legArmorTrait;
        uint8 rightWeaponTrait = 0; //random number between 1 and ZombieMetadata.survivorRightWeaponTraitCount(level)
        traits[10] = rightWeaponTrait;
        uint8 leftWeaponTrait = 0; //random number between 1 and ZombieMetadata.survivorLeftWeaponTraitCount(level)
        traits[11] = leftWeaponTrait;
        
        return traits;
   }

   function survivorMetadataBytes(nftMetadata memory survivor) public pure returns(bytes memory) {

        return bytes(
            abi.encodePacked(
                '{"type":"',
                'human',
                '", "level":"',
                survivor.level,
                survivorTraitsMetadata(survivor), //split out otherwise too many local variables for stack to support, stack too deep error
                '", "image": "',
                'data:image/svg+xml;base64,',
                Base64.encode(SurvivorFactory.survivorSVG(survivor.level, survivor.traits)),
                '"}'
            )
        );
    }

    function survivorTraitsMetadata(nftMetadata memory survivor) public pure returns(string memory) {

        string memory traits1;
        string memory traits2;

        {
            traits1 = string(abi.encodePacked(
                '", "shoes":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Shoes, survivor.level, survivor.traits[0]),
                '", "pants":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Pants, survivor.level, survivor.traits[1]),
                '", "body":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Body, survivor.level, survivor.traits[2]),
                '", "beard":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Beard, survivor.level, survivor.traits[3]),
                '", "hair":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Hair, survivor.level, survivor.traits[4]),
                '", "head":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Head, survivor.level, survivor.traits[5])
            ));
        }

        {
            traits2 = string(abi.encodePacked(
                '", "shirt":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.Shirt, survivor.level, survivor.traits[6]),
                '", "chest armor":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.ChestArmor, survivor.level, survivor.traits[7]),
                '", "shoulder armor":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.ShoulderArmor, survivor.level, survivor.traits[8]),
                '", "leg armor":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.LegArmor, survivor.level, survivor.traits[9]),
                '", "right weapon":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.RightWeapon, survivor.level, survivor.traits[10]),
                '", "left weapon":"',
                SurvivorFactory.survivorTrait(SurvivorFactory.SurvivorTrait.LeftWeapon, survivor.level, survivor.traits[11])
            ));
        }

        return string(abi.encodePacked(traits1, traits2));
    }

    function zombieMetadataBytes(nftMetadata memory zombie) public pure returns(bytes memory) {
        return bytes(
            abi.encodePacked(
                '{"type":"',
                'zombie',
                '", "level":"',
                zombie.level,
                '", "torso":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.Torso, zombie.level, zombie.traits[0]),
                '", "left arm":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.LeftArm, zombie.level, zombie.traits[1]),
                '", "right arm":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.RightArm, zombie.level, zombie.traits[2]),
                '", "legs":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.Legs, zombie.level, zombie.traits[3]),
                '", "head":"',
                ZombieMetadata.zombieTrait(ZombieMetadata.ZombieTrait.Head, zombie.level, zombie.traits[4]),
                '", "image": "',
                'data:image/svg+xml;base64,',
                Base64.encode(ZombieMetadata.zombieSVG(zombie.level, zombie.traits)),
                '"}'
            )
        );
    }
    
}
// File: base/Context.sol



pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: base/ERC721.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint) private _balances;

    // Mapping from token ID to approved address
    mapping(uint => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
    function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint tokenId) public virtual override {
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
    function getApproved(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        uint tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint tokenId)
    internal
    view
    virtual
    returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint tokenId,
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
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

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
    function _burn(uint tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
        uint tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                    "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
        uint tokenId
    ) internal virtual {}
}

// File: base/ERC721Enumerable.sol



pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint => uint)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint => uint) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint => uint) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721)
    returns (bool)
    {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint tokenId) private {
        uint length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint tokenId)
    private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = _allTokens.length - 1;
        uint tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
// File: base/Ownable.sol




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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: TestContracts/testnftFactory.sol



pragma solidity ^0.8.0;









contract testNftFactory is Ownable, ERC721Enumerable{
    using Strings for uint;


    //NFTs
    MetadataFactory.nftMetadata[] public nfts;
    mapping (uint => address) public tokenOwner;

    //sales
    uint public HungerBrainz_MAX_COUNT = 40000; //maxSupply

    //todo place the finalised price
    // To-change -> from 0 eth to 0.067 eth
    uint public HungerBrainz_MAINSALE_PRICE = 0 ether; //priceInMainSale
    GameEngine game;
    IERC20 SUP;

    mapping (address => uint) public saleListPurchase;

    function setContract(address _gameAddress, address _tokenAddress) external onlyOwner {
        game = GameEngine(_gameAddress);
        SUP = IERC20(_tokenAddress);
    }
    //todo : we need to change this baseURI

    string private _tokenBaseURI = "https://gateway.pinata.cloud/ipfs/QmNNmN2JGayxRk3hwEWw5gMCUyfmikgosrAQuCWnc9tDdN/";
    bool public saleLive;
    bool public locked;

    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    constructor() ERC721("HungerBrainz", "hungerbrainz") {}

    function setHungerBrainz_MAX_COUNT(uint _maxCount) external onlyOwner{
        HungerBrainz_MAX_COUNT = _maxCount;
    }

    function burnNFT(uint tokenId) override external {
        _burn(tokenId);
    }
//mint&Stake mintUsingSUP
    uint public totalSup;
    function buy (uint8 tokenType, bool stake, bool mintOnlyUsingSUP) external payable {
        require(tokenType == 0 || tokenType == 1);
        require(totalSupply() == nfts.length); //must be the same length, else minting miscount
        uint id = totalSupply();
        if (!stake && !mintOnlyUsingSUP && totalSupply() < 10000) {
            require (HungerBrainz_MAINSALE_PRICE <= msg.value, "INSUFFICIENT_ETH");
            _safeMint(msg.sender,  totalSupply()+1);
            totalSup = id;
            nfts.push(MetadataFactory.createRandomMetadata(1,tokenType));
            //     createNFTStruct(1,tokenType);
            tokenOwner[totalSupply()]=msg.sender;
        }
        //mint&stake
        else if (stake && !mintOnlyUsingSUP){
            SUP.transferFrom(_msgSender(), address(this), 0.0000006 ether);
            SUP.burn(0.0000006 ether);
            _safeMint(address(game), totalSupply()+1);
            nfts.push(MetadataFactory.createRandomMetadata(1,tokenType));
         //   createNFTStruct(1,tokenType);
            game.alertStake(totalSupply(), tokenType);
            tokenOwner[totalSupply()]=msg.sender;
        }
        //mintUsingSUP
        else if (!stake && mintOnlyUsingSUP) {
            SUP.transferFrom(_msgSender(), address(this), 0.0000006 ether);
            SUP.burn(0.0000006 ether);
            _safeMint(msg.sender, totalSupply()+1 );
            nfts.push(MetadataFactory.createRandomMetadata(1,tokenType));
          //    createNFTStruct(1,tokenType);
            tokenOwner[totalSupply()]=msg.sender;
        }
    }

    function tokenOwnerCall(uint tokenId) external view override returns (address) {
        return tokenOwner[tokenId];
    }


    function withdraw() external {
        uint balance = address(this).balance;
        require(balance > 0);
        payable(owner()).transfer(address(this).balance);
    }

    function toggleSaleStatus() external onlyOwner{
        saleLive = !saleLive;
    }

    function setBaseURI(string calldata URI) external notLocked onlyOwner{
        _tokenBaseURI = URI;
    }

    // function createNFTStruct (uint8 level, uint8 types) internal {
    //   //  nfts.push(nftMetadata(types,0,level,false,block.timestamp,0,0));
    // }   //todo remove this creative function or use it in someway

    //    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) internal pure returns(nftMetadata memory) {
    //        nftMetadata memory nft;
    //        nft.nftType = nftType;
    //        nft.traits = traits;
    //        nft.level = level;
    //        nft.canClaim = canClaim;
    //        nft.stakedTime = stakedTime;
    //        nft.lastClaimTime = lastClaimTime;
    //        return nft;
    //
    //    }

        function restrictedChangeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) external override {
            require(msg.sender == address(game),"Call restricted");
            changeNft(tokenID,nftType,level,canClaim,stakedTime,lastClaimTime);
        }

        function changeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) internal {
            require(_exists(tokenID), "Cannot change");

            MetadataFactory.nftMetadata memory original = nfts[tokenID];

            if(original.level != level || original.nftType != nftType) { //only recreate metadata if level changes or type changes
                uint8[] memory traits;
                if(nftType == 0) {
                    (traits,,,,) = MetadataFactory.createRandomZombie(level);
                } else {
                    (traits,,,,) = MetadataFactory.createRandomSurvivor(level);
                }
                nfts[tokenID] = MetadataFactory.constructNft(nftType, traits, level, canClaim, stakedTime, lastClaimTime);
            } else {
                //Level and type have not changed, change everything else
                original.canClaim = canClaim;
                original.stakedTime = stakedTime;
                original.lastClaimTime = lastClaimTime;
                nfts[tokenID] = original;
            }
        }

    function getNft(uint256 _tokenId) internal view returns(MetadataFactory.nftMetadata memory) {
        return nfts[_tokenId - 1];
    }

    function setNft(uint256 _tokenId, MetadataFactory.nftMetadata memory metadata) internal {
        nfts[_tokenId - 1] = metadata;
    }

    //STRUCT giving out info of the NFT, view function only, input token ID
    function getToken(uint256 _tokenId) external override view returns(uint8, uint8, bool, uint,uint, uint) {
        return (
        getNft(_tokenId).nftType,
        getNft(_tokenId).level,
        getNft(_tokenId).canClaim,
        getNft(_tokenId).stakedTime,
        getNft(_tokenId).stakedTime,
        getNft(_tokenId).lastClaimTime) ;
    }//todo toinsert creationTimeInHere at position 4

    //When steal happens, we must change metadata, internal function only
    function changeToken(uint256 _tokenId, MetadataFactory.nftMetadata memory metadata) internal {
        setNft(_tokenId, metadata);
    }

    function isSurvivor(uint256 _tokenId) internal view returns(bool) {
        return (getNft(_tokenId).nftType == 1);
    }
       
    //#endregion

    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        MetadataFactory.nftMetadata memory nft = getNft(tokenId);
        return MetadataFactory.buildMetadata(nft, isSurvivor(tokenId));
    }
}