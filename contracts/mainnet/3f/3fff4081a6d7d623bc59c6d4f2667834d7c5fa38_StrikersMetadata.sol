pragma solidity 0.4.24;

/// @title An optional contract that allows us to associate metadata to our cards.
/// @author The CryptoStrikers Team
contract StrikersMetadata {

  /// @dev The base url for the API where we fetch the metadata.
  ///   ex: https://us-central1-cryptostrikers-api.cloudfunctions.net/cards/
  string public apiUrl;

  constructor(string _apiUrl) public {
    apiUrl = _apiUrl;
  }

  /// @dev Returns the API URL for a given token Id.
  ///   ex: https://us-central1-cryptostrikers-api.cloudfunctions.net/cards/22
  ///   Right now, this endpoint returns a JSON blob conforming to OpenSea&#39;s spec.
  ///   see: https://docs.opensea.io/docs/2-adding-metadata
  function tokenURI(uint256 _tokenId) external view returns (string) {
    string memory _id = uint2str(_tokenId);
    return strConcat(apiUrl, _id);
  }

  // String helpers below were taken from Oraclize.
  // https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.4.sol

  function strConcat(string _a, string _b) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory bab = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }

  function uint2str(uint i) internal pure returns (string) {
    if (i == 0) return "0";
    uint j = i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (i != 0) {
      bstr[k--] = byte(48 + i % 10);
      i /= 10;
    }
    return string(bstr);
  }
}