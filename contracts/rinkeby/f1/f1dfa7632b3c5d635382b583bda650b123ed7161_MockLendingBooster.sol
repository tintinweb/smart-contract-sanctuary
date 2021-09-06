/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

contract MockLendingBooster {
    event LockToken(uint256 pid, address sender, uint256 amount);
    event UnLockToken(uint256 pid, address sender, uint256 amount);
    event UnLockTokenErc20(
        uint256 pid,
        address sender,
        uint256 amount,
        uint256 repayAmount
    );

    function checkPool(uint256 _pid) public view returns (bool) {
        return true;
    }

    function lockToken(
        uint256 _pid,
        address _sender,
        uint256 _amount
    ) external returns (bool) {
        emit LockToken(_pid, _sender, _amount);

        return true;
    }

    function unLockToken(
        uint256 _pid,
        address _sender,
        uint256 _amount
    ) external payable {
        emit UnLockToken(_pid, _sender, _amount);
    }

    function unLockTokenErc20(
        uint256 _pid,
        address _sender,
        uint256 _unlockAmount,
        uint256 _repayAmount
    ) external {
        emit UnLockTokenErc20(_pid, _sender, _unlockAmount, _repayAmount);
    }

    function totalSupplyOf(uint256 _pid) public view returns (uint256) {
        return 10000000 * 1e18;
    }
}