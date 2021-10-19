/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

//-*-solidity-*-                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
//SPDX-License-Identifier:UNLICENSED                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
pragma solidity >=0.7.0;
pragma abicoder v2;
interface ILimitManager {
    function closeLimitTrade(uint tokenId) external;
}
interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external
        returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}
interface IUniswapV3PoolState_Minimum {
    function slot0() external view
        returns (uint160 sqrtPriceX96,
                 int24 tick,
                 uint16 observationIndex,
                 uint16 observationCardinality,
                 uint16 observationCardinalityNext,
                 uint8 feeProtocol,
                 bool unlocked);
}
interface IOrderBook {
    function pools() external
        view returns(address[] memory);
    function tokenIds(address pool) external
        view returns(uint[] memory);
    function hasOrder(uint tokenId) external
        view returns(bool);
    function getOrder(uint tokenId) external
        view  returns(address pool,
                      int24   min,  int24 max, uint amt0, uint amt1);
    function delOrder(uint tokenId) external;
    function addOrder(address pool, int24 min, int24 max,
                      uint amount0, uint amount1,
                      uint tokenId, address user) external;
    function limitTradeManager() external view returns(address);
    function setLimitTradeManager(address contractAddress) external;
}
contract OrderBook is IOrderBook, KeeperCompatibleInterface {

    int24 debugPrice = type(int24).min;

    function setDebugPrice(int24 newPrice)external {
        debugPrice = newPrice;
    }
    function clrDebugPrice()external {
        debugPrice = type(int24).min;
    }

    function getPrice(address pool)internal view returns(int24 price){
        if(debugPrice > type(int24).min)
            return debugPrice;
        (,price,,,,,) = IUniswapV3PoolState_Minimum(pool).slot0();
    }

    ILimitManager imgr;
    function setLimitTradeManager(address a) external override {
        imgr = ILimitManager(a);}
    function limitTradeManager() external view override returns(address) {
        return address(imgr);}

    function closeOrder(uint tokenId) internal {
        delOrder(tokenId);
        if(address(imgr)!=address(0))
            imgr.closeLimitTrade(tokenId);
    }

    struct Order {
        uint tokenId;
        int24 min;
        int24 max;
        uint  amt0;
        uint  amt1;
        address pool;
        address user;
        uint __ndx;
    }
    address[] pools_;
    mapping(address => uint256) poolIndex_;
    mapping(address=>uint[]) tokenIds_;
    mapping(uint=>Order) orders_;
    function pools() view external override returns(address[] memory){
        return pools_;
    }
    function tokenIds(address pool) view external override  returns(uint[] memory){
        return tokenIds_[pool];
    }
    function hasOrder(uint tokenId) view public override returns(bool) {
        return orders_[tokenId].tokenId == 0;
    }
    function getOrder(uint tokenId) view public override
        returns(address pool,
                int24 min,    int24 max,
                uint  amt0,   uint  amt1) {
        Order memory ord = orders_[tokenId];
        return(ord.pool, ord.min, ord.max, ord.amt0, ord.amt1);
    }
    function addOrder(address pool, int24 min, int24 max,
                      uint amount0, uint amount1,
                      uint tokenId, address user) public override {
        require(orders_[tokenId].tokenId==0, "already there");
        uint[] storage ids = tokenIds_[pool];
        if(ids.length==0){
            pools_.push(pool);
            poolIndex_[pool] = pools_.length;
        }
        orders_[tokenId] = Order(tokenId, min, max,
                                 amount0, amount1, pool,
                                 user, ids.length);
        ids.push(tokenId);
    }
    function delOrder(uint tokenId) public override {
        Order storage ord = orders_[tokenId];
        require(ord.tokenId!=0, "not found");
        address opool = ord.pool;
        uint[] storage ids = tokenIds_[ord.pool];
        ids[ord.__ndx] = ids[ids.length-1];
        ids.pop();
        delete orders_[tokenId];
        if(ids.length==0){
            uint len = pools_.length;
            uint cur = poolIndex_[opool];
            address a = pools_[cur-1] = pools_[len-1];
            pools_.pop();
            delete poolIndex_[ord.pool];
            poolIndex_[a] = cur;
        }
    }
    function scanOrders(address[] memory _pools, int24[] memory _prices)
        view public returns(uint[][] memory _ids) {
        uint plen = _pools.length;
        _ids = new uint[][](plen);
        for(uint p=0; p<plen; ++p){
            address pool = _pools[p];
            int24 price = _prices[p];
            uint[] storage tids = tokenIds_[pool];
            bool[] memory valid = new bool[](tokenIds_[pool].length);
            uint nlen = valid.length;
            uint mlen = 0;
            for(uint n=0; n<nlen; ++n){
                Order storage ord = orders_[tids[n]];
                bool isValid = true;
                isValid = (price < ord.min || price > ord.max);
                if(isValid) {
                    valid[n] = true;
                    ++mlen;
                }
            }
            uint[] memory ids = new uint[](mlen);
            uint m;
            for(uint n=0; n<nlen; ++n)
                if(valid[n])
                    ids[m++] = tokenIds_[pool][n];
            _ids[p] = ids;
        }
    }

    uint public interval;
    uint public lastTimeStamp;

    constructor(uint updateInterval) {interval = updateInterval;}

    function checkUpkeep(address[] memory _pools)
        view public returns (bool upkeepNeeded,
                             bytes memory performData) {
        if(_pools.length == 0)
            _pools = pools_;
        if((block.timestamp - lastTimeStamp) > interval){
            int24[] memory prices = new int24[](_pools.length);
            for(uint n=0; n<_pools.length; ++n)
                prices[n] = getPrice(_pools[n]);
            uint256[][] memory ids= this.scanOrders(_pools, prices);
            return(true, abi.encode(_pools, prices, ids));
        }
    }
    function checkUpkeep()
        view public returns (bool upkeepNeeded,
                             bytes memory performData) {
        return checkUpkeep(pools_);
    }
    function checkUpkeep(bytes calldata /*checkData*/)
        view override external returns (bool upkeepNeeded,
                                        bytes memory performData) {
        return checkUpkeep();
    }
    function triggered(int24 price, uint256 id
                       ) public view returns(bool success) {
        Order memory ord = orders_[id];
        if(ord.tokenId != 0)
            success = (ord.min < price || price > ord.max);
    }
    function processOrders(address[] memory /*_pools*/,
                           int24[] memory _prices,
                           uint256[][] memory _ids)
        internal {
        for(uint n=0; n<_ids.length; ++n){
            //address _pool = _pools[n];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
            int24 _price = _prices[n];
            for(uint m=0; m<_ids[n].length; ++m){
                uint256 tokenId = _ids[n][m];
                if(triggered(_price, tokenId))
                    closeOrder(tokenId);
            }
        }
    }
    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        (address[] memory _pools,
         int24[] memory _oldPrices,
         uint256[][] memory _ids) =
            abi.decode(performData, (address[], int24[], uint256[][]));
        processOrders(_pools, _oldPrices, _ids);
    }
}