/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface UniPoolLike {
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
    function swap(address, bool, int256, uint160, bytes calldata) external;
    function positions(bytes32) external view returns (uint128, uint256, uint256, uint128, uint128);
}

interface GUNITokenLike is IERC20 {
    function mint(uint256 mintAmount, address receiver) external returns (
        uint256 amount0,
        uint256 amount1,
        uint128 liquidityMinted
    );
    function burn(uint256 burnAmount, address receiver) external returns (
        uint256 amount0,
        uint256 amount1,
        uint128 liquidityBurned
    );
    function getMintAmounts(uint256 amount0Max, uint256 amount1Max) external view returns (uint256 amount0, uint256 amount1, uint256 mintAmount);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function pool() external view returns (address);
    function getUnderlyingBalances() external view returns (uint256, uint256);
}

interface PSMLike {
    function gemJoin() external view returns (address);
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}

interface GUNIRouterLike {
    function addLiquidity(
        address _pool,
        uint256 _amount0Max,
        uint256 _amount1Max,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address _receiver
    )
    external
    returns (
        uint256 amount0,
        uint256 amount1,
        uint256 mintAmount
    );
    function removeLiquidity(
        address _pool,
        uint256 _burnAmount,
        uint256 _amount0Min,
        uint256 _amount1Min,
        address _receiver
    )
    external
    returns (
        uint256 amount0,
        uint256 amount1,
        uint256 liquidityBurned
    );
}

interface GUNIResolverLike {
    function getRebalanceParams(
        address pool,
        uint256 amount0In,
        uint256 amount1In,
        uint256 price18Decimals
    ) external view returns (bool zeroForOne, uint256 swapAmount);
}

interface IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLender {
    function maxFlashLoan(
        address token
    ) external view returns (uint256);
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface GemJoinLike {
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface DaiJoinLike {
    function vat() external view returns (address);
    function dai() external view returns (address);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,  // [wad]
        uint256 rate, // [ray]
        uint256 spot, // [ray]
        uint256 line, // [rad]
        uint256 dust  // [rad]
    );
    function urns(bytes32, address) external view returns (uint256, uint256);
    function hope(address usr) external;
    function frob (bytes32 i, address u, address v, address w, int dink, int dart) external;
    function dai(address) external view returns (uint256);
    function file(bytes32, bytes32, uint256) external;
}

interface SpotLike {
    function ilks(bytes32) external view returns (address pip, uint256 mat);
}

contract GuniLev is IERC3156FlashBorrower {

    uint256 constant RAY = 10 ** 27;

    enum Action {WIND, UNWIND}

    VatLike public immutable vat;
    bytes32 public immutable ilk;
    GemJoinLike public immutable join;
    DaiJoinLike public immutable daiJoin;
    SpotLike public immutable spotter;
    GUNITokenLike public immutable guni;
    IERC20 public immutable dai;
    IERC20 public immutable otherToken;
    IERC3156FlashLender public immutable lender;
    PSMLike public immutable psm;
    address public immutable psmGemJoin;
    GUNIRouterLike public immutable router;
    GUNIResolverLike public immutable resolver;
    uint256 public immutable otherTokenTo18Conversion;

    constructor(
        GemJoinLike _join,
        DaiJoinLike _daiJoin,
        SpotLike _spotter,
        IERC20 _otherToken,
        IERC3156FlashLender _lender,
        PSMLike _psm,
        GUNIRouterLike _router,
        GUNIResolverLike _resolver
    ) {
        vat = VatLike(_join.vat());
        ilk = _join.ilk();
        join = _join;
        daiJoin = _daiJoin;
        spotter = _spotter;
        guni = GUNITokenLike(_join.gem());
        dai = IERC20(_daiJoin.dai());
        otherToken = _otherToken;
        lender = _lender;
        psm = _psm;
        psmGemJoin = PSMLike(_psm).gemJoin();
        router = _router;
        resolver = _resolver;
        otherTokenTo18Conversion = 10 ** (18 - _otherToken.decimals());
        
        VatLike(_join.vat()).hope(address(_daiJoin));
    }

    function getWindEstimates(address usr, uint256 principal) public view returns (uint256 estimatedDaiRemaining, uint256 estimatedGuniAmount, uint256 estimatedDebt) {
        uint256 leveragedAmount;
        {
            (,uint256 mat) = spotter.ilks(ilk);
            leveragedAmount = principal*RAY/(mat - RAY);
        }

        uint256 swapAmount;
        {
            (uint256 sqrtPriceX96,,,,,,) = UniPoolLike(guni.pool()).slot0();
            (, swapAmount) = resolver.getRebalanceParams(
                address(guni),
                guni.token0() == address(dai) ? leveragedAmount : 0,
                guni.token1() == address(dai) ? leveragedAmount : 0,
                ((((sqrtPriceX96*sqrtPriceX96) >> 96) * 1e18) >> 96) * otherTokenTo18Conversion
            );
        }

        uint256 daiBalance;
        {
            (,, estimatedGuniAmount) = guni.getMintAmounts(guni.token0() == address(dai) ? leveragedAmount - swapAmount : swapAmount / otherTokenTo18Conversion, guni.token1() == address(otherToken) ? swapAmount / otherTokenTo18Conversion : leveragedAmount - swapAmount);
            (,uint256 rate, uint256 spot,,) = vat.ilks(ilk);
            (uint256 ink, uint256 art) = vat.urns(ilk, usr);
            estimatedDebt = ((estimatedGuniAmount + ink) * spot / rate - art) * rate / RAY;
            daiBalance = dai.balanceOf(usr);
        }

        require(leveragedAmount <= estimatedDebt + daiBalance, "not-enough-dai");

        estimatedDaiRemaining = estimatedDebt + daiBalance - leveragedAmount;
    }

    function getUnwindEstimates(uint256 ink, uint256 art) public view returns (uint256 estimatedDaiRemaining) {
        (,uint256 rate,,,) = vat.ilks(ilk);
        (uint256 bal0, uint256 bal1) = guni.getUnderlyingBalances();
        uint256 totalSupply = guni.totalSupply();
        bal0 = bal0 * ink / totalSupply;
        bal1 = bal1 * ink / totalSupply;
        uint256 dy = (guni.token0() == address(dai) ? bal1 : bal0) * otherTokenTo18Conversion;

        return (guni.token0() == address(dai) ? bal0 : bal1) + dy - art * rate / RAY;
    }

    function getUnwindEstimates(address usr) external view returns (uint256 estimatedDaiRemaining) {
        (uint256 ink, uint256 art) = vat.urns(ilk, usr);
        return getUnwindEstimates(ink, art);
    }

    function getLeverageBPS() external view returns (uint256) {
        (,uint256 mat) = spotter.ilks(ilk);
        return 10000 * RAY/(mat - RAY);
    }

    function getEstimatedCostToWindUnwind(address usr, uint256 principal) external view returns (uint256) {
        (, uint256 estimatedGuniAmount, uint256 estimatedDebt) = getWindEstimates(usr, principal);
        (,uint256 rate,,,) = vat.ilks(ilk);
        return dai.balanceOf(usr) - getUnwindEstimates(estimatedGuniAmount, estimatedDebt * RAY / rate);
    }

    function wind(
        uint256 principal,
        uint256 minWalletDai
    ) external {
        bytes memory data = abi.encode(Action.WIND, msg.sender, minWalletDai);
        (,uint256 mat) = spotter.ilks(ilk);
        initFlashLoan(data, principal*RAY/(mat - RAY));
    }

    function unwind(
        uint256 minWalletDai
    ) external {
        bytes memory data = abi.encode(Action.UNWIND, msg.sender, minWalletDai);
        (,uint256 rate,,,) = vat.ilks(ilk);
        (, uint256 art) = vat.urns(ilk, msg.sender);
        initFlashLoan(data, art*rate/RAY);
    }

    function initFlashLoan(bytes memory data, uint256 amount) internal {
        uint256 _allowance = dai.allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(address(dai), amount);
        uint256 _repayment = amount + _fee;
        dai.approve(address(lender), _allowance + _repayment);
        lender.flashLoan(this, address(dai), amount, data);
    }

    function onFlashLoan(
        address initiator,
        address,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(
            msg.sender == address(lender),
            "FlashBorrower: Untrusted lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower: Untrusted loan initiator"
        );
        (Action action, address usr, uint256 minWalletDai) = abi.decode(data, (Action, address, uint256));
        if (action == Action.WIND) {
            _wind(usr, amount + fee, minWalletDai);
        } else if (action == Action.UNWIND) {
            _unwind(usr, amount, fee, minWalletDai);
        }
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function _wind(address usr, uint256 totalOwed, uint256 minWalletDai) internal {
        // Calculate how much DAI we should be swapping for otherToken
        uint256 swapAmount;
        {
            (uint256 sqrtPriceX96,,,,,,) = UniPoolLike(guni.pool()).slot0();
            (, swapAmount) = resolver.getRebalanceParams(
                address(guni),
                IERC20(guni.token0()).balanceOf(address(this)),
                IERC20(guni.token1()).balanceOf(address(this)),
                ((((sqrtPriceX96*sqrtPriceX96) >> 96) * 1e18) >> 96) * otherTokenTo18Conversion
            );
        }

        // Swap DAI for otherToken in PSM
        dai.approve(address(psm), swapAmount / otherTokenTo18Conversion * otherTokenTo18Conversion);    // Truncate rounding errors
        psm.buyGem(address(this), swapAmount / otherTokenTo18Conversion);

        // Mint G-UNI
        uint256 guniBalance;
        {
            uint256 bal0 = IERC20(guni.token0()).balanceOf(address(this));
            uint256 bal1 = IERC20(guni.token1()).balanceOf(address(this));
            dai.approve(address(router), bal0);
            otherToken.approve(address(router), bal1);
            (,, guniBalance) = router.addLiquidity(address(guni), bal0, bal1, 0, 0, address(this));
            dai.approve(address(router), 0);
            otherToken.approve(address(router), 0);
        }

        // Open / Re-enforce vault
        {
            guni.approve(address(join), guniBalance);
            join.join(address(usr), guniBalance);
            (,uint256 rate, uint256 spot,,) = vat.ilks(ilk);
            (uint256 ink, uint256 art) = vat.urns(ilk, usr);
            uint256 dart = (guniBalance + ink) * spot / rate - art;
            vat.frob(ilk, address(usr), address(usr), address(this), int256(guniBalance), int256(dart));
            daiJoin.exit(address(this), vat.dai(address(this)) / RAY);
        }

        uint256 daiBalance = dai.balanceOf(address(this));
        if (daiBalance > totalOwed) {
            // Send extra dai to user
            dai.transfer(usr, daiBalance - totalOwed);
        } else if (daiBalance < totalOwed) {
            // Pull remaining dai needed from usr
            dai.transferFrom(usr, address(this), totalOwed - daiBalance);
        }

        // Send any remaining dust from other token to user as well
        otherToken.transfer(usr, otherToken.balanceOf(address(this)));

        require(dai.balanceOf(address(usr)) + otherToken.balanceOf(address(this)) >= minWalletDai, "slippage");
    }

    function _unwind(address usr, uint256 amount, uint256 fee, uint256 minWalletDai) internal {
        // Pay back all CDP debt and exit g-uni
        (uint256 ink, uint256 art) = vat.urns(ilk, usr);
        dai.approve(address(daiJoin), amount);
        daiJoin.join(address(this), amount);
        vat.frob(ilk, address(usr), address(this), address(this), -int256(ink), -int256(art));
        join.exit(address(this), ink);

        // Burn G-UNI
        guni.approve(address(router), ink);
        router.removeLiquidity(address(guni), ink, 0, 0, address(this));

        // Trade all otherToken for dai
        uint256 swapAmount = otherToken.balanceOf(address(this));
        otherToken.approve(address(psmGemJoin), swapAmount);
        psm.sellGem(address(this), swapAmount);

        uint256 daiBalance = dai.balanceOf(address(this));
        uint256 totalOwed = amount + fee;
        if (daiBalance > totalOwed) {
            // Send extra dai to user
            dai.transfer(usr, daiBalance - totalOwed);
        } else if (daiBalance < totalOwed) {
            // Pull remaining dai needed from usr
            dai.transferFrom(usr, address(this), totalOwed - daiBalance);
        }

        // Send any remaining dust from other token to user as well
        otherToken.transfer(usr, otherToken.balanceOf(address(this)));

        require(dai.balanceOf(address(usr)) + otherToken.balanceOf(address(this)) >= minWalletDai, "slippage");
    }

}