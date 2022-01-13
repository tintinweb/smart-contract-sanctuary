// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./open-zeppelin/interfaces/IERC20.sol";
import "./open-zeppelin/libraries/SafeERC20.sol";
import "./open-zeppelin/utils/Ownable.sol";
import "./open-zeppelin/utils/Pausable.sol";
import "./open-zeppelin/utils/ReentrancyGuard.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IVotingEscrowDelegation.sol";

/** @title Warden contract  */
/// @author Paladin
/*
    Delegation market based on Curve VotingEscrowDelegation contract
*/
contract Warden is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constants :
    uint256 public constant UNIT = 1e18;
    uint256 public constant MAX_PCT = 10000;
    uint256 public constant WEEK = 7 * 86400;

    // Storage :

    /** @notice Offer made by an user to buy a given amount of his votes 
    user : Address of the user making the offer
    pricePerVote : Price per vote per second, set by the user
    minPerc : Minimum percent of users voting token balance to buy for a Boost (in BPS)
    maxPerc : Maximum percent of users total voting token balance available to delegate (in BPS)
    */
    struct BoostOffer {
        // Address of the user making the offer
        address user;
        // Price per vote per second, set by the user
        uint256 pricePerVote;
        // Minimum percent of users voting token balance to buy for a Boost
        uint16 minPerc; //bps
        // Maximum percent of users total voting token balance available to delegate
        uint16 maxPerc; //bps
    }

    /** @notice ERC20 used to pay for DelegationBoost */
    IERC20 public feeToken;
    /** @notice Address of the votingToken to delegate */
    IVotingEscrow public votingEscrow;
    /** @notice Address of the Delegation Boost contract */
    IVotingEscrowDelegation public delegationBoost;

    /** @notice ratio of fees to be set as Reserve (in BPS) */
    uint256 public feeReserveRatio; //bps
    /** @notice Total Amount in the Reserve */
    uint256 public reserveAmount;
    /** @notice Address allowed to withdraw from the Reserve */
    address public reserveManager;

    /** @notice Min Percent of delegator votes to buy required to purchase a Delegation Boost (in BPS) */
    uint256 public minPercRequired; //bps

    /** @notice Minimum delegation time, taken from veBoost contract */
    uint256 public minDelegationTime = 1 weeks;

    /** @notice List of all current registered users and their delegation offer */
    BoostOffer[] public offers;

    /** @notice Index of the user in the offers array */
    mapping(address => uint256) public userIndex;

    /** @notice Amount of fees earned by users through Boost selling */
    mapping(address => uint256) public earnedFees;

    bool private _claimBlocked;

    // Events :

    event Registred(address indexed user, uint256 price);

    event UpdateOffer(address indexed user, uint256 newPrice);

    event Quit(address indexed user);

    event BoostPurchase(
        address indexed delegator,
        address indexed receiver,
        uint256 tokenId,
        uint256 percent, //bps
        uint256 price,
        uint256 paidFeeAmount,
        uint256 expiryTime
    );

    event Claim(address indexed user, uint256 amount);

    modifier onlyAllowed(){
        require(msg.sender == reserveManager || msg.sender == owner(), "Warden: Not allowed");
        _;
    }

    // Constructor :
    /**
     * @dev Creates the contract, set the given base parameters
     * @param _feeToken address of the token used to pay fees
     * @param _votingEscrow address of the voting token to delegate
     * @param _delegationBoost address of the contract handling delegation
     * @param _feeReserveRatio Percent of fees to be set as Reserve (bps)
     * @param _minPercRequired Minimum percent of user
     */
    constructor(
        address _feeToken,
        address _votingEscrow,
        address _delegationBoost,
        uint256 _feeReserveRatio, //bps
        uint256 _minPercRequired //bps
    ) {
        feeToken = IERC20(_feeToken);
        votingEscrow = IVotingEscrow(_votingEscrow);
        delegationBoost = IVotingEscrowDelegation(_delegationBoost);

        require(_feeReserveRatio <= 5000);
        require(_minPercRequired > 0 && _minPercRequired <= 10000);
        feeReserveRatio = _feeReserveRatio;
        minPercRequired = _minPercRequired;

        // fill index 0 in the offers array
        // since we want to use index 0 for unregistered users
        offers.push(BoostOffer(address(0), 0, 0, 0));
    }

    // Functions :

    function offersIndex() external view returns(uint256){
        return offers.length;
    }

    /**
     * @notice Registers a new user wanting to sell its delegation
     * @dev Regsiters a new user, creates a BoostOffer with the given parameters
     * @param pricePerVote Price of 1 vote per second (in wei)
     * @param minPerc Minimum percent of users voting token balance to buy for a Boost (in BPS)
     * @param maxPerc Maximum percent of users total voting token balance available to delegate (in BPS)
     */
    function register(
        uint256 pricePerVote,
        uint16 minPerc,
        uint16 maxPerc
    ) external whenNotPaused returns(bool) {
        address user = msg.sender;
        require(userIndex[user] == 0, "Warden: Already registered");
        require(
            delegationBoost.isApprovedForAll(user, address(this)),
            "Warden: Not operator for caller"
        );

        require(pricePerVote > 0, "Warden: Price cannot be 0");
        require(maxPerc <= 10000, "Warden: maxPerc too high");
        require(minPerc <= maxPerc, "Warden: minPerc is over maxPerc");
        require(minPerc >= minPercRequired, "Warden: minPerc too low");

        // Create the BoostOffer for the new user, and add it to the storage
        userIndex[user] = offers.length;
        offers.push(BoostOffer(user, pricePerVote, minPerc, maxPerc));

        emit Registred(user, pricePerVote);

        return true;
    }

    /**
     * @notice Updates an user BoostOffer parameters
     * @dev Updates parameters for the user's BoostOffer
     * @param pricePerVote Price of 1 vote per second (in wei)
     * @param minPerc Minimum percent of users voting token balance to buy for a Boost (in BPS)
     * @param maxPerc Maximum percent of users total voting token balance available to delegate (in BPS)
     */
    function updateOffer(
        uint256 pricePerVote,
        uint16 minPerc,
        uint16 maxPerc
    ) external whenNotPaused returns(bool) {
        // Fet the user index, and check for registration
        address user = msg.sender;
        uint256 index = userIndex[user];
        require(index != 0, "Warden: Not registered");

        // Fetch the BoostOffer to update
        BoostOffer storage offer = offers[index];

        require(offer.user == msg.sender, "Warden: Not offer owner");

        require(pricePerVote > 0, "Warden: Price cannot be 0");
        require(maxPerc <= 10000, "Warden: maxPerc too high");
        require(minPerc <= maxPerc, "Warden: minPerc is over maxPerc");
        require(minPerc >= minPercRequired, "Warden: minPerc too low");

        // Update the parameters
        offer.pricePerVote = pricePerVote;
        offer.minPerc = minPerc;
        offer.maxPerc = maxPerc;

        emit UpdateOffer(user, pricePerVote);

        return true;
    }

    /**
     * @notice Remove the BoostOffer of the user, and claim any remaining fees earned
     * @dev User's BoostOffer is removed from the listing, and any unclaimed fees is sent
     */
    function quit() external whenNotPaused nonReentrant returns(bool) {
        address user = msg.sender;
        require(userIndex[user] != 0, "Warden: Not registered");

        // Check for unclaimed fees, claim it if needed
        if (earnedFees[user] > 0) {
            _claim(user, earnedFees[user]);
        }

        // Find the BoostOffer to remove
        uint256 currentIndex = userIndex[user];
        // If BoostOffer is not the last of the list
        // Replace last of the list with the one to remove
        if (currentIndex < offers.length) {
            uint256 lastIndex = offers.length - 1;
            address lastUser = offers[lastIndex].user;
            offers[currentIndex] = offers[lastIndex];
            userIndex[lastUser] = currentIndex;
        }
        //Remove the last item of the list
        offers.pop();
        userIndex[user] = 0;

        emit Quit(user);

        return true;
    }

    /**
     * @notice Gives an estimate of fees to pay for a given Boost Delegation
     * @dev Calculates the amount of fees for a Boost Delegation with the given amount (through the percent) and the duration
     * @param delegator Address of the delegator for the Boost
     * @param percent Percent of the delegator balance to delegate (in BPS)
     * @param duration Duration (in weeks) of the Boost to purchase
     */
    function estimateFees(
        address delegator,
        uint256 percent,
        uint256 duration //in weeks
    ) external view returns (uint256) {
        require(delegator != address(0), "Warden: Zero address");
        require(userIndex[delegator] != 0, "Warden: Not registered");
        require(
            percent >= minPercRequired,
            "Warden: Percent under min required"
        );
        require(percent <= MAX_PCT, "Warden: Percent over 100");

        // Get the duration in seconds, and check it's more than the minimum required
        uint256 durationSeconds = duration * 1 weeks;
        require(
            durationSeconds >= minDelegationTime,
            "Warden: Duration too short"
        );

        // Fetch the BoostOffer for the delegator
        BoostOffer storage offer = offers[userIndex[delegator]];

        require(
            percent >= offer.minPerc && percent <= offer.maxPerc,
            "Warden: Percent out of Offer bounds"
        );
        uint256 expiryTime = ((block.timestamp + durationSeconds) / WEEK) * WEEK;
        expiryTime = (expiryTime < block.timestamp + durationSeconds) ?
            ((block.timestamp + durationSeconds + WEEK) / WEEK) * WEEK :
            expiryTime;
        require(
            expiryTime <= votingEscrow.locked__end(delegator),
            "Warden: Lock expires before Boost"
        );

        // Find how much of the delegator's tokens the given percent represents
        uint256 delegatorBalance = votingEscrow.balanceOf(delegator);
        uint256 toDelegateAmount = (delegatorBalance * percent) / MAX_PCT;

        // Get the price for the whole Amount (price fer second)
        uint256 priceForAmount = (toDelegateAmount * offer.pricePerVote) / UNIT;

        // Then multiply it by the duration (in seconds) to get the cost of the Boost
        return priceForAmount * durationSeconds;
    }

    /** 
        All local variables used in the buyDelegationBoost function
     */
    struct BuyVars {
        uint256 boostDuration;
        uint256 delegatorBalance;
        uint256 toDelegateAmount;
        uint256 realFeeAmount;
        uint256 expiryTime;
        uint256 cancelTime;
        uint256 boostPercent;
        uint256 newId;
        uint256 newTokenId;
    }

    /**
     * @notice Buy a Delegation Boost for a Delegator Offer
     * @dev If all parameters match the offer from the delegator, creates a Boost for the caller
     * @param delegator Address of the delegator for the Boost
     * @param receiver Address of the receiver of the Boost
     * @param percent Percent of the delegator balance to delegate (in BPS)
     * @param duration Duration (in weeks) of the Boost to purchase
     * @param maxFeeAmount Maximum amount of feeToken available to pay to cover the Boost Duration (in wei)
     * returns the id of the new veBoost
     */
    function buyDelegationBoost(
        address delegator,
        address receiver,
        uint256 percent,
        uint256 duration, //in weeks
        uint256 maxFeeAmount
    ) external nonReentrant whenNotPaused returns(uint256) {
        require(
            delegator != address(0) && receiver != address(0),
            "Warden: Zero address"
        );
        require(userIndex[delegator] != 0, "Warden: Not registered");
        require(maxFeeAmount > 0, "Warden: No fees");
        require(
            percent >= minPercRequired,
            "Warden: Percent under min required"
        );
        require(percent <= MAX_PCT, "Warden: Percent over 100");

        BuyVars memory vars;

        // Get the duration of the wanted Boost in seconds
        vars.boostDuration = duration * 1 weeks;
        require(
            vars.boostDuration >= minDelegationTime,
            "Warden: Duration too short"
        );

        // Fetch the BoostOffer for the delegator
        BoostOffer storage offer = offers[userIndex[delegator]];

        require(
            percent >= offer.minPerc && percent <= offer.maxPerc,
            "Warden: Percent out of Offer bounds"
        );

        // Find how much of the delegator's tokens the given percent represents
        vars.delegatorBalance = votingEscrow.balanceOf(delegator);
        vars.toDelegateAmount = (vars.delegatorBalance * percent) / MAX_PCT;

        // Check if delegator can delegate the amount, without exceeding the maximum percent allowed by the delegator
        // _canDelegate will also try to cancel expired Boosts of the deelgator to free more tokens for delegation
        require(
            _canDelegate(delegator, vars.toDelegateAmount, offer.maxPerc),
            "Warden: Cannot delegate"
        );

        // Calculate the price for the given duration, get the real amount of fees to pay,
        // and check the maxFeeAmount provided (and approved beforehand) is enough.
        // Calculated using the pricePerVote set by the delegator
        vars.realFeeAmount = (vars.toDelegateAmount * offer.pricePerVote * vars.boostDuration) / UNIT;
        require(
            vars.realFeeAmount <= maxFeeAmount,
            "Warden: Fees do not cover Boost duration"
        );

        // Pull the tokens from the buyer, setting it as earned fees for the delegator (and part of it for the Reserve)
        _pullFees(msg.sender, vars.realFeeAmount, delegator);

        // Calcualte the expiry time for the Boost = now + duration
        vars.expiryTime = ((block.timestamp + vars.boostDuration) / WEEK) * WEEK;

        // Hack needed because veBoost contract rounds down expire_time
        // We don't want buyers to receive less than they pay for
        // So an "extra" week is added if needed to get an expire_time covering the required duration
        // But cancel_time will be set for the exact paid duration, so any "bonus days" received can be canceled
        // if a new buyer wants to take the offer
        vars.expiryTime = (vars.expiryTime < block.timestamp + vars.boostDuration) ?
            ((block.timestamp + vars.boostDuration + WEEK) / WEEK) * WEEK :
            vars.expiryTime;
        require(
            vars.expiryTime <= votingEscrow.locked__end(delegator),
            "Warden: Lock expires before Boost"
        );

        // VotingEscrowDelegation needs the percent of available tokens for delegation when creating the boost, instead of
        // the percent of the users balance. We calculate this percent representing the amount of tokens wanted by the buyer
        vars.boostPercent = (vars.toDelegateAmount * MAX_PCT) / 
            (vars.delegatorBalance - delegationBoost.delegated_boost(delegator));

        // Get the id (depending on the delegator) for the new Boost
        vars.newId = delegationBoost.total_minted(delegator);
        unchecked {
            // cancelTime stays current timestamp + paid duration
            // Should not overflow : Since expiryTime is the same + some extra time, expiryTime >= cancelTime
            vars.cancelTime = block.timestamp + vars.boostDuration;
        }

        // Creates the DelegationBoost
        delegationBoost.create_boost(
            delegator,
            receiver,
            int256(vars.boostPercent),
            vars.cancelTime,
            vars.expiryTime,
            vars.newId
        );

        // Fetch the tokenId for the new DelegationBoost that was created, and check it was set for the correct delegator
        vars.newTokenId = delegationBoost.get_token_id(delegator, vars.newId);
        require(
            vars.newTokenId ==
                delegationBoost.token_of_delegator_by_index(delegator, vars.newId),
            "Warden: DelegationBoost failed"
        );

        emit BoostPurchase(
            delegator,
            receiver,
            vars.newTokenId,
            percent,
            offer.pricePerVote,
            vars.realFeeAmount,
            vars.expiryTime
        );

        return vars.newTokenId;
    }

    /**
     * @notice Cancels a DelegationBoost
     * @dev Cancels a DelegationBoost :
     * In case the caller is the owner of the Boost, at any time
     * In case the caller is the delegator for the Boost, after cancel_time
     * Else, after expiry_time
     * @param tokenId Id of the DelegationBoost token to cancel
     */
    function cancelDelegationBoost(uint256 tokenId) external whenNotPaused returns(bool) {
        address tokenOwner = delegationBoost.ownerOf(tokenId);
        // If the caller own the token, and this contract is operator for the owner
        // we try to burn the token directly
        if (
            msg.sender == tokenOwner &&
            delegationBoost.isApprovedForAll(tokenOwner, address(this))
        ) {
            delegationBoost.burn(tokenId);
            return true;
        }

        uint256 currentTime = block.timestamp;

        // Delegator can cancel the Boost if Cancel Time passed
        address delegator = _getTokenDelegator(tokenId);
        if (
            delegationBoost.token_cancel_time(tokenId) < currentTime &&
            (msg.sender == delegator &&
                delegationBoost.isApprovedForAll(delegator, address(this)))
        ) {
            delegationBoost.cancel_boost(tokenId);
            return true;
        }

        // Else, we wait Exipiry Time, so anyone can cancel the delegation
        if (delegationBoost.token_expiry(tokenId) < currentTime) {
            delegationBoost.cancel_boost(tokenId);
            return true;
        }

        revert("Cannot cancel the boost");
    }

    /**
     * @notice Returns the amount of fees earned by the user that can be claimed
     * @dev Returns the value in earnedFees for the given user
     * @param user Address of the user
     */
    function claimable(address user) external view returns (uint256) {
        return earnedFees[user];
    }

    /**
     * @notice Claims all earned fees
     * @dev Send all the user's earned fees
     */
    function claim() external nonReentrant returns(bool) {
        require(
            earnedFees[msg.sender] != 0,
            "Warden: Claim null amount"
        );
        return _claim(msg.sender, earnedFees[msg.sender]);
    }

    /**
     * @notice Claims all earned fees, and cancel all expired Delegation Boost for the user
     * @dev Send all the user's earned fees, and fetch all expired Boosts to cancel them
     */
    function claimAndCancel() external nonReentrant returns(bool) {
        _cancelAllExpired(msg.sender);
        return _claim(msg.sender, earnedFees[msg.sender]);
    }

    /**
     * @notice Claims an amount of earned fees through Boost Delegation selling
     * @dev Send the given amount of earned fees (if amount is correct)
     * @param amount Amount of earned fees to claim
     */
    function claim(uint256 amount) external nonReentrant returns(bool) {
        require(amount <= earnedFees[msg.sender], "Warden: Amount too high");
        require(
            amount != 0,
            "Warden: Claim null amount"
        );
        return _claim(msg.sender, amount);
    }

    function _pullFees(
        address buyer,
        uint256 amount,
        address seller
    ) internal {
        // Pull the given token amount ot this contract (must be approved beforehand)
        feeToken.safeTransferFrom(buyer, address(this), amount);

        // Split fees between Boost offerer & Reserve
        earnedFees[seller] += (amount * (MAX_PCT - feeReserveRatio)) / MAX_PCT;
        reserveAmount += (amount * feeReserveRatio) / MAX_PCT;
    }

    function _canDelegate(
        address delegator,
        uint256 amount,
        uint256 delegatorMaxPerc
    ) internal returns (bool) {
        if (!delegationBoost.isApprovedForAll(delegator, address(this)))
            return false;

        // Delegator current balance
        uint256 balance = votingEscrow.balanceOf(delegator);

        // Percent of delegator balance not allowed to delegate (as set by maxPerc in the BoostOffer)
        uint256 blockedBalance = (balance * (MAX_PCT - delegatorMaxPerc)) / MAX_PCT;

        // Available Balance to delegate = VotingEscrow Balance - Blocked Balance
        uint256 availableBalance = balance - blockedBalance;
        // Then need to check what is the amount currently delegated out of the Available Balance
        uint256 delegatedBalance = delegationBoost.delegated_boost(delegator);

        if(availableBalance > delegatedBalance){
            if(amount <= (availableBalance - delegatedBalance)) return true;
        }

        // Check if cancel expired Boosts could bring enough to delegate
        uint256 potentialCancelableBalance = 0;

        uint256 nbTokens = delegationBoost.total_minted(delegator);
        uint256[256] memory toCancel; //Need this type of array because of batch_cancel_boosts() from veBoost
        uint256 nbToCancel = 0;

        // Loop over the delegator current boosts to find expired ones
        for (uint256 i = 0; i < nbTokens; i++) {
            uint256 tokenId = delegationBoost.token_of_delegator_by_index(
                delegator,
                i
            );

            if (delegationBoost.token_cancel_time(tokenId) <= block.timestamp && delegationBoost.token_cancel_time(tokenId) != 0) {
                int256 boost = delegationBoost.token_boost(tokenId);
                uint256 absolute_boost = boost >= 0 ? uint256(boost) : uint256(-boost);
                potentialCancelableBalance += absolute_boost;
                toCancel[nbToCancel] = tokenId;
                nbToCancel++;
            }
        }

        // If the current Boosts are more than the availableBalance => No balance available for a new Boost
        if (availableBalance < (delegatedBalance - potentialCancelableBalance)) return false;
        // If canceling the tokens can free enough to delegate,
        // cancel the batch and return true
        if (amount <= (availableBalance - (delegatedBalance - potentialCancelableBalance)) && nbToCancel > 0) {
            delegationBoost.batch_cancel_boosts(toCancel);
            return true;
        }

        return false;
    }

    function _cancelAllExpired(address delegator) internal {
        uint256 nbTokens = delegationBoost.total_minted(delegator);
        // Delegator does not have active Boosts currently
        if (nbTokens == 0) return;

        uint256[256] memory toCancel;
        uint256 nbToCancel = 0;
        uint256 currentTime = block.timestamp;

        // Loop over the delegator current boosts to find expired ones
        for (uint256 i = 0; i < nbTokens; i++) {
            uint256 tokenId = delegationBoost.token_of_delegator_by_index(
                delegator,
                i
            );
            uint256 cancelTime = delegationBoost.token_cancel_time(tokenId);

            if (cancelTime <= currentTime && cancelTime != 0) {
                toCancel[nbToCancel] = tokenId;
                nbToCancel++;
            }
        }

        // If Boost were found, cancel the batch
        if (nbToCancel > 0) {
            delegationBoost.batch_cancel_boosts(toCancel);
        }
    }

    function _claim(address user, uint256 amount) internal returns(bool) {
        require(
            !_claimBlocked,
            "Warden: Claim blocked"
        );
        require(
            amount <= feeToken.balanceOf(address(this)),
            "Warden: Insufficient cash"
        );

        if(amount == 0) return true; // nothing to claim, but used in claimAndCancel()

        // If fees to be claimed, update the mapping, and send the amount
        unchecked{
            // Should not underflow, since the amount was either checked in the claim() method, or set as earnedFees[user]
            earnedFees[user] -= amount;
        }

        feeToken.safeTransfer(user, amount);

        emit Claim(user, amount);

        return true;
    }

    function _getTokenDelegator(uint256 tokenId)
        internal
        pure
        returns (address)
    {
        //Extract the address from the token id : See VotingEscrowDelegation.vy for the logic
        return address(uint160(tokenId >> 96));
    }

    // Admin Functions :

    /**
     * @notice Updates the minimum percent required to buy a Boost
     * @param newMinPercRequired New minimum percent required to buy a Boost (in BPS)
     */
    function setMinPercRequired(uint256 newMinPercRequired) external onlyOwner {
        require(newMinPercRequired > 0 && newMinPercRequired <= 10000);
        minPercRequired = newMinPercRequired;
    }

        /**
     * @notice Updates the minimum delegation time
     * @param newMinDelegationTime New minimum deelgation time (in seconds)
     */
    function setMinDelegationTime(uint256 newMinDelegationTime) external onlyOwner {
        require(newMinDelegationTime > 0);
        minDelegationTime = newMinDelegationTime;
    }

    /**
     * @notice Updates the ratio of Fees set for the Reserve
     * @param newFeeReserveRatio New ratio (in BPS)
     */
    function setFeeReserveRatio(uint256 newFeeReserveRatio) external onlyOwner {
        require(newFeeReserveRatio <= 5000);
        feeReserveRatio = newFeeReserveRatio;
    }

    /**
     * @notice Updates the Delegation Boost (veBoost)
     * @param newDelegationBoost New veBoost contract address
     */
    function setDelegationBoost(address newDelegationBoost) external onlyOwner {
        delegationBoost = IVotingEscrowDelegation(newDelegationBoost);
    }

    /**
     * @notice Updates the Reserve Manager
     * @param newReserveManager New Reserve Manager address
     */
    function setReserveManager(address newReserveManager) external onlyOwner {
        reserveManager = newReserveManager;
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Block user fee claims
     */
    function blockClaim() external onlyOwner {
        require(
            !_claimBlocked,
            "Warden: Claim blocked"
        );
        _claimBlocked = true;
    }

    /**
     * @notice Unblock user fee claims
     */
    function unblockClaim() external onlyOwner {
        require(
            _claimBlocked,
            "Warden: Claim not blocked"
        );
        _claimBlocked = false;
    }

    /**
     * @dev Withdraw either a lost ERC20 token sent to the contract (expect the feeToken)
     * @param token ERC20 token to withdraw
     * @param amount Amount to transfer (in wei)
     */
    function withdrawERC20(address token, uint256 amount) external onlyOwner returns(bool) {
        require(_claimBlocked || token != address(feeToken), "Warden: cannot withdraw fee Token"); //We want to be able to recover the fees if there is an issue
        IERC20(token).safeTransfer(owner(), amount);

        return true;
    }

    function depositToReserve(address from, uint256 amount) external onlyAllowed returns(bool) {
        reserveAmount = reserveAmount + amount;
        feeToken.safeTransferFrom(from, address(this), amount);

        return true;
    }

    function withdrawFromReserve(uint256 amount) external onlyAllowed returns(bool) {
        require(amount <= reserveAmount, "Warden: Reserve too low");
        reserveAmount = reserveAmount - amount;
        feeToken.safeTransfer(reserveManager, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve VotingEscrow contract  */
interface IVotingEscrow {
    
    function balanceOf(address _account) external view returns (uint256);

    function create_lock(uint256 _value, uint256 _unlock_time) external returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve VotingEscrowDelegation contract  */
interface IVotingEscrowDelegation {

    function isApprovedForAll(address owner, address operator) external view returns(bool);

    function ownerOf(uint256 tokenId) external view returns(address);

    function balanceOf(uint256 tokenId) external view returns(uint256);

    function token_of_delegator_by_index(address delegator, uint256 index) external view returns(uint256);

    function total_minted(address delegator) external view returns(uint256);

    function grey_list(address receiver, address delegator) external view returns(bool);

    function setApprovalForAll(address _operator, bool _approved) external;

    function create_boost(
        address _delegator,
        address _receiver,
        int256 _percentage,
        uint256 _cancel_time,
        uint256 _expire_time,
        uint256 _id
    ) external;

    function extend_boost(
        uint256 _token_id,
        int256 _percentage,
        uint256 _cancel_time,
        uint256 _expire_time
    ) external;

    function burn(uint256 _token_id) external;

    function cancel_boost(uint256 _token_id) external;

    function batch_cancel_boosts(uint256[256] memory _token_ids) external;

    function adjusted_balance_of(address _account) external view returns(uint256);

    function delegated_boost(address _account) external view returns(uint256);

    function token_boost(uint256 _token_id) external view returns(int256);

    function token_cancel_time(uint256 _token_id) external view returns(uint256);

    function token_expiry(uint256 _token_id) external view returns(uint256);

    function get_token_id(address _delegator, uint256 _id) external view returns(uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}