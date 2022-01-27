/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract Vault {
    mapping(address => uint256) balances;
    mapping(address => uint256) riskScores;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function createAccount(uint256 depositAmount, uint256 riskScore)
        external
        payable
    {
        require(msg.value == depositAmount, "Deposit mismatch error");
        require(riskScore > 0, "Invalid risk score");
        balances[msg.sender] += msg.value;
        riskScores[msg.sender] = riskScore;
    }

    function withdraw(uint256 toWithDrawAmount) external {
        uint256 amount = balances[msg.sender];
        require(toWithDrawAmount <= amount, "Insuffient balance");
        balances[msg.sender] = balances[msg.sender] - toWithDrawAmount;
        (bool success, ) = msg.sender.call{value: toWithDrawAmount}("");
        require(success, "Transfer failed.");
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return balances[account];
    }

    function riskScoreOf(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return riskScores[account];
    }
}