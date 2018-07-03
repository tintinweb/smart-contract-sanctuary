pragma solidity ^0.4.23;
/*
deploy gas limit = 1766974, gas price = 1 GWei
Ropsten 0x3e10649e608b1be3d452228805c2e5062440dbbd
gas limit = 2223176, gas price = 1 GWei
Kovan  0x0cF3466C0bCD5674FDaf41f0778c5230F458Cceb
addr 0x8e9dca5ae198d5a2067a2e5a757d158e0cc87521a30e314d5e0c2b37a4e8cab2

deploy gas limit = 2223176, gas price = 1 GWei
Ropsten  0xf3f5f80878f623f858c18beb782b595ba511ec34f562ecc3d398ab0e76854c89
addr 0xE0257d634ea4523a6ddeC3210C7fA4eB73e0d3b1

Event marks the end of a function call at this contract or other people&#39;s contracts, but not the confirmation of a transaction, which is decided by the miners and txn fee
*/
contract Exchange {
    //https://0xproject.com/wiki#Message-Format
    address public owner;
    address public maker;//Address originating the order.
    address public taker;//Address permitted to fill the order (optional).
    address public makerTokenAddress;
    address public takerTokenAddress;
    address public feeRecipient;//Address that recieves transaction fees (optional).

    uint public makerTokenAmount;
    uint public takerTokenAmount;
    uint8 public errorId;
    uint public expirationTimestampInSec;
    uint public salt;

    uint public makerFee;//Total units of ZRX paid to feeRecipient by maker.
    uint public takerFee;//Total units of ZRX paid to feeRecipient by taker.
    
    uint public filledMakerTokenAmount;//new
    uint public filledTakerTokenAmount;
    uint public paidMakerFee;
    uint public paidTakerFee;
    bytes32 public tokens;
    bytes32 public orderHash;
    uint public cancelledMakerTokenAmount;
    uint public cancelledTakerTokenAmount;

    constructor() public {
        owner = msg.sender;
        maker = 0x6f44Cceb49b4A5812d54b6F494FC2feBF25511eD;
        taker = 0x0000000000000000000000000000000000000000;
        feeRecipient = 0xF694dCbec7f434dE9F892cfACF0449DB8661334D;
        makerTokenAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        takerTokenAddress = 0x0d0F936Ee4c93e25944694D6C121de94D9760F11;
        filledMakerTokenAmount  = 1111111111;
        filledTakerTokenAmount  = 2222222222;
        paidMakerFee = 10;
        paidTakerFee = 20;
        errorId  = 255;//0 ~ 255
        tokens   = getKeccak256Address(makerTokenAddress, takerTokenAddress);
        salt = 1234567;
        orderHash = keccak256(abi.encodePacked(salt));
        cancelledMakerTokenAmount = 31;
        cancelledTakerTokenAmount = 42;
        makerTokenAmount = 5000000000000000;
        takerTokenAmount = 7000000000000000;
    }
/**
receive arguments => do a little operation to test if they are of that variable type
maker: 0x6f44Cceb49b4A5812d54b6F494FC2feBF25511eD
taker: 0x0000000000000000000000000000000000000000   //open order role
exchangeContractAddress: 0x479CC461fEcd078F766eCc58533D6F69580CF3AC
makerTokenAddress: 0xc778417E063141139Fce010982780140Aa0cD5Ab
takerTokenAddress: 0x0d0F936Ee4c93e25944694D6C121de94D9760F11
makerTokenAmount: 5000000000000000
takerTokenAmount: 5000000000000000  
*/
    event LogFill(
        address indexed maker,
        address taker,
        address indexed feeRecipient,
        address makerToken,
        address takerToken,
        uint filledMakerTokenAmount,
        uint filledTakerTokenAmount,
        uint paidMakerFee,
        uint paidTakerFee,
        bytes32 indexed tokens, // keccak256(abi.encodePacked(makerToken, takerToken), allows subscribing to a token pair
        bytes32 orderHash
    );
    function getKeccak256Address(address addr1, address addr2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr1, addr2));
    }

    function makeLogFill(address _maker, address _taker, address _feeRecipient, address _makerTokenAddress, address _takerTokenAddress, uint _filledMakerTokenAmount, uint _filledTakerTokenAmount, uint _paidMakerFee, uint _paidTakerFee, uint _salt) public {
        maker = _maker;
        taker = _taker;
        feeRecipient = _feeRecipient;
        makerTokenAddress = _makerTokenAddress;
        takerTokenAddress = _takerTokenAddress;
        filledMakerTokenAmount = _filledMakerTokenAmount;
        filledTakerTokenAmount = _filledTakerTokenAmount;
        paidMakerFee = _paidMakerFee;
        paidTakerFee = _paidTakerFee;
        tokens = getKeccak256Address(_makerTokenAddress, _takerTokenAddress);
        salt = _salt;
        orderHash = keccak256(abi.encodePacked(_salt));
        emit LogFill(_maker, _taker, _feeRecipient, _makerTokenAddress, _takerTokenAddress, _filledMakerTokenAmount, _filledTakerTokenAmount, _paidMakerFee, _paidTakerFee, tokens, orderHash);
    }
    function getLogFillArguments() view public returns (address, address, address, address, address, uint, uint, uint, uint, bytes32, uint, bytes32) {
        return (maker, taker, feeRecipient, makerTokenAddress, takerTokenAddress, filledMakerTokenAmount, filledTakerTokenAmount, paidMakerFee, paidTakerFee, tokens, salt, orderHash);
    }
/**
    event LogFill(
        address indexed maker,
        address taker,
        address indexed feeRecipient,
        address makerToken,
        address takerToken,
        uint filledMakerTokenAmount,
        uint filledTakerTokenAmount,
        uint paidMakerFee,
        uint paidTakerFee,
        bytes32 indexed tokens, // keccak256(abi.encodePacked(makerToken, takerToken), allows subscribing to a token pair
        bytes32 orderHash
    );
    //orderHash: getOrderHash(orderAddresses, orderValues)
    function getOrderHash(address[5] orderAddresses, uint[6] orderValues)
        public constant returns (bytes32) {
        return keccak256(abi.encodePacked(
            address(this),
            orderAddresses[0], // maker
            orderAddresses[1], // taker
            orderAddresses[2], // makerToken
            orderAddresses[3], // takerToken
            orderAddresses[4], // feeRecipient
            orderValues[0],    // makerTokenAmount
            orderValues[1],    // takerTokenAmount
            orderValues[2],    // makerFee
            orderValues[3],    // takerFee
            orderValues[4],    // expirationTimestampInSec
            orderValues[5]     // salt
        ));
    }
        owner = msg.sender;
        maker = 0x6f44Cceb49b4A5812d54b6F494FC2feBF25511eD;
        taker = msg.sender;
        feeRecipient = 0xF694dCbec7f434dE9F892cfACF0449DB8661334D;
        makerTokenAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        takerTokenAddress = 0x0d0F936Ee4c93e25944694D6C121de94D9760F11;
        filledMakerTokenAmount  = 1111111111;
        filledTakerTokenAmount  = 2222222222;
        paidMakerFee = 10;
        paidTakerFee = 20;
        errorId  = 255;//0 ~ 255
        tokens   = getKeccak256Address(makerTokenAddress, takerTokenAddress);
        cancelledMakerTokenAmount = 31;
        cancelledTakerTokenAmount = 32;
*/
    event LogCancel(
        address indexed maker,
        address indexed feeRecipient,
        address makerToken,
        address takerToken,
        uint cancelledMakerTokenAmount,
        uint cancelledTakerTokenAmount,
        bytes32 indexed tokens,
        bytes32 orderHash
    );
    function makeLogCancel(address _maker, address _feeRecipient, address _makerTokenAddress, address _takerTokenAddress, uint _cancelledMakerTokenAmount,
        uint _cancelledTakerTokenAmount, uint _salt) public {
        maker = _maker;
        feeRecipient = _feeRecipient;
        makerTokenAddress = _makerTokenAddress;
        takerTokenAddress = _takerTokenAddress;
        cancelledMakerTokenAmount = _cancelledMakerTokenAmount;
        cancelledTakerTokenAmount = _cancelledTakerTokenAmount;
        tokens = getKeccak256Address(_makerTokenAddress, _takerTokenAddress);
        salt = _salt;
        orderHash = keccak256(abi.encodePacked(_salt));
        emit LogCancel(_maker, _feeRecipient, _makerTokenAddress, _takerTokenAddress,
            _cancelledMakerTokenAmount, _cancelledTakerTokenAmount, tokens, orderHash);
    }
    function getLogCancelArguments() view public returns (address, address, address, address, uint, uint, bytes32, uint, bytes32) {
        return (maker, feeRecipient, makerTokenAddress, takerTokenAddress, cancelledMakerTokenAmount, cancelledTakerTokenAmount, tokens, salt, orderHash);
    }

    event LogError(uint8 indexed errorId, bytes32 indexed orderHash);
    function makeLogError(uint8 _errorId, uint _expirationTimestampInSec, uint _salt) public {
    //LogError(uint8(Errors.ORDER_EXPIRED), order.orderHash);
    //LogError(uint8(Errors.ORDER_FULLY_FILLED_OR_CANCELLED), order.orderHash);
        errorId = _errorId;
        expirationTimestampInSec  = _expirationTimestampInSec;
        salt = _salt; 
        orderHash = getKeccak256Uint(_expirationTimestampInSec, _salt);
        emit LogError(_errorId, orderHash);
    }
    function getLogErrorArguments() view public returns (uint8, uint, uint, bytes32) {
        return (errorId, expirationTimestampInSec, salt, orderHash);
    }



    function getOrderOtherArguments() view public returns (uint, uint, uint, uint, uint, uint) {
        return (makerTokenAmount, takerTokenAmount, expirationTimestampInSec, salt, makerFee, takerFee);
    }


    /*function getKeccak256Address(address addr1, address addr2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr1, addr2));
    }*/
    function getKeccak256Uint(uint a, uint b) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

    function userAddr() public view returns (address) {
      return msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public {
        require(newOwner != address(0));
        owner = newOwner;
    }
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}