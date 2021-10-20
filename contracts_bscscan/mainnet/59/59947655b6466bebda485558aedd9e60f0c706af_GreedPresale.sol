/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
    constructor() internal {
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract GreedPresale is Ownable {
    using SafeMath for uint256;

    IBEP20 public TOKEN;

    uint256 public sellStartAt = 1635004800; // Oct 23rd, 2021 04:00:00 PM UTC
    uint256 public sellEndAt = 1635091200; // Oct 24th, 2021 04:00:00 PM UTC
    bool public claimEnabled = false;

    uint256 public tokenPerBnb = 50000 ether; // token price per bnb
    uint256 public totalTokensToSell = 1500000 ether; // 500k tokens for sell
    uint256 public minPerTransaction = 0; // min amount per transaction
    uint256 public maxPerUserInBnb = 5 ether; // max token amount per user in BNB
    uint256 public totalSold;

    mapping(address => uint256) public tokenPerAddresses;

    event tokensBought(address indexed user, uint256 amountSpent, uint256 amountBought, string tokenName, uint256 date);
    event tokensClaimed(address indexed user, uint256 amount, uint256 date);

    modifier checkSaleRequirements(uint256 buyAmount) {
        require(now >= sellStartAt && now < sellEndAt, 'Presale time mismatch');
        require(buyAmount > 0 && buyAmount <= unsoldTokens(), 'Insufficient buy amount');
        _;
    }

    constructor(address _TOKEN) public {
        TOKEN = IBEP20(_TOKEN);
    }

    // Function to buy TOKEN using BNB token
    function buyWithBNB(uint256 buyAmount) public payable checkSaleRequirements(buyAmount) {
        uint256 amount = calculateBNBAmount(buyAmount);
        require(msg.value >= amount, 'Insufficient BNB balance');
        require(buyAmount >= minPerTransaction, 'Lower than the minimal transaction amount');

        uint256 sumSoFar = tokenPerAddresses[msg.sender].add(buyAmount);
        require(sumSoFar <= maxTokenAmountPerUser(), 'Greater than the maximum purchase limit');

        tokenPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(buyAmount);

        emit tokensBought(msg.sender, amount, buyAmount, 'BNB', now);
    }

    // Max token amount per user
    function maxTokenAmountPerUser() internal view returns (uint256) {
        return maxPerUserInBnb.mul(tokenPerBnb);
    }

    // Function to claim
    function claimToken() external {
        require(claimEnabled == true, 'GreedPresale: Claim disabled');
        uint256 boughtAmount = tokenPerAddresses[msg.sender];
        require(boughtAmount > 0, 'Insufficient token amount');
        TOKEN.transfer(msg.sender, boughtAmount);
        tokenPerAddresses[msg.sender] = 0;

        emit tokensClaimed(msg.sender, boughtAmount, now);
    }

    // function to set the presale start date
    // only owner can call this function
    function setSellStartDate(uint256 _sellStartAt) external onlyOwner {
        require(now < _sellStartAt, 'GreedPresale: sale start date should be later time');
        require(_sellStartAt < sellEndAt, 'GreedPresale: sale start date should be before end date');
        sellStartAt = _sellStartAt;
    }

    // function to set the presale end date
    // only owner can call this function
    function setSellEndDate(uint256 _sellEndAt) external onlyOwner {
        require(now < _sellEndAt, 'GreedPresale: sale end date should be later time');
        require(sellStartAt < _sellEndAt, 'GreedPresale: sale end date should be after start date');
        sellEndAt = _sellEndAt;
    }

    // function to set the token claimable status
    // only owner can call this function
    function setClaimable(bool _claimable) external onlyOwner {
        claimEnabled = _claimable;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTotalTokensToSell(uint256 _totalTokensToSell) external onlyOwner {
        totalTokensToSell = _totalTokensToSell;
    }

    // function to set the token price per bnb
    // only owner can call this function
    function setTokenPerBnb(uint256 _tokenPerBnb) external onlyOwner {
        require(_tokenPerBnb > 0, "GreedPresale: invalid token per bnb value");
        tokenPerBnb = _tokenPerBnb;
    }

    //function to withdraw collected tokens by sale.
    //only owner can call this function
    function withdrawCollectedTokens() external onlyOwner {
        require(address(this).balance > 0, 'Insufficient balance');
        payable(msg.sender).transfer(address(this).balance);
    }

    //function to withdraw unsold tokens
    //only owner can call this function
    function withdrawUnsoldTokens() external onlyOwner {
        uint256 remainedTokens = unsoldTokens();
        require(remainedTokens > 0, 'No remained tokens');
        TOKEN.transfer(msg.sender, remainedTokens);
    }

    //function to return the amount of unsold tokens
    function unsoldTokens() private view returns (uint256) {
        // return totalTokensToSell.sub(totalSold);
        return TOKEN.balanceOf(address(this));
    }

    //function to calculate the quantity of TOKEN based on the TOKEN price of bnbAmount
    function calculateTokenAmount(uint256 bnbAmount) public view returns (uint256) {
        uint256 tokenAmount = tokenPerBnb.mul(bnbAmount).div(1 ether);
        return tokenAmount;
    }

    //function to calculate the quantity of bnb needed using its TOKEN price to buy `buyAmount` of TOKEN
    function calculateBNBAmount(uint256 tokenAmount) public view returns (uint256) {
        require(tokenPerBnb > 0, 'TOKEN price per BNB should be greater than 0');
        uint256 bnbAmount = tokenAmount.mul(1 ether).div(tokenPerBnb);
        return bnbAmount;
    }
}