/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function lastBuyTime(address account) external view returns (uint256);

    function lastSellTime(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "NOT AN OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract DecentGrants is Ownable {
    IBEP20 public decent;
    address[] public researchUsers;
    address[] public scholarshipUsers;
    address[] public researchWinners;
    address[] public scholarshipWinnerrs;

    uint256 public researchRewardAmount;
    uint256 public scholarshipRewardAmount;
    uint256 public minAmountForResearch;
    uint256 public minAmountForScholarship;
    uint256 public timePeriod = 14 days;

    struct User {
        bool isResearchUser;
        bool isScholarshipUser;
        uint256 researcherRegisterTime;
        uint256 scholarRegisterTime;
        uint256 researchWinCount;
        uint256 scholarshipWinCount;
        uint256 lastResearchWinAt;
        uint256 lastScholarshipWinAt;
    }

    mapping(address => User) public userData;

    event ResearcherRegistered(address user, uint256 registrationTime);
    event ScholarRegistered(address user, uint256 registrationTime);
    event ResearcherWinner(
        address user,
        uint256 winningAmount,
        uint256 winningTime
    );
    event ScholarWinner(
        address user,
        uint256 winningAmount,
        uint256 winningTime
    );

    constructor(address _decent) Ownable(msg.sender) {
        decent = IBEP20(_decent);
        researchRewardAmount = 5 * 10**9 * 10**decent.decimals(); // 5 Billion
        scholarshipRewardAmount = 1 * 10**9 * 10**decent.decimals(); // 1 Billion
        minAmountForResearch = 1 * 10**9 * 10**decent.decimals(); // 1 Billion
        minAmountForScholarship = 200 * 10**6 * 10**decent.decimals(); // 200 Million
    }

    function RegisterResearchGrant() public {
        require(
            decent.balanceOf(msg.sender) >= minAmountForResearch,
            "You need at least 1 billion DECENT decents to register"
        );
        researchUsers.push(msg.sender);
        User memory user = userData[msg.sender];
        user.isResearchUser = true;
        user.researcherRegisterTime = block.timestamp;
        emit ResearcherRegistered(msg.sender, block.timestamp);
    }

    function RegisterScholarship() public {
        require(
            decent.balanceOf(msg.sender) >= minAmountForScholarship,
            "You need at least 200 million DECENT decents to register"
        );
        scholarshipUsers.push(msg.sender);
        User memory user = userData[msg.sender];
        user.isScholarshipUser = true;
        user.scholarRegisterTime = block.timestamp;
        emit ScholarRegistered(msg.sender, block.timestamp);
    }

    function GiveResearchGrant() public onlyOwner {
        address winner;
        bool winnerFound;
        while (!winnerFound) {
            uint256 winnerIndex = luckyDraw(
                0,
                researchUsers.length,
                researchRewardAmount
            );
            winner = researchUsers[winnerIndex];
            if (
                decent.balanceOf(winner) >= minAmountForResearch &&
                block.timestamp > decent.lastSellTime(winner) + timePeriod &&
                userData[winner].isResearchUser
            ) {
                winnerFound = true;
            }
        }
        userData[winner].researchWinCount++;
        userData[winner].lastResearchWinAt = block.timestamp;
        decent.transferFrom(owner, winner, researchRewardAmount);
        researchWinners.push(winner);
        emit ResearcherWinner(winner, researchRewardAmount, block.timestamp);
    }

    function GiveScholarship() public onlyOwner {
        address winner;
        bool winnerFound;
        while (!winnerFound) {
            uint256 winnerIndex = luckyDraw(
                0,
                scholarshipUsers.length,
                scholarshipRewardAmount
            );
            winner = scholarshipUsers[winnerIndex];
            if (
                decent.balanceOf(winner) >= minAmountForScholarship &&
                block.timestamp > decent.lastSellTime(winner) + timePeriod &&
                userData[winner].isScholarshipUser
            ) {
                winnerFound = true;
            }
        }
        userData[winner].scholarshipWinCount++;
        userData[winner].lastScholarshipWinAt = block.timestamp;
        decent.transferFrom(owner, winner, scholarshipRewardAmount);
        scholarshipWinnerrs.push(winner);
        emit ResearcherWinner(winner, scholarshipRewardAmount, block.timestamp);
    }

    function luckyDraw(
        uint256 from,
        uint256 to,
        uint256 amount
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        amount
                )
            )
        );
        return (seed % (to - from)) + from;
    }

    function changedecent(address _decent) external onlyOwner {
        decent = IBEP20(_decent);
    }

    function changeAmounts(
        uint256 _researchRewardAmount,
        uint256 _scholarshipRewardAmount,
        uint256 _minAmountForResearch,
        uint256 _minAmountForScholarship
    ) public onlyOwner {
        researchRewardAmount = _researchRewardAmount;
        scholarshipRewardAmount = _scholarshipRewardAmount;
        minAmountForResearch = _minAmountForResearch;
        minAmountForScholarship = _minAmountForScholarship;
    }
    function changeTimePeriod(uint256 _time)public onlyOwner{
        timePeriod = _time;
    }
}