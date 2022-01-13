/// SPDX-License-Identifier: MIT
/// CryptoHero Contracts v1.0.0 (HeroCore.sol)

pragma solidity ^0.8.0;

import "./HeroMinting.sol";

contract HeroCore is HeroMinting {
    address public newContractAddress;

    /// @notice Creates the main cryptoHero smart contract instance.
    constructor() {
        // starts paused.
        pause();

        // start with the mythical hero 0 - so we don't have generation-0 parent issues
        _createHero(0, 0, 0, 0, 0, 0, address(this));
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyOwner whenPaused {
        newContractAddress = _v2Address;
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it's from one of the auction contracts.
    //  (Hopefully, we can prevent user accidents.)
    receive() external payable {
        require(msg.sender == address(breedingAuction), "Only breeding auction payable");
    }

    /// Pause crypto hero contract.
    function pause() public onlyOwner whenNotPaused {
        super._pause();
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause without using an expensive CALL.
    function unpause() public onlyOwner whenPaused {
        require(address(breedingAuction) != address(0), "Breeding auction is not ready.");
        require(address(geneScience) != address(0), "Gene science is not ready.");
        require(newContractAddress == address(0), "New contract was updated.");
        // Actually unpause the contract.
        super._unpause();
    }

    // @dev Allows the owner to capture the balance available to the contract.
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        address owner = super.owner();
        require(payable(owner).send(balance), "Failed to withdraw balance.");
    }
}

/// SPDX-License-Identifier: MIT
/// CryptoHero Contracts v1.0.0 (HeroMinting.sol)

pragma solidity ^0.8.0;

import "./HeroAuction.sol";

/// @title all functions related to creating heroes
contract HeroMinting is HeroAuction {
    // Limits the number of heroes the contract owner can ever create.
    uint256 internal constant GEN0_CREATION_LIMIT = 2100;

    // Counts the number of heroes the contract owner has created.
    uint256 public gen0CreatedCount;

    /// @dev we can create hero from cryptoSanguo, up to a limit. Only callable by contract owner.
    function createGen0Hero(
        uint8 _gender,
        uint256 _appearanceGenes,
        uint256 _attributeGenes,
        address _owner
    ) external onlyOwner {
        require(_owner != address(0), "Can't mint to the zero address.");
        require(gen0CreatedCount < GEN0_CREATION_LIMIT, "more than gen0 hero limit");

        gen0CreatedCount++;
        _createHero(_gender, 0, 0, 0, _appearanceGenes, _attributeGenes, _owner);
    }
}

/// SPDX-License-Identifier: MIT
/// CryptoHero Contracts v1.0.0 (HeroAuction.sol)

pragma solidity ^0.8.0;

import "./HeroBreeding.sol";
import "./Auction/BreedingAuction.sol";

/// @title Handles creating auctions for breeding of heroes.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract HeroAuction is HeroBreeding {
    // `breedingAuction` refers to the auction for breeding rights of heroes.
    BreedingAuction public breedingAuction;

    /// @dev Sets the reference to the breeding auction.
    /// @param _address - Address of breeding contract.
    function setBreedingAuctionAddress(address _address) external onlyOwner {
        BreedingAuction candidateContract = BreedingAuction(_address);
        require(candidateContract.isBreedingAuction(), "Candidate contract is illegal.");
        breedingAuction = candidateContract;
    }

    /// @dev Put a hero up for breeding auction.
    ///  Performs checks to ensure the hero can breeding, then delegates to reverse auction.
    function createBreedingAuction(uint256 _heroId, uint256 _price) external whenNotPaused {
        // Auction contract checks input sizes
        // If hero is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_heroId > 0, "The heroId is illegal.");

        require(msg.sender == ERC721.ownerOf(_heroId), "The msg.sender is not owner.");

        Hero memory hero = heroes[_heroId];
        require(_canBreed(hero), "Hero can't breed.");

        ERC721.approve(address(breedingAuction), _heroId);
        // breeding auction throws if inputs are invalid and clears
        // transfer and breed approval after escrowing the hero.
        breedingAuction.createAuction(_heroId, _price, msg.sender);
    }

    /// @dev Completes a breeding auction by bidding.
    function bidOnBreedingAuction(uint256 _breedingHeroId, uint256 _coupleHeroId) external payable whenNotPaused {
        require(_breedingHeroId > 0, "The heroId is illegal.");
        require(_coupleHeroId > 0, "The heroId is illegal.");

        require(msg.sender == ERC721.ownerOf(_breedingHeroId), "The msg.sender is not owner.");

        Hero memory hero = heroes[_breedingHeroId];
        require(_canBreed(hero), "Hero can't breed.");

        require(_canBreedWithViaAuction(_breedingHeroId, _coupleHeroId), "Can't breed together.");

        // Define the current price of the auction.
        uint256 price = breedingAuction.getPrice(_coupleHeroId);
        require(msg.value >= price + birthFee, "The msg.value is too low");

        // breeding auction will throw if the bid fails.
        breedingAuction.bid{value: msg.value - birthFee}(_coupleHeroId);
        _breedWith(_breedingHeroId, _coupleHeroId);
    }

    /// @dev Transfers the balance of the breeding auction contract
    /// to the heroCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyOwner {
        breedingAuction.withdrawBalance();
    }
}

/// SPDX-License-Identifier: MIT
/// CryptoHero Contracts v1.0.0 (HeroBreeding.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./HeroERC721.sol";
import "./IGeneScience.sol";

contract HeroBreeding is HeroERC721, Ownable, Pausable {
    /// @notice birth fee for the contract,contract owner can change it by call the method setAutoBirthFee()
    ///  0.002 ether
    uint256 public birthFee = 2 * 1e6 gwei;

    /// @dev male hero gender
    uint8 internal constant MALE = 1;

    /// @dev female hero gender
    uint8 internal constant FEMALE = 0;

    /// @dev The address of the GeneScience contract, genetic combination algorithm.
    IGeneScience public geneScience;

    /// @dev Update the address of the genetic contract, can only be called by the Owner.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setGeneScienceAddress(address _address) external onlyOwner {
        IGeneScience candidateContract = IGeneScience(_address);
        require(candidateContract.isGeneScience(), "Candidate contract is illegal.");
        geneScience = candidateContract;
    }

    /// @dev Updates the minimum payment required for the birth fee. Can only be called by the owner address.
    function setBirthFee(uint256 _fee) public onlyOwner {
        birthFee = _fee;
    }

    /// @notice Checks that a given hero can breed (i.e. check hero breeding index less than 10).
    function canBreed(uint256 _heroId) public view returns (bool) {
        require(_heroId > 0, "The heroId is illegal.");
        Hero memory hero = heroes[_heroId];
        return _canBreed(hero);
    }

    /// @dev Checks that a given hero is able to breed. Requires that the
    ///  check there is no pending pregnancy and current cooldown is finished.
    function _canBreed(Hero memory _hero) internal pure returns (bool) {
        return _hero.birthTime != 0 && _hero.breedingIndex < 10;
    }

    /// @notice Grants approval to another user to breeding with one of your heroes.
    /// @param _address The address that will be able to breeding with your hero.
    ///  Set to address(0) to clear all breeding approvals for this hero.
    /// @param _heroId A hero that you own that _address will be able to breeding with.
    function approveBreeding(address _address, uint256 _heroId) external whenNotPaused {
        require(msg.sender == ERC721.ownerOf(_heroId), "The msg.sender is not owner.");
        breedingAllowedToAddress[_heroId] = _address;
    }

    /// @dev Check if a breeding has authorized. True if both mother hero and father hero have the same owner,
    ///  or if the mother(father) hero has given breeding permission to the father(mother) hero's owner (via approveBreeding()).
    function _isBreedingPermitted(uint256 _breedingHeroId, uint256 _coupleHeroId) internal view returns (bool) {
        address breedingHeroOwner = ERC721.ownerOf(_breedingHeroId);
        address coupleHeroOwner = ERC721.ownerOf(_coupleHeroId);

        // breeding is okay if the two heroes have same owner, or if the breeding hero's owner was given permission to breeding with hero owner.
        return (breedingHeroOwner == coupleHeroOwner || breedingAllowedToAddress[_coupleHeroId] == breedingHeroOwner);
    }

    /// @dev Internal check to see if two hero are a valid breeding pair.
    /// DOES NOT check ownership permissions (that is up to the caller).
    function _isValidBreedingPair(
        Hero memory _breedingHero,
        uint256 _breedingHeroId,
        Hero memory _coupleHero,
        uint256 _coupleHeroId
    ) private view returns (bool) {
        // A Hero can't breed with itself!
        if (_breedingHeroId == _coupleHeroId) {
            return false;
        }

        if (_breedingHero.gender == _coupleHero.gender) {
            return false;
        }

        // TODO

        // Everything seems cool! Let's get DTF.
        return true;
    }

    /// @notice Checks to see if two heroes can breed together, including checks for ownership and breeding approvals.
    function canBreedWith(uint256 _breedingHeroId, uint256 _coupleHeroId) external view returns (bool) {
        require(_breedingHeroId > 0, "The heroId is illegal.");
        require(_coupleHeroId > 0, "The heroId is illegal.");
        return _canBreedWith(_breedingHeroId, _coupleHeroId);
    }

    function _canBreedWith(uint256 _breedingHeroId, uint256 _coupleHeroId) internal view returns (bool) {
        Hero memory breedingHero = heroes[_breedingHeroId];
        Hero memory coupleHero = heroes[_coupleHeroId];
        require(_canBreed(breedingHero), "Breeding hero can't breed.");
        require(_canBreed(coupleHero), "Couple hero is can't breed.");
        return
            _isBreedingPermitted(_breedingHeroId, _coupleHeroId) &&
            _isValidBreedingPair(breedingHero, _breedingHeroId, coupleHero, _coupleHeroId);
    }

    /// @dev Internal check to see if a given two heroes are a valid breeding pair for
    ///  breeding via auction (i.e. skips ownership and breeding approval checks).
    function _canBreedWithViaAuction(uint256 _breedingHeroId, uint256 _coupleHeroId) internal view returns (bool) {
        Hero memory breedingHero = heroes[_breedingHeroId];
        Hero memory coupleHero = heroes[_coupleHeroId];
        require(_canBreed(breedingHero), "Breeding hero can't breed.");
        require(_canBreed(coupleHero), "Couple hero is can't breed.");
        return _isValidBreedingPair(breedingHero, _breedingHeroId, coupleHero, _coupleHeroId);
    }

    /// @notice Breed a hero you own (as breedingHero) with a coupleHero that you own, or for which you
    ///  have previously been given Breeding approval. Will birth a new baby hero, or will fail entirely.
    function breedWith(uint256 _breedingHeroId, uint256 _coupleHeroId)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        // Checks for payment of birth fee.
        require(msg.value >= birthFee, "The msg.value is too low.");

        // Caller must own the breeding hero.
        require(msg.sender == ERC721.ownerOf(_breedingHeroId), "The msg.sender is not owner.");

        // Check two heroes can breed with each other.
        require(_canBreedWith(_breedingHeroId, _coupleHeroId), "Two heroes can't breed together");

        return _breedWith(_breedingHeroId, _coupleHeroId);
    }

    /// @notice Internal utility function to initiate breeding, assumes that all breeding requirements have been checked.
    function _breedWith(uint256 _breedingHeroId, uint256 _coupleHeroId) internal whenNotPaused returns (uint256) {
        // Grab a reference to the breeding hero.
        Hero storage breedingHero = heroes[_breedingHeroId];

        // Grab a reference to the couple hero.
        Hero storage coupleHero = heroes[_coupleHeroId];

        // Both parents breeding index increase.
        breedingHero.breedingIndex += 1;
        coupleHero.breedingIndex += 1;

        // Clear couple hero breeding permission.
        delete breedingAllowedToAddress[_coupleHeroId];

        return _birth(breedingHero, _breedingHeroId, coupleHero, _coupleHeroId);
    }

    /// @notice Have a baby hero birth!
    function _birth(
        Hero memory _breedingHero,
        uint256 _breedingHeroId,
        Hero memory _coupleHero,
        uint256 _coupleHeroId
    ) internal whenNotPaused returns (uint256) {
        // blockhash() return hash of 256 most recent blocks otherwise returns zero.
        uint256 targetBlock = uint256(block.number) - _rand(256);

        // Generate child hero gender.
        uint8 gender = geneScience.generateGender(targetBlock);

        // Set motherId and fatherId by breeding hero gender
        uint256 motherId = _breedingHeroId;
        uint256 fatherId = _coupleHeroId;
        if (_breedingHero.gender == MALE) {
            motherId = _coupleHeroId;
            fatherId = _breedingHeroId;
        }

        // Determine the higher generation number of the two parents
        uint16 parentGen = _breedingHero.generation;
        if (_coupleHero.generation > _breedingHero.generation) {
            parentGen = _coupleHero.generation;
        }

        Hero memory motherHero = _breedingHero;
        Hero memory fatherHero = _coupleHero;
        if (_breedingHero.gender == MALE) {
            motherHero = _coupleHero;
            fatherHero = _breedingHero;
        }

        uint256 childAppearanceGenes = geneScience.mixAppearanceGenes(
            gender,
            motherHero.appearanceGenes,
            fatherHero.appearanceGenes,
            targetBlock
        );

        uint256 childAttributeGenes = geneScience.mixAttributeGenes(
            motherHero.attributeGenes,
            fatherHero.attributeGenes,
            targetBlock
        );

        // Make the new hero!
        address owner = ERC721.ownerOf(_breedingHeroId);

        // Create new baby hero, emit birth event.
        uint256 heroId = _createHero(
            gender,
            motherId,
            fatherId,
            parentGen + 1,
            childAppearanceGenes,
            childAttributeGenes,
            owner
        );

        // Return the new baby hero's ID
        return heroId;
    }

    /// @param _range is random max value. 1 ~ range
    function _rand(uint256 _range) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return (random % _range) + 1;
    }
}

// SPDX-License-Identifier: MIT
// CryptoHero Contracts v1.0.0 (BreedingAuction.sol)

pragma solidity ^0.8.0;

import "./AuctionCore.sol";

/// @title Reverse auction modified for breeding
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract BreedingAuction is AuctionCore {
    // Delegate constructor
    constructor(address _nftAddr) AuctionCore(_nftAddr) {}

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setBreedingAuctionAddress() call.
    function isBreedingAuction() external pure returns (bool) {
        return true;
    }

    /// @dev Creates and begins a new auction. Since this function is wrapped,require sender to be cryptoHero contract.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _price - Price (in wei) of item auction.
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    ) external override {
        // Sanity check that no inputs overflow how many bits we've allocated to store them in the auction struct.
        require(_price == uint256(uint128(_price)), "Price is invalid.");

        require(msg.sender == address(nonFungibleContract), "The msg.sender isn't contract");
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(_seller, uint128(_price), uint64(block.timestamp));
        _addAuction(_tokenId, auction);
    }

    /// @dev Places a bid for breeding. Requires the sender
    /// is the cryptoHero contract because all bid methods
    /// should be wrapped. Also returns the hero to the
    /// seller rather than the winner.
    function bid(uint256 _tokenId) external payable override {
        require(msg.sender == address(nonFungibleContract), "The msg.sender isn't contract");
        address seller = tokenIdToAuction[_tokenId].seller;
        // _bid checks that token ID is valid and will throw if bid fails
        _bid(_tokenId, msg.value);
        // We transfer the hero back to the seller, the winner will get the breeding right
        _transfer(seller, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

/// SPDX-License-Identifier: MIT
/// CryptoHero Contracts v1.0.0 (HeroERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract HeroERC721 is ERC721 {
    /// @dev The Birth event is fired whenever a new hero comes into existence. This obviously
    ///  includes any time a hero is created through the giveBirth method, but it is also called
    ///  when a new gen0 hero is created.
    event Birth(
        address owner,
        uint256 heroId,
        uint256 motherId,
        uint256 fatherId,
        uint256 appearanceGenes,
        uint256 attributeGenes
    );

    /// @dev The main hero struct.
    struct Hero {
        // male is 1 and female is 0
        uint8 gender;
        uint64 birthTime;
        uint32 motherId;
        uint32 fatherId;
        uint16 breedingIndex;
        uint16 generation;
        // the hero's appearance genetic code is packed into these 256-bits. Never change
        uint256 appearanceGenes;
        // the hero's attribute genetic code is packed into these 256-bits. Never change
        uint256 attributeGenes;
    }

    /// @dev An array containing the Hero struct for all heroes in existence.
    Hero[] internal heroes;

    /// @dev A mapping from heroIDs to an address that has been approved to use
    /// this hero for breeding via breedWith(). Each hero can only have one approved
    /// address for breeding at any time. A zero value means no approval is outstanding.
    mapping(uint256 => address) public breedingAllowedToAddress;

    constructor() ERC721("CryptoHero", "CH") {}

    /// @notice Returns the total number of crypto hero currently in existence.
    /// @dev Required for etherscan.
    function totalSupply() public view returns (uint256) {
        return heroes.length - 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // once the hero is transferred also clear breed allowances
        delete breedingAllowedToAddress[tokenId];
    }

    /// @dev An internal method that creates a new hero and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event and a Transfer event.
    /// @param _gender The hero's gender
    /// @param _motherId The hero ID of the mother of this hero (zero for gen0)
    /// @param _fatherId The hero ID of the father of this hero (zero for gen0)
    /// @param _generation The generation number of this hero, must be computed by caller.
    /// @param _appearanceGenes The hero's appearance genetic code.
    /// @param _attributeGenes The hero's attribute genetic code.
    /// @param _owner The initial owner of this hero, must be non-zero
    function _createHero(
        uint8 _gender,
        uint256 _motherId,
        uint256 _fatherId,
        uint256 _generation,
        uint256 _appearanceGenes,
        uint256 _attributeGenes,
        address _owner
    ) internal returns (uint256) {
        // These requires are not strictly necessary, our calling code should make
        // sure that these conditions are never broken. However! _createHero() is already
        // an expensive call (for storage), and it doesn't hurt to be especially careful
        // to ensure our data structures are always valid.
        require(_motherId == uint256(uint32(_motherId)), "The motherId is illegal.");
        require(_fatherId == uint256(uint32(_fatherId)), "The fatherId is illegal.");
        require(_generation == uint256(uint16(_generation)), "The generation is illegal.");

        Hero memory _hero = Hero({
            gender: _gender,
            birthTime: uint64(block.timestamp),
            motherId: uint32(_motherId),
            fatherId: uint32(_fatherId),
            breedingIndex: 0,
            generation: uint16(_generation),
            appearanceGenes: _appearanceGenes,
            attributeGenes: _attributeGenes
        });

        heroes.push(_hero);
        uint256 newHeroId = heroes.length - 1;

        // It's probably never going to happen, 4 billion heroes is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newHeroId == uint256(uint32(newHeroId)), "The heroId is illegal.");

        // emit the birth event
        emit Birth(
            _owner,
            newHeroId,
            uint256(_hero.motherId),
            uint256(_hero.fatherId),
            _hero.appearanceGenes,
            _hero.attributeGenes
        );

        // This will mint hero token, and also emit the Transfer event
        ERC721._safeMint(_owner, newHeroId);

        return newHeroId;
    }

    /// @notice Returns a list of all hero IDs assigned to an address.
    /// @param _owner The owner whose heroes we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code.
    function heroesOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory ownerHeroes = new uint256[](tokenCount);
            uint256 ownerHeroesIndex = 0;
            for (uint256 heroId = 1; heroId < heroes.length; heroId++) {
                if (ownerOf(heroId) == _owner) {
                    ownerHeroes[ownerHeroesIndex] = heroId;
                    ownerHeroesIndex++;
                }
            }
            return ownerHeroes;
        }
    }

    /// @notice Returns all the relevant information about a specific hero.
    /// @param _id The ID of the hero of interest.
    function getHero(uint256 _id)
        external
        view
        returns (
            uint8 gender,
            uint64 birthTime,
            uint32 motherId,
            uint32 fatherId,
            uint16 breedingIndex,
            uint16 generation,
            uint256 appearanceGenes,
            uint256 attributeGenes
        )
    {
        Hero storage hero = heroes[_id];
        gender = hero.gender;
        birthTime = hero.birthTime;
        motherId = hero.motherId;
        fatherId = hero.fatherId;
        breedingIndex = hero.breedingIndex;
        generation = hero.generation;
        appearanceGenes = hero.appearanceGenes;
        attributeGenes = hero.attributeGenes;
    }
}

/// SPDX-License-Identifier: MIT
/// CryptoHero Contracts v1.0.0 (IGeneScience.sol)

pragma solidity ^0.8.0;

interface IGeneScience {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneScience() external pure returns (bool);

    /// @dev random generate hero gender
    function generateGender(uint256 targetBlock) external view returns (uint8);

    /// @dev given appearance genes of hero mother & hero father, return a genetic combination
    /// @return the genes that are supposed to be passed down the baby hero
    function mixAppearanceGenes(
        uint8 gender,
        uint256 motherGenes,
        uint256 fatherGenes,
        uint256 targetBlock
    ) external view returns (uint256);

    /// @dev given attribute genes of hero mother & hero father, return a genetic combination
    /// @return the genes that are supposed to be passed down the baby hero
    function mixAttributeGenes(
        uint256 motherGenes,
        uint256 fatherGenes,
        uint256 targetBlock
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// CryptoHero Contracts v1.0.0 (AuctionCore.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./AuctionBase.sol";

/// @title auction for non-fungible tokens.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract AuctionCore is AuctionBase, Ownable, Pausable {
    /// @dev The ERC-165 interface signature for ERC-721.
    //  Ref: https://eips.ethereum.org/EIPS/eip-721
    //  type(IERC721).interfaceId == 0x80ac58cd
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = bytes4(0x80ac58cd);

    /// @dev Constructor creates a reference to the NFT ownership contract
    /// @param _nftAddress - address of a deployed contract implementing the NonFungible Interface.
    constructor(address _nftAddress) {
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(INTERFACE_SIGNATURE_ERC721), "Not support contract interface.");
        nonFungibleContract = candidateContract;
    }

    /// @dev Remove all Ether from the contract, which is the owner's cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(msg.sender == Ownable.owner() || msg.sender == nftAddress, "No authorization.");
        // We are using this boolean method to make sure that even if one fails it will still work
        require(payable(nftAddress).send(address(this).balance), "Failed to withdraw balance.");
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _price - Price (in wei) of item auction.
    /// @param _seller - Seller, if not the message sender.
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    ) external virtual whenNotPaused {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_price == uint256(uint128(_price)), "Price is invalid.");

        require(_owns(msg.sender, _tokenId), "Not owner.");
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(_seller, uint128(_price), uint64(block.timestamp));
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId) external payable virtual whenNotPaused {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "Token isn't on auction.");
        address seller = auction.seller;
        require(msg.sender == seller, "The msg.sender is not seller");
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId) external whenPaused onlyOwner {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "Token isn't on auction.");
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint256 price,
            uint256 startedAt
        )
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "Token isn't on auction.");
        return (auction.seller, auction.price, auction.startedAt);
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "Token isn't on auction.");
        return uint256(auction.price);
    }
}

// SPDX-License-Identifier: MIT
// CryptoHero Contracts v1.0.0 (AuctionBase.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract AuctionBase {
    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) of auction
        uint128 price;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    // Map from token ID to their corresponding auction.
    mapping(uint256 => Auction) public tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 price);
    event AuctionSuccessful(uint256 tokenId, uint256 price, address winner);
    event AuctionCancelled(uint256 tokenId);

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.safeTransferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;
        emit AuctionCreated(uint256(_tokenId), uint256(_auction.price));
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount) internal returns (uint256) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction), "Token isn't on auction.");

        // Check that the bid is greater than or equal to the current price
        uint256 price = auction.price;
        require(_bidAmount >= price, "Bid amount is less than price.");

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            payable(seller).transfer(price);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        payable(msg.sender).transfer(bidExcess);

        // Tell the world!
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }
}