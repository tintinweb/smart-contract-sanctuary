// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './SafeMath.sol';

interface sACX
{
    function totalGons()external pure returns(uint256 _gons);
    function gonsForBalance( uint amount ) external view returns ( uint );
    function balanceForGons( uint gons ) external view returns ( uint );
    function balanceOf( address who ) external view returns ( uint256 );
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns(uint256);
}

interface Distributor
{
    function nextRewardAt( uint _rate ) external view returns ( uint );

}

contract RewardCalculator 
{

    using SafeMath for uint256;
    sACX StakingTokenContract;
    Distributor distributor;
    uint256 private reward=0;
    uint256 oldBalance = 0;
    uint256 newBalance = 0;
    uint256 sACXsupply = 0;
    uint256 Gons = 0;
    uint256 _totalSupply = 0;
    uint256 EpochReward = 0;
    uint256 balanceInGons = 0;
    uint256 gonsPerFragment = 0;
    uint256 balance = 0;
    uint256 _circulatingSupply = 0;
    constructor(address _sACX, address _distributor)
    {
        StakingTokenContract = sACX(_sACX);
        distributor = Distributor(_distributor);
    }
    function calculateReward(uint256 _stakingAmount, address _user)public
    {
        _totalSupply = StakingTokenContract.totalSupply();
        EpochReward = distributor.nextRewardAt(5000);
        _circulatingSupply = StakingTokenContract.circulatingSupply() + _stakingAmount;
        if ( _circulatingSupply > 0 )
        {
            uint256 rebaseAmount = EpochReward.mul( _totalSupply ).div( _circulatingSupply);
            _totalSupply = rebaseAmount;

        } else {
            _totalSupply = EpochReward;
        }
        Gons = StakingTokenContract.totalGons();
        gonsPerFragment = Gons.div(_totalSupply);
        oldBalance = StakingTokenContract.balanceOf(_user);
        newBalance = oldBalance + _stakingAmount;
        balanceInGons = StakingTokenContract.gonsForBalance(newBalance);
        balance = balanceInGons.div(gonsPerFragment);
        reward = balance.sub(newBalance);
    }

    function getReward()public view returns(uint256 _reward)
    {
        return reward;
    }
}