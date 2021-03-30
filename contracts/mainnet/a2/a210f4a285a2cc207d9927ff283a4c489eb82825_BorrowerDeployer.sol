/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15 <0.6.0;


// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15 <0.6.0;

interface NAVFeedFabLike {
    function newFeed() external returns (address);
}

interface TitleFabLike {
    function newTitle(string calldata, string calldata) external returns (address);
}

interface CollectorFabLike {
    function newCollector(address, address, address) external returns (address);
}

interface PileFabLike {
    function newPile() external returns (address);
}

interface ShelfFabLike {
    function newShelf(address, address, address, address) external returns (address);
}


// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15 <0.6.0;

contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}


interface DependLike {
    function depend(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface NFTFeedLike {
    function init() external;
}

interface FeedFabLike {
    function newFeed() external returns(address);
}


interface FileLike {
    function file(bytes32 name, uint value) external;
}

contract BorrowerDeployer is FixedPoint {
    address      public root;

    TitleFabLike     public titlefab;
    ShelfFabLike     public shelffab;
    PileFabLike      public pilefab;
    CollectorFabLike public collectorFab;
    FeedFabLike      public feedFab;

    address public title;
    address public shelf;
    address public pile;
    address public collector;
    address public currency;
    address public feed;

    string  public titleName;
    string  public titleSymbol;
    Fixed27 public discountRate;

    address constant ZERO = address(0);

    constructor (
      address root_,
      address titlefab_,
      address shelffab_,
      address pilefab_,
      address collectorFab_,
      address feedFab_,
      address currency_,
      string memory titleName_,
      string memory titleSymbol_,
      uint discountRate_
    ) public {
        root = root_;

        titlefab = TitleFabLike(titlefab_);
        shelffab = ShelfFabLike(shelffab_);

        pilefab = PileFabLike(pilefab_);
        collectorFab = CollectorFabLike(collectorFab_);
        feedFab = FeedFabLike(feedFab_);

        currency = currency_;

        titleName = titleName_;
        titleSymbol = titleSymbol_;
        discountRate = Fixed27(discountRate_);
    }

    function deployCollector() public {
        require(collector == ZERO && address(shelf) != ZERO);
        collector = collectorFab.newCollector(address(shelf), address(pile), address(feed));
        AuthLike(collector).rely(root);
    }

    function deployPile() public {
        require(pile == ZERO);
        pile = pilefab.newPile();
        AuthLike(pile).rely(root);
    }

    function deployTitle() public {
        require(title == ZERO);
        title = titlefab.newTitle(titleName, titleSymbol);
        AuthLike(title).rely(root);
    }

    function deployShelf() public {
        require(shelf == ZERO && title != ZERO && pile != ZERO && feed != ZERO);
        shelf = shelffab.newShelf(currency, address(title), address(pile), address(feed));
        AuthLike(shelf).rely(root);
    }

    function deployFeed() public {
        feed = feedFab.newFeed();
        AuthLike(feed).rely(root);
    }

    function deploy() public {
        // ensures all required deploy methods were called
        require(shelf != ZERO && collector != ZERO);

        // shelf allowed to call
        AuthLike(pile).rely(shelf);

        DependLike(feed).depend("shelf", address(shelf));
        DependLike(feed).depend("pile", address(pile));

        // allow nftFeed to update rate groups
        AuthLike(pile).rely(feed);
        NFTFeedLike(feed).init();

        DependLike(shelf).depend("subscriber", address(feed));

        AuthLike(feed).rely(shelf);
        AuthLike(title).rely(shelf);

        // collector allowed to call
        AuthLike(shelf).rely(collector);

        FileLike(feed).file("discountRate", discountRate.value);
    }
}