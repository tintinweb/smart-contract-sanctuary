/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: NONE
/** 
 * ver 1.7.12
 * telegram
 * Community
 * https://t.me/fruitsadventures_com
 * 
 * FruitsAdventures News & Announcements
 * https://t.me/fruitsadventures
 * 
 * twitter
 * https://twitter.com/FruitsAdventure
 *
 * medium
 * https://fruitsadventures.medium.com
*/

pragma solidity =0.8.4;



contract Context { 
    constructor()  {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} 
contract PartnerOwnable is Context {
    address private _owner;
    address private _admin;
    address private _partner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PartnerTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        _admin = msgSender;
        _partner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function owner_admin() public view returns (address) {
        return _admin;
    }
    function owner_partner() public view returns (address) {
        return _partner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyAdmin() {
        require(_owner == _msgSender() || _admin == _msgSender() , 'Ownable: caller is not the partner');
        _;
    }
    modifier onlyPartner() {
        require(_owner == _msgSender() || _admin == _msgSender() || _partner == _msgSender(), 'Ownable: caller is not the partner');
        _;
    }
    function transferPartner(address newOwner) public onlyPartner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit PartnerTransferred(_partner, newOwner);
        _partner = newOwner;
    }
    function transferAdmin(address newOwner) public onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit PartnerTransferred(_admin, newOwner);
        _admin = newOwner;
    }
    function transferOwnership(address newOwner) public onlyOwner { 
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


contract ifContract is Context, PartnerOwnable  { 
    constructor()   { }
 
    function isContract(address addr) public view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
    
    
    
}