// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Base.sol";
import "./IAToken.sol";
import "./IBToken.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


interface IERC721 {
    //下面是ERC721的标准接口 http://erc721.org/
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed spender, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address spender);
    function setApprovalForAll(address spender, bool _approved) external;
    function isApprovedForAll(address owner, address spender) external view returns (bool);
}


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    // a)	五个等级：青铜，白银，黄金，铂金，钻石
    // b)	面值：B Token铸造NFT的价值
    // c)	效率：Staking速度的核心系数
    // d)	生产力：每个NFT都有其生产力，生产力根据等级随机效率值公式计算得出。生产力是Staking挖矿的核心因素之一（功率= B Token面值*采矿效率）

    struct TokenInfo {            //TokenProperty Info TokenInfo
        uint tokenId;
        uint grade;               //五个等级：青铜，白银，黄金，铂金，钻石
        uint bTokenAmount;        //面值：B Token铸造NFT的价值
        uint efficiency;          //效率：Staking速度的核心系数
        uint mintTime;            // 产生时间，也是挖矿时间
        uint wuxing;                // 五行属性
        uint power;             //生产力：每个NFT都有其生产力, 这个是算出来的，不需要记录
    }

    struct TokenIdsOfOwner {
        mapping(uint => uint) next;
        mapping(uint => uint) prev;
    }

    uint constant LAST = type(uint).max;
    mapping(address => uint) _balanceOf;
    mapping(address => TokenIdsOfOwner) tokenIdsOf;

    // 兑换产生的tokenid
    uint internal _currentTokenId = 0;
    // 兑换数量
    uint internal _exchange_num = 0;
    mapping(uint => address) public _ownerOf;          //TokenIdOwnerOf;    //TokenId => owner
    mapping(uint => TokenInfo) public _tokenInfoOf;          //TokenIdOwnerOf;    //TokenId => owner
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _spenderApprovals;


    function getTokenIdsOf(address _owner) external view returns (uint[] memory ids) {
        mapping(uint => uint) storage prev = tokenIdsOf[_owner].prev;
        uint tokenId = prev[LAST];
        uint len = _balanceOf[_owner];
        ids = new uint[](len);
        for (uint i = 0; i < len; i++) {
            ids[i] = tokenId;
            tokenId = prev[tokenId];
        }
    }

    function getPowerInfo(uint _tokenId) external view returns (uint256) {
        return _tokenInfoOf[_tokenId].power;
    }

    function getTokenInfo(uint _tokenId) public view returns (TokenInfo memory) {
        require(_tokenId <= _currentTokenId, "_tokenId <= _currentTokenId");
        return _tokenInfoOf[_tokenId];
    }

    function ownerAddTokenId(address _owner, uint _tokenId) private {
        require(0 != _tokenId, "ownerAddTokenId: 0 != _tokenId");
        TokenIdsOfOwner storage tio = tokenIdsOf[_owner];
        uint lastElement = tio.prev[LAST];
        tio.next[lastElement] = _tokenId;
        tio.next[_tokenId] = LAST;
        tio.prev[_tokenId] = lastElement;
        tio.prev[LAST] = _tokenId;

        _balanceOf[_owner] = _balanceOf[_owner].add(1);
    }

    function ownerRemoveTokenId(address _owner, uint _tokenId) private {
        require(0 != _tokenId, "ownerRemoveTokenId: 0 != _tokenId");
        TokenIdsOfOwner storage tio = tokenIdsOf[_owner];
        uint nextElement = tio.next[_tokenId];
        require(0 != nextElement, "ownerRemoveTokenId: 0 != prevElement");
        uint prevElement = tio.prev[_tokenId];
        tio.next[prevElement] = nextElement;
        tio.prev[nextElement] = prevElement;

        _balanceOf[_owner] = _balanceOf[_owner] - 1;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownerOf[tokenId];
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(to != _ownerOf[tokenId], "ERC721: approval to current owner");

        require(_msgSender() == _ownerOf[tokenId] || isApprovedForAll(_ownerOf[tokenId], _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address spender, bool approved) public virtual override {
        require(spender != _msgSender(), "ERC721: approve to caller");

        _spenderApprovals[_msgSender()][spender] = approved;
        emit ApprovalForAll(_msgSender(), spender, approved);
    }

    function isApprovedForAll(address owner, address spender) public view override returns (bool) {
        return _spenderApprovals[owner][spender];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual override {
        // safeTransferFrom(from, to, tokenId, "");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }

    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    //     _safeTransfer(from, to, tokenId, _data);
    // }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        require(_data.length == 0, "_data.length == 0");        //新加的，不允许传递数据

        _transfer(from, to, tokenId);
        // require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId <= _currentTokenId;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: spender query for nonexistent token");
        return (spender == _ownerOf[tokenId] || getApproved(tokenId) == spender || isApprovedForAll(_ownerOf[tokenId], spender));
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        require(0 != tokenId, "_burn: 0 != tokenId");
        address owner = ERC721.ownerOf(tokenId);
        require(address(0) != owner, "_burn: address(0) != owner");
        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (0 != _tokenInfoOf[tokenId].tokenId) {
            delete _tokenInfoOf[tokenId];
        }

        ownerRemoveTokenId(owner, tokenId);
        delete _ownerOf[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        //下面两句是新加的, tokenid 必须顺序增加
        require(tokenId == _currentTokenId + 1, "tokenId == _CurrentTokenId + 1");
        _currentTokenId = _currentTokenId + 1;

        // _beforeTokenTransfer(address(0), to, tokenId);

        ownerAddTokenId(to, tokenId);
        _ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(_ownerOf[tokenId] == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // 清空授权，不需要，
        _approve(address(0), tokenId);

        ownerRemoveTokenId(from, tokenId);
        ownerAddTokenId(to, tokenId);

        _ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;                          //这个授权和ERC20的授权记录是反着的！
        emit Approval(_ownerOf[tokenId], to, tokenId);
    }

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


interface IERC721Ex {
    //下面是ERC721的辅助接口
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
}


// 支付合约
contract PayToken is Base {

    using SafeMath for uint256;
    using Address for address;
    IERC20 public payToken;
    uint internal baseCoin = 10 ** 6; // 1usdt

    mapping(address => uint) public ethUserAmountOf;            //用户的存款

    event OnDeposit (address indexed _user, uint _amount, uint _balance);
    event OnWithdraw(address indexed _user, uint _amount, uint _balance);

    // 存款，可以不需要调用
    function deposit() payable external returns (bool){
        if (msg.value > 0) {
            ethUserAmountOf[msg.sender] = ethUserAmountOf[msg.sender].add(msg.value);
            emit OnDeposit(msg.sender, msg.value, ethUserAmountOf[msg.sender]);
            return true;
        }
        return false;
    }
}

// 分红合约，分红地址写死在里面
contract DivToken is PayToken {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // 邀请返佣：
    // 说明：用户分享邀请地址给好友，好友通过链接参与共振，用户则可以获得好友共振数量的10%返佣。只记录第一次分享的关系。
    // 付费：邀请返佣需要付费支付购买，生成邀请资格
    // 初始价格为0.1 ETH。每销售100个邀请后，价格将上涨0.1 ETH。
    // 例如，第1个到第100个引荐ID的价格为0.1 ETH，第101个引荐ID的价格上升为0.2 ETH，依此类推
    // 邀请链接格式：www.abc.com/ETH地址

    uint public ReMenberCounter = 0;                            //接口，购买传销的人数
    mapping(address => bool) public refMenberOf;                //接口，购买传销的地址列表

    uint256 public ToPeople = 0;
    mapping(address => uint256) public ToPeopleGot;     // 已领取

    // 2u + 2u * (ReMenberCounter/100)
    function getRefMenberEth() public view returns (uint) {//接口，
        uint base = 2 * baseCoin;
        return base.add(base.mul(ReMenberCounter.div(100)));
    }

    // todo
    address public MenberPayTo = 0x8ff73Ac95FB00967cB51f0b55D3a984e4cc1D74B;        //正式地址

    event OnBuyReMenber(address indexed _user, uint _timestamp, uint _amount);
    // 购买邀请码
    function buyReMenber() external {//接口，
        require(!refMenberOf[msg.sender], "!refMenberOf[msg.sender]");
        uint amount = getRefMenberEth();
        payToken.safeTransferFrom(msg.sender, address(this), amount);
        ReMenberCounter = ReMenberCounter + 1;

        ethUserAmountOf[MenberPayTo] = ethUserAmountOf[MenberPayTo].add(amount);    //把钱转到指定地址
        // 记录购买邀请码地址 以及 所需开销
        emit OnBuyReMenber(msg.sender, block.timestamp, amount);

        refMenberOf[msg.sender] = true;
    }

    mapping(address => address) public buyerReferenceOf;    // 上线 //接口，

    mapping(uint => address)    public PeopleAddressOf;     // index => People address
    mapping(uint => uint)       public PeoplePer10000Of;    // People address => per100

    uint public PeopleCount = 0;

    // todo
    function IniPeople() internal {
        //  总份额 9000
        //下面是正式地址，
        // 编号	比例	地址
        // 1	45.00%	0x99c5095D737676ED53692D01541d460561433aeB 机构护盘
        PeopleAddressOf[1] = 0x99c5095D737676ED53692D01541d460561433aeB;
        PeoplePer10000Of[1] = 4500;
        // 2	13.50%	0xbbe9254B0ADA4c71810f8bD2951E7cbBf270DFBf 技术地址
        PeopleAddressOf[2] = 0xbbe9254B0ADA4c71810f8bD2951E7cbBf270DFBf;
        PeoplePer10000Of[2] = 1350;
        // 3	13.50%	0x16Da5d1676a10FC625045D3E5976E6Bd91359ccB 合作运营地址
        PeopleAddressOf[3] = 0x16Da5d1676a10FC625045D3E5976E6Bd91359ccB;
        PeoplePer10000Of[3] = 1350;
        // 4	9.00%	0x2Ee16d6a15d5E8d9551952490553CdDaE98EC9dE 合作地址1
        PeopleAddressOf[4] = 0x2Ee16d6a15d5E8d9551952490553CdDaE98EC9dE;
        PeoplePer10000Of[4] = 900;
        // 5	9.00%	0x8E79605EC36448106C728a5D5AA9D43d32fE1F28 合作地址2
        PeopleAddressOf[5] = 0x8E79605EC36448106C728a5D5AA9D43d32fE1F28;
        PeoplePer10000Of[5] = 900;

        PeopleCount = 5;
    }

    // 兑换ETH收益分配：
    // 10%：邀请返佣，如无邀请，则百分百进入下面地址分配
    function DivToPeopleEth(uint _ethAmount) internal {
        address _reference = buyerReferenceOf[msg.sender];
        uint ToRef = _ethAmount / 10;
        if (_reference == address(0)) {
            /* ToRef = 0; */
            // add by k 给到同购买邀请码同一个地址
            ethUserAmountOf[MenberPayTo] = ethUserAmountOf[MenberPayTo] + ToRef;
        }
        else {
            ethUserAmountOf[_reference] = ethUserAmountOf[_reference] + ToRef;
        }

        for (uint i = 1; i <= PeopleCount; i++) {
            address people = PeopleAddressOf[i];
            uint Per10000 = PeoplePer10000Of[i];
            uint PeopleEthAmount = ToPeople * Per10000 / 90 / 100;
            ethUserAmountOf[people] = ethUserAmountOf[people] + PeopleEthAmount;
        }
    }
}


// 具体的 ERC721 Token
contract NftERC721 is ERC721, DivToken, IERC721Ex {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;
    uint private _vkey;

    event BuyToken(address indexed _reference, address indexed _sender, uint indexed _tokenId, uint _grade, uint _wuXing, uint _aTokenAmount);


    constructor (address _admin) {
        require(_admin != address(0));
        admin = _admin;

        _name = "MagicRings";
        _symbol = "Nft";
        // todo
        payToken = IERC20(0x01Ae5980Ec32D5e8Aa88c54f47B8c1359D7Be6Fa);

        IniPeople();
    }

    function getNFTsOf(address _owner) external view returns (TokenInfo[] memory nfts) {
        mapping(uint => uint) storage prev = tokenIdsOf[_owner].prev;
        uint tokenId = prev[LAST];
        uint len = _balanceOf[_owner];
        nfts = new TokenInfo[](len);
        for (uint i = 0; i < len; i++) {
            nfts[i] = _tokenInfoOf[tokenId];
            tokenId = prev[tokenId];
        }
    }

    function setPayToken(address _payToken) external onlyAdmin {
        payToken = IERC20(_payToken);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // max supply 500,000
    uint public MaxExchangeTokenNum = 50_0000;

    function totalSupply() public view override returns (uint256) {
        return _currentTokenId;
    }

    bool public isPaused = false;                       // 可以暂停 BuyToken ！
    function setIsPaused(bool _value) external onlyAdmin {
        isPaused = _value;
    }

    uint[] public ATokenPer100 = [100, 90, 80, 70, 60, 50, 40, 30, 20, 10];     // AToken产出的数量和 NFT 的比值

    function getATokenAmount(uint _buyCount) public view returns (uint amount, uint grade) {
        require(_buyCount <= MaxExchangeTokenNum, "getATokenAmount: _buyCount <= MaxExchangeTokenNum");
        uint index = _buyCount / GradeMul;
        amount = ATokenPer100[index] * (1e18);
        // 总共10级，每5万个nft一级
        grade = index + 1;
    }

    function getEthUserAmountOf(address _user) public view returns (uint) {
        return ethUserAmountOf[_user];
    }

    //接口，//取款
    function withdraw(uint _amount) external lock returns (bool) {
        require(ethUserAmountOf[msg.sender] >= _amount, "ethUserAmountOf[msg.sender] >= _amount");
        ethUserAmountOf[msg.sender] = ethUserAmountOf[msg.sender].sub(_amount);
        payToken.safeTransfer(msg.sender, _amount);
        emit OnWithdraw(msg.sender, _amount, ethUserAmountOf[msg.sender]);
        return true;
    }

    address public aToken;
    function setAToken(address _value) external onlyAdmin payable {
        aToken = _value;
    }

    address public bToken;
    function setBToken(address _value) external onlyAdmin payable {
        bToken = _value;
    }

    // 生成随机数, 只能内部调用
    function geEthdNumber(uint _index1) internal view returns (uint) {
        bytes32 _result = keccak256(abi.encodePacked(_index1, msg.sender, blockhash(block.number), address(this), gasleft(), _currentTokenId));
        return uint(_result);
    }

    uint[] public gradeEfficiency = [0, 5_000, 8_000, 9_000, 9_800, 10_000];  // 等级和效率区间 比等级多一位

    //得到效率值(随机)，
    function getEfficiency(uint _grade, uint _randomNumber) public view returns (uint) {
        uint StartNum = gradeEfficiency[_grade - 1];        // 1 代表第一级
        uint EndNum = gradeEfficiency[_grade];
        uint AddNum = EndNum - StartNum;
        uint result = (_randomNumber % AddNum) + 1 + StartNum;
        return result;
    }

    uint[] public GradeTotalOf = [317250, 150000, 30000, 2500, 250];     // 每个等级的NFT总数
    uint public GradeMul = 50_000;                                      // 各个级别的NFT数量是比例的五万倍。

    mapping(uint => uint) public gradeCounterOf;   //级别和统计数量， 级别 => 总量 1 开始

    function testSetGradeCounter(uint _grade, uint _value) external {  //todo: test
        gradeCounterOf[_grade] = _value;            //测试边界条件
    }

    //得到级别值(随机,返回：1-5)，  //各个级别的比例和数量，是50倍关系
    function getGrade(uint _randomNumber) public view returns (uint) {
        // 对剩余可兑换数量取模
        uint RIndex = _randomNumber.mod(MaxExchangeTokenNum - _exchange_num);
        uint _num = 0;
        for (uint i = 0; i <= 4; i++) {
            _num = _num + GradeTotalOf[i] - gradeCounterOf[i];
            if (RIndex < _num) {
                return i + 1;
            }
        }

        require(1 == 2, "1 == 2");
        return 0;
    }

    // 生产力 基础系数  效率系数
    uint[5] public _basePower = [1.1 * 1e18, 1.2 * 1e18, 1.3 * 1e18, 1.6 * 1e18, 1.8 * 1e18];
    uint[5] public _ratePower = [0.1 * 1e18, 0.1 * 1e18, 0.1 * 1e18, 0.2 * 1e18, 0.2 * 1e18];
    // NFT 生产力=等级基础值+效率系数*（Staking 效率随机数—Staking效率最低数值）/效率范围差值
    function _calPower(uint grade, uint efficiency) private view returns (uint) {
        require(grade > 0 && grade < 6, "error grade");
        uint _i1 = efficiency.sub(gradeEfficiency[grade - 1]);
        uint _i2 = gradeEfficiency[grade].sub(gradeEfficiency[grade - 1]);
        uint _i3 = _ratePower[grade - 1].mul(_i1.div(_i2));
        uint result = _basePower[grade - 1].add(_i3);

        return result;
    }

    uint[] public BTokenValues = [0.2 * 1e18, 0.5 * 1e18, 2 * 1e18, 10 * 1e18, 50 * 1e18];

    function getBTokenValue(uint _grade) public view returns (uint) {
        require(1 <= _grade && _grade <= 5, "1 <= _grade && _grade <= 5");
        return BTokenValues[_grade - 1];
    }

    uint public OneAmount = 10 * baseCoin;

    function buyToken(uint _tokenNumber, address _reference) external lock returns (bool) {//接口，
        require(0 < _tokenNumber, "1");
        require(_tokenNumber <= 10, "2");                                       //新需求，最多抽取10份
        require(_exchange_num + _tokenNumber <= MaxExchangeTokenNum, "3");
        require(aToken != address(0), "AToken != address(0)");
        require(!isPaused, "!isPaused");
        require(msg.sender == tx.origin, "msg.sender == tx.origin");            //不支持合约调用

        // 所需usdt
        uint _amount = OneAmount.mul(_tokenNumber);
        payToken.safeTransferFrom(msg.sender, address(this), _amount);

        //条件： 1, 有邀请资格；2，第一次邀请（不存在上线）；3，输入的上线不为空
        if (refMenberOf[_reference] && buyerReferenceOf[msg.sender] == address(0) && _reference != address(0)) {
            buyerReferenceOf[msg.sender] = _reference;
        }

        uint aTokenAmountCount;
        for(uint i = 0; i < _tokenNumber; i++) {
            (, uint aTokenAmount) = buyOneToken(i);
            // count total aToken amount to be sent
            aTokenAmountCount = aTokenAmountCount.add(aTokenAmount);
        }
        // mint aToken to sender
        require(aTokenAmountCount > 0, "buyToken: aTokenAmountCount > 0");
        bool mintResult = IAToken(aToken).mintOnlyByNft(msg.sender, aTokenAmountCount);
        require(mintResult, "buyToken: mintOnlyByNft");

        DivToPeopleEth(_amount);                                                 //3，分钱

        return true;
    }

    // 生成一个NFT结构数据  供兑换 合成等使用
    function genNft(uint _Index, uint _g) internal view returns(TokenInfo memory) {
        uint rn1 = geEthdNumber(5);
        uint g = _g;
        if (_g == 0) {g = getGrade(rn1); }                          //1, 得到级别
        uint rn2 = geEthdNumber(5 * _Index + 1);
        uint _bamount = getBTokenValue(g);                              //2, 得到BToken 面值
        uint _efficiency = getEfficiency(g, rn2);                       //3, 得到生产力
        uint _power = _calPower(g, _efficiency);                        // 得到挖矿效率
        uint rn3 = geEthdNumber(5 * _Index + 2)  % 5;                   // 五行属性  0-4代表 金木水火土

        TokenInfo memory ti;
        ti.grade = g;
        ti.bTokenAmount = _bamount;
        ti.efficiency = _efficiency;
        ti.wuxing = rn3;
        ti.mintTime = block.timestamp;
        ti.power = _power;

        return ti;
    }

    function buyOneToken(uint _index) private returns (uint tokenId, uint aTokenAmount) {
        TokenInfo memory ti = genNft(_index, 0);
        tokenId = _currentTokenId + 1;
        ti.tokenId = tokenId;

        _tokenInfoOf[tokenId] = ti;                                     //4, 保存 Token 属性
        _mint(msg.sender, tokenId);                                     //5, 挖矿，产生Token
        gradeCounterOf[ti.grade] = gradeCounterOf[ti.grade] + 1;        //6, 记录各个级别的数量

        (aTokenAmount, ) = getATokenAmount(_exchange_num);               //7, 产生AToken
        _exchange_num = _exchange_num + 1;

        emit BuyToken(buyerReferenceOf[msg.sender], msg.sender, tokenId, ti.grade, ti.wuxing, aTokenAmount);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//    event OnAdminWithdraw(address indexed _token, address indexed _to, uint _amount);

    // 为了预防意外，管理员在 365 天后可以提走所有 token， 包括eth
//    function AdminWithdraw(address _token, address payable _to, uint _amount) external lock onlyAdmin returns (bool) {
//        // 30 天后可取款
//        require(createTime + (365 days) < block.timestamp, "createTime + (365 days) < block.timestamp");
//        require(_token != address(this), "_token != address(this)");
//        require(_to != address(0), "_to != address(0)");
//        if (_token == address(0)) {
//            if (address(_to).isContract()) {                     //合约地址提现, 管理员有可能是个合约！
//                (bool success,) = _to.call {value : _amount} ("");
//                require(success, "8");
//            }
//            else {
//                _to.transfer(_amount);                           //用户地址提现
//            }
//        }
//        else {
//            IERC20(_token).safeTransfer(_to, _amount);
//        }
//
//        emit OnAdminWithdraw(_token, _to, _amount);
//        return true;
//    }

    event Decompose(address indexed from, uint[] tokenIds, uint bTokenAmount);
    event Forge(address indexed from, uint[] tokenIds, uint grade);
    event Compound(address indexed from, uint[] tokenIds, uint newTokenId, uint currGrade, uint newGrade, uint aTokenAmount);
    mapping(uint => uint[]) canForgeTokenIDList; // 可铸造列表

//    function getCanForgeList() external returns (uint[5] memory lenList) {
//        for (uint i = 0; i < 5; i++){
//            lenList[i] = canForgeTokenIDList[i+1].length;
//        }
//    }

    /**
     * @dev decompose nft
     * @dev _tokenIds array of nft tokenIds to be decompose
     */
    function decompose(uint[] memory _tokenIds) external returns (uint bTokenAmount) {
        require(_tokenIds.length > 0, "decompose: _tokenIds.length > 0");
        require(bToken != address(0), "decompose: bToken != address(0)");

        for (uint i = 0; i < _tokenIds.length; i++) {
            // no needed
//            require(_ownerOf[_tokenIds[i]] == msg.sender, "ERC721: transfer of token that is not own");
            // 把该nft转移到合约
            _transfer(msg.sender, address(this), _tokenIds[i]);
            // 把该nft加入可铸造列表
            canForgeTokenIDList[getTokenInfo(_tokenIds[i]).grade].push(_tokenIds[i]);
            bTokenAmount = bTokenAmount.add(getTokenInfo(_tokenIds[i]).bTokenAmount);
        }

        // 给玩家相应的bToken
        IBToken(bToken).transferAuth(_msgSender(), bTokenAmount);

        emit Decompose(msg.sender, _tokenIds, bTokenAmount);
    }

    /**
     * @dev forge nft
     * @param _grade grade of nft to be forge
     * @dev _amount amount of nft to be forge
     */
    function forge(uint _grade, uint _amount) external returns (bool) {
        require(0 < _amount, "forge: 0 < _amount");
        require(0 < _grade && _grade <= 5, "forge: 0 < _grade && _grade <= 5");
        require(canForgeTokenIDList[_grade].length >= _amount, "forge: canForgeTokenIDList[_grade].length >= _amount");

        uint[] memory tokenIds = new uint[](_amount);
        for (uint i = 0; i < _amount; i++) {
            uint tokenId = canForgeTokenIDList[_grade][canForgeTokenIDList[_grade].length - 1];
            tokenIds[i] = tokenId;
            // 判断该tokenId是不是属于合约的 // no needed
            //            require(_ownerOf[tokenId] == address(this), "contract no tokenId");

            // 该nft所需bToken
            uint bTokenAmount = getTokenInfo(tokenId).bTokenAmount;
            IBToken(bToken).transferFromAuth(msg.sender, address(this), bTokenAmount);

            canForgeTokenIDList[_grade].pop();

            // 把这个nft转给玩家
            _transfer(address(this), msg.sender, tokenId);
        }

        emit Forge(msg.sender, tokenIds, _grade);

        return true;
    }

    // 合成
    uint constant COMPOUND_RATE = 20; // 每种属性20%的跳级成功率
    uint[] public COMPOUND_USE_ATOKEN = [300 * 1e18, 500 * 1e18, 1500 * 1e18, 3000 * 1e18];

    /**
     * @dev compound nft
     * @dev _tokenIds array of nft tokenIds to be compound
     * must the same
     */
    function compound(uint[] memory _tokenIds) external returns (bool) {
        require(_tokenIds.length == 5, "compound: _tokenIds.length == 5");
        uint currGrade = getTokenInfo(_tokenIds[0]).grade;
        require(5 > currGrade, "compound: 5 > gradeTemp");
        for (uint i = 0; i < _tokenIds.length; i++) {
            // 判断这5个token是不是该玩家的
            require(_ownerOf[_tokenIds[i]] == msg.sender, "ERC721: transfer of token that is not own");
            // is the same grade
            require(currGrade == getTokenInfo(_tokenIds[i]).grade, "compound: must the same grade");
        }

        // 获取有多少个五行属性
        uint andTemp;
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint wuXing = getTokenInfo(_tokenIds[i]).wuxing;
            andTemp = (2 ** wuXing) | andTemp;
        }
        uint wuXingCount;
        for (uint i = 0; i < 5; i++) {
            wuXingCount = (andTemp>>i & 1) + wuXingCount;
        }

        // 消耗Atoken
        uint aTokenAmount = COMPOUND_USE_ATOKEN[currGrade - 1];
        IAToken(aToken).burnOnlyByNFT(msg.sender, aTokenAmount);

        // 生成跳级成功率随机数
        uint rate = geEthdNumber(wuXingCount)  % 100;
        uint increaseGrade = 1;
        if (rate < wuXingCount * COMPOUND_RATE) increaseGrade = 2;
        // 获得新的锻造等级
        uint newGrade = currGrade + increaseGrade;
        if (newGrade > 4) {newGrade = 4;}

        // 先销毁旧的token
        for (uint i = 1; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
        }

        // 生成新的NFT
        TokenInfo memory ti = genNft(wuXingCount, newGrade);
        uint tokenId = _currentTokenId + 1;
        ti.tokenId = tokenId;
        _tokenInfoOf[tokenId] = ti;                                     //4, 保存 Token 属性
        _mint(msg.sender, tokenId);                                     //5, 挖矿，产生Token

        emit Compound(msg.sender, _tokenIds, tokenId, currGrade, newGrade, aTokenAmount);

        return true;
    }

    event WithdrawBToken(address to, uint amount);

    function withdrawBToken(address _to) external onlyAdmin returns (bool) {
        uint bTokenAmount = IERC20(bToken).balanceOf(address(this));
        IBToken(bToken).transferAuth(_to, bTokenAmount);

        emit WithdrawBToken(_to, bTokenAmount);
        return true;
    }

///////////////////////////////////////////////////////////////////////////

receive() external payable {
//ethUserAmountOf[msg.sender] = ethUserAmountOf[msg.sender]  +  msg.value;
}

fallback() external {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


contract Base {
    //避免重入。有调用外部合约的时候，可以谨慎使用！
    bool private unlocked = true;
    address public admin;

    modifier lock() {
        require(unlocked == true, 'lock: unlocked == true');
        unlocked = false;
        _;
        unlocked = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


interface IAToken {
    function mintOnlyByNft(address _to, uint _amount) external returns (bool);
    function burnOnlyByNFT(address _account, uint _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


interface IBToken {
    function transferAuth(address _to, uint _amount) external returns (bool);
    function transferFromAuth(address _from, address _to, uint _amount) external returns (bool);
    function mintOnlyByPool(address _to, uint _amount) external returns (bool);
    function burnOnlyByNFT(address _account, uint _amount) external returns (bool);
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}