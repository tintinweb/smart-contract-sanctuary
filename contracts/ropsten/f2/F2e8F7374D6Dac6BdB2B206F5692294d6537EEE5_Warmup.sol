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
    address private staketoken;
    modifier onlyStaker()
    {
        require(msg.sender == staketoken, "Only Stake Contract is allowed to retrieve sACX!");
        _;
    }
    function setStakeContract(address _stake)public onlyOwner
    {
        staketoken = _stake;
    }
    function retrieve( address staker_, uint amount_ ) external override onlyStaker
    {
        isohm(staketoken).transfer(staker_, amount_);
    }

}