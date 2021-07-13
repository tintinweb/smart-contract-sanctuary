/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity =0.7.4;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity =0.7.4;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


contract Scimagine is Ownable
{
    //ScimagineDataPlaceholder placeholder; //TODO For future upgradeble contracts
    // function setPlaceholder(address) public only
    struct digest
    {
        
        string metadata;
        string owner;
        uint256 registeredDate;
        uint32 userid;

    }
    mapping (bytes32 => digest) digests;
    constructor()
    {
        
    }
    
    function insertDigest(bytes32 hash, string memory metadata, string memory owner, uint32 userid) public onlyOwner
    {
        require(digests[hash].registeredDate == 0, "Error: this hash was already in the system");
        digests[hash].metadata = metadata;
        digests[hash].owner = owner;
        digests[hash].userid = userid;
        digests[hash].registeredDate = block.timestamp;
    }
    
    function getDigest(bytes32 hash) public view returns(string memory,string memory, uint32,uint256)
    {
        return(digests[hash].metadata, digests[hash].owner, digests[hash].userid, digests[hash].registeredDate);
    }
   
}

//TODO revert back this for upgradable
/*contract ScimagineDataPlaceholder
{
    address scimagineAddress;
    constructor()
    {
        scimagineAddress = msg.sender;
    }
    function changeSCIaddress(address addr) public  //todo only right contract
    {
        scimagineAddress = addr;
    }
}*/