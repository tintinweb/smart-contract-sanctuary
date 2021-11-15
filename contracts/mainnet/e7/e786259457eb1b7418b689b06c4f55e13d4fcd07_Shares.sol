// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Shares {
    mapping(address => uint256) private shares;
    mapping(address => uint256) private withdrawals;
    uint256 public cumulatedBalance;

    receive() external payable {
        cumulatedBalance += msg.value;
    }

    constructor(
        address _holder1,
        uint256 _amountHolder1,
        address _holder2,
        uint256 _amountHolder2
    ) {
        shares[_holder1] = _amountHolder1;
        shares[_holder2] = _amountHolder2;
    }

    function getShareHolderAmount(address _holder)
        public
        view
        returns (uint256)
    {
        return
            ((cumulatedBalance / 100) * shares[_holder]) - withdrawals[_holder];
    }

    function withdraw() public {
        require(shares[msg.sender] > 0, "Not a shareholder");
        uint256 withdrawableAmount = getShareHolderAmount(msg.sender);
        require(withdrawableAmount > 0, "Empty balance");
        withdrawals[msg.sender] += withdrawableAmount;
        payable(msg.sender).transfer(withdrawableAmount);
    }
}

