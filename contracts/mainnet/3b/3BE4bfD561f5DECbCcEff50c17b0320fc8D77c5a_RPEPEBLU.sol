// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
//////// THIS IS THE RPEPEBLU POOL OF rPEPE STAKING - rPepe Token Staking //////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Context.sol";

interface IPEPE {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract RPEPEBLU is Context {
    using SafeMath for uint256;
    
    // Contract state variables
    address private _RarePepeV2;
    uint256 private _totalStakedAmount;
    mapping(address => uint256) private _stakedAmount;
    address[] private _stakers;

    // Events
    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);
    
    constructor(address RarePepeV2) public {
        _RarePepeV2 = RarePepeV2;
    }
    
    /**
     * @dev API to stake rPEPE tokens
     *
     * @param amount: Amount of tokens to deposit
     */
    function stake(uint256 amount) external {
        require(amount > 0, "Staking amount must be more than zero");
        // Transfer tokens from staker to the contract amount
        require(IPEPE(_RarePepeV2).transferFrom(_msgSender(), address(this), amount), "It has failed to transfer tokens from staker to contract.");
        // add staker to array
        if (_stakedAmount[_msgSender()] == 0) {
            _stakers.push(_msgSender());
        }
        // considering the burning 2.5%
        uint256 burnedAmount = amount.ceil(100).mul(100).div(4000);
        uint256 realStakedAmount = amount.sub(burnedAmount);
        // Increase the total staked amount
        _totalStakedAmount = _totalStakedAmount.add(realStakedAmount);
        // Add staked amount
        _stakedAmount[_msgSender()] = _stakedAmount[_msgSender()].add(realStakedAmount);
        emit Staked(_msgSender(), realStakedAmount);
    }

    /**
     * @dev API to unstake staked rPEPE tokens
     *
     * @param amount: Amount of tokens to unstake
     *
     * requirements:
     *
     * - Must not be consider the burning amount
     */
    function unstake(uint256 amount) public {
        require(_stakedAmount[_msgSender()] > 0, "No running stake.");
        require(amount > 0, "Unstaking amount must be more than zero.");
        require(_stakedAmount[_msgSender()] >= amount, "Staked amount must be ustaking amount or more.");
        // Transfer tokens from contract amount to staker
        require(IPEPE(_RarePepeV2).transfer(_msgSender(), amount), "It has failed to transfer tokens from contract to staker.");
        // Decrease the total staked amount
        _totalStakedAmount = _totalStakedAmount.sub(amount);
        // Decrease the staker's staked amount
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
     * @dev API to get the total staked amount of all stakers
     */
    function getTotalStakedAmount() external view returns (uint256) {
        return _totalStakedAmount;
    }

    /**
     * @dev API to get the staker's staked amount
     */
    function getStakedAmount(address account) external view returns (uint256) {
        return _stakedAmount[account];
    }

    /**
     * @dev API to get the staker's array
     */
    function getStakers() external view returns (address[] memory) {
        return _stakers;
    }
}