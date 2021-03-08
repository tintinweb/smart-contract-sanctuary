/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity ^0.4.24;/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
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
}/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}/**
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
}/**
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
}/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}// SPDX-License-Identifier: MIT





contract GovManager is Pausable {
    address public GovernerContract;

    modifier onlyOwnerOrGov() {
        require(msg.sender == owner || msg.sender == GovernerContract, "Authorization Error");
        _;
    }

    function setGovernerContract(address _address) external onlyOwnerOrGov{
        GovernerContract = _address;
    }

    constructor() public {
        GovernerContract = address(0);
    }
}// SPDX-License-Identifier: MIT







contract ERC20Helper is GovManager {
    event TransferOut(uint256 Amount, address To, address Token);
    event TransferIn(uint256 Amount, address From, address Token);
    modifier TestAllownce(
        address _token,
        address _owner,
        uint256 _amount
    ) {
        require(
            ERC20(_token).allowance(_owner, address(this)) >= _amount,
            "no allowance"
        );
        _;
    }

    function TransferToken(
        address _Token,
        address _Reciver,
        uint256 _Amount
    ) internal {
        uint256 OldBalance = CheckBalance(_Token, address(this));
        emit TransferOut(_Amount, _Reciver, _Token);
        ERC20(_Token).transfer(_Reciver, _Amount);
        require(
            (SafeMath.add(CheckBalance(_Token, address(this)), _Amount)) == OldBalance
                ,
            "recive wrong amount of tokens"
        );
    }

    function CheckBalance(address _Token, address _Subject)
        internal
        view
        returns (uint256)
    {
        return ERC20(_Token).balanceOf(_Subject);
    }

    function TransferInToken(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal TestAllownce(_Token, _Subject, _Amount) {
        require(_Amount > 0);
        uint256 OldBalance = CheckBalance(_Token, address(this));
        ERC20(_Token).transferFrom(_Subject, address(this), _Amount);
        emit TransferIn(_Amount, _Subject, _Token);
        require(
            (SafeMath.add(OldBalance, _Amount)) ==
                CheckBalance(_Token, address(this)),
            "recive wrong amount of tokens"
        );
    }
}// SPDX-License-Identifier: MIT



//True POZ Token will have this, 
interface IPOZBenefit {
    function IsPOZHolder(address _Subject) external view returns(bool);
}// SPDX-License-Identifier: MIT






contract PozBenefit is ERC20Helper {
    constructor() public {
        PozFee = 15; // *10000
        PozTimer = 1000; // *10000
    
       // POZ_Address = address(0x0);
       // POZBenefit_Address = address(0x0);
    }

    uint256 public PozFee; // the fee for the first part of the pool
    uint256 public PozTimer; //the timer for the first part fo the pool
    
    modifier PercentCheckOk(uint256 _percent) {
        if (_percent < 10000) _;
        else revert("Not in range");
    }
    modifier LeftIsBigger(uint256 _left, uint256 _right) {
        if (_left > _right) _;
        else revert("Not bigger");
    }

    function SetPozTimer(uint256 _pozTimer)
        public
        onlyOwnerOrGov
        PercentCheckOk(_pozTimer)
    {
        PozTimer = _pozTimer;
    }

    
}// SPDX-License-Identifier: MIT





contract ETHHelper is PozBenefit {
    constructor() public {
        IsPayble = false;
    }

    modifier ReceivETH(uint256 msgValue, address msgSender, uint256 _MinETHInvest) {
        require(msgValue >= _MinETHInvest, "Send ETH to invest");
        emit TransferInETH(msgValue, msgSender);
        _;
    }

    //@dev not/allow contract to receive funds
    function() public payable {
        if (!IsPayble) revert();
    }

    event TransferOutETH(uint256 Amount, address To);
    event TransferInETH(uint256 Amount, address From);

    bool public IsPayble;
 
    function SwitchIsPayble() public onlyOwner {
        IsPayble = !IsPayble;
    }

    function TransferETH(address _Reciver, uint256 _ammount) internal {
        emit TransferOutETH(_ammount, _Reciver);
        uint256 beforeBalance = address(_Reciver).balance;
        _Reciver.transfer(_ammount);
        require(
            SafeMath.add(beforeBalance, _ammount) == address(_Reciver).balance,
            "The transfer did not complite"
        );
    }
 
}// SPDX-License-Identifier: MIT



//For whitelist, 
interface IWhiteList {
    function Check(address _Subject, uint256 _Id) external view returns(uint);
    function Register(address _Subject,uint256 _Id,uint256 _Amount) external;
    function IsNeedRegister(uint256 _Id) external view returns(bool);
}// SPDX-License-Identifier: MIT






contract Manageable is ETHHelper {
    constructor() public {
        Fee = 20; // *10000
        //MinDuration = 0; //need to set
        //PoolPrice = 0; // Price for create a pool
        MaxDuration = 60 * 60 * 24 * 30 * 6; // half year
        MinETHInvest = 10000; // for percent calc
        MaxETHInvest = 100 * 10**18; // 100 eth per wallet
        //WhiteList_Address = address(0x0);
    }

    mapping(address => uint256) FeeMap;
    //@dev for percent use uint16
    uint256 public Fee; //the fee for the pool
    uint256 public MinDuration; //the minimum duration of a pool, in seconds
    uint256 public MaxDuration; //the maximum duration of a pool from the creation, in seconds
    uint256 public PoolPrice;
    uint256 public MinETHInvest;
    uint256 public MaxETHInvest;
    address public WhiteList_Address; //The address of the Whitelist contract

    bool public IsTokenFilterOn;
    uint256 public TokenWhitelistId;
    uint256 public MCWhitelistId; // Main Coin WhiteList ID

    function SwapTokenFilter() public onlyOwner {
        IsTokenFilterOn = !IsTokenFilterOn;
    }

    function setTokenWhitelistId(uint256 _whiteListId) external onlyOwnerOrGov{
        TokenWhitelistId = _whiteListId;
    }

    function setMCWhitelistId(uint256 _whiteListId) external onlyOwnerOrGov{
        MCWhitelistId = _whiteListId;
    }

    function IsValidToken(address _address) public view returns (bool) {
        return !IsTokenFilterOn || (IWhiteList(WhiteList_Address).Check(_address, TokenWhitelistId) > 0);
    }

    function IsERC20Maincoin(address _address) public view returns (bool) {
        return !IsTokenFilterOn || IWhiteList(WhiteList_Address).Check(_address, MCWhitelistId) > 0;
    }
    
    function SetWhiteList_Address(address _WhiteList_Address) public onlyOwnerOrGov {
        WhiteList_Address = _WhiteList_Address;
    }

    function SetMinMaxETHInvest(uint256 _MinETHInvest, uint256 _MaxETHInvest)
        public
        onlyOwnerOrGov
    {
        MinETHInvest = _MinETHInvest;
        MaxETHInvest = _MaxETHInvest;
    }

    function SetMinMaxDuration(uint256 _minDuration, uint256 _maxDuration)
        public
        onlyOwnerOrGov
    {
        MinDuration = _minDuration;
        MaxDuration = _maxDuration;
    }

    function SetPoolPrice(uint256 _PoolPrice) public onlyOwnerOrGov {
        PoolPrice = _PoolPrice;
    }

    function SetFee(uint256 _fee)
        public
        onlyOwnerOrGov
        PercentCheckOk(_fee)
        LeftIsBigger(_fee, PozFee)
    {
        Fee = _fee;
    }

    function SetPOZFee(uint256 _fee)
        public
        onlyOwnerOrGov
        PercentCheckOk(_fee)
        LeftIsBigger(Fee, _fee)
    {
        PozFee = _fee;
    }

    
}// SPDX-License-Identifier: MIT






contract Pools is Manageable {
    event NewPool(address token, uint256 id);
    event FinishPool(uint256 id);
    event PoolUpdate(uint256 id);

    constructor() public {
        //  poolsCount = 0; //Start with 0
    }

    uint256 public poolsCount; // the ids of the pool
    mapping(uint256 => Pool) public pools; //the id of the pool with the data
    mapping(address => uint256[]) public poolsMap; //the address and all of the pools id's
    struct Pool {
        PoolBaseData BaseData;
        PoolMoreData MoreData;
    }
    struct PoolBaseData {
        address Token; //the address of the erc20 toke for sale
        address Creator; //the project owner
        uint256 FinishTime; //Until what time the pool is active
        uint256 Rate; //for eth Wei, in token, by the decemal. the cost of 1 token
        uint256 POZRate; //the rate for the until OpenForAll, if the same as Rate , OpenForAll = StartTime .
        address Maincoin; // on adress.zero = ETH
        uint256 StartAmount; //The total amount of the tokens for sale
    }
    struct PoolMoreData {
        uint64 LockedUntil; // true - the investors getting the tokens after the FinishTime. false - intant deal
        uint256 Lefttokens; // the ammount of tokens left for sale
        uint256 StartTime; // the time the pool open //TODO Maybe Delete this?
        uint256 OpenForAll; // The Time that all investors can invest
        uint256 UnlockedTokens; //for locked pools
        uint256 WhiteListId; // 0 is turn off, the Id of the whitelist from the contract.
        bool TookLeftOvers; //The Creator took the left overs after the pool finished
        bool Is21DecimalRate; //If true, the rate will be rate*10^-21
    }

    function isPoolLocked(uint256 _id) public view returns(bool){
        return pools[_id].MoreData.LockedUntil > now;
    }

    //create a new pool
    function CreatePool(
        address _Token, //token to sell address
        uint256 _FinishTime, //Until what time the pool will work
        uint256 _Rate, //the rate of the trade
        uint256 _POZRate, //the rate for POZ Holders, how much each token = main coin
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        uint64 _LockedUntil, //False = DSP or True = TLP
        address _MainCoin, // address(0x0) = ETH, address of main token
        bool _Is21Decimal, //focus the for smaller tokens.
        uint256 _Now, //Start Time - can be 0 to not change current flow
        uint256 _WhiteListId // the Id of the Whitelist contract, 0 For turn-off
    ) public payable whenNotPaused {
        require(msg.value >= PoolPrice, "Need to pay for the pool");
        require(IsValidToken(_Token), "Need Valid ERC20 Token"); //check if _Token is ERC20
        require(
            _MainCoin == address(0x0) || IsERC20Maincoin(_MainCoin),
            "Main coin not in list"
        );
        require(_FinishTime  < SafeMath.add(MaxDuration, now), "Pool duration can't be that long");
        require(_LockedUntil < SafeMath.add(MaxDuration, now) , "Locked value can't be that long");
        require(
            _Rate <= _POZRate,
            "POZ holders need to have better price (or the same)"
        );
        require(_POZRate > 0, "It will not work");
        if (_Now < now) _Now = now;
        require(
            SafeMath.add(now, MinDuration) <= _FinishTime,
            "Need more then MinDuration"
        ); // check if the time is OK
        TransferInToken(_Token, msg.sender, _StartAmount);
        uint256 Openforall =
            (_WhiteListId == 0) 
                ? _Now //and this
                : SafeMath.add(
                    SafeMath.div(
                        SafeMath.mul(SafeMath.sub(_FinishTime, _Now), PozTimer),
                        10000
                    ),
                    _Now
                );
        //register the pool
        pools[poolsCount] = Pool(
            PoolBaseData(
                _Token,
                msg.sender,
                _FinishTime,
                _Rate,
                _POZRate,
                _MainCoin,
                _StartAmount
            ),
            PoolMoreData(
                _LockedUntil,
                _StartAmount,
                _Now,
                Openforall,
                0,
                _WhiteListId,
                false,
                _Is21Decimal
            )
        );
        poolsMap[msg.sender].push(poolsCount);
        emit NewPool(_Token, poolsCount);
        poolsCount = SafeMath.add(poolsCount, 1); //joke - overflowfrom 0 on int256 = 1.16E77
    }
}// SPDX-License-Identifier: MIT




contract PoolsData is Pools {
    enum PoolStatus {Created, Open, PreMade, OutOfstock, Finished, Close} //the status of the pools

    modifier PoolId(uint256 _id) {
        require(_id < poolsCount, "Wrong pool id, Can't get Status");
        _;
    }

    function GetMyPoolsId() public view returns (uint256[]) {
        return poolsMap[msg.sender];
    }

    function GetPoolBaseData(uint256 _Id)
        public
        view
        PoolId(_Id)
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            pools[_Id].BaseData.Token,
            pools[_Id].BaseData.Creator,
            pools[_Id].BaseData.FinishTime,
            pools[_Id].BaseData.Rate,
            pools[_Id].BaseData.POZRate,
            pools[_Id].BaseData.StartAmount
        );
    }

    function GetPoolMoreData(uint256 _Id)
        public
        view
        PoolId(_Id)
        returns (
            uint64,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            pools[_Id].MoreData.LockedUntil,
            pools[_Id].MoreData.Lefttokens,
            pools[_Id].MoreData.StartTime,
            pools[_Id].MoreData.OpenForAll,
            pools[_Id].MoreData.UnlockedTokens,
            pools[_Id].MoreData.Is21DecimalRate
        );
    }

    function GetPoolExtraData(uint256 _Id)
        public
        view
        PoolId(_Id)
        returns (
            bool,
            uint256,
            address
        )
    {
        return (
            pools[_Id].MoreData.TookLeftOvers,
            pools[_Id].MoreData.WhiteListId,
            pools[_Id].BaseData.Maincoin
        );
    }

    function IsReadyWithdrawLeftOvers(uint256 _PoolId)
        public
        view
        PoolId(_PoolId)
        returns (bool)
    {
        return
            pools[_PoolId].BaseData.FinishTime <= now &&
            pools[_PoolId].MoreData.Lefttokens > 0 &&
            !pools[_PoolId].MoreData.TookLeftOvers;
    }

    //@dev no use of revert to make sure the loop will work
    function WithdrawLeftOvers(uint256 _PoolId) public PoolId(_PoolId) returns (bool) {
        //pool is finished + got left overs + did not took them
        if (IsReadyWithdrawLeftOvers(_PoolId)) {
            pools[_PoolId].MoreData.TookLeftOvers = true;
            TransferToken(
                pools[_PoolId].BaseData.Token,
                pools[_PoolId].BaseData.Creator,
                pools[_PoolId].MoreData.Lefttokens
            );
            return true;
        }
        return false;
    }

    //calculate the status of a pool
    function GetPoolStatus(uint256 _id)
        public
        view
        PoolId(_id)
        returns (PoolStatus)
    {
        //Don't like the logic here - ToDo Boolean checks (truth table)
        if (now < pools[_id].MoreData.StartTime) return PoolStatus.PreMade;
        if (
            now < pools[_id].MoreData.OpenForAll &&
            pools[_id].MoreData.Lefttokens > 0
        ) {
            //got tokens + only poz investors
            return (PoolStatus.Created);
        }
        if (
            now >= pools[_id].MoreData.OpenForAll &&
            pools[_id].MoreData.Lefttokens > 0 &&
            now < pools[_id].BaseData.FinishTime
        ) {
            //got tokens + all investors
            return (PoolStatus.Open);
        }
        if (
            pools[_id].MoreData.Lefttokens == 0 &&
            isPoolLocked(_id) &&
            now < pools[_id].BaseData.FinishTime
        ) //no tokens on locked pool, got time
        {
            return (PoolStatus.OutOfstock);
        }
        if (
            pools[_id].MoreData.Lefttokens == 0 && !isPoolLocked(_id)
        ) //no tokens on direct pool
        {
            return (PoolStatus.Close);
        }
        if (
            now >= pools[_id].BaseData.FinishTime &&
            !isPoolLocked(_id)
        ) {
            // After finish time - not locked
            if (pools[_id].MoreData.TookLeftOvers) return (PoolStatus.Close);
            return (PoolStatus.Finished);
        }
        if (
            (pools[_id].MoreData.TookLeftOvers ||
                pools[_id].MoreData.Lefttokens == 0) &&
            (pools[_id].MoreData.UnlockedTokens +
                pools[_id].MoreData.Lefttokens ==
                pools[_id].BaseData.StartAmount)
        ) return (PoolStatus.Close);
        return (PoolStatus.Finished);
    }
}// SPDX-License-Identifier: MIT





contract Invest is PoolsData {
    event NewInvestorEvent(uint256 Investor_ID, address Investor_Address);

    modifier CheckTime(uint256 _Time) {
        require(now >= _Time, "Pool not open yet");
        _;
    }

    //using SafeMath for uint256;
    constructor() public {
        //TotalInvestors = 0;
    }

    //Investorsr Data
    uint256 internal TotalInvestors;
    mapping(uint256 => Investor) Investors;
    mapping(address => uint256[]) InvestorsMap;
    struct Investor {
        uint256 Poolid; //the id of the pool, he got the rate info and the token, check if looked pool
        address InvestorAddress; //
        uint256 MainCoin; //the amount of the main coin invested (eth/dai), calc with rate
        uint256 TokensOwn; //the amount of Tokens the investor needto get from the contract
        uint256 InvestTime; //the time that investment made
    }

    function getTotalInvestor() external view returns(uint256){
        return TotalInvestors;
    }
    
    //@dev Send in wei
    function InvestETH(uint256 _PoolId)
        external
        payable
        ReceivETH(msg.value, msg.sender, MinETHInvest)
        whenNotPaused
        CheckTime(pools[_PoolId].MoreData.StartTime)
    {
        require(_PoolId < poolsCount, "Wrong pool id, InvestETH fail");
        require(pools[_PoolId].BaseData.Maincoin == address(0x0), "Pool is not for ETH");
        require(
            msg.value >= MinETHInvest && msg.value <= MaxETHInvest,
            "Investment amount not valid"
        );
        require(
            msg.sender == tx.origin && !isContract(msg.sender),
            "Some thing wrong with the msgSender"
        );
        uint256 ThisInvestor = NewInvestor(msg.sender, msg.value, _PoolId);
        uint256 Tokens = CalcTokens(_PoolId, msg.value, msg.sender);
        
        TokenAllocate(_PoolId, ThisInvestor, Tokens);

        uint256 EthMinusFee =
            SafeMath.div(
                SafeMath.mul(msg.value, SafeMath.sub(10000, CalcFee(_PoolId))),
                10000
            );
        // send money to project owner - the fee stays on contract
        TransferETH(pools[_PoolId].BaseData.Creator, EthMinusFee); 
        RegisterInvest(_PoolId, Tokens);
    }

    function InvestERC20(uint256 _PoolId, uint256 _Amount)
        external
        whenNotPaused
        CheckTime(pools[_PoolId].MoreData.StartTime)
    {
        require(_PoolId < poolsCount, "Wrong pool id, InvestERC20 fail");
        require(
            pools[_PoolId].BaseData.Maincoin != address(0x0),
            "Pool is for ETH, use InvetETH"
        );
        require(_Amount > 10000, "Need invest more then 10000");
        require(
            msg.sender == tx.origin && !isContract(msg.sender),
            "Some thing wrong with the msgSender"
        );
        TransferInToken(pools[_PoolId].BaseData.Maincoin, msg.sender, _Amount);
        uint256 ThisInvestor = NewInvestor(msg.sender, _Amount, _PoolId);
        uint256 Tokens = CalcTokens(_PoolId, _Amount, msg.sender);

        TokenAllocate(_PoolId, ThisInvestor, Tokens);

        uint256 RegularFeePay =
            SafeMath.div(SafeMath.mul(_Amount, CalcFee(_PoolId)), 10000);

        uint256 RegularPaymentMinusFee = SafeMath.sub(_Amount, RegularFeePay);
        FeeMap[pools[_PoolId].BaseData.Maincoin] = SafeMath.add(
            FeeMap[pools[_PoolId].BaseData.Maincoin],
            RegularFeePay
        );
        TransferToken(
            pools[_PoolId].BaseData.Maincoin,
            pools[_PoolId].BaseData.Creator,
            RegularPaymentMinusFee
        ); // send money to project owner - the fee stays on contract
        RegisterInvest(_PoolId, Tokens);
    }

    function TokenAllocate(uint256 _PoolId, uint256 _ThisInvestor, uint256 _Tokens) internal {
        if (isPoolLocked(_PoolId)) {
            Investors[_ThisInvestor].TokensOwn = SafeMath.add(
                Investors[_ThisInvestor].TokensOwn,
                _Tokens
            );
        } else {
            // not locked, will transfer the tokens
            TransferToken(pools[_PoolId].BaseData.Token, Investors[_ThisInvestor].InvestorAddress, _Tokens);
        }
    }

    function RegisterInvest(uint256 _PoolId, uint256 _Tokens) internal {
        require(
            _Tokens <= pools[_PoolId].MoreData.Lefttokens,
            "Not enough tokens in the pool"
        );
        pools[_PoolId].MoreData.Lefttokens = SafeMath.sub(
            pools[_PoolId].MoreData.Lefttokens,
            _Tokens
        );
        if (pools[_PoolId].MoreData.Lefttokens == 0) emit FinishPool(_PoolId);
        else emit PoolUpdate(_PoolId);
    }

    function NewInvestor(
        address _Sender,
        uint256 _Amount,
        uint256 _Pid
    ) internal returns (uint256) {
        Investors[TotalInvestors] = Investor(
            _Pid,
            _Sender,
            _Amount,
            0,
            block.timestamp
        );
        InvestorsMap[msg.sender].push(TotalInvestors);
        emit NewInvestorEvent(TotalInvestors, _Sender);
        TotalInvestors = SafeMath.add(TotalInvestors, 1);
        return SafeMath.sub(TotalInvestors, 1);
    }

    function CalcTokens(
        uint256 _Pid,
        uint256 _Amount,
        address _Sender
    ) internal returns (uint256) {
        uint256 msgValue = _Amount;
        uint256 result = 0;
        if (GetPoolStatus(_Pid) == PoolStatus.Created) {
            IsWhiteList(_Sender, pools[_Pid].MoreData.WhiteListId, _Amount);
            result = SafeMath.mul(msgValue, pools[_Pid].BaseData.POZRate);
        }
        if (GetPoolStatus(_Pid) == PoolStatus.Open) {
            result = SafeMath.mul(msgValue, pools[_Pid].BaseData.Rate);
        }
        if (result >= 10**21) {
            if (pools[_Pid].MoreData.Is21DecimalRate) {
                result = SafeMath.div(result, 10**21);
            }
            return result;
        }
        revert("Wrong pool status to CalcTokens");
    }

    function CalcFee(uint256 _Pid) internal view returns (uint256) {
        if (GetPoolStatus(_Pid) == PoolStatus.Created) {
            return PozFee;
        }
        if (GetPoolStatus(_Pid) == PoolStatus.Open) {
            return Fee;
        }
        //will not get here, will fail on CalcTokens
    }

    //@dev use it with  require(msg.sender == tx.origin)
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    //  no need register - will return true or false base on Check
    //  if need register - revert or true
    function IsWhiteList(
        address _Investor,
        uint256 _Id,
        uint256 _Amount
    ) internal returns (bool) {
        if (_Id == 0) return true; //turn-off
        IWhiteList(WhiteList_Address).Register(_Investor, _Id, _Amount); //will revert if fail
        return true;
    }
}// SPDX-License-Identifier: MIT





contract InvestorData is Invest {
    function IsReadyWithdrawInvestment(uint256 _id) public view returns (bool) {
        return
            _id <= TotalInvestors &&
            Investors[_id].TokensOwn > 0 &&
            pools[Investors[_id].Poolid].MoreData.LockedUntil <= now;
    }

    function WithdrawInvestment(uint256 _id) public returns (bool) {
        if (IsReadyWithdrawInvestment(_id)) {
            uint256 temp = Investors[_id].TokensOwn;
            Investors[_id].TokensOwn = 0;
            TransferToken(
                pools[Investors[_id].Poolid].BaseData.Token,
                Investors[_id].InvestorAddress,
                temp
            );
            pools[Investors[_id].Poolid].MoreData.UnlockedTokens = SafeMath.add(
                pools[Investors[_id].Poolid].MoreData.UnlockedTokens,
                temp
            );

            return true;
        }
        return false;
    }

    //Give all the id's of the investment  by sender address
    function GetMyInvestmentIds() public view returns (uint256[]) {
        return InvestorsMap[msg.sender];
    }

    function GetInvestmentData(uint256 _id)
        public
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            Investors[_id].Poolid,
            Investors[_id].InvestorAddress,
            Investors[_id].MainCoin,
            Investors[_id].TokensOwn,
            Investors[_id].InvestTime
        );
    }
}// SPDX-License-Identifier: MIT




contract ThePoolz is InvestorData {
    constructor() public {    }

    function WithdrawETHFee(address _to) public onlyOwner {
        _to.transfer(address(this).balance); // keeps only fee eth on contract //To Do need to take 16% to burn!!!
    }

    function WithdrawERC20Fee(address _Token, address _to) public onlyOwner {
        uint256 temp = FeeMap[_Token];
        FeeMap[_Token] = 0;
        TransferToken(_Token, _to, temp);
    }
    
}