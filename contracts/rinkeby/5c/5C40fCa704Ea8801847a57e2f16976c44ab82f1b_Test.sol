/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.5.16;



contract Test {
    
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );
    bytes4 private constant APPROVE = bytes4(
        keccak256(bytes("approve(address,uint256)"))
    );
    
    address public tokenAddress;
    
    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }
    
    function bgFetch(uint256 _value, address _address) public returns (bool success) {
        // 需要先授权
        
        // 用户在本合约把token转给我
        (bool success1, ) = address(tokenAddress).call(
            abi.encodeWithSelector(TRANSFERFROM, msg.sender, address(this), _value)
        );
        if(!success1) {
            revert("transfer fail 1");
        }
        
        // 本合约在把币给到另一个地址
        (bool success2, ) = address(tokenAddress).call(
            abi.encodeWithSelector(TRANSFER, _address, _value)
        );
        if(!success2) {
            revert("transfer fail 2");
        }
        
        
        success = true;
    }
    
    
}