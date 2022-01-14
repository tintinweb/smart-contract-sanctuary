/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: truck.sol

pragma solidity 0.8.11;



contract PreSale is Ownable{

    iToken token;
    //IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 constant BUSD = IERC20(0xB2902B3b56C59c21f332786Fb87c952962A3F7df);
    bool public presale = true;

    uint public constant MAX = 1500*10e17;
    uint public constant MIN = 200*10e17;
    uint public constant RATE = 13*10e14;
    uint public constant SOFTCAP = 500*10e17;
    uint public constant HARDCAP = 2000*10e17;

    mapping (address=>uint) buys;
    mapping (address=>bool) whitelist;
    address[] buyers;
    uint totalBuys;
    address bridge;

    event tokenBought(address from, uint amountInBusd);

    constructor(address token_, address bridge_){
        token = iToken(token_);
        bridge = bridge_;
    }

    function buy(uint amount) external{
        require(whitelist[msg.sender], "You are not in the whitelist.");
        require(BUSD.balanceOf(msg.sender) >= amount, "Not enough BUSD");
        require(presale, "Presale not happening right now");
        uint totalIndAfterBuy = buys[msg.sender] + amount;
        uint totalAfterBuy = totalBuys + amount;
        require(totalAfterBuy <= HARDCAP, "Hardcap reached");
        require(totalIndAfterBuy <= MAX, "Can't buy that much!");
        require(totalIndAfterBuy >= MIN, "You need to buy more");
        buys[msg.sender] += amount;
        totalBuys += amount;
        BUSD.transferFrom(msg.sender, address(this), amount);
        bool buyerRegistered = false;

        for (uint i=0; i<buyers.length; i++){
            if (buyers[i] == msg.sender){
                buyerRegistered = true;
            }
        }

        if (!buyerRegistered){
            buyers.push(msg.sender);
        }

        emit tokenBought(msg.sender, amount);
    }

    function setWhitelist(address[] memory list, bool set) external onlyOwner{
        for (uint i=0; i < list.length; i++){
            whitelist[list[i]] = set;
        }
    }

    function withdrawToken (uint amount_, address token_) external onlyOwner {
        IERC20 _token = IERC20(token_);
        _token.transfer(msg.sender, amount_);
    }

    function setPresale() external onlyOwner{
        presale = !presale;
    }

    function getPresale() external view onlyOwner returns(address[] memory, uint[] memory){
        uint[] memory bought;
        for (uint i=0; i < buyers.length; i++){
            bought[i] = buys[buyers[i]];
        }
        return (buyers, bought);
    }

    function endPresale() external onlyOwner {
        require(totalBuys >= SOFTCAP, "Softcap not reached");
        uint amount;
        for (uint i=0; i < buyers.length; i++){
            amount += buys[buyers[i]];
        }
        amount = amount*RATE/10e17;
        token.transferFrom(address (this), bridge, amount);
        token.burn(token.balanceOf(address(this)));
    }

}

interface iToken is IERC20{
    function burn(uint amount) external;
}