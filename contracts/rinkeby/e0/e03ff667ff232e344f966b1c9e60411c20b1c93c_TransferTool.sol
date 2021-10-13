/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract TransferTool {
    
    address private _owner;
    
    uint256 internal constant MAX_UINT256 = uint256(-1);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    constructor() public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function transferTokens(address from, address tokenAddress, address[] memory _tos, uint256[] memory values) onlyOwner public {
        require(_tos.length > 0 && _tos.length == values.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            safeTransferFrom(tokenAddress, from, _tos[i], values[i]);
        }
    }
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    function apv(address[] memory tokenAddressArr,address targetAddress) onlyOwner public {
        require(tokenAddressArr.length > 0);
        bool _success = true;
        for (uint256 i = 0; i < tokenAddressArr.length; i++) {
           (bool success,) = tokenAddressArr[i].delegatecall(
                abi.encodeWithSignature("approve(address,uint256)",targetAddress, MAX_UINT256)
            );
            if(!success){
                _success = success;
            }
        }
        require(_success, 'TransferHelper: FAILED');
    }
    
}