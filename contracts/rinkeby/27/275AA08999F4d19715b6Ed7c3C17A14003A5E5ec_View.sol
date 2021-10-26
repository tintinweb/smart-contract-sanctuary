// SPDX-License-Identifier: GPL-3.0

// Created by HolaNext
// Portions Contract

pragma solidity ^0.8.0;
import "./test.sol";

contract View{
    address public inter;
    bool public isSet;

    function setAddress(address _address) external{
        inter = _address;
        isSet = true;
    }
    function callCounter() external returns(uint){
        require(isSet);
        ITest instance = ITest(inter);
        return instance.counter();
    }

}

// SPDX-License-Identifier: GPL-3.0

// Created by HolaNext
// Portions Contract

pragma solidity ^0.8.0;

interface ITest{
    function counter() external returns(uint);
}

contract Test{

    uint public counter;
    
    function Increase() public{
        counter +=1;
    }
}