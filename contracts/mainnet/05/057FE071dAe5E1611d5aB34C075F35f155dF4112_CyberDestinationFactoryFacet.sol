// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

//
import "../CyberDestinationFactoryBase.sol";

contract CyberDestinationFactoryFacet is CyberDestinationFactoryBase {}

//                       .   *        .       .
//        *      -0-
//           .                .  *       - )-
//        .      *       o       .       *
//  o                |
//            .     -O-
// .                 |        *      .     -0-
//        *  o     .    '       *      .        o
//               .         .        |      *
//    *             *              -O-          .
//          .             *         |     ,
//                 .           o
//         .---.
//   =   _/__~0_\_     .  *            o       '
//  = = (_________)             .
//                  .                        *
//        *               - ) -       *
// ________/\\\\\\\\\_        __/\\\________/\\\_        __/\\\\\\\\\\\\\___        __/\\\\\\\\\\\\\\\_        ____/\\\\\\\\\_____        
//  _____/\\\////////__        _\///\\\____/\\\/__        _\/\\\/////////\\\_        _\/\\\///////////__        __/\\\///////\\\___       
//   ___/\\\/___________        ___\///\\\/\\\/____        _\/\\\_______\/\\\_        _\/\\\_____________        _\/\\\_____\/\\\___      
//    __/\\\_____________        _____\///\\\/______        _\/\\\\\\\\\\\\\\__        _\/\\\\\\\\\\\_____        _\/\\\\\\\\\\\/____     
//     _\/\\\_____________        _______\/\\\_______        _\/\\\/////////\\\_        _\/\\\///////______        _\/\\\//////\\\____    
//      _\//\\\____________        _______\/\\\_______        _\/\\\_______\/\\\_        _\/\\\_____________        _\/\\\____\//\\\___   
//       __\///\\\__________        _______\/\\\_______        _\/\\\_______\/\\\_        _\/\\\_____________        _\/\\\_____\//\\\__  
//        ____\////\\\\\\\\\_        _______\/\\\_______        _\/\\\\\\\\\\\\\/__        _\/\\\\\\\\\\\\\\\_        _\/\\\______\//\\\_ 
//         _______\/////////__        _______\///________        _\/////////////____        _\///////////////__        _\///________\///__

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

//
import '@solidstate/contracts/token/ERC1155/IERC1155.sol';
import "./ERC1155URI/ERC1155URI.sol";
import "./BaseRelayRecipient/BaseRelayRecipient.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Diamond/LibDiamond.sol";
import "./BaseRelayRecipient/BaseRelayRecipientStorage.sol";
import "./libraries/LibAppStorage.sol";

contract CyberDestinationFactoryBase is BaseRelayRecipient, ERC1155URI {

  using ECDSA for bytes32;
  using Counters for Counters.Counter;

  event Minted(address indexed account, uint256 indexed tokenId, uint256 indexed amount);

  function initialize(string memory _uri, address _manager, address _trustedForwarder, address _opensea, address _oncyber) public {

    require(LibDiamond.diamondStorage().contractOwner == msg.sender, "NO");

    BaseRelayRecipientStorage.layout().trustedForwarder = _trustedForwarder;
    LibDiamond.diamondStorage().supportedInterfaces[type(IERC1155).interfaceId] = true;
    setURI(_uri);
    LibAppStorage.layout().manager = _manager;
    LibAppStorage.layout().opensea = _opensea;
    LibAppStorage.layout().oncyber = _oncyber;

  }

  function totalSupply() public view returns (uint256) {

    return LibAppStorage.layout().totalSupply.current();

  }

  function manager() public view returns (address) {

    return LibAppStorage.layout().manager;

  }

  function oncyber() public view returns (address) {

    return LibAppStorage.layout().oncyber;

  }

  function minterNonce(address _minter) public view returns (uint256){

    return LibAppStorage.layout().minterNonce[_minter].current();

  }

  function mint(string memory _uri, uint256 _amount, uint256 _amount_oncyber, bytes memory _signature) public returns (uint256 _tokenId) {

    address sender = _msgSender();
    uint256 nonce = minterNonce(sender);

    bytes memory _message = abi.encodePacked(_uri, _amount, _amount_oncyber, nonce, sender);
    address _recoveredAddress = keccak256(_message).toEthSignedMessageHash().recover(_signature);
    require(_recoveredAddress == LibAppStorage.layout().manager, "NM");
    require(_amount >= _amount_oncyber, "IAO");

    // Mint token
    _tokenId = LibAppStorage.layout().totalSupply.current();
    setTokenURI(_tokenId, _uri);
    LibAppStorage.layout().totalSupply.increment();
    LibAppStorage.layout().minterNonce[sender].increment();
    _safeMint(sender, _tokenId, _amount, "");

    if(_amount_oncyber > 0){
      _safeTransfer(sender, sender, LibAppStorage.layout().oncyber, _tokenId, _amount_oncyber, "");
    }

    emit Minted(sender, _tokenId, _amount);

    if(!isApprovedForAll(sender, LibAppStorage.layout().opensea) ){

      setApprovalForAll(LibAppStorage.layout().opensea, true);

    }

    return _tokenId;

  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from '../../introspection/IERC165.sol';

interface IERC1155 is IERC165 {
  event TransferSingle (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  event TransferBatch (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  event ApprovalForAll (
    address indexed account,
    address indexed operator,
    bool approved
  );

  event URI (
    string value,
    uint256 indexed id
  );

  function balanceOf (
    address account,
    uint256 id
  ) external view returns (uint256);

  function balanceOfBatch (
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view returns (uint256[] memory);

  function setApprovalForAll (
    address operator,
    bool approved
  ) external;

  function isApprovedForAll (
    address account,
    address operator
  ) external view returns (bool);

  function safeTransferFrom (
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom (
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@solidstate/contracts/token/ERC1155/ERC1155.sol";
import "./ERC1155URIStorage.sol";

abstract contract ERC1155URI is ERC1155 {

  function uri(uint256 _tokenId) public view virtual returns (string memory) {

    string memory tokenURI = ERC1155URIStorage.layout().tokenURIs[_tokenId];
    require(bytes(tokenURI).length != 0, "ERC1155URI: tokenId not exist");
    return string(abi.encodePacked(ERC1155URIStorage.layout().uri, tokenURI));

  }

  function setURI(string memory new_uri) internal virtual {
    ERC1155URIStorage.layout().uri = new_uri;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    ERC1155URIStorage.layout().tokenURIs[tokenId] = _tokenURI;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/utils/Context.sol";
import "./BaseRelayRecipientStorage.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */

abstract contract BaseRelayRecipient is Context {

  /*
   * require a function to be called through GSN only
   */
//  modifier trustedForwarderOnly() {
//    require(msg.sender == address(s.trustedForwarder), "Function can only be called through the trusted Forwarder");
//    _;
//  }

  function isTrustedForwarder(address forwarder) public view returns(bool) {
    return forwarder == BaseRelayRecipientStorage.layout().trustedForwarder;
  }

  /**
   * return the sender of this call.
   * if the call came through our trusted forwarder, return the original sender.
   * otherwise, return `msg.sender`.
   * should be used in the contract anywhere instead of msg.sender
   */
  function _msgSender() internal override virtual view returns (address ret) {
    if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
      // At this point we know that the sender is a trusted forwarder,
      // so we trust that the last bytes of msg.data are the verified sender address.
      // extract sender address from the end of msg.data
      assembly {
        ret := shr(96,calldataload(sub(calldatasize(),20)))
      }
    } else {
      return msg.sender;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly { ds.slot := position }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

library BaseRelayRecipientStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'diamond.storage.BaseRelayRecipientStorage'
  );

  struct Layout {
    /*
     * Forwarder singleton we accept calls from
     */
    address trustedForwarder;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/utils/Counters.sol";
//

library LibAppStorage {
  bytes32 constant STORAGE_SLOT = keccak256("app.storage");

  struct Layout {

    address manager;
    address opensea;
    Counters.Counter totalSupply;
    mapping (address => Counters.Counter) minterNonce;
    address oncyber;

  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
  function supportsInterface (
    bytes4 interfaceId
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC1155Base} from './ERC1155Base.sol';

abstract contract ERC1155 is ERC1155Base {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

library ERC1155URIStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'diamond.storage.ERC1155URI'
  );

  struct Layout {
    mapping (uint256 => string) tokenURIs;
    string uri;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// TODO: remove ERC165

import {IERC1155} from './IERC1155.sol';
import {IERC1155Receiver} from './IERC1155Receiver.sol';
import {ERC1155BaseStorage} from './ERC1155BaseStorage.sol';
import {ERC165} from '../../introspection/ERC165.sol';
import {AddressUtils} from '../../utils/AddressUtils.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155, ERC165 {
  using AddressUtils for address;

  /**
   * @notice query the balance of given token held by given address
   * @param account address to query
   * @param id token to query
   * @return token balance
   */
  function balanceOf (
    address account,
    uint id
  ) override public view returns (uint) {
    require(account != address(0), 'ERC1155: balance query for the zero address');
    return ERC1155BaseStorage.layout().balances[id][account];
  }

  /**
   * @notice query the balances of given tokens held by given addresses
   * @param accounts addresss to query
   * @param ids tokens to query
   * @return token balances
   */
  function balanceOfBatch (
    address[] memory accounts,
    uint[] memory ids
  ) override public view returns (uint[] memory) {
    require(accounts.length == ids.length, 'ERC1155: accounts and ids length mismatch');

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    uint[] memory batchBalances = new uint[](accounts.length);

    for (uint i; i < accounts.length; i++) {
      require(accounts[i] != address(0), 'ERC1155: batch balance query for the zero address');
      batchBalances[i] = balances[ids[i]][accounts[i]];
    }

    return batchBalances;
  }

  /**
   * @notice query approval status of given operator with respect to given address
   * @param account address to query for approval granted
   * @param operator address to query for approval received
   * @return whether operator is approved to spend tokens held by account
   */
  function isApprovedForAll (
    address account,
    address operator
  ) override public view returns (bool) {
    return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
  }

  /**
   * @notice grant approval to or revoke approval from given operator to spend held tokens
   * @param operator address whose approval status to update
   * @param status whether operator should be considered approved
   */
  function setApprovalForAll (
    address operator,
    bool status
  ) override public {
    require(msg.sender != operator, 'ERC1155: setting approval status for self');
    ERC1155BaseStorage.layout().operatorApprovals[msg.sender][operator] = status;
    emit ApprovalForAll(msg.sender, operator, status);
  }

  /**
   * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
   * @param from sender of tokens
   * @param to receiver of tokens
   * @param id token ID
   * @param amount quantity of tokens to transfer
   * @param data data payload
   */
  function safeTransferFrom (
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  ) override public {
    require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: caller is not owner nor approved');
    _safeTransfer(msg.sender, from, to, id, amount, data);
  }

  /**
   * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
   * @param from sender of tokens
   * @param to receiver of tokens
   * @param ids list of token IDs
   * @param amounts list of quantities of tokens to transfer
   * @param data data payload
   */
  function safeBatchTransferFrom (
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) override public {
    require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: caller is not owner nor approved');
    _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
  }

  /**
   * @notice mint given quantity of tokens for given address
   * @dev ERC1155Receiver implemenation is not checked
   * @param account beneficiary of minting
   * @param id token ID
   * @param amount quantity of tokens to mint
   * @param data data payload
   */
  function _mint (
    address account,
    uint id,
    uint amount,
    bytes memory data
  ) virtual internal {
    require(account != address(0), 'ERC1155: mint to the zero address');

    _beforeTokenTransfer(msg.sender, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

    mapping (address => uint) storage balances = ERC1155BaseStorage.layout().balances[id];
    balances[account] += amount;

    emit TransferSingle(msg.sender, address(0), account, id, amount);
  }

  /**
   * @notice mint given quantity of tokens for given address
   * @param account beneficiary of minting
   * @param id token ID
   * @param amount quantity of tokens to mint
   * @param data data payload
   */
  function _safeMint (
    address account,
    uint id,
    uint amount,
    bytes memory data
  ) virtual internal {
    _doSafeTransferAcceptanceCheck(msg.sender, address(0), account, id, amount, data);
    _mint(account, id, amount, data);
  }

  /**
   * @notice mint batch of tokens for given address
   * @dev ERC1155Receiver implemenation is not checked
   * @param account beneficiary of minting
   * @param ids list of token IDs
   * @param amounts list of quantities of tokens to mint
   * @param data data payload
   */
  function _mintBatch (
    address account,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {
    require(account != address(0), 'ERC1155: mint to the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    _beforeTokenTransfer(msg.sender, address(0), account, ids, amounts, data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint id = ids[i];
      balances[id][account] += amounts[i];
    }

    emit TransferBatch(msg.sender, address(0), account, ids, amounts);
  }

  /**
   * @notice mint batch of tokens for given address
   * @param account beneficiary of minting
   * @param ids list of token IDs
   * @param amounts list of quantities of tokens to mint
   * @param data data payload
   */
  function _safeMintBatch (
    address account,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {
    _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), account, ids, amounts, data);
    _mintBatch(account, ids, amounts, data);
  }

  /**
   * @notice burn given quantity of tokens held by given address
   * @param account holder of tokens to burn
   * @param id token ID
   * @param amount quantity of tokens to burn
   */
  function _burn (
    address account,
    uint id,
    uint amount
  ) virtual internal {
    require(account != address(0), 'ERC1155: burn from the zero address');

    _beforeTokenTransfer(msg.sender, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), '');

    mapping (address => uint) storage balances = ERC1155BaseStorage.layout().balances[id];
    require(balances[account] >= amount, 'ERC1155: burn amount exceeds balances');
    balances[account] -= amount;

    emit TransferSingle(msg.sender, account, address(0), id, amount);
  }

  /**
   * @notice burn given batch of tokens held by given address
   * @param account holder of tokens to burn
   * @param ids token IDs
   * @param amounts quantities of tokens to burn
   */
  function _burnBatch (
    address account,
    uint[] memory ids,
    uint[] memory amounts
  ) virtual internal {
    require(account != address(0), 'ERC1155: burn from the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint id = ids[i];
      require(balances[id][account] >= amounts[i], 'ERC1155: burn amount exceeds balance');
      balances[id][account] -= amounts[i];
    }

    emit TransferBatch(msg.sender, account, address(0), ids, amounts);
  }

  /**
   * @notice transfer tokens between given addresses
   * @dev ERC1155Receiver implemenation is not checked
   * @param operator executor of transfer
   * @param sender sender of tokens
   * @param recipient receiver of tokens
   * @param id token ID
   * @param amount quantity of tokens to transfer
   * @param data data payload
   */
  function _transfer (
    address operator,
    address sender,
    address recipient,
    uint id,
    uint amount,
    bytes memory data
  ) virtual internal {
    require(recipient != address(0), 'ERC1155: transfer to the zero address');

    _beforeTokenTransfer(operator, sender, recipient, _asSingletonArray(id), _asSingletonArray(amount), data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    uint256 senderBalance = balances[id][sender];
    require(senderBalance >= amount, 'ERC1155: insufficient balances for transfer');
    unchecked {
      balances[id][sender] = senderBalance - amount;
    }
    balances[id][recipient] += amount;

    emit TransferSingle(operator, sender, recipient, id, amount);
  }

  /**
   * @notice transfer tokens between given addresses
   * @param operator executor of transfer
   * @param sender sender of tokens
   * @param recipient receiver of tokens
   * @param id token ID
   * @param amount quantity of tokens to transfer
   * @param data data payload
   */
  function _safeTransfer (
    address operator,
    address sender,
    address recipient,
    uint id,
    uint amount,
    bytes memory data
  ) virtual internal {
    _doSafeTransferAcceptanceCheck(operator, sender, recipient, id, amount, data);
    _transfer(operator, sender, recipient, id, amount, data);
  }

  /**
   * @notice transfer batch of tokens between given addresses
   * @dev ERC1155Receiver implemenation is not checked
   * @param operator executor of transfer
   * @param sender sender of tokens
   * @param recipient receiver of tokens
   * @param ids token IDs
   * @param amounts quantities of tokens to transfer
   * @param data data payload
   */
  function _transferBatch (
    address operator,
    address sender,
    address recipient,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {
    require(recipient != address(0), 'ERC1155: transfer to the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint token = ids[i];
      uint amount = amounts[i];

      uint256 senderBalance = balances[token][sender];
      require(senderBalance >= amount, 'ERC1155: insufficient balances for transfer');
      unchecked {
        balances[token][sender] = senderBalance - amount;
      }
      balances[token][recipient] += amount;
    }

    emit TransferBatch(operator, sender, recipient, ids, amounts);
  }

  /**
   * @notice transfer batch of tokens between given addresses
   * @param operator executor of transfer
   * @param sender sender of tokens
   * @param recipient receiver of tokens
   * @param ids token IDs
   * @param amounts quantities of tokens to transfer
   * @param data data payload
   */
  function _safeTransferBatch (
    address operator,
    address sender,
    address recipient,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {
    _doSafeBatchTransferAcceptanceCheck(operator, sender, recipient, ids, amounts, data);
    _transferBatch(operator, sender, recipient, ids, amounts, data);
  }

  /**
   * @notice wrap given element in array of length 1
   * @param element element to wrap
   * @return singleton array
   */
  function _asSingletonArray (
    uint element
  ) private pure returns (uint[] memory) {
    uint[] memory array = new uint[](1);
    array[0] = element;
    return array;
  }

  /**
   * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
   * @param operator executor of transfer
   * @param from sender of tokens
   * @param to receiver of tokens
   * @param id token ID
   * @param amount quantity of tokens to transfer
   * @param data data payload
   */
  function _doSafeTransferAcceptanceCheck (
    address operator,
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        require(
          response == IERC1155Receiver.onERC1155Received.selector,
          'ERC1155: ERC1155Receiver rejected tokens'
        );
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  /**
  * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
   * @param operator executor of transfer
   * @param from sender of tokens
   * @param to receiver of tokens
   * @param ids token IDs
   * @param amounts quantities of tokens to transfer
   * @param data data payload
   */
  function _doSafeBatchTransferAcceptanceCheck (
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
        require(
          response == IERC1155Receiver.onERC1155BatchReceived.selector,
          'ERC1155: ERC1155Receiver rejected tokens'
        );
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  /**
   * @notice ERC1155 hook, called before all transfers including mint and burn
   * @dev function should be overridden and new implemenation must call super
   * @dev called for both single and batch transfers
   * @param operator executor of transfer
   * @param from sender of tokens
   * @param to receiver of tokens
   * @param ids token IDs
   * @param amounts quantities of tokens to transfer
   * @param data data payload
   */
  function _beforeTokenTransfer (
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from '../../introspection/IERC165.sol';

interface IERC1155Receiver is IERC165 {
  function onERC1155Received (
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  function onERC1155BatchReceived (
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC1155BaseStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC1155Base'
  );

  struct Layout {
    mapping (uint => mapping (address => uint)) balances;
    mapping (address => mapping (address => bool)) operatorApprovals;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from './IERC165.sol';
import {ERC165Storage} from './ERC165Storage.sol';

abstract contract ERC165 is IERC165 {
  using ERC165Storage for ERC165Storage.Layout;

  function supportsInterface (bytes4 interfaceId) override public view returns (bool) {
    return ERC165Storage.layout().isSupportedInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
  function toString (address account) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(account)));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory chars = new bytes(42);

    chars[0] = '0';
    chars[1] = 'x';

    for (uint256 i = 0; i < 20; i++) {
      chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }

    return string(chars);
  }

  function isContract (address account) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function sendValue (address payable account, uint amount) internal {
    (bool success, ) = account.call{ value: amount }('');
    require(success, 'AddressUtils: failed to send value');
  }

  function functionCall (address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'AddressUtils: failed low-level call');
  }

  function functionCall (address target, bytes memory data, string memory error) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, error);
  }

  function functionCallWithValue (address target, bytes memory data, uint value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'AddressUtils: failed low-level call with value');
  }

  function functionCallWithValue (address target, bytes memory data, uint value, string memory error) internal returns (bytes memory) {
    require(address(this).balance >= value, 'AddressUtils: insufficient balance for call');
    return _functionCallWithValue(target, data, value, error);
  }

  function _functionCallWithValue (address target, bytes memory data, uint value, string memory error) private returns (bytes memory) {
    require(isContract(target), 'AddressUtils: function call to non-contract');

    (bool success, bytes memory returnData) = target.call{ value: value }(data);

    if (success) {
      return returnData;
    } else if (returnData.length > 0) {
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert(error);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC165'
  );

  struct Layout {
    // TODO: use EnumerableSet to allow post-diamond-cut auditing
    mapping (bytes4 => bool) supportedInterfaces;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function isSupportedInterface (
    Layout storage l,
    bytes4 interfaceId
  ) internal view returns (bool) {
    return l.supportedInterfaces[interfaceId];
  }

  function setSupportedInterface (
    Layout storage l,
    bytes4 interfaceId,
    bool status
  ) internal {
    require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
    l.supportedInterfaces[interfaceId] = status;
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}