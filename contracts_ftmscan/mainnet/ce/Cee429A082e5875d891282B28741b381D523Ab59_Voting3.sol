/**
 *Submitted for verification at FtmScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;


interface IBEP21{ 
    function SetStar3Reach(uint256 Star3Reach) external returns (bool);

    function SetStar4Reach(uint256 Star4Reach) external returns (bool);

    function SetRewardRatio(uint256 RewardRatioA,uint256 RewardRatioB) external returns (bool);
    
    function SetStar1Reach(uint256 Star1Reach) external returns (bool);

    function VotersAll() external view returns (uint256);
      
}

contract Voting3 {
    address Admin;
    address nFTWPower;
    IBEP21  NFTWPower;
    uint256 VotingMX;
    
    uint256  _4005_RewardAccelerate_5Percent;
    uint256  _4010_RewardAccelerate_10Percent;
    uint256  _4015_RewardAccelerate_15Percent;
    uint256  _4020_RewardAccelerate_20Percent;
    uint256  _4025_RewardAccelerate_25Percent;
    
    uint256  _5005_RewardDecelerate_5Percent;
    uint256  _5010_RewardDecelerate_10Percent;
    uint256  _5015_RewardDecelerate_15Percent;
    uint256  _5020_RewardDecelerate_20Percent;
    uint256  _5025_RewardDecelerate_25Percent;
    uint256  _5000_RewardDecelerate_0Percent;
    
    uint256  _6003_Star1Reach_Invita_3_Gade4; 
    uint256  _6004_Star1Reach_Invita_4_Gade4;
    uint256  _6005_Star1Reach_Invita_5_Gade4;
    uint256  _6006_Star1Reach_Invita_6_Gade4;
    uint256  _6007_Star1Reach_Invita_7_Gade4;

    uint256  _8003_Star3Reach_Invita_3_Star1;
    uint256  _8004_Star3Reach_Invita_4_Star1;
    uint256  _8005_Star3Reach_Invita_5_Star1;
    uint256  _8006_Star3Reach_Invita_6_Star1;
    uint256  _8007_Star3Reach_Invita_7_Star1;
    
    uint256  _9008_Star4Reach_Invita_8_Star1;
    uint256  _9009_Star4Reach_Invita_9_Star1;
    uint256  _9010_Star4Reach_Invita_10_Star1;
    uint256  _9011_Star4Reach_Invita_11_Star1;
    uint256  _9012_Star4Reach_Invita_12_Star1;
    
    
    
      constructor(address Voting1)public{Admin = Voting1;}
      
      function _VotingB (uint256 Amount) external{
        require(nFTWPower==msg.sender);  
        if(Amount==4005){_4005_RewardAccelerate_5Percent = _4005_RewardAccelerate_5Percent+1;
        }
        if(Amount==4010){_4010_RewardAccelerate_10Percent = _4010_RewardAccelerate_10Percent+1;
        }
        if(Amount==4015){_4015_RewardAccelerate_15Percent = _4015_RewardAccelerate_15Percent+1;
        }
        if(Amount==4020){_4020_RewardAccelerate_20Percent = _4020_RewardAccelerate_20Percent+1;
        }
        if(Amount==4025){_4025_RewardAccelerate_25Percent = _4025_RewardAccelerate_25Percent+1;
        }
        
        
        if(Amount==5005){_5005_RewardDecelerate_5Percent = _5005_RewardDecelerate_5Percent+1;
        }
        if(Amount==5010){_5010_RewardDecelerate_10Percent = _5010_RewardDecelerate_10Percent+1;
        }
        if(Amount==5015){_5015_RewardDecelerate_15Percent = _5015_RewardDecelerate_15Percent+1;
        }
        if(Amount==5020){_5020_RewardDecelerate_20Percent = _5020_RewardDecelerate_20Percent+1;
        }
        if(Amount==5025){_5025_RewardDecelerate_25Percent = _5025_RewardDecelerate_25Percent+1;
        }
        if(Amount==5000){_5000_RewardDecelerate_0Percent = _5000_RewardDecelerate_0Percent+1;
        }

        if(Amount==6003){_6003_Star1Reach_Invita_3_Gade4 = _6003_Star1Reach_Invita_3_Gade4+1;}
        if(Amount==6004){_6004_Star1Reach_Invita_4_Gade4 = _6004_Star1Reach_Invita_4_Gade4+1;}
        if(Amount==6005){_6005_Star1Reach_Invita_5_Gade4 = _6005_Star1Reach_Invita_5_Gade4+1;}
        if(Amount==6006){_6006_Star1Reach_Invita_6_Gade4 = _6006_Star1Reach_Invita_6_Gade4+1;}
        if(Amount==6007){_6007_Star1Reach_Invita_7_Gade4 = _6007_Star1Reach_Invita_7_Gade4+1;}
        
        if(Amount==8003){_8003_Star3Reach_Invita_3_Star1 = _8003_Star3Reach_Invita_3_Star1+1;}
        if(Amount==8004){_8004_Star3Reach_Invita_4_Star1 = _8004_Star3Reach_Invita_4_Star1+1;}
        if(Amount==8005){_8005_Star3Reach_Invita_5_Star1 = _8005_Star3Reach_Invita_5_Star1+1;}
        if(Amount==8006){_8006_Star3Reach_Invita_6_Star1 = _8006_Star3Reach_Invita_6_Star1+1;}
        if(Amount==8007){_8007_Star3Reach_Invita_7_Star1 = _8007_Star3Reach_Invita_7_Star1+1;}

        if(Amount==9008){_9008_Star4Reach_Invita_8_Star1 = _9008_Star4Reach_Invita_8_Star1+1;}
        if(Amount==9009){_9009_Star4Reach_Invita_9_Star1 = _9009_Star4Reach_Invita_9_Star1+1;}
        if(Amount==9010){_9010_Star4Reach_Invita_10_Star1 = _9010_Star4Reach_Invita_10_Star1+1;}
        if(Amount==9011){_9011_Star4Reach_Invita_11_Star1 = _9011_Star4Reach_Invita_11_Star1+1;}
        if(Amount==9012){_9012_Star4Reach_Invita_12_Star1 = _9012_Star4Reach_Invita_12_Star1+1;}

        


        if(_4005_RewardAccelerate_5Percent >= VotingMX&&_4005_RewardAccelerate_5Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(1050,1000);_4005_RewardAccelerate_5Percent=0;}
        
        if(_4010_RewardAccelerate_10Percent >= VotingMX&&_4010_RewardAccelerate_10Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(1100,1000);_4010_RewardAccelerate_10Percent=0;}
        
        if(_4015_RewardAccelerate_15Percent >= VotingMX&&_4015_RewardAccelerate_15Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(1150,1000);_4015_RewardAccelerate_15Percent=0;}
        
        if(_4020_RewardAccelerate_20Percent >= VotingMX&&_4020_RewardAccelerate_20Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(1200,1000);_4020_RewardAccelerate_20Percent=0;}
        
        if(_4025_RewardAccelerate_25Percent >= VotingMX&&_4025_RewardAccelerate_25Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(1250,1000);_4025_RewardAccelerate_25Percent=0;}
        
        if(_5005_RewardDecelerate_5Percent >= VotingMX&&_5005_RewardDecelerate_5Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(950,1000);_5005_RewardDecelerate_5Percent=0;}
        
        if(_5010_RewardDecelerate_10Percent >= VotingMX&&_5010_RewardDecelerate_10Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(900,1000);_5010_RewardDecelerate_10Percent=0;}
        
        if(_5015_RewardDecelerate_15Percent >= VotingMX&&_5015_RewardDecelerate_15Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(850,1000);_5015_RewardDecelerate_15Percent=0;}
        
        if(_5020_RewardDecelerate_20Percent >= VotingMX&&_5020_RewardDecelerate_20Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(800,1000);_5020_RewardDecelerate_20Percent=0;}
        
        if(_5025_RewardDecelerate_25Percent >= VotingMX&&_5025_RewardDecelerate_25Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(750,1000);_5025_RewardDecelerate_25Percent=0;}
        
        if(_5000_RewardDecelerate_0Percent >= VotingMX&&_5000_RewardDecelerate_0Percent >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetRewardRatio(1000,1000);_5000_RewardDecelerate_0Percent=0;}
        
        
        if(_6003_Star1Reach_Invita_3_Gade4 >= VotingMX&&_6003_Star1Reach_Invita_3_Gade4 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(3);_6003_Star1Reach_Invita_3_Gade4=0;}
        if(_6004_Star1Reach_Invita_4_Gade4 >= VotingMX&&_6004_Star1Reach_Invita_4_Gade4 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(4);_6004_Star1Reach_Invita_4_Gade4=0;}
        if(_6005_Star1Reach_Invita_5_Gade4 >= VotingMX&&_6005_Star1Reach_Invita_5_Gade4 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(5);_6005_Star1Reach_Invita_5_Gade4=0;}
        if(_6006_Star1Reach_Invita_6_Gade4 >= VotingMX&&_6006_Star1Reach_Invita_6_Gade4 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(6);_6006_Star1Reach_Invita_6_Gade4=0;}
        if(_6007_Star1Reach_Invita_7_Gade4 >= VotingMX&&_6007_Star1Reach_Invita_7_Gade4 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(7);_6007_Star1Reach_Invita_7_Gade4=0;}
        
        if(_8003_Star3Reach_Invita_3_Star1 >= VotingMX&&_8003_Star3Reach_Invita_3_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(3);_8003_Star3Reach_Invita_3_Star1=0;}
        if(_8004_Star3Reach_Invita_4_Star1 >= VotingMX&&_8004_Star3Reach_Invita_4_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(4);_8004_Star3Reach_Invita_4_Star1=0;}
        if(_8005_Star3Reach_Invita_5_Star1 >= VotingMX&&_8005_Star3Reach_Invita_5_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(5);_8005_Star3Reach_Invita_5_Star1=0;}
        if(_8006_Star3Reach_Invita_6_Star1 >= VotingMX&&_8006_Star3Reach_Invita_6_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(6);_8006_Star3Reach_Invita_6_Star1=0;}
        if(_8007_Star3Reach_Invita_7_Star1 >= VotingMX&&_8007_Star3Reach_Invita_7_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(7);_8007_Star3Reach_Invita_7_Star1=0;}

        if(_9008_Star4Reach_Invita_8_Star1 >= VotingMX&&_9008_Star4Reach_Invita_8_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(8);_9008_Star4Reach_Invita_8_Star1=0;}
        if(_9009_Star4Reach_Invita_9_Star1 >= VotingMX&&_9009_Star4Reach_Invita_9_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(9);_9009_Star4Reach_Invita_9_Star1=0;}
        if(_9010_Star4Reach_Invita_10_Star1 >= VotingMX&&_9010_Star4Reach_Invita_10_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(10);_9010_Star4Reach_Invita_10_Star1=0;}
        if(_9011_Star4Reach_Invita_11_Star1 >= VotingMX&&_9011_Star4Reach_Invita_11_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(11);_9011_Star4Reach_Invita_11_Star1=0;}
        if(_9012_Star4Reach_Invita_12_Star1 >= VotingMX&&_9012_Star4Reach_Invita_12_Star1 >=NFTWPower.VotersAll()/3)
        {NFTWPower.SetStar1Reach(12);_9012_Star4Reach_Invita_12_Star1=0;}

    }
    
    function SetToken(address _NFTWPower) external returns(bool){
      require(Admin==msg.sender);
      NFTWPower = IBEP21(_NFTWPower);nFTWPower = _NFTWPower;return true;}
      
    function SetVotingMX(uint256 _VotingMX) external returns(bool){
      require(Admin==msg.sender);
      VotingMX = _VotingMX;return true;}     
    
    function RewardAccelerate_5Percent () external view returns(uint256){return _4005_RewardAccelerate_5Percent;}
    function RewardAccelerate_10Percent () external view returns(uint256){return _4010_RewardAccelerate_10Percent;}
    function RewardAccelerate_15Percent () external view returns(uint256){return _4015_RewardAccelerate_15Percent;}
    function RewardAccelerate_20Percent () external view returns(uint256){return _4020_RewardAccelerate_20Percent;}
    function RewardAccelerate_25Percent () external view returns(uint256){return _4025_RewardAccelerate_25Percent;}
    
    function RewardDecelerate_5Percent () external view returns(uint256){return _5005_RewardDecelerate_5Percent;}
    function RewardDecelerate_10Percent () external view returns(uint256){return _5010_RewardDecelerate_10Percent;}
    function RewardDecelerate_15Percent () external view returns(uint256){return _5015_RewardDecelerate_15Percent;}
    function RewardDecelerate_20Percent () external view returns(uint256){return _5020_RewardDecelerate_20Percent;}
    function RewardDecelerate_25Percent () external view returns(uint256){return _5025_RewardDecelerate_25Percent;}
    function RewardDecelerate_0Percent () external view returns(uint256){return _5000_RewardDecelerate_0Percent;}
    
    function Star1Reach_Invita_3_Gade4 () external view returns(uint256){return _6003_Star1Reach_Invita_3_Gade4;}
    function Star1Reach_Invita_4_Gade4 () external view returns(uint256){return _6004_Star1Reach_Invita_4_Gade4;}
    function Star1Reach_Invita_5_Gade4 () external view returns(uint256){return _6005_Star1Reach_Invita_5_Gade4;}
    function Star1Reach_Invita_6_Gade4 () external view returns(uint256){return _6006_Star1Reach_Invita_6_Gade4;}
    function Star1Reach_Invita_7_Gade4 () external view returns(uint256){return _6007_Star1Reach_Invita_7_Gade4;}

    function Star3Reach_Invita_3_Star1 () external view returns(uint256){return _8003_Star3Reach_Invita_3_Star1;}
    function Star3Reach_Invita_4_Star1 () external view returns(uint256){return _8004_Star3Reach_Invita_4_Star1;}
    function Star3Reach_Invita_5_Star1 () external view returns(uint256){return _8005_Star3Reach_Invita_5_Star1;}
    function Star3Reach_Invita_6_Star1 () external view returns(uint256){return _8006_Star3Reach_Invita_6_Star1;}
    function Star3Reach_Invita_7_Star1 () external view returns(uint256){return _8007_Star3Reach_Invita_7_Star1;}

    function Star4Reach_Invita_8_Star1 () external view returns(uint256){return _9008_Star4Reach_Invita_8_Star1;}
    function Star4Reach_Invita_9_Star1 () external view returns(uint256){return _9009_Star4Reach_Invita_9_Star1;}
    function Star4Reach_Invita_10_Star1 () external view returns(uint256){return _9010_Star4Reach_Invita_10_Star1;}
    function Star4Reach_Invita_11_Star1 () external view returns(uint256){return _9011_Star4Reach_Invita_11_Star1;}
    function Star4Reach_Invita_12_Star1 () external view returns(uint256){return _9012_Star4Reach_Invita_12_Star1;}

}