/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity 0.5.8;

/**
 *
 * https://squirrel.finance
 * 
 * SquirrelFinance is a DeFi project which offers farm insurance
 *
 */
 

contract InsuredCakeFarm {
    using SafeMath for uint256;

    ERC20 constant cake = ERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    ERC20 constant wbnb = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 constant nuts = ERC20(0x8893D5fA71389673C5c4b9b3cb4EE1ba71207556);
    ERC20 constant nutsLP = ERC20(0x789fd04BFbC64169104466Ee0d48716E0452Bcf6);

    NutsStaking nutsStaking = NutsStaking(0x9D5f6E85b3DeAD1cb27C8033059aB472674f62d4);
    SyrupPool constant cakePool = SyrupPool(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    
    OracleSimpleBNBCake cakeTwap = OracleSimpleBNBCake(0x21c7B83fB58329dbaCe8F46f628fE6441ccEab33);
    OracleSimpleBNBNuts nutsTwap = OracleSimpleBNBNuts(0xD0A80f37E2958B6484E82B9bDC679726B3cE7eCA);
    UniswapV2 cakeV2 = UniswapV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    UniswapV2 ape = UniswapV2(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    SquirrelGoverance governance = SquirrelGoverance(0x32031eeD8c80f90C543DcF88a90d347f988e37EF);

    mapping(address => uint256) public balances;

    uint256 public totalDeposits;
    uint256 constant internal magnitude = 2 ** 64;
    
    mapping(address => int256) public nutsPayoutsTo;
    uint256 public nutsProfitPerShare;
    
    uint256 public nutsPerEpoch;
    uint256 public payoutEndTime;
    uint256 public lastDripTime;

    uint256 constant nutsPercent = 20;
    uint256 public nutsRate = 1600; // 16:1 nuts
    uint256 public pendingNutsAlloc;
    uint256 nutsCompPerCake;
    bool compensationUsed;
    address blobby = msg.sender;

    constructor() public {
        nuts.approve(address(nutsStaking), 2 ** 255);
        nutsLP.approve(address(nutsStaking), 2 ** 255);
        cake.approve(address(cakePool), 2 ** 255);
        cake.approve(address(cakeV2), 2 ** 255);
        nuts.approve(address(ape), 2 ** 255);
        wbnb.approve(address(ape), 2 ** 255);
    }
    
    function() payable external { /* Payable */ }

    function deposit(uint256 amount) external {
        address farmer = msg.sender;
        require(farmer == tx.origin);
        require(!compensationUsed); // Don't let people deposit after compensation is needed
        require(cake.transferFrom(address(farmer), address(this), amount));
        pullOutstandingDivs();
        dripNuts();
        
        cakePool.enterStaking(amount);
        balances[farmer] += amount;
        totalDeposits += amount;
        nutsPayoutsTo[farmer] += (int256) (nutsProfitPerShare * amount);
    }

    function claimYield() public {
        address farmer = msg.sender;
        pullOutstandingDivs();
        dripNuts();
        
        uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
        if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            nuts.transfer(farmer, nutsDividends);
        }
    }
    
    function depositYield() external {
        address farmer = msg.sender;
        pullOutstandingDivs();
        dripNuts();
        
        uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
        if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            nutsStaking.depositFor(farmer, nutsDividends);
        }
    }
    
    function pullOutstandingDivs() internal {
        uint256 beforeBalance = cake.balanceOf(address(this));
        address(cakePool).call(abi.encodePacked(cakePool.leaveStaking.selector, abi.encode(0)));

        uint256 divsGained = cake.balanceOf(address(this)) - beforeBalance;
        if (divsGained > 0) {
            uint256 nutsCut = (divsGained * nutsPercent) / 100; // 20%
            pendingNutsAlloc += nutsCut;
            
            uint256 nutsDividends = ((divsGained - nutsCut) * nutsRate) / 100; // Convert cake gained into extra nuts
            nutsProfitPerShare += (nutsDividends * magnitude) / totalDeposits;
        }
    }

    function cashout(uint256 amount) external {
        address farmer = msg.sender;
        claimYield();

        uint256 systemTotal = totalDeposits;
        balances[farmer] = balances[farmer].sub(amount);
        nutsPayoutsTo[farmer] -= (int256) (nutsProfitPerShare * amount);
        totalDeposits = totalDeposits.sub(amount);

        uint256 beforeBalance = cake.balanceOf(address(this));
        address(cakePool).call(abi.encodePacked(cakePool.leaveStaking.selector, abi.encode(amount)));

        uint256 gained = cake.balanceOf(address(this)) - beforeBalance;
        require(cake.transfer(farmer, gained));
        
        if (gained < (amount * 95) / 100) {
            compensate(farmer, amount - gained, amount, systemTotal);
        }
    }
    
    function compensate(address farmer, uint256 amountShort, uint256 farmersCashout, uint256 systemAmount) internal {
        if (!compensationUsed) {
            compensationUsed = true; // Flag to end deposits
            
            uint256 totalCakeShort = (amountShort * systemAmount) / farmersCashout;
            uint256 cakeNutsValue = (totalCakeShort * cakeTwap.consult(address(cake), (10 ** 18))) / nutsTwap.consult(address(nuts), (10 ** 18)); // cake * (cake price divided by nuts price)
            uint256 beforeBalance = nuts.balanceOf(address(this));
            address(governance).call(abi.encodePacked(governance.pullCollateral.selector, abi.encode(cakeNutsValue)));
            uint256 nutsCover = nuts.balanceOf(address(this)) - beforeBalance;
            nutsCompPerCake = (nutsCover * 1000) / systemAmount; // * 1000 to avoid roundings
        }
        nuts.transfer(farmer, (farmersCashout * nutsCompPerCake) / 1000);
    }
    
    function sweepNutsLP(uint256 amount, uint256 minBNB, uint256 minNuts) external {
        require(msg.sender == blobby);
        pendingNutsAlloc = pendingNutsAlloc.sub(amount);
        
        address[] memory path = new address[](2);
        path[0] = address(cake);
        path[1] = address(wbnb);
        
        cakeV2.swapExactTokensForTokens(amount, minBNB, path, address(this), 2 ** 255);
        uint256 bnbHalf = wbnb.balanceOf(address(this)) / 2;
        
        path[0] = address(wbnb);
        path[1] = address(nuts);
        
        uint256 beforeBalance = nuts.balanceOf(address(this));
        ape.swapExactTokensForTokens(bnbHalf, minNuts, path, address(this), 2 ** 255);
        uint256 nutsGained = nuts.balanceOf(address(this)) - beforeBalance;
        
        WBNB wrappedBNB = WBNB(address(wbnb));
        wrappedBNB.withdraw(bnbHalf);
        uint256 bnb = address(this).balance;
        ape.addLiquidityETH.value(bnb)(address(nuts), nutsGained, nutsGained, bnb / 2, address(this), now);

        nutsStaking.distributeDivs(nutsLP.balanceOf(address(this)));
        cakeTwap.update();
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

    // For beta this function just avoids blackholing cake IF an issue causing compensation is later resolved
    function withdrawAfterSystemClosed(uint256 amount) external {
        require(msg.sender == blobby);
        require(compensationUsed); // Cannot be called unless compensation was triggered

        if (amount > 0) {
            cakePool.leaveStaking(amount);
        } else {
            cakePool.emergencyWithdraw(0);
        }
        cake.transfer(msg.sender, cake.balanceOf(address(this)));
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
    
    function updateNutsRate(uint256 newRate) external {
        require(msg.sender == blobby);
        nutsRate = newRate;
    }
    
    function burnExcessNuts(uint256 amount) external {
        require(msg.sender == blobby);
        nuts.burn(amount); // Longterm any cake:nuts rate excess can be burnt 
    }
    
    function sweepCake(uint256 minBNB, uint256 minNuts) external {
        require(msg.sender == blobby);

        address[] memory path = new address[](2);
        path[0] = address(cake);
        path[1] = address(wbnb);
        
        uint256 amount = cake.balanceOf(address(this)) - pendingNutsAlloc;
        cakeV2.swapExactTokensForTokens(amount, minBNB, path, address(this), 2 ** 255);
        
        path[0] = address(wbnb);
        path[1] = address(nuts);
        
        ape.swapExactTokensForTokens(wbnb.balanceOf(address(this)), minNuts, path, address(this), 2 ** 255);
    }

    function dividendsOf(address farmer) view public returns (uint256) {
        return 0;
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
        
        uint256 unClaimedDivs = (cakePool.pendingCake(0, address(this)) * nutsRate) / 100; // Convert cake gained into extra nuts
        unClaimedDivs -= (unClaimedDivs * nutsPercent) / 100;
        
        totalProfitPerShare += (unClaimedDivs * magnitude) / totalDeposits;
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
    }
}


contract NutsStaking {
    function depositFor(address player, uint256 amount) external;
    function distributeDivs(uint256 amount) external;
}

contract OracleSimpleBNBCake {
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

interface SyrupPool {
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function pendingCake(uint256 _pid, address _user) external view returns (uint256); 
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