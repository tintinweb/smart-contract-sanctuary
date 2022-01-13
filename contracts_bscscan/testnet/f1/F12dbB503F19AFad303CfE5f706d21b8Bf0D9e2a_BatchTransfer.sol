// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.0;

contract ERC20Interface {
  function transferFrom(address _from, address _to, uint _value) public returns (bool){}
}
contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner()  {
    require(msg.sender == owner, "owner: whut?");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {

    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


contract BatchTransfer is Ownable {

  function sendToken (address contractObj,
                    address   tokenRepo,
                    address[] memory desinationAddress,
                    uint[] memory amounts) public onlyOwner{

    for( uint i = 0 ; i < desinationAddress.length; i++ ) {
        ERC20Interface(contractObj).transferFrom(tokenRepo, desinationAddress[i], amounts[i]);
    }
   }
   
  function sendNativeCoin(address payable[] memory _to, uint[] memory _value)
                  public payable onlyOwner returns(bool){
    assert(_to.length == _value.length);
		assert(_to.length <= 255);
		uint256 beforeValue = msg.value;
		uint256 afterValue = 0;
		for (uint8 i = 0; i < _to.length; i++) {
			afterValue = afterValue + _value[i];
			_to[i].transfer(_value[i]);
		}
		uint256 remainingValue = beforeValue - afterValue;
		if (remainingValue > 0) {
      // send back remaining value
			assert(msg.sender.send(remainingValue));
		}
		return true; 
  }
}