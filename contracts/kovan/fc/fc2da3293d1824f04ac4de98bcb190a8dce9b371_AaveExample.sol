/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT

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

//no need to import safemath in solidity 8

/*
interface IaToken {
    function balanceOf(address _user) external view returns (uint256);
    function redeem(uint256 _amount) external;
}
*/

interface IaveProvider{
    function getLendingPool() external view returns (address);
}
interface IAaveLendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    
    function withdraw(address asset, uint256 amount, address to) external;
}

contract AaveExample {
    
    uint public balanceReceived = 0;
    
    IERC20 public usdt = IERC20(0x13512979ADE267AB5100878E2e0f485B568328a4); //Kovan address     USDC address 0xe22da380ee6B445bb8273C81944ADEB6E8450422
    IERC20 public aUsdt = IERC20(0xFF3c8bc103682FA918c954E84F5056aB4DD5189d); //Kovan address USDC
    IaveProvider provider   = IaveProvider(0x88757f2f99175387aB4C6a4b3067c77A695b0349);
    IAaveLendingPool public aaveLendingPool = IAaveLendingPool(provider.getLendingPool()); // Kovan address
    //IAaveLendingPool public aaveLendingPool = IAaveLendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    
    uint256 max = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  
    
    mapping(address => uint256) public userDepositedUsdt;
    
    constructor()   {
        
        usdt.approve(address(aaveLendingPool), max);
        aUsdt.approve(address(aaveLendingPool), max);

    }
    
    function receiveMoney() public payable {
        balanceReceived += msg.value;
    }
    
    // User deposit USDT and the A token goes to this contract
    function userDepositUsdt(uint256 _amountInUsdt) external {
        userDepositedUsdt[msg.sender] = _amountInUsdt;
        require(usdt.transferFrom(msg.sender, address(this), _amountInUsdt), "USDC Transfer failed!");
        aaveLendingPool.deposit(address(usdt), _amountInUsdt, msg.sender, 0);
    }
    
    // For testing pupose withdrawing to this contract now
    function userWithdrawUsdt(uint256 _amountInUsdt) external {
        require(userDepositedUsdt[msg.sender] >= _amountInUsdt, "You cannot withdraw more than deposited!");
        userDepositedUsdt[msg.sender] = userDepositedUsdt[msg.sender] - _amountInUsdt;
        aaveLendingPool.withdraw(address(aUsdt), _amountInUsdt, msg.sender); 
        
       
    }
}