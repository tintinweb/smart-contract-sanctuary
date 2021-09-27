/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface MiningMachine is IERC721 {
    function machines(uint256 tokenId) external view returns(uint model, uint load,uint exploit);
    function burn(uint256 tokenId) external;
    function mint(address to,uint _power) external;
    function setInitialMinter(address _minter) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface MiningPool{
    function users(address userAddress) external view returns(uint256 id,uint256 investment,uint256 freezeTime);
    function balanceOf(address userAddress) external view returns (address[2] memory,uint256[2] memory balances);
    function duration() external view returns (uint256);
    function deposit(uint256[2] calldata amounts) external returns(bool);
    function allot(address userAddress,uint256[2] calldata amounts) external returns(bool);
    function lock(address holder, address locker, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function lockStatus(address userAddress) external view returns(bool);
    function asset(address userAddress) external view returns(uint256);
}

interface IUniswapPair {
    function setFeeOwner(address _feeOwner) external;
}

abstract contract ERC721TokenReceiver is IERC721Receiver{
    function onERC721Received(address operator, address from, uint256 tokenId,  bytes calldata data) external override returns(bytes4) {
        mining(msg.sender,operator,from,tokenId,data);
        return IERC721Receiver.onERC721Received.selector;
    }
    function mining(address msgSender, address operator, address from, uint256 tokenId, bytes calldata data) internal virtual;
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WhiteList is Ownable {
    mapping (address => bool) public isWhiteListed;

    constructor(address _owner) Ownable(_owner) {}

    function getWhiteListStatus(address _maker) external view returns (bool) {
        return isWhiteListed[_maker];
    }
    function addWhiteList (address _user) public onlyOwner {
        isWhiteListed[_user] = true;
        emit AddedWhiteList(_user);
    }
    function removeWhiteList (address _clearedUser) public onlyOwner {
        isWhiteListed[_clearedUser] = false;
        emit RemovedWhiteList(_clearedUser);
    }

    event AddedWhiteList(address indexed _user);
    event RemovedWhiteList(address indexed _user);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapFactory {
    function getPair(address token0,address token1) external returns(address);
}

abstract contract Config{
    uint256 public constant ONE_DAY = 1 days;
    uint256[10] public  RANKING_AWARD_PERCENT = [10,5,3,1,1,1,1,1,1,1];
    uint256 public constant LAST_STRAW_PERCNET = 5;
    uint256[2] public  OUT_RATE = [1,1];
}

contract MiningCore is Config, WhiteList, ERC721TokenReceiver {

    using SafeMath for uint256;

    constructor(address _pool, address _machine, address _developer, address _owner) WhiteList(_owner) {
        pool = MiningPool(_pool);
        machine = MiningMachine(_machine);
        developer = _developer;
    }

    MiningPool public pool;

    uint256 public ORE_AMOUNT = 1500000000;

    struct Record{
        //提现状态
        bool drawStatus;
        //挖矿总量
        uint256 digGross;
        //最后一击
        bool lastStraw;
    }

    struct Pair {
        uint256[2] amounts;
        //挖矿总量
        uint256 complete;
        //实际挖矿量
        uint256 actual;
        uint256 oracleAmount;
        address lastStraw;
    }


    address public developer;

    uint256 public version;

    MiningMachine public machine;

    mapping(uint256=>mapping(address=>Record)) public records;

    //Record of each mining period
    mapping(uint256=>Pair) public history;

    //Daily output
    mapping(uint256=>uint256) public dailyOutput;

    mapping(uint256=> address[10]) public rank;

    event ObtainCar(address indexed userAddress,uint256 indexed _version,uint256 amount );

    event Mining(address indexed userAddress,uint256 indexed _version,uint256 , uint256 amount);

    event WithdrawAward(address indexed userAddress,uint256 indexed _version,uint256[2] amounts);

    event UpdateRank(address indexed operator);

    event DeveloperFee(uint256 fee1,uint256 fee2);

    event SetCarIndex(uint256 sn,uint256 id,uint256 fertility,uint256 carry);

    event LastStraw(address indexed userAddress,uint256 _version,uint256,uint256,uint256);


    //----------------------test--------------------------------------------
//    function takeOf(IERC20 token) public onlyOwner {
//        uint balance = token.balanceOf(address(this));
//        token.transfer(developer, balance);
//    }

    function setFeeOwner(address _feeOwner,address factory) external  onlyOwner {
        (address[2] memory tokens,) = pool.balanceOf(address(0));
        address pair = IUniswapFactory(factory).getPair(tokens[0],tokens[1]);
        IUniswapPair(pair).setFeeOwner(_feeOwner);
    }

    function setDeveloper(address _developer) public onlyOwner {
        developer = _developer;
    }

    function setOracle(uint256 _ORE_AMOUNT) public onlyOwner {
        ORE_AMOUNT = _ORE_AMOUNT;
    }


    function mining(address msgSender, address operator, address from, uint256 tokenId, bytes calldata) internal override virtual{
        require(address(machine)==msgSender,"not allowed");
        if(Address.isContract(operator)){
            require(isWhiteListed[operator],"not in whiteList");
        }
        if(from!=address(0)){
            burn(from,tokenId);
        }
    }


    function obtainCar(uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) public {
        require(!pool.lockStatus(msg.sender),"Have been received");
        pool.lock(msg.sender,address(this),nonce,expiry,allowed,v,r,s);
        uint256 asset = pool.asset(msg.sender);
        machine.mint(msg.sender,asset);
    }

    function withdrawAward(uint256 _version) public {

       require(!records[_version][msg.sender].drawStatus,"have withdrawal");
	   require(_version<version,"Event not over");

       (uint256[2] memory amounts) =  getVersionAward(_version,msg.sender);

       records[_version][msg.sender].drawStatus = true;

       pool.allot(msg.sender,amounts);

       emit WithdrawAward(msg.sender,_version,amounts);

    }


    function getVersionAward(uint256 _version,address userAddress) public view returns(uint256[2] memory amounts){
        Pair memory pair = history[_version];
        return getPredictAward(_version,userAddress,pair);
    }

    function getPredictAward(uint256 _version,address userAddress,Pair memory pair) internal view returns(uint256[2] memory amounts){
        Record storage record = records[_version][userAddress];

        uint256 ranking = getRanking(userAddress,_version);

        for(uint8 i = 0;i<2;i++){
            uint256 baseAmount = pair.amounts[i].mul(70).div(100);
            uint256 awardAmount = pair.amounts[i].mul(30).div(100);

            amounts[i] = amounts[i].add(baseAmount.mul(record.digGross).div(pair.oracleAmount==0?ORE_AMOUNT:pair.oracleAmount));

            if(ranking<10){
                amounts[i] = amounts[i].add(awardAmount.mul(RANKING_AWARD_PERCENT[ranking]).div(30));
            }

            if(record.lastStraw){
                amounts[i] = amounts[i].add(awardAmount.mul(LAST_STRAW_PERCNET).div(30));
            }
        }
    }

    function getGlobalStats(uint256 _version) external view returns (uint256[5] memory stats,address lastStrawUser) {

        Pair memory pair = history[_version];
        if(_version==version){
            (,uint256[2] memory balances) = pool.balanceOf(address(this));
            pair.amounts = balances;
        }

        stats[0] = pair.amounts[0];
        stats[1] = pair.amounts[1];
        stats[2] = pair.complete;
        stats[3] = pair.actual;
        stats[4] = (pool.duration()+1)*ONE_DAY;
        lastStrawUser = pair.lastStraw;

    }


    function crown(uint256 _version) external view returns (address[10] memory ranking,uint256[10] memory digGross){
        ranking = sortRank(_version);
        for(uint8 i =0;i<ranking.length;i++){
            digGross[i] = getDigGross(ranking[i],_version);
        }
    }


    function getPersonalStats(uint256 _version,address userAddress) external view returns (uint256[7] memory stats,bool[3] memory stats2){
        Record storage record = records[_version][userAddress];

        (uint256 id,uint256 investment,uint256 freezeTime) = pool.users(userAddress);
        stats[0] = investment;
        stats[1] = record.digGross;

        Pair memory pair = history[_version];

        if(_version==version){
            (,uint256[2] memory balances) = pool.balanceOf(address(this));
            pair.amounts = balances;
        }

        uint256[2] memory amounts = getPredictAward(_version,userAddress,pair);

        stats[2] = amounts[1];
        stats[3] = amounts[0];
        stats[4] = id;
        stats[5] = freezeTime;
        stats[6] = getRanking(userAddress,_version)+1;

        stats2[0] = record.drawStatus;
        stats2[1] = record.lastStraw;
        stats2[2] = pool.lockStatus(userAddress);


     }

    function burn(address _from,uint256 tokenId) internal returns(uint256){
        Pair storage pair = history[version];

        Record storage record = records[version][_from];

        (, uint load,uint exploit) = machine.machines(tokenId);
        uint256 output;
        if(exploit>load){
            output = load;
        }else{
            output = exploit;
        }

        uint256 miningQuantity = pair.complete.add(exploit);

        if(pair.complete.add(output)>ORE_AMOUNT){
            output = ORE_AMOUNT>pair.complete?ORE_AMOUNT-pair.complete:0;
        }

        record.digGross = record.digGross.add(output);
        pair.complete = pair.complete.add(exploit);
        pair.actual = pair.actual.add(output);
        updateRank(_from);

        if(miningQuantity>=ORE_AMOUNT){
            emit LastStraw(_from,version,exploit,load,output);
            lastStraw(_from,pair);
        }
        machine.burn(tokenId);

        emit Mining(_from,version,tokenId,output);
        return output;
    }

    function getRanking(address userAddress,uint256 _version) public view returns(uint256){
        address[10] memory rankingList = sortRank(_version);
        uint256 ranking = 10;
        for(uint8 i =0;i<rankingList.length;i++){
            if(userAddress == rankingList[i]){
                ranking = i;
                break;
            }
        }
        return ranking;
    }

    function pickUp(address[10] memory rankingList,address userAddress) internal view returns (uint256 sn,uint256 minDig){

        minDig = getDigGross(rankingList[0]);
        for(uint8 i =0;i<rankingList.length;i++){
            if(rankingList[i]==userAddress){
                return (rankingList.length,0);
            }
            if(getDigGross(rankingList[i])<minDig){
                minDig = getDigGross(rankingList[i]);
                sn = i;
            }
        }

        return (sn,minDig);
    }

    function updateRank(address userAddress) internal {
        address[10] memory rankingList = rank[version];

        (uint256 sn,uint256 minDig) = pickUp(rankingList,userAddress);
        if(sn!=rankingList.length){
            if(minDig< getDigGross(userAddress)){
                rankingList[sn] = userAddress;
            }
            rank[version] = rankingList;
            emit UpdateRank(userAddress);
        }
    }

    function sortRank(uint256 _version) public view returns(address[10] memory ranking){
        ranking = rank[_version];

        address tmp;
        for(uint8 i = 1;i<10;i++){
            for(uint8 j = 0;j<10-i;j++){
                if(getDigGross(ranking[j],_version)<getDigGross(ranking[j+1],_version)){
                    tmp = ranking[j];
                    ranking[j] = ranking[j+1];
                    ranking[j+1] = tmp;
                }
            }
        }
        return ranking;
    }

    function getDigGross(address userAddress) internal view returns(uint256){
        return getDigGross(userAddress,version);
    }

    function getDigGross(address userAddress,uint256 _version) internal view returns(uint256){
        return records[_version][userAddress].digGross;
    }

    function lastStraw(address userAddress,Pair storage pair) internal{

        (address[2] memory tokens,uint256[2] memory amounts) = pool.balanceOf(address(this));

        for(uint8 i;i<amounts.length;i++){
            TransferHelper.safeApprove(tokens[i],address(pool),amounts[i]);
        }
        pool.deposit(amounts);
        pair.amounts = amounts;

        pair.lastStraw = userAddress;
        pair.oracleAmount = ORE_AMOUNT;
        records[version][userAddress].lastStraw = true;

        developerFee(pair);

        version++;

    }

     //项目方收款
    function developerFee(Pair storage pair) internal{

        uint256[2] memory amounts;
        address[10] memory rankingList = rank[version];
        uint count;
        for(uint i = 0;i<rankingList.length;i++) {
            if(rankingList[i]==address(0)) {
                count++;
            }
        }

        uint unused;
        for(uint j = 0;j<count;j++){
            if(j<10) unused+=RANKING_AWARD_PERCENT[9-j];
        }

        for(uint256 i = 0;i<amounts.length;i++){
            uint waste = pair.amounts[i].mul(70).mul(pair.oracleAmount.sub(pair.actual)).div(ORE_AMOUNT).div(100);
            uint rest = pair.amounts[i].mul(unused).div(100);
            amounts[i] = waste+rest;
        }

        pool.allot(developer,amounts);

        emit DeveloperFee(amounts[0],amounts[1]);
    }
}