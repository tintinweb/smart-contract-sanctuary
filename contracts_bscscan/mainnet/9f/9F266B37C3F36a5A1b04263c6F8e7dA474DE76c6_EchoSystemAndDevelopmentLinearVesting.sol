/**
 *Submitted for verification at BscScan.com on 2021-09-15
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


// File contracts/LinearVestingContract.sol

pragma solidity ^0.8.0;

contract LinearVesting {
    address public token;
    uint256 public distributionAmount;
    uint256 public cliff;
    uint256 public nextUnlock;
    uint256 public constant interval = 1 * 30 days;  // Delays between each unlock CHANGE FIRST NUMBER ONLY
    uint256 public cycles;
    uint256 public unlockEnd;
    address public beneficiary;

    IERC20 _token;
    /* cliff - cliff need to be in 30 * months */
    constructor(address beneficiary_, address token_, uint256 distributionAmount_, uint256 cycles_, uint256 cliff_) {
        beneficiary = beneficiary_;
        token = token_;
        _token = IERC20(token_);
        cliff = cliff_;
        cycles = cycles_;
        nextUnlock = block.timestamp + cliff;
        unlockEnd = block.timestamp + cliff + (cycles - 1) * interval;
        distributionAmount = distributionAmount_;
    }

    function distribute() public // This can be called by anyone and will distribute the tokens to everyone on the whitelist, as long as Distribution is possible
    {
        require(block.timestamp >= nextUnlock, "No tokens to distribute yet");
        require(unlockEnd >= nextUnlock, "Distribution Completed");
        nextUnlock = nextUnlock + interval;

        uint256 initialTokenBalance = _token.balanceOf(beneficiary);

        _token.transfer(beneficiary, distributionAmount);

        uint256 afterTokenBalance = _token.balanceOf(beneficiary);
        require(afterTokenBalance > initialTokenBalance, "Failed sending tokens");
    }

    function recoverLeftover() public // Only callable once distribute has been called X amount of times (sucessfully), where X is the number of cycles above
    {
        require(unlockEnd <= block.timestamp, "Distribution not completed");
        uint256 leftOverBalance = _token.balanceOf(address(this));
        _token.transfer(beneficiary, leftOverBalance);
    }
}


// File contracts/For Client/EchoSystemAndDevelopmentVesting.sol

contract EchoSystemAndDevelopmentLinearVesting is LinearVesting {
    address beneficiary_ = 0x45C40E472770686d6f30fCa1724cCFd56A43E740;
    address tokenAddress = 0x0055448eEefD5c4bAc80d260fa63FF0D8402685f;
    uint256 cliff_ = 30 days * 6; // cliff is 6 month in days assuming each month has 30 days.
    constructor() LinearVesting(beneficiary_, tokenAddress, 1_500_000 ether, 20,  cliff_){

    }

}