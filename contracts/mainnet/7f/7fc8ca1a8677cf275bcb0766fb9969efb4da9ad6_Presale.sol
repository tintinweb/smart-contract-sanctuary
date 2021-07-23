/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
}


contract Presale is Context, Ownable {
    using SafeMath for uint256;
    mapping(address => bool) private whitelisted;
    event PresalerSubmitted(address presaler);
    
    
    receive () external payable{
        require(msg.value == 200000000000000000);
        require(whitelisted[_msgSender()]);
        
        emit PresalerSubmitted(_msgSender()); //Listened to in the backend
    }
    
    function addToWhitelist(address user) public onlyOwner{
        require(!whitelisted[user]);
        whitelisted[user] = true;
    }
    
    
    function RemoveFromWhitelist(address user) public onlyOwner{
        require(whitelisted[user]);
        whitelisted[user] = false;
    }
    
    
    function exportETH() public onlyOwner{
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    
    
    
}