// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IPresale.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IPresaleFactory.sol";

contract PresaleReader {
    function getCurrentTime() external view returns (uint256){
        uint256 currentTime = block.timestamp;
        return currentTime;
    }

    function getPresaleTokenInfo(address[] memory _tokens) external view returns (
            uint256[] memory,
            bool[] memory,
            uint[] memory,
            string[] memory) {
            uint256 launchInfoLength = 15;
            uint256 opsLength = 4;
            uint256 extraInfoLength = 9;
            uint256 socialInfoLength = 12;
            uint addressLength = 2;

            uint256[] memory launchInfos = new uint256[](_tokens.length * launchInfoLength);
            bool[] memory opsInfos = new bool[](_tokens.length * opsLength);
            uint[] memory extraInfos = new uint[](_tokens.length * extraInfoLength);
            string[] memory socialInfos = new string[](_tokens.length * socialInfoLength);
            for (uint256 i = 0; i < _tokens.length; i++) {
                IPresale presale = IPresale(_tokens[i]);
                launchInfos[i * launchInfoLength] = presale._presaleRate();
                launchInfos[i * launchInfoLength + 1] = presale._listingRate();
                launchInfos[i * launchInfoLength + 2] = presale._softCap();
                launchInfos[i * launchInfoLength + 3] = presale._hardCap();
                launchInfos[i * launchInfoLength + 4] = presale._minPurchase();
                launchInfos[i * launchInfoLength + 5] = presale._maxPurchase();
                launchInfos[i * launchInfoLength + 6] = presale._presaleStartTime();
                launchInfos[i * launchInfoLength + 7] = presale._presaleEndTime();
                launchInfos[i * launchInfoLength + 8] = presale._liquidityPercent();
                launchInfos[i * launchInfoLength + 9] = presale._liquidityLockup();
                launchInfos[i * launchInfoLength + 10] = presale._totalToken();
                launchInfos[i * launchInfoLength + 11] = presale._tokenDecimals();
                launchInfos[i * launchInfoLength + 12] = presale._totalSupply();
                launchInfos[i * launchInfoLength + 13] = presale._weiRaised();
                launchInfos[i * launchInfoLength + 14] = presale._finalizeTime();
                opsInfos[i * opsLength] = presale._usingWhitelist();
                opsInfos[i * opsLength + 1] = presale._refundType();
                opsInfos[i * opsLength + 2] = presale._usingVestingContributor();
                opsInfos[i * opsLength + 3] = presale._usingTeamVesting();
                extraInfos[i * extraInfoLength] = presale._firstReleasePercent();
                extraInfos[i * extraInfoLength + 1] = presale._vestingPeriodEachCycle();
                extraInfos[i * extraInfoLength + 2] = presale._tokenReleasePercentEachCycle();
                extraInfos[i * extraInfoLength + 3] = presale._totalTeamVestingTokens();
                extraInfos[i * extraInfoLength + 4] = presale._teamFirstReleaseDays();
                extraInfos[i * extraInfoLength + 5] = presale._teamFirstReleasePercent();
                extraInfos[i * extraInfoLength + 6] = presale._teamVestingPeriodEachCycle();
                extraInfos[i * extraInfoLength + 7] = presale._teamTokenReleasePercentEachCycle();
                extraInfos[i * extraInfoLength + 8] = presale.state();
                socialInfos[i * socialInfoLength] = presale._logoImg();
                socialInfos[i * socialInfoLength + 1] = presale._website();
                socialInfos[i * socialInfoLength + 2] = presale._facebook();
                socialInfos[i * socialInfoLength + 3] = presale._twitter();
                socialInfos[i * socialInfoLength + 4] = presale._github();
                socialInfos[i * socialInfoLength + 5] = presale._telegram();
                socialInfos[i * socialInfoLength + 6] = presale._instagram();
                socialInfos[i * socialInfoLength + 7] = presale._discord();
                socialInfos[i * socialInfoLength + 8] = presale._reddit();
                socialInfos[i * socialInfoLength + 9] = presale._description();
                socialInfos[i * socialInfoLength + 10] = presale._name();
                socialInfos[i * socialInfoLength + 11] = presale._symbol();
            }
            return (launchInfos, opsInfos, extraInfos, socialInfos);
        }


    function getLockTokenInfo(address _owner, address _token) external view returns (string[] memory, uint256) {
        IUniswapV2Pair myToken = IUniswapV2Pair(_token);
        string[] memory tokenData = new string[](3);
        uint256 balanceOf;
        if (keccak256(abi.encodePacked(myToken.name())) == keccak256("Pancake LPs"))
        {
            tokenData[0] = "Dex";
            IUniswapV2Pair tokenA = IUniswapV2Pair(myToken.token0());
            IUniswapV2Pair tokenB = IUniswapV2Pair(myToken.token1());
            tokenData[1] = tokenA.name();
            tokenData[2] = tokenB.name();
            balanceOf = myToken.balanceOf(_owner);
        }
        else {
            tokenData[0] = "General";
            tokenData[1] = myToken.name();
            tokenData[2] = myToken.symbol();
            balanceOf = myToken.balanceOf(_owner);
        }
        return (tokenData, balanceOf);
    }

    function getLockGeneralTokensInfo(address[] memory _tokens, address _factory) external view returns (string[] memory) {
        uint256 tokenDataLength = 4;
        string[] memory tokenData = new string[](_tokens.length * tokenDataLength);
        IPresaleFactory presaleFactory = IPresaleFactory(_factory);
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (presaleFactory.checkHasToken(_tokens[i]))
            {
                IPresale presale = IPresale(presaleFactory.getPresaleCoins(_tokens[i]));
                IUniswapV2Pair myToken = IUniswapV2Pair(_tokens[i]);
                if (keccak256(abi.encodePacked(myToken.name())) == keccak256("Pancake LPs"))
                {
                    tokenData[i * tokenDataLength] = "Dex";
                    IUniswapV2Pair tokenA = IUniswapV2Pair(myToken.token0());
                    IUniswapV2Pair tokenB = IUniswapV2Pair(myToken.token1());
                    tokenData[i * tokenDataLength + 1] = tokenA.name();
                    tokenData[i * tokenDataLength + 2] = tokenB.name();
                    tokenData[i * tokenDataLength + 3] = presale._logoImg();
                }
                else
                {
                    tokenData[i * tokenDataLength] = "General";
                    tokenData[i * tokenDataLength + 1] = myToken.name();
                    tokenData[i * tokenDataLength + 2] = myToken.symbol();
                    tokenData[i * tokenDataLength + 3] = presale._logoImg();
                }
            }
            else
            {
                IUniswapV2Pair myToken = IUniswapV2Pair(_tokens[i]);
                if (keccak256(abi.encodePacked(myToken.name())) == keccak256("Pancake LPs"))
                {
                    tokenData[i * tokenDataLength] = "Dex";
                    IUniswapV2Pair tokenA = IUniswapV2Pair(myToken.token0());
                    IUniswapV2Pair tokenB = IUniswapV2Pair(myToken.token1());
                    tokenData[i * tokenDataLength + 1] = tokenA.name();
                    tokenData[i * tokenDataLength + 2] = tokenB.name();
                    tokenData[i * tokenDataLength + 3] = "None";
                }
                else
                {
                    tokenData[i * tokenDataLength] = "General";
                    tokenData[i * tokenDataLength + 1] = myToken.name();
                    tokenData[i * tokenDataLength + 2] = myToken.symbol();
                    tokenData[i * tokenDataLength + 3] = "None";
                }
            }
        }
        return tokenData;
    }

    function getStatusInfo(address[] memory _tokens, address _factory) external view returns (bool[] memory) {
        uint statusLength = 2;
        bool[] memory statusInfos = new bool[](_tokens.length * statusLength);
        IPresaleFactory presaleFactory = IPresaleFactory(_factory);
        for (uint256 i = 0; i < _tokens.length; i++) {
            IPresale presale = IPresale(_tokens[i]);
            statusInfos[i * statusLength] = presaleFactory.fetchKycStatus(presale._wallet());
            statusInfos[i * statusLength + 1] = presale._audit();
        }
        return statusInfos;
    }

    function getTokenAddressInfo(address[] memory _tokens) external view returns (
        address[] memory, address[] memory) {
        address[] memory tokenAddresses = new address[](2 * _tokens.length);
        address[] memory routers = new address[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            IPresale presale = IPresale(_tokens[i]);
            tokenAddresses[2 * i] = presale._tokenAddress();
            tokenAddresses[2 * i + 1] = presale._wallet();
            routers[i] = presale._router();
        }
        return (tokenAddresses, routers);
    }

    function getItemTokenInfo(address _token) external view returns (
        uint256[] memory,
        bool[] memory,
        uint[] memory,
        string[] memory) {
        uint256 launchInfoLength = 15;
        uint256 opsLength = 6;
        uint256 extraInfoLength = 9;
        uint256 socialInfoLength = 12;
        uint addressLength = 2;

        uint256[] memory launchInfos = new uint256[](launchInfoLength);
        bool[] memory opsInfos = new bool[](opsLength);
        uint[] memory extraInfos = new uint[](extraInfoLength);
        string[] memory socialInfos = new string[](socialInfoLength);
        IPresale presale = IPresale(_token);
//        IPresaleFactory presaleFactory = IPresaleFactory(_factory);
        launchInfos[0] = presale._presaleRate();
        launchInfos[1] = presale._listingRate();
        launchInfos[2] = presale._softCap();
        launchInfos[3] = presale._hardCap();
        launchInfos[4] = presale._minPurchase();
        launchInfos[5] = presale._maxPurchase();
        launchInfos[6] = presale._presaleStartTime();
        launchInfos[7] = presale._presaleEndTime();
        launchInfos[8] = presale._liquidityPercent();
        launchInfos[9] = presale._liquidityLockup();
        launchInfos[10] = presale._totalToken();
        launchInfos[11] = presale._tokenDecimals();
        launchInfos[12] = presale._totalSupply();
        launchInfos[13] = presale._weiRaised();
        launchInfos[14] = presale._finalizeTime();
        opsInfos[0] = presale._usingWhitelist();
        opsInfos[1] = presale._refundType();
        opsInfos[2] = presale._usingVestingContributor();
        opsInfos[3] = presale._usingTeamVesting();
//        opsInfos[4] = presaleFactory.fetchKycStatus(presale._wallet());
//        opsInfos[5] = presale._audit();
        extraInfos[0] = presale._firstReleasePercent();
        extraInfos[1] = presale._vestingPeriodEachCycle();
        extraInfos[2] = presale._tokenReleasePercentEachCycle();
        extraInfos[3] = presale._totalTeamVestingTokens();
        extraInfos[4] = presale._teamFirstReleaseDays();
        extraInfos[5] = presale._teamFirstReleasePercent();
        extraInfos[6] = presale._teamVestingPeriodEachCycle();
        extraInfos[7] = presale._teamTokenReleasePercentEachCycle();
        extraInfos[8] = presale.state();
        socialInfos[0] = presale._logoImg();
        socialInfos[1] = presale._website();
        socialInfos[2] = presale._facebook();
        socialInfos[3] = presale._twitter();
        socialInfos[4] = presale._github();
        socialInfos[5] = presale._telegram();
        socialInfos[6] = presale._instagram();
        socialInfos[7] = presale._discord();
        socialInfos[8] = presale._reddit();
        socialInfos[9] = presale._description();
        socialInfos[10] = presale._name();
        socialInfos[11] = presale._symbol();
        return (launchInfos, opsInfos, extraInfos, socialInfos);
    }

    function getItemAddressInfo(address _token) external view returns (
        address, address) {
        address tokenAddress;
        address wallet;
        address router;
        IPresale presale = IPresale(_token);
        tokenAddress = presale._tokenAddress();
        wallet = presale._wallet();
        router = presale._router();
        return (tokenAddress, router);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() external view returns (uint8);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import "./IERC20.sol";

interface IPresale {
    enum RouterType {
        pancakeswap,
        pancakeswap_test
    }

    enum RefundType {
        Burn,
        Refund
    }

    enum PresaleState { Active, Refunding, Closed, Canceled, Filled }

    function initLaunchInfo(
        uint256[] memory,
        bool[] memory,
        uint[] memory,
        address
    ) external;
    function initSocialInfo(
        string[] memory
    ) external;

    // Social Link Data
    function _tokenDecimals() external view returns (uint);
    function _totalSupply() external view returns (uint256);
    function _symbol() external view returns (string memory);
    function _finalizeTime() external view returns(uint256);
    function _wallet() external view returns (address payable);
    function _name() external view returns (string memory);
    function _tokenAddress() external view returns (address);
    function _logoImg() external view returns (string memory);
    function _website() external view returns (string memory);
    function _facebook() external view returns (string memory);
    function _twitter() external view returns (string memory);
    function _github() external view returns (string memory);
    function _telegram() external view returns (string memory);
    function _instagram() external view returns (string memory);
    function _discord() external view returns (string memory);
    function _reddit() external view returns (string memory);
    function _description() external view returns (string memory);

    // Defi Launchpad Info
    function _presaleRate() external view returns (uint256);
    function _softCap() external view returns (uint256);
    function _hardCap() external view returns (uint256);
    function _minPurchase() external view returns (uint256);
    function _maxPurchase() external view returns (uint256);
    function _presaleStartTime() external view returns (uint256);
    function _presaleEndTime() external view returns (uint256);
    function _liquidityPercent() external view returns (uint256);
    function _listingRate() external view returns (uint256);
    function _totalToken() external view returns (uint256);
    function _liquidityLockup() external view returns (uint256);
    function _usingWhitelist() external view returns (bool);
    function _refundType() external view returns (bool);
    function _router() external view returns (address);

    // Extra Info
    function _usingVestingContributor() external view returns (bool);
    function _firstReleasePercent() external view returns (uint);
    function _vestingPeriodEachCycle() external view returns (uint);
    function _tokenReleasePercentEachCycle() external view returns (uint);

    function _usingTeamVesting() external view returns (bool);
    function _totalTeamVestingTokens() external view returns (uint);
    function _teamFirstReleaseDays() external view returns (uint);
    function _teamFirstReleasePercent() external view returns (uint);
    function _teamVestingPeriodEachCycle() external view returns (uint);
    function _teamTokenReleasePercentEachCycle() external view returns (uint);

    //////////////////////////////////////////
    function _weiRaised() external view returns (uint256);

    function _refundStartDate() external view returns (uint256);
    function updatePoolDetails(string[] memory) external;
    function getPresaleStatus() external view returns (uint);
    function getSocialData() external view returns (string[] memory);
    function getContribution(address) external view returns (uint256);
    function _audit() external view returns (bool);
    function approveAudit() external;
    function cancelAudit() external;
    function _kyc() external view returns (bool);
    function state() external view returns (uint);
    function approveBeneficiaryKYC() external;
    function cancelBeneficiaryKYC() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPresaleFactory {
    function fetchKycStatus(address) external view returns (bool);
    function getPresaleCoins(address) external view returns (address);
    function checkHasToken(address) external view returns (bool);
}