// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IAttr.sol";

contract PVE is Ownable, Context, Attr {
    constructor() {
        updateAdminAddress(_msgSender(), true);
        mktAddress = _msgSender();
    }

    mapping(address => bool) public adminAddress;

    modifier onlyOwnerOrAdminAddress() {
        require(adminAddress[_msgSender()], "permission denied");
        _;
    }

    function updateAdminAddress(address newAddress, bool flag)
        public
        onlyOwner
    {
        require(
            adminAddress[newAddress] != flag,
            "The adminAddress already has that address"
        );
        adminAddress[newAddress] = flag;
    }

    modifier onlyUse() {
        require(use, "contract not use!");
        _;
    }

    bool public use;

    function setUse(bool status) public onlyOwner {
        use = status;
    }

    mapping(address => uint256) public userUseNft;

    function setUserUseNft(uint256 id) public {
        // 设置上阵nft
        userUseNft[msg.sender] = id;
    }

    struct task {
        IERC20 rewardToken; // 奖励token.
        uint256 ce; // 战斗力
        uint256 coolingTime; // 冷却时间.
        uint256 minReward; // 最小奖励
        uint256 maxReward; // 最大奖励
        string monsterImage; // 怪物图片
    }

    task[] public tasks;
    
    function tasksLength() external view returns (uint256) {
        return tasks.length;
    }

    function addTask(
        IERC20 _rewardToken,
        uint256 _ce,
        uint256 _coolingTime,
        uint256 _minReward,
        uint256 _maxReward,
        string memory _monsterImage
    ) public onlyOwnerOrAdminAddress {
        // 添加日常任务
        tasks.push(
            task({
                rewardToken: _rewardToken,
                ce: _ce,
                coolingTime: _coolingTime,
                minReward: _minReward,
                maxReward: _maxReward,
                monsterImage: _monsterImage
            })
        );
    }

    function delTask(uint256 tid) public onlyOwnerOrAdminAddress {
        // 删除日常任务
        uint256 lastTaskIndex = tasks.length - 1;
        task memory lastTask = tasks[lastTaskIndex];
        tasks[tid] = lastTask;
        tasks.pop();
    }

    function updateTask(
        uint256 tid,
        IERC20 _rewardToken,
        uint256 _ce,
        uint256 _coolingTime,
        uint256 _minReward,
        uint256 _maxReward,
        string memory _monsterImage
    ) public onlyOwnerOrAdminAddress {
        // 修改日常任务
        tasks[tid] = task({
            rewardToken: _rewardToken,
            ce: _ce,
            coolingTime: _coolingTime,
            minReward: _minReward,
            maxReward: _maxReward,
            monsterImage: _monsterImage
        });
    }

    IERC721 public nftAddress;

    function setNftAddress(address nft) public onlyOwnerOrAdminAddress {
        // 设置nft合约地址
        nftAddress = IERC721(nft);
    }

    mapping(uint256 => mapping(address => uint256)) public userCoolingTime;

    function setUserCoolingTime(uint256 tid, uint256 time)
        public
        onlyOwnerOrAdminAddress
    {
        userCoolingTime[tid][msg.sender] = time;
    }

    IERC20 public tokenAddress;
    uint256 public fightingPrice;
    address public mktAddress;

    function setMktAddress(address mktAddr) public onlyOwner {
        require(
            mktAddr != address(mktAddress),
            "mktAddress address Currently in use!"
        );
        mktAddress = mktAddr;
    }

    function setFightingPricePrice(uint256 price) public onlyOwner {
        require(price > 100, "price must be gt 100!");
        fightingPrice = price;
    }

    function setTokenAddress(address token) public onlyOwner {
        require(
            token != address(tokenAddress),
            "token address Currently in use!"
        );
        tokenAddress = IERC20(token);
    }

    function tokenAddressTransFrom() internal {
        if (address(tokenAddress) != address(0)) {
            // token
            IERC20(tokenAddress).transferFrom(
                _msgSender(),
                mktAddress,
                fightingPrice
            );
        } else {
            // eth
            require(msg.value == fightingPrice, "msg.value Too little");
            payable(mktAddress).transfer(address(this).balance);
        }
    }

    function rand(uint256 _length) internal view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender.balance
                )
            )
        );
        return random % _length;
    }

    event fightingLog(address indexed, uint256, uint256);

    function fighting(uint256 tid) public payable onlyUse returns (uint256 reward) {
        // 战斗
        // 校验nft拥有人
        uint256 nftId = userUseNft[msg.sender];
        require(nftId != 0, "You must set up userUseNft");
        address _o = nftAddress.ownerOf(nftId);
        require(msg.sender == _o, "You don't own it");

        // 收取战斗手续费
        tokenAddressTransFrom();

        // 校验，设置冷却时间
        task memory t = tasks[tid];
        require(
            block.timestamp - userCoolingTime[tid][msg.sender] >= t.coolingTime,
            "Cooldown time is not up"
        );
        userCoolingTime[tid][msg.sender] = block.timestamp;

        // 战斗
        NftInfo memory nftInfo = nftAttrAddress.getNftInfoMap(nftId);

        uint256 nftCe = uint256((nftInfo.ce + nftInfo.hp) * nftInfo.level);

        if (nftCe > t.ce) {
            uint256 extraReward = rand(t.maxReward - t.minReward);
            reward = t.minReward + extraReward;
        }

        // 发放奖励
        if (reward != 0) {
            t.rewardToken.transfer(msg.sender, reward);
        }

        emit fightingLog(msg.sender, tid, reward);
        return reward;
    }

    receive() external payable {}

    function OwnerSafeWithdrawalEth(uint256 amount) public onlyOwner {
        if (amount == 0) {
            payable(owner).transfer(address(this).balance);
            return;
        }
        payable(owner).transfer(amount);
    }

    function OwnerSafeWithdrawalToken(address token_address, uint256 amount)
        public
        onlyOwner
    {
        IERC20 token_t = IERC20(token_address);
        if (amount == 0) {
            token_t.transfer(owner, token_t.balanceOf(address(this)));
            return;
        }
        token_t.transfer(owner, amount);
    }
}