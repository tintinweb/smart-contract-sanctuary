//SourceUnit: Pin.sol


pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

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

interface iRelation{

    function getRecommers(address[] calldata owners)external view returns(address[] memory recommers);

    function _recommerMapping(address owner) external view returns(address);

    function getChilds(address owner,uint offset,uint size)external view returns(address[] memory childs);
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

contract Pin is Initializable,Verifiable,Time {

    event AwardEvent(address indexed owner,uint indexed amount,uint indexed time,uint8 aType);

    event EarnestEvent(address indexed owner,uint indexed amount,uint indexed time,uint8 eType);

    struct Player{
        uint256 drawAward;
        uint256 partakeAward;
        uint256 recommendAward;
        uint earnestAmount;
        mapping(uint =>bool) partakeFlags;
    }

    mapping(address => Player) public players;

    struct Round{
        uint256 prepareBlock;
        uint256 power;
        uint8 stallIndex;
        uint8 luckyValue;
        address sender;
        address[] players;
    }
    mapping(uint256 => Round) public rounds;

    uint256[] internal worldRounds;

    struct Stall{
        uint256 payment;
        uint256 pinValue;
        uint256 lastUpdateTime;
        uint256 inrRate;
        uint256 partakeAward;
        uint256 firstRecommendAward;
        uint256 repurchase;
        uint256 senderAward;
    }

    Stall[] public stalls;

    mapping(uint256 => uint256) internal roundNumbers;
    uint internal newestRoundNumber;

    mapping(address =>uint256[]) internal myRounds;

    IERC20 internal pinToken;
    iMine internal mineModule;
    IERC20 internal usdtToken;
    iRelation internal relationModule;

    IJustswapExchange internal usdtExchange;
    IJustswapExchange internal pinExchange;

    uint internal usdtAmount;

    bool public isStart;

    function initialize(
        address _usdtToken,
        address _pinToken,
        address _mineModule,
        address _relationModule,
        address _factory,
        address _ownerAddress,
        uint256 power) public initializer {

        newestRoundNumber = 10000000;
        usdtToken = IERC20(_usdtToken);
        pinToken = IERC20(_pinToken);
        mineModule = iMine(_mineModule);
        relationModule = iRelation(_relationModule);

        if( _factory != address(0)){
            IJustswapFactory factory = IJustswapFactory(_factory);

            address usdtExchangeAddress = factory.getExchange(_usdtToken);
            require(usdtExchangeAddress != address(0),"not exchange");
            usdtExchange = IJustswapExchange(usdtExchangeAddress);

            address pinExchangeAddress = factory.getExchange(_pinToken);
            require(pinExchangeAddress != address(0),"not exchange");
            pinExchange = IJustswapExchange(pinExchangeAddress);
        }


        uint time = timestempZero();
        stalls.push(Stall(500e6,power,time,1.002e6,10e6,10e6,250e6,50e6));


        if( address(usdtToken) != address(0)){
            address(usdtToken).call(abi.encodeWithSelector(0x095ea7b3, address(usdtExchange), 1e6 * 10 ** 12));
        }

        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _ownerAddress);
    }

    function start()external onlyOwner{
        isStart = true;
    }

    function UpdateStall(
        uint256 index,
        uint256 payment,
        uint256 pinValue,
        uint256 partakeAward,
        uint256 firstRecommendAward,
        uint256 repurchase,
        uint256 senderAward) external onlyOwner{

            stalls[index].payment = payment;
            stalls[index].pinValue = pinValue;
            stalls[index].partakeAward = partakeAward;
            stalls[index].firstRecommendAward = firstRecommendAward;
            stalls[index].repurchase = repurchase;
            stalls[index].senderAward = senderAward;
        }

    function getRoundPlayers(uint number)external view returns(address[] memory){
        return rounds[number].players;
    }

   function getWorldNewRound()external view returns(uint[] memory numbers){
        uint len = worldRounds.length;
        uint size = len > 10 ? 10 : len;

        numbers = new uint[](size);

        for( (uint i,uint k) = (len,0); i >0 && k < size; (i--,k++)){
            numbers[k] = worldRounds[i-1];
        }
   }


   function getMyNewRounds(address owner)external view returns(uint[] memory numbers){
       uint[] storage _myRounds =  myRounds[owner];
        uint len = _myRounds.length;
        uint size = len > 10 ? 10 : len;

        numbers = new uint[](size);

        for( (uint i,uint k) = (len,0); i >0 && k < size; (i--,k++)){
            numbers[k] = _myRounds[i-1];
        }
   }

   function getStallLength()external view returns(uint){
       return stalls.length;
   }

    function getStallPowerPerUsdt() external view returns(uint){
        Stall storage stall = stalls[stalls.length -1];
        return stall.pinValue * 1e12 / stall.payment;
    }


    function doDrawAward() external KRejectContractCall returns(bool){

        Player storage player = players[msg.sender];

        uint256 amount = player.partakeAward + player.recommendAward;

        require( amount > 0 ,"not_value");

        player.drawAward += amount;

        uint time = timestemp();

        if( player.partakeAward > 0){
            emit AwardEvent(msg.sender,player.partakeAward,time,1);
            player.partakeAward = 0;
        }

        if( player.recommendAward > 0){
            emit AwardEvent(msg.sender,player.recommendAward,time,2);
            player.recommendAward = 0;
        }

        usdtToken.transfer(msg.sender,amount);
        return true;
    }


    function _partakeable(address owner)internal view returns(bool){
        uint len = myRounds[owner].length;
        if( len > 0 ){
            Round storage round = rounds[myRounds[owner][len-1]];
            return round.luckyValue != 0xff || (round.prepareBlock > 0 &&  block.number > round.prepareBlock + 256) ;
        }
        return true;
    }


    function doPin(uint8 stallIndex) external returns(bool){

        require( isStart ,"not start");

        Stall storage stall = stalls[stallIndex];

        uint time = timestempZero();
        _updateStall(stall,time);

        Player storage player = players[msg.sender];

        require(player.earnestAmount >= stall.payment,"earnest_lock");

        require(_partakeable(msg.sender),"partaked");

        uint256 currentNumber = roundNumbers[stallIndex];

        if( currentNumber == 0 ){
            currentNumber = newestRoundNumber;
            roundNumbers[stallIndex] = currentNumber;
            worldRounds.push(currentNumber);
            newestRoundNumber ++;
        }

        Round storage round = rounds[currentNumber];

        if( round.players.length < 10){
            round.stallIndex = stallIndex;
            round.power = stall.pinValue;
            round.luckyValue = 0xff;
            round.players.push(msg.sender);
            myRounds[msg.sender].push(currentNumber);

            if( !player.partakeFlags[time]){
                player.partakeFlags[time] = true;
            }
        }

        if( round.players.length >= 10 ){
            round.prepareBlock = block.number;
            roundNumbers[stallIndex] = 0;
        }

        return true;
    }



    function _updateStall(Stall storage config,uint time) internal{

        uint256 d = (time - config.lastUpdateTime) / 1 days;

        if( d >= 1 ){
            uint256 rate = config.inrRate;
            uint inr = rate;

            for( uint256 i = 1; i < d; i++ ){
                rate = rate * inr / 1e6;
            }
            uint oldPinValue = config.pinValue;
            uint newPinValue = oldPinValue * rate / 1e6;
            config.pinValue = newPinValue;
            config.lastUpdateTime = time;
        }
    }


    function doSettlement(uint256 roundNum,uint deadline) external returns(bool){

        Round storage round = rounds[roundNum];

        uint currentBlock = block.number;
        uint prepareBlock = round.prepareBlock;

        require(currentBlock > prepareBlock + 10 && currentBlock < prepareBlock + 255,"noable settlement");

        require(round.luckyValue == 0xff && round.sender == address(0) ,"is settled");//

        Stall storage config = stalls[round.stallIndex];
        address luckyPlayer;
        {
            bytes32 bkhash = blockhash(prepareBlock + 10);
            uint8 luckyValue  = _calculateLuckyValue(bkhash);
            round.luckyValue = luckyValue;

            luckyPlayer = round.players[luckyValue];

            require(luckyPlayer != address(0));

            if( msg.sender != luckyPlayer){
                require(currentBlock >= prepareBlock + 50,"not lucky player");
            }

            uint luckyPlayerAmount = players[luckyPlayer].earnestAmount;
            require(luckyPlayerAmount >= config.payment,"earnest_lock");
            luckyPlayerAmount -= config.payment;
            players[luckyPlayer].earnestAmount = luckyPlayerAmount;

            mineModule.changePower(luckyPlayer,round.power * 2,true,0);
        }

        uint value = config.payment;
        {
            uint partakeAward = config.partakeAward;
            uint len = round.players.length;

            bool isPlayer = false;
            address player;
            for( uint i = 0; i < len ; i++){
                player = round.players[i];
                players[player].partakeAward += partakeAward;

                if( !isPlayer && player == msg.sender){
                    isPlayer = true;
                }
            }
            require( isPlayer,"sender not player");
            round.sender = msg.sender;
            value -= partakeAward * len;
        }

        {
            uint firstRecommendAward = config.firstRecommendAward;

            address[] memory recommers = relationModule.getRecommers(round.players);

            uint len = recommers.length;
            uint time = timestempZero();

            for( uint i = 0; i < len; i++){

                address recommer = recommers[i];

                if( players[recommer].partakeFlags[time] ){
                    players[recommer].recommendAward += firstRecommendAward;
                    value -= firstRecommendAward;
                }
            }
        }

        {
            uint senderAward = config.senderAward;
            players[msg.sender].partakeAward += senderAward;
            value -= senderAward;

            uint repurchase = config.repurchase;
            value -= repurchase;
            usdtExchange.tokenToExchangeTransferInput(repurchase,10,10,deadline,address(0xdead),address(pinExchange));
        }

        if( value > 0 ){
            usdtAmount += value;
        }
        return true;
    }



    function _calculateLuckyValue(bytes32 txHash)internal pure returns(uint8 value){
        for(uint i = txHash.length - 1; i >= 0; i--){
            value = uint8(txHash[i] & 0x0f);
            if( value < 10) return value;

            value = uint8( txHash[i] >> 4);
            if( value < 10) return value;
        }
        return 0;
    }



    function rechargeEarnestAmount(uint256 amount) external returns(bool){

        require(amount > 0);

        usdtToken.transferFrom(msg.sender,address(this),amount);

        players[msg.sender].earnestAmount += amount;

        emit EarnestEvent(msg.sender,amount,timestemp(),1);
        return true;
    }

    function drawEarnestAmount(uint256 amount) external KRejectContractCall returns(bool){

        Player storage player = players[msg.sender];

        require(_partakeable(msg.sender),"not able draw");

        require(amount > 0);

        require(player.earnestAmount >= amount,"amount_lock");

        player.earnestAmount -= amount;

        usdtToken.transfer(msg.sender,amount);

        emit EarnestEvent(msg.sender,amount,timestemp(),2);
        return true;
    }


    function withdraw(address owner)external onlyOwner returns(uint amount){
        amount = usdtAmount;
        if( amount > 0 ){
            usdtAmount = 0;
            usdtToken.transfer(owner,amount);
        }
    }
}