// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./rarityNamesRelated.sol";

contract rarity_names is ERC721Enumerable {
    uint private next_name = 1;//序号1，不存在的名称会引用0对应的值为空

    rarity_manifested constant _rm = rarity_manifested(0x9d1aFD46058E553EC134b5c90E4cE67CFd905111);
    // rarity_gold constant _gold = rarity_gold(0x8668caf01a46659173828A2BDC17767fDc6723b6);

    // uint public immutable NAME_AUTHORITY = 1672924;
    // uint public immutable KEEPER = 1672965;
    // uint public immutable NAME_GOLD_PRICE = 200e18;

    // 第一个召唤师角色名称
    string author_name;
    string lower_author_name;
    mapping(uint => string) public names;  // token => name
    mapping(uint => uint) public summoner_to_name_id; // summoner => token
    mapping(uint => uint) public name_id_to_summoner; // token => summoner
    mapping(string => bool) private _is_name_claimed;

    event NameClaimed(address indexed owner, uint indexed summoner, string name, uint name_id);
    event NameUpdated(uint indexed name_id, string old_name, string new_name);
    event NameAssigned(uint indexed name_id, uint indexed previous_summoner, uint indexed new_summoner);

    constructor() ERC721("Shang Hai Ching Names", "SHCN") {
        author_name = "SHC MASTER";
        names[0] = author_name;
        summoner_to_name_id[0] = 0;
        name_id_to_summoner[0] = 0;
        
        lower_author_name = to_lower(names[0]);
        _is_name_claimed[lower_author_name] = true;
    }

    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return _rm.getApproved(_summoner) == msg.sender || _rm.ownerOf(_summoner) == msg.sender;
    }

    function summoner_name(uint summoner) public view returns (string memory name){
        uint name_id = summoner_to_name_id[summoner];
        // 过滤非首个召唤师的默认名称
        if (name_id == 0 && summoner != 0) {
            name = "";
        } else {
            name = names[summoner_to_name_id[summoner]];
        }
    }

    function is_name_claimed(string memory name) external view returns(bool is_claimed) {
        is_claimed = _is_name_claimed[to_lower(name)];
    }

    // @dev Claim a name for a summoner. Summoner must hold the required gold.
    // 声明一个名称 金币、付费验证去除
    function claim(string memory name, uint summoner) public returns (uint name_id){
        require(_isApprovedOrOwner(summoner), '!owner');
        require(validate_name_v1(name), 'invalid name');
        string memory lower_name = to_lower(name);
        require(!_is_name_claimed[lower_name], 'name taken');
        // _gold.transferFrom(NAME_AUTHORITY, summoner, KEEPER, NAME_GOLD_PRICE);
        _mint(msg.sender, next_name);
        name_id = next_name;
        next_name++;
        names[name_id] = name;
        _is_name_claimed[lower_name] = true;
        assign_name(name_id, summoner);
        emit NameClaimed(msg.sender, summoner, name, name_id);
    }

    /**
     * 命名或修改名称，不开放修改public
     */
    function clain_or_update(string memory name, uint summoner) private returns (uint name_id_old) {
        if (summoner_to_name_id[summoner] <= 0) {
            claim(name, summoner);
        } else {
            require(_isApprovedOrOwner(summoner), '!owner');
            require(validate_name(name), 'invalid name');
            string memory lower_name = to_lower(name);
            require(!_is_name_claimed[lower_name], 'name taken');
            
            // 先清除旧名称
            name_id_old = summoner_to_name_id[summoner];
            string memory name_old = to_lower(names[name_id_old]);
            _is_name_claimed[name_old] = false;
            // clear_summoner_name(summoner);

            // 更新名称，名称ID不变
            names[name_id_old] = name;
            _is_name_claimed[lower_name] = true;

            // 更新完成返回跟命名相同的事件
            emit NameClaimed(msg.sender, summoner, name, name_id_old);
        }
    }

    /**
     * 将名称ID指派给另一个召唤师ID角色
     */
    // @dev Move a name to a (new) summoner
    function assign_name(uint name_id, uint to) private {
        require(to > 0, "sorry summoner 0");
        require(_isApprovedOrOwner(msg.sender, name_id), "!owner or approved name");
        require(_isApprovedOrOwner(to), "!owner or approved to");
        require(summoner_to_name_id[to] == 0, "to already named");
        uint from = name_id_to_summoner[name_id];
        if (from > 0) {
            summoner_to_name_id[from] = 0;
        }
        summoner_to_name_id[to] = name_id;
        name_id_to_summoner[name_id] = to;
        emit NameAssigned(name_id, from, to);
    }

    /**
     * 清除名称ID 暂不开放 public
     */
    // @dev Unlink a name from a summoner without transferring it.
    //      Use move_name to reassign the name.
    function clear_summoner_name(uint summoner) private {
        uint name_id = summoner_to_name_id[summoner];
        require(_isApprovedOrOwner(summoner) || _isApprovedOrOwner(msg.sender, name_id), "!owner or approved");
        summoner_to_name_id[summoner] = 0;
        name_id_to_summoner[name_id] = 0;
        emit NameAssigned(name_id, summoner, 0);
    }

    // @dev Change the capitalization (as it is unique).
    //      Can't change the name.
    function update_capitalization(uint name_id, string memory new_name) private {
        require(_isApprovedOrOwner(msg.sender, name_id), "!owner or approved name");
        require(validate_name(new_name), 'invalid name');
        string memory name = names[name_id];
        require(keccak256(abi.encodePacked(to_lower(name))) == keccak256(abi.encodePacked(to_lower(new_name))), 'name different');
        names[name_id] = new_name;
        emit NameUpdated(name_id, name, new_name);
    }

    // @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
    function validate_name(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 last_char = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];
            if (char == 0x20 && last_char == 0x20) return false; // Cannot contain continous spaces
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            last_char = char;
        }

        return true;
    }

    function validate_name_v1(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 18) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if(b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 last_char = b[0];

        for(uint i; i < b.length; i++){
            bytes1 char = b[i];
            if (char == 0x20 && last_char == 0x20) return false; // Cannot contain continous spaces
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) && //space
                !(char >= 0x80) //中文
            )
                return false;

            last_char = char;
        }
        return true;
    }
    
    function validate_name_test(string memory str) public pure returns (bytes memory, uint, bool, bytes1){
        bytes memory b = bytes(str);
        if(b.length < 1) return (b, b.length, false, 0);
        if(b.length > 12) return (b, b.length, false, 0); // Cannot be longer than 25 characters
        if(b[0] == 0x20) return (b, b.length, false, 0); // Leading space
        if(b[b.length - 1] == 0x20) return (b, b.length, false, 0); // Trailing space

        bytes1 last_char = b[0];

        bytes1 char;
        for(uint i; i < b.length; i++){
            char = b[i];
            if (char == 0x20 && last_char == 0x20) return (b, b.length, false, char); // Cannot contain continous spaces
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) && //space
                !(char >= 0x80) //中文
            )
                return (b, b.length, false, char);

            last_char = char;
        }
        return (b, b.length, true, char);
    }



    // @dev Converts the string to lowercase
    function to_lower(string memory str) public pure returns (string memory){
        bytes memory b_str = bytes(str);
        bytes memory b_lower = new bytes(b_str.length);
        for (uint i = 0; i < b_str.length; i++) {
            // Uppercase character
            if ((uint8(b_str[i]) >= 65) && (uint8(b_str[i]) <= 90)) {
                b_lower[i] = bytes1(uint8(b_str[i]) + 32);
            } else {
                b_lower[i] = b_str[i];
            }
        }
        return string(b_lower);
    }

    function tokenURI(uint name_id) public override view returns (string memory output) {
        uint summoner = name_id_to_summoner[name_id];
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        if (summoner > 0) {
            output = string(abi.encodePacked(output, "Level ", toString(_rm.level(summoner)), ' ', _rm.classes(_rm.class(summoner)), '</text><text x="10" y="40" class="base">'));
        }
        output = string(abi.encodePacked(output, names[name_id], '</text></svg>'));
        output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "', names[name_id], '", "description": "Rarity ERC721 names for summoners.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))))));
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