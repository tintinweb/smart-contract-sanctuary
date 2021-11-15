//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

contract NftMetadataHelper {

  enum UriExecutedMethod { tokenMetadataURI, tokenURI, uri, baseTokenURI }

  struct UriResponse {
    UriExecutedMethod method;
    string metaUri;
    string assetUri;
    string contractName;
    string contractSymbol;
  }

  constructor() {}

  function _staticcall(address nftContract, uint256 tokenId, string memory sig) view internal returns (bool success, bytes memory result) {
    return nftContract.staticcall(abi.encodeWithSignature(sig, tokenId));
  }

  function _tokenMetadataURI(address nftContract, uint256 tokenId) view internal returns (bool success, bytes memory result) { 
    return _staticcall(nftContract, tokenId, "tokenMetadataURI(uint256)");
  }

  function _tokenURI(address nftContract, uint256 tokenId) view internal returns (bool success, bytes memory result) { 
    (bool status, bytes memory results) = _staticcall(nftContract, tokenId, "tokenURI(uint256)");
    return (status, results);
  }

  function _uri(address nftContract, uint256 tokenId) view internal returns (bool success, bytes memory result) { 
    return _staticcall(nftContract, tokenId, "uri(uint256)");
  }

  function _baseTokenURI(address nftContract) view internal returns (bool success, bytes memory result) { 
    return nftContract.staticcall(abi.encodeWithSignature("baseTokenURI()"));
  }

   function _contractName(address nftContract) view internal returns (bool success, bytes memory result) { 
    return nftContract.staticcall(abi.encodeWithSignature("name()"));
  }

  function _contractSymbol(address nftContract) view internal returns (bool success, bytes memory result) { 
    return nftContract.staticcall(abi.encodeWithSignature("symbol()"));
  }

  function _buildUriResponse(address nftContract, UriExecutedMethod method, bytes memory metaUri, bytes memory assetUri) internal view returns (UriResponse memory response) { 
    string memory contractName = "";
    (bool contractNameSuccess, bytes memory contractNameResult) = _contractName(nftContract);
    if (contractNameSuccess) {
      contractName = abi.decode(contractNameResult, (string));
    }

    string memory contractSymbol = "";
    (bool symbolSuccess, bytes memory symbolResult) = _contractSymbol(nftContract);
    if (symbolSuccess) {
      contractSymbol = abi.decode(symbolResult, (string));
    }

    string memory assetUriString = "";
    if (assetUri.length > 0) {
      assetUriString = abi.decode(assetUri, (string));
    }

    return UriResponse({
      method: method,
      metaUri: abi.decode(metaUri, (string)),
      assetUri: assetUriString,
      contractName: contractName,
      contractSymbol: contractSymbol
    });
  }

   function _getBalance(address nftContract, address owner, uint256 tokenId) view internal returns (bool success, bytes memory result) { 
    return nftContract.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)",owner,tokenId));
  }

  function getUri(address nftContract, uint256 tokenId) view public returns (UriResponse memory uri) {
    (bool tokenMetadataSuccess, bytes memory tokenMetadataResult) = _tokenMetadataURI(nftContract, tokenId);
    if (tokenMetadataSuccess) { 
      (bool internalTokenUriSuccess, bytes memory internalTokenUriResult) = _tokenURI(nftContract, tokenId);
      if (internalTokenUriSuccess) {
        return _buildUriResponse(nftContract, UriExecutedMethod.tokenMetadataURI, tokenMetadataResult, internalTokenUriResult);
      } else {
        return _buildUriResponse(nftContract, UriExecutedMethod.tokenMetadataURI, tokenMetadataResult, bytes(""));
      }
    }

    (bool tokenUriSuccess, bytes memory tokenUriResult) = _tokenURI(nftContract, tokenId);
    if (tokenUriSuccess) { 
      return _buildUriResponse(nftContract, UriExecutedMethod.tokenURI, tokenUriResult, bytes(""));
    } else {
      if(tokenUriResult.length > 0) {
        bytes memory errorMessage = tokenUriResult;
        assembly {
            // Slice the sighash.
            errorMessage := add(errorMessage, 0x04)
        }

        string memory errorMessageString = abi.decode(errorMessage, (string));
        string memory expectedErrorMessage = "ERC721Metadata: URI query for nonexistent token";
        require(!(keccak256(abi.encodePacked(errorMessageString)) == keccak256(abi.encodePacked(expectedErrorMessage))), "Could not find URI for token due to it being burnt");
      }
    }

    (bool uriSuccess, bytes memory uriResult) = _uri(nftContract, tokenId);
    if (uriSuccess) { 
      return _buildUriResponse(nftContract, UriExecutedMethod.uri, uriResult, bytes(""));
    }

    (bool baseTokenUriSuccess, bytes memory baseTokenUriResult) = _baseTokenURI(nftContract);
    if (baseTokenUriSuccess) { 
      return _buildUriResponse(nftContract, UriExecutedMethod.baseTokenURI, baseTokenUriResult, bytes(""));
    }

    require(false, "Could not find URI for token");
  }

  function getBalances(address nftContract, uint256 tokenId, address[] memory owners) view public returns (uint256[] memory ownerBalances) {
    uint256[] memory balances = new uint256[](owners.length);
    for (uint256 i = 0; i < owners.length; i++) { 
      (bool success, bytes memory result) = _getBalance(nftContract, owners[i], tokenId);
      if (success) { 
        balances[i] = abi.decode(result, (uint256));
      } else {
        balances[i] = 0;
      }
    }

    return balances;
  }
}

