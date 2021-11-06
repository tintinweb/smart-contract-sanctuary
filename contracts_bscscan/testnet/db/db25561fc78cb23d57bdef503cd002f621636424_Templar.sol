/**
 *Submitted for verification at BscScan.com on 2021-11-06
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
    function requestRandomness(uint256 tokenId) external;

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

interface IDGE20Miner {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

interface IDGE721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address recipient_) external returns (uint256);

    function getTokens(address owner) external view returns (uint256[] memory);
}

contract Templar is Owner {
    struct Token {
        uint256 fightAt; // last fight time
        uint256 todayUsed;
        uint256 energy; // stamina left
        uint256 levelCode; // 100、200、300、400、500...、600
        uint256 supplyId;
        uint256 winCount;
        uint256 dgeeCount;
    }
    struct AccountInfo {
        uint256 reward;
        uint256 claimAt;
        uint256 totalClaim;
        uint256 dgeReward;
        uint256 xdgeReward;
        uint256 mintCount;
        uint256 inviteCount;
        bool isInvite;
        address inviter;
        address[] invitee;
    }
    struct Mission {
        uint256 winRate;
        uint256 reward;
    }
    struct Level {
        uint256 winRateAdd; // %
        uint256 rewardAdd; // %
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

    IERC20 public immutable DGE20;
    IDGE721 public immutable DGE721;
    IDGE20Miner public DGE20Miner;
    IRandom public random;

    uint256 private randOffset = block.number;
    uint256 public fightAnchor = block.timestamp;

    uint256 public constant claimCD = 1 days;
    uint256 public constant maxEnergy = 120;
    uint256 public constant energyCD = 2 hours;
    uint256 public constant dailyMaxEnergy = 12;

    uint256 public lotteryAmount = 100e18;
    uint256[] public lotteryReward = [70e18, 100e18, 200e18, 500e18, 1000e18];

    mapping(uint256 => Token) public tokenInfo;
    mapping(address => AccountInfo) public accountInfo;
    mapping(uint256 => Mission) public missionInfo;
    mapping(uint256 => Level) public levelInfo;
    mapping(uint256 => Supply) public supplyInfo;

    address public feeAccount;

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
    event OpenLottery(address indexed account, uint256 reward, uint256 rand);

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
        address DGE20_,
        address DGE721_,
        address DGE20Miner_,
        address pendingOwner_,
        address feeAccount_
    ) Owner() {
        DGE20 = IERC20(DGE20_);
        DGE721 = IDGE721(DGE721_);
        DGE20Miner = IDGE20Miner(DGE20Miner_);
        feeAccount = feeAccount_;
        setPendingOwner(pendingOwner_);

        setMissionInfo(1, 8000, 50e18);
        setMissionInfo(2, 6000, 150e18);
        setMissionInfo(3, 4000, 300e18);
        setMissionInfo(4, 2000, 500e18);
        setMissionInfo(5, 800, 2000e18);

        //
        setLevelInfo(
            1,
            0,
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
            0,
            120,
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
            0,
            160,
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
            0,
            300,
            1e18,
            0,
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        );
        setLevelInfo(
            5,
            500,
            1000,
            1e18,
            0,
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        );
        setLevelInfo(
            6,
            500,
            2000,
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

        require(accountInfo[inviter].mintCount >= 5, "no invite anthority");

        require(inviter != address(0), "not zero account");
        require(inviter != msg.sender, "can not be yourself");
        require(accountInfo[msg.sender].inviter == address(0), "already bind");
        accountInfo[msg.sender].inviter = inviter;
        accountInfo[inviter].invitee.push(msg.sender);
        emit Bind(inviter, msg.sender);
    }

    function _multMint(
        IERC20 _token,
        address _addr,
        uint256 _amount
    ) private {
        _token.transferFrom(msg.sender, _addr, _amount);
        if (address(DGE20) == address(_token)) {
            accountInfo[_addr].dgeReward += _amount;
        } else {
            accountInfo[_addr].xdgeReward += _amount;
        }
    }

    function multiMint(uint256 nftAmount, uint256 supplyId)
        external
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

        accountInfo[msg.sender].mintCount += nftAmount;

        uint256 inviterPart;
        if (inviter != address(0)) {
            if (!accountInfo[msg.sender].isInvite) {
                accountInfo[msg.sender].isInvite = true;
                accountInfo[inviter].inviteCount++;
            }

            inviterPart += (fee * 8) / 100;

            _multMint(token, inviter, (fee * 8) / 100);

            if (
                accountInfo[inviter].inviter != address(0) &&
                accountInfo[accountInfo[inviter].inviter].inviteCount >= 10
            ) {
                inviterPart += (fee * 2) / 100;

                _multMint(token, accountInfo[inviter].inviter, (fee * 2) / 100);
            }
        }

        token.transferFrom(msg.sender, feeAccount, fee - inviterPart);

        for (uint256 index = 0; index < nftAmount; index++) {
            uint256 tokenId = DGE721.mint(msg.sender);
            tokenInfo[tokenId].supplyId = supplyId;
            random.requestRandomness(tokenId);
            emit Mint(msg.sender, supplyInfo[supplyId].fee, tokenId, inviter);
        }
    }

    function _rand(uint256 _length) private view returns (uint256) {
        uint256 _random = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        return _random % _length;
    }

    function setLotteryAmount(uint256 _amount) public onlyOwner returns (bool) {
        lotteryAmount = _amount;
        return true;
    }

    function setLotteryReward(uint256 _pid, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        lotteryReward[_pid] = _amount;
        return true;
    }

    function addLotteryReward(uint256 _amount) public onlyOwner returns (bool) {
        lotteryReward.push(_amount);
        return true;
    }

    function openLottery(uint256 nftAmount)
        external
        checkContractCall
        checkPaused
    {
        migrateAccountInfo(msg.sender);

        uint256 fee = nftAmount * lotteryAmount;
        require(DGE20.balanceOf(msg.sender) >= fee, "less DGE20");

        address inviter = accountInfo[msg.sender].inviter;

        accountInfo[msg.sender].mintCount += nftAmount;

        uint256 inviterPart;
        if (inviter != address(0)) {
            if (!accountInfo[msg.sender].isInvite) {
                accountInfo[msg.sender].isInvite = true;
                accountInfo[inviter].inviteCount++;
            }

            inviterPart += (fee * 8) / 100;

            DGE20.transferFrom(msg.sender, inviter, (fee * 8) / 100);
            accountInfo[inviter].dgeReward += (fee * 8) / 100;

            if (
                accountInfo[inviter].inviter != address(0) &&
                accountInfo[accountInfo[inviter].inviter].inviteCount >= 10
            ) {
                inviterPart += (fee * 2) / 100;

                DGE20.transferFrom(msg.sender, inviter, (fee * 2) / 100);
                accountInfo[inviter].dgeReward += (fee * 2) / 100;
            }
        }

        DGE20.transferFrom(msg.sender, feeAccount, fee - inviterPart);

        for(uint i=0; i<nftAmount; i++) {
            uint256 reward = lotteryReward[_rand(lotteryReward.length)];
            DGE20Miner.mint(msg.sender, reward);
            accountInfo[msg.sender].totalClaim += reward;
            emit OpenLottery(msg.sender, reward, _rand(lotteryReward.length));
        }
        
    }

    function open(uint256 tokenId) external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);
        migrateTokenInfo(tokenId);
        //
        require(DGE721.ownerOf(tokenId) == msg.sender, "not yours");
        require(
            tokenInfo[tokenId].levelCode == 0 ||
                tokenInfo[tokenId].levelCode == 10,
            "never retry"
        );

        //
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
        require(DGE721.ownerOf(tokenId) == msg.sender, "not yours");
        migrateTokenInfo(tokenId);
        migrateAccountInfo(msg.sender);

        (
            ,
            uint256 energy,
            uint256 todayUsed,
            uint256 levelCode,
            ,
            ,

        ) = getTokenInfo(tokenId);
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

        require(DGE721.ownerOf(tokenId) == msg.sender, "not yours");

        Token storage tokenIf = tokenInfo[tokenId];

        require(tokenIf.energy + energy <= maxEnergy, "over flaw");
        require(tokenIf.levelCode >= 100, "open first");
        uint256 level = tokenIf.levelCode / 100;
        uint256 fee = levelInfo[level].recoveryFee * energy;

        DGE20.transferFrom(msg.sender, feeAccount, fee);
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
                inviterPart += (reward * 8) / 100;
                DGE20Miner.mint(inviter, (reward * 8) / 100);
                accountInfo[inviter].dgeReward += (reward * 8) / 100;

                if (
                    accountInfo[inviter].inviter != address(0) &&
                    accountInfo[accountInfo[inviter].inviter].inviteCount >= 10
                ) {
                    inviterPart += (reward * 2) / 100;
                    DGE20Miner.mint(
                        accountInfo[inviter].inviter,
                        (reward * 2) / 100
                    );
                    accountInfo[accountInfo[inviter].inviter].dgeReward +=
                        (reward * 2) /
                        100;
                }
            }

            accountInfo[msg.sender].totalClaim += reward - inviterPart;
            DGE20Miner.mint(msg.sender, reward - inviterPart);

            accountInfo[msg.sender].claimAt = block.timestamp;
            accountInfo[msg.sender].reward = 0;
        }
        emit Claim(msg.sender, reward, inviter);
    }

    function reMint(uint256 tokenId) external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);
        migrateTokenInfo(tokenId);

        require(DGE721.ownerOf(tokenId) == msg.sender, "not yours");

        (, uint256 energy, uint256 levelCode) = _getTokenInfo(tokenId);
        require(energy == maxEnergy, "rest awhile");
        require(levelCode >= 100, "open first");

        uint256 level = levelCode / 100;
        uint256 reMintFee = levelInfo[level].reMintFee;
        require(reMintFee > 0, "not allowed to reMint");

        DGE20.transferFrom(msg.sender, feeAccount, reMintFee);
        tokenInfo[tokenId].levelCode = level;

        random.requestRandomness(tokenId);
        levelInfo[level].reMintCount += 1;

        emit ReMint(msg.sender, reMintFee, tokenId);
    }

    function reOpen(uint256 tokenId) external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);
        migrateTokenInfo(tokenId);

        uint256 levelCode = tokenInfo[tokenId].levelCode;

        require(DGE721.ownerOf(tokenId) == msg.sender, "not yours");
        require(levelCode > 0 && levelCode < 7, "wrong method");

        (bool usable, uint256 r) = random.openRand(tokenId);
        require(usable, "randomness is not ready");

        for (uint256 i = 0; i < 5; i++) {
            if (r < levelInfo[levelCode].reMintOffset[i]) {
                if (i == 4) {
                    random.requestRandomness(tokenId);
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

    /********                       ********
     ***********   only owner    ***********
     ********                       ********/

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
    ) external onlyOwner {
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
        uint256 reward
    ) public onlyOwner {
        missionInfo[mission].winRate = winRate;
        missionInfo[mission].reward = reward;
    }

    function setComptroller(address c) external onlyOwner {
        DGE20Miner = IDGE20Miner(c);
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
            uint256 supplyId
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

    function getInvitation(address account)
        external
        view
        returns (
            address inviter,
            uint256 dgeReward,
            uint256 xdgeReward,
            address[] memory invitees
        )
    {
        AccountInfo memory info = accountInfo[account];
        return (info.inviter, info.dgeReward, info.xdgeReward, info.invitee);
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