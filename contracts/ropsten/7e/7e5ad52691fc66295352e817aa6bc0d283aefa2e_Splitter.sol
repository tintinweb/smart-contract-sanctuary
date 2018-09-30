pragma solidity ^0.4.18;

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract Splitter {

	address[] public contracts;

	function NewContent(string Content)
    public
    returns(address newContract)
  {
    Contenter c = new Contenter(Content);
    contracts.push(c);
    return c;
  }
}

contract Contenter {

	string public Content;

	constructor (string initContent){
		Content = initContent;
	}



	function getContent()
    public
    constant
    returns (string)
	  {
	    return Content;
	  }   
}