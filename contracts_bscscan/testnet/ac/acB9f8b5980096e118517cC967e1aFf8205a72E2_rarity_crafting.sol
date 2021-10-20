/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is ERC165, IERC721 {
    using Strings for uint256;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

interface rarity {
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function class(uint) external view returns (uint);
    function summon(uint _class) external;
    function next_summoner() external view returns (uint);
    function spend_xp(uint _summoner, uint _xp) external;
}

interface rarity_attributes {
    function character_created(uint) external view returns (bool);
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);
}

interface rarity_skills {
    function get_skills(uint _summoner) external view returns (uint8[36] memory);
}

interface rarity_gold {
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface rarity_crafting_materials_i {
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface codex_items_goods {
    function item_by_id(uint _id) external pure returns(
        uint id,
        uint cost,
        uint weight,
        string memory name,
        string memory description
    );
}

interface codex_items_armor {
    function get_proficiency_by_id(uint _id) external pure returns (string memory description);
    function item_by_id(uint _id) external pure returns(
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    );
}

interface codex_items_weapons {
    struct weapon {
        uint id;
        uint cost;
        uint proficiency;
        uint encumbrance;
        uint damage_type;
        uint weight;
        uint damage;
        uint critical;
        int critical_modifier;
        uint range_increment;
        string name;
        string description;
    }

    function get_proficiency_by_id(uint _id) external pure returns (string memory description);
    function get_encumbrance_by_id(uint _id) external pure returns (string memory description);
    function get_damage_type_by_id(uint _id) external pure returns (string memory description);
    function item_by_id(uint _id) external pure returns(weapon memory _weapon);
}

interface codex_base_random {
    function d20(uint _summoner) external view returns (uint);
}
 
contract rarity_crafting is ERC721Enumerable {
    uint public next_item;
    uint constant craft_xp_per_day = 250e18;

    rarity constant _rm = rarity(0xc4B6C3E745313384072Cc0CcaC56ad2a40459855);
    rarity_attributes constant _attr = rarity_attributes(0x7b72CC5f3100c4B1dD124F6a6e48ef671e5658bf);
    rarity_crafting_materials_i constant _craft_i = rarity_crafting_materials_i(0x8F58b01f7e15357de2a19a2069E53bD5EB533cab);
    rarity_gold constant _gold = rarity_gold(0xa9E5C934377211Fcc1Ad44e957F0D7098eCDdA50);
    rarity_skills constant _skills = rarity_skills(0xa9d663154edD552ef1057B88582D76DfAD36333C);

    codex_base_random constant _random = codex_base_random(0xc5F5E553D6b98824E4EC826EBADe8e3C176f0B08);
    codex_items_goods constant _goods = codex_items_goods(0x166F68F5D2fb5d8f31Dd21e3F3271dBB6dE7B324);
    codex_items_armor constant _armor = codex_items_armor(0x861dBd31A44C0737176d63030363A335cd5AAd29);
    codex_items_weapons constant _weapons = codex_items_weapons(0x75dC798E880Dc89179886A02B93B39Ee4c6A73FF);

    string constant public name = "Shang Hai Ching Crafting (I)";
    string constant public symbol = "SHCC(I)";

    //精心制作
    event Crafted(address indexed owner, uint check, uint summoner, uint base_type, uint item_type, uint gold, uint craft_i);

    //召唤师ID
    uint public immutable SUMMMONER_ID;

    constructor() {
        SUMMMONER_ID = _rm.next_summoner();
        _rm.summon(4);
    }

    struct item {//物品
        uint8 base_type;//基本类型
        uint8 item_type;//物品种类
        uint32 crafted;//精心制作的
        uint crafter;//工匠
    }

    //被批准或所有者
    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return _rm.getApproved(_summoner) == msg.sender || _rm.ownerOf(_summoner) == msg.sender;
    }

    //拿取dc
    function get_goods_dc() public pure returns (uint dc) {
        return 20;
    }

    //获得盔甲dc
    function get_armor_dc(uint _item_id) public pure returns (uint dc) {
        (,,,,uint _armor_bonus,,,,,) = _armor.item_by_id(_item_id);
        return 20 + _armor_bonus;
    }

    //获得武器dc
    function get_weapon_dc(uint _item_id) public pure returns (uint dc) {
        codex_items_weapons.weapon memory _weapon = _weapons.item_by_id(_item_id);
        if (_weapon.proficiency == 1) {
            return 20;
        } else if (_weapon.proficiency == 2) {
            return 25;
        } else if (_weapon.proficiency == 3) {
            return 30;
        }
    }

    //获得dc
    function get_dc(uint _base_type, uint _item_id) public pure returns (uint dc) {
        if (_base_type == 1) {
            return get_goods_dc();
        } else if (_base_type == 2) {
            return get_armor_dc(_item_id);
        } else if (_base_type == 3) {
            return get_weapon_dc(_item_id);
        }
    }

    //获取物品成本
    function get_item_cost(uint _base_type, uint _item_type) public pure returns (uint cost) {
        if (_base_type == 1) {
            (,cost,,,) = _goods.item_by_id(_item_type);
        } else if (_base_type == 2) {
            (,cost,,,,,,,,) = _armor.item_by_id(_item_type);
        } else if (_base_type == 3) {
            codex_items_weapons.weapon memory _weapon = _weapons.item_by_id(_item_type);
            cost = _weapon.cost;
        }
    }

    //属性修饰符
    function modifier_for_attribute(uint _attribute) public pure returns (int _modifier) {
        if (_attribute == 9) {
            return -1;
        }
        return (int(_attribute) - 10) / 2;
    }

    //工艺技能检查
    function craft_skillcheck(uint _summoner, uint _dc) public view returns (bool crafted, int check) {
        check = int(uint(_skills.get_skills(_summoner)[5]));
        if (check == 0) {
            return (false, 0);
        }
        (,,,uint _int,,) = _attr.ability_scores(_summoner);
        check += modifier_for_attribute(_int);
        if (check <= 0) {
            return (false, 0);
        }
        check += int(_random.d20(_summoner));
        return (check >= int(_dc), check);
    }

    //已验证
    function isValid(uint _base_type, uint _item_type) public pure returns (bool) {
        if (_base_type == 1) {
            return (1 <= _item_type && _item_type <= 24);
        } else if (_base_type == 2) {
            return (1 <= _item_type && _item_type <= 18);
        } else if (_base_type == 3) {
            return (1 <= _item_type && _item_type <= 59);
        }
        return false;
    }

    //模拟
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc) {
        dc = get_dc(_base_type, _item_type);//得到dc
        if (_crafting_materials >= 10) {
            dc = dc - (_crafting_materials / 10);
        }
        (crafted, check) = craft_skillcheck(_summoner, dc);//制作材料
        if (crafted) {
            cost = get_item_cost(_base_type, _item_type);//获取物品成本
        }
    }

    //工艺
    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external {
        require(_isApprovedOrOwner(_summoner), "!owner");//批准或所有者
        require(_attr.character_created(_summoner), "!created");//创建的角色
        require(_summoner != SUMMMONER_ID, "hax0r");//召唤师ID
        require(isValid(_base_type, _item_type), "!valid");//已验证
        uint _dc = get_dc(_base_type, _item_type);//得到dc
        if (_crafting_materials >= 10) {//制作材料 >= 10
            require(_craft_i.transferFrom(SUMMMONER_ID, _summoner, SUMMMONER_ID, _crafting_materials), "!craft");
            _dc = _dc - (_crafting_materials / 10);
        }
        (bool crafted, int check) = craft_skillcheck(_summoner, _dc);//工艺技能检查
        if (crafted) {
            uint _cost = get_item_cost(_base_type, _item_type);//获取物品成本
            require(_gold.transferFrom(SUMMMONER_ID, _summoner, SUMMMONER_ID, _cost), "!gold");
            items[next_item] = item(_base_type, _item_type, uint32(block.timestamp), _summoner);
            _safeMint(msg.sender, next_item);
            emit Crafted(msg.sender, uint(check), _summoner, _base_type, _item_type, _cost, _crafting_materials);
            next_item++;
        }
        _rm.spend_xp(_summoner, craft_xp_per_day);
    }

    mapping(uint => item) public items;//物品

    //获取类型
    function get_type(uint _type_id) public pure returns (string memory _type) {
        if (_type_id == 1) {
            _type = "Goods";
        } else if (_type_id == 2) {
            _type = "Armor";
        } else if (_type_id == 3) {
            _type = "Weapons";
        }
    }

    function tokenURI(uint _item) public view returns (string memory uri) {
        uint _base_type = items[_item].base_type;
        if (_base_type == 1) {
            return get_token_uri_goods(_item);
        } else if (_base_type == 2) {
            return get_token_uri_armor(_item);
        } else if (_base_type == 3) {
            return get_token_uri_weapon(_item);
        }
    }

    function get_token_uri_goods(uint _item) public view returns (string memory output) {
        item memory _data = items[_item];
        {
            (,
                uint _cost,
                uint _weight,
                string memory _name,
                string memory _description
            ) = _goods.item_by_id(_data.item_type);
            output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
            output = string(abi.encodePacked(output, "category ", get_type(_data.base_type), '</text><text x="10" y="40" class="base">'));
            output = string(abi.encodePacked(output, "name ", _name, '</text><text x="10" y="60" class="base">'));
            output = string(abi.encodePacked(output, "cost ", toString(_cost/1e18), "gp", '</text><text x="10" y="80" class="base">'));
            output = string(abi.encodePacked(output, "weight ", toString(_weight), "lb", '</text><text x="10" y="100" class="base">'));
            output = string(abi.encodePacked(output, "description ", _description, '</text><text x="10" y="120" class="base">'));
            output = string(abi.encodePacked(output, "crafted by ", toString(_data.crafter), '</text><text x="10" y="140" class="base">'));
            output = string(abi.encodePacked(output, "crafted at ", toString(_data.crafted), '</text></svg>'));
        }
        output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "item #', toString(_item), '", "description": "Rarity tier 1, non magical, item crafting.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))))));

        return output;
    }

    function get_token_uri_armor(uint _item) public view returns (string memory output) {
        item memory _data = items[_item];
        {
            (,
                uint _cost,
                uint _proficiency,
                uint _weight,
                uint _armor_bonus,
                uint _max_dex_bonus,
                int _penalty,
                uint _spell_failure,
                string memory _name,
                string memory _description
            ) = _armor.item_by_id(_data.item_type);
            output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
            output = string(abi.encodePacked(output, "category ", get_type(_data.base_type), '</text><text x="10" y="40" class="base">'));
            output = string(abi.encodePacked(output, "name ", _name, '</text><text x="10" y="60" class="base">'));
            output = string(abi.encodePacked(output, "cost ", toString(_cost/1e18), "gp", '</text><text x="10" y="80" class="base">'));
            output = string(abi.encodePacked(output, "weight ", toString(_weight), "lb", '</text><text x="10" y="100" class="base">'));
            output = string(abi.encodePacked(output, "proficiency ", _armor.get_proficiency_by_id(_proficiency), '</text><text x="10" y="120" class="base">'));
            output = string(abi.encodePacked(output, "armor bonus ", toString(_armor_bonus), '</text><text x="10" y="140" class="base">'));
            output = string(abi.encodePacked(output, "max dex ", toString(_max_dex_bonus), '</text><text x="10" y="160" class="base">'));
            output = string(abi.encodePacked(output, "penalty ", toString(_penalty), '</text><text x="10" y="180" class="base">'));
            output = string(abi.encodePacked(output, "spell failure ", toString(_spell_failure), "%", '</text><text x="10" y="200" class="base">'));
            output = string(abi.encodePacked(output, "description ", _description, '</text><text x="10" y="220" class="base">'));
            output = string(abi.encodePacked(output, "crafted by ", toString(_data.crafter), '</text><text x="10" y="240" class="base">'));
            output = string(abi.encodePacked(output, "crafted at ", toString(_data.crafted), '</text></svg>'));
        }
        output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "item #', toString(_item), '", "description": "Rarity tier 1, non magical, item crafting.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))))));
    }

    function get_token_uri_weapon(uint _item) public view returns (string memory output) {
        item memory _data = items[_item];
        {
            codex_items_weapons.weapon memory _weapon = _weapons.item_by_id(_data.item_type);
            output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
            output = string(abi.encodePacked(output, "category ", get_type(_data.base_type), '</text><text x="10" y="40" class="base">'));
            output = string(abi.encodePacked(output, "name ", _weapon.name, '</text><text x="10" y="60" class="base">'));
            output = string(abi.encodePacked(output, "cost ", toString(_weapon.cost/1e18), "gp", '</text><text x="10" y="80" class="base">'));
            output = string(abi.encodePacked(output, "weight ", toString(_weapon.weight), "lb", '</text><text x="10" y="100" class="base">'));
            output = string(abi.encodePacked(output, "proficiency ", _weapons.get_proficiency_by_id(_weapon.proficiency), '</text><text x="10" y="120" class="base">'));
            output = string(abi.encodePacked(output, "encumbrance ", _weapons.get_encumbrance_by_id(_weapon.encumbrance), '</text><text x="10" y="140" class="base">'));
            output = string(abi.encodePacked(output, "damage 1d", toString(_weapon.damage), " ", _weapons.get_damage_type_by_id(_weapon.damage_type), '</text><text x="10" y="160" class="base">'));
            output = string(abi.encodePacked(output, "(modifier) x critical (", toString(_weapon.critical_modifier), ") x ", toString(_weapon.critical), '</text><text x="10" y="180" class="base">'));
            output = string(abi.encodePacked(output, "range ", toString(_weapon.range_increment), "ft", '</text><text x="10" y="200" class="base">'));
            output = string(abi.encodePacked(output, "description ", _weapon.description, '</text><text x="10" y="220" class="base">'));
            output = string(abi.encodePacked(output, "crafted by ", toString(_data.crafter), '</text><text x="10" y="240" class="base">'));
            output = string(abi.encodePacked(output, "crafted at ", toString(_data.crafted), '</text></svg>'));
        }
        output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "item #', toString(_item), '", "description": "Rarity tier 1, non magical, item crafting.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))))));
    }

    function toString(int value) internal pure returns (string memory) {
        string memory _string = '';
        if (value < 0) {
            _string = '-';
            value = value * -1;
        }
        return string(abi.encodePacked(_string, toString(uint(value))));
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}