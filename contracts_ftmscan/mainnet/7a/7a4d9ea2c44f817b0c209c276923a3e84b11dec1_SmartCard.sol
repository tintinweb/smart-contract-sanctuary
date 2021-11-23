/**
 *Submitted for verification at FtmScan.com on 2021-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface Staking {
    function totalStaked() external view returns (uint);
    function totalStakers() external view returns (uint);
    function totalDistributions() external view returns (uint);
    function profitPerShare() external view returns (uint);
    function stakerPayouts(address) external view returns (int);
    function dividendsOf(address staker) external view returns (uint);
}

interface LPToken {
    function getReserves() external view returns (uint112, uint112, uint32);
}

contract SmartCard {
    LPToken public smartFtmLp;
    LPToken public ftmUsdcLp;
    Staking public staking;
    IERC20 public smart;
    constructor() {
       smart = IERC20(0x34D33dc8Ac6f1650D94A7E9A972B47044217600b);
       staking = Staking(0xDDddE9Df7A604ceb41203B312B8B962A53c46997);
       smartFtmLp = LPToken(0x2FAd3Fcfc99B9D25b182B3Ed5A8E30eF70ba7Da5);
       ftmUsdcLp = LPToken(0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c);
    }
    
    function getData(address user) public view returns (uint smartFtm1, uint smartFtm2,
                                                        uint ftmUsdc1, uint ftmUsdc2,
                                                        uint totalStaked, uint totalDistributed,
                                                        uint totalStakers, uint addressBalance,
                                                        uint addressDividends, int addressPayout) {
        uint32 t1;
        uint32 t2;
        (smartFtm1, smartFtm2,  t1) = smartFtmLp.getReserves();
        (ftmUsdc1, ftmUsdc2,  t2) = ftmUsdcLp.getReserves();
        totalStaked = staking.totalStaked();
        totalDistributed = staking.totalDistributions();
        totalStakers = staking.totalStakers();
        
        if(user!=address(0)){
            addressBalance = smart.balanceOf(user);
            addressDividends = staking.dividendsOf(user);
            addressPayout = staking.stakerPayouts(user);
        }
        
    }
}