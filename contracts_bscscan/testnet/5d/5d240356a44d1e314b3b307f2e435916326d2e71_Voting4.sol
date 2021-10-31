/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4;


interface IBEP20 {event Transfer(address indexed from, address indexed to, uint256 value);}

interface IBEP21{ 
    
    
    function SetStar1BurnRate(uint256 Star1BurnRate) external returns (bool);
      
    function SetStar2BurnRate(uint256 Star2BurnRate) external returns (bool);
    
    function SetStar1Keep(uint256 Star1Keep) external returns (bool);

    function SetStar2Keep(uint256 Star2Keep) external returns (bool);
    
    function PowerOf(address account) external view returns (uint256);
    
}

contract Voting4 {
    address Admin;
    address nFTWPower;
    IBEP21  NFTWPower;
    uint256 VotingMX;
    uint256 PowerOf;
    struct Voter{uint256 LastVoting;}
    mapping (address=>Voter) Voters;
    uint256 _80001_Star1Keep_Invita1Gade4;
    uint256 _80002_Star1Keep_Invita2Gade4;
    uint256 _80003_Star1Keep_Invita3Gade4;
    uint256 _80004_Star1Keep_Invita4Gade4;
    uint256 _80005_Star1Keep_Invita5Gade4;
    
    uint256 _90003_Star2Keep_Invita3Gade4;
    uint256 _90004_Star2Keep_Invita4Gade4;
    uint256 _90005_Star2Keep_Invita5Gade4;
    uint256 _90006_Star2Keep_Invita6Gade4;
    uint256 _90007_Star2Keep_Invita7Gade4;

    uint256 _100012_Star1Burn_rate_12Percent;
    uint256 _100014_Star1Burn_rate_14Percent;
    uint256 _100016_Star1Burn_rate_16Percent;
    uint256 _100018_Star1Burn_rate_18Percent;
    uint256 _100020_Star1Burn_rate_20Percent;

    uint256 _110008_Star2Burn_rate_8Percent;
    uint256 _110010_Star2Burn_rate_10Percent;
    uint256 _110012_Star2Burn_rate_12Percent;
    uint256 _110014_Star2Burn_rate_14Percent;
    uint256 _110016_Star2Burn_rate_16Percent;
    
    event Transfer(address indexed from, address indexed to, uint256 value);


      constructor() {Admin=msg.sender;VotingMX=2;PowerOf=100000;}
      
      function _Voting (address from, address to, uint256 Amount) public  {
        require(nFTWPower==msg.sender);  
        require(from != address(0), 'Voting: transfer from the zero address');
        require(to != address(0), 'Voting: transfer to the zero address');
        require((block.number-Voters[from].LastVoting)<=20*5, 'Voting: you have already voted this option');  
        require(NFTWPower.PowerOf(from) >= PowerOf, 'Voting: your power is not enough');
        if(Amount==80001){_80001_Star1Keep_Invita1Gade4 = _80001_Star1Keep_Invita1Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==80002){_80002_Star1Keep_Invita2Gade4 = _80002_Star1Keep_Invita2Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==80003){_80003_Star1Keep_Invita3Gade4 = _80003_Star1Keep_Invita3Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==80004){_80004_Star1Keep_Invita4Gade4 = _80004_Star1Keep_Invita4Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==80005){_80005_Star1Keep_Invita5Gade4 = _80005_Star1Keep_Invita5Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}


        if(Amount==90003){_90003_Star2Keep_Invita3Gade4 = _90003_Star2Keep_Invita3Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==90004){_90004_Star2Keep_Invita4Gade4 = _90004_Star2Keep_Invita4Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==90005){_90005_Star2Keep_Invita5Gade4 = _90005_Star2Keep_Invita5Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==90006){_90006_Star2Keep_Invita6Gade4 = _90006_Star2Keep_Invita6Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==90007){_90007_Star2Keep_Invita7Gade4 = _90007_Star2Keep_Invita7Gade4+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}

        
        if(Amount==100012){_100012_Star1Burn_rate_12Percent = _100012_Star1Burn_rate_12Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==100014){_100014_Star1Burn_rate_14Percent = _100014_Star1Burn_rate_14Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==100016){_100016_Star1Burn_rate_16Percent = _100016_Star1Burn_rate_16Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==100018){_100018_Star1Burn_rate_18Percent = _100018_Star1Burn_rate_18Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==100020){_100020_Star1Burn_rate_20Percent = _100020_Star1Burn_rate_20Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}


        if(Amount==110008){_110008_Star2Burn_rate_8Percent = _110008_Star2Burn_rate_8Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==110010){_110010_Star2Burn_rate_10Percent = _110010_Star2Burn_rate_10Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==110012){_110012_Star2Burn_rate_12Percent = _110012_Star2Burn_rate_12Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==110014){_110014_Star2Burn_rate_14Percent = _110014_Star2Burn_rate_14Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==110016){_110016_Star2Burn_rate_16Percent = _110016_Star2Burn_rate_16Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}

        if(_80001_Star1Keep_Invita1Gade4 >= VotingMX&&
        _80001_Star1Keep_Invita1Gade4 > _80002_Star1Keep_Invita2Gade4&&
        _80001_Star1Keep_Invita1Gade4 > _80003_Star1Keep_Invita3Gade4&&
        _80001_Star1Keep_Invita1Gade4 > _80004_Star1Keep_Invita4Gade4&&
        _80001_Star1Keep_Invita1Gade4 > _80005_Star1Keep_Invita5Gade4)
        {NFTWPower.SetStar1Keep(1);}

        if(_80002_Star1Keep_Invita2Gade4 >= VotingMX&&
        _80002_Star1Keep_Invita2Gade4 > _80001_Star1Keep_Invita1Gade4&&
        _80002_Star1Keep_Invita2Gade4 > _80003_Star1Keep_Invita3Gade4&&
        _80002_Star1Keep_Invita2Gade4 > _80004_Star1Keep_Invita4Gade4&&
        _80002_Star1Keep_Invita2Gade4 > _80005_Star1Keep_Invita5Gade4)
        {NFTWPower.SetStar1Keep(2);}

        if(_80003_Star1Keep_Invita3Gade4 >= VotingMX&&
        _80003_Star1Keep_Invita3Gade4 > _80002_Star1Keep_Invita2Gade4&&
        _80003_Star1Keep_Invita3Gade4 > _80001_Star1Keep_Invita1Gade4&&
        _80003_Star1Keep_Invita3Gade4 > _80004_Star1Keep_Invita4Gade4&&
        _80003_Star1Keep_Invita3Gade4 > _80005_Star1Keep_Invita5Gade4)
        {NFTWPower.SetStar1Keep(3);}

        if(_80004_Star1Keep_Invita4Gade4 >= VotingMX&&
        _80004_Star1Keep_Invita4Gade4 > _80002_Star1Keep_Invita2Gade4&&
        _80004_Star1Keep_Invita4Gade4 > _80003_Star1Keep_Invita3Gade4&&
        _80004_Star1Keep_Invita4Gade4 > _80001_Star1Keep_Invita1Gade4&&
        _80004_Star1Keep_Invita4Gade4 > _80005_Star1Keep_Invita5Gade4)
        {NFTWPower.SetStar1Keep(4);}

        if(_80005_Star1Keep_Invita5Gade4 >= VotingMX&&
        _80005_Star1Keep_Invita5Gade4 > _80002_Star1Keep_Invita2Gade4&&
        _80005_Star1Keep_Invita5Gade4 > _80003_Star1Keep_Invita3Gade4&&
        _80005_Star1Keep_Invita5Gade4 > _80004_Star1Keep_Invita4Gade4&&
        _80005_Star1Keep_Invita5Gade4 > _80001_Star1Keep_Invita1Gade4)
        {NFTWPower.SetStar1Keep(5);}


        if(_90003_Star2Keep_Invita3Gade4 >= VotingMX&&
        _90003_Star2Keep_Invita3Gade4 > _90004_Star2Keep_Invita4Gade4&&
        _90003_Star2Keep_Invita3Gade4 > _90005_Star2Keep_Invita5Gade4&&
        _90003_Star2Keep_Invita3Gade4 > _90006_Star2Keep_Invita6Gade4&&
        _90003_Star2Keep_Invita3Gade4 > _90007_Star2Keep_Invita7Gade4)
        {NFTWPower.SetStar2Keep(3);}

        if(_90004_Star2Keep_Invita4Gade4 >= VotingMX&&
        _90004_Star2Keep_Invita4Gade4 > _90003_Star2Keep_Invita3Gade4&&
        _90004_Star2Keep_Invita4Gade4 > _90005_Star2Keep_Invita5Gade4&&
        _90004_Star2Keep_Invita4Gade4 > _90006_Star2Keep_Invita6Gade4&&
        _90004_Star2Keep_Invita4Gade4 > _90007_Star2Keep_Invita7Gade4)
        {NFTWPower.SetStar2Keep(4);}

        if(_90005_Star2Keep_Invita5Gade4 >= VotingMX&&
        _90005_Star2Keep_Invita5Gade4 > _90004_Star2Keep_Invita4Gade4&&
        _90005_Star2Keep_Invita5Gade4 > _90003_Star2Keep_Invita3Gade4&&
        _90005_Star2Keep_Invita5Gade4 > _90006_Star2Keep_Invita6Gade4&&
        _90005_Star2Keep_Invita5Gade4 > _90007_Star2Keep_Invita7Gade4)
        {NFTWPower.SetStar2Keep(5);}

        if(_90006_Star2Keep_Invita6Gade4 >= VotingMX&&
        _90006_Star2Keep_Invita6Gade4 > _90004_Star2Keep_Invita4Gade4&&
        _90006_Star2Keep_Invita6Gade4 > _90005_Star2Keep_Invita5Gade4&&
        _90006_Star2Keep_Invita6Gade4 > _90003_Star2Keep_Invita3Gade4&&
        _90006_Star2Keep_Invita6Gade4 > _90007_Star2Keep_Invita7Gade4)
        {NFTWPower.SetStar2Keep(6);}

        if(_90007_Star2Keep_Invita7Gade4 >= VotingMX&&
        _90007_Star2Keep_Invita7Gade4 > _90004_Star2Keep_Invita4Gade4&&
        _90007_Star2Keep_Invita7Gade4 > _90005_Star2Keep_Invita5Gade4&&
        _90007_Star2Keep_Invita7Gade4 > _90006_Star2Keep_Invita6Gade4&&
        _90007_Star2Keep_Invita7Gade4 > _90003_Star2Keep_Invita3Gade4)
        {NFTWPower.SetStar2Keep(7);}

        
        if(_100012_Star1Burn_rate_12Percent >= VotingMX&&
        _100012_Star1Burn_rate_12Percent > _100014_Star1Burn_rate_14Percent&&
        _100012_Star1Burn_rate_12Percent > _100016_Star1Burn_rate_16Percent&&
        _100012_Star1Burn_rate_12Percent > _100018_Star1Burn_rate_18Percent&&
        _100012_Star1Burn_rate_12Percent > _100020_Star1Burn_rate_20Percent)
        {NFTWPower.SetStar1BurnRate(12);}

        if(_100014_Star1Burn_rate_14Percent >= VotingMX&&
        _100014_Star1Burn_rate_14Percent > _100012_Star1Burn_rate_12Percent&&
        _100014_Star1Burn_rate_14Percent > _100016_Star1Burn_rate_16Percent&&
        _100014_Star1Burn_rate_14Percent > _100018_Star1Burn_rate_18Percent&&
        _100014_Star1Burn_rate_14Percent > _100020_Star1Burn_rate_20Percent)
        {NFTWPower.SetStar1BurnRate(14);}

        if(_100016_Star1Burn_rate_16Percent >= VotingMX&&
        _100016_Star1Burn_rate_16Percent > _100014_Star1Burn_rate_14Percent&&
        _100016_Star1Burn_rate_16Percent > _100012_Star1Burn_rate_12Percent&&
        _100016_Star1Burn_rate_16Percent > _100018_Star1Burn_rate_18Percent&&
        _100016_Star1Burn_rate_16Percent > _100020_Star1Burn_rate_20Percent)
        {NFTWPower.SetStar1BurnRate(16);}

        if(_100018_Star1Burn_rate_18Percent >= VotingMX&&
        _100018_Star1Burn_rate_18Percent > _100014_Star1Burn_rate_14Percent&&
        _100018_Star1Burn_rate_18Percent > _100016_Star1Burn_rate_16Percent&&
        _100018_Star1Burn_rate_18Percent > _100012_Star1Burn_rate_12Percent&&
        _100018_Star1Burn_rate_18Percent > _100020_Star1Burn_rate_20Percent)
        {NFTWPower.SetStar1BurnRate(18);}

        if(_100020_Star1Burn_rate_20Percent >= VotingMX&&
        _100020_Star1Burn_rate_20Percent > _100014_Star1Burn_rate_14Percent&&
        _100020_Star1Burn_rate_20Percent > _100016_Star1Burn_rate_16Percent&&
        _100020_Star1Burn_rate_20Percent > _100018_Star1Burn_rate_18Percent&&
        _100020_Star1Burn_rate_20Percent > _100012_Star1Burn_rate_12Percent)
        {NFTWPower.SetStar1BurnRate(20);}
    
        

        if(_110008_Star2Burn_rate_8Percent >= VotingMX&&
        _110008_Star2Burn_rate_8Percent > _110010_Star2Burn_rate_10Percent&&
        _110008_Star2Burn_rate_8Percent > _110012_Star2Burn_rate_12Percent&&
        _110008_Star2Burn_rate_8Percent > _110014_Star2Burn_rate_14Percent&&
        _110008_Star2Burn_rate_8Percent > _110016_Star2Burn_rate_16Percent)
        {NFTWPower.SetStar2BurnRate(8);}

        if(_110010_Star2Burn_rate_10Percent >= VotingMX&&
        _110010_Star2Burn_rate_10Percent > _110008_Star2Burn_rate_8Percent&&
        _110010_Star2Burn_rate_10Percent > _110012_Star2Burn_rate_12Percent&&
        _110010_Star2Burn_rate_10Percent > _110014_Star2Burn_rate_14Percent&&
        _110010_Star2Burn_rate_10Percent > _110016_Star2Burn_rate_16Percent)
        {NFTWPower.SetStar2BurnRate(10);}

        if(_110012_Star2Burn_rate_12Percent >= VotingMX&&
        _110012_Star2Burn_rate_12Percent > _110010_Star2Burn_rate_10Percent&&
        _110012_Star2Burn_rate_12Percent > _110008_Star2Burn_rate_8Percent&&
        _110012_Star2Burn_rate_12Percent > _110014_Star2Burn_rate_14Percent&&
        _110012_Star2Burn_rate_12Percent > _110016_Star2Burn_rate_16Percent)
        {NFTWPower.SetStar2BurnRate(12);}

        if(_110014_Star2Burn_rate_14Percent >= VotingMX&&
        _110014_Star2Burn_rate_14Percent > _110010_Star2Burn_rate_10Percent&&
        _110014_Star2Burn_rate_14Percent > _110012_Star2Burn_rate_12Percent&&
        _110014_Star2Burn_rate_14Percent > _110008_Star2Burn_rate_8Percent&&
        _110014_Star2Burn_rate_14Percent > _110016_Star2Burn_rate_16Percent)
        {NFTWPower.SetStar2BurnRate(14);}

        if(_110016_Star2Burn_rate_16Percent >= VotingMX&&
        _110016_Star2Burn_rate_16Percent > _110010_Star2Burn_rate_10Percent&&
        _110016_Star2Burn_rate_16Percent > _110012_Star2Burn_rate_12Percent&&
        _110016_Star2Burn_rate_16Percent > _110014_Star2Burn_rate_14Percent&&
        _110016_Star2Burn_rate_16Percent > _110008_Star2Burn_rate_8Percent)
        {NFTWPower.SetStar2BurnRate(16);}

    }
    
    function SetToken(address _NFTWPower) public  {
      require(Admin==msg.sender);
      NFTWPower = IBEP21(_NFTWPower);nFTWPower = _NFTWPower;}
      
    function SetVotingMX(uint256 _VotingMX,uint256 _PowerOf) public  {
      require(Admin==msg.sender);
      VotingMX = _VotingMX; PowerOf = _PowerOf;}    
    
    function Star1Keep_Invita_1_Gade4 () public view returns(uint256){return _80001_Star1Keep_Invita1Gade4;}
    function Star1Keep_Invita_2_Gade4 () public view returns(uint256){return _80002_Star1Keep_Invita2Gade4;}
    function Star1Keep_Invita_3_Gade4 () public view returns(uint256){return _80003_Star1Keep_Invita3Gade4;}
    function Star1Keep_Invita_4_Gade4 () public view returns(uint256){return _80004_Star1Keep_Invita4Gade4;}
    function Star1Keep_Invita_5_Gade4 () public view returns(uint256){return _80005_Star1Keep_Invita5Gade4;}
    
    function Star2Keep_Invita_3_Gade4 () public view returns(uint256){return _90003_Star2Keep_Invita3Gade4;}
    function Star2Keep_Invita_4_Gade4 () public view returns(uint256){return _90004_Star2Keep_Invita4Gade4;}
    function Star2Keep_Invita_5_Gade4 () public view returns(uint256){return _90005_Star2Keep_Invita5Gade4;}
    function Star2Keep_Invita_6_Gade4 () public view returns(uint256){return _90006_Star2Keep_Invita6Gade4;}
    function Star2Keep_Invita_7_Gade4 () public view returns(uint256){return _90007_Star2Keep_Invita7Gade4;}
    
    
    function Star1Burn_rate_12_Percent () public view returns(uint256){return _100012_Star1Burn_rate_12Percent;}
    function Star1Burn_rate_14_Percent () public view returns(uint256){return _100014_Star1Burn_rate_14Percent;}
    function Star1Burn_rate_16_Percent () public view returns(uint256){return _100016_Star1Burn_rate_16Percent;}
    function Star1Burn_rate_18_Percent () public view returns(uint256){return _100018_Star1Burn_rate_18Percent;}
    function Star1Burn_rate_20_Percent () public view returns(uint256){return _100020_Star1Burn_rate_20Percent;}
   
    
    function Star2Burn_rate_8_Percent () public view returns(uint256){return _110008_Star2Burn_rate_8Percent;}
    function Star2Burn_rate_10_Percent () public view returns(uint256){return _110010_Star2Burn_rate_10Percent;}
    function Star2Burn_rate_12_Percent () public view returns(uint256){return _110012_Star2Burn_rate_12Percent;}
    function Star2Burn_rate_14_Percent () public view returns(uint256){return _110014_Star2Burn_rate_14Percent;}
    function Star2Burn_rate_16_Percent () public view returns(uint256){return _110016_Star2Burn_rate_16Percent;}
    

}