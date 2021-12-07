/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// File: contracts/UniswapV2Interfaces.sol

pragma solidity 0.5.17;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}


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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}
// File: contracts/UniswapFlashSwapper.sol

contract UniswapFlashSwapper {

    enum SwapType {SimpleLoan, SimpleSwap, TriangularSwap}

    // CONSTANTS
    IUniswapV2Factory constant uniswapV2Factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); // same for all networks
    address constant ETH = address(0);

    // ACCESS CONTROL
    // Only the `permissionedPairAddress` may call the `uniswapV2Call` function
    address permissionedPairAddress = address(1);

    // DEFAULT TOKENS
    address WETH;
    address DAI;

    constructor() public {
        WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    }

    // Fallback must be payable
    function() external payable {}

    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function startSwap(address _tokenBorrow, uint256 _amount, address _tokenPay, bytes memory _userData) internal {
        bool isBorrowingEth;
        bool isPayingEth;
        address tokenBorrow = _tokenBorrow;
        address tokenPay = _tokenPay;

        if (tokenBorrow == ETH) {
            isBorrowingEth = true;
            tokenBorrow = WETH; // we'll borrow WETH from UniswapV2 but then unwrap it for the user
        }
        if (tokenPay == ETH) {
            isPayingEth = true;
            tokenPay = WETH; // we'll wrap the user's ETH before sending it back to UniswapV2
        }

        if (tokenBorrow == tokenPay) {
            simpleFlashLoan(tokenBorrow, _amount, isBorrowingEth, isPayingEth, _userData);
            return;
        } else if (tokenBorrow == WETH || tokenPay == WETH) {
            simpleFlashSwap(tokenBorrow, _amount, tokenPay, isBorrowingEth, isPayingEth, _userData);
            return;
        } else {
            traingularFlashSwap(tokenBorrow, _amount, tokenPay, _userData);
            return;
        }

    }


    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        // access control
        require(msg.sender == permissionedPairAddress, "only permissioned UniswapV2 pair can call");
        require(_sender == address(this), "only this contract may initiate");

        // decode data
        (
            SwapType _swapType,
            address _tokenBorrow,
            uint _amount,
            address _tokenPay,
            bool _isBorrowingEth,
            bool _isPayingEth,
            bytes memory _triangleData,
            bytes memory _userData
        ) = abi.decode(_data, (SwapType, address, uint, address, bool, bool, bytes, bytes));

        if (_swapType == SwapType.SimpleLoan) {
            simpleFlashLoanExecute(_tokenBorrow, _amount, msg.sender, _isBorrowingEth, _isPayingEth, _userData);
            return;
        } else if (_swapType == SwapType.SimpleSwap) {
            simpleFlashSwapExecute(_tokenBorrow, _amount, _tokenPay, msg.sender, _isBorrowingEth, _isPayingEth, _userData);
            return;
        } else {
            traingularFlashSwapExecute(_tokenBorrow, _amount, _tokenPay, _triangleData, _userData);
        }

        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            _amount0;
            _amount1;
        }
    }

    // @notice This function is used when the user repays with the same token they borrowed
    // @dev This initiates the flash borrow. See `simpleFlashLoanExecute` for the code that executes after the borrow.
    function simpleFlashLoan(address _tokenBorrow, uint256 _amount, bool _isBorrowingEth, bool _isPayingEth, bytes memory _userData) private {
        address tokenOther = _tokenBorrow == WETH ? DAI : WETH;
        permissionedPairAddress = uniswapV2Factory.getPair(_tokenBorrow, tokenOther); // is it cheaper to compute this locally?
        address pairAddress = permissionedPairAddress; // gas efficiency
        require(pairAddress != address(0), "Requested _token is not available.");
        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(
            SwapType.SimpleLoan,
            _tokenBorrow,
            _amount,
            _tokenBorrow,
            _isBorrowingEth,
            _isPayingEth,
            bytes(""),
            _userData
        ); // note _tokenBorrow == _tokenPay
        IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), data);
    }

    // @notice This is the code that is executed after `simpleFlashLoan` initiated the flash-borrow
    // @dev When this code executes, this contract will hold the flash-borrowed _amount of _tokenBorrow
    function simpleFlashLoanExecute(
        address _tokenBorrow,
        uint _amount,
        address _pairAddress,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _userData
    ) private {
        // unwrap WETH if necessary
        if (_isBorrowingEth) {
            IWETH(WETH).withdraw(_amount);
        }

        // compute amount of tokens that need to be paid back
        uint fee = ((_amount * 3) / 997) + 1;
        uint amountToRepay = _amount + fee;
        address tokenBorrowed = _isBorrowingEth ? ETH : _tokenBorrow;
        address tokenToRepay = _isPayingEth ? ETH : _tokenBorrow;

        // do whatever the user wants
        execute(tokenBorrowed, _amount, tokenToRepay, amountToRepay, _userData);

        // payback the loan
        // wrap the ETH if necessary
        if (_isPayingEth) {
            IWETH(WETH).deposit.value(amountToRepay)();
        }
        IERC20(_tokenBorrow).transfer(_pairAddress, amountToRepay);
    }

    // @notice This function is used when either the _tokenBorrow or _tokenPay is WETH or ETH
    // @dev Since ~all tokens trade against WETH (if they trade at all), we can use a single UniswapV2 pair to
    //     flash-borrow and repay with the requested tokens.
    // @dev This initiates the flash borrow. See `simpleFlashSwapExecute` for the code that executes after the borrow.
    function simpleFlashSwap(
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _userData
    ) private {
        permissionedPairAddress = uniswapV2Factory.getPair(_tokenBorrow, _tokenPay); // is it cheaper to compute this locally?
        address pairAddress = permissionedPairAddress; // gas efficiency
        require(pairAddress != address(0), "Requested pair is not available.");
        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(
            SwapType.SimpleSwap,
            _tokenBorrow,
            _amount,
            _tokenPay,
            _isBorrowingEth,
            _isPayingEth,
            bytes(""),
            _userData
        );
        IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), data);
    }

    // @notice This is the code that is executed after `simpleFlashSwap` initiated the flash-borrow
    // @dev When this code executes, this contract will hold the flash-borrowed _amount of _tokenBorrow
    function simpleFlashSwapExecute(
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        address _pairAddress,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _userData
    ) private {
        // unwrap WETH if necessary
        if (_isBorrowingEth) {
            IWETH(WETH).withdraw(_amount);
        }

        // compute the amount of _tokenPay that needs to be repaid
        address pairAddress = permissionedPairAddress; // gas efficiency
        uint pairBalanceTokenBorrow = IERC20(_tokenBorrow).balanceOf(pairAddress);
        uint pairBalanceTokenPay = IERC20(_tokenPay).balanceOf(pairAddress);
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amount) / (997 * pairBalanceTokenBorrow)) + 1;

        // get the orignal tokens the user requested
        address tokenBorrowed = _isBorrowingEth ? ETH : _tokenBorrow;
        address tokenToRepay = _isPayingEth ? ETH : _tokenPay;

        // do whatever the user wants
        execute(tokenBorrowed, _amount, tokenToRepay, amountToRepay, _userData);

        // payback loan
        // wrap ETH if necessary
        if (_isPayingEth) {
            IWETH(WETH).deposit.value(amountToRepay)();
        }
        IERC20(_tokenPay).transfer(_pairAddress, amountToRepay);
    }

    // @notice This function is used when neither the _tokenBorrow nor the _tokenPay is WETH
    // @dev Since it is unlikely that the _tokenBorrow/_tokenPay pair has more liquidaity than the _tokenBorrow/WETH and
    //     _tokenPay/WETH pairs, we do a triangular swap here. That is, we flash borrow WETH from the _tokenPay/WETH pair,
    //     Then we swap that borrowed WETH for the desired _tokenBorrow via the _tokenBorrow/WETH pair. And finally,
    //     we pay back the original flash-borrow using _tokenPay.
    // @dev This initiates the flash borrow. See `traingularFlashSwapExecute` for the code that executes after the borrow.
    function traingularFlashSwap(address _tokenBorrow, uint _amount, address _tokenPay, bytes memory _userData) private {
        address borrowPairAddress = uniswapV2Factory.getPair(_tokenBorrow, WETH); // is it cheaper to compute this locally?
        require(borrowPairAddress != address(0), "Requested borrow token is not available.");

        permissionedPairAddress = uniswapV2Factory.getPair(_tokenPay, WETH); // is it cheaper to compute this locally?
        address payPairAddress = permissionedPairAddress; // gas efficiency
        require(payPairAddress != address(0), "Requested pay token is not available.");

        // STEP 1: Compute how much WETH will be needed to get _amount of _tokenBorrow out of the _tokenBorrow/WETH pool
        uint pairBalanceTokenBorrowBefore = IERC20(_tokenBorrow).balanceOf(borrowPairAddress);
        require(pairBalanceTokenBorrowBefore >= _amount, "_amount is too big");
        uint pairBalanceTokenBorrowAfter = pairBalanceTokenBorrowBefore - _amount;
        uint pairBalanceWeth = IERC20(WETH).balanceOf(borrowPairAddress);
        uint amountOfWeth = ((1000 * pairBalanceWeth * _amount) / (997 * pairBalanceTokenBorrowAfter)) + 1;

        // using a helper function here to avoid "stack too deep" :(
        traingularFlashSwapHelper(_tokenBorrow, _amount, _tokenPay, borrowPairAddress, payPairAddress, amountOfWeth, _userData);
    }

    // @notice Helper function for `traingularFlashSwap` to avoid `stack too deep` errors
    function traingularFlashSwapHelper(
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        address _borrowPairAddress,
        address _payPairAddress,
        uint _amountOfWeth,
        bytes memory _userData
    ) private returns (uint) {
        // Step 2: Flash-borrow _amountOfWeth WETH from the _tokenPay/WETH pool
        address token0 = IUniswapV2Pair(_payPairAddress).token0();
        address token1 = IUniswapV2Pair(_payPairAddress).token1();
        uint amount0Out = WETH == token0 ? _amountOfWeth : 0;
        uint amount1Out = WETH == token1 ? _amountOfWeth : 0;
        bytes memory triangleData = abi.encode(_borrowPairAddress, _amountOfWeth);
        bytes memory data = abi.encode(SwapType.TriangularSwap, _tokenBorrow, _amount, _tokenPay, false, false, triangleData, _userData);
        // initiate the flash swap from UniswapV2
        IUniswapV2Pair(_payPairAddress).swap(amount0Out, amount1Out, address(this), data);
    }

    // @notice This is the code that is executed after `traingularFlashSwap` initiated the flash-borrow
    // @dev When this code executes, this contract will hold the amount of WETH we need in order to get _amount
    //     _tokenBorrow from the _tokenBorrow/WETH pair.
    function traingularFlashSwapExecute(
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        bytes memory _triangleData,
        bytes memory _userData
    ) private {
        // decode _triangleData
        (address _borrowPairAddress, uint _amountOfWeth) = abi.decode(_triangleData, (address, uint));

        // Step 3: Using a normal swap, trade that WETH for _tokenBorrow
        address token0 = IUniswapV2Pair(_borrowPairAddress).token0();
        address token1 = IUniswapV2Pair(_borrowPairAddress).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;
        IERC20(WETH).transfer(_borrowPairAddress, _amountOfWeth); // send our flash-borrowed WETH to the pair
        IUniswapV2Pair(_borrowPairAddress).swap(amount0Out, amount1Out, address(this), bytes(""));

        // compute the amount of _tokenPay that needs to be repaid
        address payPairAddress = permissionedPairAddress; // gas efficiency
        uint pairBalanceWETH = IERC20(WETH).balanceOf(payPairAddress);
        uint pairBalanceTokenPay = IERC20(_tokenPay).balanceOf(payPairAddress);
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amountOfWeth) / (997 * pairBalanceWETH)) + 1;

        // Step 4: Do whatever the user wants (arb, liqudiation, etc)
        execute(_tokenBorrow, _amount, _tokenPay, amountToRepay, _userData);

        // Step 5: Pay back the flash-borrow to the _tokenPay/WETH pool
        IERC20(_tokenPay).transfer(payPairAddress, amountToRepay);
    }

    // @notice This is where the user's custom logic goes
    // @dev When this function executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds the necessary
    //     amount of the original _tokenPay needed to pay back the flash-loan.
    // @dev Paying back the flash-loan happens automatically by the calling function -- do not pay back the loan in this function
    // @dev If you entered `0x0` for _tokenPay when you called `flashSwap`, then make sure this contract holds _amount ETH before this
    //     finishes executing
    // @dev User will override this function on the inheriting contract
    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal;

}

interface IUniswapV2Router02 {
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only for owner");
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ExampleContract is UniswapFlashSwapper, Ownable {

    // JUST FOR TESTING - ITS OKAY TO REMOVE ALL OF THESE VARS
    address public lastTokenBorrow;
    uint public lastAmount;
    address public lastTokenPay;
    uint public lastamountToRepay;
    bytes public lastUserData;
    uint public lastAmountRec;

    address private constant ape = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7; 
    IUniswapV2Router02 apeRouter = IUniswapV2Router02(ape);

    constructor() public UniswapFlashSwapper() {}

    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function flashSwap(address _tokenBorrow, uint256 _amount, address _tokenPay, bytes calldata _userData) external {
        // you can do anything you want to here before the flash swap happens
        // ...

        // Start the flash swap
        // This will acuire _amount of the _tokenBorrow token for this contract and then
        // run the `execute` function below
        startSwap(_tokenBorrow, _amount, _tokenPay, _userData);

        // you can do anything you want to here after the flash swap has completed
        // ...
    }


    // @notice This is where your custom logic goes
    // @dev When this code executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds
    //     at least _amountToRepay of the _tokenPay token
    // @dev Paying back the flash-loan happens automatically for you -- DO NOT pay back the loan in this function
    // @param _tokenBorrow The address of the token you flash-borrowed, address(0) indicates ETH
    // @param _amount The amount of the _tokenBorrow token you borrowed
    // @param _tokenPay The address of the token in which you'll repay the flash-borrow, address(0) indicates ETH
    // @param _amountToRepay The amount of the _tokenPay token that will be auto-removed from this contract to pay back
    //        the flash-borrow when this function finishes executing
    // @param _userData Any data you privided to the flashBorrow function when you called it
    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal {
        // do whatever you want here
        // we're just going to update some local variables because we're boring
        // but you could do some arbitrage or liquidaztions or CDP collateral swaps, etc
        
        // swap token and obtain equivalent otherToken amountRequired as a result
        // need to receive amountRequired at minimum amount to pay back
        // uint amountReceived = bakeryRouter.swapExactTokensForTokens(
        address[] memory path = new address[](2);

        path[0] = _tokenBorrow;
        path[1] = _tokenPay;

        uint amountReceived = apeRouter.swapExactTokensForTokens(
            _amount,
            0,
            path,
            msg.sender,
            block.timestamp
        )[1];

        lastTokenBorrow = _tokenBorrow; // just for testing
        lastAmount = _amount; // just for testing
        lastTokenPay = _tokenPay; // just for testing
        lastamountToRepay = _amountToRepay; // just for testing
        lastUserData = _userData; // just for testing
        lastAmountRec = amountReceived;

        require(amountReceived > _amountToRepay, "Not Prof"); // fail if we didn't get enough tokens
    }

    function getLastData() public view returns(address,uint256,address,uint256,uint256,bytes memory){
        return(lastTokenBorrow, lastAmount, lastTokenPay, lastamountToRepay, lastAmountRec, lastUserData);
    }

    // @notice Simple getter for convenience while testing
    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }

    function() external payable {}

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance); 
    }
}