/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// File: contracts/codecs/EggCodec.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity <0.9.0;

///@title Specification for encoding and decoding eggs.
///@author CryptoDragons.app.
library EggCodec {
    // NB: View in an IDE without wordwrap.

    /*
     * ..............................................................................................................................................................1................................................................................................. card
     * ..........................................................................................................................................................1111.................................................................................................. magic
     * 1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111...................................................................................................... wallet
     */

    /**
     * @dev Shift, length and mask bitmap data for the card
     * 0 = Card 0 (Rare)
     * 1 = Card 1 (Uncommon)
     *
     * Bits 97 to 97 (1 bit: 0 to 1) card
     */
    uint256 private constant CARD_SHIFT = 97;
    uint256 private constant CARD_LENGTH = 1;
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 private constant CARD_MASK =
        0x000000000000000000000000000000000000002000000000000000000000000;

    ///@dev A token's card number is 0 (rare)
    uint256 private constant CARD_0_RARE = 0;
    ///@dev A token's card number is 1 (uncommon)
    uint256 private constant CARD_1_UNCOMMON = 1;

    /**
     * @dev Shift, length and mask bitmap data for the magic
     * Valid values for egg: 5, 10
     * Could codify as a single bit, but keeping as an integer for ease of decoding by contracts
     *
     * Bits 98 to 101 (4 bits: 0 to 15) magic
     */
    uint256 private constant MAGIC_SHIFT = CARD_SHIFT + CARD_LENGTH;
    uint256 private constant MAGIC_LENGTH = 4;
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 private constant MAGIC_MASK =
        0x000000000000000000000000000000000000003C000000000000000000000000;

    ///@dev A token's magic is 5
    uint256 private constant MAGIC_5 = 5;
    ///@dev A token's magic is 10
    uint256 private constant MAGIC_10 = 10;

    /**
     * @dev Shift, length and mask bitmap data for the wallet address of the minter
     *
     * Bits 102 to 255 (154 bits: 0 to 22835963083295358096932575511191922182123945983)
     */
    uint256 private constant WALLET_SHIFT = MAGIC_SHIFT + MAGIC_LENGTH;
    uint256 private constant WALLET_LENGTH = 154;
    // 1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 private constant WALLET_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC0000000000000000000000000;

    ///@dev Not enough room in the token to store the whole wallet address, so have to shift by this much to fit
    uint256 private constant ADDRESS_SHIFT = 160 - WALLET_LENGTH;

    /**
     * @dev Card of `token_`
     * @param token_ Token
     * @return card_ Card of `token`
     */
    function card(uint256 token_) internal pure returns (uint256 card_) {
        card_ = (token_ & CARD_MASK) >> CARD_SHIFT;
    }

    /**
     * @dev Is card of `token_` 0 (rare)?
     * @param token_ Token
     * @return isCard0Rare_ Whether card `token` is 0 (rare)
     */
    function isCard0Rare(uint256 token_)
        internal
        pure
        returns (bool isCard0Rare_)
    {
        isCard0Rare_ = CARD_0_RARE == card(token_);
    }

    /**
     * @dev Is card of `token_` 1 (uncommon)?
     * @param token_ Token
     * @return isCard1Uncommon_ Whether card `token` is 1 (uncommon)
     */
    function isCard1Uncommon(uint256 token_)
        internal
        pure
        returns (bool isCard1Uncommon_)
    {
        isCard1Uncommon_ = CARD_1_UNCOMMON == card(token_);
    }

    /**
     * @dev Magic of `token_`
     * @param token_ Token
     * @return magic_  Magic of `token`
     */
    function magic(uint256 token_) internal pure returns (uint256 magic_) {
        magic_ = (token_ & MAGIC_MASK) >> MAGIC_SHIFT;
    }

    /**
     * @dev Wallet of minter of `token_`
     * @param token_ Token
     * @return wallet_  Wallet of minter of `token`
     */
    function wallet(uint256 token_) internal pure returns (uint256 wallet_) {
        wallet_ = (token_ & WALLET_MASK) >> WALLET_SHIFT;
    }

    /**
     * @dev Get the address of the sender shifted to fit in the allocated space in the token
     * @return shiftedSenderAddress_ Shifted sender address
     */
    function shiftedSenderAddress() private view returns (uint256 shiftedSenderAddress_) {
        shiftedSenderAddress_ = uint256(uint160(msg.sender) >> ADDRESS_SHIFT);
    }

    /**
     * @dev Is sender minter of `token_`?
     * @param token_ Token
     * @return isSenderMinter_ Whether sender is minter of `token`
     */
    function isSenderMinter(uint256 token_)
        internal
        view
        returns (bool isSenderMinter_)
    {
        isSenderMinter_ = shiftedSenderAddress() == wallet(token_);
    }

    /**
     * @dev All egg data for `token_`
     * @param token_ Token
     * @return card_ Card of `token_`
     * @return magic_ Magic of `token_`
     * @return wallet_ Wallet of `token_`
     */
    function eggData(uint256 token_)
        internal
        pure
        returns (
            uint256 card_,
            uint256 magic_,
            uint256 wallet_
        )
    {
        card_ = card(token_);
        magic_ = magic(token_);
        wallet_ = wallet(token_);
    }

    /**
     * @dev Set the card bits of `token_`
     * @param token_ Token
     * @param card_ Card to set
     * @return tokenWithCard_ `token_` with card bits set to `card_`
     */
    function setCard(uint256 token_, uint256 card_)
        private
        pure
        returns (uint256 tokenWithCard_)
    {
        require(card(token_) == 0);
        if (CARD_0_RARE == card_) return token_;
        require(card_ < 2**CARD_LENGTH);

        tokenWithCard_ = token_ | (card_ << CARD_SHIFT);
    }

    /**
     * @dev Set the card bits of `token_` to be card 0 (rare)
     * @param token_ Token
     * @return tokenWithCard_ `token_` with card bits set to card 0 (rare)
     */
    function setCard0Rare(uint256 token_)
        private
        pure
        returns (uint256 tokenWithCard_)
    {
        tokenWithCard_ = setCard(token_, CARD_0_RARE);
    }

    /**
     * @dev Set the card bits of `token_` to be card 1 (uncommon)
     * @param token_ Token
     * @return tokenWithCard_ `token_` with card bits set to card 1 (uncommon)
     */
    function setCard1Uncommon(uint256 token_)
        private
        pure
        returns (uint256 tokenWithCard_)
    {
        tokenWithCard_ = setCard(token_, CARD_1_UNCOMMON);
    }

    /**
     * @dev Set the magic bits of `token_`
     * @param token_ Token
     * @param magic_ Magic to set
     * @return tokenWithMagic_ `token_` with magic bits set to `magic_`
     */
    function setMagic(uint256 token_, uint256 magic_)
        private
        pure
        returns (uint256 tokenWithMagic_)
    {
        require(magic(token_) == 0);
        require(magic_ < 2**MAGIC_LENGTH);

        tokenWithMagic_ = token_ | (magic_ << MAGIC_SHIFT);
    }

    /**
     * @dev Set the magic bits of `token_` to be 5
     * @param token_ Token
     * @return tokenWithMagic_ `token_` with magic bits set to 5
     */
    function setMagic5(uint256 token_)
        private
        pure
        returns (uint256 tokenWithMagic_)
    {
        tokenWithMagic_ = setMagic(token_, MAGIC_5);
    }

    /**
     * @dev Set the magic bits of `token_` to be 10
     * @param token_ Token
     * @return tokenWithMagic_ `token_` with magic bits set to 10
     */
    function setMagic10(uint256 token_)
        private
        pure
        returns (uint256 tokenWithMagic_)
    {
        tokenWithMagic_ = setMagic(token_, MAGIC_10);
    }

    /**
     * @dev Set the card and magic bits of `token_` for a rare egg
     * @param token_ Token
     * @return tokenWithCardAndMagic_ `token_` with card and magic bits set for a rare egg
     */
    function setCardAndMagicRare(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithCardAndMagic_)
    {
        tokenWithCardAndMagic_ = setCard0Rare(setMagic10(token_));
    }

    /**
     * @dev Set the card and magic bits of `token_` for an uncommon egg
     * @param token_ Token
     * @return tokenWithCardAndMagic_ `token_` with card and magic bits set for an uncommon egg
     */
    function setCardAndMagicUncommon(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithCardAndMagic_)
    {
        tokenWithCardAndMagic_ = setCard1Uncommon(setMagic5(token_));
    }

    /**
     * @dev Set the wallet bits of `token_` to the shifted address of sender
     * @param token_ Token
     * @return tokenWithWallet_ `token_` with wallet bits set`
     */
    function setWallet(uint256 token_)
        internal
        view
        returns (uint256 tokenWithWallet_)
    {
        tokenWithWallet_ = token_ | (shiftedSenderAddress() << WALLET_SHIFT);
    }
}

// File: contracts/codecs/INftCodec.sol

pragma solidity <0.9.0;

///@title Specification for encoding and decoding iNFTs.
///@author CryptoDragons.app.
library INftCodec {
    // NB: View in an IDE without wordwrap.

    /*
     * ................................................................................................................................................................................................1111111111111111111111111111111111111111111111111111111111111111 id
     * ........................................................................................................................................................................................11111111................................................................ chain
     * .......................................................................................................................................................................................1........................................................................ fungibility
     * .......................................................................................................................................................................1111111111111111......................................................................... _type
     * ...............................................................................................................................................................11111111......................................................................................... version
     */

    /**
     * @dev Shift, length and mask bitmap data for the token id
     *
     * Bits 0 to 63 (64 bits: 0 to 18446744073709551615)
     */
    uint256 private constant ID_SHIFT = 0;
    uint256 private constant ID_LENGTH = 64;
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111
    uint256 private constant ID_MASK =
        0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF;

    /**
     * @dev Shift, length and mask bitmap data for the source chain of the token
     * 0 = Polygon
     * Others to be determined
     * 
     * Bits 64 to 71 (8 bits: 0 to 255)
     */
    uint256 private constant CHAIN_SHIFT = ID_SHIFT + ID_LENGTH;
    uint256 private constant CHAIN_LENGTH = 8;
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000000000000000
    uint256 private constant CHAIN_MASK =
        0x0000000000000000000000000000000000000000000000FF0000000000000000;

    ///@dev A token's source chain is Polygon
    uint256 private constant POLYGON = 0;

    /**
     * @dev Shift, length and mask bitmap data for the fungibility of the token
     * 0 = Fungible or semi-fungible
     * 1 = Non-fungible
     *
     * Bits 72 to 72 (1 bit: 0 to 1)
     */
    uint256 private constant FUNGIBILITY_SHIFT = CHAIN_SHIFT + CHAIN_LENGTH;
    uint256 private constant FUNGIBILITY_LENGTH = 1;
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 private constant FUNGIBILITY_MASK =
        0x0000000000000000000000000000000000000000000001000000000000000000;

    ///@dev A token is fungible
    uint256 private constant FUNGIBLE = 0;
    ///@dev A token is non-fungible
    uint256 private constant NON_FUNGIBLE = 1;

    /**
     * @dev Shift, length and mask bitmap data for the type of the token
     * 0 = Reserved
     * 1 = Egg
     * 2 = Dragon
     * Others to be determined
     *
     * Bits 73 to 88 (16 bits: 0 to 65535)
     */
    uint256 private constant TYPE_SHIFT =
        FUNGIBILITY_SHIFT + FUNGIBILITY_LENGTH;
    uint256 private constant TYPE_LENGTH = 16;
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 private constant TYPE_MASK =
        0x000000000000000000000000000000000000000001FFFE000000000000000000;

    ///@dev A token is of the reserved type
    uint256 private constant RESERVED = 0;
    ///@dev A token is of the egg type
    uint256 private constant EGG = 1;
    ///@dev A token is of the dragon type
    uint256 private constant DRAGON = 2;

    /**
     * @dev Shift, length and mask bitmap data for the token version
     * 0 = Version 1
     * Others to be determined
     *
     * Bits 89 to 96 (8 bits: 0 to 255)
     */
    uint256 internal constant VERSION_SHIFT = TYPE_SHIFT + TYPE_LENGTH;
    uint256 internal constant VERSION_LENGTH = 8;
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 private constant VERSION_MASK =
        0x0000000000000000000000000000000000000001FE0000000000000000000000;

    ///@dev A token is version 1
    uint256 private constant VERSION_1 = 0;

    /**
     * @dev Id of `token_`
     * @param token_ Token
     * @return id_ Id of `token`
     */
    function id(uint256 token_) internal pure returns (uint256 id_) {
        id_ = (token_ & ID_MASK) >> ID_SHIFT;
    }

    /**
     * @dev Source chain of `token_`
     * @param token_ Token
     * @return chain_ Source chain of `token`
     */
    function chain(uint256 token_) internal pure returns (uint256 chain_) {
        chain_ = (token_ & CHAIN_MASK) >> CHAIN_SHIFT;
    }

    /**
     * @dev Is source chain of `token_` Polygon?
     * @param token_ Token
     * @return isChainPolygon_ Whether source chain of `token` is Polygon
     */
    function isChainPolygon(uint256 token_)
        internal
        pure
        returns (bool isChainPolygon_)
    {
        isChainPolygon_ = POLYGON == chain(token_);
    }

    /**
     * @dev Fungibility of `token_`
     * @param token_ Token
     * @return fungibility_ Fungibility of `token_`
     */
    function fungibility(uint256 token_)
        internal
        pure
        returns (uint256 fungibility_)
    {
        fungibility_ = (token_ & FUNGIBILITY_MASK) >> FUNGIBILITY_SHIFT;
    }

    /**
     * @dev  Is `token_` fungible?
     * @param token_ Token
     * @return isFungible_ Whether `token_` is fungible
     */
    function isFungible(uint256 token_)
        internal
        pure
        returns (bool isFungible_)
    {
        isFungible_ = FUNGIBLE == fungibility(token_);
    }

    /**
     * @dev  Is `token_` non-fungible?
     * @param token_ Token
     * @return isNonFungible_ Whether `token_` is non-fungible
     */
    function isNonFungible(uint256 token_)
        internal
        pure
        returns (bool isNonFungible_)
    {
        isNonFungible_ = NON_FUNGIBLE == fungibility(token_);
    }

    /**
     * @dev Type of an `token_`
     * @param token_ Token
     * @return type__ Type of `token_`
     */
    function type_(uint256 token_) internal pure returns (uint256 type__) {
        type__ = (token_ & TYPE_MASK) >> TYPE_SHIFT;
    }

    /**
     * @dev Is `token_` an egg?
     * @param token_ Token
     * @return isEgg_ Whether `token_` is an egg
     */
    function isEgg(uint256 token_) internal pure returns (bool isEgg_) {
        isEgg_ = EGG == type_(token_);
    }

    /**
     * @dev Is `token_` a dragon?
     * @param token_ Token
     * @return isDragon_ Whether `token_` is a dragon
     */
    function isDragon(uint256 token_) internal pure returns (bool isDragon_) {
        isDragon_ = DRAGON == type_(token_);
    }

    /**
     * @dev Version of `token_`
     * @param token_ Token
     * @return version_ Version of `token_`
     */
    function version(uint256 token_) internal pure returns (uint256 version_) {
        version_ = (token_ & VERSION_MASK) >> VERSION_SHIFT;
    }

    /**
     * @dev Is `token_` version 1?
     * @param token_ Token
     * @return isVersion1_ Whether version of `token_` is 1
     */
    function isVersion1(uint256 token_)
        internal
        pure
        returns (bool isVersion1_)
    {
        isVersion1_ = VERSION_1 == version(token_);
    }

    /**
     * @dev All core data for `token_`
     * @param token_ Token
     * @return id_ Id of `token_`
     * @return chain_ Chain of `token_`
     * @return fungibility_ Fungibility of `token_`
     * @return type__ Type of `token_`
     * @return version_ Version of `token_`
     */
    function coreData(uint256 token_)
        internal
        pure
        returns (
            uint256 id_,
            uint256 chain_,
            uint256 fungibility_,
            uint256 type__,
            uint256 version_
        )
    {
        id_ = id(token_);
        chain_ = chain(token_);
        fungibility_ = fungibility(token_);
        type__ = type_(token_);
        version_ = version(token_);
    }

    /**
     * @dev Set the id bits of `token_`
     * @param token_ Token
     * @param id_ Id to set
     * @return tokenWithId_ `token_` with id bits set to `id_`
     */
    function setId(uint256 token_, uint256 id_)
        internal
        pure
        returns (uint256 tokenWithId_)
    {
        require(id(token_) == 0);
        require(id_ < 2**ID_LENGTH);

        tokenWithId_ = token_ | (id_ << ID_SHIFT);
    }

    /**
     * @dev Set the chain bits of `token_`
     * @param token_ Token
     * @param chain_ Id to set
     * @return tokenWithChain_ `token_` with chain bits set to `chain_`
     */
    function setChain(uint256 token_, uint256 chain_)
        private
        pure
        returns (uint256 tokenWithChain_)
    {
        require(chain(token_) == 0);
        if (POLYGON == chain_) return token_;
        require(chain_ < 2**CHAIN_LENGTH);

        tokenWithChain_ = token_ | (chain_ << CHAIN_SHIFT);
    }

    /**
     * @dev Set the chain bits of `token_` to be Polygon
     * @param token_ Token
     * @return tokenWithChain_ `token_` with chain bits set to Polygon
     */
    function setPolygon(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithChain_)
    {
        tokenWithChain_ = setChain(token_, POLYGON);
    }

    /**
     * @dev Set the fungibility bits of `token_`
     * @param token_ Token
     * @param fungibility_ Fungibility to set
     * @return tokenWithFungiblity_ `token_` with fungibility bits set to `fungibility_`
     */
    function setFungibility(uint256 token_, uint256 fungibility_)
        private
        pure
        returns (uint256 tokenWithFungiblity_)
    {
        require(fungibility(token_) == 0);
        if (FUNGIBLE == fungibility_) return token_;
        require(fungibility_ < 2**FUNGIBILITY_LENGTH);

        tokenWithFungiblity_ = token_ | (fungibility_ << FUNGIBILITY_SHIFT);
    }

    /**
     * @dev Set the fungibility bits of `token_` to be fungible
     * @param token_ Token
     * @return tokenWithFungiblity_ `token_` with fungibility bits set to fungible
     */
    function setFungible(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithFungiblity_)
    {
        tokenWithFungiblity_ = setFungibility(token_, FUNGIBLE);
    }

    /**
     * @dev Set the fungibility bits of `token_` to be non-fungible
     * @param token_ Token
     * @return tokenWithFungiblity_ `token_` with fungibility bits set to non-fungible
     */
    function setNonFungible(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithFungiblity_)
    {
        tokenWithFungiblity_ = setFungibility(token_, NON_FUNGIBLE);
    }

    /**
     * @dev Set the type bits of `token_`
     * @param token_ Token
     * @param type__ Type to set
     * @return tokenWithType_ `token_` with type bits set to `type_`
     */
    function setType(uint256 token_, uint256 type__)
        private
        pure
        returns (uint256 tokenWithType_)
    {
        require(type_(token_) == 0);
        require(type__ != RESERVED);
        require(type__ < 2**TYPE_LENGTH);

        tokenWithType_ = token_ | (type__ << TYPE_SHIFT);
    }

    /**
     * @dev Set the type bits of `token_` to be egg
     * @param token_ Token
     * @return tokenWithType_ `token_` with type bits set to egg
     */
    function setEgg(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithType_)
    {
        tokenWithType_ = setType(token_, EGG);
    }

    /**
     * @dev Set the type bits of `token_` to be dragon
     * @param token_ Token
     * @return tokenWithType_ `token_` with type bits set to dragon
     */
    function setDragon(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithType_)
    {
        tokenWithType_ = setType(token_, DRAGON);
    }

    /**
     * @dev Set the version bits of `token_`
     * @param token_ Token
     * @param version_ Version to set
     * @return tokenWithVersion_ `token_` with version bits set to `version_`
     */
    function setVersion(uint256 token_, uint256 version_)
        private
        pure
        returns (uint256 tokenWithVersion_)
    {
        require(version(token_) == 0);
        if (VERSION_1 == version_) return token_;
        require(version_ < 2**VERSION_LENGTH);

        tokenWithVersion_ = token_ | (version_ << VERSION_SHIFT);
    }

    /**
     * @dev Set the version bits of `token_` to be version 1
     * @param token_ Token
     * @return tokenWithVersion_ `token_` with type bits set to version 1
     */
    function setVersion1(uint256 token_)
        internal
        pure
        returns (uint256 tokenWithVersion_)
    {
        tokenWithVersion_ = setVersion(token_, VERSION_1);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/EggSpawner.sol

pragma solidity 0.8.10;







///@dev Interface to functions in the core ERC-1155 iNFT contract.
interface IINft {
    /**
     * @dev Creates a single token of token type `id`, and assigns it to `to`.
     * The lower 64 bits of `id` are set to {nextTokenId} to ensure uniqueness.
     *
     * Emits a {TransferSingle} event.
     *
     * This is a convenience overload for minting NFTs that doesn't require an amount parameter, which is set to
     * {SINGLE_NFT} before calling the main overload.
     *
     * This is a convenience overload that doesn't require a data parameter, which is set to empty before
     * calling the main overload.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `id` must have its fungibility bit set to fungible if amounts > {SINGLE_NFT} are to be minted.
     */
    function mintNFT(address to, uint256 id) external;

    ///@dev The id number of the next token to be created.
    function nextTokenId() external returns (uint64);
}

///@title Spawner for presale rare and uncommon eggs.
///@author CryptoDragons.app.
contract EggSpawner is Ownable, Pausable {
    using SafeERC20 for IERC20;

    using INftCodec for uint256;
    using EggCodec for uint256;

    ///@dev Possible phases for the presale to be in.
    enum Phase {
        NOT_STARTED,
        RARE,
        UNCOMMON,
        ENDED
    }

    ///@dev Address of the USDC contract used to pay for eggs.
    IERC20 private immutable usdc;
    ///@dev Cost in USDC of an egg.
    uint256 public rate = 50000000;
    ///@dev Address of the core ERC-1155 iNFT contract.
    IINft private immutable iNft;
    ///@dev Address of the multisig safe that receives the sale proceeds.
    address public multisig;
    ///@dev Current phase the presale is in.
    Phase public phase = Phase.NOT_STARTED;
    ///@dev Mapping from an address to the token id of the rare egg it owns (if any).
    mapping(address => uint256) public rareEggs;
    ///@dev Mapping from an address to the token id of the uncommon egg it owns (if any).
    mapping(address => uint256) public uncommonEggs;
    ///@dev The total number of rare eggs created.
    uint256 public rareEggCount;
    ///@dev The total number of uncommon eggs created.
    uint256 public uncommonEggCount;
    /**
     * @dev For testing that admin permissions have been successfully transferred
     * to a multisig before renouncing the admin role from the deployer wallet.
     *
     * See {setFlag} and {resetFlag}.
     */
    bool public flag = false;

    /**
     * @dev Create the egg spawner.
     * @param usdc_ Address of the USDC contract used to pay for eggs.
     * @param iNft_ Address of the core ERC-1155 iNFT contract.
     * @param multisig_ Address of the multisig safe that receives the sale proceeds.
     */
    constructor(
        IERC20 usdc_,
        IINft iNft_,
        address multisig_
    ) {
        iNft = iNft_;
        usdc = usdc_;
        multisig = multisig_;
    }

    /**
     * @dev Convert an iNFT token id representing an egg to its statistics.
     * @param token_ Token
     * @return id_ Id of `token_`
     * @return chain_ Chain of `token_`
     * @return fungibility_ Fungibility of `token_`
     * @return type_ Type of `token_`
     * @return version_ Version of `token_`
     * @return card_ Card of `token_`
     * @return magic_ Magic of `token_`
     * @return wallet_ Wallet of `token_`
     */
    function tokenToStats(uint256 token_)
        public
        pure
        returns (
            uint256 id_,
            uint256 chain_,
            uint256 fungibility_,
            uint256 type_,
            uint256 version_,
            uint256 card_,
            uint256 magic_,
            uint256 wallet_
        )
    {
        (id_, chain_, fungibility_, type_, version_) = token_.coreData();
        (card_, magic_, wallet_) = token_.eggData();

        require(INftCodec.isNonFungible(token_), "Not an NFT");
        require(INftCodec.isVersion1(token_), "Unknown version");
        require(INftCodec.isEgg(token_), "Not an egg");
    }

    /**
     * @dev Is sender minter of `token_`?
     * @param token_ Token
     * @return isSenderMinter_ Whether sender is minter of `token`
     */
    function isSenderMinter(uint256 token_)
        public
        view
        returns (bool isSenderMinter_)
    {
        isSenderMinter_ = token_.isSenderMinter();
    }

    /**
     * @dev Set data on `_token` that is common to all eggs.
     * @return token_ token with common data set.
     */
    function commonDataToToken() private view returns (uint256 token_) {
        token_ = token_
            .setPolygon()
            .setNonFungible()
            .setEgg()
            .setVersion1()
            .setWallet();
    }

    /**
     * @dev Generate a token id for a rare egg (card 0).
     * @return token_ Token with id for a rare egg (card 0).
     */
    function card0RareToToken() public view returns (uint256 token_) {
        token_ = commonDataToToken().setCardAndMagicRare();
    }

    /**
     * @dev Generate a token id for an uncommon egg (card 1).
     * @return token_ Token with id for an uncommon egg (card 1).
     */
    function card1UncommonToToken() public view returns (uint256 token_) {
        token_ = commonDataToToken().setCardAndMagicUncommon();
    }

    /**
     * @dev Require that the contract be in active presale phases.
     */
    modifier duringSale() {
        require(Phase.NOT_STARTED != phase, "Not started");
        require(Phase.ENDED != phase, "Already ended");
        _;
    }

    /**
     * @dev Create a presale egg for sender in exchange for USDC.
     *
     * Only available when the contract is in active presale phase.
     */
    function spawnEgg() external duringSale {
        if (0 < rate) {
            usdc.safeTransferFrom(msg.sender, multisig, rate);
        }

        uint256 token;

        if (Phase.RARE == phase) {
            require(0 == rareEggs[msg.sender], "Already have Rare egg");

            token = card0RareToToken();

            ++rareEggCount;
            rareEggs[msg.sender] = token | iNft.nextTokenId();
        } else if (Phase.UNCOMMON == phase) {
            require(0 == uncommonEggs[msg.sender], "Already have Uncommon egg");

            token = card1UncommonToToken();

            ++uncommonEggCount;
            uncommonEggs[msg.sender] = token | iNft.nextTokenId();
        }

        iNft.mintNFT(msg.sender, token);
    }

    /**
     * @dev Move the contract phase onto the next state.
     */
    function advancePhase() external onlyOwner {
        if (Phase.NOT_STARTED == phase) {
            phase = Phase.RARE;
        } else if (Phase.RARE == phase) {
            phase = Phase.UNCOMMON;
        } else if (Phase.UNCOMMON == phase) {
            phase = Phase.ENDED;
        }
    }

    /**
     * @dev Set the rate for minting eggs.
     * @param rate_ The new rate.
     */
    function setRate(uint256 rate_) external onlyOwner {
        rate = rate_;
    }

    /**
     * @dev Set the multisig safe address that receives sale proceeds.
     * @param multisig_ The new multisig safe address.
     */
    function setMultisig(address multisig_) external onlyOwner {
        multisig = multisig_;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev For testing that admin permissions have been successfully transferred
     * to a multisig before renouncing the admin role from the deployer wallet.
     */
    function setFlag() external onlyOwner {
        flag = true;
    }

    /**
     * @dev Reset flag. Callable by anyone.
     */
    function resetFlag() external {
        flag = false;
    }
}