// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface StandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address reveiver, uint256 amount) external returns (bool);
    function burn(address sender, uint256 amount) external returns (bool);
}

contract CMCBridge is Ownable{
    // we assign a unique ID to each transaction(txId)
    event Bridge(
        uint256 txId,
        address wallet,
        uint256 amount,
        string toWallet
    );

    struct TX{
        uint256 txId;
       	address wallet;
        uint256 amount;
        string toWallet;
    }
    uint256 public lastTxId = 0;


    address public tokenAddress = 0x67541e66343dC96FD26d70Ebc02FC960986BA606;

    mapping(uint256 => TX) public txs;

    constructor(){

    }

    function deposit(uint256 amount, string memory toWallet) public returns (uint256){
    	require(amount > 0, "0");
        StandardToken token = StandardToken(tokenAddress);
        token.transferFrom(address(msg.sender), address(this), amount);

        uint256 txId = ++lastTxId;
        txs[txId] = TX({
            txId: txId,
            wallet: msg.sender,
            amount: amount,
            toWallet: toWallet
        });
        emit Bridge(txId, msg.sender, amount, toWallet);
        return txId;
    }

    // allows the owner to withdraw BNB and other tokens
    function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyOwner{
        require(_to != address(0));
        if(_tokenAddr == address(0)){
        	payable(_to).transfer(amount);
        }else{
        	StandardToken(_tokenAddr).transfer(_to, amount);	
        }
    }

    function setTokenAddress(address newToken) public onlyOwner {
        tokenAddress = newToken;
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

