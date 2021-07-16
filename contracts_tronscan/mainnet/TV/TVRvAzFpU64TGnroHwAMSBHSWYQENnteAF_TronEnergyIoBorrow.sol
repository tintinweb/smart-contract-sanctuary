//SourceUnit: TronEnergyIoBorrow.sol

pragma solidity >=0.4.23 <0.6.0;

contract TronEnergyIoBorrow {
    //system
    address payable public owner;
    address public worker;
    bool public disabled;
    uint32 public version;

    constructor() public {
        //system
        owner = msg.sender;
        worker = msg.sender;
        lendContractAddress = msg.sender;
        disabled = false;
        version = 5;

        //options
        feeMinPay = 10;
        feeBuy = 3;
    }

    //contract system
    function() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this.");
        _;
    }

    modifier usable() {
        require(disabled == false, "The current contract has been disabled.");
        _;
    }

    modifier onlyOwnerOrWorker() {
        require(msg.sender == owner || msg.sender == worker, "Only owner can call this.");
        _;
    }

    function finalize() public payable onlyOwner {
        selfdestruct(owner);
    }

    function take(uint amount) public payable onlyOwner {
        owner.transfer(amount);
    }

    function setUsable(bool value) public onlyOwner {
        disabled = !value;
    }

    function setWorker(address value) public onlyOwner {
        worker = value;
    }

    function setVersion(uint32 value) public onlyOwner {
        version = value;
    }

    //Supply Contract
    address public lendContractAddress;

    function setLendContractAddress(address value) public onlyOwner {
        lendContractAddress = value;
    }

    function getOptions() public view returns (uint32 FeeMinPay, uint32 FeeBuy){
        return (feeMinPay, feeBuy);
    }

    //Pool
    uint8 constant POOL_STATUS_ACTIVE = 1;
    uint8 constant POOL_STATUS_INACTIVE = 2;

    struct Pool {
        uint32 poolId;
        uint8 status; //1: active, inactive
        uint8 poolType; //1: official, 2: public, 3: seller
        address supplyAddress;
        address payable awardAddress;
        uint64 minFreezeTrx;
        uint64 maxFreezeTrx;
        uint32 price;
        uint16 minFreezeDays;
        uint64 keepTrx;
        uint64 holdingTrx;
        uint64 lockingTrx;
    }

    mapping(uint32 => Pool) public pools;
    uint32[] public poolIds;

    function getPoolCount() public view returns (uint32) {
        return uint32(poolIds.length);
    }

    function addPool(
        uint32 poolId,
        uint8 poolType,
        address supplyAddress,
        address payable awardAddress,
        uint64 minFreezeTrx,
        uint64 maxFreezeTrx,
        uint32 price,
        uint16 minFreezeDays,
        uint64 keepTrx
    ) public onlyOwner {
        for (uint i = 0; i < poolIds.length; i++) {
            if (poolIds[i] == poolId) {
                require(false, 'Duplicated Pool Id');
            }
        }

        require(poolId > 0, 'Invalid poolId');
        require(poolType > 0, 'Invalid poolType');
        require(uint(supplyAddress) != 0, 'Invalid poolAddress');
        require(uint(awardAddress) != 0, 'Invalid awardAddress');
        require(minFreezeTrx > 0, 'Invalid minFreezeTrx');
        require(maxFreezeTrx > 0, 'Invalid maxFreezeTrx');
        require(price > 0, 'Invalid price');
        require(minFreezeDays >= 3, 'Invalid minFreezeDays');


        pools[poolId] = Pool({
        poolId : poolId,
        status : POOL_STATUS_ACTIVE,
        poolType : poolType,
        supplyAddress : supplyAddress,
        awardAddress : awardAddress,
        minFreezeTrx : minFreezeTrx,
        maxFreezeTrx : maxFreezeTrx,
        price : price,
        minFreezeDays : minFreezeDays,
        keepTrx : keepTrx,
        holdingTrx : 0,
        lockingTrx : 0
        });

        poolIds.push(poolId);
    }

    function removePool(
        uint32 poolId
    ) public onlyOwner {
        uint index = poolIds.length;
        for (uint i = 0; i < poolIds.length; i++) {
            if (poolIds[i] == poolId) {
                index = i;
                break;
            }
        }
        if (index < poolIds.length) {
            for (uint i = index; i < poolIds.length - 1; i++) {
                poolIds[i] = poolIds[i + 1];
            }
            delete poolIds[poolIds.length - 1];
            poolIds.length--;
        }

        delete pools[poolId];
    }

    function updatePool(
        uint32 poolId,
        uint8 poolType,
        address payable awardAddress,
        uint64 minFreezeTrx,
        uint64 maxFreezeTrx,
        uint32 price,
        uint16 minFreezeDays,
        uint64 keepTrx
    ) public onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");

        require(poolType > 0, 'Invalid poolType');
        require(uint(awardAddress) != 0, 'Invalid awardAddress');
        require(minFreezeTrx > 0, 'Invalid minFreezeTrx');
        require(maxFreezeTrx > 0, 'Invalid maxFreezeTrx');
        require(price > 0, 'Invalid price');
        require(minFreezeDays >= 3, 'Invalid minFreezeDays');

        pool.poolType = poolType;
        pool.awardAddress = awardAddress;
        pool.minFreezeTrx = minFreezeTrx;
        pool.maxFreezeTrx = maxFreezeTrx;
        pool.price = price;
        pool.minFreezeDays = minFreezeDays;
        pool.keepTrx = keepTrx;
    }

    function updatePoolStatus(
        uint32 poolId,
        uint8 status
    ) public onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");

        pool.status = status;
    }

    function updatePoolPrice(
        uint32 poolId,
        uint64 minFreezeTrx,
        uint32 price
    ) public onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");

        pool.minFreezeTrx = minFreezeTrx;
        pool.price = price;
    }

    function updatePoolKeepTrx(
        uint32 poolId,
        uint64 keepTrx
    ) public onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");

        pool.keepTrx = keepTrx;
    }

    function updatePoolHoldingTrx(
        uint32 poolId,
        uint64 holdingTrx
    ) public onlyOwner {
        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");

        pool.holdingTrx = holdingTrx;
    }

    function updatePoolLockingTrx(
        uint32 poolId,
        uint64 lockingTrx
    ) public {
        if (msg.sender == lendContractAddress || msg.sender == owner) {
            //ok
        }
        else {
            require(false, "Only owner can call this.");
        }

        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");

        pool.lockingTrx = lockingTrx;
    }

    function getPool(uint32 PoolId) public view returns (
        uint32 poolId,
        uint8 status,
        uint8 poolType,
        address supplyAddress,
        address awardAddress,
        uint64 minFreezeTrx,
        uint64 maxFreezeTrx,
        uint32 price,
        uint64 minFreezeDays,
        uint64 usableTrx,
        uint64 balanceTrx
    ) {
        Pool memory pool = pools[PoolId];
        if (pool.poolId > 0) {

            balanceTrx = uint64(address(pool.supplyAddress).balance / 1_000_000);
            if (balanceTrx > pool.keepTrx + pool.holdingTrx + pool.lockingTrx) {
                usableTrx = balanceTrx - (pool.keepTrx + pool.holdingTrx + pool.lockingTrx);
            }
            else {
                usableTrx = 0;
            }

            return (pool.poolId,
            pool.status,
            pool.poolType,
            pool.supplyAddress,
            pool.awardAddress,
            pool.minFreezeTrx,
            pool.maxFreezeTrx,
            pool.price,
            pool.minFreezeDays,
            usableTrx,
            balanceTrx);
        }
        else {
            return (0,
            pool.status,
            pool.poolType,
            pool.supplyAddress,
            pool.awardAddress,
            pool.minFreezeTrx,
            pool.maxFreezeTrx,
            pool.price,
            pool.minFreezeDays,
            0,
            0);
        }
    }

    function getPools(
        uint32 page,
        uint32 rowCount
    ) public view returns (
        uint32[] memory poolIdList,
        uint8[] memory statusList,
        address[] memory supplyAddressList,
        uint64[] memory minFreezeDaysList,
        uint64[] memory minFreezeTrxList,
        uint32[] memory priceList,
        uint64[] memory usableTrxList
    ) {
        uint start = (page - 1) * rowCount;
        if (start >= poolIds.length) {
            return (new uint32[](0),
            new uint8[](0),
            new address[](0),
            new uint64[](0),
            new uint64[](0),
            new uint32[](0),
            new uint64[](0));
        }

        uint end = start + rowCount;
        if (end > poolIds.length) {
            end = poolIds.length;
        }

        uint32 count = uint32(end - start);

        poolIdList = new uint32[](count);
        statusList = new uint8[](count);
        supplyAddressList = new address[](count);
        minFreezeDaysList = new uint64[](count);
        minFreezeTrxList = new uint64[](count);
        priceList = new uint32[](count);
        usableTrxList = new uint64[](count);

        for (uint i = start; i < end; i++) {
            uint index = i - start;
            Pool memory pool = pools[poolIds[i]];
            if (pool.poolId > 0) {
                poolIdList[index] = pool.poolId;
                statusList[index] = pool.status;
                supplyAddressList[index] = pool.supplyAddress;
                minFreezeDaysList[index] = pool.minFreezeDays;
                minFreezeTrxList[index] = pool.minFreezeTrx;
                priceList[index] = pool.price;

                uint64 b = uint64(address(pool.supplyAddress).balance / 1_000_000);
                if (b > pool.keepTrx + pool.holdingTrx + pool.lockingTrx) {
                    usableTrxList[index] = b - (pool.keepTrx + pool.holdingTrx + pool.lockingTrx);
                }
                else {
                    usableTrxList[index] = 0;
                }
            }
            else {
                poolIdList[index] = 0;
                statusList[index] = pool.status;
                supplyAddressList[index] = pool.supplyAddress;
                minFreezeDaysList[index] = 0;
                minFreezeTrxList[index] = 0;
                priceList[index] = 0;
                usableTrxList[index] = 0;
            }
        }
    }

    function getPoolsExtra(
        uint32 page,
        uint32 rowCount
    ) public view returns (
        uint32[] memory poolIdList,
        uint8[] memory poolTypeList,
        address[] memory awardAddressList,
        uint64[] memory maxFreezeTrxList,
        uint64[] memory keepTrxList,
        uint64[] memory holdingTrxList,
        uint64[] memory lockingTrxList
    ) {
        uint start = (page - 1) * rowCount;
        if (start >= poolIds.length) {
            return (new uint32[](0),
            new uint8[](0),
            new address[](0),
            new uint64[](0),
            new uint64[](0),
            new uint64[](0),
            new uint64[](0));
        }

        uint end = start + rowCount;
        if (end > poolIds.length) {
            end = poolIds.length;
        }

        uint32 count = uint32(end - start);

        poolIdList = new uint32[](count);
        poolTypeList = new uint8[](count);
        awardAddressList = new address[](count);
        maxFreezeTrxList = new uint64[](count);
        keepTrxList = new uint64[](count);
        holdingTrxList = new uint64[](count);
        lockingTrxList = new uint64[](count);

        for (uint i = start; i < end; i++) {
            uint index = i - start;
            Pool memory pool = pools[poolIds[i]];
            if (pool.poolId > 0) {
                poolIdList[index] = pool.poolId;
                poolTypeList[index] = pool.poolType;
                awardAddressList[index] = pool.awardAddress;
                maxFreezeTrxList[index] = pool.maxFreezeTrx;
                keepTrxList[index] = pool.keepTrx;
                holdingTrxList[index] = pool.holdingTrx;
                lockingTrxList[index] = pool.lockingTrx;
            }
            else {
                poolIdList[index] = 0;
                poolTypeList[index] = pool.poolType;
                awardAddressList[index] = pool.awardAddress;
                maxFreezeTrxList[index] = pool.maxFreezeTrx;
                keepTrxList[index] = pool.keepTrx;
                holdingTrxList[index] = pool.holdingTrx;
                lockingTrxList[index] = pool.lockingTrx;
            }
        }
    }

    function calculateOrder(
        uint32 poolId,
        uint64 freezeTrx,
        uint64 freezeDays,
        uint64 hasFrozenTrx,
        uint64 hasFrozenTrxExpire,
        uint64 orderTime
    ) public view returns (uint32 status, uint64 curOrderPay, uint64 curOrderFee, uint64 existedOrderPay){

        if (disabled == true) {
            return (0, 0, 0, 0);
        }

        Pool memory pool = pools[poolId];
        if (pool.poolId > 0) {
            //ok
        }
        else {
            return (2, 0, 0, 0);
        }

        if (pool.status == POOL_STATUS_ACTIVE) {
            //ok
        }
        else {
            return (3, 0, 0, 0);
        }

        if (freezeTrx > 0 && freezeTrx >= pool.minFreezeTrx) {
            //ok
        }
        else {
            return (4, 0, 0, 0);
        }
        if (freezeTrx <= pool.maxFreezeTrx) {
            //ok
        }
        else {
            return (5, 0, 0, 0);
        }

        if (freezeDays >= 3 && freezeDays >= pool.minFreezeDays) {
            //ok
        }
        else {
            return (6, 0, 0, 0);
        }
        if (freezeDays <= 300) {
            //ok
        }
        else {
            return (7, 0, 0, 0);
        }

        curOrderPay = freezeTrx * pool.price * freezeDays;

        if (curOrderPay < feeMinPay * 1_000_000) {
            curOrderFee = feeBuy * 1_000_000;
        }
        else {
            curOrderFee = 0;
        }

        existedOrderPay = 0;
        if (hasFrozenTrx > 0) {
            uint64 curOrderExpire = orderTime + (freezeDays * 24 * 3600 * 1000);
            if (curOrderExpire > hasFrozenTrxExpire) {
                uint64 diff = curOrderExpire - hasFrozenTrxExpire;
                uint64 hs = diff / (1800 * 1000);
                if (diff % (1800 * 1000) > 0) {
                    hs = hs + 1;
                }
                existedOrderPay = ((hasFrozenTrx / 1_000_000) * pool.price * hs) / 48;
            }
        }

        {
            uint left = address(pool.supplyAddress).balance;
            uint used = (pool.keepTrx + pool.holdingTrx + pool.lockingTrx) * 1_000_000;
            if (left > used) {
                left = left - used;
            }
            else {
                left = 0;
            }

            if (left >= freezeTrx * 1_000_000) {
                //ok
            }
            else {
                return (8, 0, 0, 0);
            }
        }

        return (1, curOrderPay, curOrderFee, existedOrderPay);
    }

    uint32 public feeMinPay;
    uint32 public feeBuy;

    function setFeeMinPay(uint32 value) public onlyOwner {
        feeMinPay = value;
    }

    function setFeeBuy(uint32 value) public onlyOwner {
        feeBuy = value;
    }

    function createOrder(
        uint32 poolId,
        uint8 resType,
        uint64 freezeTrx,
        uint64 freezeDays,
        address receiveAddress,
        uint64 hasFrozenTrx,
        uint64 hasFrozenTrxExpire,
        uint64 orderTime
    ) public usable payable returns (
        uint64 curOrderPay,
        uint64 curOrderFee,
        uint64 existedOrderPay
    ){
        if (msg.value >= 3_000_000) {
            //ok
        }
        else {
            require(false, "Invalid Pay Amount");
        }

        if (hasFrozenTrx > 0) {
            if (orderTime / 1000 >= block.timestamp) {
                //ok
            }
            else {
                require(false, "Invalid orderTime");
            }
        }

        Pool storage pool = pools[poolId];
        if (pool.poolId > 0) {
            //ok
        }
        else {
            require(false, "Invalid poolId");
        }

        if (pool.status == POOL_STATUS_ACTIVE) {
            //ok
        }
        else {
            require(false, "Pool is inactive");
        }

        if (freezeTrx > 0 && freezeTrx >= pool.minFreezeTrx) {
            //ok
        }
        else {
            require(false, "freezeTrx is too small");
        }
        if (freezeTrx <= pool.maxFreezeTrx) {
            //ok
        }
        else {
            require(false, "freezeTrx is too big");
        }

        if (freezeDays >= 3 && freezeDays >= pool.minFreezeDays) {
            //ok
        }
        else {
            require(false, "freezeDays is too small");
        }
        if (freezeDays <= 300) {
            //ok
        }
        else {
            require(false, "freezeDays is too big");
        }


        curOrderPay = freezeTrx * pool.price * freezeDays;
        curOrderFee = 0;
        if (curOrderPay < feeMinPay * 1_000_000) {
            curOrderFee = feeBuy * 1_000_000;
        }

        existedOrderPay = 0;
        if (hasFrozenTrx > 0) {
            uint64 curOrderExpire = orderTime + (freezeDays * 24 * 3600 * 1000);
            if (curOrderExpire > hasFrozenTrxExpire) {
                uint64 diff = curOrderExpire - hasFrozenTrxExpire;
                uint64 hs = diff / (1800 * 1000);
                if (diff % (1800 * 1000) > 0) {
                    hs = hs + 1;
                }
                existedOrderPay = ((hasFrozenTrx / 1_000_000) * pool.price * hs) / 48;
            }
        }

        if (msg.value >= curOrderPay + curOrderFee + existedOrderPay) {
            //ok
        }
        else {
            require(false, "Invalid Pay Amount.");
        }

        if (address(pool.supplyAddress).balance >= (pool.keepTrx + pool.holdingTrx + pool.lockingTrx + freezeTrx) * 1_000_000) {
            //ok
        }
        else {
            require(false, "Balance not enough");
        }

        pool.holdingTrx = pool.holdingTrx + freezeTrx;
    }

    function completeOrder(
        uint orderTxId,
        uint freezeTxId,
        uint32 orderId,
        uint32 poolId,
        uint64 freezeTrx,
        uint64 awardTrx
    ) public onlyOwnerOrWorker {
        require(orderTxId != 0, "Invalid orderTxId");
        require(orderId != 0, "Invalid orderId");

        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");
        if (pool.holdingTrx >= freezeTrx) {
            pool.holdingTrx = pool.holdingTrx - freezeTrx;
        }
        else {
            pool.holdingTrx = 0;
        }

        pool.awardAddress.transfer(awardTrx);
    }

    function requestCancelOrder(
        uint orderTxId,
        uint32 orderId
    ) public onlyOwnerOrWorker {
        require(orderTxId != 0, "Invalid orderTxId");
        require(orderId != 0, "Invalid orderId");
    }

    function cancelOrder(
        uint orderTxId,
        uint32 orderId,
        uint32 poolId,
        uint64 freezeTrx,
        address payable returnAddress,
        uint64 returnTrx
    ) public onlyOwnerOrWorker {
        require(orderTxId != 0, "Invalid orderTxId");
        require(orderId != 0, "Invalid orderId");

        Pool storage pool = pools[poolId];
        require(pool.poolId > 0, "Invalid poolId");
        if (pool.holdingTrx >= freezeTrx) {
            pool.holdingTrx = pool.holdingTrx - freezeTrx;
        }
        else {
            pool.holdingTrx = 0;
        }

        returnAddress.transfer(returnTrx);
    }
}