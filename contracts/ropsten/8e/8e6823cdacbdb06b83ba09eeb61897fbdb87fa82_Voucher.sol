/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity >= 0.6.0;

contract Voucher {
    
    mapping(address=>uint256) public balances;
    uint256 public totalSupplyTokens;
    address public owner;
    
    function name() public pure returns (string memory) {
        return "[email protected]";
    }
    
    function symbol() public pure returns (string memory) {
        return "PHD";
    }
    
    function decimals() public pure returns (uint8){
        return 0;
    }
    
    function totalSupply() public view returns (uint256){
        return totalSupplyTokens;    
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    
    function mint(uint256 _value) public returns (bool){
        require(msg.sender == owner);
        totalSupplyTokens += _value;
        balances[msg.sender] += _value;
        return true;
    }
    
    constructor() {
        balances[msg.sender] = 100;
        totalSupplyTokens = 100;
        owner = msg.sender;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        // transfer tokens from msg.sender to _to
        require(balances[msg.sender] >= _value, "Not enough funds");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
    
}