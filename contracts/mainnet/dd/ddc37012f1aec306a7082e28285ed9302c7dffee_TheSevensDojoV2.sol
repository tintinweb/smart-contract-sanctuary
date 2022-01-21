// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Companions.sol";

contract TheSevensDojoV2 is Ownable {

    modifier directOnly {
        require(msg.sender == tx.origin);
        _;
    }

    modifier notPaused {
        require(!paused, "This function is currently paused");
        _;
    }

    event StakedCompanions(address indexed from, uint indexed tokenId, uint timestamp);
    event UnstakedCompanions(address indexed from, uint indexed tokenId, uint timestamp);
    event StakedSevens(address indexed from, uint indexed tokenId, uint timestamp);
    event UnstakedSevens(address indexed from, uint indexed tokenId, uint timestamp);
    event ClaimedReward(address indexed from, uint amount, uint timestamp);

    mapping(address => uint) public companionsTokensStaked;
    mapping(uint => address) public ownerOfCompanionsToken;

    mapping(address => uint) public sevensTokensStaked;
    mapping(uint => address) public ownerOfSevensToken;

    mapping(address => uint) public lastClaimOfOwner;
    mapping(address => uint) public addressToPendingClaim;

    // Per second
    uint constant companionsReward = (uint(3e18) / 1 days) + 1;
    uint constant sevensReward = (uint(7e18) / 1 days) + 1;
    uint constant bothReward = (uint(10e18) / 1 days) + 1;

    IERC20 rewardContract;
    IERC721Enumerable immutable sevensContract;
    TheSevensCompanions immutable companionsContract;

    bool public paused = false;
    bool public emergency = false;

    constructor(IERC20 rewardContract_, IERC721Enumerable sevensContract_, TheSevensCompanions companionsContract_) {
        rewardContract = rewardContract_;
        sevensContract = sevensContract_;
        companionsContract = companionsContract_;
    }

    // Public/External State-Changing

    function stakeAndUnstake(uint[] memory companionsStakes,uint[] memory companionsUnstakes,uint[] memory sevensStakes,uint[] memory sevensUnstakes, bool claimTokens) directOnly notPaused external {
        if(claimTokens) {
            claim();
        } else {
            updateRewards(msg.sender);
        }

        for(uint i = 0; i < companionsStakes.length; i++) { 
            stakeCompanions(companionsStakes[i]);
        }
        for(uint i = 0; i < companionsUnstakes.length; i++) {
            unstakeCompanions(companionsUnstakes[i]);
        }
        for(uint i = 0; i < sevensStakes.length; i++) {
            stakeSevens(sevensStakes[i]);
        }
        for(uint i = 0; i < sevensUnstakes.length; i++) {
            unstakeSevens(sevensUnstakes[i]);
        }
    }

    function claim() public directOnly notPaused {
        address to = msg.sender;
        updateRewards(to);
        uint amount = addressToPendingClaim[to];
        if(amount != 0) {
            addressToPendingClaim[to] = 0;
            rewardContract.transfer(to, amount);
            emit ClaimedReward(msg.sender, amount, block.timestamp);
        }
    }

    function updateRewards(address addr) internal {
        require(!emergency, "You can't use this function at this time");
        addressToPendingClaim[addr] += getClaimAmount(addr, false);
        lastClaimOfOwner[addr] = block.timestamp;
    }

    // Public/External Non-State-Changing

    function getClaimAmount(address addr, bool perDay) public view returns(uint) {
        uint lastClaim = lastClaimOfOwner[addr];
        if(lastClaim == 0)
            return 0;

        uint totalClaimTime = perDay ? 1 days : block.timestamp - lastClaimOfOwner[addr];
        uint companionsCount = companionsTokensStaked[addr];
        uint sevensCount = sevensTokensStaked[addr];
        if(companionsCount == 0 && sevensCount == 0) 
            return 0;

        return (
                (companionsCount * companionsReward * totalClaimTime) +             // Each Companion
                (sevensCount * sevensReward * totalClaimTime) +                     // Each Sevens
                (min(companionsCount, sevensCount) * bothReward * totalClaimTime)   // Each combo (1 comp + 1 sevens)
            );
    }

    function walletOfOwner(address addr) external view returns(uint[] memory companionsTokens, uint[] memory sevensTokens) {
        unchecked {
            companionsTokens = new uint[](companionsTokensStaked[addr]);
            sevensTokens = new uint[](sevensTokensStaked[addr]);
            uint cnext = 0;
            uint snext = 0;
            for(uint i = 1; i <= companionsContract.totalSupply(); i++) { // 1 ~ totalSupply
                if(ownerOfCompanionsToken[i] == addr)
                    companionsTokens[cnext++] = i;
            }
            for(uint i = 0; i < sevensContract.totalSupply(); i++) { // 0 ~ totalSupply - 1
                if(ownerOfSevensToken[i] == addr)
                    sevensTokens[snext++] = i;
            }
        }
    }

    // Internal

    function stakeCompanions(uint tokenId) internal {
        companionsContract.takeToken(msg.sender, tokenId);
        companionsTokensStaked[msg.sender]++;
        ownerOfCompanionsToken[tokenId] = msg.sender;
        emit StakedCompanions(msg.sender, tokenId, block.timestamp);
    }

    function unstakeCompanions(uint tokenId) internal {
        require(ownerOfCompanionsToken[tokenId] == msg.sender);

        ownerOfCompanionsToken[tokenId] = address(0);
        companionsTokensStaked[msg.sender]--;
        companionsContract.transferFrom(address(this), msg.sender, tokenId);
        emit UnstakedCompanions(msg.sender, tokenId, block.timestamp);
    }

    function stakeSevens(uint tokenId) internal {
        sevensContract.transferFrom(msg.sender, address(this), tokenId);
        sevensTokensStaked[msg.sender]++;
        ownerOfSevensToken[tokenId] = msg.sender;
        emit StakedSevens(msg.sender, tokenId, block.timestamp);
    }

    function unstakeSevens(uint tokenId) internal {
        require(ownerOfSevensToken[tokenId] == msg.sender);

        ownerOfSevensToken[tokenId] = address(0);
        sevensTokensStaked[msg.sender]--;
        sevensContract.transferFrom(address(this), msg.sender, tokenId);
        emit UnstakedSevens(msg.sender, tokenId, block.timestamp);
    }

    function min(uint a, uint b) internal pure returns(uint) {
        return (a < b ? a : b);
    }

    // Only Owner

    function withdrawReward(uint amount) external onlyOwner {
        rewardContract.transfer(msg.sender, amount);
    }

    function setRewardContract(IERC20 rewardContract_) external onlyOwner {
        rewardContract = rewardContract_;
    }

    function flipPause() external onlyOwner {
        paused = !paused;
    }

    function flipEmergency() external onlyOwner {
        emergency = !emergency;
    }


    // Emergency only

    function emergencyWithdrawCompanion(uint tokenId) external directOnly {
        require(emergency);
        lastClaimOfOwner[msg.sender] = block.timestamp;
        unstakeCompanions(tokenId);
    }

    function emergencyWithdrawSevens(uint tokenId) external directOnly {
        require(emergency);
        lastClaimOfOwner[msg.sender] = block.timestamp;
        unstakeSevens(tokenId);
    }

}