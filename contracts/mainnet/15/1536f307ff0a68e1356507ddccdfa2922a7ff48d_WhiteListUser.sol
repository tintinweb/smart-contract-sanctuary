pragma solidity ^0.4.11;

contract I_WhiteList {
    function contains(address) public returns(bool);
}

contract WhiteListUser {

    function assert(I_WhiteList whiteList, address addr) external {
      assert (whiteList.contains(addr));
    }

}