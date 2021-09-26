/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

pragma solidity 0.5.8;

/**
 *
 * https://squirrel.finance
 * 
 * SquirrelFinance is a DeFi project which offers farm insurance
 *
 */


contract InsuredHunnyFarm {
    using SafeMath for uint256;
    using SafeMath128 for uint128;

    ERC20 constant hunny = ERC20(0x565b72163f17849832A692A3c5928cc502f46D69);
    ERC20 constant wbnb = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 constant nuts = ERC20(0x8893D5fA71389673C5c4b9b3cb4EE1ba71207556);
    ERC20 constant nutsLP = ERC20(0x789fd04BFbC64169104466Ee0d48716E0452Bcf6);

    NutsStaking nutsStaking = NutsStaking(0x9D5f6E85b3DeAD1cb27C8033059aB472674f62d4);
    HunnyPool constant hunnyPool = HunnyPool(0x8B2cf8CF0A30082111FB50D9a8FEBfe53C155B50);
    
    OracleSimpleBNBHunny constant hunnyTwap = OracleSimpleBNBHunny(0x6aae6CAD7935C4fa4944f4c52e0130649962D324);
    OracleSimpleBNBNuts constant nutsTwap = OracleSimpleBNBNuts(0xD0A80f37E2958B6484E82B9bDC679726B3cE7eCA);
    UniswapV2 constant ape = UniswapV2(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    UniswapV2 constant cakeV2 = UniswapV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    SquirrelGoverance governance = SquirrelGoverance(0x32031eeD8c80f90C543DcF88a90d347f988e37EF);
    
    struct Player {
        uint128 balance;
        uint128 playersCake;
    }

    mapping(address => Player) public players;
    mapping(address => int256) public payoutsTo;

    uint256 public totalDeposits;
    uint256 public profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    mapping(address => int256) public nutsPayoutsTo;
    uint256 public nutsProfitPerShare;
    
    uint256 public nutsPerEpoch;
    uint256 public payoutEndTime;
    uint256 public lastDripTime;

    uint256 constant nutsPercent = 20;
    uint256 public pendingNutsAlloc;
    uint256 nutsCompPerCake;
    bool compensationUsed;
    address blobby = msg.sender;

    constructor() public {
        nuts.approve(address(nutsStaking), 2 ** 255);
        nutsLP.approve(address(nutsStaking), 2 ** 255);
        hunny.approve(address(hunnyPool), 2 ** 255);
        hunny.approve(address(cakeV2), 2 ** 255);
        wbnb.approve(address(ape), 2 ** 255);
        nuts.approve(address(ape), 2 ** 255);
    }
    
    function() payable external { /* Payable */ }

    function deposit(uint256 amount) external {
        address farmer = msg.sender;
        require(farmer == tx.origin);
        require(!compensationUsed); // Don't let people deposit after compensation is needed
        require(hunny.transferFrom(address(farmer), address(this), amount));
        dripNuts();
        
        uint256 beforeBalance = hunnyPool.sharesOf(address(this));
        hunnyPool.deposit(amount);
        uint256 newBalance = hunnyPool.sharesOf(address(this));
        uint256 increase = newBalance - beforeBalance;
        
        if (beforeBalance > 0) {
            increase = ((totalDeposits * newBalance) / beforeBalance) - totalDeposits;
        }
        
        Player memory player = players[farmer];
        player.balance = player.balance.add(increase);
        player.playersCake = player.playersCake.add(amount);
        players[farmer] = player;
        
        totalDeposits += increase;
        nutsPayoutsTo[farmer] += (int256) (nutsProfitPerShare * increase);
    }

    function claimYield() public {
        address farmer = msg.sender;
        dripNuts();
        
        uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * players[farmer].balance) - nutsPayoutsTo[farmer]) / magnitude;
        if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            nuts.transfer(farmer, nutsDividends);
        }
    }

    function depositYield() external {
        address farmer = msg.sender;
        dripNuts();
        
        uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * players[farmer].balance) - nutsPayoutsTo[farmer]) / magnitude;
        if (nutsDividends > 0) {
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            nutsStaking.depositFor(farmer, nutsDividends);
        }
    }

    function cashout(uint128 amount) external {
        address farmer = msg.sender;
        claimYield();
        
        uint256 totalMoo = hunnyPool.sharesOf(address(this));
        uint256 mooCashout = (amount * totalMoo) / totalDeposits;
        uint256 principalCashout = mooCashout * hunnyPool.principalOf(address(this)) / totalMoo;
        
        Player memory player = players[farmer];
        uint128 cakeExpected = uint128((uint256(player.playersCake) * uint256(amount)) / player.balance);
        player.balance = player.balance.sub(amount);
        player.playersCake = player.playersCake.sub(cakeExpected);
        players[farmer] = player;

        uint256 systemTotal = totalDeposits;
        nutsPayoutsTo[farmer] -= (int256) (nutsProfitPerShare * amount);
        totalDeposits = totalDeposits.sub(amount);

        uint256 beforeBalance = hunny.balanceOf(address(this));
        address(hunnyPool).call(abi.encodePacked(hunnyPool.withdraw.selector, abi.encode(principalCashout)));

        uint256 gained = hunny.balanceOf(address(this)) - beforeBalance;
        require(hunny.transfer(farmer, gained));

        if (gained < (cakeExpected * 95) / 100) {
            compensate(farmer, cakeExpected - gained, amount, systemTotal);
        }
    }
    
    function compensate(address farmer, uint256 amountShort, uint256 farmersCashout, uint256 systemAmount) internal {
        if (!compensationUsed) {
            compensationUsed = true; // Flag to end deposits
            
            uint256 totalBunnyShort = (amountShort * systemAmount) / farmersCashout;
            uint256 bunnyNutsValue = (totalBunnyShort * hunnyTwap.consult(address(hunny), (10 ** 18))) / nutsTwap.consult(address(nuts), (10 ** 18)); // hunny * (hunny price divided by nuts price)
            uint256 beforeBalance = nuts.balanceOf(address(this));
            address(governance).call(abi.encodePacked(governance.pullCollateral.selector, abi.encode(bunnyNutsValue)));
            uint256 nutsCover = nuts.balanceOf(address(this)) - beforeBalance;
            nutsCompPerCake = (nutsCover * 1000) / systemAmount; // * 1000 to avoid roundings
        }
        nuts.transfer(farmer, (farmersCashout * nutsCompPerCake) / 1000);
    }
    
    function pullOutstandingDivs() external {
        require(msg.sender == blobby);

        uint256 beforeBalance = hunny.balanceOf(address(this));
        address(hunnyPool).call(abi.encodePacked(hunnyPool.getReward.selector));
        uint256 bunnyGained = hunny.balanceOf(address(this)) - beforeBalance;
        
        uint256 nutsAlloc = (bunnyGained * nutsPercent) / 100;
        pendingNutsAlloc += nutsAlloc;
        hunnyPool.deposit(bunnyGained - nutsAlloc);
    }
    
    function sweepNutsLP(uint256 amount, uint256 minNuts) external {
        require(msg.sender == blobby);
        pendingNutsAlloc = pendingNutsAlloc.sub(amount);

        address[] memory path = new address[](2);
        path[0] = address(hunny);
        path[1] = address(wbnb);
        
        cakeV2.swapExactTokensForTokens(amount, 1, path, address(this), 2 ** 255);

        path[0] = address(wbnb);
        path[1] = address(nuts);
        
        uint256 bnbHalf = wbnb.balanceOf(address(this)) / 2;
        uint256 beforeBalance = nuts.balanceOf(address(this));
        ape.swapExactTokensForTokens(bnbHalf, minNuts, path, address(this), 2 ** 255);
        uint256 nutsGained = nuts.balanceOf(address(this)) - beforeBalance;
        
        WBNB wrappedBNB = WBNB(address(wbnb));
        wrappedBNB.withdraw(bnbHalf);
        uint256 bnb = address(this).balance;
        ape.addLiquidityETH.value(bnb)(address(nuts), nutsGained, nutsGained, bnb / 2, address(this), now);

        nutsStaking.distributeDivs(nutsLP.balanceOf(address(this)));
        hunnyTwap.update();
        nutsTwap.update();
    }
    
    function setWeeksRewards(uint256 amount) external {
        require(msg.sender == address(governance));
        dripNuts();
        uint256 remainder;
        if (now < payoutEndTime) {
            remainder = nutsPerEpoch * (payoutEndTime - now);
        }
        nutsPerEpoch = (amount + remainder) / 7 days;
        payoutEndTime = now + 7 days;
    }
    
    function dripNuts() internal {
        uint256 divs;
        if (now < payoutEndTime) {
            divs = nutsPerEpoch * (now - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = nutsPerEpoch * (payoutEndTime - lastDripTime);
        }
        lastDripTime = now;

        if (divs > 0) {
            nutsProfitPerShare += divs * magnitude / totalDeposits;
        }
    }

    // For beta this function just avoids blackholing hunny IF an issue causing compensation is later resolved
    function withdrawAfterSystemClosed(uint256 amount) external {
        require(msg.sender == blobby);
        require(compensationUsed); // Cannot be called unless compensation was triggered

        if (amount > 0) {
            hunnyPool.withdraw(amount);
        } else {
            hunnyPool.withdrawAll();
        }
        hunny.transfer(msg.sender, hunny.balanceOf(address(this)));
    }
    
    function updateGovenance(address newGov) external {
        require(msg.sender == blobby);
        require(!compensationUsed);
        governance = SquirrelGoverance(newGov); // Used for pulling NUTS compensation only
    }
    
    function upgradeNutsStaking(address stakingContract) external {
        require(msg.sender == blobby);
        require(address(nutsStaking) == address(0x9D5f6E85b3DeAD1cb27C8033059aB472674f62d4)); // Upgrade to staking v2 once after it is deployed
        nutsStaking = NutsStaking(stakingContract);
        nutsLP.approve(stakingContract, 2 ** 255);
        nuts.approve(stakingContract, 2 ** 255);
    }

    function mooBalance(address farmer) view public returns (uint256) {
        return (players[farmer].balance * hunnyPool.sharesOf(address(this))) / totalDeposits;
    }
    
    function cakeBalance(address farmer) view public returns (uint256) {
        return (mooBalance(farmer) * hunnyPool.priceShare()) / (10 ** 18);
    }
    
    function totalCakeBalance() view public returns (uint256) {
        return (hunnyPool.sharesOf(address(this)) * hunnyPool.priceShare()) / (10 ** 18);
    }
    
    function nutsDividendsOf(address farmer) view public returns (uint256) {
        uint256 totalProfitPerShare = nutsProfitPerShare;
        uint256 divs;
        if (now < payoutEndTime) {
            divs = nutsPerEpoch * (now - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = nutsPerEpoch * (payoutEndTime - lastDripTime);
        }
        
        if (divs > 0) {
            totalProfitPerShare += divs * magnitude / totalDeposits;
        }
        return (uint256) ((int256)(totalProfitPerShare * players[farmer].balance) - nutsPayoutsTo[farmer]) / magnitude;
    }
}


contract NutsStaking {
    function depositFor(address player, uint256 amount) external;
    function distributeDivs(uint256 amount) external;
}

contract OracleSimpleBNBHunny {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}

contract OracleSimpleBNBNuts {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}


interface SquirrelGoverance {
    function pullCollateral(uint256 amount) external returns (uint256 compensation);
    function compensationAvailable(address farm) external view returns (uint256);
    
}

interface HunnyPool {
    function sharesOf(address account) external view returns (uint256);
    function principalOf(address account) external view returns (uint256);
    function deposit(uint256 _amount) external;
    function getReward() external;
    function withdraw(uint256 _amount) external;
    function withdrawAll() external;
    function priceShare() external view returns (uint256);
    function earned(address account) external view returns (uint256);
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
  function maxTransferAmount() external view returns (uint256); // Hunny Anti-Whale
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


library SafeMath128 {
    
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint128 a, uint256 b) internal pure returns (uint128) {
    assert(b == uint128(b));
    uint128 c = a + uint128(b);
    assert(c >= a);
    return c;
  }    

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint128 a, uint128 b) internal pure returns (uint128) {
    uint128 c = a + b;
    assert(c >= a);
    return c;
  }
  
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint128 a, uint128 b) internal pure returns (uint128) {
    assert(b <= a);
    return a - b;
  }
}