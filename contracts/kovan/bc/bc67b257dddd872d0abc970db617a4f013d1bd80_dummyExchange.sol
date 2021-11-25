/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity 0.7.5 <0.8.0;

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
// File contracts/interfaces/IAggregationExecutor.sol

pragma solidity 0.7.5;
//interface for 1Inch dummy
interface IAggregationExecutor {
    function callBytes(bytes calldata data) external payable;  // 0xd9c45357
}
pragma solidity 0.7.5;
pragma abicoder v2;

//working tokens can be changed
contract dummyExchange {
    address public workingToken1;
    address public workingToken2;
    
    //part of 1inch dummy definition
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }
    
    constructor() payable{
        workingToken1 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; //Kovan WETH9 token
        workingToken2 = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2; //Kovan DAI token
    }
    function changeWorkingTokens(address newToken1, address newToken2) external payable{
        workingToken1 = newToken1;
        workingToken2 = newToken2;
    }
    //1inch swap dummy
    function swap(IAggregationExecutor caller, SwapDescription calldata desc, bytes calldata data) external {
        doStep1();
    }
    //DEX.AG dummy swap function
    function trade(
        IERC20 _from,
        IERC20 _to,
        uint256 fromAmount,
        address[] memory exchanges,
        address[] memory approvals,
        bytes memory data,
        uint256[] memory offsets,
        uint256[] memory etherValues,
        uint256 limitAmount,
        uint256 tradeType
        ) external{
        doStep2();
    }
    
    function doStep1() internal {
        uint256 bal = IERC20(workingToken2).balanceOf(address(this)); 
        IERC20(workingToken2).transfer(msg.sender, 4);                //Step1: accept token1, transfer token2
    }
    
    function doStep2() internal {
        uint256 bal = IERC20(workingToken1).balanceOf(address(this));
        IERC20(workingToken1).transfer(msg.sender, 4);            //Step2: accept token2, transfer token1
    }
}