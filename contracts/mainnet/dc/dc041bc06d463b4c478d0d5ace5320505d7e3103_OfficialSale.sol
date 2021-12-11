/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: contracts/interface/MinterMintable.sol

pragma solidity ^0.8.7;

interface MinterMintable {
    function isMinter(address check) external view returns (bool);
    function mint(address owner) external returns (uint256);
    function batchMint(address owner, uint256 amount) external returns (uint256[] memory);
}

// File: contracts/OfficialSale.sol

pragma solidity ^0.8.7;



contract OfficialSale is Ownable {

    MinterMintable _minterMintable_;

    constructor(address ghettoSharkhoodAddress) {
        _minterMintable_ = MinterMintable(ghettoSharkhoodAddress);
    }

    function price() public view returns (uint256) {
        if (block.timestamp <= whitelistUnlockAt()) return 0.085 ether;
        
        return 0.09 ether;
    }

    function whitelistUnlockAt() public virtual pure returns (uint256) {
        return 1639360800;
    }

    // Whitelist

    struct buyerData {
        uint256 cap; // the max number of NFT buyer can buy
        uint256 bought; // the number of NFT buyer have bought
    }

    mapping(address => buyerData) _buyers_;

    /**
     * This purpose of this function is to check whether buyer can buy,
     */
    modifier onlyAllowedBuyer(uint256 amount) {

        /**
         * only if block.timestamp less than whitelistUnlockAt will check buyer cap
         */
        if (block.timestamp <= whitelistUnlockAt()) {
            require(
                _buyers_[msg.sender].bought < _buyers_[msg.sender].cap
                && _buyers_[msg.sender].bought + amount > _buyers_[msg.sender].bought
                && _buyers_[msg.sender].bought + amount <= _buyers_[msg.sender].cap, 
                "Presale: this address hasn't been added to whitelist."
            );
        }
        
        _;
    }

    /**
     * Set buyer cap, only owner can do this operation, and this function can be call before closing.
     */
    function setBuyerCap(address buyer, uint256 cap) public onlyOwner onlyOpened {
        _buyers_[buyer].cap = cap;
    }

    /**
     * This function can help owner to add larger than one addresses cap.
     */
    function setBuyerCapBatch(address[] memory buyers, uint256[] memory amount) public onlyOwner onlyOpened {
        require(buyers.length == amount.length, "Presale: buyers length and amount length not match");
        require(buyers.length <= 100, "Presale: the max size of batch is 100.");

        for(uint256 i = 0; i < buyers.length; i ++) {
            _buyers_[buyers[i]].cap = amount[i];
        }
    }

    function buyerCap(address buyer) public view returns (uint256) {
        return _buyers_[buyer].cap;
    }

    function buyerBought(address buyer) public view returns (uint256) {
        return _buyers_[buyer].bought;
    }

    // withdraw related functions

    function withdraw() public onlyOwner {
        address payable receiver = payable(owner());
        receiver.transfer(address(this).balance);
    }

    // open and start control
    bool _opened_ = true;
    bool _started_ = false;

    modifier onlyOpened() {
        require(_opened_, "Presale: presale has been closed.");
        _;
    }
    
    modifier onlyStart() {
        require(_started_, "Presale: presale is not now.");
        _;
    }

    function start() public onlyOwner onlyOpened {
        _started_ = true;
    }

    function end() public onlyOwner onlyOpened {
        _started_ = false;
    }

    function close() public onlyOwner onlyOpened {
        _started_ = false;
        _opened_ = false;
    }

    function started() public view returns (bool) {
        return _started_;
    }

    function opened() public view returns (bool) {
        return _opened_;
    }

    // Presale

    uint256 _sold_ = 0;

    /**
     * Only pay larger than or equal to total price will
     */
    modifier onlyPayEnoughEth(uint256 amount) {
        require(msg.value >= amount * price(), "Presale: please pay enough ETH to buy.");
        _;
    }

    /**
     * Buy one NFT in one transaction
     */
    function buy() public payable 
        onlyOpened
        onlyStart
        onlyAllowedBuyer(1) 
        onlyPayEnoughEth(1)
        returns (uint256) {
        _sold_ += 1;
        // if whitelist still active, add number of bought
        _buyers_[msg.sender].bought += 1;
        return _minterMintable_.mint(msg.sender);
    }

    /**
     * Buy numbers of NFT in one transaction.
     * It will also increase the number of NFT buyer has bought.
     */
    function buyBatch(uint256 amount) public payable 
        onlyOpened
        onlyStart
        onlyAllowedBuyer(amount) 
        onlyPayEnoughEth(amount)
        returns (uint256[] memory) {
        require(amount <= 20, "Presale: batch size should less than 20.");
        require(amount >= 1, "Presale: batch size should larger than 0.");
        _sold_ += amount;
        // if whitelist still active, add number of bought
        _buyers_[msg.sender].bought += amount;
        return _minterMintable_.batchMint(msg.sender, amount);
    }

    /**
     * Get the number of NFT has been sold during presale
     */
    function sold() public view returns (uint256) {
        return _sold_;
    }

}