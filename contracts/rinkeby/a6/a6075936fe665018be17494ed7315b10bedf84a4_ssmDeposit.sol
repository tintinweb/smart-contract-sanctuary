/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// File: contracts/Ownable.sol

pragma solidity 0.8.0;

contract Ownable{
    constructor(){
     _setOwner(msg.sender);
    }
    address public  owner;
    
    event OwnershipTransferred(
       address oldOwner,
       address newOwner
    );

    modifier onlyOwner(){
        require(msg.sender == owner,"Not an owner");
        _;
    }

    function _setOwner(address _owner) internal returns(bool){
         owner = _owner;
         return true;
    }
    

    function transferOwnership(address _newOwner)public onlyOwner returns(bool)
    {
        _setOwner(_newOwner);
        emit OwnershipTransferred(msg.sender, _newOwner);
        return true;
    }
}
// File: contracts/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// File: contracts/ssmDeposit.sol

pragma solidity ^0.8.0;



contract ssmDeposit is Ownable{

    constructor(address _ssmTokenAddress){
        ssmtoken = IERC20(_ssmTokenAddress);
    }

    //variables
    IERC20 ssmtoken;
    uint256 public MIN_DEPOSIT = 1000e18;
    uint256 internal MIN_EXPIRATION_DATE = 365 days;
   

    //mappings
    mapping(address => uint256)internal userDepositExpiration;
    mapping(address => uint256)internal userDeposit;

    //events
    event Deposit(
        address userAddress,
        uint256 userDepositedAmount,
        uint256 timestamp
    );

    event Claim(
        address userAddress,
        uint256 userClaimedAmount,
        uint256 timestamp
    );

    function depositTokens(uint _amount)external returns(bool){
        address user = msg.sender;

        require(_amount != 0 && _amount > MIN_DEPOSIT,"SSM: Deposit should be greater than 1000");
        require(ssmtoken.transferFrom(user,address(this),_amount),"SMM: Error in transfer");

        userDeposit[user] = _amount;
        userDepositExpiration[user] = block.timestamp + MIN_EXPIRATION_DATE;
        emit Deposit(user,_amount, block.timestamp);
        return true;
    } 
    
    function claim() external returns(bool){
      address user = msg.sender;
      uint256 amountDeposited = getUserDepositedAmount();

      require(amountDeposited != 0,"SSM: User has not deposited any amount");
      require(block.timestamp > getUserExpirationTime(),"SSM: Please wait before claim");
      
      uint256 userRewards = _calculateRewards(amountDeposited);
    
     
      require(ssmtoken.transferFrom(address(this), user, amountDeposited),"SMM: Error in transfer");
      require(ssmtoken.transferFrom(owner, user, userRewards),"SSM: Error in transfer");

      userDeposit[user] = 0;
      userDepositExpiration[user] = 0;
      emit Claim(user,amountDeposited + userRewards, block.timestamp);
      return true;

    }

    function _calculateRewards(uint256 _amountDeposited)internal pure returns(uint256){
        uint256 rewards = _amountDeposited * 10 / 100;
        return(rewards);
    }

    function getUserDepositedAmount()public view returns(uint256){
        return userDeposit[msg.sender];
    }

    function getUserExpirationTime()public view returns(uint256){
        return userDepositExpiration[msg.sender];
    }
}