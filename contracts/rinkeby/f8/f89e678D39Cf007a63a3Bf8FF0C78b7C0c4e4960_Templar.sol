/**
 *Submitted for verification at Etherscan.io on 2022-01-27
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IWuFU721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address recipient_, string memory tokenURI)
        external
        returns (uint256);

    function getTokens(address owner) external view returns (uint256[] memory);

    function getNextTokenId() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Templar is Owner {
    struct Token {
        uint256 levelCode;
    }

    struct RewardPool {
        uint256 reward;
        uint256 feeReward;
    }

    struct Supply {
        uint256 fee;
        uint256 feerate;
        address token;
        uint256 total;
        uint256 left;
        uint256[] levelCode;
        uint256[] levelOffset;
    }

    IWuFU721 public immutable WuFu721;

    uint256 public RANDSEED = 10000;
    uint256 public RewardTime;

    uint256 private SuperLuckyAmount;
    uint256 private HasSuperLuckyAmount;
    uint256 private AllRewardPool;

    address public Setter;

    address public FeeAccount;
    address private DeadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    mapping(IERC20 => RewardPool) public rewardPoolInfo;
    mapping(uint256 => Token) public tokenInfo;
    mapping(uint256 => Supply) public supplyInfo;

    event Mint(
        address indexed account,
        uint256 fee,
        uint256 indexed tokenId,
        uint256 indexed levelCode
    );

    constructor(address WuFu721_, address FeeAccount_, uint256 timeStamp_) Owner() {
        WuFu721 = IWuFU721(WuFu721_);
        FeeAccount = FeeAccount_;
        RewardTime = timeStamp_;
    }

    function setRewardTime(uint256 rewardTime) public onlyOwner {
        RewardTime = rewardTime;
    }

    function setSuperLuckyAmount() external {
        require(msg.sender == Setter, "not setter");
        SuperLuckyAmount += 1;
    } 

    function getSuperLuckyAmount() public view returns (uint256) {
        return SuperLuckyAmount;
    }

    function getHasSuperLuckyAmount() public view returns (uint256) {
        return HasSuperLuckyAmount;
    }

    function getAllRewardPool() public view returns (uint256) {
        return AllRewardPool;
    }

    function setSetter(address set) public onlyOwner {
        Setter = set;
    }


    function setTokenLevelCode(uint256 tokenId, uint256 levelCode) external {
        require(msg.sender == Setter, "not setter");
        tokenInfo[tokenId].levelCode = levelCode;
    }


    function multMint(
        uint256 nftAmount,
        uint256 supplyId,
        string[] memory tokenUrls
    ) external payable checkContractCall checkPaused {
        require(block.timestamp <= RewardTime, "have end");
        require(nftAmount > 0, "multiple");
        require(supplyInfo[supplyId].fee != 0, "wrong supplyId");

        supplyInfo[supplyId].left -= nftAmount;
        uint256 fee = nftAmount * supplyInfo[supplyId].fee;
        IERC20 token = IERC20(supplyInfo[supplyId].token);

        uint256 fee2 = (fee * supplyInfo[supplyId].feerate) / 100;
        if (address(token) == address(2)) {
            (bool success, ) = FeeAccount.call{value: fee2}(new bytes(0));
            require(success, "TransferHelper: ETH_TRANSFER_FAILED");
        } else {
            token.transferFrom(msg.sender, FeeAccount, fee2);
        }

        AllRewardPool += fee - fee2;
        rewardPoolInfo[token].reward += fee - fee2;
        rewardPoolInfo[token].feeReward += fee2;
        

        for (uint256 index = 0; index < nftAmount; index++) {
            uint256 tokenId = WuFu721.getNextTokenId();
            uint256 r = rand(index);

            for (
                uint256 i = 0;
                i < supplyInfo[supplyId].levelCode.length;
                i++
            ) {
                if (r < supplyInfo[supplyId].levelOffset[i]) {
                    tokenInfo[tokenId].levelCode = supplyInfo[supplyId]
                        .levelCode[i];
                    break;
                }
            }

            if (tokenInfo[tokenId].levelCode == 600) {
                SuperLuckyAmount++;
            }

            WuFu721.mint(
                msg.sender,
                tokenUrls[tokenInfo[tokenId].levelCode / 100 - 1]
            );
            emit Mint(msg.sender, supplyInfo[supplyId].fee, tokenId, tokenInfo[tokenId].levelCode);
        }
    }

    function setFeeAccount(address _feeAccount)
        public
        onlyOwner
        returns (bool)
    {
        FeeAccount = _feeAccount;
        return true;
    }

    function setSupplyInfo(
        uint256 id,
        uint256 total,
        uint256 fee,
        uint256 feeRate,
        address token,
        uint256[] memory levelCode,
        uint256[] memory openRate
    ) public onlyOwner {
        require(levelCode.length == openRate.length, "rewrite it");
        supplyInfo[id].fee = fee;
        supplyInfo[id].feerate = feeRate;
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
        require(su == RANDSEED, "denominator is error");
        supplyInfo[id].levelOffset = offset;
    }

    function getSupplyInfo(uint256 id)
        external
        view
        returns (
            uint256 fee,
            uint256 feeRate,
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
            info.feerate,
            info.total,
            info.left,
            info.token,
            info.levelCode,
            info.levelOffset
        );
    }

    function rand(uint256 i) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp + i))
        );
        return random % RANDSEED;
    }

    function myInventory(address owner, uint256 levelcode)
        public
        view
        returns (uint256[] memory available)
    {
        uint256[] memory a = WuFu721.getTokens(owner);
        if (levelcode == 0) {
            uint256[] memory aa = new uint256[](a.length);
            uint256 acounter = 0;
            for (uint256 i = 0; i < a.length; i++) {
                aa[acounter] = a[i];
                acounter++;
            }
            return aa;
        }

        available = new uint256[](a.length);

        uint256 counter = 0;
        for (uint256 i = 0; i < a.length; i++) {
            if (tokenInfo[a[i]].levelCode == levelcode) {
                available[counter] = a[i];
                counter++;
            }
        }

        return available;
    }

    function getReward(address userAddress) public view returns (uint256) {
        if (userAddress == DeadAddress) {
            return 0;
        }
        
        uint256[] memory  available = myInventory(userAddress, 600);

        uint256 amount = 0;
        for (uint256 i = 0; i < available.length; i++) {
            if (available[i] > 0) {
                amount++;
            }
        }
        
        if (amount == 0) {
            return 0;
        } else {
            return AllRewardPool * amount / (SuperLuckyAmount - HasSuperLuckyAmount);
        }
    }

    function claim() public {
        require(msg.sender != DeadAddress, "no address");
        require(block.timestamp >= RewardTime, "no start");

        uint256[] memory  available = myInventory(msg.sender, 600);
        uint256 amount = 0;
        for (uint256 i = 0; i < available.length; i++) {
            if (available[i] > 0) {
                amount++;
            }
        }
        require(amount > 0, "Insufficient permissions");

        uint256 myReward = getReward(msg.sender);
        if (AllRewardPool >= myReward) {
            AllRewardPool -= myReward;
        } else {
            AllRewardPool = 0;
        }
        
        bool suc;
        if (address(this).balance >= myReward) {
            (suc, ) = msg.sender.call{value: myReward}(new bytes(0));
        } else {
            (suc, ) = msg.sender.call{value: address(this).balance}(new bytes(0));
        }
        
        require(suc, "TransferHelper: ETH_TRANSFER_FAILED");

        for (uint256 index = 0; index < amount; index++) {
            HasSuperLuckyAmount += 1;
            WuFu721.transferFrom(msg.sender, DeadAddress, available[0]);
        }   
    }
}