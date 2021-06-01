/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IAuctionHouse {
    function buy(
        uint256 wethInMax,
        uint256 bankInMax,
        uint256 floatOutMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function sell(
        uint256 floatIn,
        uint256 wethOutMin,
        uint256 bankOutMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

contract FloatBuyer {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function withdrawERC20(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(
            address(this),
            msg.sender,
            token.balanceOf(address(this))
        );
    }

    function approve(
        address tokenAddress,
        uint256 amount,
        address spender
    ) public onlyOwner {
        IERC20(tokenAddress).approve(spender, amount);
    }

    function executeAndBuy(
        address floatAddress,
        address usdcTokenAddress,
        uint256 usdcTokenAmount,
        address dexAddress,
        bytes memory dexData,
        address auctionHouse,
        uint256 wethInMax,
        uint256 bankInMax,
        uint256 floatOutMin,
        uint256 deadline
    ) public {
        // transfer usdc in
        IERC20 usdc = IERC20(usdcTokenAddress);
        usdc.transferFrom(msg.sender, address(this), usdcTokenAmount);

        (bool success1, ) = dexAddress.call(dexData);
        require(success1, "dex trade not sucessful");

        // buy float
        IAuctionHouse(auctionHouse).buy(
            wethInMax,
            bankInMax,
            floatOutMin,
            address(this),
            deadline
        );

        // transfer float out
        _sendOutAll(IERC20(floatAddress));
        // transfer leftover usdc
        _sendOutAll(usdc);
    }

    function executeAndSell(
        address floatAddress,
        address usdcTokenAddress,
        address wethTokenAddress,
        address dexAddress,
        bytes memory dexData,
        address auctionHouse,
        uint256 floatIn,
        uint256 wethOutMin,
        uint256 bankOutMin,
        uint256 deadline
    ) public {
        // transfer float in
        IERC20 float = IERC20(floatAddress);
        float.transferFrom(msg.sender, address(this), floatIn);

        // sell float for WETH
        IAuctionHouse(auctionHouse).sell(
            floatIn,
            wethOutMin,
            bankOutMin,
            address(this),
            deadline
        );

        // sell WETH for USDC
        (bool success1, ) = dexAddress.call(dexData);
        require(success1, "dex trade not sucessful");

        // transfer USDC out
        _sendOutAll(IERC20(usdcTokenAddress));
        // transfer leftover float
        _sendOutAll(float);
        // transfer leftover weth
        _sendOutAll(IERC20(wethTokenAddress));
    }

    function executeArbitrary(
        address targetAddress,
        bytes memory targetCallData
    ) public onlyOwner returns (bool) {
        (bool success, ) = targetAddress.call(targetCallData);
        return success;
    }

    function _sendOutAll(IERC20 token) private {
        token.transferFrom(
            address(this),
            msg.sender,
            token.balanceOf(address(this))
        );
    }
}