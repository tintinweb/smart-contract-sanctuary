/**
 *Submitted for verification at cronoscan.com on 2022-05-31
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
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
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/3_Ballot.sol



pragma solidity 0.8.13;



interface ITOKEN {
    function balanceOf(address) external view returns (uint256);
}

contract CROLotterySteakhouse is Ownable {

    struct DISCOUNT_INFO {
        address tokenAddress;
        uint256 fee;
        uint256 minimumHolding;
        uint256 tokenType;
    }

    uint256 private STEAK_TO_HATCH_1cheffs = 1728000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 3;
    uint256 private marketingFeeVal = 1;
    bool private initialized = false;
    address payable private devWallet;
    address payable private marketWallet = payable(0xcBd3E8B401F659C4037074cF2946f359de1c12e4);
    mapping (address => uint256) private GrillingCheffs;
    mapping (address => uint256) private claimedSteak;
    mapping (address => uint256) private lastGrill;
    mapping (address => address) private referrals;
    uint256 private marketSteak;
    mapping(address => uint256) private lastSell;
    uint256 public WITHDRAW_COOLDOWN = 6 days;
    DISCOUNT_INFO[] private discountTokens;
    mapping(address => uint256) discountTokenIndex;
    uint256 private chefCount;
    address[] private chefs;
    uint256 public lotteryTime;
    uint256 public lotteryInterval = 7 days;
    uint256 public bonusPercent = 1;
    address public lastWinner;
    uint256 public lastReward;
        
    constructor(address _market) {
        devWallet = payable(msg.sender);
        marketWallet = payable(_market);
        lotteryTime = block.timestamp + lotteryInterval;
    }
    
    function reGrill(address ref) public {
        require(initialized);

        if (block.timestamp > lotteryTime) {
            lotteryTime = lotteryTime + lotteryInterval;
            uint256 winnerIdx = _getRand() % chefCount;
            rewardWinner(chefs[winnerIdx]);
        }
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 MeatGrilled = getMySteak(msg.sender);
        uint256 newCheffs = MeatGrilled / STEAK_TO_HATCH_1cheffs;
        GrillingCheffs[msg.sender] = GrillingCheffs[msg.sender] + newCheffs;
        claimedSteak[msg.sender] = 0;
        lastGrill[msg.sender] = block.timestamp;
        
        //send referral 
        claimedSteak[referrals[msg.sender]] = claimedSteak[referrals[msg.sender]] + MeatGrilled/20;
        
        //boost market to nerf MasterChefs 
        marketSteak=marketSteak + MeatGrilled / 5;
    }
    
    function eatSteak() public {
        require(initialized);
        require(lastSell[msg.sender] + WITHDRAW_COOLDOWN <= block.timestamp, "You can't withdraw yet");
        uint256 hasMeat = getMySteak(msg.sender);
        uint256 meatValue = calculateSteakSell(hasMeat);
        uint256 fee = devFee(meatValue);
        uint256 mfee = marketingFee(meatValue);
        claimedSteak[msg.sender] = 0;
        lastGrill[msg.sender] = block.timestamp;
        marketSteak = marketSteak + hasMeat;
        devWallet.transfer(fee);
        marketWallet.transfer(mfee);
        payable(msg.sender).transfer(meatValue-fee-mfee);
        lastSell[msg.sender] = block.timestamp;
    }
    
    function steakRewards(address adr) public view returns(uint256) {
        uint256 hasMeat = getMySteak(adr);
        uint256 meatValue = calculateSteakSell(hasMeat);
        return meatValue;
    }
    
    function grillSteak(address ref) public payable {
        require(initialized);
        uint256 contractBalance = address(this).balance;
        uint256 meatBought = calculateSteakBuy(msg.value, contractBalance);
        meatBought = meatBought - devFee(meatBought) - marketingFee(meatBought);
        uint256 fee = devFee(msg.value);
        uint256 mfee = marketingFee(msg.value);
        devWallet.transfer(fee);
        marketWallet.transfer(mfee);
        claimedSteak[msg.sender] = claimedSteak[msg.sender] + meatBought;
        if (GrillingCheffs[msg.sender] == 0) {
            chefCount += 1;
            chefs.push(msg.sender);
        }
        reGrill(ref);
        lastSell[msg.sender] = block.timestamp;
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs) / (PSNH + (((PSN*rs) + (PSNH*rt)) / rt));
    }
    
    function calculateSteakSell(uint256 meats) public view returns(uint256) {
        return calculateTrade(meats,marketSteak,address(this).balance);
    }
    
    function calculateSteakBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSteak);
    }
    
    function calculateSteakBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSteakBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        uint256 discountFee = getDevFee();

        return amount*discountFee/100;
    }

    function getDevFee() public view returns(uint256) {
        uint256 discountFee = devFeeVal;
        for (uint256 i = 0; i < discountTokens.length; i++) {
            DISCOUNT_INFO storage info = discountTokens[i];
            ITOKEN token = ITOKEN(info.tokenAddress);
            if (token.balanceOf(msg.sender) >= info.minimumHolding) {
                if (info.fee < discountFee)
                    discountFee = info.fee;
            }
        }
        return discountFee;
    }

    function marketingFee(uint256 amount) private view returns(uint256) {
        return amount*marketingFeeVal/100;
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketSteak == 0);

        initialized = true;
        marketSteak = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyChefs(address adr) public view returns(uint256) {
        return GrillingCheffs[adr];
    }
    
    function getMySteak(address adr) public view returns(uint256) {
        return claimedSteak[adr] + getSteakSinceLastGrill(adr);
    }
    
    function getSteakSinceLastGrill(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(STEAK_TO_HATCH_1cheffs, block.timestamp - lastGrill[adr]);
        return secondsPassed * GrillingCheffs[adr];
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function addOrUpdateDiscountToken(address _address, uint256 _fee, uint256 _minimum, uint256 _type) external onlyOwner {
        if (discountTokenIndex[_address] == 0) {
            discountTokens.push(DISCOUNT_INFO(_address, _fee, _minimum, _type));
            discountTokenIndex[_address] = discountTokens.length;
        }
        else {
            uint256 tokenIndex = discountTokenIndex[_address] - 1;
            discountTokens[tokenIndex] = DISCOUNT_INFO(_address, _fee, _minimum, _type);
        }
    }

    function removeDiscountToken(address _address) external onlyOwner {
        require(discountTokenIndex[_address] > 0, "Invalid Address");
        uint256 tokenIndex = discountTokenIndex[_address] - 1;
        uint256 lastIndex = discountTokens.length - 1;
        discountTokens[tokenIndex] = discountTokens[lastIndex];
        discountTokens.pop();
        delete discountTokenIndex[_address];
    }

    function getInvestorCount() external view returns (uint256) {
        return chefCount;
    }

    function _getRand() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(blockhash(block.number - 1),block.timestamp,block.difficulty, msg.sender))); 
    }

    function rewardWinner(address _winner) internal {
        require(initialized);
        
        uint256 winnings = (address(this).balance * bonusPercent) / 100;
        payable(_winner).transfer(winnings);
        lastWinner = _winner;
        lastReward = winnings;
    }
}