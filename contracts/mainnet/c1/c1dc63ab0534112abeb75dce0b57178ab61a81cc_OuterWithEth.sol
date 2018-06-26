pragma solidity ^0.4.24;

contract OuterWithEth {
    Inner1WithEth public myInner1 = new Inner1WithEth();
    
    function callSomeFunctionViaOuter() public payable {
        myInner1.callSomeFunctionViaInner1.value(msg.value)();
    }
}

contract Inner1WithEth {
    Inner2WithEth public myInner2 = new Inner2WithEth();
    
    function callSomeFunctionViaInner1() public payable{
        myInner2.callSomeFunctionViaInner2.value(msg.value)();
    }
}

contract Inner2WithEth {
    Inner3WithEth public myInner3 = new Inner3WithEth();
    
    function callSomeFunctionViaInner2() public payable{
        myInner3.callSomeFunctionViaInner3.value(msg.value)();
    }
}

contract Inner3WithEth {
    Inner4WithEth public myInner4 = new Inner4WithEth();
    
    function callSomeFunctionViaInner3() public payable{
        myInner4.doSomething.value(msg.value)();
    }
}

contract Inner4WithEth {
    uint256 someValue;
    event SetValue(uint256 val);
    
    function doSomething() public payable {
        someValue = block.timestamp;
        emit SetValue(someValue);
    }
    
    function getAllMoneyOut() public {
        msg.sender.transfer(this.balance);
    }
}