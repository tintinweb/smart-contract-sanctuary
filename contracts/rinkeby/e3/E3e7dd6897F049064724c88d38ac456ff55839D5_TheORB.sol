// SPDX-License-Identifier: Unlicensed



pragma solidity 0.8.4;

// FIXME - Console Debug
// import "hardhat/console.sol"; // debugging

// Standard Imports
import "./SafeMath.sol";
import "./Context.sol";
import "./IBEP20.sol";
import "./Ownable.sol";     // need owner because of transfer LP functions


// PancakeSwap 
import "./IPancakeFactory.sol";
import "./IPancakeRouter01.sol";
import "./IPancakeRouter02.sol";



// The reason why it is ownable is so the deployer can move LP to PancakeSwap after the PreSale.

contract TheORB is Context, IBEP20, Ownable {

    using SafeMath for uint256;

    IPancakeRouter02 public pancakeswapRouter;
    address public pancakeswapPair;
    address public routerAddressForDEX;

    string private nameOfToken;
    string private symbolOfToken;
    uint8 private decimalsOfToken;
    uint256 private totalSupplyOfToken;
    
    mapping (address => uint256) private tokenBalance;
    mapping (address => mapping (address => uint256)) public allowancesOfToken;

    mapping (address => uint256) public amountORBstaked;
    mapping (address => bool) public hasStakedORB;
    mapping (address => uint256) public timeStartedStaking;


    address public deadAddress;


    bool public isAllStakingUnlocked;
    uint256 public creationDateOfcContract;
    uint256 public preSaleRate;   
    mapping(address => uint256) public ORBAmountPurchasedInPresaleInJager; 
    uint256 public timePresaleEndedAndLiquidityProvided;
    uint256 public timeStakingIsEnabled;


    
    uint256 oneDayTimer;       
    uint256 threeDaysTimer;
    uint256 fiveDaysTimer;



    
 

    // Events
    event PreSalePurchase(address indexed buyer, uint256 amountORBpurchased, uint256 amountBNBInJagerSold, uint256 totalORBAmountPurchasedInPresaleInJager);
    event AllStakingUnlocked(uint256 indexed timeAllStakingUnlocked);
    event ContractDeployed(string message);
    event MintedORB(address indexed accountMintedTo, uint256 indexed amountMinted);
    event ORBstaked(address indexed stakerAddress, uint256 indexed amountOfORBstaked, uint256 indexed timeStaked);
    event ORBunStaked(address indexed stakerAddress, uint256 indexed timeUnStaked);
    event EndedPresaleProvidedLiquidity(uint256 BNBprovidedToPancakeSwap, uint256 ORBprovidedToPancakeSwap, uint256 timePresaleEndedAndLiquidityProvided);


    constructor () {

        deadAddress = 0x0000000000000000000000000000000000000000;

        address msgSender = _msgSender();

        nameOfToken = "The ORB";
        symbolOfToken = "ORB";
        decimalsOfToken = 9;
        totalSupplyOfToken = 1 * 10**6 * 10**9; // the 10^9 is to get us past the decimal amount and the 2nd one gets us to 1 billion

        tokenBalance[address(this)] = totalSupplyOfToken;
        emit Transfer(address(0), msgSender, totalSupplyOfToken);    // emits event of the transfer of the supply from dead to owner

        emit OwnershipTransferred(address(0), msgSender);

        routerAddressForDEX = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;       // CHANGEIT - change this to pancakeswap router v2
        // routerAddressForDEX = 0x10ED43C718714eb63d5aA57B78B54704E256024E;       // v2 pancakeswap router
        IPancakeRouter02 pancakeswapRouterLocal = IPancakeRouter02(routerAddressForDEX);      // gets the router
        pancakeswapPair = IPancakeFactory(pancakeswapRouterLocal.factory()).createPair(address(this), pancakeswapRouterLocal.WETH());     // Creates the pancakeswap pair   
        pancakeswapRouter = pancakeswapRouterLocal; 



        // distribute team cut, 36,000 ORB given to team.
        // uint256 tenThousandTokens = 10000 * 10**9;
        uint256 oneThousandTokens = 1000 * 10**9;
        uint256 thirtyThousandTokens = 30000 * 10**9;
        uint256 sixThousandTokens = 6000 * 10**9;
        // uint256 fourThousandTokens = 4000 * 10**9;
        uint256 tokensToSubtractForDistribution = thirtyThousandTokens.add(sixThousandTokens);

        tokenBalance[address(this)] = tokenBalance[address(this)].sub(tokensToSubtractForDistribution);

        // CHANGEIT - get everyone's confirmed addresses
        // Primary Team Devs
        tokenBalance[0x59ed330ca05bFfbaBd4fcE758234C71f8F08cBd9] = oneThousandTokens;   // Nox
        tokenBalance[0x0C2a98ace816259c0bB369f88Dd4bcb9135E0787] = oneThousandTokens.add(sixThousandTokens);   // Yoshiko
        tokenBalance[0x2b30eca9e19B480533db8EC37fa2faC035E32082] = oneThousandTokens;   // Space Cat



        isAllStakingUnlocked = false;
        creationDateOfcContract = block.timestamp;

        // CHANGEIT - correct it after test
        // oneDayTimer = 1 days;       
        // threeDaysTimer = 3 days;
        // fiveDaysTimer = 5 days;

        oneDayTimer = 1 minutes;       
        threeDaysTimer = 10 minutes;
        fiveDaysTimer = 20 minutes;


        

        preSaleRate = 1000;


        emit ContractDeployed("The ORB Launched!");
    }

    function name() public view override returns (string memory) {
        return nameOfToken;
    }

    function symbol() public view override returns (string memory) {
        return symbolOfToken;
    }

    function decimals() public view override returns (uint8) {
        return decimalsOfToken;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupplyOfToken;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenBalance[account];
    }


    function getOwner() external view override returns (address){
        return owner();     // gets current owner address
    }



    ////////////////////////////TRANSFER FUNCTIONS////////////////////////////
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        transferInternal(_msgSender(), recipient, amount);
        return true;
    }

    function transferInternal(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");    
        require(amount != 0, "BEP20: transfer amount was 0");
        tokenBalance[sender] = tokenBalance[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        tokenBalance[recipient] = tokenBalance[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        transferInternal(sender, recipient, amount);
        approveInternal(sender, _msgSender(), allowancesOfToken[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    ////////////////////////////TRANSFER FUNCTIONS////////////////////////////





    ////////////////////////////APPROVE FUNCTIONS////////////////////////////
    function approveInternal(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allowancesOfToken[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        approveInternal(_msgSender(), spender, amount);
        return true;
    }
    ////////////////////////////APPROVE FUNCTIONS////////////////////////////






    ////////////////////////////ALLOWANCE FUNCTIONS////////////////////////////
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowancesOfToken[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        approveInternal(_msgSender(), spender, allowancesOfToken[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        approveInternal(_msgSender(), spender, allowancesOfToken[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    ////////////////////////////ALLOWANCE FUNCTIONS////////////////////////////
    

    
    ////////////////////////////MINT FUNCTIONS////////////////////////////
    function mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        totalSupplyOfToken = totalSupplyOfToken.add(amount);
        tokenBalance[account] = tokenBalance[account].add(amount);
        emit Transfer(address(0), account, amount);
        emit MintedORB(account, amount);
    }
    ////////////////////////////MINT FUNCTIONS////////////////////////////


    




    
    ////////////////////////////STAKING FUNCTIONS////////////////////////////
    function stakeORB(uint256 amountOfORBtoStake) public {

        // figure out the staking numbers of 1, you will need to multiply by 10 ** 9 somewhere to make it equal 1

        require(timeStakingIsEnabled != 0, "Staking must be enabled first.");
        require(block.timestamp > timeStakingIsEnabled, "Staking is not yet enabled, check the website for enabling staking.");
        require(!isAllStakingUnlocked, "Staking is over, you can unstake though.");

        

        address stakerAddress = _msgSender();

        require(!hasStakedORB[stakerAddress], "You have already staked ORB.");
        require(amountOfORBtoStake >= 1, "Requires at least 1 ORB to Stake.");
        require(amountOfORBtoStake <= 1000, "Maximum 1,000 ORB to Stake.");
        require(tokenBalance[stakerAddress] >= amountOfORBtoStake , "Not enough ORB in account.");

        hasStakedORB[stakerAddress] = true;
        amountORBstaked[stakerAddress] = amountOfORBtoStake;
        
        tokenBalance[stakerAddress] = tokenBalance[stakerAddress].sub(amountOfORBtoStake, "BEP20: transfer amount exceeds balance");
        tokenBalance[deadAddress] = tokenBalance[deadAddress].add(amountOfORBtoStake);
        timeStartedStaking[stakerAddress] = block.timestamp;

        emit ORBstaked(stakerAddress, amountOfORBtoStake, block.timestamp);
    }


    function unStakeORB() public {

        address stakerAddress = _msgSender();

        require(hasStakedORB[stakerAddress], "You are not staking ORB.");

        if(!isAllStakingUnlocked){      // checks to see if the unlock has happened, if not do the normal timer check
            require(block.timestamp > timeStartedStaking[stakerAddress] + threeDaysTimer, "You cannot unstake, it has not been 3 days.");
        }
        
        tokenBalance[deadAddress] = tokenBalance[deadAddress].sub(amountORBstaked[stakerAddress], "BEP20: transfer amount exceeds balance");
        tokenBalance[stakerAddress] = tokenBalance[stakerAddress].add(amountORBstaked[stakerAddress]);

        uint256 amountToMint = howMuchORBhasBeenGeneratedSoFar(stakerAddress);

        mint(stakerAddress, amountToMint);

        emit ORBunStaked(stakerAddress, block.timestamp);
    }


    function howMuchORBhasBeenGeneratedSoFar(address stakerAddress) public view returns (uint256) {
        uint256 totalAmountORBgenerated = howMuchORBafterStaking3days(amountORBstaked[stakerAddress]);

        uint256 timeUnlocked = stakeUnlockTime(stakerAddress);

        if(timeUnlocked >= block.timestamp){        // if the time unlocked is greater than the blockstamp, just return the total amount of orb to generate
            return totalAmountORBgenerated;
        }

        uint256 timeUnlockedMul100 = timeUnlocked.mul(100);
        uint256 percentOfTimeCompleted = timeUnlockedMul100.div(block.timestamp);

        uint256 totalAmountMul100 = totalAmountORBgenerated.mul(percentOfTimeCompleted); 
        uint256 amountOrbGeneratedSoFar = totalAmountMul100.div(100);

        return amountOrbGeneratedSoFar;

    }


    function stakeUnlockTime(address stakerAddress) public view returns (uint256){
        uint256 stakeUnlockTimeForStaker = timeStartedStaking[stakerAddress] + threeDaysTimer;
        return stakeUnlockTimeForStaker;
    }


    function howMuchORBafterStaking3days(uint256 amountOfOrbStaked) public pure returns (uint256){
        uint256 amountORBgenerated = amountOfOrbStaked.mul(calculateThreeDayRate());
        return amountORBgenerated;
    }


    function unlockAllStaking() public onlyOwner {
        require(timeStakingIsEnabled != 0, "Staking must be enabled first.");
        require(block.timestamp > timeStakingIsEnabled + fiveDaysTimer, "Must be at least 5 days after staking has started.");
        isAllStakingUnlocked = true;
        emit AllStakingUnlocked(block.timestamp);
    }
    ////////////////////////////STAKING FUNCTIONS////////////////////////////





    ////////////////////////////APY FUNCTIONS////////////////////////////
    function calculateAPY() public pure returns (uint256) {
        uint256 interestRate = 1000000;
        uint256 periodsInYear = 365;
        uint256 rateDivPeriods = interestRate.div(periodsInYear);
        uint256 rateAddedOne = rateDivPeriods.add(1);
        uint256 rateAddedMulPeriod = rateAddedOne.mul(periodsInYear);
        uint256 apyFiguredUp = rateAddedMulPeriod.sub(1);
        return apyFiguredUp;
    }

    function calculateThreeDayRate() public pure returns (uint256) {
        uint256 threeDayRate = calculateAPY().mul(3).div(365);
        return threeDayRate;
    }
    ////////////////////////////APY FUNCTIONS////////////////////////////








    ////////////////////////////PRESALE FUNCTIONS////////////////////////////
    function presaleBuy(uint256 keyCode) external payable {
        require(keyCode == 1337, "Don't use this contract presale function except through our website at catnip.world");

        address buyer = _msgSender();

        uint256 amountOfBNBtoInputInJager = msg.value;     // BNB input amount in Jager

        uint256 oneBNBAmountInJager = 1000000000000000000;      // 1 BNB in Jager

        require(amountOfBNBtoInputInJager >= oneBNBAmountInJager.div(100), "BNB must be at least 0.01 BNB");  
        require(amountOfBNBtoInputInJager <= oneBNBAmountInJager, "Capped at 1 BNB For This PreSale, please input less BNB.");

        uint256 amountPurchasedWithNewPurchase = ORBAmountPurchasedInPresaleInJager[buyer].add(amountOfBNBtoInputInJager);

        require(amountPurchasedWithNewPurchase <= oneBNBAmountInJager, 
            "Capped at 1 BNB (100,000,000 Jager) Per Account, please input less BNB. Check current Purchase Amount with ORBAmountPurchasedInPresaleInJager");  

        uint256 amountOfORBtoGive = amountOfBNBtoInputInJager.mul(preSaleRate).div(oneBNBAmountInJager);  // determin how much NIP to get

        uint256 totalBalanceOfORBinContract = balanceOf(address(this));
        uint256 totalBalanceAfterGive = totalBalanceOfORBinContract.sub(amountOfORBtoGive);

        uint256 amountORBminForLPCreation = 1 * 10**5 * 10**9;  // 100,000 ORB minimum should be in the contract

        require(totalBalanceAfterGive > amountORBminForLPCreation, ("Not enough ORB left in the Presale. Please check the ORB left in the contract itself and Adjust"));

        ORBAmountPurchasedInPresaleInJager[buyer] = amountPurchasedWithNewPurchase;     // sets the new nip amount an account has purchased

        approveInternal(address(this), buyer, amountOfORBtoGive.mul(10**9));   
        transferFrom(address(this), buyer, amountOfORBtoGive.mul(10**9));    
        approveInternal(address(this), buyer, 0);   

        emit PreSalePurchase(buyer, amountOfORBtoGive, amountOfBNBtoInputInJager, ORBAmountPurchasedInPresaleInJager[buyer]);  
    }


    function endPresaleProvideLiquidity() external onlyOwner {

        require(block.timestamp > creationDateOfcContract + oneDayTimer, "You cannot end the presale yet because it has not been 1 day after the creation of the contract.");

        // this will take the ORB and BNB within the contract, and provide liquidity to PancakeSwap.

        uint256 ORBinContract = balanceOf(address(this));

        uint256 BNBinContract = address(this).balance;      // why doesn't this take all the BNB in the contract?

        approveInternal(address(this), address(pancakeswapRouter), ORBinContract);    
        pancakeswapRouter.addLiquidityETH{value: BNBinContract}(address(this),ORBinContract, 0, BNBinContract, address(this), block.timestamp);     // adds the liquidity

        timePresaleEndedAndLiquidityProvided = block.timestamp;
        timeStakingIsEnabled = timePresaleEndedAndLiquidityProvided + oneDayTimer;

        emit EndedPresaleProvidedLiquidity(BNBinContract, ORBinContract, timePresaleEndedAndLiquidityProvided);  
    }
    ////////////////////////////PRESALE FUNCTIONS////////////////////////////


    receive() external payable { }      // oh it's payable alright

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
// https://github.com/binance-chain/bsc-genesis-contract/blob/master/contracts/bep20_template/BEP20Token.template
// https://docs.binance.org/smart-chain/developer/BEP20.html

pragma solidity ^0.8.4;


interface IBEP20 {

    // Functions
    
    function totalSupply() external view returns (uint256);     // Returns the amount of tokens in existence.

    function decimals() external view returns (uint8);  // Returns the token decimals.

    function symbol() external view returns (string memory); // Returns the token symbol.

    function name() external view returns (string memory); // Returns the token name.

    function getOwner() external view returns (address); // Returns the bep token owner.

    function balanceOf(address account) external view returns (uint256);   // Returns the amount of tokens owned by `account`
    
    function transfer(address recipient, uint256 amount) external returns (bool);  // transfer tokens to addr, Emits a {Transfer} event.

    function allowance(address _owner, address spender) external view returns (uint256); // Returns remaining tokens that spender is allowed during {approve} or {transferFrom} 

    function approve(address spender, uint256 amount) external returns (bool); // sets amount of allowance, emits approval event

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // move amount, then reduce allowance, emits a transfer event


    // Events

    event Transfer(address indexed from, address indexed to, uint256 value);    // emitted when value tokens moved, value can be zero

    event Approval(address indexed owner, address indexed spender, uint256 value);  // emits when allowance of spender for owner is set by a call to approve. value is new allowance

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";
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
// https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
// https://github.com/pancakeswap/pancake-swap-core

pragma solidity ^0.8.4;
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);      // creates pair of BNB and token

    function feeTo() external view returns (address);       // gives a fee to the LP provider?
    function feeToSetter() external view returns (address);     // gives a fee to the LP setter?

    function getPair(address tokenA, address tokenB) external view returns (address pair);  // gets the address of the LP token pair
    function allPairs(uint) external view returns (address pair);       // gets address of all the pairs? not sure
    function allPairsLength() external view returns (uint);     // gets the length?

    function createPair(address tokenA, address tokenB) external returns (address pair);    // creates the pair

    function setFeeTo(address) external;        // sets a fee to an address
    function setFeeToSetter(address) external;  // sets fee to the setter address

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol
// https://github.com/pancakeswap/pancake-swap-periphery


// TODO - might want to change the ETH name to BNB, but that might not work because it's that way in pancake swap I think

pragma solidity ^0.8.4;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) 
        external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) 
        external returns (uint amountA, uint amountB);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit( address tokenA, address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountA, uint amountB);
        
    function removeLiquidityETHWithPermit(address token, uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}

// SPDX-License-Identifier: MIT
// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol
// https://github.com/pancakeswap/pancake-swap-periphery

// TODO - might want to change the ETH name to BNB, but that might not work because it's that way in pancake swap I think

pragma solidity ^0.8.4;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

