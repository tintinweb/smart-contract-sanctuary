/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

// File: contracts/IXayaPolicy.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev Interface for a contract that defines the validation and fee
 * policy for Xaya accounts, as well as the NFT metadata returned for
 * a particular name.  This contract is the "part" of the Xaya account
 * registry that can be configured by the owner.
 *
 * All fees are denominated in WCHI tokens, this is not configurable
 * by the policy (but instead coded into the non-upgradable parts
 * of the account registry).
 */
interface IXayaPolicy
{

  /**
   * @dev Returns the address to which fees should be paid.
   */
  function feeReceiver () external returns (address);

  /**
   * @dev Verifies if the given namespace/name combination is valid; if it
   * is not, the function throws.  If it is valid, the fee that should be
   * charged is returned.
   */
  function checkRegistration (string memory ns, string memory name)
      external returns (uint256);

  /**
   * @dev Verifies if the given value is valid as a move for the given
   * namespace.  If it is not, the function throws.  If it is, the fee that
   * should be charged is returned.
   *
   * Note that the function does not know the exact name.  This ensures that
   * the policy cannot be abused to censor specific names (and the associated
   * game assets) after they have already been accepted for registration.
   *
   * FIXME: Should the policy (e.g. for fee) depend on the move's payment
   * amount?  So that a certain fraction of each in-game payment can be
   * charged as fee?
   */
  function checkMove (string memory ns, string memory mv)
      external returns (uint256);

  /**
   * @dev Constructs and returns the token URI that should be returned
   * as NFT metadata for a given name.
   */
  function tokenUriForName (string memory ns, string memory name)
      external view returns (string memory);

}

// File: contracts/HexEscapes.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev A Solidity library for escaping UTF-8 characters into
 * hex sequences, e.g. for JSON string literals.
 */
library HexEscapes
{

  /** @dev Hex characters used.  */
  bytes internal constant HEX = bytes ("0123456789ABCDEF");

  /**
   * @dev Converts a single uint16 number into a \uXXXX JSON escape
   * string.  This does not do any UTF-16 surrogate pair conversion.
   */
  function jsonUint16 (uint16 val) private pure returns (string memory)
  {
    bytes memory res = bytes ("\\uXXXX");

    for (uint i = 0; i < 4; ++i)
      {
        res[5 - i] = HEX[val & 0xF];
        val >>= 4;
      }

    return string (res);
  }

  /**
   * @dev Converts a given Unicode codepoint into a corresponding
   * escape sequence inside a JSON literal.  This takes care of encoding
   * it into either one or two \uXXXX sequences based on UTF-16.
   */
  function jsonCodepoint (uint32 val) internal pure returns (string memory)
  {
    if (val < 0xD800 || (val >= 0xE000 && val < 0x10000))
      return jsonUint16 (uint16 (val));

    require (val >= 0x10000 && val < 0x110000, "invalid codepoint");

    val -= 0x10000;
    return string (abi.encodePacked (
      jsonUint16 (0xD800 | uint16 (val >> 10)),
      jsonUint16 (0xDC00 | uint16 (val & 0x3FF))
    ));
  }

}

// File: contracts/Utf8.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev A Solidity library for validating UTF-8 from strings / bytes.
 * This is based on the definition of UTF-8 in RFC 3629.
 */
library Utf8
{

  /**
   * @dev Decodes the next codepoint from a byte array of UTF-8 encoded
   * data.  The input is expected in the byte(s) following the offset
   * into the array, and the return value is the decoded codepoint as well
   * as the offset of the following bytes (if any).  If the input bytes
   * are invalid, this method throws.
   */
  function decodeCodepoint (bytes memory data, uint offset)
      internal pure returns (uint32 cp, uint newOffset)
  {
    require (offset < data.length, "no more input bytes available");

    uint8 cur = uint8 (data[offset]);

    /* Special case for ASCII characters.  */
    if (cur < 0x80)
      return (cur, offset + 1);

    if (cur < 0xC0)
      revert ("mid-sequence character at start of sequence");

    /* Process the sequence-start character.  */
    uint8 numBytes;
    uint8 state;
    if (cur < 0xE0)
      {
        numBytes = 2;
        cp = uint32 (cur & 0x1F) << 6;
        state = 6;
      }
    else if (cur < 0xF0)
      {
        numBytes = 3;
        cp = uint32 (cur & 0x0F) << 12;
        state = 12;
      }
    else if (cur < 0xF8)
      {
        numBytes = 4;
        cp = uint32 (cur & 0x07) << 18;
        state = 18;
      }
    else
      revert ("invalid sequence start byte");
    newOffset = offset + 1;

    /* Process the following bytes of this sequence.  */
    while (state > 0)
      {
        require (newOffset < data.length, "eof in the middle of a sequence");

        cur = uint8 (data[newOffset]);
        newOffset += 1;

        require (cur & 0xC0 == 0x80, "expected sequence continuation");

        state -= 6;
        cp |= uint32 (cur & 0x3F) << state;
      }

    /* Verify that the character we decoded matches the number of bytes
       we had, to prevent overlong sequences.  */
    if (numBytes == 2)
      require (cp >= 0x80 && cp < 0x800, "overlong sequence");
    else if (numBytes == 3)
      require (cp >= 0x800 && cp < 0x10000, "overlong sequence");
    else if (numBytes == 4)
      require (cp >= 0x10000 && cp < 0x110000, "overlong sequence");
    else
      revert ("invalid number of bytes");

    /* Prevent characters reserved for UTF-16 surrogate pairs.  */
    require (cp < 0xD800 || cp > 0xDFFF, "surrogate-pair character decoded");
  }

  /**
   * @dev Validates that the given sequence of bytes is valid UTF-8
   * as per the definition in RFC 3629.  Throws if not.
   */
  function validate (bytes memory data) internal pure
  {
    uint offset = 0;
    while (offset < data.length)
      (, offset) = decodeCodepoint (data, offset);
    require (offset == data.length, "offset beyond string end");
  }

}

// File: base64-sol/base64.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: contracts/NftMetadata.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;





/**
 * @dev The logic for constructing the NFT metadata for a given Xaya account
 * token on-chain into JSON and a data: URL.
 *
 * There are certain bits of data that can be configured per namespace,
 * and this state is stored in the contract / can be updated by the owner.
 */
contract NftMetadata is Ownable
{

  /* ************************************************************************ */

  /** @dev Configuration data for a known namespace.  */
  struct NamespaceData
  {

    /** @dev Set to true if there is custom configuration for a namespace.  */
    bool configured;

    /** @dev Description string for names of this namespace.  */
    string description;

    /**
     * @dev Background colour returned for names of this namespace
     * in the NFT metadata.
     */
    string backgroundColour;

    /** @dev Value returned for the "type" attribute.  */
    string typ;

  }

  /** @dev Known namespaces for which we return custom metadata.  */
  mapping (string => NamespaceData) public namespaces;

  /** @dev The default configuration for unknown namespaces.  */
  NamespaceData public defaultConfig;

  /** @dev Emitted when a namespace is reconfigured.  */
  event NamespaceConfigured (string ns);

  /**
   * @dev The constructor applies the initial configuration of known
   * namespaces.
   */
  constructor ()
  {
    defaultConfig.description =
        "A generic name for the Xaya platform (of unknown type).";
    defaultConfig.backgroundColour = "999999";
    defaultConfig.typ = "Unknown";
    emit NamespaceConfigured ("");

    setNamespaceData ("p",
        "A player account for the Xaya platform.",
        "3333bb", "Player Account");
    setNamespaceData ("g",
        "The admin account for a game on the Xaya platform.",
        "bb3333", "Game");
  }

  /**
   * @dev Adds or updates the namespace data for a given namespace.  If ns
   * is the empty string, it changes the default configuration instead.
   */
  function setNamespaceData (string memory ns, string memory description,
                             string memory backgroundColour,
                             string memory typ) public onlyOwner
  {
    NamespaceData storage entry;
    if (bytes (ns).length == 0)
      entry = defaultConfig;
    else
      entry = namespaces[ns];

    entry.configured = true;
    entry.description = description;
    entry.backgroundColour = backgroundColour;
    entry.typ = typ;

    emit NamespaceConfigured (ns);
  }

  /* ************************************************************************ */

  /**
   * @dev Encodes a given payload of data into a data: URL string.
   */
  function buildDataUrl (string memory mimeType, bytes memory payload)
      internal pure returns (string memory)
  {
    return string (abi.encodePacked (
      "data:", mimeType,
      ";base64,", Base64.encode (payload)
    ));
  }

  /**
   * @dev Encodes a given string as JSON string literal.
   */
  function jsonStringLiteral (string memory str)
      internal pure returns (string memory)
  {
    bytes memory data = bytes (str);
    string memory val = "\"";

    uint offset = 0;
    while (offset < data.length)
      {
        uint32 cp;
        (cp, offset) = Utf8.decodeCodepoint (data, offset);
        val = string (abi.encodePacked (val, HexEscapes.jsonCodepoint (cp)));
      }

    return string (abi.encodePacked (val, "\""));
  }

  /**
   * @dev Constructs the metadata JSON for a given name.
   */
  function buildMetadataJson (string memory ns, string memory name)
      internal view returns (string memory)
  {
    NamespaceData storage config = namespaces[ns];
    if (!config.configured)
      config = defaultConfig;

    string memory fullName = string (abi.encodePacked (ns, "/", name));
    string memory attributes = string (abi.encodePacked (
      "[",
        "{",
          "\"trait_type\":\"Namespace\"",
          ",\"value\":", jsonStringLiteral (ns),
        "}",
        ",{",
          "\"trait_type\":\"Name\"",
          ",\"value\":", jsonStringLiteral (name),
        "}",
        ",{",
          "\"trait_type\":\"Type\"",
          ",\"value\":", jsonStringLiteral (config.typ),
        "}",
      "]"
    ));

    /* TODO: Add generated image.  */

    return string (abi.encodePacked (
      "{",
        "\"name\":",  jsonStringLiteral (fullName),
        ",\"description\":", jsonStringLiteral (config.description),
        ",\"background_color\":", jsonStringLiteral (config.backgroundColour),
        ",\"attributes\":", attributes,
      "}"
    ));
  }

  /**
   * @dev Constructs the full metadata URI for a given name.
   */
  function tokenUriForName (string memory ns, string memory name)
      public view returns (string memory)
  {
    bytes memory jsonData = bytes (buildMetadataJson (ns, name));
    return buildDataUrl ("application/json;charset=utf8", jsonData);
  }

  /* ************************************************************************ */

}

// File: contracts/XayaPolicy.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;





/**
 * @dev Implementation of the validation and fee policy that we use.
 *
 * Namespaces must be non-empty and consist only of lower-case letters a-z.
 * Names must be valid UTF-8 not including codepoints below 0x20.
 * Name + namespace must be shorter than 256 bytes, in UTF-8 encoded form.
 *
 * Move data must contain only ASCII characters between 0x20 and 0x7F
 * (but no JSON validation is performed).
 *
 * There is a configurable flat fee for registrations, and no fee
 * for moves.
 *
 * This contract has an owner, who is able to modify the fee receiver
 * address and the registration fee (with a time lock).
 */
contract XayaPolicy is Ownable, IXayaPolicy
{

  /* ************************************************************************ */

  /** @dev The metadata construction contract.  */
  NftMetadata public metadataContract;

  /** @dev The address receiving fee payments in WCHI.  */
  address public override feeReceiver;

  /** @dev Time lock for fee changes.  */
  uint public constant feeTimelock = 1 weeks;

  /** @dev The flat fee for registrations.  */
  uint256 public registrationFee;

  /** @dev If the fee is being changed, the next fee.  */
  uint256 public nextFee;

  /**
   * @dev If the fee is being changed, the earliest timestamp when the
   * change can be enacted.  Zero when there is no current change.
   */
  uint public nextFeeAfter;

  /** @dev Emitted when the metadata contract is updated.  */
  event MetadataContractChanged (NftMetadata oldContract,
                                 NftMetadata newContract);

  /** @dev Emitted when the fee receiver changes.  */
  event FeeReceiverChanged (address oldReceiver, address newReceiver);

  /** @dev Emitted when a fee change is scheduled.  */
  event FeeChangeScheduled (uint256 newRegistrationFee, uint validAfter);

  /** @dev Emitted when the fee is changed.  */
  event FeeChanged (uint256 oldRegistrationFee, uint256 newRegistrationFee);

  /* ************************************************************************ */

  constructor (NftMetadata metadata, uint256 initialFee)
  {
    require (metadata != NftMetadata (address (0)),
             "invalid metadata contract");
    metadataContract = metadata;
    emit MetadataContractChanged (NftMetadata (address (0)), metadataContract);

    feeReceiver = msg.sender;
    emit FeeReceiverChanged (address (0), feeReceiver);

    registrationFee = initialFee;
    emit FeeChanged (0, registrationFee);

    /* nextFee starts off as zero, which means that
       there is no fee change scheduled.  */
  }

  /**
   * @dev Updates the contract that is used for generating metadata.
   */
  function setMetadataContract (NftMetadata newContract) public onlyOwner
  {
    require (newContract != NftMetadata (address (0)),
             "invalid metadata contract");

    emit MetadataContractChanged (metadataContract, newContract);
    metadataContract = newContract;
  }

  /**
   * @dev Updates the fee receiver.  This takes effect immediately (without
   * a time lock).
   */
  function setFeeReceiver (address newReceiver) public onlyOwner
  {
    require (newReceiver != address (0), "invalid fee receiver");

    emit FeeReceiverChanged (feeReceiver, newReceiver);
    feeReceiver = newReceiver;
  }

  /**
   * @dev Schedules a fee change to take place after the time lock.
   */
  function scheduleFeeChange (uint256 newRegistrationFee) public onlyOwner
  {
    nextFee = newRegistrationFee;
    nextFeeAfter = block.timestamp + feeTimelock;
    emit FeeChangeScheduled (nextFee, nextFeeAfter);
  }

  /**
   * @dev Executes a scheduled fee change when the timelock is expired.
   * This can be done by anyone, not only the owner.
   */
  function enactFeeChange () public
  {
    require (nextFeeAfter != 0, "no fee change is scheduled");
    require (block.timestamp >= nextFeeAfter,
             "fee timelock is not expired yet");

    emit FeeChanged (registrationFee, nextFee);
    registrationFee = nextFee;
    nextFee = 0;
    nextFeeAfter = 0;
  }

  /* ************************************************************************ */

  function checkRegistration (string memory ns, string memory name)
      public override view returns (uint256)
  {
    bytes memory nsBytes = bytes (ns);
    bytes memory nameBytes = bytes (name);

    require (nsBytes.length > 0, "namespace must not be empty");
    require (nsBytes.length + nameBytes.length < 256, "name is too long");

    for (uint i = 0; i < nsBytes.length; ++i)
      require (nsBytes[i] >= 0x61 && nsBytes[i] <= 0x7A, "invalid namespace");

    uint cp;
    uint offset = 0;
    while (offset < nameBytes.length)
      {
        (cp, offset) = Utf8.decodeCodepoint (nameBytes, offset);
        require (cp >= 0x20, "invalid codepoint in name");
      }

    return registrationFee;
  }

  function checkMove (string memory, string memory mv)
      public override pure returns (uint256)
  {
    bytes memory mvBytes = bytes (mv);
    for (uint i = 0; i < mvBytes.length; ++i)
      require (mvBytes[i] >= 0x20 && mvBytes[i] < 0x80, "invalid move data");

    return 0;
  }

  function tokenUriForName (string memory ns, string memory name)
      public override view returns (string memory)
  {
    return metadataContract.tokenUriForName (ns, name);
  }

  /* ************************************************************************ */

}