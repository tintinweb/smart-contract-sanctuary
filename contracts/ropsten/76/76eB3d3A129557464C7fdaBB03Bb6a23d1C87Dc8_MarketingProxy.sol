//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

import "SafeMath.sol";
import "RPGC.sol";


contract MarketingProxy is TokenProviderRole, Ownable, AdminRole{

    using SafeMath for *;

    uint public totalTokensToDistribute;
    uint public totalTokensWithdrawn;
    IERC20 public token;

    struct Participation {
        uint256 vestedAmount;
        uint unlockedAmount;
        bool[] isVestedPortionWithdrawn;
    }

    mapping(address => Participation) public addressToParticipation;
    mapping(address => bool) public hasParticipated;

    uint[] distributionDates;
    uint[] distributionPercents;

    /// Load initial distribution dates
    constructor (
        uint[] memory _distributionDates,
        uint[] memory _distributionPercents,
        address _adminWallet,
        address _token
    )
    {
        require(_distributionDates.length == _distributionPercents.length, "the number of dates and percenages has to be equal");
        // Check distribution percents
        require(correctPercentages(_distributionPercents), "wrong percentages");

        distributionDates = _distributionDates;
        distributionPercents = _distributionPercents;

        // Set the token address
        token = IERC20(_token);
        _addAdmin(_adminWallet);
    }

    /// Register participant
    function registerParticipant(
        address participant,
        uint participationAmount
    )
    public onlyTokenProvider
    {
        require(totalTokensToDistribute.sub(totalTokensWithdrawn).add(participationAmount) <= token.balanceOf(address(this)),
            "Safeguarding existing token buyers. Not enough tokens."
        );
        require(distributionDates[0] > block.timestamp, "sales have ended");

        totalTokensToDistribute = totalTokensToDistribute.add(participationAmount);

        // Create new participation object
        Participation storage p = addressToParticipation[participant];
        
        p.vestedAmount = p.vestedAmount.add(participationAmount);

        if (!hasParticipated[participant]){
            bool[] memory isPortionWithdrawn = new bool[](distributionDates.length);
            p.isVestedPortionWithdrawn = isPortionWithdrawn;
            p.unlockedAmount = 0;
            // Mark that user have participated
            hasParticipated[participant] = true;
        }
    }


    // User will always withdraw everything available
    function withdraw()
    external
    {
        address user = msg.sender;
        require(hasParticipated[user] == true, "Withdraw: User is not a participant.");

        Participation storage p = addressToParticipation[user];

        uint remainLocked = p.vestedAmount.sub(p.unlockedAmount);
        require(remainLocked > 0, "everything unlocked");

        uint256 toWithdraw = 0;
        uint amountPerPortion;

        for(uint i = 0 ; i < distributionDates.length ; i++) {
            if(!p.isVestedPortionWithdrawn[i]) {
                if(isPortionUnlocked(i) == true) {
                    // Add this portion to withdraw amount
                    amountPerPortion = p.vestedAmount.mul(distributionPercents[i]).div(10000);
                    toWithdraw = toWithdraw.add(amountPerPortion);

                    // Mark portion as withdrawn
                    p.isVestedPortionWithdrawn[i] = true;
                }
                else {
                    break;
                }
            }
        }
        
        uint remain = p.vestedAmount.sub(p.unlockedAmount);
        if (isPortionUnlocked(distributionDates.length-1) && remain > 0){
            toWithdraw = toWithdraw.add(remain);
        } 

        p.unlockedAmount = p.unlockedAmount.add(toWithdraw);
        // Account total tokens withdrawn.
        totalTokensWithdrawn = totalTokensWithdrawn.add(toWithdraw);
        // Transfer all tokens to user
        token.transfer(user, toWithdraw);
    }

    function isPortionUnlocked(uint portionId)
    public
    view
    returns (bool)
    {
        return block.timestamp >= distributionDates[portionId];
    }

    function getParticipation(address account)
    external
    view
    returns (uint256, uint, bool[] memory)
    {
        Participation memory p = addressToParticipation[account];
        return (
            p.vestedAmount,
            p.unlockedAmount,
            p.isVestedPortionWithdrawn
        );
    }

    // Get all distribution dates
    function getDistributionDates()
    external
    view
    returns (uint256[] memory)
    {
        return distributionDates;
    }

    // Method is using by any Exchangers to issue tokens
    function transfer(address recipient, uint256 amount) external onlyTokenProvider returns (bool) {
        RPGC(address(token)).transferToProxy(msg.sender, amount);
        registerParticipant(recipient, amount);
        return true;
    }

    function addTokenProvider(address account) public onlyAdmin {
        require(!isTokenProvider(account), "[Token Provider Role]: account already has token provider role");
        _addTokenProvider(account);
    }

    function removeTokenProvider(address account) public onlyAdmin {
        require(isTokenProvider(account), "[Token Provider Role]: account has not token provider role");
        _removeTokenProvider(account);
    }

    function addAdmin(address account) public onlyOwner {
        require(!isAdmin(account), "[Admin Role]: account already has admin role");
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyOwner {
        require(isAdmin(account), "[Admin Role]: account has not admin role");
        _removeAdmin(account);
    }

    function correctPercentages(uint[] memory percentages) internal pure returns(bool) {
        uint totalPercent = 0;
        for(uint i = 0 ; i < percentages.length; i++) {
            totalPercent = totalPercent.add(percentages[i]);
        }

        if (totalPercent == 10000)
            return true;
        return false;
    } 

    function updateOneDistrDate(uint index, uint newDate) public onlyAdmin {
        distributionDates[index] = newDate;
    }

    function updateAllDistDates(uint[] memory newDates) public onlyAdmin {
        require(distributionPercents.length == newDates.length, "the number of Percentages and Dates do not match");
        distributionDates = newDates;
    }

    function updatePercentages(uint[] memory newPercentages) public onlyAdmin {
        require(newPercentages.length == distributionDates.length, "the number of Percentages and Dates do not match");
        require(correctPercentages(newPercentages), "wrong percentages");
        distributionPercents = newPercentages;
    }

    function setNewUnlockingSystem(uint[] memory newDates, uint[] memory newPercentages) public onlyAdmin {
        require(newPercentages.length == newDates.length, "the number of Percentages and Dates do not match");
        distributionDates = newDates;
        distributionPercents = newPercentages;
    }

    function totalToWithdraw(address user) public view returns(uint) {
        Participation memory p = addressToParticipation[user];
        uint toWithdraw = 0;
        uint amountPerPortion;
        for(uint i = 0 ; i < distributionDates.length ; i++) {
            if(!p.isVestedPortionWithdrawn[i]) {
                if(isPortionUnlocked(i) == true) {
                    // Add this portion to withdraw amount
                    amountPerPortion = p.vestedAmount.mul(distributionPercents[i]).div(10000);
                    toWithdraw = toWithdraw.add(amountPerPortion);
                }
                else {
                    break;
                }
            }
        }

        uint remain = p.vestedAmount.sub(p.unlockedAmount);
        if (isPortionUnlocked(distributionDates.length-1) && remain > 0){
            toWithdraw = toWithdraw.add(remain);
        } 

        return toWithdraw;
    }
}