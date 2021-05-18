// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ISwapFactory {
    function balanceCallback(address hashAddress, uint256 foreignBalance) external returns(bool);
    function balancesCallback(
        address hashAddress, 
        uint256 foreignBalance, // total user's tokens balance on foreign chain
        uint256 foreignSpent,   // total tokens spent by SmartSwap pair
        uint256 nativeEncoded   // (nativeSpent, nativeRate) = _decode(nativeEncoded)
    ) external returns(bool);
}

// 1 - BNB, 2 - ETH, 3 - BTC
interface ICompanyOracle {
    function getBalance(uint256 network,address token,address user) external returns(uint256);
    function getPriceAndBalance(address tokenA,address tokenB,uint256 network,address token,address[] calldata user) external returns(uint256);
}

interface IPriceFeed {
    function latestAnswer() external returns (int256);
}


contract Validator is Ownable {

    uint256 constant NETWORK = 56;  // ETH mainnet = 1, Ropsten = 3,Kovan - 42, BSC_TESTNET = 97, BSC_MAINNET = 56
    uint256 constant NOMINATOR = 10**18;     // rate nominator

    
    mapping(address => bool) public isAllowedAddress; 
    address public factory;
    address public companyOracle;
    mapping (uint256 => address) public companyOracleRequests;  // companyOracleRequest ID => user (hashAddress)
    mapping (uint256 => uint256) public gasLimit;  // request type => amount of gas
    uint256 public customGasPrice = 50 * 10**9; // 20 GWei
    mapping(address => IPriceFeed) tokenPriceFeed;

    event LogMsg(string description);

    modifier onlyAllowed() {
        require(isAllowedAddress[msg.sender] || owner() == msg.sender,"ERR_ALLOWED_ADDRESS_ONLY");
        _;
    }


    constructor (address _oracle) {
        companyOracle = _oracle;
        //Kovan Testnet
        //tokenPriceFeed[address(1)] = IPriceFeed(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);    // BNB/USD
        //tokenPriceFeed[address(2)] = IPriceFeed(0x9326BFA02ADD2366b30bacB125260Af641031331);    // ETH/USD
        // BSC Testnet
        //tokenPriceFeed[address(1)] = IPriceFeed(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);    // BNB/USD
        //tokenPriceFeed[address(2)] = IPriceFeed(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);    // ETH/USD

        // ETH mainnet
        tokenPriceFeed[address(1)] = IPriceFeed(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);    // BNB/USD
        tokenPriceFeed[address(2)] = IPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);    // ETH/USD
        // BSC mainnet
        //tokenPriceFeed[address(1)] = IPriceFeed(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);    // BNB/USD
        //tokenPriceFeed[address(2)] = IPriceFeed(0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e);    // ETH/USD

    }

    // returns rate (with 9 decimals) = Token B price / Token A price
    function getRate(address tokenA, address tokenB) external returns (uint256 rate) {
        int256 priceA = tokenPriceFeed[tokenA].latestAnswer();
        int256 priceB = tokenPriceFeed[tokenB].latestAnswer();
        require(priceA > 0 && priceB > 0, "Zero price");
        rate = uint256(priceB * int256(NOMINATOR) / priceA);     // get rate on BSC side: ETH price / BNB price
    }

    function setCompanyOracle(address _addr) external onlyOwner returns(bool) {
        companyOracle = _addr;
        return true;
    }

    function setFactory(address _addr) external onlyOwner returns(bool) {
        factory = _addr;
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

    function checkBalance(address foreignFactory, address user) external returns(uint256) {
        require(msg.sender == factory, "Not factory");
        uint256 myId = ICompanyOracle(companyOracle).getBalance(NETWORK, foreignFactory, user);
        companyOracleRequests[myId] = user;
        return myId;
    }

    function oracleCallback(uint256 requestId, uint256 balance) external returns(bool) {
        require (companyOracle == msg.sender, "Wrong Oracle");
        address hashAddress = companyOracleRequests[requestId];
        require(hashAddress != address(0), "Wrong requestId");
        delete companyOracleRequests[requestId];   // requestId fulfilled
        ISwapFactory(factory).balanceCallback(hashAddress, balance);
        return true;
    }

    function checkBalances(address foreignFactory, address[] calldata users) external returns(uint256) {
        require(msg.sender == factory, "Not factory");
        uint256 myId = ICompanyOracle(companyOracle).getPriceAndBalance(address(1), address(2), NETWORK, foreignFactory, users);
        companyOracleRequests[myId] = users[0];
        return myId;
    }

    function oraclePriceAndBalanceCallback(uint256 requestId,uint256 priceA,uint256 priceB,uint256[] calldata balances) external returns(bool) {
        require (companyOracle == msg.sender, "Wrong Oracle");
        priceA = priceB; // remove unused
        address hashAddress = companyOracleRequests[requestId];
        require(hashAddress != address(0), "Wrong requestId");
        delete companyOracleRequests[requestId];   // requestId fulfilled
        ISwapFactory(factory).balancesCallback(hashAddress, balances[0], balances[1], balances[2]);
        return true;
    }

    function withdraw(uint256 amount) external onlyAllowed returns (bool) {
        payable(msg.sender).transfer(amount);
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