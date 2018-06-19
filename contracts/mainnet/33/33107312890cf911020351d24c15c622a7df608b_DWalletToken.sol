/**
 * The D-WALLET token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 * Additionally tokens can be locked for a defined time interval by token holders.
 * Except  1,024,000,000 tokens (D-WALLET Frozen Vault + Bounty) all unsold tokens will be burned.
 * Author: D-WALLET TEAM
 * */

pragma solidity ^0.4.6;

contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract DWalletToken is SafeMath {

    /* Public variables of the token */
    string public standard = &#39;ERC20&#39;;
    string public name = &#39;D-WALLET TOKEN&#39;;
    string public symbol = &#39;DWT&#39;;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    address public owner;
    /* ICO Start time 26 August, 2017 13:00:00 GMT*/
    uint256 public startTime = 1503752400;
	/* ICO Start time 25 October, 2017 17:00:00 GMT*/
	uint256 public endTime = 1508950800;
    /* tells if tokens have been burned already */
    bool burned;

    /* Create an array with all balances so that blockchain will know */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* Generate a public event on the blockchain to notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	event Burned(uint amount);
	  // fallback function
    function () payable {
     owner.transfer(msg.value);
   }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function DWalletToken() {
        owner = 0x1C46b45a7d6d28E27A755448e68c03248aefd18b;
        balanceOf[owner] = 10000000000;              // Give the owner all initial tokens
        totalSupply = 10000000000;                   // Update initial total supply
    }

    /* function to send tokens to a given address */
    function transfer(address _to, uint256 _value) returns (bool success){
        require (now < startTime); //check if the crowdsale is already over
        require(msg.sender == owner && now < startTime + 1 years && safeSub(balanceOf[msg.sender],_value) < 1000000000); //prevent the owner of spending his share of tokens within the first year 
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);                     // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Function to allow spender to spend token on owners behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /* Transferfrom function*/
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (now < startTime && _from!=owner); //check if the crowdsale is already over 
        require(_from == owner && now < startTime + 1 years && safeSub(balanceOf[_from],_value) < 1000000000);
        var _allowance = allowance[_from][msg.sender];
        balanceOf[_from] = safeSub(balanceOf[_from],_value); // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);     // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(_allowance,_value);
        Transfer(_from, _to, _value);
        return true;
    }


    /* To be called when ICO is closed, burns the remaining tokens but the D-WALLET FREEZE VAULT (1000000000) and the ones reserved
    *  for the bounty program (24000000).
    *  anybody may burn the tokens after ICO ended, but only once (in case the owner holds more tokens in the future).
    *  this ensures that the owner will not posses a majority of the tokens. */
    function burn(){
    	//if tokens have not been burned already and the ICO ended
    	if(!burned && now>endTime){
    		uint difference = safeSub(balanceOf[owner], 1024000000);//checked for overflow above
    		balanceOf[owner] = 1024000000;
    		totalSupply = safeSub(totalSupply, difference);
    		burned = true;
    		Burned(difference);
    	}
    }

}