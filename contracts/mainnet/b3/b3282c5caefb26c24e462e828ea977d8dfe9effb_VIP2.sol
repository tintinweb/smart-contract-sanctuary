pragma solidity 0.5.16;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function burn(uint) external;
}

interface VoteInterface {
    function voter2VotingValue(address, uint, address) external view returns (uint32);
}

interface YFVRewards {
    function periodFinish() external view returns (uint);
}

contract VIP2 {

    address payable owner;
    YFVRewards pool0 = YFVRewards(0xa8d3084Fa61C893eACAE2460ee77E3E5f11C8CFE);
    TokenInterface usdt = TokenInterface(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    VoteInterface vote = VoteInterface(0x6ba70f65877Da18e751fF42fC1C3Fee8c66280E6);
    address payable whaleAddress = 0xCebaa26C11Bdf4F239424CcC17864B2C0f03e2BD;
    uint public contractDeployTime;
    uint public initialPeriodFinish;

    constructor() public {
        owner = msg.sender;
        contractDeployTime = block.timestamp;
        initialPeriodFinish = pool0.periodFinish();
    }

    // If whale voted yes, and fund is unlocked, calling this function will send the 10,000 USDT to the whale address
    function donationToWhale() public {
        require(isWhaleVotedYes());
        require(isFundUnlocked());
        usdt.transfer(whaleAddress, usdt.balanceOf(address(this)));
    }

    // Check if whale voted Yes
    function isWhaleVotedYes() public view returns (bool) {
        address poolAddress = 0x0e6ffd4dAecA13A8158146516f847D2F44AD4A30; // YFV Staking Pool V1
        uint votingItem = 2; // VIP2

        return vote.voter2VotingValue(poolAddress, votingItem, whaleAddress) != 0; // any value other than 0 is Yes
    }

    // Use the periodFinish data to check if pool0 is unlocked
    function isFundUnlocked() public view returns (bool) {
        return pool0.periodFinish() > initialPeriodFinish;
    }

    // If the fund is not unlocked after 2 weeks, owner can get back all assets in this contract
    function getBackAfterTwoWeeks() public {
        require(msg.sender == owner);
        require(block.timestamp > contractDeployTime + 14 days);
        usdt.transfer(owner, usdt.balanceOf(address(this)));
    }

}