pragma solidity 0.4.25;

contract HomburgerToken {
    string public constant name = "Kevin&#39;s Homburger Token";
    string public constant symbol ="KHT";
    uint256 public constant decimal = 18;
    
    address public owner;
    uint256 public totalSupply;
    mapping(address=>uint256) private balances;
    
    constructor() public {
        owner = msg.sender;
        /*totalSupply = 1000;
        balances[owner] = totalSupply;*/
        }
    
    function balanceOf(address tokenHolder) public view returns (uint256) {
        return balances[tokenHolder];
    }
    
    function mint(address to, uint256 value) public returns(bool) {
        require(msg.sender == owner);
        require(to != address(0));
        
        totalSupply += value; // totalSupply + value
        balances[to] += value;
        return true;
    }
}