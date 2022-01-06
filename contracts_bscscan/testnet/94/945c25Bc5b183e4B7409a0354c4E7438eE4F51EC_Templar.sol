/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// File: contracts/utils/Owner.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Owner {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able, address indexed owner);

    constructor() {
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0), "zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner, "not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _pause;
    }

    function setPaused(bool p) external onlyOwner {
        _pause = p;
    }

    modifier checkContractCall() {
        require(contractCallable() || notContract(msg.sender), "non contract");
        _;
    }

    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }

    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able, _owner);
    }

    function notContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }
}

// File: contracts/Templar.sol

pragma solidity ^0.8.0;

interface IRandom {
    function requestRandomness(
        uint256 tokenId,
        uint256 randomness,
        bool isYes
    ) external;

    function usable(uint256 tokenId) external view returns (bool);

    function openRand(uint256 tokenId) external returns (bool, uint256);

    function fightRand(uint256 tokenId, uint256 energy)
        external
        returns (bool, uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IGTOKEN20Miner {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

interface IGTOKEN721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address recipient_) external returns (uint256);

    function getTokens(address owner) external view returns (uint256[] memory);
}

contract Templar is Owner {
    struct Token {
        uint256 fightAt;
        uint256 todayUsed;
        uint256 energy;
        uint256 levelCode;
        uint256 supplyId;
        uint256 winCount;
        uint256 dgeeCount;
        bool isStake;
        bool isSell;
    }
    struct AccountInfo {
        uint256 reward;
        uint256 claimAt;
        uint256 totalClaim;
        uint256 dgeReward;
        uint256 xdgeReward;
        bool isInvite;
        address inviter;
        address[] invitee;
    }
    struct Mission {
        uint256 winRate;
        uint256 reward;
        uint256 fee;
    }
    struct Level {
        uint256 winRateAdd;
        uint256 rewardAdd;
        uint256 recoveryFee;
        uint256 reMintFee;
        uint256 reMintCount;
        uint256[5] reMintOffset;
    }
    struct Supply {
        uint256 fee;
        address token;
        uint256 total;
        uint256 left;
        uint256[] levelCode;
        uint256[] levelOffset;
    }

    IERC20 public immutable GTOKEN20;
    IGTOKEN721 public immutable GTOKEN721;
    IGTOKEN20Miner public GTOKEN20Miner;
    IRandom public random;

    uint256 private randOffset = block.number;
    uint256 public fightAnchor = block.timestamp;

    uint256 public constant claimCD = 1 days;
    uint256 public constant maxEnergy = 100;
    uint256 public constant energyCD = 4 hours;
    uint256 public constant dailyMaxEnergy = 6;

    //Set reward ratio for buying blind box
    uint256 public BUY_BOX_REWARD_RATE = 8;
    //Set reward ratio for PVE
    uint256 public PVE_REWARD_RATE = 5;

    address public feeAccount;

    mapping(uint256 => Token) public tokenInfo;
    mapping(address => AccountInfo) public accountInfo;
    mapping(uint256 => Mission) public missionInfo;
    mapping(uint256 => Level) public levelInfo;
    mapping(uint256 => Supply) public supplyInfo;

    event Bind(address indexed inviter, address indexed invitee);
    event Mint(
        address indexed account,
        uint256 fee,
        uint256 indexed tokenId,
        address indexed inviter
    );
    event Open(
        address indexed account,
        uint256 indexed level,
        uint256 indexed tokenId,
        uint256 rand
    );
    event Fight(
        address indexed account,
        bool indexed win,
        uint256 indexed reward,
        uint256 boss,
        uint256 tokenId,
        uint256 rand
    );
    event Recovery(
        address indexed account,
        uint256 increment,
        uint256 energy,
        uint256 tokenId
    );
    event Claim(
        address indexed account,
        uint256 indexed amount,
        address indexed inviter
    );

    event ReMint(address indexed account, uint256 fee, uint256 indexed tokenId);
    event ReOpen(
        address indexed account,
        uint256 indexed level,
        uint256 indexed tokenId
    );

    constructor(
        address GTOKEN20_,
        address GTOKEN721_,
        address GTOKEN20Miner_,
        address pendingOwner_,
        address feeAccount_
    ) Owner() {
        GTOKEN20 = IERC20(GTOKEN20_);
        GTOKEN721 = IGTOKEN721(GTOKEN721_);
        GTOKEN20Miner = IGTOKEN20Miner(GTOKEN20Miner_);
        feeAccount = feeAccount_;
        setPendingOwner(pendingOwner_);

        //set PVE level information
        setMissionInfo(1, 8000, 100e18, 0);
        setMissionInfo(2, 6000, 200e18, 20e18);
        setMissionInfo(3, 5000, 400e18, 40e18);
        setMissionInfo(4, 4000, 800e18, 80e18);
        setMissionInfo(5, 2000, 1600e18, 100e18);

        //set NFT level information
        setLevelInfo(
            1,
            100,
            100,
            1e18,
            79.9e18,
            [
                uint256(5000),
                uint256(3000),
                uint256(700),
                uint256(300),
                uint256(1000)
            ]
        );
        setLevelInfo(
            2,
            500,
            100,
            1e18,
            79.9e18,
            [
                uint256(0),
                uint256(6000),
                uint256(2000),
                uint256(500),
                uint256(1500)
            ]
        );
        setLevelInfo(
            3,
            800,
            150,
            1e18,
            79.9e18,
            [
                uint256(0),
                uint256(0),
                uint256(7000),
                uint256(1000),
                uint256(2000)
            ]
        );
        setLevelInfo(
            4,
            800,
            200,
            1e18,
            0,
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        );
        setLevelInfo(
            5,
            1200,
            500,
            1e18,
            0,
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        );
        setLevelInfo(
            6,
            2000,
            900,
            1e18,
            0,
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        );
    }

    function setFeeAccount(address _feeAccount)
        public
        onlyOwner
        returns (bool)
    {
        feeAccount = _feeAccount;
        return true;
    }

    function setParentByAdmin(address user, address parent) public onlyOwner {
        migrateAccountInfo(msg.sender);

        require(accountInfo[user].inviter == address(0), "already bind");
        accountInfo[user].inviter = parent;
        accountInfo[parent].invitee.push(user);
    }

    function bind(address inviter) external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);

        require(inviter != address(0), "not zero account");
        require(inviter != msg.sender, "can not be yourself");
        require(accountInfo[msg.sender].inviter == address(0), "already bind");
        accountInfo[msg.sender].inviter = inviter;
        accountInfo[inviter].invitee.push(msg.sender);
        emit Bind(inviter, msg.sender);
    }

    function multMint(uint256 nftAmount, uint256 supplyId)
        external
        payable
        checkContractCall
        checkPaused
    {
        migrateAccountInfo(msg.sender);

        require(nftAmount > 0, "multiple");
        require(supplyInfo[supplyId].fee != 0, "wrong supplyId");

        supplyInfo[supplyId].left -= nftAmount;
        uint256 fee = nftAmount * supplyInfo[supplyId].fee;
        IERC20 token = IERC20(supplyInfo[supplyId].token);
        address inviter = accountInfo[msg.sender].inviter;

        uint256 fee2;
        if (inviter != address(0)) {
            if (!accountInfo[msg.sender].isInvite) {
                accountInfo[msg.sender].isInvite = true;
            }

            fee2 = (fee * BUY_BOX_REWARD_RATE) / 100;
            if (address(token) == address(2)) {
                (bool success, ) = inviter.call{value: fee2}(new bytes(0));
                require(success, "TransferHelper: BNB_TRANSFER_FAILED");
                accountInfo[inviter].xdgeReward += fee2;
            } else {
                token.transferFrom(msg.sender, inviter, fee2);
                accountInfo[inviter].dgeReward += fee2;
            }
        }

        if (address(token) == address(2)) {
            (bool success, ) = feeAccount.call{value: fee - fee2}(new bytes(0));
            require(success, "TransferHelper: BNB_TRANSFER_FAILED");
        } else {
            token.transferFrom(msg.sender, feeAccount, fee - fee2);
        }

        for (uint256 index = 0; index < nftAmount; index++) {
            uint256 tokenId = GTOKEN721.mint(msg.sender);
            tokenInfo[tokenId].supplyId = supplyId;
            random.requestRandomness(tokenId, block.timestamp + index, false);
            emit Mint(msg.sender, supplyInfo[supplyId].fee, tokenId, inviter);

            open(tokenId);
        }
    }

    function open(uint256 tokenId) private {
        (bool usable, uint256 r) = random.openRand(tokenId);
        require(usable, "randomness not ready");

        uint256 supplyId = tokenInfo[tokenId].supplyId;

        for (uint256 i = 0; i < supplyInfo[supplyId].levelCode.length; i++) {
            if (r < supplyInfo[supplyId].levelOffset[i]) {
                tokenInfo[tokenId].levelCode = supplyInfo[supplyId].levelCode[
                    i
                ];
                break;
            }
        }
        tokenInfo[tokenId].energy = maxEnergy;
        emit Open(msg.sender, tokenInfo[tokenId].levelCode, tokenId, r);
    }

    function multiFight(
        uint256 tokenId,
        uint256 mission,
        uint256 times
    ) external checkContractCall checkPaused {
        require(GTOKEN721.ownerOf(tokenId) == msg.sender, "not yours");
        migrateTokenInfo(tokenId);
        migrateAccountInfo(msg.sender);

        (
            ,
            uint256 energy,
            uint256 todayUsed,
            uint256 levelCode,
            ,
            ,
            ,
            ,

        ) = getTokenInfo(tokenId);
        require(!tokenInfo[tokenId].isStake, "nft stake");
        (uint256 winRate, uint256 rewards) = getWRR(mission, levelCode);

        require(times + todayUsed <= dailyMaxEnergy, "fight too much");

        for (uint256 index = 0; index < times; index++) {
            if (energy == 0) {
                break;
            }
            if (todayUsed == dailyMaxEnergy) {
                break;
            }
            (bool usable, uint256 r) = random.fightRand(tokenId, todayUsed);
            require(usable, "randomness is not ready");
            if (winRate > r) {
                todayUsed += 1;
                accountInfo[msg.sender].reward += rewards;
                tokenInfo[tokenId].winCount += 1;
                emit Fight(msg.sender, true, rewards, mission, tokenId, r);
            } else {
                energy -= 1;
                todayUsed += 1;
                tokenInfo[tokenId].dgeeCount += 1;
                emit Fight(msg.sender, false, 0, mission, tokenId, r);
            }
        }
        tokenInfo[tokenId].fightAt = block.timestamp;
        tokenInfo[tokenId].energy = energy;
        tokenInfo[tokenId].todayUsed = todayUsed;
    }

    function recovery(uint256 tokenId, uint256 energy)
        external
        checkContractCall
        checkPaused
    {
        migrateTokenInfo(tokenId);
        migrateAccountInfo(msg.sender);

        require(GTOKEN721.ownerOf(tokenId) == msg.sender, "not yours");

        Token storage tokenIf = tokenInfo[tokenId];

        require(tokenIf.energy + energy <= maxEnergy, "over flaw");
        require(tokenIf.levelCode >= 100, "open first");
        uint256 level = tokenIf.levelCode / 100;
        uint256 fee = levelInfo[level].recoveryFee * energy;

        GTOKEN20.transferFrom(msg.sender, feeAccount, fee);
        tokenIf.energy += energy;

        emit Recovery(msg.sender, energy, tokenIf.energy, tokenId);
    }

    function claim() external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);

        address inviter = accountInfo[msg.sender].inviter;
        uint256 reward = accountInfo[msg.sender].reward;
        uint256 claimAt = accountInfo[msg.sender].claimAt;
        if (reward > 0) {
            require(
                claimAt == 0 || block.timestamp - claimAt >= claimCD,
                "not now"
            );

            uint256 inviterPart = 0;
            if (inviter != address(0)) {
                inviterPart += (reward * PVE_REWARD_RATE) / 100;
                GTOKEN20Miner.mint(inviter, (reward * PVE_REWARD_RATE) / 100);
                accountInfo[inviter].dgeReward +=
                    (reward * PVE_REWARD_RATE) /
                    100;
            }

            accountInfo[msg.sender].totalClaim += reward - inviterPart;
            GTOKEN20Miner.mint(msg.sender, reward - inviterPart);

            accountInfo[msg.sender].claimAt = block.timestamp;
            accountInfo[msg.sender].reward = 0;
        }
        emit Claim(msg.sender, reward, inviter);
    }

    function reMint(uint256 tokenId) external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);
        migrateTokenInfo(tokenId);

        require(GTOKEN721.ownerOf(tokenId) == msg.sender, "not yours");

        (, uint256 energy, uint256 levelCode) = _getTokenInfo(tokenId);
        require(energy == maxEnergy, "rest awhile");
        require(levelCode >= 100, "open first");

        uint256 level = levelCode / 100;
        uint256 reMintFee = levelInfo[level].reMintFee;
        require(reMintFee > 0, "not allowed to reMint");

        GTOKEN20.transferFrom(msg.sender, feeAccount, reMintFee);
        tokenInfo[tokenId].levelCode = level;

        random.requestRandomness(tokenId, block.timestamp, false);
        levelInfo[level].reMintCount += 1;

        emit ReMint(msg.sender, reMintFee, tokenId);
    }

    function reOpen(uint256 tokenId) external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);
        migrateTokenInfo(tokenId);

        uint256 levelCode = tokenInfo[tokenId].levelCode;

        require(GTOKEN721.ownerOf(tokenId) == msg.sender, "not yours");
        require(levelCode > 0 && levelCode < 7, "wrong method");

        (bool usable, uint256 r) = random.openRand(tokenId);
        require(usable, "randomness is not ready");

        for (uint256 i = 0; i < 5; i++) {
            if (r < levelInfo[levelCode].reMintOffset[i]) {
                if (i == 4) {
                    random.requestRandomness(
                        tokenId,
                        block.timestamp + i,
                        false
                    );
                    levelCode = 10;
                    tokenInfo[tokenId].supplyId = 2;
                } else {
                    if (tokenInfo[tokenId].supplyId == 1) {
                        levelCode = (i + 1) * 100;
                    } else {
                        levelCode = (i + 1) * 100 + 10;
                    }
                }
                break;
            }
        }
        tokenInfo[tokenId].levelCode = levelCode;
        emit ReOpen(msg.sender, levelCode, tokenId);
    }

    function setRandom(address r) public onlyOwner {
        random = IRandom(r);
    }

    function setSupplyInfo(
        uint256 id,
        uint256 total,
        uint256 fee,
        address token,
        uint256[] memory levelCode,
        uint256[] memory openRate
    ) public onlyOwner {
        require(levelCode.length == openRate.length, "rewrite it");
        supplyInfo[id].fee = fee;
        supplyInfo[id].total = total;
        supplyInfo[id].left = total;
        supplyInfo[id].token = token;
        supplyInfo[id].levelCode = levelCode;

        uint256 su;
        uint256[] memory offset = new uint256[](levelCode.length);
        for (uint256 i = 0; i < levelCode.length; i++) {
            su += openRate[i];
            offset[i] = su;
        }
        require(su == 10000, "denominator is 10000");
        supplyInfo[id].levelOffset = offset;
    }

    function setLevelInfo(
        uint256 level,
        uint256 winRateAdd,
        uint256 rewardAdd,
        uint256 recoveryFee,
        uint256 reMintFee,
        uint256[5] memory rate
    ) public onlyOwner {
        levelInfo[level].winRateAdd = winRateAdd;
        levelInfo[level].rewardAdd = rewardAdd;
        levelInfo[level].recoveryFee = recoveryFee;

        if (reMintFee != 0) {
            levelInfo[level].reMintFee = reMintFee;
            uint256 su;
            uint256[5] storage offset = levelInfo[level].reMintOffset;
            for (uint256 i = 0; i < 5; i++) {
                su += rate[i];
                offset[i] = su;
            }
            require(su == 10000, "denominator is 10000");
        }
    }

    function setMissionInfo(
        uint256 mission,
        uint256 winRate,
        uint256 reward,
        uint256 fee
    ) public onlyOwner {
        missionInfo[mission].winRate = winRate;
        missionInfo[mission].reward = reward;
        missionInfo[mission].fee = fee;
    }

    function setComptroller(address c) external onlyOwner {
        GTOKEN20Miner = IGTOKEN20Miner(c);
    }

    function setBuyBoxRewardRate(uint256 rate) public onlyOwner {
        BUY_BOX_REWARD_RATE = rate;
    }

    function setPVERewardRate(uint256 rate) public onlyOwner {
        PVE_REWARD_RATE = rate;
    }

    /********                       ********
     ***********   read only     ***********
     ********                       ********/
    function openAble(uint256 tokenId) external view returns (bool) {
        return random.usable(tokenId);
    }

    function _getTokenInfo(uint256 tokenId)
        private
        view
        returns (
            uint256 fightAt,
            uint256 energy,
            uint256 levelCode
        )
    {
        Token memory token = tokenInfo[tokenId];
        if (token.energy != maxEnergy) {
            uint256 r = (block.timestamp - token.fightAt) / energyCD;
            if (token.energy + r < maxEnergy) {
                fightAt = token.fightAt + (r * energyCD);
                energy = token.energy + r;
                return (fightAt, energy, token.levelCode);
            }
        }
        return (block.timestamp, maxEnergy, token.levelCode);
    }

    function getTokenInfo(uint256 tokenId)
        public
        view
        returns (
            uint256 fightAt,
            uint256 energy,
            uint256 todayUsed,
            uint256 levelCode,
            uint256 winCount,
            uint256 dgeeCount,
            uint256 supplyId,
            bool isStake,
            bool isSell
        )
    {
        Token memory token = tokenInfo[tokenId];
        if (
            tokenInfo[tokenId].levelCode == 0 &&
            tokenInfo[tokenId].supplyId == 0
        ) {
            (fightAt, , levelCode) = _getTokenInfo(tokenId);
            energy = maxEnergy;
            todayUsed = 0;
            supplyId = 1;
            isStake = false;
            isSell = false;
        } else {
            if (token.fightAt < getLatestAnchor()) {
                todayUsed = 0;
            } else {
                todayUsed = token.todayUsed;
            }
            fightAt = token.fightAt;
            energy = token.energy;
            levelCode = token.levelCode;
            winCount = token.winCount;
            dgeeCount = token.dgeeCount;
            supplyId = token.supplyId;
            isStake = token.isStake;
            isSell = token.isSell;
        }
    }

    function getWRR(uint256 mission, uint256 levelCode)
        public
        view
        returns (uint256 winRate, uint256 reward)
    {
        Level memory l = levelInfo[levelCode / 100];
        winRate = missionInfo[mission].winRate + l.winRateAdd;
        if (winRate > 10000) {
            winRate = 10000;
        }
        reward = (missionInfo[mission].reward * l.rewardAdd) / 100;
        return (winRate, reward);
    }

    function getSupplyInfo(uint256 id)
        external
        view
        returns (
            uint256 fee,
            uint256 total,
            uint256 left,
            address token,
            uint256[] memory levelCode,
            uint256[] memory levelOffset
        )
    {
        Supply memory info = supplyInfo[id];
        return (
            info.fee,
            info.total,
            info.left,
            info.token,
            info.levelCode,
            info.levelOffset
        );
    }

    function getLevelInfo(uint256 level)
        external
        view
        returns (
            uint256 winRateAdd,
            uint256 rewardAdd,
            uint256 recoveryFee,
            uint256 reMintFee,
            uint256 reMintCount,
            uint256[5] memory reMintOffset
        )
    {
        Level memory info = levelInfo[level];
        return (
            info.winRateAdd,
            info.rewardAdd,
            info.recoveryFee,
            info.reMintFee,
            info.reMintCount,
            info.reMintOffset
        );
    }

    function _getAccountInfo(address account)
        private
        view
        returns (uint256 reward, uint256 claimAt)
    {
        return (accountInfo[account].reward, accountInfo[account].claimAt);
    }

    function getAccountInfo(address account)
        external
        view
        returns (
            uint256 reward,
            uint256 claimAt,
            address inviter,
            address[] memory invitees
        )
    {
        AccountInfo memory info = accountInfo[account];
        if (accountInfo[account].totalClaim == 0) {
            (reward, claimAt) = _getAccountInfo(account);
            invitees = accountInfo[account].invitee;
            return (reward, claimAt, info.inviter, info.invitee);
        } else {
            return (info.reward, info.claimAt, info.inviter, info.invitee);
        }
    }

    function setTokenIsStake(uint256 tokenId, bool isStake) external {
        migrateAccountInfo(msg.sender);
        migrateTokenInfo(tokenId);

        require(GTOKEN721.ownerOf(tokenId) == msg.sender, "not yours");

        tokenInfo[tokenId].isStake = isStake;
    }

    function getTokenIsStake(uint256 tokenId) external view returns (bool) {
        return tokenInfo[tokenId].isStake;
    }

    function setUserReward(uint256 reward) external {
        migrateAccountInfo(msg.sender);
        accountInfo[msg.sender].dgeReward = reward;
    }

    function setTokenIsSell(uint256 tokenId, bool isSell) external {
        migrateAccountInfo(msg.sender);
        migrateTokenInfo(tokenId);

        require(GTOKEN721.ownerOf(tokenId) == msg.sender, "not yours");

        tokenInfo[tokenId].isSell = isSell;
    }

    function getTokenIsSell(uint256 tokenId) external view returns (bool) {
        return tokenInfo[tokenId].isSell;
    }

    function getInvitation(address account)
        external
        view
        returns (
            address inviter,
            uint256 dgeReward,
            uint256 xdgeReward,
            bool isInvite,
            address[] memory invitees
        )
    {
        AccountInfo memory info = accountInfo[account];
        return (
            info.inviter,
            info.dgeReward,
            info.xdgeReward,
            info.isInvite,
            info.invitee
        );
    }

    function setFightAnchor(uint256 _fightAnchor)
        public
        onlyOwner
        returns (bool)
    {
        fightAnchor = _fightAnchor;
        return true;
    }

    function getLatestAnchor() public view returns (uint256) {
        if (block.timestamp - fightAnchor > 1 days) {
            uint256 offset = (block.timestamp - fightAnchor) / 1 days;
            return (offset * 1 days) + fightAnchor;
        } else {
            return fightAnchor;
        }
    }

    function migrateTokenInfo(uint256 tokenId) internal {
        if (
            tokenInfo[tokenId].levelCode == 0 &&
            tokenInfo[tokenId].supplyId == 0
        ) {
            (uint256 fightAt, , uint256 levelCode) = _getTokenInfo(tokenId);
            tokenInfo[tokenId].fightAt = fightAt;
            tokenInfo[tokenId].energy = maxEnergy;
            tokenInfo[tokenId].levelCode = levelCode;
            tokenInfo[tokenId].supplyId = 1;
        }
    }

    function migrateAccountInfo(address account) internal {
        if (accountInfo[account].totalClaim == 0) {
            (uint256 reward, uint256 claimAt) = _getAccountInfo(account);
            accountInfo[account].reward = reward;
            accountInfo[account].claimAt = claimAt;
            accountInfo[account].totalClaim = 1;
        }
    }
}