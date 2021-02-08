pragma solidity ^0.5.16;

import "openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol";

contract UniverseChart is Ownable {
    /**
     * @dev The struct of account information
     * @param id The account id
     * @param referrer The referrer addresss (cannot be address 0)
     * @notice company is the root account with id = 0 on initialization
     */
    struct Account {
        uint128 id;
        uint128 referrerId;
    }

    uint128 public lastId = 1;
    mapping(address => Account) public accounts;
    mapping(uint128 => address) public accountIds;

    event Register(uint128 id, address user, address referrer);

    constructor(address _company) public {
        setCompany(_company);
    }

    /**
     * @dev Utils function to change default company address
     * @param _referrer The referrer address;
     */
    function register(address _referrer) external {
        require(
            accounts[_referrer].id != 0 || _referrer == accountIds[0],
            "Invalid referrer address"
        );
        require(accounts[msg.sender].id == 0, "Account has been registered");

        Account memory account =
            Account({id: lastId, referrerId: accounts[_referrer].id});

        accounts[msg.sender] = account;
        accountIds[lastId] = msg.sender;

        emit Register(lastId++, msg.sender, _referrer);
    }

    /**
     * @dev Utils function to change default company address
     * @param _company The new company address;
     */
    function setCompany(address _company) public onlyOwner {
        require(
            _company != accountIds[0],
            "You entered the same company address"
        );
        require(
            accounts[_company].id == 0,
            "Company was registered on the chart"
        );
        Account memory account = Account({id: 0, referrerId: 0});
        accounts[_company] = account;
        accountIds[0] = _company;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}