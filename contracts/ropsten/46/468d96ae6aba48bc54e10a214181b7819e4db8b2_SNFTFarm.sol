/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: MIT

// This contract is provided "as-is" under the principle of code-is-law.
// Any actions taken by this contract are considered the expected outcomes from a legal perspective.
// The deployer and maintainers have no liability in the result of any error.
// By interacting with this contract in any way you agree to these terms.

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.0;

contract SNFTFarm {
    
    mapping(address => uint256) public SNFTLPBalance;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public SNFTTokenBalance;
    
    string public name = "SNFTFarm";
    
    IERC20 public SNFTLP;
    IERC20 public SNFTToken;
    uint256 public launch;
    
    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);
    
    constructor(IERC20 _SNFTLP, IERC20 _snftToken) {
            SNFTLP = _SNFTLP;
            SNFTToken = _snftToken;
            launch = block.timestamp;
        }
        
    function stake(uint256 amount) public { 
    require(amount > 0 && SNFTLP.balanceOf(msg.sender) >= amount, "You cannot stake zero tokens");
            
     if(isStaking[msg.sender] == true){
        uint256 toTransfer = calculateYieldTotal(msg.sender);
        SNFTTokenBalance[msg.sender] += toTransfer;
        }
        
        SNFTLP.transferFrom(msg.sender, address(this), amount);
        SNFTLPBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        emit Stake(msg.sender, amount);
    }
    
    function unstake(uint256 amount) public {
        require(isStaking[msg.sender] = true && SNFTLPBalance[msg.sender] >= amount, "Insufficient Staked LP Tokens");
        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        startTime[msg.sender] = block.timestamp;
        uint256 balTransfer = amount;
        amount = 0;
        SNFTLPBalance[msg.sender] -= balTransfer;
        SNFTLP.transfer(msg.sender, balTransfer);
        SNFTTokenBalance[msg.sender] += yieldTransfer;
        if(SNFTLPBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }
        emit Unstake(msg.sender, balTransfer);
    }

    function calculateStakingTime(address user) public view returns(uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns(uint256) {
        uint256 eN = 271828;
        uint256 eD = 100000;
        uint256 rateCoefa = 25;
        uint256 rateCoefb = 100;
        uint256 currentBlock = block.timestamp;
        uint256 timeSinceInception = currentBlock - launch;
        uint256 rawYield = ((SNFTLPBalance[user] / SNFTLP.balanceOf(address(this))) * (SNFTToken.balanceOf(address(this)) * (1 - (eN/eD)**(((rateCoefa / rateCoefb) - ((rateCoefa / rateCoefb) * 2))*(timeSinceInception / 31536000)) ) )) / 10**18;
        return rawYield;
    } 
    
    function calculateYieldTest(address user) public view returns(uint256, uint256, uint256) {
        uint256 eN = 271828;
        uint256 eD = 100000;
        uint256 rateCoefa = 25;
        uint256 rateCoefb = 100;
        uint256 currentBlock = block.timestamp;
        uint256 timeSinceInception = currentBlock - launch;
        uint256 rawYield = ((SNFTLPBalance[user] / SNFTLP.balanceOf(address(this))) * (SNFTToken.balanceOf(address(this)) * (1 - (eN/eD)**(((rateCoefa / rateCoefb) - ((rateCoefa / rateCoefb) * 2))*(timeSinceInception / 31536000)) ) )) / 10**18;
        return (rawYield, currentBlock, timeSinceInception);
    } 

    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        require(toTransfer > 0 || SNFTTokenBalance[msg.sender] > 0, "Insufficient amount" );
            
        if(SNFTTokenBalance[msg.sender] != 0){
            uint256 oldBalance = SNFTTokenBalance[msg.sender];
            SNFTTokenBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }

        startTime[msg.sender] = block.timestamp;
        SNFTToken.transfer(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
    } 
    
}