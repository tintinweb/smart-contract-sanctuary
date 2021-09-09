/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

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

  /**
   * @dev Converts a given Unicode codepoint into an XML escape sequence.
   */
  function xmlCodepoint (uint32 val) internal pure returns (string memory)
  {
    bytes memory res = bytes ("&#x000000;");

    for (uint i = 0; val > 0; ++i)
      {
        require (i < 6, "codepoint does not fit into 24 bits");

        res[8 - i] = HEX[val & 0xF];
        val >>= 4;
      }

    return string (res);
  }

}

// File: contracts/StringBuilder.sol

// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev Utility library for building up strings in Solidity bit-by-bit,
 * without the need to re-allocate the string for each bit.
 */
library StringBuilder
{

  /**
   * @dev A string being built.  This is just a bytes array of a given
   * allocated size, and the current length (which might be smaller than
   * the allocated size).
   */
  struct Type
  {

    /**
     * @dev The allocated data array.  The size (stored in the first slot)
     * is set to the actual (current) length, rather than the allocated one.
     */
    bytes data;

    /** @dev The maximu / allocated size of the data array.  */
    uint maxLen;

  }

  /**
   * @dev Constructs a new builder that is empty initially but has space
   * for the given number of bytes.
   */
  function create (uint maxLen) internal pure returns (Type memory res)
  {
    bytes memory data = new bytes (maxLen);

    assembly {
      mstore (data, 0)
    }

    res.data = data;
    res.maxLen = maxLen;
  }

  /**
   * @dev Extracts the current data from a builder instance as string.
   */
  function extract (Type memory b) internal pure returns (string memory)
  {
    return string (b.data);
  }

  /**
   * @dev Adds the given string to the content of the builder.  This must
   * not exceed the allocated maximum size.
   */
  function append (Type memory b, string memory str) internal pure
  {
    bytes memory buf = b.data;
    bytes memory added = bytes (str);

    uint256 oldLen = buf.length;
    uint256 newLen = oldLen + added.length;
    require (newLen <= b.maxLen, "StringBuilder maxLen exceeded");
    assembly {
      mstore (buf, newLen)
    }

    for (uint i = 0; i < added.length; ++i)
      buf[i + oldLen] = added[i];
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
    string bgColour;

    /**
     * @dev Foreground / text colour used in the SVG image for names
     * of this namespace.
     */
    string fgColour;

    /** @dev Value returned for the "type" attribute.  */
    string typ;

  }

  /** @dev Known namespaces for which we return custom metadata.  */
  mapping (string => NamespaceData) public namespaces;

  /** @dev The default configuration for unknown namespaces.  */
  NamespaceData public defaultConfig;

  /** @dev Emitted when a namespace is reconfigured.  */
  event NamespaceConfigured (string ns);

  /* ************************************************************************ */

  /** @dev Width of the generated SVG.  */
  string internal constant svgWidth = "512";

  /** @dev Height of the generated SVG.  */
  string internal constant svgHeight = "256";

  /**
   * @dev For the SVG generation, we use a table of (maximum) string
   * lengths (in codepoints) and the corresponding font-size to use.
   * These structs are individual entries in that table.
   *
   * When looking through an array of these structs (which is the look-up
   * table), the first entry matching a given string is used.  If none match
   * (as the string is too long), then the last entry is used and the string
   * is truncated to that entry's length with an ellipsis added.
   */
  struct SvgSizeEntry
  {

    /**
     * @dev The maximum length of a string in codepoints to match this
     * table entry.
     */
    uint len;

    /** @dev The font-size to use for a matching string.  */
    string fontSize;

  }

  /* Solidity does not (yet) support simple creation of a constant
     variable holding the look-up table as SvgSizeEntry[].  Thus we
     define the actual table as memory array inside the function below.  */

  /* ************************************************************************ */

  /**
   * @dev The constructor applies the initial configuration of known
   * namespaces.
   */
  constructor ()
  {
    defaultConfig.description =
        "A generic name for the Xaya platform (of unknown type).";
    defaultConfig.bgColour = "999999";
    defaultConfig.fgColour = "000000";
    defaultConfig.typ = "Unknown";
    emit NamespaceConfigured ("");

    setNamespaceData ("p",
        "A player account for the Xaya platform.  All in-game assets are"
        " associated to account NFTs.",
        "3333bb", "000000", "Player Account");
    setNamespaceData ("g",
        "The admin account for a game on the Xaya platform.",
        "bb3333", "000000", "Game");
  }

  /**
   * @dev Adds or updates the namespace data for a given namespace.  If ns
   * is the empty string, it changes the default configuration instead.
   */
  function setNamespaceData (string memory ns, string memory description,
                             string memory bgColour, string memory fgColour,
                             string memory typ) public onlyOwner
  {
    NamespaceData storage entry;
    if (bytes (ns).length == 0)
      entry = defaultConfig;
    else
      entry = namespaces[ns];

    entry.configured = true;
    entry.description = description;
    entry.bgColour = bgColour;
    entry.fgColour = fgColour;
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
      "https://extra.domob.eu/base64.php?t=", mimeType,
      "&d=", Base64.encode (payload)
    ));
    /*
    return string (abi.encodePacked (
      "data:", mimeType,
      ";base64,", Base64.encode (payload)
    ));
    */
  }

  /**
   * @dev Encodes a given string as JSON string literal.
   */
  function jsonStringLiteral (string memory str)
      internal pure returns (string memory)
  {
    bytes memory data = bytes (str);

    /* Each codepoint is encoded into a \uXXXX sequence of size 6.  The number
       of codepoints can never be larger than the byte-size of the UTF-8 string
       (even with UTF-16 surrogate pairs).  */
    StringBuilder.Type memory builder = StringBuilder.create (6 * data.length);

    uint offset = 0;
    while (offset < data.length)
      {
        uint32 cp;
        (cp, offset) = Utf8.decodeCodepoint (data, offset);
        StringBuilder.append (builder, HexEscapes.jsonCodepoint (cp));
      }

    return string (abi.encodePacked (
      "\"", StringBuilder.extract (builder), "\""
    ));
  }

  /**
   * @dev Encodes a given string as XML escape sequences.  The string
   * is truncated to the given length.
   */
  function xmlStringLiteral (string memory str, uint maxLen)
      internal pure returns (string memory, uint, bool)
  {
    bytes memory data = bytes (str);

    StringBuilder.Type memory builder = StringBuilder.create (10 * data.length);
    uint len = 0;

    uint offset = 0;
    while (offset < data.length)
      {
        uint32 cp;
        (cp, offset) = Utf8.decodeCodepoint (data, offset);
        StringBuilder.append (builder, HexEscapes.xmlCodepoint (cp));
        ++len;

        if (len == maxLen)
          return (StringBuilder.extract (builder), len, true);
      }

    require (len <= maxLen, "string length exceeded");
    return (StringBuilder.extract (builder), len, false);
  }

  /**
   * @dev Constructs the NFT image as SVG string.  For simplicity, we already
   * expect the string to be passed in the full form with ns/name.
   */
  function buildSvgImage (string memory fullName, NamespaceData storage config)
      internal view returns (string memory)
  {
    SvgSizeEntry[3] memory sizeTable = [
      SvgSizeEntry (10, "36"),
      SvgSizeEntry (20, "24"),
      SvgSizeEntry (30, "12")
    ];

    string memory escapedString;
    string memory fontSize;

    {
      uint cpLen;
      bool trunc;
      (escapedString, cpLen, trunc)
          = xmlStringLiteral (fullName, sizeTable[sizeTable.length - 1].len);

      if (trunc)
        {
          escapedString = string (abi.encodePacked (escapedString, "..."));
          fontSize = sizeTable[sizeTable.length - 1].fontSize;
        }
      else
        {
          bool found = false;
          for (uint i = 0; i < sizeTable.length; ++i)
            {
              if (cpLen <= sizeTable[i].len)
                {
                  fontSize = sizeTable[i].fontSize;
                  found = true;
                  break;
                }
            }
          require (found, "no matching entry found");
        }
    }

    return string (abi.encodePacked (
      "<?xml version='1.0' ?>"
      "<svg xmlns='http://www.w3.org/2000/svg'"
      " width='", svgWidth, "'"
      " height='", svgHeight, "'>"

      "<rect x='0' y='0' width='100%' height='100%'"
      " fill='#", config.bgColour, "' />"

      "<text x='50%' y='50%' text-anchor='middle' dominant-baseline='middle'"
      " fill='#", config.fgColour, "'"
      " font-size='", fontSize, "'>",
      escapedString,
      "</text>"

      "</svg>"
    ));
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

    string memory imgData = buildSvgImage (fullName, config);
    string memory imgUri = buildDataUrl ("image/svg+xml", bytes (imgData));

    return string (abi.encodePacked (
      "{",
        "\"name\":",  jsonStringLiteral (fullName),
        /* The base64-encoded data: URI can be included literally
           as a JSON string.  This way, we avoid a rather costly
           re-encoding step.  */
        ",\"image\":\"", imgUri, "\""
        ",\"description\":", jsonStringLiteral (config.description),
        ",\"background_color\":\"", config.bgColour, "\""
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
    return buildDataUrl ("application/json", jsonData);
  }

  /* ************************************************************************ */

}