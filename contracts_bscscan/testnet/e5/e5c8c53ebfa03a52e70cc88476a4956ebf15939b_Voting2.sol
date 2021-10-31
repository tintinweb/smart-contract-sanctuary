/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4;


interface IBEP20 {event Transfer(address indexed from, address indexed to, uint256 value);}

interface IBEP21{ 
    
    function SetInvitation(uint256 Invitation) external returns (bool);

    function SetPowerBurn(uint256 PowerBurn) external returns (bool);

    function SetBonusRatio(uint256 BonusRatio) external returns (bool);
    
    function SetStar2Reach(uint256 Star2Reach) external returns (bool);
    
    function PowerOf(address account) external view returns (uint256);
    
}

contract Voting2  {
    address Admin;
    address nFTWPower;
    IBEP21  NFTWPower;
    uint256 VotingMX;
    uint256 PowerOf;
    struct Voter{uint256 LastVoting;}
    mapping (address=>Voter) Voters;
    
    uint256  _10500_Invitation_Point_To500;
    uint256  _11000_Invitation_Point_To1000;
    uint256  _12000_Invitation_Point_To2000;
    uint256  _13000_Invitation_Point_To3000;
    uint256  _15000_Invitation_Point_To5000;
    
    uint256  _20010_PowerBurn_Withdraw_To10Percent;
    uint256  _20020_PowerBurn_Withdraw_To20Percent;
    uint256  _20030_PowerBurn_Withdraw_To30Percent;
    uint256  _20040_PowerBurn_Withdraw_To40Percent;
    uint256  _20050_PowerBurn_Withdraw_To50Percent;
    
    uint256  _30005_Invitation_BonusRatio_To5Percent;
    uint256  _30006_Invitation_BonusRatio_To6Percent;
    uint256  _30007_Invitation_BonusRatio_To7Percent;
    uint256  _30008_Invitation_BonusRatio_To8Percent;
    uint256  _30009_Invitation_BonusRatio_To9Percent;
    uint256  _30010_Invitation_BonusRatio_To10Percent;
    
    uint256  _40003_Star2Reach_Invita3Star1; 
    uint256  _40004_Star2Reach_Invita4Star1;
    uint256  _40005_Star2Reach_Invita5Star1;
    uint256  _40006_Star2Reach_Invita6Star1;
    uint256  _40007_Star2Reach_Invita7Star1;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);

      constructor() {Admin=msg.sender;VotingMX=2;PowerOf=100000;}
      
      function _Voting (address from, address to, uint256 Amount) public{
        require(nFTWPower==msg.sender);
        require(from != address(0), 'Voting: transfer from the zero address');
        require(to != address(0), 'Voting: transfer to the zero address');
        require((block.number-Voters[from].LastVoting)<=20*5, 'Voting: you have already voted this option');  
        require(NFTWPower.PowerOf(from) >= PowerOf, 'Voting: your power is not enough');
        if(Amount==10500){_10500_Invitation_Point_To500 = _10500_Invitation_Point_To500+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==11000){_11000_Invitation_Point_To1000 = _11000_Invitation_Point_To1000+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==12000){_12000_Invitation_Point_To2000 = _12000_Invitation_Point_To2000+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==13000){_13000_Invitation_Point_To3000 = _13000_Invitation_Point_To3000+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==15000){_15000_Invitation_Point_To5000 = _15000_Invitation_Point_To5000+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        
        if(Amount==20010){_20010_PowerBurn_Withdraw_To10Percent = _20010_PowerBurn_Withdraw_To10Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==20020){_20020_PowerBurn_Withdraw_To20Percent = _20020_PowerBurn_Withdraw_To20Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==20030){_20030_PowerBurn_Withdraw_To30Percent = _20030_PowerBurn_Withdraw_To30Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==20040){_20040_PowerBurn_Withdraw_To40Percent = _20040_PowerBurn_Withdraw_To40Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==20050){_20050_PowerBurn_Withdraw_To50Percent = _20050_PowerBurn_Withdraw_To50Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}


        if(Amount==30005){_30005_Invitation_BonusRatio_To5Percent = _30005_Invitation_BonusRatio_To5Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==30006){_30006_Invitation_BonusRatio_To6Percent = _30006_Invitation_BonusRatio_To6Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==30007){_30007_Invitation_BonusRatio_To7Percent = _30007_Invitation_BonusRatio_To7Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==30008){_30008_Invitation_BonusRatio_To8Percent = _30008_Invitation_BonusRatio_To8Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==30009){_30009_Invitation_BonusRatio_To9Percent = _30009_Invitation_BonusRatio_To9Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==30010){_30010_Invitation_BonusRatio_To10Percent = _30010_Invitation_BonusRatio_To10Percent+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}  
        

        if(Amount==40003){_40003_Star2Reach_Invita3Star1 = _40003_Star2Reach_Invita3Star1+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==40004){_40004_Star2Reach_Invita4Star1 = _40004_Star2Reach_Invita4Star1+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==40005){_40005_Star2Reach_Invita5Star1 = _40005_Star2Reach_Invita5Star1+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==40006){_40006_Star2Reach_Invita6Star1 = _40006_Star2Reach_Invita6Star1+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        if(Amount==40007){_40007_Star2Reach_Invita7Star1 = _40007_Star2Reach_Invita7Star1+1;
        Voters[from].LastVoting=block.number;emit Transfer(from, to, Amount);}
        

        
        if(_10500_Invitation_Point_To500 >= VotingMX&&
        _10500_Invitation_Point_To500 > _11000_Invitation_Point_To1000&&
        _10500_Invitation_Point_To500 > _12000_Invitation_Point_To2000&&
        _10500_Invitation_Point_To500 > _13000_Invitation_Point_To3000&&
        _10500_Invitation_Point_To500 > _15000_Invitation_Point_To5000)
        {NFTWPower.SetInvitation(500);}
        
        if(_11000_Invitation_Point_To1000 >= VotingMX&&
        _11000_Invitation_Point_To1000 > _10500_Invitation_Point_To500&&
        _11000_Invitation_Point_To1000 > _12000_Invitation_Point_To2000&&
        _11000_Invitation_Point_To1000 > _13000_Invitation_Point_To3000&&
        _11000_Invitation_Point_To1000 > _15000_Invitation_Point_To5000)
        {NFTWPower.SetInvitation(1000);}
        
        if(_12000_Invitation_Point_To2000 >= VotingMX&&
        _12000_Invitation_Point_To2000 > _11000_Invitation_Point_To1000&&
        _12000_Invitation_Point_To2000 > _10500_Invitation_Point_To500&&
        _12000_Invitation_Point_To2000 > _13000_Invitation_Point_To3000&&
        _12000_Invitation_Point_To2000 > _15000_Invitation_Point_To5000)
        {NFTWPower.SetInvitation(2000);}
        
        if(_13000_Invitation_Point_To3000 >= VotingMX&&
        _13000_Invitation_Point_To3000 > _11000_Invitation_Point_To1000&&
        _13000_Invitation_Point_To3000 > _12000_Invitation_Point_To2000&&
        _13000_Invitation_Point_To3000 > _10500_Invitation_Point_To500&&
        _13000_Invitation_Point_To3000 > _15000_Invitation_Point_To5000)
        {NFTWPower.SetInvitation(3000);}
        
        if(_15000_Invitation_Point_To5000 >= VotingMX&&
        _15000_Invitation_Point_To5000 > _11000_Invitation_Point_To1000&&
        _15000_Invitation_Point_To5000 > _12000_Invitation_Point_To2000&&
        _15000_Invitation_Point_To5000 > _10500_Invitation_Point_To500&&
        _15000_Invitation_Point_To5000 > _10500_Invitation_Point_To500)
        {NFTWPower.SetInvitation(5000);}
        
      
        
        if(_20010_PowerBurn_Withdraw_To10Percent >= VotingMX&&
        _20010_PowerBurn_Withdraw_To10Percent > _20020_PowerBurn_Withdraw_To20Percent&&
        _20010_PowerBurn_Withdraw_To10Percent > _20030_PowerBurn_Withdraw_To30Percent&&
        _20010_PowerBurn_Withdraw_To10Percent > _20040_PowerBurn_Withdraw_To40Percent&&
        _20010_PowerBurn_Withdraw_To10Percent > _20050_PowerBurn_Withdraw_To50Percent)
        {NFTWPower.SetPowerBurn(100);}
        
        if(_20020_PowerBurn_Withdraw_To20Percent >= VotingMX&&
        _20020_PowerBurn_Withdraw_To20Percent > _20010_PowerBurn_Withdraw_To10Percent&&
        _20020_PowerBurn_Withdraw_To20Percent > _20030_PowerBurn_Withdraw_To30Percent&&
        _20020_PowerBurn_Withdraw_To20Percent > _20040_PowerBurn_Withdraw_To40Percent&&
        _20020_PowerBurn_Withdraw_To20Percent > _20050_PowerBurn_Withdraw_To50Percent)
        {NFTWPower.SetPowerBurn(200);}
        
        if(_20030_PowerBurn_Withdraw_To30Percent >= VotingMX&&
        _20030_PowerBurn_Withdraw_To30Percent > _20020_PowerBurn_Withdraw_To20Percent&&
        _20030_PowerBurn_Withdraw_To30Percent > _20010_PowerBurn_Withdraw_To10Percent&&
        _20030_PowerBurn_Withdraw_To30Percent > _20040_PowerBurn_Withdraw_To40Percent&&
        _20030_PowerBurn_Withdraw_To30Percent > _20050_PowerBurn_Withdraw_To50Percent)
        {NFTWPower.SetPowerBurn(300);}
        
        if(_20040_PowerBurn_Withdraw_To40Percent >= VotingMX&&
        _20040_PowerBurn_Withdraw_To40Percent > _20020_PowerBurn_Withdraw_To20Percent&&
        _20040_PowerBurn_Withdraw_To40Percent > _20030_PowerBurn_Withdraw_To30Percent&&
        _20040_PowerBurn_Withdraw_To40Percent > _20010_PowerBurn_Withdraw_To10Percent&&
        _20040_PowerBurn_Withdraw_To40Percent > _20050_PowerBurn_Withdraw_To50Percent)
        {NFTWPower.SetPowerBurn(400);}
        
        if(_20050_PowerBurn_Withdraw_To50Percent >= VotingMX&&
        _20050_PowerBurn_Withdraw_To50Percent > _20020_PowerBurn_Withdraw_To20Percent&&
        _20050_PowerBurn_Withdraw_To50Percent > _20030_PowerBurn_Withdraw_To30Percent&&
        _20050_PowerBurn_Withdraw_To50Percent > _20040_PowerBurn_Withdraw_To40Percent&&
        _20050_PowerBurn_Withdraw_To50Percent > _20010_PowerBurn_Withdraw_To10Percent)
        {NFTWPower.SetPowerBurn(500);}
        
       


        if(_30005_Invitation_BonusRatio_To5Percent >= VotingMX&&
        _30005_Invitation_BonusRatio_To5Percent > _30006_Invitation_BonusRatio_To6Percent&&
        _30005_Invitation_BonusRatio_To5Percent > _30007_Invitation_BonusRatio_To7Percent&&
        _30005_Invitation_BonusRatio_To5Percent > _30008_Invitation_BonusRatio_To8Percent&&
        _30005_Invitation_BonusRatio_To5Percent > _30009_Invitation_BonusRatio_To9Percent&&
        _30005_Invitation_BonusRatio_To5Percent > _30010_Invitation_BonusRatio_To10Percent)
        {NFTWPower.SetBonusRatio(50);}
        
        if(_30006_Invitation_BonusRatio_To6Percent >= VotingMX&&
        _30006_Invitation_BonusRatio_To6Percent > _30005_Invitation_BonusRatio_To5Percent&&
        _30006_Invitation_BonusRatio_To6Percent > _30007_Invitation_BonusRatio_To7Percent&&
        _30006_Invitation_BonusRatio_To6Percent > _30008_Invitation_BonusRatio_To8Percent&&
        _30006_Invitation_BonusRatio_To6Percent > _30009_Invitation_BonusRatio_To9Percent&&
        _30006_Invitation_BonusRatio_To6Percent > _30010_Invitation_BonusRatio_To10Percent)
        {NFTWPower.SetBonusRatio(60);}
        
        if(_30007_Invitation_BonusRatio_To7Percent >= VotingMX&&
        _30007_Invitation_BonusRatio_To7Percent > _30006_Invitation_BonusRatio_To6Percent&&
        _30007_Invitation_BonusRatio_To7Percent > _30005_Invitation_BonusRatio_To5Percent&&
        _30007_Invitation_BonusRatio_To7Percent > _30008_Invitation_BonusRatio_To8Percent&&
        _30007_Invitation_BonusRatio_To7Percent > _30009_Invitation_BonusRatio_To9Percent&&
        _30007_Invitation_BonusRatio_To7Percent > _30010_Invitation_BonusRatio_To10Percent)
        {NFTWPower.SetBonusRatio(70);}
        
        if(_30008_Invitation_BonusRatio_To8Percent >= VotingMX&&
        _30008_Invitation_BonusRatio_To8Percent > _30006_Invitation_BonusRatio_To6Percent&&
        _30008_Invitation_BonusRatio_To8Percent > _30007_Invitation_BonusRatio_To7Percent&&
        _30008_Invitation_BonusRatio_To8Percent > _30005_Invitation_BonusRatio_To5Percent&&
        _30008_Invitation_BonusRatio_To8Percent > _30009_Invitation_BonusRatio_To9Percent&&
        _30008_Invitation_BonusRatio_To8Percent > _30010_Invitation_BonusRatio_To10Percent)
        {NFTWPower.SetBonusRatio(80);}
        
        if(_30009_Invitation_BonusRatio_To9Percent >= VotingMX&&
        _30009_Invitation_BonusRatio_To9Percent > _30006_Invitation_BonusRatio_To6Percent&&
        _30009_Invitation_BonusRatio_To9Percent > _30007_Invitation_BonusRatio_To7Percent&&
        _30009_Invitation_BonusRatio_To9Percent > _30008_Invitation_BonusRatio_To8Percent&&
        _30009_Invitation_BonusRatio_To9Percent > _30005_Invitation_BonusRatio_To5Percent&&
        _30009_Invitation_BonusRatio_To9Percent > _30010_Invitation_BonusRatio_To10Percent)
        {NFTWPower.SetBonusRatio(90);}
        
        if(_30010_Invitation_BonusRatio_To10Percent >= VotingMX&&
        _30010_Invitation_BonusRatio_To10Percent > _30006_Invitation_BonusRatio_To6Percent&&
        _30010_Invitation_BonusRatio_To10Percent > _30007_Invitation_BonusRatio_To7Percent&&
        _30010_Invitation_BonusRatio_To10Percent > _30008_Invitation_BonusRatio_To8Percent&&
        _30010_Invitation_BonusRatio_To10Percent > _30009_Invitation_BonusRatio_To9Percent&&
        _30010_Invitation_BonusRatio_To10Percent > _30010_Invitation_BonusRatio_To10Percent)
        {NFTWPower.SetBonusRatio(100);}
        
        
        if(_40003_Star2Reach_Invita3Star1 >= VotingMX&&
        _40003_Star2Reach_Invita3Star1 > _40004_Star2Reach_Invita4Star1&&
        _40003_Star2Reach_Invita3Star1 > _40005_Star2Reach_Invita5Star1&&
        _40003_Star2Reach_Invita3Star1 > _40006_Star2Reach_Invita6Star1&&
        _40003_Star2Reach_Invita3Star1 > _40007_Star2Reach_Invita7Star1)
        {NFTWPower.SetStar2Reach(3);}

        if(_40004_Star2Reach_Invita4Star1 >= VotingMX&&
        _40004_Star2Reach_Invita4Star1 > _40003_Star2Reach_Invita3Star1&&
        _40004_Star2Reach_Invita4Star1 > _40005_Star2Reach_Invita5Star1&&
        _40004_Star2Reach_Invita4Star1 > _40006_Star2Reach_Invita6Star1&&
        _40004_Star2Reach_Invita4Star1 > _40007_Star2Reach_Invita7Star1)
        {NFTWPower.SetStar2Reach(4);}

        if(_40005_Star2Reach_Invita5Star1 >= VotingMX&&
        _40005_Star2Reach_Invita5Star1 > _40004_Star2Reach_Invita4Star1&&
        _40005_Star2Reach_Invita5Star1 > _40003_Star2Reach_Invita3Star1&&
        _40005_Star2Reach_Invita5Star1 > _40006_Star2Reach_Invita6Star1&&
        _40005_Star2Reach_Invita5Star1 > _40007_Star2Reach_Invita7Star1)
        {NFTWPower.SetStar2Reach(5);}

        if(_40006_Star2Reach_Invita6Star1 >= VotingMX&&
        _40006_Star2Reach_Invita6Star1 > _40004_Star2Reach_Invita4Star1&&
        _40006_Star2Reach_Invita6Star1 > _40005_Star2Reach_Invita5Star1&&
        _40006_Star2Reach_Invita6Star1 > _40003_Star2Reach_Invita3Star1&&
        _40006_Star2Reach_Invita6Star1 > _40007_Star2Reach_Invita7Star1)
        {NFTWPower.SetStar2Reach(6);}

        if(_40007_Star2Reach_Invita7Star1 >= VotingMX&&
        _40007_Star2Reach_Invita7Star1 > _40004_Star2Reach_Invita4Star1&&
        _40007_Star2Reach_Invita7Star1 > _40005_Star2Reach_Invita5Star1&&
        _40007_Star2Reach_Invita7Star1 > _40006_Star2Reach_Invita6Star1&&
        _40007_Star2Reach_Invita7Star1 > _40003_Star2Reach_Invita3Star1)
        {NFTWPower.SetStar2Reach(7);}

}
    
    function SetToken(address _NFTWPower) public  {
      require(Admin==msg.sender);
      NFTWPower = IBEP21(_NFTWPower);nFTWPower = _NFTWPower;}
      
    function SetVotingMX(uint256 _VotingMX,uint256 _PowerOf) public  {
      require(Admin==msg.sender);
      VotingMX = _VotingMX; PowerOf = _PowerOf;}  
    
    function Invitation_Point_To500 () public view returns(uint256){return _10500_Invitation_Point_To500;}
    function Invitation_Point_To1000 () public view returns(uint256){return _11000_Invitation_Point_To1000;}
    function Invitation_Point_To2000 () public view returns(uint256){return _12000_Invitation_Point_To2000;}
    function Invitation_Point_To3000 () public view returns(uint256){return _13000_Invitation_Point_To3000;}
    function Invitation_Point_To5000 () public view returns(uint256){return _15000_Invitation_Point_To5000;}
    
    function PowerBurn_Withdraw_To10Percent () public view returns(uint256){return _20010_PowerBurn_Withdraw_To10Percent;}
    function PowerBurn_Withdraw_To20Percent () public view returns(uint256){return _20020_PowerBurn_Withdraw_To20Percent;}
    function PowerBurn_Withdraw_To30Percent () public view returns(uint256){return _20030_PowerBurn_Withdraw_To30Percent;}
    function PowerBurn_Withdraw_To40Percent () public view returns(uint256){return _20040_PowerBurn_Withdraw_To40Percent;}
    function PowerBurn_Withdraw_To50Percent () public view returns(uint256){return _20050_PowerBurn_Withdraw_To50Percent;}
    
    function Invitation_BonusRatio_To5Percent () public view returns(uint256){return _30005_Invitation_BonusRatio_To5Percent;}
    function Invitation_BonusRatio_To6Percent () public view returns(uint256){return _30006_Invitation_BonusRatio_To6Percent;}
    function Invitation_BonusRatio_To7Percent () public view returns(uint256){return _30007_Invitation_BonusRatio_To7Percent;}
    function Invitation_BonusRatio_To8Percent () public view returns(uint256){return _30008_Invitation_BonusRatio_To8Percent;}
    function Invitation_BonusRatio_To9Percent () public view returns(uint256){return _30009_Invitation_BonusRatio_To9Percent;}
    function Invitation_BonusRatio_To10Percent () public view returns(uint256){return _30010_Invitation_BonusRatio_To10Percent;}
    
    function Star2Reach_Invita_3_Star1 () public view returns(uint256){return _40003_Star2Reach_Invita3Star1;}
    function Star2Reach_Invita_4_Star1 () public view returns(uint256){return _40004_Star2Reach_Invita4Star1;}
    function Star2Reach_Invita_5_Star1 () public view returns(uint256){return _40005_Star2Reach_Invita5Star1;}
    function Star2Reach_Invita_6_Star1 () public view returns(uint256){return _40006_Star2Reach_Invita6Star1;}
    function Star2Reach_Invita_7_Star1 () public view returns(uint256){return _40007_Star2Reach_Invita7Star1;}

}