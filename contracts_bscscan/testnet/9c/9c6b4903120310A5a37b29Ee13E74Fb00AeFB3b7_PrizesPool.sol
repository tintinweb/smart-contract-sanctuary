/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.7;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

contract Ownable {
    address owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
    }
}

contract PrizesPool is Ownable {
    mapping(address => bool) public authorisedAddrs;

    function payPrize(address _token_addr, address _to_addr, uint _amount) public returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_to_addr != address(0), "address is null");
        require(authorisedAddrs[msg.sender] == true, "not authorised address");
        ERC20 token = ERC20(_token_addr);
        token.transfer(_to_addr, _amount);
        return true;
    }

    function sys_set_authorised_addr(address _authorised_addr, bool _allow) public onlyOwner returns(bool) {
        require(_authorised_addr != address(0), "address is null");
        authorisedAddrs[_authorised_addr] = _allow;
        return true;
    }

    function sys_transfer_token(address _token_addr, address _receive_addr) public onlyOwner returns(bool) {
        require(_token_addr != address(0), "address is null");
        require(_receive_addr != address(0), "address is null");

        ERC20 token = ERC20(_token_addr);
        token.transfer(_receive_addr, token.balanceOf(address(this)));
        return true;
    }
}