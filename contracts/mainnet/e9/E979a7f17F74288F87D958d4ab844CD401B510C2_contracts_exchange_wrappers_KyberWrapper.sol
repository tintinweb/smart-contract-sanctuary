pragma solidity ^0.6.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterfaceV2.sol";
import "../../DS/DSMath.sol";

contract KyberWrapper is DSMath, ExchangeInterfaceV2 {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant KYBER_INTERFACE = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;
    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;

    using SafeERC20 for ERC20;

    /// @notice Sells a _srcAmount of tokens at Kyber
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external override payable returns (uint) {
        ERC20 srcToken = ERC20(_srcAddr);
        ERC20 destToken = ERC20(_destAddr);

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), _srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            _srcAmount,
            destToken,
            msg.sender,
            uint(-1),
            0,
            WALLET_ID
        );

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Kyber
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external override payable returns(uint) {
        ERC20 srcToken = ERC20(_srcAddr);
        ERC20 destToken = ERC20(_destAddr);

        uint srcAmount = 0;
        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmount = srcToken.balanceOf(address(this));
        } else {
            srcAmount = msg.value;
        }

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            srcAmount,
            destToken,
            msg.sender,
            _destAmount,
            0,
            WALLET_ID
        );

        require(destAmount == _destAmount, "Wrong dest amount");

        uint srcAmountAfter = 0;

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmountAfter = srcToken.balanceOf(address(this));
        } else {
            srcAmountAfter = address(this).balance;
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return (srcAmount - srcAmountAfter);
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return rate Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public override view returns (uint rate) {
        (rate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE)
            .getExpectedRate(ERC20(_srcAddr), ERC20(_destAddr), _srcAmount);

        // multiply with decimal difference in src token
        rate = rate * (10**(18 - getDecimals(_srcAddr)));
        // divide with decimal difference in dest token
        rate = rate / (10**(18 - getDecimals(_destAddr)));
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return rate Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public override view returns (uint rate) {
        uint256 srcRate = getSellRate(_srcAddr, _destAddr, _destAmount);
        uint256 srcAmount = wmul(_destAmount, srcRate);

        rate = getSellRate(_destAddr, _srcAddr, srcAmount);

        // increase rate by 3% too account for inaccuracy between sell/buy conversion
        rate = rate + (rate / 30);
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        if (_srcAddr == KYBER_ETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_srcAddr).safeTransfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    receive() payable external {}

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }
}
