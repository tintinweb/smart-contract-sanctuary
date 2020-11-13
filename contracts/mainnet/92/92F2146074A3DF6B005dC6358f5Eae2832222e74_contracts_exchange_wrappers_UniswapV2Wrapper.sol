pragma solidity ^0.6.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces/ExchangeInterfaceV2.sol";
import "../../interfaces/UniswapRouterInterface.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";

/// @title DFS exchange wrapper for UniswapV2
contract UniswapV2Wrapper is DSMath, ExchangeInterfaceV2, AdminAuth {

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    UniswapRouterInterface public constant router = UniswapRouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    using SafeERC20 for ERC20;

    /// @notice Sells a _srcAmount of tokens at UniswapV2
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable override returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        uint[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        ERC20(_srcAddr).safeApprove(address(router), _srcAmount);

        // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            amounts = router.swapExactTokensForETH(_srcAmount, 1, path, msg.sender, block.timestamp + 1);
        }
        // if we are selling token to token
        else {
            amounts = router.swapExactTokensForTokens(_srcAmount, 1, path, msg.sender, block.timestamp + 1);
        }

        return amounts[amounts.length - 1];
    }

    /// @notice Buys a _destAmount of tokens at UniswapV2
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external override payable returns(uint) {

        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        uint[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        ERC20(_srcAddr).safeApprove(address(router), uint(-1));


         // if we are buying ether
        if (_destAddr == WETH_ADDRESS) {
            amounts = router.swapTokensForExactETH(_destAmount, uint(-1), path, msg.sender, block.timestamp + 1);
        }
        // if we are buying token to token
        else {
            amounts = router.swapTokensForExactTokens(_destAmount, uint(-1), path, msg.sender, block.timestamp + 1);
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return amounts[0];
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        uint[] memory amounts = router.getAmountsOut(_srcAmount, path);
        return wdiv(amounts[amounts.length - 1], _srcAmount);
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public override view returns (uint) {
        _srcAddr = ethToWethAddr(_srcAddr);
        _destAddr = ethToWethAddr(_destAddr);

        address[] memory path = new address[](2);
        path[0] = _srcAddr;
        path[1] = _destAddr;

        uint[] memory amounts = router.getAmountsIn(_destAmount, path);
        return wdiv(_destAmount, amounts[0]);
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    receive() payable external {}
}
