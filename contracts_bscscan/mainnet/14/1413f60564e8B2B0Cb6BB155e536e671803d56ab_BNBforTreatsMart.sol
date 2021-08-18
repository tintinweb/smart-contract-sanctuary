/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

pragma solidity ^0.5.0;


/**
                                  ▄▄▄▄       ░
                              ▄▄██▓▓▓███▄ ▀▀▄▓▄▄▄▀▀▀ ▀
              ▀ ▄▄         ▄██▓▓░░░░▓▓▓▓▓██▄ ▀  ▄▄▄██████▄▄▄▄▄
              ▄▀░ ▀▄     ▄█▓▓▓░░░  ░░░░░░░▓▓█▄██▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓░ ░
              █   ▓█   ▄█▓▓▓░░░      ░░░░▓▓██▓▓▓▓░░░░░░░░░░░░▓▓▓██
               ▀▄▓▀   █▓▓▓░░░         ░░░▓█▓▓▓░░░░░       ░░▓▓▓██  ▄
                   ▄▄█▓▓░░░         ░ ░░▓█░░░░░░     ░░░░▓▓▓████▄ ▀▓▀
              ▄▄███▓▓▓░░░            ░░▓▓▓░            ░░░░░▓▓████▄
              ▀▀█▓▓▓░░░          ░  ░░░▓█▓░░               ░░░▓▓███▄
      ▄▓▄      ░▄█▓░░   ░      ░  ░░░▓▓██▓▓░░░         ░░░   ░░░▓▓▓██
       ▀    ▄▄██▓▓▓░  ░░      ░▓░░░▓█████▓░░░░░          ░░░   ░░░░▓██
  ▄▀▀▄   ▄██▓▓▓░░░▓░░  ░       ░▓▓██▓▓▓▓█▓▓░░               ░    ░░░▓██
  █ ▓█  ██▓▓░░░░ ░░▓░         ░▓██▓░░░░▓▓█▓▓░░                    ░░░▓██▄
   ▀▀  ██▓░░░     ░░░      ░░░▓█▓░░ ░  ░ ▓█▓▓░░░                   ░░░▓███▄▄
      ██▓░   ░  ░   ░░      ░▓█░░  ░  ░ ░ ░▀█▓▓▓░░░░            ░░░░░▓▓▓██▀
    ▄██▓▓▓▓░░    ░░  ░░    ░▓█░░ ░       ░ ░ █▀██▓▓░░░░░░░░   ░░░▓▓▓▓▓▓██
    ▀▀▀████▓▓░░      ░    ░▓█▓░ ░       ░ ░   ░ ░███▓▓▓▓▓▓░░░   ░░░▓▓██▀
     ▄ ░██▓▓░       ░    ░▓██▓█▄       ░▄██▀▀▄   ░▓▓█████▓▓▓░░   ░░░▓▓██░  ▄▄
    ▀▓▀ ██▓░             ░▓█▓▓▄█▓     ░█░█▓▓  ▄ ░ ░▓▓███▓▓▓▓▓░░   ░░▓▓▓█▓ █ ▓█
        ░█▓░             ░▓█▓░▀        ▀▀██▄▀     ░░███▓▓░░░░▓░    ░░▓▓██  ▀▀
     ░ ░▓█▓░            ░▓█▓░ ░    █             ░░░▓██▓░░  ░░░     ░░▓▓█  ▄▓▄
  ▄▄   ██▓░░            ░▓█▓ ░   ▄█░          ░ ░ ░▓▓█▓▓░   ░      ░░░▓▓▓█  ▀
 █ ▓█ ██▓░░            ░░▓█░░     ▀▀           ░░░░▓██▓░░            ░░░░▓█
  ▀▀  █▓░░     ░    ░░░▓▓▓██░                   ░░▓█▓▓▓░           ░   ░░░▓█
     ██▓░░     ░      ░░░▓▓██░               ░ ░░▓██▓░░           ░   ░░░░▓▓█
  ▄  █▓░░     ░░░░     ░░░▓▓█▓░  ▀█▓▄         ░▓███▓░░               ░░▓░░▓▓██
    ██▓░      ░░▓░░░ ░░ ░░░░▓█▄            ░▓██████▓░░   ░            ▓█▓▓▓▓██
    █▓░░     ░░▓▓▓▓░░░░░░░░░░▓██▄        ▄▄█▀▓▓███▓░░     ▓░ ░░░░░░   ░▓██▓▓█
   ██▓░  ░  ░▓▓▓██▓▓▓▓▓▓▓▓▓░░░▓▓███▄▄▄▀▀▀  ░░░▓▓██▓░░░ ░   █▓▓▓▓▓▓░░░░ ░▓████
   █▓░░    ░░░▓████████████▓▓▓████▓░         ░▓██▓░░░░░░   ░███████▓▓░░ ░▓██
  ██▓░     ░░▓██▓▓▓░░░░░░░░███████▄    ░    ░░▓█▓▓▓▓▓▓▓░░  ░██▓▓▓▓▓██▓░░░▓██
  ██▓░░ ░░ ░▓██▓░░░░░         ░░░▓▓▀        ░░▀████▀▀▀█▓▓░  ▓█░░░▓▓▓▓█▓░░▓██
   ██▓░░▓▓░▓██▓░░            ▄▄▄                       ▀█▓ ░▓█░ ░░░▓▓██░▓███
    ██▓▓▓█▓▓█▓░░        ▄▄▀▀▀ ░░▓▄  ▄    ▄  ▄▓▀▀▄▄      ▀█▓█▀ ░  ░░▓▓▓█▓▓██  ▀
     ▀██▓▓██▓▓░░                 ░▀▀      ▀▀░     ▀▀░    █▀       ░░▓▓█▓▓██
       ▀████▓░░     ░                                    ▓        ░░▓▓█▓██
     ▄    ▓█▓░░    ░▓                                   ░     ░   ░░▓█▓██  ▄▓▄
          ░█▓▓░   ░▓█▄░                                      ░     ░▓███    ▀
     ▄▀▀▄  ░█▓░░ ░▓▓█░                                      ░▓     ░▓██ ▄▀▀▄
    █ ░ ▓█  █▓░░░▓▓█░                    ░                 ░▓▓    ░░▓██ ▀▄▓▀
     ▀▄▓▀   ▓█▓░▓██░░░░         ░        ░  ░░            ▄▓█░    ░▓▓█▓█    ▄▄
        ▄▓▄ ░█▓██▓░░░            ░     ░░▓░░░   ░░░░      ░█▓░    ░▓█▓░▓█▄▄█▓█
         ▀   ██▓▓░░               ░░▄ ░▓▓█░▓░░░░░         ░█▓░    ░▓█░ ░░▓▓▓▓█
  ▄░▀▀▀▄    ██▓▓░░                 ░▓██▓███▓▓░░░        ░░▓▓█░    ░▓█▓   ░░▓█
 █░░  ░▓█   █▓▓░░  ▄░              ░░▓████▓▓░░░          ░░▓█▓░   ░▓██▓░░░▓█
 █░   ░▓█  ██▓▓░  █░ ▄▄  ▄          ░░▓██▓▓░░░            ░▓█▓░   ░▓███▓▓█▀
  ▀▄▄▓▓▀   █▓▓░░ █░ █▓░█ ░█          ░▓██▓▓░░░            ░▓▓█▓░  ░▓██▓▀▀
          ██▓▓░░ █▓  ░▀  ▓█         ░░▓▓█▓▓░░░            ░░▓▓█░  ░▓█▓░     ▄▓▄
          █▓▓▓░░  ▀▓▄▄▄▄▓▀          ░░▓▓█▓▓░░             ░░░▓▓█░ ░░▓█░      ▀
     ▀    ██▓▓░░░                  ░░▓▓██▓▓░░              ░░▓▓█▓  ░▓█
          ▀█▓▓░░░                 ░░░▓▓██▓▓░░              ░░░▓▓█░ ░▓█░   ▀
       ▄▓▄ █▓▓▓░░░              ░░░░▓▓▓█▓▓▓░░               ░░▓▓█░ ░▓█
        ▀  ▀█▓▓▓░░░░       ░░░░░░▓▓▓▓▓██▓▓░░░       ▄▓▓░     ░░▓▓█░░▓█  ▄▄
     ▄▄▄    ▀█▓▓▓▓░░░░░░░░▓▓███████▓▓██▓▓▓░░       █▓        ░░▓▓█░░▓█ █ ▓█
   ▄▓░  ▀▄   ▀██▓▓▓░░░▓▓█▀▀▀░░░░▓▓█████▓▓░░░      █▓░ ▄▄     ░▓▓▓█░░▓█  ▀▀
  █▓░    ░█    ███▓▓▓███░       ░░░████▓▓░░░      █▓  ▄▓█   ░░░▓██ ░░▓█
  █░    ░▓█     ███▀█████▄▄▄███▄  ░░▓██▓▓░░░       █░  ▀  █ ░░▓▓█░  ░▓█  ▄▀▀▀▄
   ▀▄ ░░▓▀    ▄ ▓█▓░░▓██████▓▓▓██  ░░▓██▓▓░░░       ▀▓▓▄▄▀  ░░▓██░ ░▓▓█ █ ░ ░▓█
     ▀▀▀         ▀█▀▄░░░▓████▓██▓   ░▓██▓▓░░░░             ░░▓██▓░░▓▓██  ▀▄▄▓▀
            ▄░▀▄  ▀▄ ▀▄░░░░▀▀▀▀░  ░░░▓▓██▓▓▓░░░░       ░ ░░▓▓██▓▓▓███▀
           █  ░▓█   ▀▄ ▀▀▄▄     ░░░▓███▀███▓▓▓▓░░░░░░░░░░▓▓██████▀▀▀  ▄▓▄
            ▀░▓▀      ▀▀▄▄  ░░░▓▓██▀▀    ▀███▓▓▓▓▓▓░░░▓▓▓██▀▀          ▀
                  ▄      ▀▀█▀▀▀▀▀█   ▄▄▄    ▀▀██████████▀▀    ▀  ▄▓▄
                           █             ▄▓▄      █        ▀      ▀
   ▄▓▄            ▄▄  ▀▄▄▄▄ ▀▄  ▄▓▓██▄▄■  ▀    ▄▄██▄    ▀     ▄▄███   ░░░  ▀    ▄▄▄▄         
    ▀   ▄▄                                                                     ▄▀░   ▓▄  
       █ ▓█     /$$$$$$$$ /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$              █ ░   ░▓█ 
        ▀▀     |__  $$__/| $$__  $$| $$_____/ /$$__  $$|__  $$__/          ▄▄  █    ░▓▓█ 
  ▄░▀▀▀▄          | $$   | $$  \ $$| $$      | $$  \ $$   | $$   ░        █ ▓█  ▀▄░░▓█▀
 █░   ░░█         | $$   | $$$$$$$/| $$$$$   | $$$$$$$$   | $$    ▄██      ▀▀    ▀▀▀▀  ▄ 
 █    ░▓█         | $$   | $$__  $$| $$__/   | $$__  $$   | $$   ████▓▄    
  ▀▄▄▓▓▀          | $$   | $$  \ $$| $$      | $$  | $$   | $$   ███▓▓▌   ▄▓▄ 
  ░ ░             | $$   | $$  | $$| $$$$$$$$| $$  | $$   | $$        ▀
  ░ ░ ▀ ▄▓▄       |__/   |__/  |__/|________/|__/  |__/   |__/   ▄   
  ░ ░ ▄▄ ▀  █▀▀▀▀   ▀▀▀█▄▄▄▄█     ▄▀▀▀   ░            ▀▀ █   ▄ ▀      █    ▄▄ 
  ░ ░█ ▓█   █                                                         █   █ ▓█ 
  ░ ░ ▀▀  ▄ █                  bnb your self a treat                  █    ▀▀
  ░ ░ ░    ██▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▀▄
  ░ ░ ░   ■ █▀                                                        █
  ░ ░ ░                                                             



 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface TREATcontract {
    function balanceOf(address _owner) external view returns (uint256);
}


/**
interface TreatNFTMinter {
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function create(uint256 _maxSupply, uint256 _initialSupply, string calldata _uri, bytes calldata _data, address _performerAddress) external returns (uint256 nftId);
    function mint(address _to, uint256 _id, uint256 _quantity, bytes calldata _data) external;
    function totalSupply(uint256 _id) external view returns (uint256);
    function maxSupply(uint256 _id) external view returns (uint256);
    function creators(uint256 nftId) external view returns (address payable);
    function referrers(address treatModel) external view returns (address payable);
    function isPerformer(address account) external view returns (bool);
}
*/


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

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
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

    constructor () internal {
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

/**
 * @title PerformerRole
 * @dev Performers are responsible for creating their own nfts.
 */
contract PerformerRole is Context {
    using Roles for Roles.Role;

    event PerformerAdded(address indexed account);
    event PerformerRemoved(address indexed account);

    Roles.Role private _performers;

    constructor () internal {
        _addPerformer(_msgSender());
    }

    modifier onlyPerformer() {
        require(isPerformer(_msgSender()), "PerformerRole: caller does not have the Performer role");
        _;
    }

    function isPerformer(address account) public view returns (bool) {
        return _performers.has(account);
    }

    /*function addPerformer(address account) public onlyWhiteListAdmin {
        _addPerformer(account);
    }*/

    function renouncePerformer() public {
        _removePerformer(_msgSender());
    }

    function _addPerformer(address account) internal {
        _performers.add(account);
        emit PerformerAdded(account);
    }

    function _removePerformer(address account) internal {
        _performers.remove(account);
        emit PerformerRemoved(account);
    }
}

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

}

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

interface IERC1155 {
    // Events

    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

    /**
     * @dev MUST emit when an approval is updated
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev MUST emit when the URI is updated for a token ID
     *   URIs are defined in RFC 3986
     *   The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema"
     */
    event URI(string _amount, uint256 indexed _id);

    /**
     * @notice Transfers amount of an _id from the _from address to the _to address specified
     * @dev MUST emit TransferSingle event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @dev MUST emit TransferBatch event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if length of `_ids` is not the same as length of `_amounts`
     * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @dev MUST emit the ApprovalForAll event on success
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);

}

/**
 * Copyright 2018 ZeroEx Intl.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * Utility library of inline functions on addresses
 */
library Address {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

}

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165 {
    using SafeMath for uint256;
    using Address for address;


    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // onReceive function signatures
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Objects balances
    mapping (address => mapping(uint256 => uint256)) internal balances;

    // Operator Functions
    mapping (address => mapping(address => bool)) internal operators;

    // Events
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _uri, uint256 indexed _id);


    /***********************************|
    |     Public Transfer Functions     |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public
    {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
        require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
        // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, _data);
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public
    {
        // Requirements
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
        require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
    }


    /***********************************|
    |    Internal Transfer Functions    |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     */
    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
    {
        // Update balances
        balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
        balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
     */
    function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
    {
        // Check if recipient is contract
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
            require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
        }
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     */
    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
    {
        require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfer; i++) {
            // Update storage balance of previous bin
            balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
     */
    function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
    {
        // Pass data if recipient is contract
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
            require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
        }
    }


    /***********************************|
    |         Operator Functions        |
    |__________________________________*/

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved)
    external
    {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
    public view returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }


    /***********************************|
    |         Balance Functions         |
    |__________________________________*/

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
    public view returns (uint256)
    {
        return balances[_owner][_id];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public view returns (uint256[] memory)
    {
        require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }


    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

    /**
     * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
     */
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /**
     * INTERFACE_SIGNATURE_ERC1155 =
     * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
     * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
     * bytes4(keccak256("balanceOf(address,uint256)")) ^
     * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
     * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
     * bytes4(keccak256("isApprovedForAll(address,address)"));
     */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceID  The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `_interfaceID` and
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
            return true;
        }
        return false;
    }

}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {

    // URI's default URI prefix
    string internal baseMetadataURI;
    event URI(string _uri, uint256 indexed _id);


    /***********************************|
    |     Metadata Public Function s    |
    |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     *      Token IDs are assumed to be represented in their hex format in URIs
     * @return URI string
     */
    function uri(uint256 _id) public view returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
    }


    /***********************************|
    |    Metadata Internal Functions    |
    |__________________________________*/

    /**
     * @notice Will emit default URI log event for corresponding token _id
     * @param _tokenIDs Array of IDs of tokens to log default URI
     */
    function _logURIs(uint256[] memory _tokenIDs) internal {
        string memory baseURL = baseMetadataURI;
        string memory tokenURI;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
            emit URI(tokenURI, _tokenIDs[i]);
        }
    }

    /**
     * @notice Will emit a specific URI log event for corresponding token
     * @param _tokenIDs IDs of the token corresponding to the _uris logged
     * @param _URIs    The URIs of the specified _tokenIDs
     */
    function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
        require(_tokenIDs.length == _URIs.length, "ERC1155Metadata#_logURIs: INVALID_ARRAYS_LENGTH");
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            emit URI(_URIs[i], _tokenIDs[i]);
        }
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }


    /***********************************|
    |    Utility Internal Functions     |
    |__________________________________*/

    /**
     * @notice Convert uint256 to string
     * @param _i Unsigned integer to convert to string
     */
    function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 ii = _i;
        uint256 len;

        // Get number of bytes
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;

        // Get each individual ASCII
        while (ii != 0) {
            bstr[k--] = byte(uint8(48 + ii % 10));
            ii /= 10;
        }

        // Convert to string
        return string(bstr);
    }

}

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {


    /****************************************|
    |            Minting Functions           |
    |_______________________________________*/

    /**
     * @notice Mint _amount of tokens of a given id
     * @param _to      The address to mint tokens to
     * @param _id      Token id to mint
     * @param _amount  The amount to be minted
     * @param _data    Data to pass if receiver is contract
     */
    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
    {
        // Add _amount
        balances[_to][_id] = balances[_to][_id].add(_amount);

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
    }

    /**
     * @notice Mint tokens for each ids in _ids
     * @param _to       The address to mint tokens to
     * @param _ids      Array of ids to mint
     * @param _amounts  Array of amount of tokens to mint per id
     * @param _data    Data to pass if receiver is contract
     */
    function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
    {
        require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

        // Number of mints to execute
        uint256 nMint = _ids.length;

        // Executing all minting
        for (uint256 i = 0; i < nMint; i++) {
            // Update storage balance
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        // Emit batch mint event
        emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

        // Calling onReceive method if recipient is contract
        _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, _data);
    }


    /****************************************|
    |            Burning Functions           |
    |_______________________________________*/

    /**
     * @notice Burn _amount of tokens of a given token id
     * @param _from    The address to burn tokens from
     * @param _id      Token id to burn
     * @param _amount  The amount to be burned
     */
    function _burn(address _from, uint256 _id, uint256 _amount)
    internal
    {
        //Substract _amount
        balances[_from][_id] = balances[_from][_id].sub(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
    }

    /**
     * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
     * @param _from     The address to burn tokens from
     * @param _ids      Array of token ids to burn
     * @param _amounts  Array of the amount to be burned
     */
    function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
    {
        require(_ids.length == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

        // Number of mints to execute
        uint256 nBurn = _ids.length;

        // Executing all minting
        for (uint256 i = 0; i < nBurn; i++) {
            // Update storage balance
            balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
        }

        // Emit batch mint event
        emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
    }

}

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable, MinterRole, WhitelistAdminRole, PerformerRole {
    using Strings for string;

    address proxyRegistryAddress;
    uint256 private _currentTokenID = 0;
    mapping(uint256 => address payable) public creators;
    mapping(address => address payable) public referrers;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function addPerformer(address account) public onlyWhitelistAdmin {
        _addPerformer(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function removePerformer(address account) public onlyOwner {
        _removePerformer(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function uri(uint256 _id) public view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @param _performerAddress If Treat creates the NFT Treat must set the Performer Address
     * @return The newly created token ID
     */
    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data,
        address payable _performerAddress
    ) external onlyWhitelistAdmin returns (uint256 tokenId) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        creators[_id] = _performerAddress;
        return _id;
    }

    

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return The newly created token ID
     */
    function createTreat(
        uint256 _maxSupply,
        string calldata _uri,
        bytes calldata _data
    ) external onlyPerformer returns (uint256 tokenId) {
        require(0 < _maxSupply, "Max supply cannot be 0");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        tokenSupply[_id] = 0;
        tokenMaxSupply[_id] = _maxSupply;
        creators[_id] = msg.sender;
        return _id;
    }


    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyMinter {
        uint256 tokenId = _id;
        uint256 newSupply = tokenSupply[tokenId].add(_quantity);
        require(newSupply <= tokenMaxSupply[tokenId], "Max supply reached");
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }
}

/**
 * @title Treat
 */
contract TreatNFTMinterV2 is ERC1155Tradable {
    string private _contractURI;

    constructor(address _proxyRegistryAddress) public ERC1155Tradable("Treat NFT Minter", "TreatNFTMinter", _proxyRegistryAddress) {
        _setBaseMetadataURI("https://api.treatdao.com/treats/");
        _contractURI = "https://treatdao.com/api/treats-erc1155";
    }

    function setBaseMetadataURI(string memory newURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(newURI);
    }

    function setContractURI(string memory newURI) public onlyWhitelistAdmin {
        _contractURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function addTreatReferrer(address treatmodel, address payable referrer) public onlyWhitelistAdmin {
        referrers[treatmodel] = referrer;
    }

    function removeTreatReferrer(address treatmodel) public onlyWhitelistAdmin {
        referrers[treatmodel] = address(0);
    }

    /**
         * @dev Ends minting of token
         * @param _id          Token ID for which minting will end
         */
    function endMinting(uint256 _id) external onlyWhitelistAdmin {
        tokenMaxSupply[_id] = tokenSupply[_id];
    }

    /**
         * @dev Ends minting of token by Treat Performer
         * @param _id          Token ID for which minting will end
         */
    function endTreatMinting(uint256 _id) external onlyPerformer {
        require(creators[_id] == msg.sender);
        tokenMaxSupply[_id] = tokenSupply[_id];
    }

    function updateNftCreator(uint256 _id, address payable _creatorAddress) external onlyWhitelistAdmin {
        creators[_id] = _creatorAddress;
    }

    function burn(address _account, uint256 _id, uint256 _amount) public onlyMinter {
        require(balanceOf(_account, _id) >= _amount, "cannot burn more than address has");
        _burn(_account, _id, _amount);
    }

    /**
    * Mint NFT and send those to the list of given addresses
    */
    function airdrop(uint256 _id, address[] memory _addresses) public onlyMinter {
        require(tokenMaxSupply[_id] - tokenSupply[_id] >= _addresses.length, "cannot mint above max supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            mint(_addresses[i], _id, 1, "");
        }
    }
}

/** TREATEXCHANGE 1155 PROXY  0xb1A71cFF851607AD06ed7C924C48e07044826743
*/
interface TreatOfTheWeekMart {
    function nftCosts(uint256 nftId) external view returns (uint256);
    function isGiveAwayCard(uint256 _id) external view returns (bool);
}

contract BNBforTreatsMart is Ownable {
    using SafeMath for uint256;
    TreatNFTMinterV2 public treatNFTMinter;
    TreatOfTheWeekMart public totwMart;
    TREATcontract public treatDaoToken;
    uint256 public melonNumber;
    address payable public treatTreasuryAddress;
    mapping(uint256 => uint256) public nftCosts;
    mapping(uint256 => address) public treatModels;
    mapping(uint256 => uint256) public performerPercentages;
    mapping(uint256 => uint256) public refPercentages;
    mapping(uint256 => uint256) public refSetPercentages;
    mapping(uint256 => address payable) internal creatorOverrides;
    mapping(address => address payable) internal creatorRefOverrides;
    mapping(uint256 => bool) public isGiveAwayCard;
    address payable public tittyFundAddress;
    uint256 public maxSetId;
    uint256 public nftIdV2Start;
    uint256 public defaultCreatorPercentage;
    uint256 public defaultRefPercentage;
    uint256 public melonCreatorPercentage;
    uint256 public melonRefPercentage;
    bool public paused;
    bool public pausedTreats;
    mapping(uint256 => uint256[]) public nftSetIds;
    mapping(uint256 => uint256) public nftSetCosts;
    mapping(uint256 => address payable) public treatSetModels;
    mapping(uint256 => uint256) public performerSetPercentages;

    event NFTAdded(uint256[] nftIds, uint256 points, address treatModel);
    event NFTsAdded(uint256[] nftIds, uint256[] points, address treatModel);
    event NFTCreatedAndAdded(uint256[] nftIds, uint256[] points, bool[] isGiveAways, address treatModel);
    event SetAdded(uint256 indexed setId, uint256[] nftIds, uint256 points, address treatModel);
    event Redeemed(address indexed user, uint256 amount);
    event OnCreatorUpdated(address indexed oldAddress, address indexed newAddress);
    event OnCreatorRefUpdated(address indexed oldAddress, address indexed newAddress);

    constructor(TreatNFTMinterV2 _TreatNFTMinterAddress, address payable _TreatTreasuryAddress, address _treatDaoAddress, address _totwMartAddress) public {
        treatNFTMinter = _TreatNFTMinterAddress;
        totwMart = TreatOfTheWeekMart(_totwMartAddress);
        treatTreasuryAddress = _TreatTreasuryAddress;
        melonNumber = 734000000000000000000;
        defaultCreatorPercentage = 925;
        melonCreatorPercentage = 975;
        defaultRefPercentage = 200;
        melonRefPercentage = 400;
        nftIdV2Start = 92;
        treatDaoToken = TREATcontract(_treatDaoAddress);
        paused = false;
        pausedTreats = false;

        maxSetId = 0;
    }

    function createAndAddNFTs(uint256[] memory maxNftSupplys, uint256[] memory nftAmounts, bool[] memory isNotListedFlags, bytes memory _nftData) public returns (uint256[] memory nftIds) {
        require(treatNFTMinter.isPerformer(msg.sender) == true, "not performer role. cannot create nfts");
        require(pausedTreats == false, "Contract Paused");
        require(maxNftSupplys.length == nftAmounts.length, "NFT Supply and Price Arrays not equal len");
        require(maxNftSupplys.length == isNotListedFlags.length, "NFT Not Listed Arrays not equal len");
        uint256[] memory newNftIds = new uint256[](nftAmounts.length);
        bool[] memory newGiveAwayFlags = new bool[](nftAmounts.length);
        for (uint256 i = 0; i < nftAmounts.length; ++i) {
            newNftIds[i] = treatNFTMinter.create(maxNftSupplys[i],0,"",_nftData, msg.sender);
            nftCosts[newNftIds[i]] = nftAmounts[i];
            if(nftAmounts[i] == 0) {
                isGiveAwayCard[newNftIds[i]] = true;
                nftCosts[newNftIds[i]] = 0;
            }
            if(isNotListedFlags[i] == true) {
                isGiveAwayCard[newNftIds[i]] = false;
                nftCosts[newNftIds[i]] = 0;
            }
            treatModels[newNftIds[i]] = msg.sender;
            newGiveAwayFlags[i] = isGiveAwayCard[newNftIds[i]];
            performerPercentages[newNftIds[i]] = defaultCreatorPercentage;
            refPercentages[newNftIds[i]] = defaultRefPercentage;
        }
        emit NFTCreatedAndAdded(newNftIds, nftAmounts, newGiveAwayFlags, msg.sender);
        return newNftIds;
    }

    function addNFT(uint256[] memory nftIds, uint256[] memory amounts) public {
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(nftIds[i] >= nftIdV2Start, "cant list nft ids from v1 minter");
            require(msg.sender == treatNFTMinter.creators(nftIds[i]), "cannot list nfts you did not create");
            require(totwMart.nftCosts(nftIds[i]) == 0, "cannot list nfts in totw sale contract");
            require(totwMart.isGiveAwayCard(nftIds[i]) == false, "cannot list nfts in totw sale contract");
        }
        require(nftIds.length == amounts.length, "NFT Arrays not equal len");
        require(pausedTreats == false, "Contract Paused");
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(treatNFTMinter.maxSupply(nftIds[i]) > 0, "NFT doesn't exist");
            nftCosts[nftIds[i]] = amounts[i];
            isGiveAwayCard[nftIds[i]] = false;
            treatModels[nftIds[i]] = msg.sender;
            performerPercentages[nftIds[i]] = defaultCreatorPercentage;
            refPercentages[nftIds[i]] = defaultRefPercentage;
        }
        emit NFTsAdded(nftIds, amounts, msg.sender);
    }

    function addGiveAwayTreat(uint256[] memory nftIds) public {
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(nftIds[i] >= nftIdV2Start, "cant list nft ids from v1 minter");
            require(msg.sender == treatNFTMinter.creators(nftIds[i]), "cannot give away nft you did not create");
            require(totwMart.nftCosts(nftIds[i]) == 0, "cannot giveaway nfts in totw sale contract");
            require(totwMart.isGiveAwayCard(nftIds[i]) == false, "cannot giveaway nfts in totw sale contract");
        }
        require(pausedTreats == false, "Contract Paused");
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(treatNFTMinter.maxSupply(nftIds[i]) > 0, "NFT doesn't exist");
            isGiveAwayCard[nftIds[i]] = true;
            nftCosts[nftIds[i]] = 0;
            treatModels[nftIds[i]] = treatNFTMinter.creators(nftIds[i]);
        }
        emit NFTAdded(nftIds, 0, msg.sender);
    } 

    function addSet(uint256[] memory nftIds, uint256 _amount) public {
        for (uint256 i = 0; i < nftIds.length; ++i) {
            require(nftIds[i] >= nftIdV2Start, "cant list nft ids from v1 minter");
            require(msg.sender == treatNFTMinter.creators(nftIds[i]), "cannot add nfts to set you did not create");
            require(totwMart.nftCosts(nftIds[i]) == 0, "cannot list nfts in totw sale contract");
            require(totwMart.isGiveAwayCard(nftIds[i]) == false, "cannot list nfts in totw sale contract");
        }

        for(uint256 i = 0; i < nftIds.length; i++) {
            require(treatNFTMinter.maxSupply(nftIds[i]) > 0, "NFT doesn't exist");
        }

        require(pausedTreats == false, "Contract Paused");

        uint256 nextSetId = maxSetId.add(1);

        nftSetCosts[nextSetId] = _amount;
        nftSetIds[nextSetId] = nftIds;
        treatSetModels[nextSetId] = msg.sender;
        performerSetPercentages[nextSetId] = defaultCreatorPercentage;
        refSetPercentages[nextSetId] = defaultRefPercentage;

        maxSetId = nextSetId;

        emit SetAdded(nextSetId, nftIds, _amount, msg.sender);
    }

    function editSetCost(uint256 _setId, uint256 _newAmount) public {
        require(msg.sender == treatSetModels[_setId], "cannot edit set cost of set that is not yours");
        nftSetCosts[_setId] = _newAmount;
    }

    function getCreatedNFTsRange(uint256 startNftId, uint256 endNftId) public view returns (uint256[] memory createdNftIds, uint256[] memory listedNftCosts, bool[] memory isNftGiveAway) {
        require(endNftId > startNftId, "nft id range invalid");
        uint256 returnArrayLen = endNftId - startNftId + 1;
        uint256[] memory theNftIds = new uint256[](returnArrayLen);
        uint256[] memory theNftCosts = new uint256[](returnArrayLen);
        bool[] memory theNftGiveAwayFlags = new bool[](returnArrayLen);
        for(uint256 i = 0; i < returnArrayLen; i++) {
            theNftIds[i] = startNftId+i;
            theNftCosts[i] = nftCosts[startNftId+i];
            theNftGiveAwayFlags[i] = isGiveAwayCard[startNftId+i];
        }
        return (theNftIds, theNftCosts, theNftGiveAwayFlags);
    }

    function getListedCreatedNFTsRange(uint256 startNftId, uint256 endNftId) public view returns (uint256[] memory listedNftIds, uint256[] memory listedNftCosts, bool[] memory isNftGiveAway) {
        require(endNftId > startNftId, "nft id range invalid");
        uint256 returnArrayLen = endNftId - startNftId + 1;
        uint256[] memory theNftIds = new uint256[](returnArrayLen);
        uint256[] memory theNftCosts = new uint256[](returnArrayLen);
        bool[] memory theNftGiveAwayFlags = new bool[](returnArrayLen);
        for(uint256 i = 0; i < returnArrayLen; i++) {
            theNftIds[i] = startNftId+i;
            theNftCosts[i] = nftCosts[startNftId+i];
            theNftGiveAwayFlags[i] = isGiveAwayCard[startNftId+i];
            if(nftCosts[startNftId+i] == 0) {
                if(isGiveAwayCard[startNftId+i] == false) {
                    theNftIds[i] = 0;
                    theNftCosts[i] = 0;
                }
            }
        }
        return (theNftIds, theNftCosts, theNftGiveAwayFlags);
    }

    function getNotListedCreatedNFTsRange(uint256 startNftId, uint256 endNftId) public view returns (uint256[] memory notListedNftIds) {
        require(endNftId > startNftId, "nft id range invalid");
        uint256 returnArrayLen = endNftId - startNftId + 1;
        uint256[] memory theNftIds = new uint256[](returnArrayLen);
        for(uint256 i = 0; i < returnArrayLen; i++) {
            theNftIds[i] = 0;
            if(nftCosts[startNftId+i] == 0) {
                if(isGiveAwayCard[startNftId+i] == false) {
                    theNftIds[i] = startNftId+i;
                }
            }
        }
        return (theNftIds);
    }

    function getNFTsListStatus(uint256[] memory nftIds) public view returns (uint256[] memory isListed, uint256[] memory isNotListed) {
        uint256[] memory listedNftIds = new uint256[](nftIds.length);
        uint256[] memory notListedNftIds = new uint256[](nftIds.length);
        for(uint256 i = 0; i < nftIds.length; i++) {
            if(isGiveAwayCard[nftIds[i]] == true) {
                listedNftIds[i] = nftIds[i];
                notListedNftIds[i] = 0;
            } else {
                if(nftCosts[nftIds[i]] == 0) {
                    listedNftIds[i] = 0;
                    notListedNftIds[i] = nftIds[i];
                }
                else {
                    listedNftIds[i] = nftIds[i];
                    notListedNftIds[i] = 0;
                }
            }
        }
        return (isListed, isNotListed);
    }

    function getCreatorAddress(uint256 nftId) public view returns (address payable) {
        address payable overrideAddress = creatorOverrides[nftId];
        if(overrideAddress == address(0x00000000000000000000000000000000)) {
            return treatNFTMinter.creators(nftId);
        }

        return overrideAddress;
    }

    function getCreatorRefAddress(address treatModel) public view returns (address payable) {
        address payable overrideAddress = creatorRefOverrides[treatModel];
        if(overrideAddress == address(0x00000000000000000000000000000000)) {
            address payable refAddress = treatNFTMinter.referrers(treatModel);
            if(refAddress == address(0x00000000000000000000000000000000)) {
                refAddress = tittyFundAddress;
            }
            return refAddress;
        }

        return overrideAddress;
    }

    function setCreatorOverrides(uint256[] memory nftIds, address payable[] memory overrideAddresses) public onlyOwner {
        require(nftIds.length == overrideAddresses.length, "invalid arrays length");

        for(uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            address payable overrideAddress = overrideAddresses[i];
            address payable currentCreatorAddress = getCreatorAddress(nftId);

            require(msg.sender == currentCreatorAddress || msg.sender == owner(), "sender not contract owner or current creator");
            require(currentCreatorAddress != overrideAddress, "can't override to same address");

            emit OnCreatorUpdated(currentCreatorAddress, overrideAddress);
            creatorOverrides[nftId] = overrideAddress;
        }
    }
    
    function setCreatorRefOverrides(address payable[] memory treatCreators, address payable[] memory overrideAddresses) public onlyOwner {
        require(treatCreators.length == overrideAddresses.length, "invalid arrays length");

        for(uint256 i = 0; i < treatCreators.length; i++) {
            address payable treatModel = treatCreators[i];
            address payable overrideAddress = overrideAddresses[i];
            address payable currentCreatorRefAddress = getCreatorRefAddress(treatModel);

            require(msg.sender == currentCreatorRefAddress || msg.sender == owner(), "sender not contract owner or current creator");
            require(currentCreatorRefAddress != overrideAddress, "can't override to same address");

            emit OnCreatorRefUpdated(currentCreatorRefAddress, overrideAddress);
            creatorRefOverrides[treatModel] = overrideAddress;
        }
    }


        // Mint 1 nft directly to the user wallet from TreatNFTMinter 
    function redeem(uint256 _nft) payable public {
        require(paused == false, "Contract Paused");
        require(nftCosts[_nft] != 0, "nft not found");
        require(msg.value >= nftCosts[_nft], "not enough treats to buy yoursef a treat");
        require(treatNFTMinter.totalSupply(_nft) < treatNFTMinter.maxSupply(_nft), "max nfts minted");

        address payable creatorAddress = getCreatorAddress(_nft);
        address payable referrerAddress = getCreatorRefAddress(creatorAddress);

        uint256 refPercentage = defaultRefPercentage;
        if(treatDaoToken.balanceOf(referrerAddress) >= melonNumber) {
            refPercentage = melonRefPercentage;
        }

        uint256 creatorPercentage = defaultCreatorPercentage;
        if(treatDaoToken.balanceOf(creatorAddress) >= melonNumber) {
            creatorPercentage = melonCreatorPercentage;
        }
        

        uint256 creatorTake = nftCosts[_nft].mul(creatorPercentage).div(1000);
        uint256 treatTake = nftCosts[_nft].mul(1000-creatorPercentage).div(1000);
        uint256 refTake = treatTake.mul(refPercentage).div(1000);
        uint256 treasuryTake = treatTake.mul(1000-refPercentage).div(1000);

        address(uint160(creatorAddress)).transfer(creatorTake);
        address(uint160(treatTreasuryAddress)).transfer(treasuryTake);
        address(uint160(referrerAddress)).transfer(refTake);

        treatNFTMinter.mint(msg.sender, _nft, 1, "");
        emit Redeemed(msg.sender, nftCosts[_nft]);
    }
    
        // Mint multiple nft directly to the user wallet from TreatNFTMinter 
    function redeemMultiple(uint256 _nft, uint256 _amount) payable public {
        require(paused == false, "Contract Paused");
        require(nftCosts[_nft] != 0, "nft not found");
        uint256 treatSetCost = nftCosts[_nft].mul(_amount);
        require(msg.value >= treatSetCost, "not enough treats to buy yoursef a treat");
        require(treatNFTMinter.totalSupply(_nft).add(_amount) <= treatNFTMinter.maxSupply(_nft), "max nfts minted");

        address payable creatorAddress = getCreatorAddress(_nft);
        address payable referrerAddress = getCreatorRefAddress(creatorAddress);

        uint256 refPercentage = defaultRefPercentage;
        if(treatDaoToken.balanceOf(referrerAddress) >= melonNumber) {
            refPercentage = melonRefPercentage;
        }

        uint256 creatorPercentage = defaultCreatorPercentage;
        if(treatDaoToken.balanceOf(creatorAddress) >= melonNumber) {
            creatorPercentage = melonCreatorPercentage;
        }

        uint256 creatorTake = treatSetCost.mul(creatorPercentage).div(1000);
        uint256 treatTake = treatSetCost.mul(1000-creatorPercentage).div(1000);
        uint256 refTake = treatTake.mul(refPercentage).div(1000);
        uint256 treasuryTake = treatTake.mul(1000-refPercentage).div(1000);

        address(uint160(creatorAddress)).transfer(creatorTake);
        address(uint160(treatTreasuryAddress)).transfer(treasuryTake);
        address(uint160(referrerAddress)).transfer(refTake);

        treatNFTMinter.mint(msg.sender, _nft, _amount, "");
        emit Redeemed(msg.sender, treatSetCost);
    }

    function redeemSet(uint256 _setId) payable public {
        require(paused == false, "Contract Paused");
        uint256[] memory setIds = nftSetIds[_setId];
        require(setIds.length > 0, "set not found");
        require(nftSetCosts[_setId] != 0, "set price not found");
        require(msg.value == nftSetCosts[_setId], "not enough BNB");

        for(uint256 i = 0; i < setIds.length; i++) {
          require(treatNFTMinter.totalSupply(setIds[i]) < treatNFTMinter.maxSupply(setIds[i]), "max nfts minted");
        }

        address payable creatorAddress = treatSetModels[_setId];
        address payable referrerAddress = getCreatorRefAddress(creatorAddress);

        uint256 refPercentage = defaultRefPercentage;
        if(treatDaoToken.balanceOf(referrerAddress) >= melonNumber) {
            refPercentage = melonRefPercentage;
        }

        uint256 creatorPercentage = defaultCreatorPercentage;
        if(treatDaoToken.balanceOf(creatorAddress) >= melonNumber) {
            creatorPercentage = melonCreatorPercentage;
        }

        uint256 treatSetCost = nftSetCosts[_setId];

        uint256 creatorTake = treatSetCost.mul(creatorPercentage).div(1000);
        uint256 treatTake = treatSetCost.mul(1000-creatorPercentage).div(1000);
        uint256 refTake = treatTake.mul(refPercentage).div(1000);
        uint256 treasuryTake = treatTake.mul(1000-refPercentage).div(1000);

        address(uint160(creatorAddress)).transfer(creatorTake);
        address(uint160(treatTreasuryAddress)).transfer(treasuryTake);
        address(uint160(referrerAddress)).transfer(refTake);

        for(uint256 i = 0; i < setIds.length; i++) {
          treatNFTMinter.mint(msg.sender, setIds[i], 1, "");
        }
    }
    
    function redeemFreeTreat(uint256 nftId) payable public {
        require(paused == false, "Contract Paused");
        require(isGiveAwayCard[nftId] == true, "treat not found");
        require(msg.value >= nftCosts[nftId], "wrong price");
        require(treatNFTMinter.totalSupply(nftId) < treatNFTMinter.maxSupply(nftId), "max nfts minted");

        treatNFTMinter.mint(msg.sender, nftId, 1, "");
        emit Redeemed(msg.sender, nftCosts[nftId]);
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4) {
        return 0xf23a6e61;
    }
    
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4) {
        return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
    
    function treasury(address payable _treatTreasuryAddress) public onlyOwner {
        require(_treatTreasuryAddress != address(0), "cannot switch treasury to the zero address");
        treatTreasuryAddress = _treatTreasuryAddress;
    }

    function tittyFund(address payable _tittyFundAddress) public onlyOwner {
        tittyFundAddress = _tittyFundAddress;
    }

    function setPercentages(uint256 _defaultCreatorPercentage, uint256 _melonCreatorPercentage, uint256 _defaultRefPercentage, uint256 _melonRefPercentage) public onlyOwner {
        defaultCreatorPercentage = _defaultCreatorPercentage;
        melonCreatorPercentage = _melonCreatorPercentage;
        defaultRefPercentage = _defaultRefPercentage;
        melonRefPercentage = _melonRefPercentage;
    }
    
    function harvestTreats(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPausedTreats(bool _paused) public onlyOwner {
        pausedTreats = _paused;
    }
}