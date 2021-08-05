pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ChainlinkClient.sol";

interface IDotxGame{
     function firstHouseOpen(uint256 _price, uint256 warIndex) external;
     function secondHouseOpen(uint256 _price, uint256 warIndex) external;
     function firstHouseClose(uint256 _price, uint256 warIndex) external;
     function secondHouseClose(uint256 _price, uint256 warIndex) external;
 }
 
 contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address public dotxGameAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || dotxGameAddress == _msgSender() || dotxGameAddress == address(0), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyDoTxGame() {
        require(dotxGameAddress == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title DeFi Of Thrones Game Contract Lib
 * @author Maxime Reynders - DefiOfThrones (https://github.com/DefiOfThrones/DOTTokenContract)
 */
contract DoTxLib is ChainlinkClient, Ownable {
    using SafeMathChainlink for uint256;
    //DOTX Game Contract
    IDotxGame private dotxGame;

    //CHAINLINK VARS
    // The address of an oracle - you can find node addresses on https://market.link/search/nodes
    //address ORACLE_ADDRESS = 0xB36d3709e22F7c708348E225b20b13eA546E6D9c; ROPSTEN
    address public ORACLE_ADDRESS = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
    // The address of the http get > uint256 job
    string public JOBID = "b6602d14e4734c49a5e1ce19d45a4632";
    //LINK amount / transaction (oracle payment)
    uint256 public ORACLE_PAYMENT = 100000000000000000;
    
    uint256 public rewardPrecision = 10000;
    
    uint256 public warIndex;
    /**
     * Game contract constructor
     * Just pass the DoTx contract address in parameter
     **/
    constructor() public {
        //Setup Chainlink address for the network
        setPublicChainlinkToken();
    }
    
    function calculateHousePerf(int256 open, int256 close, int256 precision) external pure returns(int256){
        return ((close - open) * precision) / open;
    }
    
    /*
    * CALCULATE BURN OR STAKING %
    */
    function calculatePercentage(uint256 amount, uint256 percentage, uint256 selecteWinnerPrecision) public pure returns(uint256){
        return amount.mul(selecteWinnerPrecision).mul(percentage).div(100).div(selecteWinnerPrecision);
    }
    
    function calculateReward(uint256 dotxUserBalance, uint256 totalDoTxWinningHouse, uint256 totalDoTxLosingHouse) public view returns(uint256){
        uint256 percent = (dotxUserBalance.mul(rewardPrecision)).div(totalDoTxWinningHouse);
        //Reward for user balance
        return (totalDoTxLosingHouse.mul(percent)).div(rewardPrecision);
    }
    
    /*******************************
            CHAINLINK METHODS
    ********************************/
    
    /**
     * Fetch the prices for the 2 houses the first day for the current war
     **/
    function fetchFirstDayPrices(string memory firstHouseTicker, string memory secondHouseTicker, string memory firstHouseId, string memory secondHouseId, int256 multiplicator, uint256 _warIndex) public onlyDoTxGame {
        warIndex = _warIndex;
        queryChainLinkPrice(firstHouseTicker, firstHouseId, multiplicator, this.firstHouseOpen.selector);
        queryChainLinkPrice(secondHouseTicker, secondHouseId, multiplicator, this.secondHouseOpen.selector);
    }

    /**
     * Fetch the prices for the 2 houses the last day for the current war
     **/
    function fetchLastDayPrices(string memory firstHouseTicker, string memory currentSecondHouseTicker, string memory firstHouseId, string memory secondHouseId, int256 multiplicator, uint256 _warIndex) public onlyDoTxGame {
        warIndex = _warIndex;
        queryChainLinkPrice(firstHouseTicker, firstHouseId, multiplicator, this.firstHouseClose.selector);
        queryChainLinkPrice(currentSecondHouseTicker, secondHouseId, multiplicator, this.secondHouseClose.selector);
    }
    
    // 
    /**
     * Creates a Chainlink request with the uint256 multiplier job to retrieve a price for a coin
     * _fsym from symbol
     * _selector handler method called by Chainlink Oracle
     **/
    function queryChainLinkPrice(string memory _fsym, string memory _fsymId, int256 _multiplicator, bytes4 _selector) public onlyDoTxGame {
        // newRequest takes a JobID, a callback address, and callback function as input
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOBID), address(this), _selector);

        //Call Coingecko from DeFi Of Thrones API (code available in official git repo under WS folder)
        req.add("get", append("https://us-central1-defiofthrones.cloudfunctions.net/getCurrentPrice?fsym=", _fsym, "&tsym=usd", "&fsymId=", _fsymId));
        req.add("path", "usd");
        // Multiply the price by multiplicator because Solidty can only manage Integer type
        req.addInt("times", _multiplicator);
        // Sends the request with the amount of payment specified to the oracle
        sendChainlinkRequestTo(ORACLE_ADDRESS, req, ORACLE_PAYMENT);
    }
    /**
     * Handler method called by Chainlink for the first house open price 
     **/
    function firstHouseOpen(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId){
        dotxGame.firstHouseOpen(_price, warIndex);
    }
    /**
     * Handler method called by Chainlink for the second house open price 
     **/
    function secondHouseOpen(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId){
        dotxGame.secondHouseOpen(_price, warIndex);
    }
    /**
     * Handler method called by Chainlink for the first house close price 
     **/
    function firstHouseClose(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId){
        dotxGame.firstHouseClose(_price, warIndex);
    }
    /**
     * Handler method called by Chainlink for the second house close price 
     **/
    function secondHouseClose(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId){
        dotxGame.secondHouseClose(_price, warIndex);
    }
    
    
    /**
     * Set Chainlink Oracle's address
     **/
    function setChainLinkOracleAddress(address _oracleAddress) public onlyOwner{
        ORACLE_ADDRESS = _oracleAddress;
    }
    
    /**
     * Set Chainlink Oracle's job id -> http get > uint256 job
     **/
    function setChainJobId(string memory _jobId) public onlyOwner{
        JOBID = _jobId;
    }
    
    /**
     * Set the amount of Link used to performe a call
     **/
    function setOraclePaymentAmount(uint256 _linkAmount) public onlyOwner{
        ORACLE_PAYMENT = _linkAmount;
    }

    /*****************************
            ADMIN METHODS
    ******************************/
    
    /**
     * Let owner withdraw Link owned by the contract
     **/
    function withdrawLink() public onlyOwner{
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(owner(), link.balanceOf(address(this))), "Unable to transfer");
    }
    
    function setDoTxGame(address gameAddress) public onlyOwner{
        dotxGame = IDotxGame(gameAddress);
        dotxGameAddress = gameAddress;
    }
    
    function setRewardPrecision(uint256 precision) public onlyOwner{
        rewardPrecision = precision;
    }
    
    function getWarIndex() public view returns(uint256){
        return warIndex;
    }
    
    function setWarIndex(uint256 _warIndex) public onlyOwner{
        warIndex = _warIndex;
    }
    
    /****************************
            UTILS METHODS
    *****************************/
    
    /**
     * Convert string to bytes32
     **/
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /**
     * Convert bytes32 to string
     **/
    function bytes32ToString(bytes32 x) public pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    /**
     * A method to concat multiples string in one
     **/
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) public pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
}