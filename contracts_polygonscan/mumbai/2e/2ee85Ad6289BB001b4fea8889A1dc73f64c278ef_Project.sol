// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AbstractRegulatorService.sol";
import "./AbstractTMYToken.sol";

contract Project is IERC20 {
    address public owner; // The Many will be the contract owner
    string public name; // Name of the token
    string public symbol; // Ticker
    uint256 public decimals = 18; // Using same standard as ETH
    uint256 public purchaseLimit = 50 * (10**decimals); // 50 TMY tokens

    uint256 public tokenPrice; // Price of 1 share (1 token) in the project
    uint256 public totalShareholders; // Amount of token holders (shareholders)

    uint256 public tokensSold; // Amount of tokens sold in the offering
    uint256 public totalSupply; // Initial supply of shares in the project
    mapping(address => uint256) public balanceOf; // Mapping of shareholders in the project
    mapping(address => mapping(address => uint256)) allowed;

    bool public projectCanceled = false; // Will be set to true by The Many if project fails to raise enough capital

    address public regServiceContract;
    AbstractRegulatorService regService;

    address public tmyTokenContract;
    AbstractTMYToken tmyToken;

    modifier restrictedOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    modifier isActive() {
        require(!projectCanceled, "Project is not active");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _tokenPrice,
        uint256 _totalSupply,
        address _regServiceContract,
        address _tmyTokenContract
    ) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        tokenPrice = _tokenPrice;
        totalSupply = _totalSupply * (10**decimals);

        regServiceContract = _regServiceContract;
        regService = AbstractRegulatorService(_regServiceContract);

        tmyTokenContract = _tmyTokenContract;
        tmyToken = AbstractTMYToken(_tmyTokenContract);
    }

    function tokensRemaining() public view returns (uint256) {
        return totalSupply - tokensSold;
    }

    function cancelSale(bool isCanceled) public restrictedOwner {
        projectCanceled = isCanceled;
    }

    function buy(uint256 investmentAmount) public isActive {
        // This buy function will NOT accept the native currency (MATIC or ETH)
        // but only TMY tokens (i.e. not marked "payable")
        require(
            investmentAmount >= purchaseLimit,
            "The investment is below the required minimum"
        ); // Check that the investment limit is met

        // Calculate the amount of tokens (shares) to issue to the investor
        uint256 tokensReceivable;
        tokensReceivable = (investmentAmount * (10**decimals)) / tokenPrice;

        // If the tokensReceivable is larger than the available supply,
        // only the remaining supply is issued to the investor and the
        // investmentAmount adjusted accordingly
        if ((tokensSold + tokensReceivable) > totalSupply) {
            tokensReceivable = totalSupply - tokensSold;
            investmentAmount = tokensReceivable * (tokenPrice / (10**decimals));
        }

        // Transfer payment (TMY tokens) to contract owner (The Many)
        tmyToken.transferFrom(msg.sender, owner, investmentAmount);

        // Increment number of shareholders if investor is new shareholder
        if (balanceOf[msg.sender] == 0) {
            totalShareholders += 1;
        }

        // Transfer the tokens to the buyer
        balanceOf[msg.sender] += tokensReceivable;

        // Increase the tokens sold state variable
        tokensSold += tokensReceivable;
    }

    function claimBack() public {
        require(
            balanceOf[msg.sender] != 0,
            "Only token holders can be reimbursed"
        );
        uint256 refund;

        // Calculate the amount of ether to refund
        refund = balanceOf[msg.sender] * (tokenPrice / (10**decimals));

        // Refund TMY tokens
        tmyToken.transferFrom(owner, msg.sender, refund);

        // Set token balance to zero
        balanceOf[msg.sender] = 0;
    }

    function transfer(address receiver, uint256 amount)
        public
        override
        isActive
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
        isActive
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address _owner, address delegate)
        public
        view
        override
        isActive
        returns (uint256)
    {
        return allowed[_owner][delegate];
    }

    function transferFrom(
        address _owner,
        address buyer,
        uint256 amount
    ) public override isActive returns (bool) {
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