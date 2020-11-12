// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
//////// THIS IS THE RPEPE.LPURPLE POOL OF LP STAKING - rPepe Token Staking ////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Context.sol";

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function transfer(address recipient, uint amount) external returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract RPEPELPURPLE is Context {
    using SafeMath for uint256;
    
    // Contract state variables
    address private _UniswapV2Pair;
    uint256 private _totalStakedAmount;
    mapping(address => uint256) private _stakedAmount;
    address[] private _stakers;

    // Events
    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);
    
    constructor(address UniswapV2Pair) public {
        _UniswapV2Pair = UniswapV2Pair;
    }
    
    /**
     * @dev Stake rPEPE-ETH LP tokens
     *
     * Requirement
     *
     * - In this pool, don't care about 2.5% fee for stake/unstake
     *
     * @param amount: Amount of LP tokens to deposit
     */
    function stake(uint256 amount) public {
        require(amount > 0, "Staking amount must be more than zero");
        // Transfer tokens from staker to the contract amount
        require(IUniswapV2Pair(_UniswapV2Pair).transferFrom(_msgSender(), address(this), uint(amount)), "It has failed to transfer tokens from staker to contract.");
        // add staker to array
        if (_stakedAmount[_msgSender()] == 0) {
            _stakers.push(_msgSender());
        }
        // Increase the total staked amount
        _totalStakedAmount = _totalStakedAmount.add(amount);
        // Add new stake amount
        _stakedAmount[_msgSender()] = _stakedAmount[_msgSender()].add(amount);
        emit Staked(_msgSender(), amount);
    }

    /**
     * @dev Unstake staked rPEPE-ETH LP tokens
     * 
     * Requirement
     *
     * - In this pool, don't care about 2.5% fee for stake/unstake
     *
     * @param amount: Amount of LP tokens to unstake
     */
    function unstake(uint256 amount) public {
        // Transfer tokens from contract amount to staker
        require(IUniswapV2Pair(_UniswapV2Pair).transfer(_msgSender(), uint(amount)), "It has failed to transfer tokens from contract to staker.");
        // Decrease the total staked amount
        _totalStakedAmount = _totalStakedAmount.sub(amount);
        // Decrease the staker's amount
        _stakedAmount[_msgSender()] = _stakedAmount[_msgSender()].sub(amount);
        // remove staker from array
        if (_stakedAmount[_msgSender()] == 0) {
            for (uint256 i=0; i < _stakers.length; i++) {
                if (_stakers[i] == _msgSender()) {
                    _stakers[i] = _stakers[_stakers.length.sub(1)];
                    _stakers.pop();
                    break;
                }
            }
        }
        emit Unstaked(_msgSender(), amount);
    }
    
    /**
     * @dev API to get the total staked LP amount of all stakers
     */
    function getTotalStakedLPAmount() external view returns (uint256) {
        return _totalStakedAmount;
    }

    /**
     * @dev API to get the staker's staked LP amount
     */
    function getStakedLPAmount(address account) external view returns (uint256) {
        return _stakedAmount[account];
    }

    /**
     * @dev API to get the total staked rPEPE amount of all stakers
     */
    function getTotalStakedAmount() external view returns (uint256) {
        return _getStakedPepeAmount(_totalStakedAmount);
    }

    /**
     * @dev API to get the staker's staked rPEPE amount
     */
    function getStakedAmount(address account) external view returns (uint256) {
        return _getStakedPepeAmount(_stakedAmount[account]);
    }

    /**
     * @dev API to get the staker's array
     */
    function getStakers() external view returns (address[] memory) {
        return _stakers;
    }

    /**
     * @dev count and return pepe amount from lp token amount in uniswap v2 pool
     * 
     * Formula
     * 
     * - rPEPE = (staked LP / total LP in uniswap pool) * rPEPE in uniswap pool
     */
    function _getStakedPepeAmount(uint256 amount) internal view returns (uint256)  {
        (uint112 pepeAmount,,) = IUniswapV2Pair(_UniswapV2Pair).getReserves();
        // get the total amount of LP token in uniswap v2 pool
        uint totalAmount = IUniswapV2Pair(_UniswapV2Pair).totalSupply();
        return amount.mul(uint256(pepeAmount)).div(uint256(totalAmount));
    }
}