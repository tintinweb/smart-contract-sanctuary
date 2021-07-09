/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.8;

contract TEST {
    // bytes public a = 1;
    // string public 
    
    // string public b;
    
    event test(bytes);
    
    function request(
        string memory _b   
    ) public {
        // a += 1;
        // b = _b;
        
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    //     require(value != 0, "ddd");
    //     (bool success, bytes memory data) = address(0x3D348C0fe5e6e8f62C1276FF1764CAa35ce22458).call(
    //         abi.encodeWithSelector(0x23b872dd, from, to, value)
    //     );
    //     require(
    //         success && (data.length == 0 || abi.decode(data, (bool))),
    //         "TransferHelper: TRANSFER_FROM_FAILED"
    //     );
    emit test(bytes(_b));
    }
}