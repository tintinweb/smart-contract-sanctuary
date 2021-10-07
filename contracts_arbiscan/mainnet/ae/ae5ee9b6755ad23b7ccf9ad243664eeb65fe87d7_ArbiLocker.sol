/**
 *Submitted for verification at arbiscan.io on 2021-09-23
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol



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

// File: ArbiLocker.sol

pragma solidity ^0.8.0;



contract ArbiLocker is Ownable {

    uint counter;
    uint public lpFee;
    uint public ethFee;

    mapping (address => uint[]) public addressToIds;
    mapping (uint => Safe) public idToSafe;

    struct Safe {
        address owner;
        address token;
        uint amount;
        uint unlock;
        bool active;
    }
    
    constructor() {
        ethFee = 1*(10**17); //0.1 eth
        lpFee = 100; //1%
    }

    function setBurnAmount(uint amount) onlyOwner public {
        ethFee = amount;
    }

    function setFeePercent(uint amount) onlyOwner public {
        lpFee = amount;
    }

    function depositForLP(address user, address token, uint amount, uint length) public returns(uint id) {
        //costs a set percentage of tokens deposited
        require(amount > 1000, "Deposit too low");
        require(length > 0 && length < 10000, "9999 days max lock");
        address _owner = owner();
        uint leftoverAmount;
        uint fee;
        IERC20 lp = IERC20(token);
        lp.transferFrom(msg.sender, address(this), amount);
        fee = amount / lpFee;
        leftoverAmount = amount - fee;
        require((leftoverAmount + fee) <= amount, "Error in rounding");
        lp.transfer(_owner, fee);
        Safe memory newSafe;
        newSafe.owner = user;
        newSafe.token = token;
        newSafe.amount = leftoverAmount;
        newSafe.unlock = block.timestamp + (length * 1 days); 
        newSafe.active = true;
        addressToIds[msg.sender].push(counter);
        idToSafe[counter] = newSafe;
        counter++;
        return(counter -1);
    }

    function depositForEth(address user, address token, uint amount, uint length) public payable returns(uint id) {
        //burns a set amount of ArbiLocker tokens
        require(amount > 1000, "Deposit too low");
        require(length > 0 && length < 10000, "9999 days max lock");
        require(msg.value == ethFee,"Please include fee");
        address _owner = owner();
        IERC20 lp = IERC20(token);
        lp.transferFrom(msg.sender, _owner, amount);
        Safe memory newSafe;
        newSafe.owner = user;
        newSafe.token = token;
        newSafe.amount = amount;
        newSafe.unlock = block.timestamp + (length * 1 days);
        newSafe.active = true;
        addressToIds[msg.sender].push(counter);
        idToSafe[counter] = newSafe;
        counter++;
        return(counter -1);
    }
    
    function unlock(uint id) public {
        require(idToSafe[id].owner == msg.sender, "Not the owner of this safe");
        require(idToSafe[id].unlock <= block.timestamp, "Still locked");
        IERC20 lp = IERC20(idToSafe[id].token);
        lp.transfer(msg.sender, idToSafe[id].amount);
        idToSafe[id].amount = 0;
        idToSafe[id].active = false;
    }
    
    function getSafe(uint id) view public returns(Safe memory) {
        Safe memory res = idToSafe[id];
        return(res);
    }
    
    function getIds(address user) view public returns(uint[] memory) {
        uint total = addressToIds[user].length;
        uint[] memory res = new uint[](total);
        uint i;
        uint ticker;
        while(i < total) {
            address _owner = idToSafe[ticker].owner;
            if(_owner == msg.sender) { 
                res[i] = ticker; 
                i++; 
            }
            ticker++;
        }
        return(res);
    }
}