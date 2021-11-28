//SourceUnit: Community.sol


pragma solidity >=0.5.0;

contract Initializable {


    bool private _initialized;


    bool private _initializing;


     //|| _isConstructor()
    modifier initializer() {
        require(_initializing  || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    function _isConstructor() private view returns (bool) {
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Verifiable is Ownable{

    mapping ( address => bool) public isAuthAddress;

    modifier KRejectContractCall() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "Sender Is Contract" );
        _;
    }

    modifier KDelegateMethod() {
        require(isAuthAddress[msg.sender], "PermissionDeny");
        _;
    }


    function KAuthAddress(address user,bool isAuth) external  onlyOwner returns (bool) {
        isAuthAddress[user] = isAuth;
        return true;
    }

}

contract Time is Ownable{


    function timestempZero() internal view returns (uint) {
        return timestemp() / 1 days * 1 days;
    }



    function timestemp() internal view returns (uint) {
        return now;
    }

}

interface IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface iMine{
       function changePower(address owner,uint amount ,bool isAdd,uint powerSource) external;
}

interface IJustswapFactory {
  function getExchange(address token) external view returns (address payable);
  function getToken(address token) external view returns (address);
}

interface IJustswapExchange {

 function tokenToExchangeTransferInput(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_trx_bought,
    uint256 deadline,
    address recipient,
    address exchange_addr)
    external returns (uint256);

  function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

  function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
}

interface iPin{

   function getStallPowerPerUsdt() external view returns(uint);
}

contract Community is Initializable,Verifiable,Time{

    event Destory(address indexed owner,uint256 time,uint256 amount,uint256 power);
    event Convert(address indexed owner,uint256 time,uint256 usdtAmount,uint256 tokenAmount,uint256 power,address receiver);

    mapping(address => bool) internal validTokens;
    mapping(address => uint) internal defaultPrices;
    mapping(address => address) internal exchanges;
    mapping(address => address) internal receivers;

    IERC20 internal usdtToken;

    iMine internal mineModule;

    IERC20 internal pinToken;

    iPin internal pinModule;

    address constant internal BURN_ADDRESS = address(0xdead);

    mapping(address =>uint256) internal totalConvertAmounts;
    mapping(address =>mapping(uint256 => uint256)) internal todayConvertAmount;

    uint256 internal everyDayLimit;
    uint256 internal historyLimit;

    IJustswapFactory internal factory;

    bool public isStart;

    function initialize(
        address _usdtToken,
        address _mineModule,
        address _pinToken,
        address _pinModule,
        address _factory,
        address _ownerAddress) public initializer {

        everyDayLimit = 2000e6;
        historyLimit = 20000e6;
        usdtToken = IERC20(_usdtToken);
        mineModule = iMine(_mineModule);
        pinToken = IERC20(_pinToken);
        pinModule = iPin(_pinModule);

        if( _factory != address(0)){
            factory = IJustswapFactory(_factory);

            address usdtExchangeAddress = factory.getExchange(_usdtToken);
            require(usdtExchangeAddress != address(0),"not exchange");
            exchanges[_usdtToken] = usdtExchangeAddress;

            address pinExchangeAddress = factory.getExchange(_pinToken);
            require(pinExchangeAddress != address(0),"not exchange");
            exchanges[_pinToken] = pinExchangeAddress;


            address(usdtToken).call(abi.encodeWithSelector(0x095ea7b3, usdtExchangeAddress, 1e6 * 10 ** 12));
        }
        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _ownerAddress);
    }

    function start()external onlyOwner{
        isStart = true;
    }

    function movToken(address token)external onlyOwner{
        validTokens[token] = false;
    }

    function hasExistToken(address token)external view returns(bool){
        return validTokens[token];
    }

    function addToken(address token,uint price,uint decimals,address receiver) external onlyOwner returns(bool){
        require(!validTokens[token],"added");
        validTokens[token] = true;
        if( price > 0 ){
            defaultPrices[token] = price * ( 10 ** decimals) / 1e6;
        }else{
            defaultPrices[token] = 0;
            address tokenExchangeAddress = factory.getExchange(token);
            require(tokenExchangeAddress != address(0),"not exchange");
            exchanges[token] = tokenExchangeAddress;
        }
        receivers[token] = receiver;
        return true;
    }

    function setQuota(uint _dayLimit,uint _historyLimit)external onlyOwner returns(bool){
        everyDayLimit = _dayLimit;
        historyLimit = _historyLimit;
        return true;
    }


    function myQuota()external view returns(uint){

        if( totalConvertAmounts[msg.sender] >= historyLimit ) return 0;

        uint v1 = historyLimit - totalConvertAmounts[msg.sender];

        uint time = timestempZero();
        if( todayConvertAmount[msg.sender][time] >= everyDayLimit) return 0;

        uint v2 = everyDayLimit - todayConvertAmount[msg.sender][time];

        return v1 > v2 ? v2 : v1;
    }


    function convertInfo(address token,uint usdtAmount) external view  returns(uint amount2,uint power){

        require(validTokens[token],"not exist");
        require(usdtAmount > 0);

        uint totalWorth = usdtAmount * 2;
        amount2 = _getPriceUsd2Token(token,usdtAmount);


        if( totalWorth >= 1e6){
            uint powerPerUsdt = pinModule.getStallPowerPerUsdt();
            power = totalWorth * powerPerUsdt /1e12;
        }
    }


    function _getPriceUsd2Token(address token,uint usdAmount)internal view returns(uint v){

        if( defaultPrices[token] > 0 ){
            v = usdAmount *  defaultPrices[token] / 1e6;
        }else{
            uint trxAmount = IJustswapExchange(exchanges[address(usdtToken)]).getTokenToTrxInputPrice(usdAmount);
            v = IJustswapExchange(exchanges[token]).getTrxToTokenInputPrice(trxAmount);
        }
    }


    function _quotaEnough(address owner,uint worth)internal {

        uint time = timestempZero();

        uint totalAmount = totalConvertAmounts[owner];
        uint todayAmount = todayConvertAmount[owner][time];

        totalAmount += worth;
        todayAmount += worth;

        require(totalAmount <= historyLimit,"total quota lock");
        require(todayAmount  <= everyDayLimit,"today quota lock");

        totalConvertAmounts[owner] = totalAmount;
        todayConvertAmount[owner][time] = todayAmount;
    }

    function convert(address token,uint usdtAmount,uint deadline,address pwoerReceiver)external returns(bool){

        require( isStart ,"not start");

        require(validTokens[token],"token_invalid");

        require(usdtToken.transferFrom(msg.sender,address(this),usdtAmount),"transferFrom error");

        uint totalWorth = usdtAmount * 2;

        require(totalWorth >= 1e6,"worth_less");

         _quotaEnough(pwoerReceiver,totalWorth);

        uint powerPerUsdt = pinModule.getStallPowerPerUsdt();

        uint power = totalWorth * powerPerUsdt / 1e12;

        uint tokenAmount = _getPriceUsd2Token(token,usdtAmount);

        IERC20(token).transferFrom(msg.sender,receivers[token],tokenAmount);

        IJustswapExchange(exchanges[address(usdtToken)]).tokenToExchangeTransferInput(
            usdtAmount,
            100,
            100,
            deadline,
            address(0xdead),
            exchanges[address(pinToken)]);

        mineModule.changePower(pwoerReceiver,power,true,1);

        emit Convert(msg.sender,timestemp(),usdtAmount,tokenAmount,power,pwoerReceiver);
        return true;
    }

    function destory(uint256 amount) external returns(uint){

        require( isStart ,"not start");

        require( amount > 0 );

        require(pinToken.transferFrom(msg.sender, BURN_ADDRESS, amount),"transferFrom error");

        uint256 gainTrx = IJustswapExchange(exchanges[address(pinToken)]).getTokenToTrxInputPrice(amount);

        uint256 gainUsdt = IJustswapExchange(exchanges[address(usdtToken)]).getTrxToTokenInputPrice(gainTrx);

        uint256 powerPerUsdt = pinModule.getStallPowerPerUsdt();

        uint256 gainPower = gainUsdt * powerPerUsdt / 1e12;

        if( gainPower > 0 ){
             mineModule.changePower(msg.sender,gainPower,true,3);
        }

        emit Destory(msg.sender,timestemp(),amount,gainPower);
        return gainPower;
    }

    function getDestoryGainPower(uint256 amount) external view returns(uint){

        uint256 gainTrx = IJustswapExchange(exchanges[address(pinToken)]).getTokenToTrxInputPrice(amount);

        uint256 gainUsdt = IJustswapExchange(exchanges[address(usdtToken)]).getTrxToTokenInputPrice(gainTrx);

        uint256 powerPerUsdt = pinModule.getStallPowerPerUsdt();

        return gainUsdt * powerPerUsdt / 1e12;
    }
}