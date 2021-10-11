// SPDX-License-Identifier: GPL-3.0
// uni -> stable -> stable scheme
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../symbdex/libraries/TransferHelper.sol";
import "../synth-contracts/utils/IWrapper.sol";
import "../symbdex/interfaces/ISymbiosisV2Router02Restricted.sol";
import "../synth-contracts/interfaces/IPortal.sol";
import "../synth-contracts/interfaces/ISynthesis.sol";
import "../MetaRouteStructs.sol";

contract MetaRouterReverseUSU is Context {
    address public portal;
    address public wrapper;

    receive() external payable {}

    constructor(address _portal, address _wrapper) public {
        portal = _portal;
        wrapper = _wrapper;
    }

    function metaRouteReverse(
        MetaRouteStructs.MetaRouteReverseTransaction
            memory _metaRouteReverseTransaction
    ) external payable returns (bytes32) {

        TransferHelper.safeTransferFrom(
            _metaRouteReverseTransaction.firstPath[0],
            _msgSender(),
            address(this),
            _metaRouteReverseTransaction.amount
        );

        return
            _metaRouteReverseInternal(
                _metaRouteReverseTransaction,
                msg.value
            );
    }

    function metaRouteReverseNative(
         MetaRouteStructs.MetaRouteReverseTransaction
            memory _metaRouteReverseTransaction
    ) external payable returns (bytes32) {
        uint256 amount = _metaRouteReverseTransaction.amount;
        require(amount > 0, "MetaRouter: Not enough money");

        IWrapper(wrapper).deposit{value: amount}();

        return
            _metaRouteReverseInternal(
                _metaRouteReverseTransaction,
                msg.value - amount
            );
    }

    function _metaRouteReverseInternal(
         MetaRouteStructs.MetaRouteReverseTransaction
            memory _metaRouteReverseTransaction,
        uint256 bridgingFee
    ) internal returns (bytes32) {
        uint256 synthesizeAmount = _metaRouteReverseTransaction.amount;

        uint256 firstPathLength = _metaRouteReverseTransaction
            .firstPath
            .length;
        address rToken;

        // NOTE: if firstPath contains only one token (routing without first swap case) - it's rToken address
        rToken = _metaRouteReverseTransaction.firstPath[0];

        if (firstPathLength > 1) {
            IERC20(_metaRouteReverseTransaction.firstPath[0]).approve(
                _metaRouteReverseTransaction.firstDexRouter,
                synthesizeAmount
            );

            ISymbiosisV2Router02Restricted(
                _metaRouteReverseTransaction.firstDexRouter
            ).swapExactTokensForTokens(
                    synthesizeAmount,
                    _metaRouteReverseTransaction.firstAmountOutMin,
                    _metaRouteReverseTransaction.firstPath,
                    address(this),
                    _metaRouteReverseTransaction.firstDeadline
                );

            synthesizeAmount = IERC20(
                _metaRouteReverseTransaction.firstPath[
                    firstPathLength - 1
                ]
            ).balanceOf(address(this));

            rToken = _metaRouteReverseTransaction.firstPath[
                firstPathLength - 1
            ];
        }

        MetaRouteStructs.MetaSynthesizeTransaction
            memory metaSynthesizeTx = MetaRouteStructs
                .MetaSynthesizeTransaction(
                    rToken,
                    synthesizeAmount,
                    _metaRouteReverseTransaction.to,
                    _metaRouteReverseTransaction.synthesis,
                    _metaRouteReverseTransaction.bridge,
                    _msgSender(),
                    _metaRouteReverseTransaction.chainID,
                    _metaRouteReverseTransaction.secondPath,
                    _metaRouteReverseTransaction.secondDexRouter,
                    _metaRouteReverseTransaction.secondAmountOutMin,
                    _metaRouteReverseTransaction.finalPath,
                    _metaRouteReverseTransaction.finalDexRouter,
                    _metaRouteReverseTransaction.finalAmountOutMin,
                    _metaRouteReverseTransaction.finalDeadline
                );

        IERC20(rToken).approve(portal, synthesizeAmount);

        return
            IPortal(portal).metaSynthesize{value: bridgingFee}(
                metaSynthesizeTx
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrapper is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

import "../../MetaRouteStructs.sol";

interface IPortal {
  function getChainId() external view returns (uint256);

  function synthesize(
    address _token,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable returns (bytes32);

  function metaSynthesize(
    MetaRouteStructs.MetaSynthesizeTransaction
      memory _metaSynthesizeTransaction
  ) external payable returns (bytes32);

  function synthesizeNative(
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable returns (bytes32 txID);

  function synthesizeWithPermit(
    bytes calldata _approvalData,
    address _token,
    uint256 _amount,
    address _chain2address,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainID
  ) external payable returns (bytes32 txID);

  function revertSynthesize(bytes32 _txID) external;

  function unsynthesize(
    bytes32 _txID,
    address _token,
    uint256 _amount,
    address _to
  ) external;

  function revertBurnRequest(
    bytes32 _txID,
    address _receiveSide,
    address _oppositeBridge,
    uint256 _chainId
  ) external payable;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}