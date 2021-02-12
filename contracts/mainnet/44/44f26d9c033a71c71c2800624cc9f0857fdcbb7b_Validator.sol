// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;

import "./SafeMath.sol";
import "./Ownable.sol";

interface ISwapFactory {
    function balanceCallback(address payable pair, address user, uint256 balanceForeign) external returns(bool);
    function balancesCallback(
            address payable pair,
            address user,
            uint256 balanceForeign,
            uint256 nativeEncoded,
            uint256 foreignSpent,
            uint256 rate    // rate = foreignPrice.mul(NOMINATOR) / nativePrice;   // current rate
        ) external returns(bool);
    function newFactory() external view returns(address);
}

interface ISwapPair {
    function getTokens() external view returns(address tokenA, address tokenB);
}

// 1 - BNB, 2 - ETH, 3 - BTC
interface ICompanyOracle {
    function getBalance(uint256 network,address token,address user) external returns(uint256);
    function getPriceAndBalance(address tokenA,address tokenB,uint256 network,address token,address[] calldata user) external returns(uint256);
}


contract Validator is Ownable {
    using SafeMath for uint256;

    uint256 constant NETWORK = 56;  // ETH mainnet = 1, Ropsten = 3,Kovan - 42, BSC_TESTNET = 97, BSC_MAINNET = 56
    uint256 constant NOMINATOR = 10**9;     // rate nominator
    address constant NATIVE = address(-1);  // address which holds native token ballance that was spent
    address constant FOREIGN = address(-2); // address which holds foreign token encoded ballance that was spent

    struct Request {
        //uint32 approves;
        address factory;
        address tokenForeign;
        address user;
        address payable pair;
        //uint256 balanceForeign;
    }

    Request[] public requests;
    
    mapping(address => bool) public isAllowedAddress; 
    uint32 public approves_required = 1;

    address public companyOracle;
    mapping (uint256 => uint256) public companyOracleRequests;  // companyOracleRequest ID => requestId
    //mapping (bytes32 => uint256) public provableOracleRequests;  // provableOracleRequests ID => requestId
    mapping (uint256 => uint256) public gasLimit;  // request type => amount of gas
    uint256 public customGasPrice = 20 * 10**9; // 20 GWei

    event LogMsg(string description);
    event CompanyOracle(uint256 requestId, uint256 balance);
    event CompanyOracle3(uint256 requestId, uint256 userBalance, uint256 nativeSpent, uint256 foreignEncoded);

    modifier onlyAllowed() {
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        _;
    }

    constructor (address _oracle) public {
        companyOracle = _oracle;
        requests.push();    // request ID starts from 1. ID = 0 means completed/empty
    }

    function setApproves_required(uint32 n) external onlyOwner returns(bool) {
        approves_required = n;
        return true;
    }

    function setCompanyOracle(address _addr) external onlyOwner returns(bool) {
        companyOracle = _addr;
        return true;
    }

    function changeAllowedAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isAllowedAddress[_which] = _bool;
        return true;
    }

    // returns: oracle fee
    function getOracleFee(uint256 req) external view returns(uint256) {  //req: 1 - cancel, 2 - claim, returns: value
        return gasLimit[req] * customGasPrice;
    }

    function checkBalance(address payable pair, address tokenForeign, address user) external onlyAllowed returns(uint256 requestId) {
        requestId = requests.length;
        requests.push(Request(msg.sender, tokenForeign, user, pair));

        uint256 myId = ICompanyOracle(companyOracle).getBalance(NETWORK, tokenForeign, user);
        companyOracleRequests[myId] = requestId;
        //_provable_request(requestId, network, tokenForeign, user);
    }

    function oracleCallback(uint256 requestId, uint256 balance) external returns(bool) {
        require (companyOracle == msg.sender, "Wrong Oracle");
        uint256 r_id = companyOracleRequests[requestId];
        require(r_id != 0, "Wrong requestId");
        companyOracleRequests[requestId] = 0;   // requestId fulfilled
        Request storage r = requests[r_id];
        ISwapFactory(r.factory).balanceCallback(r.pair, r.user, balance);
        emit CompanyOracle(r_id, balance);
        return true;
    }

    function checkBalances(address payable pair, address tokenForeign, address user) external onlyAllowed returns(uint256 requestId) {
        requestId = requests.length;
        requests.push(Request(msg.sender, tokenForeign, user, pair));
        (address tokenA, address tokenB) = ISwapPair(pair).getTokens();
        address[] memory users = new address[](3);
        users[0] = user;
        users[1] = NATIVE;
        users[2] = FOREIGN;
        uint256 myId = ICompanyOracle(companyOracle).getPriceAndBalance(tokenA, tokenB, NETWORK, tokenForeign, users);
        companyOracleRequests[myId] = requestId;
        //_provable_request(requestId, network, tokenForeign, user);
    }

    function oraclePriceAndBalanceCallback(uint256 requestId,uint256 priceA,uint256 priceB,uint256[] calldata balances) external returns(bool) {
        require (companyOracle == msg.sender, "Wrong Oracle");
        uint256 r_id = companyOracleRequests[requestId];
        require(r_id != 0, "Wrong requestId");
        companyOracleRequests[requestId] = 0;   // requestId fulfilled
        Request storage r = requests[r_id];
        require(priceA != 0 && priceB != 0, "Zero price");
        uint256 rate = priceB * NOMINATOR / priceA;     // get rate on BSC side: ETH price / BNB price
        ISwapFactory(r.factory).balancesCallback(r.pair, r.user, balances[0], balances[2], balances[1], rate);
        emit CompanyOracle3(r_id, balances[0], balances[1], balances[2]);
        return true;
    }

    function withdraw(uint256 amount) external onlyAllowed returns (bool) {
        msg.sender.transfer(amount);
        return true;
    }

    // set gas limit to request: 1 - cancel request, 2 - claim request
    function setGasLimit(uint256 req, uint256 amount) external onlyAllowed returns (bool) {
        gasLimit[req] = amount;
        return true;
    }

    function setCustomGasPrice(uint256 amount) external onlyAllowed returns (bool) {
        customGasPrice = amount;
        //provable_setCustomGasPrice(amount);
        return true;
    }

    receive() external payable {}
}