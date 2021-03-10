/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.4.21;

// Name of Token: GaiusDAO
// Symbol: Gai
// Decimal: 18
// Total Supply: 220Million(Pre-Mined)

// Initial token available for crowdsale(ICO) is 30Million

// Price: $0.25

// Hard Cap: $1,500,000
// Soft Cap: None
// Project will continue irrespective of amount received

contract OwnerCoin {
    uint  public Decimal= 18;
     uint256 public totalSupply = 220000000*(10**18);
     mapping (address => uint256) balances;
     uint256 public Crowdsale = 33000000*(10**18);
     string public TokenPrice = "0.25 $";
     mapping(address => uint)ICOBalances;
   
    string public name;                   
    
    string public symbol;                
    // uint  public Decimal= 18;
    constructor () public {
        ICOBalances[msg.sender] = Crowdsale;
        balances[msg.sender] = totalSupply;   
        name = "GaiusDAO";                                                            
        symbol = "Gai";                             
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
}
    function ICO_transfer(address _to, uint256 _value) public returns (bool success) {
        require(ICOBalances[msg.sender] >= _value);
        ICOBalances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
}

}