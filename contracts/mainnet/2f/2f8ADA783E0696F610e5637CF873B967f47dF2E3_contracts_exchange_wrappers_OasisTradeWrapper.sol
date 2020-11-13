pragma solidity ^0.6.0;

import "../../interfaces/ExchangeInterfaceV2.sol";
import "../../interfaces/OasisInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSMath.sol";
import "../../utils/SafeERC20.sol";
import "../../auth/AdminAuth.sol";

contract OasisTradeWrapper is DSMath, ExchangeInterfaceV2, AdminAuth {

    using SafeERC20 for ERC20;

    address public constant OTC_ADDRESS = 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Sells a _srcAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external override payable returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        ERC20(srcAddr).safeApprove(OTC_ADDRESS, _srcAmount);

        uint destAmount = OasisInterface(OTC_ADDRESS).sellAllAmount(srcAddr, _srcAmount, destAddr, 0);

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(destAmount);
            msg.sender.transfer(destAmount);
        } else {
            ERC20(destAddr).safeTransfer(msg.sender, destAmount);
        }

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external override payable returns(uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        ERC20(srcAddr).safeApprove(OTC_ADDRESS, uint(-1));

        uint srcAmount = OasisInterface(OTC_ADDRESS).buyAllAmount(destAddr, _destAmount, srcAddr, uint(-1));

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(_destAmount);
            msg.sender.transfer(_destAmount);
        } else {
            ERC20(destAddr).safeTransfer(msg.sender, _destAmount);
        }

        // Send the leftover from the source token back
        sendLeftOver(srcAddr);

        return srcAmount;
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public override view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(OasisInterface(OTC_ADDRESS).getBuyAmount(destAddr, srcAddr, _srcAmount), _srcAmount);
    }


    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public override view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(1 ether, wdiv(OasisInterface(OTC_ADDRESS).getPayAmount(srcAddr, destAddr, _destAmount), _destAmount));
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


    receive() payable external {}
}
