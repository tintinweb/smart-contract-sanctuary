// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8;

import {ILendingPool, IERC20} from "./Interfaces.sol";
import "./Ownable.sol";
import "./Uniswap.sol";

interface ChiToken {
    function freeFromUpTo(address from, uint256 value) external;
}

contract Ducky is Ownable {
    event Log(string message, uint256 val);
    bool isStopped = false;
    ChiToken public constant chi =
        ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    address l_router;
    address l_pair;
    address l_borrowAsset1;
    address l_borrowAsset2;

    constructor(
        address[] memory _spenders,
        address[] memory _tokens,
        uint256 _approvalAmount
    ) {
        for (uint256 i = 0; i < _spenders.length; i++) {
            app(_spenders[i], _tokens, _approvalAmount);
        }
        app(address(this), _tokens, _approvalAmount);
    }

    // important to receive ETH
    receive() external payable {}

    modifier dc() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    modifier active() {
        require(!isStopped);
        _;
    }

    function getAssets(address _borrowAsset, uint256 _borrowAmt)
        internal
        view
        returns (uint256 poolAmt, uint8 source)
    {
        if (_borrowAsset != l_borrowAsset1 && _borrowAsset != l_borrowAsset2) {
            return (_borrowAmt, 0);
        } else {
            if (_borrowAsset == l_borrowAsset1) {
                return (IERC20(l_borrowAsset1).balanceOf(address(this)), 1);
            } else {
                return (IERC20(l_borrowAsset2).balanceOf(address(this)), 2);
            }
        }
    }

    function al2(
        address _router,
        address _borrowAsset1,
        uint256 _borrowAmt1,
        address _borrowAsset2,
        uint256 _borrowAmt2,
        address _lpAddress,
        address _pair
    ) public onlyOwner active dc {
        uint256 poolAmt1;
        uint256 poolAmt2;
        uint8 source1;
        uint8 source2;
        if (l_pair != address(0)) {
            removeLiquidity(l_router, l_pair, l_borrowAsset1, l_borrowAsset2);
        }
        
        (poolAmt1, source1) = getAssets(_borrowAsset1, _borrowAmt1);
        (poolAmt2, source2) = getAssets(_borrowAsset2, _borrowAmt2);
        
        if (l_borrowAsset1 != address(0)) {
            checkForRepay(1, source1, source2, l_borrowAsset1, _lpAddress);
        }
        if (l_borrowAsset2 != address(0)) {
            checkForRepay(2, source1, source2, l_borrowAsset2, _lpAddress);
        }

        if (source1 == 0) {
            borrow(_borrowAsset1, _borrowAmt1, _lpAddress, 1);
        }
        else {
        
            l_borrowAsset1 = _borrowAsset1;
        }
        if (source2 == 0) {
            borrow(_borrowAsset2, _borrowAmt2, _lpAddress, 2);
        }
        else {
            l_borrowAsset2 = _borrowAsset2;
        }

        if (poolAmt1 < _borrowAmt1 || poolAmt2 < _borrowAmt2) {
            uint256 impliedK = _borrowAmt1 * _borrowAmt2;
            uint256 ratio1 = impliedK / _borrowAmt1;
            uint256 ratio2 = impliedK / _borrowAmt2;
            uint256 newImpliedK;

            if (poolAmt1 < _borrowAmt1) {
                newImpliedK = poolAmt1 * ratio1;
                poolAmt2 = newImpliedK / ratio2;
            } else if (poolAmt2 < _borrowAmt2) {
                newImpliedK = poolAmt2 * ratio2;
                poolAmt1 = newImpliedK / ratio1;
            }
        }

        addLiquidity(
            _router,
            _pair,
            _borrowAsset1,
            _borrowAsset2,
            poolAmt1,
            poolAmt2
        );
    }

    function checkForRepay(
        uint8 _pairNo,
        uint8 _source1,
        uint8 _source2,
        address _l_borrowAsset,
        address _lpAddress
    ) internal {
        if (_source1 != _pairNo && _source2 != _pairNo) {
            uint256 l_borrowAmt = IERC20(_l_borrowAsset).balanceOf(
                address(this)
            );
            repay(_l_borrowAsset, l_borrowAmt, _lpAddress, _pairNo);
        }
    }

    function setLast(
        address _l_router,
        address _l_pair,
        address _l_borrowAsset1,
        address _l_borrowAsset2
    ) public onlyOwner active dc {
        l_router = _l_router;
        l_pair = _l_pair;
        l_borrowAsset1 = _l_borrowAsset1;
        l_borrowAsset2 = _l_borrowAsset2;
    }

    function getLast()
        public
        view
        active
        returns (
            address rl_router,
            address rl_pair,
            address rl_borrowAsset1,
            address rl_borrowAsset2
        )
    {
        return (l_router, l_pair, l_borrowAsset1, l_borrowAsset2);
    }

    function rla() public onlyOwner active dc {
        removeLiquidity(l_router, l_pair, l_borrowAsset1, l_borrowAsset2);
    }

    function rl(
        address _router,
        address _pair,
        address _borrowAsset1,
        address _borrowAsset2
    ) public onlyOwner active dc {
        removeLiquidity(_router, _pair, _borrowAsset1, _borrowAsset2);
    }

    function rlrp(
        address _router,
        address _pair,
        address _borrowAsset1,
        address _borrowAsset2,
        address _lpAddress
    ) public onlyOwner active dc {
        removeLiquidity(_router, _pair, _borrowAsset1, _borrowAsset2);
        uint256 borrowAmt1 = IERC20(_borrowAsset1).balanceOf(address(this));
        uint256 borrowAmt2 = IERC20(_borrowAsset2).balanceOf(address(this));
        repay(_borrowAsset1, borrowAmt1, _lpAddress, 1);
        repay(_borrowAsset2, borrowAmt2, _lpAddress, 2);
    }

    function app(
        address _spender,
        address[] memory _tokens,
        uint256 _approvalAmount
    ) public onlyOwner active {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).approve(_spender, _approvalAmount);
        }
    }

    function deposit(
        address _depositAsset,
        uint256 _depositAmount,
        address _lpAddress
    ) public onlyOwner active dc {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.deposit(
            _depositAsset,
            _depositAmount,
            address(this),
            uint16(0)
        );
    }

    function borrow(
        address _borrowAsset,
        uint256 _borrowAmt,
        address _lpAddress,
        uint8 _pairNo
    ) public onlyOwner active dc {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.borrow(
            _borrowAsset,
            _borrowAmt,
            2,
            uint16(0),
            address(this)
        );
        if (_pairNo == 1) {
            l_borrowAsset1 = _borrowAsset;
        }
        if (_pairNo == 2) {
            l_borrowAsset2 = _borrowAsset;
        }
    }

    function withdraw(
        address _depositAsset,
        uint256 _depositAmt,
        address _lpAddress
    ) public onlyOwner active dc {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.withdraw(_depositAsset, _depositAmt, address(this));
    }

    function repay(
        address _borrowAsset,
        uint256 _borrowAmt,
        address _lpAddress,
        uint8 _pairNo
    ) public onlyOwner active dc {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        lendingPool.repay(_borrowAsset, _borrowAmt, 2, address(this));
        if (_pairNo == 1) {
            l_borrowAsset1 = address(0);
        } else {
            l_borrowAsset2 = address(0);
        }
    }

    function repayAuto(
        address _tokenAddress,
        address _dTokenAddress,
        address _lpAddress
    ) public onlyOwner active dc {
        ILendingPool lendingPool = ILendingPool(_lpAddress);
        uint256 balance = IERC20(_dTokenAddress).balanceOf(address(this));
        lendingPool.repay(_tokenAddress, balance, 2, address(this));
    }

    function draC(
        address _assetAddress,
        address _amAssetAddress,
        uint256 _manualAmount,
        address _lpAddress
    ) public onlyOwner active dc {
        uint256 amount = _manualAmount == 0
            ? IERC20(_amAssetAddress).balanceOf(address(this))
            : _manualAmount;
        withdraw(_assetAddress, amount, _lpAddress);
        IERC20(_assetAddress).transferFrom(address(this), owner(), amount);
    }

    function sendToOwner(address _assetAddress, uint256 _amount)
        public
        onlyOwner
        active
        dc
    {
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
        address _pair,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) public onlyOwner active dc {
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
        l_pair = _pair;
        l_router = _router;
        emit Log("addAmountA", amountA);
        emit Log("addAmountB", amountB);
        emit Log("addLiquidity", liquidity);
    }

    function removeLiquidity(
        address _router,
        address _pair,
        address _tokenA,
        address _tokenB
    ) public onlyOwner active dc {
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
        l_pair = address(0);
        l_router = address(0);
        emit Log("removeAmountA", amountA);
        emit Log("removeAmountB", amountB);
        emit Log("removeLiquidity", liquidity);
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