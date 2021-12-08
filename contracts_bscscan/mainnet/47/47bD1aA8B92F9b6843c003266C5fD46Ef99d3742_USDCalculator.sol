/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract USDCalculator {

    IERC20 public BUSDBNB = IERC20(address(0x522361C3aa0d81D1726Fa7d40aA14505d0e097C9));
    IERC20 public FCBBNB = IERC20(address(0x5110E75c9E10D13b26ecea220cAF0C3968f906c9));
    IERC20 public BUSD = IERC20(address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56));
    IERC20 public FCB = IERC20(address(0xD6F53E7fA7c6c83D749255C06E9444E3325Ab53E));
    IERC20 public WBNB = IERC20(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));

    constructor() {

    }

    function get() external view returns(uint) {

        uint fcb_amt_fcb = FCB.balanceOf(address(FCBBNB));
        uint wbnb_amt_fcb = WBNB.balanceOf(address(FCBBNB));

        uint busd_amt_busd = BUSD.balanceOf(address(BUSDBNB));
        uint wbnb_amt_busd = WBNB.balanceOf(address(BUSDBNB));

        return fcb_amt_fcb / wbnb_amt_fcb * wbnb_amt_busd / busd_amt_busd;
    }

    function getFCBPerWBNB() external view returns(uint) {
        uint fcb_amt_fcb = FCB.balanceOf(address(FCBBNB));
        uint wbnb_amt_fcb = WBNB.balanceOf(address(FCBBNB));

        return fcb_amt_fcb / wbnb_amt_fcb;
    }

    function getWBNBPerBUSD() external view returns(uint) {
        uint busd_amt_busd = BUSD.balanceOf(address(BUSDBNB));
        uint wbnb_amt_busd = WBNB.balanceOf(address(BUSDBNB));

        return wbnb_amt_busd / busd_amt_busd;
    }

    function getFCBAmountInUSDWorth(uint amount_) external view returns(uint) {
        // insert USD amount
        return this.get() * amount_;
    }

    function getFCBFCB() external view returns(uint) {
        return FCB.balanceOf(address(FCBBNB));
    }

    function getWBNBFCB() external view returns(uint) {
        return WBNB.balanceOf(address(FCBBNB));
    }

    function getBUSDBUSD() external view returns(uint) {
        return BUSD.balanceOf(address(BUSDBNB));
    }

    function getWBNBBUSD() external view returns(uint) {
        return WBNB.balanceOf(address(BUSDBNB));
    }

}