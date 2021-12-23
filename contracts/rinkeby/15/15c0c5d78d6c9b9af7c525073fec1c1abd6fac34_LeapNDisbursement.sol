/**
 *Submitted for verification at Etherscan.io on 2021-12-23
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

// File: contracts/LeapNDisbursement.sol



pragma solidity ^0.8.7;


struct PayeeDetails{
    address addr;
    uint256 shares;
}

contract LeapNDisbursement is Ownable {
    mapping(address => bool) private _allowedPayers;
    
    uint256 public constant TOTAL_SHARES = 10_000;

    event PaymentDisbursed(address indexed recipient, uint256 indexed amount, string indexed reason, uint256 timestamp);

    function disperseEther(PayeeDetails[] calldata payees, string calldata reason) external payable onlyOwnerOrAllowed {
        uint256 amount = address(this).balance;
        require(amount > 0, "No tx value specified");

        uint256 payableShares = 0;

        for (uint256 i = 0; i < payees.length; i++) {
            payableShares += payees[i].shares;
            if(payableShares > TOTAL_SHARES){
                revert("Specified shares exceeds total shares");
            }

            uint256 paymentAmount = (amount * payees[i].shares) / TOTAL_SHARES;            
            payable(payees[i].addr).transfer(paymentAmount);

            emit PaymentDisbursed(payees[i].addr, paymentAmount, reason, block.timestamp);
        }

        uint256 balance = address(this).balance;
        
        // If there is anything left over (because not enough shares were specified), return the balance to the sender
        if (balance > 0) {
            payable(_msgSender()).transfer(balance);
        }
    }

    function addPayer(address payer) external onlyOwner{
        _allowedPayers[payer] = true;
    }

    function removePayer(address payer) external onlyOwner{
        _allowedPayers[payer] = false;
    }

    /**
     * @dev Throws if called by any account other than the owner or one of the predefined allowed payers.
     */
    modifier onlyOwnerOrAllowed() {
        require(
            _msgSender() == owner() || _allowedPayers[_msgSender()],
            "Caller is not the owner or an allowed payer"
        );
        _;
    }
}