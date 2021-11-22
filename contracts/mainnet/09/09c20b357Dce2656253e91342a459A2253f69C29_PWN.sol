// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

import "./PWNVault.sol";
import "./PWNDeed.sol";
import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PWN is Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    PWNDeed public deed;
    PWNVault public vault;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    // No events nor error defined

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * Constructor
     * @dev establishes a connection with other pre-deployed components
     * @dev for the set up to work both PWNDeed & PWNVault contracts have to called via `.setPWN(PWN.address)`
     * @param _PWND Address of the PWNDeed contract - defines Deed tokens
     * @param _PWNV Address of the PWNVault contract - holds assets
     */
    constructor(
        address _PWND,
        address _PWNV
    ) Ownable() {
        deed = PWNDeed(_PWND);
        vault = PWNVault(_PWNV);
    }

    /**
     * createDeed - sets & locks collateral
     * @dev for UI integrations is this the function enabling creation of a new Deed token
     * @param _assetAddress Address of the asset contract
     * @param _assetCategory Category of the asset - see { MultiToken.sol }
     * @param _duration Loan duration in seconds
     * @param _assetId ID of an ERC721 or ERC1155 token || 0 in case the token doesn't have IDs
     * @param _assetAmount Amount of an ERC20 or ERC1155 token || 0 in case of NFTs
     * @return a Deed ID of the newly created Deed
     */
    function createDeed(
        address _assetAddress,
        MultiToken.Category _assetCategory,
        uint32 _duration,
        uint256 _assetId,
        uint256 _assetAmount
    ) external returns (uint256) {
        uint256 did = deed.create(_assetAddress, _assetCategory, _duration, _assetId, _assetAmount, msg.sender);
        vault.push(deed.getDeedCollateral(did), msg.sender);

        return did;
    }

    /**
     * revokeDeed
     * @dev through this function the borrower can delete the Deed token given no offer was accepted
     * @param _did Deed ID specifying the concrete Deed
     */
    function revokeDeed(uint256 _did) external {
        deed.revoke(_did, msg.sender);
        vault.pull(deed.getDeedCollateral(_did), msg.sender);

        deed.burn(_did, msg.sender);
    }

    /**
     * makeOffer
     * @dev this is the function used by lenders to cast their offers
     * @dev this function doesn't assume the asset is approved yet for PWNVault
     * @dev this function requires lender to have a sufficient balance
     * @param _assetAddress Address of the asset contract
     * @param _assetAmount Amount of an ERC20 token to be offered as loan
     * @param _did ID of the Deed the offer should be bound to
     * @param _toBePaid Amount to be paid back by the borrower
     * @return a hash of the newly created offer
     */
    function makeOffer(
        address _assetAddress,
        uint256 _assetAmount,
        uint256 _did,
        uint256 _toBePaid
    ) external returns (bytes32) {
        return deed.makeOffer(_assetAddress, _assetAmount, msg.sender, _did, _toBePaid);
    }

    /**
     * revokeOffer
     * @dev this is the function lenders can use to remove their offers on Deeds they are in the stage of getting offers
     * @param _offer Identifier of the offer to be revoked
     */
    function revokeOffer(bytes32 _offer) external {
        deed.revokeOffer(_offer, msg.sender);
    }

    /**
     * acceptOffer
     * @dev through this function a borrower can accept an existing offer
     * @dev a UI should do an off-chain balance check on the lender side to make sure the call won't throw
     * @param _offer Identifier of the offer to be accepted
     * @return true if successful
     */
    function acceptOffer(bytes32 _offer) external returns (bool) {
        uint256 did = deed.getDeedID(_offer);
        deed.acceptOffer(did, _offer, msg.sender);

        address lender = deed.getLender(_offer);
        vault.pullProxy(deed.getOfferLoan(_offer), lender, msg.sender);

        MultiToken.Asset memory collateral;
        collateral.category = MultiToken.Category.ERC1155;
        collateral.id = did;
        collateral.assetAddress = address(deed);
        vault.pullProxy(collateral, msg.sender, lender);

        return true;
    }

    /**
     * repayLoan
     * @dev the borrower can pay back the funds through this function
     * @dev the function assumes the asset (and amount to be paid back) to be returned is approved for PWNVault
     * @dev the function assumes the borrower has the full amount to be paid back in their account
     * @param _did Deed ID of the deed being paid back
     * @return true if successful
     */
    function repayLoan(uint256 _did) external returns (bool) {
        deed.repayLoan(_did);

        bytes32 offer = deed.getAcceptedOffer(_did);
        MultiToken.Asset memory loan = deed.getOfferLoan(offer);
        loan.amount = deed.toBePaid(offer);  //override the num of loan given

        vault.pull(deed.getDeedCollateral(_did), deed.getBorrower(_did));
        vault.push(loan, msg.sender);

        return true;
    }

    /**
     * claim Deed
     * @dev The current Deed owner can call this function if the Deed is expired or payed back
     * @param _did Deed ID of the deed to be claimed
     * @return true if successful
     */
    function claimDeed(uint256 _did) external returns (bool) {
        uint8 status = deed.getDeedStatus(_did);

        deed.claim(_did, msg.sender);

        if (status == 3) {
            bytes32 offer = deed.getAcceptedOffer(_did);
            MultiToken.Asset memory loan = deed.getOfferLoan(offer);
            loan.amount = deed.toBePaid(offer);

            vault.pull(loan, msg.sender);

        } else if (status == 4) {
            vault.pull(deed.getDeedCollateral(_did), msg.sender);
        }

        deed.burn(_did, msg.sender);

        return true;
    }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

// @dev importing contract interfaces - for supported contracts; nothing more than the interface is needed!
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library MultiToken {

    /**
     * @title Category
     * @dev enum represention Asset category
     */
    enum Category {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
     * @title Asset
     * @param assetAddress Address of the token contract defining the asset
     * @param category Corresponding asset category
     * @param amount Amount of fungible tokens or 0 -> 1
     * @param id TokenID of an NFT or 0
     */
    struct Asset {
        address assetAddress;
        Category category;
        uint256 amount;
        uint256 id;
    }

    /**
     * transferAsset
     * @dev wrapping function for transfer calls on various token interfaces
     * @param _asset Struck defining all necessary context of a token
     * @param _dest Destination address
     */
    function transferAsset(Asset memory _asset, address _dest) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.transfer(_dest, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.transferFrom(address(this), _dest, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            if (_asset.amount == 0) {
                _asset.amount = 1;
            }
            token.safeTransferFrom(address(this), _dest, _asset.id, _asset.amount, "");
        }
    }

    /**
     * transferAssetFrom
     * @dev wrapping function for transfer From calls on various token interfaces
     * @param _asset Struck defining all necessary context of a token
     * @param _source Account/address that provided the allowance
     * @param _dest Destination address
     */
    function transferAssetFrom(Asset memory _asset, address _source, address _dest) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.transferFrom(_source, _dest, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.transferFrom(_source, _dest, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            if (_asset.amount == 0) {
                _asset.amount = 1;
            }
            token.safeTransferFrom(_source, _dest, _asset.id, _asset.amount, "");
        }
    }

    /**
     * balanceOf
     * @dev wrapping function for checking balances on various token interfaces
     * @param _asset Struck defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function balanceOf(Asset memory _asset, address _target) internal view returns (uint256) {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            return token.balanceOf(_target);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            if (token.ownerOf(_asset.id) == _target) {
                return 1;
            } else {
                return 0;
            }

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            return token.balanceOf(_target, _asset.id);
        }
    }

    /**
     * approveAsset
     * @dev wrapping function for approve calls on various token interfaces
     * @param _asset Struck defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function approveAsset(Asset memory _asset, address _target) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.approve(_target, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.approve(_target, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            token.setApprovalForAll(_target, true);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract PWNDeed is ERC1155, Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    address public PWN;                 // necessary msg.sender for all Deed related manipulations
    uint256 public id;                  // simple DeedID counter
    uint256 private nonce;              // server for offer hash generation

    /**
     * Construct defining a Deed
     * @param status 0 == none/dead || 1 == new/open || 2 == running/accepted offer || 3 == paid back || 4 == expired
     * @param borrower Address of the issuer / borrower - stays the same for entire lifespan of the token
     * @param duration Loan duration in seconds
     * @param expiration Unix timestamp (in seconds) setting up the default deadline
     * @param collateral Consisting of another an `Asset` struct defined in the MultiToken library
     * @param acceptedOffer Hash of the offer which will be bound to the deed
     * @param pendingOffers List of offers made to the Deed
     */
    struct Deed {
        uint8 status;
        address borrower;
        uint32 duration;
        uint40 expiration;
        MultiToken.Asset collateral;
        bytes32 acceptedOffer;
        bytes32[] pendingOffers;
    }

    /**
     * Construct defining an offer
     * @param did Deed ID the offer is bound to
     * @param toBePaid Nn amount to be paid back (borrowed + interest)
     * @param lender Address of the lender to be the loan withdrawn from
     * @param loan Consisting of another an `Asset` struct defined in the MultiToken library
     */
    struct Offer {
        uint256 did;
        uint256 toBePaid;
        address lender;
        MultiToken.Asset loan;
    }

    mapping (uint256 => Deed) public deeds;             // mapping of all Deed data
    mapping (bytes32 => Offer) public offers;           // mapping of all Offer data

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    event DeedCreated(address indexed assetAddress, MultiToken.Category category, uint256 id, uint256 amount, uint32 duration, uint256 indexed did);
    event OfferMade(address assetAddress, uint256 amount, address indexed lender, uint256 toBePaid, uint256 indexed did, bytes32 offer);
    event DeedRevoked(uint256 did);
    event OfferRevoked(bytes32 offer);
    event OfferAccepted(uint256 did, bytes32 offer);
    event PaidBack(uint256 did, bytes32 offer);
    event DeedClaimed(uint256 did);

    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyPWN() {
        require(msg.sender == PWN, "Caller is not the PWN");
        _;
    }

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /*
     *  PWN Deed constructor
     *  @dev Creates the PWN Deed token contract - ERC1155 with extra use case specific features
     *  @dev Once the PWN contract is set, you'll have to call `this.setPWN(PWN.address)` for this contract to work
     *  @param _uri Uri to be used for finding the token metadata (https://api.pwn.finance/deed/...)
     */
    constructor(string memory _uri) ERC1155(_uri) Ownable() {

    }

    /*
     *   All contracts of this section can only be called by the PWN contract itself - once set via `setPWN(PWN.address)`
     */

    /**
     * create
     * @dev Creates the PWN Deed token contract - ERC1155 with extra use case specific features
     * @param _assetAddress Address of the asset contract
     * @param _assetCategory Category of the asset - see { MultiToken.sol }
     * @param _duration Loan duration in seconds
     * @param _assetId ID of an ERC721 or ERC1155 token || 0 in case the token doesn't have IDs
     * @param _assetAmount Amount of an ERC20 or ERC1155 token || 0 in case of NFTs
     * @param _owner Address initiating the new Deed
     * @return Deed ID of the newly minted Deed
     */
    function create(
        address _assetAddress,
        MultiToken.Category _assetCategory,
        uint32 _duration,
        uint256 _assetId,
        uint256 _assetAmount,
        address _owner
    ) external onlyPWN returns (uint256) {
        id++;

        Deed storage deed = deeds[id];
        deed.duration = _duration;
        deed.collateral.assetAddress = _assetAddress;
        deed.collateral.category = _assetCategory;
        deed.collateral.id = _assetId;
        deed.collateral.amount = _assetAmount;

        _mint(_owner, id, 1, "");

        deed.status = 1;

        emit DeedCreated(_assetAddress, _assetCategory, _assetId, _assetAmount, _duration, id);

        return id;
    }

    /**
     * revoke
     * @dev Burns a deed token
     * @param _did Deed ID of the token to be burned
     * @param _owner Address of the borrower who issued the Deed
     */
    function revoke(
        uint256 _did,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _did) == 1, "The deed doesn't belong to the caller");
        require(getDeedStatus(_did) == 1, "Deed can't be revoked at this stage");

        deeds[_did].status = 0;

        emit DeedRevoked(_did);
    }

    /**
     * makeOffer
     * @dev saves an offer object that defines loan terms
     * @dev only ERC20 tokens can be offered as loan
     * @param _assetAddress Address of the asset contract
     * @param _assetAmount Amount of an ERC20 token to be offered as loan
     * @param _lender Address of the asset lender
     * @param _did ID of the Deed the offer should be bound to
     * @param _toBePaid Amount to be paid back by the borrower
     * @return hash of the newly created offer
     */
    function makeOffer(
        address _assetAddress,
        uint256 _assetAmount,
        address _lender,
        uint256 _did,
        uint256 _toBePaid
    ) external onlyPWN returns (bytes32) {
        require(getDeedStatus(_did) == 1, "Deed not accepting offers");

        bytes32 hash = keccak256(abi.encodePacked(_lender, nonce));
        nonce++;

        Offer storage offer = offers[hash];
        offer.loan.assetAddress = _assetAddress;
        offer.loan.amount = _assetAmount;
        offer.toBePaid = _toBePaid;
        offer.lender = _lender;
        offer.did = _did;

        deeds[_did].pendingOffers.push(hash);

        emit OfferMade(_assetAddress, _assetAmount, _lender, _toBePaid, _did, hash);

        return hash;
    }

    /**
     * revokeOffer
     * @dev function to remove a pending offer
     * @dev This only removes the offer representation but it doesn't remove the offer from a list of pending offers.
     *         The offers associated with a deed has to be filtered on the front end to only list the valid ones.
     *         No longer existent offers will simply return 0 if prompted about their DID.
     * @param _offer Hash identifying an offer
     * @param _lender Address of the lender who made the offer
     * @dev TODO: consider ways to remove the offer from the pending offers array / maybe replace for a mapping
     */
    function revokeOffer(
        bytes32 _offer,
        address _lender
    ) external onlyPWN {
        require(offers[_offer].lender == _lender, "This address didn't create the offer");
        require(getDeedStatus(offers[_offer].did) == 1, "Can only remove offers from open Deeds");

        delete offers[_offer];

        emit OfferRevoked(_offer);
    }

    /**
     * acceptOffer
     * @dev function to set accepted offer
     * @param _did ID of the Deed the offer should be bound to
     * @param _offer Hash identifying an offer
     * @param _owner Address of the borrower who issued the Deed
     */
    function acceptOffer(
        uint256 _did,
        bytes32 _offer,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _did) == 1, "The deed doesn't belong to the caller");
        require(getDeedStatus(_did) == 1, "Deed can't accept more offers");

        Deed storage deed = deeds[_did];
        deed.borrower = _owner;
        deed.expiration = uint40(block.timestamp) + deed.duration;
        deed.acceptedOffer = _offer;
        delete deed.pendingOffers;
        deed.status = 2;

        emit OfferAccepted(_did, _offer);
    }

    /**
     * repayLoan
     * @dev function to make proper state transition
     * @param _did ID of the Deed which is paid back
     */
    function repayLoan(uint256 _did) external onlyPWN {
        require(getDeedStatus(_did) == 2, "Deed doesn't have an accepted offer to be paid back");

        deeds[_did].status = 3;

        emit PaidBack(_did, deeds[_did].acceptedOffer);
    }

    /**
     * claim
     * @dev function that would burn the deed token if the token is in paidBack or expired state
     * @param _did ID of the Deed which is claimed
     * @param _owner Address of the deed token owner
     */
    function claim(
        uint256 _did,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _did) == 1, "Caller is not the deed owner");
        require(getDeedStatus(_did) >= 3, "Deed can't be claimed yet");

        deeds[_did].status = 0;

        emit DeedClaimed(_did);
    }

    /**
     * burn
     * @dev function that would burn the deed token if the token is in dead state
     * @param _did ID of the Deed which is burned
     * @param _owner Address of the deed token owner
     */
    function burn(
        uint256 _did,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _did) == 1, "Caller is not the deed owner");
        require(deeds[_did].status == 0, "Deed can't be burned at this stage");

        delete deeds[_did];
        _burn(_owner, _did, 1);
    }

    /*----------------------------------------------------------*|
    |*  ## VIEW FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    /*--------------------------------*|
    |*  ## VIEW FUNCTIONS - DEEDS     *|
    |*--------------------------------*/

    /**
     * getDeedStatus
     * @dev used in contract calls & status checks and also in UI for elementary deed status categorization
     * @param _did Deed ID checked for status
     * @return a status number
     */
    function getDeedStatus(uint256 _did) public view returns (uint8) {
        if (deeds[_did].expiration > 0 && deeds[_did].expiration < block.timestamp && deeds[_did].status != 3) {
            return 4;
        } else {
            return deeds[_did].status;
        }
    }

    /**
     * getExpiration
     * @dev utility function to find out exact expiration time of a particular Deed
     * @dev for simple status check use `this.getDeedStatus(did)` if `status == 4` then Deed has expired
     * @param _did Deed ID to be checked
     * @return unix time stamp in seconds
     */
    function getExpiration(uint256 _did) public view returns (uint40) {
        return deeds[_did].expiration;
    }

    /**
     * getDuration
     * @dev utility function to find out loan duration period of a particular Deed
     * @param _did Deed ID to be checked
     * @return loan duration period in seconds
     */
    function getDuration(uint256 _did) public view returns (uint32) {
        return deeds[_did].duration;
    }

    /**
     * getBorrower
     * @dev utility function to find out a borrower address of a particular Deed
     * @param _did Deed ID to be checked
     * @return address of the borrower
     */
    function getBorrower(uint256 _did) public view returns (address) {
        return deeds[_did].borrower;
    }

    /**
     * getDeedCollateral
     * @dev utility function to find out collateral asset of a particular Deed
     * @param _did Deed ID to be checked
     * @return Asset construct - for definition see { MultiToken.sol }
     */
    function getDeedCollateral(uint256 _did) public view returns (MultiToken.Asset memory) {
        return deeds[_did].collateral;
    }

    /**
     * getOffers
     * @dev utility function to get a list of all pending offers of a Deed
     * @param _did Deed ID to be checked
     * @return a list of offer hashes
     */
    function getOffers(uint256 _did) public view returns (bytes32[] memory) {
        return deeds[_did].pendingOffers;
    }

    /**
     * getAcceptedOffer
     * @dev used to get a list of made offers to be queried in the UI - needs additional check for re-validating each offer
     * @dev revalidation requires checking if the lender has sufficient balance and approved the asset
     * @param _did Deed ID being queried for offers
     * @return Hash of the accepted offer
     */
    function getAcceptedOffer(uint256 _did) public view returns (bytes32) {
        return deeds[_did].acceptedOffer;
    }

    /*--------------------------------*|
    |*  ## VIEW FUNCTIONS - OFFERS    *|
    |*--------------------------------*/

    /**
     * getDeedID
     * @dev utility function to find out which Deed is an offer associated with
     * @param _offer Offer hash of an offer to be prompted
     * @return Deed ID
     */
    function getDeedID(bytes32 _offer) public view returns (uint256) {
        return offers[_offer].did;
    }

    /**
     * getOfferLoan
     * @dev utility function that returns the loan asset of a particular offer
     * @param _offer Offer hash of an offer to be prompted
     * @return Asset construct - for definition see { MultiToken.sol }
     */
    function getOfferLoan(bytes32 _offer) public view returns (MultiToken.Asset memory) {
        return offers[_offer].loan;
    }

    /**
     * toBePaid
     * @dev quick query of the total amount to be paid to an offer
     * @param _offer Offer hash of an offer to be prompted
     * @return Amount to be paid back
     */
    function toBePaid(bytes32 _offer) public view returns (uint256) {
        return offers[_offer].toBePaid;
    }

    /**
     * getLender
     * @dev utility function to find out a lender address of a particular offer
     * @param _offer Offer hash of an offer to be prompted
     * @return Address of the lender
     */
    function getLender(bytes32 _offer) public view returns (address) {
        return offers[_offer].lender;
    }

    /*--------------------------------*|
    |*  ## SETUP FUNCTIONS            *|
    |*--------------------------------*/

    /**
     * setPWN
     * @dev An essential setup function. Has to be called once PWN contract was deployed
     * @param _address Identifying the PWN contract
     */
    function setPWN(address _address) external onlyOwner {
        PWN = _address;
    }

    /**
     * setUri
     * @dev An non-essential setup function. Can be called to adjust the Deed token metadata URI
     * @param _newUri setting the new origin of Deed metadata
     */
    function setUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract PWNVault is Ownable, IERC1155Receiver {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    address public PWN;

    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyPWN() {
        require(msg.sender == PWN, "Caller is not the PWN");
        _;
    }

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    event VaultPush(MultiToken.Asset asset, address indexed origin);
    event VaultPull(MultiToken.Asset asset, address indexed beneficiary);
    event VaultProxy(MultiToken.Asset asset, address indexed origin, address indexed beneficiary);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * PWN Vault constructor
     * @dev this contract holds balances of all locked collateral & paid back loan prior to their rightful claims
     * @dev in order for the vault to work it has to have an association with the PWN logic via `.setPWN(PWN.address)`
     */
    constructor() Ownable() IERC1155Receiver() {
    }

    /**
     * push
     * @dev function accessing an asset and pushing it INTO the vault
     * @dev the function assumes a prior token approval was made with the PWNVault.address to be approved
     * @param _asset An asset construct - for definition see { MultiToken.sol }
     * @return true if successful
     */
    function push(MultiToken.Asset memory _asset, address _origin) external onlyPWN returns (bool) {
        _asset.transferAssetFrom(_origin, address(this));
        emit VaultPush(_asset, _origin);
        return true;
    }

    /**
     * pull
     * @dev function pulling an asset FROM the vault, sending to a defined recipient
     * @dev this is used for unlocking the collateral on revocations & claims or when claiming a paidback loan
     * @param _asset An asset construct - for definition see { MultiToken.sol }
     * @param _beneficiary An address of the recipient of the asset - is set in the PWN logic contract
     * @return true if successful
     */
    function pull(MultiToken.Asset memory _asset, address _beneficiary) external onlyPWN returns (bool) {
        _asset.transferAsset(_beneficiary);
        emit VaultPull(_asset, _beneficiary);
        return true;
    }

    /**
     * pullProxy
     * @dev function pulling an asset FROM a lender, sending to a borrower
     * @dev this function assumes prior approval for the asset to be spend by the borrower address
     * @param _asset An asset construct - for definition see { MultiToken.sol }
     * @param _origin An address of the lender who is providing the loan asset
     * @param _beneficiary An address of the recipient of the asset - is set in the PWN logic contract
     * @return true if successful
     */
    function pullProxy(MultiToken.Asset memory _asset, address _origin, address _beneficiary) external onlyPWN returns (bool) {
        _asset.transferAssetFrom(_origin, _beneficiary);
        emit VaultProxy(_asset, _origin, _beneficiary);
        return true;
    }
    
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     * To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        override
        external
        pure
        returns(bytes4)
    {
        return 0xf23a6e61;
    }
    
    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated. To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        override
        external
        pure
        returns(bytes4)
    {
        return 0xbc197c81;
    }

    /**
     * setPWN
     * @dev An essential setup function. Has to be called once PWN contract was deployed
     * @param _address Identifying the PWN contract
     */
    function setPWN(address _address) external onlyOwner {
        PWN = _address;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || // ERC165
            interfaceId == type(Ownable).interfaceId || // Ownable
            interfaceId == type(IERC1155Receiver).interfaceId || // ERC1155Receiver
            interfaceId == this.PWN.selector
                            ^ this.push.selector
                            ^ this.pull.selector
                            ^ this.pullProxy.selector
                            ^ this.setPWN.selector; // PWN Vault

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}