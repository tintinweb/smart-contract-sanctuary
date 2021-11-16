// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./Strings.sol";
import "./Address.sol";

contract CCPolyRenderer {
  using Strings for uint256;

  string[] private randColor = [
    "red", "green", "blue", "#FF00FF", "#FFFF00", "#00FFFF"
  ];

  string[] private logoColor = [
    "#590044", "#001859", "gray", 'black'
  ];

  string[] private randBG = [
    "#17163B", "#3B1627", "#442244", "#224444", "#163B2A",
    "#771414", "#AF8D14", "#F699CD", "#F6F199", "#99F6C2",
    "#999EF6"
  ];

  struct TokenData {
    uint256 seed;
    uint256 tokenId;
    string from;
    string header;
    string footer;
    uint256 balance;
    address tokenOwnerAddress;
  }

  function getTokenURI(TokenData calldata data) public view returns (string memory) {
    bytes[4] memory attrib;
    bytes[9] memory parts;

    uint256 salt = 0;
    {
      parts[0] = abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" ',
        'preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 300">',
        '<defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse">',
        '<feGaussianBlur stdDeviation="48"/></filter><clipPath id="a">',
        '<rect width="500" height="300" rx="40" ry="40"/></clipPath>',
        '<path id="c" d="M40 12h420a28 28 0 0 1 28 28v220a28 28 0 0 1-28 28H40a28 28 0 0 1-28-28V40a28 28 0 0 1 28-28z"/>',
        '<linearGradient y2="0" x2="1" y1="1" x1="0" id="d"><stop offset="0" stop-color="#D1A255"/>',
        '<stop offset="1" stop-color="#EBDD9E"/></linearGradient><mask id="e"><rect width="100%" height="100%" fill="#fff"/>',
        '<rect rx="4" x="30" y="25" width="30" height="25" fill="#fff" stroke="#000" stroke-width="3"/>');
    }

    uint256 ib = getProperty(data.seed, salt++, randBG.length);
    bool blk = getRarity(data.seed, salt++, 3);
    bool dark = !blk && (ib >= 7);
    {
      string memory cb = blk ? 'black' : randBG[ib];
      string memory c0 = getRarity(data.seed, salt++, 4) ? 'gold' : dark ? 'black' : 'white';
      string memory c1 = getRarity(data.seed, salt++, 4) ? 'gold' : dark ? 'black' : 'white';
      attrib[0] = abi.encodePacked(c0);
      attrib[1] = abi.encodePacked(c1);
      attrib[2] = abi.encodePacked(cb);

      parts[1] = abi.encodePacked(
        '<path stroke="#000" stroke-width="3" d="M0 37.5h30M60 37.5h30M45 0v25M45 50v25"/></mask>',
        '</defs><style>text{font-family:Courier New,monospace;}.btxt{fill:',c0,'}.htxt{fill:',c1,
        ';font-size:14px;}.ftxt{fill:',c1,';font-size:14px;}</style>',
        '<g clip-path="url(#a)"><path fill="',cb,'" d="M0 0h500v300H0z"/><g style="filter:url(#b)">',
        '<path fill="',cb,'" d="M0 0h500v300H0z"/>');
    }

    {
      uint256 offset = getProperty(data.seed, salt++, randColor.length);
      {
        string memory c4 = randColor[offset];
        string memory c5 = randColor[(offset + 1) % randColor.length];
        string memory c6 = randColor[(offset + 2) % randColor.length];

        uint256 r0 = 60 + getProperty(data.seed, salt++, 40);
        uint256 r1 = 60 + getProperty(data.seed, salt++, 40);
        uint256 r2 = 60 + getProperty(data.seed, salt++, 40);

        parts[2] = abi.encodePacked(
          '<circle cx="20" cy="20" r="',r0.toString(),'" fill="',c4,'">',
          '<animateMotion dur="10s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
          '</circle><circle cx="300" cy="40" r="',r1.toString(),'" fill="',c5,'">'
          '<animateMotion dur="7s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
          '</circle><circle cx="40" cy="250" r="',r2.toString(),'" fill="',c6,'">');
      }

      {
        uint256 r3 = 60 + getProperty(data.seed, salt++, 40);
        string memory c7 = randColor[(offset + 3) % randColor.length];
        parts[3] = abi.encodePacked(
          '<animateMotion dur="5s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
          '</circle><circle cx="300" cy="250" r="',r3.toString(),'" fill="',c7,'">'
          '<animateMotion dur="11s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
          '</circle></g></g><text text-rendering="optimizeSpeed" xml:space="preserve" class="htxt">');
      }
    }

    {
      parts[4] = abi.encodePacked(
        '<textPath startOffset="-100%" xlink:href="#c">',data.header,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
        '<textPath startOffset="0%" xlink:href="#c">',data.header,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
        '</text><text text-rendering="optimizeSpeed" xml:space="preserve" class="ftxt">',
        '<textPath startOffset="50%" xlink:href="#c">',data.footer,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
        '<textPath startOffset="-50%" xlink:href="#c">',data.footer,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
        '</text><g style="transform:translate(297px,22px)"><g style="transform:scale(4.7)">');
    }

    {
      bool rare = getRarity(data.seed, salt++, 4);
      string memory ec0 = rare ? logoColor[getProperty(data.seed, salt++, logoColor.length)] : '#8247E5';

      attrib[3] = abi.encodePacked(ec0);

      parts[5] = abi.encodePacked(
        '<path d="M29,10.2c-0.7-0.4-1.6-0.4-2.4,0L21,13.5l-3.8,2.1l-5.5,3.3c-0.7,0.4-1.6,0.4-2.4,0L5,16.3c-0.7-0.4-1.2-1.2-1.2-2.1v-5c0-0.8,0.4-1.6,1.2-2.1l4.3-2.5c0.7-0.4,1.6-0.4,2.4,0L16,7.2c0.7,0.4,1.2,1.2,1.2,2.1v3.3l3.8-2.2V7c0-0.8-0.4-1.6-1.2-2.1l-8-4.7c-0.7-0.4-1.6-0.4-2.4,0L1.2,5C0.4,5.4,0,6.2,0,7v9.4c0,0.8,0.4,1.6,1.2,2.1l8.1,4.7c0.7,0.4,1.6,0.4,2.4,0l5.5-3.2l3.8-2.2l5.5-3.2c0.7-0.4,1.6-0.4,2.4,0l4.3,2.5c0.7,0.4,1.2,1.2,1.2,2.1v5c0,0.8-0.4,1.6-1.2,2.1L29,28.8c-0.7,0.4-1.6,0.4-2.4,0l-4.3-2.5c-0.7-0.4-1.2-1.2-1.2-2.1V21l-3.8,2.2v3.3c0,0.8,0.4,1.6,1.2,2.1l8.1,4.7c0.7,0.4,1.6,0.4,2.4,0l8.1-4.7c0.7-0.4,1.2-1.2,1.2-2.1V17c0-0.8-0.4-1.6-1.2-2.1L29,10.2z" style="opacity:.6" fill="',ec0,'"/></g></g>',
        '<text y="70" x="32" class="btxt" style="font-size:36px;font-weight:500">CRYPTO CARD</text>',
        '<rect x="30" y="120" width="55" height="47.5" rx="14" fill="rgba(0,0,0,0.4)"/>',
        '<g style="transform:translate(35px,125px)"><rect x="0" y="0" width="90" height="75" rx="20" ',
        'fill="url(#d)" mask="url(#e)" style="transform:scale(.5)"/></g>');
    }

    {
      string memory balance = formatBalance(data.balance);

      uint256 fwidth1 = 60 + 72*bytes(data.tokenId.toString()).length/10;
      string memory color = dark ? '0,0,0' : '255,255,255';
      string memory fsz = bytes(balance).length > 10 ? '20' : '24';
      parts[6] = abi.encodePacked(
        '<text y="100" x="32" class="btxt" style="font-size:',fsz,'px;font-weight:200">',balance,' MATIC</text>',
        '<rect x="16" y="16" width="468" height="268" rx="24" ry="24" fill="rgba(0,0,0,0)" stroke="rgba(',color,',0.2)"/>',
        '<g style="transform:translate(30px,185px);font-size:12">',
        '<rect width="',fwidth1.toString(),'" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.55)"/>');

    }

    {
      uint256 fwidth2 = 70 + 72*bytes(data.from).length/10;
      parts[7] = abi.encodePacked(
        '<text x="12" y="17" fill="#fff" xml:space="preserve"><tspan fill="rgba(255,255,255,0.6)">ID: </tspan>',data.tokenId.toString(),'</text></g>',
        '<g style="transform:translate(30px,215px);font-size:12"><rect width="',fwidth2.toString(),'" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.55)"/>',
        '<text x="12" y="17" fill="#fff" xml:space="preserve"><tspan fill="rgba(255,255,255,0.6)">From: </tspan>',data.from,'</text></g>');
    }

    {
      uint256 tokenOwner = uint256(uint160(data.tokenOwnerAddress));
      parts[8] = abi.encodePacked(
        '<g style="transform:translate(30px,245px);font-size:12">',
        '<rect width="375" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.55)"/>',
        '<text x="12" y="17" fill="#fff" xml:space="preserve"><tspan fill="rgba(255,255,255,0.6)">',
        'Owner: </tspan>0x', checksum(tokenOwner.toHexString()), '</text></g></svg>');
    }

    bytes memory output = abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]);

    string memory json = Base64.encode(
      abi.encodePacked(abi.encodePacked(
        '{"name": "CryptoCard #', data.tokenId.toString(),
        '", "description": "CryptoCard is a fully on-chain, generative NFT gift card. ',
        'The text is customizable to celebrate special occasions and lives forever on the blockchain. ',
        'The gift card value is rechargable and redeemable via contract and https://www.raritycard.com.", '),
        '"image": "data:image/svg+xml;base64,', Base64.encode(output), '", "attributes": [{"trait_type": "Main Text Color","value": "',
        attrib[0],'"}, {"trait_type": "Border Text Color","value": "',attrib[1],'"}, {"trait_type": "Card Color","value": "',attrib[2],
        '"}, {"trait_type": "Logo Color","value": "',attrib[3],'"}]}')
    );

    output = abi.encodePacked('data:application/json;base64,', json);

    return string(output);
  }

  function getRarity(uint256 seed, uint256 salt, uint8 num) internal pure returns (bool) {
    uint256 hash = uint256(keccak256(abi.encodePacked(seed, salt)));
    for (uint8 i = 0; i < num; i++) {
      if ((hash & (0x1 << i)) != 0) {
        return false;
      }
    }
    return true;
  }

  function getProperty(uint256 seed, uint256 salt, uint256 mod) internal pure returns (uint256) {
    uint256 num = uint256(keccak256(abi.encodePacked(seed, salt))) % mod;
    return num;
  }

  function formatBalance(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 whole = value / 1000000000000000000;
    uint256 fraction =  value % 1000000000000000000;

    string memory frac = fraction.toString();
    bytes memory tmp = bytes(frac);
    uint256 i = tmp.length;
    uint256 nz = (i == 1 && tmp[0] == '0') ? 0 : 18 - i;
    bytes memory zeros = new bytes(nz);
    for (uint256 j = 0; j < nz; j++) {
      zeros[j] = '0';
    }
    if (i > 1) {
      for (; i > 0; i--) {
        if (tmp[i-1] != '0') {
          break;
        }
      }
    }
    string memory strFrac = substring(frac, 0, i);
    return string(abi.encodePacked(whole.toString(), '.', string(zeros), strFrac));
  }

  function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    uint256 endMax = endIndex > strBytes.length ? strBytes.length : endIndex;
    bytes memory result = new bytes(endMax - startIndex);
    for (uint256 i = startIndex; i < endMax ; i++) {
      result[i - startIndex] = strBytes[i];
    }
    return string(result);
  }

  function checksum(string memory addr) internal pure returns (string memory) {
    assert(bytes(addr).length == 42);
    bytes memory tmp = abi.encodePacked(substring(addr,2, 42));
    bytes memory sum = abi.encodePacked(keccak256(tmp));

    bytes memory buffer = new bytes(40);
    for (uint8 i = 0; i < 20; i++) {
      bytes1 ch = sum[i];
      bytes1 a0 = tmp[2*i];
      bytes1 a1 = tmp[2*i+1];
      buffer[2*i] = (ch & 0x80) != 0 && a0 >= 'a' ? a0 ^ ' ' : a0;
      buffer[2*i+1] = (ch & 0x08) != 0 && a1 >= 'a' ? a1 ^ ' ' : a1;
    }
    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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