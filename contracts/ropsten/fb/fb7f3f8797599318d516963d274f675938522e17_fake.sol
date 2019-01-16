pragma solidity >=0.4.22 <0.6.0;

contract fake {
    function hoge(address victim) public {
        victim.call(bytes4(sha3("deploy()")));
    }
}