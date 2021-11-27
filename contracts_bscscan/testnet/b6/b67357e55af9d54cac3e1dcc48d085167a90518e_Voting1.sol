/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;


interface IBEP21{
    function GetWhatStarYouAre(address account) external view returns(bool Star1,bool Star2,bool Star3,bool Star4, uint256 Gade4);
    function GetRelationShip(address account) external view returns(address Father);
    function SetVotingMX(uint256 _VotingMX) external returns(bool);
    function SetToken(address _NFTWPower) external returns(bool);
    function SetVotingMX_PowerOf(uint256 _VotingMX,uint256 _PowerOf) external returns(bool);
    
    function  StarBurnRateAccele_5_Percent () external view returns(uint256);
    function  StarBurnRateAccele_10_Percent () external view returns(uint256);
    function  StarBurnRateAccele_15_Percent () external view returns(uint256);
    function  StarBurnRateAccele_20_Percent () external view returns(uint256);
    function  StarBurnRateAccele_25_Percent () external view returns(uint256);

    function  StarBurnRateDecele_5_Percent () external view returns(uint256);
    function  StarBurnRateDecele_10_Percent () external view returns(uint256);
    function  StarBurnRateDecele_15_Percent () external view returns(uint256);
    function  StarBurnRateDecele_20_Percent () external view returns(uint256);
    function  StarBurnRateDecele_25_Percent () external view returns(uint256);
    
    function PowerBurn_Withdraw_To10Percent () external view returns(uint256);
    function PowerBurn_Withdraw_To20Percent () external view returns(uint256);
    function PowerBurn_Withdraw_To30Percent () external view returns(uint256);
    function PowerBurn_Withdraw_To40Percent () external view returns(uint256);
    function PowerBurn_Withdraw_To50Percent () external view returns(uint256);
    
    function Invitation_BonusRatio_To5Percent () external view returns(uint256);
    function Invitation_BonusRatio_To6Percent () external view returns(uint256);
    function Invitation_BonusRatio_To7Percent () external view returns(uint256);
    function Invitation_BonusRatio_To8Percent () external view returns(uint256);
    function Invitation_BonusRatio_To9Percent () external view returns(uint256);
    function Invitation_BonusRatio_To10Percent () external view returns(uint256);
    
    function RewardAccelerate_5Percent () external view returns(uint256);
    function RewardAccelerate_10Percent () external view returns(uint256);
    function RewardAccelerate_15Percent () external view returns(uint256);
    function RewardAccelerate_20Percent () external view returns(uint256);
    function RewardAccelerate_25Percent () external view returns(uint256);
    
    function RewardDecelerate_5Percent () external view returns(uint256);
    function RewardDecelerate_10Percent () external view returns(uint256);
    function RewardDecelerate_15Percent () external view returns(uint256);
    function RewardDecelerate_20Percent () external view returns(uint256);
    function RewardDecelerate_25Percent () external view returns(uint256);
    function RewardDecelerate_0Percent () external view returns(uint256);
    
    function Star1Reach_Invita_3_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_4_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_5_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_6_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_7_Gade4 () external view returns(uint256);

    function Star2Reach_Invita_8_Gade4 () external view returns(uint256);
    function Star2Reach_Invita_9_Gade4 () external view returns(uint256);
    function Star2Reach_Invita_10_Gade4 () external view returns(uint256);
    function Star2Reach_Invita_11_Gade4 () external view returns(uint256);
    function Star2Reach_Invita_12_Gade4 () external view returns(uint256);

    function Star3Reach_Invita_3_Star1 () external view returns(uint256);
    function Star3Reach_Invita_4_Star1 () external view returns(uint256);
    function Star3Reach_Invita_5_Star1 () external view returns(uint256);
    function Star3Reach_Invita_6_Star1 () external view returns(uint256);
    function Star3Reach_Invita_7_Star1 () external view returns(uint256);

    function Star4Reach_Invita_8_Star1 () external view returns(uint256);
    function Star4Reach_Invita_9_Star1 () external view returns(uint256);
    function Star4Reach_Invita_10_Star1 () external view returns(uint256);
    function Star4Reach_Invita_11_Star1 () external view returns(uint256);
    function Star4Reach_Invita_12_Star1 () external view returns(uint256);
    
    function Star1Keep_Invita_1_Gade4 () external view returns(uint256);
    function Star1Keep_Invita_2_Gade4 () external view returns(uint256);
    function Star1Keep_Invita_3_Gade4 () external view returns(uint256);
    
    
    function Star2Keep_Invita_2_Gade4 () external view returns(uint256);
    function Star2Keep_Invita_3_Gade4 () external view returns(uint256);
    function Star2Keep_Invita_4_Gade4 () external view returns(uint256);
    
    
    function Star3Keep_Invita_3_Gade4 () external view returns(uint256);
    function Star3Keep_Invita_4_Gade4 () external view returns(uint256);
    function Star3Keep_Invita_5_Gade4 () external view returns(uint256);
    
    function Star4Keep_Invita_4_Gade4 () external view returns(uint256);
    function Star4Keep_Invita_5_Gade4 () external view returns(uint256);
    function Star4Keep_Invita_6_Gade4 () external view returns(uint256);
    
    
    function VotersAll() external view returns (uint256);
    function SetVotingPower(uint256 votingPower) external  returns (bool);
    
}

contract Voting1 {
    
    IBEP21 Voters;
    IBEP21 Voting2;
    IBEP21 Voting3;
    IBEP21 Voting4;
    address Admin;
   
    
    constructor() public {Admin=msg.sender;}


    function SetToken(address _Voting2,address _Voting3,address _Voting4,address _NFTWPower) external{
      require(Admin==msg.sender);Voters=IBEP21(_NFTWPower);
      Voting2 = IBEP21(_Voting2);  Voting3 = IBEP21(_Voting3); Voting4 = IBEP21(_Voting4);Voting2.SetToken(_NFTWPower);Voting3.SetToken(_NFTWPower);Voting4.SetToken(_NFTWPower);}
   
    function SetVotingMX(uint256 _VotingMX,uint256 _PowerOf)external{
       Voters.SetVotingPower(_PowerOf);
       Voting2.SetVotingMX_PowerOf(_VotingMX,_PowerOf); Voting3.SetVotingMX(_VotingMX);Voting4.SetVotingMX(_VotingMX);}

    function _010_ALL_Voters_010_ () external view returns(uint256){return Voters.VotersAll();}
    function _010_WhatStarYouAre_010_ (address account) external view returns(bool,bool,bool,bool , uint256 ,address){
    (bool Star1,bool Star2,bool Star3,bool Star4, uint256 Gade4)=Voters.GetWhatStarYouAre(account);
    (address Father)=Voters.GetRelationShip(account);
    return (Star1, Star2, Star3, Star4, Gade4,Father);}
   


    function _1505_StarBurnRateAccele_5_Percent () external view returns(uint256){return Voting2.StarBurnRateAccele_5_Percent ();}
    function _1510_StarBurnRateAccele_10_Percent () external view returns(uint256){return Voting2.StarBurnRateAccele_10_Percent ();}
    function _1515_StarBurnRateAccele_15_Percent () external view returns(uint256){return Voting2.StarBurnRateAccele_15_Percent ();}
    function _1520_StarBurnRateAccele_20_Percent () external view returns(uint256){return Voting2.StarBurnRateAccele_20_Percent ();}
    function _1525_StarBurnRateAccele_25_Percent () external view returns(uint256){return Voting2.StarBurnRateAccele_25_Percent ();}

    function _1605_StarBurnRateDecele_5_Percent () external view returns(uint256){return Voting2.StarBurnRateDecele_5_Percent();}
    function _1610_StarBurnRateDecele_10_Percent () external view returns(uint256){return Voting2.StarBurnRateDecele_10_Percent();}
    function _1615_StarBurnRateDecele_15_Percent () external view returns(uint256){return Voting2.StarBurnRateDecele_15_Percent();}
    function _1620_StarBurnRateDecele_20_Percent () external view returns(uint256){return Voting2.StarBurnRateDecele_20_Percent();}
    function _1625_StarBurnRateDecele_25_Percent () external view returns(uint256){return Voting2.StarBurnRateDecele_25_Percent();}


    function _2010_Withdraw_PowerBurn_10_Percent () external view returns(uint256){return Voting2.PowerBurn_Withdraw_To10Percent ();}
    function _2020_Withdraw_PowerBurn_20_Percent () external view returns(uint256){return Voting2.PowerBurn_Withdraw_To20Percent ();}
    function _2030_Withdraw_PowerBurn_30_Percent () external view returns(uint256){return Voting2.PowerBurn_Withdraw_To30Percent ();}
    function _2040_Withdraw_PowerBurn_40_Percent () external view returns(uint256){return Voting2.PowerBurn_Withdraw_To40Percent ();}
    function _2050_Withdraw_PowerBurn_50_Percent () external view returns(uint256){return Voting2.PowerBurn_Withdraw_To50Percent ();}
    
    function _3005_Invitation_BonusRatio_5_Percent () external view returns(uint256){return Voting2.Invitation_BonusRatio_To5Percent ();}
    function _3006_Invitation_BonusRatio_6_Percent () external view returns(uint256){return Voting2.Invitation_BonusRatio_To6Percent ();}
    function _3007_Invitation_BonusRatio_7_Percent () external view returns(uint256){return Voting2.Invitation_BonusRatio_To7Percent ();}
    function _3008_Invitation_BonusRatio_8_Percent () external view returns(uint256){return Voting2.Invitation_BonusRatio_To8Percent ();}
    function _3009_Invitation_BonusRatio_9_Percent () external view returns(uint256){return Voting2.Invitation_BonusRatio_To9Percent ();}
    function _3010_Invitation_BonusRatio_10_Percent () external view returns(uint256){return Voting2.Invitation_BonusRatio_To10Percent ();}
    
    function _4005_RewardAcceleRate_5_Percent () external view returns(uint256){return Voting3.RewardAccelerate_5Percent ();}
    function _4010_RewardAcceleRate_10_Percent () external view returns(uint256){return Voting3.RewardAccelerate_10Percent ();}
    function _4015_RewardAcceleRate_15_Percent () external view returns(uint256){return Voting3.RewardAccelerate_15Percent ();}
    function _4020_RewardAcceleRate_20_Percent () external view returns(uint256){return Voting3.RewardAccelerate_20Percent ();}
    function _4025_RewardAcceleRate_25_Percent () external view returns(uint256){return Voting3.RewardAccelerate_25Percent ();}
    
    function _5005_RewardDeceleRate_5_Percent () external view returns(uint256){return Voting3.RewardDecelerate_5Percent ();}
    function _5010_RewardDeceleRate_10_Percent () external view returns(uint256){return Voting3.RewardDecelerate_10Percent ();}
    function _5015_RewardDeceleRate_15_Percent () external view returns(uint256){return Voting3.RewardDecelerate_15Percent ();}
    function _5020_RewardDeceleRate_20_Percent () external view returns(uint256){return Voting3.RewardDecelerate_20Percent ();}
    function _5025_RewardDeceleRate_25_Percent () external view returns(uint256){return Voting3.RewardDecelerate_25Percent ();}
    function _5000_RewardBackToStart_ () external view returns(uint256){return Voting3.RewardDecelerate_0Percent ();}
    
   

    function _6003_Star1Reach_Invita_3_Gade4 () external  view returns(uint256){return Voting3.Star1Reach_Invita_3_Gade4();}
    function _6004_Star1Reach_Invita_4_Gade4 () external  view returns(uint256){return Voting3.Star1Reach_Invita_4_Gade4();}
    function _6005_Star1Reach_Invita_5_Gade4 () external  view returns(uint256){return Voting3.Star1Reach_Invita_5_Gade4();}
    function _6006_Star1Reach_Invita_6_Gade4 () external  view returns(uint256){return Voting3.Star1Reach_Invita_6_Gade4();}
    function _6007_Star1Reach_Invita_7_Gade4 () external  view returns(uint256){return Voting3.Star1Reach_Invita_7_Gade4();}

    

    function _7008_Star2Reach_Invita_8_Gade4() external  view returns(uint256){return Voting2.Star2Reach_Invita_8_Gade4();}
    function _7009_Star2Reach_Invita_9_Gade4() external  view returns(uint256){return Voting2.Star2Reach_Invita_9_Gade4();}
    function _7010_Star2Reach_Invita_10_Gade4() external  view returns(uint256){return Voting2.Star2Reach_Invita_10_Gade4();}
    function _7011_Star2Reach_Invita_11_Gade4() external  view returns(uint256){return Voting2.Star2Reach_Invita_11_Gade4();}
    function _7012_Star2Reach_Invita_12_Gade4() external  view returns(uint256){return Voting2.Star2Reach_Invita_12_Gade4();}
    

    
    function _8003_Star3Reach_Invita_3_Star1() external  view returns(uint256){return Voting3.Star3Reach_Invita_3_Star1();}
    function _8004_Star3Reach_Invita_4_Star1() external  view returns(uint256){return Voting3.Star3Reach_Invita_4_Star1();}
    function _8005_Star3Reach_Invita_5_Star1() external  view returns(uint256){return Voting3.Star3Reach_Invita_5_Star1();}
    function _8006_Star3Reach_Invita_6_Star1() external  view returns(uint256){return Voting3.Star3Reach_Invita_6_Star1();}
    function _8007_Star3Reach_Invita_7_Star1() external  view returns(uint256){return Voting3.Star3Reach_Invita_7_Star1();}




    function _9008_Star4Reach_Invita_8_Star1() external  view returns(uint256){return Voting3.Star4Reach_Invita_8_Star1();}
    function _9009_Star4Reach_Invita_9_Star1() external  view returns(uint256){return Voting3.Star4Reach_Invita_9_Star1();}
    function _9010_Star4Reach_Invita_10_Star1() external  view returns(uint256){return Voting3.Star4Reach_Invita_10_Star1();}
    function _9011_Star4Reach_Invita_11_Star1() external  view returns(uint256){return Voting3.Star4Reach_Invita_11_Star1();}
    function _9012_Star4Reach_Invita_12_Star1() external  view returns(uint256){return Voting3.Star4Reach_Invita_12_Star1();}


    
    function _1101_Star1Keep_Invita1Gade4() external view returns(uint256){return Voting4.Star1Keep_Invita_1_Gade4();}
    function _1102_Star1Keep_Invita2Gade4() external view returns(uint256){return Voting4.Star1Keep_Invita_2_Gade4();}
    function _1103_Star1Keep_Invita3Gade4() external view returns(uint256){return Voting4.Star1Keep_Invita_3_Gade4();}
    

    
    function _1202_Star2Keep_Invita2Gade4() external view returns(uint256){return Voting4.Star2Keep_Invita_2_Gade4();}
    function _1203_Star2Keep_Invita3Gade4() external view returns(uint256){return Voting4.Star2Keep_Invita_3_Gade4();}
    function _1204_Star2Keep_Invita4Gade4() external view returns(uint256){return Voting4.Star2Keep_Invita_4_Gade4();}

    
    
    function _1303_Star3Keep_Invita3Gade4() external view returns(uint256){return Voting4.Star3Keep_Invita_3_Gade4();}
    function _1304_Star3Keep_Invita4Gade4() external view returns(uint256){return Voting4.Star3Keep_Invita_4_Gade4();}
    function _1305_Star3Keep_Invita5Gade4() external view returns(uint256){return Voting4.Star3Keep_Invita_5_Gade4();}


    
    function _1404_Star4Keep_Invita4Gade4() external view returns(uint256){return Voting4.Star4Keep_Invita_4_Gade4();}
    function _1405_Star4Keep_Invita5Gade4() external view returns(uint256){return Voting4.Star4Keep_Invita_5_Gade4();}
    function _1406_Star4Keep_Invita6Gade4() external view returns(uint256){return Voting4.Star4Keep_Invita_6_Gade4();}

    
}