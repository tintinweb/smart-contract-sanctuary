/**
 *Submitted for verification at snowtrace.io on 2021-12-14
*/

pragma solidity =0.6.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IEleBank{
    function deposit(uint[] calldata amounts) external;
    function withdraw(uint share, uint8) external;    
    function getPricePerFullShare() view external returns(uint);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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


contract UniswapV2MetaRouter02 is Ownable {
    using SafeMath for uint;

    address public immutable router;

    mapping(address=>address) public bank;

    constructor(address _router) public {
        router = _router;
        setBank(address(0x130966628846BFd36ff31a822705796e8cb8C18D),address(0x724341e1aBbC3cf423C0Cb3E248C87F3fb69b82D));
        setBank(address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7),address(0xe03BCB67C4d0087f95185af107625Dc8a39CB742));
    }


    function setBank(address _token, address _bank) public onlyOwner{
        bank[_token] = _bank;
    }

    function depositToBank(address _token, address _bank) internal returns(uint _shares){
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.approve(_bank,balance);
        uint[] memory amounts = new uint[](1);
        amounts[0] = balance;
        IEleBank(_bank).deposit(amounts);
        _shares = IERC20(_bank).balanceOf(address(this));
    }

    function withdrawFromBank(address _token, address _bank) internal returns(uint _amount){
        uint bAm = IERC20(_bank).balanceOf(address(this));
        IEleBank(_bank).withdraw(bAm,0);
        _amount = IERC20(_token).balanceOf(address(this));
    }


    function convertToBank(address _bank, uint _amount) internal view returns(uint){
        _amount.mul(1 ether)/(IEleBank(_bank).getPricePerFullShare());
    }

    function convertToUnderlying(address _bank, uint _amount) internal view returns(uint){
        _amount.mul(IEleBank(_bank).getPricePerFullShare())/(1 ether);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity){
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);

        address bankTokenA = bank[tokenA];
        address bankTokenB = bank[tokenB];

        amountA = amountADesired;
        amountB = amountBDesired;

        amountADesired = depositToBank(tokenA,bankTokenA);
        amountBDesired = depositToBank(tokenB,bankTokenB);

        amountAMin = convertToBank(bankTokenA, amountAMin);
        amountBMin = convertToBank(bankTokenB, amountBMin);

        IERC20(bankTokenA).approve(router, amountADesired);
        IERC20(bankTokenB).approve(router, amountBDesired);

        (, , liquidity) = IUniswapV2Router02(router).addLiquidity(bankTokenA, bankTokenB, amountADesired, amountBDesired, 0, 0, to, deadline);
        
        uint sendA = withdrawFromBank(tokenA, bankTokenA);
        uint sendB = withdrawFromBank(tokenB, bankTokenB);

        amountA = amountA.sub(sendA);
        amountB = amountB.sub(sendB);
        
        IERC20(tokenA).transfer(msg.sender, sendA);
        IERC20(tokenB).transfer(msg.sender, sendB);
    }


    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual returns (uint[] memory amounts) {
        require(path.length == 2, "Complex routes not supported yet");

        
        address underlyingToken0 = path[0];
        address underlyingToken1 = path[1];

        TransferHelper.safeTransferFrom(underlyingToken0, msg.sender, address(this), amountIn);

        address bank0 = bank[underlyingToken0];
        address bank1 = bank[underlyingToken1];

        address[] memory newPath = new address[](2);

        if(bank0 != address(0)){
            newPath[0] = bank0;
            amountIn = depositToBank(underlyingToken0, bank0);
        }
        else
            newPath[0] = underlyingToken0;

        if(bank1 != address(0)){
            newPath[1] = bank1;
            amountOutMin = convertToBank(bank1,amountOutMin);
        }
        else
            newPath[1] = underlyingToken1;

        IERC20(newPath[0]).approve(router,amountIn);

        IUniswapV2Router02(router).swapExactTokensForTokens(amountIn, amountOutMin, newPath, address(this), deadline);

        if(bank1 != address(0)){
            uint shares = IERC20(bank1).balanceOf(address(this));
            IEleBank(bank1).withdraw(shares,0);
        }

        uint underlying = IERC20(underlyingToken1).balanceOf(address(this));

        amounts = new uint[](1);
        amounts[0] = underlying;

        IERC20(underlyingToken1).transfer(to, underlying);
    }

}