// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IFundable {
    function fund(string memory name) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IHirable {
    function hire(string memory name) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './ERC721/IFundable.sol';
import './ERC721/IHirable.sol';

interface IAttributes {
    function generate(uint256 tokenId) external;
}

contract Game {
    address private immutable _team;
    address private immutable _teamAttr;
    address private immutable _coach;
    address private immutable _coachAttr;
    address private immutable _player;
    address private immutable _playerAttr;
    address private immutable _scouter;
    address private immutable _scouterAttr;

    constructor(address team_, address teamAttr_, address coach_, address coachAttr_, address player_, address playerAttr_, address scouter_, address scouterAttr_) {
        _team = team_;
        _teamAttr = teamAttr_;
        _coach = coach_;
        _coachAttr = coachAttr_;
        _player = player_;
        _playerAttr = playerAttr_;
        _scouter = scouter_;
        _scouterAttr = scouterAttr_;
    }

    function fund(string memory name) external {
        uint256 tokenId = IFundable(_team).fund(name);
        IAttributes(_teamAttr).generate(tokenId);
    }
}

