/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4;


interface IBEP20 {event Transfer(address indexed from, address indexed to, uint256 value);}

interface IBEP21{ 
    
    function SetRewardRatio(uint256 RewardRatioA,uint256 RewardRatioB) external returns (bool);
    
    function SetStar1Reach(uint256 Star1Reach) external returns (bool);
      
    

    function PowerOf(address account) external view returns (uint256);
    
}

contract Voting3 {
    address Admin;
    address nFTWPower;
    IBEP21  NFTWPower;
    uint256 VotingMX;
    uint256 PowerOf;
    struct Voter{uint256 LastVoting;}
    mapping (address=>Voter) Voters;
    uint256  _70005_RewardAccelerate_5Percent;
    uint256  _70010_RewardAccelerate_10Percent;
    uint256  _70015_RewardAccelerate_15Percent;
    uint256  _70020_RewardAccelerate_20Percent;
    uint256  _70025_RewardAccelerate_25Percent;
    
    uint256  _50005_RewardDecelerate_5Percent;
    uint256  _50010_RewardDecelerate_10Percent;
    uint256  _50015_RewardDecelerate_15Percent;
    uint256  _50020_RewardDecelerate_20Percent;
    uint256  _50025_RewardDecelerate_25Percent;
    uint256  _50000_RewardDecelerate_0Percent;
    
    uint256  _60005_Star1Reach_Invita5Gade4; 
    uint256  _60006_Star1Reach_Invita6Gade4;
    uint256  _60007_Star1Reach_Invita7Gade4;
    uint256  _60008_Star1Reach_Invita8Gade4;
    uint256  _60009_Star1Reach_Invita9Gade4;
    uint256  _60010_Star1Reach_Invita10Gade4;
    
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);


      constructor() {Admin=msg.sender;VotingMX=2;PowerOf=100000;}
      
      function _Voting (address from, address to, uint256 Amount) public  {
        require(nFTWPower==msg.sender);  
        require(from != address(0), 'Voting: transfer from the zero address');
        require(to != address(0), 'Voting: transfer to the zero address');
        require((block.number-Voters[from].LastVoting)<=20*5, 'Voting: you have already voted this option');  
        require(NFTWPower.PowerOf(from) >= PowerOf, 'Voting: your power is not enough');
        
        if(Amount==70005){_70005_RewardAccelerate_5Percent = _70005_RewardAccelerate_5Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==70010){_70010_RewardAccelerate_10Percent = _70010_RewardAccelerate_10Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==70015){_70015_RewardAccelerate_15Percent = _70015_RewardAccelerate_15Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==70020){_70020_RewardAccelerate_20Percent = _70020_RewardAccelerate_20Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==70025){_70025_RewardAccelerate_25Percent = _70025_RewardAccelerate_25Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        
        
        if(Amount==50005){_50005_RewardDecelerate_5Percent = _50005_RewardDecelerate_5Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==50010){_50010_RewardDecelerate_10Percent = _50010_RewardDecelerate_10Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==50015){_50015_RewardDecelerate_15Percent = _50015_RewardDecelerate_15Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==50020){_50020_RewardDecelerate_20Percent = _50020_RewardDecelerate_20Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==50025){_50025_RewardDecelerate_25Percent = _50025_RewardDecelerate_25Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==50000){_50000_RewardDecelerate_0Percent = _50000_RewardDecelerate_0Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}

        if(Amount==60005){_60005_Star1Reach_Invita5Gade4 = _60005_Star1Reach_Invita5Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==60006){_60006_Star1Reach_Invita6Gade4 = _60006_Star1Reach_Invita6Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==60007){_60007_Star1Reach_Invita7Gade4 = _60007_Star1Reach_Invita7Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==60008){_60008_Star1Reach_Invita8Gade4 = _60008_Star1Reach_Invita8Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==60009){_60009_Star1Reach_Invita9Gade4 = _60009_Star1Reach_Invita9Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==60010){_60010_Star1Reach_Invita10Gade4 = _60010_Star1Reach_Invita10Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}


        


        if(_70005_RewardAccelerate_5Percent >= VotingMX&&
        _70005_RewardAccelerate_5Percent > _70010_RewardAccelerate_10Percent&&
        _70005_RewardAccelerate_5Percent > _70015_RewardAccelerate_15Percent&&
        _70005_RewardAccelerate_5Percent > _70020_RewardAccelerate_20Percent&&
        _70005_RewardAccelerate_5Percent > _70025_RewardAccelerate_25Percent&&
        _70005_RewardAccelerate_5Percent > _50005_RewardDecelerate_5Percent&&
        _70005_RewardAccelerate_5Percent > _50010_RewardDecelerate_10Percent&&
        _70005_RewardAccelerate_5Percent > _50015_RewardDecelerate_15Percent&&
        _70005_RewardAccelerate_5Percent > _50020_RewardDecelerate_20Percent&&
        _70005_RewardAccelerate_5Percent > _50025_RewardDecelerate_25Percent&&
        _70005_RewardAccelerate_5Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(1050,1000);}
        
        if(_70010_RewardAccelerate_10Percent >= VotingMX&&
        _70010_RewardAccelerate_10Percent > _70005_RewardAccelerate_5Percent&&
        _70010_RewardAccelerate_10Percent > _70015_RewardAccelerate_15Percent&&
        _70010_RewardAccelerate_10Percent > _70020_RewardAccelerate_20Percent&&
        _70010_RewardAccelerate_10Percent > _70025_RewardAccelerate_25Percent&&
        _70010_RewardAccelerate_10Percent > _50005_RewardDecelerate_5Percent&&
        _70010_RewardAccelerate_10Percent > _50010_RewardDecelerate_10Percent&&
        _70010_RewardAccelerate_10Percent > _50015_RewardDecelerate_15Percent&&
        _70010_RewardAccelerate_10Percent > _50020_RewardDecelerate_20Percent&&
        _70010_RewardAccelerate_10Percent > _50025_RewardDecelerate_25Percent&&
        _70010_RewardAccelerate_10Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(1100,1000);}
        
        if(_70015_RewardAccelerate_15Percent >= VotingMX&&
        _70015_RewardAccelerate_15Percent > _70010_RewardAccelerate_10Percent&&
        _70015_RewardAccelerate_15Percent > _70005_RewardAccelerate_5Percent&&
        _70015_RewardAccelerate_15Percent > _70020_RewardAccelerate_20Percent&&
        _70015_RewardAccelerate_15Percent > _70025_RewardAccelerate_25Percent&&
        _70015_RewardAccelerate_15Percent > _50005_RewardDecelerate_5Percent&&
        _70015_RewardAccelerate_15Percent > _50010_RewardDecelerate_10Percent&&
        _70015_RewardAccelerate_15Percent > _50015_RewardDecelerate_15Percent&&
        _70015_RewardAccelerate_15Percent > _50020_RewardDecelerate_20Percent&&
        _70015_RewardAccelerate_15Percent > _50025_RewardDecelerate_25Percent&&
        _70015_RewardAccelerate_15Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(1150,1000);}
        
        if(_70020_RewardAccelerate_20Percent >= VotingMX&&
        _70020_RewardAccelerate_20Percent > _70010_RewardAccelerate_10Percent&&
        _70020_RewardAccelerate_20Percent > _70015_RewardAccelerate_15Percent&&
        _70020_RewardAccelerate_20Percent > _70005_RewardAccelerate_5Percent&&
        _70020_RewardAccelerate_20Percent > _70025_RewardAccelerate_25Percent&&
        _70020_RewardAccelerate_20Percent > _50005_RewardDecelerate_5Percent&&
        _70020_RewardAccelerate_20Percent > _50010_RewardDecelerate_10Percent&&
        _70020_RewardAccelerate_20Percent > _50015_RewardDecelerate_15Percent&&
        _70020_RewardAccelerate_20Percent > _50020_RewardDecelerate_20Percent&&
        _70020_RewardAccelerate_20Percent > _50025_RewardDecelerate_25Percent&&
        _70020_RewardAccelerate_20Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(1200,1000);}
        
        if(_70025_RewardAccelerate_25Percent >= VotingMX&&
        _70025_RewardAccelerate_25Percent > _70010_RewardAccelerate_10Percent&&
        _70025_RewardAccelerate_25Percent > _70015_RewardAccelerate_15Percent&&
        _70025_RewardAccelerate_25Percent > _70020_RewardAccelerate_20Percent&&
        _70025_RewardAccelerate_25Percent > _70005_RewardAccelerate_5Percent&&
        _70025_RewardAccelerate_25Percent > _50005_RewardDecelerate_5Percent&&
        _70025_RewardAccelerate_25Percent > _50010_RewardDecelerate_10Percent&&
        _70025_RewardAccelerate_25Percent > _50015_RewardDecelerate_15Percent&&
        _70025_RewardAccelerate_25Percent > _50020_RewardDecelerate_20Percent&&
        _70025_RewardAccelerate_25Percent > _50025_RewardDecelerate_25Percent&&
        _70025_RewardAccelerate_25Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(1250,1000);}
        
        if(_50005_RewardDecelerate_5Percent >= VotingMX&&
        _50005_RewardDecelerate_5Percent > _70010_RewardAccelerate_10Percent&&
        _50005_RewardDecelerate_5Percent > _70015_RewardAccelerate_15Percent&&
        _50005_RewardDecelerate_5Percent > _70020_RewardAccelerate_20Percent&&
        _50005_RewardDecelerate_5Percent > _70025_RewardAccelerate_25Percent&&
        _50005_RewardDecelerate_5Percent > _70005_RewardAccelerate_5Percent&&
        _50005_RewardDecelerate_5Percent > _50010_RewardDecelerate_10Percent&&
        _50005_RewardDecelerate_5Percent > _50015_RewardDecelerate_15Percent&&
        _50005_RewardDecelerate_5Percent > _50020_RewardDecelerate_20Percent&&
        _50005_RewardDecelerate_5Percent > _50025_RewardDecelerate_25Percent&&
        _50005_RewardDecelerate_5Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(950,1000);}
        
        if(_50010_RewardDecelerate_10Percent >= VotingMX&&
        _50010_RewardDecelerate_10Percent > _70010_RewardAccelerate_10Percent&&
        _50010_RewardDecelerate_10Percent > _70015_RewardAccelerate_15Percent&&
        _50010_RewardDecelerate_10Percent > _70020_RewardAccelerate_20Percent&&
        _50010_RewardDecelerate_10Percent > _70025_RewardAccelerate_25Percent&&
        _50010_RewardDecelerate_10Percent > _50005_RewardDecelerate_5Percent&&
        _50010_RewardDecelerate_10Percent > _70005_RewardAccelerate_5Percent&&
        _50010_RewardDecelerate_10Percent > _50015_RewardDecelerate_15Percent&&
        _50010_RewardDecelerate_10Percent > _50020_RewardDecelerate_20Percent&&
        _50010_RewardDecelerate_10Percent > _50025_RewardDecelerate_25Percent&&
        _50010_RewardDecelerate_10Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(900,1000);}
        
        if(_50015_RewardDecelerate_15Percent >= VotingMX&&
        _50015_RewardDecelerate_15Percent > _70010_RewardAccelerate_10Percent&&
        _50015_RewardDecelerate_15Percent > _70015_RewardAccelerate_15Percent&&
        _50015_RewardDecelerate_15Percent > _70020_RewardAccelerate_20Percent&&
        _50015_RewardDecelerate_15Percent > _70025_RewardAccelerate_25Percent&&
        _50015_RewardDecelerate_15Percent > _50005_RewardDecelerate_5Percent&&
        _50015_RewardDecelerate_15Percent > _50010_RewardDecelerate_10Percent&&
        _50015_RewardDecelerate_15Percent > _70005_RewardAccelerate_5Percent&&
        _50015_RewardDecelerate_15Percent > _50020_RewardDecelerate_20Percent&&
        _50015_RewardDecelerate_15Percent > _50025_RewardDecelerate_25Percent&&
        _50015_RewardDecelerate_15Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(850,1000);}
        
        if(_50020_RewardDecelerate_20Percent >= VotingMX&&
        _50020_RewardDecelerate_20Percent > _70010_RewardAccelerate_10Percent&&
        _50020_RewardDecelerate_20Percent > _70015_RewardAccelerate_15Percent&&
        _50020_RewardDecelerate_20Percent > _70020_RewardAccelerate_20Percent&&
        _50020_RewardDecelerate_20Percent > _70025_RewardAccelerate_25Percent&&
        _50020_RewardDecelerate_20Percent > _50005_RewardDecelerate_5Percent&&
        _50020_RewardDecelerate_20Percent > _50010_RewardDecelerate_10Percent&&
        _50020_RewardDecelerate_20Percent > _50015_RewardDecelerate_15Percent&&
        _50020_RewardDecelerate_20Percent > _70005_RewardAccelerate_5Percent&&
        _50020_RewardDecelerate_20Percent > _50025_RewardDecelerate_25Percent&&
        _50020_RewardDecelerate_20Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(800,1000);}
        
        if(_50025_RewardDecelerate_25Percent >= VotingMX&&
        _50025_RewardDecelerate_25Percent > _70010_RewardAccelerate_10Percent&&
        _50025_RewardDecelerate_25Percent > _70015_RewardAccelerate_15Percent&&
        _50025_RewardDecelerate_25Percent > _70020_RewardAccelerate_20Percent&&
        _50025_RewardDecelerate_25Percent > _70025_RewardAccelerate_25Percent&&
        _50025_RewardDecelerate_25Percent > _50005_RewardDecelerate_5Percent&&
        _50025_RewardDecelerate_25Percent > _50010_RewardDecelerate_10Percent&&
        _50025_RewardDecelerate_25Percent > _50015_RewardDecelerate_15Percent&&
        _50025_RewardDecelerate_25Percent > _50020_RewardDecelerate_20Percent&&
        _50025_RewardDecelerate_25Percent > _70005_RewardAccelerate_5Percent&&
        _50025_RewardDecelerate_25Percent > _50000_RewardDecelerate_0Percent)
        {NFTWPower.SetRewardRatio(750,1000);}
        
        if(_50000_RewardDecelerate_0Percent >= VotingMX&&
        _50000_RewardDecelerate_0Percent > _70010_RewardAccelerate_10Percent&&
        _50000_RewardDecelerate_0Percent > _70015_RewardAccelerate_15Percent&&
        _50000_RewardDecelerate_0Percent > _70020_RewardAccelerate_20Percent&&
        _50000_RewardDecelerate_0Percent > _70025_RewardAccelerate_25Percent&&
        _50000_RewardDecelerate_0Percent > _50005_RewardDecelerate_5Percent&&
        _50000_RewardDecelerate_0Percent > _50010_RewardDecelerate_10Percent&&
        _50000_RewardDecelerate_0Percent > _50015_RewardDecelerate_15Percent&&
        _50000_RewardDecelerate_0Percent > _50020_RewardDecelerate_20Percent&&
        _50000_RewardDecelerate_0Percent > _50025_RewardDecelerate_25Percent&&
        _50000_RewardDecelerate_0Percent > _70005_RewardAccelerate_5Percent)
        {NFTWPower.SetRewardRatio(1000,1000);}
        
        
        if(_60005_Star1Reach_Invita5Gade4 >= VotingMX&&
        _60005_Star1Reach_Invita5Gade4 > _60006_Star1Reach_Invita6Gade4&&
        _60005_Star1Reach_Invita5Gade4 > _60007_Star1Reach_Invita7Gade4&&
        _60005_Star1Reach_Invita5Gade4 > _60008_Star1Reach_Invita8Gade4&&
        _60005_Star1Reach_Invita5Gade4 > _60009_Star1Reach_Invita9Gade4&&
        _60005_Star1Reach_Invita5Gade4 > _60010_Star1Reach_Invita10Gade4)
        {NFTWPower.SetStar1Reach(5);}
        
        if(_60006_Star1Reach_Invita6Gade4 >= VotingMX&&
        _60006_Star1Reach_Invita6Gade4 > _60005_Star1Reach_Invita5Gade4&&
        _60006_Star1Reach_Invita6Gade4 > _60007_Star1Reach_Invita7Gade4&&
        _60006_Star1Reach_Invita6Gade4 > _60008_Star1Reach_Invita8Gade4&&
        _60006_Star1Reach_Invita6Gade4 > _60009_Star1Reach_Invita9Gade4&&
        _60006_Star1Reach_Invita6Gade4 > _60010_Star1Reach_Invita10Gade4)
        {NFTWPower.SetStar1Reach(6);}
        
        if(_60007_Star1Reach_Invita7Gade4 >= VotingMX&&
        _60007_Star1Reach_Invita7Gade4 > _60006_Star1Reach_Invita6Gade4&&
        _60007_Star1Reach_Invita7Gade4 > _60005_Star1Reach_Invita5Gade4&&
        _60007_Star1Reach_Invita7Gade4 > _60008_Star1Reach_Invita8Gade4&&
        _60007_Star1Reach_Invita7Gade4 > _60009_Star1Reach_Invita9Gade4&&
        _60007_Star1Reach_Invita7Gade4 > _60010_Star1Reach_Invita10Gade4)
        {NFTWPower.SetStar1Reach(7);}
        
        if(_60008_Star1Reach_Invita8Gade4 >= VotingMX&&
        _60008_Star1Reach_Invita8Gade4 > _60006_Star1Reach_Invita6Gade4&&
        _60008_Star1Reach_Invita8Gade4 > _60007_Star1Reach_Invita7Gade4&&
        _60008_Star1Reach_Invita8Gade4 > _60005_Star1Reach_Invita5Gade4&&
        _60008_Star1Reach_Invita8Gade4 > _60009_Star1Reach_Invita9Gade4&&
        _60008_Star1Reach_Invita8Gade4 > _60010_Star1Reach_Invita10Gade4)
        {NFTWPower.SetStar1Reach(8);}
        
        if(_60009_Star1Reach_Invita9Gade4 >= VotingMX&&
        _60009_Star1Reach_Invita9Gade4 > _60006_Star1Reach_Invita6Gade4&&
        _60009_Star1Reach_Invita9Gade4 > _60007_Star1Reach_Invita7Gade4&&
        _60009_Star1Reach_Invita9Gade4 > _60008_Star1Reach_Invita8Gade4&&
        _60009_Star1Reach_Invita9Gade4 > _60005_Star1Reach_Invita5Gade4&&
        _60009_Star1Reach_Invita9Gade4 > _60010_Star1Reach_Invita10Gade4)
        {NFTWPower.SetStar1Reach(9);}
        
        if(_60010_Star1Reach_Invita10Gade4 >= VotingMX&&
        _60010_Star1Reach_Invita10Gade4 > _60006_Star1Reach_Invita6Gade4&&
        _60010_Star1Reach_Invita10Gade4 > _60007_Star1Reach_Invita7Gade4&&
        _60010_Star1Reach_Invita10Gade4 > _60008_Star1Reach_Invita8Gade4&&
        _60010_Star1Reach_Invita10Gade4 > _60009_Star1Reach_Invita9Gade4&&
        _60010_Star1Reach_Invita10Gade4 > _60005_Star1Reach_Invita5Gade4)
        {NFTWPower.SetStar1Reach(10);}

        
        
    

    }
    
    function SetToken(address _NFTWPower) public  {
      require(Admin==msg.sender);
      NFTWPower = IBEP21(_NFTWPower);nFTWPower = _NFTWPower;}
      
    function SetVotingMX(uint256 _VotingMX,uint256 _PowerOf) public  {
      require(Admin==msg.sender);
      VotingMX = _VotingMX; PowerOf = _PowerOf;}     
    
    function RewardAccelerate_5Percent () public view returns(uint256){return _70005_RewardAccelerate_5Percent;}
    function RewardAccelerate_10Percent () public view returns(uint256){return _70010_RewardAccelerate_10Percent;}
    function RewardAccelerate_15Percent () public view returns(uint256){return _70015_RewardAccelerate_15Percent;}
    function RewardAccelerate_20Percent () public view returns(uint256){return _70020_RewardAccelerate_20Percent;}
    function RewardAccelerate_25Percent () public view returns(uint256){return _70025_RewardAccelerate_25Percent;}
    
    function RewardDecelerate_5Percent () public view returns(uint256){return _50005_RewardDecelerate_5Percent;}
    function RewardDecelerate_10Percent () public view returns(uint256){return _50010_RewardDecelerate_10Percent;}
    function RewardDecelerate_15Percent () public view returns(uint256){return _50015_RewardDecelerate_15Percent;}
    function RewardDecelerate_20Percent () public view returns(uint256){return _50020_RewardDecelerate_20Percent;}
    function RewardDecelerate_25Percent () public view returns(uint256){return _50025_RewardDecelerate_25Percent;}
    function RewardDecelerate_0Percent () public view returns(uint256){return _50000_RewardDecelerate_0Percent;}
    
    function Star1Reach_Invita_5_Gade4 () public view returns(uint256){return _60005_Star1Reach_Invita5Gade4;}
    function Star1Reach_Invita_6_Gade4 () public view returns(uint256){return _60006_Star1Reach_Invita6Gade4;}
    function Star1Reach_Invita_7_Gade4 () public view returns(uint256){return _60007_Star1Reach_Invita7Gade4;}
    function Star1Reach_Invita_8_Gade4 () public view returns(uint256){return _60008_Star1Reach_Invita8Gade4;}
    function Star1Reach_Invita_9_Gade4 () public view returns(uint256){return _60009_Star1Reach_Invita9Gade4;}
    function Star1Reach_Invita_10_Gade4 () public view returns(uint256){return _60010_Star1Reach_Invita10Gade4;}


}