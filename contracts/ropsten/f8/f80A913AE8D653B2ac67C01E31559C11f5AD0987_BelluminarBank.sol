/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity ^0.4.23;

contract BelluminarBank {
    struct Investment {
        uint256 amount;
        uint256 deposit_term;
        address owner;
    }
    //全局变量
    Investment[] balances;
    uint256 head;
    address private owner;
    bytes16 private secret;  //secret可读取

    function BelluminarBank(bytes16 _secret, uint256 deposit_term) public payable {
        secret = _secret;
        owner = msg.sender;
        if(msg.value > 0) {
            balances.push(Investment(msg.value, deposit_term, msg.sender));
        }
    }

    function bankBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //局部变量覆盖全局变量
    function invest(uint256 account, uint256 deposit_term) public payable {
        if (account >= head && account < balances.length) {
            Investment storage investment = balances[account];
            investment.amount += msg.value;
        } else {
            if(balances.length > 0) {
            //存在整数溢出
                require(deposit_term >= balances[balances.length - 1].deposit_term + 1 years);
            }
            //局部变量
            investment.amount = msg.value;
            investment.deposit_term = deposit_term;
            investment.owner = msg.sender;
            balances.push(investment);
        }
    }

    function withdraw(uint256 account) public {
        require(now >= balances[account].deposit_term);
        require(msg.sender == balances[account].owner);

        msg.sender.transfer(balances[account].amount);
    }

    function confiscate(uint256 account, bytes16 _secret) public {
        require(msg.sender == owner);
        require(secret == _secret);
        require(now >= balances[account].deposit_term + 1 years);

        uint256 total = 0;
        for (uint256 i = head; i <= account; i++) {
            total += balances[i].amount;
            delete balances[i];
        }
        head = account + 1;
        msg.sender.transfer(total);
    }
}