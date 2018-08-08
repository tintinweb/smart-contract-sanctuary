pragma solidity ^ 0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // Required methods for ERC-721 Compatibility.
    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function ownerOf(uint256 _tokenId) external view returns(address _owner);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns(bool);

    function totalSupply() public view returns(uint256 total);

    function balanceOf(address _owner) public view returns(uint256 _balance);
}

contract AnimecardAccessControl {
    /// @dev Event is fired when contract is forked.
    event ContractFork(address newContract);

    /// - CEO: The CEO can reassign other roles, change the addresses of dependent smart contracts,
    /// and pause/unpause the AnimecardCore contract.
    /// - CFO: The CFO can withdraw funds from its auction and sale contracts.
    /// - Manager: The Animator can create regular and promo AnimeCards.
    address public ceoAddress;
    address public cfoAddress;
    address public animatorAddress;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked.
    bool public paused = false;

    /// @dev Access-modifier for CEO-only functionality.
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access-modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access-modifier for Animator-only functionality.
    modifier onlyAnimator() {
        require(msg.sender == animatorAddress);
        _;
    }

    /// @dev Access-modifier for C-level-only functionality.
    modifier onlyCLevel() {
        require(
            msg.sender == animatorAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// Assigns a new address to the CEO role. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// Assigns a new address to the Animator role. Only available to the current CEO.
    /// @param _newAnimator The address of the new Animator
    function setAnimator(address _newAnimator) external onlyCEO {
        require(_newAnimator != address(0));

        animatorAddress = _newAnimator;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /*** Destructible functionality adapted from OpenZeppelin ***/
    /**
     * @dev Transfers the current balance to the owner and terminates the contract.
     */
    function destroy() onlyCEO public {
        selfdestruct(ceoAddress);
    }

    function destroyAndSend(address _recipient) onlyCEO public {
        selfdestruct(_recipient);
    }
}

contract AnimecardBase is AnimecardAccessControl {
    using SafeMath
    for uint256;

    /*** DATA TYPES ***/

    /// The main anime card struct
    struct Animecard {
        /// Name of the character
        string characterName;
        /// Name of designer & studio that created the character
        string studioName;

        /// AWS S3-CDN URL for character image
        string characterImageUrl;
        /// IPFS hash of character details
        string characterImageHash;
        /// The timestamp from the block when this anime card was created
        uint64 creationTime;
    }


    /*** EVENTS ***/
    /// The Birth event is fired whenever a new anime card comes into existence.
    event Birth(address owner, uint256 tokenId, string cardName, string studio);
    /// Transfer event as defined in current draft of ERC721. Fired every time animecard
    /// ownership is assigned, including births.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    /// The TokenSold event is fired whenever a token is sold.
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 price, address prevOwner, address owner, string cardName);

    /*** STORAGE ***/
    /// An array containing all AnimeCards in existence. The id of each animecard
    /// is an index in this array.
    Animecard[] animecards;

    /// @dev A mapping from anime card ids to the address that owns them.
    mapping(uint256 => address) public animecardToOwner;

    /// @dev A mapping from owner address to count of anime cards that address owns.
    /// Used internally inside balanceOf() to resolve ownership count.
    mapping(address => uint256) public ownerAnimecardCount;

    /// @dev A mapping from anime card ids to an address that has been approved to call
    ///  transferFrom(). Each anime card can only have 1 approved address for transfer
    ///  at any time. A 0 value means no approval is outstanding.
    mapping(uint256 => address) public animecardToApproved;

    // @dev A mapping from anime card ids to their price.
    mapping(uint256 => uint256) public animecardToPrice;

    // @dev Previous sale price of anime card
    mapping(uint256 => uint256) public animecardPrevPrice;

    /// @dev Assigns ownership of a specific anime card to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Transfer ownership and update owner anime card counts.
        // ownerAnimecardCount[_to] = ownerAnimecardCount[_to].add(1);
        ownerAnimecardCount[_to]++;
        animecardToOwner[_tokenId] = _to;
        // When creating new tokens _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            // ownerAnimecardCount[_from] = ownerAnimecardCount[_from].sub(1);
            ownerAnimecardCount[_from]--;
            // clear any previously approved ownership exchange
            delete animecardToApproved[_tokenId];
        }
        // Fire the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new anime card and stores it.
    /// @param _characterName The name of the character
    /// @param _studioName The studio that created this character
    /// @param _characterImageUrl AWS S3-CDN URL for character image
    /// @param _characterImageHash IPFS hash for character image
    /// @param _price of animecard character
    /// @param _owner The initial owner of this anime card
    function _createAnimecard(
        string _characterName,
        string _studioName,
        string _characterImageUrl,
        string _characterImageHash,
        uint256 _price,
        address _owner
    )
    internal
    returns(uint) {

        Animecard memory _animecard = Animecard({
            characterName: _characterName,
            studioName: _studioName,
            characterImageUrl: _characterImageUrl,
            characterImageHash: _characterImageHash,
            creationTime: uint64(now)
        });
        uint256 newAnimecardId = animecards.push(_animecard);
        newAnimecardId = newAnimecardId.sub(1);

        // Fire the birth event.
        Birth(
            _owner,
            newAnimecardId,
            _animecard.characterName,
            _animecard.studioName
        );

        // Set the price for the animecard.
        animecardToPrice[newAnimecardId] = _price;

        // This will assign ownership, and also fire the Transfer event as per ERC-721 draft.
        _transfer(0, _owner, newAnimecardId);

        return newAnimecardId;

    }
}

contract AnimecardPricing is AnimecardBase {

    /*** CONSTANTS ***/
    // Pricing steps.
    uint256 private constant first_step_limit = 0.05 ether;
    uint256 private constant second_step_limit = 0.5 ether;
    uint256 private constant third_step_limit = 2.0 ether;
    uint256 private constant fourth_step_limit = 5.0 ether;


    // Cut for studio & platform for each sale transaction
    uint256 public platformFee = 50; // 50%

    /// @dev Set Studio Fee. Can only be called by the Animator address. 
    function setPlatformFee(uint256 _val) external onlyAnimator {
        platformFee = _val;
    }

    /// @dev Computes next price of token given the current sale price.
    function computeNextPrice(uint256 _salePrice)
    internal
    pure
    returns(uint256) {
        if (_salePrice < first_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 200), 100);
        } else if (_salePrice < second_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 135), 100);
        } else if (_salePrice < third_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 125), 100);
        } else if (_salePrice < fourth_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 120), 100);
        } else {
            return SafeMath.div(SafeMath.mul(_salePrice, 115), 100);
        }
    }

    /// @dev Computes the payment for the token, which is the sale price of the token
    /// minus the house&#39;s cut.
    function computePayment(
        uint256 _tokenId,
        uint256 _salePrice)
    internal
    view
    returns(uint256) {
        uint256 prevSalePrice = animecardPrevPrice[_tokenId];

        uint256 profit = _salePrice - prevSalePrice;

        uint256 ownerCut = SafeMath.sub(100, platformFee);
        uint256 ownerProfitShare = SafeMath.div(SafeMath.mul(profit, ownerCut), 100);

        return prevSalePrice + ownerProfitShare;
    }
}

contract AnimecardOwnership is AnimecardPricing, ERC721 {
    /// Name of the collection of NFTs managed by this contract, as defined in ERC721.
    string public constant NAME = "CryptoAnime";
    /// Symbol referencing the entire collection of NFTs managed in this contract, as
    /// defined in ERC721.
    string public constant SYMBOL = "ANM";

    bytes4 public constant INTERFACE_SIGNATURE_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 public constant INTERFACE_SIGNATURE_ERC721 =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)")) ^
        bytes4(keccak256("transferFrom(address,address,uint256)")) ^
        bytes4(keccak256("tokensOfOwner(address)")) ^
        bytes4(keccak256("tokenMetadata(uint256,string)"));

    /*** EVENTS ***/
    /// Approval event as defined in the current draft of ERC721. Fired every time
    /// animecard approved owners is updated. When Transfer event is emitted, this 
    /// also indicates that approved address is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID)
    external
    view
    returns(bool) {
        return ((_interfaceID == INTERFACE_SIGNATURE_ERC165) || (_interfaceID == INTERFACE_SIGNATURE_ERC721));
    }

    // @notice Optional for ERC-20 compliance.
    function name() external pure returns(string) {
        return NAME;
    }

    // @notice Optional for ERC-20 compliance.
    function symbol() external pure returns(string) {
        return SYMBOL;
    }

    /// @dev Returns the total number of Animecards currently in existence.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function totalSupply() public view returns(uint) {
        return animecards.length;
    }

    /// @dev Returns the number of Animecards owned by a specific address.
    /// @param _owner The owner address to check.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function balanceOf(address _owner)
    public
    view
    returns(uint256 count) {
        return ownerAnimecardCount[_owner];
    }

    /// @dev Returns the address currently assigned ownership of a given Animecard.
    /// @notice Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
    external
    view
    returns(address _owner) {
        _owner = animecardToOwner[_tokenId];
        require(_owner != address(0));
    }

    /// @dev Grant another address the right to transfer a specific Anime card via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Animecard that can be transferred if this call succeeds.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function approve(address _to, uint256 _tokenId)
    external
    whenNotPaused {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Fire approval event upon successful approval.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @dev Transfers a Animecard to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 or else your
    /// Animecard may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Animecard to transfer.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId)
    external
    whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any animecard (except very briefly
        // after a Anime card is created).
        require(_to != address(this));

        // You can only transfer your own Animecard.
        require(_owns(msg.sender, _tokenId));
        // TODO - Disallow transfer to self

        // Reassign ownership, clear pending approvals, fire Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Transfer a Animecard owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Animecard to be transfered.
    /// @param _to The address that should take ownership of the Animecard. Can be any
    /// address, including the caller.
    /// @param _tokenId The ID of the Animecard to be transferred.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId)
    external
    whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any animecard (except very briefly
        // after an animecard is created).
        require(_to != address(this));

        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and fires Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @dev Returns a list of all Animecard IDs assigned to an address.
    /// @param _owner The owner whose Animecards we are interested in.
    ///  This method MUST NEVER be called by smart contract code. First, it is fairly
    ///  expensive (it walks the entire Animecard array looking for Animecard belonging
    /// to owner), but it also returns a dynamic array, which is only supported for web3
    /// calls, and not contract-to-contract calls. Thus, this method is external rather
    /// than public.
    function tokensOfOwner(address _owner)
    external
    view
    returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Returns an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalAnimecards = totalSupply();
            uint256 resultIndex = 0;

            uint256 animecardId;
            for (animecardId = 0; animecardId <= totalAnimecards; animecardId++) {
                if (animecardToOwner[animecardId] == _owner) {
                    result[resultIndex] = animecardId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @dev Checks if a given address is the current owner of a particular Animecard.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId Animecard id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId)
    internal
    view
    returns(bool) {
        return animecardToOwner[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    /// approval. Setting _approved to address(0) clears all transfer approval.
    /// NOTE: _approve() does NOT send the Approval event. This is intentional because
    /// _approve() and transferFrom() are used together for putting Animecards on sale and,
    /// there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        animecardToApproved[_tokenId] = _approved;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular 
    /// Animecard.
    /// @param _claimant the address we are confirming Animecard is approved for.
    /// @param _tokenId Animecard id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId)
    internal
    view
    returns(bool) {
        return animecardToApproved[_tokenId] == _claimant;
    }

    /// Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) internal pure returns(bool) {
        return _to != address(0);
    }

}

contract AnimecardSale is AnimecardOwnership {

    // Allows someone to send ether and obtain the token
    function purchase(uint256 _tokenId)
    public
    payable
    whenNotPaused {
        address newOwner = msg.sender;
        address oldOwner = animecardToOwner[_tokenId];
        uint256 salePrice = animecardToPrice[_tokenId];

        // Require that the owner of the token is not sending to self.
        require(oldOwner != newOwner);

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Check that sent amount is greater than or equal to the sale price
        require(msg.value >= salePrice);

        uint256 payment = uint256(computePayment(_tokenId, salePrice));
        uint256 purchaseExcess = SafeMath.sub(msg.value, salePrice);

        // Set next listing price.
        animecardPrevPrice[_tokenId] = animecardToPrice[_tokenId];
        animecardToPrice[_tokenId] = computeNextPrice(salePrice);

        // Transfer the Animecard to the buyer.
        _transfer(oldOwner, newOwner, _tokenId);

        // Pay seller of the Animecard if they are not this contract.
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        TokenSold(_tokenId, salePrice, animecardToPrice[_tokenId], oldOwner, newOwner, animecards[_tokenId].characterName);

        // Reimburse the buyer of any excess paid.
        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId)
    public
    view
    returns(uint256 price) {
        return animecardToPrice[_tokenId];
    }


}

contract AnimecardMinting is AnimecardSale {
    /*** CONSTANTS ***/
    /// @dev Starting price of a regular Animecard.
    // uint128 private constant STARTING_PRICE = 0.01 ether;

    /// @dev Creates a new Animecard
    function createAnimecard(
        string _characterName,
        string _studioName,
        string _characterImageUrl,
        string _characterImageHash,
        uint256 _price
    )
    public
    onlyAnimator
    returns(uint) {
        uint256 animecardId = _createAnimecard(
            _characterName, _studioName,
            _characterImageUrl, _characterImageHash,
            _price, address(this)
        );

        return animecardId;
    }
}

// Cryptoanime: Anime collectibles on blockchain
contract AnimecardCore is AnimecardMinting {
    // contract AnimecardCore is AnimecardMinting {
    // Set in case the core contract is broken and a fork is required
    address public newContractAddress;

    function AnimecardCore() public {
        // Starts paused.
        paused = true;

        // The creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // The creator of the contract is also the initial Animator
        animatorAddress = msg.sender;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address)
    external
    onlyCEO
    whenPaused {
        newContractAddress = _v2Address;
        ContractFork(_v2Address);
    }

    /// @dev Withdraw all Ether from the contract. This includes both the studio fee
    /// and blockpunk fee on every animecard sold and any Ether sent directly to
    /// contract address.
    /// Only the CFO can withdraw the balance or specify the address to send
    /// the balance to.
    function withdrawBalance(address _to) external onlyCFO {
        // We are using this boolean method to make sure that even if one fails it will still work
        if (_to == address(0)) {
            cfoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

    /// @notice Returns all the relevant information about a specific animecard.
    /// @param _tokenId The tokenId of the animecard of interest.
    function getAnimecard(uint256 _tokenId)
    external
    view
    returns(
        string characterName,
        string studioName,
        string characterImageUrl,
        string characterImageHash,
        uint256 sellingPrice,
        address owner) {
        Animecard storage animecard = animecards[_tokenId];
        characterName = animecard.characterName;
        studioName = animecard.studioName;
        characterImageUrl = animecard.characterImageUrl;
        characterImageHash = animecard.characterImageHash;
        sellingPrice = animecardToPrice[_tokenId];
        owner = animecardToOwner[_tokenId];
    }


    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive call.
    function unpause()
    public
    onlyCEO
    whenPaused {
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    /// @notice Direct donations
    function () external payable {}
}