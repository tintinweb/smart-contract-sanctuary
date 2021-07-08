/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.8;

contract TEST {
    uint256 public a = 1;
    
    uint256 public b = 0;
    
    event test(uint256 _a,uint256 _b);
    
    function request(
   
    ) public {
        a += 1;
        b = 5;
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    //     require(value != 0, "ddd");
    //     (bool success, bytes memory data) = address(0x3D348C0fe5e6e8f62C1276FF1764CAa35ce22458).call(
    //         abi.encodeWithSelector(0x23b872dd, from, to, value)
    //     );
    //     require(
    //         success && (data.length == 0 || abi.decode(data, (bool))),
    //         "TransferHelper: TRANSFER_FROM_FAILED"
    //     );
    emit test(a,b);
    }
}