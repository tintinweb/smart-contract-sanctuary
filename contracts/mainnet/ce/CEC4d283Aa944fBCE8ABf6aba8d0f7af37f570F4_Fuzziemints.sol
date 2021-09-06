pragma solidity ^0.8.4;

import "./SniftieERC721Common.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract Fuzziemints is SniftieERC721Common {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter private _fuzzieTokenIdTracker;

    // backend signer address used for checking if data was created by Sniftie's server
    address private _backend;

    // payable wallet addresses
    address payable private _charity1;
    address payable private _charity2;
    address payable private _charity3;
    address payable private _sniftie;
    address payable private _f100royalty;
    address payable private _fuzziemints;

    uint256 public constant FUZZIE_PREMINT_MAX = 205;
    uint256 public constant FUZZIEMAX = 5555;
    uint8 public constant PURCHASE_LIMIT = 17;

    uint256 private constant PAYMENT_GAS_LIMIT = 5000;
    uint256 private constant PRICE_PER_TOKEN = 55000000 gwei;

    uint256 private _eachCharityPercentage = 100;
    uint256 private _f100RoyaltyPercentage = 1090;
    uint256 private _sniftieRoyaltyPercentage = 2200;
    uint256 private _fuzziemintsPercentage = 6410;

    mapping(address => uint8) whitelistMintCount;
    mapping(address => bool) whitelistAddresses;

    bool private _isPublicSaleLocked = true;

    constructor (string memory name, string memory symbol, string memory baseTokenURI, string memory contractMetadataURI, address sniftieAdmin, address backend, address payable[] memory payableAddresses) SniftieERC721Common(name, symbol, baseTokenURI, contractMetadataURI, sniftieAdmin) {
            _backend = backend;

            // payable addresses array must be in this order
            _charity1 = payableAddresses[0];
            _charity2 = payableAddresses[1];
            _charity3 = payableAddresses[2];
            _f100royalty = payableAddresses[3];
            _sniftie = payableAddresses[4];
            _fuzziemints = payableAddresses[5];
    }

    function getIsPublicSaleLocked() public view returns (bool) { return _isPublicSaleLocked; }
    function getBackend() public view returns (address) { return _backend; }
    function getSniftie() public view returns (address) { return _sniftie; }
    function getFuzziemints() public view returns (address) { return _fuzziemints; }
    function getF100royalty() public view returns (address) { return _f100royalty; }
    function getCharity1() public view returns (address) { return _charity1; }
    function getCharity2() public view returns (address) { return _charity2; }
    function getCharity3() public view returns (address) { return _charity3; }

    function setIsPublicSalesLocked(bool locked) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _isPublicSaleLocked = locked;
    }
    function setBackend(address backend) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _backend = backend;
    }
    function setSniftie(address payable sniftie) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _sniftie = sniftie;
    }
    function setFuzziemints(address payable fuzziemints) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _fuzziemints = fuzziemints;
    }
    function setF100royalty(address payable f100royalty) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _f100royalty = f100royalty;
    }
    function setCharity1(address payable charity1) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _charity1 = charity1;
    }
    function setCharity2(address payable charity2) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _charity2 = charity2;
    }
    function setCharity3(address payable charity3) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        _charity3 = charity3;
    }

    function premint() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE to mint first 100 tokens");
        uint totalSupply = totalSupply();
        uint available = FUZZIE_PREMINT_MAX - totalSupply;
        uint mintQty = available >= 25 ? 25 : available;

        require(mintQty > 0, "Premint limit reached");

        for (uint i = 0; i < mintQty; i++) {
            mintToken(_msgSender());
        }
    }

    function addToWhitelist(address[] memory add) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE to add to whitelist");
        for (uint i = 0; i < add.length; i++) {
            whitelistAddresses[add[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory remove) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE remove from whitelist");
        for (uint i = 0; i < remove.length; i++) {
            whitelistAddresses[remove[i]] = false;
        }
    }

    function mintToken(address to) internal returns (uint256) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _fuzzieTokenIdTracker.increment();
        uint256 newItemId = _fuzzieTokenIdTracker.current();
        _mint(to, newItemId);

        return newItemId;
    }

    function salePayment(uint256 charityAmount, uint256 f100RoyaltyAmount, uint256 sniftieAmount, uint256 fuzziemintsAmount) internal {
        // transfer amounts to respective wallets
        (bool charity1Success, ) = _charity1.call{ value:charityAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(charity1Success, "Charity 1 payment failed");

        (bool charity2Success, ) = _charity2.call{ value:charityAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(charity2Success, "Charity 2 payment failed");

        (bool charity3Success, ) = _charity3.call{ value:charityAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(charity3Success, "Charity 3 payment failed");

        (bool f100Success, ) = _f100royalty.call{ value:f100RoyaltyAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(f100Success, "First 100 royalty payment failed");

        (bool sniftieSuccess, ) = _sniftie.call{ value:sniftieAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(sniftieSuccess, "Sniftie payment failed");

        (bool fuzziemintsSuccess, ) = _fuzziemints.call{ value:fuzziemintsAmount, gas: PAYMENT_GAS_LIMIT }("");
        require(fuzziemintsSuccess, "Fuzziemints payment failed");
    }

    function purchaseAndMint(bytes32 message, bytes32 messageHash, bytes memory signature, uint8 qty) public payable {
        // calculate signer address and check if it is equal to _backendSigner
        require(messageHash.recover(signature) == _backend, "Content not signed by Sniftie");

        // regenerate hash from parameters and check if it is equal to hash generated from sniftie's backend server
        require(keccak256(abi.encodePacked(qty)) == message, "Message hash does not match");

        // check if public sale is locked
        require(!_isPublicSaleLocked, "Public sales is still closed");

        // check if total supply does not exceed FUZZIEMAX
        require(totalSupply() + qty <= FUZZIEMAX, "Qty exceeds max number of tokens");

        // check for maximum token quantity to mint
        require(qty <= PURCHASE_LIMIT, "Cannot purchase more than 17 tokens");

        // check if amount sent is at least equal to the price of token
        require(msg.value >= PRICE_PER_TOKEN * qty, "Amount less than required price");

        // calculate amounts to transfer
        uint256 charityAmount = (msg.value / 10000) * _eachCharityPercentage;
        uint256 f100RoyaltyAmount = (msg.value / 10000) * _f100RoyaltyPercentage;
        uint256 sniftieAmount = (msg.value / 10000) * _sniftieRoyaltyPercentage;

        uint256 fuzziemintsAmount = msg.value - ((charityAmount * 3) + f100RoyaltyAmount + sniftieAmount);

        // call payment function to make the payments
        salePayment(charityAmount, f100RoyaltyAmount, sniftieAmount, fuzziemintsAmount);

        // call mint function
        for (uint i = 0; i < qty; i++) {
            mintToken(msg.sender);
        }
    }

    function whitelistedPurchaseAndMint(bytes32 message, bytes32 messageHash, bytes memory signature, uint8 qty) public payable {
        // calculate signer address and check if it is equal to _backendSigner
        require(messageHash.recover(signature) == _backend, "Content not signed by Sniftie");

        // regenerate hash from parameters and check if it is equal to hash generated from sniftie's backend server
        require(keccak256(abi.encodePacked(qty)) == message, "Message hash does not match");

        // check if public sale is locked and sender is whitelisted
        require(_isPublicSaleLocked && whitelistAddresses[msg.sender], "Public sales is still closed and you are not whitelisted");

        // limit token purchase to 5 if public sale is locked (whitelist period)
        require(whitelistMintCount[msg.sender] + qty <= 5, "Whitelist minting restricted to 5 tokens");

        // check if total supply does not exceed FUZZIEMAX
        require(totalSupply() + qty <= FUZZIEMAX, "Qty exceeds max number of tokens");

        // check for maximum token quantity to mint
        require(qty <= PURCHASE_LIMIT, "Cannot purchase more than 17 tokens");

        // check if amount sent is at least equal to the price of token
        require(msg.value >= PRICE_PER_TOKEN * qty, "Amount less than required price");

        // calculate amounts to transfer
        uint256 charityAmount = (msg.value / 10000) * _eachCharityPercentage;
        uint256 f100RoyaltyAmount = (msg.value / 10000) * _f100RoyaltyPercentage;
        uint256 sniftieAmount = (msg.value / 10000) * _sniftieRoyaltyPercentage;

        uint256 fuzziemintsAmount = msg.value - ((charityAmount * 3) + f100RoyaltyAmount + sniftieAmount);

        // call payment function to make the payments
        salePayment(charityAmount, f100RoyaltyAmount, sniftieAmount, fuzziemintsAmount);

        // implement minting here
        for (uint i = 0; i < qty; i++) {
            mintToken(msg.sender);
        }

        // update whitelist mint count tracker
        whitelistMintCount[msg.sender] = whitelistMintCount[msg.sender] + qty;
    }

    function setTokenMediaHashAndURI(uint tokenId, string memory mediaHashOrId, string memory tokenURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot set media hash and token URI if not admin");
        setTokenURI(tokenId, tokenURI);
        setTokenMediaHash(tokenId, mediaHashOrId);
    }

    function batchSetTokenMediaHashAndURI(uint256 startAtTokenIndex, string[] memory mediaHashes, string[] memory tokenURIs) public {
        require(mediaHashes.length == tokenURIs.length, "MediaHash Array and TokenURI Array lengths must match");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot batch set media hash and token URI if not admin");

        for (uint i = startAtTokenIndex; i < startAtTokenIndex + mediaHashes.length; i++) {
            uint256 tokenId = tokenByIndex(i);
            uint256 zeroIndex = i - startAtTokenIndex;
            setTokenMediaHashAndURI(tokenId, mediaHashes[zeroIndex], tokenURIs[zeroIndex]);
        }
    }
}