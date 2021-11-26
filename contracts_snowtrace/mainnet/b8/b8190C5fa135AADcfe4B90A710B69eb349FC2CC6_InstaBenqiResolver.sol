/**
 *Submitted for verification at snowtrace.io on 2021-11-26
*/

// File contracts/protocols/avalanche/benqi/interfaces.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface QiTokenInterface {
    function exchangeRateStored() external view returns (uint256);

    function borrowRatePerTimestamp() external view returns (uint256);

    function supplyRatePerTimestamp() external view returns (uint256);

    function borrowBalanceStored(address) external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function getCash() external view returns (uint256);
}

interface TokenInterface {
    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function delegates(address) external view returns (address);

    function getCurrentVotes(address) external view returns (uint96);
}

interface OrcaleQi {
    function getUnderlyingPrice(address) external view returns (uint256);
}

interface ComptrollerLensInterface {
    function markets(address)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimReward(uint8, address) external;

    function rewardAccrued(uint8, address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);

    function borrowGuardianPaused(address) external view returns (bool);

    function oracle() external view returns (address);

    function rewardSpeeds(uint8, address) external view returns (uint256);
}


// File contracts/utils/dsmath.sol

pragma solidity >=0.7.0;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}


// File contracts/protocols/avalanche/benqi/helpers.sol

pragma solidity >=0.8.0;


contract Helpers is DSMath {
    /**
     * @dev get Benqi Comptroller
     */
    function getComptroller() public pure returns (ComptrollerLensInterface) {
        return ComptrollerLensInterface(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);
    }

    /**
     * @dev get Benqi Open Feed Oracle Address
     */
    function getOracleAddress() public view returns (address) {
        return getComptroller().oracle();
    }

    /**
     * @dev get QiAVAX Address
     */
    function getQiAVAXAddress() public pure returns (address) {
        return 0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
    }

    /**
     * @dev get Qi Token Address
     */
    function getQiToken() public pure returns (TokenInterface) {
        return TokenInterface(0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5);
    }

    struct BenqiData {
        uint256 tokenPriceInAvax;
        uint256 tokenPriceInUsd;
        uint256 exchangeRateStored;
        uint256 balanceOfUser;
        uint256 borrowBalanceStoredUser;
        uint256 totalBorrows;
        uint256 totalSupplied;
        uint256 borrowCap;
        uint256 supplyRatePerTimestamp;
        uint256 borrowRatePerTimestamp;
        uint256 collateralFactor;
        uint256 rewardSpeedQi;
        uint256 rewardSpeedAvax;
        bool isQied;
        bool isBorrowPaused;
    }

    struct MetadataExt {
        uint256 avaxAccrued;
        uint256 qiAccrued;
        address delegate;
        uint96 votes;
    }
}


// File contracts/protocols/avalanche/benqi/main.sol

pragma solidity >=0.8.0;


contract Resolver is Helpers {
    // reward token type to show BENQI or AVAX
    uint8 public constant rewardQi = 0;
    uint8 public constant rewardAvax = 1;

    function getPriceInAvax(QiTokenInterface qiToken) public view returns (uint256 priceInAVAX, uint256 priceInUSD) {
        uint256 decimals = getQiAVAXAddress() == address(qiToken)
            ? 18
            : TokenInterface(qiToken.underlying()).decimals();
        uint256 price = OrcaleQi(getOracleAddress()).getUnderlyingPrice(address(qiToken));
        uint256 avaxPrice = OrcaleQi(getOracleAddress()).getUnderlyingPrice(getQiAVAXAddress());
        priceInUSD = price / 10**(18 - decimals);
        priceInAVAX = wdiv(priceInUSD, avaxPrice);
    }

    function getBenqiData(address owner, address[] memory qiAddress) public view returns (BenqiData[] memory) {
        BenqiData[] memory tokensData = new BenqiData[](qiAddress.length);
        ComptrollerLensInterface troller = getComptroller();
        for (uint256 i = 0; i < qiAddress.length; i++) {
            QiTokenInterface qiToken = QiTokenInterface(qiAddress[i]);
            (uint256 priceInAVAX, uint256 priceInUSD) = getPriceInAvax(qiToken);
            (, uint256 collateralFactor, bool isQied) = troller.markets(address(qiToken));
            uint256 _totalBorrowed = qiToken.totalBorrows();
            tokensData[i] = BenqiData(
                priceInAVAX,
                priceInUSD,
                qiToken.exchangeRateStored(),
                qiToken.balanceOf(owner),
                qiToken.borrowBalanceStored(owner),
                _totalBorrowed,
                sub(add(_totalBorrowed, qiToken.getCash()), qiToken.totalReserves()),
                troller.borrowCaps(qiAddress[i]),
                qiToken.supplyRatePerTimestamp(),
                qiToken.borrowRatePerTimestamp(),
                collateralFactor,
                troller.rewardSpeeds(rewardQi, qiAddress[i]),
                troller.rewardSpeeds(rewardAvax, qiAddress[i]),
                isQied,
                troller.borrowGuardianPaused(qiAddress[i])
            );
        }

        return tokensData;
    }

    function claimQiReward(address owner) internal returns (uint256) {
        TokenInterface qiToken = getQiToken();
        ComptrollerLensInterface troller = getComptroller();
        uint256 initialBalance = qiToken.balanceOf(owner);
        troller.claimReward(rewardQi, owner);
        uint256 finalBalance = qiToken.balanceOf(owner);
        return finalBalance - initialBalance;
    }

    function getQiRewardAccrued(address owner) internal returns (uint256) {
        uint256 qiAccrued = claimQiReward(owner);
        return qiAccrued;
    }

    function claimAvaxReward(address owner) internal returns (uint256) {
        ComptrollerLensInterface troller = getComptroller();
        uint256 initialBalance = owner.balance;
        troller.claimReward(rewardAvax, owner);
        uint256 finalBalance = owner.balance;
        return finalBalance - initialBalance;
    }

    function getAvaxRewardAccrued(address owner) internal returns (uint256) {
        uint256 avaxAccrued = claimAvaxReward(owner);
        return avaxAccrued;
    }

    function getRewardsData(address owner, TokenInterface qiToken) public returns (MetadataExt memory) {
        return
            MetadataExt(
                getAvaxRewardAccrued(owner),
                getQiRewardAccrued(owner),
                qiToken.delegates(owner),
                qiToken.getCurrentVotes(owner)
            );
    }

    function getPosition(address owner, address[] memory qiAddress)
        public
        returns (BenqiData[] memory, MetadataExt memory)
    {
        return (getBenqiData(owner, qiAddress), getRewardsData(owner, getQiToken()));
    }
}

contract InstaBenqiResolver is Resolver {
    string public constant name = "Benqi-Resolver-v1";
}