pragma solidity ^0.4.0;


contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract SimpleExchange is Ownable {

    ERC20Basic public token;
    uint256 public rate;

    function SimpleExchange(address _token, uint256 _rate) public {
        setToken(_token);
        setRate(_rate);
    }

    function setToken(address _token) public onlyOwner {
        require(_token != 0);
        token = ERC20Basic(_token);
    }

    function setRate(uint256 _rate) public onlyOwner {
        require(_rate != 0);
        rate = _rate;
    }

    function buy() public payable {
        uint256 tokensAmount = msg.value * rate;
        token.transfer(msg.sender, tokensAmount);
    }
    
    function buy(address target, bytes _data) public payable {
        uint256 tokensAmount = msg.value * rate;
        token.transfer(target, tokensAmount);
        require(target.call(_data));
    }

    function claim() public onlyOwner {
        owner.transfer(this.balance);
    }

    function claimTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(this));
    }

}