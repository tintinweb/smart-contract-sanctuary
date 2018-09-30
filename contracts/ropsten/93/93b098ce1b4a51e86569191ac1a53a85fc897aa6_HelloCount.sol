pragma solidity ^0.4.25;

contract HelloCount {
    address owner;
    string message;
    uint public count;
    event DidCountUp(uint currentCount, address sender);
    event DidCountDown(uint currentCount, address sender);
    
    constructor ()
        public
    {
        owner = msg.sender;
        message = "hello!";
    }
    
    function hello() 
        public
        view
        returns(string)
    {
        return message;
    }
    
    function getCount()
        public
        view
        returns(uint)
    {
        return count;
    }
    
    function countUp()
        public
    {
        count += 1;
        emit DidCountUp(count, msg.sender);
    }
    
    function countDown()
        public
    {
        count -= 1;
        emit DidCountDown(count, msg.sender);
    }
    
    function destroy() 
        public
    {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

}