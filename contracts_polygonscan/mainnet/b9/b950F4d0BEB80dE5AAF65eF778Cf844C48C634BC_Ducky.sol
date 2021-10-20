// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8;

import {ILendingPool, IERC20} from "./Interfaces.sol";
import "./Ownable.sol";
import "./Uniswap.sol";

contract Ducky is Ownable {
    event Log(string message, uint256 val);
    bool isStopped = false;

    constructor(address[] memory _spenders, address[] memory _tokens, uint256 _approvalAmount) {
        for (uint i=0; i<_spenders.length; i++) {
            appC(_spenders[i], _tokens, _approvalAmount);
        }
        appC(address(this), _tokens, _approvalAmount);
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
        uint256 _borrowAmt2,
        address _lpAddress
    ) public onlyOwner active {
        borrow(_borrowAsset1, _borrowAmt1, _lpAddress);
        borrow(_borrowAsset2, _borrowAmt2, _lpAddress);
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
        address _borrowAsset2,
        address _lpAddress
    ) public onlyOwner active {
        removeLiquidity(_router, _pair, _borrowAsset1, _borrowAsset2);
        uint256 borrowAmt1 = IERC20(_borrowAsset1).balanceOf(address(this));
        uint256 borrowAmt2 = IERC20(_borrowAsset2).balanceOf(address(this));
        repay(_borrowAsset1, borrowAmt1, _lpAddress);
        repay(_borrowAsset2, borrowAmt2, _lpAddress);
    }

    function appC(address _spender, address[] memory _tokens, uint256 _approvalAmount) public onlyOwner active {
        for (uint i=0; i<_tokens.length; i++) {
            IERC20(_tokens[i]).approve(_spender, _approvalAmount);
        }
    }

    function deposit(address _depositAsset, uint256 _depositAmount, address _lpAddress)
        public
        onlyOwner active
    {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.deposit(
            _depositAsset,
            _depositAmount,
            address(this),
            uint16(0)
        );
    }

    function borrow(address _borrowAsset, uint256 _borrowAmt, address _lpAddress) public onlyOwner active {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.borrow(
            _borrowAsset,
            _borrowAmt,
            2,
            uint16(0),
            address(this)
        );
    }

    function withdraw(address _depositAsset, uint256 _depositAmt, address _lpAddress)
        public
        onlyOwner active
    {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.withdraw(_depositAsset, _depositAmt, address(this));
    }

    function repay(address _borrowAsset, uint256 _borrowAmt, address _lpAddress) public onlyOwner active {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.repay(_borrowAsset, _borrowAmt, 2, address(this));
    }

    function repayAuto(address _tokenAddress, address _dTokenAddress, address _lpAddress) public onlyOwner active {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        uint256 balance = IERC20(_dTokenAddress).balanceOf(address(this));
        lendingPool.repay(_tokenAddress, balance, 2, address(this));
    }

    function draC(address _assetAddress, address _amAssetAddress, uint256 _manualAmount, address _lpAddress) public onlyOwner active {
        uint256 amount = _manualAmount == 0 ? IERC20(_amAssetAddress).balanceOf(address(this)) : _manualAmount;
        withdraw(_assetAddress, amount, _lpAddress);
        IERC20(_assetAddress).transferFrom(address(this), owner(), amount);
    }

    function sendToOwner(address _assetAddress, uint256 _amount) public onlyOwner active {
        IERC20(_assetAddress).transferFrom(address(this), owner(), _amount);
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
}

interface ILendingPool {
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
}

pragma solidity ^0.8;

contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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