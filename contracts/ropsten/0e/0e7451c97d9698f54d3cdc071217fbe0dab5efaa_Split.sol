pragma solidity ^0.4.24;
contract Split {
    address public constant MY_ADDRESS = 0xcE01a664b35105de0679A74f7cDbA9EA2b9870Fa;
    address public constant BRO_ADDRESS = 0xca192567a1332A0Ad54f0Bb2874e66bF9Bd17c48;

    function () external payable {
        if (msg.value > 0) {
            // msg.value - received ethers
            MY_ADDRESS.transfer(msg.value / 2);
            // address(this).balance - contract balance after transaction to MY_ADDRESS (half of received ethers)  
            BRO_ADDRESS.transfer(address(this).balance);
        }
    }
}