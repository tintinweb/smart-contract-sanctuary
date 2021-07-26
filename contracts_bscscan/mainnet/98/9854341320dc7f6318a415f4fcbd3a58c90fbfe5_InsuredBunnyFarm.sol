/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

/**
 * CookieFinance
 * App:             https://cookiebake.finance
 * Medium:          https://medium.com/@cookiefinance    
 * Twitter:         https://twitter.com/cookiedefi 
 * Telegram:        https://t.me/cookiedefi 
 * Announcements:   https://t.me/cookiefinance
 * GitHub:          https://github.com/cookiedefi
 */
 
pragma solidity 0.6.12;

// SPDX-License-Identifier: UNLICENSED

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ChipsStaking {
    function depositFor(address player, uint256 amount) external;
    function distributeDivs(uint256 amount) external;
}

interface OracleSimpleBNBBunny {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}

interface OracleSimpleBNBchips {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}

interface CookieGovernance {
    function pullCollateral(uint256 amount) external returns (uint256 compensation);
    function compensationAvailable(address farm) external view returns (uint256);
}

interface BunnyPool {
    function deposit(uint256 _amount) external;
    function getReward() external;
    function withdraw(uint256 _amount) external;
    function withdrawAll() external;
    function profitOf(address account) external view returns (uint _usd, uint _bunny, uint _bnb);
}

interface WBNB {
    function withdraw(uint wad) external;
}

interface UniswapV2 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
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
    constructor() public {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract InsuredBunnyFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    ERC20 constant bunny = ERC20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);
    ERC20 constant wbnb = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 constant chips = ERC20(0x1e584D356db17deCFA474Fb9669Fa7D2f181eE4E);
    ERC20 constant chipsLP = ERC20(0x742d99d675cDB0b339F0BDC4453f66f75985573d); //Cake LP

    ChipsStaking chipsStaking = ChipsStaking(0x1E822a7f027Cd8e56DA8D9220A82AADF878dD233);
    BunnyPool constant bunnyPool = BunnyPool(0xCADc8CB26c8C7cB46500E61171b5F27e9bd7889D);
    
    OracleSimpleBNBBunny bunnyTwap = OracleSimpleBNBBunny(0x95b71F3a533C4595964282a4fa4F4F3c86809a42); //Cake LP
    OracleSimpleBNBchips chipsTwap = OracleSimpleBNBchips(0x8595346f2Dc71Aa72F9c8340493D445835281c3F); //Cake LP
    UniswapV2 cake = UniswapV2(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Cake Router 
    CookieGovernance governance = CookieGovernance(0x508E510E162D7539aC13BB3F0Edd26a0cFc20eAe);

    mapping(address => uint256) public balances;
    mapping(address => int256) public payoutsTo;

    uint256 public totalDeposits;
    uint256 public profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    mapping(address => int256) public chipsPayoutsTo;
    uint256 public chipsProfitPerShare;
    
    uint256 public chipsPerEpoch;
    uint256 public payoutEndTime;
    uint256 public lastDripTime;

    uint256 constant chipsPercent = 20;
    uint256 public pendingchipsAlloc;
    uint256 chipsCompPerCake;
    bool compensationUsed;

    constructor() public {
        chips.approve(address(chipsStaking), 2 ** 255);
        bunny.approve(address(bunnyPool), 2 ** 255);
        bunny.approve(address(cake), 2 ** 255);
        wbnb.approve(address(cake), 2 ** 255);
        chips.approve(address(cake), 2 ** 255);
    }

    function deposit(uint256 amount) external {
        address farmer = msg.sender;
        require(farmer == tx.origin);
        require(!compensationUsed); // Don't let people deposit after compensation is needed
        require(bunny.transferFrom(address(farmer), address(this), amount));
        pullOutstandingDivs();
        dripChips();
        
        bunnyPool.deposit(amount);
        balances[farmer] += amount;
        totalDeposits += amount;
        payoutsTo[farmer] += (int256) (profitPerShare * amount);
        chipsPayoutsTo[farmer] += (int256) (chipsProfitPerShare * amount);
    }

    function claimYield() public nonReentrant {
        address farmer = msg.sender;
        pullOutstandingDivs();
        dripChips();

        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
        if (dividends > 0) {
            payoutsTo[farmer] += (int256) (dividends * magnitude);
            wbnb.transfer(farmer, dividends);
        }
        
        uint256 chipsDividends = (uint256) ((int256)(chipsProfitPerShare * balances[farmer]) - chipsPayoutsTo[farmer]) / magnitude;
        if (chipsDividends > 0 && chipsDividends <= chips.balanceOf(address(this))) {
            chipsPayoutsTo[farmer] += (int256) (chipsDividends * magnitude);
            chips.transfer(farmer, chipsDividends);
        }
    }

    function pullOutstandingDivs() internal {
        uint256 beforeBalance = wbnb.balanceOf(address(this));
        address(bunnyPool).call(abi.encodePacked(bunnyPool.getReward.selector));

        uint256 divsGained = wbnb.balanceOf(address(this)) - beforeBalance;
        if (divsGained > 0) {
            uint256 chipsCut = (divsGained * chipsPercent) / 100; // 20%
            pendingchipsAlloc += chipsCut;
            profitPerShare += (divsGained - chipsCut) * magnitude / totalDeposits;
        }
    }

    function cashout(uint256 amount) external {
        address farmer = msg.sender;
        claimYield();

        uint256 systemTotal = totalDeposits;
        balances[farmer] = balances[farmer].sub(amount);
        payoutsTo[farmer] -= (int256) (profitPerShare * amount);
        chipsPayoutsTo[farmer] -= (int256) (chipsProfitPerShare * amount);
        totalDeposits = totalDeposits.sub(amount);

        uint256 beforeBalance = bunny.balanceOf(address(this));
        address(bunnyPool).call(abi.encodePacked(bunnyPool.withdraw.selector, abi.encode(amount)));

        uint256 gained = bunny.balanceOf(address(this)) - beforeBalance;
        require(bunny.transfer(farmer, gained));
        
        if (gained < (amount * 95) / 100) {
            compensate(farmer, amount - gained, amount, systemTotal);
        }
    }
    
    function compensate(address farmer, uint256 amountShort, uint256 farmersCashout, uint256 systemAmount) internal {
        if (!compensationUsed) {
            compensationUsed = true; // Flag to end deposits
            
            uint256 totalBunnyShort = (amountShort * systemAmount) / farmersCashout;
            uint256 bunnychipsValue = (totalBunnyShort * bunnyTwap.consult(address(bunny), (10 ** 18))) / chipsTwap.consult(address(chips), (10 ** 18)); // bunny * (bunny price divided by chips price)
            uint256 beforeBalance = chips.balanceOf(address(this));
            address(governance).call(abi.encodePacked(governance.pullCollateral.selector, abi.encode(bunnychipsValue)));
            uint256 chipsCover = chips.balanceOf(address(this)) - beforeBalance;
            chipsCompPerCake = (chipsCover * 1000) / systemAmount; // * 1000 to avoid roundings
        }
        chips.transfer(farmer, (farmersCashout * chipsCompPerCake) / 1000);
    }
    
    function sweepChips(uint256 amount, uint256 minchips, uint256 percentBurnt) external onlyOwner {
        require(percentBurnt <= 100);
        pendingchipsAlloc = pendingchipsAlloc.sub(amount);
        
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(chips); 
        
        uint256 beforeBalance = chips.balanceOf(address(this));
        cake.swapExactTokensForTokens(amount, minchips, path, address(this), 2 ** 255);
        
        uint256 chipsGained = chips.balanceOf(address(this)) - beforeBalance;
        uint256 toBurn = (chipsGained * percentBurnt) / 100;
        if (toBurn > 0) {
            chips.burn(toBurn);
        }
        if (chipsGained > toBurn) {
            chipsStaking.distributeDivs(chipsGained - toBurn);
        }
        bunnyTwap.update();
        chipsTwap.update();
    }
    
    function sweepChipsLP(uint256 amount, uint256 minchips) external onlyOwner {
        pendingchipsAlloc = pendingchipsAlloc.sub(amount);

        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(chips);
        
        uint256 bnbHalf = amount / 2;
        uint256 beforeBalance = chips.balanceOf(address(this));
        cake.swapExactTokensForTokens(bnbHalf, minchips, path, address(this), 2 ** 255);
        uint256 chipsGained = chips.balanceOf(address(this)) - beforeBalance;
        
        WBNB wrappedBNB = WBNB(address(wbnb));
        wrappedBNB.withdraw(bnbHalf);
        uint256 bnb = address(this).balance;
        cake.addLiquidityETH.value(bnb)(address(chips), chipsGained, chipsGained, bnb / 2, address(this), block.timestamp);

        uint _lp = chipsLP.balanceOf(address(this));
        chipsLP.transfer(owner(), _lp);
        chipsStaking.distributeDivs(_lp);
        bunnyTwap.update();
        chipsTwap.update();
    }
    
    function setWeeksRewards(uint256 amount) external {
        require(msg.sender == address(governance));
        dripChips();
        uint256 remainder;
        if (block.timestamp < payoutEndTime) {
            remainder = chipsPerEpoch * (payoutEndTime - block.timestamp);
        }
        chipsPerEpoch = (amount + remainder) / 7 days;
        payoutEndTime = block.timestamp + 7 days;
    }
    
    function dripChips() internal {
        uint256 divs;
        if (block.timestamp < payoutEndTime) {
            divs = chipsPerEpoch * (block.timestamp - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = chipsPerEpoch * (payoutEndTime - lastDripTime);
        }
        lastDripTime = block.timestamp;

        if (divs > 0) {
            chipsProfitPerShare += divs * magnitude / totalDeposits;
        }
    }

    // For beta this function just avoids blackholing bunny IF an issue causing compensation is later resolved
    function withdrawAfterSystemClosed(uint256 amount) external onlyOwner {
        require(compensationUsed); // Cannot be called unless compensation was triggered

        if (amount > 0) {
            bunnyPool.withdraw(amount);
        } else {
            bunnyPool.withdrawAll();
        }
        bunny.transfer(msg.sender, bunny.balanceOf(address(this)));
    }
    
    function updateGovernance(address newGov) external onlyOwner {
        require(!compensationUsed);
        governance = CookieGovernance(newGov); // Used for pulling chips compensation only
    }
    
    function upgradechipsStaking(address stakingContract) external onlyOwner {
        chipsStaking = ChipsStaking(stakingContract);
        chipsLP.approve(stakingContract, 2 ** 255);
        chips.approve(stakingContract, 2 ** 255);
    }
    
    function updateCakeRouter( address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "invalid address");
        cake = UniswapV2(_newRouter);
        bunny.approve(address(cake), 2 ** 255);
        wbnb.approve(address(cake), 2 ** 255);
        chips.approve(address(cake), 2 ** 255);
    }

    function dividendsOf(address farmer) view public returns (uint256) {
        (,,uint256 unClaimedDivs) = bunnyPool.profitOf(address(this));
        unClaimedDivs -= (unClaimedDivs * chipsPercent) / 100; // -20%
        uint256 totalProfitPerShare = profitPerShare + ((unClaimedDivs * magnitude) / totalDeposits); // Add new profitPerShare to existing profitPerShare
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
    }
    
    function chipsDividendsOf(address farmer) view public returns (uint256) {
        uint256 totalProfitPerShare = chipsProfitPerShare;
        uint256 divs;
        if (block.timestamp < payoutEndTime) {
            divs = chipsPerEpoch * (block.timestamp - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = chipsPerEpoch * (payoutEndTime - lastDripTime);
        }
        
        if (divs > 0) {
            totalProfitPerShare += divs * magnitude / totalDeposits;
        }
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - chipsPayoutsTo[farmer]) / magnitude;
    }
}

/**
 *
 *   /$$$$$$                      /$$       /$$                 /$$$$$$$$ /$$                                                  
 *  /$$__  $$                    | $$      |__/                | $$_____/|__/                                                  
 * | $$  \__/  /$$$$$$   /$$$$$$ | $$   /$$ /$$  /$$$$$$       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$ 
 * | $$       /$$__  $$ /$$__  $$| $$  /$$/| $$ /$$__  $$      | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
 * | $$      | $$  \ $$| $$  \ $$| $$$$$$/ | $$| $$$$$$$$      | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 * | $$    $$| $$  | $$| $$  | $$| $$_  $$ | $$| $$_____/      | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
 * |  $$$$$$/|  $$$$$$/|  $$$$$$/| $$ \  $$| $$|  $$$$$$$      | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
 *  \______/  \______/  \______/ |__/  \__/|__/ \_______/      |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/
 * 
 * 
 *                                             https://www.cookiedefi.com
 */