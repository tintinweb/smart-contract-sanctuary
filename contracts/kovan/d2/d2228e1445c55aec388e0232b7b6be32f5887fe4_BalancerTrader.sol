/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.2;

interface PoolInterface {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
}

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}


contract BalancerTrader {
    PoolInterface public bPool;
    TokenInterface public daiToken;
    TokenInterface public weth;
    
    constructor(PoolInterface bPool_, TokenInterface daiToken_, TokenInterface weth_) {
        bPool = bPool_;
        daiToken = daiToken_;
        weth = weth_;
    }

    function pay(uint paymentAmountInDai) public payable {
        if (msg.value > 0) {
              _swapEthForDai(paymentAmountInDai);
        } else {
              require(daiToken.transferFrom(msg.sender, address(this), paymentAmountInDai));
        }
    }
    
    function _swapEthForDai(uint daiAmount) private {
        _wrapEth(); // wrap ETH and approve to balancer pool

        PoolInterface(bPool).swapExactAmountOut(
            address(weth),
            type(uint).max, // maxAmountIn, set to max -> use all sent ETH
            address(daiToken),
            daiAmount,
            type(uint).max // maxPrice, set to max -> accept any swap prices
        );

        require(daiToken.transfer(msg.sender, daiToken.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        _refundLeftoverEth();
    }
 
    function _wrapEth() private {
        weth.deposit{ value: msg.value }();
    
        if (weth.allowance(address(this), address(bPool)) < msg.value) {
            weth.approve(address(bPool), type(uint).max);
        }
    
    }
    
    function _refundLeftoverEth() private {
        uint wethBalance = weth.balanceOf(address(this));
    
        if (wethBalance > 0) {
            // refund leftover ETH
            weth.withdraw(wethBalance);
            (bool success,) = msg.sender.call{ value: wethBalance }("");
            require(success, "ERR_ETH_FAILED");
        }
    }
    
    receive() external payable {}
}