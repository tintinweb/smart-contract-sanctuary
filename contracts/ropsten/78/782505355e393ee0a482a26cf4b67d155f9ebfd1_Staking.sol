pragma solidity ^0.6.12;
import "./stakingtoken.sol";

contract Staking{
    
    PSYCHICToken token;
     
     struct User{
         uint256 depositTime;
         uint256 _depositToken;
         uint256 points;
     }
     
    mapping(address=>User) public users;
    
    constructor(PSYCHICToken _token) public {
        token=_token;
        //users[msg.sender].points=50000000*10e18;
    }
    
    function pointsCalculation(address _user)public view returns(uint256){
        uint256 point=(now - users[msg.sender].depositTime)/(10 seconds)*10**18;
         uint256 totalReward= (point/5000)*users[_user]._depositToken;
         return totalReward/10**18;
    }

    function depositTokens(uint256 _numberOfTokens)public {
        require(token.balanceOf(msg.sender)>=_numberOfTokens,"Not enough tokens");
        users[msg.sender].points+=pointsCalculation(msg.sender);
        token.transferFrom(msg.sender,address(this),_numberOfTokens);
        users[msg.sender]._depositToken+=_numberOfTokens;
        users[msg.sender].depositTime=now;
    }
    function withdraw()public{
        uint256 rewardOfUser=pointsCalculation(msg.sender);
        users[msg.sender].points+=rewardOfUser;
        users[msg.sender].depositTime=now;
    }
    
    function transferPoints(address _to,uint256 _numberOfPoints) public{
        require(users[msg.sender].points>=_numberOfPoints,"Not enough points!");
        users[msg.sender].points-=_numberOfPoints;
        users[_to].points+=_numberOfPoints;
    }
    function unstake()public{
        token.transfer(msg.sender,users[msg.sender]._depositToken);
        users[msg.sender].points+=pointsCalculation(msg.sender);
        users[msg.sender].depositTime=0;
        users[msg.sender]._depositToken=0;
    }
     
}