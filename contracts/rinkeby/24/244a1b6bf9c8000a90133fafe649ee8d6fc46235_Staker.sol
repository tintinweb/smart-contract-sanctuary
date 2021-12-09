/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: ERC20STaker.sol


pragma solidity ^0.8.0;


contract Staker {
    IERC20 token;
    address public owner;
    address public tokenAddress;
    uint public APY;
    uint public rewardInterval;
   
    


    mapping(address => uint) public UserTokenBalance;
    mapping(address => uint) public UserRewardAmount;
    mapping(address => uint) public lastStakeTime;
    mapping(address => uint) public lastUnstakeTime;


// Reward amount = Staked Amount * Reward Rate * TimeDiff / RewardInterval

    constructor() {
    
            owner = msg.sender;
            APY = 1000000000 ether;
            rewardInterval = 1 days;
            tokenAddress = 0x07B0749e071D624ba20520a852907B430396BA7C;
    }
    
    function rewardCalculator() public returns(uint){
    uint timeDiff = block.timestamp - lastStakeTime[msg.sender];
    uint rewardAmount = UserTokenBalance[msg.sender] * APY * timeDiff / rewardInterval;

    return rewardAmount;

    }


    function rewardCalculatoradd(address _add) public view returns(uint){
    uint timeDiff = lastUnstakeTime[_add] - lastStakeTime[_add];
    uint rewardAmount = UserTokenBalance[_add] * APY * timeDiff / rewardInterval;

    return rewardAmount;

    }

    function claimStakingRewards() public returns(bool){

//remember allowance in web3

        unStakeToken(rewardCalculator() );


    }


    
    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

  
  function setToken(address _tokenAddr) public OnlyOwner{
      
         token = IERC20(_tokenAddr);
         tokenAddress = _tokenAddr;
      
  }
  
  
   function GetUserTokenBalance() public view returns(uint256){ 
       return token.balanceOf(msg.sender);// balancdOf function is already declared in ERC20 token function
   }
   
   
   function GetAllowance(address _tokenOwnerAdd) public view returns(uint256){
       return token.allowance(_tokenOwnerAdd, address(this));
   }
   
   function stakeToken(uint256 _tokenamount) public returns(bool) {
       require(_tokenamount <= GetAllowance(msg.sender), "Please approve tokens for staking before transferring");
       token.transferFrom(msg.sender, address(this), _tokenamount);
       
        UserTokenBalance[msg.sender] += _tokenamount;
        lastStakeTime[msg.sender] = block.timestamp;
       
       return true;
   }
   
   
    function unStakeToken(uint256 _tokenamount) public returns(bool) {
        // require(_tokenamount <= GetAllowance(msg.sender), "Please approve tokens for unstaking before transferring");
       require(_tokenamount <= UserTokenBalance[msg.sender], "You cannot unstake more than you staked");
       token.transfer(msg.sender, _tokenamount);
       
            UserTokenBalance[msg.sender] -= _tokenamount;
            lastUnstakeTime[msg.sender] = block.timestamp;

       return true;
   }
   
function changeAPY(uint _apy) public OnlyOwner{

    APY = _apy;
}

function changerewardInterval(uint _rewardInterval) public OnlyOwner{

    rewardInterval = _rewardInterval;
}

   
    function addGas(uint256 _weiAMt) public payable {

        //just remember in the web3 implementation to set this equal to the ETH amount sent
        
        

   }
   
   
   
   function GetContractTokenBalance() public view returns(uint256){
       return token.balanceOf(address(this));
   }
   
}