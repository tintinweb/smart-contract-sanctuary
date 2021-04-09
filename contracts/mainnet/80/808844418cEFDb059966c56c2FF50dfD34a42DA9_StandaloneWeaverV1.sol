// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Helpers.sol";

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";
import "./IUniswapV2.sol";
import "./IBasicIssuanceModule.sol";

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

// Basket Weaver is a way to socialize gas costs related to minting baskets tokens
contract StandaloneWeaverV1 is Helpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IBDPI public constant BDPI = IBDPI(0x0309c98B1bffA350bcb3F9fB9780970CA32a5060);

    address public governance;

    // **** Constructor and modifiers ****

    constructor(address _governance) {
        governance = _governance;

        // Enter compound markets
        address[] memory markets = new address[](2);
        markets[0] = CUNI;
        markets[0] = CCOMP;
        enterMarkets(markets);
    }

    receive() external payable {}

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    // **** Restricted functions ****

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    function recoverERC20(address _token) public onlyGov {
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }

    // **** Public Functions ****

    /// @notice Converts ETH into a Basket, socializing gas cost
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasket  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasket  How much 1 basket token is worth in ETH
    /// @param  minMintAmount Minimum amount of basket token to mint
    /// @param  deadline      Deadline to mint by
    function mintWithETH(
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasket,
        uint256 ethPerBasket,
        uint256 minMintAmount,
        uint256 deadline
    ) public payable returns (uint256) {
        require(block.timestamp <= deadline, "expired");
        
        // BDPI to mint
        uint256 bdpiToMint =
            _convertETHToDerivativeAndGetMintAmount(derivatives, underlyings, underlyingsInEthPerBasket, ethPerBasket);

        require(bdpiToMint >= minMintAmount, "!mint-min-amount");

        // Mint tokens and transfer to user
        BDPI.mint(bdpiToMint);
        IERC20(address(BDPI)).safeTransfer(msg.sender, bdpiToMint);

        return bdpiToMint;
    }

    // **** Internals ****

    /// @notice Chooses which router address to use
    function _getRouterAddressForToken(address _token) internal pure returns (address) {
        // Chooses which router (uniswap or sushiswap) to use to swap tokens
        // By default: SUSHI
        // But some tokens don't have liquidity on SUSHI, so we use UNI
        // Don't want to use 1inch as its too costly gas-wise

        if (_token == KNC || _token == LRC || _token == BAL || _token == MTA) {
            return UNIV2_ROUTER;
        }

        return SUSHISWAP_ROUTER;
    }

    /// @notice Converts ETH into the specific derivative and get mint amount for basket
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasketToken  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasketToken  How much 1 basket token is worth in ETH
    function _convertETHToDerivativeAndGetMintAmount(
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasketToken,
        uint256 ethPerBasketToken
    ) internal returns (uint256) {
        // Path
        address[] memory path = new address[](2);
        path[0] = WETH;

        // Convert them all to the underlyings
        uint256 bdpiToMint;

        // Get total amount in bdpi
        (, uint256[] memory tokenAmountsInBasket) = BDPI.getAssetsAndBalances();

        // BDPI total supply
        uint256 basketTotalSupply = BDPI.totalSupply();

        // ETH received
        uint256 totalETHReceived = address(this).balance;

        {
            uint256 ratio;
            uint256 ethToSend;
            for (uint256 i = 0; i < derivatives.length; i++) {
                ratio = underlyingsInEthPerBasketToken[i].mul(1e18).div(ethPerBasketToken);

                // Convert them from ETH to their respective tokens (truncate 1e6 for rounding errors)
                ethToSend = totalETHReceived.mul(ratio).div(1e24).mul(1e6);

                path[1] = underlyings[i];
                IUniswapV2Router02(_getRouterAddressForToken(underlyings[i])).swapExactETHForTokens{ value: ethToSend }(
                    0,
                    path,
                    address(this),
                    block.timestamp + 60
                );

                // Convert to from respective token to derivative
                _toDerivative(underlyings[i], derivatives[i]);

                // Approve derivative and calculate mint amount
                bdpiToMint = _approveDerivativeAndGetMintAmount(
                    derivatives[i],
                    basketTotalSupply,
                    tokenAmountsInBasket[i],
                    bdpiToMint
                );
            }
        }

        return bdpiToMint;
    }

    /// @notice Approves derivative to the basket address and gets the mint amount.
    ///         Mainly here to avoid stack too deep errors
    /// @param  derivative  Address of the derivative (e.g. cUNI, aYFI)
    /// @param  basketTotalSupply  Total supply of the basket token
    /// @param  tokenAmountInBasket  Amount of derivative currently in the basket
    /// @param  curMintAmount  Accumulator - whats the minimum mint amount right now
    function _approveDerivativeAndGetMintAmount(
        address derivative,
        uint256 basketTotalSupply,
        uint256 tokenAmountInBasket,
        uint256 curMintAmount
    ) internal returns (uint256) {
        uint256 derivativeBal = IERC20(derivative).balanceOf(address(this));

        IERC20(derivative).safeApprove(address(BDPI), 0);
        IERC20(derivative).safeApprove(address(BDPI), derivativeBal);

        // Calculate how much BDPI we can mint at max
        // Formula: min(e for e in bdpiSupply * tokenWeHave[e] / tokenInBDPI[e])
        if (curMintAmount == 0) {
            return basketTotalSupply.mul(derivativeBal).div(tokenAmountInBasket);
        }

        uint256 temp = basketTotalSupply.mul(derivativeBal).div(tokenAmountInBasket);
        if (temp < curMintAmount) {
            return temp;
        }

        return curMintAmount;
    }
}