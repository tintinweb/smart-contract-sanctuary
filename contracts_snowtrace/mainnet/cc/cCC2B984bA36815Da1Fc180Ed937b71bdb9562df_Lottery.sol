// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Lottery is Ownable {
    
    //events 
    event LottoEntry(
        uint lottoNumber,
        uint totalTickets,
        uint qty,
        address entrant);

    event Winner(address winner);

    event EndLotto(
        uint lottoNumber, 
        uint totalTicketsSold,
        uint totalStack);

    //uint256
    uint public maxTickets = 99;
    uint public price = 5000000000000000000;
    uint public avaxTicketPrice = 17000000000000000;    
    uint public totalTicketsSold;    
    uint public lottoNumber;     
      

    //addresses
    address public winner;
    address public raffler;
    IERC20 public wStackAddress;

    //winners mapping
    mapping (uint => address) winners;

    //bools
    bool public isLottoLive;
    bool public allowBuyingWithAvax;

    //constructor
    constructor(address _wStackAddress) {
        isLottoLive = false;
        allowBuyingWithAvax = true;
        wStackAddress = IERC20(_wStackAddress);
        raffler = msg.sender;
    }

    function setMaxTickets(uint _amount) external onlyOwner() {
        maxTickets = _amount;
    }
    function setPrice(uint _price) external onlyOwner() {
        //must set price with 18 decimals
        price = _price;
    }

    function startLotto() external onlyOwner () {
        require(!isLottoLive);
        isLottoLive = true;
        lottoNumber++;
    }

    //all stack users can buy tickets
    function buyTickets(uint _qty) external {
        require(isLottoLive, 'thou shall not pass, lotto is not live');
        require(_qty > 0);
        require(totalTicketsSold + _qty <= maxTickets, 'thou shall not pass, try less tickets');
        wStackAddress.transferFrom(msg.sender, address(this), price * _qty);
        totalTicketsSold += _qty;
        emit LottoEntry (lottoNumber, totalTicketsSold, _qty, msg.sender);
    }

    function buyTicketsAvax(uint _qty) external payable {
        require(allowBuyingWithAvax, 'thou shall not pass, buying tickets with Avax is turned off');
        require(isLottoLive);
        require(_qty > 0);
        require(totalTicketsSold + _qty <= maxTickets, 'thou shall not pass, try less tickets');
        require(msg.value >= _qty * avaxTicketPrice, 'thou shall not pass, not enough AVAX sent');
        totalTicketsSold += _qty;
        emit LottoEntry (lottoNumber, totalTicketsSold, _qty, msg.sender);
    }

    //reset the lottery
    function endLotto() external onlyOwner {
        require(isLottoLive);
        emit EndLotto(lottoNumber, totalTicketsSold, price * totalTicketsSold);
        isLottoLive = false;
        totalTicketsSold = 0;

    }
    //after lottery
    function withdrawStack(address _to) external onlyOwner {
        uint256 tokenSupply = wStackAddress.balanceOf(address(this));
        wStackAddress.transfer(_to, tokenSupply);
    }

      //after lottery
    function withdrawAvax(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function setLottoLiveFalse () external onlyOwner {
        isLottoLive = false;
    }

    function setLottoLiveTrue () external onlyOwner {
        isLottoLive = true;
    }

    function setBuyingWithAvaxFalse () external onlyOwner {
        allowBuyingWithAvax = false;
    }

    function setBuyingWithAvaxTrue () external onlyOwner {
        allowBuyingWithAvax = true;
    }


    function setWinner (address _winner, uint _lottoNumber) external onlyRaffler {
        require(winners[_lottoNumber] == 0x0000000000000000000000000000000000000000);
        winners[_lottoNumber] = _winner;
        winner = _winner;
    }

    function setAvaxTicketPrice (uint _value) external onlyOwner {
        // in wei = 18 decimals
        avaxTicketPrice = _value;
    }

    function setRaffler (address _raffler) external onlyRaffler {
        raffler = _raffler;
    }

    modifier onlyRaffler () {
        require(msg.sender == raffler, 'thou shall not pass, you are not the raffler');
        _;
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}