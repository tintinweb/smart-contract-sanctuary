/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/mockUniswap.sol


pragma solidity >=0.4.22 <0.9.0;



// 重要な値は大きく分けて3つある
// 1. token0の残高
// 2. token1の残高
// 3. depositという値（これはLiquidity供給者が預け入れたtokenの量を管理するための値）
contract mockUniswap {
    // 足し算割り算の安全性のためsafemathを利用
    using SafeMath for uint256;
    // Liquidity供給者の残高
    mapping(address => uint256) deposits;
    // そう残高
    uint256 totalDeposits;
    // １個目のトークン
    IERC20 token0;
    // ２個目のトークン
    IERC20 token1;

    bool isInitialized = false;

    address owner;

    constructor(IERC20 _token0, IERC20 _token1){
        token0 = _token0;
        token1 = _token1;
        owner = msg.sender;
    }
    
    function initialize(uint256 token0Amount, uint256 token1Amount) public {
        require(msg.sender == owner && !isInitialized, "Error: Invalid sender");
        // 最初のdepositを行うことで初期交換レートを設定する
        totalDeposits = token0Amount;
        deposits[msg.sender] = token0Amount;
        isInitialized = true;
        // transferFromとはこのアドレス(address(this))にsenderからamount送金する（送り主と送金関数を実行するaddressが同一でない場合のもの）
        require(token0.transferFrom(msg.sender, address(this), token0Amount), "TransferFrom token0 failed"); // msg.senderからaddress(this)にamount送ってください
        require(token1.transferFrom(msg.sender, address(this), token1Amount), "TransferFrom token1 failed");
    }

    // 交換レートの計算
    function calcRate(uint256 amount0, uint256 amount1) public view returns (uint256){
        // このコントラクトが所有するtoken0,  token1の残高を取得する
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 token1Balance = token1.balanceOf(address(this));
        // 交換レートはtoken1の残高 / token0の残高　で決まる(ただし小数点が表現できないので10**8をかけて、下8桁を小数点にしている)
        return ((token1Balance + amount1).mul(10**8).div(token0Balance + amount0));
    }

    function addLiquidity(uint256 token0Amount) public {
        require(isInitialized, "Error: has not initialized");
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 rate = calcRate(0, 0);
        // 追加するtoken1の量を確定させる
        // token1の数量は (今回追加するtoken0の量) * 交換レート (下8桁が小数点だったので10**8でわる)
        uint256 token1Amount = token0Amount.mul(rate).div(10**8);
        // depositの量を確定させる
        // depositの数量は　(今回追加するtoken0の量 / コントラクトが持っているtoken0の総量 * 全体のdeposit残高)
        uint256 share = token0Amount.mul(totalDeposits).div(token0Balance);
        // 追加したdepositを記録する
        deposits[msg.sender] = deposits[msg.sender].add(share);
        totalDeposits = totalDeposits.add(share);
        // 各トークンを送金してもらう
        require(token0.transferFrom(msg.sender, address(this), token0Amount), "TransferFrom token0 failed");
        require(token1.transferFrom(msg.sender, address(this), token1Amount), "TransferFrom token1 failed");
    }

    function removeLiquidity(uint256 shareAmount) public {
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 token1Balance = token1.balanceOf(address(this));
        // 今回引き出すdepositの数量 / 全体のdepositの数量　を計算することで今回引き出すdepositの全体に占める割合を確定する(下8桁小数点)
        uint256 shareRatio = shareAmount.mul(10**8).div(totalDeposits);
        // contractが所有するtoken0の量 * 先ほどの割合　で引き出せるtokenの数量が計算できる
        uint256 token0Returned = token0Balance.mul(shareRatio).div(10**8);
        uint256 token1Returned = token1Balance.mul(shareRatio).div(10**8);
        // depositを減らす
        deposits[msg.sender] = deposits[msg.sender].sub(shareAmount);
        totalDeposits = totalDeposits.sub(shareAmount);
        // 送金する
        require(token0.transfer(msg.sender, token0Returned), "Transfer token0 failed");
        require(token1.transfer(msg.sender, token1Returned), "Transfer token1 failed");
    }

    // is0to1 とはtrueならtoken0を送ってtoken1をもらう。falseならその逆
    // amountとは交換したいトークンの量(is0to1がtrueならtoken0の量。falseならその逆)
    function swap(uint256 amount, bool is0to1) public {
        if(is0to1){
            uint256 rate = calcRate(amount, 0);
            // senderに渡すtoken1の量を計算する
            // rateは token1 / token0なので (交換するtoken0の量) * rateで計算できる
            uint256 amount1 = amount.mul(rate).div(10**8);
            // 送金する
            // token0はtransferFrom
            // token1はtransfer
            require(token0.transferFrom(msg.sender, address(this), amount), "TransferFrom token0 failed");
            require(token1.transfer(msg.sender, amount1), "Transfer token1 failed");
        } else {
            uint256 rate = calcRate(0, amount);
            // senderに渡すtoken0の量を計算する
            // rateは token1 / token0なので (交換するtoken1の量) / rateで計算できる
            uint256 amount0 = amount.mul(10**8).div(rate);
            // token0はtransfer
            // token1はtransferFrom
            require(token0.transfer(msg.sender, amount0), "Transfer token0 failed");
            require(token1.transferFrom(msg.sender, address(this), amount), "TransferFrom token1 failed");
        }
    }

    function getTotalDeposits() public view returns(uint256){
        return totalDeposits;
    }

    function getDepositAmount(address owner) public view returns(uint256){
        return deposits[owner];
    }
}