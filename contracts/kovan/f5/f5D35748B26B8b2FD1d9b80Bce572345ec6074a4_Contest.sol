pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEnterContest{
    function enterCallback(uint256 amount) external;
    function refundCallback(address refundee, uint256 amount) external;
}

contract Contest{
    // The current King
    address public theKing;
    // Saving entering contract address since we can replace it over time
    IEnterContest public enterigContract;
    uint256 public kingsStake;

    IERC20 public tokenToStake;

    modifier onlyChecker(){
        require(msg.sender == 0xBe56E9aA7792B2f1F4132631B7A0E1927090D78A);
        _;
    }

    constructor(
        IERC20 _tokenToStake
    ){
        tokenToStake = _tokenToStake;
    }

    function beatTheKing(uint256 amount) external{
        require(amount > kingsStake, "not enough to beat");
        uint256 balance = tokenToStake.balanceOf(address(this));
        IEnterContest(msg.sender).enterCallback(amount);
        require(tokenToStake.balanceOf(address(this)) - balance >= amount, "got wrong amount");

        if(kingsStake > 0){
            tokenToStake.approve(address(enterigContract), type(uint256).max);
            enterigContract.refundCallback(theKing, kingsStake);
        }

        theKing = tx.origin;
        enterigContract = IEnterContest(msg.sender);
        kingsStake = amount;
    }

    // FUNCTION FOR CHECKER

    function checkTask(uint256 amount) external onlyChecker{
        require(amount > kingsStake, "not enough to beat");
        //uint256 balance = tokenToStake.balanceOf(address(this));
        //IEnterContest(msg.sender).enterCallback(amount);
        //require(tokenToStake.balanceOf(address(this)) - balance >= amount, "got wrong amount");

        if(kingsStake > 0){
            tokenToStake.approve(address(enterigContract), type(uint256).max);
            enterigContract.refundCallback(theKing, kingsStake);
        }

        theKing = tx.origin;
        enterigContract = IEnterContest(msg.sender);
        kingsStake = amount;
    }
}

// SPDX-License-Identifier: MIT
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