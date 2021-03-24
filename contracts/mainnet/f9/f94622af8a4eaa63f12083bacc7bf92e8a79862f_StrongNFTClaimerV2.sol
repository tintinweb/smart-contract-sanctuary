//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./ServiceInterfaceV10.sol";
import "./IERC1155Preset.sol";

import "./Context.sol";
import "./Counters.sol";

contract StrongNFTClaimerV2 is Context {
  using Counters for Counters.Counter;

  IERC1155Preset public token;
  ServiceInterfaceV10 public service;

  bool public initDone;

  address public serviceAdmin;
  address public superAdmin;

  address payable public feeCollector;
  uint256 public claimingFeeInWei;

  string[] public tokenNames;
  mapping(string => uint256) public tokenNameIndex;
  mapping(string => bool) public tokenNameExists;
  mapping(string => Counters.Counter) public tokenNameCounter;
  mapping(string => mapping(address => bool)) public tokenNameAddressClaimed;

  function init(address tokenContract, address serviceContract, address serviceAdminAddress, address superAdminAddress) public {
    require(initDone == false, "init done");

    serviceAdmin = serviceAdminAddress;
    superAdmin = superAdminAddress;
    token = IERC1155Preset(tokenContract);
    service = ServiceInterfaceV10(serviceContract);
    initDone = true;
  }

  function isEligible(string memory tokenName, address claimer) public view returns (bool) {
    if (keccak256(abi.encode(tokenName)) == keccak256(abi.encode("BRONZE"))) {
      return
        tokenNameExists[tokenName] &&
        !tokenNameAddressClaimed[tokenName][claimer] &&
        service.isEntityActive(claimer) &&
        service.traunch(claimer) == 0;
    }

    return false;
  }

  function claim(string memory tokenName) public payable {
    require(tokenNameExists[tokenName], "invalid token");
    require(msg.value == claimingFeeInWei, "invalid fee");
    require(tokenNameAddressClaimed[tokenName][_msgSender()] == false, "already claimed");

    if (keccak256(abi.encode(tokenName)) == keccak256(abi.encode("BRONZE"))) {
      require(service.isEntityActive(_msgSender()), "not active");
      require(service.traunch(_msgSender()) == 0, "wrong traunch");

      token.mint(_msgSender(), tokenNameCounter[tokenName].current(), 1, "");
      tokenNameCounter[tokenName].increment();
      tokenNameAddressClaimed[tokenName][_msgSender()] = true;

      feeCollector.transfer(msg.value);
    } else {
      return;
    }
  }

  function updateFeeCollector(address payable newFeeCollector) public {
    require(newFeeCollector != address(0), "zero");
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    feeCollector = newFeeCollector;
  }

  function updateClaimingFee(uint256 feeInWei) public {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    claimingFeeInWei = feeInWei;
  }

  function addTokenName(string memory tokenName, uint256 counterValue) public {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    if (tokenNames.length != 0) {
      uint256 index = tokenNameIndex[tokenName];
      require(keccak256(abi.encode(tokenNames[index])) != keccak256(abi.encode(tokenName)), "exists");
    }
    uint256 len = tokenNames.length;
    tokenNameIndex[tokenName] = len;
    tokenNameExists[tokenName] = true;
    tokenNameCounter[tokenName] = Counters.Counter(counterValue);
    tokenNames.push(tokenName);
  }

  function updateTokenCounter(string memory tokenName, uint256 counterValue) public {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    tokenNameCounter[tokenName] = Counters.Counter(counterValue);
  }
}