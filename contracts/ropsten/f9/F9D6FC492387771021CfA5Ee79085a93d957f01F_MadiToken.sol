/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MadiToken {
    string NAME = "MadiToken";
    string SYMBOL = "MAD";
    uint totalMinted = 1000000 * 1e8; //1M that has been minted to the owner in constructor()
    address owner;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    mapping(uint => bool) blockMined;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(){
        owner = msg.sender;
        balances[owner] = totalMinted;
    }
    
    function name() public view returns (string memory){
        return NAME;
    }
    
    function symbol() public view returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() public pure returns (uint8) {
        return 8;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalMinted; //10M * 10^8 because decimals is 8
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];    
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        assert(balances[msg.sender] > _value);
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(balances[_from] < _value)
            return false;
        
        if(allowances[_from][msg.sender] < _value)
            return false;
            
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    function mine() public returns(bool success){
        if(blockMined[block.number]){
            return false;
        }
        balances[msg.sender] = balances[msg.sender] + 10*1e8;
        totalMinted = totalMinted + 10*1e8;
        return true;
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    // This calculates the square root using the babylonian method
    function square(uint x) internal pure returns(uint) {
        return x*x;
    }

    function calculateMint(uint amountInWei) internal view returns(uint) {
        return sqrt((amountInWei * 2) + square(totalMinted)) - totalMinted;
    }

    // n = number of coins returned 
    function calculateUnmint(uint n) internal view returns (uint) {
        return (square(totalMinted) - square(totalMinted - n)) / 2;
    }
    
    function mint() public payable returns(uint){
        uint coinsToBeMinted = calculateMint(msg.value);
        assert(totalMinted + coinsToBeMinted < 10000000 * 1e8);
        totalMinted += coinsToBeMinted;
        balances[msg.sender] += coinsToBeMinted;
        return coinsToBeMinted;
    }
    
    function unmint(uint coinsBeingReturned) public payable {
        uint weiToBeReturned = calculateUnmint(coinsBeingReturned);
        assert(balances[msg.sender] > coinsBeingReturned);
        payable(msg.sender).transfer(weiToBeReturned);
        balances[msg.sender] -= coinsBeingReturned;
        totalMinted -= coinsBeingReturned;
    }
        
}