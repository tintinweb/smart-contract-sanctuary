/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

pragma solidity 0.6.12;

contract timelock {

    address usdc = 0x48C1be647204eb97BC5C6914e5D60E7A7b7b398B;
    bool public _success = false;

    function test(uint value, string memory signature, bytes memory data) external {
        bytes memory callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);


        (bool success, bytes memory returnData) = usdc.call.value(value)(callData);
        _success = success;
    }
    
    function getdata() public view returns(bytes memory){
        return(abi.encode(0xC189Ca9C9168004B3c0eED5409c15A88B87a0702,1000));
    }
}