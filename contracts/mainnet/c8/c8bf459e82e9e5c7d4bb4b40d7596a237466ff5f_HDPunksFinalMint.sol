/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;


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

// File: contracts/HDPunksFinalMint/contracts/HDPunksFinalMint.sol


pragma solidity ^0.8.4;


contract HDPunksFinalMint is Ownable {

    uint public price = 0.04 ether;
    uint public maxPunks = 2177;
    uint public mintCount = 0;
    uint public maxPunksPerTx = 50;
    mapping(address => uint) public hdpunks;
    mapping(address => bool) public addressRecorded;
    address[] public addresses;

    uint public startTimestamp = 1630341000; // Mon Aug 30, 12:30pm EST

    constructor() {}

    modifier mintingOpen() {
        require(block.timestamp > startTimestamp, "Not open yet");
        _;
    }

    receive() external payable mintingOpen {
        _mint(msg.value);
    }

    function mint() external payable mintingOpen {
        _mint(msg.value);
    }

    function _mint(uint weiValue) internal {
        uint remainder = weiValue % price;
        uint amount = weiValue / price;
        require(amount < maxPunksPerTx, "Max 50 mints per tx");
        require(mintCount + amount < maxPunks, "Sold out");
        // Send back the extra
        if (remainder > 0) {
            (bool success,) = owner().call{value: remainder}("");
            require(success, "Failed to send ether");
        }
        hdpunks[msg.sender] += amount;
        mintCount += amount;
        if(!addressRecorded[msg.sender]) {
            addressRecorded[msg.sender] = true;
            addresses.push(msg.sender);
        }
    }

    function setMaxPunks(uint _maxPunks) public onlyOwner {
        maxPunks = _maxPunks;
    }

    /**
     * @dev Withdraw the contract balance to the dev address
     */
    function withdraw() public {
        uint amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Failed to send ether");
    }

}