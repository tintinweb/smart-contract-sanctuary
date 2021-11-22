/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRarity {
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function ownerOf(uint _summoner) external view returns (address);
}

interface IRarityName {
    function summoner_name(uint summoner) external view returns (string memory name);
}

contract rarity_extended_name {
    IRarity constant _rm = IRarity(0xb5A78f79384612510EcE6822d67575e6b937B29c);
    IRarityName constant _rarity_names_unique = IRarityName(0x9533c9F78117F4CF196c05Ddb1b7e547cA249047);
    string constant public name = "Rarity Extended Name";
    mapping(uint => string) private adventurers_name;
    mapping(uint => bool) private name_is_set;

    event NameSet(uint indexed summoner, string name);
    event NameUnset(uint indexed summoner);

    /**
    **  @dev Check if the msg.sender has the autorization to act on this adventurer
    **	@param _adventurer: TokenID of the adventurer we want to check
    **/
    function _isApprovedOrOwner(uint _adventurer) internal view returns (bool) {
        return (_rm.getApproved(_adventurer) == msg.sender || _rm.ownerOf(_adventurer) == msg.sender || _rm.isApprovedForAll(_rm.ownerOf(_adventurer), msg.sender));
    }

    /**
    **  @dev set the name of an adventurer
    **  @param _adventurer tokenID of the adventurer to assign a name to
    **  @param _name name to assign to this adventurer
    */
    function set_name(uint _adventurer, string memory _name) external {
        require(_isApprovedOrOwner(_adventurer));
        require(validate_name(_name), 'invalid name');
        adventurers_name[_adventurer] = _name;
        name_is_set[_adventurer] = true;
        emit NameSet(_adventurer, _name);
    }

    /**
    **  @dev unset the name of an adventurer
    **  @param _adventurer tokenID of the adventurer to unset a name to
    */
    function unset_name(uint _adventurer) external {
        require(_isApprovedOrOwner(_adventurer));
        adventurers_name[_adventurer] = '';
        name_is_set[_adventurer] = false;
        emit NameUnset(_adventurer);
    }
    
    /**
    **  @dev get the different parts of the name of the adventurer
    **  @param _adventurer tokenID of the adventurer to get name of
    */
    function get_name(uint _adventurer) public view returns (string memory) {
        if (name_is_set[_adventurer])
            return (adventurers_name[_adventurer]);
        return _rarity_names_unique.summoner_name(_adventurer);
    }

    /**
    **  @dev Check if the name string is valid (Alpha, spaces and -, without leading or trailing space)
    **  @param str string to check
    */
    function validate_name(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        //between 1 & 25 char, not starting or ending by space or `-`
        if (b.length < 1 || b.length > 25 || b[0] == 0x20 || b[b.length - 1] == 0x20 || b[0] == 0x2D || b[b.length - 1] == 0x2D)
            return false;
        

        bytes1 last_char = b[0];

        for (uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && last_char == 0x20)
                return false; // Cannot contain continous spaces
            if (char == 0x2D && last_char == 0x2D)
                return false; // Cannot contain continous -
            if (char == 0x20 && last_char == 0x2D)
                return false; // Cannot contain space before -
            if (char == 0x2D && last_char == 0x20)
                return false; // Cannot contain - after space

            if (
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) && //space
                !(char == 0x2D) //-
            )
                return false;

            last_char = char;
        }

        return true;
    }
}