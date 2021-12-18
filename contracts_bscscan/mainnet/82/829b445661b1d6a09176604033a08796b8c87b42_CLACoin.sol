/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT
                                                                       
//   .d8888b.  888             d8888       .d8888b.           d8b          
//  d88P  Y88b 888            d88888      d88P  Y88b          Y8P          
//  888    888 888           d88P888      888    888                       
//  888        888          d88P 888      888         .d88b.  888 88888b.  
//  888        888         d88P  888      888        d88""88b 888 888 "88b 
//  888    888 888        d88P   888      888    888 888  888 888 888  888 
//  Y88b  d88P 888       d8888888888      Y88b  d88P Y88..88P 888 888  888 
//   "Y8888P"  88888888 d88P     888       "Y8888P"   "Y88P"  888 888  888 

// by Community Liberation Army  www.CommunityLiberationArmy.com
// https://www.TheClaCoin.com
// https://www.twitter.com/TheClaCoin
// https://github.com/TheClaCoin
// https://t.me/TheClaCoin
// https://t.me/TheClaCoinChat

pragma solidity ^0.8.6;

contract CLACoin {

    string public name = "CLA Coin";
    string public symbol = "CLAC";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000 * 10 ** 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {

        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

}