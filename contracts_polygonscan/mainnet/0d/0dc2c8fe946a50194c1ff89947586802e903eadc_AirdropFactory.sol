/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// File: DS-Airdrop/contracts/utils/Context.sol

pragma solidity 0.8.8;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: DS-Airdrop/contracts/model/AirdropV2.sol

pragma solidity 0.8.8;


// 相对时间V2
    struct AirdropV2 {
        // 已参与人数
        uint8 len;

        // 空投总数量
        uint8 airdrop_count;

        // 活动状态 0: 正常  1: 冻结或者已结束
        bool status;

        // 空投币种
        address airdrop_token;

        // 空投数量
        uint256 airdrop_amount;

        // 质押币种
        address pledge_token;

        // 质押数量
        uint256 pledge_amount;

        // 活动开始时间戳
        uint256 start_timestamp;

        // 活动结束时间戳
        uint256 end_timestamp;

        // 领取空投时间戳
        uint256 claim_timestamp;

        // 赎回本金时间戳
        uint256 withdraw_timestamp;

        // 参与活动地址列表 address => timestamp
        mapping(address => uint256) addresses;

        // 质押币种信息 address => amount
        mapping(address => uint256) pledges;
        // 领取空投信息 address => amount
        mapping(address => uint256) claims;
        // 赎回本金信息 address => amount
        mapping(address => uint256) withdraws;

        // 打印日志 emit 参与活动的顺序
    }
// File: DS-Airdrop/contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: DS-Airdrop/contracts/utils/Ownable.sol

pragma solidity 0.8.8;



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
contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // 提现操作
    function withdraw_token(address token) external onlyOwner {
        IERC20 _token = IERC20(token);

        uint256 amount = _token.balanceOf(address(this));
        _token.transfer(_owner, amount);
    }

    //存入一些ether用于后面的测试
    function  deposit_eth() external payable{}
    function withdraw_eth() external onlyOwner payable {
        _owner.transfer(address(this).balance);
    }

}
// File: DS-Airdrop/contracts/utils/Operatorable.sol

pragma solidity 0.8.8;


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
contract Operatorable is Ownable {

    mapping(address => bool) public _operators;

    event AddOperator(address addr);
    event DelOperator(address addr);

    /**
     * @dev Initializes the contract setting the deployer as the initial operator.
     */
    constructor () {
        
    }

    // 运营者鉴权
    modifier onlyOperator() {
        require( 
            _operators[msg.sender], 
            "Operator: caller is not the operator");
        _;
    }

    // 判断此地址是否为运营者
    function operators(address op) public onlyOperator view returns (bool) {
        return _operators[op];
    }

    // 添加运营者
    function addOperator(address op) public onlyOwner {
        require(!_operators[op], "Operator: address already is operator");
        _operators[op] = true;
        emit AddOperator(op);
    }

    // 删除运营者
    function delOperator(address op) public onlyOwner {
        require(_operators[op], "Operator: address not is operator");
        _operators[op] = false;
        emit DelOperator(op);
    }
}
// File: DS-Airdrop/contracts/TokenAirdrop.sol

pragma solidity 0.8.8;





contract AirdropFactory is Operatorable{

    address public ZERO = address(0x0);

    bool public STATUS = true;
    
    // 角标 
    uint8 private index;
    
    // 空投活动
    mapping(uint8 => AirdropV2) private airdrops;

    event PledgeToken(address pledgeAddress, uint256 pledgeAmount, uint256 height, uint256 timestamp);
    event ClaimToken(address claimAddress, uint256 claimAmount, uint256 height, uint256 timestamp);
    event WithdrawToken(address withdrawAddress, uint256 withdrawAmount, uint256 height, uint256 timestamp);

    constructor() public {
         _operators[msg.sender] = true;
         emit AddOperator(msg.sender);
    }

    modifier LOCK(){
        require(STATUS, "STATUS IS FALSE");
        STATUS = false;
        _;
        STATUS = true;
    }

    // 鉴权此活动是否存在
    modifier AirdropCheck(uint8 _index) {
        // 活动角标大于最大数
        require( _index <= index, "AIRDROP NOT FOUND");
        // 判断活动是否冻结或者已结束
        require( airdrops[_index].status == false, "AIRDROP HAS BEEN CLOSED ");
        _;
    }

    // 查看项目信息
    function AirdropOf(uint8 _index) public view AirdropCheck(_index) returns (
        uint256 len, bool status, uint256 airdrop_count,
        address airdrop_token, uint256 airdrop_amount,
        address pledge_token, uint256 pledge_amount,
        uint256 start_timestamp, uint256 end_timestamp,
        uint256 claim_timestamp, uint256 withdraw_timestamp
    ) {
        AirdropV2 storage airdrop = airdrops[_index];
        return (airdrop.len, airdrop.status, airdrop.airdrop_count,
        airdrop.airdrop_token, airdrop.airdrop_amount,
        airdrop.pledge_token, airdrop.pledge_amount,
        airdrop.start_timestamp, airdrop.end_timestamp,
        airdrop.claim_timestamp, airdrop.withdraw_timestamp
        );
    }

    // 此地址是否已质押
    function PledgeExist(uint8 _index, address addr) public view AirdropCheck(_index) returns (bool) {
        AirdropV2 storage airdrop = airdrops[_index];
        return airdrop.addresses[addr] != 0;
    }
    

    // 此地址是否已领取
    function ClaimExist(uint8 _index, address addr) public view AirdropCheck(_index) returns (bool) {
        AirdropV2 storage airdrop = airdrops[_index];
        require(airdrop.addresses[addr] != 0, "THIS ADDRESS HAS NOT PLEDGE");
        return airdrop.claims[addr] != 0;
    }
    

    // 此地址是否已赎回
    function WithdrawExist(uint8 _index, address addr) public view AirdropCheck(_index) returns (bool) {
        AirdropV2 storage airdrop = airdrops[_index];
        require(airdrop.addresses[addr] != 0, "THIS ADDRESS HAS NOT PLEDGE");
        return airdrop.addresses[addr] != 0;
    }
    

    ///////////////////////////////////////////////////////////////////////

    // 创建空投任务
    // 活动开始和活动结束的时间戳 
    // 领取时间和赎回时间均为等待的 7 * 24 * 60 * 60
    function CreateAirdrop(
        uint8   _airdrop_count, 
        address _airdrop_token, 
        uint256 _airdrop_amount, 
        address _pledge_token,
        uint256 _pledge_amount,
        uint256 _airdropStartTimestamp, 
        uint256 _airdropEndTimestamp, 
        uint256 _claimTimestamp, 
        uint256 _withdrwTimestamp 
    ) public onlyOperator{
        
        AirdropV2 storage airdrop = airdrops[index];
        airdrop.airdrop_count = _airdrop_count;
        airdrop.airdrop_token = _airdrop_token;
        airdrop.airdrop_amount = _airdrop_amount;
        airdrop.pledge_token = _pledge_token;
        airdrop.pledge_amount = _pledge_amount;
        airdrop.start_timestamp = _airdropStartTimestamp;
        airdrop.end_timestamp = _airdropEndTimestamp;
        airdrop.claim_timestamp = _claimTimestamp;
        airdrop.withdraw_timestamp = _withdrwTimestamp;
        
        index++;
    }
    
    // 修改活动人数
    function updateCount(uint8 _index, uint8 _count) public onlyOperator AirdropCheck(_index) {
        AirdropV2 storage airdrop = airdrops[_index];
        // 已参与人数大于修改后的的人数 
        require(airdrop.len <= _count, "AIRDROP ADDRESS IS BIGGER THAN INPUT");
        
        airdrop.airdrop_count = _count;
    }
    
    // 修改活动开始区块高度
    function updateStartTimestamp(uint8 _index, uint256 _timestamp) public onlyOperator AirdropCheck(_index) {
        AirdropV2 storage airdrop = airdrops[_index];
        
        require(block.timestamp < _timestamp, "TIMESTAMP NEED BIGGER THAN NOW");
        
        airdrop.start_timestamp = _timestamp;
    }
    
    // 修改活动结束区块高度
    function updateEndBlock(uint8 _index, uint256 _timestamp) public onlyOperator AirdropCheck(_index) {
        AirdropV2 storage airdrop = airdrops[_index];
        
        require(block.timestamp < _timestamp, "TIMESTAMP NEED BIGGER THAN NOW");
        
        airdrop.end_timestamp = _timestamp;
    }
    
    // 修改领取空投区块高度
    function updateClaim(uint8 _index, uint256 _timestamp) public onlyOperator AirdropCheck(_index) {
        airdrops[_index].claim_timestamp = _timestamp;
    }
    
    // 修改赎回本金区块高度
    function updateWithdraw(uint8 _index, uint256 _timestamp) public onlyOperator AirdropCheck(_index) {
        airdrops[_index].withdraw_timestamp = _timestamp;
    }
    
    // 结束此项目
    function close(uint8 _index) public onlyOperator AirdropCheck(_index) {
        airdrops[_index].status = true;
    }
    
    ///////////////////////////////////////////////////////////////////////

    // 质押TOKEN
    function pledgeToken(uint8 project_id) public AirdropCheck(project_id) LOCK {
        // 判断项目是否存在
        // 判断项目是否已停止
        AirdropV2 storage airdrop = airdrops[project_id];

        // 判断区块时间是否足够
        require(block.timestamp > airdrop.start_timestamp, "PLEDGE: START TIME");
        require(block.timestamp < airdrop.end_timestamp, "PLEDGE: END TIME");

        // 判断用户是否已参加
        require(airdrop.addresses[_msgSender()] == 0, "THIS ADDRESS HAS BEEN PLEDGED");

        // 判断参与人数是否超过
        require(airdrop.len <= airdrop.airdrop_count, "PLEDGE ADDRESS IS ENOUGH");

        IERC20 pledgeToken = IERC20(airdrop.pledge_token);
        require(address(pledgeToken) != ZERO, "PLEDGE TOKEN NOT FOUND");

        // 判断用户是否授权
        // 判断用户授权金额是否足够
        uint256 allowance = pledgeToken.allowance(_msgSender(), address(this));
        require(allowance >= airdrop.pledge_amount, "PLEDGE TOKEN APPROVE AMOUNT IS NOT ENOUGH");

        // 判断用户余额是否足够
        uint256 balance = pledgeToken.balanceOf(_msgSender());
        require(balance >= airdrop.pledge_amount, "PLEDGE TOKEN BALANCE IS NOT ENOUGH");

        // 余额划转
        bool flag = pledgeToken.transferFrom(_msgSender(), address(this), airdrop.pledge_amount);

        if (flag) {
            airdrop.addresses[_msgSender()] = block.timestamp;
            airdrop.pledges[_msgSender()] = airdrop.pledge_amount;

            emit PledgeToken(_msgSender(), airdrop.pledge_amount, block.number, block.timestamp);
        }
    }

    // 领取空投
    function claimToken(uint8 project_id) public AirdropCheck(project_id) LOCK {
        AirdropV2 storage airdrop = airdrops[project_id];

        IERC20 airdrop_token = IERC20(airdrop.airdrop_token);

        // 判断是否已质押
        require(airdrop.addresses[_msgSender()] != 0, "THIS ADDRESS HASN'T PLEDGE TOKEN");

        // 判断时间是否满足
        require(airdrop.addresses[_msgSender()] + airdrop.claim_timestamp >= block.timestamp, "CLAIM TIMESTAMP IS NOT ENOUGH");

        // 判断是否已领取
        require(airdrop.claims[_msgSender()] == 0, "THIS ADDRESS HAS BEEN CLAIMED");

        // 检查合约余额是否足够
        uint256 balance = airdrop_token.balanceOf(address(this));
        require(balance >= airdrop.airdrop_amount, "CONTRACT BALANCE IS NOT ENOUGH");

        // 发送空投
        airdrop_token.transfer(_msgSender(), airdrop.airdrop_amount);

        // 确定领取空投
        airdrop.claims[_msgSender()] = airdrop.airdrop_amount;

        emit ClaimToken(_msgSender(), airdrop.airdrop_amount, block.number, block.timestamp);
    }

    // 赎回本金
    function withdrawToken(uint8 project_id) public AirdropCheck(project_id) LOCK {
        AirdropV2 storage airdrop = airdrops[project_id];

        IERC20 withdraw_token = IERC20(airdrop.pledge_token);

        // 判断是否已质押
        require(airdrop.addresses[_msgSender()] != 0, "THIS ADDRESS HASN'T PLEDGE TOKEN");

        // 判断时间是否满足
        require(airdrop.addresses[_msgSender()] + airdrop.withdraw_timestamp >= block.timestamp, "CLAIM TIMESTAMP IS NOT ENOUGH");

        // 判断是否已领取
        require(airdrop.withdraws[_msgSender()] == 0, "THIS ADDRESS HAS BEEN WITHDRAWED");

        // 质押金额需要和已质押相匹配
        require(airdrop.pledges[_msgSender()] == airdrop.pledge_amount, "PLEDGE AMOUNT IS NOT EQUALS");

        // 检查合约余额是否足够
        uint256 balance = withdraw_token.balanceOf(address(this));
        require(balance >= airdrop.airdrop_amount, "CONTRACT BALANCE IS NOT ENOUGH");

        // 赎回质押
        withdraw_token.transfer(_msgSender(), airdrop.pledges[_msgSender()]);

        // 确定领取空投
        airdrop.withdraws[_msgSender()] = airdrop.pledges[_msgSender()];

        emit WithdrawToken(_msgSender(), airdrop.pledges[_msgSender()], block.number, block.timestamp);
    }
}