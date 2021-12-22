/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Dojo is Context, Ownable{
    using Address for address payable;

    address private _addr1;
    address private _addr2;
    address private _addr3;
    uint256 private fee1;
    uint256 private fee2;
    uint256 private fee3;

    constructor( address addr1, address addr2, address addr3){
        _addr1 = addr1;
        _addr2 = addr2;
        _addr3 = addr3;
    }

    receive() external payable {
    }

    function forwardFunds() internal {
        uint256 BNBbalance = address(this).balance;
        uint256 firstPart = BNBbalance  * fee1 / 100;
        uint256 secondPart = BNBbalance * fee2 / 100;
        uint256 thirdPart = BNBbalance * fee3 / 100;
        if(firstPart > 0) payable(_addr1).sendValue(firstPart);
        if(secondPart > 0) payable(_addr2).sendValue(secondPart);
        if(thirdPart > 0) payable(_addr3).sendValue(thirdPart);
    }

    function forceForwardFunds() external {
        forwardFunds();
    }

    function setWallets(address addr1, address addr2, address addr3) external onlyOwner{
        _addr1 = addr1;
        _addr2 = addr2;
        _addr3 = addr3;
    }
    
    function setFees(uint256 _fee1, uint256 _fee2, uint256 _fee3) external onlyOwner{
        fee1 = _fee1;
        fee2 = _fee2;
        fee3 = _fee3;
    }

    function rescueTokensWronglySent(IERC20 tokenAddress) external onlyOwner{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(owner(), tokenAmt);
    }
}