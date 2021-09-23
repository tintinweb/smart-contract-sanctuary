/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT
 
 
// File: contracts/Gen.sol



pragma solidity ^0.8.7;

 
 
contract Gen {

    

    // MAPPINGS //    
    mapping(string => uint) internal charsMap; // maps characters to numbers for easier access in 'generateWord()' function
    mapping(uint => uint) internal tokenIdToSeed; // initial seed for each tokenId minted
    mapping(uint => uint[8]) internal tokenIdToShuffleShift; // tokenId => array of inexes for words to be shifted as a result of shuffling
    mapping(uint => uint) internal shuffleCount; // tokenId => number of shuffles tokenId has had
    mapping(address => bool) internal hasClaimed; // keeps track of addresses that have claimed a mint
    

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
    
    
    // VARIABLES //
    
    
    uint16[297] ps = [
        1000, 1889, 2889, 3556, 5223, 6223, 7334, 8778, 9334, 9556, 10000,
        381, 952, 1428, 1809, 2761, 4856, 6094, 7523, 9523, 9809, 10000,
        198, 792, 1584, 2079, 2574, 3267, 3366, 5643, 7029, 9900, 10000,
        714, 1071, 1607, 2232, 2945, 4285, 5178, 6516, 7856, 9195, 10000,
        385, 1348, 3467, 5201, 6163, 7127, 9824, 9920, 9939, 9958, 10000,
        135, 405, 1081, 1216, 1892, 2703, 4325, 5541, 7568, 9730, 10000,
        2443, 2932, 3421, 3910, 4561, 5212, 6677, 8470, 9936, 9985, 10000,
        1239, 1770, 2655, 4071, 5310, 6726, 7257, 9912, 9947, 9982, 10000,
        268, 281, 294, 328, 1668, 4751, 7432, 9979, 9986, 9993, 10000,
        291, 679, 1164, 1649, 2329, 3106, 3689, 4951, 6504, 9708, 10000,
        353, 706, 1923, 3510, 5097, 7672, 8818, 9964, 9982, 9991, 10000, 
        755, 1227, 1416, 1605, 1888, 2077, 2171, 3114, 9246, 9812, 10000,
        695, 721, 747, 834, 851, 3023, 5195, 6846, 9974, 9991, 10000,
        103, 308, 513, 821, 1437, 2566, 3901, 7289, 9958, 9979, 10000,
        294, 588, 735, 750, 1337, 2071, 2805, 4127, 6183, 8239, 10000,
        88, 1148, 2561, 2738, 3975, 4682, 4859, 5389, 7156, 9983, 10000,
        325, 760, 1303, 1629, 1955, 3367, 4670, 6624, 8253, 9990, 10000,
        4955, 9910, 9920, 9930, 9940, 9950, 9960, 9970, 9980, 9990, 10000,
        214, 428, 641, 663, 1197, 1411, 1454, 2522, 3590, 4658, 10000,
        196, 784, 2548, 3332, 4312, 5488, 7644, 9800, 9996, 9998, 10000,
        475, 1424, 1661, 2848, 4272, 5933, 8544, 9256, 9968, 9992, 10000,
        515, 618, 1133, 1442, 2267, 3298, 4947, 6493, 7730, 9483, 10000,
        202, 1412, 3025, 5444, 7662, 9880, 9920, 9940, 9960, 9980, 10000,
        23, 252, 480, 2657, 2886, 4719, 7354, 9645, 9874, 9885, 10000,
        433, 866, 1732, 3464, 5195, 8659, 9525, 9698, 9871, 9958, 10000,
        601, 901, 1502, 2103, 3605, 4806, 6007, 9010, 9310, 9400, 10000,
        204, 511, 613, 714, 1737, 3782, 9917, 9968, 9978, 9988, 10000];
    


    string[] nextChars = [
        "fbrwsaltpzj",
        "gmldslrtnkb",
        "blriiluoaey",
        "rliktauhooe",
        "ruaoiiegfws",
        "mfteladsnrg",
        "luaarreioyw",
        "luiraohezgy",
        "urryoiaejlw",
        "gredlocstnb",
        "iieaaouuytf",
        "aollarsieut",
        "ussdyoaielf",
        "smmupioaeyn",
        "aauyiosetgd",
        "zolwtmfurny",
        "tupiilaores",
        "uuaeiosrfyw",
        "nudytslaioe",
        "puhaoietwyq",
        "usraieohhty",
        "ebgzplsntrm",
        "uoaieeyvxrl",
        "snnoheaiuyr",
        "oaueeityxth",
        "lmaiseeouvx",
        "uyooiaelzrl"];

    

    
    /**
     * @dev Maps characters in 'chars' to numbers for easier comparison in 'generateWord()' function
     */
    function mapChars() internal {
        string[27] memory chars = [" ", "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"];
        for (uint i=0; i<27; i++) {
            charsMap[chars[i]] = i;
        }
    }

    
    /**
     * @dev Returns length of a string '_string'.
     */
    function stringLength(string memory _string) internal pure returns(uint) {
        return bytes(_string).length;
    }

    
    /**
     * @dev Gets character from 'nextChars'.
     */
    function getChar(uint row, uint col) internal view returns(string memory) {
        bytes memory line = bytes(nextChars[row]);
        string memory temp = new string(1);
        bytes memory output = bytes(temp);
        output[0] = line[col];
        return string(output); 
    }
    
    
    
    /**
     * @dev Generates word length (1-16) using a distribution
     */
    function determineWordLength(uint rand) internal pure returns(uint) {
        
        uint16[16] memory cumulativeDistribution = [2,99,761,1929,3175,4694,6291,7654,8744,9328,9678,9872,9938,9976,9991,10000];
        
        uint i = 0;
        while (i <= 15) { 
            if (rand <= cumulativeDistribution[i]) {
                break;
            }
            i++;
        }
        return i+1;  // returns word length
    }
    
    
    
    /**
     * @dev Generates a random word of length 1-16, given a '_tokenId' and '_totalSeed' as a seed of randomness
     */
    function generateWord(uint256 _tokenId, uint _totalSeed) internal view returns(string memory) { // change visibility

        require(_tokenId >= 1 && _tokenId <= 10000, "Invalid tokenId.");

        string memory word;
        string memory char;
        
        uint lengthRand = (uint(keccak256(abi.encodePacked(_tokenId, _totalSeed)))% 10000); // gets random number between 0 and 10,000
        uint rand = (uint(keccak256(abi.encodePacked(_tokenId, lengthRand, _totalSeed)))% 10000) + 1; // gets random number between 1 and 10,000

        // generates word
        for (uint n=1; n <= determineWordLength(lengthRand); n++) {
            
            // generates letter
            uint i = 0;
            while (i < 11) { // indexStart of ps[] to indexEnd
                if (rand <= ps[(charsMap[char]*11)+i]) {
                    break;
                }
                i++;
            }
            char = getChar(charsMap[char], i);
            
            word = string(abi.encodePacked(word, char)); // appends letter to word
            rand = (uint(keccak256(abi.encodePacked(_tokenId, rand, word, n, _totalSeed)))% 10000) + 1; // gets new random number between 1 and 10,000
        }
        return word;
    }
    
    
}

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol



pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}


// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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



// File: @openzeppelin/contracts/access/Ownable.sol



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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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


// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

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


// File: @openzeppelin/contracts/utils/Address.sol



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


// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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


// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



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
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}





// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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

// File: contracts/Lootlang.sol



pragma solidity ^0.8.7;



// IMPORTS //

/**
 * @dev ERC721 token standard
 */


/**
 * @dev Modifier 'onlyOwner' becomes available where owner is the contract deployer
 */


/**
 * @dev Verification of Merkle trees
 */


/**
 * @dev Generates words etc
 */



// LIBRARIES //

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}






//  CONTRACT //  

contract Lootlang is ERC721, Ownable, Gen {
    
    
    // VARIABLES //
    
    uint public enabled;
    uint internal mints; 
    uint internal claims; 
    uint internal nextTokenId;
    uint public contractBalance;
    string internal contractURIstring;
    uint public freezeBlock;
    uint internal freezeBlockChanges;
    bytes32 internal root;

    
    constructor() Ownable() ERC721('Lootlang', 'LANG') {

        nextTokenId = 1;
        
        freezeBlock = 13487654;
        
        contractURIstring = "https://lootlang.com/metadata.json";
        
        mapChars(); // maps characters to uints
        
    }


    // EVENTS //
    
    event Shuffled(uint tokenId);



    // ONLY OWNER FUNCTIONS //
    
    /**
     * @dev Set the root for Merkle Proof
     */
    function setRoot(bytes32 _newRoot) external onlyOwner {
        root = _newRoot;
    }
    
    
    /**
     * @dev Set the new block number to freeze shuffling. Can only be called once.
     */
    function setFreezeBlock(uint _newFreezeBlockNumber) external onlyOwner {
        require(freezeBlockChanges < 1, "Freeze block already changed");
        freezeBlock = _newFreezeBlockNumber;
        freezeBlockChanges++;
    }
    

    /**
     * @dev Withdraw '_amount' of Ether to address '_to'. Only contract owner can call.
     * @param _to - address Ether will be sent to
     * @param _amount - amount of Ether, in Wei, to be withdrawn
     */
    function withdrawFunds(address payable _to, uint _amount) external onlyOwner {
        require(_amount <= contractBalance, "Withdrawal amount greater than balance");
        contractBalance -= _amount;
        _to.transfer(_amount);
    }


    /**
     * @dev activates/deactivates the minting functionality - only the contract owner can call
     * @param _enabled where 1 = enabled and 0 = not
     */
    function setEnable(uint _enabled) external onlyOwner {
        enabled = _enabled;
    }
    
    
    /**
     * @dev Set the contract's URI
     * @param _contractURIstring - web address containing data read by OpenSea
     */
    function setContractURI(string memory _contractURIstring) external onlyOwner {
        contractURIstring = _contractURIstring;
    }
    

    // USER FUNCTIONS // 
    

    /**
     * @dev Mint an ERC721 token. 
     */
    function mint() external payable {
        require(enabled == 1, "Minting is yet to be enabled");
        require(nextTokenId <= 10000 && mints <= 9700, "All NFTs have been minted");
        require(msg.value >= (2*10**16), "Insufficient funds provided"); // 0.02 eth (cost of minting an NFT) // SET MINT PRICE

        mints++;
        contractBalance += msg.value;
        sharedMintCode();
    }
    
    /**
     * @dev Claim and mint an ERC721 token.
     */
    function claim(bytes32[] memory proof) external { 
        require(enabled == 1, "Minting is yet to be enabled");
        require(hasClaimed[msg.sender] == false, "Already claimed");
        require(nextTokenId <= 10000 && claims <= 300, "All NFTs have been minted");

        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))) == true, "Not on pre-approved claim list");

        claims++;
        hasClaimed[msg.sender] = true;
        sharedMintCode();
    }
    
    /**
     * @dev Shared code used by both 'mint()' and 'claim()' functions.
     */
    function sharedMintCode() internal {
        uint tokenId = nextTokenId;
        nextTokenId++;
        tokenIdToSeed[tokenId] = uint(keccak256(abi.encodePacked(tokenId, msg.sender, block.timestamp)))%1000000;
        _safeMint(msg.sender, tokenId);
    }


    /**
     * @dev Shuffles up to 8 words. Set input params as 1 to shuffle word, and 0 to leave it. 
     *      E.g. shuffle(243,1,0,0,0,0,0,0,1) shuffles the 1st and 8th word of token 243.
     */
    function shuffle(uint _tokenId, uint one, uint two, uint three, uint four, uint five, uint six, uint seven, uint eight) external {
        require(ownerOf(_tokenId) == msg.sender, "Must be NFT owner");
        require(shuffleCount[_tokenId] < 5, "Shuffled max amount already");
        require(block.number < freezeBlock, "Shuffling has been frozen!");
        require((one+two+three+four+five+six+seven+eight) > 0, "No words selected to be shuffled"); 
       
        uint randomish = uint(keccak256(abi.encodePacked(block.number)))%1000000;
        uint[8] memory indexesToChange = [one, two, three, four, five, six, seven, eight];
        
        for (uint i=0; i<8; i++) {
            if (indexesToChange[i] > 0) {
                tokenIdToShuffleShift[_tokenId][i] += randomish;
            }
        }
        
        shuffleCount[_tokenId]++;
        emit Shuffled(_tokenId);
    }
    



    // VIEW FUNCTIONS //
    
    
    /**
     * @dev View total number of minted tokens
     */
    function totalSupply() external view returns(uint) {
        return mints+claims;
    }
    
    /**
     * @dev View the contract URI.
     */
    function contractURI() public view returns (string memory) {
        return contractURIstring;
    }

    /**
     * @dev Internal function used by function 'tokenURI()' to format word lengths for .json file output
     */
    function getMetaText(string memory word) internal pure returns(string memory) {
        string memory length = string(abi.encodePacked("\"", toString(stringLength(word)), " letters", "\""));
        return length;
    }
    
    /**
     * @dev Internal function used by function 'tokenURI()' to format words for .json file output
     */
    function getMetaWord(string memory word) internal pure returns(string memory) {
        string memory length = string(abi.encodePacked("\"", word, "\""));
        return length;
    }
    
    /**
     * @dev Creates seed passed in to 'generateWord()' function for seeding randomness
     */
    function totalSeedGen(uint tokenId, uint wordNum) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(uint(wordNum), tokenIdToSeed[tokenId], tokenIdToShuffleShift[tokenId][wordNum-1])));
    }
    
    /**
     * @dev View tokenURI of 'tokenId'. 
     */
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        
        require(_exists(tokenId), "URI query for nonexistent token");

        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 20px; }</style><rect width="100%" height="100%" fill="black" /><text x="15" y="30" class="base">';
        parts[1] = generateWord(tokenId, totalSeedGen(tokenId, 1));
        parts[2] = '</text><text x="15" y="65" class="base">';
        parts[3] = generateWord(tokenId, totalSeedGen(tokenId, 2));
        parts[4] = '</text><text x="15" y="100" class="base">';
        parts[5] = generateWord(tokenId, totalSeedGen(tokenId, 3));
        parts[6] = '</text><text x="15" y="135" class="base">';
        parts[7] = generateWord(tokenId, totalSeedGen(tokenId, 4));
        parts[8] = '</text><text x="15" y="170" class="base">';
        parts[9] = generateWord(tokenId, totalSeedGen(tokenId, 5));
        parts[10] = '</text><text x="15" y="205" class="base">';
        parts[11] = generateWord(tokenId, totalSeedGen(tokenId, 6));
        parts[12] = '</text><text x="15" y="240" class="base">';
        parts[13] = generateWord(tokenId, totalSeedGen(tokenId, 7));
        parts[14] = '</text><text x="15" y="275" class="base">';
        parts[15] = generateWord(tokenId, totalSeedGen(tokenId, 8));
        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = string(abi.encodePacked('{"name": "Pack #', toString(tokenId), '", "description": "Pack of 8 Lootlang words", "attributes": [{"trait_type": "Shuffles Used", "value":', getMetaWord(toString(shuffleCount[tokenId])), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[1]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[3]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[5]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[7]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[9]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[11]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[13]), '}, {"trait_type": "Word Length", "value":', getMetaText(parts[15]), '}'));
        json = Base64.encode(bytes(string(abi.encodePacked(json, ', {"trait_type": "Word", "value":', getMetaWord(parts[1]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[3]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[5]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[7]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[9]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[11]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[13]), '}, {"trait_type": "Word", "value":', getMetaWord(parts[15]), '}], "image": "data:image/svg+xml;base64, ', Base64.encode(bytes(output)), '"}'))));
        
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    

}