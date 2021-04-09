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
import "./IOneInch.sol";

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

// Basket Weaver is a way to socialize gas costs related to minting baskets tokens
contract SocialWeaverV1 is ReentrancyGuard, Helpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IOneInch public constant OneInch = IOneInch(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);
    IBDPI public constant BDPI = IBDPI(0x0309c98B1bffA350bcb3F9fB9780970CA32a5060);

    IBasicIssuanceModule public constant DPI_ISSUER = IBasicIssuanceModule(0xd8EF3cACe8b4907117a45B0b125c68560532F94D);

    address public governance;

    // **** ETH **** //

    // Current weaveId
    uint256 public weaveIdETH = 0;

    // User Address => WeaveId => Amount deposited
    mapping(address => mapping(uint256 => uint256)) public depositsETH;

    // User Address => WeaveId => Claimed
    mapping(address => mapping(uint256 => bool)) public basketsClaimedETH;

    // WeaveId => Amount deposited
    mapping(uint256 => uint256) public totalDepositedETH;

    // Basket minted per weaveId
    mapping(uint256 => uint256) public basketsMintedETH;

    // **** DPI **** //
    uint256 public weaveIdDPI = 0;

    // User Address => WeaveId => Amount deposited
    mapping(address => mapping(uint256 => uint256)) public depositsDPI;

    // User Address => WeaveId => Claimed
    mapping(address => mapping(uint256 => bool)) public basketsClaimedDPI;

    // WeaveId => Amount deposited
    mapping(uint256 => uint256) public totalDepositedDPI;

    // Basket minted per weaveId
    mapping(uint256 => uint256) public basketsMintedDPI;

    // Approved users to call weave
    // This is v important as invalid inputs will
    // be basically a "fat finger"
    mapping(address => bool) public approvedWeavers;

    // **** Constructor and modifiers ****

    constructor(address _governance) {
        governance = _governance;

        // Enter compound markets
        address[] memory markets = new address[](2);
        markets[0] = CUNI;
        markets[0] = CCOMP;
        enterMarkets(markets);
    }

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyWeavers {
        require(msg.sender == governance || approvedWeavers[msg.sender], "!weaver");
        _;
    }

    receive() external payable {}

    // **** Protected functions ****

    function approveWeaver(address _weaver) public onlyGov {
        approvedWeavers[_weaver] = true;
    }

    function revokeWeaver(address _weaver) public onlyGov {
        approvedWeavers[_weaver] = false;
    }

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    // Emergency
    function recoverERC20(address _token) public onlyGov {
        require(address(_token) != address(BDPI), "!dpi");
        require(address(_token) != address(DPI), "!dpi");
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }

    /// @notice Converts DPI into a Basket, socializing gas cost
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  minMintAmount Minimum amount of basket token to mint
    /// @param  deadline      Deadline to mint by
    function weaveWithDPI(
        address[] memory derivatives,
        address[] memory underlyings,
        uint256 minMintAmount,
        uint256 deadline
    ) public onlyWeavers {
        require(block.timestamp <= deadline, "expired");
        uint256 bdpiToMint = _burnDPIAndGetMintableBDPI(derivatives, underlyings);
        require(bdpiToMint >= minMintAmount, "!mint-min-amount");

        // Save the amount minted to mintId
        // Leftover dust will be rolledover to next batch
        basketsMintedDPI[weaveIdDPI] = bdpiToMint;

        // Mint tokens
        BDPI.mint(bdpiToMint);

        weaveIdDPI++;
    }

    /// @notice Converts ETH into a Basket, socializing gas cost
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  minMintAmount Minimum amount of basket token to mint
    /// @param  deadline      Deadline to mint by
    function weaveWithETH(
        address[] memory derivatives,
        address[] memory underlyings,
        uint256 minMintAmount,
        uint256 deadline
    ) public onlyWeavers {
        require(block.timestamp <= deadline, "expired");

        // ETH -> DPI
        // address(0) is ETH
        (uint256 retAmount, uint256[] memory distribution) =
            OneInch.getExpectedReturn(address(0), DPI, address(this).balance, 2, 0);
        OneInch.swap{ value: address(this).balance }(
            address(0),
            DPI,
            address(this).balance,
            retAmount,
            distribution,
            0
        );
        // DPI -> BDPI
        uint256 bdpiToMint = _burnDPIAndGetMintableBDPI(derivatives, underlyings);
        require(bdpiToMint >= minMintAmount, "!mint-min-amount");

        // Save the amount minted to mintId
        // Leftover dust will be rolledover to next batch
        basketsMintedETH[weaveIdETH] = bdpiToMint;

        // Mint tokens
        BDPI.mint(bdpiToMint);

        weaveIdETH++;
    }

    // **** Public functions ****

    //// DPI

    /// @notice Deposits DPI to be later converted into the Basket by some kind soul
    function depositDPI(uint256 _amount) public nonReentrant {
        require(_amount > 1e8, "!dust-dpi");
        IERC20(DPI).safeTransferFrom(msg.sender, address(this), _amount);

        depositsDPI[msg.sender][weaveIdDPI] = depositsDPI[msg.sender][weaveIdDPI].add(_amount);
        totalDepositedDPI[weaveIdDPI] = totalDepositedDPI[weaveIdDPI].add(_amount);
    }

    /// @notice User doesn't want to wait anymore and just wants their DPI back
    function withdrawDPI(uint256 _amount) public nonReentrant {
        // Reverts if withdrawing too many
        depositsDPI[msg.sender][weaveIdDPI] = depositsDPI[msg.sender][weaveIdDPI].sub(_amount);
        totalDepositedDPI[weaveIdDPI] = totalDepositedDPI[weaveIdDPI].sub(_amount);

        IERC20(DPI).safeTransfer(msg.sender, _amount);
    }

    /// @notice User withdraws converted Basket token
    function withdrawBasketDPI(uint256 _weaveId) public nonReentrant {
        require(_weaveId < weaveIdDPI, "!weaved");
        require(!basketsClaimedDPI[msg.sender][_weaveId], "already-claimed");
        uint256 userDeposited = depositsDPI[msg.sender][_weaveId];
        require(userDeposited > 0, "!deposit");

        uint256 ratio = userDeposited.mul(1e18).div(totalDepositedDPI[_weaveId]);
        uint256 userBasketAmount = basketsMintedDPI[_weaveId].mul(ratio).div(1e18);
        basketsClaimedDPI[msg.sender][_weaveId] = true;

        IERC20(address(BDPI)).safeTransfer(msg.sender, userBasketAmount);
    }

    /// @notice User withdraws converted Basket token
    function withdrawBasketDPIMany(uint256[] memory _weaveIds) public {
        for (uint256 i = 0; i < _weaveIds.length; i++) {
            withdrawBasketDPI(_weaveIds[i]);
        }
    }

    //// ETH

    /// @notice Deposits ETH to be later converted into the Basket by some kind soul
    function depositETH() public payable nonReentrant {
        require(msg.value > 1e8, "!dust-eth");

        depositsETH[msg.sender][weaveIdETH] = depositsETH[msg.sender][weaveIdETH].add(msg.value);
        totalDepositedETH[weaveIdETH] = totalDepositedETH[weaveIdETH].add(msg.value);
    }

    /// @notice User doesn't want to wait anymore and just wants their ETH back
    function withdrawETH(uint256 _amount) public nonReentrant {
        // Reverts if withdrawing too many
        depositsETH[msg.sender][weaveIdETH] = depositsETH[msg.sender][weaveIdETH].sub(_amount);
        totalDepositedETH[weaveIdETH] = totalDepositedETH[weaveIdETH].sub(_amount);

        (bool s, ) = msg.sender.call{ value: _amount }("");
        require(s, "!transfer-eth");
    }

    /// @notice User withdraws converted Basket token
    function withdrawBasketETH(uint256 _weaveId) public nonReentrant {
        require(_weaveId < weaveIdETH, "!weaved");
        require(!basketsClaimedETH[msg.sender][_weaveId], "already-claimed");
        uint256 userDeposited = depositsETH[msg.sender][_weaveId];
        require(userDeposited > 0, "!deposit");

        uint256 ratio = userDeposited.mul(1e18).div(totalDepositedETH[_weaveId]);
        uint256 userBasketAmount = basketsMintedETH[_weaveId].mul(ratio).div(1e18);
        basketsClaimedETH[msg.sender][_weaveId] = true;

        IERC20(address(BDPI)).safeTransfer(msg.sender, userBasketAmount);
    }

    /// @notice User withdraws converted Basket token
    function withdrawBasketETHMany(uint256[] memory _weaveIds) public {
        for (uint256 i = 0; i < _weaveIds.length; i++) {
            withdrawBasketETH(_weaveIds[i]);
        }
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

    /// @notice
    function _burnDPIAndGetMintableBDPI(address[] memory derivatives, address[] memory underlyings)
        internal
        returns (uint256)
    {
        // Burn DPI
        uint256 dpiBal = IERC20(DPI).balanceOf(address(this));
        IERC20(DPI).approve(address(DPI_ISSUER), dpiBal);
        DPI_ISSUER.redeem(address(DPI), dpiBal, address(this));

        // Convert components to derivative
        (, uint256[] memory tokenAmountsInBasket) = BDPI.getAssetsAndBalances();
        uint256 basketTotalSupply = BDPI.totalSupply();
        uint256 bdpiToMint;
        for (uint256 i = 0; i < derivatives.length; i++) {
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