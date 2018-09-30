pragma solidity ^0.4.0;
contract One{
    uint a=100;
    function get()returns(uint){
        return a;
    }
}
contract Two{
    event _e(uint);
    function get(){
        One one=new One();
        _e(one.get());
    }
}