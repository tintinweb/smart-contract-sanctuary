/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
/**
 *  ____        _       _     __  __      _
 * / ___|  __ _(_)_ __ | |_  |  \/  | ___| |_ __ ___   _____ _ __ ___  ___
 * \___ \ / _` | | '_ \| __| | |\/| |/ _ \ __/ _` \ \ / / _ \ '__/ __|/ _ \
 *  ___) | (_| | | | | | |_  | |  | |  __/ || (_| |\ V /  __/ |  \__ \  __/
 * |____/ \__,_|_|_| |_|\__| |_|  |_|\___|\__\__,_| \_/ \___|_|  |___/\___|
 *
 */
pragma solidity ^0.6.12;

library TransferHelper {

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

}

contract TransferTool {

    address private _owner;

    mapping (address => bool) private _allowList;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier isAllowList(address account) {
        require(_allowList[account], "Not allow");
        _;
    }

    constructor() public{
        address msgSender = _msgSender();
        _owner = msgSender;
        _allowList[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function addAllowList(address[] memory addr) public onlyOwner {
        for (uint i; i < addr.length - 1; i++) {
            require(addr[i] != address(0), "Ownable: account is the zero address");
            _allowList[addr[i]] = true;
        }
    }

    function removeAllowList(address[] memory addr) public onlyOwner {
        for (uint i; i < addr.length - 1; i++) {
            require(addr[i] != address(0), "Ownable: account is the zero address");
            _allowList[addr[i]] = false;
        }
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferEthsAvg(address[] memory _tos) payable isAllowList(msg.sender) public {
        require(_tos.length > 0);
        uint256 vv = address(this).balance / _tos.length;
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferETH(_tos[i], vv);
        }
    }

    function transferEths(address[] memory _tos, uint256[] memory values) payable isAllowList(msg.sender) public {
        require(_tos.length > 0 && _tos.length == values.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferETH(_tos[i], values[i]);
        }
    }

    function transferTokensAvg(address from, address tokenAddress, address[] memory _tos, uint256 v) isAllowList(msg.sender) public {
        require(_tos.length > 0);
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferFrom(tokenAddress, from, _tos[i], v);
        }
    }

    function transferTokens(address from, address tokenAddress, address[] memory _tos, uint256[] memory values) isAllowList(msg.sender) public {
        require(_tos.length > 0 && _tos.length == values.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferFrom(tokenAddress, from, _tos[i], values[i]);
        }
    }
    
}