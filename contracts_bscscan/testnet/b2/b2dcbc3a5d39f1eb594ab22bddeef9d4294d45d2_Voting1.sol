/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4;


interface IBEP21{
    
    
    function Invitation_Point_To500 () external view returns(uint256);
    function Invitation_Point_To1000 () external view returns(uint256);
    function Invitation_Point_To2000 () external view returns(uint256);
    function Invitation_Point_To3000 () external view returns(uint256);
    function Invitation_Point_To5000 () external view returns(uint256);
    
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
    
    function Star1Reach_Invita_5_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_6_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_7_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_8_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_9_Gade4 () external view returns(uint256);
    function Star1Reach_Invita_10_Gade4 () external view returns(uint256);
    
    function Star2Reach_Invita_3_Star1 () external view returns(uint256);
    function Star2Reach_Invita_4_Star1 () external view returns(uint256);
    function Star2Reach_Invita_5_Star1 () external view returns(uint256);
    function Star2Reach_Invita_6_Star1 () external view returns(uint256);
    function Star2Reach_Invita_7_Star1 () external view returns(uint256);
    
    function Star1Keep_Invita_1_Gade4 () external view returns(uint256);
    function Star1Keep_Invita_2_Gade4 () external view returns(uint256);
    function Star1Keep_Invita_3_Gade4 () external view returns(uint256);
    function Star1Keep_Invita_4_Gade4 () external view returns(uint256);
    function Star1Keep_Invita_5_Gade4 () external view returns(uint256);
    
    function Star2Keep_Invita_3_Gade4 () external view returns(uint256);
    function Star2Keep_Invita_4_Gade4 () external view returns(uint256);
    function Star2Keep_Invita_5_Gade4 () external view returns(uint256);
    function Star2Keep_Invita_6_Gade4 () external view returns(uint256);
    function Star2Keep_Invita_7_Gade4 () external view returns(uint256);
    
    
    function Star1Burn_rate_12_Percent () external view returns(uint256);
    function Star1Burn_rate_14_Percent () external view returns(uint256);
    function Star1Burn_rate_16_Percent () external view returns(uint256);
    function Star1Burn_rate_18_Percent () external view returns(uint256);
    function Star1Burn_rate_20_Percent () external view returns(uint256);
   
    
    function Star2Burn_rate_8_Percent () external view returns(uint256);
    function Star2Burn_rate_10_Percent () external view returns(uint256);
    function Star2Burn_rate_12_Percent () external view returns(uint256);
    function Star2Burn_rate_14_Percent () external view returns(uint256);
    function Star2Burn_rate_16_Percent () external view returns(uint256);
    
    
}

contract Voting1 {
    
    
    IBEP21 Voting2;
    IBEP21 Voting3;
    IBEP21 Voting4;
    address Admin;
   
    
    constructor() {Admin=msg.sender;}


    function SetToken(address _Voting2,address _Voting3,address _Voting4) public  {
      require(Admin==msg.sender);
      Voting2 = IBEP21(_Voting2);  Voting2 = IBEP21(_Voting3); Voting2 = IBEP21(_Voting4);}
   
    function _10500_Invitation_Point_To_500 () public view returns(uint256){return Voting2.Invitation_Point_To500();}
    function _11000_Invitation_Point_To_1000 () public view returns(uint256){return Voting2.Invitation_Point_To1000 ();}
    function _12000_Invitation_Point_To_2000 () public view returns(uint256){return Voting2.Invitation_Point_To2000();}
    function _13000_Invitation_Point_To_3000 () public view returns(uint256){return Voting2.Invitation_Point_To3000();}
    function _15000_Invitation_Point_To_5000 () public view returns(uint256){return Voting2.Invitation_Point_To5000();}
    
    function _20010_Withdraw_PowerBurn_10_Percent () public view returns(uint256){return Voting2.PowerBurn_Withdraw_To10Percent ();}
    function _20020_Withdraw_PowerBurn_20_Percent () public view returns(uint256){return Voting2.PowerBurn_Withdraw_To20Percent ();}
    function _20030_Withdraw_PowerBurn_30_Percent () public view returns(uint256){return Voting2.PowerBurn_Withdraw_To30Percent ();}
    function _20040_Withdraw_PowerBurn_40_Percent () public view returns(uint256){return Voting2.PowerBurn_Withdraw_To40Percent ();}
    function _20050_Withdraw_PowerBurn_50_Percent () public view returns(uint256){return Voting2.PowerBurn_Withdraw_To50Percent ();}
    
    function _30005_Invitation_BonusRatio_5_Percent () public view returns(uint256){return Voting2.Invitation_BonusRatio_To5Percent ();}
    function _30006_Invitation_BonusRatio_6_Percent () public view returns(uint256){return Voting2.Invitation_BonusRatio_To6Percent ();}
    function _30007_Invitation_BonusRatio_7_Percent () public view returns(uint256){return Voting2.Invitation_BonusRatio_To7Percent ();}
    function _30008_Invitation_BonusRatio_8_Percent () public view returns(uint256){return Voting2.Invitation_BonusRatio_To8Percent ();}
    function _30009_Invitation_BonusRatio_9_Percent () public view returns(uint256){return Voting2.Invitation_BonusRatio_To9Percent ();}
    function _30010_Invitation_BonusRatio_10_Percent () public view returns(uint256){return Voting2.Invitation_BonusRatio_To10Percent ();}
    
    function _40005_RewardAcceleRate_5_Percent () public view returns(uint256){return Voting2.RewardAccelerate_5Percent ();}
    function _40010_RewardAcceleRate_10_Percent () public view returns(uint256){return Voting2.RewardAccelerate_10Percent ();}
    function _40015_RewardAcceleRate_15_Percent () public view returns(uint256){return Voting2.RewardAccelerate_15Percent ();}
    function _40020_RewardAcceleRate_20_Percent () public view returns(uint256){return Voting2.RewardAccelerate_20Percent ();}
    function _40025_RewardAcceleRate_25_Percent () public view returns(uint256){return Voting2.RewardAccelerate_25Percent ();}
    
    function _50005_RewardDeceleRate_5_Percent () public view returns(uint256){return Voting3.RewardDecelerate_5Percent ();}
    function _50010_RewardDeceleRate_10_Percent () public view returns(uint256){return Voting3.RewardDecelerate_10Percent ();}
    function _50015_RewardDeceleRate_15_Percent () public view returns(uint256){return Voting3.RewardDecelerate_15Percent ();}
    function _50020_RewardDeceleRate_20_Percent () public view returns(uint256){return Voting3.RewardDecelerate_20Percent ();}
    function _50025_RewardDeceleRate_25_Percent () public view returns(uint256){return Voting3.RewardDecelerate_25Percent ();}
    function _50000_RewardBackToStart_ () public view returns(uint256){return Voting3.RewardDecelerate_0Percent ();}
    
    function _60005_Star1Reach_Invita_5_Gade4 () public view returns(uint256){return Voting3.Star1Reach_Invita_5_Gade4 ();}
    function _60006_Star1Reach_Invita_6_Gade4 () public view returns(uint256){return Voting3.Star1Reach_Invita_6_Gade4 ();}
    function _60007_Star1Reach_Invita_7_Gade4 () public view returns(uint256){return Voting3.Star1Reach_Invita_7_Gade4 ();}
    function _60008_Star1Reach_Invita_8_Gade4 () public view returns(uint256){return Voting3.Star1Reach_Invita_8_Gade4 ();}
    function _60009_Star1Reach_Invita_9_Gade4 () public view returns(uint256){return Voting3.Star1Reach_Invita_9_Gade4 ();}
    function _60010_Star1Reach_Invita_10_Gade4 () public view returns(uint256){return Voting3.Star1Reach_Invita_10_Gade4 ();}
    
    function _70003_Star2Reach_Invita_3_Star1 () public view returns(uint256){return Voting3.Star2Reach_Invita_3_Star1 ();}
    function _70004_Star2Reach_Invita_4_Star1 () public view returns(uint256){return Voting3.Star2Reach_Invita_4_Star1 ();}
    function _70005_Star2Reach_Invita_5_Star1 () public view returns(uint256){return Voting3.Star2Reach_Invita_5_Star1 ();}
    function _70006_Star2Reach_Invita_6_Star1 () public view returns(uint256){return Voting3.Star2Reach_Invita_6_Star1 ();}
    function _70007_Star2Reach_Invita_7_Star1 () public view returns(uint256){return Voting3.Star2Reach_Invita_7_Star1 ();}
    
    function _80001_Star1Keep_Invita_1_Gade4 () public  view returns(uint256){return Voting4.Star1Keep_Invita_1_Gade4();}
    function _80002_Star1Keep_Invita_2_Gade4 () public view returns(uint256){return Voting4.Star1Keep_Invita_2_Gade4 ();}
    function _80003_Star1Keep_Invita_3_Gade4 () public view returns(uint256){return Voting4.Star1Keep_Invita_3_Gade4 ();}
    function _80004_Star1Keep_Invita_4_Gade4 () public view returns(uint256){return Voting4.Star1Keep_Invita_4_Gade4 ();}
    function _80005_Star1Keep_Invita_5_Gade4 () public view returns(uint256){return Voting4.Star1Keep_Invita_5_Gade4 ();}
    
    function _90003_Star2Keep_Invita_3_Gade4 () public view returns(uint256){return Voting4.Star2Keep_Invita_3_Gade4();}
    function _90004_Star2Keep_Invita_4_Gade4 () public view returns(uint256){return Voting4.Star2Keep_Invita_4_Gade4();}
    function _90005_Star2Keep_Invita_5_Gade4 () public view returns(uint256){return Voting4.Star2Keep_Invita_5_Gade4();}
    function _90006_Star2Keep_Invita_6_Gade4 () public view returns(uint256){return Voting4.Star2Keep_Invita_6_Gade4();}
    function _90007_Star2Keep_Invita_7_Gade4 () public view returns(uint256){return Voting4.Star2Keep_Invita_7_Gade4();}
    
    function _100012_Star1Burn_Rate_12_Percent () public view returns(uint256){return Voting4.Star1Burn_rate_12_Percent();}
    function _100014_Star1Burn_Rate_14_Percent () public view returns(uint256){return Voting4.Star1Burn_rate_14_Percent();}
    function _100016_Star1Burn_Rate_16_Percent () public view returns(uint256){return Voting4.Star1Burn_rate_16_Percent();}
    function _100018_Star1Burn_Rate_18_Percent () public view returns(uint256){return Voting4.Star1Burn_rate_18_Percent();}
    function _100020_Star1Burn_Rate_20_Percent () public view returns(uint256){return Voting4.Star1Burn_rate_20_Percent();}
    
    function _110008_Star2Burn_Rate_8_Percent () public view returns(uint256){return Voting4.Star2Burn_rate_8_Percent();}
    function _110010_Star2Burn_Rate_10_Percent () public view returns(uint256){return Voting4.Star2Burn_rate_10_Percent();}
    function _110012_Star2Burn_Rate_12_Percent () public view returns(uint256){return Voting4.Star2Burn_rate_12_Percent();}
    function _110014_Star2Burn_Rate_14_Percent () public view returns(uint256){return Voting4.Star2Burn_rate_14_Percent();}
    function _110016_Star2Burn_Rate_16_Percent () public view returns(uint256){return Voting4.Star2Burn_rate_16_Percent();}
}