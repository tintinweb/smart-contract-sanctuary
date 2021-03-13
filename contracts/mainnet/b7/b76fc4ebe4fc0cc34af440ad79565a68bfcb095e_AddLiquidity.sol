/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/AddLiquidity.sol
pragma solidity >=0.7.4 <0.8.0;

////// src/AddLiquidity.sol
// SPDX-License-Identifier: MIT
/* pragma solidity ^0.7.4; */

interface ERC20_2 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address, uint256) external;
}

interface UniswapV2Router02 {
    function addLiquidity(address, address, uint256, uint256, uint256, uint256, address, uint256) external;
}

contract AddLiquidity {
    address constant public UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public radLiquidity = 0;
    uint256 public usdcLiquidity = 0;
    uint256 public minRadLiquidity = 0;
    uint256 public minUsdcLiquidity = 0;

    address immutable public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function setLiquidity(
        uint256 _radLiquidity,
        uint256 _usdcLiquidity,
        uint256 _minRadLiquidity,
        uint256 _minUsdcLiquidity
    ) public {
        require(msg.sender == admin, "Sender must be admin");
        require(_radLiquidity <= 500_000e18, "RAD liquidity must not exceed maximum");
        require(_usdcLiquidity <= 5_000_000e6, "USDC liquidity must not exceed maximum");
        require(_minRadLiquidity <= _radLiquidity);
        require(_minUsdcLiquidity <= _usdcLiquidity);

        radLiquidity = _radLiquidity;
        usdcLiquidity = _usdcLiquidity;
        minRadLiquidity = _minRadLiquidity;
        minUsdcLiquidity = _minUsdcLiquidity;
    }

    function addLiquidity(address rad, address usdc) public {
        require(
            ERC20_2(rad).transferFrom(msg.sender, address(this), radLiquidity),
            "Transfer of RAD must succeed"
        );
        require(
            ERC20_2(usdc).transferFrom(msg.sender, address(this), usdcLiquidity),
            "Transfer of USDC must succeed"
        );
        ERC20_2(rad).approve(UNISWAP_ROUTER, radLiquidity);
        ERC20_2(usdc).approve(UNISWAP_ROUTER, usdcLiquidity);

        UniswapV2Router02(UNISWAP_ROUTER).addLiquidity(
            rad,
            usdc,
            radLiquidity,
            usdcLiquidity,
            minRadLiquidity,
            minUsdcLiquidity,
            msg.sender,
            block.timestamp + 1 days
        );
    }
}