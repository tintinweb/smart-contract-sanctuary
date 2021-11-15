// SPDX-License-Identifier: GPL-3.0
// uni -> stable -> uni scheme

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../synth-contracts/interfaces/ISynthesis.sol";
import "../synth-contracts/interfaces/IBridge.sol";
import "../symbdex/interfaces/IERC20.sol";
import "../symbdex/libraries/TransferHelper.sol";
import "../symbdex/interfaces/ISymbiosisV2Router02Restricted.sol";
import "../stabledex/interfaces/ISwap.sol";
import "../MetaRouteStructs.sol";

contract MetaRouterUSU is Context {
  address public synthesis;

  receive() external payable {}

  constructor(address _synthesis) public {
    synthesis = _synthesis;
  }

  function metaRoute(
    MetaRouteStructs.MetaRouteTransaction memory _metarouteTransaction
  ) external payable returns (bytes32) {
    uint256 secondSwapAmountIn = _metarouteTransaction.amount;
    uint256 firstPathLength = _metarouteTransaction.firstPath.length;

    if (firstPathLength != 0) {
      TransferHelper.safeTransferFrom(
        _metarouteTransaction.firstPath[0],
        _msgSender(),
        address(this),
        _metarouteTransaction.amount
      );

      IERC20(_metarouteTransaction.firstPath[0]).approve(
        _metarouteTransaction.firstDexRouter,
        _metarouteTransaction.amount
      );

      ISymbiosisV2Router02Restricted(_metarouteTransaction.firstDexRouter)
        .swapExactTokensForTokens(
          _metarouteTransaction.amount,
          _metarouteTransaction.firstAmountOutMin,
          _metarouteTransaction.firstPath,
          address(this),
          _metarouteTransaction.firstDeadline
        );

      secondSwapAmountIn = IERC20(
        _metarouteTransaction.firstPath[firstPathLength - 1]
      ).balanceOf(address(this));
    } else {
      TransferHelper.safeTransferFrom(
        _metarouteTransaction.secondPath[0],
        _msgSender(),
        address(this),
        _metarouteTransaction.amount
      );
    }

    uint256 secondPathLength = _metarouteTransaction.secondPath.length;

    IERC20(_metarouteTransaction.secondPath[0]).approve(
      _metarouteTransaction.secondDexRouter,
      secondSwapAmountIn
    );

    ISwap(_metarouteTransaction.secondDexRouter).swap(
      ISwap(_metarouteTransaction.secondDexRouter).getTokenIndex(
        _metarouteTransaction.secondPath[0]
      ),
      ISwap(_metarouteTransaction.secondDexRouter).getTokenIndex(
        _metarouteTransaction.secondPath[secondPathLength - 1]
      ),
      secondSwapAmountIn,
      _metarouteTransaction.secondAmountOutMin,
      _metarouteTransaction.firstDeadline
    );

    uint256 secondSwapReturnAmount = IERC20(
      _metarouteTransaction.secondPath[secondPathLength - 1]
    ).balanceOf(address(this));

    bytes memory swapCalldata;
    if (_metarouteTransaction.finalPath.length != 0) {
      swapCalldata = abi.encodeWithSelector(
        bytes4(
          keccak256(
            bytes(
              "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"
            )
          )
        ),
        secondSwapReturnAmount,
        _metarouteTransaction.finalAmountOutMin,
        _metarouteTransaction.finalPath,
        _metarouteTransaction.to,
        _metarouteTransaction.finalDeadline
      );
    }

    MetaRouteStructs.MetaBurnTransaction memory metaBurnTransaction = MetaRouteStructs
      .MetaBurnTransaction(
        _msgSender(),
        _metarouteTransaction.finalDexRouter,
        _metarouteTransaction.secondPath[secondPathLength - 1], // sToken
        swapCalldata,
        secondSwapReturnAmount,
        _metarouteTransaction.to,
        _metarouteTransaction.portal,
        _metarouteTransaction.bridge,
        _metarouteTransaction.chainID
      );

    return
      ISynthesis(synthesis).metaBurnSyntheticToken{ value: msg.value }(
        metaBurnTransaction
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

import "../../MetaRouteStructs.sol";

interface ISynthesis {
  function mintSyntheticToken(
    bytes32 _txID,
    address _tokenReal,
    uint256 _chainID,
    uint256 _amount,
    address _to
  ) external;

  function revertSynthesizeRequest(
    bytes32 _txID,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable;

  function burnSyntheticToken(
    address _stoken,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable returns (bytes32 txID);

  function metaBurnSyntheticToken(
    MetaRouteStructs.MetaBurnTransaction memory _metaBurnTransaction
  ) external payable returns (bytes32 txID);

  function revertBurn(bytes32 _txID) external;

  function getBridgingFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IBridge {
    function transmitRequestV2(
        bytes memory owner,
        address receiveSide,
        address oppositeBridge,
        uint256 chainID
    ) external;

    function receiveRequestV2(
        bytes32 _requestId,
        bytes memory _callData,
        address _receiveSide,
        address _bridgeFrom
    ) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity 0.8.0;


interface ISymbiosisV2Router02Restricted {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

     function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        virtual
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISwap {
    function updateUserWithdrawFee(address recipient, uint256 transferAmount)
    external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function getTokenIndex(address tokenAddress) external view returns (uint8);
}

pragma solidity ^0.8.0;

library MetaRouteStructs {
  struct MetaBurnTransaction {
    address syntCaller;
    address finalDexRouter;
    address sToken;
    bytes swapCallData;
    uint256 amount;
    address chain2address;
    address receiveSide;
    address oppositeBridge;
    uint256 chainID;
  }

  struct MetaMintTransaction {
    bytes32 txID;
    address tokenReal;
    uint256 chainID;
    uint256 amount;
    address to;
    address[] secondPath;
    address secondDexRouter;
    uint256 secondAmountOutMin;
    address[] finalPath;
    address finalDexRouter;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
  }

  struct MetaRouteReverseTransaction {
    address to;
    address[] firstPath; // firstToken -> secondToken
    address[] secondPath; // sSecondToken -> WETH
    address[] finalPath; // WETH -> finalToken
    address firstDexRouter;
    address secondDexRouter;
    uint256 amount;
    uint256 firstAmountOutMin;
    uint256 secondAmountOutMin;
    uint256 firstDeadline;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
    address finalDexRouter;
    uint256 chainID;
    address bridge;
    address synthesis;
  }

  struct MetaRouteTransaction {
    address to;
    address[] firstPath; // uni -> BUSD
    address[] secondPath; // BUSD -> sToken
    address[] finalPath; // rToken -> another token
    address firstDexRouter;
    address secondDexRouter;
    uint256 amount;
    uint256 firstAmountOutMin;
    uint256 secondAmountOutMin;
    uint256 firstDeadline;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
    address finalDexRouter;
    uint256 chainID;
    address bridge;
    address portal;
  }

  struct MetaSynthesizeTransaction {
    address rtoken;
    uint256 amount;
    address chain2address;
    address receiveSide;
    address oppositeBridge;
    address syntCaller;
    uint256 chainID;
    address[] secondPath;
    address secondDexRouter;
    uint256 secondAmountOutMin;
    address[] finalPath;
    address finalDexRouter;
    uint256 finalAmountOutMin;
    uint256 finalDeadline;
  }
}

