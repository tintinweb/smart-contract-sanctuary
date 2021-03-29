/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

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

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract ERC20Timelock {
    using SafeMath for uint256;
    mapping (address => uint256) public _tokenBalances;
    mapping (address => uint256) public _balances;
    mapping (address => uint256) public _unlockTimeTable;
    
    IERC20 public _token;
    
    constructor(address token)  {
        require(token != address(0), "Token can't be 0 address");
        _token = IERC20(token);
    }
    
    function lock(uint256 amount, address beneficiary, uint256 releaseTime) payable external {
        require(releaseTime > block.timestamp, "Release time is before current time");
        if (amount > 0) {
            _token.transferFrom(msg.sender, address(this), amount);
            _tokenBalances[beneficiary] = _tokenBalances[beneficiary].add(amount);
        }
        if (msg.value > 0) {
            _balances[beneficiary] = _balances[beneficiary].add(msg.value);
        }
        if (_unlockTimeTable[beneficiary] == 0) {
            _unlockTimeTable[beneficiary] = releaseTime;
        }
    }
    
    function unlock(address payable beneficiary) external {
        require (_unlockTimeTable[beneficiary] >= block.timestamp, "Not yet");
        if (_balances[beneficiary] > 0) {
            uint256 amount = _balances[beneficiary];
            _balances[beneficiary] = 0;
            beneficiary.send(amount);
        }
        if (_tokenBalances[beneficiary] > 0) {
            uint256 amount = _tokenBalances[beneficiary];
            _tokenBalances[beneficiary] = 0;
            _token.transfer(beneficiary, amount);
        }
        _unlockTimeTable[beneficiary] = 0;
    }
    
    function currentTime() public view returns (uint256 time) {
        time = block.timestamp;
    }
}