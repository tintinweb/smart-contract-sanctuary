/**
 *Submitted for verification at Etherscan.io on 2020-08-15
*/

pragma solidity ^0.6.0;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}

interface ICurveVesting {
  function vestedOf(address addr) external view returns (uint256);
  function balanceOf(address addr) external view returns (uint256);
  function lockedOf(address addr) external view returns (uint256);
  function total_claimed(address addr) external view returns (uint256);
}

contract CurveVestingHelpers {
  /**
  * @dev Return Curve Token Address
  */
  function getCurveTokenAddr() internal pure returns (address) {
    return 0xD533a949740bb3306d119CC777fa900bA034cd52;
  }

  /**
  * @dev Return Curve Vesting Address
  */
  function getCurveVestingAddr() internal pure returns (address) {
    return 0x575CCD8e2D300e2377B43478339E364000318E2c;
  }
}


contract Resolver is CurveVestingHelpers {
    function getPosition(address user) public view returns (
        uint vestedBalance,
        uint unclaimedBal,
        uint claimedBal,
        uint lockedBalance,
        uint crvBalance
    ) {
        ICurveVesting vestingContract = ICurveVesting(getCurveVestingAddr());
        vestedBalance = vestingContract.vestedOf(user);
        unclaimedBal = vestingContract.balanceOf(user);
        claimedBal = vestingContract.total_claimed(user);
        lockedBalance = vestingContract.lockedOf(user);

        crvBalance = TokenInterface(getCurveTokenAddr()).balanceOf(user);
    }
}


contract InstaCurveVestingResolver is Resolver {
    string public constant name = "Curve-Vesting-Resolver-v1";
}