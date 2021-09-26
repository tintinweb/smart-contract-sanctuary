/**
 *Submitted for verification at polygonscan.com on 2021-09-26
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router02 {
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline) external payable returns (uint[] memory amounts);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

interface IERC3156FlashBorrower {

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLender {

    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface ISwap {
    function swapExtractOut(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (uint256 swapExtractOut);

    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);

    function swapEstimateIn(address tokenIn, address tokenOut, uint256 amountOut) external view returns (uint256);
}

contract FlashloanArbitrage is IERC3156FlashBorrower, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IWETH public weth;
    IERC3156FlashLender[] public lenders;
    mapping(string => IERC3156FlashLender) public flashloanLenders;


    struct Dex {
        string name;
        ISwap handler;
        bool status;
    }

    struct DexOutRes {
        uint256 resultAmount;
        Dex resultDex;
    }

    Dex[] public dexs;
    mapping(string => ISwap) public dexHandlers;


    event TokenAdded(address token);
    event NewDexAdded(string name, address indexed handler);
    event DexHandlerChanged(string name, address indexed oldHandler, address indexed newHandler, bool status);
    event Swap(
        string dexName,
        address indexed dexHandler,
        address sender,
        address recipient,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _weth,string[] memory handlerNames, ISwap[] memory handlers,string[] memory lenderNames, IERC3156FlashLender[] memory lenders) public {
        weth = IWETH(_weth);
        supportDexs(handlerNames,handlers);
        setLenders(lenderNames,lenders);
    }

    // 聚合交易开始..........

    function getOutWithDex(address tokenIn, address tokenOut, uint256 amountIn) public view returns (DexOutRes[] memory) {
        require(tokenIn != address(0), "AggregateSwap: tokenIn is the zero address");
        require(tokenOut != address(0), "AggregateSwap: tokenOut is the zero address");
        require(tokenIn != tokenOut, "AggregateSwap: tokenIn and tokenOut is the same");
        require(amountIn > 0, "AggregateSwap: amountIn must be greater than zero");

        DexOutRes[] memory res = new DexOutRes[](dexs.length);
        for (uint256 i = 0; i < dexs.length; i++) {
            if (dexs[i].status == false) {
                continue;
            }
            uint256 resultAmount = dexs[i].handler.swapEstimateOut(tokenIn, tokenOut, amountIn);
            Dex memory resultDex = dexs[i];
            res[i] = DexOutRes({
            resultAmount : resultAmount,
            resultDex : resultDex
            });
        }

        return res;
    }

    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) {
        (uint256 resultAmount,) = _getBestOut(tokenIn, tokenOut, amountIn);
        return resultAmount;
    }

    function swapEstimateIn(address tokenIn, address tokenOut, uint256 amountOut) public view returns (uint256) {
        (uint256 resultAmount,) = _getBestIn(tokenIn, tokenOut, amountOut);
        return resultAmount;
    }

    function swapEstimateOutWithDEX(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256 amountOut, string memory dexName) {
        Dex memory dex;
        (amountOut, dex) = _getBestOut(tokenIn, tokenOut, amountIn);
        dexName = dex.name;
    }

    function swapEstimateInWithDEX(address tokenIn, address tokenOut, uint256 amountOut) public view returns (uint256 amountIn, string memory dexName) {
        Dex memory dex;
        (amountIn, dex) = _getBestIn(tokenIn, tokenOut, amountOut);
        dexName = dex.name;
    }

    function _getBestOut(address tokenIn, address tokenOut, uint256 amountIn) internal view returns (uint256, Dex memory) {
        require(tokenIn != address(0), "AggregateSwap: tokenIn is the zero address");
        require(tokenOut != address(0), "AggregateSwap: tokenOut is the zero address");
        require(tokenIn != tokenOut, "AggregateSwap: tokenIn and tokenOut is the same");
        require(amountIn > 0, "AggregateSwap: amountIn must be greater than zero");

        uint256 resultAmount = 0;
        Dex memory resultDex;

        for (uint256 i = 0; i < dexs.length; i++) {
            if (dexs[i].status == false) {
                continue;
            }
            uint256 amount = dexs[i].handler.swapEstimateOut(tokenIn, tokenOut, amountIn);
            if (amount > resultAmount) {
                resultAmount = amount;
                resultDex = dexs[i];
            }
        }

        return (resultAmount, resultDex);
    }

    function _getBestIn(address tokenIn, address tokenOut, uint256 amountOut) internal view returns (uint256, Dex memory) {
        require(tokenIn != address(0), "AggregateSwap: tokenIn is the zero address");
        require(tokenOut != address(0), "AggregateSwap: tokenOut is the zero address");
        require(tokenIn != tokenOut, "AggregateSwap: tokenIn and tokenOut is the same");
        require(amountOut > 0, "AggregateSwap: amountOut must be greater than zero");

        uint256 resultAmount = 0;
        Dex memory resultDex;

        for (uint256 i = 0; i < dexs.length; i++) {
            if (dexs[i].status == false) {
                continue;
            }
            uint256 amount = dexs[i].handler.swapEstimateIn(tokenIn, tokenOut, amountOut);
            if (amount > 0) {
                if (amount < resultAmount || resultAmount == 0) {
                    resultAmount = amount;
                    resultDex = dexs[i];
                }
            }
        }

        return (resultAmount, resultDex);
    }

    

    function supportDexs(string[] memory names, ISwap[] memory handlers) public onlyOwner {
        require(names.length == handlers.length, "AggregateSwap: names's length must equals with handlers's length");
        for (uint i = 0; i < names.length; i++) {
            supportDex(names[i], handlers[i]);
        }
    }

    function supportDex(string memory name, ISwap handler) public onlyOwner {
        require(address(handler) != address(0), "AggregateSwap: handler is the zero address");
        require(address(dexHandlers[name]) == address(0), "AggregateSwap: the dex is already added");
        dexHandlers[name] = handler;
        Dex memory dex = Dex(name, handler, true);
        dexs.push(dex);
    }

    function updateDexHandler(string memory name, ISwap handler, bool status) public onlyOwner {
        require(address(handler) != address(0), "AggregateSwap: handler is the zero address");
        require(address(dexHandlers[name]) != address(0), "AggregateSwap: the dex is not exist");
        for (uint256 i = 0; i < dexs.length; i++) {
            if (keccak256(abi.encodePacked(dexs[i].name)) == keccak256(abi.encodePacked(name))) {
                dexs[i].handler = handler;
                dexs[i].status = status;
            }
        }
        emit DexHandlerChanged(name, address(dexHandlers[name]), address(handler), status);
        dexHandlers[name] = handler;
    }

   function swapExtractOut(string memory handlerName, address tokenIn, address tokenOut, address recipient, uint256 amountIn, uint256 amountOutMin, uint256 deadline) public returns (uint256){

        ISwap handler = dexHandlers[handlerName];
        
        uint balance1 = _getBalanceInternal(address(this),tokenIn);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(handler), amountIn);

        uint amountOut = ISwap(handler).swapExtractOut(tokenIn, tokenOut, recipient, amountIn, amountOutMin, deadline);
        emit Swap(handlerName, address(handler), msg.sender, recipient, tokenIn, tokenOut, amountIn, amountOut);

        return amountOut;
    }


    function start(string calldata lenderName, address tokenBorrow, uint borrowAmount, address tokenSwapTo, uint swapMinAmount,
        string calldata smallHandlerName, string calldata biggerHanderName) public {

        bytes memory data = abi.encode(tokenBorrow, borrowAmount, tokenSwapTo, swapMinAmount, smallHandlerName, biggerHanderName);

        // STEP1: 进行闪电贷，借出borrowAmount的tokenBorrow
        IERC3156FlashLender lender = flashloanLenders[lenderName];
        lender.flashLoan(this, tokenBorrow, borrowAmount, data);


        _transferInternal(tokenBorrow, payable(owner()), _getBalanceInternal(address(this), tokenBorrow));

    }


    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external override returns (bytes32) {

        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");
        uint256 repayment = amount + fee;

        //授权给贷款方合约
        _approveMaxInternal(token, msg.sender, repayment);

        //解构数据
        (,,address tokenSwapTo,uint256 swapMinAmount,string memory smallHandlerName,string memory biggerHandlerName) = abi.decode(data, (address, uint256, address, uint256, string, string));

        // STEP2:  从最小的交易中获得相关的交易代币
        uint amountOut = swapExtractOut(smallHandlerName, token, tokenSwapTo, address(this), amount, swapMinAmount, block.number);

        //STEP3:  交易回原来借的币
        swapExtractOut(biggerHandlerName, tokenSwapTo, token, address(this), amountOut, repayment, block.number);


        return keccak256("ERC3156FlashBorrower.onFlashLoan");

    }


    // 设置lender
    function setLender(string memory name, IERC3156FlashLender lender) public onlyOwner {
        require(address(lender) != address(0), " lender is the zero address");
        flashloanLenders[name] = lender;
        lenders.push(lender);
    }

    function setLenders(string[] memory names, IERC3156FlashLender[] memory lenders) public onlyOwner {
        require(names.length == lenders.length, "names's length must equals with lenders's length");
        for (uint i = 0; i < lenders.length; i++) {
            setLender(names[i], lenders[i]);
        }
    }

    // 设置weth地址
    function setWETH(address _weth) public onlyOwner {
        weth = IWETH(_weth);
    }

    function transfer(address _asset, address payable _to, uint amount) public onlyOwner {
        _transferInternal(_asset, _to, amount);
    }


    function _transferInternal(address _asset, address payable _to, uint _amount) internal {
        uint balance = _getBalanceInternal(address(this), _asset);
        if (balance < _amount) {
            _amount = balance;
        }

        if (_asset == ethAddress) {
            (bool success,) = _to.call{value : _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_asset).safeTransfer(_to, _amount);
    }

    function _getBalanceInternal(address _target, address _reserve) internal view returns (uint256) {
        if (_reserve == ethAddress) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }

    function _approveMaxInternal(address _asset, address _spender, uint amount) internal {
        IERC20 erc20 = IERC20(_asset);
        uint allowance = erc20.allowance(address(this), _spender);
        if (allowance < amount) {
            uint MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            erc20.safeApprove(_spender, MAX_INT);
        }
    }

    receive() payable external {}


}