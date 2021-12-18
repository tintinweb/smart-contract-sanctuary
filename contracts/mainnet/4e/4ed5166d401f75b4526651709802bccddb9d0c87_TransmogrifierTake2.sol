/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface WETH9 {
    function withdraw(uint256) external;
}

interface SwapRouter02 {
    function checkOracleSlippage(bytes memory path, uint24 maximumTickDivergence, uint32 secondsAgo) external view;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract TransmogrifierTake2 {
    SwapRouter02 constant public swapRouter            = SwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    ERC20        constant public DAI                   = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    WETH9        constant public WETH                  = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint24       constant public fee                   = 500; // .05%
    bytes        constant public path                  = abi.encodePacked(DAI, fee, WETH);
    uint24       constant public maximumTickDivergence = 10; // represents a ~.1% price movement
    uint32       constant public secondsAgo            = 1 minutes;

    address immutable public recipient;

    constructor() {
        recipient = msg.sender;
    }

    receive() external payable {
        require(msg.sender == address(WETH));
    }

    function getDAIBalance() public view returns (uint256) {
        return DAI.balanceOf(address(this));
    }

    function canConvertSafely(uint24 maximumTickDivergence_, uint32 secondsAgo_) public view returns (bool) {
        try swapRouter.checkOracleSlippage(path, maximumTickDivergence_, secondsAgo_) {
            return true;
        } catch {
            return false;
        }
    }

    function convert(uint256 amountIn) external {
        if (amountIn == 0) amountIn = getDAIBalance();
        require(canConvertSafely(maximumTickDivergence, secondsAgo));
        DAI.transfer(address(swapRouter), amountIn); // DAI.transfer never returns false
        uint256 amountOut = swapRouter.exactInputSingle(SwapRouter02.ExactInputSingleParams({
            tokenIn:           address(DAI),
            tokenOut:          address(WETH),
            fee:               fee,
            recipient:         address(this), // so the WETH can be unwrapped
            amountIn:          0, // magic constant indicating that tokens have been paid already
            amountOutMinimum:  0, // safe because of the oracle check
            sqrtPriceLimitX96: 0
        }));
        WETH.withdraw(amountOut);
        (bool sent, ) = recipient.call{value: amountOut}("");
        require(sent);
    }
}