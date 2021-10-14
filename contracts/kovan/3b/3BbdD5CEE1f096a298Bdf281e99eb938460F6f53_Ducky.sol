// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8;

import {ILendingPool, IERC20} from "./Interfaces.sol";
import "./Ownable.sol";
import "./Uniswap.sol";

contract Ducky is Ownable {
    address lendingPoolAddr = 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe;
    ILendingPool lendingPool = ILendingPool(lendingPoolAddr);
    address DAI = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
    address aDAI = 0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8;
    address USDT = 0x13512979ADE267AB5100878E2e0f485B568328a4;
    address USDC = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    uint256 maxApprove = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    event Log(string message, uint256 val);

    constructor() {
        IERC20(USDT).approve(ROUTER, maxApprove);
        IERC20(USDC).approve(ROUTER, maxApprove);
        IERC20(DAI).approve(lendingPoolAddr, maxApprove);
        IERC20(USDT).approve(lendingPoolAddr, maxApprove);
        IERC20(USDC).approve(lendingPoolAddr, maxApprove);
    }

    // important to receive ETH
    receive() external payable {}

    function al(
        address _borrowAsset1,
        uint256 _borrowAmt1,
        address _borrowAsset2,
        uint256 _borrowAmt2
    ) onlyOwner public {
        borrow(_borrowAsset1, _borrowAmt1);
        borrow(_borrowAsset2, _borrowAmt2);
        addLiquidity(_borrowAsset1, _borrowAsset2, _borrowAmt1, _borrowAmt2);
    }

    function rl(
        address _borrowAsset1,
        address _borrowAsset2
    ) onlyOwner public {
        removeLiquidity(_borrowAsset1, _borrowAsset2);
        uint borrowAmt1 = IERC20(_borrowAsset1).balanceOf(address(this));
        uint borrowAmt2 = IERC20(_borrowAsset2).balanceOf(address(this));
        repay(_borrowAsset1, borrowAmt1);
        repay(_borrowAsset2, borrowAmt2); 
    }

    function depositDai(uint256 _depositAmount) onlyOwner public {
        lendingPool.deposit(DAI, _depositAmount, address(this), uint16(0));
    }

    function borrow(address _borrowAsset, uint256 _borrowAmt) onlyOwner public {
        lendingPool.borrow(
            _borrowAsset,
            _borrowAmt,
            2,
            uint16(0),
            address(this)
        );
    }

     function withdraw(address _depositAsset, uint256 _depositAmt) onlyOwner public {
        lendingPool.withdraw(
            _depositAsset,
            _depositAmt,
            address(this)
        );
    }

    function repay(address _borrowAsset,uint256 _borrowAmt) onlyOwner public {
      lendingPool.repay(
        _borrowAsset,
        _borrowAmt,
        2,
        address(this)
      );
    }

    function drainDai() onlyOwner public {
        uint daiAmt = IERC20(aDAI).balanceOf(address(this));
        withdraw(DAI,daiAmt);
        IERC20(DAI).transferFrom(address(this),0xda174bB98ffE276712E18C0b131F51692A2aB2D5,daiAmt);
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) onlyOwner public {
        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) = IUniswapV2Router(ROUTER).addLiquidity(
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

    function removeLiquidity(address _tokenA, address _tokenB) onlyOwner public {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);

        uint liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(ROUTER, liquidity);

        (uint amountA, uint amountB) =
          IUniswapV2Router(ROUTER).removeLiquidity(
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