pragma solidity ^0.4.18;

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract Splitter {

	address[] public contracts;

	function NewContent(bytes32 Content)
    public
    returns(address newContract)
  {
    Contenter c = new Contenter(Content);
    contracts.push(c);
    return c;
  }
}

contract Contenter {

	bytes32 public Content;

	constructor (bytes32 newContent){
		Content = newContent;
	}



	function getContent()
    public
    constant
    returns (bytes32)
	  {
	    return Content;
	  }   
}