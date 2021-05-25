/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// File: node_modules\openzeppelin-solidity\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// File: openzeppelin-solidity\contracts\access\Ownable.sol



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

// File: contracts\PresaleICO.sol


pragma solidity >=0.4.22 <0.9.0;


interface IVendorToken {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function setTimeLockForTranaction(address recipient, uint256 timestamp) external returns (bool);
}

contract PresaleICO is Ownable {
    mapping(address => uint256) public deposits;
    address[] public buyers;
    uint256 public totalDeposits;
    uint256 public icoTimeLimit;
    bool public closed = false;
    IVendorToken public token;

    event Deposit(address indexed _from, uint256 _value);
    event PayoutToken(address indexed _to, uint256 _value);

    constructor() {
        icoTimeLimit = block.timestamp + 30 days;
    }

    function setVendorToken(address _vendorAddress) public onlyOwner {
        require(_vendorAddress != address(0x0), "Invalid address");
        token = IVendorToken(_vendorAddress);
    }

    function deposit() public payable {
        require(icoTimeLimit > block.timestamp, "ICO is already ended!");
        require(!closed);

        deposits[_msgSender()] += msg.value;
        totalDeposits += msg.value;
        buyers.push(_msgSender());

        emit Deposit(_msgSender(), msg.value);
    }

    function close(address _withdrawAddress) public onlyOwner {
        require(icoTimeLimit < block.timestamp, "ICO is locked by timeline!");
        require(!closed);

        closed = true;

        for (uint256 i = 0; i < buyers.length; i++) {
            address buyerAddr = buyers[i];
            uint256 buyerDeposit = deposits[buyerAddr];

            if (buyerDeposit == 0) continue;

            uint256 buyerShare = (token.balanceOf(address(this)) * buyerDeposit) / totalDeposits;
            require(token.transfer(buyerAddr, buyerShare));
            deposits[buyerAddr] = 0;
            emit PayoutToken(buyerAddr, buyerShare);
            
            if (buyerDeposit > 20 * (10**16) && buyerDeposit <= 40 * (10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 30 days);
            }
            else if (buyerDeposit > 40 * (10**16) && buyerDeposit <= 50 * (10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 60 days);
            }
            else if (buyerDeposit > 50 * (10**16) && buyerDeposit <= 75 *(10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 90 days);
            }
            else if (buyerDeposit > 75 *(10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 120 days);
            }
        }

        address payable owner = payable(_withdrawAddress);
        owner.transfer(totalDeposits);
        totalDeposits = 0;
    }
}