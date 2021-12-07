// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

library rl {
    struct _summoner_service_data {
        uint goldBalance;
        uint xp;
        string class;
        uint level;
        bool transferred;
        bool hasName;
        string summonerName;
        uint8[36] current_skills;
        bool[36] class_skills;
        uint32 _str; 
        uint32 _dex; 
        uint32 _con; 
        uint32 _int; 
        uint32 _wis; 
        uint32 _cha;
    }

    struct _item_service_data {
        string base_type;
        uint item_type;
        uint weight;
        uint gold_cost;
        string name;
        string description;
        string proficiency; 
        string encumbrance; 
        string damage_type; 
        uint damage;
        uint critical;
        int critical_modifier;
        uint range_increment; 
        uint armor_bonus;
        uint max_dex_bonus;
        int penalty;
        uint spell_failure;
    }

    struct _base {
        uint xp;
        uint log;
        uint class;
        uint level;
    }

    struct _ability_scores {
        uint32 _str;
        uint32 _dex;
        uint32 _con;
        uint32 _int;
        uint32 _wis;
        uint32 _cha;
    }

    struct _ability_modifiers {
        int32 _str;
        int32 _dex;
        int32 _con;
        int32 _int;
        int32 _wis;
        int32 _cha;
    }

    struct _ability_scores_full {
        _ability_scores attributes;
        _ability_modifiers modifiers;
        uint total_points;
        uint spent_points;
        bool created;
    }

    struct _skills {
        uint8[36] skills;
        bool[36] class_skills;
        uint total_points;
        uint spent_points;
    }

    struct _gold {
        uint balance;
        uint claimed;
        uint claimable;
    }

    struct _material {
        uint balance;
        uint scout;
        uint log;
    }

    struct _summoner {
        _base base;
        _ability_scores_full ability_scores;
        _skills skills;
        _gold gold;
        _material[] materials;
    }

    struct _item1 {
        uint8 base_type;
        uint8 item_type;
        uint32 crafted;
        uint crafter;
    }

}

interface rarity_lib {
    function base(uint _s) external view returns (rl._base memory);
    function description(uint _s) external view returns (string memory);
    function ability_scores(uint _s) external view returns (rl._ability_scores memory);
    function ability_modifiers(uint _s) external view returns (rl._ability_modifiers memory);
    function ability_scores_full(uint _s) external view returns (rl._ability_scores_full memory);
    function skills(uint _s) external view returns (rl._skills memory);
    function gold(uint _s) external view returns (rl._gold memory);
    function materials(uint _s) external view returns (rl._material[] memory);
    function summoner_full(uint _s) external view returns (rl._summoner memory);
    function summoners_full(uint[] calldata _s) external view returns (rl._summoner[] memory);
    function items1(address _owner) external view returns (rl._item1[] memory);
}

interface adventurable {
    function adventure(uint _summoner) external;
    function adventurers_log(uint _summoner) external view returns(uint);
}

interface rarity_manifested is IERC721, adventurable {
    function summoner(uint _summoner) external view returns (uint _xp, uint _log, uint _class, uint _level);
    function level(uint) external view returns (uint);
    function minters(uint) external view returns (address);
    function class(uint) external view returns (uint);
    function classes(uint) external pure returns (string memory);
    function level_up(uint _summoner) external;
}

interface rarity_attributes {
    function ability_scores(uint _summoner) external view returns (uint32, uint32, uint32, uint32, uint32, uint32);
    function abilities_by_level(uint _level) external view returns (uint);
    function character_created(uint _summoner) external view returns (bool);
}

interface rarity_skills {
    function get_skills(uint _summoner) external view returns (uint8[36] memory);
    function skills_per_level(int _int, uint _class, uint _level) external view returns (uint points);
    function calculate_points_for_set(uint _class, uint8[36] memory _skills) external view returns (uint points);
    function class_skills(uint _class) external view returns (bool[36] memory _skills);
}

interface rarity_fungible {
    event Transfer(uint indexed from, uint indexed to, uint amount);
    event Approval(uint indexed from, uint indexed to, uint amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(uint owner) external view returns (uint);
    function allowance(uint owner, uint spender) external view returns (uint);

    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface rarity_gold is rarity_fungible {
    function claimed(uint _summoner) external view returns (uint);
}

interface rarity_mat1 is rarity_fungible, adventurable {
    function scout(uint _summoner) external view returns (uint reward);
}

interface rarity_item1 is IERC721Enumerable {
    function items(uint) external view returns (uint8, uint8, uint32, uint, address);
    function get_type(uint) external pure returns (string memory);
}

interface rarity_names is IERC721Enumerable {
    function summoner_to_name_id(uint _summoner) external view returns (uint id);
    function summoner_name(uint summoner) external view returns (string memory name);
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


contract rarity_library {
    using Strings for uint;

    rarity_manifested immutable _rm;
    rarity_attributes immutable _attr;
    rarity_skills immutable _skills;
    rarity_gold immutable _gold;
    rarity_mat1 immutable _mat1;
    rarity_item1 immutable _items1;
    rarity_names immutable _names;
    codex_items_goods immutable _goods;
    codex_items_armor immutable _armor;
    codex_items_weapons immutable _weapons;

    constructor(
        rarity_manifested _rarity_manifested,
        rarity_attributes _rarity_attributes,
        rarity_skills _rarity_skills,
        rarity_gold _rarity_gold,
        rarity_mat1 _rarity_mat1,
        rarity_item1 _rarity_item1,
        rarity_names _rarity_names,
        codex_items_goods _codex_items_goods,
        codex_items_armor _codex_items_armor, 
        codex_items_weapons _codex_items_weapons
        ) {
        _rm = _rarity_manifested;
        _attr = _rarity_attributes;
        _skills = _rarity_skills;
        _gold = _rarity_gold;
        _mat1 = _rarity_mat1;
        _items1 = _rarity_item1;
        _names = _rarity_names;
        _goods = _codex_items_goods;
        _armor = _codex_items_armor;
        _weapons = _codex_items_weapons;
    }

    function base(uint _s) public view returns (rl._base memory c) {
        (uint _xp, uint _log, uint _class, uint _level) = _rm.summoner(_s);
        c = rl._base(_xp, _log, _class, _level);
    }

    function description(uint _s) public view returns (string memory full_name) {
        (,,uint class, uint level) = _rm.summoner(_s);
        full_name = string(abi.encodePacked("Level ", level.toString(), " ", _rm.classes(class)));
        full_name = string(abi.encodePacked("Unnamed ", full_name));
    }

    function ability_scores(uint _s) public view returns (rl._ability_scores memory scores) {
        (uint32 _str, uint32 _dex, uint32 _con, uint32 _int, uint32 _wis, uint32 _cha) = _attr.ability_scores(_s);
        scores = rl._ability_scores(_str, _dex, _con, _int, _wis, _cha);
    }

    function _modifier_for_attribute(uint32 _attribute) internal pure returns (int32 _modifier) {
        if (_attribute == 9) {
            return - 1;
        }
        return (int32(_attribute) - 10) / 2;
    }

    function ability_modifiers(uint _s) public view returns (rl._ability_modifiers memory modifiers) {
        rl._ability_scores memory scores = ability_scores(_s);
        modifiers = rl._ability_modifiers(
            _modifier_for_attribute(scores._str),
            _modifier_for_attribute(scores._dex),
            _modifier_for_attribute(scores._con),
            _modifier_for_attribute(scores._int),
            _modifier_for_attribute(scores._wis),
            _modifier_for_attribute(scores._cha)
        );
    }

    function _pb(uint score) internal pure returns (uint) {
        if (score < 8) {
            return 0;
        } else if (score <= 14) {
            return score - 8;
        } else {
            return ((score - 8) ** 2) / 6;
        }
    }

    function ability_scores_full(uint _s) public view returns (rl._ability_scores_full memory scores_full) {
        rl._ability_scores memory scores = ability_scores(_s);
        rl._ability_modifiers memory modifiers = ability_modifiers(_s);
        uint total_points = _attr.abilities_by_level(_rm.level(_s)) + 32;
        uint spent_points = _pb(scores._str) + _pb(scores._dex) + _pb(scores._con) + _pb(scores._int) + _pb(scores._wis) + _pb(scores._cha);
        bool character_created = _attr.character_created(_s);
        scores_full = rl._ability_scores_full(scores, modifiers, total_points, spent_points, character_created);
    }

    function skills(uint _s) public view returns (rl._skills memory s) {
        uint8[36] memory _current_skills = _skills.get_skills(_s);
        rl._ability_modifiers memory mod = ability_modifiers(_s);
        (,, uint _class, uint _level) = _rm.summoner(_s);
        bool[36] memory _class_skills = _skills.class_skills(_class);
        uint _total_points;
        uint _spent_points;
        if (mod._int > -5) {
            // This will underflow for summoners with -5 int mod or less
            _total_points = _skills.skills_per_level(mod._int, _class, _level);
            _spent_points = _skills.calculate_points_for_set(_class, _current_skills);
        }
        s = rl._skills(
            _current_skills,
            _class_skills,
            _total_points,
            _spent_points
        );
    }

    function wealth_by_level(uint level) public pure returns (uint wealth) {
        for (uint i = 1; i < level; i++) {
            wealth += i * 1000e18;
        }
    }

    function gold(uint _s) public view returns (rl._gold memory g) {
        uint _claimed_gold;
        uint _claimed_level = _gold.claimed(_s);
        for (uint i = 1; i <= _claimed_level; i++) {
            _claimed_gold += wealth_by_level(i);
        }
        uint _current_level = _rm.level(_s);
        uint _total_claimable_gold;
        for (uint i = 1; i <= _current_level; i++) {
            _total_claimable_gold += wealth_by_level(i);
        }
        g = rl._gold(
            _gold.balanceOf(_s),
            _claimed_gold,
            _total_claimable_gold - _claimed_gold
        );
    }

    function materials(uint _s) public view returns (rl._material[] memory mats) {
        mats = new rl._material[](1);
        mats[0] = rl._material(_mat1.balanceOf(_s), _mat1.scout(_s), _mat1.adventurers_log(_s));
    }

    function summoner_full(uint _s) public view returns (rl._summoner memory s) {
        s = rl._summoner(
            base(_s),
            ability_scores_full(_s),
            skills(_s),
            gold(_s),
            materials(_s)
        );
    }

    function summoners_full(uint[] calldata _s) public view returns (rl._summoner[] memory s) {
        s = new rl._summoner[](_s.length);
        for (uint i = 0; i < _s.length; i++) {
            s[i] = summoner_full(_s[i]);
        }
    }

    function items1(address _owner) public view returns (rl._item1[] memory items){
        uint _total_items = _items1.balanceOf(_owner);
        items = new rl._item1[](_total_items);
        for (uint i = 0; i < _total_items; i++) {
            (uint8 _base_type, uint8 _item_type, uint32 _crafted, uint _crafter, ) = _items1.items(_items1.tokenOfOwnerByIndex(_owner, i));
            items[i] = rl._item1(_base_type, _item_type, _crafted, _crafter);
        }
    }

    function summonerBaseInfo(uint _s) public view returns(uint _xp, string memory _class, uint _level) {
        uint class;
       (_xp,, class, _level) = _rm.summoner(_s);
       _class = _rm.classes(class);
    }

    function summonerIsTransferred(uint _s) public view returns(bool _transferred) {
        address _minter = _rm.minters(_s);
        address _owner = _rm.ownerOf(_s);
        return _owner != _minter;
    }

    function hasName(uint _s) public view returns(bool _assigned) {
        return _names.summoner_to_name_id(_s) > 0;
    }

    function currentAndClassSkills(uint _s) public view returns(uint8[36] memory _current_skills, bool[36] memory _class_skills) {
        _current_skills = _skills.get_skills(_s);
        (,, uint _class,) = _rm.summoner(_s);
        _class_skills = _skills.class_skills(_class);
    }

    function summonerServiceData(uint _s) public view returns (rl._summoner_service_data memory data) {
        data.goldBalance = _gold.balanceOf(_s);
        
        (data.xp, data.class, data.level) = summonerBaseInfo(_s);
        data.transferred = summonerIsTransferred(_s);
        data.hasName = hasName(_s);
        data.summonerName = _names.summoner_name(_s);
        (data.current_skills, data.class_skills) =  currentAndClassSkills(_s);

        (data._str, data._dex, data._con, data._int, data._wis, data._cha) = _attr.ability_scores(_s);
    }

    function itemIsTransferred(uint _i) public view returns(bool _transferred) {
        (,,,,address _minter) = _items1.items(_i);
        address _owner = _items1.ownerOf(_i);
        return _owner != _minter;
    }

    function itemServiceData(uint _i) public view returns (rl._item_service_data memory data) {
        uint8 _base_type;
        (_base_type, data.item_type,,, ) = _items1.items(_i);
        data.base_type = _items1.get_type(_base_type);

        if (_base_type == 1) {
            (, data.gold_cost, data.weight, data.name, data.description) = _goods.item_by_id(data.item_type);
        } else if (_base_type == 2) {
            uint _proficiency;
            
            (, data.gold_cost, _proficiency, data.weight, data.armor_bonus, data.max_dex_bonus,,,,) = _armor.item_by_id(data.item_type);
            (,,,,,, data.penalty, data.spell_failure, data.name, data.description) = _armor.item_by_id(data.item_type);

            data.proficiency = _armor.get_proficiency_by_id(_proficiency);
        } else if (_base_type == 3) {
            codex_items_weapons.weapon memory _weapon = _weapons.item_by_id(data.item_type);
            data.gold_cost = _weapon.cost;
            data.proficiency = _weapons.get_proficiency_by_id(_weapon.proficiency);
            data.encumbrance = _weapons.get_encumbrance_by_id(_weapon.encumbrance);
            data.damage_type = _weapons.get_damage_type_by_id(_weapon.damage_type);
            data.weight = _weapon.weight;
            data.damage = _weapon.damage;
            data.critical = _weapon.critical; 
            data.critical_modifier = _weapon.critical_modifier;
            data.range_increment = _weapon.range_increment;
            data.name = _weapon.name;
            data.description = _weapon.description;
        } 
    }
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