//SourceUnit: CF.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";
import "./Owned.sol";

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface TRC721TokenReceiver {
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

contract TRC721Holder is TRC721TokenReceiver {
    function onTRC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onTRC721Received.selector;
    }
}

contract CrazyForest is TRC721Holder, VRFConsumerBase, Owned {
    // solidity 0.8.0 以上版本已默认检查溢出，可以不使用SafeMath
    // 开启编译优化，共占用256的空间，节省gas开销
    struct Tree {
        uint8 magicNum; //神奇果树的数量
        uint8 isNFT;
        uint8 isOpen;
        uint8 treeIndex;
        uint32 timestamp;
        uint32 num;
        uint32 cont;
        uint64 totalCont;
        uint64 price;
    }

    struct TreeInfo {
        uint128 treeIndex;
        uint128 cont;
    }

    struct Income {
        uint32 dividendDay; //分红起始日
        uint32 minIndex; //最小有效树下标
        uint64 ref; //推荐
        uint64 lottery; //抽奖
        uint64 bonus; //大奖
    }

    struct DividendCheck {
        uint32 treeIndex; //树坐标
        uint32 minIndex; //本次分红最小树坐标
        uint64 value; //分红金额
        uint64 totalShare; //单个贡献值累计分红金额
        uint64 sumCont; //本次分红总贡献值
    }

    struct CheckPoint {
        uint64  treeIndex; // 最大树坐标
        uint64  minIndex; // 最小树坐标
        uint128  value; 
    }

     struct BackGround {
        uint128 index;
        uint128 price;
        string url;
    }

    struct Request {
        uint64 requestType;
        uint64 valid;
        uint128 value;
    }
    
    // 占用一个256位存储槽
    struct GameCondition {
        uint8  flag; // released(4) | start(2) | preBuy(1)
        uint16 dayOffset;
        uint16 currentDay;
        uint16 minDay;
        uint24 roundOffset;
        uint24 currentRound;
        uint24 remainTime;
        uint32 minIndex; // 最小的有效的树下标
        uint32 treeNum; // 当前下标
        uint32 currentMagic;
        uint32 currentNFT;
    }

    // 占用一个256位存储槽
    struct GameState {
        uint32 timestamp;
        uint48 totalContributes;
        uint56 ecology;
        uint56 community;
        uint64 bonus;
    }
    
    // 为了降低gas开销，如需修改下面的值，请在467行的函数内修改
    // uint256[] private _trees = [1, 2, 5, 10, 20, 50, 100, 200];
    // uint256[] private _increase = [600, 300, 60, 60, 30];
    // uint256 private _singlePrice = 158000000;

    GameCondition private _gCondition = GameCondition(1, 0, 0, 0, 0, 0, 86400, 0, 0, 0, 0);
    GameState private _gState = GameState(0, 0, 0, 0, 0);

    mapping(uint256 => DividendCheck) private _dividendCheck;
    mapping(uint256 => CheckPoint) private _lotteryCheck;
    mapping(uint256 => CheckPoint) private _magicCheck;
    mapping(address => Income) private _userIncome;
    mapping(address => TreeInfo[]) private _userTrees;
    mapping(address => mapping(uint256 => uint256)) private _userWater;
    mapping(address => uint256) private _bonusTaken;
    mapping(uint256 => Tree)  private _treeList;
    mapping(uint256 => address) private _treeOwners;
    uint256[] private _magicTrees;
    uint256[] private _nftTrees;
    mapping(uint256 => uint256) private _nftTokens;
    mapping(address => address) _super;
    mapping(address => uint256) _userBox;
    address[] _boxUsers;
    BackGround[] _bgs;
    mapping(address => uint256[]) _userBgs;
    mapping(bytes32 => Request) _requests;
    mapping(bytes32 => uint256) _rands;

    address public stakeToken;
    address private _first;
    address private _admin;
    address private _nft;
    uint256 private _tokenId = 1;

    bytes32 private s_keyHash;
    uint256 private s_fee;

    constructor(address _stakeToken, address _f, address _n, address vrfCoordinator, address win, address winkMid, bytes32 keyHashValue, uint256 feeValue)
    VRFConsumerBase(vrfCoordinator, win, winkMid){
        _admin = msg.sender;
        stakeToken = _stakeToken;
        _first = _f;
        _nft = _n;
        s_keyHash = keyHashValue;
        s_fee = feeValue;
    }

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Direct(address indexed user, address superUser, uint256 amount);
    event InDirect(address indexed user, address inSuper, uint256 amount);
    event BuyTree(address indexed user, uint256 price);
    event Lottery(address indexed user, uint256 amount);
    event DividendTake(address indexed user, uint256 amount);
    event PoolTake(address indexed user, uint256 amount);
    event RefTake(address indexed user, uint256 amount);
    event NftUse(uint256 tokenId);
    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);
    event ReciveRand(bytes32 indexed requestId, uint256 randomness);
    event MagicCheck(uint64 cIndex, uint64 treeIndex, uint64 minIndex, uint64 magicNum);

    modifier activated() {
        require(_super[msg.sender] != address(0) || msg.sender == _first, "Must activate first");
        _;
    }

    modifier started() {
        require((_gCondition.flag & 2) == 2, "Not started");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin can change items");
        _;
    }

    function _rollDice(uint256 userProvidedSeed, address roller) private returns (bytes32 requestId)
    {
        require(winkMid.balanceOf(address(this)) >= s_fee, "Not enough WIN to pay fee");
        requestId = requestRandomness(s_keyHash, s_fee, userProvidedSeed);
        emit DiceRolled(requestId, roller);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (_rands[requestId] == 0) {
            _rands[requestId] = randomness;
            emit ReciveRand(requestId, randomness);
        }
    }

    function processRandomness(bytes32 requestId) public onlyAdmin {
        uint256 randomness =  _rands[requestId];
        Request storage r = _requests[requestId];
        require(r.valid == 1, "finished!");
        require(randomness != 0, "please wait!");
        if (r.requestType == 1) {
            // 抽取神奇果树
            uint256 currentMagic = r.value;
            require(_gCondition.currentMagic == currentMagic, "Duplicated!");
            CheckPoint memory mc = _magicCheck[currentMagic];
            uint256 mNum = mc.value;
            require(mNum > 0, "Not time!");
            uint256 beginIndex = 0;
            if (currentMagic > 0) {
                beginIndex = _magicCheck[currentMagic-1].treeIndex + 1;
            }
            beginIndex = Math.max(beginIndex, mc.minIndex);
            
            while(true) {
                uint256 index = _getRandTree(randomness, beginIndex, mc.treeIndex);
                if(_treeList[index].magicNum < _treeList[index].num) {
                    _treeList[index].magicNum += 1;
                    _magicTrees.push(index);
                    mNum -= 1;
                    if(mNum == 0) {
                        break;
                    }
                }
                randomness = uint256(keccak256(abi.encodePacked(randomness, uint256(mNum))));
            }
            _gCondition.currentMagic += uint32(mc.value);
            r.valid = 0;
        } else if (r.requestType == 2) {
            // 抽取NFT
            uint256 currentNFT = r.value;
            require(_gCondition.currentNFT == currentNFT, "Duplicated!");
            uint256 maxIndex = currentNFT * 20 + 20;
            uint256 minIndex = 0;
            uint256 gMinIndex = _gCondition.minIndex;
            uint256 sum = 0;
            while(minIndex < maxIndex && _magicTrees[minIndex] < gMinIndex) {
                ++minIndex;
            }
            uint256[] memory indexList = new uint256[](maxIndex - minIndex + 1);
            for(uint256 i = minIndex; i < maxIndex; ++i) {
                uint256 ti = _magicTrees[i];
                if (_treeList[ti].isNFT == 0) {
                    indexList[sum] = ti;
                    sum++;
                }
            }
            if (sum > 0) {
                uint256 nftTokenId = _getTokenId();
                require(nftTokenId != 0, "No NFT left!");
                uint256 rand = randomness % sum;
                uint256 tIndex = indexList[rand];
                _treeList[tIndex].isNFT = 1;
                _nftTrees.push(tIndex);
                _nftTokens[tIndex] = nftTokenId;
            }
            _gCondition.currentNFT += 1;
            r.valid = 0;
        } else if(r.requestType == 3){
            // 抽奖
            require(_gCondition.currentRound == r.value, "Duplicated!");
            CheckPoint memory lCheck = _lotteryCheck[r.value];
            uint256 index = _getRandTree(randomness, lCheck.minIndex, lCheck.treeIndex);
            address user = _treeOwners[index];
            TransferHelper.safeTransfer(stakeToken, user, lCheck.value);
            // _userIncome[user].lottery += r.v2;
            _gCondition.currentRound += 1;
            r.valid = 0;
            emit Lottery(user, lCheck.value);
        } else {
            require((_gCondition.flag & 2) == 0, "Duplicated!");
            uint256 len = _boxUsers.length;
            if (len > 0) {
                uint256 num = (len + 29) / 30;
                uint256 rand = randomness % len;
                uint256 tCont = _gState.totalContributes;
                uint256 tIndex = _gCondition.treeNum;
                for(uint256 i = 0; i < num; ++i) {
                    address user = _boxUsers[rand];
                    tCont += 1;
                    _treeList[tIndex] = Tree(0, 0, 0, 0, uint32(_userBox[user]), 1, 1, uint64(tCont), uint64(_treePrice(0)));
                    _treeOwners[tIndex] = user;
                    _userTrees[user].push(TreeInfo(uint128(tIndex), 1));
                    //add magic check
                    if(tCont % 500 == 0) {
                        _magicCheck[tCont / 500 - 1] = CheckPoint(uint64(tIndex), 0, 1);
                        emit MagicCheck(uint64(tCont / 500 - 1), uint64(tIndex), 0, 1);
                    }
                    tIndex += 1;
                    rand += 30;
                    if(rand >= len) {
                        rand -= len;
                    }
                }
                _gState.totalContributes += uint48(tCont);
                _gCondition.treeNum = uint32(tIndex);
            }
            _startGame();
        }
        emit DiceLanded(requestId, 0);
    }

    function _startGame() private {
        _gState.timestamp = uint32(block.timestamp);
        _gCondition.dayOffset = uint16((block.timestamp + 28800) / 86400);
        _gCondition.roundOffset = uint24(block.timestamp / 7200);
        _gCondition.flag |= 2; // start
    }

    function _getRandTree(uint256 r, uint256 minIndex, uint256 maxIndex) private view returns (uint256) {
        uint256 baseCont = 0;
        if (minIndex > 0) {
            baseCont = _treeList[minIndex-1].totalCont;
        }
        uint256 totalCont = _treeList[maxIndex].totalCont - baseCont;
        r = (r % totalCont) + baseCont;
        while(minIndex + 1 < maxIndex) {
            uint256 midIndex = (minIndex + maxIndex) >> 1;
            if(_treeList[midIndex].totalCont <= r) {
                minIndex = midIndex;
            } else {
                maxIndex = midIndex;
            }
        }
        if(_treeList[minIndex].totalCont > r) {
            return minIndex;
        } else {
            return maxIndex;
        }
    }

    function withdrawWIN(address to, uint256 value) public onlyAdmin {
        token.approve(winkMidAddress(), value);
        require(winkMid.transferFrom(address(this), to, value), "Not enough WIN");
    }

    function setKeyHash(bytes32 keyHashValue) public onlyAdmin {
        s_keyHash = keyHashValue;
    }

    function keyHash() public view returns (bytes32) {
        return s_keyHash;
    }

    function setFee(uint256 feeValue) public onlyAdmin {
        s_fee = feeValue;
    }

    function fee() public view returns (uint256) {
        return s_fee;
    }

    // 树的贡献值，树的类型在此修改，internal gas消耗更少
    function _treeCont(uint256 index) internal pure returns (uint256) {
        uint256[8] memory _treeContValue = [uint256(1), 2, 5, 10, 20, 50, 100, 200];
        require(index < _treeContValue.length, "Index error");
        return _treeContValue[index];
    }

    // 树的价格，树的单价在此修改，internal gas消耗更少
    function _treePrice(uint256 index) internal view returns (uint256) {
        uint256 _singlePrice = 158000000;
        return _treeCont(index) * _singlePrice * (_gState.totalContributes / 1000 * 5 + 1000) / 1000;
    }
    
    // 更新剩余时间，时间增加幅度值在此修改
    function _updateTime(uint256 cont, uint256 timeGap) private {
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 200000) {
            cont *= 30;
        } else if (totalCont > 100000) {
            cont *= 60;
        } else if (totalCont > 50000) {
            cont *= 300;
        } else {
            cont *= 600;
        }
        _gCondition.remainTime = uint24(Math.min(_gCondition.remainTime + cont - timeGap, _getLimit()));
    }

    // 树的贡献值，供前端调用
    function treeCont(uint256 index) public pure returns (uint256) {
        return _treeCont(index);
    }
    // 树的价格，供前端调用
    function treePrice(uint256 index) public view returns (uint256) {
        return _treePrice(index);
    }

    // 背景列表
    function allBg() public view returns (BackGround[] memory){
        return _bgs;
    }

    // 游戏是否开始
    function isStart() public view returns (bool) {
        return (_gCondition.flag & 2) == 2;
    }

    // 游戏是否结束
    function isEnd() public view returns (bool) {
        return _ifEnd();
    }

    // 时间
    function checkPoint() public view returns (uint256) {
        return _gState.timestamp;
    }

    // 剩余时间
    function remainTime() public view returns (uint256) {
        uint256 timeGap = _timeGap(_gState.timestamp, block.timestamp);
        if(timeGap > _gCondition.remainTime) {
            return 0;
        }
        return _gCondition.remainTime - timeGap;
    }
    
    // 返回订单数
    function orderNum() public view returns (uint32) {
        return _gCondition.treeNum;
    }

    // 返回订单信息
    function treeInfo(uint256 idx) public view returns (Tree memory) {
        return _treeList[idx];
    }

    // 返回订单owner
    function treeOwner(uint256 idx) public view returns (address) {
        return _treeOwners[idx];
    }

    // 用户是否激活
    function isActivate(address account) public view returns (bool){
        return account == _first || _super[account] != address(0);
    }

    // 用户背景列表
    function bgOf(address account) public view returns (uint256[] memory){
        return _userBgs[account];
    }

    // 累计分红
    function totalDividend() public view returns (uint256){
        return _dividendCheck[_getDay()].value;
    }

    // 累计奖池
    function totalPool() public view returns (uint256){
        return _gState.bonus;
    }

    // 抽奖奖池
    function totalLottery() public view returns (uint256){
        return _lotteryCheck[_getRound()].value;
    }

    // 累计贡献值
    function totalContribute() public view returns (uint256){
        return _gState.totalContributes;
    }

    // 用户的盲盒
    function boxOf(address account) public view returns (uint256){
        return _userBox[account];
    }

    // 返回用户所有的树，树里包含了树种信息，前端处理以提高效率
    function treeOf(address account) public view returns (Tree[] memory) {
        TreeInfo[] memory ut = _userTrees[account];
        Tree[] memory tl = new Tree[](ut.length);       
        for(uint i = 0; i < ut.length; ++i) {
            tl[i] = (_treeList[ut[i].treeIndex]);
        }
        return tl;
    }

    // 上面的函数返回了所有的树，树的信息包含了是否是神奇果树
    // function magicTreeOf(address account) public view returns (MagicTree[] memory){
    //    
    // }

    // 用户未领取的分红
    function dividendOf(address account) public view returns (uint256){
        Income memory uIncome = _userIncome[account];
        uint256 dDay = uIncome.dividendDay;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentDay = _gCondition.currentDay;
        TreeInfo[] memory ut =  _userTrees[account];
        for(; dDay < currentDay; ++dDay) {
            DividendCheck memory dc = _dividendCheck[dDay];
            uint256 minIndexCheck = dc.minIndex;
            uint256 maxIndexCheck = dc.treeIndex;
            while(ut[minIndex].treeIndex < minIndexCheck) {
                ++minIndex;
            }
            for(uint256 i = minIndex; i < ut.length; ++i) {
                if(ut[i].treeIndex <= maxIndexCheck) {
                    sum += dc.value * ut[i].cont / dc.sumCont;
                }
            }
        }
        return sum;
    }

    // 用户未领取的奖池
    function poolOf(address account) public view returns (uint256){
        return _userIncome[account].bonus;
    }

    // 用户未领取的推荐奖励
    function refOf(address account) public view returns (uint256){
        return _userIncome[account].ref;
    }

    // 我的贡献值, 不建议调用，因为treeOf中包含了贡献值，前端做计算即可，这样可以提升运行效率
    // function userC(address account) public view returns (uint256){
    //     uint256 sum = 0;
    //     uint256[] memory ut = _userTrees[account];
    //     for(uint i = 0; i < ut.length; ++i) {
    //         sum += _treeList[ut[i]].cont;
    //     }
    //     return sum;
    // }

    // 用户今日浇水次数
    // function waterCountOf(address account) public view returns (uint256){
    //     return _userWater[account][_getDay()];
    // }

    // 激活用户
    function activate(address superUser) public {
        require(isActivate(superUser) == true, "Super not activated");
        require(isActivate(msg.sender) == false, "Already activated");
        _super[msg.sender] = superUser;
    }

    // 购买背景
    function buyBg(uint256 index) public activated started {
        require(index < _bgs.length, "Bg index error");
        // require(_haveBg(msg.sender, index) == false, "Already have bg");
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, _first, _bgs[index].price);
        _userBgs[msg.sender].push(index);
    }

    // 购买树苗
    function buyTree(uint256 index, uint256 num) public activated started {
        require(num > 0, "Must greater than zero");
        uint256 tIndex = _gCondition.treeNum;
        uint256 timeGap = _timeGap(_gState.timestamp, block.timestamp);
        require(timeGap < _gCondition.remainTime, "Time is over!");
        uint256 price = _treePrice(index) * num;
        uint256 direct = 0;
        address superUser = _super[msg.sender];
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), price);
        if (superUser != address(0)) {
            direct = price * 10 / 100;
            _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(direct);
            emit Direct(msg.sender, superUser, direct);
        }
        uint256 indirect = 0;
        address inSuper = _super[superUser];
        if (inSuper != address(0)) {
            indirect = price * 5 / 100;
            _userIncome[inSuper].ref = _userIncome[inSuper].ref + uint64(indirect);
            emit InDirect(msg.sender, inSuper, indirect);
        }

        //update trees
        uint256 cont = _treeCont(index) * num;
        uint256 preTotalCont = _gState.totalContributes;
        uint256 totalCont = preTotalCont + cont;
        _gState.totalContributes = uint48(totalCont);
        _treeList[tIndex] = Tree(0, 0, 0, uint8(index), uint32(block.timestamp), uint32(num), uint32(cont), uint64(totalCont), uint64(price / cont));
        _treeOwners[tIndex] = msg.sender;
        _userTrees[msg.sender].push(TreeInfo(uint128(tIndex), uint128(cont)));
        //add magic check
        uint256 mNum = totalCont / 500 - preTotalCont / 500;
        if(mNum > 0) {
            _magicCheck[preTotalCont / 500] = CheckPoint(uint64(tIndex), uint64(_gCondition.minIndex), uint128(mNum));
            emit MagicCheck(uint64(preTotalCont / 500), uint64(tIndex), uint64(_gCondition.minIndex), uint64(mNum));
        }

        uint256 day = _getDay();
        _dividendCheck[day] = DividendCheck(uint32(tIndex), 0, uint64(_dividendCheck[day].value + price * 38 / 100), 0, uint64(totalCont));
        uint256 round = _getRound();
        _lotteryCheck[round] = CheckPoint(uint64(tIndex), uint64(_gCondition.minIndex), uint128(_lotteryCheck[round].value + price * 5 / 100));
        _gState.bonus += uint64(price * 15 / 100);
        _gState.ecology += uint56(price * 12 / 100);
        _gState.community += uint56(price * 30 / 100 - direct - indirect);
        _gState.timestamp = uint32(block.timestamp);
        _gCondition.treeNum = uint32(tIndex + 1);

        _updateTime(cont, timeGap);

        emit BuyTree(msg.sender, price);
    }

    function _getDay() private view returns (uint256) {
        return (block.timestamp + 28800) / 86400 - _gCondition.dayOffset;
    }

    function _getRound() private view returns (uint256) {
        return block.timestamp / 7200 - _gCondition.roundOffset;
    }

    // 浇水
    // function water() public activated started {
    //     uint256 day = _getDay();
    //     _userWater[msg.sender][day] += 1;
    // }

    // 开启魔法树的NFT
    function openMagicTree(uint256 index) public activated started {
        require(index < _userTrees[msg.sender].length, "Index error");
        uint256 tIndex = _userTrees[msg.sender][index].treeIndex;
        Tree storage t = _treeList[tIndex];
        require(t.isNFT == 1, "Not Magic tree!");
        require(t.isOpen == 0, "It is opened!");
        uint256 tokenId = _nftTokens[tIndex];
        IERC721(_nft).transferFrom(address(this), msg.sender, tokenId);
        t.isOpen = 1;
        emit NftUse(tokenId);
    }

    // 提取分红
    function dividendTake() public activated started {
        Income storage uIncome = _userIncome[msg.sender];
        uint256 dDay = uIncome.dividendDay;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentDay = _gCondition.currentDay;
        TreeInfo[] memory ut =  _userTrees[msg.sender];
        for(; dDay < currentDay; ++dDay) {
            DividendCheck memory dc = _dividendCheck[dDay];
            uint256 minIndexCheck = dc.minIndex;
            uint256 maxIndexCheck = dc.treeIndex;
            while(ut[minIndex].treeIndex < minIndexCheck) {
                ++minIndex;
            }
            for(uint256 i = minIndex; i < ut.length; ++i) {
                if(ut[i].treeIndex <= maxIndexCheck) {
                    sum += dc.value * ut[i].cont / dc.sumCont;
                }
            }
        }
        if (sum > 0) {
            TransferHelper.safeTransfer(stakeToken, msg.sender, sum);
        }
        uIncome.dividendDay = uint32(currentDay);
        uIncome.minIndex = uint32(minIndex);
        emit DividendTake(msg.sender, sum);
    }

    // 新增：提取推荐奖励，降低购买树苗的收费，合并转账，降低转账手续费
    function refTake() public activated started {
        uint256 amount = _userIncome[msg.sender].ref;
        require(amount > 0, "No remain ref");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _userIncome[msg.sender].ref = 0;
        emit RefTake(msg.sender, amount);
    }

    // 提取奖池收益
    function poolTake() public activated started {
        require((_gCondition.flag & 4) == 4, "It is not released!!");
        if(_gState.totalContributes > 101) {
            uint256 cont = 0;
            TreeInfo[] memory trees = _userTrees[msg.sender];
            for(uint i = 0; i < trees.length; ++i) {
                cont += trees[i].cont;
            }
            cont -= _bonusTaken[msg.sender];
            _userIncome[msg.sender].bonus += uint64(_gState.bonus * cont / (_gState.totalContributes - 101));
        }
        uint256 amount = _userIncome[msg.sender].bonus;
        require(amount > 0, "No remain bonus!");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _userIncome[msg.sender].bonus = 0;
        emit PoolTake(msg.sender, amount);
    }

    // 购买盲盒
    function buyBox() public activated {
        require(_userBox[msg.sender] == 0, "Only once");
        require((_gCondition.flag & 1) == 1, "Activity end");
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, _first, 5000000);
        _userBox[msg.sender] = block.timestamp;
        _boxUsers.push(msg.sender);
    }

    // ---
    function openBox() public onlyAdmin {
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(4, 1, 0);
        _gCondition.flag ^= 1; //preBuy = 0
    }

    function addBg(uint256 _price, string memory _url) public onlyAdmin {
        _bgs.push(BackGround(uint128(_bgs.length), uint128(_price), _url));
    }
    
    // 抽奖
    function lottery() public onlyAdmin started {
        uint256 round = _getRound();
        uint256 currentRound = _gCondition.currentRound;
        require(round > currentRound, "It is not time yet!!");
        if (_lotteryCheck[currentRound].value > 0) {
            uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
            bytes32 requestId = _rollDice(seed, address(this));
            _requests[requestId] = Request(3, 1, uint128(currentRound));
        } else {
            _gCondition.currentRound += 1;
        }
    }
    
    // 抽神奇果树
    function genMagicTree() public onlyAdmin started {
        uint256 currentMagic = _gCondition.currentMagic;
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(1, 1, uint128(currentMagic));
    }
    
    // 抽取NFT
    function genNFT() public onlyAdmin {
        uint256 nftCount = _magicTrees.length / 20;
        require(_gCondition.currentNFT < nftCount, "It is not time yet!!");
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(2, 1, uint128(_gCondition.currentNFT));
    }

    function ecologyTake(address account) public onlyAdmin {
        if (_gState.ecology > 0) {
            TransferHelper.safeTransfer(stakeToken, account, _gState.ecology);
            _gState.ecology = 0;
        }
    }

    function communityTake(address account) public onlyAdmin {
        if (_gState.community > 0) {
            TransferHelper.safeTransfer(stakeToken, account, _gState.community);
            _gState.community = 0;
        }
    }

    function dividend() public onlyAdmin {
        uint256 day = _getDay();
        uint256 currentDay = _gCondition.currentDay;
        require(day > currentDay, "It is not time yet!!");
        DividendCheck storage dCheck = _dividendCheck[currentDay];
        uint256 dValue = dCheck.value;
        uint256 maxIndex = dCheck.treeIndex;
        uint256 sumCont = dCheck.sumCont;
        uint256 minIndex = _gCondition.minIndex;
        uint256 minDay = _gCondition.minDay;
        if (minIndex > 0) {
            sumCont -= _treeList[minIndex - 1].totalCont;
        }
        uint256 totalShare = dValue / sumCont;
        if(currentDay > 0) {
            totalShare += _dividendCheck[currentDay-1].totalShare;
        }

        dCheck.minIndex = uint32(minIndex);
        dCheck.totalShare = uint32(totalShare);
        dCheck.sumCont = uint32(sumCont);

        // update minDay
        if (minDay > 0) {
            totalShare -= _dividendCheck[minDay - 1].totalShare;
        }

        for(; minDay < currentDay; ++minDay) {
            DividendCheck memory dc = _dividendCheck[minDay];
            Tree memory t = _treeList[dc.treeIndex];
            if (totalShare < t.price * 3) {
                maxIndex = dc.treeIndex;
                break;
            }
            totalShare -= dc.totalShare;
            minIndex = dc.treeIndex + 1;
        }
        // update minIndex
        while(minIndex + 1 < maxIndex) {
            uint256 midIndex = (minIndex + maxIndex) >> 1;
            if (totalShare < _treeList[midIndex].price * 3) {
                maxIndex = midIndex;
            } else {
                minIndex = midIndex;
            }
        }
        if (totalShare >= _treeList[minIndex].price * 3) {
            minIndex += 1;
        }

        _gCondition.minIndex = uint32(minIndex);
        _gCondition.minDay = uint16(minDay);
        _gCondition.currentDay += 1;
    }

    function poolRelease() public onlyAdmin {
        require(_ifEnd(), "It is not time yet!!");
        require((_gCondition.flag & 4) == 0, "It is released!!");
        uint256 leftCont = 100;
        uint256 bonus = _gState.bonus;
        uint256 reward = bonus * 40 / 100;
        uint256 secondContribute = Math.min(100, _gState.totalContributes - 1);
        if (bonus > 0) {
            uint256 idx = _gCondition.treeNum - 1;
            Tree memory t = _treeList[idx];
            address user = _treeOwners[idx];
            _userIncome[user].bonus += uint64(reward);
            bonus -= reward;
             _bonusTaken[user] += 1;
            if (t.cont > 1) {
                uint256 cont = Math.min(t.cont-1, 100);
                uint256 b = reward * cont / secondContribute;
                bonus -= b;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
                _bonusTaken[user] += cont;
            }
        
            while(leftCont > 0) {
                idx -= 1;
                t = _treeList[idx];
                user = _treeOwners[idx];
                uint256 cont = Math.min(t.cont, leftCont);
                uint256 b = reward * cont / secondContribute;
                bonus -= b;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
                _bonusTaken[user] += cont;
            }
            _gState.bonus = uint64(bonus);
        }
        _gCondition.flag ^= 4; //released
    }

    // 前端判断即可
    // function _haveBg(address account, uint256 index) private view returns (bool) {
    //     uint256 len = _userBgs[account].length;
    //     for (uint256 i = 0; i < len; i++) {
    //         if (_userBgs[account][i] == index) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    function _isSleep(uint256 blockTime) private pure returns (bool) {
        return (blockTime + 25200) % 86400 < 21600;
    }

    function _timeGap(uint256 begin, uint256 end) private pure returns (uint256) {
        if(!_isSleep(begin) && !_isSleep(end)) {
            if ((begin + 25200) % 86400 <= (end + 25200) % 86400) {
                return (end - begin) - (end - begin) / 86400 * 21600;
            } else {
                return (end - begin) - (end - begin) / 86400 * 21600 - 21600;
            }
        } else {
            if(_isSleep(begin)) {
                begin = (begin + 25200) / 86400 * 86400 + 21600;
            }
            if(_isSleep(end)) {
                end = (end + 25200) / 86400 * 86400;
            }
            if(begin >= end) {
                return 0;
            } else {
                return (end - begin) - (end - begin) / 86400 * 21600;
            }

        }
    }
    
    // private 消耗gas更少
    function _ifEnd() private view returns (bool){
        uint256 dura = _timeGap(_gState.timestamp, block.timestamp);
        return dura >= _gCondition.remainTime;
    }

    function ifEnd() public view returns (bool){
        return _ifEnd();
    }

    function _getLimit() private view returns (uint256) {
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 50000) {
            return 86400;
        } else if (totalCont > 20000) {
            return 172800;
        } else if (totalCont > 10000) {
            return 345600;
        } else {
            return 691200;
        }
    }

    function _getTokenId() internal returns (uint256) {
        IERC721Enumerable nf = IERC721Enumerable(_nft);
        uint256 balance = nf.balanceOf(address(this));
        for (uint256 i = 0; i < balance; i++) {
            uint256 tId = nf.tokenOfOwnerByIndex(address(this), i);
            if (tId > _tokenId) {
                _tokenId = tId;
                return tId;
            }
        }
        return 0; //0表示没有剩余的nft，不要使用0作为nft tokenid
    }
}

//SourceUnit: Owned.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}


//SourceUnit: TRC20Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TRC20Interface {

    function totalSupply() public view virtual returns (uint);

    function balanceOf(address guy) public view virtual returns (uint);

    function allowance(address src, address guy) public view virtual returns (uint);

    function approve(address guy, uint wad) public  virtual returns (bool);

    function transfer(address dst, uint wad) public virtual returns (bool);

    function transferFrom(address src, address dst, uint wad) public virtual returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract WinkMid {

    function setToken(address tokenAddress) public virtual;

    function transferAndCall(address from, address to, uint tokens, bytes memory _data) public virtual returns (bool success);

    function balanceOf(address guy) public view virtual returns (uint);

    function transferFrom(address src, address dst, uint wad) public virtual returns (bool);

    function allowance(address src, address guy) public view virtual returns (uint);

}

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns (uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The start offset to write to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns (buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Length of existing buffer data
            let buflen := mload(bufptr)
        // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
        // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
    * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write the byte at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns (buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Length of existing buffer data
            let buflen := mload(bufptr)
        // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
        // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
    * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = 256 ** len - 1;
        // Right-align data
        data = data >> (8 * (32 - len));
        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
    * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
    * @dev Writes an integer to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (right-aligned).
    * @return The original buffer, for chaining.
    */
    function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
        // Memory address of the buffer data
            let bufptr := mload(buf)
        // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns (buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure {
        if (value <= 23) {
            buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.appendUint8(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.appendUint8(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if (value <= 0xFFFFFFFFFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure {
        buf.appendUint8(uint8((major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal pure {
        if (value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(- 1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

/**
 * @title Library for common Winklink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Winklink {
    uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

    using Buffer for Buffer.buffer;
    using CBOR for Buffer.buffer;

    struct Request {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackFunctionId;
        uint256 nonce;
        Buffer.buffer buf;
    }

    /**
     * @notice Initializes a Winklink request
     * @dev Sets the ID, callback address, and callback function signature on the request
     * @param self The uninitialized request
     * @param _id The Job Specification ID
     * @param _callbackAddress The callback address
     * @param _callbackFunction The callback function signature
     * @return The initialized request
     */
    function initialize(
        Request memory self,
        bytes32 _id,
        address _callbackAddress,
        bytes4 _callbackFunction
    ) internal pure returns (Winklink.Request memory) {
        Buffer.init(self.buf, defaultBufferSize);
        self.id = _id;
        self.callbackAddress = _callbackAddress;
        self.callbackFunctionId = _callbackFunction;
        return self;
    }

    /**
     * @notice Sets the data for the buffer without encoding CBOR on-chain
     * @dev CBOR can be closed with curly-brackets {} or they can be left off
     * @param self The initialized request
     * @param _data The CBOR data
     */
    function setBuffer(Request memory self, bytes memory _data)
    internal pure
    {
        Buffer.init(self.buf, _data.length);
        Buffer.append(self.buf, _data);
    }

    /**
     * @notice Adds a string value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The string value to add
     */
    function add(Request memory self, string memory _key, string memory _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeString(_value);
    }

    /**
     * @notice Adds a bytes value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The bytes value to add
     */
    function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeBytes(_value);
    }

    /**
     * @notice Adds a int256 value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The int256 value to add
     */
    function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeInt(_value);
    }

    /**
     * @notice Adds a uint256 value to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _value The uint256 value to add
     */
    function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.encodeUInt(_value);
    }

    /**
     * @notice Adds an array of strings to the request with a given key name
     * @param self The initialized request
     * @param _key The name of the key
     * @param _values The array of string values to add
     */
    function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
    {
        self.buf.encodeString(_key);
        self.buf.startArray();
        for (uint256 i = 0; i < _values.length; i++) {
            self.buf.encodeString(_values[i]);
        }
        self.buf.endSequence();
    }
}

interface WinklinkRequestInterface {
    function vrfRequest(
        address sender,
        uint256 payment,
        bytes32 id,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 nonce,
        uint256 version,
        bytes calldata data
    ) external;
}

/**
 * @title The WinklinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Winklink network
 */
contract WinklinkClient {
    using Winklink for Winklink.Request;

    uint256 constant internal LINK = 10 ** 18;
    uint256 constant private AMOUNT_OVERRIDE = 0;
    address constant private SENDER_OVERRIDE = address(0);
    uint256 constant private ARGS_VERSION = 1;

    WinkMid internal winkMid;
    TRC20Interface internal token;
    WinklinkRequestInterface private oracle;

    /**
     * @notice Creates a request that can hold additional parameters
     * @param _specId The Job Specification ID that the request will be created for
     * @param _callbackAddress The callback address that the response will be sent to
     * @param _callbackFunctionSignature The callback function signature to use for the callback address
     * @return A Winklink Request struct in memory
     */
    function buildWinklinkRequest(
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunctionSignature
    ) internal pure returns (Winklink.Request memory) {
        Winklink.Request memory req;
        return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
    }

    /**
     * @notice Sets the LINK token address
     * @param _link The address of the LINK token contract
     */
    function setWinklinkToken(address _link) internal {
        token = TRC20Interface(_link);
    }

    function setWinkMid(address _winkMid) internal {
        winkMid = WinkMid(_winkMid);
    }

    /**
     * @notice Retrieves the stored address of the LINK token
     * @return The address of the LINK token
     */
    function winkMidAddress()
    public
    view
    returns (address)
    {
        return address(winkMid);
    }

    /**
     * @notice Encodes the request to be sent to the vrfCoordinator contract
     * @dev The Winklink node expects values to be in order for the request to be picked up. Order of types
     * will be validated in the VRFCoordinator contract.
     * @param _req The initialized Winklink Request
     * @return The bytes payload for the `transferAndCall` method
     */
    function encodeVRFRequest(Winklink.Request memory _req)
    internal
    view
    returns (bytes memory)
    {
        return abi.encodeWithSelector(
            oracle.vrfRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            _req.id,
            _req.callbackAddress,
            _req.callbackFunctionId,
            _req.nonce,
            ARGS_VERSION,
            _req.buf.buf);
    }
}




//SourceUnit: VRFConsumerBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TRC20Interface.sol";
import "./VRFRequestIDBase.sol";
// import "./Owned.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase, WinklinkClient {
    event VRFRequested(bytes32 indexed id);

    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    /**
    * @notice fulfillRandomness handles the VRF response. Your contract must
    * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
    * @notice principles to keep in mind when implementing your fulfillRandomness
    * @notice method.
    *
    * @dev VRFConsumerBase expects its subcontracts to have a method with this
    * @dev signature, and will call it once it has verified the proof
    * @dev associated with the randomness. (It is triggered via a call to
    * @dev rawFulfillRandomness, below.)
    *
    * @param requestId The Id initially returned by requestRandomness
    * @param randomness the VRF output
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal virtual;
    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of WIN to send with the request
     * @param _seed seed mixed into the input of the VRF.
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
      internal returns (bytes32 requestId)
    {
        Winklink.Request memory _req;
        _req = buildWinklinkRequest(_keyHash, address(this), this.rawFulfillRandomness.selector);
        _req.nonce = nonces[_keyHash];
        _req.buf.buf = abi.encode(_keyHash, _seed);
        token.approve(winkMidAddress(), _fee);
        require(winkMid.transferAndCall(address(this), vrfCoordinator, _fee, encodeVRFRequest(_req)), "unable to transferAndCall to vrfCoordinator");

        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful winkMid.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;

        return makeRequestId(_keyHash, vRFSeed);
    }

    /**
     * @param _win The address of the WIN token
     * @param _winkMid The address of the WinkMid token
     * @param _vrfCoordinator The address of the VRFCoordinator contract
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _win, address _winkMid) {
        setWinklinkToken(_win);
        setWinkMid(_winkMid);
        vrfCoordinator = _vrfCoordinator;
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}


//SourceUnit: VRFRequestIDBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}