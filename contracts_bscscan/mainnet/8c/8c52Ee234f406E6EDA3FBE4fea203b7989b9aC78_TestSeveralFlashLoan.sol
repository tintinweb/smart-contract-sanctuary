/**
 *Submitted for verification at BscScan.com on 2021-07-23
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

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IPancakeCallee {
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract TestSeveralFlashLoan is IPancakeCallee {
    
    address private constant FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    
    address public owner;
    // Max amount => 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    
    event IntLog(string message, uint val);
    event StrLog(string message, address val);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    
    function approveForContract(address _token, address _spender, uint _amount) external ownerOnly {
        IERC20(_token).approve(_spender, _amount);
    }
    
    function balanceOf(address _token, address _address) external view returns (uint) {
        return IERC20(_token).balanceOf(_address);
    }
    
    function allowance(address _token, address _owner, address _spender) external view returns (uint) {
        return IERC20(_token).allowance(_owner, _spender);
    }
    
    function transferBack(address _token, uint _amount) public ownerOnly {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
    }
    
    function TestFlashSwap(address[2] memory _pairA, address[2] memory _pairB, uint _pairA_amountBorrow, uint _pairB_amountBorrow) external ownerOnly {
        address pairA = IPancakeFactory(FACTORY).getPair(_pairA[0], _pairA[1]);
        address pairB = IPancakeFactory(FACTORY).getPair(_pairB[0], _pairB[1]);
        require(pairA != address(0), "!pairA");
        require(pairB != address(0), "!pairB");
        
        // need to pass some data to trigger pancakeCall
        bytes memory dataA = abi.encode(_pairA[0], _pairA_amountBorrow);
        bytes memory dataB = abi.encode(_pairB[0], _pairB_amountBorrow);
        
        IPancakePair(pairA).swap(_pairA_amountBorrow, 0, address(this), dataA);
        IPancakePair(pairB).swap(_pairB_amountBorrow, 0, address(this), dataB);
        
        uint feeA = ((_pairA_amountBorrow * 3) / 997) + 1;
        uint feeB = ((_pairB_amountBorrow * 3) / 997) + 1;
        
        IERC20(_pairA[0]).transfer(pairA, _pairA_amountBorrow + feeA);
        IERC20(_pairB[0]).transfer(pairB, _pairB_amountBorrow + feeB);
    }
    
    function pancakeCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
        address token0 = IPancakePair(msg.sender).token0();
        address token1 = IPancakePair(msg.sender).token1();
        address pair = IPancakeFactory(FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "msg sender address != pair address");
        require(_sender == address(this), "sender address != contract address");
        
        (address tokenBorrow, uint amountBorrow) = abi.decode(_data, (address, uint));
        
        // about 0.3%
        uint fee = ((amountBorrow * 3) / 997) + 1;
        
        // do stuff here
        emit StrLog("tokenBorrow", tokenBorrow);
        emit IntLog("amount0", _amount0);
        emit StrLog("token0", token0);
        emit IntLog("amount1", _amount1);
        emit StrLog("token1", token1);
        emit StrLog("pair", pair);
        emit IntLog("amount", amountBorrow);
        emit IntLog("fee", fee);
        emit IntLog("amount to repay", amountBorrow + fee);
        
        // IERC20(tokenBorrow).transfer(pair, amountBorrow + fee);
    }
    
}