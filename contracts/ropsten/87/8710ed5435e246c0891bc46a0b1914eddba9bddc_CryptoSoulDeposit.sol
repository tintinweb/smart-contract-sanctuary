pragma solidity ^0.4.25;

contract CryptosoulToken{

  function transfer(address to, uint256 value) public returns(bool);
  function balanceOf(address who) public view returns(uint256);
}

contract Ownable {
    
    address public owner = 0x0;
    
    constructor() public {
        owner = msg.sender;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract CryptoSoulDeposit is Ownable{
    
    event Deposit(address indexed _wallet, uint256 _value);
    
    CryptosoulToken cs;
    
    function setCryptoSoulContract(address cryptoSoulContract) public onlyOwner{
        cs = CryptosoulToken(cryptoSoulContract);
    }
    
    function depositSoul(uint256 _value) public returns(bool){
        cs.transfer(owner, _value);
        emit Deposit(msg.sender, _value);
        return true;
    }
}