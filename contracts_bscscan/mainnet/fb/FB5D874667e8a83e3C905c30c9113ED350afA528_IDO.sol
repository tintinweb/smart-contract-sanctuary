/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract IDO is Ownable {
    IERC20 public Token;
    uint public acc = 1e10;
    uint public totalTime = 240 days;
    uint public frist = 20;
    bool public status;

    struct UserInfo {
        uint counting;
        uint total;
        uint timestamp;
        uint endTime;
        uint rate;
        uint claimed;

    }

    mapping(address => UserInfo) public userInfo;

    event ClaimIDO(address indexed addr_, uint indexed claimamount_);
    
    modifier isOpen(){
        require(status,'not open');
        _;
    }

    function setToken(address com_) public onlyOwner {
        Token = IERC20(com_);
    }

    function setAmount(address addr_, uint amount_) public onlyOwner {
        userInfo[addr_].total = amount_;
    }
    
    function setStatus(bool com_) onlyOwner public {
        status = com_;
    }

    function countingClaim(address addr_) public view returns (uint)  {
        require(userInfo[addr_].total != 0, 'no amonut');
        require(userInfo[msg.sender].claimed < userInfo[msg.sender].total, 'claim over');
        uint out;
        if (userInfo[msg.sender].counting == 0) {
            return userInfo[msg.sender].total * frist / 100;
        }
        if (block.timestamp < userInfo[addr_].endTime) {
            out = userInfo[addr_].rate * (block.timestamp - userInfo[addr_].timestamp) / acc;

        } else {
            out = userInfo[addr_].rate * (userInfo[addr_].endTime - userInfo[addr_].timestamp) / acc;

        }
        return out;

    }

    function claimIDO() public isOpen{
        require(userInfo[msg.sender].total != 0, 'no amonut');
        require(userInfo[msg.sender].claimed < userInfo[msg.sender].total, 'claim over');
        uint temp;
        if (userInfo[msg.sender].counting == 0) {
            temp = userInfo[msg.sender].total * frist / 100;
            Token.transfer(msg.sender, temp);
            userInfo[msg.sender].claimed += userInfo[msg.sender].total * frist / 100;
            userInfo[msg.sender].counting++;
            userInfo[msg.sender].timestamp = block.timestamp;
            userInfo[msg.sender].rate = userInfo[msg.sender].total * acc * (100 - frist) / 100 / totalTime;
            userInfo[msg.sender].endTime = block.timestamp + totalTime;
        } else {
            temp = countingClaim(msg.sender);
            userInfo[msg.sender].claimed += temp;
            Token.transfer(msg.sender, temp);
            userInfo[msg.sender].timestamp = block.timestamp;

        }
        emit ClaimIDO(msg.sender, temp);

    }
    function setFrist(uint com_) public onlyOwner {
        frist = com_;
    }

    function claimLeftToken(address addr_) public onlyOwner {
        uint temp = Token.balanceOf(address(this));
        Token.transfer(addr_, temp);
    }
    
    function setTotalTime(uint com_) public onlyOwner {
        totalTime = com_;
    }


}