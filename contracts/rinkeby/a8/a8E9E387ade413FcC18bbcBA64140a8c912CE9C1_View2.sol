// SPDX-License-Identifier: GPL-3.0

// Created by HolaNext
// Portions Contract

pragma solidity ^0.8.0;
import "./test.sol";

contract View2{
    address public inter;
    bool public isSet;

    function setAddress(address _address) external{
        inter = _address;
        isSet = true;
    }
    function callCounter() external returns(uint){
        require(isSet);
        ITest2 instance = ITest2(inter);
        return instance.counter();
    }

}

// SPDX-License-Identifier: GPL-3.0

// Created by HolaNext
// Portions Contract

pragma solidity ^0.8.0;

interface ITest2{
    function counter() external returns(uint);
}

contract Test2{

    uint public counter;

    function Increase() public{
        counter +=1;
    }
}