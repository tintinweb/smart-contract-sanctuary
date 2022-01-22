/**
 *Submitted for verification at BscScan.com on 2022-01-21
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

// File: contracts/Stake.sol

pragma solidity ^0.8.0;

interface IGTOKEN20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address recipient, uint256 amount) external returns (bool);
}

interface IGTOKEN721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getTokens(address owner) external view returns (uint256[] memory);

    function transfer(address to, uint256 tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IGTOKEN20Miner {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

interface ITemplar {
    function getInvitation(address account)
        external
        view
        returns (
            address inviter,
            uint256 gtokenReward,
            uint256 xgtokenReward,
            bool isInvite,
            address[] memory invitees
        );

    function setUserReward(address user, uint256 reward) external;

    function setTokenIsStake(uint256 tokenId, bool isStake) external;

    function getTokenIsStake(uint256 tokenId) external view returns (bool);

    function getTokenIsSell(uint256 tokenId) external view returns (bool);

    function getTokenInfo(uint256 tokenId)
        external
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
        );
}

contract StakeERC721 is Owner {
    IGTOKEN20 public GTOKEN20;
    IGTOKEN721 public GTOKEN721;
    IGTOKEN20Miner public GTOKEN20Miner;
    ITemplar public TEMPLAR;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public feeAccount;
    address public pancakeswapPair;
    address public deadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256 public lpfee = 2;
    uint256 public deadfee = 4;
    uint256 public inviteefee = 3;
    uint256 public fee = 1;

    //Mapping of mouse to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    //Mapping of mouse to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    //Mapping of staker to mice
    mapping(address => uint256[]) internal stakerToTokenIds;

    mapping(uint256 => uint256) internal stakeTokenAmount;

    mapping(uint256 => uint256) internal levelEmissionsRate;

    event Stake(address indexed account, uint256 tokenId);
    event Unstake(address indexed account, uint256 tokenId);

    function setTemplar(address templar_) public onlyOwner {
        TEMPLAR = ITemplar(templar_);
    }

    function setComptroller(address c) external onlyOwner {
        GTOKEN20Miner = IGTOKEN20Miner(c);
    }

    function setLevelEmissionsRate(uint256 level, uint256 EMISSIONS_RATE_)
        public
        onlyOwner
    {
        levelEmissionsRate[level] = EMISSIONS_RATE_;
    }

    function setFeeAccount(address _account) external onlyOwner {
        feeAccount = _account;
    }

    function changeSwapAddress(address _addr) public onlyOwner {
        pancakeswapPair = _addr;
    }

    function changeLpFee(uint256 _lpfee) public onlyOwner {
        lpfee = _lpfee;
    }

    function changeDeadFee(uint256 _deadfee) public onlyOwner {
        deadfee = _deadfee;
    }

    function changeInviteeFee(uint256 _fee) public onlyOwner {
        inviteefee = _fee;
    }

    function changeFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    constructor(
        address GTOKEN20_,
        address GTOKEN721_,
        address GTOKEN20Miner_,
        address TEMPLAR_,
        address feeAccount_
    ) Owner() {
        GTOKEN20 = IGTOKEN20(GTOKEN20_);
        GTOKEN721 = IGTOKEN721(GTOKEN721_);
        GTOKEN20Miner = IGTOKEN20Miner(GTOKEN20Miner_);
        TEMPLAR = ITemplar(TEMPLAR_);
        feeAccount = feeAccount_;

        setStakeTokenAmount(1, 200e18);
        setStakeTokenAmount(2, 300e18);
        setStakeTokenAmount(3, 400e18);
        setStakeTokenAmount(4, 500e18);
        setStakeTokenAmount(5, 600e18);
        setStakeTokenAmount(6, 700e18);

        setLevelEmissionsRate(1, 1e16);
        setLevelEmissionsRate(2, 2e16);
        setLevelEmissionsRate(3, 3e16);
        setLevelEmissionsRate(4, 4e16);
        setLevelEmissionsRate(5, 5e16);
        setLevelEmissionsRate(6, 6e16);
    }

    function setStakeTokenAmount(uint256 id, uint256 amount) public onlyOwner {
        stakeTokenAmount[id] = amount;
    }

    function getStakeTokenAmount(uint256 id) public view returns (uint256) {
        return stakeTokenAmount[id];
    }

    function getTokensStaked(address staker, uint256 levelcode)
        public
        view
        returns (uint256[] memory)
    {
        if (levelcode == 0) {
            return stakerToTokenIds[staker];
        }

        uint256[] memory a = new uint256[](stakerToTokenIds[staker].length);

        uint256 c = 0;
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(
                stakerToTokenIds[staker][i]
            );
            if (levelcode == levelCode) {
                a[c] = stakerToTokenIds[staker][i];
                c++;
            }
        }
        return a;
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                GTOKEN721.ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            require(
                !TEMPLAR.getTokenIsStake(tokenIds[i]),
                "Token must be unstake"
            );

            require(
                !TEMPLAR.getTokenIsSell(tokenIds[i]),
                "Token must be unselling"
            );

            GTOKEN721.transferFrom(msg.sender, address(this), tokenIds[i]);

            (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(
                tokenIds[i]
            );
            GTOKEN20.transferFrom(
                msg.sender,
                address(this),
                stakeTokenAmount[levelCode / 100]
            );

            TEMPLAR.setTokenIsStake(tokenIds[i], true);

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;

            emit Stake(msg.sender, tokenIds[i]);
        }
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one token staked!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            TEMPLAR.setTokenIsStake(tokenId, false);

            GTOKEN721.transfer(msg.sender, tokenId);

            (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(tokenId);

            if (
                GTOKEN20.balanceOf(address(this)) >=
                stakeTokenAmount[levelCode / 100]
            ) {
                GTOKEN20.transfer(
                    msg.sender,
                    stakeTokenAmount[levelCode / 100]
                );
            } else {
                GTOKEN20.transfer(
                    msg.sender,
                    GTOKEN20.balanceOf(address(this))
                );
            }

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    levelEmissionsRate[levelCode / 100]);

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;

            emit Unstake(msg.sender, tokenId);
        }

        GTOKEN20Miner.mint(deadAddress, (totalRewards * deadfee) / 100);
        GTOKEN20Miner.mint(pancakeswapPair, (totalRewards * lpfee) / 100);
        GTOKEN20Miner.mint(feeAccount, (totalRewards * fee) / 100);
        (address inviter, , , , ) = TEMPLAR
            .getInvitation(msg.sender);
        if (inviter != address(0)) {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(inviter, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) /
                    100
            );
            TEMPLAR.setUserReward(inviter, f);
        } else {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(feeAccount, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) / 100
            );
        }

        // GTOKEN20Miner.mint(msg.sender, totalRewards);
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            TEMPLAR.setTokenIsStake(tokenIds[i], false);

            GTOKEN721.transfer(msg.sender, tokenIds[i]);

            (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(
                tokenIds[i]
            );

            if (
                GTOKEN20.balanceOf(address(this)) >=
                stakeTokenAmount[levelCode / 100]
            ) {
                GTOKEN20.transfer(
                    msg.sender,
                    stakeTokenAmount[levelCode / 100]
                );
            } else {
                GTOKEN20.transfer(
                    msg.sender,
                    GTOKEN20.balanceOf(address(this))
                );
            }

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    levelEmissionsRate[levelCode / 100]);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;

            emit Unstake(msg.sender, tokenIds[i]);
        }

        GTOKEN20Miner.mint(deadAddress, (totalRewards * deadfee) / 100);
        GTOKEN20Miner.mint(pancakeswapPair, (totalRewards * lpfee) / 100);
        GTOKEN20Miner.mint(feeAccount, (totalRewards * fee) / 100);
        (address inviter, , , , ) = TEMPLAR
            .getInvitation(msg.sender);
        if (inviter != address(0)) {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(inviter, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) /
                    100
            );

            TEMPLAR.setUserReward(inviter, f);
        } else {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(feeAccount, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) / 100
            );
        }

        // GTOKEN20Miner.mint(msg.sender, totalRewards);
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );

        (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(tokenId);

        uint256 totalRewards = ((block.timestamp -
            tokenIdToTimeStamp[tokenId]) * levelEmissionsRate[levelCode / 100]);

        tokenIdToTimeStamp[tokenId] = block.timestamp;

        GTOKEN20Miner.mint(deadAddress, (totalRewards * deadfee) / 100);
        GTOKEN20Miner.mint(pancakeswapPair, (totalRewards * lpfee) / 100);
        GTOKEN20Miner.mint(feeAccount, (totalRewards * fee) / 100);
        (address inviter, , , , ) = TEMPLAR
            .getInvitation(msg.sender);
        if (inviter != address(0)) {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(inviter, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) /
                    100
            );

            TEMPLAR.setUserReward(inviter, f);
        } else {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(feeAccount, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) / 100
            );
        }
    }

    function claimAll() public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    levelEmissionsRate[levelCode / 100]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        GTOKEN20Miner.mint(deadAddress, (totalRewards * deadfee) / 100);
        GTOKEN20Miner.mint(pancakeswapPair, (totalRewards * lpfee) / 100);
        GTOKEN20Miner.mint(feeAccount, (totalRewards * fee) / 100);
        (address inviter, , , , ) = TEMPLAR
            .getInvitation(msg.sender);
        if (inviter != address(0)) {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(inviter, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) /
                    100
            );

            TEMPLAR.setUserReward(inviter, f);
        } else {
            uint256 f = (totalRewards * inviteefee) / 100;
            GTOKEN20Miner.mint(feeAccount, f);
            GTOKEN20Miner.mint(
                msg.sender,
                (totalRewards * (100 - deadfee - lpfee - inviteefee - fee)) / 100
            );
        }

        // GTOKEN20Miner.mint(msg.sender, totalRewards);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    levelEmissionsRate[levelCode / 100]);
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != nullAddress,
            "Token is not staked!"
        );

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        (, , , uint256 levelCode, , , , , ) = TEMPLAR.getTokenInfo(tokenId);

        return secondsStaked * levelEmissionsRate[levelCode / 100];
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }
}