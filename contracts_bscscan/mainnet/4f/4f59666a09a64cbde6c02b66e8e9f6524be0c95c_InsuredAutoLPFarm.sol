/**
 *Submitted for verification at BscScan.com on 2021-08-19
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

pragma solidity 0.5.8;

contract InsuredAutoLPFarm {
    using SafeMath for uint256;

    ERC20 constant autoLP = ERC20(0x4d0228EBEB39f6d2f29bA528e2d15Fc9121Ead56);
    ERC20 constant autoToken = ERC20(0xa184088a740c695E156F91f5cC086a06bb78b827);
    ERC20 constant chips = ERC20(0x1e584D356db17deCFA474Fb9669Fa7D2f181eE4E);

    ChipsStaking constant chipsStaking = ChipsStaking(0x1E822a7f027Cd8e56DA8D9220A82AADF878dD233);
    AutoLPFarm constant autoPool = AutoLPFarm(0x0895196562C7868C5Be92459FaE7f877ED450452);
    
    OracleSimpleBNBAuto autoTwap = OracleSimpleBNBAuto(0x22a2359B7177A4e6BC4c7c8EbBE620b0Bc550025);
    OracleSimpleBNBChips chipsTwap = OracleSimpleBNBChips(0x8595346f2Dc71Aa72F9c8340493D445835281c3F);
    UniswapV2 pancake = UniswapV2(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
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
    uint256 public pendingChipsAlloc;
    uint256 chipsCompPerAuto;
    bool compensationUsed;
    address owner = msg.sender;

    constructor() public {
        chips.approve(address(chipsStaking), 2 ** 255);
        autoLP.approve(address(autoPool), 2 ** 255);
        autoToken.approve(address(pancake), 2 ** 255);
    }

    function deposit(uint256 amount) external {
        address farmer = msg.sender;
        require(farmer == tx.origin);
        require(!compensationUsed); // Don't let people deposit after compensation is needed
        require(autoLP.transferFrom(address(farmer), address(this), amount));
        pullOutstandingDivs();
        dripChips();
        
        autoPool.deposit(6, amount);
        balances[farmer] += amount;
        totalDeposits += amount;
        payoutsTo[farmer] += (int256) (profitPerShare * amount);
        chipsPayoutsTo[farmer] += (int256) (chipsProfitPerShare * amount);
    }

    function claimYield() public {
        address farmer = msg.sender;
        pullOutstandingDivs();
        dripChips();

        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
        if (dividends > 0) {
            payoutsTo[farmer] += (int256) (dividends * magnitude);
            autoToken.transfer(farmer, dividends);
        }
        
        uint256 chipsDividends = (uint256) ((int256)(chipsProfitPerShare * balances[farmer]) - chipsPayoutsTo[farmer]) / magnitude;
        if (chipsDividends > 0) {
            chipsPayoutsTo[farmer] += (int256) (chipsDividends * magnitude);
            chips.transfer(farmer, chipsDividends);
        }
    }

    function pullOutstandingDivs() internal {
        uint256 beforeBalance = autoToken.balanceOf(address(this));
        address(autoPool).call(abi.encodePacked(autoPool.withdraw.selector, abi.encode(6, 0)));

        uint256 divsGained = autoToken.balanceOf(address(this)) - beforeBalance;
        if (divsGained > 0) {
            uint256 chipsCut = (divsGained * chipsPercent) / 100; // 20%
            pendingChipsAlloc += chipsCut;
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

        uint256 beforeBalance = autoLP.balanceOf(address(this));
        address(autoPool).call(abi.encodePacked(autoPool.withdraw.selector, abi.encode(6, amount)));

        uint256 gained = autoLP.balanceOf(address(this)) - beforeBalance;
        require(autoLP.transfer(farmer, gained));
        
        if (gained < (amount * 95) / 100) {
            compensate(farmer, amount - gained, amount, systemTotal);
        }
    }
    
    function compensate(address farmer, uint256 amountShort, uint256 farmersCashout, uint256 systemAmount) internal {
        if (!compensationUsed) {
            compensationUsed = true; // Flag to end deposits
            
            uint256 totalAutoLPShort = (amountShort * systemAmount) / farmersCashout;
            (uint256 autoAmount, uint256 lpAmount) = autoTwap.consultLP(address(autoToken));
            uint256 autoChipsValue = ((totalAutoLPShort * autoAmount * 2 / lpAmount) * autoTwap.consult(address(autoToken), (10 ** 18))) / chipsTwap.consult(address(chips), (10 ** 18)); // auto * (auto price divided by chips price)
            uint256 beforeBalance = chips.balanceOf(address(this));
            address(governance).call(abi.encodePacked(governance.pullCollateral.selector, abi.encode(autoChipsValue)));
            uint256 chipsCover = chips.balanceOf(address(this)) - beforeBalance;
            chipsCompPerAuto = (chipsCover * 1000) / systemAmount; // * 1000 to avoid roundings
        }
        chips.transfer(farmer, (farmersCashout * chipsCompPerAuto) / 1000);
    }
    
    function sweepChips(uint256 amount, uint256 minChips, uint256 percentBurnt) external {
        require(msg.sender == owner);
        require(percentBurnt <= 100);
        pendingChipsAlloc = pendingChipsAlloc.sub(amount);
        
        address[] memory path = new address[](3);
        path[0] = address(autoToken);
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // wbnb
        path[2] = address(chips);
        
        uint256 beforeBalance = chips.balanceOf(address(this));
        pancake.swapExactTokensForTokens(amount, minChips, path, address(this), 2 ** 255);
        
        uint256 chipsGained = chips.balanceOf(address(this)) - beforeBalance;
        uint256 toBurn = (chipsGained * percentBurnt) / 100;
        if (toBurn > 0) {
            chips.burn(toBurn);
        }
        if (chipsGained > toBurn) {
            chipsStaking.distributeDivs(chipsGained - toBurn);
        }
        autoTwap.update();
        chipsTwap.update();
    }
    
    function setWeeksRewards(uint256 amount) external {
        require(msg.sender == address(governance));
        dripChips();
        uint256 remainder;
        if (now < payoutEndTime) {
            remainder = chipsPerEpoch * (payoutEndTime - now);
        }
        chipsPerEpoch = (amount + remainder) / 7 days;
        payoutEndTime = now + 7 days;
    }
    
    function dripChips() internal {
        uint256 divs;
        if (now < payoutEndTime) {
            divs = chipsPerEpoch * (now - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = chipsPerEpoch * (payoutEndTime - lastDripTime);
        }
        lastDripTime = now;

        if (divs > 0) {
            chipsProfitPerShare += divs * magnitude / totalDeposits;
        }
    }

    // For beta this function just avoids blackholing auto IF an issue causing compensation is later resolved
    function withdrawAfterSystemClosed(uint256 amount) external {
        require(msg.sender == owner);
        require(compensationUsed); // Cannot be called unless compensation was triggered

        if (amount > 0) {
            autoPool.withdraw(6, amount);
        } else {
            autoPool.emergencyWithdraw(6);
        }
        autoLP.transfer(msg.sender, autoLP.balanceOf(address(this)));
    }
    
    function updateGovernance(address newGov) external {
        require(msg.sender == owner);
        require(!compensationUsed);
        governance = CookieGovernance(newGov); // Used for pulling CHIPS compensation only
    }

    function dividendsOf(address farmer) view public returns (uint256) {
        uint256 unClaimedDivs = autoPool.pendingAUTO(6, address(this));
        unClaimedDivs -= (unClaimedDivs * chipsPercent) / 100; // -20%
        uint256 totalProfitPerShare = profitPerShare + ((unClaimedDivs * magnitude) / totalDeposits); // Add new profitPerShare to existing profitPerShare
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
    }
    
    function chipsDividendsOf(address farmer) view public returns (uint256) {
        uint256 totalProfitPerShare = chipsProfitPerShare;
        uint256 divs;
        if (now < payoutEndTime) {
            divs = chipsPerEpoch * (now - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = chipsPerEpoch * (payoutEndTime - lastDripTime);
        }
        
        if (divs > 0) {
            totalProfitPerShare += divs * magnitude / totalDeposits;
        }
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - chipsPayoutsTo[farmer]) / magnitude;
    }
}


contract ChipsStaking {
    function depositFor(address player, uint256 amount) external;
    function distributeDivs(uint256 amount) external;
}

contract OracleSimpleBNBAuto {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function consultLP(address token) external view returns (uint, uint);
    function update() external;
}

contract OracleSimpleBNBChips {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}


interface CookieGovernance {
    function pullCollateral(uint256 amount) external returns (uint256 compensation);
    function compensationAvailable(address farm) external view returns (uint256);
    
}

interface AutoLPFarm {
    function pendingAUTO(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amt) external;
    function withdraw(uint256 _pid, uint256 _amt) external;
    function emergencyWithdraw(uint256 _pid) external; 
}


interface UniswapV2 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
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