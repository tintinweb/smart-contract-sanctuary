pragma solidity >=0.4.22 <0.6.0;

contract fake {
    function hoge(address victim) public {
        victim.call(bytes4(sha3("deploy()")));
    }
    function fuga(address victim, bytes4 fun) public {
        victim.call(fun);
    }
}