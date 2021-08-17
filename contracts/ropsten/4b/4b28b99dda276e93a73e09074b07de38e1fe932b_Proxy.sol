/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity =0.8;

contract Proxy {
    
    function setCall(address _to, uint256 _value) public returns(bytes memory){
        (bool success, bytes memory result) = _to.call(abi.encodeWithSignature("set()",_value));
        if(success){
            return result;
            // return abi.decode(result, (bool));
        }else{
            revert();
        }
    }
    
    function setDelegateCall(address _to, uint256 _value) public returns(bytes memory){
        (bool success, bytes memory result) = _to.call(abi.encodeWithSignature("set()",_value));
        if(success){
            return result;
            // return abi.decode(result, (bool));
        }else{
            revert();
        }
    }
}