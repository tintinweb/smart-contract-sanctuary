/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/borrower/deployer.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

////// src/borrower/fabs/interfaces.sol
/* pragma solidity >=0.7.6; */

interface NAVFeedFabLike {
    function newFeed() external returns (address);
}

interface TitleFabLike {
    function newTitle(string calldata, string calldata) external returns (address);
}

interface PileFabLike {
    function newPile() external returns (address);
}

interface ShelfFabLike {
    function newShelf(address, address, address, address) external returns (address);
}



////// src/fixed_point.sol
/* pragma solidity >=0.7.6; */

abstract contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}

////// src/borrower/deployer.sol
/* pragma solidity >=0.7.6; */

/* import { ShelfFabLike, PileFabLike, TitleFabLike } from "./fabs/interfaces.sol"; */
/* import { FixedPoint } from "./../fixed_point.sol"; */

interface DependLike_1 {
    function depend(bytes32, address) external;
}

interface AuthLike_1 {
    function rely(address) external;
    function deny(address) external;
}

interface NAVFeedLike_1 {
    function init() external;
}

interface FeedFabLike {
    function newFeed() external returns(address);
}

interface FileLike_1 {
    function file(bytes32 name, uint value) external;
}

contract BorrowerDeployer is FixedPoint {
    address      public immutable root;

    TitleFabLike     public immutable titlefab;
    ShelfFabLike     public immutable shelffab;
    PileFabLike      public immutable pilefab;
    FeedFabLike      public immutable feedFab;

    address public title;
    address public shelf;
    address public pile;
    address public immutable currency;
    address public feed;

    string  public titleName;
    string  public titleSymbol;
    Fixed27 public discountRate;

    address constant ZERO = address(0);
    bool public wired;

    constructor (
      address root_,
      address titlefab_,
      address shelffab_,
      address pilefab_,
      address feedFab_,
      address currency_,
      string memory titleName_,
      string memory titleSymbol_,
      uint discountRate_
    ) {
        root = root_;

        titlefab = TitleFabLike(titlefab_);
        shelffab = ShelfFabLike(shelffab_);

        pilefab = PileFabLike(pilefab_);
        feedFab = FeedFabLike(feedFab_);

        currency = currency_;

        titleName = titleName_;
        titleSymbol = titleSymbol_;
        discountRate = Fixed27(discountRate_);
    }

    function deployPile() public {
        require(pile == ZERO);
        pile = pilefab.newPile();
        AuthLike_1(pile).rely(root);
    }

    function deployTitle() public {
        require(title == ZERO);
        title = titlefab.newTitle(titleName, titleSymbol);
        AuthLike_1(title).rely(root);
    }

    function deployShelf() public {
        require(shelf == ZERO && title != ZERO && pile != ZERO && feed != ZERO);
        shelf = shelffab.newShelf(currency, address(title), address(pile), address(feed));
        AuthLike_1(shelf).rely(root);
    }

    function deployFeed() public {
        require(feed == ZERO);
        feed = feedFab.newFeed();
        AuthLike_1(feed).rely(root);
    }

    function deploy(bool initNAVFeed) public {
        // ensures all required deploy methods were called
        require(shelf != ZERO);
        require(!wired, "borrower contracts already wired"); // make sure borrower contracts only wired once
        wired = true;

        // shelf allowed to call
        AuthLike_1(pile).rely(shelf);

        DependLike_1(feed).depend("shelf", address(shelf));
        DependLike_1(feed).depend("pile", address(pile));

        // allow nftFeed to update rate groups
        AuthLike_1(pile).rely(feed);

        DependLike_1(shelf).depend("subscriber", address(feed));

        AuthLike_1(feed).rely(shelf);
        AuthLike_1(title).rely(shelf);
        
        FileLike_1(feed).file("discountRate", discountRate.value);

        if (initNAVFeed) {
            NAVFeedLike_1(feed).init();
        }
    }


    function deploy() public {
        deploy(false);
    }
}