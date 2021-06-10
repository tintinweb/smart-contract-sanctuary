/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StringUtil {
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function append2(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function append3(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }

    function bool2str(bool b) internal pure returns(string memory){
        if(b) return "true";

        return "false";
    }

    function address2str(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

contract Constants {
    uint internal constant oneMantissa = 10**18;

    enum LoopControl {
        NONE,
        CONTINUE,
        BREAK
    }
}

contract CompoundAddresses {
      address internal constant cDAIAddr = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
      address internal constant cETHAddr = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
      address internal constant cUSDCAddr = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
      address internal constant cUSDTAddr = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
      address internal constant cWBTCAddr = 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4;
      address internal constant cWBTC2Addr = 0xccF4429DB6322D5C611ee964527D42E5d685DD6a; //migrated at block number 12069867
      address internal constant cCOMPAddr = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;
      address internal constant cSAIAddr = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;
      address internal constant compAddr = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

      address internal constant compoundLensAddr = 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074;
      address internal constant comptrollerAddr = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
      address internal constant uniswapAnchoredViewAddr = 0x922018674c12a7F0D394ebEEf9B58F186CdE13c1;

      function getCWBTCAddr(uint blockNumber) public pure returns(address){
          if(blockNumber >= 12069867){
              return cWBTC2Addr;
          }

          return cWBTCAddr;
      }
}

contract ERC20Addresses {
      address internal constant usdtAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
}

contract UniswapV2Addresses {
      address internal constant uniswapV2Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
      address internal constant wETHAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

contract ERC20 {

    uint8 public decimals;

    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address dst, uint amount) external returns (bool);
    function symbol() external view returns (string memory);

}

contract USDT_ERC20 {
    function approve(address spender, uint value) external;
}

contract Comptroller {
    struct Market {
           bool isListed;
           uint collateralFactorMantissa;
           bool isComped;
    }

    mapping(address => Market) public markets;
    mapping(address => uint) public compAccrued;


    uint public closeFactorMantissa;
    uint public liquidationIncentiveMantissa;
    address public oracle;
    function getAccountLiquidity(address account) public view returns (uint, uint, uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function compSpeeds(address cTokenAddress) external view returns(uint);
    function getAllMarkets() public view returns (CToken[] memory);


}

contract CToken is ERC20{
    address public underlying;
    uint public totalBorrows;
    uint public totalReserves;
    
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function exchangeRateStored() public view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceStored(address account) public view returns (uint);
    function getCash() external view returns (uint);
    function totalBorrowsCurrent() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

contract PriceOracle {
    function getUnderlyingPrice(CToken cToken) public view returns (uint);
}

contract UniswapAnchoredView {
    function price(string memory symbol) public view returns (uint);
}

contract CErc20 is CToken {
    address public underlying;
    function liquidateBorrow(address borrower, uint repayAmount, CToken cTokenCollateral) external returns (uint);
}

contract CompoundLens {

    struct CompBalanceMetadataExt{
            uint balance;
            uint votes;
            address delegate;
            uint allocated;
    }

    function getCompBalanceMetadataExt(Comp comp, ComptrollerLensInterface comptroller, address account) external returns (CompBalanceMetadataExt memory);

}

contract Comp {

}

interface ComptrollerLensInterface {

}

contract ERC20ErrorReporter {
    enum ERC20Error {
        NO_ERROR,
        TRANSFER_FROM_FAILED,
        APPROVE_FAILED,
        TRANSFER_FAILED
    }

    event fail(uint err);
}

contract ERC20Methods is ERC20ErrorReporter, ERC20Addresses{

    function getDecimals(address token) internal view returns(uint decimals){
        if(token == address(0)){
            return 18;
        }

        return ERC20(token).decimals();
    }

    function transferIn(address token, address from, address to, uint amount) internal returns(ERC20Error){

        if(!ERC20(token).transferFrom(from, to, amount)){
             emit fail(uint(ERC20Error.TRANSFER_FROM_FAILED));
             return ERC20Error.TRANSFER_FROM_FAILED;
        }

        return ERC20Error.NO_ERROR;
    }

    function transferOut(address token, address to, uint amount) internal returns(ERC20Error){
        ERC20 erc20 = ERC20(token);

        if(!erc20.approve(to, amount)){
             emit fail(uint(ERC20Error.APPROVE_FAILED));
             return ERC20Error.APPROVE_FAILED;
        }

        if(!erc20.transfer(to, amount)){
             emit fail(uint(ERC20Error.TRANSFER_FAILED));
             return ERC20Error.TRANSFER_FAILED;
        }

        return ERC20Error.NO_ERROR;
    }

    //works with ETH and ERC20
    function balanceOf(address tokenAddr, address accAddr) internal view returns(uint){
        //for ETH
        if(tokenAddr == address(0)){
            return accAddr.balance;
        }

        return ERC20(tokenAddr).balanceOf(accAddr);
    }

    //works with standard and non-standard ERC20
    function approve(address tokenAddr, address spender, uint256 amount) internal returns(bool){
        if(tokenAddr == usdtAddr){
             USDT_ERC20(usdtAddr).approve(spender, 0);
             USDT_ERC20(usdtAddr).approve(spender, amount);
             return true;
        }

        return ERC20(tokenAddr).approve(spender, amount);
    }
}

contract CompoundMethodsErrorReporter {
    enum CompoundMethodsError {
        NO_ERROR,
        Liquidation_Failed,
        APPROVE_FAILED,
        Redeem_Failed
    }

    event fail(uint err);
    event fail(uint err, uint detail);
}

contract CompoundMethods is CompoundMethodsErrorReporter, ERC20Methods, CompoundAddresses, UniswapV2Addresses, Constants, StringUtil{
      using SafeMath for uint;

      function cmp_redeemUnderlying(address cToken, uint amount) internal returns(CompoundMethodsError err){
          uint error_redeem = CToken(cToken).redeem(amount);
          if(error_redeem != 0){
              emit fail(uint(CompoundMethodsError.Redeem_Failed), error_redeem);
              return CompoundMethodsError.Redeem_Failed;
          }

          return CompoundMethodsError.NO_ERROR;
      }

      function cmp_liquidateBorrow(address cTokenBorrowed, address underlyingBorrowed, address borrower, uint repayAmount, CToken cTokenCollateral) internal returns(CompoundMethodsError err){
          //approve USDT won't work
          if(!approve(underlyingBorrowed, cTokenBorrowed, repayAmount)){
              emit fail(uint(CompoundMethodsError.APPROVE_FAILED));
              return CompoundMethodsError.APPROVE_FAILED;
          }

          //liquidate
          uint err_liquidateBorrow = CErc20(cTokenBorrowed).liquidateBorrow(borrower, repayAmount, cTokenCollateral);
          if(err_liquidateBorrow != 0){
              emit fail(uint(CompoundMethodsError.APPROVE_FAILED), err_liquidateBorrow);
              return CompoundMethodsError.APPROVE_FAILED;
          }

          return CompoundMethodsError.NO_ERROR;
      }

      function cmp_getUnderlyingAddr(address cTokenAddr) internal view returns(address underlyingAddr) {
          if(cTokenAddr == cETHAddr){
              return address(0);
          }

          underlyingAddr = CToken(cTokenAddr).underlying();

          return underlyingAddr;
      }


      function cmp_underlyingValueInUSD(uint underlyingBalance, address cTokenAddr) internal view returns(uint valueInUSD){

          uint underlyingDecimals = cmp_getUnderlyingDecimals(cTokenAddr);
          valueInUSD = cmp_getUnderlyingPriceInUSD(cTokenAddr).mul(underlyingBalance).div(10**underlyingDecimals);

          return valueInUSD;
      }

      function cmp_getUnderlyingPriceInUSD(address cTokenAddr) internal view returns (uint priceInUSD){

            address oracleAddr = Comptroller(comptrollerAddr).oracle();

            if(cTokenAddr == cUSDCAddr || cTokenAddr == cUSDTAddr){
                priceInUSD = oneMantissa;
                return priceInUSD;
            }

            if(cTokenAddr == cWBTC2Addr || cTokenAddr == cWBTCAddr){
                priceInUSD = PriceOracle(oracleAddr).getUnderlyingPrice(CToken(cTokenAddr)).div(10**10);
                return priceInUSD;
            }

            priceInUSD = PriceOracle(oracleAddr).getUnderlyingPrice(CToken(cTokenAddr));
            return priceInUSD;
      }

      function cmp_getPriceInUSDByUnderlyingAddr(address underlyingAddr) internal view returns(uint underlyingPriceInUSD){
          string memory symbol = ERC20(underlyingAddr).symbol();
          if(compareStrings(symbol, "wBTC")){
              symbol = "BTC";
          }

          return cmp_getPriceBySymbol(symbol).mul(10**12);
      }

      function cmp_getPriceBySymbol(string memory symbol) internal view returns(uint priceInUSDMantissa6){
          return UniswapAnchoredView(uniswapAnchoredViewAddr).price(symbol);
      }

      function cmp_getUnderlyingSymbol(address cTokenAddr) internal view returns(string memory getUnderlyingSymbol){
          if(cTokenAddr == cETHAddr) return "ETH";

          if(cTokenAddr == cSAIAddr) return "SAI";

          return ERC20(CToken(cTokenAddr).underlying()).symbol();
      }

      function cmp_getUnderlyingDecimals(address cTokenAddr) internal view returns(uint decimals){
          if(cTokenAddr == cETHAddr){
               decimals = 18;
               return decimals;
          }

          address underlyingAddr = cmp_getUnderlyingAddr(cTokenAddr);
          decimals = ERC20(underlyingAddr).decimals();
          return decimals;
      }

      //not tested
      function cmp_getTotalSupplyInUSD(address cTokenAddr) internal view returns(uint totalSupplyInUSD){
          return cmp_underlyingValueInUSD(cmp_getTotalSupply(cTokenAddr), cTokenAddr);
      }

      function cmp_getTotalSupply(address cTokenAddr) internal view returns(uint totalSupply){
          CToken cToken = CToken(cTokenAddr);
          uint cash = cToken.getCash();
          uint totalBorrow = cToken.totalBorrows();
          uint totalReserves = cToken.totalReserves();

          return cash.add(totalBorrow).sub(totalReserves);
      }

      function cmp_getCompDistSpeedPerBlock(address cTokenAddr) internal view returns(uint compDistSpeedPerBlock){
          Comptroller comptroller = Comptroller(comptrollerAddr);
          return comptroller.compSpeeds(cTokenAddr);
      }


      function cmp_getCompDistAmount(address cTokenAddr, uint numberOfBlocks) internal view returns(uint compDistAmount){
          return cmp_getCompDistSpeedPerBlock(cTokenAddr).mul(numberOfBlocks);
      }

      function cmp_getCurrentCTokenAddrList() internal view returns(address[] memory cTokenAddrList){
            Comptroller comptroller = Comptroller(comptrollerAddr);
            CToken[] memory allMarkets = comptroller.getAllMarkets();

            cTokenAddrList = new address[](cmp_getNumberOfCurrentCTokens(allMarkets));

            CToken eachCToken;
            uint index;
            for(uint i = 0; i < allMarkets.length; i++){
                eachCToken = allMarkets[i];

                if(!cmp_isCurrentCToken(address(eachCToken))) continue;

                cTokenAddrList[index] = address(eachCToken);
                index++;
            }

            return cTokenAddrList;
      }

      function cmp_getCurrentCTokenSymbolList() internal view returns(string[] memory cTokenSymbolList){
            Comptroller comptroller = Comptroller(comptrollerAddr);
            CToken[] memory allMarkets = comptroller.getAllMarkets();

            cTokenSymbolList = new string[](cmp_getNumberOfCurrentCTokens(allMarkets));

            CToken eachCToken;
            uint index;
            for(uint i = 0; i < allMarkets.length; i++){
                eachCToken = allMarkets[i];

                if(!cmp_isCurrentCToken(address(eachCToken))) continue;

                cTokenSymbolList[index] = eachCToken.symbol();
                index++;
            }

            return cTokenSymbolList;
      }



      function cmp_isCurrentCToken(address cTokenAddr) internal view returns(bool){
          bool isListed;
          bool isComped;

          Comptroller comptroller = Comptroller(comptrollerAddr);
          (isListed, , isComped) = comptroller.markets(cTokenAddr);

          if(isListed && isComped) return true;

          return false;
      }

      function cmp_getNumberOfCurrentCTokens(CToken[] memory allMarkets) internal view returns(uint numberOfCurrentCTokens){

          for(uint i = 0; i < allMarkets.length; i++){
              if(cmp_isCurrentCToken(address(allMarkets[i]))) numberOfCurrentCTokens++;
          }

          return numberOfCurrentCTokens;
      }

      function cmp_getPercentageOfStakeOnSupplyMantissa(address acc, address cTokenAddr) internal view returns(uint percentageOfStakeOnSupplyMantissa){

          uint supplyByTheAcc = cmp_getUnderlyingBalanceOfAnAcc(acc, cTokenAddr);

          return cmp_calPercentageOfStakeOnSupplyMantissa(cTokenAddr, supplyByTheAcc);
      }

      function cmp_calPercentageOfStakeOnSupplyMantissa(address cTokenAddr, uint supplyByTheAcc) internal view returns(uint percentageOfStakeOnSupplyMantissa){
          uint totalSupply = cmp_getTotalSupply(cTokenAddr);

          return supplyByTheAcc.mul(oneMantissa).div(totalSupply);
      }

      function cmp_getPercentageOfStakeOnBorrowMantissa(address acc, address cTokenAddr) internal view returns(uint percentageOfStakeOnBorrowMantissa){

          uint err;
          uint borrowByTheAcc;

          (err, ,borrowByTheAcc, ) = CToken(cTokenAddr).getAccountSnapshot(acc);

          if(err != 0){
              return 0;
          }

          return cmp_calPercentageOfStakeOnBorrowMantissa(cTokenAddr, borrowByTheAcc);
      }

      function cmp_calPercentageOfStakeOnBorrowMantissa(address cTokenAddr, uint borrowByTheAcc) internal view returns(uint percentageOfStakeOnBorrowMantissa){

          uint totalBorrow = CToken(cTokenAddr).totalBorrows();

          return borrowByTheAcc.mul(oneMantissa).div(totalBorrow);
      }

      function cmp_getUnderlyingBalanceOfAnAcc(address acc, address cTokenAddr) internal view returns(uint underlyingBalanceOfAnAcc){
          CToken cToken = CToken(cTokenAddr);
          return cToken.balanceOf(acc).mul(cToken.exchangeRateStored()).div(oneMantissa);
      }

      function cmp_getBorrowedTokenList(address acc) internal view returns(address[] memory borrowedCTokenList){
          CToken[] memory allMarkets = Comptroller(comptrollerAddr).getAllMarkets();

          uint length;
          for(uint i = 0; i < allMarkets.length; i++){
//require(false, uint2str(CToken(cDAIAddr).borrowBalanceStored(acc)));
              if(allMarkets[i].borrowBalanceStored(acc) == 0) continue;

              length++;
          }

          borrowedCTokenList = new address[](length);

          uint index;
          for(uint i = 0; i < allMarkets.length; i++){
              if(allMarkets[i].borrowBalanceStored(acc) == 0) continue;

              borrowedCTokenList[index] = address(allMarkets[i]);
              index++;
          }

          return borrowedCTokenList;
      }

      function cmp_getCollateralFactorMantissa(address cTokenAddr) internal view returns(uint collateralFactorMantissa){
          bool isListed;

          (isListed, collateralFactorMantissa, ) = Comptroller(comptrollerAddr).markets(cTokenAddr);

          if(!isListed) return 0;

          return collateralFactorMantissa;
      }



}

contract ArrayUtil {
      
      function quickSortDESC(string[] memory keys, uint[] memory values) internal pure returns (string[] memory, uint[] memory){

            string[] memory keysPlus = new string[](keys.length + 1);
            uint[] memory valuesPlus = new uint[](values.length + 1);

            for(uint i = 0; i < keys.length; i++){
                keysPlus[i] = keys[i];
                valuesPlus[i] = values[i];
            }

            (keysPlus, valuesPlus) = quickSort(keysPlus, valuesPlus, 0, keysPlus.length - 1);

            string[] memory keys_desc = new string[](keys.length);
            uint[] memory values_desc = new uint[](values.length);
            for(uint i = 0; i < keys.length; i++){
                keys_desc[keys.length - 1 - i] = keysPlus[i + 1];
                values_desc[keys.length - 1 - i] = valuesPlus[i + 1];
            }

            return (keys_desc, values_desc);
      }

      function quickSort(string[] memory keys, uint[] memory values, uint left, uint right) internal pure returns (string[] memory, uint[] memory){
            uint i = left;
            uint j = right;
            uint pivot = values[left + (right - left) / 2];
            while (i <= j) {
                while (values[i] < pivot) i++;
                while (pivot < values[j]) j--;
                if (i <= j) {
                    (keys[i], keys[j]) = (keys[j], keys[i]);
                    (values[i], values[j]) = (values[j], values[i]);
                    i++;
                    j--;
                }
            }
            if (left < j)
                quickSort(keys, values, left, j);

            if (i < right)
                quickSort(keys, values, i, right);

                return (keys, values);
      }
}

contract Logging is StringUtil{

    function debug(string memory name, string[] memory values) internal pure{
        string memory log_name = append(name, ": ");
        string memory valueStr;

        for(uint i = 0; i < values.length; i++){
            valueStr = append(valueStr, values[i]);
            valueStr = append(valueStr, ", ");
        }

        require(false, append(log_name, valueStr));
    }

    function debug(string memory name, address[] memory values) internal pure{
        string memory log_name = append(name, ": ");
        string memory valueStr;

        for(uint i = 0; i < values.length; i++){
            valueStr = append(valueStr, address2str(values[i]));
            valueStr = append(valueStr, ", ");
        }

        require(false, append(log_name, valueStr));
    }

    function debug(string memory name, uint[] memory values) internal pure{
        string memory log_name = append(name, ": ");
        string memory valueStr;

        for(uint i = 0; i < values.length; i++){
            valueStr = append(valueStr, uint2str(values[i]));
            valueStr = append(valueStr, ", ");
        }

        require(false, append(log_name, valueStr));
    }

    function debug(string memory name, string memory value) internal pure{
        string memory log_name = append(name, ": ");
        string memory valueStr = value;

        require(false, append(log_name, valueStr));
    }

    function debug(string memory name, address value) internal pure{
        string memory log_name = append(name, ": ");
        string memory valueStr = address2str(value);

        require(false, append(log_name, valueStr));
    }

    function debug(string memory name, uint value) internal pure{
        string memory log_name = append(name, ": ");
        string memory valueStr = uint2str(value);

        require(false, append(log_name, valueStr));
    }

    function debug(string memory name, bool value) internal pure{
        string memory log_name = append(name, ": ");
        string memory valueStr = bool2str(value);

        require(false, append(log_name, valueStr));
    }



    event log(string name, address value);
    event log(string name, uint value);
    event log(string name, string value);
    event log(string name, bool value);
    event log(string name, uint[] value);
    event log(string name, address[] value);

}

contract CompFarmingSummaryV3Model is CompoundMethods, ArrayUtil{
    uint256 constant public MAX_INT_NUMBER = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    enum LiquidationRiskRanking{
        ZERO_RISK,
        INTEREST_RISK_ONLY,
        PRICE_MOVEMENT_RISK
    }

    struct CompProfile{
         uint balance;
         uint yetToClaimed;
    }

    struct AccountInterestProfile{
        CTokenInterest[] supplyInterests;
        CTokenInterest[] borrowInterests;

        uint totalInterestInUSD_;
        bool isPositiveInterest_;
    }

    struct CTokenInterest{
        address cTokenAddr;
        uint interestRateMantissa;
        uint balance;
        uint numberOfBlocks;

        string underlyingSymbol_;
        uint interestInUSD_;
    }

    struct AccountProfile{
        SupplyAsset[] suppliedAssets;
        BorrowAsset[] borrowedAssets;

        uint totalSuppliedInUSD_;
        uint totalBorrowedInUSD_;
        uint totalSuppliedInUsdAsCollateral_;
        uint borrowLimitPCTMantissa_;
        uint accountCapital_;

        uint[] borrowLimitPCTLineItemMantissaList;
    }

    struct SupplyAsset{
        Asset asset;

        uint collateralFactorMantissa_;
        uint suppliedInUsdAsCollateral_;
    }

    struct BorrowAsset{
        Asset asset;
    }

    struct Asset{
        address cTokenAddr;
        uint amount;

        string underlyingSymbol_;
        uint underlyingDecimals_;
        uint valueInUSD_;
        uint compSpeed_;
    }

    function createCTokenInterest(address cTokenAddr, uint interestRateMantissa, uint balance, uint numberOfBlocks) internal view returns(CTokenInterest memory cTokenInterest){
        cTokenInterest.cTokenAddr = cTokenAddr;
        cTokenInterest.interestRateMantissa = interestRateMantissa;
        cTokenInterest.balance = balance;
        cTokenInterest.numberOfBlocks = numberOfBlocks;

        refreshCTokenInterest(cTokenInterest);

        return cTokenInterest;
    }

    function refreshCTokenInterest(CTokenInterest memory cTokenInterest) internal view{
        cTokenInterest.underlyingSymbol_ = cmp_getUnderlyingSymbol(cTokenInterest.cTokenAddr);
        cTokenInterest.interestInUSD_ = cmp_underlyingValueInUSD(cTokenInterest.balance.mul(cTokenInterest.interestRateMantissa), cTokenInterest.cTokenAddr).mul(cTokenInterest.numberOfBlocks).div(oneMantissa);
    }

    function createAccountInterestProfile(CTokenInterest[] memory supplyInterests, CTokenInterest[] memory borrowInterests) internal pure returns(AccountInterestProfile memory accountInterestProfile){
        accountInterestProfile.supplyInterests = supplyInterests;
        accountInterestProfile.borrowInterests = borrowInterests;

        refreshAccountInterestProfile(accountInterestProfile);

        return accountInterestProfile;
    }

    function refreshAccountInterestProfile(AccountInterestProfile memory accountInterestProfile) internal pure {
        uint totalSupplyInterestInUSD;
        uint totalBorrowInterestInUSD;

        for(uint i = 0; i < accountInterestProfile.supplyInterests.length; i++){
            totalSupplyInterestInUSD += accountInterestProfile.supplyInterests[i].interestInUSD_;
        }

        for(uint i = 0; i < accountInterestProfile.borrowInterests.length; i++){
            totalBorrowInterestInUSD += accountInterestProfile.borrowInterests[i].interestInUSD_;
        }

        if(totalSupplyInterestInUSD > totalBorrowInterestInUSD){
            accountInterestProfile.totalInterestInUSD_ = totalSupplyInterestInUSD.sub(totalBorrowInterestInUSD);
            accountInterestProfile.isPositiveInterest_ = true;
        }

        if(totalSupplyInterestInUSD <= totalBorrowInterestInUSD){
            accountInterestProfile.totalInterestInUSD_ = totalBorrowInterestInUSD.sub(totalSupplyInterestInUSD);
            accountInterestProfile.isPositiveInterest_ = false;
        }
    }

    function createSupplyAsset(address cTokenAddr, uint amount) internal view returns(SupplyAsset memory supplyAsset){
        Asset memory asset = createAsset(cTokenAddr, amount);
        supplyAsset.asset = asset;

        refreshSupplyAsset(supplyAsset);

        return supplyAsset;
    }

    function createBorrowAsset(address cTokenAddr, uint amount) internal view returns(BorrowAsset memory borrowAsset){
        Asset memory asset = createAsset(cTokenAddr, amount);
        borrowAsset.asset = asset;

        return borrowAsset;
    }

    function updateSupplyAssetAmount(SupplyAsset memory supplyAsset, uint newAmount) internal view{
        supplyAsset.asset.amount = newAmount;

        refreshAsset(supplyAsset.asset);
        refreshSupplyAsset(supplyAsset);
    }

    function updateBorrowAssetAmount(BorrowAsset memory borrowAsset, uint newAmount) internal view{
        borrowAsset.asset.amount = newAmount;

        refreshAsset(borrowAsset.asset);
    }

    function refreshSupplyAsset(SupplyAsset memory supplyAsset) internal view{
        supplyAsset.collateralFactorMantissa_ = cmp_getCollateralFactorMantissa(supplyAsset.asset.cTokenAddr);
        supplyAsset.suppliedInUsdAsCollateral_ = supplyAsset.asset.valueInUSD_.mul(supplyAsset.collateralFactorMantissa_).div(oneMantissa);
    }

    function createAsset(address cTokenAddr, uint amount) internal view returns(Asset memory asset){
        updateAsset(asset, cTokenAddr, amount);

        return asset;
    }

    function updateAsset(Asset memory asset, address cTokenAddr, uint amount) internal view{
        asset.cTokenAddr = cTokenAddr;
        asset.amount = amount;

        refreshAsset(asset);
    }

    function refreshAsset(Asset memory asset) internal view{
        asset.underlyingSymbol_ = cmp_getUnderlyingSymbol(asset.cTokenAddr);
        asset.underlyingDecimals_ = cmp_getUnderlyingDecimals(asset.cTokenAddr);
        asset.valueInUSD_ = cmp_underlyingValueInUSD(asset.amount, asset.cTokenAddr);
        asset.compSpeed_ = cmp_getCompDistSpeedPerBlock(asset.cTokenAddr);
    }

    function createAccountProfile(SupplyAsset[] memory suppliedAssets, BorrowAsset[] memory borrowedAssets) internal pure returns(AccountProfile memory accountProfile){
        accountProfile.suppliedAssets = suppliedAssets;
        accountProfile.borrowedAssets = borrowedAssets;

        refreshAccountProfile(accountProfile);
    }

    function refreshAccountProfile(AccountProfile memory accountProfile) internal pure{
        accountProfile.totalSuppliedInUSD_ = calTotalSuppliedInUSD(accountProfile.suppliedAssets);
        accountProfile.totalBorrowedInUSD_ = calTotalBorrowedInUSD(accountProfile.borrowedAssets);
        accountProfile.totalSuppliedInUsdAsCollateral_ = calTotalSuppliedInUsdAsCollateral(accountProfile.suppliedAssets);
        accountProfile.accountCapital_ = calAccountCapital(accountProfile.totalSuppliedInUSD_, accountProfile.totalBorrowedInUSD_);
        accountProfile.borrowLimitPCTMantissa_ = calBorrowLimitPCTMantissa(accountProfile.totalSuppliedInUsdAsCollateral_, accountProfile.totalBorrowedInUSD_);
        accountProfile.borrowLimitPCTLineItemMantissaList = calBorrowLimitPCTLineItemMantissaList(accountProfile.suppliedAssets, accountProfile.borrowedAssets);
    }

    function calTotalSuppliedInUSD(SupplyAsset[] memory suppliedAssets) internal pure returns(uint totalSuppliedInUSD){
        for(uint i = 0; i < suppliedAssets.length; i++){
            totalSuppliedInUSD += suppliedAssets[i].asset.valueInUSD_;
        }

        return totalSuppliedInUSD;
    }

    function calTotalBorrowedInUSD(BorrowAsset[] memory borrowedAssets) internal pure returns(uint totalBorrowedInUSD){
        for(uint i = 0; i < borrowedAssets.length; i++){
            totalBorrowedInUSD += borrowedAssets[i].asset.valueInUSD_;
        }

        return totalBorrowedInUSD;
    }

    function calTotalSuppliedInUsdAsCollateral(SupplyAsset[] memory suppliedAssets) internal pure returns(uint totalSuppliedInUsdAsCollateral){
        for(uint i = 0; i < suppliedAssets.length; i++){
            totalSuppliedInUsdAsCollateral += suppliedAssets[i].suppliedInUsdAsCollateral_;
        }

        return totalSuppliedInUsdAsCollateral;
    }

    function calBorrowLimitPCTMantissa(uint totalSuppliedInUsdAsCollateral, uint totalBorrowedInUSD) internal pure returns(uint borrowLimitPCTMantissa){
        if(totalSuppliedInUsdAsCollateral == 0) return oneMantissa;

        return totalBorrowedInUSD.mul(oneMantissa).div(totalSuppliedInUsdAsCollateral);
    }

    function calBorrowLimitPCTLineItemMantissaList(SupplyAsset[] memory suppliedAssets, BorrowAsset[] memory borrowedAssets) internal pure returns(uint[] memory borrowLimitPCTLineItemMantissaList){

        borrowLimitPCTLineItemMantissaList = new uint[](suppliedAssets.length);

        bool _hasFound;
        BorrowAsset memory _borrowedAsset;

        for(uint i = 0; i < suppliedAssets.length; i++){
            (_hasFound, _borrowedAsset) = findBorrowedAssetBycTokenAddr(suppliedAssets[i].asset.cTokenAddr, borrowedAssets);

            if(suppliedAssets[i].suppliedInUsdAsCollateral_ == 0){
                borrowLimitPCTLineItemMantissaList[i] = MAX_INT_NUMBER;
            }

            if(!_hasFound){
                borrowLimitPCTLineItemMantissaList[i] = 0;
                continue;
            }

            if(suppliedAssets[i].suppliedInUsdAsCollateral_ != 0){
                borrowLimitPCTLineItemMantissaList[i] = _borrowedAsset.asset.valueInUSD_.mul(oneMantissa).div(suppliedAssets[i].suppliedInUsdAsCollateral_);
            }

        }

        return borrowLimitPCTLineItemMantissaList;
    }

    function calAccountCapital(uint totalSuppliedInUSD, uint totalBorrowedInUSD) internal pure returns(uint accountCapital){
        if(totalSuppliedInUSD > totalBorrowedInUSD){
            return totalSuppliedInUSD.sub(totalBorrowedInUSD);
        }

        return 0;
    }

    function findBorrowedAssetBycTokenAddr(address cTokenAddr, BorrowAsset[] memory borrowedAssets) internal pure returns(bool hasFound, BorrowAsset memory borrowAsset){
        for(uint i = 0; i < borrowedAssets.length; i++){
            if(borrowedAssets[i].asset.cTokenAddr == cTokenAddr) return (true, borrowedAssets[i]);
        }

        return (false, borrowAsset);
    }

    function addSuppliedAsset(AccountProfile memory accountProfile, SupplyAsset memory supplyAsset) internal view{

        for(uint i = 0; i < accountProfile.suppliedAssets.length; i++){
            if(accountProfile.suppliedAssets[i].asset.cTokenAddr != supplyAsset.asset.cTokenAddr) continue;

            updateSupplyAssetAmount(accountProfile.suppliedAssets[i], accountProfile.suppliedAssets[i].asset.amount.add(supplyAsset.asset.amount));
            refreshAccountProfile(accountProfile);

            return;
        }

        //if not matching existing supplyAsset found
        uint length = accountProfile.suppliedAssets.length.add(1);
        SupplyAsset[] memory newSupplyAsset = new SupplyAsset[](length);

        for(uint i = 0; i < accountProfile.suppliedAssets.length; i++){
            newSupplyAsset[i] = accountProfile.suppliedAssets[i];
        }

        newSupplyAsset[length-1] = supplyAsset;
        accountProfile.suppliedAssets = newSupplyAsset;

        refreshAccountProfile(accountProfile);
    }

    function addBorrowAsset(AccountProfile memory accountProfile, BorrowAsset memory borrowAsset) internal view{
        for(uint i = 0; i < accountProfile.borrowedAssets.length; i++){
            if(accountProfile.borrowedAssets[i].asset.cTokenAddr != borrowAsset.asset.cTokenAddr) continue;

            updateBorrowAssetAmount(accountProfile.borrowedAssets[i], accountProfile.borrowedAssets[i].asset.amount.add(borrowAsset.asset.amount));
            refreshAccountProfile(accountProfile);

            return;
        }

        uint length = accountProfile.borrowedAssets.length.add(1);
        BorrowAsset[] memory newBorrowAssets = new BorrowAsset[](length);

        for(uint i = 0; i < accountProfile.borrowedAssets.length; i++){
            newBorrowAssets[i] = accountProfile.borrowedAssets[i];
        }

        newBorrowAssets[length-1] = borrowAsset;

        accountProfile.borrowedAssets = newBorrowAssets;
        refreshAccountProfile(accountProfile);

    }

    function findSuppliedAsset(address cTokenAddr, SupplyAsset[] memory supplyAssets) internal pure returns(bool hasFound, SupplyAsset memory supplyAsset){
        for(uint i = 0; i < supplyAssets.length; i++){
            if(cTokenAddr == supplyAssets[i].asset.cTokenAddr){
                return (true, supplyAssets[i]);
            }
        }

        return (false, supplyAsset);
    }

    function findBorrowAsset(address cTokenAddr, BorrowAsset[] memory borrowAssets) internal pure returns(bool hasFound, BorrowAsset memory borrowAsset){
        for(uint i = 0; i < borrowAssets.length; i++){
            if(cTokenAddr == borrowAssets[i].asset.cTokenAddr){
                return (true, borrowAssets[i]);
            }
        }

        return (false, borrowAsset);
    }

    function removeEmptySupplyAsset(SupplyAsset[] memory supplyAssets) internal pure returns(SupplyAsset[] memory newSupplyAssets){
        uint length;

        for(uint i = 0; i < supplyAssets.length; i++){
            if(supplyAssets[i].asset.valueInUSD_ == 0) continue;

            length++;
        }

        newSupplyAssets = new SupplyAsset[](length);
        uint index;

        for(uint i = 0; i < supplyAssets.length; i++){
            if(supplyAssets[i].asset.valueInUSD_ == 0) continue;

            newSupplyAssets[index] = supplyAssets[i];
            index++;
        }

        return newSupplyAssets;
    }

    function removeEmptyBorrowAsset(BorrowAsset[] memory borrowAssets) internal pure returns(BorrowAsset[] memory newBorrowAssets){
        uint length;

        for(uint i = 0; i < borrowAssets.length; i++){
            if(borrowAssets[i].asset.valueInUSD_ == 0) continue;

            length++;
        }

        newBorrowAssets = new BorrowAsset[](length);
        uint index;

        for(uint i = 0; i < borrowAssets.length; i++){
            if(borrowAssets[i].asset.valueInUSD_ == 0) continue;

            newBorrowAssets[index] = borrowAssets[i];
            index++;
        }

        return newBorrowAssets;
    }


}

contract CompFarmingSummaryV3 is CompFarmingSummaryV3Model{

    string constant public version = "v3";
    uint constant internal n80PCTMantissa = 800000000000000000;
    uint constant internal n1PCTMantissa = 10000000000000000;

    uint constant internal borrowLimitPCTDelta = 50000000000000000;

    function getCompProfile(address acc) external returns(CompProfile memory compProfile){
        return getCompProfileInternal(acc);
    }

    function getCOMPPriceInUSD() public view returns(uint compPriceInUSD){
        return cmp_getUnderlyingPriceInUSD(cCOMPAddr);
    }
    //bulk testing required
    function getTotalCompReceivable(address acc, uint numberOfBlocks) public view returns(uint totalCompReceivable){
        return getTotalCompReceivableInternal(acc, numberOfBlocks);
    }

    function getTotalCompReceivablByAP(AccountProfile memory accountProfile, uint numberOfBlocks) public view returns(uint compReceivable){
        return getTotalCompReceivableInternal(accountProfile, numberOfBlocks);
    }
    //bulk testing done
    function getAccountProfile(address acc) external view returns(AccountProfile memory accountProfile){
        return getAccountProfileInternal(acc);
    }

    function getAccountInterestProfile(address acc, uint numberOfBlocks) external view returns(AccountInterestProfile memory accountInterestProfile){
        return getAccountInterestProfileInternal(acc, numberOfBlocks);
    }

    function getFarmingAccountProfileByAP(AccountProfile memory accountProfile, uint targetedBorrowLimitPCTMantissa) public view returns(bool isValidated, AccountProfile memory farmingAccountProfile){
        return getFarmingAccountProfileInternal(accountProfile, targetedBorrowLimitPCTMantissa);
    }

    function getAccountInterestProfileByAP(AccountProfile memory accountProfile, uint numberOfBlocks) public view returns(AccountInterestProfile memory accountInterestProfile){
        return getAccountInterestProfileInternal(accountProfile, numberOfBlocks);
    }
    //bulk testing done
    function getLiquidationRiskRanking(address acc) external view returns(LiquidationRiskRanking liquidationRiskRanking){
        return getLiquidationRiskRankingInternal(acc);
    }

    function getLiquidationRiskRankingByAP(AccountProfile memory accountProfile) public view returns(LiquidationRiskRanking liquidationRiskRanking){
        return getLiquidationRiskRankingInternal(accountProfile);
    }

    function getMaxInterestAccountProfileByAP(AccountProfile memory accountProfile) public view returns(bool isValidated, AccountProfile memory maxInterestAccountProfile){
        return getMaxInterestAccountProfileInternal(accountProfile);
    }

    //internal functions below
    function getTotalCompReceivableInternal(address acc, uint numberOfBlocks) internal view returns(uint compReceivable){
        return getTotalCompReceivableInternal(getAccountProfileInternal(acc), numberOfBlocks);
    }

    function getCompReceivableOfCToken(uint supplyByTheAcc, uint borrowByTheAcc, address cTokenAddr, uint numberOfBlocks) internal view returns(uint compReceivableByCToken){

        uint compDistAmount = cmp_getCompDistAmount(cTokenAddr, numberOfBlocks);
        uint percentageOfStakeOnSupplyMantissa = cmp_calPercentageOfStakeOnSupplyMantissa(cTokenAddr, supplyByTheAcc);
        uint percentageOfStakeOnBorrowMantissa = cmp_calPercentageOfStakeOnBorrowMantissa(cTokenAddr, borrowByTheAcc);
        uint decimals = cmp_getUnderlyingDecimals(cCOMPAddr);

        //formula: compDistAmount * (stakeSupplied + stakeBorrowed)
        compReceivableByCToken = compDistAmount.mul(percentageOfStakeOnSupplyMantissa.add(percentageOfStakeOnBorrowMantissa)).div(10**decimals);

        return compReceivableByCToken;
    }


    function getTotalCompReceivableInternal(AccountProfile memory accountProfile, uint numberOfBlocks) internal view returns(uint compReceivable){
        SupplyAsset[] memory suppliedAssets = accountProfile.suppliedAssets;
        BorrowAsset[] memory borrowedAssets = accountProfile.borrowedAssets;

        for(uint i = 0; i < suppliedAssets.length; i++){
            compReceivable += getCompReceivableOfCToken(suppliedAssets[i].asset.amount, 0, suppliedAssets[i].asset.cTokenAddr, numberOfBlocks);
        }

        for(uint i = 0; i < borrowedAssets.length; i++){
            compReceivable += getCompReceivableOfCToken(0, borrowedAssets[i].asset.amount, borrowedAssets[i].asset.cTokenAddr, numberOfBlocks);
        }

        return compReceivable;
    }

    function getCompProfileInternal(address acc) internal returns(CompProfile memory compProfile){

        compProfile.balance = ERC20(compAddr).balanceOf(acc);

        CompoundLens compoundLens = CompoundLens(compoundLensAddr);
        compProfile.yetToClaimed = compoundLens.getCompBalanceMetadataExt(Comp(compAddr), ComptrollerLensInterface(comptrollerAddr), acc).allocated;

    }

    function getAccountProfileInternal(address acc) internal view returns(AccountProfile memory accountProfile){

        SupplyAsset[] memory suppliedAssets = getSuppliedAssets(acc);
        BorrowAsset[] memory borrowedAssets = getBorrowedAssets(acc);

        return createAccountProfile(suppliedAssets, borrowedAssets);
    }

    function getSuppliedAssets(address acc) internal view returns(SupplyAsset[] memory suppliedAssets){
        address[] memory suppliedCTokenAddrList = Comptroller(comptrollerAddr).getAssetsIn(acc);
        suppliedAssets = new SupplyAsset[](suppliedCTokenAddrList.length);

        for(uint i = 0; i < suppliedCTokenAddrList.length; i++){
            //filter out cSAI
            //if(suppliedCTokenAddrList[i] == 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC) continue;
            suppliedAssets[i] = createSupplyAsset(suppliedCTokenAddrList[i], cmp_getUnderlyingBalanceOfAnAcc(acc, suppliedCTokenAddrList[i]));
        }

        suppliedAssets = removeEmptySupplyAsset(suppliedAssets);

        return suppliedAssets;
    }

    function getBorrowedAssets(address acc) internal view returns(BorrowAsset[] memory borrowedAssets){
        address[] memory borrowedCTokenList = cmp_getBorrowedTokenList(acc);

        borrowedAssets = new BorrowAsset[](borrowedCTokenList.length);

        for(uint i = 0; i < borrowedCTokenList.length; i++){
            borrowedAssets[i] = createBorrowAsset(borrowedCTokenList[i], CToken(borrowedCTokenList[i]).borrowBalanceStored(acc));
        }

        borrowedAssets = removeEmptyBorrowAsset(borrowedAssets);

        return borrowedAssets;
    }


    function getFarmingAccountProfileInternal(AccountProfile memory accountProfile, uint targetedBorrowLimitPCTMantissa) internal view returns(bool isValidated, AccountProfile memory farmingAccountProfile){
        //liquidation risk ranking needs to be lower or equials to 2
        if(uint(getLiquidationRiskRankingInternal(accountProfile)) > 1) return (false, farmingAccountProfile);

        //each supplied asset, run borrowANDsupplym check util borrowLimitsPCTPerAsset hits 80%withDelta
        SupplyAsset[] memory suppliedAssets = accountProfile.suppliedAssets;

        for(uint i = 0; i < suppliedAssets.length; i++){

              if(suppliedAssets[i].collateralFactorMantissa_ == 0) continue;

              uint maxBorrowAmount;
              BorrowAsset memory moreBorrowAsset;
              SupplyAsset memory moreSupplyAsset;

              while(accountProfile.borrowLimitPCTLineItemMantissaList[i] <= targetedBorrowLimitPCTMantissa.sub(n1PCTMantissa)){
                  maxBorrowAmount = suppliedAssets[i].asset.amount.mul(suppliedAssets[i].collateralFactorMantissa_).mul(targetedBorrowLimitPCTMantissa.sub(accountProfile.borrowLimitPCTLineItemMantissaList[i])).div(oneMantissa).div(oneMantissa);
                  moreBorrowAsset = createBorrowAsset(suppliedAssets[i].asset.cTokenAddr, maxBorrowAmount);
                  moreSupplyAsset = createSupplyAsset(suppliedAssets[i].asset.cTokenAddr, maxBorrowAmount);

                  addBorrowAsset(accountProfile, moreBorrowAsset);
                  addSuppliedAsset(accountProfile, moreSupplyAsset);

              }
        }

        return (true, accountProfile);
    }

    function getAccountInterestProfileInternal(address acc, uint numberOfBlocks) internal view returns(AccountInterestProfile memory accountInterestProfile){
        return getAccountInterestProfileInternal(getAccountProfileInternal(acc), numberOfBlocks);
    }

    function getAccountInterestProfileInternal(AccountProfile memory accountProfile, uint numberOfBlocks) internal view returns(AccountInterestProfile memory accountInterestProfile){
        return createAccountInterestProfile(getSupplyInterests(accountProfile.suppliedAssets, numberOfBlocks), getBorrowInterests(accountProfile.borrowedAssets, numberOfBlocks));
    }

    function getSupplyInterests(SupplyAsset[] memory supplyAssets, uint numberOfBlocks) internal view returns(CTokenInterest[] memory supplyInterests){
        supplyInterests = new CTokenInterest[](supplyAssets.length);

        address cTokenAddr;
        uint interestRateMantissa;
        uint balance;
        for(uint i = 0; i < supplyAssets.length; i++){
            cTokenAddr = supplyAssets[i].asset.cTokenAddr;
            interestRateMantissa = CToken(cTokenAddr).supplyRatePerBlock();
            balance = supplyAssets[i].asset.amount;

            supplyInterests[i] = createCTokenInterest(cTokenAddr, interestRateMantissa, balance, numberOfBlocks);
        }

        return supplyInterests;
    }

    function getBorrowInterests(BorrowAsset[] memory borrowedAssets, uint numberOfBlocks) internal view returns(CTokenInterest[] memory borrowInterests){
        borrowInterests = new CTokenInterest[](borrowedAssets.length);

        address cTokenAddr;
        uint interestRateMantissa;
        uint balance;
        for(uint i = 0; i < borrowedAssets.length; i++){
            cTokenAddr = borrowedAssets[i].asset.cTokenAddr;
            interestRateMantissa = CToken(cTokenAddr).borrowRatePerBlock();
            balance = borrowedAssets[i].asset.amount;

            borrowInterests[i] = createCTokenInterest(cTokenAddr, interestRateMantissa, balance, numberOfBlocks);
        }

        return borrowInterests;
    }

    function getLiquidationRiskRankingInternal(AccountProfile memory accountProfile) internal view returns(LiquidationRiskRanking liquidationRiskRanking){
        //find all the supplied asset
        //find all the matching asset
        //find calBorrowLimitPCTLineItemMantissaList
        //check to see if any borrowed asset outside from supplied asset, acceptable asset require valueInUSD over 1
        //check to see if any borrowed asset with underlying supplied of 0 collateral factor

        //get account interest profile


        liquidationRiskRanking = LiquidationRiskRanking.ZERO_RISK;
///
        if(!getAccountInterestProfileInternal(accountProfile, 1).isPositiveInterest_){
            liquidationRiskRanking = LiquidationRiskRanking.INTEREST_RISK_ONLY;
        }

        for(uint i = 0; i < accountProfile.borrowLimitPCTLineItemMantissaList.length; i++){
            if(accountProfile.borrowLimitPCTLineItemMantissaList[i] == MAX_INT_NUMBER) continue;

            if(accountProfile.borrowLimitPCTLineItemMantissaList[i] > oneMantissa) {
                liquidationRiskRanking = LiquidationRiskRanking.PRICE_MOVEMENT_RISK;
                break;
            }

        }

        bool hasFound;
        SupplyAsset memory suppliedAsset;
        for(uint i = 0; i < accountProfile.borrowedAssets.length; i++){
            if(accountProfile.borrowedAssets[i].asset.valueInUSD_ < oneMantissa) continue;  //filter small value asset(asset USD value less than 1 USD)

            (hasFound, suppliedAsset) = findSuppliedAsset(accountProfile.borrowedAssets[i].asset.cTokenAddr, accountProfile.suppliedAssets);

            if(!hasFound){
                liquidationRiskRanking = LiquidationRiskRanking.PRICE_MOVEMENT_RISK;
                break;
            }

            if(suppliedAsset.collateralFactorMantissa_ == 0){
                liquidationRiskRanking = LiquidationRiskRanking.PRICE_MOVEMENT_RISK;
                break;
            }
        }

        return liquidationRiskRanking;
    }

    function getLiquidationRiskRankingInternal(address acc) internal view returns(LiquidationRiskRanking liquidationRiskRanking){
        return getLiquidationRiskRankingInternal(getAccountProfileInternal(acc));
    }

    function getMaxInterestAccountProfileInternal(AccountProfile memory accountProfile) internal view returns(bool isValidated, AccountProfile memory maxInterestAccountProfile){
        if(uint(getLiquidationRiskRankingInternal(accountProfile)) > 1) return (false, maxInterestAccountProfile);

        SupplyAsset[] memory newSupplyAssets = new SupplyAsset[](accountProfile.suppliedAssets.length);

        address cTokenAddr;
        uint amount;
        bool hasFound;
        BorrowAsset memory borrowedAsset;
        for(uint i = 0; i < accountProfile.suppliedAssets.length; i++){
            cTokenAddr = accountProfile.suppliedAssets[i].asset.cTokenAddr;

            (hasFound, borrowedAsset) = findBorrowAsset(cTokenAddr, accountProfile.borrowedAssets);
            if(!hasFound){
                amount = accountProfile.suppliedAssets[i].asset.amount;
            }

            amount = accountProfile.suppliedAssets[i].asset.amount.sub(borrowedAsset.asset.amount);

            newSupplyAssets[i] = createSupplyAsset(cTokenAddr, amount);
        }

        BorrowAsset[] memory borrowedAssets;

        return (true, createAccountProfile(newSupplyAssets, borrowedAssets));
    }



}