/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

contract Treasury is Auth {
    constructor() Auth(msg.sender) {
    }

    receive() external payable {
    }

    function retrieveAllBNB() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success,) = payable(msg.sender).call{ value: balance }("");
        require(success, "Failed");
    }

    function retrieveAllTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));

        require(IERC20(token).transfer(msg.sender, balance), "Transfer failed");
    }

    function claimBNB(uint256 amount, address receiver) external onlyOwner {
        uint256 balance = address(this).balance;

        if(amount > balance){
            amount = balance;
        }

        (bool success,) = payable(receiver).call{ value: amount }("");
        require(success, "Failed");
    }

    function claimTokens(address token, uint256 amount, address receiver) external authorized {
        uint256 balance = IERC20(token).balanceOf(address(this));

        if(amount > balance){
            amount = balance;
        }

        require(IERC20(token).transfer(receiver, amount), "Transfer failed");
    }
}