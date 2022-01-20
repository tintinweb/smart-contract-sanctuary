// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./IWarmup.sol";
import "./SafeERC20.sol";


interface isohm
{
    function transfer( address to, uint256 value ) external returns (bool);
}

contract Warmup is IWarmup, Ownable
{
    address private sACX;
    address private StakingAddress;
    modifier onlyStaker()
    {
        require(msg.sender == StakingAddress, "Only Stake Contract is allowed to retrieve sACX!");
        _;
    }
    function setStakeContract(address _stakeContract)public onlyOwner
    {
        StakingAddress = _stakeContract;
    }
    function setStakingToken(address _stakeToken)public onlyOwner
    {
        sACX = _stakeToken;
    }
    function retrieve( address staker_, uint amount_ ) external override onlyStaker
    {
        isohm(sACX).transfer(staker_, amount_);
    }
    function StakingContract()public view returns(address _stakingcontract)
    {
        return StakingAddress;
    }
    function StakingToken()public view returns(address _stakingtoken)
    {
        return sACX;
    }
}