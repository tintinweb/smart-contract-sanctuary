/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.2;

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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
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

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.2;

contract DuckRaceAlpha is Ownable {
    
    address payable[] public players; //dynamic array of type address payable
    string[] public playerNames; //dynamic array of type string
    address public _manager;
    IERC20 DUCKRACE = IERC20(0xfEce5402E0E3bE4Ceb7ee46b08F4888f29a7c062);
    uint256 public _stake = 10000000 * (10**18);
    uint public winnerPrize;
    address payable public lastWinner;
    
    constructor() public {
        // initializing the owner to the address that deploys the contract
        _manager = msg.sender;
    }
    
    
   function enterRace(string memory _playerName) public{

        // each player calls this function to enter the race
        
        require (players.length <=2);
        
        DUCKRACE.transferFrom(msg.sender, address(this), _stake);
        playerNames.push(_playerName);
        players.push(payable(msg.sender));
    }
    
    // returning the contract's balance
    function getBalance() public view returns(uint256){
        
        uint balance = DUCKRACE.balanceOf(address(this));
        return balance;
    }
    
    function getPlayerID(string memory _playerName) public view returns(uint){
        for (uint i=0; i<players.length; i++) {
            
            if(keccak256(bytes(playerNames[i])) == keccak256(bytes(_playerName))){
                return i;
            }
        }
    }
    // selecting the winner
    function pickWinner(uint winningNumber) public{
        // only the manager can pick a winner if there are at least 2 players in the game
        require(msg.sender == _manager);
        require (players.length >= 2);
        
        lastWinner = players[(winningNumber - 1)];
        
        winnerPrize = DUCKRACE.balanceOf(address(this));
        
        // transferring contract's balance of DUCKRACE to the race winner
        DUCKRACE.transfer(lastWinner, winnerPrize);
        
        // reset race
        players = new address payable[](0);
        playerNames = new string[](0);
        winnerPrize = DUCKRACE.balanceOf(address(this));
    }
    
        function setManager(address manager) external onlyOwner{
        _manager = manager;
    }
    
        function setStake(uint stake) external {
        require(msg.sender == _manager);
        _stake = stake * (10**18);
    }
}