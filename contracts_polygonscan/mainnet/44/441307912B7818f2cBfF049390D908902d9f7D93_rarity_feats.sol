// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface rarity {
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function class(uint) external view returns (uint);
}

interface rarity_codex_feats {
    function feat_by_id(uint _id) external pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    );
}

contract rarity_feats {

    rarity immutable _rm;
    rarity_codex_feats immutable _feats_1;
    rarity_codex_feats immutable _feats_2;

    constructor(rarity _rarity, rarity_codex_feats _rarity_feats_1, rarity_codex_feats _rarity_feats_2) {
        _rm = _rarity;
        _feats_1 = _rarity_feats_1;
        _feats_2 = _rarity_feats_2;
    }

    function is_valid(uint feat) public pure returns (bool) {
        return (1 <= feat && feat <= 99);
    }
    
    function feat_by_id(uint _id) public view returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prerequisites_feat,
        uint prerequisites_class,
        uint prerequisites_level,
        string memory benefit
    ) {
        if (_id <= 64) {
            return _feats_1.feat_by_id(_id);
        } else if (_id <= 99) {
            return _feats_2.feat_by_id(_id);
        }
    }

    function feats_per_level(uint _level) public pure returns (uint amount) {
        amount = (_level / 3)+1;
    }

    function feats_per_class(uint _class, uint _level) public pure returns (uint amount) {
        amount = feats_per_level(_level);
        if (_class == 1) {
            amount += 5;
        } else if (_class == 2) {
            amount += 4;
        } else if (_class == 3) {
            amount += 5;
        } else if (_class == 4) {
            amount += 4;
        } else if (_class == 5) {
            amount += 7;
        } else if (_class == 6) {
            amount += 2;
        } else if (_class == 7) {
            amount += 6;
        } else if (_class == 8) {
            amount += 4;
        } else if (_class == 9) {
            amount += 3;
        } else if (_class == 10) {
            amount += 1;
        } else if (_class == 11) {
            amount += 2;
        }
        
        if (_class == 5) {
            amount += (_level / 2)+1;
        
        } else if (_class == 6) {
            if (_level >= 6) {
                amount += 3;
            } else if (_level >= 2) {
                amount += 2;
            } else {
                amount += 1;
            }
        } else if (_class == 11) {
            amount += (_level / 5);
        }
    }

    mapping(uint => bool[100]) public feats;
    mapping(uint => uint[]) public feats_by_id;
    mapping(uint => bool) public character_created;

    function get_feats(uint _summoner) external view returns (bool[100] memory _feats) {
        return feats[_summoner];
    }
    
    function get_feats_by_id(uint _summoner) external view returns (uint[] memory _feats) {
        return feats_by_id[_summoner];
    }
    
    function get_feats_by_name(uint _summoner) external view returns (string[] memory _names) {
        _names = new string[](feats_by_id[_summoner].length);
        for (uint i = 0; i < _names.length; i++) {
            (,string memory _name,,,,,) = feat_by_id(feats_by_id[_summoner][i]);
            _names[i] = _name;
        }
    }

    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return _rm.getApproved(_summoner) == msg.sender || _rm.ownerOf(_summoner) == msg.sender;
    }
    
    function is_valid_class(uint _flag, uint _class) public pure returns (bool) {
        return (_flag & (2**(_class-1))) == (2**(_class-1));
    }
    
    function get_base_class_feats(uint _class) public pure returns (uint8[7] memory _feats) {
        if (_class == 1) {
            _feats = [91,75,5,6,63,0,0];
        } else if (_class == 2) {
            _feats = [91,75,5,63,0,0,0];
        } else if (_class == 3) {
            _feats = [91,5,6,7,63,0,0];
        } else if (_class == 4) {
            _feats = [91,5,6,63,0,0,0];
        } else if (_class == 5) {
            _feats = [91,75,5,6,7,63,96];
        } else if (_class == 6) {
            _feats = [34,24,0,0,0,0,0];
        } else if (_class == 7) {
            _feats = [91,75,5,6,7,63,0];
        } else if (_class == 8) {
            _feats = [91,75,5,63,0,0,0];
        } else if (_class == 9) {
            _feats = [91,75,5,0,0,0,0];
        } else if (_class == 10) {
            _feats = [91,0,0,0,0,0,0];
        } else if (_class == 11) {
            _feats = [91,88,0,0,0,0,0];
        }
    }
    
    function setup_class(uint _summoner) public {
        uint _class = _rm.class(_summoner);
        uint8[7] memory _feats = get_base_class_feats(_class);
        for (uint i = 0; i < 7; i++) {
            if (is_valid(_feats[i])) {
                feats[_summoner][_feats[i]] = true;
                feats_by_id[_summoner].push(_feats[i]);
            }
        }
        character_created[_summoner] = true;
    }

    function select_feat(uint _summoner, uint _feat) external {
        require(_isApprovedOrOwner(_summoner), "!summoner");
        require(is_valid(_feat), "!feat");
        uint _class = _rm.class(_summoner);
        uint _level = _rm.level(_summoner);
        require(feats_per_class(_class, _level) > feats_by_id[_summoner].length, "!points");
        if (!character_created[_summoner]) {
            setup_class(_summoner);
        }
        require(!feats[_summoner][_feat], "known");
        (,,
            bool _prerequisites,
            uint _prerequisites_feat,
            uint _prerequisites_class,
            uint _prerequisites_level,
        ) = feat_by_id(_feat);
        if (_prerequisites) {
            if (_prerequisites_feat > 0) {
                require(feats[_summoner][_prerequisites_feat]);
            }
            require(is_valid_class(_prerequisites_class, _class), "!class");
            require(_level >= _prerequisites_level);
        }
        feats[_summoner][_feat] = true;
        feats_by_id[_summoner].push(_feat);
    }
}