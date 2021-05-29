/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity =0.7.6;


// 
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        z = x / y;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// 
interface ILimitswapFactory {
    function getPair(address, address) external view returns (address);
    function createPair(address, address) external returns(address);
    function allPairs(uint) external view returns(address);
    function allPairsLength() external view returns (uint);
}

// 
interface ILimitswapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function liquidity() external view returns (uint256);
    function lastBalance0() external view returns (uint256);
    function lastBalance1() external view returns (uint256);
    function currentSqrtPriceX96() external view returns (uint160);
    function amount0ToAmount1(uint256 amount0, uint160 sqrtPriceX96) external pure returns (uint256 amount1);
    function amount1ToAmount0(uint256 amount1, uint160 sqrtPriceX96) external pure returns (uint256 amount0);
    function mint(address to) external returns (uint256 share);
    function burn(address to) external returns (uint amount0, uint amount1);
    function putLimitOrder(int24 tick, uint256 amount, bool zeroForToken1) external returns (uint256 share);
    function cancelLimitOrder(int24 tick, uint256 share, bool isSellShare) external returns (uint256 token0Out, uint256 token1Out);
    function swap(uint256 amountIn, bool zeroForToken0, address to) external returns (uint256 amountOut, uint160 toSqrtPriceX96);
    function initTokenAddress(address, address) external;
    function sellShare(address, int24) external view returns (uint256);
    function buyShare(address, int24) external view returns (uint256);
    function getLimitTokens (int24 tick, address user, uint256 share, bool isSellShare) external view returns(uint256 token0Out, uint256 token1Out);
    function getDeep (int24 tick) external view returns(uint256 token0Deep, uint256 token1Deep);
    function estOutput(uint256 amountIn, bool zeroForToken0) external view returns (uint256, uint256, uint160);
    function currentTick() external view returns(int24 tick);
    function reserve0() external view returns (uint256);
    function reserve1() external view returns (uint256);
    function getTotalLimit () external view returns(uint256 totalLimit0, uint256 totalLimit1);
    function flashLoan(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// 
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

// 
/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }

    
    
}

// 
/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// 
interface IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {

    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}

// 
//import './libraries/TickFinder.sol';
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint) external;
}

//Router is only for add/remove liquidity and swap
//put/cancel limit order should direct interplay with the pair contract
contract LimitswapRouter {
    using SafeMath for uint256;
    using StructuredLinkedList for StructuredLinkedList.List;

    address public immutable factory;
    address public immutable WETH;

    constructor (address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'LimitswapRouter: EXPIRED');
        _;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal returns (uint256 remainedA, uint256 remainedB, address pair) {
        // create the pair if it doesn't exist yet
        require(amountA == uint128(amountA) && amountB == uint128(amountB), 'LimitswapRouter: TOO_MUCH_INPUT');
        pair = ILimitswapFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = ILimitswapFactory(factory).createPair(tokenA, tokenB);
        }
        if (ILimitswapPair(pair).liquidity() > 0) {
            uint160 currentSqrtPriceX96 = ILimitswapPair(pair).currentSqrtPriceX96();
            uint256 amountBDesired = ILimitswapPair(pair).amount0ToAmount1(amountA, currentSqrtPriceX96);
            if (amountB < amountBDesired){
                uint256 amountADesired = ILimitswapPair(pair).amount1ToAmount0(amountB, currentSqrtPriceX96);
                remainedA = amountA.sub(amountADesired);
                amountA = amountADesired;
            } else {
                remainedB = amountB.sub(amountBDesired);
                amountB = amountBDesired;
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountAIn,
        uint256 amountBIn,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (uint256 remainedA, uint256 remainedB, address pair) = _addLiquidity(tokenA, tokenB, amountAIn, amountBIn);
        amountA = amountAIn.sub(remainedA);
        amountB = amountBIn.sub(remainedB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ILimitswapPair(pair).mint(msg.sender);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenIn,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (uint256 remainedToken, uint256 remainedETH, address pair) = _addLiquidity(token, WETH, amountTokenIn, msg.value);
        amountToken = amountTokenIn.sub(remainedToken);
        amountETH = msg.value.sub(remainedETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken.sub(remainedToken));
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = ILimitswapPair(pair).mint(msg.sender);
        // refund dust eth, if any
        if (remainedETH > 0) TransferHelper.safeTransferETH(msg.sender, remainedETH);
    }
//update 2021.5.14:  line 113 tokenA -> tokenB
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 share,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        address pair = ILimitswapFactory(factory).getPair(tokenA, tokenB);
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, share);
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        ILimitswapPair(pair).burn(address(this));
        amountA = IERC20(tokenA).balanceOf(address(this)).sub(balanceA);
        amountB = IERC20(tokenB).balanceOf(address(this)).sub(balanceB);
        transferExtraTokens(tokenA, tokenB, balanceA, balanceB);
    }

    function transferExtraTokens(address tokenA, address tokenB, uint256 balanceA, uint256 balanceB) private {
        //without checking token order
        //must make sure tokenA < tokenB before calling
        uint256 amountA = IERC20(tokenA).balanceOf(address(this)).sub(balanceA);
        uint256 amountB = IERC20(tokenB).balanceOf(address(this)).sub(balanceB);
        if (tokenA == WETH) {
            IWETH(WETH).withdraw(amountA);
            TransferHelper.safeTransferETH(msg.sender, amountA);
        } else {
            TransferHelper.safeTransfer(tokenA, msg.sender, amountA);
        }
        if (tokenB == WETH) {
            IWETH(WETH).withdraw(amountB);
            TransferHelper.safeTransferETH(msg.sender, amountB);
        } else {
            TransferHelper.safeTransfer(tokenB, msg.sender, amountB);
        }
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256 amountIn, address[] memory path, address _to) internal returns(uint256) {
        address to;
        bool zeroForToken0;
        for (uint i; i < path.length - 1; i++) {
            zeroForToken0 = path[i] < path[i + 1] ? false : true;
            to = i < path.length - 2 ? ILimitswapFactory(factory).getPair(path[i + 1], path[i + 2]) : _to;
            (amountIn,) = ILimitswapPair(ILimitswapFactory(factory).getPair(path[i], path[i + 1])).swap(amountIn, zeroForToken0, to);
        }
        return amountIn;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ILimitswapFactory(factory).getPair(path[0], path[1]), amountIn
        );
        amountOut = _swap(amountIn, path, to);
        require(amountOut >= amountOutMin, 'LimitswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    }
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        ensure(deadline)
        returns (uint256 amountOut)
    {
        require(path[0] == WETH, 'LimitswapRouter: INVALID_PATH');
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(ILimitswapFactory(factory).getPair(path[0], path[1]), msg.value));
        amountOut = _swap(msg.value, path, to);
        require(amountOut >= amountOutMin, 'LimitswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    }

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        ensure(deadline)
        returns (uint256 amountOut)
    {
        require(path[path.length - 1] == WETH, 'LimitswapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ILimitswapFactory(factory).getPair(path[0], path[1]), amountIn
        );
        amountOut = _swap(amountIn, path, address(this));
        require(amountOut >= amountOutMin, 'LimitswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function getAmountsOut(uint amountIn, address[] calldata path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'LimitswapRouter: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            address pair = ILimitswapFactory(factory).getPair(path[i], path[i+1]);
            (amountIn,,) = ILimitswapPair(pair).estOutput(amountIn, path[i] < path[i+1] ? false : true);
            amounts[i + 1] = amountIn;
        }
    }

    function getAmountOut(uint amountIn, address[] calldata path) public view returns (uint amountOut, uint amountOutNoPriceImpact) {
        require(path.length >= 2, 'LimitswapRouter: INVALID_PATH');
        amountOut = amountIn;
        amountOutNoPriceImpact = amountIn;
        for (uint i; i < path.length - 1; i++) {
            address pair = ILimitswapFactory(factory).getPair(path[i], path[i+1]);
            (amountOut,,) = ILimitswapPair(pair).estOutput(amountOut, path[i] < path[i+1] ? false : true);
            if (path[i] < path[i+1]){//input is token0
                amountOutNoPriceImpact = ILimitswapPair(pair).amount0ToAmount1(amountOutNoPriceImpact, ILimitswapPair(pair).currentSqrtPriceX96());
            } else {//input is token1
                amountOutNoPriceImpact = ILimitswapPair(pair).amount1ToAmount0(amountOutNoPriceImpact, ILimitswapPair(pair).currentSqrtPriceX96());
            }
        }
    }

    address public sender;
    mapping (address => StructuredLinkedList.List) limitOrders;

    //record of limit order
    //uint256 = padding X64 + address(uint160) pair + padding X7 + bool isSellShare + int24 tick
    //256 = 64 + 160 + 7 + 1 + 24
    function packRecord (address pair, int24 tick, bool isSellShare) internal pure returns(uint256 record) {
        record += uint256(uint24(tick));
        if (isSellShare) record += (1 << 24);
        record += (uint256(pair) << 32);
    }

    function resovleRecord (uint256 record) internal pure returns(address pair, int24 tick, bool isSellShare) {
        pair = address(record >> 32);
        tick = int24(record);
        isSellShare = (record & (1 << 24)) > 0 ? true : false;
    }


    function putLimitOrder (address pair, address tokenIn, uint256 amountIn, int24 tick) external returns(uint256 share) {
        address tokenA = ILimitswapPair(pair).token0();
        address tokenB = ILimitswapPair(pair).token1();
        require(tokenA == tokenIn || tokenB == tokenIn, 'TOKENERROR');
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, pair, amountIn
        );
        bool isSellShare = tokenIn == ILimitswapPair(pair).token0()? true : false;
        sender = msg.sender;
        share = ILimitswapPair(pair).putLimitOrder(tick, amountIn, isSellShare);
        delete sender;
        limitOrders[msg.sender].pushFront(packRecord(pair, tick, isSellShare));
        transferExtraTokens(tokenA, tokenB, balanceA, balanceB);
    }

    function cancelLimitOrder (address pair, int24 tick, uint256 share, bool isSellShare) external returns(uint256 token0Out, uint256 token1Out) {
        address tokenA = ILimitswapPair(pair).token0();
        address tokenB = ILimitswapPair(pair).token1();
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        uint256 totalUserShare;
        if (isSellShare) {
            totalUserShare = ILimitswapPair(pair).sellShare(msg.sender, tick);
        } else {
            totalUserShare = ILimitswapPair(pair).buyShare(msg.sender, tick);
        }
        if (share > totalUserShare) share = totalUserShare;
        sender = msg.sender;
        (token0Out, token1Out) = ILimitswapPair(pair).cancelLimitOrder(tick, share, isSellShare);
        delete sender;
        if(share == totalUserShare){
            limitOrders[msg.sender].remove(packRecord(pair, tick, isSellShare));
        }
        transferExtraTokens(tokenA, tokenB, balanceA, balanceB);
    }
//add: 2021.5.13
    function putLimitOrderETH (address pair, int24 tick) external payable returns (uint256 share) {
        address tokenA = ILimitswapPair(pair).token0();
        address tokenB = ILimitswapPair(pair).token1();
        require(tokenA == WETH || tokenB == WETH, 'TOKENERROR');
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pair, msg.value));
        bool isSellShare = WETH == ILimitswapPair(pair).token0()? true : false;
        sender = msg.sender;
        share = ILimitswapPair(pair).putLimitOrder(tick, msg.value, isSellShare);
        delete sender;
        limitOrders[msg.sender].pushFront(packRecord(pair, tick, isSellShare));
        transferExtraTokens(tokenA, tokenB, balanceA, balanceB);
    }

    function getLimitOrdersRaw(address user, uint256 limit, uint256 offset) public view returns(uint256[] memory records){
        records = new uint[](limit);
        uint256 cursor;
        bool toContinue = true;
        for(uint i; (i < offset) && toContinue && (cursor > 0 || i == 0); i++){
            (toContinue, cursor) = limitOrders[user].getNextNode(cursor);
        }
        for(uint i; (i < limit) && toContinue && (cursor > 0 || i == 0); i++){
            (toContinue, cursor) = limitOrders[user].getNextNode(cursor);
            if(toContinue) records[i] = cursor;
        }
    }
//update 2021.5.14: positions(token0Out+token1Out) -> token0Out, token1Out
    function getLimitOrders(address user, uint256 limit, uint256 offset) public view
        returns(uint256[] memory records, uint256[] memory token0Out, uint256[] memory token1Out){
        records = getLimitOrdersRaw(user, limit, offset);
        token0Out = new uint256[](limit);
        token1Out = new uint256[](limit);
        uint256 position;
        for (uint i; i < limit; i++){
            if (records[i] > 0) {
                (address pair, int24 tick, bool isSellShare) = resovleRecord(records[i]);
                if (isSellShare){
                    position = ILimitswapPair(pair).sellShare(user, tick);
                } else {
                    position = ILimitswapPair(pair).buyShare(user, tick);
                }
                (token0Out[i], token1Out[i]) = ILimitswapPair(pair).getLimitTokens(tick, user, position, isSellShare);
                //positions[i] = (token0Out<<128) + (token1Out&uint128(-1));
            }
        }
    }

    //return value: uint256 = uint64 pairId + uint192 balance
    function getLPBalance (address user, uint256 scanLimit, uint256 scanOffset, uint256 resLimit) public view returns(uint256[] memory balances) {
        balances = new uint256[](resLimit);
        uint256 length = ILimitswapFactory(factory).allPairsLength();
        scanLimit = scanLimit + scanOffset > length ? length : scanLimit + scanOffset;
        length = 0;//reuse length as the length of balances
        for (uint i=scanOffset; i<scanLimit && length<resLimit; i++){
            uint256 balance = IERC20(ILimitswapFactory(factory).allPairs(i)).balanceOf(user);
            if (balance > 0){
                balances[length] = (i << 192) + balance;
                length ++;
            }
        }
    }

    function getPairInfo (address tokenA, address tokenB) public view
        returns(int24 currentTick, uint160 currentSqrtPriceX96, address pair, uint256 reserve0,
        uint256 reserve1, uint256 totalLimit0, uint256 totalLimit1) {
        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = ILimitswapFactory(factory).getPair(tokenA, tokenB);
        if (pair != address(0)){
            currentTick = ILimitswapPair(pair).currentTick();
            currentSqrtPriceX96 = ILimitswapPair(pair).currentSqrtPriceX96();
            reserve0 = ILimitswapPair(pair).reserve0();
            reserve1 = ILimitswapPair(pair).reserve1();
            (totalLimit0, totalLimit1) = ILimitswapPair(pair).getTotalLimit();
        }
    }




}