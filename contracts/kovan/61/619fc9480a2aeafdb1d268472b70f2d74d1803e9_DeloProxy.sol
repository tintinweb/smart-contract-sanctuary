// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract DeloProxy {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address owner;

    // Uniswap Router
    IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    //Kovan addresses
    address private constant DAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address private constant WBTC = 0xe0C9275E44Ea80eF17579d33c55136b7DA269aEb;
    address private constant USDC = 0x2F375e94FC336Cdec2Dc0cCB5277FE59CBf1cAe5;
    address private constant USDT = 0xf3e0d7bF58c5d455D31ef1c2d5375904dF525105;
    address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    uint24 public constant poolFee = 3000;

    address[] tokens = [WETH, DAI, USDC, USDT, WBTC, UNI];

	constructor(address _owner) {
     owner = _owner;
    }


    struct Order {
        address payable sender;
        uint8 tokenIn;          //token-in index
        uint8 tokenOut;         //token-out index
        uint amountIn;
        uint amountOut;
        uint ID;
    }

    event Received(address, uint);

    uint numOrders;
    mapping (uint => Order) orders;

    function nextID() private  returns (uint) {
        _tokenIds.increment();
        uint newNftTokenId = _tokenIds.current();

        return newNftTokenId;
    }

    // swap ether to token order (sell ETH)
    function etherToTokenOrder(address tokenOut, uint amountOut) public payable returns (uint orderID) {
        uint8 tokenIndex = findTokenIndex(tokenOut);
        require((tokenIndex < tokens.length && tokenIndex > 0), "Input INF");

        uint amountEth = msg.value;

        require(amountEth > 0 && amountOut > 0, "No ETH or Amt");

        orderID = numOrders++;
        uint tokenID =  nextID();

        orders[orderID] = Order(payable(msg.sender), 0, tokenIndex, amountEth, amountOut, tokenID);
        Order storage order =  orders[orderID];

    }

    function transferToken(address tokenIn, address _from, address _to, uint amount) internal returns (uint oid) {
        ERC20 token = ERC20(tokenIn);
            require(token.transferFrom(_from, _to, amount), "Transfer token failed");

            oid = numOrders++;

    }

    function findTokenIndex(address token) internal view returns (uint8 ret){
         ret = 128;
         for (uint8 i=0; i<tokens.length; i++){
             if (tokens[i] == token)
                ret = i;
         }
         return ret;
    }

    // swap one ERC20 token type to another
    function tokenToOtherOrder(address tokenIn, address tokenOut, uint amountIn, uint amountOut) public returns (uint orderID) {
        uint8 tokenIndex = findTokenIndex(tokenIn);
        require(tokenIndex < tokens.length && findTokenIndex(tokenOut) < tokens.length, "Token not found");

        ERC20 token = ERC20(tokenIn);
        require(amountIn > 0 && amountIn <= token.balanceOf(msg.sender), "Not enough token to trade");

        orderID = transferToken(tokenIn, msg.sender, address(this), amountIn);

        uint tokenID =  nextID();
        orders[orderID] =  Order(payable(msg.sender), tokenIndex, findTokenIndex(tokenOut), amountIn, amountOut, tokenID);
        Order storage order = orders[orderID];
    }

     function swapOrderTaker(uint orderID, uint estGas, uint delay)  external payable returns (bool){
          //uint amountEth = msg.value;
          (uint index, bool found) = findOrder(orderID);

          require ((found), "Order not found");

          uint8 Idx = orders[index].tokenIn;
          uint8 Odx = orders[index].tokenOut;
          address oToken = tokens[Odx];

          uint amtIn = orders[index].amountIn;
          uint expectedAmtOut = orders[index].amountOut;


          // a) first,  approve tokenIn for spending on swap router
          TransferHelper.safeApprove(tokens[Idx], address(uniswapRouter), amtIn);

          // b) swap to get amtOut
          ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokens[Idx],
            tokenOut: oToken,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + delay,
            amountIn: amtIn,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
          });
          uint amtOut = uniswapRouter.exactInputSingle(params);  

          require ((amtOut >= expectedAmtOut + estGas), "Insufficient OAmt");

          // c) send expected amount to order owner (maker)
          address payable maker = orders[index].sender;

          TransferHelper.safeApprove(oToken, maker, expectedAmtOut);
          TransferHelper.safeTransferFrom(oToken, address(this), maker, expectedAmtOut);

          // d) remaining amount to caller (contract owner) to compensate for gas costs, etc.
          address payable coll = payable(owner);
          if (amtOut > expectedAmtOut){

             TransferHelper.safeApprove(oToken, coll, (amtOut - expectedAmtOut));
             TransferHelper.safeTransferFrom(oToken, address(this), coll, (amtOut - expectedAmtOut));
          }

          // e) remove order from list
          return removeFromList(index);
     }


     // taker of Ether-to-Token order
     function etherOrderTaker(uint orderID, uint estGas, uint delay)  external payable returns (bool) {

          (uint index, bool found) = findOrder(orderID);

          require ((found), "Order not found");

          uint8 Idx = orders[index].tokenIn;
          require(Idx == 0, "Not ETH Order");

          uint8 Odx = orders[index].tokenOut;
          address oToken = tokens[Odx];

          uint amtIn = orders[index].amountIn; // amount of ETH to swap
          uint expectedAmtOut = orders[index].amountOut;

          require(amtIn > estGas, "Gas exceeds AIn");

          address sender = orders[index].sender; // address(0);

          ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: tokens[Idx],
            tokenOut: oToken,
            fee:  poolFee,
            recipient: sender,
            deadline: block.timestamp + delay,
            amountOut: expectedAmtOut,
            amountInMaximum: amtIn,
            sqrtPriceLimitX96: 0
          });

          uint amtInRet =  uniswapRouter.exactOutputSingle{value: amtIn - estGas}(params); 

          require(amtInRet < amtIn - estGas, "Not enough SOR");

          uniswapRouter.refundETH();

          // refund leftover ETH to caller
          address payable coll = payable(owner);
          (bool success,) = coll.call{value: (amtIn - amtInRet)}("");
           require(success, "refund failed");

          //-- remove order from list
          return removeFromList(index);
     }

     function findOrder(uint orderID) internal view returns (uint, bool){
         uint index = 0;
	     bool found = false;

	     for (uint i=0; i<numOrders; i++){
	       if  (orders[i].ID == orderID) {
	           index = i;
	           found = true;
	           break;
	       }
	     }

	     return (index, found);
     }


	 function cancelOrder(uint orderID) public returns (bool){

	    (uint index, bool found) = findOrder(orderID);

        require ((found), "Order not found");

        address addr = orders[index].sender;
        require (addr == msg.sender, "Order not owned by caller");

        uint8 Idx = orders[index].tokenIn;
        if (Idx == 0) {
            return canceEtherOrder(orderID);
        }else{
            ERC20 token = ERC20(tokens[Idx]);

            uint amt = orders[index].amountIn;

            bool success = token.transfer(msg.sender, amt);
            if (success){
                return removeFromList(index);
            }else{
                return false;
            }
        }
    }

 	function canceEtherOrder(uint orderID) internal returns (bool){

	    (uint index, bool found) = findOrder(orderID);

        require ((found), "Order not found");

        address addr = orders[index].sender;
        require (addr == msg.sender, "Order not owned by caller");

        uint amt = orders[index].amountIn;

        bool success = payable(msg.sender).send(amt);
        if (success){
             return removeFromList(index);
        }else{
            return false;
        }
    }

    function removeFromList(uint index) internal returns (bool){
        for (uint i = index; i<numOrders-1; i++){
             orders[i] = orders[i+1];
        }
        numOrders--;
        return true;
    }

    function findOrderByOrderID(uint orderID) public view returns (address sender, uint8 inIdx, uint8 outIdx, uint amtIn, uint amtOut) {
         (uint index, bool found) = findOrder(orderID);
          require ((found), "Order not found");

          sender = orders[index].sender;
          outIdx = orders[index].tokenOut;
          inIdx = orders[index].tokenIn;
          amtIn = orders[index].amountIn;
          amtOut = orders[index].amountOut;
    }



    // find the swap order with the lowest swap-out amount of tokenOut per unit of swap-in token
    function findLowestOrder(uint8 tokenIn, uint8 tokenOut) public view returns (uint amountIn, uint amountOut, uint orderID) {

        uint rateMin = 0;
        uint amt = 0;
        uint out = 0;
        uint id = 0;
        uint found = 0;
        for (uint i = 0; i<numOrders; i++){
            if (orders[i].tokenIn == tokenIn && orders[i].tokenOut == tokenOut){
                found++;
                uint rate = orders[i].amountOut * (10**10)/orders[i].amountIn;
                 if (found == 1 || rate < rateMin) {
                    rateMin =  rate;
                    amt  =  orders[i].amountIn;
                    out = orders[i].amountOut;
                    id = orders[i].ID;
                 }
            }
        }

      amountIn = amt;
      amountOut = out;
      orderID = id;
    }

    // list all orders by sender address
    function listOpenOrders(address sender) public view returns (uint[5][] memory) {
        uint num = getNumberOfOrders(sender);
        uint[5][] memory ords = new uint[5][](num);
        uint count = 0;
        if (num > 0){
          for (uint i=0; i<numOrders; i++){
            if (orders[i].sender == sender){
                ords[count][0] = orders[i].tokenIn;
                ords[count][1] = orders[i].tokenOut;
                ords[count][2] = orders[i].ID;
                ords[count][3] = orders[i].amountIn;
                ords[count][4] = orders[i].amountOut;
                count++;
            }
          }
        }
        return ords;
    }


    /* list all orders by swap pair */
    function listOpenOrdersByPair(address tokenIn, address tokenOut) public view returns (uint[3][] memory, address[] memory){
        uint8 tokIdex = findTokenIndex(tokenIn);
        uint8 tokOdex  = findTokenIndex(tokenOut);
        uint counter = 0;
        for (uint i=0; i<numOrders; i++){
            if (orders[i].tokenIn == tokIdex && orders[i].tokenOut == tokOdex){
                counter++;
            }
        }
        uint[3][] memory ords = new uint[3][](counter);
        address[] memory addrs = new address[](counter);
        uint count = 0;
        if (counter > 0){
          for (uint i=0; i<numOrders; i++){
            if (orders[i].tokenIn == tokIdex && orders[i].tokenOut == tokOdex){
                addrs[count] = orders[i].sender;
                ords[count][0] = orders[i].ID;
                ords[count][1] = orders[i].amountIn;
                ords[count][2] = orders[i].amountOut;
                count++;
            }
          }
        }
        return (ords, addrs);
    }

    /* find number of orders by sender address */
    function getNumberOfOrders(address sender) internal view returns (uint){
        uint count = 0;
        for (uint i=0; i<numOrders; i++){
            if (orders[i].sender == sender){
                count++;
            }
        }
        return count;
    }


    receive() payable external {}
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

// SPDX-License-Identifier: MIT

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