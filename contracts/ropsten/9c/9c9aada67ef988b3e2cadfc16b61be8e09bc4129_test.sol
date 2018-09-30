pragma solidity ^0.4.24;

contract test {
    event INFO(bytes _msgPack);
    function info(bytes _msgPack) public {
        emit INFO(_msgPack);
    }
}