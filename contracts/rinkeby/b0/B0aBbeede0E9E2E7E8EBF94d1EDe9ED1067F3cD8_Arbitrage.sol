pragma solidity 0.6.12;

interface IMyRouterInterface {
    // UniswapV2Interface
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Arbitrage {
    address public routerA;
    address public routerB;

    address public BUSD;
    address public BNB;

    address[] public path;
    address[] public reversePath;

    constructor() public {
        routerA = address(0xE49FaAd9fB25Cc7928c0Ca5e47dc55aB5F85Cd5e);
        routerB = address(0x458134fDB03ee63035b48BD07Ae39b799C1991CB);
        BUSD = address(0x62fA3d49518010d43FAf3101909730645Da488F1);
        BNB = address(0x7f014543C001a0F616c466ba6C3f2641D11a731c);

        path = [BUSD, BNB];
        reversePath = [BNB, BUSD];
    }

    function performArtbitrage(uint256 busdAmount) public {
        uint256 bnbPriceAtA = checkPriceAtRouterA();
        uint256 bnbPriceAtB = checkPriceAtRouterB();

        if (bnbPriceAtB > bnbPriceAtA) {
            // BNB B 600 > BNB A 500
            uint256 bnbAmountRecieved = swapAtRouterA(busdAmount);
            uint256 busdAmountRecieved = swapAtRouterB(bnbAmountRecieved);

            uint256 profit = busdAmountRecieved - busdAmount;
            IERC20(BUSD).transfer(msg.sender, profit);
        }
    }

    function withdrawBUSD() public {
        IERC20 theBUSD = IERC20(BUSD);
        theBUSD.transfer(msg.sender, theBUSD.balanceOf(address(this)));
    }

    function checkPriceAtRouterA() public view returns (uint256) {
        uint256 amountIn = 1 ether;
        return IMyRouterInterface(routerA).getAmountsOut(amountIn, path)[1];
    }

    function checkPriceAtRouterB() public view returns (uint256) {
        uint256 amountIn = 1 ether;
        return
            IMyRouterInterface(routerB).getAmountsOut(amountIn, reversePath)[1];
    }

    function swapAtRouterA(uint256 busdAmount) public returns (uint256) {
        // BUSD -> BNB
        path = [BUSD, BNB];

        IERC20(BUSD).approve(address(this), busdAmount);
        uint256[] memory amountsOut = IMyRouterInterface(routerA).getAmountsOut(
            busdAmount,
            path
        );
        uint256[] memory amountsBNB = IMyRouterInterface(routerA)
            .swapExactTokensForTokens(
                busdAmount,
                amountsOut[1],
                path,
                address(this),
                block.timestamp
            );
        return amountsBNB[1];
    }

    function swapAtRouterB(uint256 bnbAmount) public returns (uint256) {
        // BNB -> BUSD
        path = [BNB, BUSD];

        IERC20(BNB).approve(address(this), bnbAmount);
        uint256[] memory amountsOut = IMyRouterInterface(routerB).getAmountsOut(
            bnbAmount,
            path
        );
        uint256[] memory amountsBUSD = IMyRouterInterface(routerB)
            .swapExactTokensForTokens(
                bnbAmount,
                amountsOut[1],
                path,
                address(this),
                block.timestamp
            );
        return amountsBUSD[1];
    }
}