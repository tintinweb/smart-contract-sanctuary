/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract dGoldToken {
    string public constant name = "Devious Licks dGOLD";
    string public constant symbol = "dGOLD";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public owner;

    modifier ownerOnly {
        require(msg.sender == owner, "You do not have owner right.");
        _;
    }
    modifier issuerOnly {
        require(isIssuer[msg.sender] || msg.sender == owner, "You do not have issuer right.");
        _;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isIssuer;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event IssuerRights(address indexed issuer, bool value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
        // mint(address(0xf7B33BB41e60E0B56BafeFd6D0E6Bb3E19D55012), );
        mint(address(0xD79bdB9eB68636E1de8D448242a75aB211FB7FA8), 1000 * 10 ** decimals);
    }

    function mint(address _to, uint256 _amount) public issuerOnly returns (bool success) {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(uint256 _amount) public issuerOnly returns (bool success) {
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount) public issuerOnly returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _amount) public returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit TransferOwnership(owner, _newOwner);
    }

    function setIssuerRights(address _issuer, bool _value) public ownerOnly {
        isIssuer[_issuer] = _value;
        emit IssuerRights(_issuer, _value);
    }

    function gift(address[] calldata receivers, uint256[] calldata _amounts) public ownerOnly {
        for(uint256 i = 0; i < receivers.length; i++){
            mint(receivers[i], _amounts[i]);
        }
    }
}