/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

//-*-solidity-*-
//SPDX-License-Identifier:UNLICENSED
pragma solidity >=0.7.6;
interface ICivTradeKeeper {
    
    function pools() external
	view returns(address[] memory);
    
    function orderIds(address pool) external
	view returns(uint[] memory);
    
    function hasOrder(uint tokenId) external
	view returns(bool);
    
    function getOrder(uint tokenId) external
	view  returns(address pool, address user,
		      int24   min,  int24 max, uint amt0, uint amt1);
    
    function delOrder(uint tokenId) external;
    
    function addOrder(address pool, int24 min, int24 max,
		      uint amount0, uint amount1,
		      uint tokenId, address user) external;
    
    function positionManager() external view returns(address);
    
    function setPositionManager(address contractAddress) external;
}


//pragma abicoder v2;

interface IPositionManager {
    
    function __finishPosition(uint orderId) external;
    
    function closePosition(uint orderId) external;
    
}
//-*-solidity-*-


pragma abicoder v2;




/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}







/* Signature Verification
How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)
# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

library VerifySignature {
    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )
    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(address _to,
			    uint _amount,
			    string memory _message,
			    uint _nonce
			    ) internal pure returns (bytes32) {
	return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }
    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)
    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)
    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
	/*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
	return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(address _signer,
		    address _to,
		    uint _amount,
		    string memory _message,
		    uint _nonce,
		    bytes memory signature
		    ) internal pure returns (bool) {
	bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
	bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
	return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
	internal pure returns (address) {
	(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
	return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    function splitSignature(bytes memory sig)
	internal pure returns (bytes32 r,
			       bytes32 s,
			       uint8 v) {
	require(sig.length == 65, "invalid signature length");
	assembly {
	    /*
            First 32 bytes stores the length of the signature
            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature
            mload(p) loads next 32 bytes starting at the memory address p into memory
            */
	    // first 32 bytes, after the length prefix
	    r := mload(add(sig, 32))
	    // second 32 bytes
	    s := mload(add(sig, 64))
	    // final byte (first byte of the next 32 bytes)
	    v := byte(0, mload(add(sig, 96)))
	}
	// implicitly return (r, s, v)
    }
}


interface KeeperCompatibleInterface {
    
    function checkUpkeep(bytes calldata checkData) external
	returns (bool upkeepNeeded, bytes memory performData);
    
    function performUpkeep(bytes calldata performData) external;    
}

contract CivTradeKeeper is ICivTradeKeeper, KeeperCompatibleInterface {

    using VerifySignature for bytes32;
    
    struct Order {
	uint orderId;
	int24 min;
	int24 max;
	uint  amt0;
	uint  amt1;
	address pool;
	address user;
	uint __ndx;
    }

    int24 public debugPrice = type(int24).min;

    uint public interval = 1;
    uint public lastTimeStamp = block.timestamp;

    address public owner = msg.sender;

    int public x;

    IPositionManager imgr;

    address[] public pools_;
    
    mapping(address => uint256) poolIndex_;
    
    mapping(address=>uint[]) public orderIds_;
    
    mapping(uint=>Order) public orders_;

    modifier ecprotect(bytes32 _h, bytes memory _s) {
	address a = _h.recoverSigner(_s);
	require(a == owner, "nope");
	_;
    }

    function updateInterval(uint _updateInterval) public {
	interval = _updateInterval;
    }

    function pools() view external override returns(address[] memory){
	return pools_;
    }
    
    function orderIds(address pool) view external override  returns(uint[] memory){
	return orderIds_[pool];
    }
    
    function hasOrder(uint orderId) view public override returns(bool) {
	return orders_[orderId].orderId != 0;
    }
    
    function getOrder(uint orderId) view public override
	returns(address pool, address user,
		int24 min,    int24 max,
		uint  amt0,   uint  amt1) {
	Order memory ord = orders_[orderId];
	return(ord.pool, ord.user, ord.min, ord.max, ord.amt0, ord.amt1);
    }
    
    function setDebugPrice(int24 newPrice)external {
	debugPrice = newPrice;
    }
    
    function clrDebugPrice()external {
	debugPrice = type(int24).min;
    }

    function getPrice(address pool)public view returns(int24 price){
	if(debugPrice > type(int24).min)
	    return debugPrice;
	(,price,,,,,) = IUniswapV3PoolState(pool).slot0();
    }

    function setPositionManager(address a) external override {
	imgr = IPositionManager(a);}
    
    function positionManager() external view override returns(address) {
	return address(imgr);}

    function closeOrder(uint orderId) private {
	delOrder(orderId);
	if(address(imgr)!=address(0))
	    imgr.__finishPosition(orderId);
    }

    function closeOrder(uint orderId,
			bytes32 _msgHash, bytes memory _signature)
	ecprotect(_msgHash, _signature) public
    {
	closeOrder(orderId);
    }

    function addOrder(address pool, int24 min, int24 max,
		      uint amount0, uint amount1,
		      uint orderId, address user) public override {
	require(orders_[orderId].orderId==0, "already there");
	uint[] storage ids = orderIds_[pool];
	if(ids.length==0){
	    pools_.push(pool);
	    poolIndex_[pool] = pools_.length;
	}
	ids.push(orderId);
	orders_[orderId] = Order(orderId, min, max,
				 amount0, amount1, pool,
				 user, ids.length);
    }
    
    function delOrder(uint orderId) public override {
	Order storage ord = orders_[orderId];
	require(ord.orderId!=0, "not found");
	uint[] storage ids = orderIds_[ord.pool];

	if(ids.length==1){
	    uint cur = poolIndex_[ord.pool];
	    uint len = pools_.length;
	    if(cur < len)
		poolIndex_[pools_[cur-1] =
			   pools_[len-1]] = cur;
	    pools_.pop();
	    delete poolIndex_[ord.pool];
	}
	
	uint n = ord.__ndx;
	uint m = ids.length;
	if(n<m)
	    orders_[ids[n-1] =
		    ids[m-1]].__ndx = n;
	ids.pop();
	delete orders_[orderId];
    }
    function scanOrders(address[] memory _pools, int24[] memory _prices)
	view public returns(uint[][] memory _ids) {
	uint plen = _pools.length;
	_ids = new uint[][](plen);
	for(uint p=0; p<plen; ++p){
	    address pool = _pools[p];
	    int24 price = _prices[p];
	    uint[] storage tids = orderIds_[pool];
	    bool[] memory valid = new bool[](orderIds_[pool].length);
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
		    ids[m++] = orderIds_[pool][n];
	    _ids[p] = ids;
	}
    }

    function checkUp(address[] memory _pools)
	view public returns (bool _upkeepNeeded,
			     address[] memory __pools,
			     int24[] memory _prices,
			     uint256[][] memory _ids) {
	if((block.timestamp - lastTimeStamp) > interval){
	    __pools = _pools;
	    _prices = new int24[](_pools.length);
	    for(uint n=0; n<_pools.length; ++n)
		_prices[n] = getPrice(_pools[n]);
	    _ids= scanOrders(_pools, _prices);
	    _upkeepNeeded = true;
	}
    }

    function checkUp()
	view public returns (bool _upkeepNeeded,
			     address[] memory _pools,
			     int24[] memory _prices,
			     uint256[][] memory _ids) {
	return checkUp(pools_);
    }
    
    function checkUpkeep(address[] memory _pools)
	view public returns (bool upkeepNeeded,
			     bytes memory performData) {
	(bool _upkeepNeeded,
	 address[] memory __pools,
	 int24[] memory _prices,
	 uint256[][] memory _ids) = checkUp(_pools);
	if(_upkeepNeeded)
	    return(true, abi.encode(__pools, _prices, _ids));
    }
    
    function testUpkeep() public {
	(bool upkeepNeeded,
	 bytes memory performData) = checkUpkeep();
	if(upkeepNeeded)
	    this.performUpkeep(performData);
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
	require(ord.orderId != 0, "bad token id");
	
	if(ord.amt0 > 0)
	    if(price < ord.min)
		success = true;
	if(ord.amt1 > 0)
	    if(price > ord.max)
		success = true;
    }
    
    function processOrders(address[] memory /*_pools*/,
			   int24[] memory _prices,
			   uint256[][] memory _ids) public {
	for(uint n=0; n<_ids.length; ++n){
	    //address _pool = _pools[n];
	    int24 _price = _prices[n];
	    for(uint m=0; m<_ids[n].length; ++m){
		uint256 orderId = _ids[n][m];
		if(triggered(_price, orderId)){
		    closeOrder(orderId);
		}
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