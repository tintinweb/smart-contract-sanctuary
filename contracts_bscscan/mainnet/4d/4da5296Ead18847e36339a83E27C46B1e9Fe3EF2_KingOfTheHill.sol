/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

pragma solidity 0.5.8;

/**
 *
 * https://squirrel.finance
 * 
 * SquirrelFinance is a DeFi project which offers farm insurance
 *
 */
 
contract KingOfTheHill {
    
    ERC20 constant nuts = ERC20(0x8893D5fA71389673C5c4b9b3cb4EE1ba71207556);
    ERC20 constant banana = ERC20(0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95);
    ERC20 constant wbnb = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 constant bunny = ERC20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);
    
    InsuredBananaKeyVault constant bananaKeyVault = InsuredBananaKeyVault(0x73742D6108EAb0390515e6Fd702DaF172437B4b8);
    
    NutsStaking nutsStaking = NutsStaking(0x9D5f6E85b3DeAD1cb27C8033059aB472674f62d4);
    
    UniswapV2 constant ape = UniswapV2(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    UniswapV2 constant cakeV2 = UniswapV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    ERC20 constant nutsLP = ERC20(0x789fd04BFbC64169104466Ee0d48716E0452Bcf6);
    
    ERC20 keysLP;
    ERC20 keysToken;
    address governance = address(0x32031eeD8c80f90C543DcF88a90d347f988e37EF);
    address blobby = msg.sender;
    
    mapping(uint256 => Purchases[]) public keyPurchases;
    mapping(address => Earnings) public divs;
    
    uint256 public currentRoundNumber;
    uint256 public potTimer;
    
    uint256 public maxTimer = 24 hours;
    
    uint256 public nutsPrize;
    uint256 public bananaPrize;
    
    uint256 public previousNutsPrize;
    uint256 public previousBananaPrize;
    
    uint256 public pendingBananaAlloc;
    uint256 public pendingNutsAlloc;
    
    uint256 public futureRoundsPercent = 15;
    uint256 public nutsPercent = 5;
    
    uint256 public dailyDrip = 50; // 5%
    uint256 public lastDripTime;
    
    struct Purchases {
        address player;
        uint128 purchaseTime;
        uint128 lastDripTime;
    }
    
    struct Earnings {
        uint128 nuts;
        uint128 banana;
    }
    
    constructor() public {
        bunny.approve(address(cakeV2), 2 ** 255);
        banana.approve(address(ape), 2 ** 255);
        banana.approve(address(bananaKeyVault), 2 ** 255);
        wbnb.approve(address(ape), 2 ** 255);
        nuts.approve(address(ape), 2 ** 255);
        nuts.approve(address(nutsStaking), 2 ** 255);
        nutsLP.approve(address(nutsStaking), 2 ** 255);
    }
    
    function() payable external { /* Payable */ }
    
    function receiveApproval(address player, uint256, address, bytes calldata) external {
        require(msg.sender == address(keysToken));   
        require(now < potTimer);
        keysToken.transferFrom(player, address(this), 10 ** 18);
        
        keyPurchases[currentRoundNumber].push(Purchases(player, uint128(now), 0));
        potTimer = now + maxTimer;
        
        uint256 length = keyPurchases[currentRoundNumber].length;
        if (length > 3) {
            Purchases memory previous = keyPurchases[currentRoundNumber][length - 4];
            address previousPlayer = previous.player;
            
            uint128 timePast = uint128(now) - previous.purchaseTime;
            if (previous.lastDripTime > 0) {
                timePast = uint128(now) - previous.lastDripTime;
            }
            
            uint128 nutsDivs = uint128((timePast * nutsPrize * dailyDrip) / 86400000);
            uint128 bananaDivs = uint128((timePast * bananaPrize * dailyDrip) / 86400000);
            
            // claim divs for fourth key
            Earnings memory playersEarnings = divs[previousPlayer];
            playersEarnings.nuts += nutsDivs;
            playersEarnings.banana += bananaDivs;
            divs[previousPlayer] = playersEarnings;
            nutsPrize -= nutsDivs;
            bananaPrize -= bananaDivs;
        }
    }
    
    function claimDivs() external {
        Earnings memory playersEarnings = divs[msg.sender];
        
        dripKeyDivs(1, playersEarnings);
        dripKeyDivs(2, playersEarnings);
        dripKeyDivs(3, playersEarnings);
        
        nuts.transfer(msg.sender, playersEarnings.nuts);
        banana.transfer(msg.sender, playersEarnings.banana);
        delete divs[msg.sender];
    }
    
    function pendingDivs(address player) external view returns (uint256, uint256) {
        Earnings memory playersEarnings = divs[player];
        
        dripKeyDivsView(1, playersEarnings, player);
        dripKeyDivsView(2, playersEarnings, player);
        dripKeyDivsView(3, playersEarnings, player);
        
        return (playersEarnings.nuts, playersEarnings.banana);
    }
    
    function dripKeyDivs(uint256 i, Earnings memory playersEarnings) internal {
        uint256 length = keyPurchases[currentRoundNumber].length;
        if (i > length) {
            return;
        }
        
        Purchases memory key = keyPurchases[currentRoundNumber][length - i];
        
        if (key.player == msg.sender && now < potTimer) {
            uint128 timePast = uint128(now) - key.purchaseTime;
            if (key.lastDripTime > 0) {
                timePast = uint128(now) - key.lastDripTime;
            }
            
            uint128 nutsDivs = uint128((timePast * nutsPrize * dailyDrip) / 86400000);
            uint128 bananaDivs = uint128((timePast * bananaPrize * dailyDrip) / 86400000);

            playersEarnings.nuts += nutsDivs;
            playersEarnings.banana += bananaDivs;
            
            nutsPrize -= nutsDivs;
            bananaPrize -= bananaDivs;
            keyPurchases[currentRoundNumber][length - i].lastDripTime = uint128(now);
        }
    }
    
    function dripKeyDivsView(uint256 i, Earnings memory playersEarnings, address player) internal view {
        uint256 length = keyPurchases[currentRoundNumber].length;
        if (i > length) {
            return;
        }
        
        Purchases memory key = keyPurchases[currentRoundNumber][length - i];
        
        if (key.player == player && now < potTimer) {
            uint128 timePast = uint128(now) - key.purchaseTime;
            if (key.lastDripTime > 0) {
                timePast = uint128(now) - key.lastDripTime;
            }
            
            uint128 nutsDivs = uint128((timePast * nutsPrize * dailyDrip) / 86400000);
            uint128 bananaDivs = uint128((timePast * bananaPrize * dailyDrip) / 86400000);

            playersEarnings.nuts += nutsDivs;
            playersEarnings.banana += bananaDivs;
        }
    }
    
    function setupRound(address newKeys, address newKeysLP) external {
        require(msg.sender == address(blobby));
        keysToken = ERC20(newKeys);
        keysLP = ERC20(newKeysLP);
        keysLP.transferFrom(blobby, address(this), keysLP.balanceOf(blobby));
        keysLP.approve(address(ape), 2 ** 255);
    }
    
    // Start round
    function setWeeksRewards(uint256 amount) external {
        require(msg.sender == address(governance));
        require(address(keysToken) != address(0));
        nutsPrize += amount;
        if (potTimer == 0) {
            potTimer = now + maxTimer;
        }
    }
    
    function addNuts(uint256 amount) external {
        require(nuts.transferFrom(msg.sender, address(this), amount));
        require(potTimer > 0); // Round started
        nutsPrize += amount;
    }
    
    function addBanana(uint256 amount) external {
        require(banana.transferFrom(msg.sender, address(this), amount));
        bananaPrize += amount;
    }
    
    function addBunny(uint256 amount, uint256 minBanana) external {
        require(bunny.transferFrom(msg.sender, address(this), amount));
        
        address[] memory path = new address[](2);
        path[0] = address(bunny);
        path[1] = address(wbnb);
        
        cakeV2.swapExactTokensForTokens(amount, 1, path, address(this), 2 ** 255);

        path[0] = address(wbnb);
        path[1] = address(banana);
        uint256 beforeBalance = banana.balanceOf(address(this));
        ape.swapExactTokensForTokens(wbnb.balanceOf(address(this)), minBanana, path, address(this), 2 ** 255);
        uint256 bananaGained = banana.balanceOf(address(this)) - beforeBalance;
        
        bananaPrize += (bananaGained * 80) / 100; // 80% banana goes to game pot
        pendingBananaAlloc += (bananaGained * futureRoundsPercent) / 100; // 15% banana goes farm for future rounds
        pendingNutsAlloc += (bananaGained * nutsPercent) / 100; // 5% goes to Nuts Farm
    }
    
    function addBnb(uint256 amount, uint256 minBanana) external {
        require(wbnb.transferFrom(msg.sender, address(this), amount));
        
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(banana);
        uint256 beforeBalance = banana.balanceOf(address(this));
        ape.swapExactTokensForTokens(wbnb.balanceOf(address(this)), minBanana, path, address(this), 2 ** 255);
        uint256 bananaGained = banana.balanceOf(address(this)) - beforeBalance;
        
        bananaPrize += (bananaGained * 80) / 100; // 80% banana goes to game pot
        pendingBananaAlloc += (bananaGained * futureRoundsPercent) / 100; // 15% banana goes farm for future rounds
        pendingNutsAlloc += (bananaGained * nutsPercent) / 100; // 5% goes to Nuts Farm
    }
    
    function sweepNutsLP(uint256 amount, uint256 minBNB, uint256 minNuts) external {
        require(msg.sender == blobby);
        require(pendingNutsAlloc >= amount);
        pendingNutsAlloc = pendingNutsAlloc - amount;
        
        address[] memory path = new address[](2);
        path[0] = address(banana);
        path[1] = address(wbnb);
        
        ape.swapExactTokensForTokens(amount, minBNB, path, address(this), 2 ** 255);
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
    }
    
    function changeRewardPercents(uint256 newFutureRoundsPercent, uint256 newNutsPercent) external {
        require(msg.sender == blobby);
        require(newFutureRoundsPercent <= 15);
        require(newNutsPercent <= 20);
        require(newFutureRoundsPercent + newNutsPercent == 20);
        futureRoundsPercent = newFutureRoundsPercent;
        nutsPercent = newNutsPercent;
    }
    
    function changeDrip(uint256 newDaily) external {
        require(msg.sender == blobby);
        require(newDaily <= 100);
        require(newDaily >= 10);
        dailyDrip = newDaily;
    }
    
    function reduceMaxTimer(uint256 newMax) external {
        require(msg.sender == blobby);
        require(newMax < maxTimer);
        require(newMax >= 1 hours);
        maxTimer = newMax;
    }
    
    function addFomoBanana(uint256 amount) external {
        require(msg.sender == blobby);
        require(amount <= pendingBananaAlloc);
        bananaKeyVault.deposit(amount, address(0));
        pendingBananaAlloc -= amount;
    }
    
    function moveFomoBanana(uint128 amount, address newFomo) external {
        require(msg.sender == blobby);
        
        uint256 beforeBalance = banana.balanceOf(address(this));
        bananaKeyVault.cashout(amount);
        uint256 bananaGained = banana.balanceOf(address(this)) - beforeBalance;
        
        // Migrate the portion of banana which is farming for future fomo rounds
        banana.transfer(newFomo, bananaGained);
    }
    
    function upgradeNutsStaking(address stakingContract) external {
        require(msg.sender == blobby);
        require(address(nutsStaking) == address(0x9D5f6E85b3DeAD1cb27C8033059aB472674f62d4)); // Upgrade to staking v2 once after it is deployed
        nutsStaking = NutsStaking(stakingContract);
        nutsLP.approve(stakingContract, 2 ** 255);
        nuts.approve(stakingContract, 2 ** 255);
    }
    
    function endRound() external {
        require(potTimer > 0 && now >= potTimer);
        
        uint256 length = keyPurchases[currentRoundNumber].length;
        Purchases memory winner1 = keyPurchases[currentRoundNumber][length - 1];
        nuts.transfer(winner1.player, (nutsPrize * 50) / 100);
        banana.transfer(winner1.player, (bananaPrize * 50) / 100);
        
        Purchases memory winner2 = keyPurchases[currentRoundNumber][length - 2];
        nuts.transfer(winner2.player, (nutsPrize * 30) / 100);
        banana.transfer(winner2.player, (bananaPrize * 30) / 100);
        
        Purchases memory winner3 = keyPurchases[currentRoundNumber][length - 3];
        nuts.transfer(winner3.player, (nutsPrize * 20) / 100);
        banana.transfer(winner3.player, (bananaPrize * 20) / 100);
        
        previousNutsPrize = nutsPrize;
        previousBananaPrize = bananaPrize;
        
        potTimer = 0;
        nutsPrize = 0;
        bananaPrize = 0;
        currentRoundNumber++;
        
        ape.removeLiquidityETH(address(keysToken), keysLP.balanceOf(address(this)), 1, 1, blobby, 2 ** 255);
        keysToken = ERC20(0x0);
    }
    
    function getLatestBuys() public view returns (address[] memory, uint256[] memory) {
        uint256 length = keyPurchases[currentRoundNumber].length;
        uint256 results = length;
        if (results > 3) {
            results = 3;
        }

        address[] memory players = new address[](results);
        uint256[] memory purchaseTime = new uint256[](results);

        for (uint256 i = 0; i < results; i++) {
            Purchases memory purchase = keyPurchases[currentRoundNumber][length - i - 1];
            players[i] = purchase.player;
            purchaseTime[i] = purchase.purchaseTime;
        }
        
        return (players, purchaseTime);
    }
    
    function getPreviousWinners() public view returns (address[] memory, uint256[] memory, uint256, uint256) {
        if (currentRoundNumber == 0) {
            return (new address[](0), new uint256[](0), 0, 0);
        }

        uint256 length = keyPurchases[currentRoundNumber-1].length;
        uint256 results = length;
        if (results > 3) {
            results = 3;
        }

        address[] memory players = new address[](results);
        uint256[] memory purchaseTime = new uint256[](results);

        for (uint256 i = 0; i < results; i++) {
            Purchases memory purchase = keyPurchases[currentRoundNumber-1][length - i - 1];
            players[i] = purchase.player;
            purchaseTime[i] = purchase.purchaseTime;
        }
        return (players, purchaseTime, previousNutsPrize, previousBananaPrize);
    }
     
}


interface InsuredBananaKeyVault {
    function deposit(uint256 amount, address referrer) external;
    function cashout(uint128 amount) external;
}

interface NutsStaking {
    function distributeDivs(uint256 amount) external;
}

interface UniswapV2 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface WBNB {
    function withdraw(uint wad) external;
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

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract FomoKey is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    string public constant name = "Keys#07";
    string public constant symbol = "KEYS#07";
    uint8 public constant decimals = 18;
    
    address constant CAKE_FARM = address(0x73191b9200e9CC74AdfD0Ea27B7E0fB73F7256eb);
    address constant BANANA_FARM = address(0x73742D6108EAb0390515e6Fd702DaF172437B4b8);
    
    uint256 totalKeys = 200 * (10 ** 18);
    
    constructor() public {
        balances[msg.sender] = totalKeys;
    }

    function totalSupply() public view returns (uint256) {
        return totalKeys;
    }

    function balanceOf(address player) public view returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    function burn(uint256 amount) external {
        if (amount > 0) {
            totalKeys = totalKeys.sub(amount);
            balances[msg.sender] = balances[msg.sender].sub(amount);
            emit Transfer(msg.sender, address(0), amount);
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);
        return true;
    }
    
    function claimFarmKeys(address player, uint256 amount) external {
        require(msg.sender == CAKE_FARM || msg.sender == BANANA_FARM);
        balances[player] = balances[player].add(amount);
        totalKeys = totalKeys.add(amount);
        emit Transfer(address(0), player, amount);
    }
    
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}