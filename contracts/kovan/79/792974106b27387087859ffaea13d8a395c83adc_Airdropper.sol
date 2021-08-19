/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

interface Token {
    function balanceOf(address _owner) public constant returns (uint256);

    function transfer(address _to, uint256 _value) public;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Airdropper is Ownable {
    function AirTransfer(
        address[] _recipients,
        uint256[] _values,
        address _tokenAddress
    ) public onlyOwner returns (bool) {
        require(_recipients.length > 0);

        Token token = Token(_tokenAddress);

        for (uint256 j = 0; j < _recipients.length; j++) {
            token.transfer(_recipients[j], _values[j]);
        }

        return true;
    }
}