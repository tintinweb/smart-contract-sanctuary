/**
 *Submitted for verification at snowtrace.io on 2021-12-16
*/

// SPDX-License-Identifier: Unlicensed
// Contract developed for Blizzard Finance
// Author: @PeteLongsword

pragma solidity ^0.8.4;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BlizzardInvest {

    // Define the admin of ICO
    address public _owner;

    // Define input token
    address public _inputToken;

    // Determines whether investing is enabled
    bool public _investingEnabled = false;

    // Determines the current status of the raise
    uint8 _raiseIndex;

    // Stores whitelisted Addresses
    mapping (address => bool) private _whitelistAddresses;

    // Current round
    uint256 public round = 0;

    mapping(address => bool) public _existingUser;
    mapping(address => uint256) public _userInvested;
    address[] public _investors;

    // Minimum that can be invested
    uint256 public _minInvestment = 500 * 10**18;
    uint256 public _maxInvestment = 1000 * 10**18;

    //hardcap
    // uint256 public icoTarget;
    uint256 public _raiseTarget = 325000 * 10**18;

    //define a state variable to track the funded amount
    uint256 public receivedFund;

    // Declare onlyOwner modification
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    // Initiate contract, declaring owner and MIM address
    constructor() {
        _owner = msg.sender;
        _inputToken = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    }


    // Investing function
    function Investing(uint256 _amount) public {
        
        require(_investingEnabled == true, "Raise is not in progress");

        // If in Whitelist round, confirm address is whitelisted
        if (round == 0) {
            bool iswhitelisted = checkWhitelist(msg.sender);
            require(iswhitelisted == true, "Not whitelisted address");
        }

        //check for hard cap
        require(
            _raiseTarget >= receivedFund + _amount,
            "Target Achieved. Investment not accepted"
        );

        // Cannot invest 0
        require(_amount > 0, "min Investment not zero");

        // Confirm user has not overinvested
        uint256 checkamount = _userInvested[msg.sender] + _amount;
        //check maximum investment
        require(
            checkamount <= _maxInvestment,
            "Investment not in allowed range"
        );

        // check for _existingUser, otherwise add to _investors
        if (_existingUser[msg.sender] == false) {
            _existingUser[msg.sender] = true;
            _investors.push(msg.sender);
        }

        // Increase amount invested by user
        _userInvested[msg.sender] += _amount;
        receivedFund = receivedFund + _amount;

        // Transfer tokens from user
        // User must have approved MIM prior to this step
        IERC20(_inputToken).transferFrom(msg.sender, address(this), _amount);
    }

    // Function returns how much an individual can still invest
    function remainigContribution(address owner) public view returns (uint256) {
        uint256 remaining = _maxInvestment - _userInvested[owner];
        return remaining;
    }

    // Returns the amount raised so far
    function checkRaiseAmount() public view returns (uint256 _balance) {

        return IERC20(_inputToken).balanceOf(address(this));
    }

    // Withdraws any raised funds to owner address
    function withdarwinputToken(address _admin) public onlyOwner {
        uint256 raisedAmount = IERC20(_inputToken).balanceOf(address(this));
        IERC20(_inputToken).transfer(_admin, raisedAmount);
    }

    // Function to begin the raise
    function startRaise() external onlyOwner {
        require(_raiseIndex == 0, "Cannot restart raise");
        _investingEnabled = true;
        _raiseIndex = _raiseIndex + 1;
    }

    // Set Max Investment
    function changeMaxInvestment(uint256 limit) public onlyOwner {
        _maxInvestment = limit;
    }

    // Set Min Investment
    function changeMinInvestment(uint256 limit) public onlyOwner {
        _minInvestment = limit;
    }

    // Begin the whitelisting round
    function startWhitelistingRound() public onlyOwner {
        round = 0;
    }

    // Start the normal round
    function startNormalRound() public onlyOwner {
        round = 1;
    }

    // Add addresses to whitelist
    function addWhitelist(address[] memory whitelistAddresses) public onlyOwner {
        for (uint i = 0; i < whitelistAddresses.length; i++) {
            _whitelistAddresses[whitelistAddresses[i]] = true;
        }
    }

    // Remove address from whitelist
    function removeWhitelist(address notWhitelistAddress) public onlyOwner {
        _whitelistAddresses[notWhitelistAddress] = false;
    }

    // Function to return whether address is whitelisted
    function checkWhitelist(address user) public view returns (bool) {
        return _whitelistAddresses[user];
    }

    // Function to initialize aspects of raise
    // Does not need to be used unless functionality is changing
    function initializeRaise( address inputToken, uint256 minInvestment, uint256 maxinvestment, uint256 raiseTarget) public onlyOwner {
        
        require(raiseTarget > maxinvestment, "Incorrect max investment value");

        _inputToken = inputToken;
        _raiseTarget = raiseTarget;
        _maxInvestment = maxinvestment;
        _minInvestment = minInvestment;
    }
}