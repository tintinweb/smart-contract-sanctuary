/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity 0.8.1;

// SPDX-License-Identifier: MIT

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract CommonsWhitelist is Ownable {
    address[] public whitelistId;
    mapping(address => Member) public whitelist; //uses delegateAddress

    struct Member {
        address idAddress;
        bool employee; // true: employee member; false: coalition member
        bool whitelisted;
    }

    event AddedToWhitelist(address indexed account, bool employee);
    event MassAdd(address[] indexed accounts, bool[] memberTypes);
    event RemovedFromWhitelist(address indexed account);
    event UpdatedWhitelistAddress(address indexed oldAddress, address indexed newMemberAddress, address indexed idAddress);
    event WhitelistLength(uint256 whitelistLength);

    modifier onlyWhitelisted() {
        require(
            isWhitelisted(msg.sender),
            "CommonsWhitelist :: not whitelisted"
        );
        _;
    }
    
    constructor(address[] memory _initialMembers, bool[] memory _initialMemberTypes){
        require(_initialMembers.length == _initialMemberTypes.length, "arrays !match");
        massAdd(_initialMembers, _initialMemberTypes);
    }

    function add(address _address, bool _employee) public onlyOwner {
        whitelistId.push(_address);
        whitelist[_address] = Member(_address, _employee, true);
        emit AddedToWhitelist(_address, _employee);
    }

    function massAdd(address[] memory _addresses, bool[] memory _memberTypes) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistId.push(_addresses[i]);
            whitelist[_addresses[i]] = Member(
                _addresses[i],
                _memberTypes[i],
                true
            );
        }

        emit MassAdd(_addresses, _memberTypes);
    }

    function update(address _newDelegateAddress) public onlyWhitelisted {
        whitelist[msg.sender] = whitelist[_newDelegateAddress];
        emit UpdatedWhitelistAddress(msg.sender, _newDelegateAddress, whitelist[msg.sender].idAddress);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address].whitelisted = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address].whitelisted;
    }

    function isEmployeeMember(address _address) public view returns (bool) {
        return isWhitelisted(_address) && whitelist[_address].employee;
    }

    function isCoalitionMember(address _address) public view returns (bool) {
        return isWhitelisted(_address) && !whitelist[_address].employee;
    }

    function getWhitelistLength() public view returns (uint256) {
        uint256 length = whitelistId.length;
        return length;
    }
}