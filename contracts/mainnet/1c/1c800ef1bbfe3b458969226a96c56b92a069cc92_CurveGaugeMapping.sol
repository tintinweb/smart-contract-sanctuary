pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ConnectorsInterface {
  function chief(address) external view returns (bool);
}

interface IndexInterface {
  function master() external view returns (address);
}

contract BytesHelper {
  /**
  * @dev Convert String to bytes32.
  */
  function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
    require(bytes(str).length != 0, "String-Empty");
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(str, 32))
    }
  }
}

contract Helpers is BytesHelper {
  address public constant connectors = 0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c;
  address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
  uint public version = 1;

  mapping (bytes32 => GaugeData) public gaugeMapping;

  struct GaugeData {
    address gaugeAddress;
    bool rewardToken;
  }

  event LogAddGaugeMapping(
    string gaugeName,
    address gaugeAddress,
    bool rewardToken
  );

  event LogRemoveGaugeMapping(
    string gaugeName,
    address gaugeAddress
  );

  modifier isChief virtual {
    require(
      ConnectorsInterface(connectors).chief(msg.sender) ||
      IndexInterface(instaIndex).master() == msg.sender, "not-Chief");
      _;
  }

  function _addGaugeMapping(
    string memory gaugeName,
    address gaugeAddress,
    bool rewardToken
  ) internal {
    require(gaugeAddress != address(0), "gaugeAddress-not-vaild");
    require(bytes(gaugeName).length <= 32, "Length-exceeds");
    bytes32 gaugeType = stringToBytes32(gaugeName);
    require(gaugeMapping[gaugeType].gaugeAddress == address(0), "gaugePool-already-added");

    gaugeMapping[gaugeType].gaugeAddress = gaugeAddress;
    gaugeMapping[gaugeType].rewardToken = rewardToken;

    emit LogAddGaugeMapping(gaugeName, gaugeAddress, rewardToken);
  }

  function addGaugeMappings(
    string[] memory gaugeNames,
    address[] memory gaugeAddresses,
    bool[] memory rewardTokens
  ) public isChief {
    require(gaugeNames.length == gaugeAddresses.length && gaugeAddresses.length == rewardTokens.length, "length-not-match");
    for (uint32 i; i < gaugeNames.length; i++) {
      _addGaugeMapping(gaugeNames[i], gaugeAddresses[i], rewardTokens[i]);
    }
  }

  function removeGaugeMapping(string memory gaugeName, address gaugeAddress) public isChief {
    require(gaugeAddress != address(0), "gaugeAddress-not-vaild");
    bytes32 gaugeType = stringToBytes32(gaugeName);
    require(gaugeMapping[gaugeType].gaugeAddress == gaugeAddress, "different-gauge-pool");

    delete gaugeMapping[gaugeType];

    emit LogRemoveGaugeMapping(
      gaugeName,
      gaugeAddress
    );
  }
}

contract CurveGaugeMapping is Helpers {
  string constant public name = "Curve-Gauge-Mapping-v1";

  constructor (
    string[] memory gaugeNames,
    address[] memory gaugeAddresses,
    bool[] memory rewardTokens
  ) public {
    require(gaugeNames.length == gaugeAddresses.length && gaugeAddresses.length == rewardTokens.length, "length-not-match");
    for (uint32 i; i < gaugeNames.length; i++) {
      _addGaugeMapping(gaugeNames[i], gaugeAddresses[i], rewardTokens[i]);
    }
  }
}