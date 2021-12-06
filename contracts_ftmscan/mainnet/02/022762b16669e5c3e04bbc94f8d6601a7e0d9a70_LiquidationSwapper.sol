/**
 *Submitted for verification at FtmScan.com on 2021-12-06
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// File contracts/swappers/SushiSwapMultiExactSwapper.sol
// SPDX-License-Identifier: MIT AND GPL-3.0
pragma solidity 0.8.7;

// solhint-disable avoid-low-level-calls

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
interface IERC20 {

}

// File @sushiswap/bentobox-sdk/contracts/[email protected]

interface IBentoBoxV1 {
    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
    
    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
    
    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

interface IKashiPairV1 {
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        address swapper
    ) external;
}

interface IExactSwapper {
    function swap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountMaxIn,
        address path1,
        address path2,
        address to,
        uint256 shareIn,
        uint256 shareOut
    ) external returns (uint256);
}

interface ISwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);
    
}


contract LiquidationSwapper is ISwapper {
    struct SwapData {
        address path1;
        address path2;
        address pair;
        address to;
    }
    
    IExactSwapper public immutable exactSwapper;
    IBentoBoxV1 private immutable bentoBox;
    SwapData private swapData;

    constructor(
        IExactSwapper _exactSwapper,
        IBentoBoxV1 _bentoBox
    )  {
        exactSwapper = _exactSwapper;
        bentoBox = _bentoBox;
    }
    
    function swap(IERC20 fromToken,
        IERC20 toToken,
        address,
        uint256 shareToMin,
        uint256 shareFrom) external override returns (uint256, uint256) {
        bentoBox.transfer(fromToken, address(this), address(exactSwapper), shareFrom);
        uint256 difference = exactSwapper.swap(fromToken, toToken, type(uint256).max, swapData.path1, swapData.path2, address(this), shareFrom, shareToMin);
        bentoBox.transfer(toToken, address(this), swapData.pair, shareToMin);
        bentoBox.withdraw(fromToken, address(this), swapData.to, 0, difference);
        return (0,0);
    }
    
    function liquidate(address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        IKashiPairV1 pair, address path1, address path2) external {
        swapData = SwapData(path1, path2, address(pair), to);
        pair.liquidate(users, maxBorrowParts, address(0), address(this));
    }

    
}