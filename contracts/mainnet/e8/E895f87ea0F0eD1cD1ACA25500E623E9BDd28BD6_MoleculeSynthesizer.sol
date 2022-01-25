// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./MoleculeScripter.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title ChemScripts Contract
/// @notice interface to get ElementBlocks owner addresses
interface ElementBlocksInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

/*
   ___ _  _ ___ __  __ ___  ___ ___ ___ ___ _____ ___
  / __| || | __|  \/  / __|/ __| _ \_ _| _ \_   _/ __|
 | (__| __ | _|| |\/| \__ \ (__|   /| ||  _/ | | \__ \
  \___|_||_|___|_|  |_|___/\___|_|_\___|_|   |_| |___/

  This is an ode to the scientific and technological progress humanity has made.

  It is also a reminder of the importance of freedom and the decentralization of
  power.

  The contract allows creators to store generative art scripts that
  turn chemical molecules into artworks.

  Every molecule that has been discovered so far can be minted.

  Use this experimental software at your own risk.

*/


contract MoleculeSynthesizer is MoleculeScripter, ERC721 {

  ////////////////////////////////////////////////////////////////////////////////////////
  // SETUP                                                                              //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice initiates the ElementBlocks contract
  ElementBlocksInterface elementBlocksContract;

  /// @notice sets up the token name, tracker and the ElementBlocks contract address
  constructor(address _elementsContract) ERC721("ChemScripts", "CHEMS") {
      elementBlocksContract = ElementBlocksInterface(_elementsContract);
  }

  /// @notice element short names to ElementBlocks tokenIDs
  mapping (string => uint) public elementToId;

  /// @notice allows contract owner to set the element's tokenIDs
  function setElementId (string memory _element, uint _elementId) public onlyOwner {
    elementToId[_element] = _elementId;
  }

  /// @notice gets element tokenIDs
  function getElementId (string memory _element) public view returns(uint) {
    return elementToId[_element];
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  // ERC721 MAGIC                                                                       //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice apiURI stores the base URI to which the tokenID can be added for tokenURI
  string public apiURI;

  /// @notice contract owner can set and change the apiURI
  function setApiURI(string memory _apiURI) external onlyOwner {
      apiURI = _apiURI;
  }

  /// @notice returns the apiURI
  function _baseURI() internal view virtual override returns (string memory) {
    return apiURI;
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  // NFT CHEMISTRY                                                                      //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice event is emitted when a new molecule gets minted
  event NewMolecule(uint indexed moleculeId, string formula, string indexed key, string name, uint16 indexed scriptId);

  /// @notice stores molecule information
  /// @param formula is in InChI (international chemical Identifier) format
  /// @param key is a unique hash for each molecule
  /// @param name must be one of the molecules official names
  /// @param scriptId links to the generative art script that visualizes the molecule
  struct Molecule {
    string formula;
    string key;
    string name;
    uint16 scriptId;
  }

  /// @notice tokenIds to molecules
  mapping (uint => Molecule) public molecules;

  /// @notice keys to tokenIDs
  mapping (string => uint) public keys;

  /// @notice ensures that each molecule can only exist once per script
  function moleculeChecker (uint16 _scriptId, string memory _key) public view {
    if (keys[_key] > 0) {
      require(molecules[keys[_key]-1].scriptId != _scriptId, "molecule already minted");
    }
  }

  /// @notice mints an ERC721 token and ties it to the molecule
  /// @param _formula requires everything after "InChI=" to at least one letter after the second slash
  function _createMolecule(
    string memory _formula,
    string memory _key,
    string memory _name,
    uint16 _scriptId
    ) internal mintableScript(_scriptId) returns (uint) {
          moleculeChecker(_scriptId, _key);
          uint id = _scriptId * 100000 + scripts[_scriptId].currentSupply;
          _safeMint(msg.sender, id);
          molecules[id] = Molecule(_formula, _key, _name, _scriptId);
          keys[_key] = id+1;
          scripts[_scriptId].currentSupply++;
          emit NewMolecule(id, _formula, _key, _name, _scriptId);
          return id;
      }

  /// @notice allows contract owner to re-assign wrong molecules when script not yet sealed
  function chemPolice(
    uint _moleculeId,
    string memory _formula,
    string memory _key,
    string memory _name) notSealed(molecules[_moleculeId].scriptId) onlyOwner external {
      Molecule storage wrongMolecule = molecules[_moleculeId];
      wrongMolecule.formula = _formula;
      wrongMolecule.key = _key;
      wrongMolecule.name = _name;
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  // MINTING & ROYALTIES                                                                //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice elementPercentage percentage that gets send to ElementBlocks holders
  uint public elementPercentage = 50;

  /// @notice allows contract owner to set percentage that flows to element holders
  function elementSetup(uint _elementPercentage) external onlyOwner {
    elementPercentage = _elementPercentage;
  }

  /// @notice element that currently gets the general royalties
  uint public royaltyHoldingElement = 1;

  /// @notice increments the royaltyHoldingElement and accounts for non-existent tokens
  function _nextRoyaltyHolder() internal {
    royaltyHoldingElement++;
    if (royaltyHoldingElement == 101) {
      royaltyHoldingElement++;
    } else if (royaltyHoldingElement == 107) {
      royaltyHoldingElement ++;
    } else if (royaltyHoldingElement == 121) {
      royaltyHoldingElement = 1;
    }
  }

  /// @notice gets current price and enables dutch auctions
  function getPrice(uint _scriptId) view public returns(uint) {
    uint duration = uint256(scripts[_scriptId].saleDuration) * 1 hours;
    if (!scripts[_scriptId].publicSale && !scripts[_scriptId].whitelistSale) {
      return 0; // allows creator and owner to test mint for free before the sale starts
    } else if ((block.timestamp - startingTime[_scriptId]) >= duration) {
      return scripts[_scriptId].endPrice;
    } else {
      return ((duration - (block.timestamp - startingTime[_scriptId])) * ((scripts[_scriptId].startPrice - scripts[_scriptId].endPrice)  / duration) + scripts[_scriptId].endPrice);
    }
  }

  /// @notice distributes funds from minting to script creator and ElementBlock holders
  function _distributeFunds(uint _scriptId, string memory _formula, uint _numberOfElements) internal {
    if (msg.value > 0) {

      // script creator funds
      payable(scripts[_scriptId].creator).send(
        (msg.value - (msg.value*elementPercentage/100))
      );

      // specific elements royalties
      uint[] memory elementIds = formulaToElementIds(_formula, _numberOfElements);
      uint fundsPerElement = msg.value*elementPercentage/2/elementIds.length/100;
      for (uint i = 0; i < elementIds.length; i++) {
        payable(elementBlocksContract.ownerOf(elementIds[i])).send(fundsPerElement);
      }

      // general element royalties
      payable(elementBlocksContract.ownerOf(royaltyHoldingElement)).send(msg.value*elementPercentage/2/100);
      _nextRoyaltyHolder();

    }
  }

  /// @notice returns tokenIds from all elements in a formula
  function formulaToElementIds(string memory _formula, uint _numberOfElements) public view returns(uint[] memory) {
    uint[] memory elementIds = new uint[](_numberOfElements);
    uint slashCounter = 0;
    uint elementsFound = 0;
    bytes memory moleculeBytes = bytes(_formula);

    for (uint i=1; i<moleculeBytes.length; i++) {
      if (bytes1("/") == moleculeBytes[i-1]) {
        slashCounter++;
      }

      if (slashCounter == 2) {
        if (_numberOfElements != elementsFound) {
          revert("Wrong elements nr");
        }
        return elementIds;
      }

      if (slashCounter > 0) {
        string memory oneLetter = string(abi.encodePacked(moleculeBytes[i-1]));
        string memory twoLetters = string(abi.encodePacked(oneLetter, abi.encodePacked(moleculeBytes[i])));
        if (elementToId[twoLetters] > 0) {
          uint element = elementToId[twoLetters];
          elementIds[elementsFound] = element;
          elementsFound++;
        } else if (elementToId[oneLetter] > 0) {
          uint element = elementToId[oneLetter];
          elementIds[elementsFound] = element;
          elementsFound++;

        }
      }
    }

    revert("Wrong formula");

  }

  /// @notice mints a molecule
  /// @param _numberOfElements is the number of different elements in the formula
  /// @dev set the _numberOfElements to how often the element's letters occur in formula
  function mintMolecule(
    string memory _formula,
    string memory _key,
    string memory _name,
    uint16 _scriptId,
    uint _numberOfElements
    ) public payable {
      require(msg.value >= getPrice(_scriptId), "Insufficient funds");
      require(scripts[_scriptId].publicSale || msg.sender == scripts[_scriptId].creator || msg.sender == owner(), "No public sale");
      _distributeFunds(_scriptId, _formula, _numberOfElements);
      _createMolecule(_formula, _key, _name, _scriptId);
  }

  /// @notice root for whitelist minting
  bytes32 public merkleRoot;

  /// @notice allows owner to set the merkleRoot for whitelist minting
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /// @notice counts the total amount of whitelisted mints across scripts per address
  mapping (address => uint) public mintCount;

  /// @notice mints a molecule when msg.sender is whitelisted
  /// @param _numberOfElements is the number of different elements in the formula
  /// @param _whitelisted the amount for which msg.sender is whitelisted
  /// @param _proof an array of proof hashes for the MerkleProof
  /// @dev set the _numberOfElements to how often the element's letters occur in formula
  function whitelistMint(
    string memory _formula,
    string memory _key,
    string memory _name,
    uint16 _scriptId,
    uint _numberOfElements,
    uint _whitelisted,
    bytes32[] memory _proof
    ) public payable {
      require(msg.value >= getPrice(_scriptId), "Insufficient funds");
      require(scripts[_scriptId].whitelistSale || msg.sender == scripts[_scriptId].creator || msg.sender == owner(), "No WL sale");
      require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _whitelisted))), "merkle proof failed");
      require(mintCount[msg.sender]<_whitelisted, "max reached");
      mintCount[msg.sender] += 1;

      _distributeFunds(_scriptId, _formula, _numberOfElements);
      _createMolecule(_formula, _key, _name, _scriptId);
  }


  /// @notice contract owner can withdraw ETH that was accidentally sent to this contract
  function rescueFunds() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
  }

}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @notice stores and manages generative art scripts
contract MoleculeScripter is Ownable {

  /// @notice stores script data
  /// @param name is the script's title
  /// @param scriptCode stores all generative art code on chain
  /// @param creator is the artists address
  /// @param publicSale scripts can be minted to
  /// @param locked scripts cannot be changed anymore
  /// @param isSealed scripts lock all molecule's chemical data forever
  /// @param currentSupply shows how many molecules have been minted with that script
  /// @param totalSupply is the limit of molecules that can be minted with that script
  /// @param saleDuration is the time in hours of the dutch auction
  /// @param startPrice is the price in wei the dutch auction starts with
  /// @param endPrice is the price in wei minting stays at after the saleDuration ended
  struct Script {
    string name;
    string scriptCode;
    address creator;
    bool publicSale;
    bool whitelistSale;
    bool locked;
    bool isSealed;
    uint16 currentSupply;
    uint16 totalSupply;
    uint32 saleDuration;
    uint64 startPrice;
    uint64 endPrice;

  }

  /// @notice emits when a new script is created
  event NewScript(
    uint indexed scriptId,
    string name,
    string scriptCode,
    address creator,
    bool publicSale,
    bool whitelistSale,
    bool locked,
    bool isSealed,
    uint16 currentSupply,
    uint16 totalSupply,
    uint32 saleDuration,
    uint64 startPrice,
    uint64 endPrice
  );

  /// @notice stores all scripts on chain
  Script[] public scripts;

  /// @notice number of scripts a creator can deploy
  mapping (address => uint) public allowedScripts;

  /// @notice script ids that belong to a creator
  mapping (uint => address) public scriptToCreator;

  /// @notice total number of scripts a creator has deployed
  mapping (address => uint) creatorScriptCount;

  /// @notice script IDs to timestamps of sales starts
  mapping (uint => uint) startingTime;

  /// @notice allow new creators in
  function allowCreator(address _creator, uint _scriptsAllowed) external onlyOwner {
    allowedScripts[_creator] = allowedScripts[_creator] + _scriptsAllowed;
  }

  /// @notice returns all script ids created by one creator
  function getScriptsByCreator(address _creator) external view returns(uint[] memory) {
    uint[] memory result = new uint[](creatorScriptCount[_creator]);
    uint counter = 0;
    for (uint i = 0; i < scripts.length; i++) {
      if (scriptToCreator[i] == _creator) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  /// @notice checks if the artists is allowed to publish a script
  modifier onlyCreators(address _creator) {
    require(allowedScripts[_creator] > 0 || _creator == owner(), "Creator not allowed");
    require(allowedScripts[_creator] > creatorScriptCount[_creator] || _creator == owner(), "Creator max scripts reached");
    _;
  }

  /// @notice creates a new script
  function createScript(
    string memory _name,
    string memory _scriptCode,
    uint16 _totalSupply,
    uint32 _saleDuration,
    uint64 _startPrice,
    uint64 _endPrice
    ) external onlyCreators(msg.sender) {
      scripts.push(Script(_name, _scriptCode, msg.sender, false, false, false, false, 0, _totalSupply, _saleDuration, _startPrice, _endPrice));
      uint id = scripts.length -1;
      creatorScriptCount[msg.sender]++;
      scriptToCreator[id] = msg.sender;
      emit NewScript(id, _name, _scriptCode, msg.sender, false, false, false, false, 0, _totalSupply, _saleDuration, _startPrice, _endPrice);
  }

  /// @notice allows to activate / deactivate a script and sets starting time for the sale
  function saleSwitch(uint _scriptId, bool _publicSale, bool _whitelistSale) external onlyScriptCreator(_scriptId) {
    scripts[_scriptId].publicSale = _publicSale;
    scripts[_scriptId].whitelistSale = _whitelistSale;
    if (_publicSale || _whitelistSale) {
      startingTime[_scriptId] = block.timestamp;
    }
  }

  /// @notice only script creator or owner can execute a function
  modifier onlyScriptCreator(uint _scriptId) {
    require(msg.sender == scripts[_scriptId].creator || msg.sender == owner(), "Only script creator or owner");
    _;
  }

  /// @notice checks if the script is below its total supply
  modifier mintableScript(uint _scriptId) {
    require(scripts[_scriptId].currentSupply+1 <= scripts[_scriptId].totalSupply, "Total supply reached");
    _;
  }

  /// @notice only proceeds when the script is not locked
  modifier notLocked(uint _scriptId) {
    require(!scripts[_scriptId].locked, "Script locked");
    _;
  }

  /// @notice permanently locks a script => price, supply, and code cannot be altered
  function lockScript(uint _scriptId) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].locked = true;
  }

  /// @notice creators can update the script code when the script is not locked
  function updateScriptName(uint _scriptId, string memory _scriptName) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].name = _scriptName;
  }

  /// @notice creators can update the script code when the script is not locked
  function updateScriptCode(uint _scriptId, string memory _scriptCode) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].scriptCode = _scriptCode;
  }

  /// @notice updates total supply when the script is not locked
  function updateScriptTotalSupply(uint _scriptId, uint16 _totalSupply) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    require(scripts[_scriptId].currentSupply <= _totalSupply, "Supply already exceeded");
    scripts[_scriptId].totalSupply = _totalSupply;
  }

  /// @notice updates price per molecule when the script is not locked
  function updateScriptPrice(uint _scriptId, uint32 _saleDuration, uint64 _startPrice, uint64 _endPrice) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].saleDuration = _saleDuration;
    scripts[_scriptId].startPrice = _startPrice;
    scripts[_scriptId].endPrice = _endPrice;
  }

  /// @notice only proceeds when the script is not sealed
  modifier notSealed(uint _scriptId) {
    require(!scripts[_scriptId].isSealed, "Script is sealed");
    _;
  }

  /// @notice permanently seals a script => molecules cannot be altered anymore
  function sealScript(uint _scriptId) notSealed(_scriptId) onlyOwner external {
    scripts[_scriptId].isSealed = true;
  }
}