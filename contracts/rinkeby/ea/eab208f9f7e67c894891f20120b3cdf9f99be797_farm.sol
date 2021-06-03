/**
 *Submitted for verification at Etherscan.io on 2021-06-02
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
    uint TOTAL_POOL_VALUE;
    uint apyPerToken;
    uint mintedTokens;
    uint[] apys;
    uint[] apyTimes;
    address payable owner;
    mapping(address => user) public userList;
    event StakeTokens(address indexed user, uint tokensStaked);
    IERC20 stakeToken;
    IERC20 xKawaToken;
    mapping(address => uint) earlyUnstake;
    constructor(address tokenAddress, address _xKawa) public{
        stakeToken = IERC20(tokenAddress);
        xKawaToken = IERC20(_xKawa);
        owner = msg.sender;
        changeAPY(86400);
    }
    
    modifier onlyOwner() { 
        require(msg.sender == owner);
        _;
    }
    
    function withdrawExtraxKawa() onlyOwner public{
        xKawaToken.transfer(msg.sender, xKawaToken.balanceOf(address(this)));
    }
    
    function userStaked(address addrToCheck) public view returns(uint){
        return userList[addrToCheck].staked;
    }
    
    function userClaimable(address addrToCheck) view public returns(uint){
        return calculateStaked(addrToCheck) + earlyUnstake[addrToCheck];
    }
    
    function changeAPY(uint newAPY) onlyOwner public{
        apys.push(newAPY);
        apyTimes.push(now);
    }
    
    function withdrawTokens() public{//remove supplied
        earlyUnstake[msg.sender] += calculateStaked(msg.sender);
        stakeToken.transfer(msg.sender, userList[msg.sender].staked);
        delete userList[msg.sender].staked;
        delete userList[msg.sender].stakeTimes;
        delete userList[msg.sender].stakeAmounts;
        delete userList[msg.sender].startingAPYLength;
    }
    
    function withdrawReward() public{
        uint withdrawable = (calculateStaked(msg.sender) + earlyUnstake[msg.sender]) - userList[msg.sender].withdrawn;
        xKawaToken.transfer(msg.sender, withdrawable);
        userList[msg.sender].withdrawn += withdrawable;
        delete earlyUnstake[msg.sender];
    }
    
    function claimAndWithdraw() public{
        withdrawReward();
        withdrawTokens();
    }
    
    function stakeTokens(uint amountOfTokens) public{
        stakeToken.transferFrom(msg.sender, address(this), amountOfTokens);
        userList[msg.sender].staked = amountOfTokens;
        userList[msg.sender].stakeTimes.push(now);
        userList[msg.sender].stakeAmounts.push(amountOfTokens);
        userList[msg.sender].startingAPYLength.push(apys.length-1);
        emit StakeTokens(msg.sender, amountOfTokens);
    }
    
    function calculateStaked(address usercheck) public view returns(uint totalMinted) {
        totalMinted = 0;
        for(uint i = 0; i<userList[usercheck].stakeAmounts.length; i++){
            for(uint j=userList[usercheck].startingAPYLength[i]; j<apys.length;j++){
                if(userList[usercheck].stakeTimes[i]<apyTimes[j]){
                    if(userList[usercheck].stakeTimes[i]<apyTimes[j-1]){
                        totalMinted += (userList[usercheck].stakeAmounts[i].mul((apyTimes[j]-apyTimes[j-1]))).div(apys[j]);
                    }else{
                        totalMinted += (userList[usercheck].stakeAmounts[i].mul((userList[usercheck].stakeTimes[i] - apyTimes[j]))).div(apys[j]);
                    }
                }else{
                    if(j==apys.length){
                        totalMinted += (userList[usercheck].stakeAmounts[i].mul((now - userList[usercheck].stakeTimes[i]))).div(apys[j]);
                    }else{
                        totalMinted += (userList[usercheck].stakeAmounts[i].mul((now - userList[usercheck].stakeTimes[i]))).div(apys[j]);
                    }
                }
            }
        }
    }
}