/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISushiRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}

contract NothingTooSeeHereInsecureDumbassTestingHisShittyCode {
    address public owner;
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public BCT = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    IERC20 public KLIMA = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    ISushiRouter public router = ISushiRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    uint constant TWENTY_MINUTES = 1200;

    constructor() {
        owner = msg.sender;

        USDC.approve(address(router), 2**256 - 1);
        BCT.approve(address(router), 2**256 - 1);
        KLIMA.approve(address(router), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "SniperInterface: caller is not the owner");
        _;
    }

    function BuyKLIMA() external onlyOwner {
        require(USDC.balanceOf(address(this)) > 0, "SniperInterface: No USDC balance");

        address[] memory path = new address[](3);
        path[0] = address(USDC);
        path[1] = address(BCT);
        path[1] = address(KLIMA);

        router.swapExactTokensForTokens(
            (USDC.balanceOf(address(this))),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function BuyBCT() external onlyOwner {
        require(USDC.balanceOf(address(this)) > 0, "SniperInterface: No USDC balance");

        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(BCT);
            
        router.swapExactTokensForTokens(
            (USDC.balanceOf(address(this))),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function withdrawTokensFromContract(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "SniperInterface: external call failed");
        return result;
    }
}