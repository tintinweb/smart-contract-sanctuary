import "./IRecipe.sol";
import "./IUniRouter.sol";
import "./ILendingLogic.sol";
import "./ILendingRegistry.sol";
import "./IPie.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

contract NestRedeem is Ownable {
    using SafeERC20 for IERC20;

    IERC20 immutable WETH;
    IUniRouter sushiRouter;
    IRecipe public recipe;
    ILendingRegistry public lendingRegistry;

    constructor(address _weth, address _sushiRouter, address _recipe, address _lendingRegistry) {
        WETH = IERC20(_weth);
        sushiRouter = IUniRouter(_sushiRouter);
        recipe = IRecipe(_recipe);
        lendingRegistry = ILendingRegistry(_lendingRegistry);
    }

    function redeemNestToWeth(address _nestAddress, uint256 _nestAmount) external {
        require(_nestAmount >= 1e2, "Min nest amount: 0.01");

        IPie pie = IPie(_nestAddress);
        require(pie.balanceOf(msg.sender) >= _nestAmount, "Insufficient nest balance");

        // Transfer nest tokens to redeem contract
        pie.transferFrom(msg.sender, address(this), _nestAmount);
        uint256 pieBalance = pie.balanceOf(address(this));

        // Get tokens inside the index, as well as the amounts received.
        (address[] memory tokens, uint256[] memory amounts) = pie.calcTokensForAmount(pieBalance);

        // Dissolve index for the individual tokens
        pie.exitPool(pieBalance);

        // Exchange underlying tokens for WETH
        for(uint256 i = 0; i < tokens.length; i++) {
            tokensToWeth(tokens[i]);
        }
        // Transfer redeemed WETH to msg.sender
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
    }

    function tokensToWeth(address _token) internal {
        // If they are lending tokens, unlend them
        address underlying = lendingRegistry.wrappedToUnderlying(_token);
        if (underlying != address(0)) {
            // calc amount according to exchange rate
            IERC20 _inputToken = IERC20(underlying);
            IERC20 _inputTokenWrapped = IERC20(_token);
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_token);
            uint256 exchangeRate = lendingLogic.exchangeRate(_token); // wrapped to underlying exchangeRate

            uint256 _amount = _inputTokenWrapped.balanceOf(address(this));
            uint256 underlyingAmount = _amount * exchangeRate / 1e18;

            // Unlend token
            (address[] memory _targets, bytes[] memory _data) = lendingRegistry.getUnlendTXData(_token, _amount, address(this));
            for(uint256 j = 0; j < _targets.length; j++) {
                _targets[j].call(_data[j]);
            }

            // If underlying token is wETH, no need to swap
            if (underlying == address(WETH)) return;

            // Swap tokens for weth
            _inputToken.approve(address(sushiRouter), 0);
            _inputToken.approve(address(sushiRouter), type(uint256).max);
            address[] memory _route = getRoute(underlying, address(WETH));
            uint256 _minOutAmount = sushiRouter.getAmountsOut(underlyingAmount, _route)[1];
            sushiRouter.swapExactTokensForTokens(underlyingAmount, _minOutAmount, _route, address(this), block.timestamp + 1);
            return;
        }

        IERC20 inputToken = IERC20(_token);
        address[] memory route = getRoute(_token, address(WETH));
        uint256 _amount = inputToken.balanceOf(address(this));
        uint256 minOutAmount = sushiRouter.getAmountsOut(_amount, route)[1];

        // Swap tokens for wETH
        inputToken.approve(address(sushiRouter), 0);
        inputToken.approve(address(sushiRouter), type(uint256).max);
        sushiRouter.swapExactTokensForTokens(_amount, minOutAmount, route, address(this), block.timestamp + 1);
    }

    function getLendingLogicFromWrapped(address _wrapped) internal view returns(ILendingLogic) {
        return ILendingLogic(
            lendingRegistry.protocolToLogic(
                lendingRegistry.wrappedToProtocol(
                    _wrapped
                )
            )
        );
    }

    function getRoute(address _inputToken, address _outputToken) internal pure returns(address[] memory route) {
        route = new address[](2);
        route[0] = _inputToken;
        route[1] = _outputToken;

        return route;
    }

    function updateSushiRouter(address _newSushiRouter) external onlyOwner {
        sushiRouter = IUniRouter(_newSushiRouter);
    }

    function updateRecipe(address _newRecipe) external onlyOwner {
        recipe = IRecipe(_newRecipe);
    }

    function updateLendingRegistry(address _newLendingRegistry) external onlyOwner {
        lendingRegistry = ILendingRegistry(_newLendingRegistry);
    }
}