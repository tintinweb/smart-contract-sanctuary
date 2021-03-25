/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.5.1;

contract Token {
    function transfer(address to, uint256 amount) public returns (bool);
    function balanceOf(address addr) public view returns (uint256);
}

contract Faucet {
    Token token;
    address payable public  owner;
    uint256 public rate = 1000; // 1 ETH = 1000 ZAP
    event BUYZAP(address indexed _buyer, uint256 indexed _amount, uint indexed _rate);

    // 1: 1000 ratio

    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    constructor(address _token) public {
        owner = msg.sender;
        token = Token(_token);
    }

    event Log(uint256 n1, uint256 n2);

    function buyZap(address to, uint256 amt) public payable {
        require(amt > 0);
        amt = amt * rate;
        require(amt <= token.balanceOf(address(this)));
        token.transfer(to, amt);
        emit BUYZAP(msg.sender,amt,rate);
    }


    function withdrawTok() public ownerOnly {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function withdrawEther() public ownerOnly {
        owner.transfer(address(this).balance);
    }
}