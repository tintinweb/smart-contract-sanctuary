// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8;

import {ILendingPool, IERC20} from "./Interfaces.sol";
import "./Ownable.sol";
import "./Uniswap.sol";

contract Ducky is Ownable {
    address LENDING_POOL_ADDR = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf; //
    ILendingPool lendingPool = ILendingPool(LENDING_POOL_ADDR);
    address DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; //
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; //
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; //
    address WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //
    address WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; //
    address WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6; //
    address QS_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //
    address SS_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; //
    address DF_ROUTER = 0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429; //
    uint256 maxApprove =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    event Log(string message, uint256 val);
    bool isStopped = false;

    constructor() {
        appC(QS_ROUTER);
        appC(SS_ROUTER);
        appC(DF_ROUTER);
        appC(LENDING_POOL_ADDR);
    }

    // important to receive ETH
    receive() external payable {}

    modifier active {
        require(!isStopped);
        _;
    }

    function al(
        address _router,
        address _borrowAsset1,
        uint256 _borrowAmt1,
        address _borrowAsset2,
        uint256 _borrowAmt2
    ) public onlyOwner active {
        borrow(_borrowAsset1, _borrowAmt1);
        borrow(_borrowAsset2, _borrowAmt2);
        addLiquidity(
            _router,
            _borrowAsset1,
            _borrowAsset2,
            _borrowAmt1,
            _borrowAmt2
        );
    }

    function rl(
        address _router,
        address _pair,
        address _borrowAsset1,
        address _borrowAsset2
    ) public onlyOwner active {
        removeLiquidity(_router, _pair, _borrowAsset1, _borrowAsset2);
        uint256 borrowAmt1 = IERC20(_borrowAsset1).balanceOf(address(this));
        uint256 borrowAmt2 = IERC20(_borrowAsset2).balanceOf(address(this));
        repay(_borrowAsset1, borrowAmt1);
        repay(_borrowAsset2, borrowAmt2);
    }

    function appC(address _spender) public onlyOwner active {
        IERC20(USDT).approve(_spender, maxApprove);
        IERC20(USDC).approve(_spender, maxApprove);
        IERC20(DAI).approve(_spender, maxApprove);
        IERC20(WMATIC).approve(_spender, maxApprove);
        IERC20(WETH).approve(_spender, maxApprove);
        IERC20(WBTC).approve(_spender, maxApprove);
    }

    function deposit(address _depositAsset, uint256 _depositAmount)
        public
        onlyOwner active
    {
        lendingPool.deposit(
            _depositAsset,
            _depositAmount,
            address(this),
            uint16(0)
        );
    }

    function borrow(address _borrowAsset, uint256 _borrowAmt) public onlyOwner active {
        lendingPool.borrow(
            _borrowAsset,
            _borrowAmt,
            2,
            uint16(0),
            address(this)
        );
    }

    function withdraw(address _depositAsset, uint256 _depositAmt)
        public
        onlyOwner active
    {
        lendingPool.withdraw(_depositAsset, _depositAmt, address(this));
    }

    function repay(address _borrowAsset, uint256 _borrowAmt) public onlyOwner active {
        lendingPool.repay(_borrowAsset, _borrowAmt, 2, address(this));
    }

    function draC(address _asset, address _dAsset) public onlyOwner active {
        uint256 amount = IERC20(_dAsset).balanceOf(address(this));
        withdraw(_asset, amount);
        IERC20(_asset).transferFrom(address(this), owner(), amount);
    }

    function stop() public onlyOwner active {
        isStopped = true;
    }

    function resume() public onlyOwner {
        isStopped = false;
    }

    function addLiquidity(
        address _router,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) public onlyOwner active {
        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) = IUniswapV2Router(_router).addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                address(this),
                block.timestamp
            );
        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
        emit Log("liquidity", liquidity);
    }

    function removeLiquidity(
        address _router,
        address _pair,
        address _tokenA,
        address _tokenB
    ) public onlyOwner active {
        uint256 liquidity = IERC20(_pair).balanceOf(address(this));
        IERC20(_pair).approve(_router, liquidity);

        (uint256 amountA, uint256 amountB) = IUniswapV2Router(_router)
            .removeLiquidity(
                _tokenA,
                _tokenB,
                liquidity,
                1,
                1,
                address(this),
                block.timestamp
            );

        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
        emit Log("liquidity", liquidity);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8;

interface IERC20 {
  
  function balanceOf(address account) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILendingPool {
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external;

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  
}

pragma solidity ^0.8;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IUniswapV2Router {

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}