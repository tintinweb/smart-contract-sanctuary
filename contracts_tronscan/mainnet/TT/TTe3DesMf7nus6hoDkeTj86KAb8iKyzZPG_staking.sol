//SourceUnit: HubStaking.sol

pragma solidity >=0.5.0 <0.6.0;

contract Token {
    function transferFrom(address from, address to, uint256 value) public returns (bool){}

    function transfer(address to, uint256 value) public returns (bool){}

    function balanceOf(address who) public view returns (uint256){}

    function burn(uint256 _value) public {}

    function decimals() public view returns(uint8){}
}

contract ITRC20 {
function transferFrom(address from, address to, uint256 value) external returns (bool); 
function transfer(address to, uint256 value) external returns (bool);
function balanceOf(address who) external view returns (uint256);
function totalSupply() external view returns (uint256);
function allowance(address owner, address spender) external view returns (uint256); 
function approve(address spender, uint256 value) external returns (bool);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract staking{
    using SafeMath for uint;
    struct Pool{
        ITRC20 token;
        uint tokensStaked;
        uint accTrxPerShare; //Stores the accumulated trx reward per token staked by user multiplied bu 10^12 to aid with calculations
        // uint rewards;
    }//Since there are 2 pools
    Pool public lpPool;//Both pools will have separate structures to store data
    Pool public tokenPool;
    uint overflowTRX;
    address payable admin;

    struct User{ //User Structure
        uint lpTotalStaked;
        uint tokenTotalStaked;
        uint claimed;
        uint lpRewardDebt; //Stores how much a user has withdrawn after a stakein. TRX pending to a user for lp is:
            //pending lp reward = (users[userAddress].totalStaked * lpPool.accTrxPerShare)/1e12 - users[userAddress].lpRewardDebt
        uint tokenRewardDebt;//similarly for token:
            //pending token reward = (users[userAddress].totalStaked * (tokenPool.accTrxPerShare)/1e12 - users[userAddress].tokenRewardDebt
    }
    mapping(address => User) public users; // public tag makes it possible to read stake data
    constructor(address payable adminAddr, address LPTokenAddress, address tokenAddress) public{
        lpPool.token = ITRC20(LPTokenAddress);
        tokenPool.token = ITRC20(tokenAddress);
        admin = adminAddr;
    }
    
    function addRewards() public payable{ // Function to be called by ICO Contract
        require(msg.value>0, "Msg value not > 0");
        if(lpPool.tokensStaked>0){ // As denominator cannot be 0, so add to overflow trx. Can be claimed by admin and manually added to rewards later on if needed
            lpPool.accTrxPerShare += (msg.value.mul(1e12).mul(7)).div(10).div(lpPool.tokensStaked); 
        //  as mentioned above, accTrxPerShare is multiplied by 1e12, the rest is just calculating 70% of the rewards/ total supply because: "per share"
        }else{
            overflowTRX += (msg.value.mul(7)).div(10);
        }
        if(tokenPool.tokensStaked>0){
            tokenPool.accTrxPerShare += (msg.value.mul(1e12).mul(3)).div(10).div(tokenPool.tokensStaked);
        }else{
            overflowTRX += (msg.value.mul(3)).div(30);
        }
    }
    
    
    function depositLP(uint amountOfTokens) public {
        require(lpPool.token.transferFrom(msg.sender, address(this), amountOfTokens)); //Transferring tokens from their wallet to contract
        User storage curUser = users[msg.sender]; //Storing the user struct in a variable
        if (curUser.lpTotalStaked > 0) { //Sending the trx reward
            uint256 pending =
                curUser.lpTotalStaked.mul(lpPool.accTrxPerShare).div(1e12).sub(
                    curUser.lpRewardDebt
                ); //See Comment on line 42 & 44
            msg.sender.transfer(pending); //Send them their pending reward
        }
        curUser.lpTotalStaked += amountOfTokens; // adding tokens to user's lp pool's total staked
        curUser.lpRewardDebt = (lpPool.accTrxPerShare.mul(curUser.lpTotalStaked)).div(1e12); //Calculating the reward debt as of this moment
        lpPool.tokensStaked += amountOfTokens; // adding tokens to lp pool's total staked
    }
    
    function depositTokens(uint amountOfTokens) public {
        require(tokenPool.token.transferFrom(msg.sender, address(this), amountOfTokens));
        User storage curUser = users[msg.sender];
        if (curUser.tokenTotalStaked > 0) {
            uint256 pending =
                curUser.tokenTotalStaked.mul(tokenPool.accTrxPerShare).div(1e12).sub(
                    curUser.tokenRewardDebt
                );
            msg.sender.transfer(pending);
        }
        curUser.tokenTotalStaked += amountOfTokens;
        curUser.tokenRewardDebt = (tokenPool.accTrxPerShare.mul(curUser.tokenTotalStaked)).div(1e12); 
        tokenPool.tokensStaked += amountOfTokens;
    }
    
    function withdrawLp(uint256 _amount) public {
        User storage curUser = users[msg.sender];
        require(curUser.lpTotalStaked >= _amount, "withdraw: not good"); //require amount requested to be greater than equal to staked
        uint256 pending =
            curUser.lpTotalStaked.mul(lpPool.accTrxPerShare).div(1e12).sub(
                curUser.lpRewardDebt
            ); // calculate pending reward
        msg.sender.transfer(pending); // transfer pending reward
        curUser.lpTotalStaked = curUser.lpTotalStaked.sub(_amount); //Change token holding of user
        curUser.lpRewardDebt = curUser.lpTotalStaked.mul(lpPool.accTrxPerShare).div(1e12); // Recalculate reward debt since rewards = 0
        lpPool.tokensStaked -= _amount; // Reduce tokens staked in lp pool
        lpPool.token.transfer(address(msg.sender), _amount); //
    }
    
    function withdrawToken(uint256 _amount) public {
        User storage curUser = users[msg.sender];
        require(curUser.tokenTotalStaked >= _amount, "withdraw: not good");
        uint256 pending =
            curUser.tokenTotalStaked.mul(tokenPool.accTrxPerShare).div(1e12).sub(
                curUser.tokenRewardDebt
            );
        msg.sender.transfer(pending);
        curUser.tokenTotalStaked = curUser.tokenTotalStaked.sub(_amount);
        curUser.tokenRewardDebt = curUser.tokenTotalStaked.mul(tokenPool.accTrxPerShare).div(1e12);
        tokenPool.tokensStaked -= _amount;
        tokenPool.token.transfer(address(msg.sender), _amount);
    }
    
    function lpClaimRewards() public {
        User storage curUser = users[msg.sender];
        uint256 pending = lpClaimableRewards(msg.sender); // get rewards from function
        msg.sender.transfer(pending); //transfer pending trx to user
        curUser.lpRewardDebt = curUser.lpTotalStaked.mul(lpPool.accTrxPerShare).div(1e12); // update reward debt
    }
    
    function tokenClaimRewards() public {
        User storage curUser = users[msg.sender];
        uint256 pending = tokenClaimableRewards(msg.sender);
        msg.sender.transfer(pending);
        curUser.tokenRewardDebt = curUser.tokenTotalStaked.mul(tokenPool.accTrxPerShare).div(1e12);
    }
    
    function tokenClaimableRewards(address _user) public view returns (uint256){
        return (users[_user].tokenTotalStaked.mul(tokenPool.accTrxPerShare).div(1e12).sub(users[_user].tokenRewardDebt));
    //  calculate reward from formula in line 44 
    } 
    function lpClaimableRewards(address _user) public view returns (uint256){
        return (users[_user].lpTotalStaked.mul(lpPool.accTrxPerShare).div(1e12).sub(users[_user].lpRewardDebt));
    }
    
    function withdrawOverflow() public{ //Withdrawing leftover for admin
        require(msg.sender == admin);
        admin.transfer(overflowTRX);
        overflowTRX = 0;
    }
    
}

//---------------------------SAFE MATH STARTS HERE ---------------------------
library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}