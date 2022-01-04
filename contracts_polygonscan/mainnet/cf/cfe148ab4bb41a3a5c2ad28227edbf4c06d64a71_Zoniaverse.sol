//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";

// Developer: Odin / @carlosero (Github) / carlosobserva (Twitter)

contract Zoniaverse is ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public _tokenIds;
    uint256 public constant MAX_ZONIANS = 10000;
    uint256 public constant MAX_ZONIANS_FOR_SALE = 9900;
    uint256 public constant MAX_ZONIANS_PER_TRANSACTION = 100;

    bool public mintIsOpen = false;
    string public baseTokenURI;

    // to keep track of giveaway + validate it
    uint256 public MAX_GIVEAWAY_ZONIANS = 100;
    mapping(address => uint256) public giveawayRecipientTokens;
    address[] public giveawayRecipients;
    Counters.Counter public tokensGivenAway;

    // Role management
    enum ROLES { NONE, EARTHLING, HUMAN_OF_COLLABORATION, HUMAN_OF_SYMPATHY, HUMAN_OF_TRUST, COUNSELOR, ZARK }
    mapping(address => ROLES) public userRoles;
    mapping(ROLES => uint256) public mintPricePerRole;
    mapping(address => bool) receivedFreeZonian;
    address contractOwner;

    // Constructor
    constructor(string memory nftName, string memory nftSymbol, address _zark) ERC721(nftName, nftSymbol) {
        setRole(_zark, ROLES.ZARK);
        contractOwner = _zark;
    }

    // ********* //
    // Modifiers //
    // ********* //
    modifier saleIsOpen {
        require(totalMinted() < MAX_ZONIANS, "All Zonians sold!");
        require(mintIsOpen, "Sale is not open");
        _;
    }

    // role-based management
    modifier onlyZark {
        require(userRoles[msg.sender] == ROLES.ZARK, "Only Emperor Zark can!");
        _;
    }

    modifier onlyCounselor {
        require(userRoles[msg.sender] == ROLES.ZARK || userRoles[msg.sender] == ROLES.COUNSELOR, "Only Counselor or higher can!");
        _;
    }

    modifier onlyHumanOfTrust {
        require(userRoles[msg.sender] == ROLES.ZARK || userRoles[msg.sender] == ROLES.COUNSELOR || userRoles[msg.sender] == ROLES.HUMAN_OF_TRUST, "Only Humans of Trust or higher can!");
        _;
    }

    // **** //
    // MINT //
    // **** //
    // _amount: Amount of NFTs that the user wants to mint
    function mintNFT(uint8 _amount)
        public payable saleIsOpen
    {
        require(userRoles[msg.sender] != ROLES.HUMAN_OF_TRUST && userRoles[msg.sender] != ROLES.COUNSELOR && userRoles[msg.sender] != ROLES.ZARK, "Only minting roles can do mint");
        require(_amount > 0, "min 1 zonian for mint");
        require(_amount <= MAX_ZONIANS_PER_TRANSACTION, "100 max per transaction");
        require(msg.value >= mintTotalFor(msg.sender, _amount), "Insufficient funds to mint");
        require(isAvailable(_amount, MAX_ZONIANS_FOR_SALE), "Not enough zonians for mint");

        for(uint8 i = 1; i <= _amount; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }

        // extra mint for sympathy, doing it only if role && available
        if (userRoles[msg.sender] == ROLES.HUMAN_OF_SYMPATHY && (1 + totalMinted()) <= MAX_ZONIANS) {
            // mint the extra zonian + tag user as "already gave away"
            if (!receivedFreeZonian[msg.sender]) {
                _tokenIds.increment();
                uint256 newItemId = _tokenIds.current();
                _safeMint(msg.sender, newItemId);
                receivedFreeZonian[msg.sender] = true;
            }
        }
    }

    // ******* //
    // GETTERS //
    // ******* //
    function mintTotalFor(address _recipient, uint256 _amount) public view returns (uint256) {
        require(_amount > 0);
        return _amount.mul(mintPriceFor(_recipient));
    }

    function mintPriceFor(address _recipient) public view returns (uint256) {
        return mintPricePerRole[userRoles[_recipient]];
    }

    function getGiveawayParticipants() public view virtual returns (address[] memory) {
        return giveawayRecipients;
    }

    // overrides _baseURI
    function _baseURI() internal view override virtual returns (string memory) {
        return baseTokenURI;
    }

    function availableForMint() public view returns (uint256) {
        return MAX_ZONIANS.sub(totalMinted());
    }

    function totalMinted() public view returns (uint256) {
        return _tokenIds.current();
    }

    function isAvailable(uint256 _amount, uint256 _maximum) public view returns (bool) {
        return (_amount + totalMinted()) <= _maximum;
    }

    // ******* //
    // SETTERS //
    // ******* //

    // ONLY ZARK (SECURED VIA LEDGER NANO)
    function setAdminRole(address _recipient, ROLES role) public onlyZark {
        require(_recipient != contractOwner, "owner's role can't change");
        setRole(_recipient, role);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyZark {
        baseTokenURI = _baseTokenURI;
    }

    // withdraw to withdrawAddress
    function withdraw(address withdrawAddress) public payable onlyZark {
        (bool success, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(success);
    }

    // ONLY COUNSELOR
    function setMintPrices(uint256 nonePrice, uint256 earthlingPrice, uint256 collaborationPrice, uint256 sympathyPrice) public onlyCounselor {
        setPriceForRole(ROLES.NONE, nonePrice);
        setPriceForRole(ROLES.EARTHLING, earthlingPrice);
        setPriceForRole(ROLES.HUMAN_OF_COLLABORATION, collaborationPrice);
        setPriceForRole(ROLES.HUMAN_OF_SYMPATHY, sympathyPrice);
    }

    function setPriceForRole(ROLES role, uint256 price) public onlyCounselor {
        mintPricePerRole[role] = price;
    }

    function setMintIsOpen(bool _mintIsOpen) public onlyCounselor {
        if (_mintIsOpen) {
            require(mintPricePerRole[ROLES.NONE] > 0, "No mint price");
        }
        mintIsOpen = _mintIsOpen;
    }

    // It's possible that in the future we want to give more to the community so we need to be able to extend the number
    function setGiveawayZonians(uint256 newLimit) public onlyCounselor {
        MAX_GIVEAWAY_ZONIANS = newLimit;
    }

    // ONLY HUMAN OF TRUST
    // Basically for setting ONLY "None" up to "Human of Sympathy" levels, no more than that
    function setMintingRole(address _recipient, ROLES role) public onlyHumanOfTrust {
        require(role == ROLES.NONE || role == ROLES.EARTHLING || role == ROLES.HUMAN_OF_COLLABORATION || role == ROLES.HUMAN_OF_SYMPATHY, "Only Zark can assign higher roles");
        require(userRoles[_recipient] != ROLES.HUMAN_OF_TRUST && userRoles[_recipient] != ROLES.COUNSELOR && userRoles[_recipient] != ROLES.ZARK, "Only Zark can demote roles");
        setRole(_recipient, role);
    }

    function giveAway(address _recipient) public onlyHumanOfTrust {
        require(isAvailable(1, MAX_ZONIANS), "Not enough zonians for mint");
        require((1 + tokensGivenAway.current()) <= MAX_GIVEAWAY_ZONIANS, "No giveaway zonians available");

        // mint the zonian
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_recipient, newItemId);

        // tracking
        tokensGivenAway.increment();
        giveawayRecipients.push(_recipient);
        giveawayRecipientTokens[_recipient] = newItemId;
    }

    // INTERNALS
    function setRole(address _recipient, ROLES role) private {
        userRoles[_recipient] = role;
    }
}