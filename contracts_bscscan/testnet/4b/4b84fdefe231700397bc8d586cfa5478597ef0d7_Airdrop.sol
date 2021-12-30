/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.3;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
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
}


contract Airdrop is Auth {

    address token = 0x98894BC466deC87d6a8F8B968E014996B02Ba85A;

    mapping (address => uint256) public holders;

    constructor () Auth(msg.sender) {

    }

    function deposit(uint256 amount) public onlyOwner {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    } 


    function claim(uint256 amount) public {
        require(holders[msg.sender] != 0,"You are not whitelisted");
        require((IERC20(token).balanceOf(address(this))) > amount, "Not enough balance, contact owner");
        IERC20(token).approve(address(this), amount);
        IERC20(token).transferFrom(address(this), msg.sender,  amount);
        holders[msg.sender] = 0;        

    } 

    function add_whitelist(address[] calldata _holders, uint256[] calldata amount) public authorized {
        for (uint i; i < _holders.length; ++i) {
            holders[_holders[i]] = amount[i];
        }

    }

    function change_token(address _token) public onlyOwner {
        token = _token;
    } 

    function clear_balance(address receiver) public onlyOwner {
        IERC20(token).approve(address(this), IERC20(token).balanceOf(address(this)));
        IERC20(token).transferFrom(address(this), receiver, IERC20(token).balanceOf(address(this)));
    }

}