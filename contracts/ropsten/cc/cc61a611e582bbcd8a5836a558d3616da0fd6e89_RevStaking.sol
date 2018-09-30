pragma solidity ^0.4.24;

//import &#39;./DateTime.sol&#39;;
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

contract ERC20Token {
    function transferFrom(address from, address to, uint _value) public returns (bool);
    function freeze(address spender,uint256 value) public returns (bool success);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract RevStaking is Ownable {
    struct stakingDetail{
        
        uint256 duration;
        address ownerAddress;
        address stakingAddress;
        uint256 amount;
        uint256 timeStart;
        bool isActive;
        bool completed;    
    }
    
    mapping (address => stakingDetail) stakingDetails;
    mapping (address => uint256) public freezed;
    mapping (address => uint256) balances;
    address [] public stakedAddress;
    uint256 stakingCount;
    
    
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    
    function stack(address _stakingAddress, uint256 _amount, uint256 _duration) public{
        require(_amount>10000);
        //if(!IsValidAddress(_stakingAddress)) { throw; }
        ERC20Token _token = ERC20Token(0x53981B4004FE67fB3D0Da666D635fDdadeeD5cf8);
        _token.transferFrom(msg.sender, _stakingAddress, _amount);
        
        var stakingDetail = stakingDetails[_stakingAddress];
        stakingDetail.duration = _duration;
        stakingDetail.ownerAddress = msg.sender;
        stakingDetail.stakingAddress = _stakingAddress;
        stakingDetail.amount = _amount;
        stakingDetail.timeStart = now;
        stakingDetail.isActive = false;
        stakingDetail.completed =false;
        
        stakedAddress.push(_stakingAddress)-1;
        stakingCount++;
    }
    
    function getStakedAddresses() view public returns (address[]){
        return stakedAddress;
    }
    
    function getStakedAddress(address _stakingAddress) view public returns (uint256, address, uint256, uint256){
        return (stakingDetails[_stakingAddress].duration,stakingDetails[_stakingAddress].stakingAddress,stakingDetails[_stakingAddress].amount,stakingDetails[_stakingAddress].timeStart);
    }
    
    function freezeStaking(address _stakingAddress) returns (bool){
        //for(uint256 i =0; i< stakedAddress.length; i++){
            var stakingDetail = stakingDetails[_stakingAddress];
            if((stakingDetail.timeStart + 14 * 1 days)> now){
                stakingDetail.isActive = true;
            }
        //}
    }
    function revokeStaking(address _stakingAddress) returns(bool){
        var stakingDetail = stakingDetails[_stakingAddress];
        if(stakingDetail.ownerAddress != msg.sender)
            return false;
        else
        {
            ERC20Token _token = ERC20Token(0x53981B4004FE67fB3D0Da666D635fDdadeeD5cf8);
            _token.transferFrom(0x983561a720be2786f5e51a13342d07335fcde676,_stakingAddress, getStakingReward(stakingDetail.timeStart));
            stakingDetail.completed = true;
            return true;
        }
    }
    function getStakingReward(uint256 _duration) returns (uint256){
        //stakingBonusRewardPercentage
        DateTime dateTime =  DateTime(0x52065BC8e5B4Ac2f63CFbd48cD0b3BCf2fCc6ABD);
        var daysStaked = dateTime.getDay(SafeMath.sub(now,_duration));
        return getReward(daysStaked);
    }
    function  getReward(uint256 daysStaked) returns (uint256){
        //stakingBonusRewardPercentagePerDay
        var percentage = 2;
        if (daysStaked > 1) {
            return SafeMath.mul(daysStaked,  percentage);
        }else{
            uint256 returnVal = 100000;
              return returnVal;
        }
    }
    function IsValidAddress(address _stakingAddress) returns (bool){
        var stakingDetail = stakingDetails[_stakingAddress];
        if(!stakingDetail.isActive && stakingDetail.completed)
            return true;
        else
            return false;
    }
    function stakingBonus(uint256 ETH_profit, uint256 userToken, uint256 totalToken) onlyOwner public {
      
           uint256 bonusETH = SafeMath.mul(ETH_profit , (SafeMath.div(userToken,totalToken)));
    }
}

contract DateTime {
        function getYear(uint timestamp) public constant returns (uint16);
        function getMonth(uint timestamp) public constant returns (uint8);
        function getDay(uint timestamp) public constant returns (uint8);
}