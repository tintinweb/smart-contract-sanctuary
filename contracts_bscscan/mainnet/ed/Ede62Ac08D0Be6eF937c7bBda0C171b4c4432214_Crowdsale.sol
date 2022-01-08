/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/IMelodity.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMelodity {
    /**
     * Lock the provided amount of MELD for "relativeReleaseTime" seconds starting from now
     * NOTE: This method is capped
     * NOTE: time definition in the locks is relative!
     */
    function insertLock(
        address account,
        uint256 amount,
        uint256 relativeReleaseTime
    ) external;
}


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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


// File @openzeppelin/contracts/utils/structs/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File contracts/Referrable.sol

pragma solidity 0.8.11;

abstract contract Referrable {
	using EnumerableSet for EnumerableSet.AddressSet;

	event ReferralCreated(address creator);
	event ReferralUsed(address referrer, address referred);
	event ReferralPrizeRedeemed(address referrer);

	struct Referral {
		uint256 referrerPrize;
		uint256 referredPrize;
		uint256 prize;
	}

	mapping(address => Referral) public referrals;
	
	EnumerableSet.AddressSet private alreadyReferred;
	uint256 public baseReferral;
	uint256 public baseReferralDecimals;

	/**
		@param _baseReferral Maximum referral prize that will be splitted between the referrer
				and the referred
		@param _baseReferralDecimals Number of decimal under the base (18) the referral value is.
				This values allow for decimal values like 0.5%, the minimum is 0.[0 x 17 times]1 
	 */
	constructor(uint256 _baseReferral, uint256 _baseReferralDecimals) {
		baseReferralDecimals = 18;
		
		// high precision (18 decimals) the base referral is already in the normalized form
		// 1_[0 x 18 times] = 1%
		// 5_[0 x 17 times] = 0.5%
		baseReferral = _baseReferral * 10 ** (18 - _baseReferralDecimals);
	}

	/**
		@param _referrerPercent Percentage of baseReferral that is destinated to the referrer,
				18 decimal position needed for the unit
		@param _referredPercent Percentage of baseReferral that is destinated to the referred,
				18 decimal position needed for the unit
	 */
	function createReferral(uint256 _referrerPercent, uint256 _referredPercent) public {
		require(
			_referrerPercent + _referredPercent == 100 * 10 ** 18,
			"All the referral percentage must be distributed (100%)"
		);
		require(
			referrals[msg.sender].referrerPrize == 0 && referrals[msg.sender].referredPrize == 0,
			"Referral already initialized, unable to edit it"
		);
		require(
			referrals[msg.sender].prize == 0,
			"Referral has already been used, unable to edit it"
		);

		uint256 referrerPrize = baseReferral * _referrerPercent / 10 ** 20; // 18 decimals + transposition from integer to percentage
		uint256 referredPrize = baseReferral * _referredPercent / 10 ** 20; // 18 decimals + transposition from integer to percentage

		referrals[msg.sender] = Referral({
			referrerPrize: referrerPrize,
			referredPrize: referredPrize,
			prize: 0
		});

		emit ReferralCreated(msg.sender);
	}

	/**
		@param _ref Referrer address
		@param _value Value of the currency whose bonus should be computed
		@return (
			Referred bonus based on the submitted _value,
			Total value of the bonus, may be used for minting calculations
		)
	 */
	function computeReferralPrize(address _ref, uint256 _value) internal returns(uint256, uint256) {	
		if (
			// check if the referrer address is active and compute the referral if it is
			referrals[_ref].referrerPrize + referrals[_ref].referredPrize == baseReferral &&
			
			// check that no other referral have veen used before, if any referral have been used
			// any new ref-code will not be considered
			!alreadyReferred.contains(msg.sender)
			) {
			// insert the sender in the list of the referred user locking it from any other call
			alreadyReferred.add(msg.sender);

			uint256 referrerBonus = _value * referrals[_ref].referrerPrize / 10 ** 20; // 18 decimals + transposition from integer to percentage
			uint256 referredBonus = _value * referrals[_ref].referredPrize / 10 ** 20; // 18 decimals + transposition from integer to percentage

			referrals[_ref].prize += referrerBonus;

			emit ReferralUsed(_ref, msg.sender);
			return (referredBonus, referrerBonus + referredBonus);
		}
		// fallback to no bonus if the ref code is not active or already used a ref code
		return (0, 0);
	}

	function redeemReferralPrize() virtual public;

	function getReferrals() public view returns(Referral memory) {
		return referrals[msg.sender];
	}
}


// File contracts/Crowdsale.sol

pragma solidity 0.8.11;

contract Crowdsale is Referrable, ReentrancyGuard {
    IMelodity private melodity;
    PaymentTier[] public paymentTier;
	
    uint256 public saleStart = 1642147200;	// Friday, January 14, 2022 08:00:00
    uint256 public saleEnd = 1648771199;	// Thursday, March 31, 2022 23:59:59

	// Do inc. company wallet
	address public multisigWallet = 0x01Af10f1343C05855955418bb99302A6CF71aCB8;

    // used to store the amount of funds actually available for the contract,
    // this value is created in order to avoid eventually running out of funds in case of a large number of
    // interactions occurring at the same time.
    uint256 public supply = 35_000_000 ether;
    uint256 public distributed;

    event Buy(address indexed from, uint256 amount);
	event Destroied(uint256 burnedFunds);

    struct PaymentTier {
        uint256 rate;
        uint256 lowerLimit;
        uint256 upperLimit;
    }

	mapping(address => uint256) public toRefund;

	/**
     * Network: Binance Smart Chain (BSC)
     * Melodity Bep20: 0x13E971De9181eeF7A4aEAEAA67552A6a4cc54f43

	 * Network: Binance Smart Chain TESTNET (BSC)
     * Melodity Bep20: 0x5EaA8Be0ebe73C0B6AdA8946f136B86b92128c55

	 * Referrable prize 0.5%
     */
    constructor() Referrable(5, 1) {
        melodity = IMelodity(0x13E971De9181eeF7A4aEAEAA67552A6a4cc54f43);

		paymentTier.push(
			PaymentTier({
				rate: 6000,
				lowerLimit: 0,
				upperLimit: 2_500_000_000000000000000000
			})
		);
		paymentTier.push(
			PaymentTier({
				rate: 3000,
				lowerLimit: 2_500_000_000000000000000000,
				upperLimit: 12_500_000_000000000000000000
			})
		);
		paymentTier.push(
			PaymentTier({
				rate: 1500,
				lowerLimit: 12_500_000_000000000000000000,
				upperLimit: 22_500_000_000000000000000000
			})
		);
		paymentTier.push(
			PaymentTier({
				rate: 750,
				lowerLimit: 22_500_000_000000000000000000,
				upperLimit: 32_500_000_000000000000000000
			})
		);
		paymentTier.push(
			PaymentTier({
				rate: 375,
				lowerLimit: 32_500_000_000000000000000000,
				upperLimit: 35_000_000_000000000000000000
			})
		);
    }

        receive() external payable {
        revert("Direct funds receiving not enabled, call 'buy' directly");
    }

    function buy(address _ref) public nonReentrant payable {
		require(
			block.timestamp > saleStart,
			"ICO not started yet, come back starting from Friday, January 14, 2022 08:00:00"
		);
		require(
			block.timestamp < saleEnd,
			"ICO ended, sorry you're too late"
		);
		require(
			supply > 0,
			"ICO ended, everything was sold"
		);

        // compute the amount of token to buy based on the current rate
        (uint256 tokensToBuy, uint256 exceedingEther) = computeTokensAmount(msg.value);

		// refund eventually exceeding eth
        if(exceedingEther > 0) {
			uint256 _toRefund = toRefund[msg.sender] + exceedingEther;
			toRefund[msg.sender] = _toRefund;
        }

		// avoid impossibility to transfer funds to smart contracts (like gnosis safe multisig).
		// this is a workaround for the 2300 fixed gas problem
		(bool success, ) = multisigWallet.call{value: msg.value - exceedingEther}("");
		require(success, "Unable to proxy the transferred funds to the multisig wallet");

		(uint256 referredPrize, uint256 totalPrize) = computeReferralPrize(_ref, tokensToBuy);

		// change the core value asap
		distributed += tokensToBuy + totalPrize;
		supply -= tokensToBuy + totalPrize;

		tokensToBuy += referredPrize;
        
        // Mint new tokens for each submission
		saleLock(msg.sender, tokensToBuy);
        emit Buy(msg.sender, tokensToBuy);
    }    

	function saleLock(address _account, uint256 _meldToLock) private {
		// immediately release the 10% of the bought amount
        uint256 immediatelyReleased = _meldToLock / 10; // * 10 / 100 = / 10

        // 15% released after 3 months
        uint256 m3Release = _meldToLock * 15 / 100; 

        // 25% released after 9 months
        uint256 m9Release = _meldToLock * 25 / 100; 
        
        // 25% released after 15 months
        uint256 m15Release = _meldToLock * 25 / 100; 
        
        // 25% released after 21 months
        uint256 m21Release = _meldToLock - (immediatelyReleased + m3Release + m9Release + m15Release); 

		melodity.insertLock(_account, immediatelyReleased, 0);
		melodity.insertLock(_account, m3Release, 90 days);
		melodity.insertLock(_account, m9Release, 270 days);
		melodity.insertLock(_account, m15Release, 450 days);
		melodity.insertLock(_account, m21Release, 630 days);
	}

    function computeTokensAmount(uint256 funds) public view returns(uint256, uint256) {
        uint256 futureMinted = distributed;
        uint256 tokensToBuy;
        uint256 currentRoundTokens;      
        uint256 etherUsed = funds; 
        uint256 futureRound; 
        uint256 rate;
        uint256 upperLimit;

        for(uint256 i = 0; i < paymentTier.length; i++) {
            // minor performance improvement, caches the value
            upperLimit = paymentTier[i].upperLimit;

            if(
                etherUsed > 0 &&                                 // Check if there are still some funds in the request
                futureMinted >= paymentTier[i].lowerLimit &&     // Check if the current rate can be applied with the lowerLimit
                futureMinted < upperLimit                        // Check if the current rate can be applied with the upperLimit
                ) {
                // minor performance improvement, caches the value
                rate = paymentTier[i].rate;
                
                // Keep a static counter and reset it in each round
                // NOTE: Order is important in value calculation
                currentRoundTokens = etherUsed * 1e18 / 1 ether * rate;

                // minor performance optimization, caches the value
                futureRound = futureMinted + currentRoundTokens;
                // If the tokens to mint exceed the upper limit of the tier reduce the number of token bounght in this round
                if(futureRound >= upperLimit) {
                    currentRoundTokens -= futureRound - upperLimit;
                }

                // Update the futureMinted counter with the currentRoundTokens
                futureMinted += currentRoundTokens;

                // Recomputhe the available funds
                etherUsed -= currentRoundTokens * 1 ether / rate / 1e18;

                // And add the funds to the total calculation
                tokensToBuy += currentRoundTokens;
            }
        }

        // minor performance optimization, caches the value
        uint256 new_minted = distributed + tokensToBuy;
        uint256 exceedingEther;
        // Check if we have reached and exceeded the funding goal to refund the exceeding ether
        if(new_minted >= supply) {
            uint256 exceedingTokens = new_minted - supply;
            
            // Convert the exceedingTokens to ether and refund that ether
            exceedingEther = etherUsed + (exceedingTokens * 1 ether / paymentTier[paymentTier.length -1].rate / 1e18);

            // Change the tokens to buy to the new number
            tokensToBuy -= exceedingTokens;
        }

        return (tokensToBuy, exceedingEther);
    }

    function destroy() nonReentrant public {
		// permit the destruction of the contract only an hour after the end of the sale,
		// this avoid any evil miner to trigger the function before the real ending time
		require(
			block.timestamp > saleEnd + 1 hours, 
			"Destruction not enabled yet, you may call this function starting from Friday, April 1, 2022 00:59:59 UTC"
		);
		require(supply > 0, "Remaining supply already burned or all funds sold");
		uint256 remainingSupply = supply;
		
        // burn all unsold MELD
		supply = 0;

		emit Destroied(remainingSupply);
    }

	function redeemReferralPrize() public nonReentrant override {
		require(
			referrals[msg.sender].prize != 0,
			"No referral prize to redeem"
		);
		require(
			block.timestamp > saleEnd, 
			"Referral prize can be redeemed only after the end of the ICO"
		);

		uint256 prize = referrals[msg.sender].prize;
		referrals[msg.sender].prize = 0;

		melodity.insertLock(msg.sender, prize, 0);
		emit ReferralPrizeRedeemed(msg.sender);
	}

	function refund() public nonReentrant {
		require(toRefund[msg.sender] > 0, "Nothing to refund");

		uint256 _refund = toRefund[msg.sender];
		toRefund[msg.sender] = 0;

		// avoid impossibility to refund funds in case transaction are executed from a contract
		// (like gnosis safe multisig), this is a workaround for the 2300 fixed gas problem
		(bool refundSuccess, ) = msg.sender.call{value: _refund}("");
		require(refundSuccess, "Unable to refund exceeding ether");
	}

    function isStarted() public view returns(bool) { return block.timestamp >= saleStart; }
}