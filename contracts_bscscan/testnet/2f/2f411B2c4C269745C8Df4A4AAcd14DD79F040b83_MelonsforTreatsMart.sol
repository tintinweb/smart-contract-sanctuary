/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

pragma solidity ^0.6.0;


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
  ░ ░ ▀▀  ▄ █                    melons for treats                    █    ▀▀
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

interface Treat {
    function balanceOf(address _owner) external view returns (uint256);
}

interface MelonToken {
    function balanceOf(address _owner) external view returns (uint256);
    function burn(address _account, uint256 _value) external;
}


// pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * // importANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface TreatNFTMinterV2 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _amount, uint256 indexed _id);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
    function isWhitelistAdmin(address _operator) external view returns (bool isNftAdmin);
    function create(uint256 _maxSupply, uint256 _initialSupply, string calldata _uri, bytes calldata _data, address _performerAddress) external returns (uint256 _nftId);
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

contract MelonsforTreatsMart is Ownable {
    using SafeMath for uint256;
    TreatNFTMinterV2 public treatNFTMinter;
    MelonToken public melonToken;
    mapping(uint256 => bool) public isMelonNft;
    mapping(uint256 => address) public treatModels;
    uint256[] public melonNfts;
    uint256[] public melonNftsList;
    uint256 public melonNftCost;
    bool public paused;
    bool public pausedTreats;
    uint256 private nonce;

    event MelonNFTCreatedAndAdded(uint256[] nftIds, address payable[] treatModels);
    event Redeemed(address indexed user, uint256 amount);

    constructor(address _treatNFTMinterAddress, address _melonAddress, uint256 _melonNftCost) public {
        treatNFTMinter = TreatNFTMinterV2(_treatNFTMinterAddress);
        melonToken = MelonToken(_melonAddress);
        paused = false;
        pausedTreats = false;
        melonNftCost = _melonNftCost;
    }

    function transferMelonNFT(uint256 nftId, uint256 nftCount, address payable nftTo) public {
        require(treatNFTMinter.isWhitelistAdmin(msg.sender) == true, "not admin role. cannot move nfts");
        treatNFTMinter.safeTransferFrom(address(this),nftTo,nftId,nftCount,"");
    }

    function createAndAddNFTs(uint256[] memory maxNftSupplys, address payable[] memory nftCreators, bytes memory _nftData) public returns (uint256[] memory nftIds) {
        require(treatNFTMinter.isWhitelistAdmin(msg.sender) == true, "not admin role. cannot create nfts");
        require(pausedTreats == false, "Contract Paused");
        require(maxNftSupplys.length == nftCreators.length, "NFT Supply and Address Arrays not equal len");
        uint256[] memory newNftIds = new uint256[](maxNftSupplys.length);
        for (uint256 i = 0; i < maxNftSupplys.length; ++i) {
            newNftIds[i] = treatNFTMinter.create(maxNftSupplys[i],maxNftSupplys[i],"",_nftData, nftCreators[i]);
            isMelonNft[newNftIds[i]] = true;
            treatModels[newNftIds[i]] = nftCreators[i];
            melonNfts.push(newNftIds[i]);
            melonNftsList.push(newNftIds[i]);
        }
        emit MelonNFTCreatedAndAdded(newNftIds, nftCreators);
        return newNftIds;
    }

    function getListedCreatedNFTsRange(uint256 startNftId, uint256 endNftId) public view returns (uint256[] memory listedNftIds, bool[] memory listedMelonNfts) {
        require(endNftId > startNftId, "nft id range invalid");
        uint256 returnArrayLen = endNftId - startNftId + 1;
        uint256[] memory theNftIds = new uint256[](returnArrayLen);
        bool[] memory theNftMelonFlags = new bool[](returnArrayLen);
        for(uint256 i = 0; i < returnArrayLen; i++) {
            theNftIds[i] = startNftId+i;
            theNftMelonFlags[i] = isMelonNft[startNftId+i];
        }
        return (theNftIds, theNftMelonFlags);
    }

    function getNFTsListStatus(uint256[] memory nftIds) public view returns (uint256[] memory isListed, uint256[] memory isNotListed) {
        uint256[] memory listedNftIds = new uint256[](nftIds.length);
        uint256[] memory notListedNftIds = new uint256[](nftIds.length);
        for(uint256 i = 0; i < nftIds.length; i++) {
            if(isMelonNft[nftIds[i]] == false) {
                listedNftIds[i] = 0;
                notListedNftIds[i] = nftIds[i];
            }
            else {
                listedNftIds[i] = nftIds[i];
                notListedNftIds[i] = 0;
            }
        }
        return (isListed, isNotListed);
    }

        // Transfer 1 nft directly to the user wallet from MelonShop 
    function redeem(uint256 _melon) payable public {
        require(paused == false, "Contract Paused");
        require(melonToken.balanceOf(msg.sender) >= melonNftCost, "not enough melons to buy yoursef a treat");
        //pick _nft based off of rng(ish) sol'n based off length modulo of keccak of psuedorandom stuff (block diff, nonce, msg.sender encode packed)
        nonce++;
        uint256 boobanumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),block.difficulty,now,msg.sender,melonNfts.length,nonce)));
        uint256 _nft = melonNfts[boobanumber % melonNfts.length];
        require(treatNFTMinter.balanceOf(address(this),_nft) >= 1, "no more melon nfts try again later");
        melonToken.burn(msg.sender,melonNftCost);
        treatNFTMinter.safeTransferFrom(address(this),msg.sender, _nft, 1, "");
        if(treatNFTMinter.balanceOf(address(this),_nft) == 0) {
            for (uint256 i=0; i < melonNfts.length; i++) {
                if(melonNfts[i] == _nft) {
                    melonNfts[i] = melonNfts[melonNfts.length - 1];
                    melonNfts.pop();
                    isMelonNft[_nft] = false;
                }
            }
        }
        emit Redeemed(msg.sender, melonNftCost);
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
    
    function removeMelonNft(uint256 _nft) public {
        require(treatNFTMinter.isWhitelistAdmin(msg.sender), "caller not admin on minter");
        require(isMelonNft[_nft] == true, "nft id not melon nft");
        for (uint256 i=0; i < melonNfts.length; i++) {
            if(melonNfts[i] == _nft) {
                melonNfts[i] = melonNfts[melonNfts.length - 1];
                melonNfts.pop();
                isMelonNft[_nft] = false;
            }
        }

    }
    
    function removeMelonNftFromGlobal(uint256 _nft) public {
        require(treatNFTMinter.isWhitelistAdmin(msg.sender), "caller not admin on minter");
        for (uint256 i=0; i < melonNftsList.length; i++) {
            if(melonNftsList[i] == _nft) {
                melonNftsList[i] = melonNftsList[melonNftsList.length - 1];
                melonNftsList.pop();
            }
        }

    }

    function updateMelonToken(address _newMelonAddress) public onlyOwner {
        melonToken = MelonToken(_newMelonAddress);
    }

    function updateMelonNftCost(uint256 _newMelonNftCost) public onlyOwner {
        require(_newMelonNftCost >= 1000000000000000000, "cannot set cost below one melon");
        melonNftCost = _newMelonNftCost;
    }
    
    function harvestTreats(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }
    
    function withdrawAll(address _tokenAddress, address payable _to) public onlyOwner {
        uint balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(_to, balance);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPausedTreats(bool _paused) public onlyOwner {
        pausedTreats = _paused;
    }
}