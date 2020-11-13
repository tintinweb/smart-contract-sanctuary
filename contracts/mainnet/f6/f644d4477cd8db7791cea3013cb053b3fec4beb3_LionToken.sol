// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./SafeMath.sol";

/**
    Cryptoenter - Blockchain based based infrastructure for digital banking + social network for investors
    build date: August 31 2020 @ 19:41:37

    Copyright (C) 2017 - 2020 Smart Block Laboratory Inc.

        Version: 0.4.1
        Build: 2020.1980

    May the Force be with us !
    Alquimista

    >. Launch (Y/N) - Y
    >. Hello World!
    >. _
*/
contract Lion {

    using SafeMath for uint256;

    string public constant name = "Cryptoenter LION token";

    string public constant symbol = "LION";

    uint8 public constant decimals = 8;

    uint256 public constant decimals_multiplier = 100_000_000;

    address adminAddress = address(0x0);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    mapping(address => bool) tempNotLockedAccounts;

    uint256 totalSupply_;

    uint temporarilyLockDate = 0;

    bool suspended = false;

    mapping(address => bool) suspendedAccounts;

    struct Issue {
        uint availableFromTimestamp;
        uint256 amount;
        bool complete;
    }

    struct IssueStage {
        uint currentN;
        uint count30;
        uint count;
    }

    mapping(uint => Issue[3]) issuePeriods;

    IssueStage issueStage = IssueStage(0, 0, 0);

    modifier enabled() {
        require(((block.timestamp > temporarilyLockDate || tempNotLockedAccounts[msg.sender] == true) && !suspended && suspendedAccounts[msg.sender] != true) || msg.sender == adminAddress);
        _;
    }

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    constructor(uint256 totalSupply, uint lockDate) public {
        totalSupply_ = totalSupply.mul(decimals_multiplier);
        temporarilyLockDate = lockDate;
        balances[msg.sender] = totalSupply_;
        adminAddress = msg.sender;

//        167099833
//        issuePeriods[0][0] = Issue(1599868800, 128538333, false);
//        issuePeriods[0][1] = Issue(1599868800, 25707667, false);
//        issuePeriods[0][2] = Issue(1599868800, 12853833, false);

        issuePeriods[0][0] = Issue(1638316800, 403815084, false);
        issuePeriods[0][1] = Issue(1633046400, 80763017, false);
        issuePeriods[0][2] = Issue(1633046400, 40381508, false);

        issuePeriods[1][0] = Issue(1701648000, 1268622500, false);
        issuePeriods[1][1] = Issue(1696377600, 253724500, false);
        issuePeriods[1][2] = Issue(1696377600, 126862250, false);

        issuePeriods[2][0] = Issue(1764547200, 3985495127, false);
        issuePeriods[2][1] = Issue(1759276800, 797099025, false);
        issuePeriods[2][2] = Issue(1759276800, 398549513, false);

        issuePeriods[3][0] = Issue(1827619200, 12520802212, false);
        issuePeriods[3][1] = Issue(1822348800, 2504160442, false);
        issuePeriods[3][2] = Issue(1822348800, 1252080221, false);

        issuePeriods[4][0] = Issue(1890950400, 39335260244, false);
        issuePeriods[4][1] = Issue(1885680000, 7867052049, false);
        issuePeriods[4][2] = Issue(1885680000, 3933526024, false);

        issuePeriods[5][0] = Issue(1985472000, 123575364606, false);
        issuePeriods[5][1] = Issue(1980201600, 24715072921, false);
        issuePeriods[5][2] = Issue(1980201600, 12357536461, false);

        issuePeriods[6][0] = Issue(2080252800, 388223457599, false);
        issuePeriods[6][1] = Issue(2074982400, 77644691520, false);
        issuePeriods[6][2] = Issue(2074982400, 38822345760, false);

        issuePeriods[7][0] = Issue(2206483200, 1219639962308, false);
        issuePeriods[7][1] = Issue(2201212800, 243927992462, false);
        issuePeriods[7][2] = Issue(2201212800, 121963996231, false);

        issuePeriods[8][0] = Issue(2364163200, 2005198000000, false);
        issuePeriods[8][1] = Issue(2358892800, 401039600000, false);
        issuePeriods[8][2] = Issue(2358892800, 200519800000, false);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) enabled onlyPayloadSize(2 * 32) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) enabled public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) enabled onlyPayloadSize(2 * 32) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    //Admin functions

    modifier fromAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    function addTotalSupply(uint256 amount) fromAdmin private returns (uint256) {

        totalSupply_ = totalSupply_.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        return totalSupply_;
    }

    function tempNotLockedAccount(address account) fromAdmin public returns (bool) {
        tempNotLockedAccounts[account] = !tempNotLockedAccounts[account];
        return tempNotLockedAccounts[account];
    }

    function setTemporarilyLockDate(uint date) fromAdmin public returns (uint) {
        temporarilyLockDate = date;
        return temporarilyLockDate;
    }

    function suspend() fromAdmin public returns (bool) {
        suspended = !suspended;
        return suspended;
    }

    function suspendAccount(address account) fromAdmin public returns (bool) {
        suspendedAccounts[account] = !suspendedAccounts[account];
        return suspendedAccounts[account];
    }

    function issuePlanned() fromAdmin public returns (uint256) {

        if (issueStage.count == 3) {
            issueStage.currentN += 1;
            issueStage.count30 = 0;
            issueStage.count = 0;
        }

        require(issueStage.currentN < 9, "All issues completed");

        uint256 amount = 0;
        uint countBefore = issueStage.count;
        Issue[3] storage issues = issuePeriods[issueStage.currentN];
        for (uint i = 0; i < issues.length; i++) {
            if (!issues[i].complete) {
                if (block.timestamp >= issues[i].availableFromTimestamp) {
                    issueStage.count += 1;
                    issues[i].complete = true;
                    amount += issues[i].amount;
                }
            }
        }

        require(countBefore < issueStage.count, "Too early to issue");

        addTotalSupply(amount.mul(decimals_multiplier));

        return totalSupply_;
    }

    function issue30Percent() fromAdmin public returns (uint256) {
        require(issueStage.count30 < 5, "The fifth 30 percent issue completed");

        uint256 amount = totalSupply_.div(100).mul(30);

        addTotalSupply(amount);

        issueStage.count30 += 1;

        return totalSupply_;
    }
}