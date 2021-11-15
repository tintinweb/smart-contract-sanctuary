// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    function mint(address _receiver, uint256 _amount) external;
    function burn(address _receiver, uint256 _amount) external;
}

contract GRODistributer is Ownable {
    
    enum pool { NONE, DAO, INVESTOR, TEAM, COMMUNITY }
    // Limits for token minting
    uint256 public constant DEFAULT_FACTOR = 1E18;
    // Amount dedicated to the dao
    uint256 public constant DAO_QUOTA = 8_000_000 * DEFAULT_FACTOR;
    // Amount dedicated to the investor group
    uint256 public constant INVESTOR_QUOTA = 19_490_577 * DEFAULT_FACTOR;
    // Amount dedicated to the team
    uint256 public constant TEAM_QUOTA = 22_509_423 * DEFAULT_FACTOR;
    // Amount dedicated to the community
    uint256 public constant COMMUNITY_QUOTA = 45_000_000 * DEFAULT_FACTOR;

    IToken public immutable govToken; 
    address public dao;
    // contracts that are allowed to mint, and which pool they can mint from
    mapping(address => uint256) public vesters;
    // contracts that are allowed to burn
    mapping(address => bool) public burners;
    // pool with minting limits for vesters
    mapping(pool => uint256) public mintingPools;

    constructor(
        address token,
        address dao
    ) {
        govToken = IToken(token);
        mintingPools[pool.DAO] = DAO_QUOTA;
        mintingPools[pool.INVESTOR] = INVESTOR_QUOTA;
        mintingPools[pool.TEAM] = TEAM_QUOTA;
        mintingPools[pool.COMMUNITY] = COMMUNITY_QUOTA;
        transferOwnership(dao);
    }

    // @dev Set vester contracts that can mint tokens
    // @param vesters target contract
    // @param status add/remove from vester role
    function setVester(address vester, uint256 role) external onlyOwner {
        require(!burners[vester], 'setVester: burner cannot be vester');
        if (role == 1) {
            vesters[dao] = 0;
            dao = vester;
        }
        vesters[vester] = role;
    }

    // @dev Set burner contracts, that can burn tokens
    // @param burner target contract
    // @param status add/remove from burner pool
    function setBurner(address burner, bool status) external onlyOwner {
        require(vesters[burner] == 0, 'setBurner: vester cannot be burner');
        burners[burner] = status;
    }

    // @dev mint tokens - Reduces total allowance for minting pool
    // @param account account to mint for
    // @param amount amount to mint
    function mint(address account, uint256 amount) external {
        require(vesters[msg.sender] > 1, "mint: msg.sender != vester");
        uint256 poolId = vesters[msg.sender];
        if (poolId > 4) {
            poolId = 4;
        }
        mintingPools[pool(poolId)] = mintingPools[pool(poolId)] - amount;
        govToken.mint(account, amount);
    }

    // @dev mintDao seperate minting function for dao vester - can mint from both
    //      community and dao quota
    // @param account account to mint for
    // @param amount amount to mint
    // @param pool pool whos' allowance to reduce
    function mintDao(address account, uint256 amount, bool community) external {
        require(vesters[msg.sender] == 1, "mint: msg.sender != dao");
        uint256 poolId = 1;
        if (community) {
            poolId = 4;
        }
        mintingPools[pool(poolId)] = mintingPools[pool(poolId)] - amount;
        govToken.mint(account, amount);
    }

    // @dev burn tokens - adds allowance to community pool
    // @param account account whos' tokens to burn
    // @param amount amount to burn
    function burn(address account, uint256 amount) external {
        require(burners[msg.sender], "burn: msg.sender != burner");
        govToken.burn(account, amount);
        mintingPools[pool(4)] = mintingPools[pool(4)] + amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

