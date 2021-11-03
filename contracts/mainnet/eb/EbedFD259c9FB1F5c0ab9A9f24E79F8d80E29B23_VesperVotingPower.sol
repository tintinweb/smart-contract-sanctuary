// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./interfaces/ICToken.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IVesperPool.sol";

/**
 * @title Calculate voting power for VSP holders
 */
contract VesperVotingPower {
    address public constant VSP = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421;
    address public constant vVSP = 0xbA4cFE5741b357FA371b506e5db0774aBFeCf8Fc;
    address public constant fVVSP_23 = 0x63475Ab76E578Ec27ae2494d29E1df288817d931; // RariFuse#23
    address public constant fVSP_23 = 0x0879DbeE0614cc3516c464522e9B2e10eB2D415A; // RariFuse#23
    address public constant fVVSP_110 = 0xCbB25B8E3c899C9CAFd9b60C40490aa51282d476; // RariFuse#110
    address public constant uniswapV2 = 0x6D7B6DaD6abeD1DFA5eBa37a6667bA9DCFD49077; // VSP-ETH pair
    address public constant sushiswap = 0x132eEb05d5CB6829Bd34F552cDe0b6b708eF5014; // VSP-ETH pair

    uint256 public constant MINIMUM_VOTING_POWER = 1e18;

    modifier onlyIfAddressIsValid(address wallet) {
        require(wallet != address(0), "holder-address-is-zero");
        _;
    }

    /// @notice Convert vVSP to VSP amount
    function _toVSP(uint256 _vvspAmount) internal view returns (uint256) {
        return (IVesperPool(vVSP).getPricePerShare() * _vvspAmount) / 1e18;
    }

    /// @notice Get VSP amount deposited in the vVSP pool
    function _inVSPPool(address _holder) internal view returns (uint256) {
        return _toVSP(IVesperPool(vVSP).balanceOf(_holder));
    }

    /// @notice Get underlying amount from cToken-Like (e.g. fToken, crToken, etc)
    function _depositedInCTokenLike(address _cTokenLike, address _holder) internal view returns (uint256) {
        ICToken cTokenLike = ICToken(_cTokenLike);
        uint256 _balance = ((cTokenLike.balanceOf(_holder) * cTokenLike.exchangeRateStored()) / 1e18);
        uint256 _borrowed = cTokenLike.borrowBalanceStored(_holder);
        if (_balance > _borrowed) {
            return _balance - _borrowed;
        } else {
            return 0;
        }
    }

    /// @notice Get the VSP amount converted from the RariFuse's fVSP and fVVSP pools
    function _inFusePools(address _holder) internal view returns (uint256) {
        uint256 _vspBalance = _depositedInCTokenLike(fVSP_23, _holder);
        uint256 _vvspBalance = _depositedInCTokenLike(fVVSP_23, _holder) + _depositedInCTokenLike(fVVSP_110, _holder);
        return _vspBalance + _toVSP(_vvspBalance);
    }

    /// @notice Get the amout of VSP tokens deposited in UniswapV2-Like pair pool
    function _inUniswapV2Like(address _pairAddress, address _holder) internal view returns (uint256) {
        IUniswapV2Pair _pair = IUniswapV2Pair(_pairAddress);
        require(_pair.token0() == VSP, "token0-is-not-vsp");
        uint256 staked = _pair.balanceOf(_holder);
        if (staked == 0) {
            return 0;
        }
        uint256 lpTotalSupply = _pair.totalSupply();
        (uint112 _reserve0, , ) = _pair.getReserves();

        return (_reserve0 * staked) / lpTotalSupply;
    }

    /// @notice Get the voting power for an account
    function balanceOf(address _holder) public view virtual onlyIfAddressIsValid(_holder) returns (uint256) {
        uint256 votingPower = IERC20(VSP).balanceOf(_holder) + // VSP
            _inVSPPool(_holder) + // vVSP
            _inFusePools(_holder) + // fTokens (fVSP and fVVSP)
            _inUniswapV2Like(uniswapV2, _holder) + // UniswapV2 VSP/ETH
            _inUniswapV2Like(sushiswap, _holder); // Sushiswap VSP/ETH

        return votingPower >= MINIMUM_VOTING_POWER ? votingPower : 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICToken is IERC20 {
    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function getCash() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesperPool is IERC20 {
    function getPricePerShare() external view returns (uint256);
}