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

pragma solidity 0.5.15;

import {Collector} from "./../collect/collector.sol";

contract CollectorFab {
    function newCollector(
        address shelf,
        address pile,
        address threshold
    ) public returns (address) {
        Collector collector = new Collector(shelf, pile, threshold);
        collector.rely(msg.sender);
        collector.deny(address(this));
        return address(collector);
    }
}

// collector.sol -- can remove bad assets from the pool
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

pragma solidity 0.5.15;

import "../../../lib/ds-note/src/note.sol";
import "../../../lib/galaxy-auth/src/auth.sol";

contract NFTLike {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract DistributorLike {
    function balance() public;
}

contract ThresholdRegistryLike {
    function threshold(uint256) public view returns (uint256);
}

contract PileLike {
    function debt(uint256) public returns (uint256);
}

contract ShelfLike {
    function claim(uint256, address) public;

    function token(uint256 loan) public returns (address, uint256);

    function recover(
        uint256 loan,
        address usr,
        uint256 wad
    ) public;
}

contract Collector is DSNote, Auth {
    // -- Collectors --
    mapping(address => uint256) public collectors;

    function relyCollector(address usr) external auth note {
        collectors[usr] = 1;
    }

    function denyCollector(address usr) external auth note {
        collectors[usr] = 0;
    }

    modifier auth_collector() {
        require(collectors[msg.sender] == 1);
        _;
    }

    // --- Data ---
    ThresholdRegistryLike threshold;

    struct Option {
        address buyer;
        uint256 nftPrice;
    }

    mapping(uint256 => Option) public options;

    DistributorLike distributor;
    ShelfLike shelf;
    PileLike pile;

    constructor(
        address shelf_,
        address pile_,
        address threshold_
    ) public {
        shelf = ShelfLike(shelf_);
        pile = PileLike(pile_);
        threshold = ThresholdRegistryLike(threshold_);
        wards[msg.sender] = 1;
    }

    /// sets the dependency to another contract
    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "distributor") distributor = DistributorLike(addr);
        else if (contractName == "shelf") shelf = ShelfLike(addr);
        else if (contractName == "pile") pile = PileLike(addr);
        else if (contractName == "threshold") threshold = ThresholdRegistryLike(addr);
        else revert();
    }

    /// sets the liquidation-price of an NFT
    function file(
        bytes32 what,
        uint256 loan,
        address buyer,
        uint256 nftPrice
    ) external auth {
        if (what == "loan") {
            require(nftPrice > 0, "no-nft-price-defined");
            options[loan] = Option(buyer, nftPrice);
        } else revert("unknown parameter");
    }

    /// if the loan debt is above the loan threshold the NFT should be seized,
    /// i.e. taken away from the borrower to be sold off at a later stage.
    /// therefore the ownership of the nft is transferred to the collector
    function seize(uint256 loan) external {
        uint256 debt = pile.debt(loan);
        require((threshold.threshold(loan) <= debt), "threshold-not-reached");
        shelf.claim(loan, address(this));
    }

    /// a nft can be collected if the collector is the nft- owner
    /// The NFT needs to be `seized` first to transfer ownership to the collector.
    /// and then seized by the collector
    function collect(uint256 loan) external auth_collector note {
        _collect(loan, msg.sender);
    }

    function collect(uint256 loan, address buyer) external auth note {
        _collect(loan, buyer);
    }

    function _collect(uint256 loan, address buyer) internal {
        require(buyer == options[loan].buyer || options[loan].buyer == address(0), "not-allowed-to-collect");
        (address registry, uint256 nft) = shelf.token(loan);
        require(options[loan].nftPrice > 0, "no-nft-price-defined");
        shelf.recover(loan, buyer, options[loan].nftPrice);
        NFTLike(registry).transferFrom(address(this), buyer, nft);
        distributor.balance();
    }
}

/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity 0.5.15;

contract DSNote {
    event LogNote(bytes4 indexed sig, address indexed guy, bytes32 indexed foo, bytes32 indexed bar, uint256 wad, bytes fax) anonymous;

    modifier note() {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
//
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

pragma solidity 0.5.15;

import "../../ds-note/src/note.sol";

contract Auth is DSNote {
    mapping(address => uint256) public wards;

    function rely(address usr) public auth note {
        wards[usr] = 1;
    }

    function deny(address usr) public auth note {
        wards[usr] = 0;
    }

    modifier auth() {
        require(wards[msg.sender] == 1);
        _;
    }
}