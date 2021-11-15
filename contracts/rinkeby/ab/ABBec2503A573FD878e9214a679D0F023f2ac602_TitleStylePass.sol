// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 adrianleb

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

pragma solidity ^0.8.0;

interface TitlesInterface {
    function verifyTitle(uint256 _titleId, address _account)
        external
        view
        returns (bool);
}

interface BlockStyleInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract TitleStylePass {
    //Loot Contract
    mapping(uint256 => mapping(uint256 => uint256)) public styleToTitleSupply;
    mapping(uint256 => mapping(uint256 => uint256))
        public styleToTitleSupplyUsed;

    address public titlesAddr;
    address public stylesAddr;
    address public controllerAddr;

    event SupplyUpdated(
        uint256 indexed style,
        uint256 indexed title,
        uint256 indexed supply
    );

    event SupplyUsed(
        address indexed who,
        uint256 indexed style,
        uint256 indexed title
    );

    constructor(
        address _titlesAddr,
        address _stylesAddr,
        address _controllerAddr
    ) {
        titlesAddr = _titlesAddr;
        stylesAddr = _stylesAddr;
        controllerAddr = _controllerAddr;
    }

    /// @dev check if sender owns token
    modifier onlyStyleOwner(uint256 style) {
        BlockStyleInterface _styles = BlockStyleInterface(stylesAddr);
        require(msg.sender == _styles.ownerOf(style), "Sender not style owner");
        _;
    }

    function titleSupplyAvailable(uint256 style, uint256 title)
        public
        view
        returns (bool)
    {
        require(
            styleToTitleSupply[style][title] > 0,
            "Title has no supply available for Style"
        );
        return
            styleToTitleSupplyUsed[style][title] <
            styleToTitleSupply[style][title];
    }

    function canMintStyleWithTitle(
        address who,
        uint256 style,
        uint256 title
    ) public view returns (bool) {
        TitlesInterface titlesContract = TitlesInterface(titlesAddr);

        require(
            titlesContract.verifyTitle(title, who),
            "Wallet not title eligible"
        );
        require(
            titleSupplyAvailable(style, title),
            "No supply available for wallet"
        );

        return true;
    }

    function updateTitleStyleSupply(
        uint256 style,
        uint256 title,
        uint256 supply
    ) external onlyStyleOwner(style) {
        styleToTitleSupplyUsed[style][title] = supply;
    }

    function incrementTitleStyleSupplyUsed(uint256 style, uint256 title)
        external
        returns (uint256)
    {
        require(msg.sender == controllerAddr, "Operation not allowed");
        styleToTitleSupplyUsed[style][title] += 1;

        return styleToTitleSupplyUsed[style][title];
    }
}

