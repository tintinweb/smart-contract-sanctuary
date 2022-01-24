pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

contract CryptoGamble is Ownable {
    address bnbusd = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address ethusd = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
    address btcusd = 0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf;

    int256 public bnbPrice =   37530009301;
    int256 public ethPrice =  243407419339;
    int256 public btcPrice = 3530508000000;

    uint256 public poolsLength = 0;
    mapping(uint256 => Pool) internal bnbPools;
    mapping(uint256 => Pool) internal btcPools;
    mapping(uint256 => Pool) internal ethPools;

    Pool private defaultPool;

    struct PublicPool {
        uint256 startDate;
        uint256 endDate;
        int256 startPrice;
        int256 endPrice;
        string symbole;
        uint256 poolSize;
    }

    struct Pool {
        uint256 startDate;
        uint256 endDate;
        int256 startPrice;
        int256 endPrice;
        string symbole;
        uint256 enteredUpValue;
        uint256 enteredDownValue;
        uint256 enteredUpCount;
        uint256 enteredDownCount;
        mapping(address => uint256) enteredUp;
        mapping(address => uint256) enteredDown;
    }

    struct Bet {
        address owner;
        uint256 amount;
        bool claimed;
    }

    constructor(){
        closeLastPools();
    }

    function setBnbPrice(int256 price) public{
        bnbPrice = price;
    }

    function getBnbPrice() private view returns (int256){
        // (
        //     uint80 _roundID, 
        //     int price,
        //     uint _startedAt,
        //     uint _timeStamp,
        //     uint80 _answeredInRound
        // ) = AggregatorV3Interface(bnbusd).latestRoundData();
        return bnbPrice;
    }


    function setEthPrice(int256 price) public{
        ethPrice = price;
    }

    function getEthPrice() private view returns (int256){
        // (
        //     uint80 _roundID, 
        //     int price,
        //     uint _startedAt,
        //     uint _timeStamp,
        //     uint80 _answeredInRound
        // ) = AggregatorV3Interface(ethusd).latestRoundData();
        return ethPrice;
    }


    function setBtcPrice(int256 price) public{
        btcPrice = price;
    }

    function getBtcPrice() private view returns (int256){
        // (
        //     uint80 _roundID, 
        //     int price,
        //     uint _startedAt,
        //     uint _timeStamp,
        //     uint80 _answeredInRound
        // ) = AggregatorV3Interface(btcusd).latestRoundData();
        return btcPrice;
    }

    function startLastPool() public onlyOwner{
        Pool storage newBnbPool = bnbPools[poolsLength];
        Pool storage newBtcPool = btcPools[poolsLength];
        Pool storage newEthPool = ethPools[poolsLength];

        newBnbPool.startDate = block.timestamp;
        newBnbPool.endDate = block.timestamp + 300;
        newBnbPool.startPrice = getBnbPrice();

        newBtcPool.startDate = block.timestamp;
        newBtcPool.endDate = block.timestamp + 300;
        newBtcPool.startPrice = getBtcPrice();

        newEthPool.startDate = block.timestamp;
        newEthPool.endDate = block.timestamp + 300;
        newEthPool.startPrice = getEthPrice();
    }

    function closeLastPools() public onlyOwner{
        Pool storage bnbPool = bnbPools[poolsLength];
        Pool storage btcPool = btcPools[poolsLength];
        Pool storage ethPool = ethPools[poolsLength];

        bnbPool.endPrice = getBnbPrice();
        btcPool.endPrice = getBtcPrice();
        ethPool.endPrice = getEthPrice();

        poolsLength++;

        startLastPool();
    }

    function enterGamble(uint symbole, bool up) payable public{
        require(msg.value > 0.02 * (10 ** 18), "BNB value is too low");
        require(symbole >= 0 && symbole < 3, "Pool dosen't exist");
        uint256 amount = msg.value;
        Pool storage targetPool = defaultPool;

        if(symbole == 0){
            targetPool = bnbPools[poolsLength+1];
            targetPool.symbole = "BNB";
        }
        else if(symbole == 1){
            targetPool = btcPools[poolsLength+1];
            targetPool.symbole = "BTC";
        }
        else if(symbole == 2){
            targetPool = ethPools[poolsLength+1];
            targetPool.symbole = "ETH";
        }

        if(up == true){
            targetPool.enteredUp[msg.sender] = amount;
            targetPool.enteredUpValue += amount;
            targetPool.enteredUpCount++;
        }
        else{
            targetPool.enteredDown[msg.sender] = amount;
            targetPool.enteredDownValue += amount;
            targetPool.enteredDownCount++;
        }

        // call close last pool if(user count > 1 && lastPool.endDate < Date.now)

    }

    function getCurrentBnbPool(uint256 poolIndex) public view returns (PublicPool memory){
        Pool storage bnbPool = bnbPools[poolIndex];
        PublicPool memory pool = PublicPool({
            startDate: bnbPool.startDate,
            endDate: bnbPool.endDate,
            startPrice: bnbPool.startPrice,
            endPrice: bnbPool.endPrice,
            symbole: bnbPool.symbole,
            poolSize: bnbPool.enteredUpValue + bnbPool.enteredDownValue
        });
        return pool;
    }

    function getCurrentBtcPool(uint256 poolIndex) public view returns (PublicPool memory){
        Pool storage btcPool = btcPools[poolIndex];
        PublicPool memory pool = PublicPool({
            startDate: btcPool.startDate,
            endDate: btcPool.endDate,
            startPrice: btcPool.startPrice,
            endPrice: btcPool.endPrice,
            symbole: btcPool.symbole,
            poolSize: btcPool.enteredUpValue + btcPool.enteredDownValue
        });
        return pool;
    }

    function getCurrentEthPool(uint256 poolIndex) public view returns (PublicPool memory){
        Pool storage ethPool = ethPools[poolIndex];
        PublicPool memory pool = PublicPool({
            startDate: ethPool.startDate,
            endDate: ethPool.endDate,
            startPrice: ethPool.startPrice,
            endPrice: ethPool.endPrice,
            symbole: ethPool.symbole,
            poolSize: ethPool.enteredUpValue + ethPool.enteredDownValue
        });
        return pool;
    }

    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}