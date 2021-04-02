//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./ServiceInterfaceV10.sol";
import "./IERC1155Preset.sol";
import "./Context.sol";
import "./Counters.sol";

contract StrongNFTClaimerV4 is Context {
  using Counters for Counters.Counter;

  IERC1155Preset public NftToken;
  bool public initDone;
  address public serviceAdmin;
  address public superAdmin;
  address payable public feeCollector;
  uint256 public claimingFeeInWei;
  Counters.Counter public tokenCounter;
  mapping(address => bool) public addressClaimed;

  function init(
    address _tokenContract,
    address _serviceAdminAddress,
    address _superAdminAddress,
    uint256 _counterValue
  ) public {
    require(initDone == false, "init done");

    NftToken = IERC1155Preset(_tokenContract);
    serviceAdmin = _serviceAdminAddress;
    superAdmin = _superAdminAddress;
    tokenCounter = Counters.Counter(_counterValue);
    initDone = true;
  }

  function isEligible(address _address, bytes memory _signature) public view returns (bool) {
    bytes32 hash = prefixed(keccak256(abi.encodePacked(_address)));
    address signer = recoverSigner(hash, _signature);

    return !addressClaimed[_address] && (signer == superAdmin || signer == serviceAdmin);
  }

  function claim(bytes memory _signature) public payable {
    require(msg.value == claimingFeeInWei, "invalid fee");
    require(isEligible(_msgSender(), _signature), "not eligible");

    NftToken.mint(_msgSender(), tokenCounter.current(), 1, "");
    tokenCounter.increment();
    addressClaimed[_msgSender()] = true;

    feeCollector.transfer(msg.value);
  }

  // Signatures

  function recoverSigner(bytes32 _hash, bytes memory _sig) public pure returns (address) {
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_sig);

    return ecrecover(_hash, v, r, s);
  }

  function prefixed(bytes32 _hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
  }

  function splitSignature(bytes memory _sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
    require(_sig.length == 65);

    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    return (v, r, s);
  }

  // Admin

  function updateAddressClaimed(address _address, bool _value) public {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    addressClaimed[_address] = _value;
  }

  function updateCounterValue(uint256 _counterValue) public {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    tokenCounter = Counters.Counter(_counterValue);
  }

  function updateClaimingFee(uint256 _valueWei) public {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    claimingFeeInWei = _valueWei;
  }

  function updateFeeCollector(address payable _address) public {
    require(_address != address(0), "zero");
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    feeCollector = _address;
  }

}