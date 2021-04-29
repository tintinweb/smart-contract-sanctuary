/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CTokenInterface {
    function exchangeRateStored() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function borrowBalanceStored(address) external view returns (uint);
    function totalBorrows() external view returns (uint);
    
    function underlying() external view returns (address);
    function balanceOf(address) external view returns (uint);
    function getCash() external view returns (uint);
}

interface TokenInterface {
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint);
}


interface OrcaleComp {
    function getUnderlyingPrice(address) external view returns (uint);
}

interface ComptrollerLensInterface {
    function markets(address) external view returns (bool, uint, bool);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
    function borrowCaps(address) external view returns (uint);
    function borrowGuardianPaused(address) external view returns (bool);
    function oracle() external view returns (address);
    function compSpeeds(address) external view returns (uint);
}

interface CompReadInterface {
    struct CompBalanceMetadataExt {
        uint balance;
        uint votes;
        address delegate;
        uint allocated;
    }

    function getCompBalanceMetadataExt(
        TokenInterface comp,
        ComptrollerLensInterface comptroller,
        address account
    ) external returns (CompBalanceMetadataExt memory);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}

contract Helpers is DSMath {
    /**
     * @dev get Compound Comptroller
     */
    function getComptroller() public pure returns (ComptrollerLensInterface) {
        return ComptrollerLensInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    }

    /**
     * @dev get Compound Open Feed Oracle Address
     */
    function getOracleAddress() public view returns (address) {
        return getComptroller().oracle();
    }

    /**
     * @dev get Comp Read Address
     */
    function getCompReadAddress() public pure returns (address) {
        return 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074;
    }

    /**
     * @dev get ETH Address
     */
    function getCETHAddress() public pure returns (address) {
        return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    }

    /**
     * @dev get Comp Token Address
     */
    function getCompToken() public pure returns (TokenInterface) {
        return TokenInterface(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    }


    struct CompData {
        uint tokenPriceInEth;
        uint tokenPriceInUsd;
        uint exchangeRateStored;
        uint balanceOfUser;
        uint borrowBalanceStoredUser;
        uint totalBorrows;
        uint totalSupplied;
        uint borrowCap;
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint collateralFactor;
        uint compSpeed;
        bool isComped;
        bool isBorrowPaused;
    }
}


contract Resolver is Helpers {

    function getPriceInEth(CTokenInterface cToken) public view returns (uint priceInETH, uint priceInUSD) {
        uint decimals = getCETHAddress() == address(cToken) ? 18 : TokenInterface(cToken.underlying()).decimals();
        uint price = OrcaleComp(getOracleAddress()).getUnderlyingPrice(address(cToken));
        uint ethPrice = OrcaleComp(getOracleAddress()).getUnderlyingPrice(getCETHAddress());
        priceInUSD = price / 10 ** (18 - decimals);
        priceInETH = wdiv(priceInUSD, ethPrice);
    }

    function getCompoundData(address owner, address[] memory cAddress) public view returns (CompData[] memory) {
        CompData[] memory tokensData = new CompData[](cAddress.length);
        ComptrollerLensInterface troller = getComptroller();
        for (uint i = 0; i < cAddress.length; i++) {
            CTokenInterface cToken = CTokenInterface(cAddress[i]);
            (uint priceInETH, uint priceInUSD) = getPriceInEth(cToken);
            (,uint collateralFactor, bool isComped) = troller.markets(address(cToken));
            uint _totalBorrowed = cToken.totalBorrows();
            tokensData[i] = CompData(
                priceInETH,
                priceInUSD,
                cToken.exchangeRateStored(),
                cToken.balanceOf(owner),
                cToken.borrowBalanceStored(owner),
                _totalBorrowed,
                add(_totalBorrowed, cToken.getCash()),
                troller.borrowCaps(cAddress[i]),
                cToken.supplyRatePerBlock(),
                cToken.borrowRatePerBlock(),
                collateralFactor,
                troller.compSpeeds(cAddress[i]),
                isComped,
                troller.borrowGuardianPaused(cAddress[i])
            );
        }

        return tokensData;
    }

    function getPosition(
        address owner,
        address[] memory cAddress
    )
        public
        returns (CompData[] memory, CompReadInterface.CompBalanceMetadataExt memory)
    {
        return (
            getCompoundData(owner, cAddress),
            CompReadInterface(getCompReadAddress()).getCompBalanceMetadataExt(
                getCompToken(),
                getComptroller(),
                owner
            )
        );
    }

}


contract InstaCompoundResolver is Resolver {
    string public constant name = "Compound-Resolver-v1.4";
}