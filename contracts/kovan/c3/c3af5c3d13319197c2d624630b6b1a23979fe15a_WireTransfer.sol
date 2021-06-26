/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface DaiToken {
    function balanceOf(address _addr) external view returns (uint256);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);

    function approve(address usr, uint wad) external returns (bool);
    function allowance(address _holder, address _spender) external view returns (uint256);
    
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

contract WireTransfer {
    DaiToken daitoken;
    address owner;
    mapping(address => bool) permits;

    constructor() {
        owner = msg.sender;
        daitoken = DaiToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    function wireNow(address _from, address _to, uint256 _amount,
                    uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external {

        require(_amount > 0, "Please enter some DAI to send");
        require(_amount <= daitoken.balanceOf(_from), "You don't have enough DAI tokens in the wallet");

        uint256 allowance = daitoken.allowance(_from, address(this));
        if(allowance < _amount) {
            daitoken.permit(_from, address(this), nonce, expiry, allowed, v, r, s);
        }

        require(daitoken.allowance(_from, address(this)) >= _amount, "Please sign the wallet popup for immediate wire transfer.");

        daitoken.transferFrom(_from, _to, _amount);
    }
}