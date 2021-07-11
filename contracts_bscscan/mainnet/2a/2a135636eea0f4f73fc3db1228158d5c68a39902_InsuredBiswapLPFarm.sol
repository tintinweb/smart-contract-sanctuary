/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity 0.5.8;

/**
 *
 * https://squirrel.finance
 * 
 * SquirrelFinance is a DeFi project which offers farm insurance
 *
 */


contract InsuredBiswapLPFarm {
    using SafeMath for uint256;

    ERC20 constant biswapLP = ERC20(0x1483767E665B3591677Fd49F724bf7430C18Bf83);
    ERC20 constant biswap = ERC20(0x965F527D9159dCe6288a2219DB51fc6Eef120dD1);
    ERC20 constant nuts = ERC20(0x8893D5fA71389673C5c4b9b3cb4EE1ba71207556);
    ERC20 constant wbnb = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 constant busd = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    ERC20 constant nutsLP = ERC20(0x789fd04BFbC64169104466Ee0d48716E0452Bcf6);

    NutsStaking nutsStaking = NutsStaking(0x45C12738C089224F66CD7A1c85301d79C45E2dEd);
    BiswapLPFarm constant biswapPool = BiswapLPFarm(0xDbc1A13490deeF9c3C12b44FE77b503c1B061739);
    
    OracleSimpleBNBBiswapLP constant biswapTwap = OracleSimpleBNBBiswapLP(0x606684e937a73Df498bBbB99fEbB5C39d1968682);
    OracleSimpleBNBBusd constant busdTwap = OracleSimpleBNBBusd(0xBC78B40E83f90Ed281a7Cd447aC4E1f44dDF3Bea);
    OracleSimpleBNBNuts constant nutsTwap = OracleSimpleBNBNuts(0xD0A80f37E2958B6484E82B9bDC679726B3cE7eCA);
    UniswapV2 constant cakeV2 = UniswapV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    UniswapV2 constant ape = UniswapV2(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    SquirrelGoverance governance = SquirrelGoverance(0x32031eeD8c80f90C543DcF88a90d347f988e37EF);

    mapping(address => uint256) public balances;
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
    uint256 nutsCompPerBiswap;
    bool compensationUsed;
    address blobby = msg.sender;

    constructor() public {
        nuts.approve(address(nutsStaking), 2 ** 255);
        biswapLP.approve(address(biswapPool), 2 ** 255);
        biswap.approve(address(cakeV2), 2 ** 255);
        wbnb.approve(address(ape), 2 ** 255);
        nuts.approve(address(ape), 2 ** 255);
    }

    function deposit(uint256 amount) external {
        address farmer = msg.sender;
        require(farmer == tx.origin);
        require(!compensationUsed); // Don't let people deposit after compensation is needed
        require(biswapLP.transferFrom(address(farmer), address(this), amount));
        pullOutstandingDivs();
        dripNuts();
        
        biswapPool.deposit(4, amount);
        balances[farmer] += amount;
        totalDeposits += amount;
        payoutsTo[farmer] += (int256) (profitPerShare * amount);
        nutsPayoutsTo[farmer] += (int256) (nutsProfitPerShare * amount);
    }

    function claimYield() public {
        address farmer = msg.sender;
        pullOutstandingDivs();
        dripNuts();

        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
        if (dividends > 0) {
            payoutsTo[farmer] += (int256) (dividends * magnitude);
            biswap.transfer(farmer, dividends);
        }
        
        uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
        if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            nuts.transfer(farmer, nutsDividends);
        }
    }

    function pullOutstandingDivs() internal {
        uint256 beforeBalance = biswap.balanceOf(address(this));
        address(biswapPool).call(abi.encodePacked(biswapPool.deposit.selector, abi.encode(4, 0)));

        uint256 divsGained = biswap.balanceOf(address(this)) - beforeBalance;
        if (divsGained > 0) {
            uint256 nutsCut = (divsGained * nutsPercent) / 100; // 20%
            pendingNutsAlloc += nutsCut;
            profitPerShare += (divsGained - nutsCut) * magnitude / totalDeposits;
        }
    }

    function cashout(uint256 amount) external {
        address farmer = msg.sender;
        claimYield();

        uint256 systemTotal = totalDeposits;
        balances[farmer] = balances[farmer].sub(amount);
        payoutsTo[farmer] -= (int256) (profitPerShare * amount);
        nutsPayoutsTo[farmer] -= (int256) (nutsProfitPerShare * amount);
        totalDeposits = totalDeposits.sub(amount);

        uint256 beforeBalance = biswapLP.balanceOf(address(this));
        address(biswapPool).call(abi.encodePacked(biswapPool.withdraw.selector, abi.encode(4, amount)));

        uint256 gained = biswapLP.balanceOf(address(this)) - beforeBalance;
        require(biswapLP.transfer(farmer, gained));
        
        if (gained < (amount * 95) / 100) {
            compensate(farmer, amount - gained, amount, systemTotal);
        }
    }
    
    function compensate(address farmer, uint256 amountShort, uint256 farmersCashout, uint256 systemAmount) internal {
        if (!compensationUsed) {
            compensationUsed = true; // Flag to end deposits
            
            uint256 totalBiswapLPShort = (amountShort * systemAmount) / farmersCashout;
            (uint256 busdAmount, uint256 lpAmount) = biswapTwap.consultLP(address(busd));
            uint256 biswapNutsValue = ((totalBiswapLPShort * busdAmount * 2 / lpAmount) * busdTwap.consult(address(busd), (10 ** 18))) / nutsTwap.consult(address(nuts), (10 ** 18)); // lp * (lp price divided by nuts price)
            uint256 beforeBalance = nuts.balanceOf(address(this));
            address(governance).call(abi.encodePacked(governance.pullCollateral.selector, abi.encode(biswapNutsValue)));
            uint256 nutsCover = nuts.balanceOf(address(this)) - beforeBalance;
            nutsCompPerBiswap = (nutsCover * 1000) / systemAmount; // * 1000 to avoid roundings
        }
        nuts.transfer(farmer, (farmersCashout * nutsCompPerBiswap) / 1000);
    }
    
    function sweepNutsLP(uint256 amount, uint256 minBNB, uint256 minNuts) external {
        require(msg.sender == blobby);
        pendingNutsAlloc = pendingNutsAlloc.sub(amount);

        address[] memory path = new address[](2);
        path[0] = address(biswap);
        path[1] = address(wbnb);
        
        cakeV2.swapExactTokensForTokens(amount, minBNB, path, address(this), 2 ** 255);
        uint256 bnbHalf = wbnb.balanceOf(address(this)) / 2;
        
        path[0] = address(wbnb);
        path[1] = address(nuts);
        
        uint256 beforeBalance = nuts.balanceOf(address(this));
        ape.swapExactTokensForTokens(wbnb.balanceOf(address(this)), minNuts, path, address(this), 2 ** 255);
        uint256 nutsGained = nuts.balanceOf(address(this)) - beforeBalance;
        
        WBNB wrappedBNB = WBNB(address(wbnb));
        wrappedBNB.withdraw(bnbHalf);
        uint256 bnb = address(this).balance;
        ape.addLiquidityETH.value(bnb)(address(nuts), nutsGained, nutsGained, bnb / 2, address(this), now);

        nutsStaking.distributeDivs(nutsLP.balanceOf(address(this)));
        biswapTwap.update();
        busdTwap.update();
        nutsTwap.update();
    }
    
    function sweepNuts(uint256 amount, uint256 minNuts, uint256 percentBurnt) external {
        require(msg.sender == blobby);
        require(percentBurnt <= 100);
        pendingNutsAlloc = pendingNutsAlloc.sub(amount);
        
        address[] memory path = new address[](2);
        path[0] = address(biswap);
        path[1] = address(wbnb); 
        
        cakeV2.swapExactTokensForTokens(amount, 1, path, address(this), 2 ** 255);
        
        path[0] = address(wbnb);
        path[1] = address(nuts);
        
        uint256 beforeBalance = nuts.balanceOf(address(this));
        ape.swapExactTokensForTokens(wbnb.balanceOf(address(this)), minNuts, path, address(this), 2 ** 255);
        uint256 nutsGained = nuts.balanceOf(address(this)) - beforeBalance;
        
        uint256 toBurn = (nutsGained * percentBurnt) / 100;
        if (toBurn > 0) {
            nuts.burn(toBurn);
        }
        if (nutsGained > toBurn) {
            nutsStaking.distributeDivs(nutsGained - toBurn);
        }
        biswapTwap.update();
        busdTwap.update();
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

    // For beta this function just avoids blackholing lp IF an issue causing compensation is later resolved
    function withdrawAfterSystemClosed(uint256 amount) external {
        require(msg.sender == blobby);
        require(compensationUsed); // Cannot be called unless compensation was triggered

        if (amount > 0) {
            biswapPool.withdraw(4, amount);
        } else {
            biswapPool.emergencyWithdraw(4);
        }
        biswapLP.transfer(msg.sender, biswapLP.balanceOf(address(this)));
    }
    
    function updateGovenance(address newGov) external {
        require(msg.sender == blobby);
        require(!compensationUsed);
        governance = SquirrelGoverance(newGov); // Used for pulling NUTS compensation only
    }
    
    function upgradeNutsStaking(address stakingContract) external {
        require(msg.sender == blobby);
        require(address(nutsStaking) == address(0x45C12738C089224F66CD7A1c85301d79C45E2dEd)); // Upgrade to staking v2 once after it is deployed
        nutsStaking = NutsStaking(stakingContract);
        nutsLP.approve(stakingContract, 2 ** 255);
        nuts.approve(stakingContract, 2 ** 255);
    }

    function dividendsOf(address farmer) view public returns (uint256) {
        uint256 unClaimedDivs = biswapPool.pendingBSW(4, address(this));
        unClaimedDivs -= (unClaimedDivs * nutsPercent) / 100; // -20%
        uint256 totalProfitPerShare = profitPerShare + ((unClaimedDivs * magnitude) / totalDeposits); // Add new profitPerShare to existing profitPerShare
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
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
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
    }
}


contract NutsStaking {
    function depositFor(address player, uint256 amount) external;
    function distributeDivs(uint256 amount) external;
}

contract OracleSimpleBNBBiswapLP {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function consultLP(address token) external view returns (uint, uint);
    function update() external;
}

contract OracleSimpleBNBBusd {
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

interface BiswapLPFarm {
    function pendingBSW(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amt) external;
    function withdraw(uint256 _pid, uint256 _amt) external;
    function emergencyWithdraw(uint256 _pid) external; 
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