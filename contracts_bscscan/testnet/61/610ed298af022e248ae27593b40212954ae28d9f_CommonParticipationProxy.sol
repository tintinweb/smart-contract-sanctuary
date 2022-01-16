//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./RPGC.sol";


contract CommonParticipationProxy is TokenProviderRole, Ownable, AdminRole{

    using SafeMath for *;

    uint public totalTokensToDistribute;
    uint public totalTokensWithdrawn;
    string public name;

    struct Participation {
        uint256 totalParticipation;
        uint256 withdrawnAmount;
        uint256 lastWithdrawnPortionId;
    }

    IERC20 public token;

    mapping(address => Participation) private addressToParticipation;
    mapping(address => bool) public hasParticipated;

    uint public numberOfPortions;
    uint public timeBetweenPortions;
    uint[] distributionDates;
    uint[] portionsUnlockingPercents;

    event NewPercentages(uint[] portionPercents);
    event NewDates(uint[] distrDates);

    /// Load initial distribution dates
    constructor (
        uint _numberOfPortions,
        uint _timeBetweenPortions,
        uint[] memory _portionsUnlockingPercents,
        address _adminWallet,
        address _token,
        string memory _name
    )
    {
        require(_numberOfPortions == _portionsUnlockingPercents.length, 
            "number of portions is not equal to number of percents");

        // Store number of portions
        numberOfPortions = _numberOfPortions;
        // Store time between portions
        timeBetweenPortions = _timeBetweenPortions;

        require(correctPercentages(_portionsUnlockingPercents), "total percent has to be equal to 100%");
        portionsUnlockingPercents = _portionsUnlockingPercents;

        // Set the token address
        token = IERC20(_token);
        name = _name;

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
        if (distributionDates.length != 0){
            require(distributionDates[0] > block.timestamp, "sales have ended");
        }


        totalTokensToDistribute = totalTokensToDistribute.add(participationAmount);

        // Create new participation object
        Participation storage p = addressToParticipation[participant];
        
        p.totalParticipation = p.totalParticipation.add(participationAmount);

        if (!hasParticipated[participant]){
            p.withdrawnAmount = 0;

            p.lastWithdrawnPortionId = ~uint256(0);

            // Mark that user have participated
            hasParticipated[participant] = true;
        }
    }

    // User will always withdraw everything available
    function withdraw()
    external
    {
        require(hasParticipated[msg.sender] == true, "(withdraw) the address is not a participant.");
        require(distributionDates.length != 0, "(withdraw) distribution dates are not set");

        _withdraw();
    }

    function _withdraw() private {
        address user = msg.sender;
        Participation storage p = addressToParticipation[user];

        uint remainLocked = p.totalParticipation.sub(p.withdrawnAmount);
        require(remainLocked > 0, "everything unlocked");
    
        uint256 toWithdraw = 0;
        uint256 amountPerPortion = 0;

        for(uint i = 0; i < distributionDates.length; i++) {
            if(isPortionUnlocked(i) == true) {
                if(p.lastWithdrawnPortionId < i || p.lastWithdrawnPortionId == ~uint256(0)) {
                    // Add this portion to withdraw amount
                    amountPerPortion = p.totalParticipation.mul(portionsUnlockingPercents[i]).div(10000);
                    toWithdraw = toWithdraw.add(amountPerPortion);

                    // Mark portion as withdrawn
                    p.lastWithdrawnPortionId = i;
                }
            }
            else {
                break;
            }
        }
        
        if (isPortionUnlocked(distributionDates.length-1)){
            uint remain = p.totalParticipation.sub(p.withdrawnAmount.add(toWithdraw));
            if (remain > 0){
                toWithdraw = toWithdraw.add(remain);
            }
        } 

        require(toWithdraw > 0, "nothing to withdraw");

        require(p.totalParticipation >= p.withdrawnAmount.add(toWithdraw), "(withdraw) impossible to withdraw more than vested");
        p.withdrawnAmount = p.withdrawnAmount.add(toWithdraw);
        // Account total tokens withdrawn.
        require(totalTokensToDistribute >= totalTokensWithdrawn.add(toWithdraw), "(withdraw) withdraw amount more than distribution");
        totalTokensWithdrawn = totalTokensWithdrawn.add(toWithdraw);
        // Transfer all tokens to user
        token.transfer(user, toWithdraw);
    }

    function startDistribution(uint256 fromDate) public onlyOwner {
        require(distributionDates.length == 0, "(startDistribution) distribution dates already set");

        uint[] memory _distributionDates = new uint[](numberOfPortions);
        for (uint i = 0; i < numberOfPortions; i++){
            
            _distributionDates[i] = fromDate.add(timeBetweenPortions.mul(i));
        }

        distributionDates = _distributionDates;
    }

    function transfer(address recipient, uint256 amount) external onlyTokenProvider returns (bool) {
        RPGC(address(token)).transferToProxy(msg.sender, amount);
        registerParticipant(recipient, amount);
        return true;
    }

    function withdrawUndistributedTokens() external onlyOwner {
        if(distributionDates.length != 0){
            require(block.timestamp > distributionDates[distributionDates.length - 1], 
                "(withdrawUndistributedTokens) only after distribution");
        }
        uint unDistributedAmount = token.balanceOf(address(this)).sub(totalTokensToDistribute.sub(totalTokensWithdrawn));
        require(unDistributedAmount > 0, "(withdrawUndistributedTokens) zero to withdraw");
        token.transfer(owner(), unDistributedAmount);
    }

    function setPercentages(uint256[] calldata _portionPercents) public onlyOwner {
        require(_portionPercents.length == numberOfPortions, 
            "(setPercentages) number of percents is not equal to actual number of portions");
        require(correctPercentages(_portionPercents), "(setPercentages) total percent has to be equal to 100%");
        portionsUnlockingPercents = _portionPercents;

        emit NewPercentages(_portionPercents);
    }

    function updateOneDistrDate(uint index, uint newDate) public onlyAdmin {
        distributionDates[index] = newDate;

        emit NewDates(distributionDates);
    }

    function updateAllDistrDates(uint[] memory newDates) public onlyAdmin {
        require(portionsUnlockingPercents.length == newDates.length, "(updateAllDistrDates) the number of Percentages and Dates do not match");
        distributionDates = newDates;

        emit NewDates(distributionDates);
    }

    function setNewUnlockingSystem(uint[] memory newDates, uint[] memory newPercentages) public onlyAdmin {
        require(newPercentages.length == newDates.length, "(setNewUnlockingSystem) the number of Percentages and Dates do not match");
        require(correctPercentages(newPercentages), "(setNewUnlockingSystem) wrong percentages");
        distributionDates = newDates;
        portionsUnlockingPercents = newPercentages;
        numberOfPortions = newDates.length;

        emit NewDates(distributionDates);
        emit NewPercentages(portionsUnlockingPercents);
    }

    function availableToClaim(address user) public view returns(uint) {
        if (distributionDates.length == 0) {
            return 0;
        }

        Participation memory p = addressToParticipation[user];
        uint256 toWithdraw = 0;
        uint256 amountPerPortion = 0;

        for(uint i = 0; i < distributionDates.length; i++) {
            if(isPortionUnlocked(i) == true) {
                if(p.lastWithdrawnPortionId < i || p.lastWithdrawnPortionId == ~uint256(0)) {
                    // Add this portion to withdraw amount
                    amountPerPortion = p.totalParticipation.mul(portionsUnlockingPercents[i]).div(10000);
                    toWithdraw = toWithdraw.add(amountPerPortion);

                }
            }
            else {
                break;
            }
        }
        
        if (isPortionUnlocked(distributionDates.length-1)){
            uint remain = p.totalParticipation.sub(p.withdrawnAmount.add(toWithdraw));
            if (remain > 0){
                toWithdraw = toWithdraw.add(remain);
            }
        }

        return toWithdraw;
    }

    function correctPercentages(uint[] memory portionsPercentages) internal pure returns(bool) {
        uint totalPercent = 0;
        for(uint i = 0 ; i < portionsPercentages.length; i++) {
            totalPercent = totalPercent.add(portionsPercentages[i]);
        }

        return totalPercent == 10000;
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
    returns (uint256, uint256, uint256)
    {
        Participation memory p = addressToParticipation[account];
        return (
            p.totalParticipation,
            p.withdrawnAmount,
            p.lastWithdrawnPortionId
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

    // Get all distribution percents
    function getDistributionPercents()
    external
    view
    returns (uint256[] memory)
    {
        return portionsUnlockingPercents;
    }

    function balance() public view returns(uint256) {
        return token.balanceOf(address(this));
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
}