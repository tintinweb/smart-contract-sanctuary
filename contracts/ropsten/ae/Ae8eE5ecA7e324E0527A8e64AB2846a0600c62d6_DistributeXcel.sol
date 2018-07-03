pragma solidity ^0.4.21;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract DistributeXcel{
    address[] public recipients;
    ERC20Basic public token;
    address owner;
    //uint256 public tokenAmountToAirdrop = 100 * (10 ** uint256(18));

    function DistributeXcel(address _token) public{
        require(_token != address(0));
        token = ERC20Basic(_token);
        owner = msg.sender;
    }

    function doAirdrop(address[] _recipients, uint256 amount) public {
        require(msg.sender == owner);
        require(amount > 0);
        require(token.balanceOf(this) >= _recipients.length * amount * (10 ** uint256(18)));
       
        for (uint i=0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));
            token.transfer(_recipients[i], amount * (10 ** uint256(18)));
        }
    }
}