// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./TestIDOPresale.sol";
import "./TestIDOInfo.sol";
import "./TestIDOLiquidityLock.sol";
import "./ILiquidityValueCalculator.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract TestIDOFactory {
    using SafeMath for uint256;

    event PresaleCreated(bytes32 title, uint256 testIDOId, address creator);

    IUniswapV2Factory private constant ammFactory =
        IUniswapV2Factory(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f));
    address private constant wethAddress = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

    TestIDOInfo public immutable TESTIDO;
    IERC20 public platformToken; // Platform token
    ILiquidityValueCalculator public lvCalculator;
    // uint256 premiumTime = 1 hours;

    constructor(address _testIDOInfoAddress, address _platformToken) public {
        TESTIDO = TestIDOInfo(_testIDOInfoAddress);
        platformToken = IERC20(_platformToken);
    }

    modifier onlyOwner(){
        require(TESTIDO.owner() == msg.sender, "Not TESTIDO owner");
        _;
    }

    function setLVCalculator(address _lvCalculator) public onlyOwner returns (bool) {
        lvCalculator = ILiquidityValueCalculator(_lvCalculator);
        return true;
    }

    // function setPremiumTime(uint256 _premiumTime) public onlyOwner returns (bool) {
    //     premiumTime = _premiumTime ;
    //     return true;
    // }

    struct PresaleInfo {
        address tokenAddress;
        address unsoldTokensDumpAddress;
        address[] whitelistedAddresses;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 maxInvestInWei;
        uint256 minInvestInWei;
        uint256 openTime;
        uint256 closeTime;
    }

    struct PresaleAMMInfo {
        uint256 listingPriceInWei;
        uint256 liquidityAddingTime;
        uint256 lpTokensLockDurationInDays;
        uint256 liquidityPercentageAllocation;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkDiscord;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
    }

    // copied from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    // calculates the CREATE2 address for a pair without making any external calls
    function uniV2LibPairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    function initializePresale(
        TestIDOPresale _presale,
        uint256 _totalTokens,
        uint256 _finalTokenPriceInWei,
        PresaleInfo calldata _info,
        PresaleAMMInfo calldata _ammInfo,
        PresaleStringInfo calldata _stringInfo
    ) internal {
        _presale.setAddressInfo(msg.sender, _info.tokenAddress, _info.unsoldTokensDumpAddress);
        _presale.setGeneralInfo(
            _totalTokens,
            _finalTokenPriceInWei,
            _info.hardCapInWei,
            _info.softCapInWei,
            _info.maxInvestInWei,
            _info.minInvestInWei,
            _info.openTime,
            _info.closeTime
        );
        _presale.setAMMInfo(
            _ammInfo.listingPriceInWei,
            _ammInfo.liquidityAddingTime,
            _ammInfo.lpTokensLockDurationInDays,
            _ammInfo.liquidityPercentageAllocation
        );
        _presale.setStringInfo(
            _stringInfo.saleTitle,
            _stringInfo.linkTelegram,
            _stringInfo.linkDiscord,
            _stringInfo.linkTwitter,
            _stringInfo.linkWebsite
        );
        _presale.addwhitelistedAddresses(_info.whitelistedAddresses);
    }

    function createPresale(
        PresaleInfo calldata _info,
        PresaleAMMInfo calldata _ammInfo,
        PresaleStringInfo calldata _stringInfo
    ) external {
        IERC20 token = IERC20(_info.tokenAddress);

        TestIDOPresale presale = new TestIDOPresale(address(this), TESTIDO.owner());

        address existingPairAddress = ammFactory.getPair(address(token), wethAddress);
        require(existingPairAddress == address(0)); // token should not be listed in Uniswap

        uint256 maxEthPoolTokenAmount = _info.hardCapInWei.mul(_ammInfo.liquidityPercentageAllocation).div(100);
        uint256 maxLiqPoolTokenAmount = maxEthPoolTokenAmount.mul(1e18).div(_ammInfo.listingPriceInWei);

        uint256 maxTokensToBeSold = _info.hardCapInWei.mul(1e18).div(_info.tokenPriceInWei);
        uint256 requiredTokenAmount = maxLiqPoolTokenAmount.add(maxTokensToBeSold);
        token.transferFrom(msg.sender, address(presale), requiredTokenAmount);

        initializePresale(presale, maxTokensToBeSold, _info.tokenPriceInWei, _info, _ammInfo, _stringInfo);

        address pairAddress = uniV2LibPairFor(address(ammFactory), address(token), wethAddress);
        TestIDOLiquidityLock liquidityLock = new TestIDOLiquidityLock(
                IERC20(pairAddress),
                msg.sender,
                _ammInfo.liquidityAddingTime + (_ammInfo.lpTokensLockDurationInDays * 1 days)
            );

        uint256 testIDOId = TESTIDO.addPresaleAddress(address(presale));
        presale.setTestIDOInfo(address(liquidityLock), TESTIDO.getDevFeePercentage(), TESTIDO.getMinDevFeeInWei(), testIDOId);

        presale.setPlatformTokenAddress(address(platformToken));
        presale.setLiquidityValueCalculator(address(lvCalculator));
        // presale.setPresalePremiumTime(premiumTime);

        emit PresaleCreated(_stringInfo.saleTitle, testIDOId, msg.sender);
    }
}