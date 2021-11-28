//SourceUnit: Pledge.sol


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

interface iPin{

   function getStallPowerPerUsdt() external view returns(uint);
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

pragma experimental ABIEncoderV2;

contract Pledge is Initializable,Verifiable,Time{

     struct Pool{
        address mineToken;
        bool isLp;
        uint acceptRate;
        mapping(address => address) exchanges;
    }

    Pool[] public pools;

    struct Miner{
        uint totalPower;
        mapping( uint => uint) gainPowers;
        mapping( uint => uint) pledgeAmounts;
    }

    mapping( address => Miner) internal miners;

    iMine mineModule;
    iPin pinModule;
    IJustswapExchange usdtEx;

    bool public isStart;

    event DoPledge(uint indexed pool,address indexed owner,uint time,uint amount);
    event UnPledge(uint indexed pool,address indexed owner,uint time,uint amount);

    function initialize(
        address _mineModule,
        address _pinModule,
        address _factory,
        address _usdtToken,
        address _ownerAddress) public initializer {

        mineModule = iMine(_mineModule);
        pinModule = iPin(_pinModule);

         if( _factory != address(0)){
              IJustswapFactory factory = IJustswapFactory(_factory);
            address usdtExchangeAddress = factory.getExchange(_usdtToken);
            require(usdtExchangeAddress != address(0),"not exchange");
            usdtEx = IJustswapExchange(usdtExchangeAddress);
         }

        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _ownerAddress);
    }

    function start()external onlyOwner{
        isStart = true;
    }

     function addPool(address mineToken,bool isLp,uint acceptRate,address _factory)external onlyOwner returns(bool){
        pools.push(Pool(mineToken,isLp,acceptRate));

        Pool storage pool = pools[pools.length-1];

        if( !isLp){
             IJustswapFactory factory = IJustswapFactory(_factory);
            address exchangeAddress = factory.getExchange(mineToken);
            require(exchangeAddress != address(0),"not exchange");
            pool.exchanges[mineToken] = exchangeAddress;
        }
        return true;
    }

    function getAllPower(address owner)external view returns(uint){
        return miners[owner].totalPower;
    }

    function getPoolLength() external view returns(uint){
        return pools.length;
    }

    function getMinerInfo(uint poolIndex)external view returns(uint pledgeLp,uint gainPower){
        pledgeLp = miners[msg.sender].pledgeAmounts[poolIndex];
        gainPower = miners[msg.sender].gainPowers[poolIndex];
    }


    function doPledge(uint poolIndex,uint amount)external returns(uint newPower){
        require( isStart ,"not start");

        require( amount > 0);

        Pool storage pool = pools[poolIndex];


        require(IERC20(pool.mineToken).transferFrom(msg.sender,address(this),amount),"transferFrom error");

        Miner storage miner = miners[msg.sender];

        uint historyPledge = miner.pledgeAmounts[poolIndex];
        uint historyPower = miner.gainPowers[poolIndex];

        historyPledge += amount;

        newPower = _calculateGainablePower(historyPledge,pool);

        _updatePower(msg.sender,newPower,historyPower);

        miner.pledgeAmounts[poolIndex] = historyPledge;
        miner.gainPowers[poolIndex] = newPower;

        if( newPower > historyPower ){
            miner.totalPower += (newPower - historyPower);
        }else{
            miner.totalPower -= (historyPower - newPower);
        }
        emit DoPledge(poolIndex,msg.sender,now,amount);
    }

    function predictPower(uint poolIndex,uint amount,bool isAdd)external view returns(uint){
        Miner storage miner = miners[msg.sender];

        uint pledge = miner.pledgeAmounts[poolIndex];

        uint v = isAdd ? pledge + amount : pledge - amount;

        Pool storage pool = pools[poolIndex];
        return _calculateGainablePower( v , pool);
    }

    function _calculateGainablePower(uint pledgeAmount,Pool storage pool)internal view returns(uint gainPower){

        if( pledgeAmount <= 100 ) return 0;

        uint usdtWorth = 0;

        if( pool.isLp ){

            uint supply = IERC20(pool.mineToken).totalSupply();
            uint trxRatio = pledgeAmount * address(pool.mineToken).balance / supply;

            usdtWorth = usdtEx.getTrxToTokenInputPrice(trxRatio);

            usdtWorth = usdtWorth * 2;
        }else{

            uint trxWorth = IJustswapExchange(pool.exchanges[pool.mineToken]).getTokenToTrxInputPrice(pledgeAmount);

            usdtWorth = usdtEx.getTrxToTokenInputPrice(trxWorth);
        }


        uint powerPerUsdt = pinModule.getStallPowerPerUsdt();

        gainPower = usdtWorth * powerPerUsdt * pool.acceptRate / (100 * 1e12);
    }

    function unDoPledge(uint poolIndex,uint amount)external returns(uint newPower){

        require( amount > 0);

        Pool storage pool = pools[poolIndex];

        Miner storage miner = miners[msg.sender];

        uint historyPledge = miner.pledgeAmounts[poolIndex];
        uint historyPower = miner.gainPowers[poolIndex];

        require(historyPledge >= amount,"value lock");
        historyPledge -= amount;

        newPower = _calculateGainablePower(historyPledge,pool);

        _updatePower(msg.sender,newPower,historyPower);

        miner.pledgeAmounts[poolIndex] = historyPledge;
        miner.gainPowers[poolIndex] = newPower;

        if( newPower > historyPower ){
            miner.totalPower += (newPower - historyPower);
        }else{
            miner.totalPower -= (historyPower - newPower);
        }

        IERC20(pool.mineToken).transfer(msg.sender,amount);

        emit UnPledge(poolIndex,msg.sender,now,amount);
    }


    function _updatePower(address owner,uint newPower,uint historyPower)internal{

        bool isAdd = newPower > historyPower ? true : false;

        uint changeAmount = newPower > historyPower ? newPower - historyPower : historyPower - newPower;

        if( changeAmount > 0 ){
            mineModule.changePower( owner,changeAmount,isAdd,2);
        }
    }
}