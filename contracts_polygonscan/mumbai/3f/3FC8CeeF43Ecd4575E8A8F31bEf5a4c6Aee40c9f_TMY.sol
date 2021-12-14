// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AbstractRegulatorService.sol";

contract TMY is IERC20 {
    address public owner; // The Many will be the contract owner
    string public name = "The Many Token";
    string public symbol = "TMY"; // Ticker
    uint256 public decimals = 18; // Using same standard as ETH
    uint256 public totalSupply;

    // ERC-20 getters
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) allowed;

    address public regServiceContract;
    AbstractRegulatorService regService;

    modifier restrictedOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    constructor(address _regServiceContract) {
        owner = msg.sender;
        regServiceContract = _regServiceContract;
        regService = AbstractRegulatorService(_regServiceContract);
    }

    function buy() public payable {
        require(regService.check(owner, msg.sender)); // Check the RegulatorService
        uint256 tokensReceivable;
        uint256 exchangeRate = 264406869290464; // Call the Chainlink contract here to get the latest rate at the time the function is called
        tokensReceivable = (msg.value * (10**decimals)) / exchangeRate;

        // Mint tokens to the buyer
        balanceOf[msg.sender] += tokensReceivable;

        // Increase the supply state
        totalSupply += tokensReceivable;
    }

    function sell(uint256 amount) public {
        require(regService.check(msg.sender, owner)); // Check the RegulatorService
        uint256 ethReceivable;
        uint256 exchangeRate = 264406869290464; // Call the Chainlink contract here to get the latest rate at the time the function is called
        ethReceivable = (exchangeRate * amount) / 10**decimals;

        // Burn tokens from buyer
        balanceOf[msg.sender] -= amount;

        // Decrease the supply state
        totalSupply -= amount;

        // Send ether to sender
        payable(msg.sender).transfer(ethReceivable);
    }

    function mint(uint256 amount) public restrictedOwner returns (bool) {
        // Mint new tokens (for testing purposes)
        // Should only be callable by contract owner
        balanceOf[msg.sender] = balanceOf[msg.sender] + amount;
        totalSupply = totalSupply + amount;
        return true;
    }

    function burn(uint256 amount) public restrictedOwner returns (bool) {
        // Burn tokens (for testing purposes)
        // Should only be callable by contract owner
        require(amount <= balanceOf[msg.sender], "Insufficient token funds");
        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        totalSupply = totalSupply - amount;
        return true;
    }

    function transfer(address receiver, uint256 amount)
        public
        override
        returns (bool)
    {
        require(regService.check(msg.sender, receiver)); // Check the RegulatorService
        require(amount <= balanceOf[msg.sender], "Insufficient token funds");

        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        balanceOf[receiver] = balanceOf[receiver] + amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        override
        returns (bool)
    {
        require(numTokens <= balanceOf[msg.sender], "Insufficient token funds");
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address _owner, address delegate)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][delegate];
    }

    function transferFrom(
        address _owner,
        address buyer,
        uint256 amount
    ) public override returns (bool) {
        require(regService.check(_owner, buyer)); // Check the RegulatorService
        require(amount <= allowed[_owner][msg.sender], "Not allowed"); // Check that the caller is allowed to make the transfer
        require(amount <= balanceOf[_owner], "Insufficient token funds"); // Check for sufficient token balance

        balanceOf[_owner] = balanceOf[_owner] - amount;
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender] - amount;
        balanceOf[buyer] = balanceOf[buyer] + amount;
        emit Transfer(_owner, buyer, amount);
        return true;
    }
}