pragma solidity ^0.4.13;

interface CompetitionInterface {

    // EVENTS

    event Register(uint withId, address fund, address manager);
    event ClaimReward(address registrant, address fund, uint shares);

    // PRE, POST, INVARIANT CONDITIONS

    function termsAndConditionsAreSigned(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool);
    function isWhitelisted(address x) view returns (bool);
    function isCompetitionActive() view returns (bool);

    // CONSTANT METHODS

    function getMelonAsset() view returns (address);
    function getRegistrantId(address x) view returns (uint);
    function getRegistrantFund(address x) view returns (address);
    function getCompetitionStatusOfRegistrants() view returns (address[], address[], bool[]);
    function getTimeTillEnd() view returns (uint);
    function getEtherValue(uint amount) view returns (uint);
    function calculatePayout(uint payin) view returns (uint);

    // PUBLIC METHODS

    function registerForCompetition(address fund, uint8 v, bytes32 r, bytes32 s) payable;
    function batchAddToWhitelist(uint maxBuyinQuantity, address[] whitelistants);
    function withdrawMln(address to, uint amount);
    function claimReward();

}

interface ComplianceInterface {

    // PUBLIC VIEW METHODS

    /// @notice Checks whether investment is permitted for a participant
    /// @param ofParticipant Address requesting to invest in a Melon fund
    /// @param giveQuantity Quantity of Melon token times 10 ** 18 offered to receive shareQuantity
    /// @param shareQuantity Quantity of shares times 10 ** 18 requested to be received
    /// @return Whether identity is eligible to invest in a Melon fund.
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    ) view returns (bool);

    /// @notice Checks whether redemption is permitted for a participant
    /// @param ofParticipant Address requesting to redeem from a Melon fund
    /// @param shareQuantity Quantity of shares times 10 ** 18 offered to redeem
    /// @param receiveQuantity Quantity of Melon token times 10 ** 18 requested to receive for shareQuantity
    /// @return Whether identity is eligible to redeem from a Melon fund.
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    ) view returns (bool);
}

contract DBC {

    // MODIFIERS

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Owned is DBC {

    // FIELDS

    address public owner;

    // NON-CONSTANT METHODS

    function Owned() { owner = msg.sender; }

    function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }

    // PRE, POST, INVARIANT CONDITIONS

    function isOwner() internal returns (bool) { return msg.sender == owner; }

}

contract CompetitionCompliance is ComplianceInterface, DBC, Owned {

    address public competitionAddress;

    // CONSTRUCTOR

    /// @dev Constructor
    /// @param ofCompetition Address of the competition contract
    function CompetitionCompliance(address ofCompetition) public {
        competitionAddress = ofCompetition;
    }

    // PUBLIC VIEW METHODS

    /// @notice Checks whether investment is permitted for a participant
    /// @param ofParticipant Address requesting to invest in a Melon fund
    /// @param giveQuantity Quantity of Melon token times 10 ** 18 offered to receive shareQuantity
    /// @param shareQuantity Quantity of shares times 10 ** 18 requested to be received
    /// @return Whether identity is eligible to invest in a Melon fund.
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

    /// @notice Checks whether redemption is permitted for a participant
    /// @param ofParticipant Address requesting to redeem from a Melon fund
    /// @param shareQuantity Quantity of shares times 10 ** 18 offered to redeem
    /// @param receiveQuantity Quantity of Melon token times 10 ** 18 requested to receive for shareQuantity
    /// @return isEligible Whether identity is eligible to redeem from a Melon fund.
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

    /// @notice Checks whether an address is whitelisted in the competition contract and competition is active
    /// @param x Address
    /// @return Whether the address is whitelisted
    function isCompetitionAllowed(
        address x
    )
        view
        returns (bool)
    {
        return CompetitionInterface(competitionAddress).isWhitelisted(x) && CompetitionInterface(competitionAddress).isCompetitionActive();
    }


    // PUBLIC METHODS

    /// @notice Changes the competition address
    /// @param ofCompetition Address of the competition contract
    function changeCompetitionAddress(
        address ofCompetition
    )
        pre_cond(isOwner())
    {
        competitionAddress = ofCompetition;
    }

}