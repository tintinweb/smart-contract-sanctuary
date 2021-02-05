// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./RootKit.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./RootKitTransferGate.sol";
import "./UniswapV2Library.sol";
import "./KETH.sol";
import "./RootKitTwoPoolCalculator.sol";
import "./SafeMath.sol";
import "./IPonzoMaBobberV69.sol";
import "./IERC31337.sol";

contract PonzoMaBobberV69 is TokensRecoverable, IPonzoMaBobberV69

    /*
        Ponzo-Ma-BobberV69.sol
        Status: Fully functional Infinity Edition
        Calibration: Pumping Rootkit
        
        The Ponzo-Ma-Bobber is a contract with access to critical system control
        functions and liquidity tokens for ROOT. It uses kETH and the ERC-31337 
        sweeper functionality to make upwards market manipulation less tiresome.

        Created by @ProfessorPonzo


        uhhh wht?
        How does this all work you might ask?

        Any token with a fixed supply and permentantly locked liquidity has a very
        easy to calculate price floor. The ETH below the price floor is trapped 
        due to the unique market structure. In order to access this otherwise lost
        value, ROOT uses ERC-31337 to wrap wETH an extra time into kETH. Any ETH 
        trapped below the price floor in the wETH/ROOT liquidity pool is moved to
        the kETH/ROOT pool. The Floor Calculator checks how much ETH is trapped
        and removes the backing from that amount of kETH, thereby extracting the
        trapped value without effecting the market structure. Once the system is
        propped up by enough unbacked liquidity, control over factors like price
        and slippage become possible.

        After blowing thousands of ETH messing about with the market I finally
        Wrapped all my learnings into one function. A combination of...
        - Sweeping the floor and wrapping the recovered wETH into fresh kETH
        - Buying with the swept wETH and adding more liquidity
        - Removing liquidity and buying with the kETH
        - Temporarly removing ROOT tokens from circulating supply
        - Self arbatrage to extract one sided ETH liquidity

        Its just gunna pump forever lol.

        @ProfessorPonzo

    */

{
    using SafeMath for uint256;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    RootKit immutable rootKit;
    IWETH immutable weth;
    KETH immutable keth;
    IERC20 IKETH;
    IERC20 rootKeth;
    IERC20 rootWeth;
    RootKitTwoPoolCalculator calculator;
    RootKitTransferGate gate;
    mapping (address => bool) public infinitePumpers;
    uint256 minRootReverve;
    uint256 pumpItPonzoPumpAmount;
    uint256 sellmod;

    constructor(IUniswapV2Router02 _uniswapV2Router, KETH _keth, IWETH _weth, RootKit _rootKit, RootKitTwoPoolCalculator _calculator, RootKitTransferGate _gate)
    {
        uniswapV2Router = _uniswapV2Router;
        rootKit = _rootKit;
        calculator = _calculator;
        
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Factory = _uniswapV2Factory;
        weth = _weth;       
        keth = _keth;
        gate = _gate;

        _keth.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_uniswapV2Router), uint256(-1));
        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_keth), uint256(-1));

        rootKeth = IERC20(_uniswapV2Factory.getPair(address(_keth), address(_rootKit)));
        rootKeth.approve(address(_uniswapV2Router), uint256(-1));
        rootWeth = IERC20(_uniswapV2Factory.getPair(address(_weth), address(_rootKit)));
        rootWeth.approve(address(_uniswapV2Router), uint256(-1));
    }

    // The pump button is really fun, cant keep it all to myself
    function setInfinitePumper(address pumper, bool infinite) public ownerOnly() {
        infinitePumpers[pumper] = infinite;
    }
    
    // Minimum root balance to keep in contract
    function setMinRootReverve(uint256 minRoot) public ownerOnly() {
        minRootReverve = minRoot;
    }
    
    // Amount of LPs to remove and pump with
    function setPumpItPonzoPumpAmount(uint256 pumpAmount) public ownerOnly() {
        pumpItPonzoPumpAmount = pumpAmount;
    }

    // Percent to modify sell amount. 1031 base
    function setSellMod(uint256 mod) public ownerOnly() {
        sellmod = mod;
    }

    // Pumps or cycles root back into the pool
    function infinity() public override {
        if (rootKit.balanceOf(address(this)) >= minRootReverve) {
            uint256 pumpLPs = rootKeth.totalSupply().mul(1e18).mul(42069).div(100000).div(1e18);
            ETHiplication(pumpLPs);
        }
        else {
            PumpItPonzo(pumpItPonzoPumpAmount);
        }
    }

    function ETHiplicate(uint256 lpAmount) public override ownerOnly() {
        ETHiplication(lpAmount);
    }

    // Removes liq from keth pool, buys with all kETH, ignores all Root
    // Builds up a root balance in the Ponzo-Ma-Bobber
    function PumpItPonzo(uint256 liquidity) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        uint256 amountKeth= removeLiq(address(keth), liquidity);
        uint256 wethInWethLiq = weth.balanceOf(address(rootWeth));
        liquidity = amountKeth.mul(1e18).mul(wethInWethLiq).div(keth.balanceOf(address(rootKeth)).add(wethInWethLiq)).div(1e18);
        keth.withdrawTokens(liquidity);
        uniswapV2Router.swapExactTokensForTokens(keth.balanceOf(address(this)), 0, buyPath(), address(this), block.timestamp);
        uniswapV2Router.swapExactTokensForTokens(weth.balanceOf(address(this)), 0, buyPathWeth(), address(this), block.timestamp);
        gate.setUnrestricted(false);
    }

    // Equivilant to removing ETH only liquidity. When combined with the sweep 
    // function we can cycle our Root balance back into the liquidity pool
    function ETHiplication(uint256 LPsToArbAgainst) internal {
        uint256 totalExcessETH = calculator.calculateExcessInPools(weth, keth);
        //Sweep the floor - sweep it
        keth.sweepFloor(address(this));
        // Unlock LPs - unlock it
        gate.setUnrestricted(true);
        // Remove weth liq for ETH to arb with and extra root to dump - rug it left
        uint256 wethRemoved = removeLiq(address(weth), rootWeth.balanceOf(address(this)));
        // Change extra wETH into kETH - wrap it
        keth.depositTokens(weth.balanceOf(address(this)));
        // Remove kETH liq to extend price movements - rug it right
        uint256 kethRemoved = removeLiq(address(keth), LPsToArbAgainst);
        // Buy with all keth - pump it
        iPump(keth.balanceOf(address(this)));
        // calculate sell amount to return price to start - check it
        uint256 amountIn = uniswapV2Router.getAmountIn(kethRemoved.add(wethRemoved), rootKit.balanceOf(address(rootKeth)), keth.balanceOf(address(rootKeth)));
        // dump it back down - dump it
        iDump(amountIn.mul(sellmod).div(1000));
        // Withdraw original liquidity amount - unwrap it
        keth.withdrawTokens(wethRemoved);
        // Add back all weth liquidity - stitch it
        addLiq(address(weth), weth.balanceOf(address(this)));
        // Add back all weth liquidity - fix it
        addLiq(address(keth), keth.balanceOf(address(this)));
        // Lock LPs - lock it
        gate.setUnrestricted(false);
        // Check new floor against old floor - confirm it
        require (calculator.calculateExcessInPools(weth, keth) >= totalExcessETH, "Should have let it break, its always fixable. RIP gas"); // Guess some checks are important
    }

    // Move liquidity from kETH --->> wETH
    function zapKethToWeth(uint256 liquidity) public ownerOnly() {
        gate.setUnrestricted(true);
        removeLiq(address(keth),liquidity);
        keth.withdrawTokens(keth.balanceOf(address(this)));
        addLiq(address(weth), weth.balanceOf(address(this)));
        gate.setUnrestricted(false);
    }
    
    // Move liquidity from wETH --->> kETH
    function zapWethToKeth(uint256 liquidity) public ownerOnly() {
        gate.setUnrestricted(true);
        removeLiq(address(weth),liquidity);
        keth.depositTokens(weth.balanceOf(address(this)));
        addLiq(address(keth), keth.balanceOf(address(this)));
        gate.setUnrestricted(false);
    }

    // Helper functions
    function iPump(uint256 pumpAmount) internal { 
        uniswapV2Router.swapExactTokensForTokens(pumpAmount, 1, buyPath(), address(this), block.timestamp);
    }
    function iDump(uint256 dumpAmount) internal { 
        uniswapV2Router.swapExactTokensForTokens(dumpAmount, 1, sellPath(), address(this), block.timestamp);
    }
    function addLiq(address kethORweth, uint256 ethAmount) internal {
        uniswapV2Router.addLiquidity(address(kethORweth), address(rootKit), ethAmount, rootKit.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }
    function removeLiq(address kethORweth, uint256 tokens) internal returns (uint256) {
        (tokens,) = uniswapV2Router.removeLiquidity(address(kethORweth), address(rootKit), tokens, 0, 0, address(this), block.timestamp);
        return tokens;
    }
    function sellPath() internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(rootKit);
        path[1] = address(keth);
        return path;
    }
    function buyPath() internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(keth);
        path[1] = address(rootKit);
        return path;
    }
    function buyPathWeth() internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(rootKit);
        return path;
    }
}