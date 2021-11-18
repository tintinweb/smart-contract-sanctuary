// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "./libraries/TransferHelper.sol";

import "./interfaces/IFlypeRouter02.sol";
import "./libraries/FlypeLibrary.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFlypeDiscounter.sol";

contract FlypeRouter02 is FlypeLibrary {

    
    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "FlypeRouter: EXPIRED");
        _;
    }

    constructor(address factory_, address _WETH) {
        factory = factory_;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn"t exist yet
        if (IFlypeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IFlypeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 priceA, uint256 priceB) = getPrices(factory, tokenA, tokenB);
        uint256 amountBOptimal = quote(amountADesired, priceA, priceB);
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "FlypeRouter: INSUFFICIENT_B_AMOUNT");
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint256 amountAOptimal = quote(amountBDesired, priceB, priceA);
            assert(amountAOptimal <= amountADesired);
            require(amountAOptimal >= amountAMin, "FlypeRouter: INSUFFICIENT_A_AMOUNT");
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    /// @notice Adds liquidity to Flype pair
    /// @param token LpToken address
    /// @param amountTokenDesired Desired amount amount of spending lpTokens
    /// @param amountTokenMin Minimum amount of spending lpToken
    /// @param amountETHMin Minimum amount of spending ETH
    /// @param to Address of person who recieved Flype lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amountToken Amount of spended lpTokens
    /// @return amountETH Amount of spended WETH
    /// @return liquidity Amount of recieved Flype lpTokens
    function addLiquidity(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IFlypePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) internal virtual ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(factory, tokenA, tokenB);
        IFlypePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IFlypePair(pair).burn(to);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "FlypeRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "FlypeRouter: INSUFFICIENT_B_AMOUNT");
    }

    /// @notice Exchange Flype lpToken for lpToken and WETH
    /// @param token Address of desired lpToken, it must be in the Flype lpToken that is being exchanged
    /// @param liquidity Amount of Flype lpToken, that is being exchanged
    /// @param amountTokenMin Minimum amount of recieved lpToken
    /// @param amountETHMin Minimum amount of recieved WETH
    /// @param to Address of person who recieved lpTokens and ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amountToken Amount of recieved lpToken
    /// @return amountETH Amount of recieved ETH
    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = _removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /// @notice Exchange Flype lpToken for lpToken and WETH by signature
    /// @param token Address of desired lpToken, it must be in the Flype lpToken that is being exchanged
    /// @param liquidity Amount of Flype lpToken, that is being exchanged
    /// @param amountTokenMin Minimum amount of recieved lpToken
    /// @param amountETHMin Minimum amount of recieved WETH
    /// @param to Address of person who recieved lpTokens and ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @param approveMax If true => approve max uint from user to this contract
    /// @param v Part of the splited signature
    /// @param r Part of the splited signature
    /// @param s Part of the splited signature
    /// @return amountToken Amount of recieved lpToken
    /// @return amountETH Amount of recieved ETH
    function removeLiquidityWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountToken, uint256 amountETH) {
        address pair = pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IFlypePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidity(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    /// @notice Exchange Flype lpToken for lpToken and WETH
    /// @param token Address of desired lpToken, it must be in the Flype lpToken that is being exchanged
    /// @param liquidity Amount of Flype lpToken, that is being exchanged
    /// @param amountTokenMin Minimum amount of recieved lpToken
    /// @param amountETHMin Minimum amount of recieved WETH
    /// @param to Address of person who recieved lpTokens and ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amountETH Amount of recieved ETH
    function removeLiquiditySupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = _removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /// @notice Exchange Flype lpToken for lpToken and WETH by signature
    /// @param token Address of desired lpToken, it must be in the Flype lpToken that is being exchanged
    /// @param liquidity Amount of Flype lpToken, that is being exchanged
    /// @param amountTokenMin Minimum amount of recieved lpToken
    /// @param amountETHMin Minimum amount of recieved WETH
    /// @param to Address of person who recieved lpTokens and ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @param approveMax If true => approve max uint from user to this contract
    /// @param v Part of the splited signature
    /// @param r Part of the splited signature
    /// @param s Part of the splited signature
    /// @return amountETH Amount of recieved ETH
    function removeLiquidityWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountETH) {
        address pair = pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IFlypePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquiditySupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    /// @notice swap lpTokens or WETH in path 
    /// @dev requires the initial amount to have already been sent to the first pair
    /// @param amounts Calculated by FlypeLibrary amount of lpTokens to swap 
    /// @param path Array of lpToken and WETH address, see details below
    /// @param _to Address of person who recieved lpTokens and ETH
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2]) : _to;
            IFlypePair(FlypeLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /// @notice Swap exact amount of lpToken for equivalent amount of desired lpToken
    /// @param amountIn Exact amount of swapped lpToken 
    /// @param amountOutMin Minimum amount of desired lpToken
    /// @param path Array of addresses from  swapped lpToken to desired, it must be always in form [lpToken, WETH, lpToken]
    /// @param to Address of person who recieved desired lpToken
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain swaps path 
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path.length == 3 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        amounts =  getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    /// @notice Swap some amount of lpToken for equivalent amount of desired lpToken
    /// @param amountOut Exact amount of desired lpToken 
    /// @param amountInMax Maximum amount of swapped lpToken
    /// @param path Array of addresses from  swapped lpToken to desired, it must be always in form [lpToken, WETH, lpToken]
    /// @param to Address of person who recieved desired lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain swaps path
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path.length == 3 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        amounts =  getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "FlypeRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    /// @notice Swap exact amount of ETH for equivalent amount of desired lpToken
    /// @param amountOutMin Minimum amount of desired lpToken
    /// @param path Array of addresses from ETH to desired lpToken, it must always be in form [WETH, lpToken]
    /// @param to Address of person who recieved desired lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain swaps path 
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path.length == 2 && path[0] == WETH, "FlypeRouter: INVALID_PATH");
        amounts =  getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    /// @notice Swap some amount of lpToken for exact amount of ETH
    /// @param amountOut Exact amount of ETH 
    /// @param amountInMax Maximum amount of swapped lpToken
    /// @param path Array of addresses from lpToken to ETH, it must always be in form [lpToken, WETH]
    /// @param to Address of person who recieved ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain swaps path
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path.length == 2 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        amounts =  getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "FlypeRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /// @notice Swap exact amount of lpToken for equivalent amount of ETH
    /// @param amountIn Exact amount of swapped lpTokens 
    /// @param amountOutMin Minimum amount of recieved ETH
    /// @param path Array of addresses from lpToken to ETH, it must always be in form [lpToken, WETH]
    /// @param to Address of person who recieved ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain swaps path
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path.length == 2 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        amounts =  getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /// @notice Swap some amount of ETH for exact amount of desired lpToken
    /// @param amountOut Exact amount of desired lpToken
    /// @param path Array of addresses from ETH to desired lpToken, it must always be in form [WETH, lpToken]
    /// @param to Address of person who recieved desired lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain swaps path 
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual ensure(deadline) returns (uint256[] memory amounts) {
        require(path.length == 2 && path[0] == WETH, "FlypeRouter: INVALID_PATH");
        amounts =  getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "FlypeRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    /// @notice swap lpTokens or WETH in path 
    /// @dev requires the initial amount to have already been sent to the first pair
    /// @param path Array of lpToken and WETH address, see details below
    /// @param _to Address of reciever 
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = sortTokens(input, output);
            IFlypePair pair = IFlypePair(pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, ) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                (uint256 priceInput, uint256 priceOutput) = getPrices(factory, input, output);
            amountOutput = getAmountOut(amountInput, priceInput, priceOutput);            
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @notice Swap exact amount of lpToken for equivalent amount of desired lpToken
    /// @param amountIn Exact amount of swapped lpToken 
    /// @param amountOutMin Minimum amount of desired lpToken
    /// @param path Array of addresses from  swapped lpToken to desired, it must be always in form [lpToken, WETH, lpToken]
    /// @param to Address of person who recieved desired lpToken
    /// @param deadline block.timestamp before which transaction can be confirmed
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) {
        require(path.length == 3 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(factory, path[0], path[1]), amountIn);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    /// @notice Swap exact amount of ETH for equivalent amount of desired lpToken
    /// @param amountOutMin Minimum amount of desired lpToken
    /// @param path Array of addresses from ETH to desired lpToken, it must always be in form [WETH, lpToken]
    /// @param to Address of person who recieved desired lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual ensure(deadline) {
        require(path.length == 2 && path[0] == WETH, "FlypeRouter: INVALID_PATH");
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pairFor(factory, path[0], path[1]), amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    /// @notice Swap exact amount of lpToken for equivalent amount of ETH
    /// @param amountIn Exact amount of swapped lpTokens 
    /// @param amountOutMin Minimum amount of recieved ETH
    /// @param path Array of addresses from lpToken to ETH, it must always be in form [lpToken, WETH]
    /// @param to Address of person who recieved ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) {
        require(path.length == 2 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(factory, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IFlypeUPM {
    function getPrice(address lpPair, uint nominalValue) external view returns (uint price);
    function getPriceETH() external view returns(uint priceETH);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "../../Core/interfaces/IFlypeFactory.sol";
import "../../Core/interfaces/IFlypePair.sol";
import "../upm/interfaces/IFlypeUPM.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlypeLibrary is Ownable {
    address public flypeUPM;
    address public flypeToken;
    uint public sizeS;
    uint public sizeM;
    uint public sizeL;

    /// @notice Set flype token address for discounts
    /// @param _flype Flype token address
    function setflypeToken(address _flype) external onlyOwner{
        flypeToken = _flype;
    }

    /// @notice Set balance level for discount calculation
    /// @param _sizeS Balance limit for minimum discount 
    /// @param _sizeM Balance limit for medium  discount
    /// @param _sizeL Balance limit for maximum discount 
    function discountSetter(uint _sizeS, uint _sizeM, uint _sizeL) external onlyOwner{
        sizeS = _sizeS;
        sizeM = _sizeM;
        sizeL = _sizeL;
    }

    /// @notice Returns discount for specific user based on his flype token balance
    /// @param user User address
    function discountCalculator(address user) public view returns (uint discountSize){
        uint balance = IFlypeERC20(flypeToken).balanceOf(user);
        if(balance >= sizeS){
            if(balance >= sizeL) return discountSize = 30; 
            else if (balance >= sizeM) return discountSize = 25; 
            else return discountSize = 20;
        }
        else return discountSize = 0;
    }
    
    /// @notice Set flypeUPM to receive price and reserves of lpTokens
    /// @param _flypeUPM FlypeUPM address
    function setFlypeUPM(address _flypeUPM) external onlyOwner{
        flypeUPM = _flypeUPM;
    }
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'FlypeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'FlypeLibrary: ZERO_ADDRESS');
    }

    /// @notice Returns pair of lpToken from specific factory
    /// @param factory Factory address
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IFlypeFactory(factory).getPair(token0, token1);
    }

    /// @notice Returns and sorts the reserves for a pair
    /// @param factory Factory address
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IFlypePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    /// @notice Returns prices for pair
    /// @param factory Flype factory address
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function getPrices(address factory, address tokenA, address tokenB) public view returns (uint priceA, uint priceB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        // (uint reserve0, uint reserve1,) = IFlypePair(pairFor(factory, tokenA, tokenB)).getReserves();
        uint nominalValue = 1e18;
        uint price0 = IFlypeUPM(flypeUPM).getPrice(pairFor(factory, tokenA, tokenB), nominalValue);
        uint price1 = IFlypeUPM(flypeUPM).getPriceETH();
        (priceA, priceB) = tokenA == token0 ? (price0, price1) : (price1, price0);
    }

    /// @notice Given some amount of an asset and pair price, returns an equivalent amount of the other asset
    /// @param amountA Amount of swapped token
    /// @param priceA Price of first token in pair
    /// @param priceB Price of second token in pair
    function quote(uint amountA, uint priceA, uint priceB) internal pure returns (uint amountB) {
        require(amountA > 0, 'FlypeLibrary: INSUFFICIENT_AMOUNT');
        // require(reserveA > 0 && reserveB > 0, 'FlypeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * priceA / priceB;
    }

    /// @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    /// @param amountIn Amount of swapped lpToken or WETH
    /// @param priceIn Price of swapped lpToken or WETH
    /// @param priceOut Price of desired lpToken or WETH
    /// @return amountOut Equivalent amount of desired lpToken or WETH  
    function getAmountOut(uint amountIn, uint priceIn, uint priceOut) internal view returns (uint amountOut) {
        require(amountIn > 0, 'FlypeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        uint amountInWithFee = amountIn * (99800 + 2 * discountCalculator(msg.sender));
        uint numerator = amountInWithFee * priceIn;
        uint denominator = priceOut * 100000;
        amountOut = numerator / denominator;
    }
    

    /// @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    /// @param amountOut Amount of desired lpToken or WETH
    /// @param priceIn Price of swapped lpToken or WETH
    /// @param priceOut Price of desired lpToken or WETH
    /// @return amountIn Equivalent amount of swapped lpToke or WETH  
    function getAmountIn(uint amountOut, uint priceIn, uint priceOut) internal view returns (uint amountIn) {
        require(amountOut > 0, 'FlypeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        uint numerator = priceOut * amountOut * (99800 + 2 * discountCalculator(msg.sender));
        uint denominator = priceIn * 100000;
        amountIn = numerator / denominator;
    }

    /// @notice Performs chained getAmountOut calculations on any number of pairs
    /// @param factory Factory address
    /// @param amountIn Amount of swapped lpToken or WETH
    /// @param path Array of addresses from  swapped lpToken to desired, there is 2 type of swap:
    ///     1)   from WETH to lpToken
    ///     2)   from lpToken to another lpToken
    ///     For 1) case path might be: [WETH, lpToken] or vice versa
    ///     For 2) case path always be: [lpToken, WETH, lpToken]
    /// @return amounts Amount of desired lpToken or WETH
    function getAmountsOut(address factory, uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FlypeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            require(reserveIn > 0 && reserveOut > 0, 'FlypeLibrary: INSUFFICIENT_LIQUIDITY');
            (uint priceIn, uint priceOut) = getPrices(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], priceIn, priceOut);
        }
    }

    /// @notice Performs chained getAmountIn calculations on any number of pairs
    /// @param factory Factory address
    /// @param amountOut Amount of desired lpToken or WETH
    /// @param path Array of addresses from  swapped lpToken to desired, there is 2 type of swap:
    ///     1)   from WETH to lpToken
    ///     2)   from lpToken to another lpToken
    ///     For 1) case path might be: [WETH, lpToken] or vice versa
    ///     For 2) case path always be: [lpToken, WETH, lpToken]
    /// @return amounts Amount of swapped lpToken or WETH
    function getAmountsIn(address factory, uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FlypeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            require(reserveIn > 0 && reserveOut > 0, 'FlypeLibrary: INSUFFICIENT_LIQUIDITY');
            (uint priceIn, uint priceOut) = getPrices(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], priceIn, priceOut);
        }
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './IFlypeRouter01.sol';

interface IFlypeRouter02 is IFlypeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IFlypeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external view returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IFlypeDiscounter {
    function discountCalculator(address user) external view returns (uint discountSize);
    function getPrices(address factory, address tokenA, address tokenB) external view returns (uint priceA, uint priceB);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './IFlypeERC20.sol';

interface IFlypePair is IFlypeERC20 {

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IFlypeFactory {

    function feeTo() external view returns (address);
    function feeToAdmin () external view returns (address);    
    
    function feeToSetter() external view returns (address);
    function isRouter(address router) external view returns(bool);


    function getPair(address tokenA, address tokenB) external view returns (address pair);
    
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToAdmin(address _feeTo) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IFlypeERC20 {

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}