// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./IERC1155.sol";
import "./IERC1155TokenReceiver.sol";
import "./Ownable.sol";
import "./Address.sol";

// sns: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]
// ids:[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]
// fertilities:[1,2,5,10,30,100,1,2,5,10,30,100,10,20,50,100,300,1000]
// carries:[0,0,0,0,0,0,10,20,50,100,300,1000,1,2,5,10,30,100]

interface MiningPool{
    
    function users(address userAddress) external view returns(uint256 id,uint256 investment,uint256 freezeTime);
    
    function balanceOf(address userAddress) external view returns (address[2] memory,uint256[2] memory balances);
    
    function totalSupply() external view returns (uint256);
    
    function stakeAmount() external view returns (uint256);
    
    function duration() external view returns (uint256);
    
    function token() external view returns (address);
    
    function deposit(uint256[2] calldata amounts) external returns(bool);
    
    function allot(address userAddress,uint256[2] calldata amounts) external returns(bool);
    
    function lock(address holder, address locker, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    
    function lockStatus(address userAddress) external view returns(bool);
}

interface IUniswapPair {
    
    function setFeeOwner(address _feeOwner) external;
}

interface IUniswapFactory {
    
    function getPair(address token0,address token1) external returns(address);
}

abstract contract ERC1155TokenReceiver is IERC1155TokenReceiver{
    
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
    
    //-------------------------------------ERC1155---------------------------------------------------------------------
    
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external override returns(bytes4) {
        uint256[] memory _values = new uint256[](1);
        uint256[] memory _ids = new uint256[](1);
        _ids[0] = _id;
        _values[0] = _value;
        
        operateToken1155(msg.sender,_operator,_from,_ids,_values,_data);
        return ERC1155_RECEIVED_VALUE;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override returns(bytes4) {
        operateToken1155(msg.sender,_operator,_from,_ids,_values,_data);
        return ERC1155_BATCH_RECEIVED_VALUE;
    }

    // ERC165 interface support
    function supportsInterface(bytes4 interfaceID) external override pure returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC165
                interfaceID == 0x4e2312e0;      // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
    }
    
    function operateToken1155(address msgSender, address _operator, address _from, uint256[] memory _ids, uint256[] memory _values, bytes calldata _data) internal virtual;
}

contract Config{
    
    uint256 public constant ONE_DAY = 1 days;
    
    uint256[10] public  RANKING_AWARD_PERCENT = [10,5,3,1,1,1,1,1,1,1];
    
    uint256 public constant LAST_STRAW_PERCNET = 5;
    
    uint256[2] public  OUT_RATE = [1,1];

}


contract MiningCore is Config, Ownable, ERC1155TokenReceiver {
    
    using SafeMath for uint256;
    
    constructor(MiningPool _pool,IERC1155 _token1155,address payable _developer) {
        pool = _pool;
        token1155 = _token1155;
        developer = _developer;
    }
    
    MiningPool public pool;
    
    IERC1155 public token1155;
    
    
    uint256 public ORE_AMOUNT = 500000000;
    
    struct Record{
        //提现状态
        bool drawStatus;
        //挖矿总量
        uint256 digGross;
        //最后一击
        bool lastStraw;
       
        mapping(uint256=>uint256) disCars;
    }
    
    struct Pair {
        uint256[2] amounts;
        //挖矿总量
        uint256 complete;
        //实际挖矿量
        uint256 actual;
        
        address lastStraw;
    }
    
    struct Car{
        uint256 sn;
        uint256 fertility;
        uint256 carry;
    }
    
    //address[] callHelper;
    
    address payable developer;
    
    uint256 public version;
    
    //User acquisition record
    //mapping(uint256=>mapping(address=>bool)) public obtainLogs;
    
    mapping(uint256=>mapping(address=>Record)) public records;
    
    //Record of each mining period
    mapping(uint256=>Pair) public history;
    
    //Daily output
    mapping(uint256=>uint256) public dailyOutput;
    
    //The number corresponds to the carIndex
    uint256[] public carIndex;
    
    //Each ID corresponds to a car attribute
    mapping(uint256=>Car) public cars;
    
    mapping(uint256=> address[10]) public rank;
    
    event ObtainCar(address indexed userAddress,uint256 indexed _version,uint256 amount );
    
    event Mining(address indexed userAddress,uint256 indexed _version,uint256[] ,uint256[],uint256 amount);
    
    event WithdrawAward(address indexed userAddress,uint256 indexed _version,uint256[2] amounts);
    
    event UpdateRank(address indexed operator);
    
    event DeveloperFee(uint256 fee1,uint256 fee2);
    
    event SetCarIndex(uint256 sn,uint256 id,uint256 fertility,uint256 carry);
    
    event LastStraw(address indexed userAddress,uint256 _version,uint256,uint256,uint256);
    
    function init() public onlyOwner {
        uint256[18] memory _ids = [uint256(1),2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18];
        uint256[18] memory _fertilities = [uint256(1),2,5,10,30,100,1,2,5,10,30,100,10,20,50,100,300,1000];
        uint256[18] memory _carries = [uint256(0),0,0,0,0,0,10,20,50,100,300,1000,1,2,5,10,30,100];
        setCarIndexs(_ids,_fertilities,_carries);
    }

     //Set vehicle properties
    function setCarIndex(uint256 sn,uint256 id,uint256 fertility,uint256 carry) public onlyOwner{
        if(sn+1>carIndex.length){
            carIndex.push(id);
            //callHelper.push(address(this));
        }else{
            carIndex[sn] = id;
        }
        
        cars[id] = Car(sn,fertility,carry);
        emit SetCarIndex( sn, id, fertility, carry);
    }
    
    //Batch set vehicle properties
    function setCarIndexs(uint256[18] memory ids,uint256[18] memory fertilities,uint256[18] memory carries) private {
        for(uint256 i=0;i<ids.length;i++){
            setCarIndex(i,ids[i],fertilities[i],carries[i]);
        }
    }
    
    function setFeeOwner(address _feeOwner,address factory) external  onlyOwner {
        (address[2] memory tokens,) = pool.balanceOf(address(0));
        address pair = IUniswapFactory(factory).getPair(tokens[0],tokens[1]);
        IUniswapPair(pair).setFeeOwner(_feeOwner);
    }
    
    
    function setOracle(uint256 _ORE_AMOUNT) public onlyOwner {
        ORE_AMOUNT = _ORE_AMOUNT;
    }
    
    
    function operateToken1155(address msgSender,address _operator, address _from, uint256[] memory _ids, uint256[] memory _values, bytes calldata) internal override virtual{
        
        require(address(token1155)==msgSender,"not allowed");
        require(!Address.isContract(_operator),"Contract invocation is not allowed");
       
        if(_from!=address(0x0)){
            mining(_from,_ids,_values);
        }
    }
    

    function obtainCar(uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) public {
        require(!pool.lockStatus(msg.sender),"Have been received");
		
		     (,uint256[] memory counts,uint256 len,uint256 token1155Amount,uint256 quantity) = cat(msg.sender);
            
             if(dailyOutput[pool.duration()]==0){
                 dailyOutput[pool.duration()] = token1155Amount;
             }
        
        // uint256[] memory carUsable = new uint256[](kinds());
        // {
        //     (,uint256[] memory counts,uint256 len,uint256 token1155Amount,uint256 quantity) = cat(msg.sender);
            
        //     if(dailyOutput[pool.duration()]==0){
        //         dailyOutput[pool.duration()] = token1155Amount;
        //     }
        
        //     require(quantity>0&&len>0,"to small");

        //     uint256 ratio = uint256(keccak256(abi.encodePacked(block.number, block.timestamp)));
            
        //     uint256 BASIC = len*10;
        //     uint256 bn;
        //     if(quantity>BASIC){
        //         bn = (quantity-BASIC)/len+1;
        //         quantity -= (quantity-9*len);
        //     }
            
        //     for(uint256 i = 0;i<quantity;i++){
        //          uint256 sn = (ratio>>i)%len;
        //          carUsable[sn]++;
        //     }
            
        //     for(uint256 j;j<len;j++){
        //         carUsable[j]+= bn;
        //         if(carUsable[j]>counts[j]){
        //             carUsable[j] = counts[j];
        //         }
        //     }

        //     emit ObtainCar(msg.sender,version,quantity);
        // }
        
        pool.lock(msg.sender,address(this),nonce,expiry,allowed,v,r,s);
        //token1155.safeBatchTransferFrom(address(this),msg.sender,carIndex,carUsable,"success");
 
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
            
            amounts[i] = amounts[i].add(baseAmount.mul(record.digGross).div(ORE_AMOUNT));
            
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
    
    
    function getPersonalStats(uint256 _version,address userAddress) external view returns (uint256[8] memory stats,bool[3] memory stats2,uint256[] memory departs){
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
         
        departs = new uint256[](kinds());
        uint256 total;
        for(uint256 i =0;i<kinds();i++){
            uint256 depart = getDepartCars(_version,userAddress,carIndex[i]);
            departs[i] = depart;
            total = total.add(depart);
        }
        stats[7] = total;
        
     }
     

    function getDepartCars(uint256 _version,address userAddress,uint256 _carId) public view returns(uint256){
        return records[_version][userAddress].disCars[_carId];
    }
    
    
    
    function mining(address userAddress,uint256[] memory ids,uint256[] memory amounts) internal returns(uint256){
        Pair storage pair = history[version];
        require(ids.length>0&&ids.length == amounts.length,"error");
        
        uint256 carFertility;
        uint256 carCarry;
        Record storage record = records[version][userAddress];
        uint256 output;
        for(uint256 i = 0;i<ids.length;i++){
            Car memory car = cars[ids[i]];
            carFertility = carFertility.add(car.fertility.mul(amounts[i]));
            carCarry = carCarry.add(car.carry.mul(amounts[i]));
            record.disCars[ids[i]] = record.disCars[ids[i]].add(amounts[i]);
        }
        
        if(carFertility>carCarry){
            output = carCarry;
        }else{
            output = carFertility;
        }
        
        uint256 miningQuantity = pair.complete.add(carFertility);
        if(miningQuantity>=ORE_AMOUNT){ 
            if(output>ORE_AMOUNT.sub(pair.complete))  output = ORE_AMOUNT.sub(pair.complete);
            
            emit LastStraw(userAddress,version,carFertility,carCarry,output);
            lastStraw(userAddress,pair);
        }
        
        record.digGross = record.digGross.add(output);
        pair.complete = pair.complete.add(carFertility);
        pair.actual = pair.actual.add(output);
        updateRank(userAddress);
        
        token1155.safeBatchTransferFrom(address(this),owner(),ids,amounts,"success");
        
        emit Mining(userAddress,version,ids,amounts,output);
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
        for(uint8 i = 1;i<5;i++){
            for(uint8 j = 0;j<5-i;j++){
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
        records[version][userAddress].lastStraw = true;    
        
        developerFee(pair);
        version++;  
        
    }
    
     //项目方收款
    function developerFee(Pair storage pair) internal{
     
        uint256[2] memory amounts;
        for(uint256 i = 0;i<amounts.length;i++){
            amounts[i] = pair.amounts[i].mul(70).mul(ORE_AMOUNT.sub(pair.actual)).div(ORE_AMOUNT).div(100);
        }
        pool.allot(developer,amounts);
        
        emit DeveloperFee(amounts[0],amounts[1]);
    }
    
    
    
    function cat(address userAddress) public view returns(uint256[] memory,uint256[] memory counts,uint256 len,uint256 token1155Amount,uint256 quantity){
        
        ( ,uint256 investment, ) = pool.users(userAddress);
        
        (counts,token1155Amount) = determinate(); 

        uint256 dailyTokenAmount = dailyOutput[pool.duration()];
        if(dailyTokenAmount==0){
            dailyTokenAmount = token1155Amount;
        }
        uint256 totalSupply = pool.totalSupply();
        quantity = investment.mul(dailyTokenAmount).div(totalSupply);
        
        return (carIndex,counts,kinds(),token1155Amount,quantity);

    }
    
    function determinate() public view returns(uint256[] memory counts,uint256 token1155Amount){
        address _owner = owner();
        counts = new uint256[](kinds());
        for(uint8 i = 0;i<kinds();i++){
            uint256 count = token1155.balanceOf(_owner,carIndex[i]);
            counts[i] = count;
            token1155Amount+=count;
        }
		
        for(uint8 i = 0;i<kinds();i++){
            token1155Amount+=counts[i];
        }
        
    }
    
    function kinds() internal view returns (uint256) {
        return carIndex.length;
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