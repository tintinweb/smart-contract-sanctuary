pragma solidity ^0.4.19;

interface ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * Owned Contract
 *
 * This is a contract trait to inherit from. Contracts that inherit from Owned
 * are able to modify functions to be only callable by the owner of the
 * contract.
 *
 * By default it is impossible to change the owner of the contract.
 */
contract Owned {
  /**
   * Contract owner.
   *
   * This value is set at contract creation time.
   */
  address owner;

  /**
   * Contract constructor.
   *
   * This sets the owner of the Owned contract at the time of contract
   * creation.
   */
  function Owned() public {
    owner = msg.sender;
  }

  /**
   * Modify method to only allow the owner to call it.
   */
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

/**
 * Chi Token Sale Contract with revenue sharing
 *
 * The intention of this contract is to run until the total value of 2000 ETH
 * is sold out. There is no time limit placed on the contract.
 *
 * The total number of CHI tokens allocated to the contract is equal to the
 * maximum number of tokens that can be acquired. This maximum number is
 * calculating the purchase of 2000 ETH of tokens, and adding the bonus tokens
 * for that purchase.
 *
 * The bonus tiers thresholds are calculated using the absolute number of sold
 * tokens (by this contract), and are as follows:
 *  - the 1st 150.000 tokens (0 - 149.999) get a bonus of 75%;
 *  - the 2nd 150.000 tokens (150.000 - 299.999) get a bonus of 60%;
 *  - the 3rd 150.000 tokens (300.000 - 449.999) get a bonus of 50%;
 *  - the 4th 150.000 tokens (450.000 - 599.999) get a bonus of 40%;
 *  - the 5th 150.000 tokens (600.000 - 749.999) get a bonus of 30%;
 *  - the 6th 150.000 tokens (750.000 - 899.999) get a bonus of 20%;
 *  - the next 300.000 tokens (900.000 - 1.199.999) get a bonus of 10%;
 *  - the next 300.000 tokens (1.200.000 - 1.499.999) get a bonus of 5%; and
 *  - the next 500.000 tokens (1.500.000 - 1.999.999) get a bonus of 2%.
 *
 * The maximum number of tokens this contract is able to hand out, can be
 * calculated using the following Python code:
 *  https://pyfiddle.io/fiddle/9bbc870a-534e-47b1-87c3-5f000bdd7d74/
 */
contract ChiSale is Owned {
    // For simplicity reasons, all values are calculated using uint256. Both
    // values could technically be reduced to a lower bit value: percentage
    // fits in `uint8`, and threshold fits within `uint64`. This contract is
    // not optimized for storage and does not use bit packing to store multiple
    // smaller `uint` values in a single larger `uint`.
    struct BonusTier {
        uint256 percentage;
        uint256 threshold;
    }

    // The list of bonus tiers is set at contract construction and does not
    // mutate.
    BonusTier[] private bonusTiers;

    // The number of sold tokens is to keep track of the active bonus tier. The
    // number is updated every time a purchase is made.
    uint256 private tokensSold;

    // The bonus index is always up-to-date with the latest bonus tier. It is
    // automatically updated when a new threshold is hit.
    uint8 private bonusIndex;

    // The maximum bonus threshold indicated the threshold of the final bonus
    // tier. This is also the maximum number of tokens a buyer is able to
    // purchase.
    uint256 private maxBonusThreshold;

    // The price per CHI token is constant, and equal to the value determined
    // by the Aethian Crystal Bank: 0.001 ether per CHI, which is equal to 1
    // ether for 1000 CHI.
    uint256 private constant TOKEN_PRICE = 0.001 ether;

    // The revenue share percentage is the percentage that the referrer of the
    // buyer receives, after the buyer makes a purchase using their address as
    // referral address. The referral address is the address that receives the
    // revenue share percentage.
    uint256 private constant REVENUE_SHARE_PERCENTAGE = 22;

    // The CHI token contract implements ERC-20.
    ERC20 private chiContract;

    // Log the CHI purchase event. The purchase events are filterable by buyer
    // and referrer to allow for quick look-ups for specific users.
    event LogChiPurchase(
        address indexed buyer,
        address indexed referrer,
        uint256 number,
        uint256 timestamp
    );

    /**
     * CHI Sale contract constructor
     *
     * The CHI contract address and bonus numbers are passed in dynamically
     * to allow for testing using different Ethereum networks and different
     * bonus numbers.
     */
    function ChiSale(
        address chiAddress,
        uint256[] bonusThresholds,
        uint256[] bonusPercentages
    )
        public
        Owned()
    {
        // Explicitly check the lengths of the bonus percentage and threshold
        // arrays to prevent human error. This does not prevent the creator
        // from inputting the wrong numbers, however.
        require(bonusThresholds.length == bonusPercentages.length);

        // Explicitly check that the number of bonus tiers is less than 256, as
        // it should fit within the 8 bit unsigned integer value that is used
        // as the index counter.
        require(bonusThresholds.length < 256);

        // Loop through one array, whilst simultaneously reading data from the
        // other array. This is possible because both arrays are of the same
        // length, as checked in the line above.
        for (uint8 i = 0; i < bonusThresholds.length; i++) {

            // Guard against human error, by checking that the new bonus
            // threshold is always a higher value than the previous threshold.
            if (i > 0) {
                require(bonusThresholds[i] > bonusThresholds[i - 1]);
            }

            // It is already guaranteed that bonus thresholds are in ascending
            // order. For this reason, the maximum bonus threshold can be set
            // by selecting the final value in the bonus thresholds array.
            if (i > bonusThresholds.length - 1) {
                maxBonusThreshold = bonusThresholds[i];
            }

            bonusTiers.push(BonusTier({
                percentage: bonusPercentages[i],
                threshold: bonusThresholds[i]
            }));
        }

        // The CHI token contract address is passed as argument to allow for
        // easier testing on the development and testing networks.
        chiContract = ERC20(chiAddress);

        // The default value of an unsigned integer is already zero, however,
        // for verbosity and readability purposes, both counters are explicitly
        // set to zero.
        tokensSold = 0;
        bonusIndex = 0;
    }

    function buy(address referralAddress) external payable {
        // Calculate the number of tokens to buy. This can be 0, if the buyer
        // sends an ether value that is less than the price indicated by
        // `TOKEN_PRICE`.
        uint256 tokensToBuy = msg.value / TOKEN_PRICE;

        // Get the current CHI token balance of this contract. If this number
        // is zero, no more tokens can will be sold.
        uint256 tokenBalance = chiContract.balanceOf(address(this));

        // A buyer can send more than the required amount for buying a number
        // of tokens. In this case the remainder is calculated, that will be
        // sent back at the end of the transaction.
        uint256 remainder = msg.value % TOKEN_PRICE;

        // Explicitly guard against the scenario wherein human error occurs,
        // and fewer tokens have been transferred to the contract than dictated
        // by the bonus tiers. This situation can still be resolved at a later
        // date by calling `resetMaxBonusThreshold`.
        if (maxBonusThreshold < tokenBalance) {
            maxBonusThreshold = tokenBalance;
        }

        // A scenario is possible wherein a buyer attempts to buy more tokens
        // than the contract is offering. In this case the purchase is limited
        // to the available number of tokens.
        if (tokensToBuy > maxBonusThreshold) {
            tokensToBuy = maxBonusThreshold;

            // The actual number of tokens that can be bought is multiplied by
            // the token price to calculate the actual purchase price of the
            // transaction. This is then subtracted from the total value of
            // ether sent in the transaction to end up with the remainder that
            // will be sent back to the buyer.
            remainder = msg.value - tokensToBuy * TOKEN_PRICE;
        }

        // The sale contract has a bonus structure. The number of bonus tokens
        // is calculated in a different method. This method will always return
        // a number (of bonus tokens) without error; this number can be zero.
        uint256 bonusTokens = calculateBonusTokens(tokensToBuy);

        // Update the number of tokens sold. This number does not include the
        // number of bonus tokens that were given out, only the number of
        // tokens that were &#39;bought&#39;.
        tokensSold += tokensToBuy;

        // Guard against transfers where the contract attempts to transfer more
        // CHI tokens than it has available. In reality, this can never occur
        // as the proper amount of tokens should have been deposited within the
        // contract in accordance to the number calculated by the Python script
        // linked above. This is simply a guard against human error.
        if (tokenBalance < tokensToBuy + bonusTokens) {
            chiContract.transfer(msg.sender, tokenBalance);
        } else {
            chiContract.transfer(msg.sender, tokensToBuy + bonusTokens);
        }

        // The referral address has a default value set to the contract address
        // of this CHI sale contract in the web application. The application
        // changes this value to a different referral address if a special link
        // is followed. If the referral address does not equal this contract&#39;s
        // address, the revenue share percentage is paid out to that address.
        if (referralAddress != address(this) && referralAddress != address(0)) {

            // The value `msg.value * REVENUE_SHARE_PERCENTAGE / 100` is always
            // guaranteed to be a valid number (i.e. accepted by the `transfer`
            // method). The value cannot overflow as the maximum number of Wei
            // in `msg.value` fits in 128 bits. Multiplying this number by
            // `REVENUE_SHARE_PERCENTAGE` still safely fits within the current
            // 256 bit range. The value is sent using `send` to make sure the
            // purchase does not fail if someone uses an invalid address.
            referralAddress.send(
                msg.value * REVENUE_SHARE_PERCENTAGE / 100
            );
        }

        // In the case where a buyer sent in too much ether, or there weren&#39;t
        // enough tokens available, the remaining ether is sent back to the
        // buyer.
        if (remainder > 0) {
            msg.sender.transfer(remainder);
        }

        LogChiPurchase(msg.sender, referralAddress, tokensToBuy, now);
    }

    /**
     * Reset the maximum bonus threshold to the correct value.
     *
     * This number is lowered if the contract has fewer tokens available than
     * indicated by the maximum bonus threshold. In this case, the correct
     * number of tokens should be deposited before calling this method to
     * restore the numbers.
     */
    function resetMaxBonusThreshold() external onlyOwner {
        maxBonusThreshold = bonusTiers[bonusTiers.length - 1].threshold;
    }

    /**
     * Withdraw all ether from the contract.
     *
     * This withdrawal is separate from the CHI withdrawal method to allow for
     * intermittent withdrawals as the contract has no set time period to run
     * for.
     */
    function withdrawEther() external onlyOwner {
        // The transfer method cannot fail with the current given input, as a
        // transfer of 0 Wei is also a valid transfer call.
        msg.sender.transfer(address(this).balance);
    }

    /**
     * Withdraw remaining CHI from the contract.
     *
     * The intent of this method is to retrieve the remaining bonus tokens
     * after the sale has concluded successfully, but not all bonus tokens have
     * been handed out (due to rounding).
     */
    function withdrawChi() external onlyOwner {
        // This CHI transfer cannot fail as the available balance is first
        // retrieved from the CHI token contract. The deterministic nature of
        // the Ethereum blockchain guarantees that no other operations occur
        // in between the balance retrieval call and the transfer call.
        chiContract.transfer(msg.sender, chiContract.balanceOf(address(this)));
    }

    /**
     * Get the number of bonus tiers.
     *
     * Returns
     * -------
     * uint256
     *     The number of bonus tiers in the sale contract.
     *
     * Notice
     * ------
     * This method returns a 256 bit unsigned integer because that is the
     * return type of the `length` method on arrays. Type casting it would be
     * a needless gas cost.
     */
    function getBonusTierCount() external view returns (uint256) {
        return bonusTiers.length;
    }

    /**
     * Get bonus percentage and threshold of a given bonus tier.
     *
     * Parameters
     * ----------
     * bonusTierIndex : uint8
     *
     * Returns
     * -------
     * uint256
     *     The first 256 bit unsigned integer is the bonus percentage of the
     *     given bonus tier.
     * uint256
     *     The second 256 bit unsigned integer is the bonus threshold of the
     *     given bonus tier.
     *
     * Notice
     * ------
     * Both percentage and threshold are 256 bit unsigned integers, even though
     * they technically respectively fit within an 8 bit unsigned integer and
     * a 64 bit unsigned integer. For simplicity purposes, they are kept as 256
     * bit values.
     */
    function getBonusTier(
        uint8 bonusTierIndex
    )
        external
        view
        returns (uint256, uint256)
    {
        return (
            bonusTiers[bonusTierIndex].percentage,
            bonusTiers[bonusTierIndex].threshold
        );
    }

    /**
     * Get bonus percentage and threshold of the current bonus tier.
     *
     * Returns
     * -------
     * uint256
     *     The first 256 bit unsigned integer is the bonus percentage of the
     *     current bonus tier.
     * uint256
     *     The second 256 bit unsigned integer is the bonus threshold of the
     *     current bonus tier.
     *
     * Notice
     * ------
     * Both percentage and threshold are 256 bit unsigned integers, even though
     * they technically respectively fit within an 8 bit unsigned integer and
     * a 64 bit unsigned integer. For simplicity purposes, they are kept as 256
     * bit values.
     */
    function getCurrentBonusTier()
        external
        view
        returns (uint256 percentage, uint256 threshold)
    {
        return (
            bonusTiers[bonusIndex].percentage,
            bonusTiers[bonusIndex].threshold
        );
    }

    /**
     * Get the next bonus tier index.
     *
     * Returns
     * -------
     * uint8
     *     The index of the next bonus tier.
     */
    function getNextBonusIndex()
        external
        view
        returns (uint8)
    {
        return bonusIndex + 1;
    }

    /**
     * Get the number of sold tokens.
     *
     * Returns
     * -------
     * uint256
     *     The number of sold tokens.
     */
    function getSoldTokens() external view returns (uint256) {
        return tokensSold;
    }

    /**
     * Calculate the number of bonus tokens to send the buyer.
     *
     * Parameters
     * ----------
     * boughtTokens : uint256
     *     The number of tokens the buyer has bought, and to calculate the
     *     number of bonus tokens of.
     *
     * Returns
     * -------
     * uint256
     *     The number of bonus tokens to send the buyer.
     *
     * Notice
     * ------
     * This method modifies contract state by incrementing the bonus tier index
     * whenever a bonus tier is completely exhausted. This is done for
     * simplicity purposes. A different approach would have been to move the
     * loop to a different segment of the contract.
     */
    function calculateBonusTokens(
        uint256 boughtTokens
    )
        internal
        returns (uint256)
    {
        // Immediate return if all bonus tokens have already been handed out.
        if (bonusIndex == bonusTiers.length) {
            return 0;
        }

        // The number of bonus tokens always starts at zero. If the buyer does
        // not hit any of the bonus thresholds, or if the buyer buys a low
        // number of tokens that causes the bonus to round down to zero, this
        // zero value is returned.
        uint256 bonusTokens = 0;

        // Copy the number of bought tokens to an `lvalue` to allow mutation.
        uint256 _boughtTokens = boughtTokens;

        // Copy the number of sold tokens to an `lvalue` to allow mutation.
        uint256 _tokensSold = tokensSold;

        while (_boughtTokens > 0) {
            uint256 threshold = bonusTiers[bonusIndex].threshold;
            uint256 bonus = bonusTiers[bonusIndex].percentage;

            // There are two possible scenarios for the active bonus tier:
            //  1: the buyer purchases equal or more CHI tokens than available
            //     in the current bonus tier; and
            //  2: the buyer purchases less CHI tokens than available in the
            //     current bonus tier.
            if (_tokensSold + _boughtTokens >= threshold) {
                // The number of remaining tokens within the threshold is equal
                // to the threshold minus the number of tokens that have been
                // sold already.
                _boughtTokens -= threshold - _tokensSold;

                // The number of bonus tokens is equal to the remaining number
                // of tokens in the bonus tier multiplied by the bonus tier&#39;s
                // percentage. A different bonus will be calculated for the
                // remaining bought tokens. The number is first multiplied by
                // the bonus percentage to work to the advantage of the buyer,
                // as the minimum number of tokens that need to be bought for a
                // bonus to be counted would be equal to `100 / bonus` (rounded
                // down), in comparison to requiring a minimum of 100 tokens in
                // the other case.
                bonusTokens += (threshold - _tokensSold) * bonus / 100;

                // The number of sold tokens is &#39;normally&#39; incremented by the
                // number of tokens that have been bought (in that bonus tier).
                // However, when all remaining tokens in a bonus tier are
                // purchased, the resulting operation looks as follows:
                //  _tokensSold = _tokensSold + (threshold - _tokensSold)
                // which can be simplified to the current operation.
                _tokensSold = threshold;

                // If the bonus tier limit has not been reached, the bonus
                // index is incremented, because all tokens in the current
                // bonus tier have been sold.
                if (bonusIndex < bonusTiers.length) {
                    bonusIndex += 1;
                }
            } else {

                // In the case where the number of bought tokens does not hit
                // the bonus threshold. No bonus changes have to be made, and
                // the number of sold tokens can be incremented by the bought
                // number of tokens.
                _tokensSold += _boughtTokens;

                // The number of bonus tokens is equal to the number of bought
                // tokens multiplied by the bonus factor of the active bonus
                // tier.
                bonusTokens += _boughtTokens * bonus / 100;

                // Reset the bought tokens to zero.
                _boughtTokens = 0;
            }
        }

        return bonusTokens;
    }
}