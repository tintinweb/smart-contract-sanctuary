/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.7.6;


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
    function mint(address recipient, uint256 amount) external returns (bool);
    function burn(address recipient, uint256 amount) external returns (bool);

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

contract Test {
    
    struct user {
        uint depositAmt;
        uint tokenEarned;
        uint depositTime;
    }
    
    IERC20 public token;
    uint public depositAmount = 1e18;
    uint public maxDpositAmount = 5e18;
    uint public withdrawTime = 300;
    
    mapping(address => user) public users;
    address public liquidity;
    address public staking;
    constructor (address _liquidity,address _token,address _staking) {
        liquidity = _liquidity;
        token = IERC20(_token);
        staking = _staking;
    }
    
    receive()external payable {}
    
    /**
     *User can invest with above minimum deposit amount 
     * 10% amount will go for liquidity address
     * users deposits aboov 5 ether he will get 20% of dep amounts mindpay
     * if users deposits below 5 ethers 10% of dep amount mind pay will gt
     */
    function invest()public payable {
        require(msg.value > depositAmount,"Insufficeient invest amount");
        user storage userDetails = users[msg.sender];
        uint liquidityAmt = msg.value*10/100;
        payable(liquidity).transfer(liquidityAmt);
        userDetails.depositAmt = msg.value - liquidityAmt;
        userDetails.depositTime = block.timestamp;
        uint count = msg.value/1e18;
        if (count > 5) {
            token.mint(msg.sender,msg.value*20/100);
            userDetails.tokenEarned += msg.value*20/100;
        }
        else if (count <= 5) {
            token.mint(msg.sender,liquidityAmt);
            userDetails.tokenEarned += liquidityAmt;
        }
    }
    
    /**
     *users can cancel and get their invest after the period of timestamp
     * users token will be burned
     */
    function canelInvestment() public payable {
        user storage userDetails = users[msg.sender];
        require(userDetails.depositAmt > 0,"not yet deposit");
        require(block.timestamp >= userDetails.depositTime + withdrawTime,"Time not end");
        address(uint160(msg.sender)).transfer(userDetails.depositAmt);
        userDetails.depositAmt = 0;
        token.burn(msg.sender,userDetails.tokenEarned);
    }
    
    /**
     *user can stake their tokens here
     * And users dep amount will be go for liquiidty address
     */
    function stake(uint amount)public payable{
        user storage userDetails = users[msg.sender];
        require(amount > 0,"Invalid amount");
        require(userDetails.depositAmt > 0,"Insufficiet amount");
        require(block.timestamp >= userDetails.depositTime + withdrawTime,"Time not end");
        token.transferFrom(msg.sender,address(this),amount);
        address(uint160(liquidity)).transfer(userDetails.depositAmt);
        userDetails.depositAmt = 0;
        token.transfer(staking,amount);
    }
    
    function checkBalance()public view returns(uint){
        return address(this).balance;
    }
    
    function updateDepAmt(uint amt,uint maxamt)public {
        require(msg.sender == liquidity,"unauthoirze");
        depositAmount = amt;
        maxDpositAmount = maxamt;
    }
    
    function updateTime(uint _time)public {
    require(msg.sender == liquidity,"unauthoirze");    
       withdrawTime = _time;   
    }
}