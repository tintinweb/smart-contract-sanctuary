pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/GasTokenInterface.sol";
import "./SaverExchangeCore.sol";
import "../DS/DSMath.sol";
import "../loggers/DefisaverLogger.sol";
import "../auth/AdminAuth.sol";
import "../utils/GasBurner.sol";
import "../utils/SafeERC20.sol";

contract SaverExchange is SaverExchangeCore, AdminAuth, GasBurner {

    using SafeERC20 for ERC20;

    uint256 public constant SERVICE_FEE = 800; // 0.125% Fee

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    uint public burnAmount = 10;

    /// @notice Takes a src amount of tokens and converts it into the dest token
    /// @dev Takes fee from the _srcAmount before the exchange
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    /// @param _user User address who called the exchange
    function sell(ExchangeData memory exData, address payable _user) public payable burnGas(burnAmount) {

        // take fee
        uint dfsFee = getFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint destAmount) = _sell(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, _user);

        // log the event
        logger.Log(address(this), msg.sender, "ExchangeSell", abi.encode(wrapper, exData.srcAddr, exData.destAddr, exData.srcAmount, destAmount));
    }

    /// @notice Takes a dest amount of tokens and converts it from the src token
    /// @dev Send always more than needed for the swap, extra will be returned
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    /// @param _user User address who called the exchange
    function buy(ExchangeData memory exData, address payable _user) public payable burnGas(burnAmount){

        uint dfsFee = getFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint srcAmount) = _buy(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, _user);

        // log the event
        logger.Log(address(this), msg.sender, "ExchangeBuy", abi.encode(wrapper, exData.srcAddr, exData.destAddr, srcAmount, exData.destAmount));

    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @param _token Address of the token
    /// @return feeAmount Amount in Dai owner earned on the fee
    function getFee(uint256 _amount, address _token) internal returns (uint256 feeAmount) {
        uint256 fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(msg.sender)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(msg.sender);
        }

        if (fee == 0) {
            feeAmount = 0;
        } else {
            feeAmount = _amount / fee;
            if (_token == KYBER_ETH_ADDRESS) {
                WALLET_ID.transfer(feeAmount);
            } else {
                ERC20(_token).safeTransfer(WALLET_ID, feeAmount);
            }
        }
    }

    /// @notice Changes the amount of gas token we burn for each call
    /// @dev Only callable by the owner
    /// @param _newBurnAmount New amount of gas tokens to be burned
    function changeBurnAmount(uint _newBurnAmount) public {
        require(owner == msg.sender);

        burnAmount = _newBurnAmount;
    }

}
