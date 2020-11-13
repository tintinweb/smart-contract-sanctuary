pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ICurveGaugeMapping {

  struct GaugeData {
    address gaugeAddress;
    bool rewardToken;
  }

  function gaugeMapping(bytes32) external view returns(GaugeData memory);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}

interface IMintor {
    function minted(address, address) external view returns (uint);
}

interface IGauge {
  function integrate_fraction(address user) external view returns(uint256 amt);
  function lp_token() external view returns(address token);
  function rewarded_token() external view returns(address token);
  function crv_token() external view returns(address token);
  function balanceOf(address user) external view returns(uint256 amt);
  function rewards_for(address user) external view returns(uint256 amt);
  function claimed_rewards_for(address user) external view returns(uint256 amt);
}

contract GaugeHelper {
  function getCurveGaugeMappingAddr() internal pure returns (address){
    return 0x1C800eF1bBfE3b458969226A96c56B92a069Cc92;
  }

  function getCurveMintorAddr() internal pure returns (address){
    return 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
  }

  /**
   * @dev Convert String to bytes32.
   */
  function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(str, 32))
    }
  }
}


contract Resolver is GaugeHelper {
    struct PositionData {
        uint stakedBal;
        uint crvEarned;
        uint crvClaimed;
        uint rewardsEarned;
        uint rewardsClaimed;
        uint crvBal;
        uint rewardBal;
        bool hasReward;
    }
    function getPosition(string memory gaugeName, address user) public view returns (PositionData memory positionData) { 
        ICurveGaugeMapping curveGaugeMapping = ICurveGaugeMapping(getCurveGaugeMappingAddr());
        ICurveGaugeMapping.GaugeData memory curveGaugeData = curveGaugeMapping.gaugeMapping(
            bytes32(stringToBytes32(gaugeName)
        ));
        IGauge gauge = IGauge(curveGaugeData.gaugeAddress);
        IMintor mintor = IMintor(getCurveMintorAddr());
        positionData.stakedBal = gauge.balanceOf(user);
        positionData.crvEarned = gauge.integrate_fraction(user);
        positionData.crvClaimed = mintor.minted(user, address(gauge));

        if (curveGaugeData.rewardToken) {
            positionData.rewardsEarned = gauge.rewards_for(user);
            positionData.rewardsClaimed = gauge.claimed_rewards_for(user);
            positionData.rewardBal = TokenInterface(address(gauge.rewarded_token())).balanceOf(user);
        }
        positionData.hasReward = curveGaugeData.rewardToken;

        positionData.crvBal = TokenInterface(address(gauge.crv_token())).balanceOf(user);
    }

    function getPositions(string[] memory gaugesName, address user) public view returns (PositionData[] memory positions) {
        positions = new PositionData[](gaugesName.length);
        for (uint i = 0; i < gaugesName.length; i++) {
            positions[i] = getPosition(gaugesName[i], user);
        }
    }
}


contract InstaCurveGaugeResolver is Resolver {
    string public constant name = "Curve-Gauge-Resolver-v1";
}