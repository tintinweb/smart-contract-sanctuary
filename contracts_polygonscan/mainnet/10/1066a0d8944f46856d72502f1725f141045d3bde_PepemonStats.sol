/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
contract Context {

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor ()  {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        require (account != address(this));
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract PepemonStats is WhitelistAdminRole{
    
    struct BattleCardStats {
        uint16 element;
        uint16 hp;
        uint16 speed;
        uint16 intelligence;
        uint16 defense;
        uint16 attack;
        uint16 specialAttack;
        uint16 specialDefense;
    }

    struct SupportCardStats {
        bytes32 currentRoundChanges;
        bytes32 nextRoundChanges;
        uint16 modifierNumberOfNextTurns;
        uint240 specialCode;
    }
    
    struct elementWR{
        uint16 weakness;
        uint16 resistance;
    }

    mapping(uint => BattleCardStats) public battleCardStats;
    mapping(uint => SupportCardStats) public supportCardStats;
    mapping (uint16 => string) public elementDecode;
    mapping (uint16 => elementWR) public weakResist;
    
    constructor(){
        elementDecode[1]="Fire";
        elementDecode[2]="Grass";
        elementDecode[3]="Water";
        elementDecode[4]="Lighting";
        elementDecode[5]="Wind";
        elementDecode[6]="Poison";
        elementDecode[7]="Ghost";
        elementDecode[8]="Fairy";
        elementDecode[9]="Earth";
        elementDecode[10]="Unknown";
        weakResist[1] = elementWR(3,2);
        weakResist[2] = elementWR(1,3);
        weakResist[3] = elementWR(4,1);
        weakResist[4] = elementWR(9,5);
        weakResist[5] = elementWR(6,9);
        weakResist[6] = elementWR(8,2);
        weakResist[7] = elementWR(8,6);
        weakResist[8] = elementWR(7,8);
        weakResist[9] = elementWR(2,7);
        weakResist[10] = elementWR(0,0);
    }
    
    function setBattleCardStats(uint id, BattleCardStats calldata x) public onlyWhitelistAdmin{
        battleCardStats[id] = x;
    }
    function setSupportCardStats(uint id, SupportCardStats calldata x) public onlyWhitelistAdmin{
        supportCardStats[id] = x;
    }
    function setWeakResist(uint16 element, elementWR calldata x) public onlyWhitelistAdmin{
        weakResist[element] = x;
    }
    function setElementDecode(uint16 element, string calldata x) public onlyWhitelistAdmin{
        elementDecode[element] = x;
    }
    
    //Pos 0-7 = hp, spd, int, def, atk, sp atk, sp def
    //Pos 8-13 = same but for opponent
    function deconvert(bytes32 num) public pure returns(int16[14] memory){
        int16[14] memory arr;
        for (uint i =0 ; i < 14; i++){
            arr[i] = int16(uint16(bytes2(num << 240))); 
            num = num >> 16;
        } 
        return arr;
    }
    
    function convert(int16[14] calldata arr) public pure returns (bytes32){
        bytes32 num;
        for (uint i = 0 ; i < 14; i++ ){
            num |= (bytes32(uint256(uint16(arr[i])))<<(16*i));
        }
        return num;
    }
    
}