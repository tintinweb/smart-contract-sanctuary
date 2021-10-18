// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Evaluation.sol";
import "./LockFactory.sol";
import "./Challenger.sol";
import "./ChallengeUtils.sol";

contract ChallengeManager is LockFactory {
    using ChallengeUtils for string;

    uint256 counter = 0;
    Challenger challenger;
    uint256 public gymnasiaFee = 10; //percentage so always divide by 100 before

    struct Challenge {
        uint256 id; //todo remove if not needed in frontend
        address creator;
        string title;
        string description;
        uint256 start;
        uint256 end;
        uint256 currentParticipantsCount;
        uint256 maxParticipantsCount;
        uint256 fee;
        uint256 price;
        address first;
        bool redeemed;
    }

    struct Rules {
        uint32[] types;
        uint32[] conditions;
    }

    struct LeaderboardEntry {
        address challenger;
        uint32[] data; //todo change data to array if multiple challenges in one needed
        uint32[] time;
    }

    mapping(uint256 => LeaderboardEntry[]) public leaderboards;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Rules) internal rules;
    mapping(uint256 => Evaluation) public evaluations;

    function setChallenger(address adr) public {
        challenger = Challenger(adr);
    }

    function setRedeemed(uint256 challengeId) public {
        require(msg.sender == challenger.getAddress(), "NOT_CHALLENGER");
        challenges[challengeId].redeemed = true;
    }

    function setGymnasiaFee(uint256 percentage) external {
        require(
            percentage >= 0 && percentage <= 100,
            "INPUT_HAS_TO_BE_BETWEEN_100_AND_0"
        );
        gymnasiaFee = percentage;
    }

    function getFee(uint256 challengeId) public view returns (uint256) {
        return challenges[challengeId].fee;
    }

    function createChallenge(
        string calldata title,
        uint32[] calldata types,
        uint32[] calldata conditions,
        uint256 start,
        uint256 end,
        uint256 maxParticipantsCount,
        uint256 fee,
        address evaluationAdr
    ) external returns (Challenge memory) {
        //todo keys could be bought before start time through unlock contract
        require(start > block.timestamp, "START_TIME_IN_THE_PAST"); //start
        require(end > start, "END_TIME_BEFORE_START_TIME");
        require(
            types.length == conditions.length,
            "RULE_LENGTHS_IN_CREATION_INPUT_NOT_MATCHING"
        );
        require(conditions.length > 0, "EMPTY_INPUT");

        uint256 lockFeeInPercentage = fee - (fee / 100) * gymnasiaFee;
        createNewLock(
            title,
            counter,
            end - start,
            lockFeeInPercentage,
            maxParticipantsCount
        );

        rules[counter] = Rules(types, conditions);

        challenges[counter].id = counter;
        challenges[counter].creator = msg.sender;
        challenges[counter].title = title;
        challenges[counter].start = start;
        challenges[counter].end = end;
        challenges[counter].maxParticipantsCount = maxParticipantsCount;
        challenges[counter].fee = fee;
        evaluations[counter] = Evaluation(evaluationAdr);

        evaluations[counter].setRules(counter, conditions);

        string memory descriptionOfChallenge = "In this challenge you need to ";

        for (uint256 i = 0; i < conditions.length; i++) {
            descriptionOfChallenge = descriptionOfChallenge.append(
                typeToString(types[i]),
                " ",
                ChallengeUtils.uintToString(conditions[i]),
                "m"
            );

            if (conditions.length > 1 && i != conditions.length - 1)
                descriptionOfChallenge = descriptionOfChallenge.append(" and ");
        }

        challenges[counter].description = descriptionOfChallenge.append(
            evaluations[counter].getSpecificDescriptionPart()
        );

        lockToId[counter].addLockManager(challenger.getAddress());
        lockToId[counter].updateRefundPenalty(0, 10000);

        return challenges[counter++];
    }

    function addLeaderboardEntry(
        uint256 challengeId,
        address sender,
        uint32[] memory data,
        uint32[] memory time,
        bool withUnlock
    ) public {
        require(msg.sender == challenger.getAddress(), "NOT_CHALLENGER");
        require(
            evaluations[challengeId].checkRules(challengeId, data),
            "WRONG DATA FOR THIS RULESET"
        );
        leaderboards[challengeId].push(LeaderboardEntry(sender, data, time));

        if (withUnlock) {
            challenges[challengeId].price += getKeyPrice(challengeId);
            challenges[challengeId].currentParticipantsCount++;
        }

        challenges[challengeId].first = evaluations[challengeId].evaluate(
            leaderboards[challengeId]
        );
    }

    function getWinner(uint256 challengeId) public view returns (address) {
        require(
            block.timestamp >= challenges[challengeId].end,
            "CHALLENGE_NOT_ENDED_YET"
        );
        return challenges[challengeId].first;
    }

    function getRedeemed(uint256 challengeId) public view returns (bool) {
        return challenges[challengeId].redeemed;
    }

    function getAllChallenges() public view returns (Challenge[] memory) {
        Challenge[] memory array = new Challenge[](counter);
        for (uint256 i = 0; i < array.length; i++) {
            array[i].id = challenges[i].id;
            array[i].creator = challenges[i].creator;
            array[i].title = challenges[i].title;
            array[i].description = challenges[i].description;
            array[i].start = challenges[i].start;
            array[i].end = challenges[i].end;
            array[i].currentParticipantsCount = challenges[i]
                .currentParticipantsCount;
            array[i].maxParticipantsCount = challenges[i].maxParticipantsCount;
            array[i].fee = challenges[i].fee;
            array[i].price = challenges[i].price;
            array[i].first = challenges[i].first;
            array[i].redeemed = challenges[i].redeemed;
        }
        return array;
    }

    function getChallengeRuleSet(uint256 challengeId)
        external
        view
        returns (Rules memory)
    {
        return rules[challengeId];
    }

    function getMaxParticipants(uint256 challengeId)
        public
        view
        returns (uint256)
    {
        return challenges[challengeId].maxParticipantsCount;
    }

    function getCurrentParticipants(uint256 challengeId)
        public
        view
        returns (uint256)
    {
        return challenges[challengeId].currentParticipantsCount;
    }

    function getEndOfChallenge(uint256 challengeId)
        public
        view
        returns (uint256)
    {
        return challenges[challengeId].end;
    }

    function getStartOfChallenge(uint256 challengeId)
        public
        view
        returns (uint256)
    {
        return challenges[challengeId].start;
    }

    function getLeaderboard(uint256 challengeId)
        external
        view
        returns (LeaderboardEntry[] memory)
    {
        return leaderboards[challengeId];
    }

    function typeToString(uint32 t) internal pure returns (string memory) {
        if (t == 0) {
            return "row";
        } else if (t == 1) {
            return "ski";
        } else if (t == 2) {
            return "bike";
        } else if (t == 3) {
            return "paddle";
        } else if (t == 4) {
            return "water";
        } else if (t == 5) {
            return "snow";
        } else if (t == 6) {
            return "waterski";
        } else if (t == 7) {
            return "slides";
        } else if (t == 8) {
            return "dynamic";
        } else {
            require(false, "TYPE_NOT_SPECIFIED");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

library ChallengeUtils {
    function append(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concatenatedString)
    {
        return string(abi.encodePacked(_a, _b));
    }

    function append(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory _concatenatedString) {
        return string(abi.encodePacked(_a, _b, _c));
    }

    function append(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concatenatedString) {
        return string(abi.encodePacked(_a, _b, _c, _d));
    }

    function append(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        return string(abi.encodePacked(_a, _b, _c, _d, _e));
    }

    function uintToString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        uint256 c = _i;
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (c != 0) {
            bstr[k--] = bytes1(uint8(48 + (c % 10)));
            c /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./interfaces/unlock/IPublicLock.sol";
import "./ChallengeManager.sol";

contract Challenger {
    ChallengeManager internal manager;

    constructor(address adr) public {
        manager = ChallengeManager(adr);

        manager.setChallenger(address(this));
    }

    function submitData(
        uint256 challengeId,
        uint32[] calldata conditions,
        uint32[] calldata time
    ) external payable returns (bool) {
        IPublicLock lock = manager.getLock(challengeId);
        require(address(lock) != address(0), "THERE_IS_NO_LOCK");
        require(
            time.length == conditions.length,
            "ARRAY_LENGTHS_IN_SUBMITION_INPUT_NOT_MATCHING"
        );
        require(
            manager.getEndOfChallenge(challengeId) > block.timestamp,
            "CHALLENGE_ALREADY_OVER"
        );
        require(
            manager.getStartOfChallenge(challengeId) < block.timestamp,
            "CHALLENGE_NOT_STARTED_YET"
        );

        bool withUnlock = false;

        if (!lock.getHasValidKey(msg.sender)) {
            require(
                manager.getCurrentParticipants(challengeId) <
                    manager.getMaxParticipants(challengeId),
                // || manager.getMaxParticipants(challengeId) == 0
                "CHALLENGE_FULL"
            );
            require(
                msg.value >= manager.getFee(challengeId),
                "ENTERED_FEE_TOO_LOW"
            );
            uint256 gymnasiaFee = msg.value - manager.getKeyPrice(challengeId);

            lock.purchase.value(manager.getKeyPrice(challengeId))(
                // lock.purchase.value(msg.value)(
                lock.keyPrice(),
                msg.sender,
                0x0d5900731140977cd80b7Bd2DCE9cEc93F8a176B,
                "0x00"
            );

            bool sent = 0x0d5900731140977cd80b7Bd2DCE9cEc93F8a176B.send(
                gymnasiaFee
            );
            require(sent, "Failed to send ether");

            withUnlock = true;
        } else {
            bool sent = 0x0d5900731140977cd80b7Bd2DCE9cEc93F8a176B.send(
                msg.value
            );
            require(sent, "Failed to send ether");
        }

        manager.addLeaderboardEntry(
            challengeId,
            msg.sender,
            conditions,
            time,
            withUnlock
        );
    }

    function receivePrice(uint256 challengeId) external {
        require(isWinner(challengeId), "Not the winner");

        IPublicLock lock = manager.getLock(challengeId);
        lock.updateBeneficiary(msg.sender);
        lock.withdraw(address(0), 0);

        manager.setRedeemed(challengeId);
        // lock.updateBeneficiary(address(this));
    }

    function isWinner(uint256 challengeId) public view returns (bool) {
        return msg.sender == manager.getWinner(challengeId);
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function hasUnlockedChallenge(uint256 challengeId, address challenger)
        external
        view
        returns (bool)
    {
        return manager.getLock(challengeId).getHasValidKey(challenger);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ChallengeManager.sol";

contract Evaluation {
    address public manager;
    address public owner;
    string internal specificDescriptionPart;

    mapping(uint256 => uint32[]) public ruleset;

    constructor(address adr) public {
        manager = adr;
        owner = msg.sender;
    }

    function setChallengeManager(address adr) external {
        require(msg.sender == owner, "NOT_OWNER");
        manager = adr;
    }

    function getSpecificDescriptionPart() public view returns (string memory) {
        return specificDescriptionPart;
    }

    function evaluate(ChallengeManager.LeaderboardEntry[] calldata entry)
        external
        returns (address);

    function setRules(uint256 challengeId, uint32[] memory rules) public {
        require(msg.sender == manager, "NOT_CHALLENGE_MANAGER");
        ruleset[challengeId] = rules;
    }

    function checkRules(uint256 challengeId, uint32[] memory rules)
        public
        view
        returns (bool)
    {
        require(
            ruleset[challengeId].length == rules.length,
            "RULES_LENGTH_DOES_NOT_MATCH"
        );

        for (uint256 i = 0; i < rules.length; i++)
            if (ruleset[challengeId][i] != rules[i]) return false;

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./interfaces/unlock/IPublicLock.sol";
import "./interfaces/unlock/IUnlock.sol";

contract LockFactory {
    IUnlock internal unlock;

    mapping(uint256 => IPublicLock) lockToId;

    constructor() public {
        unlock = IUnlock(0xD8C88BE5e8EB88E38E6ff5cE186d764676012B0b);
    }

    function createNewLock(
        string memory name,
        uint256 id,
        uint256 duration,
        uint256 price,
        uint256 numberOfKeys
    ) internal {
        IPublicLock lock = IPublicLock(
            address(
                uint160(
                    unlock.createLock(
                        duration,
                        address(0),
                        price,
                        numberOfKeys,
                        name,
                        bytes12(keccak256(abi.encodePacked(id)))
                    )
                )
            )
        );
        lockToId[id] = lock;
    }

    function getKeyPrice(uint256 id) public view returns (uint256) {
        return lockToId[id].keyPrice();
    }

    function getLock(uint256 id) public view returns (IPublicLock) {
        return lockToId[id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Evaluation.sol";

contract MinTimeEvaluation is Evaluation {
    constructor(address adr) public Evaluation(adr) {
        specificDescriptionPart = "in the shortest amount of time.";
    }

    function evaluate(ChallengeManager.LeaderboardEntry[] memory entry)
        public
        returns (address)
    {
        require(entry.length > 0, "EMPTY_ARRAY");
        address challenger = entry[0].challenger;
        if (entry.length == 1) return challenger;

        uint256 i;
        uint256 j;
        uint256 sum = 0;
        uint256 min = 0;

        for (i = 0; i < entry[0].time.length; i++) {
            min += entry[0].time[i];
        }

        for (i = 1; i < entry.length; i++) {
            for (j = 0; j < entry[i].time.length; j++) {
                sum += entry[i].time[j];
            }
            if (sum < min) {
                min = sum;
                challenger = entry[i].challenger;
            }
            sum = 0;
        }
        return challenger;
    }
}

pragma solidity 0.5.17;

/**
 * @title The PublicLock Interface
 * @author Nick Furfaro (unlock-protocol.com)
 */

contract IPublicLock {
    // See indentationissue description here:
    // https://github.com/duaraghav8/Ethlint/issues/268
    // solium-disable indentation

    /// Functions

    function initialize(
        address _lockCreator,
        uint256 _expirationDuration,
        address _tokenAddress,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string calldata _lockName
    ) external;

    /**
     * @notice Allow the contract to accept tips in ETH sent directly to the contract.
     * @dev This is okay to use even if the lock is priced in ERC-20 tokens
     */
    function() external payable;

    /**
     * @dev Never used directly
     */
    function initialize() external;

    /**
     * @notice The version number of the current implementation on this network.
     * @return The current version number.
     */
    function publicLockVersion() public pure returns (uint256);

    /**
     * @notice Gets the current balance of the account provided.
     * @param _tokenAddress The token type to retrieve the balance of.
     * @param _account The account to get the balance of.
     * @return The number of tokens of the given type for the given address, possibly 0.
     */
    function getBalance(address _tokenAddress, address _account)
        external
        view
        returns (uint256);

    /**
     * @notice Used to disable lock before migrating keys and/or destroying contract.
     * @dev Throws if called by other than a lock manager.
     * @dev Throws if lock contract has already been disabled.
     */
    function disableLock() external;

    /**
     * @dev Called by a lock manager or beneficiary to withdraw all funds from the lock and send them to the `beneficiary`.
     * @dev Throws if called by other than a lock manager or beneficiary
     * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
     * the same as `tokenAddress` in MixinFunds.
     * @param _amount specifies the max amount to withdraw, which may be reduced when
     * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
     *  -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor`
     * use cases.
     */
    function withdraw(address _tokenAddress, uint256 _amount) external;

    /**
     * @notice An ERC-20 style approval, allowing the spender to transfer funds directly from this lock.
     */
    function approveBeneficiary(address _spender, uint256 _amount)
        external
        returns (bool);

    /**
     * A function which lets a Lock manager of the lock to change the price for future purchases.
     * @dev Throws if called by other than a Lock manager
     * @dev Throws if lock has been disabled
     * @dev Throws if _tokenAddress is not a valid token
     * @param _keyPrice The new price to set for keys
     * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
     * or 0 to use ETH
     */
    function updateKeyPricing(uint256 _keyPrice, address _tokenAddress)
        external;

    /**
     * A function which lets a Lock manager update the beneficiary account,
     * which receives funds on withdrawal.
     * @dev Throws if called by other than a Lock manager or beneficiary
     * @dev Throws if _beneficiary is address(0)
     * @param _beneficiary The new address to set as the beneficiary
     */
    function updateBeneficiary(address _beneficiary) external;

    /**
     * Checks if the user has a non-expired key.
     * @param _user The address of the key owner
     */
    function getHasValidKey(address _user) external view returns (bool);

    /**
     * @notice Find the tokenId for a given user
     * @return The tokenId of the NFT, else returns 0
     * @param _account The address of the key owner
     */
    function getTokenIdFor(address _account) external view returns (uint256);

    /**
     * A function which returns a subset of the keys for this Lock as an array
     * @param _page the page of key owners requested when faceted by page size
     * @param _pageSize the number of Key Owners requested per page
     * @dev Throws if there are no key owners yet
     */
    function getOwnersByPage(uint256 _page, uint256 _pageSize)
        external
        view
        returns (address[] memory);

    /**
     * Checks if the given address owns the given tokenId.
     * @param _tokenId The tokenId of the key to check
     * @param _keyOwner The potential key owners address
     */
    function isKeyOwner(uint256 _tokenId, address _keyOwner)
        external
        view
        returns (bool);

    /**
     * @dev Returns the key's ExpirationTimestamp field for a given owner.
     * @param _keyOwner address of the user for whom we search the key
     * @dev Returns 0 if the owner has never owned a key for this lock
     */
    function keyExpirationTimestampFor(address _keyOwner)
        external
        view
        returns (uint256 timestamp);

    /**
     * Public function which returns the total number of unique owners (both expired
     * and valid).  This may be larger than totalSupply.
     */
    function numberOfOwners() external view returns (uint256);

    /**
     * Allows a Lock manager to assign a descriptive name for this Lock.
     * @param _lockName The new name for the lock
     * @dev Throws if called by other than a Lock manager
     */
    function updateLockName(string calldata _lockName) external;

    /**
     * Allows a Lock manager to assign a Symbol for this Lock.
     * @param _lockSymbol The new Symbol for the lock
     * @dev Throws if called by other than a Lock manager
     */
    function updateLockSymbol(string calldata _lockSymbol) external;

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * Allows a Lock manager to update the baseTokenURI for this Lock.
     * @dev Throws if called by other than a Lock manager
     * @param _baseTokenURI String representing the base of the URI for this lock.
     */
    function setBaseTokenURI(string calldata _baseTokenURI) external;

    /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     * @param _tokenId The tokenID we're inquiring about
     * @return String representing the URI for the requested token
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /**
     * @notice Allows a Lock manager to add or remove an event hook
     */
    function setEventHooks(address _onKeyPurchaseHook, address _onKeyCancelHook)
        external;

    /**
     * Allows a Lock manager to give a collection of users a key with no charge.
     * Each key may be assigned a different expiration date.
     * @dev Throws if called by other than a Lock manager
     * @param _recipients An array of receiving addresses
     * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
     */
    function grantKeys(
        address[] calldata _recipients,
        uint256[] calldata _expirationTimestamps,
        address[] calldata _keyManagers
    ) external;

    /**
     * @dev Purchase function
     * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
     * (_value is ignored when using ETH)
     * @param _recipient address of the recipient of the purchased key
     * @param _referrer address of the user making the referral
     * @param _data arbitrary data populated by the front-end which initiated the sale
     * @dev Throws if lock is disabled. Throws if lock is sold-out. Throws if _recipient == address(0).
     * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if a Lock manager increases the
     * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
     * than keyPrice is approved for spending).
     */
    function purchase(
        uint256 _value,
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external payable;

    /**
     * @notice returns the minimum price paid for a purchase with these params.
     * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
     */
    function purchasePriceFor(
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external view returns (uint256);

    /**
     * Allow a Lock manager to change the transfer fee.
     * @dev Throws if called by other than a Lock manager
     * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
     * Ex: 200 bps = 2%
     */
    function updateTransferFee(uint256 _transferFeeBasisPoints) external;

    /**
     * Determines how much of a fee a key owner would need to pay in order to
     * transfer the key to another account.  This is pro-rated so the fee goes down
     * overtime.
     * @dev Throws if _keyOwner does not have a valid key
     * @param _keyOwner The owner of the key check the transfer fee for.
     * @param _time The amount of time to calculate the fee for.
     * @return The transfer fee in seconds.
     */
    function getTransferFee(address _keyOwner, uint256 _time)
        external
        view
        returns (uint256);

    /**
     * @dev Invoked by a Lock manager to expire the user's key and perform a refund and cancellation of the key
     * @param _keyOwner The key owner to whom we wish to send a refund to
     * @param amount The amount to refund the key-owner
     * @dev Throws if called by other than a Lock manager
     * @dev Throws if _keyOwner does not have a valid key
     */
    function expireAndRefundFor(address _keyOwner, uint256 amount) external;

    /**
     * @dev allows the key manager to expire a given tokenId
     * and send a refund to the keyOwner based on the amount of time remaining.
     * @param _tokenId The id of the key to cancel.
     */
    function cancelAndRefund(uint256 _tokenId) external;

    /**
     * @dev Cancels a key managed by a different user and sends the funds to the keyOwner.
     * @param _keyManager the key managed by this user will be canceled
     * @param _v _r _s getCancelAndRefundApprovalHash signed by the _keyManager
     * @param _tokenId The key to cancel
     */
    function cancelAndRefundFor(
        address _keyManager,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _tokenId
    ) external;

    /**
     * @notice Sets the minimum nonce for a valid off-chain approval message from the
     * senders account.
     * @dev This can be used to invalidate a previously signed message.
     */
    function invalidateOffchainApproval(uint256 _nextAvailableNonce) external;

    /**
     * Allow a Lock manager to change the refund penalty.
     * @dev Throws if called by other than a Lock manager
     * @param _freeTrialLength The new duration of free trials for this lock
     * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
     */
    function updateRefundPenalty(
        uint256 _freeTrialLength,
        uint256 _refundPenaltyBasisPoints
    ) external;

    /**
     * @dev Determines how much of a refund a key owner would receive if they issued
     * @param _keyOwner The key owner to get the refund value for.
     * a cancelAndRefund block.timestamp.
     * Note that due to the time required to mine a tx, the actual refund amount will be lower
     * than what the user reads from this call.
     */
    function getCancelAndRefundValueFor(address _keyOwner)
        external
        view
        returns (uint256 refund);

    function keyManagerToNonce(address) external view returns (uint256);

    /**
     * @notice returns the hash to sign in order to allow another user to cancel on your behalf.
     * @dev this can be computed in JS instead of read from the contract.
     * @param _keyManager The key manager's address (also the message signer)
     * @param _txSender The address cancelling cancel on behalf of the keyOwner
     * @return approvalHash The hash to sign
     */
    function getCancelAndRefundApprovalHash(
        address _keyManager,
        address _txSender
    ) external view returns (bytes32 approvalHash);

    function addKeyGranter(address account) external;

    function addLockManager(address account) external;

    function isKeyGranter(address account) external view returns (bool);

    function isLockManager(address account) external view returns (bool);

    function onKeyPurchaseHook() external view returns (address);

    function onKeyCancelHook() external view returns (address);

    function revokeKeyGranter(address _granter) external;

    function renounceLockManager() external;

    ///===================================================================
    /// Auto-generated getter functions from public state variables

    function beneficiary() external view returns (address);

    function expirationDuration() external view returns (uint256);

    function freeTrialLength() external view returns (uint256);

    function isAlive() external view returns (bool);

    function keyPrice() external view returns (uint256);

    function maxNumberOfKeys() external view returns (uint256);

    function owners(uint256) external view returns (address);

    function refundPenaltyBasisPoints() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function transferFeeBasisPoints() external view returns (uint256);

    function unlockProtocol() external view returns (address);

    function keyManagerOf(uint256) external view returns (address);

    ///===================================================================

    /**
     * @notice Allows the key owner to safely share their key (parent key) by
     * transferring a portion of the remaining time to a new key (child key).
     * @dev Throws if key is not valid.
     * @dev Throws if `_to` is the zero address
     * @param _to The recipient of the shared key
     * @param _tokenId the key to share
     * @param _timeShared The amount of time shared
     * checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
     * @dev Emit Transfer event
     */
    function shareKey(
        address _to,
        uint256 _tokenId,
        uint256 _timeShared
    ) external;

    /**
     * @notice Update transfer and cancel rights for a given key
     * @param _tokenId The id of the key to assign rights for
     * @param _keyManager The address to assign the rights to for the given key
     */
    function setKeyManagerOf(uint256 _tokenId, address _keyManager) external;

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    ///===================================================================

    /// From ERC165.sol
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    ///===================================================================

    /// From ERC-721
    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address _owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address _owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function approve(address to, uint256 tokenId) public;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address _owner, address operator)
        public
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;

    function totalSupply() public view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 index)
        public
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);

    /**
     * @notice An ERC-20 style transfer.
     * @param _value sends a token with _value * expirationDuration (the amount of time remaining on a standard purchase).
     * @dev The typical use case would be to call this with _value 1, which is on par with calling `transferFrom`. If the user
     * has more than `expirationDuration` time remaining this may use the `shareKey` function to send some but not all of the token.
     */
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
}

pragma solidity 0.5.17;

/**
 * @title The Unlock Interface
 * @author Nick Furfaro (unlock-protocol.com)
 **/

interface IUnlock {
    // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
    function initialize(address _unlockOwner) external;

    /**
     * @dev Create lock
     * This deploys a lock for a creator. It also keeps track of the deployed lock.
     * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
     * @param _salt an identifier for the Lock, which is unique for the user.
     * This may be implemented as a sequence ID or with RNG. It's used with `create2`
     * to know the lock's address before the transaction is mined.
     */
    function createLock(
        uint256 _expirationDuration,
        address _tokenAddress,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string calldata _lockName,
        bytes12 _salt
    ) external returns (address);

    /**
     * This function keeps track of the added GDP, as well as grants of discount tokens
     * to the referrer, if applicable.
     * The number of discount tokens granted is based on the value of the referal,
     * the current growth rate and the lock's discount token distribution rate
     * This function is invoked by a previously deployed lock only.
     */
    function recordKeyPurchase(
        uint256 _value,
        address _referrer // solhint-disable-line no-unused-vars
    ) external;

    /**
     * This function will keep track of consumed discounts by a given user.
     * It will also grant discount tokens to the creator who is granting the discount based on the
     * amount of discount and compensation rate.
     * This function is invoked by a previously deployed lock only.
     */
    function recordConsumedDiscount(
        uint256 _discount,
        uint256 _tokens // solhint-disable-line no-unused-vars
    ) external;

    /**
     * This function returns the discount available for a user, when purchasing a
     * a key from a lock.
     * This does not modify the state. It returns both the discount and the number of tokens
     * consumed to grant that discount.
     */
    function computeAvailableDiscountFor(
        address _purchaser, // solhint-disable-line no-unused-vars
        uint256 _keyPrice // solhint-disable-line no-unused-vars
    ) external view returns (uint256 discount, uint256 tokens);

    // Function to read the globalTokenURI field.
    function globalBaseTokenURI() external view returns (string memory);

    /**
     * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
     */
    function getGlobalBaseTokenURI() external view returns (string memory);

    // Function to read the globalTokenSymbol field.
    function globalTokenSymbol() external view returns (string memory);

    // Function to read the chainId field.
    function chainId() external view returns (uint256);

    /**
     * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
     */
    function getGlobalTokenSymbol() external view returns (string memory);

    /**
     * @notice Allows the owner to update configuration variables
     */
    function configUnlock(
        address _udt,
        address _weth,
        uint256 _estimatedGasForPurchase,
        string calldata _symbol,
        string calldata _URI,
        uint256 _chainId
    ) external;

    /**
     * @notice Upgrade the PublicLock template used for future calls to `createLock`.
     * @dev This will initialize the template and revokeOwnership.
     */
    function setLockTemplate(address payable _publicLockAddress) external;

    // Allows the owner to change the value tracking variables as needed.
    function resetTrackedValue(
        uint256 _grossNetworkProduct,
        uint256 _totalDiscountGranted
    ) external;

    function grossNetworkProduct() external view returns (uint256);

    function totalDiscountGranted() external view returns (uint256);

    function locks(address)
        external
        view
        returns (
            bool deployed,
            uint256 totalSales,
            uint256 yieldedDiscountTokens
        );

    // The address of the public lock template, used when `createLock` is called
    function publicLockAddress() external view returns (address);

    // Map token address to exchange contract address if the token is supported
    // Used for GDP calculations
    function uniswapOracles(address) external view returns (address);

    // The WETH token address, used for value calculations
    function weth() external view returns (address);

    // The UDT token address, used to mint tokens on referral
    function udt() external view returns (address);

    // The approx amount of gas required to purchase a key
    function estimatedGasForPurchase() external view returns (uint256);

    // The version number of the current Unlock implementation on this network
    function unlockVersion() external pure returns (uint16);

    /**
     * @notice allows the owner to set the oracle address to use for value conversions
     * setting the _oracleAddress to address(0) removes support for the token
     * @dev This will also call update to ensure at least one datapoint has been recorded.
     */
    function setOracle(address _tokenAddress, address _oracleAddress) external;

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() external view returns (bool);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}