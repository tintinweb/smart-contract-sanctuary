/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

pragma solidity 0.6.2;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract PrivateSale is Context, Ownable {
    using SafeMath for uint256;

    IBEP20 public AM;
    uint256 public maxMintable;
    uint256 public totalMinted;
    uint256 public minValue;
    uint256 public maxValue;
    uint256 public exchangeRate;
    uint256 public startTime;
    uint256 public duration;
    uint256 public percentOnStart;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _claimed;
    mapping (address => bool) private _whitelist;

    modifier isCorrectValue() {
        _;
        require(_balances[msg.sender] >= minValue, "Is Not Correct Value");
        require(_balances[msg.sender] <= maxValue, "Is Not Correct Value");
    }

    modifier isWhitelisted(){
        require(_whitelist[msg.sender], "Your not on the whitelist.");
        _;
    }

    constructor(uint256 _startTime, uint256 _duration, address token, uint256 _maxMintable, uint256 _maxValue, uint256 _minValue, uint256 _exchangeRate, address[] memory _addresses, uint256 _percentOnStart) public {
        maxMintable = _maxMintable;
        maxValue = _maxValue;
        minValue = _minValue;
        exchangeRate = _exchangeRate;
        totalMinted = 0;
        AM = IBEP20(token);
        addToWhitelist(_addresses);
        percentOnStart = _percentOnStart;
        duration = _duration;
        startTime = _startTime;
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for(uint256 index = 0; index < _addresses.length; index++){
            _whitelist[_addresses[index]] = true;
        }
    }

    function removeFromWhitelist(address[] memory _addresses) public onlyOwner {
        for(uint256 index = 0; index < _addresses.length; index++){
            _whitelist[_addresses[index]] = false;
        }
    }

    function updateToken(address _token) external onlyOwner returns (bool) {
        AM = IBEP20(_token);

        return true;
    }

    function updateStartTime(uint256 _startTime) external onlyOwner returns (bool) {
        startTime = _startTime;

        return true;
    }

    function updatePercentOnStart(uint256 _percentOnStart) external onlyOwner returns (bool) {
        percentOnStart = _percentOnStart;

        return true;
    }

    function updateDuration(uint256 _duration) external onlyOwner returns (bool) {
        duration = _duration;

        return true;
    }

    function updateRate(uint256 rate) external onlyOwner returns (bool) {
        exchangeRate = rate;

        return true;
    }

    function updateMinValue(uint256 min) external onlyOwner returns (bool) {
        minValue = min;

        return true;
    }

    function updateMaxValue(uint256 max) external onlyOwner returns (bool) {
        maxValue = max;

        return true;
    }

    function updateMaxMintable(uint256 max) external onlyOwner returns (bool) {
        maxMintable = max;

        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function whitelistOf(address account) external view returns (bool) {
        return _whitelist[account];
    }

    function claimedOf(address account) external view returns (uint256) {
        return _claimed[account];
    }

    /**
     * @dev Private function to send BNB from the contract address to the provided wallet address
     */
    function _transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    /**
     * @dev Function limited to the owner - transfers BNB from the contract to the provided wallet address
     */
    function transferToAddressETH(address payable recipient, uint256 amount) public onlyOwner {
        _transferToAddressETH(recipient, amount);
    }

    /**
     * @dev Function limited to the owner - transfers IBEP20 from the contract to the provided wallet address
     */
    function transferToAddressToken(address recipient, address token, uint256 amount) public onlyOwner {
        IBEP20 _token = IBEP20(token);
        _token.transfer(recipient, amount);
    }
    
    function _vestedAmount(address sender) private view returns (uint256) {
        uint256 onStart = _balances[sender].mul(percentOnStart).div(100);
        uint256 rest = _balances[sender].mul(100-percentOnStart).div(100);
        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp > startTime + duration) {
            return _balances[sender].sub(_claimed[sender]);
        } else {
            return onStart.add((rest * (block.timestamp - startTime)) / duration).sub(_claimed[sender]);
        }
    }
    
    function vestedAmount() public view returns (uint256) {
        return _vestedAmount(msg.sender);
    }
    
    function claim() isWhitelisted public {
        uint256 amount = _vestedAmount(msg.sender);
        require(amount > 0);
        _claimed[msg.sender] = _claimed[msg.sender].add(amount);
        AM.transfer(msg.sender, amount);
    }
    
    receive() external isWhitelisted isCorrectValue payable {
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += amount;
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

}