/**
 *Submitted for verification at snowtrace.io on 2021-12-26
*/

pragma solidity =0.6.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) external view returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) external view returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    //Metarouter V0 doesn't support transfer fee tokens yet
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
    function bankCurrencyBalance() view external returns(uint);
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract UniswapV2MetaRouter02 is Ownable, IUniswapV2Router02 {
    using SafeMath for uint;

    address public immutable router;

    address public immutable override factory;

    address public immutable override WETH;

    mapping(address=>address) public bank;

    mapping(address=>address) public underlying;


    constructor(address _router, address _factory, address _WETH) public {
        router = _router;
        WETH = _WETH;
        factory = _factory;
        setBank(address(0x130966628846BFd36ff31a822705796e8cb8C18D),address(0x724341e1aBbC3cf423C0Cb3E248C87F3fb69b82D));
        setBank(address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7),address(0xe03BCB67C4d0087f95185af107625Dc8a39CB742));
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    function actualToken(address _token) view public returns(address actualToken_){
        actualToken_ = bank[_token] == address(0) ? _token : bank[_token];
    }

    function actualPath(address[] memory _path) view public returns(address[] memory newPath_){
        uint len = _path.length;
        newPath_ = new address[](len);
        
        for(uint i; i<len; i++)
            newPath_[i] = actualToken(_path[i]);
    }

    function haveBank(address _token) view public returns(bool haveBank_){
        haveBank_ = bank[_token] != address(0);
    }

    function setBank(address _token, address _bank) public onlyOwner{
        bank[_token] = _bank;
        underlying[_bank] = _token;
    }

    function depositToBank(address _token) internal returns(uint _shares){
        address _bank = bank[_token];
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.approve(_bank,balance);
        uint[] memory amounts = new uint[](1);
        amounts[0] = balance;
        IEleBank(_bank).deposit(amounts);
        _shares = IERC20(_bank).balanceOf(address(this));
    }

    function depositIfTheresBank(address _token, uint _amount) internal returns(uint amount_){
        amount_ = haveBank(_token) ? depositToBank(_token) : _amount;
    }

    function withdrawFromBank(address _token) internal returns(uint amount_){
        address _bank = bank[_token];
        uint bAm = IERC20(_bank).balanceOf(address(this));
        IEleBank(_bank).withdraw(bAm,0);
        amount_ = IERC20(_token).balanceOf(address(this));
    }

    function withdrawIfTheresBank(address _token) internal returns(uint amount_){
        amount_ = haveBank(_token) ? withdrawFromBank(_token) : IERC20(_token).balanceOf(address(this));
    }

    function convertToBank(address _bank, uint _amount) internal view returns(uint amount_){
        amount_ = _amount.mul(1 ether)/(IEleBank(_bank).getPricePerFullShare());
    }

    function convertToUnderlying(address _bank, uint _amount) internal view returns(uint amount_){
        amount_ = _amount.mul(IEleBank(_bank).getPricePerFullShare())/(1 ether);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function isAvailable(address _bank, uint _amount) public view returns(bool){
        uint _total = IEleBank(_bank).bankCurrencyBalance();
        return(_amount < _total);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee)
        public
        view
        virtual
        override
        returns (uint amountIn)
    {
        amountIn = IUniswapV2Router02(router).getAmountIn(amountOut, reserveIn, reserveOut, fee);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee)
        public
        view
        virtual
        override
        returns (uint amountOut)
    {
        amountOut = IUniswapV2Router02(router).getAmountOut(amountIn, reserveIn, reserveOut, fee);
    }


    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        uint len = path.length;
        
        address[] memory newPath = actualPath(path);
    
        amountOut = haveBank(path[len-1]) ? convertToBank(newPath[len-1], amountOut) : amountOut;

        amounts = IUniswapV2Router02(router).getAmountsIn(amountOut, newPath);
        
        for(uint i; i<len; i++)
            amounts[i] = haveBank(path[i]) ? convertToUnderlying(newPath[i], amounts[i]) : amounts[i];

        require(isAvailable(newPath[len-1], amounts[len-1]), "Utilization problem");
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        uint len = path.length;
        
        address[] memory newPath = actualPath(path);
        
        amountIn = haveBank(path[0]) ? convertToBank(newPath[0], amountIn) : amountIn;

        amounts = IUniswapV2Router02(router).getAmountsOut(amountIn, newPath);
        
        for(uint i; i<len; i++)
            amounts[i] = haveBank(path[i]) ? convertToUnderlying(newPath[i], amounts[i]) : amounts[i];

        require(isAvailable(newPath[len-1], amounts[len-1]), "Utilization problem");
    }



    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = pairFor(WETH, token);

        uint value = approveMax ? uint(-1) : liquidity;

        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);

        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }


    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) payable returns (uint amountToken, uint amountETH, uint liquidity) {
        uint amountWETHDesired = msg.value;
        IWETH(WETH).deposit{value:amountWETHDesired}();

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);

        //IERC20(WETH).approve(address(this), amountWETHDesired); // Not needed on wavax as sender is spender
        try IERC20(token).approve(address(this), amountTokenDesired){} catch {// might be needed on some tokens
            // self approval might be disabled on others
        } 

        (amountToken, amountETH, liquidity) =
            IUniswapV2Router02(address(this)).addLiquidity
                (token, WETH, amountTokenDesired, amountWETHDesired, amountETHMin, amountTokenMin, to, deadline);

        if(amountToken < amountTokenDesired)
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));

        if(amountETH < amountWETHDesired){
            uint weiBal = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(weiBal);
            msg.sender.transfer(weiBal);
        }

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
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity){
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);

        address actualTokenA = actualToken(tokenA);
        address actualTokenB = actualToken(tokenB);

        amountA = amountADesired;
        amountB = amountBDesired;

        amountADesired = depositIfTheresBank(tokenA, amountADesired);
        amountBDesired = depositIfTheresBank(tokenB, amountBDesired);

        amountAMin = haveBank(tokenA) ? convertToBank(actualTokenA, amountAMin) : amountAMin;
        amountBMin = haveBank(tokenB) ? convertToBank(actualTokenB, amountBMin) : amountBMin;

        IERC20(actualTokenA).approve(router, amountADesired);
        IERC20(actualTokenB).approve(router, amountBDesired);

        (, , liquidity) = IUniswapV2Router02(router).addLiquidity(actualTokenA, actualTokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        
        uint sendA = withdrawIfTheresBank(tokenA);

        uint sendB = withdrawIfTheresBank(tokenB);

        amountA = amountA.sub(sendA);
        amountB = amountB.sub(sendB);
        
        IERC20(tokenA).transfer(msg.sender, sendA);
        IERC20(tokenB).transfer(msg.sender, sendB);
    }

    function pairFor(address tokenA, address tokenB) view public returns(address){
        address actualTokenA = actualToken(tokenA);
        address actualTokenB = actualToken(tokenB);
        return UniswapV2Library.pairFor(factory, actualTokenA, actualTokenB);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = pairFor(tokenA, tokenB);

        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address actualTokenA = actualToken(tokenA);
        address actualTokenB = actualToken(tokenB);

        address pair = UniswapV2Library.pairFor(factory, actualTokenA, actualTokenB);

        TransferHelper.safeTransferFrom(pair, msg.sender,address(this), liquidity);

        IERC20(pair).approve(router, liquidity);

        amountAMin = haveBank(tokenA) ? convertToBank(actualTokenA,amountAMin) : amountAMin;
        amountBMin = haveBank(tokenB) ? convertToBank(actualTokenB,amountBMin) : amountBMin;

        IUniswapV2Router02(router).removeLiquidity(actualTokenA, actualTokenB, liquidity, amountAMin, amountBMin, address(this), deadline);

        amountA = withdrawIfTheresBank(tokenA);
        amountB = withdrawIfTheresBank(tokenB);

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
    }


    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
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

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');

        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(this), amounts[0]
        );

        address[] memory newPath = actualPath(path);

        amountIn = depositIfTheresBank(path[0], amounts[0]);

        _swap(newPath, amountIn);

        uint send = withdrawIfTheresBank(path[path.length-1]);

        IWETH(WETH).withdraw(send);

        TransferHelper.safeTransferETH(to, send);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline) 
        returns (uint[] memory amounts) 
    {
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(this), amounts[0]
        );

        address[] memory newPath = actualPath(path);

        amountIn = depositIfTheresBank(path[0], amounts[0]);

        _swap(newPath, amountIn);

        uint send = withdrawIfTheresBank(path[path.length-1]);

        IERC20(path[path.length-1]).transfer(to, send);
    }    

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');

        IWETH(WETH).deposit{value: amounts[0]}();

        address[] memory newPath = actualPath(path);

        uint amountIn = depositIfTheresBank(WETH, amounts[0]);

        _swap(newPath, amountIn);

        uint send = withdrawIfTheresBank(path[path.length-1]);

        IERC20(path[path.length-1]).transfer(to, send);
        
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(this), amounts[0]
        );

        address[] memory newPath = actualPath(path);

        _swap(newPath, amounts[0]);

        uint send = withdrawIfTheresBank(WETH);

        IWETH(WETH).withdraw(send);
        TransferHelper.safeTransferETH(to, send);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, address(this), amounts[0]
        );

        address[] memory newPath = actualPath(path);

        uint amountIn = depositIfTheresBank(path[0], amounts[0]);

        _swap(newPath, amountIn);

        uint send = withdrawIfTheresBank(path[path.length-1]);

        IERC20(path[path.length-1]).transfer(to, send);
    }


    function _swap(address[] memory path, uint amountIn) internal{
        IERC20(path[0]).approve(router, amountIn);
        IUniswapV2Router02(router).swapExactTokensForTokens(amountIn,0,path,address(this),uint(-1));
    }


    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');

        amounts = getAmountsOut(msg.value, path);

        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        IWETH(WETH).deposit{value: msg.value}();

        address[] memory newPath = actualPath(path);

        uint amountIn = depositIfTheresBank(WETH, msg.value);

        _swap(newPath, amountIn);

        uint send = withdrawIfTheresBank(path[path.length-1]);

        IERC20(path[path.length-1]).transfer(to, send);
    }
}


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'dfed87310c200825be0c68d7f502397cb875f369746802e9d1dbf15ed035ddad' // init code hash
            ))));
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }


}