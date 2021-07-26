/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface DexInterface {
    function createSwaps(
        string memory _swapName,
        address _dexRouter,
        address _factory,
        address _router
    ) external;
    
    function addRegistrar(address _user) external;
    
    function setFees(uint256 _fees) external;
    
    function checkRegistrar() external returns(address);
    
    function addLiquidity(
        uint256 swapId,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external;
    
    function swapExactTokensForTokens(
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external;
    
    function swapTokensForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external;
    
    function swapExactETHForTokens(
        uint256 swapId,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable;
    
    function swapTokensForExactETH(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external;
    
    function swapExactTokensForETH(
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external;
    
    function swapETHForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        address[] calldata path,
        address to
    ) external payable;
}

//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

contract Dex {
    IERC20 private _token;
    
    // address owner = 0x8F68D208179eC82aE7c6F6D945262bA478c3d7a7;
    
    address owner = 0x6d2BF01b9FB2B41DD6BEAb8A0aCc8D249666639b;
    
    address feesOwner = 0x6d2BF01b9FB2B41DD6BEAb8A0aCc8D249666639b;
    
    address private constant UNISWAP_V2_ROUTER = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public fees = 3;
    uint256 public feesDecimal = 1;
    
    uint256 public precision = 10;

    uint256 public count;

    struct Swaps {
        uint256 id;
        string swapName;
        address dexRouter;
        address factory;
        address router;
    }

    mapping(uint256 => Swaps) public swaps;

    mapping(address => address) public registrar;

    event Swap(uint256, string, address, address, address);

    constructor() {}
    
    // function approveEco(IERC20 token, uint256 _amount) public {
    //     _token = token;
    //     _token.approve(feesOwner, _amount);
    // }
    
    // Use this function where we want to set fees
    // function transferEco(IERC20 token, uint256 _amount) public {
    //     _token = token;
    //     _token.transferFrom(msg.sender, feesOwner, _amount);
    // }
    
    
    function divider(uint256 _numerator, uint256 _denominator, uint256 _precision) public pure returns(uint256) {
        return _numerator*(10**_precision)/_denominator;
    }
    
    function calculateFees(uint256 _amount) public view returns(uint256 _fees, uint256 _decimals){
        _fees = _amount*divider(divider(fees, 10, 1), 100, 10);
        _decimals = 10**11;
    }
    
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
      
        // IERC20(_tokenIn).transferFrom(msg.sender, feesOwner, _amountIn);
        
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
    
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
        } else {
          path = new address[](3);
          path[0] = _tokenIn;
          path[1] = WETH;
          path[2] = _tokenOut;
        }
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  

    function createSwaps(
        string memory _swapName,
        address _dexRouter,
        address _factory,
        address _router
    ) public {
        count++;

        swaps[count] = Swaps(count, _swapName, _dexRouter, _factory, _router);

        emit Swap(count, _swapName, _dexRouter, _factory, _router);
    }

    function addRegistrar(address _user) public {
        require(msg.sender == owner);

        registrar[_user] = _user;
    }

    function setFees(uint256 _fees) public {
        require(msg.sender == owner);

        fees = _fees;
    }

    function checkRegistrar() public view returns(address) {
        return registrar[msg.sender];
    }

    function addLiquidity(
        uint256 swapId,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 time = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            time
        );
    }

    function swapExactTokensForTokens(
        IERC20 token,
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public {
        (uint256 _fees, uint256 _decimals ) = checkRegistrar() == address(0) ? calculateFees(amountIn) : calculateFees(0);
        
        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 time = block.timestamp + 120 days;
        
        checkRegistrar() == address(0) ? require(_fees > 0, "Please check fee amount") : require(_fees == 0, "Please check fee amount");
        
        _token = token;
        
        require(_token.transferFrom(msg.sender, feesOwner, _fees*10**18*10**_decimals));

        router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, time);
    }

    function swapTokensForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 time = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            time
        );
    }

    function swapExactETHForTokens(
        uint256 swapId,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public payable {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactETH(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForETH(
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapETHForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        address[] calldata path,
        address to
    ) public payable {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            to,
            deadline
        );
    }
}