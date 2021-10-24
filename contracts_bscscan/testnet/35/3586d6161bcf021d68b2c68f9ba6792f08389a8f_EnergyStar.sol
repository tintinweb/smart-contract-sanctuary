// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./IERC721.sol";
import "./IBOX.sol";
import "./ReentrancyGuard.sol";

contract EnergyStar is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum TokenType {
        NONE,
        BEI, // 1.  bei bei
        JING, // 2. jing jing
        HUAN, // 3. huan huan
        YIING, // 4. ying ying
        NI, // 5.ni ni
        SIMPLE, // 6. simple fuwa
        ENERGY // 7. energy fuwa
    }

    address public box;
    address public bot;
    address public usdt;

    bool public mintEnergyFuwaEnable;
    bool public buyEnergyEnable;

    uint256 public initEnergyFuwaNum = 5;
    uint256 public currentEnergyFuwaNum;
    uint256 public totalEnergyFuwaNum;
    address[] public energyFuwaOwners;

    mapping(address => uint256) public energyFuwaRewards;

    // user staking info
    uint256 public botBurnedForEnergyFuwa = 50 * (10 ** 18); // burn 50 bot for getting energy fuwa

    uint256 public energyPriceJing = 10 * (10 ** 18); // 10 usdt
    uint256 public energyPriceHuan = 50 * (10 ** 18); // 50 usdt
    uint256 public energyPriceYing = 75 * (10 ** 18); // 75 usdt
    uint256 public energyPriceNi = 100 * (10 ** 18); // 100 usdt
    uint256 public burnPercent = 200; // burn percent for energy price usdt

    uint256 public fullEnergyJing = 10;
    uint256 public fullEnergyHuan = 50;
    uint256 public fullEnergyYing = 75;
    uint256 public fullEnergyNi = 100;

    uint256 public emptyEnergy = 0;

    address public fixedWallet;

    constructor (address _box, address _bot, address _usdt) {
        box = _box;
        bot = _bot;
        usdt = _usdt;

        fixedWallet = _msgSender();
    }

    function queryStats() public view
        returns (bool mintEnergyFuwaEnablex, bool buyEnergyEnablex, uint256 botBurnedForEnergyFuwax, uint256 initEnergyFuwaNumx,
                    uint256 currentEnergyFuwaNumx, uint256 totalEnergyFuwaNumx,
                    uint256 energyPriceJingx, uint256 energyPriceHuanx, uint256 energyPriceYingx, uint256 energyPriceNix,
                    address[] memory energyFuwaOwnersx) {
        mintEnergyFuwaEnablex = mintEnergyFuwaEnable;
        buyEnergyEnablex = buyEnergyEnable;
        botBurnedForEnergyFuwax = botBurnedForEnergyFuwa;
        initEnergyFuwaNumx = initEnergyFuwaNum;
        currentEnergyFuwaNumx = currentEnergyFuwaNum;
        totalEnergyFuwaNumx = totalEnergyFuwaNum;
        energyPriceJingx = energyPriceJing;
        energyPriceHuanx = energyPriceHuan;
        energyPriceYingx = energyPriceYing;
        energyPriceNix = energyPriceNi;
        energyFuwaOwnersx = energyFuwaOwners;
    }

    function setBuyEnergyEnable(bool flag) public onlyOwner {
        buyEnergyEnable = flag;
    }

    function setEnergyPriceJing(uint256 value) public onlyOwner {
        energyPriceJing = value;
    }

    function setEnergyPriceHuan(uint256 value) public onlyOwner {
        energyPriceHuan = value;
    }

    function setEnergyPriceYing(uint256 value) public onlyOwner {
        energyPriceYing = value;
    }

    function setEnergyPriceNi(uint256 value) public onlyOwner {
        energyPriceNi = value;
    }

    function setFullEnergyJing(uint256 value) public onlyOwner {
        fullEnergyJing = value;
    }

    function setFullEnergyHuan(uint256 value) public onlyOwner {
        fullEnergyHuan = value;
    }

    function setFullEnergyYing(uint256 value) public onlyOwner {
        fullEnergyYing = value;
    }

    function setFullEnergyNi(uint256 value) public onlyOwner {
        fullEnergyNi = value;
    }

    function setEnergyFuwaEnable(bool flag) public onlyOwner {
        mintEnergyFuwaEnable = flag;
    }

    function setFixedWallet(address account) public onlyOwner {
        fixedWallet = account;
    }

    function setBotBurnedForEnergyFuwa(uint256 value) public onlyOwner {
        botBurnedForEnergyFuwa = value;
    }

    function setBox(address _box) public onlyOwner {
        box = _box;
    }

    function setBOT(address _bot) public onlyOwner {
        bot = _bot;
    }

    function setUSDT(address _usdt) public onlyOwner {
        usdt = _usdt;
    }

    function setEmptyEnergy(uint256 value) public onlyOwner {
        emptyEnergy = value;
    }

    function setBurnPercent(uint256 value) public onlyOwner {
        burnPercent = value;
    }

    function mintEnergyFuwa() public nonReentrant {
        require(mintEnergyFuwaEnable, "not start");
        require(currentEnergyFuwaNum < initEnergyFuwaNum, "no energy fuwa leftover");

        address sender = _msgSender();

        // transfer bot to fixed wallet
        TransferHelper.safeTransferFrom(bot, sender, fixedWallet, botBurnedForEnergyFuwa);

        // mint energy fuwa
        if (currentEnergyFuwaNum < initEnergyFuwaNum) {
            IBOX(box).adminMint(sender, uint256(TokenType.ENERGY));
            currentEnergyFuwaNum = currentEnergyFuwaNum.add(1);
            totalEnergyFuwaNum = totalEnergyFuwaNum.add(1);

            energyFuwaOwners.push(sender);
        }
    }

    function adminMintEnergyFuwa(address account) public onlyOwner returns (uint256 tokenId) {
        tokenId = IBOX(box).adminMint(account, uint256(TokenType.ENERGY));
        totalEnergyFuwaNum = totalEnergyFuwaNum.add(1);
        energyFuwaOwners.push(account);
    }

    function buyEnergy(uint256 tokenId) public {
        require(buyEnergyEnable, "not enable");
        // check energy
        require(IBOX(box).getTokenEnergy(tokenId) == 0, "energy not empty");

        uint256 energyPrice;
        uint256 fullEnergy;
        uint256 tp = IBOX(box).getType(tokenId);
        if (tp == uint256(TokenType.JING)) {
            energyPrice = energyPriceJing;
            fullEnergy = fullEnergyJing;
        } else if (tp == uint256(TokenType.HUAN)) {
            energyPrice = energyPriceHuan;
            fullEnergy = fullEnergyHuan;
        } else if (tp == uint256(TokenType.YIING)) {
            energyPrice = energyPriceYing;
            fullEnergy = fullEnergyYing;
        } else if (tp == uint256(TokenType.NI)) {
            energyPrice = energyPriceNi;
            fullEnergy = fullEnergyNi;
        }
        // transfer usdt
        TransferHelper.safeTransferFrom(usdt, _msgSender(), address(this), energyPrice);

        // set energy
        IBOX(box).setTokenEnergy(tokenId, fullEnergy);

        // distribute usdt, 20% -> fixed wallet
        uint256 burnAmount = energyPrice.mul(burnPercent).div(1000);
        TransferHelper.safeTransfer(usdt, fixedWallet, burnAmount);
        // 80% -> energy fuwa owners
        dispatchReward(energyPrice.sub(burnAmount));
    }

    function dispatchReward(uint256 amount) internal {
        uint256 len = energyFuwaOwners.length;
        for (uint256 i; i < len; i++) {
            address owner = energyFuwaOwners[i];
            uint256 reward = amount.div(len);
            TransferHelper.safeTransfer(usdt, owner, reward);
            energyFuwaRewards[owner] = energyFuwaRewards[owner].add(reward);
        }
    }

    function setTotalEnergyFuwaNum(uint256 value) public onlyOwner {
        totalEnergyFuwaNum = value;
    }

    function setCurrentEnergyFuwaNum(uint256 value) public onlyOwner {
        currentEnergyFuwaNum = value;
    }

    function withdrawBOT(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(bot, owner(), amount);
    }
}