pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interface/IBankConfig.sol";
import "./interface/IFarm.sol";
import "./interface/IGoblin.sol";
import "./utils/SafeToken.sol";

contract Bank is Ownable, ReentrancyGuard {
    using SafeToken for address;
    using SafeMath for uint256;

    event OpPosition(uint256 indexed id, uint256[2] debts, uint256[2] backs);
    event Liquidate(uint256 indexed id, address indexed killer, uint256[2] prize, uint256[2] left);

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /* ----------------- Banks Info ----------------- */

    struct TokenBank {
        address tokenAddr;
        bool isOpen;
        bool canDeposit;
        uint256 poolId;

        uint256 totalVal;           // Left balance, including reserved
        uint256 totalShares;        // Stake shares
        uint256 totalDebt;          // Debts balance
        uint256 totalDebtShares;    // Debts shares
        uint256 totalReserve;       // Reserved amount.
        uint256 lastInterestTime;
    }

    struct UserBankInfo {
        mapping(address => uint256) sharesPerToken;     // Shares per token pool
        EnumerableSet.AddressSet banksAddress;          // Stored banks' address.
    }

    mapping(address => TokenBank) public banks;         // Token address => TokenBank
    mapping(address => UserBankInfo) userBankInfo;      // User account address => Bank address.

    /* -------- Productions / Positions Info -------- */

    struct Production {
        address[2] borrowToken;
        bool isOpen;
        bool[2] canBorrow;

        IGoblin goblin;
        uint256[2] minDebt;
        uint256 openFactor;         // When open: (debts / total) should <= (openFactor / 10000)
        uint256 liquidateFactor;    // When liquidate: new health should <= (liquidateFactor / 10000)
    }

    struct Position {
        address owner;
        uint256 productionId;
        uint256[2] debtShare;
    }

    struct UserPPInfo {
        EnumerableSet.UintSet posId;                    // position id
        EnumerableSet.UintSet prodId;                   // production id
        mapping(uint256 => uint256) posNum;             // position num of each production(id)
    }

    mapping(address => UserPPInfo) userPPInfo;      // User Productions, Positions Info.

    mapping(uint256 => Production) productions;
    uint256 public currentProdId = 1;

    mapping(uint256 => Position) positions;     // pos info can read in positionInfo()
    uint256 public currentPos = 1;

    EnumerableSet.UintSet allPosId;

    /* ----------------- Others ----------------- */

    IBankConfig public config;
    IFarm Farm;

    /* ----------------- Temp ----------------- */

    // Used in opProduction to prevent stack over deep
    struct WorkAmount {
        uint256 sendBnb;
        uint256[2] beforeToken;      // How many token in the pool after borrow before goblin work
        uint256[2] debts;
        uint256[2] backToken;
        bool[2] isBorrowBnb;
        bool borrowed;
    }

    // Used in liquidate to prevent stack over deep
    struct liqTemp {
        uint256[2] debts;
        uint256 health;
        uint256[2] before;
        uint256 back;           // Only one item is to save memory.
        uint256[2] prize;
        uint256[2] left;
        bool[2] isBnb;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    constructor(address _stakingRewards) public {
        Farm = IFarm(_stakingRewards);
    }

    /* ==================================== Read ==================================== */

    // New health
    function allPosIdAndHealth() external view returns (uint256[] memory, uint256[] memory) {
        uint256 len = EnumerableSet.length(allPosId);
        uint256[] memory posId = new uint256[](len);
        uint256[] memory posHealth = new uint256[](len);

        for (uint256 i = 0; i < len; ++i) {
            uint256 tempPosId = EnumerableSet.at(allPosId, i);
            Position storage pos = positions[tempPosId];
            Production storage prod = productions[pos.productionId];
            uint256 debt0 = debtShareToVal(prod.borrowToken[0], pos.debtShare[0]);
            uint256 debt1 = debtShareToVal(prod.borrowToken[1], pos.debtShare[1]);

            posId[i] = tempPosId;
            posHealth[i] = prod.goblin.newHealth(tempPosId, prod.borrowToken, [debt0, debt1]);
        }

        return (posId, posHealth);
    }

    function positionInfo(uint256 posId)
        external
        view
        returns (
            uint256,                // prod id 
            uint256,                // lp amount
            uint256,                // new health
            uint256[2] memory,      // health
            uint256[2] memory,      // debts
            address                 // owner
        )
    {
        Position storage pos = positions[posId];
        Production storage prod = productions[pos.productionId];

        uint256 debt0 = debtShareToVal(prod.borrowToken[0], pos.debtShare[0]);
        uint256 debt1 = debtShareToVal(prod.borrowToken[1], pos.debtShare[1]);

        return (
            pos.productionId,
            prod.goblin.posLPAmount(posId),
            prod.goblin.newHealth(posId, prod.borrowToken, [debt0, debt1]),
            prod.goblin.health(posId, prod.borrowToken, [debt0, debt1]),
            [debt0, debt1],
            pos.owner);
    }

    function productionsInfo(uint256 prodId) 
        external 
        view 
        returns (
            address[2] memory,  // borrowToken
            bool,               // isOpen
            bool[2] memory,     // canBorrow
            address,            // goblin
            uint256[2] memory,  // minDebt
            uint256,            // openFactor   
            uint256             // liquidateFactor
        )
    {
        Production storage prod = productions[prodId];
        
        return (
            [prod.borrowToken[0], prod.borrowToken[1]], 
            prod.isOpen, 
            [prod.canBorrow[0], prod.canBorrow[1]], 
            address(prod.goblin), 
            [prod.minDebt[0], prod.minDebt[0]], 
            prod.openFactor, 
            prod.liquidateFactor
        );
    }

    // Total amount, not including reserved
    function totalToken(address token) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');

        uint balance = token == address(0)? address(this).balance: SafeToken.myBalance(token);
        balance = bank.totalVal < balance? bank.totalVal: balance;

        return balance.add(bank.totalDebt).sub(bank.totalReserve);
    }

    function debtShareToVal(address token, uint256 debtShare) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');

        if (bank.totalDebtShares == 0) return debtShare;
        return debtShare.mul(bank.totalDebt).div(bank.totalDebtShares);
    }

    function debtValToShare(address token, uint256 debtVal) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');

        if (bank.totalDebt == 0) return debtVal;
        return debtVal.mul(bank.totalDebtShares).div(bank.totalDebt);
    }

    /* ----------------- Get user info ----------------- */

    /* ---- User Banks Info ---- */

    function userBanksNum(address account) public view returns (uint256) {
        return EnumerableSet.length(userBankInfo[account].banksAddress);
    }

    // Bank address is same as token address store in bank.
    function userBankAddress(address account, uint256 index) public view returns (address) {
        return EnumerableSet.at(userBankInfo[account].banksAddress, index);
    }

    function userSharesPerTokoen(address account, address token) external view returns (uint256) {
        return userBankInfo[account].sharesPerToken[token];
    }

    function earnPertoken(address account, address token) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        return Farm.stakeEarnedPerPool(bank.poolId, account);
    }

    function earn(address account) external view returns (uint256) {
        uint256 totalEarn = 0;
        for (uint256 index = 0; index < userBanksNum(account); ++index) {
            totalEarn = totalEarn.add(earnPertoken(account, userBankAddress(account, index)));
        }
        return totalEarn;
    }

    /* ---- User Positions Info ---- */

    function userAllPosId(address account) external view returns (uint256[] memory) {
        uint256 len = userPosNum(account);
        uint256[] memory posId = new uint256[](len);

        for (uint256 i = 0; i < len; ++i) {
            posId[i] = userPosId(account, i);
        }

        return posId;
    }

    function userPosNum(address account) public view returns (uint256) {
        return EnumerableSet.length(userPPInfo[account].posId);
    }

    function userPosId(address account, uint256 index) public view returns (uint256) {
        return EnumerableSet.at(userPPInfo[account].posId, index);
    }

    /* ---- User Productions Info ---- */

    function userAllProdId(address account) external view returns (uint256[] memory) {
        uint256 len = userProdNum(account);
        uint256[] memory prodId = new uint256[](len);

        for (uint256 i = 0; i < len; ++i) {
            prodId[i] = userProdId(account, i);
        }

        return prodId;
    }

    function userProdNum(address account) public view returns (uint256) {
        return EnumerableSet.length(userPPInfo[account].prodId);
    }

    function userProdId(address account, uint256 index) public view returns (uint256) {
        return EnumerableSet.at(userPPInfo[account].prodId, index);
    }

    function userEarnPerProd(address account, uint256 prodId) external view returns (uint256, uint256) {
        Production storage prod = productions[prodId];
        return prod.goblin.userEarnedAmount(account);
    }

    /* ==================================== Write ==================================== */

    function deposit(address token, uint256 amount) external payable nonReentrant {
        TokenBank storage bank = banks[token];
        UserBankInfo storage user = userBankInfo[msg.sender];
        require(bank.isOpen && bank.canDeposit, 'Token not exist or cannot deposit');

        _calInterest(token);

        if (token != address(0)) {
            // Token is not bnb
            SafeToken.safeTransferFrom(token, msg.sender, address(this), amount);
        } else {
            amount = msg.value;
        }

        bank.totalVal = bank.totalVal.add(amount);
        uint256 total = totalToken(token).sub(amount);

        uint256 newShares = (total == 0 || bank.totalShares == 0) ? amount: amount.mul(bank.totalShares).div(total);

        // Update bank info
        bank.totalShares = bank.totalShares.add(newShares);

        // Update user info
        user.sharesPerToken[token] = user.sharesPerToken[token].add(newShares);
        EnumerableSet.add(user.banksAddress, token);

        Farm.stake(bank.poolId, msg.sender, newShares);
    }

    function withdraw(address token, uint256 withdrawShares) external nonReentrant {
        TokenBank storage bank = banks[token];
        UserBankInfo storage user = userBankInfo[msg.sender];
        require(bank.isOpen, 'Token not exist');

        _calInterest(token);

        uint256 amount = withdrawShares.mul(totalToken(token)).div(bank.totalShares);
        bank.totalVal = bank.totalVal.sub(amount);

        bank.totalShares = bank.totalShares.sub(withdrawShares);
        user.sharesPerToken[token] = user.sharesPerToken[token].sub(withdrawShares);

        Farm.withdraw(bank.poolId, msg.sender, withdrawShares);

        // get DEMA rewards
        getBankRewards();

        if (token == address(0)) {//Bnb
            SafeToken.safeTransferETH(msg.sender, amount);
        } else {
            SafeToken.safeTransfer(token, msg.sender, amount);
        }
    }

    /**
     * @dev Create position:
     * opPosition(0, productionId, [borrow0, borrow1],
     *     [addLpStrategyAddress, _token0, _token1, token0Amount, token1Amount, _minLPAmount] )
     * note: if token is Bnb, token address should be address(0);
     *
     * @dev Replenishment:
     * opPosition(posId, productionId, [0, 0],
     *     [addLpStrategyAddress, _token0, _token1, token0Amount, token1Amount, _minLPAmount] )
     *
     * @dev Withdraw:
     * opPosition(posId, productionId, [0, 0], [withdrawStrategyAddress, token0, token1, rate, whichWantBack] )
     * note: rate means how many LP will be removed liquidity. max rate is 10000 means 100%.
     *        The amount of repaid debts is the same rate of total debts.
     *        whichWantBack = 0(token0), 1(token1), 2(token what surplus).
     *
     * @dev Repay:
     * opPosition(posId, productionId, [0, 0], [withdrawStrategyAddress, token0, token1, rate, 3] )
     * note: rate means how many LP will be removed liquidity. max rate is 10000 means 100%.
     *       All withdrawn LP will used to repay debts.
     */
    function opPosition(uint256 posId, uint256 prodId, uint256[2] calldata borrow, bytes calldata data)
        external
        payable
        onlyEOA
        nonReentrant
    {
        UserPPInfo storage user = userPPInfo[msg.sender];
        if (posId == 0) {
            // Create a new position
            posId = currentPos;
            currentPos ++;
            positions[posId].owner = msg.sender;
            positions[posId].productionId = prodId;

            EnumerableSet.add(user.posId, posId);
            EnumerableSet.add(allPosId, posId);
            EnumerableSet.add(user.prodId, prodId);
            user.posNum[prodId] = user.posNum[prodId].add(1);

        } else {
            require(posId < currentPos, "bad position id");
            require(positions[posId].owner == msg.sender, "not position owner");

            prodId = positions[posId].productionId;
        }

        Production storage production = productions[prodId];

        require(production.isOpen, 'Production not exists');

        require((borrow[0] == 0 || production.canBorrow[0]) &&
            (borrow[1] == 0 || production.canBorrow[1]) , "Production can not borrow");

        _calInterest(production.borrowToken[0]);
        _calInterest(production.borrowToken[1]);

        WorkAmount memory amount;
        amount.sendBnb = msg.value;
        amount.debts = _removeDebt(positions[posId], production);
        uint256 i;

        for (i = 0; i < 2; ++i) {
            amount.debts[i] = amount.debts[i].add(borrow[i]);
            amount.isBorrowBnb[i] = production.borrowToken[i] == address(0);

            // Save the amount of borrow token after borrowing before goblin work.
            if (amount.isBorrowBnb[i]) {
                amount.sendBnb = amount.sendBnb.add(borrow[i]);
                require(amount.sendBnb <= address(this).balance && amount.debts[i] <= banks[production.borrowToken[i]].totalVal,
                    "insufficient Bnb in the bank");
                amount.beforeToken[i] = address(this).balance.sub(amount.sendBnb);

            } else {
                amount.beforeToken[i] = SafeToken.myBalance(production.borrowToken[i]);
                require(borrow[i] <= amount.beforeToken[i] && amount.debts[i] <= banks[production.borrowToken[i]].totalVal,
                    "insufficient borrowToken in the bank");
                amount.beforeToken[i] = amount.beforeToken[i].sub(borrow[i]);
                SafeToken.safeApprove(production.borrowToken[i], address(production.goblin), borrow[i]);
            }
        }

        production.goblin.work{value: amount.sendBnb}(
            posId,
            msg.sender,
            production.borrowToken,
            borrow,
            amount.debts,
            data
        );

        amount.borrowed = false;

        // Calculate the back token amount
        for (i = 0; i < 2; ++i) {
            amount.backToken[i] = amount.isBorrowBnb[i] ? (address(this).balance.sub(amount.beforeToken[i])) :
                SafeToken.myBalance(production.borrowToken[i]).sub(amount.beforeToken[i]);

            if(amount.backToken[i] >= amount.debts[i]) {
                // backToken are much more than debts, so send back backToken-debts.
                amount.backToken[i] = amount.backToken[i].sub(amount.debts[i]);
                amount.debts[i] = 0;

                amount.isBorrowBnb[i] ? SafeToken.safeTransferETH(msg.sender, amount.backToken[i]):
                    SafeToken.safeTransfer(production.borrowToken[i], msg.sender, amount.backToken[i]);

            } else {
                // There are some borrow token
                amount.borrowed = true;
                amount.debts[i] = amount.debts[i].sub(amount.backToken[i]);
                amount.backToken[i] = 0;

                require(amount.debts[i] >= production.minDebt[i], "too small debts size");
            }
        }

        if (amount.borrowed) {
            // Return the amount of each borrow token can be withdrawn with the given borrow amount rate.
            uint256[2] memory health = production.goblin.health(posId, production.borrowToken, amount.debts);

            require(health[0].mul(production.openFactor) >= amount.debts[0].mul(10000), "bad work factor");
            require(health[1].mul(production.openFactor) >= amount.debts[1].mul(10000), "bad work factor");

            _addDebt(positions[posId], production, amount.debts);
        }
        // If the lp amount in current pos is 0, delete the pos.
        else if (production.goblin.posLPAmount(posId) == 0) {
            EnumerableSet.remove(user.posId, posId);
            EnumerableSet.remove(allPosId, posId);
            user.posNum[prodId] = user.posNum[prodId].sub(1);

            // Get all rewards. Note that it MUST after user.posNum update.
            getRewardsAllProd();
        }

        emit OpPosition(posId, amount.debts, amount.backToken);
    }

    function liquidate(uint256 posId) external onlyEOA nonReentrant {
        Position storage pos = positions[posId];

        // While using new health, if user loss too much, it also can be liquidated.
        // require(pos.debtShare[0] > 0 || pos.debtShare[1] > 0, "no debts");
        Production storage production = productions[pos.productionId];
        liqTemp memory temp;

        temp.debts = _removeDebt(pos, production);

        temp.health = production.goblin.newHealth(posId, production.borrowToken, temp.debts);
        require(temp.health < production.liquidateFactor, "can't liquidate");

        // Save before amount
        uint256 i;
        for (i = 0; i < 2; ++i) {
            temp.isBnb[i] = production.borrowToken[i] == address(0);
            temp.before[i] = temp.isBnb[i] ? address(this).balance : SafeToken.myBalance(production.borrowToken[i]);
        }

        production.goblin.liquidate(posId, pos.owner, production.borrowToken, temp.debts);

        // Delete the pos from owner, posNum -= 1.
        UserPPInfo storage owner = userPPInfo[pos.owner];
        EnumerableSet.remove(owner.posId, posId);
        EnumerableSet.remove(allPosId, posId);
        owner.posNum[pos.productionId] = owner.posNum[pos.productionId].sub(1);

        // Check back amount. Repay first then send reward to sender, finally send left token back to pos.owner.
        for (i = 0; i < 2; ++i) {
            temp.back = temp.isBnb[i] ? address(this).balance: SafeToken.myBalance(production.borrowToken[i]);
            temp.back = temp.back.sub(temp.before[i]);
            
            if (temp.back > temp.debts[i]) {
                temp.back = temp.back.sub(temp.debts[i]);
                temp.prize[i] = temp.back.mul(config.getLiquidateBps()).div(10000);
                temp.left[i] = temp.back.sub(temp.prize[i]);

                // Send reward to sender
                if (temp.prize[i] > 0) {
                    temp.isBnb[i] ?
                        SafeToken.safeTransferETH(msg.sender, temp.prize[i]) :
                        SafeToken.safeTransfer(production.borrowToken[i], msg.sender, temp.prize[i]);
                }
                // Send left token to pos.owner.
                if (temp.left[i] > 0) {
                    temp.isBnb[i] ?
                        SafeToken.safeTransferETH(pos.owner, temp.left[i]) :
                        SafeToken.safeTransfer(production.borrowToken[i], pos.owner, temp.left[i]);
                }
            } else {
                banks[production.borrowToken[i]].totalVal =
                    banks[production.borrowToken[i]].totalVal.sub(temp.debts[i]).add(temp.back);
            }
        }

        emit Liquidate(posId, msg.sender, temp.prize, temp.left);
    }

    /* ----------------- Get rewards ----------------- */

    // Send earned DEMA from per token bank to user.
    function getBankRewardsPerToken(address token) public {
        TokenBank storage bank = banks[token];
        Farm.getStakeRewardsPerPool(bank.poolId, msg.sender);

        // Delete pool if no left shares
        UserBankInfo storage user = userBankInfo[msg.sender];
        if (user.sharesPerToken[token] == 0) {
            EnumerableSet.remove(user.banksAddress, token);
        }
    }

    // Send earned DEMA from all tokens to user.
    function getBankRewards() public {
        for (uint256 index = userBanksNum(msg.sender); index > 0; --index) {
            getBankRewardsPerToken(userBankAddress(msg.sender, index - 1));
        }
    }

    // Get MDX and DEMA rewards of per production
    function getRewardsPerProd(uint256 prodId) public {
        productions[prodId].goblin.getAllRewards(msg.sender);

        // Delete pool if no left pos.
        UserPPInfo storage user = userPPInfo[msg.sender];
        if (user.posNum[prodId] == 0) {
            EnumerableSet.remove(user.prodId, prodId);
        }

    }

    // Get MDX and DEMA rewards of all productions
    function getRewardsAllProd() public {
        for (uint256 i = userProdNum(msg.sender); i > 0; --i) {
            getRewardsPerProd(userProdId(msg.sender, i-1));
        }
    }

    /* ==================================== Internal ==================================== */

    function _addDebt(Position storage pos, Production storage production, uint256[2] memory debtVal) internal {
        for (uint256 i = 0; i < 2; ++i) {
            if (debtVal[i] == 0) {
                continue;
            }

            TokenBank storage bank = banks[production.borrowToken[i]];

            uint256 debtShare = debtValToShare(production.borrowToken[i], debtVal[i]);
            pos.debtShare[i] = pos.debtShare[i].add(debtShare);

            bank.totalVal = bank.totalVal.sub(debtVal[i]);
            bank.totalDebtShares = bank.totalDebtShares.add(debtShare);
            bank.totalDebt = bank.totalDebt.add(debtVal[i]);
        }
    }

    function _removeDebt(Position storage pos, Production storage production) internal returns (uint256[2] memory) {
        uint256[2] memory debtVal;

        for (uint256 i = 0; i < 2; ++i) {
            // For each borrow token
            TokenBank storage bank = banks[production.borrowToken[i]];

            uint256 debtShare = pos.debtShare[i];
            if (debtShare > 0) {
                debtVal[i] = debtShareToVal(production.borrowToken[i], debtShare);
                pos.debtShare[i] = 0;

                bank.totalVal = bank.totalVal.add(debtVal[i]);
                bank.totalDebtShares = bank.totalDebtShares.sub(debtShare);
                bank.totalDebt = bank.totalDebt.sub(debtVal[i]);
            } else {
                debtVal[i] = 0;
            }
        }

        return debtVal;
    }

    function _calInterest(address token) internal {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');

        if (now > bank.lastInterestTime) {
            uint256 timePast = now.sub(bank.lastInterestTime);
            uint256 totalDebt = bank.totalDebt;
            uint256 totalBalance = totalToken(token);

            uint256 ratePerSec = config.getInterestRate(totalDebt, totalBalance, token);
            uint256 interest = ratePerSec.mul(timePast).mul(totalDebt).div(1e18);

            uint256 toReserve = interest.mul(config.getReserveBps()).div(10000);
            bank.totalReserve = bank.totalReserve.add(toReserve);
            bank.totalDebt = bank.totalDebt.add(interest);
            bank.lastInterestTime = now;
        }
    }

    /* ==================================== Only owner ==================================== */

    function updateConfig(IBankConfig _config) external onlyOwner {
        config = _config;
    }

    function addToken(address token, uint256 poolId) external onlyOwner {
        TokenBank storage bank = banks[token];
        require(!bank.isOpen, 'token already exists');

        bank.isOpen = true;
        bank.tokenAddr = token;
        bank.canDeposit = true;
        bank.poolId = poolId;

        bank.totalVal = 0;
        bank.totalShares = 0;
        bank.totalDebt = 0;
        bank.totalDebtShares = 0;
        bank.totalReserve = 0;
        bank.lastInterestTime = now;
    }

    function updateToken(address token, bool canDeposit) external onlyOwner {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');

        bank.canDeposit = canDeposit;
    }

    function opProduction(
        uint256 prodId,
        bool isOpen,
        bool[2] calldata canBorrow,
        address[2] calldata borrowToken,
        address goblin,
        uint256[2] calldata minDebt,
        uint256 openFactor,
        uint256 liquidateFactor
    )
        external
        onlyOwner
    {
        require(borrowToken[0] != borrowToken[1], "Borrow tokens cannot be same");
        require(canBorrow[0] || minDebt[0]==0, "Token 0 can borrow or min debt should be 0");
        require(canBorrow[1] || minDebt[1]==0, "Token 1 can borrow or min debt should be 0");
        require(openFactor < 10000, "Open factor should less than 10000");
        require(liquidateFactor < 9000, "Liquidate factor should less than 9000");

        if(prodId == 0){
            prodId = currentProdId;
            currentProdId ++;
        } else {
            require(prodId < currentProdId, "bad production id");
        }

        Production storage production = productions[prodId];
        production.isOpen = isOpen;
        production.canBorrow = canBorrow;

        // Don't change it once set it. We can add new production.
        production.borrowToken = borrowToken;
        production.goblin = IGoblin(goblin);

        production.minDebt = minDebt;
        production.openFactor = openFactor;
        production.liquidateFactor = liquidateFactor;
    }

    function withdrawReserve(address token, address to, uint256 value)
        external
        onlyOwner
        nonReentrant
    {
        TokenBank storage bank = banks[token];

        uint256 balance = token == address(0)? address(this).balance: SafeToken.myBalance(token);
        if(balance >= bank.totalVal.add(value)) {
            // Received not by deposit
        } else {
            bank.totalReserve = bank.totalReserve.sub(value);
            bank.totalVal = bank.totalVal.sub(value);
        }

        if (token == address(0)) {
            SafeToken.safeTransferETH(to, value);
        } else {
            SafeToken.safeTransfer(token, to, value);
        }
    }
    
    receive() external payable {}
}

pragma solidity >=0.5.0 <0.8.0;

interface IBankConfig {

    function getInterestRate(uint256 debt, uint256 floating, address token) external view returns (uint256);

    function getReserveBps() external view returns (uint256);

    function getLiquidateBps() external view returns (uint256);
}

pragma solidity >=0.5.0 <0.8.0;

// Inheritance
interface IFarm {

    /* ==================================== Read ==================================== */
    
    /* ----------------- Pool Info ----------------- */

    function lastTimeRewardApplicable(uint256 poolId) external view returns (uint256);

    function rewardPerToken(uint256 poolId) external view returns (uint256);

    function getRewardForDuration(uint256 poolId) external view returns (uint256);

    /* ----------------- User Staked Info ----------------- */

    // Rewards amount for user in one pool.
    function stakeEarnedPerPool(uint256 poolId, address account) external view returns (uint256);

    /* ----------------- User Bonus Info  ----------------- */

    // Rewards amount for bonus in one pool.
    function bonusEarnedPerPool(uint256 poolId, address account) external view returns (uint256);

    // Rewards amount for bonus in all pools.
    function bonusEarned(address account) external view returns (uint256);

    /* ----------------- Inviter Bonus Info  ----------------- */

    // Rewards amount for inviter bonus in one pool.
    function inviterBonusEarnedPerPool(uint256 poolId, address account) external view returns (uint256);

    // Rewards amount for inviter bonus in all pools.
    function inviterBonusEarned(address account) external view returns (uint256);


    /* ==================================== Write ==================================== */

   
    /* ----------------- For Staked ----------------- */

    // Send rewards from the target pool directly to users' account
    function getStakeRewardsPerPool(uint256 poolId, address account) external;

    /* ----------------- For Bonus ----------------- */

    function getBonusRewardsPerPool(uint256 poolId, address account) external;

    function getBonusRewards(address account) external;

    /* ----------------- For Inviter Bonus ----------------- */

    function getInviterBonusRewardsPerPool(uint256 poolId, address account) external;

    function getInviterRewards(address account) external;


    /* ==================================== Only operator ==================================== */

    // Inviter is address(0), when there is no inviter.
    function stake(uint256 poolId, address account, uint256 amount) external;

    // Must indicate the inviter once the user have has one. 
    function withdraw(uint256 poolId, address account, uint256 amount) external;   
}

pragma solidity >=0.5.0 <0.8.0;


interface IGoblin {
    /* ==================================== Read ==================================== */

    /// @return Earned MDX and DEMA amount.
    function userEarnedAmount(address account) external view returns (uint256, uint256);

    /// @dev Get the lp amount at given posId.
    function posLPAmount(uint256 posId) external view returns (uint256);

    /**
     * @dev Return the amount of each borrow token can be withdrawn with the given borrow amount rate.
     * @param id The position ID to perform health check.
     * @param borrowTokens Address of two tokens this position had debt.
     * @param debts Debts of two tokens.
     */
    function health(
        uint256 id,
        address[2] calldata borrowTokens,
        uint256[2] calldata debts
    ) external view returns (uint256[2] memory);

    /**
     * @dev Return the left rate of the principal. need to divide to 10000, 100 means 1%
     * @param id The position ID to perform loss rate check.
     * @param borrowTokens Address of two tokens this position had debt.
     * @param debts Debts of two tokens.
     */
    function newHealth(
        uint256 id,
        address[2] calldata borrowTokens,
        uint256[2] calldata debts
    ) external view returns (uint256);

    /* ==================================== Write ==================================== */

    /// @dev Send all mdx rewards earned in this goblin to account.
    function getAllRewards(address account) external;

    /**
     * @dev Work on the given position. Must be called by the operator.
     * @param id The position ID to work on.
     * @param user The original user that is interacting with the operator.
     * @param borrowTokens Address of two tokens user borrow from bank.
     * @param borrowAmounts The amount of two borrow tokens.
     * @param debts The user's debt amount of two tokens.
     * @param data The encoded data, consisting of strategy address and bytes to strategy.
     */
    function work(
        uint256 id,
        address user,
        address[2] calldata borrowTokens,
        uint256[2] calldata borrowAmounts,
        uint256[2] calldata debts,
        bytes calldata data
    ) external payable;

    /**
     * @dev Liquidate the given position by converting it to debtToken and return back to caller.
     * @param id The position ID to perform liquidation.
     * @param user The address than this position belong to.
     * @param borrowTokens Two tokens address user borrow from bank.
     * @param debts Two tokens debts.
     */
    function liquidate(
        uint256 id,
        address user,
        address[2] calldata borrowTokens,
        uint256[2] calldata debts) external;
}

pragma solidity ^0.6.0;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor () internal {
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

