/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity >=0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external returns (string memory);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract balanceTest {
    function deposit() public payable {}

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawal(uint256 amount) public {
        msg.sender.transfer(amount);
    }

    /**
    @dev 合约对多个账户进行资产分发
    - 【✔】用户地址
    - 【x】合约地址
    @param amount 提款数量
    @param addr1  地址1
    @param addr2  地址2
     */
    function withdrawalToUser(
        uint256 amount,
        address payable addr1,
        address payable addr2
    ) public {
        msg.sender.transfer((amount * 80) / 100);
        addr1.transfer((amount * 10) / 100);
        addr2.transfer((amount * 10) / 100);
    }

    /**
    @dev 合约获取地址资产
    - 【✔】获取合约资产
    - 【X】获取用户资产
     */
    function getBalance(address _addr) public view returns (uint256) {
        return address(_addr).balance;
    }

    /**
    @dev erc20 向多个合约进行转账
    发行token合约
    @param token 操作token
    @param addr1 地址1
    @param addr2 地址2
     */
    function tokenDispense(
        IERC20 token,
        uint256 amount,
        address addr1,
        address addr2,
        address addr3
    ) public {
        token.transfer(addr1, (amount * 80) / 100);
        token.transfer(addr2, (amount * 10) / 100);
        token.transfer(addr3, (amount * 10) / 100);
    }

}