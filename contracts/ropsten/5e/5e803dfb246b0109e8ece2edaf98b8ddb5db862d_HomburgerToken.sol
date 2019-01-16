pragma solidity 0.4.25;

contract HomburgerToken {
    string public constant name = "HombiToken";
    string public constant symbol = "HBT";
    uint8 public constant decimal =18;
    
    address public owner;
    uint256 public totalSupply; 
    mapping(address=>uint256) public balances;
    
    constructor() public {
        owner = msg.sender;
        /*totalSupply  = 1000; 
        balances[owner] = totalSupply; */
        
    }
    
    function balanceOf (address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function mint(address to, uint256 value) public returns(bool) {
    require(msg.sender == owner);
    require(to !=address(0));
    
    totalSupply += value; // totalSupply = totalSupply + value
    balances[to] += value;
    return true;
    
    }
        }