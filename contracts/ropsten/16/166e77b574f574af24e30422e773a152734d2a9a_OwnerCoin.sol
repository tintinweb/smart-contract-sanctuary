/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.4.21;

// Blockchain: Bep-20 Binance Smart Chain (Solidity)
// Token Name: ChainSys
// Ticker: ChainS
// Supply: 1,000 Fixed
// Owner: 0x87D258eB5828EcFAD00524e4A8636Ca5bD299755
contract OwnerCoin {
     uint256 public totalSupply = 1000;
     mapping (address => uint256) balances;
  
   
    string public name;                   
    
    string public symbol;                 
     
    constructor () public {
       
        balances[msg.sender] = totalSupply;   
        name = "ChainSyS";                                                            
        symbol = "chainS";                             
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
}
   function balance() public view returns(uint){
    return balances[msg.sender];
}
}