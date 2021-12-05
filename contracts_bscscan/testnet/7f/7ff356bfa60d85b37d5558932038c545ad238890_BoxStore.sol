/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

/** 
 *  SourceUnit: d:\Projects\realream\nft-smart-contracts\contracts\BoxStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: d:\Projects\realream\nft-smart-contracts\contracts\BoxStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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


/** 
 *  SourceUnit: d:\Projects\realream\nft-smart-contracts\contracts\BoxStore.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";

interface IMysterBox {

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

}

contract BoxStore is Ownable  {

    event AdminWalletUpdated(address wallet);
    event RoundUpdated(uint256 round, uint256 boxPrice, uint256 totalSupply, bool enable);
    event WhitelistUpdated(address[] accounts, bool status);
    event BoxBought(uint256 round, address buyer, uint256 quantity, uint256 price);
    event BoxPreOrdered(uint256 round, address buyer, uint256 quantity, uint256 price);
    event BoxClaimed(address user, uint256 quantity);

    IMysterBox public boxContract;

    address public adminWallet;

    struct Round {
        uint256 boxPrice;
        uint256 totalSupply;
        uint256 totalSold;
        bool enable;
    }

    // round id => round information
    mapping(uint256 => Round) public rounds;

    mapping(address => bool) public whitelist;

    mapping(address => uint256) public orders;

    constructor(IMysterBox _boxContract, address _adminWallet) {
        boxContract = _boxContract;
        adminWallet = _adminWallet;
    }

    function setAdminWallet(address _adminWallet)
        public
        onlyOwner    
    {
        require(_adminWallet != address(0), "BoxStore: address must be not zero");

        adminWallet = _adminWallet;

        emit AdminWalletUpdated(_adminWallet);
    }

    function setRound(uint256 _round, uint256 _boxPrice, uint256 _totalSupply, bool _enable)
        public
        onlyOwner
    {
        Round storage round = rounds[_round];

        if (_boxPrice != 0) {
            round.boxPrice = _boxPrice;
        }

        if (_totalSupply != 0) {
            round.totalSupply = _totalSupply;
        }

        round.enable = _enable;

        require(round.totalSupply >= round.totalSold, "BoxStore: total supply must be greater or equal than total sold");

        emit RoundUpdated(_round, _boxPrice, _totalSupply, _enable);
    }

    function setWhitelist(address[] memory _accounts, bool _status)
        public
        onlyOwner
    {
        uint256 length = _accounts.length;

        require(length > 0, "BoxStore: array length is invalid");

        for (uint256 i = 0; i < length; i++) {
            whitelist[_accounts[i]] = _status;
        }

        emit WhitelistUpdated(_accounts, _status);
    }

    function buyBox(uint256 _round, uint256 _quantity)
        public
        payable
    {
        address msgSender = _msgSender();

        require(whitelist[msgSender], "BoxStore: caller is not in whitelist");

        require(_quantity > 0, "BoxStore: quantity must be not zero");

        Round storage round = rounds[_round];

        require(round.enable, "BoxStore: round was disabled");

        require(round.boxPrice > 0, "BoxStore: price must be not zero");

        require(round.totalSold + _quantity <= round.totalSupply, "BoxStore: the remaining quantity is not enough");

        uint256 amount = round.boxPrice * _quantity;

        require(amount == msg.value, "BoxStore: deposit amount is not enough");

        round.totalSold += _quantity;

        payable(adminWallet).transfer(amount);

        boxContract.mint(msgSender, 2, _quantity, "");

        emit BoxBought(_round, msgSender, _quantity, round.boxPrice);
    }

    function preOrderBox(uint256 _round, uint256 _quantity)
        public
        payable
    {
        address msgSender = _msgSender();

        require(whitelist[msgSender], "BoxStore: caller is not in whitelist");

        require(_quantity > 0, "BoxStore: quantity must be not zero");

        Round storage round = rounds[_round];

        require(round.enable, "BoxStore: round was disabled");

        require(round.boxPrice > 0, "BoxStore: price must be not zero");

        require(round.totalSold + _quantity <= round.totalSupply, "BoxStore: the remaining quantity is not enough");

        uint256 amount = round.boxPrice * _quantity;

        require(amount == msg.value, "BoxStore: deposit amount is not enough");

        round.totalSold += _quantity;

        payable(adminWallet).transfer(amount);

        orders[msgSender] += _quantity;

        emit BoxPreOrdered(_round, msgSender, _quantity, round.boxPrice);
    }

    function claimBox()
        public
    {
        address msgSender = _msgSender();

        uint256 quantity = orders[msgSender];

        require(quantity > 0, "BoxStore: has no box to claim");

        boxContract.mint(msgSender, 2, quantity, "");

        orders[msgSender] = 0;

        emit BoxClaimed(msgSender, quantity);
    }

}