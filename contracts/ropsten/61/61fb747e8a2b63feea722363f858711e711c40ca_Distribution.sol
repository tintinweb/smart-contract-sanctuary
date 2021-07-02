/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
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

contract Distribution
{
    address address1 = 0xC7B02A54bBD7087e94e244BE83a3de7C3D8e8BBe;
    address address2 = 0x0dAE534dc69Fd92Cd44ECa47a4CBb6B40CaFe85A;
    address address3 = 0x8B18990FbaA668f1f2268f0AF9F37C7fb7f1e085;
    address address4 = 0x59a563CE314aF9AbAEF035040F5a294390DaD36d;
    address address5 = 0x335383E3A03A14407ed8Fb85C4fC838677332F77;
    address address6 = 0xfD3c31a02c003770BD8CA4dfdA103376d6E2004D;
    address address7 = 0x6475C89Ac987ba9182858d479DE1d3606f93b8b3;
    address address8 = 0xC93C2954Fc154b0b9b1d6828229DFA8eAdF967C6;
    address address9 = 0x20cd9F0081027649604a20b5772c3a25d751C0b7;
    address address10 = 0x6b237Bf38c479EdC2d2af238b1A42E588CEc32e4;
    address address11 = 0x78eEFE0337D41cf0898d010BCa075cE7635C0fdb;
    address address12 = 0xa8dC06E5FffEed16c569B7bd27BD3AF86a0EA5E4;
    address address13 = 0xB2ae5e2Ee2f8AA2E52EAf690063B60AeD4e53560;
    address address14 = 0x11d7E22fe93C48681E1003cF0aC5c7118A9E4dA9;
    address address15 = 0x3efc3C4FB9579C577AcA37d3c271cBD9861FB9f4;
    address address16 = 0xf49F68e16e582ff2571edDAc7e2A5Aa1742D0e5F;
    address address17 = 0x3FE2Dd7aEFbd9D4a0E994339194e9025f50569D7;
    address address18 = 0x175b90734D3252a0FfD0759bE41CE32665BA43df;
    address address19 = 0xcAB7f67437049f874c76Cef1CAf1DB15E2BDF673;
    address address20 = 0x992d47D15AEe8d908E2C952cC41CE8e1258aF299;
    address address21 = 0x365DAedd21414891bCa6E3658bC553600Cb5D5C5;
    address address22 = 0x0bFcf26D2272a4719551f6324eF897173a195eBB;
    address address23 = 0xf83e1f1FDdcA7E0FC07fa5658AfaE1ad9fB9CcAd;

    address constant COINADDRESSTOKEN = 0x62f5525099B407098274658C2496307a480B8815;
    IERC20 coin = IERC20(COINADDRESSTOKEN);

    function transferTo() public
    {
        uint256 balance = coin.balanceOf(address(this));

        coin.transfer(address1, balance * 100 / 3000);
        coin.transfer(address2, balance * 100 / 3000);
        coin.transfer(address3, balance * 100 / 3000);
        coin.transfer(address4, balance * 150 / 3000);
	    coin.transfer(address5, balance * 100 / 3000);
        coin.transfer(address6, balance * 100 / 3000);
        coin.transfer(address7, balance * 350 / 3000);
        coin.transfer(address8, balance * 120 / 3000);
    	coin.transfer(address9, balance * 190 / 3000);
        coin.transfer(address10, balance * 200 / 3000);
        coin.transfer(address11, balance * 300 / 3000);
        coin.transfer(address12, balance * 100 / 3000);
    	coin.transfer(address13, balance * 200 / 3000);
        coin.transfer(address14, balance * 100 / 3000);
        coin.transfer(address15, balance * 100 / 3000);
        coin.transfer(address16, balance * 100 / 3000);
    	coin.transfer(address17, balance * 50 / 3000);
        coin.transfer(address18, balance * 100 / 3000);
        coin.transfer(address19, balance * 50 / 3000);
        coin.transfer(address20, balance * 100 / 3000);
    	coin.transfer(address21, balance * 65 / 3000);
        coin.transfer(address22, balance * 60 / 3000);
        coin.transfer(address23, balance * 165 / 3000);
    }
}