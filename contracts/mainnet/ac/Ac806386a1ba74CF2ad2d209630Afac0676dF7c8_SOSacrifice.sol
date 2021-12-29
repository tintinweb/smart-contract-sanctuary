/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
// File: IERC20.sol



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
// File: SOSacrifice.sol


pragma solidity ^0.8.3;


contract SOSacrifice {



    event Sacrificed(address indexed from, uint256 total);

    mapping (address => uint256) private _sosacrificed;

    IERC20 private _token;

    address _hak;

    address constant public _dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public _sacrificeTime = 1640710799;
    uint256 public first;
    uint256 public second;
    uint256 public third;

    constructor (IERC20 token_) {
        _token = token_;
        _hak = msg.sender;
    }

    function sacrifice(uint256 amount_) external {
        require(
            block.timestamp >= _sacrificeTime,
            "sacrifice not open"
        );
        address from = msg.sender;
        // 50% will be burned
        _token.transferFrom(from, _dead, amount_ / 2);
        // 50% will be used to cover evolving cost, reward, etc.
        _token.transferFrom(from, _hak, amount_ / 2);

        uint256 original = _sosacrificed[from];
        uint256 total = original + amount_;
        _sosacrificed[from] = total;

        if (total > first){
            first = total;
        } else if (total > second){
            second = total;
        } else if (total > third){
            third = total;
        }

        emit Sacrificed(from, total);
    }

    function sacrificedAmount(address addr) external view returns (uint256) {
        return _sosacrificed[addr];
    }

    modifier onlyHak() {
        require(msg.sender == _hak, "msg.sender is not hak");
        _;
    }

    function setHak(address hak_) external onlyHak {
        _hak = hak_;
    }

    function setTime(uint256 time_) external onlyHak {
        _sacrificeTime = time_;
    }
}