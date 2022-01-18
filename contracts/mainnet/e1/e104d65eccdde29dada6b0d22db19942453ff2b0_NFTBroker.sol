/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*
 __________________________________
|                                  |
| $ + $ + $ + $ + $ + $ + $ + $ + $|
|+ $ + $ + $ + $ + $ + $ + $ + $ + |
| + $ + $ + $ + $ + $ + $ + $ + $ +|
|$ + $ + $ + $ + $ + $ + $ + $ + $ |
| $ + $ + $ + $ + $ + $ + $ + $ + $|
|+ $ + $ + $ + $ + $ + $ + $ + $ + |
| + $ + $ + $ + $ + $ + $ + $ + $ +|
|__________________________________|

*/

/**
 * @title NFT Broker
 * @author CXIP-Labs
 * @notice A simple smart contract for selling NFTs from a private storefront.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract NFTBroker {

    /**
     * @dev Address of admin user. Primarily used as an additional recovery address.
     */
    address private _admin;

    /**
     * @dev Address of contract owner. This address can run all onlyOwner functions.
     */
    address private _owner;

    /**
     * @dev Address of wallet that can authorise proof of stake claims.
     */
    address private _notary;

    /**
     * @dev Address of the token being sold.
     */
    address payable private _tokenContract;

    /**
     * @dev UNIX timestamp of from when the tier 1 is open.
     */
    uint256 private _tier1;

    /**
     * @dev UNIX timestamp of from when the tier 2 is open.
     */
    uint256 private _tier2;

    /**
     * @dev UNIX timestamp of from when the tier 3 is open.
     */
    uint256 private _tier3;

    /**
     * @dev List of all wallets that are tier1.
     */
    mapping(address => bool) private _tier1wallets;

    /**
     * @dev Specific map of what tokenId is allowed to mint for a specific wallet.
     */
    mapping(address => uint256[]) private _reservedTokens;

    /**
     * @dev Specific map of amount of free tokens that a specific wallet can mint.
     */
    mapping(address => uint256) private _reservedTokenAmounts;

    /**
     * @dev A map keeping tally of total numer of tokens purchased by a wallet.
     */
    mapping(address => uint256) private _purchasedTokens;

    /**
     * @dev Base purchase price of token in wei.
     */
    uint256 private _tokenBasePrice;

    /**
     * @dev Stake purchase price of token in wei.
     */
    uint256 private _tokenStakePrice;

    /**
     * @dev Claim purchase price of token in wei.
     */
    uint256 private _tokenClaimPrice;

    /**
     * @dev Array of all tokenIds available for minting/purchasing.
     */
    uint256[] private _allTokens;

    /**
     * @dev Mapping from token id to position in the allTokens array.
     */
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev Boolean indicating whether to automatically withdraw payments made for minting.
     */
    bool private _autoWithdraw;

    /**
     * @dev Capped limit of how many purchases can be made per wallet.
     */
    uint256 private _maxPurchases;

    /**
     * @dev Boolean indicating whether _maxPurchases should be enforced.
     */
    bool private _reserveLifted;

    /**
     * @dev Mapping of all approved functions for specific contracts. To be used for delegate calls.
     */
    mapping(address => mapping(bytes4 => bool)) private _approvedFunctions;

    /**
     * @dev Throws if called by any account other than the owner/admin.
     */
    modifier onlyOwner() {
        require(isOwner(), "CXIP: caller not an owner");
        _;
    }

    /**
     * @dev Can be deployed with factory contracts, _admin will always be set to transaction initiator.
     * @param tokenContract Address of the contract that will mint the tokens.
     * @param notary Address of the wallet that will be used for validating stake&mint function values.
     * @param autoWithdraw If enabled, eth will be sent to Identity automatically on payment for minting.
     * @param newOwner Address of wallet/contract that will have authorization to make onlyOwner calls.
     */
    constructor (address tokenContract, address notary, bool autoWithdraw, uint256 maxPurchases, address newOwner) {
        _admin = tx.origin;
        _owner = newOwner;
        _tokenContract = payable(tokenContract);
        _notary = notary;
        _autoWithdraw = autoWithdraw;
        _maxPurchases = maxPurchases;
    }

    /**
     * @notice Pay eth and buy a token.
     * @dev Token must first be added to list of available tokens. A non-minted token will fail this call.
     * @param tokenId The id of token to buy.
     */
    function buyToken (uint256 tokenId) public payable {
        ISNUFFY500 snuffy = ISNUFFY500(_tokenContract);
        require(snuffy.exists(tokenId), "CXIP: token not minted");
        require(_exists(tokenId), "CXIP: token not for sale");
        require(snuffy.ownerOf(tokenId) == address(this), "CXIP: broker not owner of token");
        if (_tier1wallets[msg.sender]) {
            require(msg.value >= _tokenClaimPrice, "CXIP: payment amount is too low");
        } else {
            require(msg.value >= _tokenBasePrice, "CXIP: payment amount is too low");
        }
        if (!_reserveLifted) {
            require(_purchasedTokens[msg.sender] < _maxPurchases, "CXIP: max allowance reached");
        }
        _purchasedTokens[msg.sender] = _purchasedTokens[msg.sender] + 1;
        snuffy.safeTransferFrom(address(this), msg.sender, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);
        if (_autoWithdraw) {
            _moveEth();
        }
    }

    /**
     * @notice Claim and mint free token.
     * @dev Wallets needs to be added to whitelist in order for this function to work.
     * @param tokenId The id of token to mint.
     * @param tokenData The complete data for the minted token.
     * @param verification A signature for the tokenId and tokenData, made by a wallet authorized by Identity
     */
    function claimAndMint (uint256 tokenId, TokenData[] calldata tokenData, Verification calldata verification) public {
        require(block.timestamp >= _tier1, "CXIP: too early to claim");
        require(!ISNUFFY500(_tokenContract).exists(tokenId), "CXIP: token snatched");
        if (_reservedTokenAmounts[msg.sender] > 0) {
            require(_exists(tokenId), "CXIP: token not for sale");
            ISNUFFY500(_tokenContract).mint(0, tokenId, tokenData, _admin, verification, msg.sender);
            _reservedTokenAmounts[msg.sender] = _reservedTokenAmounts[msg.sender] - 1;
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else {
            uint256 length = _reservedTokens[msg.sender].length;
            require(length > 0, "CXIP: no tokens to claim");
            uint256 index = length - 1;
            require(_reservedTokens[msg.sender][index] == tokenId, "CXIP: not your token");
            delete _reservedTokens[msg.sender][index];
            _reservedTokens[msg.sender].pop();
            ISNUFFY500(_tokenContract).mint(1, tokenId, tokenData, _admin, verification, msg.sender);
        }
        if (!_tier1wallets[msg.sender]) {
            _tier1wallets[msg.sender] = true;
        }
        if (_autoWithdraw) {
            _moveEth();
        }
    }

    /**
     * @notice Call a pre-approved external function.
     * @dev This allows to extend the functionality of the contract, without the need of a complete re-deployment.
     * @param target Address of smart contract to call.
     * @param functionHash Function hash of the external contract function to call.
     * @param payload Entire payload to include in the external call. Keep in mind to not include function hash.
     */
    function delegateApproved (address target, bytes4 functionHash, bytes calldata payload) public payable {
        require(_approvedFunctions[target][functionHash], "CXIP: not approved delegate call");
        (bool success, bytes memory data) = target.delegatecall(abi.encodePacked(functionHash, payload));
        require(success, string(data));
    }

    /**
     * @notice Pay eth and mint a token.
     * @dev Token must first be added to list of available tokens. An already minted token will fail on mint.
     * @param tokenId The id of token to mint.
     * @param tokenData The complete data for the minted token.
     * @param verification A signature for the tokenId and tokenData, made by a wallet authorized by Identity
     */
    function payAndMint (uint256 tokenId, TokenData[] calldata tokenData, Verification calldata verification) public payable {
        require(block.timestamp >= _tier3 || _tier1wallets[msg.sender], "CXIP: too early to buy");
        require(!ISNUFFY500(_tokenContract).exists(tokenId), "CXIP: token snatched");
        require(_exists(tokenId), "CXIP: token not for sale");
        if (_tier1wallets[msg.sender]) {
            if (_purchasedTokens[msg.sender] > 0) {
                require(msg.value >= _tokenClaimPrice, "CXIP: payment amount is too low");
            }
        } else {
            require(msg.value >= _tokenBasePrice, "CXIP: payment amount is too low");
        }
        if (!_reserveLifted) {
            require(_purchasedTokens[msg.sender] < _maxPurchases, "CXIP: max allowance reached");
        }
        _purchasedTokens[msg.sender] = _purchasedTokens[msg.sender] + 1;
        ISNUFFY500(_tokenContract).mint(0, tokenId, tokenData, _admin, verification, msg.sender);
        _removeTokenFromAllTokensEnumeration(tokenId);
        if (_autoWithdraw) {
            _moveEth();
        }
    }

    /**
     * @notice Show proof of stake, and mint a token.
     * @dev First an off-chain validation of staking must be made, and signed by the notary wallet.
     * @param proof Signature made by the notary wallet, proving validity of stake.
     * @param tokens The total number of tokens staked by wallet.
     * @param tokenId The id of token to mint.
     * @param tokenData The complete data for the minted token.
     * @param verification A signature for the tokenId and tokenData, made by a wallet authorized by Identity
     */
    function proofOfStakeAndMint (Verification calldata proof, uint256 tokens, uint256 tokenId, TokenData[] calldata tokenData, Verification calldata verification) public payable {
        require(block.timestamp >= _tier2, "CXIP: too early to stake");
        require(msg.value >= _tokenStakePrice, "CXIP: payment amount is too low");
        require(!ISNUFFY500(_tokenContract).exists(tokenId), "CXIP: token snatched");
        require(_exists(tokenId), "CXIP: token not for sale");
        bytes memory encoded = abi.encodePacked(msg.sender, tokens);
        require(Signature.Valid(
            _notary,
            proof.r,
            proof.s,
            proof.v,
            encoded
        ), "CXIP: invalid signature");
        if (!_reserveLifted) {
            require(_purchasedTokens[msg.sender] < _maxPurchases, "CXIP: max allowance reached");
        }
        _purchasedTokens[msg.sender] = _purchasedTokens[msg.sender] + 1;
        ISNUFFY500(_tokenContract).mint(0, tokenId, tokenData, _admin, verification, msg.sender);
        _removeTokenFromAllTokensEnumeration(tokenId);
        if (_autoWithdraw) {
            _moveEth();
        }
    }

    /**
     * @notice Remove a token id from being reserved by a wallet.
     * @dev If you want to add a token id to for sale list, first remove it from a wallet if it has been reserved.
     * @param wallets Array of wallets for which to remove reserved tokens for.
     */
    function clearReservedTokens (address[] calldata wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            _reservedTokens[wallets[i]] = new uint256[](0);
        }
    }

    /**
     * @notice Can be used to bring logic from other smart contracts in (temporarily).
     * @dev Useful for fixing critical bugs, recovering lost tokens, and reversing accidental payments to contract.
     */
    /**
     * @notice Use an external contract's logic for internal use.
     * @dev This will make a delegate call and use an external contract's logic, while using internal storage.
     * @param target Address of smart contract to call.
     * @param payload Bytes of the payload to send. Including the 4 byte function hash.
     */
    function delegate (address target, bytes calldata payload) public onlyOwner {
        (bool success, bytes memory data) = target.delegatecall(payload);
        require(success, string(data));
    }

    /**
     * @notice Lift the imposed purchase limits.
     * @dev Use this function after purchasing is opened to all with no limits.
     */
    function liftPurchaseLimits () public onlyOwner {
        _reserveLifted = true;
    }

    /**
     * @notice Remove a token from being for sale.
     * @dev If you want to reserve a token, or it is no longer available, make sure to use this function and remove it.
     * @param tokens Array of token ids to remove from being for sale.
     */
    function removeOpenTokens (uint256[] calldata tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            _removeTokenFromAllTokensEnumeration(tokens[i]);
        }
    }

    /**
     * @notice Remove a token id from being reserved by a wallet.
     * @dev If you want to add a token id to for sale list, first remove it from a wallet if it has been reserved.
     * @param wallets Array of wallets for which to remove reserved tokens for.
     */
    function removeReservedTokens (address[] calldata wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            delete _reservedTokens[wallets[i]];
        }
    }

    /**
     * @notice Configure a delegate function call for use.
     * @dev This will allow users to call delegate calls on external contracts to the approved function.
     * @param target Address of smart contract that will be called.
     * @param functionHash Hash of function that will be called.
     * @param value Boolean indicating whether to approve or deny such a call.
     */
    function setApprovedFunction (address target, bytes4 functionHash, bool value) public onlyOwner {
        _approvedFunctions[target][functionHash] = value;
    }

    /**
     * @notice Set notary wallet address.
     * @dev The notary is used as a way to sign and validate proof of stake function calls.
     * @param notary Address of notary wallet to use.
     */
    function setNotary (address notary) public onlyOwner {
        _notary = notary;
    }

    /**
     * @notice Add token ids that are available for purchase.
     * @dev These tokens can be either those that still need to be minted, or already minted tokens.
     * @param tokens Array of token ids to add as available for sale.
     */
    function setOpenTokens (uint256[] calldata tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            _addTokenToEnumeration(tokens[i]);
        }
    }

    /**
     * @notice Set prices for each tier.
     * @dev It is recommended to make tier 1 price lowest, and tier 3 price highest.
     * @param claimPrice Amount in wei for Tier 3 purchase price.
     * @param claimPrice Amount in wei for Tier 1 purchase price.
     * @param stakePrice Amount in wei for Tier 2 purchase price.
     */
    function setPrices (uint256 basePrice, uint256 claimPrice, uint256 stakePrice) public onlyOwner {
        _tokenBasePrice = basePrice;
        _tokenClaimPrice = claimPrice;
        _tokenStakePrice = stakePrice;
    }

    /**
     * @notice Set maximum amount of purchases allowed to be made by a single wallet.
     * @dev This is only enforced if arePurchasesLimited is true. Claims do not count toward purchases.
     * @param limit Amount of token purchases that can be made.
     */
    function setPurchaseLimit (uint256 limit) public onlyOwner {
        _maxPurchases = limit;
    }

    /**
     * @notice Set the amounts of tokens that have already been purchased by wallets.
     * @dev Use this to add information for sales that occurred outside of this contract.
     * @param wallets Array of wallets to set specific amounts for.
     * @param amounts Array of specific amounts to set for the wallets.
     */
    function setPurchasedTokensAmount (address[] calldata wallets, uint256[] calldata amounts) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            _purchasedTokens[wallets[i]] = amounts[i];
        }
    }

    /**
     * @notice Set a specific amount of tokens that can be claimed by a wallet.
     * @dev Use this if a wallet is allowed to claim, but no specific token ids have been assigned.
     * @param wallets Array of wallets to add specific amounts for.
     * @param amounts Array of specific amounts to set for the wallets.
     */
    function setReservedTokenAmounts (address[] calldata wallets, uint256[] calldata amounts) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            _reservedTokenAmounts[wallets[i]] = amounts[i];
        }
    }

    /**
     * @notice Add a token that a wallet is pre-authorized to claim and mint.
     * @dev This function adds to the list of claimable tokens.
     * @param wallets Array of wallets for which to add a token that can be claimed.
     * @param tokens Array of token ids that a wallet can claim.
     */
    function setReservedTokens (address[] calldata wallets, uint256[] calldata tokens) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            _reservedTokens[wallets[i]].push (tokens[i]);
        }
    }

    /**
     * @notice Set the list of tokens that a wallet is pre-authorized to claim and mint.
     * @dev Resets the list of tokens for wallet to new submitted list.
     * @param wallets Array of wallets for which to set the list of tokens that can be claimed.
     * @param tokens Array of token ids that a wallet can claim.
     */
    function setReservedTokensArrays (address[] calldata wallets, uint256[][] calldata tokens) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            _reservedTokens[wallets[i]] = tokens[i];
        }
    }

    /**
     * @notice Set the time of each tier's activation.
     * @dev Can be changed at any time to push forward/back the activation times of each tier.
     * @param tier1 UNIX timestamp of when Tier 1 activates.
     * @param tier2 UNIX timestamp of when Tier 2 activates.
     * @param tier3 UNIX timestamp of when Tier 3 activates.
     */
    function setTierTimes (uint256 tier1, uint256 tier2, uint256 tier3) public onlyOwner {
        _tier1 = tier1;
        _tier2 = tier2;
        _tier3 = tier3;
    }

    /**
     * @notice Set a list of wallets as VIP.
     * @dev This allows to have wallets skip claim process and get discounted pricing directly.
     * @param wallets Array of wallets to set as VIPs.
     */
    function setVIPs (address[] calldata wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            _tier1wallets[wallets[i]] = true;
        }
    }

    /**
     * @notice Transfers ownership of the smart contract.
     * @dev Can't be transferred to a zero address.
     * @param newOwner Address of new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(!Address.isZero(newOwner), "CXIP: zero address");
        _owner = newOwner;
    }

    /**
     * @notice Withdraws all smart contract ETH.
     * @dev Can only be called by _admin or _owner. All contract ETH is send to sender.
     */
    function withdrawEth () public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Call a pre-approved external function.
     * @dev This allows to extend the functionality of the contract, without the need of a complete re-deployment.
     * @param target Address of smart contract to call.
     * @param functionHash Function hash of the external contract function to call.
     * @param payload Entire payload to include in the external call. Keep in mind to not include function hash.
     * @return bytes Returns data of response as raw bytes.
     */
    function delegateApprovedCall (address target, bytes4 functionHash, bytes calldata payload) public returns (bytes memory) {
        require(_approvedFunctions[target][functionHash], "CXIP: not approved delegate call");
        (bool success, bytes memory data) = target.delegatecall(abi.encodePacked(functionHash, payload));
        require(success, string(data));
        return data;
    }

    /**
     * @notice Simple function to accept safe transfers.
     * @dev Token transfers that are related to the _tokenContract are automatically added to _allTokens.
     * @param _operator The address of the smart contract that operates the token.
     * @dev Since it's not being used, the _from variable is commented out to avoid compiler warnings.
     * @dev _tokenId Id of the token being transferred in.
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * @return bytes4 Returns the interfaceId of onERC721Received.
     */
    function onERC721Received(
        address payable _operator,
        address/* _from*/,
        uint256 _tokenId,
        bytes calldata /*_data*/
    ) public returns (bytes4) {
        if (_operator == _tokenContract) {
            if (ISNUFFY500(_operator).ownerOf(_tokenId) == address(this)) {
                _addTokenToEnumeration (_tokenId);
            }
        }
        return 0x150b7a02;
    }

    /**
     * @notice Check if purchasing is limited.
     * @dev Call getPurchaseLimit if this returns true, to find out purchase limits.
     * @return bool Returns true if purchases are limited.
     */
    function arePurchasesLimited () public view returns (bool) {
        return !_reserveLifted;
    }

    /**
     * @notice Get the notary wallet address.
     * @dev This wallet is used to sign and validate proof of stake wallets.
     * @return address Returns address of wallet that signs the proof of stake messages.
     */
    function getNotary () public view returns (address) {
        return _notary;
    }

    /**
     * @notice Get the purchase prices for each tier.
     * @dev VIP wallets that are claiming tokens are not charged a fee.
     * @return basePrice Price of Tier 3 purchases.
     * @return claimPrice Price of Tier 1 purchases.
     * @return stakePrice Price of Tier 2 purchases.
     */
    function getPrices () public view returns (uint256 basePrice, uint256 claimPrice, uint256 stakePrice) {
        basePrice = _tokenBasePrice;
        claimPrice = _tokenClaimPrice;
        stakePrice = _tokenStakePrice;
    }

    /**
     * @notice Get maximum number of tokens that can be purchased.
     * @dev Used in conjunction with arePurchasesLimited function.
     * @return uint256 Returns the maximum amount of tokens that can be purchased at the moment.
     */
    function getPurchaseLimit() public view returns (uint256) {
        return _maxPurchases;
    }

    /**
     * @notice Check how many tokens have been purchased by a wallet.
     * @dev Used in conjunction with arePurchasesLimited function.
     * @param wallet Address of wallet in question.
     * @return uint256 Returns number of tokens that a wallet has already claimed/minted.
     */
    function getPurchasedTokensAmount (address wallet) public view returns (uint256) {
        return _purchasedTokens[wallet];
    }

    /**
     * @notice Check how many free token claims are available for a wallet.
     * @dev These are not token id locked claims.
     * @param wallet Address of wallet in question.
     * @return uint256 Returns the number of free claims available.
     */
    function getReservedTokenAmounts(address wallet) public view returns (uint256) {
        return _reservedTokenAmounts[wallet];
    }

    /**
     * @notice Check if there are any tokens specifically reserved for a wallet.
     * @dev Helpful function for front-end UI development.
     * @param wallet Address of the wallet to check.
     * @return uint256[] Returns an array of token ids that are reserved for that wallet to claim.
     */
    function getReservedTokens(address wallet) public view returns (uint256[] memory) {
        return _reservedTokens[wallet];
    }

    /**
     * @notice Get the timestamps for when each tier is activated.
     * @dev Check if a tier is active, meaning that relevant functions will work.
     * @return tier1 UNIX timestamp of when Tier 1 activates.
     * @return tier2 UNIX timestamp of when Tier 2 activates.
     * @return tier3 UNIX timestamp of when Tier 3 activates.
     */
    function getTierTimes () public view returns (uint256 tier1, uint256 tier2, uint256 tier3) {
        tier1 = _tier1;
        tier2 = _tier2;
        tier3 = _tier3;
    }

    /**
     * @notice Check if the sender is the owner.
     * @dev The owner could also be the admin.
     * @return bool Returns true if owner.
     */
    function isOwner() public view returns (bool) {
        return (msg.sender == _owner || msg.sender == _admin);
    }

    /**
     * @notice Check if a wallet is VIP.
     * @dev Any wallet that was whitelisted for specific tokenId or amount, is marked as VIP after first claim.
     * @param wallet Address of wallet in question.
     * @return bool Returns true if wallet is VIP.
     */
    function isVIP (address wallet) public view returns (bool) {
        return _tier1wallets[wallet];
    }

    /**
     * @notice Gets the owner's address.
     * @dev _owner is first set in init.
     * @return address Returns the address of owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Get token by index.
     * @dev Used in conjunction with totalSupply function to iterate over all tokens in collection.
     * @param index Index of token in array.
     * @return uint256 Returns the token id of token located at that index.
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "CXIP: index out of bounds");
        return _allTokens[index];
    }

    /**
     * @notice Get x amount of token ids, starting from index x.
     * @dev Can be used as pagination, to not have to get each token id through separate call.
     * @param start Index from which to start from.
     * @param length Total number of items to read in array.
     * @return tokens Returns an array of token ids.
     */
    function tokensByChunk(uint256 start, uint256 length) public view returns (uint256[] memory tokens) {
        if (start + length > totalSupply()) {
            length = totalSupply() - start;
        }
        tokens = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = _allTokens[start + i];
        }
    }

    /**
     * @notice Total amount of tokens available for sale.
     * @dev Does not include/count reserved tokens.
     * @return uint256 Returns the total number of available tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @notice Shows the interfaces the contracts support
     * @dev Must add new 4 byte interface Ids here to acknowledge support
     * @param interfaceId ERC165 style 4 byte interfaceId.
     * @return bool True if supported.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x150b7a02    // ERC721TokenReceiver
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Add a newly added token into managed list of tokens.
     * @param tokenId Id of token to add.
     */
    function _addTokenToEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Transfer all smart contract ETH to token contract's Identity contract.
     */
    function _moveEth() internal {
        uint256 amount = address(this).balance;
        payable(ISNUFFY500(_tokenContract).getIdentity()).transfer(amount);
    }

    /**
     * @dev Remove a token from managed list of tokens.
     * @param tokenId Id of token to remove.
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        delete _allTokensIndex[tokenId];
        delete _allTokens[lastTokenIndex];
        _allTokens.pop();
    }

    /**
     * @notice Checks if the token is in our possession.
     * @dev We check that returned value actually matches the tokenId, to avoid zero index issue.
     * @param tokenId The token in question.
     * @return bool Returns true if token exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _allTokens[_allTokensIndex[tokenId]] == tokenId;
    }

}


/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function isZero(address account) internal pure returns (bool) {
        return (account == address(0));
    }
}


/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Signature {
    function Derive(
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory encoded
    )
        internal
        pure
        returns (
            address derived1,
            address derived2,
            address derived3,
            address derived4
        )
    {
        bytes32 encoded32;
        assembly {
            encoded32 := mload(add(encoded, 32))
        }
        derived1 = ecrecover(encoded32, v, r, s);
        derived2 = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)), v, r, s);
        encoded32 = keccak256(encoded);
        derived3 = ecrecover(encoded32, v, r, s);
        encoded32 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32));
        derived4 = ecrecover(encoded32, v, r, s);
    }

    function PackMessage(bytes memory encoded, bool geth) internal pure returns (bytes32) {
        bytes32 hash = keccak256(encoded);
        if (geth) {
            hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        }
        return hash;
    }

    function Valid(
        address target,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory encoded
    ) internal pure returns (bool) {
        bytes32 encoded32;
        address derived;
        if (encoded.length == 32) {
            assembly {
                encoded32 := mload(add(encoded, 32))
            }
            derived = ecrecover(encoded32, v, r, s);
            if (target == derived) {
                return true;
            }
            derived = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)), v, r, s);
            if (target == derived) {
                return true;
            }
        }
        bytes32 hash = keccak256(encoded);
        derived = ecrecover(hash, v, r, s);
        if (target == derived) {
            return true;
        }
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        derived = ecrecover(hash, v, r, s);
        return target == derived;
    }
}


/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

struct Verification {
    bytes32 r;
    bytes32 s;
    uint8 v;
}


/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

struct TokenData {
    bytes32 payloadHash;
    Verification payloadSignature;
    address creator;
    bytes32 arweave;
    bytes11 arweave2;
    bytes32 ipfs;
    bytes14 ipfs2;
}


/*

            O
            _
     ---\ _|.|_ /---
      ---|  |  |---
         |_/ \_|
          |   |
          |   |
          |___|
           | |
           / \

       SNUFFY 500

*/

interface ISNUFFY500 {

    function mint(uint256 state, uint256 tokenId, TokenData[] memory tokenData, address signer, Verification memory verification, address recipient) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;

    function balanceOf(address wallet) external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function getIdentity() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

}