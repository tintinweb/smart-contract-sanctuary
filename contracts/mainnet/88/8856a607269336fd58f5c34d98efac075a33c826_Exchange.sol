/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.25;

/* Interface for ERC20 Tokens */
contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

/* Interface for the DMEX base contract */
contract EtherMium {
    function getReserve(address token, address user) returns (uint256);
    function setReserve(address token, address user, uint256 amount) returns (bool);

    function availableBalanceOf(address token, address user) returns (uint256);
    function balanceOf(address token, address user) returns (uint256);


    function setBalance(address token, address user, uint256 amount) returns (bool);
    function getAffiliate(address user) returns (address);
    function getInactivityReleasePeriod() returns (uint256);
    function getMakerTakerBalances(address token, address maker, address taker) returns (uint256[4]);

    function getEtmTokenAddress() returns (address);

    function subBalanceAddReserve(address token, address user, uint256 subBalance, uint256 addReserve) returns (bool);
    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) returns (bool);
    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) returns (bool);

}



// The DMEX Futures Contract
contract Exchange {
    function assert(bool assertion) pure {
        
        if (!assertion) {
            throw;
        }
    }

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    address public owner; // holds the address of the contract owner

    // Event fired when the owner of the contract is changed
    event SetOwner(address indexed previousOwner, address indexed newOwner);

    // Allows only the owner of the contract to execute the function
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // Allows only the owner of the contract to execute the function
    modifier onlyOracle {
        assert(msg.sender == DmexOracleContract);
        _;
    }

    // Changes the owner of the contract
    function setOwner(address newOwner) onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }

    // Owner getter function
    function getOwner() view returns (address out) {
        return owner;
    }

    mapping (address => bool) public admins;                    // mapping of admin addresses
    mapping (address => uint256) public lastActiveTransaction;  // mapping of user addresses to last transaction block
    mapping (bytes32 => uint256) public orderFills;             // mapping of orders to filled qunatity
    
    address public feeAccount;          // the account that receives the trading fees
    address public exchangeContract;    // the address of the main EtherMium contract
    address public DmexOracleContract;    // the address of the DMEX math contract used for some calculations

    uint256 public makerFee;            // maker fee in percent expressed as a fraction of 1 ether (0.1 ETH = 10%)
    uint256 public takerFee;            // taker fee in percent expressed as a fraction of 1 ether (0.1 ETH = 10%)
    
    struct FuturesAsset {
        string name;                    // the name of the traded asset (ex. ETHUSD)
        address baseToken;              // the token for collateral
        string priceUrl;                // the url where the price of the asset will be taken for settlement
        string pricePath;               // price path in the returned JSON from the priceUrl (ex. path "last" will return tha value last from the json: {"high": "156.49", "last": "154.31", "timestamp": "1556522201", "bid": "154.22", "vwap": "154.65", "volume": "25578.79138868", "low": "152.33", "ask": "154.26", "open": "152.99"})
        bool inversed;                  // if true, the price from the priceUrl will be inversed (i.e price = 1/priceUrl)
        bool disabled;                  // if true, the asset cannot be used in contract creation (when price url no longer valid)
    }

    function createFuturesAsset(string name, address baseToken, string priceUrl, string pricePath, bool inversed) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresAsset = keccak256(this, name, baseToken, priceUrl, pricePath, inversed);
        if (futuresAssets[futuresAsset].disabled) throw; // asset already exists and is disabled

        futuresAssets[futuresAsset] = FuturesAsset({
            name                : name,
            baseToken           : baseToken,
            priceUrl            : priceUrl,
            pricePath           : pricePath,
            inversed            : inversed,
            disabled            : false
        });

        emit FuturesAssetCreated(futuresAsset, name, baseToken, priceUrl, pricePath, inversed);
        return futuresAsset;
    }
    
    struct FuturesContract {
        bytes32 asset;                  // the hash of the underlying asset object
        uint256 expirationBlock;        // futures contract expiration block
        uint256 closingPrice;           // the closing price for the futures contract
        bool closed;                    // is the futures contract closed (0 - false, 1 - true)
        bool broken;                    // if someone has forced release of funds the contract is marked as broken and can no longer close positions (0-false, 1-true)
        uint256 floorPrice;             // the minimum price that can be traded on the contract, once price is reached the contract expires and enters settlement state 
        uint256 capPrice;               // the maximum price that can be traded on the contract, once price is reached the contract expires and enters settlement state
        uint256 multiplier;             // the multiplier price, used when teh trading pair doesn&#39;t have the base token in it (eg. BTCUSD with ETH as base token, multiplier will be the ETHBTC price)
    }

    function createFuturesContract(bytes32 asset, uint256 expirationBlock, uint256 floorPrice, uint256 capPrice, uint256 multiplier) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresContract = keccak256(this, asset, expirationBlock, floorPrice, capPrice, multiplier);
        if (futuresContracts[futuresContract].expirationBlock > 0) return futuresContract; // contract already exists

        futuresContracts[futuresContract] = FuturesContract({
            asset           : asset,
            expirationBlock : expirationBlock,
            closingPrice    : 0,
            closed          : false,
            broken          : false,
            floorPrice      : floorPrice,
            capPrice        : capPrice,
            multiplier      : multiplier
        });

        emit FuturesContractCreated(futuresContract, asset, expirationBlock, floorPrice, capPrice, multiplier);

        return futuresContract;
    }

    function getContractExpiration (bytes32 futuresContractHash) view returns (uint256)
    {
        return futuresContracts[futuresContractHash].expirationBlock;
    }

    function getContractClosed (bytes32 futuresContractHash) returns (bool)
    {
        return futuresContracts[futuresContractHash].closed;
    }

    function getContractPriceUrl (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].priceUrl;
    }

    function getContractPricePath (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].pricePath;
    }

    mapping (bytes32 => FuturesAsset)       public futuresAssets;      // mapping of futuresAsset hash to FuturesAsset structs
    mapping (bytes32 => FuturesContract)    public futuresContracts;   // mapping of futuresContract hash to FuturesContract structs
    mapping (bytes32 => uint256)            public positions;          // mapping of user addresses to position hashes to position


    enum Errors {
        INVALID_PRICE,                  // Order prices don&#39;t match
        INVALID_SIGNATURE,              // Signature is invalid
        ORDER_ALREADY_FILLED,           // Order was already filled
        GAS_TOO_HIGH,                   // Too high gas fee
        OUT_OF_BALANCE,                 // User doesn&#39;t have enough balance for the operation
        FUTURES_CONTRACT_EXPIRED,       // Futures contract already expired
        FLOOR_OR_CAP_PRICE_REACHED,     // The floor price or the cap price for the futures contract was reached
        POSITION_ALREADY_EXISTS,        // User has an open position already 
        UINT48_VALIDATION,              // Size or price bigger than an Uint48
        FAILED_ASSERTION                // Assertion failed
    }

    event FuturesTrade(bool side, uint256 size, uint256 price, bytes32 indexed futuresContract, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event FuturesPositionClosed(bytes32 indexed positionHash);
    event FuturesContractClosed(bytes32 indexed futuresContract, uint256 closingPrice);
    event FuturesForcedRelease(bytes32 indexed futuresContract, bool side, address user);
    event FuturesAssetCreated(bytes32 indexed futuresAsset, string name, address baseToken, string priceUrl, string pricePath, bool inversed);
    event FuturesContractCreated(bytes32 indexed futuresContract, bytes32 asset, uint256 expirationBlock, uint256 floorPrice, uint256 capPrice, uint256 multiplier);
 
    // Fee change event
    event FeeChange(uint256 indexed makerFee, uint256 indexed takerFee);

    // Log event, logs errors in contract execution (for internal use)
    event LogError(uint8 indexed errorId, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event LogErrorLight(uint8 indexed errorId);
    event LogUint(uint8 id, uint256 value);
    event LogBool(uint8 id, bool value);
    event LogAddress(uint8 id, address value);


    // Constructor function, initializes the contract and sets the core variables
    function Exchange(address feeAccount_, uint256 makerFee_, uint256 takerFee_, address exchangeContract_, address DmexOracleContract_) {
        owner               = msg.sender;
        feeAccount          = feeAccount_;
        makerFee            = makerFee_;
        takerFee            = takerFee_;

        exchangeContract    = exchangeContract_;
        DmexOracleContract    = DmexOracleContract_;
    }

    // Changes the fees
    function setFees(uint256 makerFee_, uint256 takerFee_) onlyOwner {
        require(makerFee_       < 10 finney && takerFee_ < 10 finney); // The fees cannot be set higher then 1%
        makerFee                = makerFee_;
        takerFee                = takerFee_;

        emit FeeChange(makerFee, takerFee);
    }

    // Adds or disables an admin account
    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }

    // Allows for admins only to call the function
    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }

    function() external {
        throw;
    }   


    function validateUint48(uint256 val) returns (bool)
    {
        if (val != uint48(val)) return false;
        return true;
    }

    function validateUint64(uint256 val) returns (bool)
    {
        if (val != uint64(val)) return false;
        return true;
    }

    function validateUint128(uint256 val) returns (bool)
    {
        if (val != uint128(val)) return false;
        return true;
    }


    // Structure that holds order values, used inside the trade() function
    struct FuturesOrderPair {
        uint256 makerNonce;                 // maker order nonce, makes the order unique
        uint256 takerNonce;                 // taker order nonce
        uint256 takerGasFee;                // taker gas fee, taker pays the gas
        uint256 takerIsBuying;              // true/false taker is the buyer

        address maker;                      // address of the maker
        address taker;                      // address of the taker

        bytes32 makerOrderHash;             // hash of the maker order
        bytes32 takerOrderHash;             // has of the taker order

        uint256 makerAmount;                // trade amount for maker
        uint256 takerAmount;                // trade amount for taker

        uint256 makerPrice;                 // maker order price in wei (18 decimal precision)
        uint256 takerPrice;                 // taker order price in wei (18 decimal precision)

        bytes32 futuresContract;            // the futures contract being traded

        address baseToken;                  // the address of the base token for futures contract
        uint256 floorPrice;                 // floor price of futures contract
        uint256 capPrice;                   // cap price of futures contract

        bytes32 makerPositionHash;          // hash for maker position
        bytes32 makerInversePositionHash;   // hash for inverse maker position 

        bytes32 takerPositionHash;          // hash for taker position
        bytes32 takerInversePositionHash;   // hash for inverse taker position
    }

    // Structure that holds trade values, used inside the trade() function
    struct FuturesTradeValues {
        uint256 qty;                // amount to be trade
        uint256 makerProfit;        // holds maker profit value
        uint256 makerLoss;          // holds maker loss value
        uint256 takerProfit;        // holds taker profit value
        uint256 takerLoss;          // holds taker loss value
        uint256 makerBalance;       // holds maker balance value
        uint256 takerBalance;       // holds taker balance value
        uint256 makerReserve;       // holds taker reserved value
        uint256 takerReserve;       // holds taker reserved value
    }

    // Opens/closes futures positions
    function futuresTrade(
        uint8[2] v,
        bytes32[4] rs,
        uint256[8] tradeValues,
        address[2] tradeAddresses,
        bool takerIsBuying,
        bytes32 futuresContractHash
    ) onlyAdmin returns (uint filledTakerTokenAmount)
    {
        /* tradeValues
          [0] makerNonce
          [1] takerNonce
          [2] takerGasFee
          [3] takerIsBuying
          [4] makerAmount
          [5] takerAmount
          [6] makerPrice
          [7] takerPrice

          tradeAddresses
          [0] maker
          [1] taker
        */

        FuturesOrderPair memory t  = FuturesOrderPair({
            makerNonce      : tradeValues[0],
            takerNonce      : tradeValues[1],
            takerGasFee     : tradeValues[2],
            takerIsBuying   : tradeValues[3],
            makerAmount     : tradeValues[4],      
            takerAmount     : tradeValues[5],   
            makerPrice      : tradeValues[6],         
            takerPrice      : tradeValues[7],

            maker           : tradeAddresses[0],
            taker           : tradeAddresses[1],

            //                                futuresContract      user               amount          price           side             nonce
            makerOrderHash  : keccak256(this, futuresContractHash, tradeAddresses[0], tradeValues[4], tradeValues[6], !takerIsBuying, tradeValues[0]),
            takerOrderHash  : keccak256(this, futuresContractHash, tradeAddresses[1], tradeValues[5], tradeValues[7],  takerIsBuying, tradeValues[1]),            

            futuresContract : futuresContractHash,

            baseToken       : futuresAssets[futuresContracts[futuresContractHash].asset].baseToken,
            floorPrice      : futuresContracts[futuresContractHash].floorPrice,
            capPrice        : futuresContracts[futuresContractHash].capPrice,

            //                                            user               futuresContractHash   side
            makerPositionHash           : keccak256(this, tradeAddresses[0], futuresContractHash, !takerIsBuying),
            makerInversePositionHash    : keccak256(this, tradeAddresses[0], futuresContractHash, takerIsBuying),

            takerPositionHash           : keccak256(this, tradeAddresses[1], futuresContractHash, takerIsBuying),
            takerInversePositionHash    : keccak256(this, tradeAddresses[1], futuresContractHash, !takerIsBuying)

        });

//--> 44 000
    
        // Valifate size and price values
        if (!validateUint128(t.makerAmount) || !validateUint128(t.takerAmount) || !validateUint64(t.makerPrice) || !validateUint64(t.takerPrice))
        {            
            emit LogError(uint8(Errors.UINT48_VALIDATION), t.makerOrderHash, t.takerOrderHash);
            return 0; 
        }


        // Check if futures contract has expired already
        if (block.number > futuresContracts[t.futuresContract].expirationBlock || futuresContracts[t.futuresContract].closed == true || futuresContracts[t.futuresContract].broken == true)
        {
            emit LogError(uint8(Errors.FUTURES_CONTRACT_EXPIRED), t.makerOrderHash, t.takerOrderHash);
            return 0; // futures contract is expired
        }

        // Checks the signature for the maker order
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.makerOrderHash), v[0], rs[0], rs[1]) != t.maker)
        {
            emit LogError(uint8(Errors.INVALID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }
       
        // Checks the signature for the taker order
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.takerOrderHash), v[1], rs[2], rs[3]) != t.taker)
        {
            emit LogError(uint8(Errors.INVALID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }



        // check prices
        if ((!takerIsBuying && t.makerPrice < t.takerPrice) || (takerIsBuying && t.takerPrice < t.makerPrice))
        {
            emit LogError(uint8(Errors.INVALID_PRICE), t.makerOrderHash, t.takerOrderHash);
            return 0; // prices don&#39;t match
        }      

//--> 54 000

         
        

        uint256[4] memory balances = EtherMium(exchangeContract).getMakerTakerBalances(t.baseToken, t.maker, t.taker);

        // Initializing trade values structure 
        FuturesTradeValues memory tv = FuturesTradeValues({
            qty                 : 0,
            makerProfit         : 0,
            makerLoss           : 0,
            takerProfit         : 0,
            takerLoss           : 0,
            makerBalance        : balances[0], //EtherMium(exchangeContract).balanceOf(t.baseToken, t.maker),
            takerBalance        : balances[1],  //EtherMium(exchangeContract).balanceOf(t.baseToken, t.maker),
            makerReserve        : balances[2],  //EtherMium(exchangeContract).balanceOf(t.baseToken, t.maker),
            takerReserve        : balances[3]  //EtherMium(exchangeContract).balanceOf(t.baseToken, t.maker),
        });

//--> 60 000


         

        // check if floor price or cap price was reached
        if (futuresContracts[t.futuresContract].floorPrice >= t.makerPrice || futuresContracts[t.futuresContract].capPrice <= t.makerPrice)
        {
            // attepting price outside range
            emit LogError(uint8(Errors.FLOOR_OR_CAP_PRICE_REACHED), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

        // traded quantity is the smallest quantity between the maker and the taker, takes into account amounts already filled on the orders
        // and open inverse positions
        tv.qty = min(safeSub(t.makerAmount, orderFills[t.makerOrderHash]), safeSub(t.takerAmount, orderFills[t.takerOrderHash]));
        
        if (positionExists(t.makerInversePositionHash) && positionExists(t.takerInversePositionHash))
        {
            tv.qty = min(tv.qty, min(retrievePosition(t.makerInversePositionHash)[0], retrievePosition(t.takerInversePositionHash)[0]));
        }
        else if (positionExists(t.makerInversePositionHash))
        {
            tv.qty = min(tv.qty, retrievePosition(t.makerInversePositionHash)[0]);
        }
        else if (positionExists(t.takerInversePositionHash))
        {
            tv.qty = min(tv.qty, retrievePosition(t.takerInversePositionHash)[0]);
        }

       



//--> 64 000       
        
        if (tv.qty == 0)
        {
            // no qty left on orders
            emit LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

        // Cheks that gas fee is not higher than 10%
        if (safeMul(t.takerGasFee, 20) > calculateTradeValue(tv.qty, t.makerPrice, t.futuresContract))
        {
            emit LogError(uint8(Errors.GAS_TOO_HIGH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        } // takerGasFee too high


        // check if users have open positions already
        // if (positionExists(t.makerPositionHash) || positionExists(t.takerPositionHash))
        // {
        //     // maker already has the position open, first must close existing position before opening a new one
        //     emit LogError(uint8(Errors.POSITION_ALREADY_EXISTS), t.makerOrderHash, t.takerOrderHash);
        //     return 0; 
        // }

//--> 66 000
        

       

        /*------------- Maker long, Taker short -------------*/
        if (!takerIsBuying)
        {     
            
      
            // position actions for maker
            if (!positionExists(t.makerInversePositionHash) && !positionExists(t.makerPositionHash))
            {


                // check if maker has enough balance   
                
                if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                {
                    // maker out of balance
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                
                
                // create new position
                recordNewPosition(t.makerPositionHash, tv.qty, t.makerPrice, 1, block.number);



                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken, // base token
                        t.maker // make address
                    ], 
                    t.makerPositionHash,  // position hash
                    [
                        tv.qty, // qty
                        t.makerPrice,  // price
                        makerFee, // fee
                        0, // profit
                        0, // loss
                        tv.makerBalance, // balance
                        0, // gasFee
                        tv.makerReserve // reserve
                    ], 
                    [
                        true, // newPostion (if true position is new)
                        true, // side (if true - long)
                        false // increase position (if true)
                    ]
                );

            } else {               
                
                if (positionExists(t.makerPositionHash))
                {
                    // check if maker has enough balance            
                    // if (safeAdd(safeMul(safeSub(t.makerPrice, t.floorPrice), tv.qty) / t.floorPrice, 
                    //     safeMul(tv.qty, makerFee) / (1 ether)) * 1e10 > safeSub(balances[0],tv.makerReserve))
                    if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                    {
                        // maker out of balance
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                    // increase position size
                    updatePositionSize(t.makerPositionHash, safeAdd(retrievePosition(t.makerPositionHash)[0], tv.qty), t.makerPrice);
                
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,  // base token
                            t.maker // make address
                        ], 
                        t.makerPositionHash, // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            makerFee, // fee
                            0, // profit
                            0, // loss
                            tv.makerBalance, // balance
                            0, // gasFee
                            tv.makerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            true, // side (if true - long)
                            true // increase position (if true)
                        ]
                    );
                }
                else
                {

                    // close/partially close existing position
                    updatePositionSize(t.makerInversePositionHash, safeSub(retrievePosition(t.makerInversePositionHash)[0], tv.qty), 0);
                    
                    

                    if (t.makerPrice < retrievePosition(t.makerInversePositionHash)[1])
                    {
                        // user has made a profit
                        //tv.makerProfit                    = safeMul(safeSub(retrievePosition(t.makerInversePositionHash)[1], t.makerPrice), tv.qty) / t.makerPrice;
                        tv.makerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, true);
                    }
                    else
                    {
                        // user has made a loss
                        //tv.makerLoss                      = safeMul(safeSub(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1]), tv.qty) / t.makerPrice;    
                        tv.makerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, true);                                        
                    }




                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken, // base token
                            t.maker // make address
                        ], 
                        t.makerInversePositionHash, // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            makerFee, // fee
                            tv.makerProfit,  // profit
                            tv.makerLoss,  // loss
                            tv.makerBalance, // balance
                            0, // gasFee
                            tv.makerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            true, // side (if true - long)
                            false // increase position (if true)
                        ]
                    );
                }                
            }

           


            // position actions for taker
            if (!positionExists(t.takerInversePositionHash) && !positionExists(t.takerPositionHash))
            {
                
                // check if taker has enough balance
                // if (safeAdd(safeAdd(safeMul(safeSub(t.capPrice, t.makerPrice), tv.qty)  / t.capPrice, safeMul(tv.qty, takerFee) / (1 ether))  * 1e10, t.takerGasFee) > safeSub(balances[1],tv.takerReserve))
                if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                {
                    // maker out of balance
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }
                
                // create new position
                recordNewPosition(t.takerPositionHash, tv.qty, t.makerPrice, 0, block.number);
                
                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken, // base token
                        t.taker // make address
                    ], 
                    t.takerPositionHash, // position hash
                    [
                        tv.qty, // qty
                        t.makerPrice,  // price
                        takerFee, // fee
                        0, // profit
                        0,  // loss
                        tv.takerBalance,  // balance
                        t.takerGasFee, // gasFee
                        tv.takerReserve // reserve
                    ], 
                    [
                        true, // newPostion (if true position is new)
                        false, // side (if true - long)
                        false // increase position (if true)
                    ]
                );

            } else {
                if (positionExists(t.takerPositionHash))
                {
                    // check if taker has enough balance
                    //if (safeAdd(safeAdd(safeMul(safeSub(t.capPrice, t.makerPrice), tv.qty)  / t.capPrice, safeMul(tv.qty, takerFee) / (1 ether))  * 1e10, t.takerGasFee) > safeSub(balances[1],tv.takerReserve))
                    if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                    {
                        // maker out of balance
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                    // increase position size
                    updatePositionSize(t.takerPositionHash, safeAdd(retrievePosition(t.takerPositionHash)[0], tv.qty), t.makerPrice);
                
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,  // base token
                            t.taker // make address
                        ], 
                        t.takerPositionHash, // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            takerFee, // fee
                            0, // profit
                            0, // loss
                            tv.takerBalance, // balance
                            t.takerGasFee, // gasFee
                            tv.takerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            false, // side (if true - long)
                            true // increase position (if true)
                        ]
                    );
                }
                else
                {   


                     
                   

                    // close/partially close existing position
                    updatePositionSize(t.takerInversePositionHash, safeSub(retrievePosition(t.takerInversePositionHash)[0], tv.qty), 0);
                    


                    if (t.makerPrice > retrievePosition(t.takerInversePositionHash)[1])
                    {
                        // user has made a profit
                        //tv.takerProfit                    = safeMul(safeSub(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1]), tv.qty) / t.makerPrice;
                        tv.takerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, false);
                    }
                    else
                    {
                        // user has made a loss
                        //tv.takerLoss                      = safeMul(safeSub(retrievePosition(t.takerInversePositionHash)[1], t.makerPrice), tv.qty) / t.makerPrice;                                  
                        tv.takerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, false); 
                    }

                  

                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken, // base token
                            t.taker // make address
                        ], 
                        t.takerInversePositionHash, // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            takerFee, // fee
                            tv.takerProfit, // profit
                            tv.takerLoss, // loss
                            tv.takerBalance,  // balance
                            t.takerGasFee,  // gasFee
                            tv.takerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            false, // side (if true - long)
                            false // increase position (if true)
                        ]
                    );
                }
            }
        }


        /*------------- Maker short, Taker long -------------*/

        else
        {      
            //LogUint(1, safeMul(safeSub(t.makerPrice, t.floorPrice), tv.qty)); return;

            // position actions for maker
            if (!positionExists(t.makerInversePositionHash) && !positionExists(t.makerPositionHash))
            {
                // check if maker has enough balance
                //if (safeAdd(safeMul(safeSub(t.makerPrice, t.floorPrice), tv.qty) / t.floorPrice, safeMul(tv.qty, makerFee) / (1 ether)) * 1e10 > safeSub(balances[0],tv.makerReserve))
                if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                {
                    // maker out of balance
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                // create new position
                recordNewPosition(t.makerPositionHash, tv.qty, t.makerPrice, 0, block.number);
                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken,   // base token
                        t.maker // make address
                    ], 
                    t.makerPositionHash, // position hash
                    [
                        tv.qty, // qty
                        t.makerPrice, // price
                        makerFee, // fee
                        0, // profit
                        0, // loss
                        tv.makerBalance, // balance
                        0, // gasFee
                        tv.makerReserve // reserve
                    ], 
                    [
                        true, // newPostion (if true position is new)
                        false, // side (if true - long)
                        false // increase position (if true)
                    ]
                );

            } else {
                if (positionExists(t.makerPositionHash))
                {
                    // check if maker has enough balance
                    //if (safeAdd(safeMul(safeSub(t.makerPrice, t.floorPrice), tv.qty) / t.floorPrice, safeMul(tv.qty, makerFee) / (1 ether)) * 1e10 > safeSub(balances[0],tv.makerReserve))
                    if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                    {
                        // maker out of balance
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                    // increase position size
                    updatePositionSize(t.makerPositionHash, safeAdd(retrievePosition(t.makerPositionHash)[0], tv.qty), t.makerPrice);
                
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,  // base token
                            t.maker // make address
                        ], 
                        t.makerPositionHash, // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            makerFee, // fee
                            0, // profit
                            0, // loss
                            tv.makerBalance, // balance
                            0, // gasFee
                            tv.makerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            false, // side (if true - long)
                            true // increase position (if true)
                        ]
                    );
                }
                else
                {

                    // close/partially close existing position
                    updatePositionSize(t.makerInversePositionHash, safeSub(retrievePosition(t.makerInversePositionHash)[0], tv.qty), 0);       
                    


                    if (t.makerPrice > retrievePosition(t.makerInversePositionHash)[1])
                    {
                        // user has made a profit
                        //tv.makerProfit                    = safeMul(safeSub(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1]), tv.qty) / t.makerPrice;
                        tv.makerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, false);
                    }
                    else
                    {
                        // user has made a loss
                        //tv.makerLoss                      = safeMul(safeSub(retrievePosition(t.makerInversePositionHash)[1], t.makerPrice), tv.qty) / t.makerPrice; 
                        tv.makerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, false);                               
                    }

                   

                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken, // base token
                            t.maker // user address
                        ], 
                        t.makerInversePositionHash, // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            makerFee, // fee
                            tv.makerProfit,  // profit
                            tv.makerLoss, // loss
                            tv.makerBalance, // balance
                            0, // gasFee
                            tv.makerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            false, // side (if true - long)
                            false // increase position (if true)
                        ]
                    );
                }
            }

            // position actions for taker
            if (!positionExists(t.takerInversePositionHash) && !positionExists(t.takerPositionHash))
            {
                // check if taker has enough balance
                // if (safeAdd(safeAdd(safeMul(safeSub(t.capPrice, t.makerPrice), tv.qty)  / t.capPrice, safeMul(tv.qty, takerFee) / (1 ether)), t.takerGasFee / 1e10) * 1e10 > safeSub(balances[1],tv.takerReserve))
                if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                {
                    // maker out of balance
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                // create new position
                recordNewPosition(t.takerPositionHash, tv.qty, t.makerPrice, 1, block.number);
           
                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken,  // base token
                        t.taker // user address
                    ], 
                    t.takerPositionHash, // position hash
                    [
                        tv.qty, // qty
                        t.makerPrice, // price
                        takerFee, // fee
                        0,  // profit
                        0,  // loss
                        tv.takerBalance, // balance
                        t.takerGasFee, // gasFee
                        tv.takerReserve // reserve
                    ], 
                    [
                        true, // newPostion (if true position is new)
                        true, // side (if true - long)
                        false // increase position (if true)
                    ]
                );

            } else {
                if (positionExists(t.takerPositionHash))
                {
                    // check if taker has enough balance
                    //if (safeAdd(safeAdd(safeMul(safeSub(t.capPrice, t.makerPrice), tv.qty)  / t.capPrice, safeMul(tv.qty, takerFee) / (1 ether)), t.takerGasFee / 1e10) * 1e10 > safeSub(balances[1],tv.takerReserve))
                    if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                    {
                        // maker out of balance
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }
                    
                    // increase position size
                    updatePositionSize(t.takerPositionHash, safeAdd(retrievePosition(t.takerPositionHash)[0], tv.qty), t.makerPrice);
                
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,  // base token
                            t.taker // user address
                        ], 
                        t.takerPositionHash, // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            takerFee, // fee
                            0, // profit
                            0, // loss
                            tv.takerBalance, // balance
                            t.takerGasFee, // gasFee
                            tv.takerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            true, // side (if true - long)
                            true // increase position (if true)
                        ]
                    );
                }
                else
                {

                    // close/partially close existing position
                    updatePositionSize(t.takerInversePositionHash, safeSub(retrievePosition(t.takerInversePositionHash)[0], tv.qty), 0);
                                     
                    if (t.makerPrice < retrievePosition(t.takerInversePositionHash)[1])
                    {
                        // user has made a profit
                        //tv.takerProfit                    = safeMul(safeSub(retrievePosition(t.takerInversePositionHash)[1], t.makerPrice), tv.qty) / t.makerPrice;
                        tv.takerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, true);
                    }
                    else
                    {
                        // user has made a loss
                        //tv.takerLoss                      = safeMul(safeSub(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1]), tv.qty) / t.makerPrice; 
                        tv.takerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, true);                                  
                    }

                    

                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,   // base toke
                            t.taker // user address
                        ], 
                        t.takerInversePositionHash,  // position hash
                        [
                            tv.qty, // qty
                            t.makerPrice, // price
                            takerFee, // fee
                            tv.takerProfit, // profit
                            tv.takerLoss, // loss
                            tv.takerBalance, // balance
                            t.takerGasFee, // gasFee
                            tv.takerReserve // reserve
                        ], 
                        [
                            false, // newPostion (if true position is new)
                            true, // side (if true - long) 
                            false // increase position (if true)
                        ]
                    );
                }
            }           
        }

//--> 220 000
        orderFills[t.makerOrderHash]            = safeAdd(orderFills[t.makerOrderHash], tv.qty); // increase the maker order filled amount
        orderFills[t.takerOrderHash]            = safeAdd(orderFills[t.takerOrderHash], tv.qty); // increase the taker order filled amount

//--> 264 000
        emit FuturesTrade(takerIsBuying, tv.qty, t.makerPrice, t.futuresContract, t.makerOrderHash, t.takerOrderHash);

        return tv.qty;
    }


    function calculateProfit(uint256 closingPrice, uint256 entryPrice, uint256 qty, bytes32 futuresContractHash, bool side) returns (uint256)
    {
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            if (inversed)
            {
                return safeMul(safeSub(entryPrice, closingPrice), qty) / closingPrice;  
            }
            else
            {
                return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier)  / 1e8 / 1e18;
            }
            
        }
        else
        {
            if (inversed)
            {
                return safeMul(safeSub(closingPrice, entryPrice), qty) / closingPrice; 
            }
            else
            {
                return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier)  / 1e8 / 1e18; 
            }
        }       
    }

    function calculateTradeValue(uint256 qty, uint256 price, bytes32 futuresContractHash) returns (uint256)
    {
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        if (inversed)
        {
            return qty * 1e10;
        }
        else
        {
            return safeMul(safeMul(safeMul(qty, price), 1e2), multiplier) / 1e18 ;
        }
    }



    function calculateLoss(uint256 closingPrice, uint256 entryPrice, uint256 qty,  bytes32 futuresContractHash, bool side) returns (uint256)
    {
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            if (inversed)
            {
                return safeMul(safeSub(closingPrice, entryPrice), qty) / closingPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier) / 1e8 / 1e18;
            }
        }
        else
        {
            if (inversed)
            {
                return safeMul(safeSub(entryPrice, closingPrice), qty) / closingPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier) / 1e8 / 1e18;
            } 
        }
        
    }

    function calculateCollateral (uint256 limitPrice, uint256 tradePrice, uint256 qty, bool side, bytes32 futuresContractHash) view returns (uint256)
    {
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            // long
            if (inversed)
            {
                return safeMul(safeSub(tradePrice, limitPrice), qty) / limitPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(tradePrice, limitPrice), qty), multiplier) / 1e8 / 1e18;
            }
        }
        else
        {
            // short
            if (inversed)
            {
                return safeMul(safeSub(limitPrice, tradePrice), qty)  / limitPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(limitPrice, tradePrice), qty), multiplier) / 1e8 / 1e18;
            }
        }         
    }

    function calculateFee (uint256 qty, uint256 tradePrice, uint256 fee, bytes32 futuresContractHash) returns (uint256)
    {
        return safeMul(calculateTradeValue(qty, tradePrice, futuresContractHash), fee) / 1e18 / 1e10;
    }


    function checkEnoughBalance (uint256 limitPrice, uint256 tradePrice, uint256 qty, bool side, uint256 fee, uint256 gasFee, bytes32 futuresContractHash, uint256 availableBalance) view returns (bool)
    {
        
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            // long
            if (safeAdd(
                    safeAdd(
                        calculateCollateral(limitPrice, tradePrice, qty, side, futuresContractHash), 
                        //safeMul(qty, fee) / (1 ether)
                        calculateFee(qty, tradePrice, fee, futuresContractHash)
                    ) * 1e10,
                    gasFee 
                ) > availableBalance)
            {
                return false; 
            }
        }
        else
        {
            // short
            if (safeAdd(
                    safeAdd(
                        calculateCollateral(limitPrice, tradePrice, qty, side, futuresContractHash), 
                        //safeMul(qty, fee) / (1 ether)
                        calculateFee(qty, tradePrice, fee, futuresContractHash)
                    ) * 1e10, 
                    gasFee 
                ) > availableBalance)
            {
                return false;
            }

        }

        return true;
       
    }  

      

    // Executes multiple trades in one transaction, saves gas fees
    function batchFuturesTrade(
        uint8[2][] v,
        bytes32[4][] rs,
        uint256[8][] tradeValues,
        address[2][] tradeAddresses,
        bool[] takerIsBuying,
        bytes32[] assetHash,
        uint256[4][] contractValues
    ) onlyAdmin
    {
        // perform trades
        for (uint i = 0; i < tradeAddresses.length; i++) {
            futuresTrade(
                v[i],
                rs[i],
                tradeValues[i],
                tradeAddresses[i],
                takerIsBuying[i],
                createFuturesContract(assetHash[i], contractValues[i][0], contractValues[i][1], contractValues[i][2], contractValues[i][3])
            );
        }
    }

    


    // Update user balance
    function updateBalances (bytes32 futuresContract, address[2] addressValues, bytes32 positionHash, uint256[8] uintValues, bool[3] boolValues) private
    {
        /*
            addressValues
            [0] baseToken
            [1] user

            uintValues
            [0] qty
            [1] price
            [2] fee
            [3] profit
            [4] loss
            [5] balance
            [6] gasFee
            [7] reserve

            boolValues
            [0] newPostion
            [1] side
            [2] increase position

        */

        //                          qty * price * fee
        // uint256 pam[0] = safeMul(safeMul(uintValues[0], uintValues[1]), uintValues[2]) / (1 ether);
        // uint256 collateral;  


        // pam = [fee value, collateral]                        
        uint256[2] memory pam = [safeAdd(calculateFee(uintValues[0], uintValues[1], uintValues[2], futuresContract) * 1e10, uintValues[6]), 0];
        
        // LogUint(100, uintValues[3]);
        // LogUint(9, uintValues[2]);
        // LogUint(7, safeMul(uintValues[0], uintValues[2])  / (1 ether));
        // return;

        

        // Position is new or position is increased
        if (boolValues[0] || boolValues[2])  
        {

            if (boolValues[1])
            {

                //addReserve(addressValues[0], addressValues[1], uintValues[ 7], safeMul(safeSub(uintValues[1], futuresContracts[futuresContract].floorPrice), uintValues[0])); // reserve collateral on user
                //pam[1] = safeMul(safeSub(uintValues[1], futuresContracts[futuresContract].floorPrice), uintValues[0]) / futuresContracts[futuresContract].floorPrice;
                pam[1] = calculateCollateral(futuresContracts[futuresContract].floorPrice, uintValues[1], uintValues[0], true, futuresContract);

            }
            else
            {
                //addReserve(addressValues[0], addressValues[1], uintValues[7], safeMul(safeSub(futuresContracts[futuresContract].capPrice, uintValues[1]), uintValues[0])); // reserve collateral on user
                //pam[1] = safeMul(safeSub(futuresContracts[futuresContract].capPrice, uintValues[1]), uintValues[0]) / futuresContracts[futuresContract].capPrice;
                pam[1] = calculateCollateral(futuresContracts[futuresContract].capPrice, uintValues[1], uintValues[0], false, futuresContract);
            }

            subBalanceAddReserve(addressValues[0], addressValues[1], pam[0], safeAdd(pam[1],1));         

            // if (uintValues[6] > 0)
            // {   
            //     subBalanceAddReserve(addressValues[0], addressValues[1], safeAdd(uintValues[6], pam[0]), pam[1]);                  
                              
            // }
            // else
            // {

            //    subBalanceAddReserve(addressValues[0], addressValues[1], safeAdd(uintValues[6], pam[0]), pam[1]);                 
            // }


            //subBalance(addressValues[0], addressValues[1], uintValues[5], feeVal); // deduct user maker/taker fee 

            
        // Position exists
        } 
        else 
        {
            if (retrievePosition(positionHash)[2] == 0)
            {
                // original position was short
                //subReserve(addressValues[0], addressValues[1], uintValues[7], safeMul(uintValues[0], safeSub(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1]))); // remove freed collateral from reserver
                //pam[1] = safeMul(uintValues[0], safeSub(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1])) / futuresContracts[futuresContract].capPrice;
                pam[1] = calculateCollateral(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1], uintValues[0], false, futuresContract);

                // LogUint(120, uintValues[0]);
                // LogUint(121, futuresContracts[futuresContract].capPrice);
                // LogUint(122, retrievePosition(positionHash)[1]);
                // LogUint(123, uintValues[3]); // profit
                // LogUint(124, uintValues[4]); // loss
                // LogUint(125, safeAdd(uintValues[4], pam[0]));
                // LogUint(12, pam[1] );
                //return;
            }
            else
            {       
                       
                // original position was long
                //subReserve(addressValues[0], addressValues[1], uintValues[7], safeMul(uintValues[0], safeSub(retrievePosition(positionHash)[1], futuresContracts[futuresContract].floorPrice)));
                //pam[1] = safeMul(uintValues[0], safeSub(retrievePosition(positionHash)[1], futuresContracts[futuresContract].floorPrice)) / futuresContracts[futuresContract].floorPrice;
                pam[1] = calculateCollateral(futuresContracts[futuresContract].floorPrice, retrievePosition(positionHash)[1], uintValues[0], true, futuresContract);

            }


                // LogUint(41, uintValues[3]);
                // LogUint(42, uintValues[4]);
                // LogUint(43, pam[0]);
                // return;  
            if (uintValues[3] > 0) 
            {
                // profi > 0

                if (pam[0] <= uintValues[3]*1e10)
                {
                    //addBalance(addressValues[0], addressValues[1], uintValues[5], safeSub(uintValues[3], pam[0])); // add profit to user balance
                    addBalanceSubReserve(addressValues[0], addressValues[1], safeSub(uintValues[3]*1e10, pam[0]), pam[1]);
                }
                else
                {
                    subBalanceSubReserve(addressValues[0], addressValues[1], safeSub(pam[0], uintValues[3]*1e10), pam[1]);
                }
                
            } 
            else 
            {   
                

                // loss >= 0
                //subBalance(addressValues[0], addressValues[1], uintValues[5], safeAdd(uintValues[4], pam[0])); // deduct loss from user balance 
                subBalanceSubReserve(addressValues[0], addressValues[1], safeAdd(uintValues[4]*1e10, pam[0]), pam[1]); // deduct loss from user balance
           
            } 
            //}            
        }          
        
        addBalance(addressValues[0], feeAccount, EtherMium(exchangeContract).balanceOf(addressValues[0], feeAccount), pam[0]); // send fee to feeAccount
    }

    function recordNewPosition (bytes32 positionHash, uint256 size, uint256 price, uint256 side, uint256 block) private
    {
        if (!validateUint128(size) || !validateUint64(price)) 
        {
            throw;
        }

        uint256 character = uint128(size);
        character |= price<<128;
        character |= side<<192;
        character |= block<<208;

        positions[positionHash] = character;
    }

    function retrievePosition (bytes32 positionHash) public view returns (uint256[4])
    {
        uint256 character = positions[positionHash];
        uint256 size = uint256(uint128(character));
        uint256 price = uint256(uint64(character>>128));
        uint256 side = uint256(uint16(character>>192));
        uint256 entryBlock = uint256(uint48(character>>208));

        return [size, price, side, entryBlock];
    }

    function updatePositionSize(bytes32 positionHash, uint256 size, uint256 price) private
    {
        uint256[4] memory pos = retrievePosition(positionHash);

        if (size > pos[0])
        {
            // position is increasing in size
            recordNewPosition(positionHash, size, safeAdd(safeMul(pos[0], pos[1]), safeMul(price, safeSub(size, pos[0]))) / size, pos[2], pos[3]);
        }
        else
        {
            // position is decreasing in size
            recordNewPosition(positionHash, size, pos[1], pos[2], pos[3]);
        }        
    }

    function positionExists (bytes32 positionHash) internal view returns (bool)
    {
        //LogUint(3,retrievePosition(positionHash)[0]);
        if (retrievePosition(positionHash)[0] == 0)
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    // This function allows the user to manually release collateral in case the oracle service does not provide the price during the inactivityReleasePeriod
    function forceReleaseReserve (bytes32 futuresContract, bool side) public
    {   
        if (futuresContracts[futuresContract].expirationBlock == 0) throw;       
        if (futuresContracts[futuresContract].expirationBlock > block.number) throw;
        if (safeAdd(futuresContracts[futuresContract].expirationBlock, EtherMium(exchangeContract).getInactivityReleasePeriod()) > block.number) throw;  

        bytes32 positionHash = keccak256(this, msg.sender, futuresContract, side);
        if (retrievePosition(positionHash)[1] == 0) throw;    
  

        futuresContracts[futuresContract].broken = true;

        address baseToken = futuresAssets[futuresContracts[futuresContract].asset].baseToken;

        if (side)
        {
            subReserve(
                baseToken, 
                msg.sender, 
                EtherMium(exchangeContract).getReserve(baseToken, msg.sender), 
                //safeMul(safeSub(retrievePosition(positionHash)[1], futuresContracts[futuresContract].floorPrice), retrievePosition(positionHash)[0]) / futuresContracts[futuresContract].floorPrice
                calculateCollateral(futuresContracts[futuresContract].floorPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], true, futuresContract)
            ); 
        }
        else
        {            
            subReserve(
                baseToken, 
                msg.sender, 
                EtherMium(exchangeContract).getReserve(baseToken, msg.sender), 
                //safeMul(safeSub(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / futuresContracts[futuresContract].capPrice
                calculateCollateral(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], false, futuresContract)
            ); 
        }

        updatePositionSize(positionHash, 0, 0);

        //EtherMium(exchangeContract).setReserve(baseToken, msg.sender, safeSub(EtherMium(exchangeContract).getReserve(baseToken, msg.sender), );
        //reserve[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(reserve[futuresContracts[futuresContract].baseToken][msg.sender], positions[msg.sender][positionHash].collateral);

        emit FuturesForcedRelease(futuresContract, side, msg.sender);

    }

    function addBalance(address token, address user, uint256 balance, uint256 amount) private
    {
        EtherMium(exchangeContract).setBalance(token, user, safeAdd(balance, amount));
    }

    function subBalance(address token, address user, uint256 balance, uint256 amount) private
    {
        EtherMium(exchangeContract).setBalance(token, user, safeSub(balance, amount));
    }

    function subBalanceAddReserve(address token, address user, uint256 subBalance, uint256 addReserve) private
    {
        EtherMium(exchangeContract).subBalanceAddReserve(token, user, subBalance, addReserve * 1e10);
    }

    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) private
    {

        EtherMium(exchangeContract).addBalanceSubReserve(token, user, addBalance, subReserve * 1e10);
    }

    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) private
    {
        // LogUint(31, subBalance);
        // LogUint(32, subReserve);
        // return;

        EtherMium(exchangeContract).subBalanceSubReserve(token, user, subBalance, subReserve * 1e10);
    }

    function addReserve(address token, address user, uint256 reserve, uint256 amount) private
    {
        //reserve[token][user] = safeAdd(reserve[token][user], amount);
        EtherMium(exchangeContract).setReserve(token, user, safeAdd(reserve, amount * 1e10));
    }

    function subReserve(address token, address user, uint256 reserve, uint256 amount) private 
    {
        //reserve[token][user] = safeSub(reserve[token][user], amount);
        EtherMium(exchangeContract).setReserve(token, user, safeSub(reserve, amount * 1e10));
    }


    function getMakerTakerBalances(address maker, address taker, address token) public view returns (uint256[4])
    {
        return [
            EtherMium(exchangeContract).balanceOf(token, maker),
            EtherMium(exchangeContract).getReserve(token, maker),
            EtherMium(exchangeContract).balanceOf(token, taker),
            EtherMium(exchangeContract).getReserve(token, taker)
        ];
    }

    function getMakerTakerPositions(bytes32 makerPositionHash, bytes32 makerInversePositionHash, bytes32 takerPosition, bytes32 takerInversePosition) public view returns (uint256[4][4])
    {
        return [
            retrievePosition(makerPositionHash),
            retrievePosition(makerInversePositionHash),
            retrievePosition(takerPosition),
            retrievePosition(takerInversePosition)
        ];
    }


    struct FuturesClosePositionValues {
        uint256 reserve;                // amount to be trade
        uint256 balance;        // holds maker profit value
        uint256 floorPrice;          // holds maker loss value
        uint256 capPrice;        // holds taker profit value
        uint256 closingPrice;          // holds taker loss value
        bytes32 futuresContract; // the futures contract hash
    }


    function closeFuturesPosition (bytes32 futuresContract, bool side)
    {
        bytes32 positionHash = keccak256(this, msg.sender, futuresContract, side);

        if (futuresContracts[futuresContract].closed == false && futuresContracts[futuresContract].expirationBlock != 0) throw; // contract not yet settled
        if (retrievePosition(positionHash)[1] == 0) throw; // position not found
        if (retrievePosition(positionHash)[0] == 0) throw; // position already closed

        uint256 profit;
        uint256 loss;

        address baseToken = futuresAssets[futuresContracts[futuresContract].asset].baseToken;

        FuturesClosePositionValues memory v = FuturesClosePositionValues({
            reserve         : EtherMium(exchangeContract).getReserve(baseToken, msg.sender),
            balance         : EtherMium(exchangeContract).balanceOf(baseToken, msg.sender),
            floorPrice      : futuresContracts[futuresContract].floorPrice,
            capPrice        : futuresContracts[futuresContract].capPrice,
            closingPrice    : futuresContracts[futuresContract].closingPrice,
            futuresContract : futuresContract
        });

        // uint256 reserve = EtherMium(exchangeContract).getReserve(baseToken, msg.sender);
        // uint256 balance = EtherMium(exchangeContract).balanceOf(baseToken, msg.sender);
        // uint256 floorPrice = futuresContracts[futuresContract].floorPrice;
        // uint256 capPrice = futuresContracts[futuresContract].capPrice;
        // uint256 closingPrice =  futuresContracts[futuresContract].closingPrice;


        
        //uint256 fee = safeMul(safeMul(retrievePosition(positionHash)[0], v.closingPrice), takerFee) / (1 ether);
        uint256 fee = calculateFee(retrievePosition(positionHash)[0], v.closingPrice, takerFee, futuresContract);



        // close long position
        if (side == true)
        {            

            // LogUint(11, EtherMium(exchangeContract).getReserve(baseToken, msg.sender));
            // LogUint(12, safeMul(safeSub(retrievePosition(positionHash)[1], futuresContracts[futuresContract].floorPrice), retrievePosition(positionHash)[0]) / futuresContracts[futuresContract].floorPrice);
            // return;
            // reserve = reserve - (entryPrice - floorPrice) * size;
            //subReserve(baseToken, msg.sender, EtherMium(exchangeContract).getReserve(baseToken, msg.sender), safeMul(safeSub(positions[positionHash].entryPrice, futuresContracts[futuresContract].floorPrice), positions[positionHash].size));
            
            
            subReserve(
                baseToken, 
                msg.sender, 
                v.reserve, 
                //safeMul(safeSub(retrievePosition(positionHash)[1], v.floorPrice), retrievePosition(positionHash)[0]) / v.floorPrice
                calculateCollateral(v.floorPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], true, v.futuresContract)
            );
            //EtherMium(exchangeContract).setReserve(baseToken, msg.sender, safeSub(EtherMium(exchangeContract).getReserve(baseToken, msg.sender), safeMul(safeSub(positions[msg.sender][positionHash].entryPrice, futuresContracts[futuresContract].floorPrice), positions[msg.sender][positionHash].size));
            //reserve[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(reserve[futuresContracts[futuresContract].baseToken][msg.sender], safeMul(safeSub(positions[msg.sender][positionHash].entryPrice, futuresContracts[futuresContract].floorPrice), positions[msg.sender][positionHash].size));
            
            

            if (v.closingPrice > retrievePosition(positionHash)[1])
            {
                // user made a profit
                //profit = safeMul(safeSub(v.closingPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / v.closingPrice;
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);
                


                // LogUint(15, profit);
                // LogUint(16, fee);
                // LogUint(17, safeSub(profit * 1e10, fee));
                // return;
                if (profit > fee)
                {
                    addBalance(baseToken, msg.sender, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, msg.sender, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }
                //EtherMium(exchangeContract).updateBalance(baseToken, msg.sender, safeAdd(EtherMium(exchangeContract).balanceOf(baseToken, msg.sender), profit);
                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeAdd(tokens[futuresContracts[futuresContract].baseToken][msg.sender], profit);
            }
            else
            {
                // user made a loss
                //loss = safeMul(safeSub(retrievePosition(positionHash)[1], v.closingPrice), retrievePosition(positionHash)[0]) / v.closingPrice;
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);  


                subBalance(baseToken, msg.sender, v.balance, safeAdd(loss * 1e10, fee * 1e10));
                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(tokens[futuresContracts[futuresContract].baseToken][msg.sender], loss);
            }
        }   
        // close short position 
        else
        {
            // LogUint(11, EtherMium(exchangeContract).getReserve(baseToken, msg.sender));
            // LogUint(12, safeMul(safeSub(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / futuresContracts[futuresContract].capPrice);
            // return;

            // reserve = reserve - (capPrice - entryPrice) * size;
            subReserve(
                baseToken, 
                msg.sender,  
                v.reserve, 
                //safeMul(safeSub(v.capPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / v.capPrice
                calculateCollateral(v.capPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], false, v.futuresContract)
            );
            //EtherMium(exchangeContract).setReserve(baseToken, msg.sender, safeSub(EtherMium(exchangeContract).getReserve(baseToken, msg.sender), safeMul(safeSub(futuresContracts[futuresContract].capPrice, positions[msg.sender][positionHash].entryPrice), positions[msg.sender][positionHash].size));
            //reserve[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(reserve[futuresContracts[futuresContract].baseToken][msg.sender], safeMul(safeSub(futuresContracts[futuresContract].capPrice, positions[msg.sender][positionHash].entryPrice), positions[msg.sender][positionHash].size));
            
            

            if (v.closingPrice < retrievePosition(positionHash)[1])
            {
                // user made a profit
                // profit = (entryPrice - closingPrice) * size
                // profit = safeMul(safeSub(retrievePosition(positionHash)[1], v.closingPrice), retrievePosition(positionHash)[0]) / v.closingPrice;
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);

                if (profit > fee)
                {
                    addBalance(baseToken, msg.sender, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, msg.sender, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }

                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeAdd(tokens[futuresContracts[futuresContract].baseToken][msg.sender], profit);
            }
            else
            {
                // user made a loss
                // profit = (closingPrice - entryPrice) * size
                //loss = safeMul(safeSub(v.closingPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / v.closingPrice;
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);  

                subBalance(baseToken, msg.sender, v.balance, safeAdd(loss * 1e10, fee * 1e10));

                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(tokens[futuresContracts[futuresContract].baseToken][msg.sender], loss);
            }
        }  

        addBalance(baseToken, feeAccount, EtherMium(exchangeContract).balanceOf(baseToken, feeAccount), fee * 1e10); // send fee to feeAccount
        updatePositionSize(positionHash, 0, 0);

        emit FuturesPositionClosed(positionHash);
    }

    function closeFuturesContract (bytes32 futuresContract, uint256 price) onlyOracle returns (bool)
    {
        if (futuresContracts[futuresContract].expirationBlock == 0)  return false; // contract not found
        if (futuresContracts[futuresContract].closed == true)  return false; // contract already closed

        if (futuresContracts[futuresContract].expirationBlock > block.number
            && price > futuresContracts[futuresContract].floorPrice
            && price < futuresContracts[futuresContract].capPrice) return false; // contract not yet expired and the price did not leave the range
                

        if (price <= futuresContracts[futuresContract].floorPrice)  
        {
            futuresContracts[futuresContract].closingPrice = futuresContracts[futuresContract].floorPrice; 
        }  
        else if (price >= futuresContracts[futuresContract].capPrice)
        {
            futuresContracts[futuresContract].closingPrice = futuresContracts[futuresContract].capPrice;
        }   
        else
        {
            futuresContracts[futuresContract].closingPrice = price;
        }         
        

        futuresContracts[futuresContract].closed = true;

        emit FuturesContractClosed(futuresContract, price);
    }  

    // closes position for user
    function closeFuturesPositionForUser (bytes32 futuresContract, bool side, address user, uint256 gasFee) onlyAdmin
    {
        bytes32 positionHash = keccak256(this, user, futuresContract, side);

        if (futuresContracts[futuresContract].closed == false && futuresContracts[futuresContract].expirationBlock != 0) throw; // contract not yet settled
        if (retrievePosition(positionHash)[1] == 0) throw; // position not found
        if (retrievePosition(positionHash)[0] == 0) throw; // position already closed

        // failsafe, gas fee cannot be greater than 5% of position value
        if (safeMul(gasFee * 1e10, 20) > calculateTradeValue(retrievePosition(positionHash)[0], retrievePosition(positionHash)[1], futuresContract))
        {
            emit LogError(uint8(Errors.GAS_TOO_HIGH), futuresContract, positionHash);
            return;
        }


        uint256 profit;
        uint256 loss;

        address baseToken = futuresAssets[futuresContracts[futuresContract].asset].baseToken;

        FuturesClosePositionValues memory v = FuturesClosePositionValues({
            reserve         : EtherMium(exchangeContract).getReserve(baseToken, user),
            balance         : EtherMium(exchangeContract).balanceOf(baseToken, user),
            floorPrice      : futuresContracts[futuresContract].floorPrice,
            capPrice        : futuresContracts[futuresContract].capPrice,
            closingPrice    : futuresContracts[futuresContract].closingPrice,
            futuresContract : futuresContract
        });

        // uint256 reserve = EtherMium(exchangeContract).getReserve(baseToken, msg.sender);
        // uint256 balance = EtherMium(exchangeContract).balanceOf(baseToken, msg.sender);
        // uint256 floorPrice = futuresContracts[futuresContract].floorPrice;
        // uint256 capPrice = futuresContracts[futuresContract].capPrice;
        // uint256 closingPrice =  futuresContracts[futuresContract].closingPrice;


        
        //uint256 fee = safeMul(safeMul(retrievePosition(positionHash)[0], v.closingPrice), takerFee) / (1 ether);
        uint256 fee = safeAdd(calculateFee(retrievePosition(positionHash)[0], v.closingPrice, takerFee, futuresContract), gasFee);

        // close long position
        if (side == true)
        {            

            // LogUint(11, EtherMium(exchangeContract).getReserve(baseToken, msg.sender));
            // LogUint(12, safeMul(safeSub(retrievePosition(positionHash)[1], futuresContracts[futuresContract].floorPrice), retrievePosition(positionHash)[0]) / futuresContracts[futuresContract].floorPrice);
            // return;
            // reserve = reserve - (entryPrice - floorPrice) * size;
            //subReserve(baseToken, msg.sender, EtherMium(exchangeContract).getReserve(baseToken, msg.sender), safeMul(safeSub(positions[positionHash].entryPrice, futuresContracts[futuresContract].floorPrice), positions[positionHash].size));
            
            
            subReserve(
                baseToken, 
                user, 
                v.reserve, 
                //safeMul(safeSub(retrievePosition(positionHash)[1], v.floorPrice), retrievePosition(positionHash)[0]) / v.floorPrice
                calculateCollateral(v.floorPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], true, v.futuresContract)
            );
            //EtherMium(exchangeContract).setReserve(baseToken, msg.sender, safeSub(EtherMium(exchangeContract).getReserve(baseToken, msg.sender), safeMul(safeSub(positions[msg.sender][positionHash].entryPrice, futuresContracts[futuresContract].floorPrice), positions[msg.sender][positionHash].size));
            //reserve[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(reserve[futuresContracts[futuresContract].baseToken][msg.sender], safeMul(safeSub(positions[msg.sender][positionHash].entryPrice, futuresContracts[futuresContract].floorPrice), positions[msg.sender][positionHash].size));
            
            

            if (v.closingPrice > retrievePosition(positionHash)[1])
            {
                // user made a profit
                //profit = safeMul(safeSub(v.closingPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / v.closingPrice;
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);
                


                // LogUint(15, profit);
                // LogUint(16, fee);
                // LogUint(17, safeSub(profit * 1e10, fee));
                // return;
                if (profit > fee)
                {
                    addBalance(baseToken, user, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, user, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }
                //EtherMium(exchangeContract).updateBalance(baseToken, msg.sender, safeAdd(EtherMium(exchangeContract).balanceOf(baseToken, msg.sender), profit);
                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeAdd(tokens[futuresContracts[futuresContract].baseToken][msg.sender], profit);
            }
            else
            {
                // user made a loss
                //loss = safeMul(safeSub(retrievePosition(positionHash)[1], v.closingPrice), retrievePosition(positionHash)[0]) / v.closingPrice;
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);  


                subBalance(baseToken, user, v.balance, safeAdd(loss * 1e10, fee * 1e10));
                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(tokens[futuresContracts[futuresContract].baseToken][msg.sender], loss);
            }
        }   
        // close short position 
        else
        {
            // LogUint(11, EtherMium(exchangeContract).getReserve(baseToken, msg.sender));
            // LogUint(12, safeMul(safeSub(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / futuresContracts[futuresContract].capPrice);
            // return;

            // reserve = reserve - (capPrice - entryPrice) * size;
            subReserve(
                baseToken, 
                user,  
                v.reserve, 
                //safeMul(safeSub(v.capPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / v.capPrice
                calculateCollateral(v.capPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], false, v.futuresContract)
            );
            //EtherMium(exchangeContract).setReserve(baseToken, msg.sender, safeSub(EtherMium(exchangeContract).getReserve(baseToken, msg.sender), safeMul(safeSub(futuresContracts[futuresContract].capPrice, positions[msg.sender][positionHash].entryPrice), positions[msg.sender][positionHash].size));
            //reserve[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(reserve[futuresContracts[futuresContract].baseToken][msg.sender], safeMul(safeSub(futuresContracts[futuresContract].capPrice, positions[msg.sender][positionHash].entryPrice), positions[msg.sender][positionHash].size));
            
            

            if (v.closingPrice < retrievePosition(positionHash)[1])
            {
                // user made a profit
                // profit = (entryPrice - closingPrice) * size
                // profit = safeMul(safeSub(retrievePosition(positionHash)[1], v.closingPrice), retrievePosition(positionHash)[0]) / v.closingPrice;
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);

                if (profit > fee)
                {
                    addBalance(baseToken, user, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, user, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }
                

                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeAdd(tokens[futuresContracts[futuresContract].baseToken][msg.sender], profit);
            }
            else
            {
                // user made a loss
                // profit = (closingPrice - entryPrice) * size
                //loss = safeMul(safeSub(v.closingPrice, retrievePosition(positionHash)[1]), retrievePosition(positionHash)[0]) / v.closingPrice;
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);  

                subBalance(baseToken, user, v.balance, safeAdd(loss * 1e10, fee * 1e10));

                //tokens[futuresContracts[futuresContract].baseToken][msg.sender] = safeSub(tokens[futuresContracts[futuresContract].baseToken][msg.sender], loss);
            }
        }  

        addBalance(baseToken, feeAccount, EtherMium(exchangeContract).balanceOf(baseToken, feeAccount), fee * 1e10); // send fee to feeAccount
        updatePositionSize(positionHash, 0, 0);

        emit FuturesPositionClosed(positionHash);
    }

    // Settle positions for closed contracts
    function batchSettlePositions (
        bytes32[] futuresContracts,
        bool[] sides,
        address[] users,
        uint256 gasFeePerClose // baseToken with 8 decimals
    ) onlyAdmin {
        
        for (uint i = 0; i < futuresContracts.length; i++) 
        {
            closeFuturesPositionForUser(futuresContracts[i], sides[i], users[i], gasFeePerClose);
        }
    }



    
    

    // Returns the smaller of two values
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}