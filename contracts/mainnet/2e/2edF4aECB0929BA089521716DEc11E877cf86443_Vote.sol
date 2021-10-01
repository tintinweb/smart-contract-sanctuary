/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0

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

// File: @openzeppelin\contracts\access\Ownable.sol


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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.8.0;

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

// File: contracts\Vote.sol

pragma solidity >=0.7.0 <0.9.0;



// _________  ________  ________  _________
//|\___   ___\\   __  \|\   __  \|\___   ___\
//\|___ \  \_\ \  \|\ /\ \  \|\  \|___ \  \_|
//     \ \  \ \ \   __  \ \  \\\  \   \ \  \
//      \ \  \ \ \  \|\  \ \  \\\  \   \ \  \
//       \ \__\ \ \_______\ \_______\   \ \__\
//        \|__|  \|_______|\|_______|    \|__|

contract Vote is Ownable {

    uint256 fee;
    address ido;
    address token;
    uint256 public expire;
    uint256 public totalVotes;
    uint256 public minTbot;

    struct Voter {
        bool voted;  // if true, that person already voted
        bool vote;
    }

    mapping(address => Voter) public votes;
    mapping(bool => int) public count;
    address[] public voters;

    event Voted(address _voter, bool _vote);

    constructor(uint256 _fee, address _ido, address _token, uint256 _expire, uint256 _minTbot){
        fee = _fee;
        ido = _ido;
        token = _token;
        expire = _expire;
        minTbot = _minTbot;
    }

    function changeFee(uint256 _fee) external onlyOwner {
        require(_fee >= 0, "Fee must be positive.");
        fee = _fee;
    }

    function changeMinTbot(uint256 _minTbot) external onlyOwner {
        require(_minTbot >= 0, "Tbot must be positive.");
        minTbot = _minTbot;
    }

    function changeExpire(uint256 _expire) external onlyOwner{
        require(_expire > block.timestamp, "Expiration date must be in the future.");
        expire = _expire;
    }

    function resetVote(uint256 _expire) external onlyOwner {
        require(_expire > block.timestamp, "Expiration must be in the future.");
        expire = _expire;
        totalVotes = 0;

        count[true] = 0;
        count[false] = 0;

        for (uint256 s = 0; s < voters.length; s += 1){
            delete votes[voters[s]];
        }
        delete voters;
    }

    function vote(bool _vote) payable external{
        require(msg.value >= fee, "Sorry, not enough ETH voting power.");

        // Check time
        require(block.timestamp < expire, "Vote is already over.");

        // Check if already voted
        require(!votes[msg.sender].voted, "Already voted.");

        // Check balance
        uint256 idoBalance = IERC20(ido).balanceOf(msg.sender);
        uint256 tokenBalance = IERC20(token).balanceOf(msg.sender);
        require(idoBalance + tokenBalance >= minTbot, "Sorry, not enough TBOT voting power.");

        count[_vote]++;
        totalVotes++;
        votes[msg.sender].voted = true;
        votes[msg.sender].vote = _vote;
        voters.push(msg.sender);

        emit Voted(msg.sender, _vote);
    }

    function transferFees(address payable _to) external onlyOwner {
        require(_to != address(0), "Zero Address.");

        uint256 balance = address(this).balance;
        require(balance > 0, "Sorry, no balance.");
        _to.transfer(balance);
    }
}