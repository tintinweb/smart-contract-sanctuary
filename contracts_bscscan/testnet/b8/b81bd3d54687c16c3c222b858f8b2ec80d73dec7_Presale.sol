// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.7;

import "./IERC20.sol";
import "./IUniswapRouter.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./ReentrancyGuard.sol";

contract Presale is ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) public tokenUnclaimed;
    mapping(address => uint256) public lasttokenclaimed;

    IERC20 public immutable TOKEN;
    IERC20 public immutable USD;
    IUniswapRouter public immutable ROUTER;

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public immutable Dev_ADDRESS = tx.origin;

    address public immutable Dividends;

    bool public isPresaleActive = false;
    bool public isClaimActive = false;
    bool public isTokenLaunched = false;

    uint256 public immutable startingPresaleTimestamp;
    uint256 public immutable endingPresaleTimestamp;
    uint256 public immutable startingClaimTimestamp;

    uint256 public totaltokenSold = 0;
    uint256 public totalUSDcollected = 0;

    uint256 public immutable USDPerTokenPresale;
    uint256 public immutable USDPerTokenLaunch;

    uint256 public immutable TOKEN_HARDCAP;

    uint256 public immutable timePerPercent;

    uint256 public immutable USDLpPercent;
    uint256 public immutable USDMarketingPercent;
    uint256 public immutable USDDevPercent;

    uint256 public immutable TOKENDevPercent;
    uint256 public immutable TOKENContributorPercent;

    address public immutable InformationalFeeContract;

    uint256 internal USD_to_LP;
    uint256 internal USD_to_Marketing;
    uint256 internal USD_to_Dev;
    uint256 internal USD_to_Fee;
    uint256 internal USD_to_Dividends;

    uint256 internal Token_to_Claim;
    uint256 internal Token_to_LP;
    uint256 internal Token_to_Dev;
    uint256 internal Token_to_Contributor;
    uint256 internal Token_to_MasterChef;

    uint256 internal Token_to_Burn;
    uint256 internal USD_improperly_sent;

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor(
        // address [_TOKEN, _USD, _ROUTER, _Dividends]
        address[4] memory _ADDRESS,
        // uint256 [_USDPerTokenPresale, _USDPerTokenLaunch]
        uint256[2] memory _USDPerTokenValues,
        uint256 _USD_HARDCAP,
        uint256 _timePerPercent,
        //uint256 [_startingPresaleTimestamp, _endingPresaleTimestamp, _startingClaimTimestamp]
        uint256[3] memory _Timestamps,
        //uint256 [_USDLpPercent, ,_USDMarketingPercent, _USDDevPercent]
        uint256[3] memory _USDDistribution,
        //uint256 [_TOKENDevPercent, TOKENContributorPercent]
        uint256[2] memory _TOKENDistribution,
        address _InformationalFeeContract
    ) nonReentrant {
        TOKEN = IERC20(_ADDRESS[0]);
        USD = IERC20(_ADDRESS[1]);

        ROUTER = IUniswapRouter(_ADDRESS[2]);

        Dividends = _ADDRESS[3];

        USDPerTokenPresale = _USDPerTokenValues[0];
        USDPerTokenLaunch = _USDPerTokenValues[1];

        TOKEN_HARDCAP = _USD_HARDCAP
            .mul(100)
            .mul(10**IERC20(_ADDRESS[0]).decimals())
            .div(_USDPerTokenValues[0]);
        timePerPercent = _timePerPercent;

        startingPresaleTimestamp = _Timestamps[0];
        endingPresaleTimestamp = _Timestamps[1];
        startingClaimTimestamp = _Timestamps[2];

        USDLpPercent = _USDDistribution[0];
        USDMarketingPercent = _USDDistribution[1];
        USDDevPercent = _USDDistribution[2];

        TOKENDevPercent = _TOKENDistribution[0];
        TOKENContributorPercent = _TOKENDistribution[1];

        InformationalFeeContract = _InformationalFeeContract;

        require(
            block.timestamp < _Timestamps[0] &&
                _Timestamps[0] < _Timestamps[1] &&
                _Timestamps[1] < _Timestamps[2],
            "Token release dates do not match"
        );
        require(
            _USDDistribution[0].add(_USDDistribution[1]).add(
                _USDDistribution[2]
            ) <= 1000,
            "USD distribution is incorrect"
        );
        require(
            _TOKENDistribution[0].add(_TOKENDistribution[1]) < 1000,
            "TOKEN distribution is incorrect"
        );
    }

    function buy(uint256 _amount, address _buyer) external nonReentrant {
        require(
            block.timestamp >= startingPresaleTimestamp,
            "Presale has not started"
        );
        if (block.timestamp < endingPresaleTimestamp) {
            if (!isPresaleActive) {
                isPresaleActive = true;
            }
        } else {
            if (isPresaleActive) {
                isPresaleActive = false;
            } else {
                revert("Presale is over");
            }
        }

        address buyer = _buyer;
        uint256 tokens = _amount
            .mul(100)
            .mul(10**TOKEN.decimals())
            .div(USDPerTokenPresale)
            .div(10**USD.decimals());

        require(
            totaltokenSold + tokens <= TOKEN_HARDCAP,
            "Token presale hardcap reached"
        );

        TransferHelper.safeTransferFrom(
            address(USD),
            buyer,
            address(this),
            _amount
        );

        tokenUnclaimed[buyer] = tokenUnclaimed[buyer].add(tokens);
        totaltokenSold = totaltokenSold.add(tokens);
        totalUSDcollected = totalUSDcollected.add(_amount);
        emit TokenBuy(buyer, tokens);

        if (!isPresaleActive && !isTokenLaunched) {
            isTokenLaunched = true;
            _launch();
        }

        if (block.timestamp >= startingClaimTimestamp && !isClaimActive) {
            isClaimActive = true;
        }
    }

    function claim() external nonReentrant {
        require(
            block.timestamp >= startingClaimTimestamp,
            "Claim is not allowed yet"
        );

        if (isPresaleActive && !isTokenLaunched) {
            isPresaleActive = false;
            isTokenLaunched = true;
            _launch();
        }
        if (!isClaimActive) {
            isClaimActive = true;
        }

        require(
            TOKEN.balanceOf(address(this)) >= tokenUnclaimed[msg.sender],
            "There are not enough tokens to transfer"
        );

        if (lasttokenclaimed[msg.sender] == 0) {
            lasttokenclaimed[msg.sender] = startingClaimTimestamp;
        }

        uint256 allowedPercentToClaim = block
            .timestamp
            .sub(lasttokenclaimed[msg.sender])
            .div(timePerPercent);

        lasttokenclaimed[msg.sender] = block.timestamp;

        if (allowedPercentToClaim > 100) {
            allowedPercentToClaim = 100;
        }

        uint256 tokenToClaim = tokenUnclaimed[msg.sender]
            .mul(allowedPercentToClaim)
            .div(100);
        tokenUnclaimed[msg.sender] = tokenUnclaimed[msg.sender].sub(
            tokenToClaim
        );

        TransferHelper.safeTransfer(address(TOKEN), msg.sender, tokenToClaim);
        emit TokenClaim(msg.sender, tokenToClaim);
    }

    function emergencyWithdraw() external nonReentrant {
        require(
            block.timestamp >= startingClaimTimestamp.add(2 days),
            "emergencyWithdraw is not allowed yet"
        );
        require(
            !isTokenLaunched,
            "The Token has been successfully released, emergency withdraw is no longer allowed"
        );

        uint256 _amount = tokenUnclaimed[msg.sender]
            .mul(USDPerTokenPresale)
            .mul(10**USD.decimals())
            .div(100)
            .div(10**TOKEN.decimals());

        TransferHelper.safeTransfer(address(USD), msg.sender, _amount);

        totaltokenSold = totaltokenSold.sub(tokenUnclaimed[msg.sender]);
        totalUSDcollected = totalUSDcollected.sub(_amount);
        tokenUnclaimed[msg.sender] = 0;
    }

    function launch() external nonReentrant {
        require(
            block.timestamp >= endingPresaleTimestamp,
            "Launch is not allowed yet"
        );
        require(
            !isTokenLaunched,
            "The Token has been successfully released, Launch has already been done"
        );

        if (isPresaleActive) {
            isPresaleActive = false;
        }

        if (block.timestamp >= startingClaimTimestamp && !isClaimActive) {
            isClaimActive = true;
        }

        isTokenLaunched = true;
        _launch();
    }

    function _launch() internal {
        USD_to_LP = totalUSDcollected.mul(USDLpPercent).div(1000);
        USD_to_Marketing = totalUSDcollected.mul(USDMarketingPercent).div(1000);
        USD_to_Dev = totalUSDcollected.mul(USDDevPercent.sub(5)).div(1000);
        USD_to_Fee = totalUSDcollected.mul(5).div(1000);
        USD_to_Dividends = totalUSDcollected
            .sub(USD_to_LP)
            .sub(USD_to_Marketing)
            .sub(USD_to_Dev)
            .sub(USD_to_Fee);

        Token_to_Claim = totalUSDcollected
            .mul(100)
            .mul(10**TOKEN.decimals())
            .div(USDPerTokenPresale)
            .div(10**USD.decimals());
        Token_to_LP = USD_to_LP
            .mul(100)
            .mul(10**TOKEN.decimals())
            .div(USDPerTokenLaunch)
            .div(10**USD.decimals());
        Token_to_Dev = Token_to_Claim.add(Token_to_LP).mul(TOKENDevPercent).div(
                uint256(1000).sub(TOKENDevPercent).sub(TOKENContributorPercent)
            );
        Token_to_Contributor = Token_to_Claim
            .add(Token_to_LP)
            .add(Token_to_Dev)
            .mul(TOKENContributorPercent)
            .div(uint256(1000).sub(TOKENContributorPercent));

        USD_improperly_sent = USD
            .balanceOf(address(this))
            .sub(USD_to_LP)
            .sub(USD_to_Marketing)
            .sub(USD_to_Dev)
            .sub(USD_to_Fee)
            .sub(USD_to_Dividends);
        Token_to_Burn = TOKEN
            .balanceOf(address(this))
            .sub(Token_to_Claim)
            .sub(Token_to_LP)
            .sub(Token_to_Dev)
            .sub(Token_to_Contributor);

        if (USD_improperly_sent > 0) {
            TransferHelper.safeTransfer(
                address(USD),
                InformationalFeeContract,
                USD_improperly_sent
            );
        }
        if (Token_to_Burn > 0) {
            TransferHelper.safeTransfer(
                address(TOKEN),
                BURN_ADDRESS,
                Token_to_Burn
            );
        }

        TransferHelper.safeTransfer(address(TOKEN), Dev_ADDRESS, Token_to_Dev);
        TransferHelper.safeTransfer(
            address(TOKEN),
            tx.origin,
            Token_to_Contributor
        );

        TransferHelper.safeTransfer(
            address(USD),
            Dev_ADDRESS,
            USD_to_Marketing.add(USD_to_Dev)
        );
        TransferHelper.safeTransfer(
            address(USD),
            InformationalFeeContract,
            USD_to_Fee
        );
        TransferHelper.safeTransfer(address(USD), Dividends, USD_to_Dividends);

        TransferHelper.safeApprove(address(USD), address(ROUTER), USD_to_LP);
        TransferHelper.safeApprove(
            address(TOKEN),
            address(ROUTER),
            Token_to_LP
        );

        ROUTER.addLiquidity(
            address(USD),
            address(TOKEN),
            USD_to_LP,
            Token_to_LP,
            0,
            0,
            BURN_ADDRESS,
            block.timestamp + 20
        );
    }
}