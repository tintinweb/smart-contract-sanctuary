pragma solidity 0.5.17;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity 0.5.17;

interface IUniswap {
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external
    returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external
    returns (uint[] memory amounts);
}

import "./lib/transfer-helper.sol";
import "./lib/uniswap.sol";

pragma solidity 0.5.17;

contract OperationsProcessor {
    event log(string message);

    uint256 constant CURRENCIES_NUMBER = 100;
    uint256 constant TOKENS_NUMBER = CURRENCIES_NUMBER - 1;
    address[TOKENS_NUMBER] private _tokens;
    IUniswap uniswap;

    function init(
        address[TOKENS_NUMBER] calldata tokens,
        address _uniswap
    ) external {
        uniswap = IUniswap(_uniswap);
        _tokens = tokens;
    }

    function() external payable { }

    function tokens() public view returns (address[TOKENS_NUMBER] memory) {
        return _tokens;
    }

    function getUniswapAddress() public view returns (address) {
        return address(uniswap);
    }

    function CW(uint256[] calldata tokensAmounts) external {
        _checkEthDeposit(tokensAmounts[0]);
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (tokensAmounts[i] != 0) {
                address token = _tokens[i-1];
                _doTokenDeposit(token, tokensAmounts[i]);
            }
        }
    }

    function processCreateWallet(uint256[] memory tokensAmounts) internal {
        _checkEthDeposit(tokensAmounts[0]);
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (tokensAmounts[i] != 0) {
                address token = _tokens[i-1];
                _doTokenDeposit(token, tokensAmounts[i]);
            }
        }
    }

    function processDeposit(uint256[] memory tokensAmounts) internal {
        _checkEthDeposit(tokensAmounts[0]);
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (tokensAmounts[i] != 0) {
                address token = _tokens[i-1];
                _doTokenDeposit(token, tokensAmounts[i]);
            }
        }
    }

    function SW(uint256 amountFrom, uint256 indexFrom, uint256 amountTo, uint256 indexTo) external {
        require(indexFrom != indexTo, "Anonymizer: FROM and TO addresses should be different");
        emit log("start swap");
        if (indexFrom == 0 || indexTo == 0) {
            if(indexFrom == 0) {
                address tokenTo = _tokens[indexTo-1];
                _ethToToken(amountFrom, amountTo, tokenTo);
            } else {
                address tokenFrom = _tokens[indexFrom-1];
                _tokenToEth(amountFrom, amountTo, tokenFrom);
            }
        }
        else {
            address tokenFrom = _tokens[indexFrom-1];
            address tokenTo = _tokens[indexTo-1];
            _tokenToToken(amountFrom, tokenFrom, amountTo, tokenTo);
        }
    }

    function processSwap(uint256 amountFrom, uint256 indexFrom, uint256 amountTo, uint256 indexTo) internal {
        require(indexFrom != indexTo, "Anonymizer: FROM and TO addresses should be different");
        emit log("start swap");
        if (indexFrom == 0 || indexTo == 0) {
            if(indexFrom == 0) {
                address tokenTo = _tokens[indexTo-1];
                _ethToToken(amountFrom, amountTo, tokenTo);
            } else {
                address tokenFrom = _tokens[indexFrom-1];
                _tokenToEth(amountFrom, amountTo, tokenFrom);
            }
        }
        else {
            address tokenFrom = _tokens[indexFrom-1];
            address tokenTo = _tokens[indexTo-1];
            _tokenToToken(amountFrom, tokenFrom, amountTo, tokenTo);
        }
    }

    function with_draw(uint256[] calldata deltas, address recepient) external {
        if (deltas[0] != 0) {
            TransferHelper.safeTransferETH(recepient, deltas[0]);
        }
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (deltas[i] != 0) {
                address token = _tokens[i-1];
                _doTokenWithdraw(token, deltas[i], recepient);
            }
        }
    }

    function processWithdraw(uint256[] memory deltas, address recepient) internal {
        if (deltas[0] != 0) {
            TransferHelper.safeTransferETH(recepient, deltas[0]);
        }
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (deltas[i] != 0) {
                address token = _tokens[i-1];
                _doTokenWithdraw(token, deltas[i], recepient);
            }
        }
    }

    function _checkEthDeposit(uint256 value) private view {
        require(msg.value == value, "Attached ether amount does not correspond to the declared amount");
    }

    function _doTokenDeposit(address token, uint256 value) private {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            value
        );
    }

    function _doTokenWithdraw(address token, uint256 value, address recepient) private {
        TransferHelper.safeTransfer(
            token,
            recepient,
            value
        );
    }

    function _ethToToken(uint256 amountFrom, uint256 amountTo, address tokenTo) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = tokenTo;
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactETHForTokens.value(amountFrom)(amountTo, path, address(this), deadline);
    }

    function _tokenToEth (uint256 amountFrom, uint256 amountTo, address tokenFrom) private returns (uint256[] memory amounts){
        TransferHelper.safeApprove(tokenFrom, address(uniswap), amountFrom);
        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = uniswap.WETH();
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactTokensForETH(
            amountFrom,
            amountTo,
            path,
            address(this),
            deadline
        );
    }

    function _tokenToToken (uint256 amountFrom, address tokenFrom, uint256 amountTo, address tokenTo) private returns (uint256[] memory amounts) {
        TransferHelper.safeApprove(tokenFrom, address(uniswap), amountFrom);
        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenTo;
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactTokensForTokens(amountFrom, amountTo, path, address(this), deadline);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}