pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/AdminAuth.sol";
import "./SaverExchange.sol";
import "../utils/SafeERC20.sol";

contract AllowanceProxy is AdminAuth {

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // TODO: Real saver exchange address
    SaverExchange saverExchange = SaverExchange(0x235abFAd01eb1BDa28Ef94087FBAA63E18074926);

    function callSell(SaverExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        saverExchange.sell{value: msg.value}(exData, msg.sender);
    }

    function callBuy(SaverExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        saverExchange.buy{value: msg.value}(exData, msg.sender);
    }

    function pullAndSendTokens(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount, "msg.value smaller than amount");
        } else {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(saverExchange), _amount);
        }
    }

    function ownerChangeExchange(address payable _newExchange) public onlyOwner {
        saverExchange = SaverExchange(_newExchange);
    }
}
