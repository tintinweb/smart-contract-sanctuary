// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

import "./interfaces/IBizzSwap.sol";
import "./interfaces/external/IWETH9.sol";

contract BizzSwap is IBizzSwap, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct Invoice {
        uint256 exactAmountOut;
        address desiredTokenAddress;
        address recipient;
        bool isEthDesired;
        bool isPaid;
        string ipfsCid;
    }

    Counters.Counter private _invoiceId;
    ISwapRouter public uniswapRouterContract;

    mapping(uint256 => Invoice) public invoices;

    event RouterContractUpdated(address indexed uniswapRouterContract);
    event InvoiceCreated(uint256 indexed invoiceId, string ipfsCid, address indexed desiredTokenAddress, bool isEthDesired, address indexed recipient, uint256 exactAmountOut);
    event PaymentCompleted(uint256 indexed invoiceId, address indexed payer, address indexed inputTokenAddress, bool isPayedWithEth);

    modifier validAddress(address _address) {
        require(_address != address(0) && _address != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "BizzSwap: Invalid address");
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "BizzSwap: Invalid amount");
        _;
    }

    constructor(address _uniswapRouterContract) {
        setRouterContract(_uniswapRouterContract);
    }

    /// @inheritdoc IBizzSwap
    function setRouterContract(address _uniswapRouterContract)
    public
    override
    onlyOwner
    validAddress(_uniswapRouterContract)
    {
        uniswapRouterContract = ISwapRouter(_uniswapRouterContract);

        emit RouterContractUpdated(_uniswapRouterContract);
    }

    /// @inheritdoc IBizzSwap
    function createInvoice(
        address _desiredTokenAddress,
        bool _isEthDesired,
        uint256 _exactAmountOut, 
        string memory _ipfsCid
    )
    public
    override
    validAddress(_desiredTokenAddress)
    validAmount(_exactAmountOut)
    returns(uint256 invoiceId)
    {
        invoiceId = _invoiceId.current();
        address desiredTokenAddress = _isEthDesired ? IPeripheryImmutableState(address(uniswapRouterContract)).WETH9() : _desiredTokenAddress;
        invoices[invoiceId] = Invoice(_exactAmountOut, desiredTokenAddress, msg.sender, _isEthDesired, false, _ipfsCid);
        _invoiceId.increment();

        emit InvoiceCreated(invoiceId, _ipfsCid, _desiredTokenAddress, _isEthDesired, msg.sender, _exactAmountOut);
    }

    /// @inheritdoc IBizzSwap
    function payOneForOne(
        uint256 invoiceId,
        address _inputTokenAddress,
        uint256 _maximumAmountIn,
        SwapParameters memory _params
    )
    public
    payable
    override
    {
        Invoice storage invoice = invoices[invoiceId];

        require(invoice.recipient != address(0), "BizzSwap::payOneForOne: Invoice with specified ID does not exist");
        require(!invoice.isPaid, "BizzSwap::payOneForOne: Invoice already paid");

        pay(_params, invoice.isEthDesired, invoice.recipient, _inputTokenAddress, invoice.desiredTokenAddress, invoice.exactAmountOut, _maximumAmountIn);

        invoice.isPaid = true;

        emit PaymentCompleted(invoiceId, msg.sender, _inputTokenAddress, _params.isPayingWithEth);
    }


    /**
     * @notice Execute one on one micro payments
     *
     * @param _params - paramters necessary for the swap
     * @param _recipient - the one who receives output tokens
     * @param _inputTokenAddress - address of the input token
     * @param _outputTokenAddress - address of the output token
     * @param _exactAmountOut - goal amount of output token for the swap
     * @param _maximumAmountIn - maximum amount of input token one is willing to spend for the swap
     *
     * No return, reverts on error
     */
    function pay(
        SwapParameters memory _params,
        bool _isEthDesired,
        address _recipient,
        address _inputTokenAddress,
        address _outputTokenAddress,
        uint256 _exactAmountOut,
        uint256 _maximumAmountIn
    )
    public
    payable
    nonReentrant
    validAddress(_outputTokenAddress)
    validAddress(_recipient)
    {
        address WETH9 = IPeripheryImmutableState(address(uniswapRouterContract)).WETH9();

        if(_params.isPayingWithEth) 
        {
            require(msg.value > 0, "BizzSwap::pay: Msg.value must be greather than zero when paying with native coin");

            if(_isEthDesired) {
                _transferEth(_recipient, _exactAmountOut);
            } else if(_outputTokenAddress == WETH9) {
                _wrapEth(WETH9, _exactAmountOut, _recipient);
            } else {
                _swapEthForToken(_params, _recipient, WETH9, _outputTokenAddress,_exactAmountOut, msg.value);
            }
        } 
        else
        {
            if(_isEthDesired) {
                _swapTokenForEth(_params, _recipient, _inputTokenAddress, WETH9, _exactAmountOut, _maximumAmountIn);
            } else {
                _swapTokens(_params, _recipient, _inputTokenAddress, _outputTokenAddress, _exactAmountOut,_maximumAmountIn);
            }
        }
    }


    /**
     * @notice Swaps as little as possible of one token for :_exactAmountOut: of another token using Uniswap V3
     * @notice Depends on Uniswap's V3 SwapRouter periphery contract
     *
     * @param _params - paramters necessary for the swap
     * @param _recipient - the one who receives output tokens
     * @param _inputTokenAddress - address of the input token
     * @param _outputTokenAddress - address of the output token
     * @param _exactAmountOut - goal amount of output token for the swap
     * @param _maximumAmountIn - maximum amount of input token one is willing to spend for the swap
     *
     * No return, reverts on error
     */
    function _swap(
        SwapParameters memory _params,
        address _recipient,
        address _inputTokenAddress,
        address _outputTokenAddress,
        uint256 _exactAmountOut,
        uint256 _maximumAmountIn
    )
    internal
    validAddress(_inputTokenAddress)
    validAddress(_outputTokenAddress)
    returns(uint256 _amountIn)
    {
        TransferHelper.safeTransferFrom(_inputTokenAddress, msg.sender, address(this), _maximumAmountIn);
        TransferHelper.safeApprove(_inputTokenAddress, address(uniswapRouterContract), _maximumAmountIn);

        if(_params.isMultiSwap) {
            _amountIn = uniswapRouterContract.exactOutput(
                ISwapRouter.ExactOutputParams({
                    path: _params.path, // @dev to swap DAI for WETH9 through a USDC pool: abi.encodePacked(WETH9, poolFee, USDC, poolFee, DAI)
                    recipient: _recipient,
                    deadline: _params.deadline,
                    amountOut: _exactAmountOut,
                    amountInMaximum: _maximumAmountIn
                })
            );
        } else {
            _amountIn = uniswapRouterContract.exactOutputSingle(
                ISwapRouter.ExactOutputSingleParams({
                    tokenIn: _inputTokenAddress,
                    tokenOut: _outputTokenAddress,
                    fee: _params.fee,
                    recipient: _recipient,
                    deadline: _params.deadline,
                    amountOut: _exactAmountOut,
                    amountInMaximum: _maximumAmountIn,
                    sqrtPriceLimitX96: _params.sqrtPriceLimitX96
                })
            );
        }

        // refund leftover
        if(_amountIn < _maximumAmountIn) {
            TransferHelper.safeApprove(_inputTokenAddress, address(uniswapRouterContract), 0);
            TransferHelper.safeTransfer(_inputTokenAddress, msg.sender, _maximumAmountIn - _amountIn);
        }
    }


    /**
     * @notice Swaps as little as possible of native coin for :_exactAmountOut: of output token using Uniswap V3
     *
     * @param _params - paramters necessary for the swap
     * @param _recipient - the one who receives output tokens
     * @param _inputTokenAddress - WETH9 token address; always will be since the function is internal, this is cheaper
     * @param _outputTokenAddress - address of the output token
     * @param _exactAmountOut - goal amount of output token for the swap
     * @param _maximumAmountIn - maximum amount of native coin one is willing to spend for the swap
     *
     * No return, reverts on error
     */
    function _swapEthForToken(
        SwapParameters memory _params,
        address _recipient,
        address _inputTokenAddress,
        address _outputTokenAddress,
        uint256 _exactAmountOut,
        uint256 _maximumAmountIn
    ) internal {
        if(_params.isMultiSwap) {
            uniswapRouterContract.exactOutput{value: _maximumAmountIn}(
                ISwapRouter.ExactOutputParams({
                    path: _params.path,
                    recipient: _recipient,
                    deadline: _params.deadline,
                    amountOut: _exactAmountOut,
                    amountInMaximum: _maximumAmountIn
                })
            );
        } else {
            uniswapRouterContract.exactOutputSingle{value: _maximumAmountIn}(
                ISwapRouter.ExactOutputSingleParams({
                    tokenIn: _inputTokenAddress,
                    tokenOut: _outputTokenAddress,
                    fee: _params.fee,
                    recipient: _recipient,
                    deadline: _params.deadline,
                    amountOut: _exactAmountOut,
                    amountInMaximum: _maximumAmountIn,
                    sqrtPriceLimitX96: _params.sqrtPriceLimitX96
                })
            );
        }

        // refund leftover
        if(address(this).balance > 0) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        }
    }


    /**
     * @notice Swaps as little as possible of input token for :_exactAmountOut: of native coin
     *
     * @param _params - paramters necessary for the swap
     * @param _recipient - the one who receives output tokens
     * @param _inputTokenAddress - address of the input token
     * @param _outputTokenAddress - WETH9 token address; always will be since the function is internal, this is cheaper
     * @param _exactAmountOut - goal amount of native coin for the swap
     * @param _maximumAmountIn - maximum amount of the input token one is willing to spend for the swap
     *
     * No return, reverts on error
     */
    function _swapTokenForEth(
        SwapParameters memory _params,
        address _recipient,
        address _inputTokenAddress,
        address _outputTokenAddress,
        uint256 _exactAmountOut,
        uint256 _maximumAmountIn
    ) internal {
        address WETH9 = IPeripheryImmutableState(address(uniswapRouterContract)).WETH9();

        if(_inputTokenAddress == WETH9) {
            // receive WETH9 exactAmountOut of tokens
            TransferHelper.safeTransferFrom(_inputTokenAddress, msg.sender, address(this), _exactAmountOut);
        } else {
            // or swap input token for exactAmountOut of WETH9 tokens
            _swap(_params, address(this), _inputTokenAddress, _outputTokenAddress, _exactAmountOut, _maximumAmountIn);
        }

        // Then, Unwrap WETH9 amount of tokens in contract and send it to the recipient
        IWETH9(WETH9).withdrawTo(_recipient, _exactAmountOut);
    }


    /**
     * @notice execute one on one token payment
     *
     * @param _params - paramters necessary for the swap
     * @param _recipient - the one who receives output tokens
     * @param _inputTokenAddress - address of the input token
     * @param _outputTokenAddress - address of the output token
     * @param _exactAmountOut - goal amount of output token for the swap
     * @param _maximumAmountIn - maximum amount of input token one is willing to spend for the swap
     *
     * No return, reverts on error
     */
    function _swapTokens(
        SwapParameters memory _params,
        address _recipient,
        address _inputTokenAddress,
        address _outputTokenAddress,
        uint256 _exactAmountOut,
        uint256 _maximumAmountIn
    ) internal {
        if(_inputTokenAddress == _outputTokenAddress) {
            TransferHelper.safeTransferFrom(_inputTokenAddress, msg.sender, _recipient, _exactAmountOut);
        } else {
            _swap(_params, _recipient, _inputTokenAddress, _outputTokenAddress, _exactAmountOut, _maximumAmountIn);
        }
    }


    /**
     * @notice Deposit native coin to get wrapped token representation of native coin
     *
     * @param _weth9 - WETH9 token address
     * @param _exactAmountOut - amount of native coin to be wrapped
     * @param _recipient - the one who receives output tokens
     *
     * No return, reverts on error
     */
    function _wrapEth(address _weth9, uint256 _exactAmountOut, address _recipient) internal {
        IWETH9(_weth9).deposit{value: _exactAmountOut}();
        TransferHelper.safeTransfer(_weth9, _recipient, _exactAmountOut);

        // refund leftover
        if(msg.value > _exactAmountOut) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - _exactAmountOut);
        }
    }


    /**
     * @notice Transfer :_exactAmountOut: of native coins to the :_recipient:
     *
     * @param _exactAmountOut - amount of native coin to transfer
     * @param _recipient - the one who receives output coins
     *
     * No return, reverts on error
     */
    function _transferEth(address _recipient, uint256 _exactAmountOut) internal {
        TransferHelper.safeTransferETH(_recipient, _exactAmountOut);

        // refund leftover
        if(msg.value > _exactAmountOut) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - _exactAmountOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.8.0;

interface IBizzSwap {

  /**
   * @notice Parameters necessary for Uniswap V3 swap
   *
   * @param deadline - transaction will revert if it is pending for more than this period of time
   * @param fee - the fee of the token pool to consider for the pair
   * @param sqrtPriceLimitX96 - the price limit of the pool that cannot be exceeded by the swap
   * @param isMultiSwap - flag to check wheter to perform single or multi swap, cheaper than to compare path with abi.encodePacked("")
   * @param isPayingWithEth - true if User is paying with native coin, false otherwise; msg.value must be grether than zero if true
   * @param path - sequence of (tokenAddress - fee - tokenAddress), encoded in reverse order, which are the variables needed to compute each pool contract address in sequence of swaps
   *
   * @notice msg.sender executes the payment
   * @notice path is encoded in reverse order
   */
  struct SwapParameters {
        uint256 deadline;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        bool isMultiSwap;
        bool isPayingWithEth;
        bytes path;
  }


  /**
   * @notice Sets address of the Router Contract
   *
   * @notice Only Administrator multisig can call
   *
   * @param _uniswapRouterContract - the address of the Router Contract
   *
   * No return, reverts on error
   */
  function setRouterContract(address _uniswapRouterContract) external;

  /**
   * @notice Creates payment invoice
   *
   * @param _desiredTokenAddress - address of the desired token
   * @param _isEthDesired - true if User wants to receive native coin, false otherwise; if true, :_desiredTokenAddress: is irrelevant
   * @param _exactAmountOut - amount of the desired token that should be payed
   * @param _ipfsCid - ipfs hash of invoice details
   *
   * @return invoiceId - id of the newly created invoice
   */
  function createInvoice(address _desiredTokenAddress, bool _isEthDesired, uint _exactAmountOut, string memory _ipfsCid) external returns(uint256 invoiceId);

  /**
   * @notice Execute payment where sender pays in one token and recipient receives payment in one token
   *
   * @param invoiceId - id of the invoice to be paid
   * @param _inputTokenAddress - address of the input token
   * @param _maximumAmountIn - maximum amount of input token one is willing to spend for the payment
   * @param _params - paramters necessary for the swap
   *
   * No return, reverts on error
   */
  function payOneForOne(uint256 invoiceId, address _inputTokenAddress, uint256 _maximumAmountIn, SwapParameters memory _params) external payable;
}

// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.8.0;

/// @title Interface for WETH9
interface IWETH9
{
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether and send got ether to :account:
    function withdrawTo(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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