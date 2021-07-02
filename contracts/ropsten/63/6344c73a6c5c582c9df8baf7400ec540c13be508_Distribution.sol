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
{    address address1 = 0xdd022aFFFdCF9f13C17cE836D7E2068eE582E1ef;
    address address2 = 0x0dAE534dc69Fd92Cd44ECa47a4CBb6B40CaFe85A;
    address address3 = 0xa0267fbd7542a3d93A1A288280C73Af4A27eBDb3;
    address address4 = 0x335383E3A03A14407ed8Fb85C4fC838677332F77;
    address address5 = 0x3efc3C4FB9579C577AcA37d3c271cBD9861FB9f4;
    address address6 = 0x55B416D204fA086e8e0B0a5DCC7951Ece58dA7c5;
    address address7 = 0xbFa191B10798Dae24Ce4a88D4dBe557e753367d4;
    address address8 = 0x9b96dd53Cb064DA75F028FD2d26c2CB64409Bc24;
    address address9 = 0x6b237Bf38c479EdC2d2af238b1A42E588CEc32e4;
    address address10 = 0xa8dC06E5FffEed16c569B7bd27BD3AF86a0EA5E4;
    address address11 = 0xC815A1C47841074B3EE1947338c932d0515666c6;
    address address12 = 0x106C736b34ea6ccA24eB48cA03F8B7b9dB4c4280;
    address address13 = 0xcAB7f67437049f874c76Cef1CAf1DB15E2BDF673;
    address address14 = 0x66cb09fc4a76a48f242A36CE676A515ac41Df796;
    address address15 = 0x4C77bC227eE09Ef960568207fbE280E988755714;
    address address16 = 0x175b90734D3252a0FfD0759bE41CE32665BA43df;
    address address17 = 0xe9c65e4F4c1C688da66e52Ac873F9aea480F7cd4;
    address address18 = 0x4C2f738da7d89b90FAA006b139f16Bf43712C170;
    address address19 = 0xea84CeAE9f73557673504Ea42777608425E726c8;
    address address20 = 0xf83e1f1FDdcA7E0FC07fa5658AfaE1ad9fB9CcAd;
    address address21 = 0xb59DC856e4EED5Fa3C82b8b171d2476064fb2822;
    address address22 = 0x11d7E22fe93C48681E1003cF0aC5c7118A9E4dA9;
    address address23 = 0x20cd9F0081027649604a20b5772c3a25d751C0b7;
    address address24 = 0x9720363251d248D9f95E95E1934114108a7eFAf6;
    address address25 = 0x4994817c8D184135Eae8B117137d0FD4B480e23b;
    address address26 = 0x05396eE54fa187750A5d740482e1770fE533cEaF;
    address address27 = 0xe97866957FF1d264Cc49849Fc379081781295CDC;
    address address28 = 0xa402212Bc41Fe6fa84c357F2e5A92d786917E890;
    address address29 = 0xB4bAf87888f69Ee26cdBA94145280BBb8Caf0f69;
    address address30 = 0xfD3c31a02c003770BD8CA4dfdA103376d6E2004D;
    address address31 = 0x78eEFE0337D41cf0898d010BCa075cE7635C0fdb;
    address address32 = 0xB4ccE9A399257B1Ef08bb7D27E42B396f757e7fD;
    address address33 = 0x8B18990FbaA668f1f2268f0AF9F37C7fb7f1e085;
    address address34 = 0xBf73623186411b1D26cD34957B7E5bE6D9Fd3b44;
    address address35 = 0xc7FEaC4e97B8F09C363d1b852719DE04873D69aa;
    address address36 = 0xf49F68e16e582ff2571edDAc7e2A5Aa1742D0e5F;
    

    address constant COINADDRESSTOKEN = 0x57157Baf4E11db961300E67A49Ab368cb3b13892;
    IERC20 coin = IERC20(COINADDRESSTOKEN);

    function transferTo() public
    {
        uint256 balance = coin.balanceOf(address(this));

        coin.transfer(address1, balance * 100 / 5000);
        coin.transfer(address2, balance * 100 / 5000);
        coin.transfer(address3, balance * 200 / 5000);
        coin.transfer(address4, balance * 100 / 5000);
	coin.transfer(address5, balance * 100 / 5000);
        coin.transfer(address6, balance * 100 / 5000);
        coin.transfer(address7, balance * 100 / 5000);
        coin.transfer(address8, balance * 100 / 5000);
	coin.transfer(address9, balance * 300 / 5000);
        coin.transfer(address10, balance * 150 / 5000);
        coin.transfer(address11, balance * 300 / 5000);
        coin.transfer(address12, balance * 100 / 5000);
	coin.transfer(address13, balance * 100 / 5000);
        coin.transfer(address14, balance * 100 / 5000);
        coin.transfer(address15, balance * 100 / 5000);
        coin.transfer(address16, balance * 250 / 5000);
	coin.transfer(address17, balance * 100 / 5000);
        coin.transfer(address18, balance * 100 / 5000);
        coin.transfer(address19, balance * 150 / 5000);
        coin.transfer(address20, balance * 334 / 5000);
	coin.transfer(address21, balance * 20 / 5000);
        coin.transfer(address22, balance * 100 / 5000);
        coin.transfer(address23, balance * 100 / 5000);
        coin.transfer(address24, balance * 100 / 5000);
        coin.transfer(address25, balance * 100 / 5000);
	coin.transfer(address26, balance * 150 / 5000);
        coin.transfer(address27, balance * 100 / 5000);
        coin.transfer(address28, balance * 50 / 5000);
        coin.transfer(address29, balance * 300 / 5000);
	coin.transfer(address30, balance * 100 / 5000);
        coin.transfer(address31, balance * 300 / 5000);
        coin.transfer(address32, balance * 100 / 5000);
        coin.transfer(address33, balance * 100 / 5000);
	coin.transfer(address34, balance * 100 / 5000);
        coin.transfer(address35, balance * 120 / 5000);
        coin.transfer(address36, balance * 176 / 5000);
    }
}