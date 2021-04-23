/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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


contract TokenTimerLottery is Context {

 
    address private _winner;
    uint256 private _lastTimestamp;
    uint256 private _timeDifference;
    uint256 private _minAmount;
    uint256 private _lotteryAmount;
    uint256 private _multiple;
    mapping (address => uint256) private _inputAmount;
    IERC20 private _token;

   

    constructor(uint256 time, uint256 minAmount, uint256 multiple, IERC20 token) {
        
        _timeDifference = time * 60;
        _winner = _msgSender();
        _minAmount = minAmount;
        _multiple = multiple;
        _token = token;
    }


    function timeDifference() public view returns (uint256) {
        return _timeDifference;
    }
    
    function token() public view returns (IERC20) {
        return _token;
    }
    
    function currentWinner() public view returns (address) {
        return _winner;
    }
    
    
    function minAmount() public view returns (uint256) {
        return _minAmount;
    }
    
    function lotteryAmount() public view returns (uint256) {
         uint256 winningAmount = (_token.balanceOf(address(this)) < _inputAmount[_winner] * _multiple ? _token.balanceOf(address(this)): _inputAmount[_winner] * _multiple );
         return winningAmount;
    }
    
    function timeLeftToWinLottery() public view returns (uint256) {

        if ((_lastTimestamp + _timeDifference) <  block.timestamp) {
            
            return 0;
        } else {
        
        return (_lastTimestamp + _timeDifference - block.timestamp );
        }
    }

   
    function participate(uint256 amount) public {
        
        
          
        if (amount >= _minAmount) {
                
            if ((block.timestamp - _lastTimestamp) > _timeDifference) {
              
                uint256 winningAmount = (_token.balanceOf(address(this)) < _inputAmount[_winner] * _multiple ? _token.balanceOf(address(this)): _inputAmount[_winner] * _multiple );
                _token.transfer(_winner, winningAmount);
               
            }
        
            _winner = _msgSender();
            _inputAmount[_winner] = amount;
            _lastTimestamp = block.timestamp;
     
        }
        
        _token.transferFrom(_msgSender(), address(this), amount);
                
    
    }
    
}