// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Contributions {
    address payable public contributionAddress = payable(0x30f47deeB98a3C3bF84dF9e720b8463C0867C47f);

    uint256 public weiRaised;
    mapping(address => uint256) public balances;

    event Contribution(address from, uint value);

    receive() external payable {
        _buyTokens(msg.sender);
    }

    function _buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        weiRaised += weiAmount;
        balances[_beneficiary] += weiAmount;

        emit Contribution(msg.sender, weiAmount);
        contributionAddress.transfer(msg.value);
    }

    function contribution(address _wallet) public view returns (uint256) {
        return balances[_wallet];
    }
}