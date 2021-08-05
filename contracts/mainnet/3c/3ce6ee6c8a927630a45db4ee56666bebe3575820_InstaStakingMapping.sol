/**
 *Submitted for verification at Etherscan.io on 2020-07-19
*/

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

  /**
  * @dev Convert bytes32 to String.
  */
  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    bytes32  _temp;
    uint count;
    for (uint256 i; i < 32; i++) {
      _temp = _bytes32[i];
      if( _temp != bytes32(0)) {
        count += 1;
      }
    }
    bytes memory bytesArray = new bytes(count);
    for (uint256 i; i < count; i++) {
      bytesArray[i] = (_bytes32[i]);
    }
    return (string(bytesArray));
  }
}
contract Helpers is BytesHelper {
  address public constant connectors = 0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c;
  address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
  uint public version = 1;

  mapping (bytes32 => StakingData) public stakingMapping;

  struct StakingData {
    address stakingPool;
    address stakingToken;
    address rewardToken;
  }

  event LogAddStakingMapping(
    string stakingName,
    bytes32 stakingType,
    address stakingAddress,
    address stakingToken,
    address rewardToken
  );
  event LogRemoveStakingMapping(
    string stakingName,
    bytes32 stakingType,
    address stakingAddress,
    address stakingToken,
    address rewardToken
  );
  modifier isChief virtual {
    require(
      ConnectorsInterface(connectors).chief(msg.sender) ||
      IndexInterface(instaIndex).master() == msg.sender, "not-Chief");
      _;
  }

  function addStakingMapping(
    string memory stakingName,
    address stakingAddress,
    address stakingToken,
    address rewardToken
  ) public isChief {
    require(stakingAddress != address(0), "stakingAddress-not-vaild");
    require(stakingToken != address(0), "stakingToken-not-vaild");
    require(rewardToken != address(0), "rewardToken-not-vaild");
    require(bytes(stakingName).length <= 32, "Length-exceeds");
    bytes32 stakeType = stringToBytes32(stakingName);
    require(stakingMapping[stakeType].stakingPool == address(0), "StakingPool-already-added");
    require(stakingMapping[stakeType].stakingToken == address(0), "StakingToken-already-added");
    require(stakingMapping[stakeType].rewardToken == address(0), "rewardToken-already-added");

    stakingMapping[stakeType] = StakingData(
      stakingAddress,
      stakingToken,
      rewardToken
    );
    emit LogAddStakingMapping(stakingName, stakeType, stakingAddress, stakingToken, rewardToken);
  }

  function removeStakingMapping(string memory stakingName, address stakingAddress) public isChief {
    require(stakingAddress != address(0), "stakingAddress-not-vaild");
    bytes32 stakeType = stringToBytes32(stakingName);
    require(stakingMapping[stakeType].stakingPool == stakingAddress, "different-staking-pool");

    emit LogRemoveStakingMapping(
      stakingName,
      stakeType,
      stakingAddress,
      stakingMapping[stakeType].stakingToken,
      stakingMapping[stakeType].rewardToken
    );
    delete stakingMapping[stakeType];
  }
}


contract InstaStakingMapping is Helpers {
  string constant public name = "Staking-Mapping-v1.1";
}