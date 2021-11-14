// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IAttr.sol";
import "./ICecale.sol";

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
        IERC20 fightingToken; // 门票token
        uint256 price;      // 门票价格
        IERC20 rewardToken; // 奖励token.
        uint32 ce; // 战斗力
        uint256 coolingTime; // 冷却时间.
        uint256 minReward; // 最小奖励
        uint256 maxReward; // 最大奖励
        string monsterImage; // 怪物图片
        bool is_active; //是否删除
        uint8 campId; // 阵营
    }

    task[] public tasks;
    
    function tasksLength() external view returns (uint256) {
        return tasks.length;
    }

    function addTask(
        IERC20 _rewardToken,
        uint32 _ce,
        uint256 _coolingTime,
        uint256 _minReward,
        uint256 _maxReward,
        string memory _monsterImage,
        IERC20 _fightingToken,
        uint256 _price,
        uint8 _campId
    ) public onlyOwnerOrAdminAddress {
        // 添加日常任务
        tasks.push(
            task({
                rewardToken: _rewardToken,
                ce: _ce,
                coolingTime: _coolingTime,
                minReward: _minReward,
                maxReward: _maxReward,
                monsterImage: _monsterImage,
                fightingToken: _fightingToken,
                price: _price,
                is_active: true,
                campId: _campId
            })
        );
    }

    function delTask(uint256 tid, bool is_active) public onlyOwnerOrAdminAddress {
        // 删除日常任务
        task storage t = tasks[tid];
        t.is_active = is_active;
    }

    function updateTask(
        uint256 tid,
        IERC20 _rewardToken,
        uint32 _ce,
        uint256 _coolingTime,
        uint256 _minReward,
        uint256 _maxReward,
        string memory _monsterImage,
        IERC20 _fightingToken,
        uint256 _price,
        uint8 _campId
    ) public onlyOwnerOrAdminAddress {
        // 修改日常任务
        tasks[tid] = task({
            rewardToken: _rewardToken,
            ce: _ce,
            coolingTime: _coolingTime,
            minReward: _minReward,
            maxReward: _maxReward,
            monsterImage: _monsterImage,
            fightingToken: _fightingToken,
            price: _price,
            is_active: true,
            campId: _campId
        });
    }

    IERC721 public nftAddress;

    function setNftAddress(address nft) public onlyOwnerOrAdminAddress {
        // 设置nft合约地址
        nftAddress = IERC721(nft);
    }

    mapping(uint256 => mapping(uint256 => uint256)) public nftCoolingTime;

    function setNftCoolingTime(uint256 tid, uint256 nftId, uint256 time)
        public
        onlyOwnerOrAdminAddress
    {
        nftCoolingTime[tid][nftId] = time;
    }

    mapping(uint256 => mapping(address => uint256)) public userCoolingTime;

    function setUserCoolingTime(uint256 tid, address user, uint256 time)
        public
        onlyOwnerOrAdminAddress
    {
        userCoolingTime[tid][user] = time;
    }

    ICECalc public cecaleAddress;

    function setCecaleAddress(ICECalc ceCale) public onlyOwner {
        cecaleAddress = ceCale;
    }

    function tokenAddressTransFrom(IERC20 tokenAddress, uint256 fightingPrice) internal {
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

    address public mktAddress;

    function setMktAddress(address mktAddr) public onlyOwner {
        require(
            mktAddr != address(mktAddress),
            "mktAddress address Currently in use!"
        );
        mktAddress = mktAddr;
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

        task storage t = tasks[tid];
        // 收取战斗手续费
        tokenAddressTransFrom(t.fightingToken, t.price);

        // 校验，设置冷却时间
        // nft冷却
        require(
            block.timestamp - nftCoolingTime[tid][nftId] >= t.coolingTime,
            "nftCooldown time is not up"
        );
        nftCoolingTime[tid][nftId] = block.timestamp;

        // user冷却
        require(
            block.timestamp - userCoolingTime[tid][msg.sender] >= t.coolingTime,
            "userCooldown time is not up"
        );
        userCoolingTime[tid][msg.sender] = block.timestamp;


        // 战斗
        uint32 nftCe = cecaleAddress.getCE(address(nftAddress), nftId);
        if (t.campId != 0){
            NftInfo memory nftInfo = nftAttrAddress.getNftInfoMap(nftId);
            uint16 coefficient = cecaleAddress.getAntiCampRate(nftInfo.campId, t.campId);
            nftCe = nftCe * coefficient / 1000;
        }
        

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
    
    
    function test(uint256 nftId)public returns(uint32){
          // 战斗
        uint32 nftCe = cecaleAddress.getCE(address(nftAddress), nftId);
        NftInfo memory nftInfo = nftAttrAddress.getNftInfoMap(nftId);
        uint16 coefficient = cecaleAddress.getAntiCampRate(nftInfo.campId, 2);
        nftCe = nftCe * coefficient / 1000;
        return nftCe;
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