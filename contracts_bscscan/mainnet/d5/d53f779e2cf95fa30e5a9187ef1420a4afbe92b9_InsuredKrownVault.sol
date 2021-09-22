/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

pragma solidity 0.5.8;

/**
 *
 * https://squirrel.finance
 * 
 * SquirrelFinance is a DeFi project which offers farm insurance
 *
 */

contract InsuredKrownVault {
    using SafeMath for uint256;
    using SafeMath128 for uint128;

    ERC20 constant krw = ERC20(0x1446f3CEdf4d86a9399E49f7937766E6De2A3AAB);
    ERC20 constant nuts = ERC20(0x8893D5fA71389673C5c4b9b3cb4EE1ba71207556);
    ERC20 constant wbnb = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 constant nutsLP = ERC20(0x789fd04BFbC64169104466Ee0d48716E0452Bcf6);

    NutsStaking nutsStaking = NutsStaking(0x9D5f6E85b3DeAD1cb27C8033059aB472674f62d4);
    KrwVault constant krwPool = KrwVault(0x98F3b99198E164f50272ea5Ba44Ea76B1a439876);
    
    OracleSimpleBNBKrw constant krwTwap = OracleSimpleBNBKrw(0x1957d3c9bBFB5C40C6DF2EdA6F2b7De5662c7FAC);
    OracleSimpleBNBNuts constant nutsTwap = OracleSimpleBNBNuts(0xD0A80f37E2958B6484E82B9bDC679726B3cE7eCA);
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
    uint256 public pendingNutsAlloc;
    uint256 public nutsCompPerCake;
    bool compensationUsed;
    address blobby = msg.sender;

    constructor() public {
        nuts.approve(address(nutsStaking), 2 ** 255);
        nutsLP.approve(address(nutsStaking), 2 ** 255);
        krw.approve(address(krwPool), 2 ** 255);
        krw.approve(address(cakeV2), 2 ** 255);
        wbnb.approve(address(ape), 2 ** 255);
        nuts.approve(address(ape), 2 ** 255);
    }
    
    function() payable external { /* Payable */ }

    function deposit(uint256 amount) external {
        address farmer = msg.sender;
        require(farmer == tx.origin);
        require(!compensationUsed); // Don't let people deposit after compensation is needed
        require(krw.transferFrom(address(farmer), address(this), amount));
        dripNuts();
        
        uint256 beforeBalance = krwPool.getDeposit(address(this));
        krwPool.deposit(amount);
        uint256 newBalance = krwPool.getDeposit(address(this));
        
        uint256 increase = newBalance - beforeBalance;
        if (beforeBalance > 0) {
            increase = ((totalDeposits * newBalance) / beforeBalance) - totalDeposits;
        }

        balances[farmer] += increase;
        totalDeposits += increase;
        nutsPayoutsTo[farmer] += (int256) (nutsProfitPerShare * increase);
    }

    function claimYield() public {
        address farmer = msg.sender;
        dripNuts();
        
        uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
        if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            nuts.transfer(farmer, nutsDividends);
        }
    }
    
    function depositYield() external {
        address farmer = msg.sender;
        dripNuts();
        
        uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
        if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            nutsStaking.depositFor(farmer, nutsDividends);
        }
    }

    function cashout(uint128 amount) external {
        address farmer = msg.sender;
        claimYield();
        
        uint256 totalKrw = krwPool.getDeposit(address(this));
        uint256 krwExpected = (amount * totalKrw) / totalDeposits;
        balances[farmer] = balances[farmer].sub(amount);

        uint256 systemTotal = totalDeposits;
        nutsPayoutsTo[farmer] -= (int256) (nutsProfitPerShare * amount);
        totalDeposits = totalDeposits.sub(amount);

        uint256 beforeBalance = krw.balanceOf(address(this));
        address(krwPool).call(abi.encodePacked(krwPool.withdraw.selector, abi.encode(krwExpected)));

        uint256 gained = krw.balanceOf(address(this)) - beforeBalance;
        require(krw.transfer(farmer, gained));
        
        if (gained < (krwExpected * 95) / 100) {
            compensate(farmer, krwExpected - gained, amount, systemTotal);
        }
    }
    
    function compensate(address farmer, uint256 amountShort, uint256 farmersCashout, uint256 systemAmount) internal {
        if (!compensationUsed) {
            compensationUsed = true; // Flag to end deposits
            
            uint256 totalCakeShort = (amountShort * systemAmount) / farmersCashout;
            uint256 krwNutsValue = (totalCakeShort * krwTwap.consult(address(krw), (10 ** 18))) / nutsTwap.consult(address(nuts), (10 ** 18)); // krw * (krw price divided by nuts price)
            uint256 beforeBalance = nuts.balanceOf(address(this));
            address(governance).call(abi.encodePacked(governance.pullCollateral.selector, abi.encode(krwNutsValue)));
            uint256 nutsCover = nuts.balanceOf(address(this)) - beforeBalance;
            nutsCompPerCake = (nutsCover * 1000) / systemAmount; // * 1000 to avoid roundings
        }
        nuts.transfer(farmer, (farmersCashout * nutsCompPerCake) / 1000);
    }
    
    function pullOutstandingDivs() external {
        require(msg.sender == blobby);
        require(!compensationUsed);
        
        krwPool.claim();
        uint256 krownDivs = krw.balanceOf(address(this)) - pendingNutsAlloc;
        uint256 nutsAlloc = (krownDivs * nutsPercent) / 100;
        
        pendingNutsAlloc += nutsAlloc;
        krownDivs -= nutsAlloc;
        krwPool.deposit(krownDivs);
    }
    
    function sweepNutsLP(uint256 amount, uint256 minBNB, uint256 minNuts) external {
        require(msg.sender == blobby);
        pendingNutsAlloc = pendingNutsAlloc.sub(amount);

        address[] memory path = new address[](2);
        path[0] = address(krw);
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
        krwTwap.update();
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
        if (lastDripTime + 5 minutes < now) {
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
    }

    // For beta this function just avoids blackholing krown IF an issue causing compensation is later resolved
    function withdrawAfterSystemClosed(uint256 amount) external {
        require(msg.sender == blobby);
        require(compensationUsed); // Cannot be called unless compensation was triggered

        if (amount > 0) {
            krwPool.withdraw(amount);
        } else {
            krwPool.emergencyWithdraw();
        }
        krw.transfer(msg.sender, krw.balanceOf(address(this)));
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
    
    function cakeBalance(address farmer) view public returns (uint256) {
        return (balances[farmer] * krwPool.getDeposit(address(this))) / totalDeposits;
    }
    
    function totalCakeBalance() view public returns (uint256) {
        return krwPool.getDeposit(address(this));
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

contract OracleSimpleBNBKrw {
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

interface KrwVault {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function claim() external;
    function emergencyWithdraw() external;
    function getDeposit(address account) external view returns (uint256);
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