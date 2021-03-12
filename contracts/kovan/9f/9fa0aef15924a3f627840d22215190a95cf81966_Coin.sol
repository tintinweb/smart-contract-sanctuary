/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity >=0.5.0 <0.7.0;

contract Coin {
    address public minter;
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);
    event Mint(address minter, uint amount);
    
    constructor() public {
        minter = msg.sender;
    }

    function send(uint amt) public {
        
    }
    
    function mint(uint amt) public {
        // access control check (only the minter) 
        if (msg.sender == minter) {
            balances[msg.sender] += amt;
            emit Mint(msg.sender, amt);
        } else
            revert();
    }
}