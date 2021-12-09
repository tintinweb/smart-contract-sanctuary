/**
 *Submitted for verification at snowtrace.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/libs/IPangolinRouter.sol

pragma solidity >=0.6.2;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
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
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
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
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/*
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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/Liquidity.sol

/*
 .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. 
( D .'( E .'( S .'( I .'( R .'( E .' 
 `.(   `.(   `.(   `.(   `.(   `.(   
                by sandman.finance                                     
 */

pragma solidity ^0.8.6;



contract Liquidity is Ownable {
    
    IERC20 public USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    IERC20 public WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public BANKSY;
    IPangolinRouter ROUTER = IPangolinRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    uint256  slippageFactor = 950; // 5% default slippage tolerance

    address[] usdtToWavaxPath = [address(USDT), address(WAVAX)];

    constructor(
      address _BANKSY
    ) {
      BANKSY = IERC20(_BANKSY);
      _allowance();
    }

  receive() external payable {}

  function withdrawBanksyLiquidity() external onlyOwner {
      USDT.transfer(msg.sender, USDT.balanceOf(address(this)));
      BANKSY.transfer(msg.sender, BANKSY.balanceOf(address(this)));
  }


  function withdrawETHLiquidity()  external onlyOwner {
      uint256 etherBalance = address(this).balance;
      payable(msg.sender).transfer(etherBalance);
  }

 function withdrawAll()  external onlyOwner {
      uint256 etherBalance = address(this).balance;
      payable(msg.sender).transfer(etherBalance);
      USDT.transfer(msg.sender, USDT.balanceOf(address(this)));
      BANKSY.transfer(msg.sender, BANKSY.balanceOf(address(this)));
  }


  function _safeSwapWavax (
      uint256 _amountIn,
      address[] memory _path,
      address _to
  ) internal {
      uint256[] memory amounts = ROUTER.getAmountsOut(_amountIn, _path);
      uint256 amountOut = amounts[amounts.length - 1 ];

      ROUTER.swapExactTokensForAVAX(
          _amountIn,
          (amountOut * slippageFactor  / 1000),
          _path,
          _to,
          block.timestamp
      );
  }

  function AutoLiquidity() external onlyOwner {
    uint256 usdtBalanceBefore = USDT.balanceOf(address(this));

    _safeSwapWavax(
          usdtBalanceBefore / 2,
          usdtToWavaxPath,
          address(this)
      );
    
    uint256 usdtBalanceAfter = USDT.balanceOf(address(this));
    uint256 wavaxBalance = address(this).balance;
    uint256 banksyBalance = BANKSY.balanceOf(address(this));
    uint256 halfTokenAmount = banksyBalance / 2;

    if (usdtBalanceAfter > 0 && wavaxBalance > 0 && banksyBalance > 0) {
        // add the liquidity banksy-avax
        ROUTER.addLiquidityAVAX{value: wavaxBalance}(
            address(BANKSY),
            halfTokenAmount,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        // add the liquidity banksy-usdt
        ROUTER.addLiquidity(
            address(BANKSY),
            address(USDT),
            halfTokenAmount,
            usdtBalanceAfter,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }
  }

  function _allowance() internal {
    USDT.approve(address(ROUTER), type(uint256).max);
    BANKSY.approve(address(ROUTER), type(uint256).max);
  }


}