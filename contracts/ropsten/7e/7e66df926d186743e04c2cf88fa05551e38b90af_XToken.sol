/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

pragma solidity >=0.5.0 <0.9.0;

contract XToken {
    
    uint public totalSupply;
    string public name;
    mapping(address => uint256) public balance;
    address private owner;
    
    constructor(string memory _name) public {
        owner = msg.sender;
        name = _name;
    }

    function transferOwnership(address _new) public onlyOwner {
        require(_new != address(0), "");
        owner = _new;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function mint(address addr, uint amount) public {
        require(amount > 0, "invalid token amount");
        balance[addr] += amount;
        totalSupply += amount;
    }
    
    function burn(address addr, uint amount) public {
        require(amount > 0, "invalid token amount");
        balance[addr] -= amount;
        totalSupply -= amount;
    }
    
    function balanceOf(address addr) public view returns(uint256){
        return balance[addr];
    }
}