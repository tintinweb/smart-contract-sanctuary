/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: MockFarm.sol

/**
 * @dev
 */
contract MockDiFi {

    // trade
    event Swap(address indexed user, uint256 amount);

    // stake
    event StakeIn(address indexed user, uint256 amount);
    event StakeOut(address indexed user, uint256 amount);

    // farm
    event Deposit(address indexed user, uint256 pool, uint256 amount);
    event Withdraw(address indexed user, uint256 pool, uint256 amount);

    function trade(address _user, uint256 _amount) external {
        emit Swap(_user, _amount);
    }

    function stakeIn(address _user, uint256 _amount) external {
        emit StakeIn(_user, _amount);
    }

    function stakeOut(address _user, uint256 _amount) external {
        emit StakeOut(_user, _amount);
    }

    function deposit(uint256 _pool, address _user, uint256 _amount) external {
        emit Deposit(_user, _pool, _amount);
    }

    function withdraw(uint256 _pool, address _user, uint256 _amount) external {
        emit Withdraw(_user, _pool, _amount);
    }

}