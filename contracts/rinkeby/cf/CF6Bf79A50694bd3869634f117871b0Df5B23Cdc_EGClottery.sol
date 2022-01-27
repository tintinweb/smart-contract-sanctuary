//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/BEP20/IBEP20.sol";
import "../interfaces/BEP20/IBEP20Metadata.sol";
import "../rewards/RewardsWallet.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EGClottery is 
    IBEP20, 
    IBEP20Metadata, 
    Context, 
    Ownable 
{
    using SafeMath for uint256;

    /* 
    BEP20
    */
    uint256 private _totalSupply;

    // BEP20 Metadata:
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


    /* 
    Dividends
    */
    // How many days are dividends paid
    uint256 private distributionDay = 1;
    // The period for which the dividends are calculated
    uint256 private distributionPeriod;
    uint256 private multiplier = 10e18;

    /*
        Mapping to ensure that addresses controlled 
        by 1 user cannot claim dividends multiple times
    */
    mapping(address => mapping(uint256 => uint256)) private sharePerDay;

    event DividendsClaimed(address _beneficiary, uint256 _amount);
    event DistributionDayPassed(uint256 _newDay);
    
    /*
    ***TOKENOMICS***

    1. 6% of every transaction as passive income in EverGrow
    2. 5% of ever transaction goes to the lottery pool
    3. 3% goes to the pancakeswap liquidity pool
    4. 1% goes to a buy back and burn wallet
    */

    /* 
    Fees
    */
    uint256 private EGCincome = 6;
    uint256 private lotteryPoolFee = 5;
    uint256 private pancakeSwapLPfee = 3;
    uint256 private burn = 1;

    // For PinkSale pre-sale
    mapping(address => bool) private excludedFromFee;

    /* 
    Wallets
    */
    address private pancakeSwapLP = 0x15314C9e4284D228a93Ead5C4d0d97cF0F67030F;
    address private lotteryPool = 0xeABc22379F929Df75aC847b971c5Fa5Ab2cf9799;
    address private burnWallet = 0x1e35087485b3fE244E7C40A6145aCd0C10c18071;
    RewardsWallet private rewardsWallet = RewardsWallet(0x2b35eFA92746595E7c4Eac2D7a61a587EFAeEbFd);
    IBEP20 private EGCreward = IBEP20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa); // DAI for testing
    //address private EGCreward = 0x5eA2D04F0BCECe3E801379Dc9Cbc093a06E134d3;
    //address private rewardsWallet = 0x42EB768f2244C8811C63729A21A3569731535f06;

    /* 
    MODIFIERS
    */
    /*
    modifier distributionDayCheck {
        if (distributionPeriod < block.timestamp) {
            distributionDay++;
            distributionPeriod = block.timestamp + 5 minutes;
            rewardsWallet.convertToEGC();
            emit DistributionDayPassed(distributionDay);
        }
        _;
    }
    */

    modifier onlyContract {
        require(_msgSender() == address(this), "Access denied");
        _;
    }

    modifier onlyRW {
        require(_msgSender() == address(rewardsWallet), "Access denied");
        _;
    }

    constructor() {
        _name = "TestToken"; // EGClottery
        _symbol = "TTKN"; // EGCL
        _decimals = 9;

        address lockedBurnWallet = 0xC979d6013868f49Bf4593743592C9D967B1300f7;
        address lp = 0xC979d6013868f49Bf4593743592C9D967B1300f7;
        address teamWallet = 0xC979d6013868f49Bf4593743592C9D967B1300f7;
        address marketingWallet = 0xC979d6013868f49Bf4593743592C9D967B1300f7;

        /*
        initial supply := 1,000,000,000,000,000

        1. 50% pre-sale
        2. 30% burn in a locked wallet
        3. 20% liquidity
        4. 7% team wallet that is locked for 1 year
        5. 3% for marketing and airdrop
        */
        uint256 initSupply = 1000000000000000*10e9;

        uint256 preSale = initSupply.div(2); // 500000000000000 EGCL ---> Pre-sale
        //amount to use in PinkSale
        _mint(msg.sender, preSale);
        uint256 burnAmount = initSupply * 30 / 100; // 300000000000000 EGCL ---> Burn and BuyBack wallet
        _mint(lockedBurnWallet, burnAmount);
        uint256 liquidity = initSupply * 20 / 100; // 200000000000000 EGCL ---> For Liquidity
        _mint(lp, liquidity);
        uint256 teamWalletDist = initSupply * 7 / 100; // 70000000000000 EGCL ---> TeamWallet
        _mint(teamWallet, teamWalletDist);
        uint256 marketingDist = initSupply * 3 / 100; // 30000000000000 EGCL ---> Marketing
        _mint(marketingWallet, marketingDist);

        distributionPeriod = block.timestamp + 5 minutes;
    }

    /* 
    GETTER FUNCTIONS
    <for BEP20 metadata>
    */
    function name() public view override returns (string memory) {return _name;}
    function symbol() public view override returns (string memory) {return _symbol;}
    function decimals() public view override returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function getOwner() external view override returns(address) {return owner();}

    /* 
    GETTER FUNCTIONS
    <for fees>
    */
    function getPancakeLPFee() external view returns(uint256) {
        return pancakeSwapLPfee;
    }

    function getEGCincome() external view returns(uint256) {
        return EGCincome;
    }

    function getLotteryPoolFee() external view returns(uint256) {
        return lotteryPoolFee;
    }
    
    function getBurnWalletFee() external view returns(uint256) {
        return burn;
    }

    /* 
    GETTER FUNCTIONS
    <for wallets>
    */
    function getPancakeLPAddres() external view returns(address) {
        return pancakeSwapLP;
    }

    function getLotteryPoolAddress() external view returns(address) {
        return lotteryPool;
    }

    function getBurnWallet() external view returns(address) {
        return burnWallet;
    }

    function getRewardsWallet() external view returns(address) {
        return address(rewardsWallet);
    }

    /* 
    GETTER FUNCTIONS
    <for dividends>
    */
    function getDistributionDay() external view returns(uint256) {
        return distributionDay;
    }

    function getSharePerDay(address _shareholder, uint256 _day) external view returns(uint256) {
        return sharePerDay[_shareholder][_day];
    }
    /* 
    BEP20 SETTER FUNCTIONS
    */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to this address is unavailable");

        // Checks for whitelisted addresses
        if (excludedFromFee[sender] == true || excludedFromFee[recipient] == true) {
            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
                _balances[sender] = senderBalance - amount;
                sharePerDay[sender][distributionDay] = calculateShare(sender);
                _balances[recipient] += amount;
            /*
            Keeping track of user's share to ensure
            he can claim dividends only once
            */
            sharePerDay[recipient][distributionDay] = calculateShare(recipient);

            emit Transfer(sender, recipient, amount);
        } else {
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        /*
        Calculating the fees
        */
        uint256 EGCfee = amount.mul(EGCincome).div(100);
        uint256 lotteryFee = amount.mul(lotteryPoolFee).div(100);
        uint256 lpFee = amount.mul(pancakeSwapLPfee).div(100);
        //uint256 toBurn = amount.mul(burn).div(100);

            _balances[sender] = senderBalance - amount;
            sharePerDay[sender][distributionDay] = _balances[sender];

        /*
        Distributing fees between wallets + burning
        */
        _balances[pancakeSwapLP] += lpFee;
        _balances[lotteryPool] += lotteryFee;
        _balances[address(rewardsWallet)] += EGCfee;
        //_burn(sender, toBurn);

        /*
        The final number of tokens that the user will receive with the deduction of fees
        */
        //uint256 amountToRecipient = amount - EGCfee - lotteryFee - lpFee - toBurn;
        uint256 amountToRecipient = amount - EGCfee - lotteryFee - lpFee;
        _balances[recipient] += amountToRecipient;
        sharePerDay[recipient][distributionDay] = _balances[recipient];

        emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _balances[burnWallet] += amount;
        _totalSupply -= amount;

        emit Transfer(account, burnWallet, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /*
    WHITELIST FUNCTIONS
    */
    function excludeFromFee(address _account) external onlyOwner {
        excludedFromFee[_account] = true;
    }

    function includeFee(address _account) external onlyOwner {
        excludedFromFee[_account] = false;
    }

    /*
    DIVIDENDS FUNCTIONS
    */

    
    /*
    Calculation process:
        The distribution of dividends is based on what % is the number
        of user's tokens from the total supply
    */
    
    function calculateDividends(address _shareholder, uint256 _day) internal view onlyContract returns(uint256) {
        uint256 _share = sharePerDay[_shareholder][_day];
        //Dividends in EGC token
        return rewardsWallet.getEGCbalancePerDay(_day).mul(_share.div(100));
    }

    function calculateShare(address _shareholder) internal returns(uint256) {
        return balanceOf(_shareholder).mul(multiplier).div(totalSupply());
    }

    function claimDividends(address _beneficiary) external onlyRW returns(uint256) {
        // Calculating all dividends available
        uint256 dividendsTotal;
        for (uint256 i = 1; i != (distributionDay+1); i++) {
            dividendsTotal += calculateDividends(_msgSender(), i);
            sharePerDay[_beneficiary][i] = 0;
        }
        require(dividendsTotal != 0 && dividendsTotal <= rewardsWallet.getEGCbalanceOfRW());

        return dividendsTotal;
    }

    // REMOVE
    function del() public onlyOwner {
        selfdestruct(payable(_msgSender()));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IBEP20.sol";

interface IBEP20Metadata is IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/BEP20/IBEP20.sol";
import "../interfaces/pancake/IPancakeRouter02.sol";
import "../interfaces/pancake/IPancakeFactory.sol";
import "../token/EGClottery.sol";

contract RewardsWallet is Context, Ownable {
    IBEP20 public EGC = IBEP20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa); // DAI for testing
    EGClottery EGCL;
    IBEP20 public WBNB = IBEP20(0xc778417E063141139Fce010982780140Aa0cD5Ab); // WETH for testing
    IPancakeRouter02 public router = IPancakeRouter02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // SushiSwap for testing

    uint256 private _distributionDay = 1;
    mapping(uint256 => uint256) private rewardsWalletBalancePerDay;

    modifier onlyEGCL {
        require(_msgSender() == address(EGCL));
        _;
    }

    function convertToEGC() external onlyEGCL {
        EGC.approve(address(router), EGC.balanceOf(address(this)));

        // EGCL --> BNB --> EGC;
        address[] memory path;
        path[0] = address(EGCL);
        path[1] = address(WBNB);
        path[2] = address(EGC);
        
        uint256 _amountIn = EGCL.balanceOf(address(this));
        uint256 _amountOutMin = getAmountOutMin(address(EGCL), address(EGC), getEGCLbalance());
        uint256 _deadline = block.timestamp + 3 minutes;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, path, address(this), _deadline);
        rewardsWalletBalancePerDay[_distributionDay] = _amountOutMin;
        _distributionDay++;
    }

    function setEGCLaddress(address _EGCL) external onlyOwner {
        EGCL = EGClottery(_EGCL);
    }

     function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal view returns(uint256) {
        address[] memory path;
        path[0] = _tokenIn;
        path[1] = address(WBNB);
        path[2] = _tokenOut;

        uint256[] memory amountOutMins = router.getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function getEGCbalanceOfRW() public view returns(uint256) {
        return EGC.balanceOf(address(this));
    }

    function getEGCLbalance() public view returns(uint256) {
        return EGCL.balanceOf(address(this));
    }

    function getEGCbalancePerDay(uint256 _day) external view returns(uint256) {
        return rewardsWalletBalancePerDay[_day];
    }

    function withdrawDividends() external {
        require(getEGCbalanceOfRW() > 0, "EGC balance is zero");
        uint256 _dividends = EGCL.claimDividends(_msgSender());
        EGC.transfer(_msgSender(), _dividends);
    }

    // REMOVE
    function del() public onlyOwner {
        selfdestruct(payable(_msgSender()));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}