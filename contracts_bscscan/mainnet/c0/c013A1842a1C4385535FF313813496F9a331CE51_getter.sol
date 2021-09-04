/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface DoubleFarm {
  function changeFee ( uint256 _pid, uint16 _fee ) external;
  function changeFirst ( uint256 _pid, address _first ) external;
  function changeLastBlock ( uint256 _pid, uint256 _lastBlock ) external;
  function changePoolFirstReward ( uint256 _pid, uint256 _firstPerBlock ) external;
  function changePoolSecondReward ( uint256 _pid, uint256 _secondPerBlock ) external;
  function changeSecond ( uint256 _pid, address _second ) external;
  function changeVault ( uint256 _pid, address _vault ) external;
  function claimBoth ( uint256 _pid ) external;
  function claimFirst ( uint256 _pid ) external;
  function claimSecond ( uint256 _pid ) external;
  function createPool ( address _lpToken, string memory _symbol, uint16 _fee, address _vault, uint256 _firstPerBlock, uint256 _secondPerBlock, address _first, address _second, uint256 _desiredBlock ) external;
  function deposit ( uint256 _pid, uint256 _amount ) external;
  function emergencyWithdraw ( uint256 _pid ) external;
  function getDeposit ( uint256 _pid, address account ) external view returns ( uint256 );
  function getPendingFirst ( uint256 _pid, address account ) external view returns ( uint256 );
  function getPendingSecond ( uint256 _pid, address account ) external view returns ( uint256 );
  function newOwner (  ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function pause (  ) external;
  function pausePool ( uint256 _pid ) external;
  function paused (  ) external view returns ( bool );
  function pausedPool ( uint256 ) external view returns ( bool );
  function pausedUpdatePools (  ) external view returns ( bool );
  function poolInfo ( uint256 ) external view returns ( address lpToken, string memory symbol, uint16 fee, address vault, uint256 totalSupply, uint256 firstPerBlock, uint256 secondPerBlock, uint256 lastRewardBlock, uint256 firstRewardsPerShare, uint256 secondRewardsPerShare, address first, address second, uint256 lastBlock );
  function poolLength (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function renounceOwnershipTimestamp (  ) external view returns ( uint256 );
  function setTransferOwnershipTimestamp ( address _newOwner ) external;
  function tokenAlreadyInPool ( address ) external view returns ( bool );
  function transferOwnership (  ) external;
  function transferOwnershipTimestamp (  ) external view returns ( uint256 );
  function unpause (  ) external;
  function unpausePool ( uint256 _pid ) external;
  function updatePool ( uint256 _pid ) external;
  function userInfo ( uint256, address ) external view returns ( uint256 amount, uint256 rewardMinusFirst, uint256 rewardMinusSecond );
  function withdraw ( uint256 _pid, uint256 _amount ) external;
  function withdrawAll ( uint256 _pid ) external;
}

contract getter{
    
    DoubleFarm public farm;
    
    constructor() public {
        farm = DoubleFarm(address(0xfddadE65Bf769E1Cd4f7Ef40Fc767175DcaF93c8));
    }
    
    function getBlock() view public returns(uint256){
        return block.number;
    }
    
    function getFee(uint256 _pid) view public returns(uint256){
        (,,uint16 fee,,,,,,,,,,) = farm.poolInfo(_pid);
        return fee;
    }
    
    function getTotalSupply(uint256 _pid) view public returns(uint256){
        (,,,, uint256 totalSupply,,,,,,,,) = farm.poolInfo(_pid);
        return totalSupply;
    }
    
    function getFirstPerBlock(uint256 _pid) view public returns(uint256){
        (,,,,,uint256 first,,,,,,,) = farm.poolInfo(_pid);
        return first;
    }
    
    function getSecondPerBlock(uint256 _pid) view public returns(uint256){
        (,,,,,,uint256 second,,,,,,) = farm.poolInfo(_pid);
        return second;
    }
}