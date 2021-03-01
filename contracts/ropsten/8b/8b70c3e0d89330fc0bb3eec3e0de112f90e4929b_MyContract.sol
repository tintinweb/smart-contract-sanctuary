/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.5.0;

contract Contract {

    MyContract contract1 = new MyContract();

    function getSelector() public view returns (bytes4, bytes4) {
        return (contract1.function1.selector, contract1.getBalance.selector);
    }

    function callGetValue(uint _x) public view returns (uint) {

        bytes4 selector = contract1.getValue.selector;

        bytes memory data = abi.encodeWithSelector(selector, _x);
        (bool success, bytes memory returnedData) = address(contract1).staticcall(data);
        require(success);

        return abi.decode(returnedData, (uint256));
    }
}

contract MyContract {

    function function1() public {}

    function getBalance(address _address) public view returns (uint256){}

    function getValue (uint _value) public pure returns (uint) {
        return _value;
    }

}