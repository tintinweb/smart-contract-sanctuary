// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract GoodGamer is ERC721Enumerable, AccessControl {
    using Strings for uint256;
    // CONSTS
    uint256 public constant CONTRACT_VERSION = 1;
    // ROLES
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    bytes32 public constant ROLE_SETTING = keccak256("ROLE_SETTING");
    bytes32 public constant ROLE_INIT = keccak256("ROLE_INIT");
    bytes32 public constant ROLE_WITHDRAW = keccak256("ROLE_WITHDRAW");
    bytes32 public constant ROLE_CUSTOM_PRICE = keccak256("ROLE_CUSTOM_PRICE");
    // SETTINGS
    address payable public treasury;
    bool public autoTrasnferToTreasury;
    // INITS
    mapping(uint256 => bool) private drop_initeds;
    mapping(uint256 => string) private drop_names;
    mapping(uint256 => uint256) private drop_start_dates;
    mapping(uint256 => uint256) private drop_end_dates;
    mapping(uint256 => uint256) private drop_maxes;
    mapping(uint256 => uint256) private drop_prices;
    mapping(uint256 => uint256) private tokens_drop;
    mapping(uint256 => uint256) private drop_tokens;
    mapping(uint256 => mapping(address => uint256)) private drop_custom_prices;

    // CONSTRUCTOR
    constructor() ERC721("Good Gamer", "GG") {
        address owner = address(msg.sender);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_INIT, owner);
        _setupRole(ROLE_SETTING, owner);
        _setupRole(ROLE_WITHDRAW, owner);
        _setupRole(ROLE_CUSTOM_PRICE, owner);
        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_INIT, ROLE_OWNER);
        _setRoleAdmin(ROLE_SETTING, ROLE_OWNER);
        _setRoleAdmin(ROLE_WITHDRAW, ROLE_OWNER);
        _setRoleAdmin(ROLE_CUSTOM_PRICE, ROLE_OWNER);
        treasury = payable(owner);
    }

    // OVERRIDE
    function tokenURI(uint256 token)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(token),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    getDropName(getDropOf(token)),
                    "/",
                    token.toString()
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://nft.goodgamer.gg/api/",
                    CONTRACT_VERSION,
                    "/"
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // SETTING
    function setSetting(
        address payable newTreasury,
        bool newAutoTrasnferToTreasury
    ) public onlyRole(ROLE_SETTING) {
        treasury = newTreasury;
        autoTrasnferToTreasury = newAutoTrasnferToTreasury;
    }

    // Drop
    function initDrop(
        uint256 drop,
        string memory name,
        uint256 start_date,
        uint256 end_date,
        uint256 max,
        uint256 price
    ) public onlyRole(ROLE_INIT) {
        require(drop > 0, "Drop must be a positive integer greater than zero.");
        require(bytes(name).length > 0, "Drop name can not be empty.");
        require(
            start_date >= 0 && end_date >= 0,
            "Dates must be a positive or zero integer."
        );
        require(max > 0, "Max must be a positive integer greater than zero.");
        require(
            price > 0,
            "Price must be a positive integer greater than zero."
        );
        require(
            drop_tokens[drop] == 0,
            "Setting can not be changed after minting."
        );
        drop_initeds[drop] = true;
        drop_names[drop] = name;
        drop_start_dates[drop] = start_date;
        drop_end_dates[drop] = end_date;
        drop_maxes[drop] = max;
        drop_prices[drop] = price;
        drop_tokens[drop] = 0;
    }

    function isDropInited(uint256 drop) public view returns (bool) {
        return drop_initeds[drop];
    }

    function getDropName(uint256 drop) public view returns (string memory) {
        return drop_names[drop];
    }

    function getDropStartDate(uint256 drop) public view returns (uint256) {
        return drop_start_dates[drop];
    }

    function getDropEndDate(uint256 drop) public view returns (uint256) {
        return drop_end_dates[drop];
    }

    function getDropMax(uint256 drop) public view returns (uint256) {
        return drop_maxes[drop];
    }

    function getDropPrice(uint256 drop) public view returns (uint256) {
        return drop_prices[drop];
    }

    function getDropTokensCount(uint256 drop) public view returns (uint256) {
        return drop_tokens[drop];
    }

    function getDropOf(uint256 token) public view returns (uint256) {
        return tokens_drop[token];
    }

    // CUSTOM PRICE
    function setCustomPrice(
        uint256 drop,
        address wallet,
        uint256 price
    ) public onlyRole(ROLE_CUSTOM_PRICE) {
        drop_custom_prices[drop][wallet] = price;
    }

    function getCustomPrice(uint256 drop, address wallet)
        public
        view
        returns (uint256)
    {
        return drop_custom_prices[drop][wallet];
    }

    function getDropFinalPrice(uint256 drop, address wallet)
        public
        view
        returns (uint256)
    {
        uint256 price = getDropPrice(drop);
        uint256 custom = getCustomPrice(drop, wallet);
        if (custom > 0) {
            price = custom;
        }
        return price;
    }

    // MINT
    function mint(uint256 drop, uint256 count) public payable {
        require(isDropInited(drop), "Drop has not been inited yet.");
        require(
            getDropStartDate(drop) <= block.timestamp,
            "Drop has not been started yet."
        );
        require(count > 0, "Count can not be less than 1.");
        require(
            getDropEndDate(drop) == 0 ||
                getDropEndDate(drop) >= block.timestamp,
            "Drop has been finished."
        );
        require(
            getDropTokensCount(drop) >= getDropMax(drop),
            "All drops have been sold out."
        );
        require(
            getDropTokensCount(drop) + count <= getDropMax(drop),
            "Insufficient count of drop requested."
        );
        require(
            getDropFinalPrice(drop, msg.sender) * count <= msg.value,
            "Drop price is not valid"
        );
        if (getCustomPrice(drop, msg.sender) > 0) {
            drop_custom_prices[drop][msg.sender] = 0;
            delete drop_custom_prices[drop][msg.sender];
        }
        for (uint256 index = 0; index < count; index++) {
            uint256 next = totalSupply() + 1;
            drop_tokens[drop]++;
            tokens_drop[next] = drop;
            _safeMint(msg.sender, next);
        }
        if (autoTrasnferToTreasury) {
            treasury.transfer(address(this).balance);
        }
    }

    function withdraw(uint256 amount) public onlyRole(ROLE_WITHDRAW) {
        treasury.transfer(amount);
    }

    function withdrawAll() public onlyRole(ROLE_WITHDRAW) {
        withdraw(address(this).balance);
    }
}