/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

pragma solidity 0.5.8;

/**
 *
 * https://squirrel.finance
 * 
 * SquirrelFinance is a DeFi project which offers farm insurance
 *
 */


contract FarmProxy {
    
    BiswapPool constant biswapPool = BiswapPool(0x72a79Ae14CFb139F9c52B304da2e42A683109Cc9);
    ERC20 constant link = ERC20(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD);
    ERC20 constant biswap = ERC20(0x965F527D9159dCe6288a2219DB51fc6Eef120dD1);
    address insuredFarm;
    
    constructor(address creator) public {
        insuredFarm = creator;
        link.approve(address(biswapPool), 2 ** 255);
    }
    
    function deposit(uint256 _amount) external {
        biswapPool.deposit(_amount);
    }
    
    function withdraw(uint256 _amount) external {
        require(msg.sender == insuredFarm);
        biswapPool.withdraw(_amount);

        transferInternal(biswap);
        transferInternal(link);
    }
    
    function transferInternal(ERC20 token) internal {
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.transfer(insuredFarm, amount);
        }
    }
    
    function emergencyWithdraw() external {
        require(msg.sender == insuredFarm);
        biswapPool.emergencyWithdraw();
        transferInternal(link);
    }
    
}

contract InsuredBiswapLinkFarm {
    using SafeMath for uint256;

    ERC20 constant biswap = ERC20(0x965F527D9159dCe6288a2219DB51fc6Eef120dD1);
    ERC20 constant link = ERC20(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD);
    WBNB constant wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 constant nuts = ERC20(0x8893D5fA71389673C5c4b9b3cb4EE1ba71207556);
    ERC20 constant nutsLP = ERC20(0x789fd04BFbC64169104466Ee0d48716E0452Bcf6);

    NutsStaking nutsStaking = NutsStaking(0x9D5f6E85b3DeAD1cb27C8033059aB472674f62d4);
    BiswapPool constant biswapPool = BiswapPool(0x72a79Ae14CFb139F9c52B304da2e42A683109Cc9);
    
    OracleSimpleBNBLink constant linkTwap = OracleSimpleBNBLink(0xab630027353470b3f0364153952eB020aaeE65Fb);
    OracleSimpleBNBNuts constant nutsTwap = OracleSimpleBNBNuts(0xD0A80f37E2958B6484E82B9bDC679726B3cE7eCA);
    UniswapV2 constant cakeV2 = UniswapV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    UniswapV2 constant ape = UniswapV2(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    SquirrelGoverance governance = SquirrelGoverance(0x32031eeD8c80f90C543DcF88a90d347f988e37EF);

    mapping(address => address) public farms;
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;
    uint256 public profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    mapping(address => int256) public nutsPayoutsTo;
    uint256 public nutsProfitPerShare;
    
    uint256 public nutsPerEpoch;
    uint256 public payoutEndTime;
    uint256 public lastDripTime;

    uint256 constant nutsPercent = 20;
    uint256 public nutsRate = 60; // 0.6 nuts
    uint256 public pendingNutsAlloc;
    uint256 nutsCompPerCake;
    bool compensationUsed;
    address blobby = msg.sender;

    constructor() public {
        nuts.approve(address(nutsStaking), 2 ** 255);
        nutsLP.approve(address(nutsStaking), 2 ** 255);
        biswap.approve(address(cakeV2), 2 ** 255);
        wbnb.approve(address(ape), 2 ** 255);
        nuts.approve(address(ape), 2 ** 255);
    }
    
    function() payable external { /* Payable */ }

    function deposit(uint256 amount) external {
        address farmer = msg.sender;
        require(farmer == tx.origin);
        require(!compensationUsed); // Don't let people deposit after compensation is needed
        
        FarmProxy proxy;
        if (farms[farmer] == address(0)) {
            proxy = new FarmProxy(address(this));
            farms[farmer] = address(proxy);
        } else {
            proxy = FarmProxy(farms[farmer]);
        }
        require(link.transferFrom(address(farmer), address(proxy), amount));
        
        dripNuts();
        proxy.deposit(amount);
        
        balances[farmer] += amount;
        totalDeposits += amount;
        nutsPayoutsTo[farmer] += (int256) (nutsProfitPerShare * amount);
    }

    function claimYield() public {
        address farmer = msg.sender;
        dripNuts();

        FarmProxy proxy = FarmProxy(farms[farmer]);
        if (address(proxy) != address(0)) {
            uint256 beforeBalance = biswap.balanceOf(address(this));
            proxy.withdraw(0);
            uint256 gained = biswap.balanceOf(address(this)) - beforeBalance;
            uint256 nutsAlloc = (gained * nutsPercent) / 100;
            pendingNutsAlloc += nutsAlloc;
            
            uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            
            nutsDividends += ((gained - nutsAlloc) * nutsRate) / 100; // Convert biswap gained into extra nuts
            if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
                nuts.transfer(farmer, nutsDividends);
            }
        }
    }
    
    function depositYield() external {
        address farmer = msg.sender;
        dripNuts();
        
        FarmProxy proxy = FarmProxy(farms[farmer]);
        if (address(proxy) != address(0)) {
            uint256 beforeBalance = biswap.balanceOf(address(this));
            proxy.withdraw(0);
            uint256 gained = biswap.balanceOf(address(this)) - beforeBalance;
            uint256 nutsAlloc = (gained * nutsPercent) / 100;
            pendingNutsAlloc += nutsAlloc;
            
            uint256 nutsDividends = (uint256) ((int256)(nutsProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
            nutsPayoutsTo[farmer] += (int256) (nutsDividends * magnitude);
            
            nutsDividends += ((gained - nutsAlloc) * nutsRate) / 100; // Convert biswap gained into extra nuts
            if (nutsDividends > 0 && nutsDividends <= nuts.balanceOf(address(this))) {
                nutsStaking.depositFor(farmer, nutsDividends);
            }
        }
    }

    function cashout(uint256 amount) external {
        address payable farmer = msg.sender;
        claimYield();

        uint256 systemTotal = totalDeposits;
        balances[farmer] = balances[farmer].sub(amount);
        nutsPayoutsTo[farmer] -= (int256) (nutsProfitPerShare * amount);
        totalDeposits = totalDeposits.sub(amount);

        uint256 beforeBalance = link.balanceOf(address(this));
        FarmProxy proxy = FarmProxy(farms[farmer]);
        farms[farmer].call(abi.encodePacked(proxy.withdraw.selector, abi.encode(amount)));

        uint256 gained = link.balanceOf(address(this)) - beforeBalance;
        if (gained > 0) {
            link.transfer(farmer, gained);
        }
        
        if (gained < (amount * 95) / 100) {
            compensate(farmer, amount - gained, amount, systemTotal);
        }
    }
    
    function compensate(address farmer, uint256 amountShort, uint256 farmersCashout, uint256 systemAmount) internal {
        if (!compensationUsed) {
            compensationUsed = true; // Flag to end deposits
            
            uint256 totalLinkShort = (amountShort * systemAmount) / farmersCashout;
            uint256 linkNutsValue = (totalLinkShort * linkTwap.consult(address(link), (10 ** 18))) / nutsTwap.consult(address(nuts), (10 ** 18)); // link * (link price divided by nuts price)
            uint256 beforeBalance = nuts.balanceOf(address(this));
            address(governance).call(abi.encodePacked(governance.pullCollateral.selector, abi.encode(linkNutsValue)));
            uint256 nutsCover = nuts.balanceOf(address(this)) - beforeBalance;
            nutsCompPerCake = (nutsCover * 1000) / systemAmount; // * 1000 to avoid roundings
        }
        nuts.transfer(farmer, (farmersCashout * nutsCompPerCake) / 1000);
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
        ape.swapExactTokensForTokens(bnbHalf, minNuts, path, address(this), 2 ** 255);
        uint256 nutsGained = nuts.balanceOf(address(this)) - beforeBalance;
        
        wbnb.withdraw(bnbHalf);
        uint256 bnb = address(this).balance;
        ape.addLiquidityETH.value(bnb)(address(nuts), nutsGained, nutsGained, bnb / 2, address(this), now);

        nutsStaking.distributeDivs(nutsLP.balanceOf(address(this)));
        linkTwap.update();
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

    // For beta this function just avoids blackholing link IF an issue causing compensation is later resolved
    function withdrawAfterSystemClosed(address proxy, uint256 amount) external {
        require(msg.sender == blobby);
        require(compensationUsed); // Cannot be called unless compensation was triggered

        FarmProxy farm = FarmProxy(proxy);
        farm.emergencyWithdraw();
        link.transfer(msg.sender, link.balanceOf(address(this)));
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
        nuts.burn(amount); // Longterm any biswap:nuts rate excess can be burnt 
    }
    
    function sweepBiswap(uint256 minBNB, uint256 minNuts) external {
        require(msg.sender == blobby);

        address[] memory path = new address[](2);
        path[0] = address(biswap);
        path[1] = address(wbnb);
        
        uint256 amount = biswap.balanceOf(address(this)) - pendingNutsAlloc;
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
        
        uint256 unClaimedDivs = (biswapPool.pendingReward(farms[farmer]) * nutsRate) / 100; // Convert biswap gained into extra nuts
        unClaimedDivs -= (unClaimedDivs * nutsPercent) / 100;
        unClaimedDivs += (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - nutsPayoutsTo[farmer]) / magnitude;
        return unClaimedDivs;
    }
    
}


contract NutsStaking {
    function depositFor(address player, uint256 amount) external;
    function distributeDivs(uint256 amount) external;
}

contract OracleSimpleBNBBiswap {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}

contract OracleSimpleBNBNuts {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}

contract OracleSimpleBNBLink {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}


interface SquirrelGoverance {
    function pullCollateral(uint256 amount) external returns (uint256 compensation);
    function compensationAvailable(address farm) external view returns (uint256);
    
}

interface BiswapPool {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function emergencyWithdraw() external;
    function pendingReward(address _user) external view returns (uint256);
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

contract WBNB is ERC20 {
    function withdraw(uint wad) external;
    function deposit() payable external;
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