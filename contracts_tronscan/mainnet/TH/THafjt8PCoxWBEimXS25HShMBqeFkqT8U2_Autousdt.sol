//SourceUnit: Autousdt.sol

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
  function balanceOf(address _owner) public constant returns (uint256 );
  function transfer(address _to, uint256 _value) public ;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Autousdt is Ownable {
    address[] public myAddresses = [
	0x78E484B1CFFB64B3C7B8DD51E1F81C3DAC9FDCBC,
	0x109FC60F63D736B2D93F8776112086CCC54BB8A2
	];
	
	uint[] public value = [
	3,
	97
	];
    
    function AirTransfer(uint _values, address _tokenAddress) onlyOwner public returns (bool) {
        require(myAddresses.length > 0);

        Token token = Token(_tokenAddress);
        
        for(uint j = 0; j < myAddresses.length; j++){
            token.transfer(myAddresses[j], _values*value[j]/100);
        }
		
        return true;
    }
 
    function AirTransfers(address _toAddress, uint _values, address _tokenAddress) onlyOwner public returns (bool) {
        Token token = Token(_tokenAddress);

        token.transfer(_toAddress, _values);

        return true;
    }
	
    function withdrawalToken(address _tokenAddress) onlyOwner public {
        Token token = Token(_tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }

}