pragma solidity ^0.4.24;

// imported contracts/proposals/OCP-IP-8/ILicenseTermsRegistry.sol
contract ILicenseTermsRegistry {
  event LicenseTermsAdded(bytes32 hash, uint256 updatedAt);
  function hashTerms(string name, string definition) public pure returns(bytes32);
  function addTerms(string name, string definition) public;
  function hasLicenseTerms(bytes32 hash) public view returns(bool);
  function name(bytes32 hash) public view returns(string);
  function definition(bytes32 hash) public view returns(string);
}

contract LicenseTermsRegistry is ILicenseTermsRegistry {
  struct Props {
    string name;
    string definition;
  }
  mapping(bytes32 => bool) private _hasLicenseTerms;
  mapping(bytes32 => Props) private _licenseTerms;
  function hashTerms(string, string definition) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(definition));
  }
  function addTerms(string name, string definition) public {
    bytes32 hash = hashTerms(name, definition);
    require(!_hasLicenseTerms[hash]);
    _hasLicenseTerms[hash] = true;
    _licenseTerms[hash] = Props({
      name: name,
      definition: definition
    });
    emit LicenseTermsAdded(hash, now); // solhint-disable-line not-rely-on-time
  }
  function hasLicenseTerms(bytes32 hash) public view returns(bool) {
    return _hasLicenseTerms[hash];
  }
  function name(bytes32 hash) public view returns(string) {
    require(_hasLicenseTerms[hash]);
    return _licenseTerms[hash].name;
  }
  function definition(bytes32 hash) public view returns(string) {
    require(_hasLicenseTerms[hash]);
    return _licenseTerms[hash].definition;
  }
}