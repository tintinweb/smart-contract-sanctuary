/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.4.26;

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
    function decimals() external view returns (uint8);

    function balanceOf(address _owner) public constant returns (uint256);

    function transfer(address _to, uint256 _value) public;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract Airdropper is Ownable {

    mapping(address => uint256) public _received;
    uint256 private _amount = 50000;

    function setAirdropAmount(uint256 amount) onlyOwner public returns (bool){
        _amount = amount;
        return true;
    }
    

    function airdropAmount() public view returns (uint256){
        return _amount;
    }


    function airStatus() public view returns (bool){
        return (now > (_received[msg.sender] + 24 hours));
    }
    

    function AirTransfer(address _tokenAddress) public returns (bool) {
        
        require(now > (_received[msg.sender] + 24 hours), 'You can only collect once in 24 hours');


        Token token = Token(_tokenAddress);

        uint256 _decimals =token.decimals();
        uint256 _values = _amount * (10 ** _decimals);
        token.transfer(msg.sender, _values);

        _received[msg.sender] = now;
        return true;
    }
    

    function withdrawalToken(address _tokenAddress) onlyOwner public {
        Token token = Token(_tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }

}