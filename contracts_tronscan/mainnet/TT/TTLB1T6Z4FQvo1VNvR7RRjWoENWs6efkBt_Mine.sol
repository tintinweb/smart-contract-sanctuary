//SourceUnit: Mine.sol


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

library TimeValue {

    struct Release {
        uint latestInrTime;
        uint value;
        uint oneDayInrValue;
    }

    struct Person{
        uint invest;
        uint lastSettleTime;
        uint award;
    }

    struct Network{
        uint invest;
        uint lastSettleTime;
    }

    struct Values{
        uint[] keys;
        mapping(uint => uint) values;
    }

    struct Data {
        Release release;
        Network network;
        Values indexs;
        mapping(address =>Person) persons;
    }

     function getOneDayRelease(Data storage self,uint time)internal view returns(uint){
        uint latestInrTime = self.release.latestInrTime;
        uint dayNum = (time - latestInrTime) / 1 days; //
        return self.release.value +  dayNum *  self.release.oneDayInrValue; //
    }

    function updateRelease(Data storage self,uint time,uint value,uint oneDayInr)internal{
        self.release.latestInrTime = time;
        self.release.value = value;
        self.release.oneDayInrValue = oneDayInr;
    }

    function changeData(Data storage self,address owner, uint value, uint time,bool isAdd)internal {

        _updateIndex(self,time);

        
        uint v = _settle(self,time,owner);
        if( v > 0 ){
            self.persons[owner].award += v;
        }

        if( value > 0 ){
            if( isAdd){
                self.network.invest += value;
                self.persons[owner].invest += value;
            }else{
                uint personInvest = self.network.invest;
                uint networkInvest = self.persons[owner].invest;
                require(personInvest >= value && networkInvest >= value,"value_lock");
                personInvest -= value;
                networkInvest -= value;
                self.network.invest = personInvest;
                self.persons[owner].invest = networkInvest;
            }
        }
    }

    function _settle(Data storage self,uint time,address owner)internal returns(uint v){

        Person storage person = self.persons[owner];

        uint lastTime = person.lastSettleTime;

        if( lastTime == 0 ){
            person.lastSettleTime = time;
            return 0;
        }

        if( time > lastTime ){
            uint invest = person.invest;

            person.lastSettleTime = time;

            if( invest > 0 ){
                v = (self.indexs.values[time] - self.indexs.values[lastTime]) * invest / 10 ** 18;
            }
        }
    }

    function _updateIndex(Data storage self,uint time)internal{

        uint lastTime = self.network.lastSettleTime;

        if( lastTime == 0 ){
            self.network.lastSettleTime = time;
            return;
        }

        if( time > lastTime ){

            uint zeroTime = time / 1 days * 1 days;

            uint latestInrTime = self.release.latestInrTime;

            require(latestInrTime != 0,"not init");

            if( zeroTime > latestInrTime ){

                _doUpdateIndex(self,latestInrTime + 1 days);

                if( zeroTime > latestInrTime + 1 days ){

                    uint dayNum = (zeroTime - latestInrTime - 1 days) / 1 days;
                    uint a1 = self.release.value;
                    uint d = self.release.oneDayInrValue;
                    uint mined = a1 * dayNum + dayNum * (dayNum - 1) * d / 2;
                    uint v = mined * 10 ** 18 / self.network.invest;
                    _increaseIndex(self.indexs, v, zeroTime);

                    self.release.value += dayNum * d;
                    self.release.latestInrTime = zeroTime;
                    self.network.lastSettleTime = zeroTime;
                }
            }

            _doUpdateIndex(self,time);
        }
    }

    function _doUpdateIndex(Data storage self,uint time)internal{

        uint latestInrTime = self.release.latestInrTime;
        uint zero = time / 1 days * 1 days;
        if( zero > latestInrTime ){
            self.release.value += ( zero - latestInrTime)/ 1 days * self.release.oneDayInrValue;
            self.release.latestInrTime = zero;
        }

        uint lastTime = self.network.lastSettleTime;

        if( time > lastTime ){
             uint dution = ( time - lastTime);

            self.network.lastSettleTime = time;

            uint invest = self.network.invest;
            if( invest > 0 ){
                uint changeNetworkV = self.release.value * dution * 10 ** 18 / (self.network.invest * 86400);
                _increaseIndex(self.indexs, changeNetworkV, time);
            }
        }
    }

    function drawAward(Data storage self, address owner,uint time)internal returns(uint v){

        _updateIndex(self,time);

        v = _settle(self,time,owner);

        uint historyAward = self.persons[owner].award;
        if( historyAward > 0 ){
            self.persons[owner].award = 0;
            v += historyAward;
        }
    }


    function networkLastvalue(Data storage self)internal view returns(uint){
        return self.network.invest;
    }

    function personalLastValue(Data storage self,address owner)internal view returns(uint){
        return self.persons[owner].invest;
    }

    function _increaseIndex(Values storage self, uint addValue, uint time) internal{

        if( self.keys.length == 0 ){
            self.keys.push(time);
            self.values[time] = addValue;
        }else{
            uint latestTime = self.keys[self.keys.length - 1];

            if (latestTime == time) {
                self.values[latestTime] += addValue;
            }else{
                self.keys.push(time);
                self.values[time] = (self.values[latestTime] + addValue);
            }
        }
    }


}


interface IERC777 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /// ERC777 appending new api
    function granularity() external view returns (uint);
    function defaultOperators() external view returns (address[] memory);

    function addDefaultOperators(address owner) external returns (bool);
    function removeDefaultOperators(address owner) external returns (bool);

    function isOperatorFor(address operator, address holder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;

    function send(address to, uint amount, bytes calldata data) external;
    function operatorSend(address from, address to, uint amount, bytes calldata data, bytes calldata operatorData) external;

    function burn(uint amount, bytes calldata data) external;
    function operatorBurn(address from, uint amount, bytes calldata data, bytes calldata operatorData) external;

    event Sent(address indexed operator, address indexed from, address indexed to, uint amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed holder);
    event RevokedOperator(address indexed operator, address indexed holder);
}

interface iPledge{

   function getAllPower(address owner) external view returns(uint);

}




contract Mine is Initializable,Verifiable,Time{

    event PowerEvent(address indexed owner,uint indexed time,uint amount,bool isAdd,uint powerSource);

    event DrawEvent(address indexed owner,uint indexed time,uint amount);

    event PowerTransfer(address indexed from,address indexed to,uint time,uint amount);


    using TimeValue for TimeValue.Data;

    struct ReleaseInfo {
        uint latestCutDownTime;
        uint initValue;
        uint degree;
        uint oneDayInrValue;
    }

    ReleaseInfo internal releaseInfo;

    struct PowerConfig{
        uint total;
        uint mined;
    }
    PowerConfig[] internal powerConfigs;

    struct MinerInfo {
        uint mined;
    }

    mapping (address => MinerInfo) public minerInfos;

    TimeValue.Data internal mineManage;

    iPledge internal pledgeMoudle;

    struct NetworkInfo{
        uint mined;
        uint total;
        mapping(uint =>bool) hasUpdateRelease;
    }
    NetworkInfo public networkInfo;

    IERC777 internal pinAddress;

    uint internal constant everyDegreeMineable = 1000000e6;

    mapping(address => uint) internal migratePowers;

    uint MigratePowerTime;

    bool public isStart;

    function initialize(
        address _pinAddress,
        address _ownerAddress) public initializer {

        pinAddress = IERC777(_pinAddress);
        networkInfo = NetworkInfo(0,19950000e6);

        uint len = networkInfo.total / everyDegreeMineable;

        for( uint i = 0; i < len; i++){
            powerConfigs.push(PowerConfig(everyDegreeMineable,0));
        }

        uint remainder = networkInfo.total % everyDegreeMineable;
        if( remainder > 0){
            powerConfigs.push(PowerConfig(remainder,0));
        }

        _owner = _ownerAddress;

        MigratePowerTime = timestemp() / 1 days * 1 days + 1 days;

        emit OwnershipTransferred(address(0), _ownerAddress);
    }


   function MigratePower(address[] calldata owners,uint256[] calldata powers)external onlyOwner{
        require(owners.length == powers.length);
        uint time = timestemp() / 1 days * 1 days + 1 days;

        require( time == MigratePowerTime ,"invalid");

        for( uint256 i = 0; i < owners.length; i++){
            if(  powers[i] > 0 && migratePowers[owners[i]] == 0 ){
                mineManage.changeData(owners[i],powers[i],time,true);
                migratePowers[owners[i]] = powers[i];
            }
        }
    }

   function MigrateReleaseInfo(uint256 todayValue,uint256 degree)external onlyOwner{
        uint256 zeroTime = timestempZero();
        releaseInfo = ReleaseInfo(zeroTime,todayValue,degree,10e6);
        mineManage.updateRelease(zeroTime,todayValue,10e6);
    }


    function MigratePowerConfig(uint256 index,uint256 mined)external onlyOwner{
        powerConfigs[index].mined = mined;
        networkInfo.mined = mined;
    }

    function setPledgeMoudle(address _pledgeMoudle)external onlyOwner{
        pledgeMoudle = iPledge(_pledgeMoudle);
    }

    function start()external onlyOwner{
        isStart = true;
    }

    function todayReleaseValue() external view returns(uint){
        return _getReleaseAmount(timestempZero());
    }

    function _getReleaseAmount(uint time)internal view returns(uint){
        return releaseInfo.initValue +  (time - releaseInfo.latestCutDownTime) / 1 days * releaseInfo.oneDayInrValue;
    }


    function mineInfo() external view returns(
        uint myPower,uint mined){
        myPower = mineManage.personalLastValue(msg.sender);
        mined = minerInfos[msg.sender].mined;
    }

    function netWorkInfo()external view returns(uint256 power,uint256 oneDayRelease,uint256 totalMined){
        power = mineManage.networkLastvalue();
        oneDayRelease = mineManage.getOneDayRelease(timestempZero());
        totalMined = networkInfo.mined;
    }


    function _upgradeReleaseInfo(uint todayZero) internal {

        uint inrV = (todayZero - releaseInfo.latestCutDownTime) / 1 days * releaseInfo.oneDayInrValue;

        releaseInfo.initValue = (releaseInfo.initValue + inrV) * 50 / 100;
        releaseInfo.latestCutDownTime = todayZero;

        releaseInfo.degree +=1;

        mineManage.updateRelease(todayZero,releaseInfo.initValue,releaseInfo.oneDayInrValue);
    }


    function drawPin() external returns (uint v) {

        uint total = networkInfo.total;
        uint mined = networkInfo.mined;
        require( total >= mined,"mine_finish");

        uint256 time = timestemp();

        v = mineManage.drawAward(msg.sender,time);

        if( v > 0 ){

            if( v + mined > total ){
                v = total - mined;
            }

            uint degree = releaseInfo.degree;

            if ( v > 0  && degree < powerConfigs.length ) {

                PowerConfig storage config = powerConfigs[degree];

                minerInfos[msg.sender].mined += v;
                config.mined += v;
                mined += v;
                networkInfo.mined = mined;

                pinAddress.operatorSend(address(pinAddress),msg.sender,v,"Mined","");

                if( config.mined >= config.total){

                    _upgradeReleaseInfo(time / 1 days * 1 days);
                }

                emit DrawEvent(msg.sender,time,v);
            }
        }
    }



    function changePower(address owner,uint amount ,bool isAdd,uint powerSource) external KDelegateMethod {

        uint time = timestemp();
        mineManage.changeData(owner,amount,time,isAdd);
        emit PowerEvent(owner,time,amount,isAdd,powerSource);
    }


    function transfer(address to , uint256 power)external returns(bool){
        require( isStart ,"not start");
        require( power > 0);

        uint256 myPower = mineManage.personalLastValue(msg.sender);

        uint256 pledgePower = pledgeMoudle.getAllPower(msg.sender);

        require( myPower > pledgePower,"value lock");

        uint tranferAble = myPower - pledgePower;

        require( tranferAble >= power,"value lock");

        uint time = timestemp();

        mineManage.changeData(msg.sender,power,time,false);
        emit PowerEvent(msg.sender,time,power,false,4);

        uint256 receivePower = power * 90 / 100;

        if( receivePower > 0 ){
            mineManage.changeData(to,receivePower,time,true);
            emit PowerEvent(to,time,receivePower,true,5);
        }

        emit PowerTransfer(msg.sender,to,time,power);
        return true;

    }
}