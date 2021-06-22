/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.4.24;

// interface(介面): 定義方法的名稱、屬性及回傳值型別，但不實作，也不能定義變數；繼承此介面虛實做出所有方法
interface class37_Interface {
     function set(uint x)external;
     function get()external returns(uint);
}

contract class37 is class37_Interface{
    uint t = 0;
    
    function set(uint x)public{
        t = x;
    }

    function get()public view returns(uint){
        return t;
    }

    // 列舉
    enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }
    ActionChoices choice;

    function setGoStraight() public {
        choice = ActionChoices.GoStraight;
    }
    function getChoice() public view returns (ActionChoices) {
        return choice;
    }
}