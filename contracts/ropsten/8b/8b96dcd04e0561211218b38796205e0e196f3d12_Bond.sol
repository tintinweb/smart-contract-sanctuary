pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: contracts/Collateral.sol

contract Collateral is Ownable {
    // 抵押品合约

    using SafeMath for SafeMath;
    using SafeERC20 for ERC20;

    address public BondAddress;
    address public DepositAddress; // 抵押品充值，退还地址
    address public VoceanAddress;  // 违约时，扣除部分转入 VoceanAddress

    uint public DeductionRate;  // 0~100  退回部分抵押物时计算给VoceanAddress部分的比例
    uint public Total = 100;

    uint public AllowWithdrawAmount;

    ERC20 public BixToken;

    event SetBondAddress(address bond_address);
    event RefundAllCollateral(uint amount);
    event RefundPartCollateral(address addr, uint amount);
    event PayByBondContract(address addr, uint amount);
    event SetAllowWithdrawAmount(uint amount);
    event WithdrawBix(uint amount);

    constructor(address _DepositAddress, ERC20 _BixToken, address _VoceanAddress, uint _DeductionRate) public{
        require(_DeductionRate < 100);
        DepositAddress = _DepositAddress;
        BixToken = _BixToken;
        VoceanAddress = _VoceanAddress;
        DeductionRate = _DeductionRate;

    }

    // 设置 债券合约地址
    function setBondAddress(address _BondAddress) onlyOwner public {
        BondAddress = _BondAddress;
        emit SetBondAddress(BondAddress);
    }


    // 退回全部抵押物
    // 只允许 债券合约地址 调用
    function refundAllCollateral() public {
        require(msg.sender == BondAddress);
        uint current_bix = BixToken.balanceOf(address(this));
        BixToken.transfer(DepositAddress, current_bix);

        emit RefundAllCollateral(current_bix);

    }

    // 退回部分抵押物
    // 另一部分转给 VoceanAddress
    function refundPartCollateral() public {

        require(msg.sender == BondAddress);

        uint current_bix = BixToken.balanceOf(address(this));

        // 计算各自数量
        uint refund_deposit_addr_amount = get_refund_deposit_addr_amount(current_bix);
        uint refund_vocean_addr_amount = get_refund_vocean_addr_amount(current_bix);

        // 退给 充值地址
        BixToken.transfer(DepositAddress, refund_deposit_addr_amount);
        emit RefundPartCollateral(DepositAddress, refund_deposit_addr_amount);

        // 退给 VoceanAddress
        BixToken.transfer(VoceanAddress, refund_vocean_addr_amount);
        emit RefundPartCollateral(VoceanAddress, refund_vocean_addr_amount);

    }

    function get_refund_deposit_addr_amount(uint current_bix) internal view returns (uint){
        return SafeMath.div(SafeMath.mul(current_bix, SafeMath.sub(Total, DeductionRate)), Total);
    }

    function get_refund_vocean_addr_amount(uint current_bix) internal view returns (uint){
        return SafeMath.div(SafeMath.mul(current_bix, DeductionRate), Total);
    }

    // 债券合约使用抵押品赔付
    function pay_by_bond_contract(address addr, uint amount) public {
        require(msg.sender == BondAddress);
        BixToken.transfer(addr, amount);
        emit PayByBondContract(addr, amount);

    }

    // 设置 允许发行方提取的数量
    function set_allow_withdraw_amount(uint amount) public {
        require(msg.sender == BondAddress);
        AllowWithdrawAmount = amount;
        emit SetAllowWithdrawAmount(amount);
    }

    // 允许发行方提取 BIX
    function withdraw_bix() public {
        require(msg.sender == DepositAddress);
        require(AllowWithdrawAmount > 0);
        BixToken.transfer(msg.sender, AllowWithdrawAmount);
        // 提取完后 将额度设置为 0
        AllowWithdrawAmount = 0;
        emit WithdrawBix(AllowWithdrawAmount);
    }

}

// File: contracts/Bond.sol

contract Bond is Ownable {


    using SafeERC20 for ERC20;
    using SafeMath for SafeMath;

    // Vocean bond status  [0,1,2,3,4,5,6]
    enum BONDSTATUS {
        SubscriptionStarted,
        SubscriptionEnd,
        MarginCall, // 需要追加抵押品
        Defaulted, // 斩仓，立即执行
        Active, // 债券正常运行
        Inactive,
        IssuedFailed, // 发行失败
        Maturity  // 到期
    }
    BONDSTATUS public bondStatus;  // Status of the bond


    ERC20 public BondToken;
    ERC20 public BixToken;
    Collateral public collateralContract;   // 抵押品合约

    string public BondName;
    string public IssuerName;

    uint public IssuedDate;          // timestamp

    uint public StartSubscribeDate;  // timestamp
    uint public EndSubscribeDate;    // timestamp

    uint public PeriodInYear;     // year
    uint public MaturityDate;  // StartIssued + Period

    uint public IssuedBondAmount; // 发行 bond 份数
    uint public RealSubScriptionAmount;   // 实际 认购 bond 份数
    uint public RealGUSDValue;   // 实际 BIX * BIX_GUSD 价格
    uint public RealBIXAmount;   // 实际 BIX
    uint public BIXFaceValue;
    uint public BixConvertBondToken;
    uint public IssuedOneBondGUSDValue;  // BIXFaceValue * Initial_BIX_GUSD_Price
    uint public IssuedBIXValue;   // IssuedBondAmount * BIXFaceValue
    uint public IssuedGUSDValue;  // IssuedBIXValue * Initial_BIX_GUSD_Price


    uint public CurrentDepositGUSDValue;

    uint public CurrentOneBondGUSDValue;
    uint public CurrentBIXValue;
    uint public CurrentGUSDValue;
    uint public CurrentBIX_GUSD_Price;

    uint public Interest;
    uint public GratifyRate;  // 80~100

    uint public Initial_BIX_GUSD_Price;
    uint public ClaimBIX_GUSD_Price;

    uint public CurrentBIXAmount;
    uint public PrevBIXAmount;  // 上一次保证金合约内BIX数量

    address public DepositAddress;
    address public CollateralAddress;  // 抵押品合约地址

    uint public InitBIXDepositAmount;
    uint public RequireBIXDepositAmount;
    uint public DepositGUSDValue;  // IssuedGUSDValue * 200%
    uint public CurrentBIXDepositAmount;

    uint public BondBIXAmount;
    uint public StartIssuedBIXAmount;
    uint public RefoundBondBIXAmount;

    uint public ShouldReturnBixAmount;  // 到期后，发行方应该还回债券合约的BIX数

    uint public CashDepositAmount;

    uint public InitCollateralBIXAmount; // 抵押品合约BIX数量

    uint public TotalBixAmountWithWhiteAddress;

    uint public OneYearSec = 60 * 60 * 24 * 365;

    uint public MarginCallExpiredDate; // 追加保证金到期时间

    bool public isBreakContract = false;  // 是否违约


    struct INVESTER {
        address addr;
        uint share;
    }


    INVESTER[] public INVEST_ADDRESS;

    mapping(address => uint) public White_Address;

    address[] public  r_addr_list;
    uint[] public  r_bix_list;

    address [] public real_address_list;
    uint [] public real_bix_amount_list;


    event RefundBIX(address r_addr, uint r_amount);

    // 开始认购
    event BondSubscriptionStarted(BONDSTATUS status, uint time);
    // 结束认购
    event BondSubscriptionEnd(BONDSTATUS status, uint time);
    // 追加保证金 添加追加数量
    event BondMarginCall(BONDSTATUS status, uint time, uint amount);
    // 追加保证金成功 添加追加数量
    event BondMarginCallDone(BONDSTATUS status, uint time, uint amount);
    // 斩仓
    event BondDefaulted(BONDSTATUS status, uint time);
    // 债券运行中
    event BondActive(BONDSTATUS status, uint time);
    // 债券到期
    event BondMaturity(BONDSTATUS status, uint time);
    // 债券失效
    event BondInactive(BONDSTATUS status, uint time);
    // 债券发行失败，添加 发行数量和收到数量
    event BondIssuedFailed(BONDSTATUS status, uint time, uint issued_amount, uint real_amount);

    // 计算应该归还的BIX
    event CalculateShouldReturnBix(uint amount);

    // 使用 债券合约赔付
    event PayWithBondContract(address addr, uint amount);

    // 使用 抵押品合约赔付
    event PayWithCollateralContract(address addr, uint amount);




    constructor(
        ERC20 _BondToken,
        ERC20 _BixToken,
        address _DepositAddress,
        address _CollateralAddress,
        string _BondName,
        string _IssuerName,
        uint _StartSubscribeDate,
        uint _EndSubscribeDate,
        uint _IssuedBondAmount,
        uint _BIXFaceValue,
        uint _AnnualInterestRate, //Interest Rate
        uint _Initial_BIX_GUSD_Price,
        uint _PeriodInYear, // 以年计
        uint _GratifyRate
    )public{

        require(_StartSubscribeDate < _EndSubscribeDate);

        BondToken = _BondToken;
        BixToken = _BixToken;

        collateralContract = Collateral(_CollateralAddress);
        CollateralAddress = _CollateralAddress;

        DepositAddress = _DepositAddress;
        BondName = _BondName;
        IssuerName = _IssuerName;

        StartSubscribeDate = _StartSubscribeDate;
        EndSubscribeDate = _EndSubscribeDate;
        IssuedBondAmount = _IssuedBondAmount;
        BIXFaceValue = _BIXFaceValue;
        PeriodInYear = get_sec_by_year(_PeriodInYear);

        //        Interest = SafeMath.div(SafeMath.mul(SafeMath.mul(_AnnualInterestRate, PeriodInYear), BIXFaceValue), 1 ether);
        Interest = SafeMath.div(SafeMath.mul(SafeMath.div(SafeMath.mul(_AnnualInterestRate, BIXFaceValue), 1 ether), _PeriodInYear), 1 ether);

        Initial_BIX_GUSD_Price = _Initial_BIX_GUSD_Price;


        IssuedOneBondGUSDValue = SafeMath.div(SafeMath.mul(BIXFaceValue, Initial_BIX_GUSD_Price), 1 ether);
        IssuedBIXValue = SafeMath.div(SafeMath.mul(IssuedBondAmount, BIXFaceValue), 1 ether);
        IssuedGUSDValue = SafeMath.div(SafeMath.mul(IssuedBIXValue, Initial_BIX_GUSD_Price), 1 ether);

        RequireBIXDepositAmount = SafeMath.mul(IssuedBIXValue, 2);
        DepositGUSDValue = SafeMath.div(SafeMath.mul(RequireBIXDepositAmount, Initial_BIX_GUSD_Price), 1 ether);

        BondBIXAmount = IssuedBIXValue;


        GratifyRate = _GratifyRate;

        BixConvertBondToken = SafeMath.div(BIXFaceValue, 1 ether);


        initInvesters();

        bondStatus = BONDSTATUS.SubscriptionStarted;
        emit BondSubscriptionStarted(bondStatus, time());


    }

    // 将年转化为秒
    function get_sec_by_year(uint _year) internal view returns (uint){

        return SafeMath.div(SafeMath.mul(_year, OneYearSec), 1 ether);
        //        return SafeMath.div(SafeMath.mul(OneYearSec, _year), 1 ether);

    }

    // 初始化认购投资人
    function initInvesters() internal {

        INVESTER memory i_1 = INVESTER({addr : 0xef52bf0a2e9ad6c3e79c5829d9207a598cc00b6c, share : 120});
        INVEST_ADDRESS.push(i_1);

        INVESTER memory i_2 = INVESTER({addr : 0xe7f20cccef02a8bef57a2c0b18a65812f2835be4, share : 60});
        INVEST_ADDRESS.push(i_2);

        INVESTER memory i_3 = INVESTER({addr : 0xf65cf1a9ddfb505e6fb477c85e2220c480efb106, share : 20});
        INVEST_ADDRESS.push(i_3);

        //
        //        INVESTER memory i_1 = INVESTER({addr : 0x13b70c93c7389144cfa1d374d28aa31ffcb4669d, share : 120});
        //        INVEST_ADDRESS.push(i_1);
        //
        //        INVESTER memory i_2 = INVESTER({addr : 0x64a463e6dd280f2a8c9051a189b2bee826ec859c, share : 60});
        //        INVEST_ADDRESS.push(i_2);
        //
        //        INVESTER memory i_3 = INVESTER({addr : 0xadd073007935ca702eec6f304f290db1f707cead, share : 20});
        //        INVEST_ADDRESS.push(i_3);


    }

    function time() public view returns (uint) {
        return block.timestamp;
    }


    // bond token 转账
    function transfer_bond_token(address target_address, uint send_bond_amount) internal {
        BondToken.transfer(target_address, SafeMath.mul(send_bond_amount, 1 ether));
    }

    // 单个 bix 转账
    function refund_bix(address addr, uint amount) internal {
        BixToken.transfer(addr, amount);

        emit RefundBIX(addr, amount);
    }

    // 批量 bix 转账
    function batch_refund_bix(address[] address_list, uint[] amount_list) internal {

        require(address_list.length == amount_list.length);
        for (uint i = 0; i < address_list.length; i++) {

            refund_bix(address_list[i], amount_list[i]);

        }

    }

    // 结束认购后6小时，还未开始发行
    // 或者 状态未 SubscriptionStarted 表明 start_bond 失败  允许创建者提取合约内BIX
    function claim_bix_with_not_start() onlyOwner public {

        require(block.timestamp > SafeMath.add(EndSubscribeDate, 6 hours));

        if (bondStatus == BONDSTATUS.IssuedFailed) {

            CurrentBIXAmount = BixToken.balanceOf(address(this));
            BixToken.transfer(msg.sender, CurrentBIXAmount);

        }
        if (bondStatus == BONDSTATUS.SubscriptionStarted) {
            CurrentBIXAmount = BixToken.balanceOf(address(this));
            BixToken.transfer(msg.sender, CurrentBIXAmount);
        }

    }






    // 债券到期4天后，允许创建者提取合约内BIX
    function claim_bix_with_maturity() onlyOwner public {
        // start_bond 成功后 MaturityDate 才会大于0
        require(MaturityDate > 0);
        require(block.timestamp >= SafeMath.add(MaturityDate, 4 days));
        CurrentBIXAmount = BixToken.balanceOf(address(this));
        BixToken.transfer(msg.sender, CurrentBIXAmount);
    }

    // 根据初始份额判断转出 bond token
    // target_address 当前地址
    // rated_share 当前地址所拥有的份额
    // real_bix_amount 当前地址实际打入合约的BIX数量
    function check_address_share_and_transfer_bond_token(uint rated_share, uint real_bix_amount, address target_address) internal {

        // 根据 当前地址所拥有的份额 计算 该地址应该打入的BIX数量
        uint share_to_bix_amount = SafeMath.mul(rated_share, BIXFaceValue);
        uint send_bond_amount = 0;
        // 判断 该地址应该打入的BIX数量 与 实际打入合约的BIX数量
        if (share_to_bix_amount == real_bix_amount) {
            // 相等，则按照
            send_bond_amount = SafeMath.div(real_bix_amount, BIXFaceValue);
            transfer_bond_token(target_address, send_bond_amount);

        } else {

            if (share_to_bix_amount > real_bix_amount) {
                // use real_bix_amount
                // transfer bond token to address
                send_bond_amount = SafeMath.div(real_bix_amount, BIXFaceValue);
                transfer_bond_token(target_address, send_bond_amount);

            } else {
                // refund part bix
                uint r_bix = SafeMath.sub(real_bix_amount, share_to_bix_amount);
                refund_bix(target_address, r_bix);

                // transfer bond token to address
                send_bond_amount = SafeMath.div(share_to_bix_amount, BIXFaceValue);
                transfer_bond_token(target_address, send_bond_amount);

            }

        }

    }


    function get_collateral_bix_amount() public view returns (uint){
        return BixToken.balanceOf(CollateralAddress);
    }

    // 将转入此合约BIX的钱包地址和相应数量传入此方法
    // 不在地址白名单内，将BIX转回
    // 在地址白名单内，计算BIX总和是否大于债券发行BIX数量的80%
    // 小于 80% 全部转回
    // 否则 判断份额，多出部分折算BIX转回
    //            少于部分折算 Bond token 转出
    function start_bond(address[] trans_bix_address_list, uint[] bix_amount_list) onlyOwner public {
        require(block.timestamp >= EndSubscribeDate);
        require(trans_bix_address_list.length == bix_amount_list.length);

        InitCollateralBIXAmount = BixToken.balanceOf(CollateralAddress);

        // 检查 充值地址打入的BIX 是否与 要求保证金BIX数量相等
        require(InitCollateralBIXAmount == RequireBIXDepositAmount);

        CurrentBIXAmount = BixToken.balanceOf(address(this));

        uint share = 0;

        for (uint i = 0; i < trans_bix_address_list.length; i++) {

            share = get_share_by_address(trans_bix_address_list[i]);
            if (share == 0) {

                // 退回不在白名单地址内打入的BIX
                refund_bix(trans_bix_address_list[i], bix_amount_list[i]);


            } else {

                // in white address
                TotalBixAmountWithWhiteAddress = SafeMath.add(TotalBixAmountWithWhiteAddress, bix_amount_list[i]);
                real_address_list.push(trans_bix_address_list[i]);
                real_bix_amount_list.push(bix_amount_list[i]);

            }

        }


        // 检查当前账户BIX数量 >= 白名单地址打入BIX总和
        require(CurrentBIXAmount >= TotalBixAmountWithWhiteAddress);

        // 判断 白名单地址打入BIX总和 是否符合 发行最低限额
        if (TotalBixAmountWithWhiteAddress >= SafeMath.div(SafeMath.mul(IssuedBIXValue, GratifyRate), 100)) {
            // 收到 BIX 满足 最小发行比例
            // 打 bond token 给 白名单地址

            for (uint v = 0; v < real_address_list.length; v++) {
                share = get_share_by_address(real_address_list[v]);

                check_address_share_and_transfer_bond_token(share, real_bix_amount_list[v], real_address_list[v]);
            }

            // 将白名单地址打入的BIX 转入 发行方地址
            BixToken.transfer(DepositAddress, TotalBixAmountWithWhiteAddress);

            // 实际认购份数 = 白名单转入 BIX 总和 / 每份BIX价值
            RealSubScriptionAmount = SafeMath.div(TotalBixAmountWithWhiteAddress, BIXFaceValue);

            // 实际发行价值 = 白名单转入 BIX 总和 * 发行时BIX_GUSD价格
            RealGUSDValue = SafeMath.div(SafeMath.mul(TotalBixAmountWithWhiteAddress, Initial_BIX_GUSD_Price), 1 ether);

            RealBIXAmount = TotalBixAmountWithWhiteAddress;

            // 从此时开始为计息日
            IssuedDate = time();

            // 到期日为计息日+周期时间
            MaturityDate = SafeMath.add(IssuedDate, PeriodInYear);

            bondStatus = BONDSTATUS.SubscriptionEnd;
            emit BondSubscriptionEnd(bondStatus, time());

            bondStatus = BONDSTATUS.Active;
            emit BondActive(bondStatus, time());


        } else {
            // 不满足发行比例 ，退回 BIX
            // refund all

            batch_refund_bix(real_address_list, real_bix_amount_list);

            bondStatus = BONDSTATUS.IssuedFailed;
            emit BondIssuedFailed(bondStatus, time(), IssuedBIXValue, TotalBixAmountWithWhiteAddress);


        }


    }


    // 根据地址获取初始份额，无则返回0
    function get_share_by_address(address target_address) public view returns (uint){

        uint res = 0;

        for (uint i; i < INVEST_ADDRESS.length; i++) {
            INVESTER storage invester = INVEST_ADDRESS[i];
            if (target_address == invester.addr) {

                res = invester.share;
            }
        }

        return res;

    }


    function get_invester_detail(uint index) public view returns (address, uint){
        INVESTER memory v = INVEST_ADDRESS[index];
        return (v.addr, v.share);
    }

    function get_invester_length() public view returns (uint){
        return INVEST_ADDRESS.length;
    }

    // 每 12 小时 检查市值
    function check_price(uint current_bix_gusd_price) onlyOwner public {
        // 检查债券是否发行
        require(bondStatus != BONDSTATUS.IssuedFailed);
        // 检查债券是否失效
        require(bondStatus != BONDSTATUS.Inactive);
        // 检查债券是否到期
        require(bondStatus != BONDSTATUS.Maturity);
        // 检查债券是否斩仓
        require(bondStatus != BONDSTATUS.Defaulted);

        CurrentBIXAmount = BixToken.balanceOf(CollateralAddress);
        CurrentBIX_GUSD_Price = current_bix_gusd_price;
        CurrentOneBondGUSDValue = SafeMath.div(SafeMath.mul(BIXFaceValue, CurrentBIX_GUSD_Price), 1 ether);
        CurrentBIXValue = SafeMath.div(SafeMath.mul(CurrentOneBondGUSDValue, BIXFaceValue), 1 ether);
        CurrentGUSDValue = SafeMath.div(SafeMath.mul(CurrentBIXAmount, CurrentBIX_GUSD_Price), 1 ether);
        CurrentDepositGUSDValue = SafeMath.div(SafeMath.mul(CurrentBIXAmount, Initial_BIX_GUSD_Price), 1 ether);

        // 计算 bond token 兑 bix 汇率
        calculate_bond_token_to_bix_rate(current_bix_gusd_price);

        // 判断当前状态是否为 MarginCall
        if (bondStatus == BONDSTATUS.MarginCall) {
            // 判断 追加保证金是否到账
            if (CurrentBIXAmount >= SafeMath.add(CashDepositAmount, PrevBIXAmount)) {
                // 追加保证金到账，修改合约状态，
                bondStatus = BONDSTATUS.Active;
                emit BondMarginCallDone(bondStatus, time(), CashDepositAmount);
                // 重新赋值上一次BIX数量
                PrevBIXAmount = CurrentBIXAmount;
                // 重新赋值追加数量
                CashDepositAmount = 0;
            } else {
                // 追加保证金未到账，检查追加保证金到期时间
                if (time() > MarginCallExpiredDate) {
                    // 到期未追加 斩仓
                    bondStatus = BONDSTATUS.Defaulted;
                    isBreakContract = true;
                    // 违约
                    emit BondDefaulted(bondStatus, time());
                }
            }

        } else {
            // 当前状态不是 MarginCall 继续
        }

        uint curren_value_rate = SafeMath.div(SafeMath.mul(CurrentGUSDValue, 1 ether), RealGUSDValue);

        if (curren_value_rate > 2 ether) {
            // more than 200%
            // 计算 允许 发行方能提取的BIX 数量
            // 判断 当前抵押品数量 大于 实际发行BIX的2倍
            if (CurrentBIXAmount > InitCollateralBIXAmount) {
                // 设置 抵押品合约中允许发行方提取的数额
                collateralContract.set_allow_withdraw_amount(SafeMath.sub(CurrentBIXAmount, InitCollateralBIXAmount));
            } else {
                // 当前抵押品数量 等于 实际发行BIX的2倍
            }

        } else {

            if (curren_value_rate >= 1.5 ether) {
                // more than 150%
                // do nothing
            } else {

                if (curren_value_rate <= 1.25 ether) {
                    // less than 125%
                    bondStatus = BONDSTATUS.Defaulted;
                    emit BondDefaulted(bondStatus, time());

                } else {
                    // calculate CashDeposit Amount

                    CashDepositAmount = SafeMath.sub(SafeMath.div(SafeMath.mul(CurrentDepositGUSDValue, 1 ether), CurrentBIX_GUSD_Price), CurrentBIXAmount);

                    if (bondStatus == BONDSTATUS.MarginCall) {
                        // 如果已经是追加状态
                        // 上面处理过了
                    } else {
                        // 设置追加保证金到期时间 = 当前时间 + 3 天
                        MarginCallExpiredDate = SafeMath.add(time(), 3 days);

                        // 记录抵押品合约当前BIX
                        PrevBIXAmount = CurrentBIXAmount;

                        bondStatus = BONDSTATUS.MarginCall;
                        emit BondMarginCallDone(bondStatus, time(), CashDepositAmount);

                    }


                }
            }


        }

        // 当前时间大于等于到期时间，则是最后一次检查价格
        if (time() >= MaturityDate) {
            bondStatus = BONDSTATUS.Maturity;
            emit BondMaturity(bondStatus, time());

        }


    }

    function calculate_bond_token_to_bix_rate(uint current_bix_gusd_price) internal {
        if (Initial_BIX_GUSD_Price > current_bix_gusd_price) {

            BixConvertBondToken = SafeMath.div(SafeMath.div(RealGUSDValue, current_bix_gusd_price), RealSubScriptionAmount);

        } else {

            BixConvertBondToken = SafeMath.div(BIXFaceValue, 1 ether);
        }
    }


    // 斩仓时传入当前 bond token 持有者的地址和相应数量数组 ， 按比例转回bix
    function refund_with_close_position(address[] hold_bond_token_address_list, uint[] bond_amount_list) onlyOwner public {
        require(bondStatus == BONDSTATUS.Defaulted);
        for (uint u = 0; u < hold_bond_token_address_list.length; u++) {
            collateralContract.pay_by_bond_contract(hold_bond_token_address_list[u], SafeMath.mul(BixConvertBondToken, bond_amount_list[u]));
        }

        // 赔付玩后，检查是否有违约
        if (isBreakContract) {
            // 部分还给发行方，部分转给vocean
            collateralContract.refundPartCollateral();

        } else {
            collateralContract.refundAllCollateral();
        }

    }


    // 债券到期 传入当前 bond token 持有者的地址和相应数量数组 ,按比例转回bix
    // 发行方 在到期后 3 天内还回BIX,不然使用抵押品BIX赔付
    function maturity_refund(address[] hold_bond_token_address_list, uint[] bond_amount_list) onlyOwner public {
        require(block.timestamp > MaturityDate);
        require(bondStatus == BONDSTATUS.Maturity);
        // 判断 当前BIX数
        if (BixToken.balanceOf(address(this)) >= ShouldReturnBixAmount) {

            // 使用债券合约内BIX赔付
            for (uint u = 0; u < hold_bond_token_address_list.length; u++) {

                uint pay_amount = SafeMath.mul(SafeMath.add(SafeMath.div(Interest, 1 ether), BixConvertBondToken), bond_amount_list[u]);
                BixToken.transfer(hold_bond_token_address_list[u], pay_amount);

                emit PayWithBondContract(hold_bond_token_address_list[u], pay_amount);
            }

            // 赔付玩后，检查是否有违约
            if (isBreakContract) {
                // 部分还给发行方，部分转给vocean
                collateralContract.refundPartCollateral();

            } else {
                collateralContract.refundAllCollateral();
            }

        } else {

            // 债券合约内BIX 不够
            // 判断是否过了3天
            if (SafeMath.sub(block.timestamp, MaturityDate) > 3 days) {
                // 使用 抵押品BIX赔付
                for (uint t = 0; t < hold_bond_token_address_list.length; t++) {
                    uint collateral_pay_amount = SafeMath.mul(SafeMath.add(SafeMath.div(Interest, 1 ether), BixConvertBondToken), bond_amount_list[t]);
                    collateralContract.pay_by_bond_contract(hold_bond_token_address_list[t], collateral_pay_amount);
                    emit PayWithCollateralContract(hold_bond_token_address_list[t], collateral_pay_amount);
                }

                // 赔付玩后，检查是否有违约
                if (isBreakContract) {
                    // 部分还给发行方，部分转给vocean
                    collateralContract.refundPartCollateral();

                } else {
                    collateralContract.refundAllCollateral();
                }

            } else {
                // 未超过三天，继续等待

            }

        }


    }

    // 债券到期后，计算发行方应该还回的BIX数
    function calculate_should_return_bix(address[] hold_bond_token_address_list, uint[] bond_amount_list) onlyOwner public {

        require(block.timestamp > MaturityDate);
        require(bondStatus == BONDSTATUS.Maturity);

        for (uint u = 0; u < hold_bond_token_address_list.length; u++) {

            ShouldReturnBixAmount = SafeMath.add(SafeMath.mul(SafeMath.add(SafeMath.div(Interest, 1 ether), BixConvertBondToken), bond_amount_list[u]), ShouldReturnBixAmount);

        }

        emit CalculateShouldReturnBix(ShouldReturnBixAmount);


    }


}