/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

interface IUniswapV2Callee {
    
  function uniswapV2Call(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
  
}

contract TestFlashLoan is IUniswapV2Callee {
    
    // Max amount => 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    // Uniswap V2 factory
    address private constant FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    
    event IntLog(string message, uint val);
    event StrLog(string message, address val);
    
    function balanceOf(address _token, address _address) external view returns (uint) {
        return IERC20(_token).balanceOf(_address);
    }
    
    function allowance(address _token, address _owner, address _spender) external view returns (uint) {
        return IERC20(_token).allowance(_owner, _spender);
    }
    
    function approveForContract(address _token, address _spender, uint _amount) external {
        IERC20(_token).approve(_spender, _amount);
    }
    
    function transferBack(address _token, uint _amount) external {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
    }
    
    function step(uint _i) internal {
        emit IntLog("step", _i);
    }
    
    function StartFlashSwap(address _tokenBorrow, address[] memory _tokenBs, uint[] memory _amountsBorrow, uint _times) external {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenBorrow, _tokenBs[0]);
        require(pair != address(0), "!pair");
        
        uint amount0Out = _tokenBorrow == IUniswapV2Pair(pair).token0() ? _amountsBorrow[0] : 0;
        uint amount1Out = _tokenBorrow == IUniswapV2Pair(pair).token1() ? _amountsBorrow[0] : 0;
        
        // need to pass some data to trigger uniswapV2Call
        uint _i = 1;
        bytes memory data = abi.encode(_tokenBorrow, _tokenBs, _amountsBorrow, _times, _i);
        
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
    
    // called by pair contract
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
        require(_sender == address(this), "sender address != contract address");
        
        (address tokenBorrow, address[] memory tokenBs, uint[] memory amountsBorrow, uint times, uint i) = abi.decode(_data, (address, address[], uint[], uint, uint));
        uint amountBorrow = amountsBorrow[i - 1];
        
        // steps stuff
        if (i == 1) {
            step(i);
        } else if (i == 2) {
            step(i);
        } else if (i == 3) {
            step(i);
        } else if (i == 4) {
            step(i);
        } else if (i == 5) {
            step(i);
        } else if (i == 6) {
            step(i);
        } else if (i == 7) {
            step(i);
        } else if (i == 8) {
            step(i);
        }
        
        // check need flash loan again  or not
        if (i < times) {
            address pair = IUniswapV2Factory(FACTORY).getPair(tokenBorrow, tokenBs[i]);
            require(pair != address(0), "!pair");
            
            uint amount0Out = tokenBorrow == IUniswapV2Pair(pair).token0() ? amountsBorrow[i] : 0;
            uint amount1Out = tokenBorrow == IUniswapV2Pair(pair).token1() ? amountsBorrow[i] : 0;
            
            i = i + 1;
            bytes memory data = abi.encode(tokenBorrow, tokenBs, amountsBorrow, times, i);
            
            IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
        }
        
        // about 0.3%
        uint fee = ((amountBorrow * 3) / 997) + 1;
        
        // do stuff here
        emit IntLog("amount0", _amount0);
        emit IntLog("amount1", _amount1);
        emit IntLog("amount", amountBorrow);
        emit IntLog("fee", fee);
        emit IntLog("amount to repay", amountBorrow + fee);
        emit StrLog("tokenBorrow", tokenBorrow);
        
        IERC20(tokenBorrow).transfer(msg.sender, amountBorrow + fee);
    }
  
}