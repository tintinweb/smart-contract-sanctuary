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
        uint16 battleType;
        uint16 hp;
        uint16 speed;
        uint16 intelligence;
        uint16 defense;
        uint16 attack;
        uint16 specialAttack;
        uint16 specialDefense;
    }

    struct SupportCardStats {
        uint16 supportType;
        int16[7] changesThisRound;
        int16[7] opponentPepemonChangesThisRound;
        int16[7] changesNextRound;
        int16[7] opponentPepemonChangesNextRound;
        uint16 modifierNumberOfNextTurns;
        uint32 specialCode;
    }

    mapping(uint => BattleCardStats) public battleCardStats;
    mapping(uint => SupportCardStats) public supportCardStats;
    
    function setBattleCardStats(uint id, BattleCardStats calldata x) public onlyWhitelistAdmin{
        battleCardStats[id] = x;
    }
    function setSupportCardStats(uint id, SupportCardStats calldata x) public onlyWhitelistAdmin{
        supportCardStats[id] = x;
    }
    
}