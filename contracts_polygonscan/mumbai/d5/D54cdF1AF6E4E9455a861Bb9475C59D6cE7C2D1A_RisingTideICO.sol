pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import "./interfaces.sol";

//import "hardhat/console.sol"; //library to add console.log() dor debug

contract RisingTideICO is Context, Ownable {
    using SafeMath for uint256;

    IERC20 public risingTideToken;
    address payable tresuaryAccount;
    
    uint256 public constant RATE = 3000; // Number of tokens per Ether
    uint256 public constant CAP = 5350; // Cap in Ether
    uint256 public constant START = 1640801141; // start date
    uint256 public constant DAYS = 45; // 45 Day

    bool public initialized = false;
    uint256 public raisedAmount = 0;


    event Bought(address to, uint256 amount);

    
    constructor() public {
        risingTideToken = IERC20(0xc8c6D155CE2C4514Df95F38B96ac8D2536C0f433);
        tresuaryAccount = msg.sender;
    }

    /**
    * buyTokens
    * @dev function that sells available tokens
    **/
    function buyTokens() public payable whenSaleIsActive {
        uint256 weiAmount = msg.value; // Calculate tokens to sell
        uint256 tokens = weiAmount.mul(RATE);
        
        emit Bought(msg.sender, tokens); // log event onto the blockchain
        raisedAmount = raisedAmount.add(msg.value); // Increment raised amount
        risingTideToken.transfer(msg.sender, tokens); // Send tokens to buyer
        
        tresuaryAccount.transfer(msg.value);// Send money to owner
    }

    /**
    * initialize
    * @dev Initialize the contract
    **/
    function initialize() public onlyOwner {
        require(initialized == false); // Can only be initialized once
        require(tokensAvailable() > 0); // Must have enough tokens allocated
        initialized = true;
    }

        /**
    * whenSaleIsActive
    * @dev ensures that the contract is still active
    **/
    modifier whenSaleIsActive() {
        // Check if sale is active
        assert(isActive());
        _;
    }

        /**
    * isActive
    * @dev Determins if the contract is still active
    **/
    function isActive() public view returns (bool) {
        return (
            initialized == true &&
            now >= START && // Must be after the START date
            now <= START.add(DAYS * 1 days) && // Must be before the end date
            goalReached() == false // Goal must not already be reached
        );
    }

    /**
    * goalReached
    * @dev Function to determin is goal has been reached
    **/
    function goalReached() public view returns (bool) {
        return (raisedAmount >= CAP * 1 ether);
    }

    /**
    * tokensAvailable
    * @dev returns the number of tokens allocated to this contract
    **/
    function tokensAvailable() public view returns (uint256) {
        return risingTideToken.balanceOf(address(this));
    }

    /**
    * destroy
    * @notice Terminate contract and refund to owner
    **/
    function destroy() onlyOwner public {
        // Transfer tokens back to owner
        uint256 balance = risingTideToken.balanceOf(address(this));
        assert(balance > 0);
        risingTideToken.transfer(tresuaryAccount, balance);
        // There should be no ether in the contract but just in case
        selfdestruct(tresuaryAccount);
    }
}