/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;

    struct tokenChecker{
        address contractAddress;
        string avatarUrl;
        string tokenName;
        uint percentage;
        uint price;
        uint confirmation;
        uint voteCount;
        bool status;
        mapping(address => uint8) votes;
    }

    
    uint public numTokenChekers;

    mapping (uint => tokenChecker) public tokenCheckers;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

        /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function tokenData(address contractAddress, string memory avatarUrl, 
            string memory tokenName, uint percentage, uint price,
            uint confirmation, bool status) public {
        
        tokenChecker storage tokenchecker = tokenCheckers[numTokenChekers];
    
        tokenchecker.contractAddress = contractAddress;
        tokenchecker.avatarUrl = avatarUrl;
        tokenchecker.tokenName = tokenName;
        tokenchecker.percentage = percentage;
        tokenchecker.price = price;
        tokenchecker.confirmation = confirmation;
        tokenchecker.status = status;
        numTokenChekers ++;

    }

    function voteChecker(uint tokenIndex, uint8 voteValue) external {
        tokenChecker storage tokenchecker = tokenCheckers[tokenIndex];
        address voter = msg.sender;
        if(tokenchecker.votes[voter] != 0 )
        {
            tokenchecker.votes[voter] = voteValue;
            tokenchecker.voteCount++;
        }
    }   
    

}