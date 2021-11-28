// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRarity {
    function adventure(uint _summoner) external;
    function level_up(uint _summoner) external;
    function approve(address _spennder, uint _summoner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IDungeon {
    function adventure(uint _summoner) external;
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function approve(uint from, uint spender, uint amount) external returns (bool);
}

interface IGold {
    function claim(uint summoner) external;
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function approve(uint from, uint spender, uint amount) external returns (bool);
}

interface ICrafting {
    function setApprovalForAll(address, bool) external;
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
    function next_item() external view returns(uint);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function SUMMMONER_ID() external view returns(uint);
}

interface IAttributes {
    function point_buy(uint _summoner, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external;
    function increase_strength(uint _summoner) external;
    function increase_dexterity(uint _summoner) external;
    function increase_constitution(uint _summoner) external;
    function increase_intelligence(uint _summoner) external;
    function increase_wisdom(uint _summoner) external;
    function increase_charisma(uint _summoner) external;
}

interface ISkills {
    function get_skills(uint _summoner) external view returns (uint8[36] memory);
    function set_skills(uint _summoner, uint8[36] memory _skills) external;
}

contract RarityAssistant {
    address owner;
    IRarity constant rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IAttributes constant attributes = IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    IDungeon constant dungeon = IDungeon(0x2A0F1cB17680161cF255348dDFDeE94ea8Ca196A);
    IGold constant gold = IGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    ISkills constant skills = ISkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);
    ICrafting constant crafting = ICrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);

    function initialize(address _owner) public {
        require(owner == address(0), "!initialized");
        owner = _owner;
        crafting.setApprovalForAll(owner, true);
    }

    function approve_all(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.approve(address(this), _ids[i]);
        }
    }

    function approve_gold_materials(uint256[] calldata _ids) external {
        uint crafting_hole_id = crafting.SUMMMONER_ID();
        uint MAX_256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            gold.approve(_ids[i], crafting_hole_id, MAX_256);
            dungeon.approve(_ids[i], crafting_hole_id, MAX_256);
        }
    }

    function transfer_summoners(uint256[] calldata _ids, address to) external {
        require(msg.sender == owner, "!owner");
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.safeTransferFrom(msg.sender, to, _ids[i]);
        }
    }

    function adventure(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.adventure(_ids[i]);
        }
    }

    function level_up(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            rarity.level_up(_ids[i]);
        }
    }

    function dungeon_adventure(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            dungeon.adventure(_ids[i]);
        }
    }

    function dungeon_transfer_same(uint256[] calldata _from_ids, uint256 _amount, uint256 to) external {
        require(msg.sender == owner, "!owner");
        uint len = _from_ids.length;
        for (uint i = 0; i < len; i++) {
            dungeon.transfer(_from_ids[i], to, _amount);
        }
    }

    function dungeon_transfer(uint256[] calldata _from_ids, uint256[] calldata _amounts, uint256 to) external {
        require(msg.sender == owner, "!owner");
        uint len = _from_ids.length;
        require(len == _amounts.length, "!length");
        for (uint i = 0; i < len; i++) {
            dungeon.transfer(_from_ids[i], to, _amounts[i]);
        }
    }

    function gold_claim(uint256[] calldata _ids) external {
        require(msg.sender == owner, "!owner");
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            gold.claim(_ids[i]);
        }
    }

    function gold_transfer_same(uint256[] calldata _from_ids, uint256 _amount, uint256 to) external {
        require(msg.sender == owner, "!owner");
        uint len = _from_ids.length;
        for (uint i = 0; i < len; i++) {
            gold.transfer(_from_ids[i], to, _amount);
        }
    }

    function gold_transfer(uint256[] calldata _from_ids, uint256[] calldata _amounts, uint256 to) external {
        require(msg.sender == owner, "!owner");
        uint len = _from_ids.length;
        require(len == _amounts.length, "!len");
        for (uint i = 0; i < len; i++) {
            gold.transfer(_from_ids[i], to, _amounts[i]);
        }
    }

    function point_buy_same(uint[] calldata _summoners, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external {
        require(msg.sender == owner, "!owner");
        uint len = _summoners.length;
        for (uint i = 0; i < len; i++) {
            attributes.point_buy(_summoners[i], _str, _dex, _const, _int, _wis, _cha);
        }
    }

    function point_buy(uint[] calldata _summoners, uint32[6][] calldata _attrs) external {
        require(msg.sender == owner, "!owner");
        uint len = _summoners.length;
        require(len == _attrs.length, "!len");
        for (uint i = 0; i < len; i++) {
            uint32[6] memory _attr = _attrs[i];
            attributes.point_buy(_summoners[i], _attr[0], _attr[1], _attr[2], _attr[3], _attr[4], _attr[5]);
        }
    }

    function increase_attributes(uint[] calldata _summoners, uint8[6][] calldata _attrs) external {
        require(msg.sender == owner, "!owner");
        uint len = _summoners.length;
        require(len == _attrs.length, "!len");
        for (uint i = 0; i < len; i++) {
            uint id = _summoners[i];
            uint8[6] memory _attr = _attrs[i];
            for (uint j = 0; j < _attr[0]; j++) {
                attributes.increase_strength(id);
            }
            for (uint j = 0; j < _attr[1]; j++) {
                attributes.increase_dexterity(id);
            }
            for (uint j = 0; j < _attr[2]; j++) {
                attributes.increase_constitution(id);
            }
            for (uint j = 0; j < _attr[3]; j++) {
                attributes.increase_intelligence(id);
            }
            for (uint j = 0; j < _attr[4]; j++) {
                attributes.increase_wisdom(id);
            }
            for (uint j = 0; j < _attr[5]; j++) {
                attributes.increase_charisma(id);
            }
        }
    }

    function increase_attributes_one(uint[] calldata _summoners, uint8[] calldata _attrs) external {
        require(msg.sender == owner, "!owner");
        uint len = _summoners.length;
        require(len == _attrs.length, "!len");
        for (uint i = 0; i < len; i++) {
            uint id = _summoners[i];
            uint8 x = _attrs[i];
            if (x == 1) {
                attributes.increase_strength(id);
            } else if (x == 2) {
                attributes.increase_dexterity(id);
            } else if (x == 3) {
                attributes.increase_constitution(id);
            } else if (x == 4) {
                attributes.increase_intelligence(id);
            } else if (x == 5) {
                attributes.increase_wisdom(id);
            } else if (x == 6) {
                attributes.increase_charisma(id);
            }
        }
    }

    function set_skills_same(uint[] calldata _summoners, uint8[36] calldata _values) external {
        require(msg.sender == owner, "!owner");
        uint len = _summoners.length;
        for (uint i = 0; i < len; i++) {
            skills.set_skills(_summoners[i], _values);
        }
    }

    function set_skills(uint[] calldata _summoners, uint8[36][] calldata _values_group) external {
        require(msg.sender == owner, "!owner");
        uint len = _summoners.length;
        require(_values_group.length == len, "!len");
        for (uint i = 0; i < len; i++) {
            skills.set_skills(_summoners[i], _values_group[i]);
        }
    }

    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) public returns (bool crafted, int check, uint cost, uint dc) {
        require(msg.sender == owner, "!owner");
        (crafted, check, cost, dc) = crafting.simulate(_summoner, _base_type, _item_type, _crafting_materials);
        require(crafted, "!luck");
        crafting.craft(_summoner, _base_type, _item_type, _crafting_materials);
        uint id = crafting.next_item();
        crafting.safeTransferFrom(address(this), msg.sender, id - 1);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public view returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}