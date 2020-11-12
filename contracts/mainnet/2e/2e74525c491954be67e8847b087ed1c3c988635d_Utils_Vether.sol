// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

interface iERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
}

interface iROUTER {
    function totalStaked() external view returns (uint);
    function totalVolume() external view returns (uint);
    function totalFees() external view returns (uint);
    function unstakeTx() external view returns (uint);
    function stakeTx() external view returns (uint);
    function swapTx() external view returns (uint);
    function tokenCount() external view returns(uint);
    function getToken(uint) external view returns(address);
    function getPool(address) external view returns(address payable);
    function stakeForMember(uint inputBase, uint inputToken, address token, address member) external payable returns (uint units);
}

interface iPOOL {
    function genesis() external view returns(uint);
    function baseAmt() external view returns(uint);
    function tokenAmt() external view returns(uint);
    function baseAmtStaked() external view returns(uint);
    function tokenAmtStaked() external view returns(uint);
    function fees() external view returns(uint);
    function volume() external view returns(uint);
    function txCount() external view returns(uint);
    function getBaseAmtStaked(address) external view returns(uint);
    function getTokenAmtStaked(address) external view returns(uint);
    function calcValueInBase(uint) external view returns (uint);
    function calcValueInToken(uint) external view returns (uint);
    function calcTokenPPinBase(uint) external view returns (uint);
    function calcBasePPinToken(uint) external view returns (uint);
}

interface iDAO {
    function ROUTER() external view returns(address);
}

// SafeMath
library SafeMath {

    function add(uint a, uint b) internal pure returns (uint)   {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Utils_Vether {

    using SafeMath for uint;

    address public BASE;
    address public DEPLOYER;
    iDAO public DAO;

    uint public one = 10**18;

    struct TokenDetails {
        string name;
        string symbol;
        uint decimals;
        uint totalSupply;
        uint balance;
        address tokenAddress;
    }

    struct ListedAssetDetails {
        string name;
        string symbol;
        uint decimals;
        uint totalSupply;
        uint balance;
        address tokenAddress;
        bool hasClaimed;
    }

    struct GlobalDetails {
        uint totalStaked;
        uint totalVolume;
        uint totalFees;
        uint unstakeTx;
        uint stakeTx;
        uint swapTx;
    }

    struct PoolDataStruct {
        address tokenAddress;
        address poolAddress;
        uint genesis;
        uint baseAmt;
        uint tokenAmt;
        uint baseAmtStaked;
        uint tokenAmtStaked;
        uint fees;
        uint volume;
        uint txCount;
        uint poolUnits;
    }

    // Only Deployer can execute
    modifier onlyDeployer() {
        require(msg.sender == DEPLOYER, "DeployerErr");
        _;
    }

    constructor () public payable {
        BASE = 0x4Ba6dDd7b89ed838FEd25d208D4f644106E34279;
        DEPLOYER = msg.sender;
    }

    function setGenesisDao(address dao) public onlyDeployer {
        DAO = iDAO(dao);
    }

    // function DAO() internal view returns(iDAO) {
    //     return DAO;
    // }

    //====================================DATA-HELPERS====================================//

    function getTokenDetails(address token) public view returns (TokenDetails memory tokenDetails){
        return getTokenDetailsWithMember(token, msg.sender);
    }

    function getTokenDetailsWithMember(address token, address member) public view returns (TokenDetails memory tokenDetails){
        if(token == address(0)){
            tokenDetails.name = 'ETHEREUM';
            tokenDetails.symbol = 'ETH';
            tokenDetails.decimals = 18;
            tokenDetails.totalSupply = 100000000 * 10**18;
            tokenDetails.balance = msg.sender.balance;
        } else {
            tokenDetails.name = iERC20(token).name();
            tokenDetails.symbol = iERC20(token).symbol();
            tokenDetails.decimals = iERC20(token).decimals();
            tokenDetails.totalSupply = iERC20(token).totalSupply();
            tokenDetails.balance = iERC20(token).balanceOf(member);
        }
        tokenDetails.tokenAddress = token;
        return tokenDetails;
    }

    function getGlobalDetails() public view returns (GlobalDetails memory globalDetails){
        globalDetails.totalStaked = iROUTER(DAO.ROUTER()).totalStaked();
        globalDetails.totalVolume = iROUTER(DAO.ROUTER()).totalVolume();
        globalDetails.totalFees = iROUTER(DAO.ROUTER()).totalFees();
        globalDetails.unstakeTx = iROUTER(DAO.ROUTER()).unstakeTx();
        globalDetails.stakeTx = iROUTER(DAO.ROUTER()).stakeTx();
        globalDetails.swapTx = iROUTER(DAO.ROUTER()).swapTx();
        return globalDetails;
    }

    function getPool(address token) public view returns(address payable pool){
        return iROUTER(DAO.ROUTER()).getPool(token);
    }
    function tokenCount() public view returns (uint256 count){
        return iROUTER(DAO.ROUTER()).tokenCount();
    }
    function allTokens() public view returns (address[] memory _allTokens){
        return tokensInRange(0, iROUTER(DAO.ROUTER()).tokenCount()) ;
    }
    function tokensInRange(uint start, uint count) public view returns (address[] memory someTokens){
        if(start.add(count) > tokenCount()){
            count = tokenCount().sub(start);
        }
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++){
            result[i] = iROUTER(DAO.ROUTER()).getToken(i);
        }
        return result;
    }
    function allPools() public view returns (address[] memory _allPools){
        return poolsInRange(0, tokenCount());
    }
    function poolsInRange(uint start, uint count) public view returns (address[] memory somePools){
        if(start.add(count) > tokenCount()){
            count = tokenCount().sub(start);
        }
        address[] memory result = new address[](count);
        for (uint i = 0; i<count; i++){
            result[i] = getPool(iROUTER(DAO.ROUTER()).getToken(i));
        }
        return result;
    }

    function getPoolData(address token) public view returns(PoolDataStruct memory poolData){
        address payable pool = getPool(token);
        poolData.poolAddress = pool;
        poolData.tokenAddress = token;
        poolData.genesis = iPOOL(pool).genesis();
        poolData.baseAmt = iPOOL(pool).baseAmt();
        poolData.tokenAmt = iPOOL(pool).tokenAmt();
        poolData.baseAmtStaked = iPOOL(pool).baseAmtStaked();
        poolData.tokenAmtStaked = iPOOL(pool).tokenAmtStaked();
        poolData.fees = iPOOL(pool).fees();
        poolData.volume = iPOOL(pool).volume();
        poolData.txCount = iPOOL(pool).txCount();
        poolData.poolUnits = iERC20(pool).totalSupply();
        return poolData;
    }

    function getMemberShare(address token, address member) public view returns(uint baseAmt, uint tokenAmt){
        address pool = getPool(token);
        uint units = iERC20(pool).balanceOf(member);
        return getPoolShare(token, units);
    }

    function getPoolShare(address token, uint units) public view returns(uint baseAmt, uint tokenAmt){
        address payable pool = getPool(token);
        baseAmt = calcShare(units, iERC20(pool).totalSupply(), iPOOL(pool).baseAmt());
        tokenAmt = calcShare(units, iERC20(pool).totalSupply(), iPOOL(pool).tokenAmt());
        return (baseAmt, tokenAmt);
    }

    function getShareOfBaseAmount(address token, address member) public view returns(uint baseAmt){
        address payable pool = getPool(token);
        uint units = iERC20(pool).balanceOf(member);
        return calcShare(units, iERC20(pool).totalSupply(), iPOOL(pool).baseAmt());
    }
    function getShareOfTokenAmount(address token, address member) public view returns(uint baseAmt){
        address payable pool = getPool(token);
        uint units = iERC20(pool).balanceOf(member);
        return calcShare(units, iERC20(pool).totalSupply(), iPOOL(pool).tokenAmt());
    }

    function getPoolShareAssym(address token, uint units, bool toBase) public view returns(uint baseAmt, uint tokenAmt, uint outputAmt){
        address payable pool = getPool(token);
        if(toBase){
            baseAmt = calcAsymmetricShare(units, iERC20(pool).totalSupply(), iPOOL(pool).baseAmt());
            tokenAmt = 0;
            outputAmt = baseAmt;
        } else {
            baseAmt = 0;
            tokenAmt = calcAsymmetricShare(units, iERC20(pool).totalSupply(), iPOOL(pool).tokenAmt());
            outputAmt = tokenAmt;
        }
        return (baseAmt, tokenAmt, outputAmt);
    }

    function getPoolAge(address token) public view returns (uint daysSinceGenesis){
        address payable pool = getPool(token);
        uint genesis = iPOOL(pool).genesis();
        if(now < genesis.add(86400)){
            return 1;
        } else {
            return (now.sub(genesis)).div(86400);
        }
    }

    function getPoolROI(address token) public view returns (uint roi){
        address payable pool = getPool(token);
        uint _baseStart = iPOOL(pool).baseAmtStaked().mul(2);
        uint _baseEnd = iPOOL(pool).baseAmt().mul(2);
        uint _ROIS = (_baseEnd.mul(10000)).div(_baseStart);
        uint _tokenStart = iPOOL(pool).tokenAmtStaked().mul(2);
        uint _tokenEnd = iPOOL(pool).tokenAmt().mul(2);
        uint _ROIA = (_tokenEnd.mul(10000)).div(_tokenStart);
        return (_ROIS + _ROIA).div(2);
   }

   function getPoolAPY(address token) public view returns (uint apy){
        uint avgROI = getPoolROI(token);
        uint poolAge = getPoolAge(token);
        return (avgROI.mul(365)).div(poolAge);
   }

    function isMember(address token, address member) public view returns(bool){
        address payable pool = getPool(token);
        if (iERC20(pool).balanceOf(member) > 0){
            return true;
        } else {
            return false;
        }
    }

    //====================================PRICING====================================//

    function calcValueInBase(address token, uint amount) public view returns (uint value){
       address payable pool = getPool(token);
       return calcValueInBaseWithPool(pool, amount);
    }

    function calcValueInToken(address token, uint amount) public view returns (uint value){
        address payable pool = getPool(token);
        return calcValueInTokenWithPool(pool, amount);
    }

    function calcTokenPPinBase(address token, uint amount) public view returns (uint _output){
        address payable pool = getPool(token);
        return  calcTokenPPinBaseWithPool(pool, amount);
   }

    function calcBasePPinToken(address token, uint amount) public view returns (uint _output){
        address payable pool = getPool(token);
        return  calcValueInBaseWithPool(pool, amount);
    }

    function calcValueInBaseWithPool(address payable pool, uint amount) public view returns (uint value){
       uint _baseAmt = iPOOL(pool).baseAmt();
       uint _tokenAmt = iPOOL(pool).tokenAmt();
       return (amount.mul(_baseAmt)).div(_tokenAmt);
    }

    function calcValueInTokenWithPool(address payable pool, uint amount) public view returns (uint value){
        uint _baseAmt = iPOOL(pool).baseAmt();
        uint _tokenAmt = iPOOL(pool).tokenAmt();
        return (amount.mul(_tokenAmt)).div(_baseAmt);
    }

    function calcTokenPPinBaseWithPool(address payable pool, uint amount) public view returns (uint _output){
        uint _baseAmt = iPOOL(pool).baseAmt();
        uint _tokenAmt = iPOOL(pool).tokenAmt();
        return  calcSwapOutput(amount, _tokenAmt, _baseAmt);
   }

    function calcBasePPinTokenWithPool(address payable pool, uint amount) public view returns (uint _output){
        uint _baseAmt = iPOOL(pool).baseAmt();
        uint _tokenAmt = iPOOL(pool).tokenAmt();
        return  calcSwapOutput(amount, _baseAmt, _tokenAmt);
    }

    //====================================CORE-MATH====================================//

    function calcPart(uint bp, uint total) public pure returns (uint part){
        // 10,000 basis points = 100.00%
        require((bp <= 10000) && (bp > 0), "Must be correct BP");
        return calcShare(bp, 10000, total);
    }

    function calcShare(uint part, uint total, uint amount) public pure returns (uint share){
        // share = amount * part/total
        return(amount.mul(part)).div(total);
    }

    function  calcSwapOutput(uint x, uint X, uint Y) public pure returns (uint output){
        // y = (x * X * Y )/(x + X)^2
        uint numerator = x.mul(X.mul(Y));
        uint denominator = (x.add(X)).mul(x.add(X));
        return numerator.div(denominator);
    }

    function  calcSwapFee(uint x, uint X, uint Y) public pure returns (uint output){
        // y = (x * x * Y) / (x + X)^2
        uint numerator = x.mul(x.mul(Y));
        uint denominator = (x.add(X)).mul(x.add(X));
        return numerator.div(denominator);
    }

    function  calcSwapInputFee(uint x, uint X) public pure returns (uint output){
        // slip = (x * x) / (x + X)
        uint numerator = x.mul(x);
        uint denominator = x.add(X);
        return numerator.div(denominator);
    }

    function calcStakeUnits(uint b, uint B, uint t, uint T, uint P) public view returns (uint units){
        if(P == 0){
            return b;
        } else {
            // units = ((P (t B + T b))/(2 T B)) * slipAdjustment
            // P * (part1 + part2) / (part3) * slipAdjustment
            uint slipAdjustment = getSlipAdustment(b, B, t, T);
            uint part1 = t.mul(B);
            uint part2 = T.mul(b);
            uint part3 = T.mul(B).mul(2);
            uint _units = (P.mul(part1.add(part2))).div(part3);
            return _units.mul(slipAdjustment).div(one);  // Divide by 10**18
        }
    }

    function getSlipAdustment(uint b, uint B, uint t, uint T) public view returns (uint slipAdjustment){
        // slipAdjustment = (1 - ABS((B t - b T)/((2 b + B) (t + T))))
        // 1 - ABS(part1 - part2)/(part3 * part4))
        uint part1 = B.mul(t);
        uint part2 = b.mul(T);
        uint part3 = b.mul(2).add(B);
        uint part4 = t.add(T);
        uint numerator;
        if(part1 > part2){
            numerator = part1.sub(part2);
        } else {
            numerator = part2.sub(part1);
        }
        uint denominator = part3.mul(part4);
        return one.sub((numerator.mul(one)).div(denominator)); // Multiply by 10**18
    }

    function calcAsymmetricShare(uint u, uint U, uint A) public pure returns (uint share){
        // share = (u * U * (2 * A^2 - 2 * U * u + U^2))/U^3
        // (part1 * (part2 - part3 + part4)) / part5
        uint part1 = u.mul(A);
        uint part2 = U.mul(U).mul(2);
        uint part3 = U.mul(u).mul(2);
        uint part4 = u.mul(u);
        uint numerator = part1.mul(part2.sub(part3).add(part4));
        uint part5 = U.mul(U).mul(U);
        return numerator.div(part5);
    }

}