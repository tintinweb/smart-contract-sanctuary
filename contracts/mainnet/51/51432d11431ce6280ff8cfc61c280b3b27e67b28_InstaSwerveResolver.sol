pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ISwerve {
    function get_virtual_price() external view returns (uint256 out);
    function underlying_coins(int128 tokenId) external view returns (address token);
    function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns (uint256 amount);
    function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external view returns (uint256 buyTokenAmt);
}

interface ISwerveZap {
  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256 amount);
}

interface TokenInterface {
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint);
}

interface IStakingRewards {
  function balanceOf(address) external view returns (uint256);
  function earned(address) external view returns (uint256);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}

contract SwerveHelpers is DSMath {
    /**
     * @dev Return Swerve Swap Address
    */
    function getSwerveSwapAddr() internal pure returns (address) {
        return 0x329239599afB305DA0A2eC69c58F8a6697F9F88d;
    }

    /**
     * @dev Return Swerve Token Address
    */
    function getSwerveTokenAddr() internal pure returns (address) {
        return 0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059;
    }

    /**
     * @dev Return Swerve Zap Address
    */
    function getSwerveZapAddr() internal pure returns (address) {
        return 0xa746c67eB7915Fa832a4C2076D403D4B68085431;
    }

    function getTokenI(address token) internal pure returns (int128 i) {
        if (token == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {
        // DAI Token
        i = 0;
        } else if (token == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {
        // USDC Token
        i = 1;
        } else if (token == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)) {
        // USDT Token
        i = 2;
        } else if (token == address(0x0000000000085d4780B73119b644AE5ecd22b376)) {
        // TUSD Token
        i = 3;
        } else {
        revert("token-not-found.");
        }
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function getBuyUnitAmt(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint buyAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _sellAmt = convertTo18(TokenInterface(sellAddr).decimals(), sellAmt);
        uint _buyAmt = convertTo18(TokenInterface(buyAddr).decimals(), buyAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getDepositUnitAmt(
        address token,
        uint depositAmt,
        uint swerveAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _depositAmt = convertTo18(TokenInterface(token).decimals(), depositAmt);
        uint _swerveAmt = convertTo18(TokenInterface(getSwerveTokenAddr()).decimals(), swerveAmt);
        unitAmt = wdiv(_swerveAmt, _depositAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getWithdrawtUnitAmt(
        address token,
        uint withdrawAmt,
        uint swerveAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _withdrawAmt = convertTo18(TokenInterface(token).decimals(), withdrawAmt);
        uint _swerveAmt = convertTo18(TokenInterface(getSwerveTokenAddr()).decimals(), swerveAmt);
        unitAmt = wdiv(_swerveAmt, _withdrawAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }
}


contract Resolver is SwerveHelpers {

    function getBuyAmount(address buyAddr, address sellAddr, uint sellAmt, uint slippage)
        public
        view
        returns (uint buyAmt, uint unitAmt, uint virtualPrice)
    {
        ISwerve swerve = ISwerve(getSwerveSwapAddr());
        buyAmt = swerve.get_dy(getTokenI(sellAddr), getTokenI(buyAddr), sellAmt);
        virtualPrice = swerve.get_virtual_price();
        unitAmt = getBuyUnitAmt(buyAddr, sellAddr, sellAmt, buyAmt, slippage);
    }

    function getDepositAmount(address token, uint depositAmt, uint slippage)
        public
        view
        returns (uint swerveAmt, uint unitAmt, uint virtualPrice)
    {
        uint[4] memory amts;
        amts[uint(getTokenI(token))] = depositAmt;
        ISwerve swerve = ISwerve(getSwerveSwapAddr());
        swerveAmt = swerve.calc_token_amount(amts, true);
        virtualPrice = swerve.get_virtual_price();
        unitAmt = getDepositUnitAmt(token, depositAmt, swerveAmt, slippage);
    }

    function getWithdrawSwerveAmount(address token, uint withdrawAmt, uint slippage)
        public
        view
        returns (uint swerveAmt, uint unitAmt, uint virtualPrice)
    {
        uint[4] memory amts;
        amts[uint(getTokenI(token))] = withdrawAmt;
        ISwerve swerve = ISwerve(getSwerveSwapAddr());
        swerveAmt = swerve.calc_token_amount(amts, false);
        virtualPrice = swerve.get_virtual_price();
        unitAmt = getWithdrawtUnitAmt(token, withdrawAmt, swerveAmt, slippage);
    }

    function getWithdrawTokenAmount(address token, uint swerveAmt, uint slippage)
        public
        view
        returns (uint tokenAmt, uint unitAmt, uint virtualPrice)
    {
        tokenAmt = ISwerveZap(getSwerveZapAddr()).calc_withdraw_one_coin(swerveAmt, getTokenI(token));
        virtualPrice = ISwerve(getSwerveSwapAddr()).get_virtual_price();
        unitAmt = getWithdrawtUnitAmt(token, tokenAmt, swerveAmt, slippage);
    }

    function getPosition(
        address user
    ) public view returns (
        uint userBal,
        uint totalSupply,
        uint virtualPrice,
        uint userShare,
        uint poolDaiBal,
        uint poolUsdcBal,
        uint poolUsdtBal,
        uint poolSusdBal
    ) {
        TokenInterface swerveToken = TokenInterface(getSwerveTokenAddr());
        userBal = swerveToken.balanceOf(user);
        totalSupply = swerveToken.totalSupply();
        userShare = wdiv(userBal, totalSupply);
        ISwerve swerveContract = ISwerve(getSwerveSwapAddr());
        virtualPrice = swerveContract.get_virtual_price();
        poolDaiBal = TokenInterface(swerveContract.underlying_coins(0)).balanceOf(getSwerveSwapAddr());
        poolUsdcBal = TokenInterface(swerveContract.underlying_coins(1)).balanceOf(getSwerveSwapAddr());
        poolUsdtBal = TokenInterface(swerveContract.underlying_coins(2)).balanceOf(getSwerveSwapAddr());
        poolSusdBal = TokenInterface(swerveContract.underlying_coins(3)).balanceOf(getSwerveSwapAddr());
    }

}


contract InstaSwerveResolver is Resolver {
    string public constant name = "Swerve-swUSD-Resolver-v1.0";
}