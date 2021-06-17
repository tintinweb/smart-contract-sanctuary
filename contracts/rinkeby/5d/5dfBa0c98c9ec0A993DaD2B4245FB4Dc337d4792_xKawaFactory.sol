/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.5;


contract IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() public view returns (string memory);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract farm{
    struct user{
        uint256 staked;
        uint256 withdrawn;
        uint[] stakeTimes;
        uint[] stakeAmounts;
        uint[] startingAPYLength;
    }
    using SafeMath for uint;
    uint public mintedTokens;
    uint public totalStaked;
    address public factory;
    uint[] apys;
    uint[] apyTimes;
    address payable owner;
    mapping(address => user) public userList;
    event StakeTokens(address indexed user, uint tokensStaked);
    IERC20 stakeToken;
    IERC20 xKawaToken;
    mapping(address => uint) earlyUnstake;
    constructor(address tokenAddress, address payable ownAdd, uint initAPY) public{
        stakeToken = IERC20(tokenAddress);
        xKawaToken = IERC20(0x2f997B58a2a21f179dd76De40aA2277C81948084);
        owner = ownAdd;
        factory = msg.sender;
        changeAPY(initAPY);
    }
    
    modifier onlyOwner() { 
        require(msg.sender == owner);
        _;
    }
    
    function userStaked(address addrToCheck) public view returns(uint){
        return userList[addrToCheck].staked;
    }
    
    function userClaimable(address addrToCheck) view public returns(uint withdrawable){
        if(xKawaToken.balanceOf(address(this)) > 0){
            withdrawable = (calculateStaked(addrToCheck) + earlyUnstake[addrToCheck])- userList[msg.sender].withdrawn;
            if(withdrawable > xKawaToken.balanceOf(address(this))){
                withdrawable = xKawaToken.balanceOf(address(this));
            }
        }else{
            withdrawable = 0;
        }
    }
    
    function changeAPY(uint newAPY) onlyOwner public{
        apys.push(newAPY);
        apyTimes.push(now);
    }
    
    function withdrawTokens() public{//remove supplied
        earlyUnstake[msg.sender] = userClaimable(msg.sender);
        stakeToken.transfer(msg.sender, userList[msg.sender].staked);
        totalStaked -= userList[msg.sender].staked;
        delete userList[msg.sender];
    }
    
    function withdrawReward() public{
        uint withdrawable = userClaimable(msg.sender);
        xKawaToken.transfer(msg.sender, withdrawable);
        userList[msg.sender].withdrawn += withdrawable;
        delete earlyUnstake[msg.sender];
        mintedTokens += withdrawable;
    }
    
    function claimAndWithdraw() public{
        withdrawReward();
        withdrawTokens();
    }
    
    function stakeTokens(uint amountOfTokens) public{
        totalStaked += amountOfTokens;
        stakeToken.transferFrom(msg.sender, address(this), amountOfTokens);
        userList[msg.sender].staked += amountOfTokens;
        userList[msg.sender].stakeTimes.push(now);
        userList[msg.sender].stakeAmounts.push(amountOfTokens);
        userList[msg.sender].startingAPYLength.push(apys.length-1);
        emit StakeTokens(msg.sender, amountOfTokens);
    }
    
    function calculateStaked(address usercheck) public view returns(uint totalMinted) {
        totalMinted = 0;
        for(uint i = 0; i<userList[usercheck].stakeAmounts.length; i++){
            //loop through everytime they have staked
            for(uint j=userList[usercheck].startingAPYLength[i]; j<apys.length;j++){
                //for the i number of time they have staked, go through each apy times and values since they have staked (which is startingAPYLength)
                if(userList[usercheck].stakeTimes[i]<apyTimes[j]){
                    //this will happen if there is an APY change after the user has staked, since only after apy change can apy time > user staked time
                    if(userList[usercheck].stakeTimes[i]<apyTimes[j-1]){
                        //assuming there are 2 or more apy changes after staking, it will mean user has amount still staked in between the 2 apy
                        totalMinted += (userList[usercheck].stakeAmounts[i].mul((apyTimes[j]-apyTimes[j-1]))).div(apys[j]);
                    }else{
                        //will take place on the 1st apy change after staking
                        totalMinted += (userList[usercheck].stakeAmounts[i].mul((now - apyTimes[j]))).div(apys[j]);
                    }
                }else{
                    //Will take place only once for each iteration in i, as only once and the first time will apy time < user stake time
                    totalMinted += (userList[usercheck].stakeAmounts[i].mul((now - userList[usercheck].stakeTimes[i]))).div(apys[j]);
                    //multiplies stake amount with time staked, divided by apy value which gives number of tokens to be minted
                }
            }
        }
    }
}


contract xKawaFactory {

  /***********************************|
  |       Events And Variables        |
  |__________________________________*/

  event NewFarm(address indexed token, address indexed exchange);
  address payable owner;
  address public exchangeTemplate;
  uint256 public tokenCount;
  mapping (address => address) internal token_to_farm;
  mapping (address => address) internal farm_to_token;

  /***********************************|
  |         Factory Functions         |
  |__________________________________*/
    
  constructor() public{
      owner = msg.sender;
  }
  
  function createFarm(address token, uint apy) public returns (address) {
    require(msg.sender == owner, "Not owner");
    require(token != address(0));
    require(token_to_farm[token] == address(0));
    farm exchange = new farm(token, msg.sender, apy);
    token_to_farm[token] = address(exchange);
    farm_to_token[address(exchange)] = token;
    emit NewFarm(token, address(exchange));
    return address(exchange);
  }

  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  function getExchange(address token) public view returns (address) {
    return token_to_farm[token];
  }

  function getToken(address exchange) public view returns (address) {
    return farm_to_token[exchange];
  }

}