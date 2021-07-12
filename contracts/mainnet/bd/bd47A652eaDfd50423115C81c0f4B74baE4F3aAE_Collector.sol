/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/borrower/collect/collector.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.6.12;

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/borrower/collect/collector.sol
/* pragma solidity >=0.6.12; */

/* import "tinlake-auth/auth.sol"; */

interface NFTLike_1 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ReserveLike_1 {
    function balance() external;
}

interface ThresholdRegistryLike {
    function threshold(uint) external view returns (uint);
}

interface PileLike_1 {
    function debt(uint) external returns (uint);
}

interface ShelfLike_1 {
    function claim(uint, address) external;
    function token(uint loan) external returns (address, uint);
    function recover(uint loan, address usr, uint wad) external;
}

contract Collector is Auth {

     // -- Collectors --
    mapping (address => uint) public collectors;
    function relyCollector(address usr) public auth { collectors[usr] = 1; emit RelyCollector(usr); }
    function denyCollector(address usr) public auth { collectors[usr] = 0; emit DenyCollector(usr); }
    modifier auth_collector { require(collectors[msg.sender] == 1); _; }

    // --- Data ---
    ThresholdRegistryLike threshold;

    struct Option {
        address buyer;
        uint    nftPrice;
    }

    mapping (uint => Option) public options;

    ReserveLike_1 reserve;
    ShelfLike_1 shelf;
    PileLike_1 pile;

    event Collect(uint indexed loan, address indexed buyer);
    event RelyCollector(address indexed usr);
    event DenyCollector(address indexed usr);
    event Depend(bytes32 indexed contractName, address addr);
    event File(bytes32 indexed what, uint indexed loan, address buyer, uint nftPrice);

    constructor (address shelf_, address pile_, address threshold_) {
        shelf = ShelfLike_1(shelf_);
        pile = PileLike_1(pile_);
        threshold = ThresholdRegistryLike(threshold_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // sets the dependency to another contract
    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "reserve") reserve = ReserveLike_1(addr);
        else if (contractName == "shelf") shelf = ShelfLike_1(addr);
        else if (contractName == "pile") pile = PileLike_1(addr);
        else if (contractName == "threshold") threshold = ThresholdRegistryLike(addr);
        else revert();
        emit Depend(contractName, addr);
    }

    // sets the liquidation-price of an NFT
    function file(bytes32 what, uint loan, address buyer, uint nftPrice) external auth {
        if (what == "loan") {
            require(nftPrice > 0, "no-nft-price-defined");
            options[loan] = Option(buyer, nftPrice);
        } else revert("unknown parameter");
        emit File(what, loan, buyer, nftPrice);
    }


    // if the loan debt is above the loan threshold the NFT should be seized,
    // i.e. taken away from the borrower to be sold off at a later stage.
    // therefore the ownership of the nft is transferred to the collector
    function seize(uint loan) external {
        uint debt = pile.debt(loan);
        require((threshold.threshold(loan) <= debt), "threshold-not-reached");
        shelf.claim(loan, address(this));
    }


    // a nft can be collected if the collector is the nft- owner
    // The NFT needs to be `seized` first to transfer ownership to the collector.
    // and then seized by the collector
    function collect(uint loan) external auth_collector {
        _collect(loan, msg.sender);
    }

    function collect(uint loan, address buyer) external auth {
        _collect(loan, buyer);
    }

    function _collect(uint loan, address buyer) internal {
        require(buyer == options[loan].buyer || options[loan].buyer == address(0), "not-allowed-to-collect");
        (address registry, uint nft) = shelf.token(loan);
        require(options[loan].nftPrice > 0, "no-nft-price-defined");
        shelf.recover(loan, buyer, options[loan].nftPrice);
        NFTLike_1(registry).transferFrom(address(this), buyer, nft);
        reserve.balance();
        emit Collect(loan, buyer);
    }
}