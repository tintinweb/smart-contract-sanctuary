pragma solidity ^0.4.13;

contract DSAuth {

    function callTest(address _from, address _to, uint256 _amount, bytes _data, string _custom_fallback){
        _from.call.value(0)(bytes4(keccak256(_custom_fallback)), _from, _amount, _data);
    }
}