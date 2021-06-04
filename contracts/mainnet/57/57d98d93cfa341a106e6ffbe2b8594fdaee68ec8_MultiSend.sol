/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract MultiSend {
    
    // to save the owner of the contract in construction
    address private owner;
    // to save the amount of ethers in the smart-contract
    uint total_value;
    
    // modifier to check if the caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "0");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender;
    }

    // charge enable the owner to store ether in the smart-contract
    function deposit() payable public isOwner {
        // adding the message value to the smart contract
        total_value += msg.value;
    }
    
    // withdraw perform the transfering of ethers
    function withdraw(address payable receiverAddr, uint receiverAmnt) private {
        receiverAddr.transfer(receiverAmnt);
    }
    

    function distribute(address payable[] memory addrs, uint amount) payable public isOwner {
        total_value += msg.value;
        uint totalAmnt = amount * addrs.length;
        
        require(total_value >= totalAmnt, "1");
        
        
        for (uint i=0; i < addrs.length; i++) {
            total_value -= amount;
            withdraw(addrs[i], amount);
        }
    }
    
}