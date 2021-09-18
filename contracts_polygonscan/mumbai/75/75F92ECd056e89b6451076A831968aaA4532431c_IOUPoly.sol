// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./OZ.sol";


contract IOUPoly is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdCounter;

  string baseUrl;
  string projectDescription;
  bool useURIPointer;
  address predicateProxy;

  mapping (uint256 => bool) public withdrawnTokens;

  constructor() ERC721("IOUPoly", "IOU") {
    baseUrl = "https://steviep.xyz/IOU/tokens/";
    projectDescription = "This IOU is a bearer instrument. It should in no way be considered a promissory note. While this token may possibly be exchanged with other parties for monetary and non-monetary compensation, there should be no reasonable expectation of profit from holding this token. The issuer of this IOU makes no claims or guarantees that it will be redeemable for an asset or service of any kind at a later date. In no event shall the issuer be held liable for any damages arising from holding the IOU.";
  }

  function setPredicateProxy(address _predicateProxy) public onlyOwner {
    predicateProxy = _predicateProxy;
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://steviep.xyz/IOU";
  }

  function safeMint(address to) public onlyOwner {
    _safeMint(to, _tokenIdCounter.current());
    _tokenIdCounter.increment();
  }

  function batchSafeMint(address[] memory addresses) public onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
      _safeMint(addresses[i], _tokenIdCounter.current());
      _tokenIdCounter.increment();
    }
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory tokenString = tokenId.toString();

    if (useURIPointer) {
      return string(abi.encodePacked(baseUrl, 'metadata/', tokenString));
    }

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "IOU #',
            tokenString,
            '", "description": "',
            projectDescription,
            '", "image": "',
            baseUrl,
            'images/',
            tokenString,
            '.png"}'
          )
        )
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));

  }


  function flipUseURIPointer() public onlyOwner {
    useURIPointer = !useURIPointer;
  }

  function updateBaseUrl(string memory _baseUrl) public onlyOwner {
    baseUrl = _baseUrl;
  }

  function updateProjectDescription(string memory _projectDescription) public onlyOwner {
    projectDescription = _projectDescription;
  }



  // REQUIRED FOR POLYGON PREDICATE PROXY

  function withdraw(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId), "ChildMintableERC721: INVALID_TOKEN_OWNER");
    withdrawnTokens[tokenId] = true;
    _burn(tokenId);
  }

  function deposit(address user, bytes calldata depositData) external {
    require(_msgSender() == predicateProxy, "Signer must be predicate proxy");

    // deposit single
    if (depositData.length == 32) {
      uint256 tokenId = abi.decode(depositData, (uint256));
      withdrawnTokens[tokenId] = false;
      _safeMint(user, tokenId);

    // deposit batch
    } else {
      uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
      uint256 length = tokenIds.length;
      for (uint256 i; i < length; i++) {
        withdrawnTokens[tokenIds[i]] = false;
        _safeMint(user, tokenIds[i]);
      }
    }

  }

  function mint(address user, uint256 tokenId) public {
    require(_msgSender() == predicateProxy, "Signer must be predicate proxy");
    require(!withdrawnTokens[tokenId], "ChildMintableERC721: TOKEN_EXISTS_ON_ROOT_CHAIN");
    _safeMint(user, tokenId);
  }




  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}





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