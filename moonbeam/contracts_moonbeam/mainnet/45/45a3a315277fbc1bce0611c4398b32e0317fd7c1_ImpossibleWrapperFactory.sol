// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './ImpossibleWrappedToken.sol';

import './interfaces/IImpossibleWrapperFactory.sol';
import './interfaces/IERC20.sol';

/**
    @title  Wrapper Factory for Impossible Swap V3
    @author Impossible Finance
    @notice This factory builds upon basic Uni V2 factory by changing "feeToSetter"
            to "governance" and adding a whitelist
    @dev    See documentation at: https://docs.impossible.finance/impossible-swap/overview
*/

contract ImpossibleWrapperFactory is IImpossibleWrapperFactory {
    address public governance;
    mapping(address => address) public override tokensToWrappedTokens;
    mapping(address => address) public override wrappedTokensToTokens;

    /**
     @notice The constructor for the IF swap factory
     @param _governance The address for IF Governance
    */
    constructor(address _governance) {
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, 'IF: FORBIDDEN');
        _;
    }

    /**
     @notice Sets the address for IF governance
     @dev Can only be called by IF governance
     @param _governance The address of the new IF governance
    */
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    /**
     @notice Creates a pair with some ratio
     @dev underlying The address of token to wrap
     @dev ratioNumerator The numerator value of the ratio to apply for ratio * underlying = wrapped underlying
     @dev ratioDenominator The denominator value of the ratio to apply for ratio * underlying = wrapped underlying
    */
    function createPairing(
        address underlying,
        uint256 ratioNumerator,
        uint256 ratioDenominator
    ) external onlyGovernance returns (address) {
        require(
            tokensToWrappedTokens[underlying] == address(0x0) && wrappedTokensToTokens[underlying] == address(0x0),
            'IF: PAIR_EXISTS'
        );
        require(ratioNumerator != 0 && ratioDenominator != 0, 'IF: INVALID_RATIO');
        ImpossibleWrappedToken wrapper = new ImpossibleWrappedToken(underlying, ratioNumerator, ratioDenominator);
        tokensToWrappedTokens[underlying] = address(wrapper);
        wrappedTokensToTokens[address(wrapper)] = underlying;
        emit WrapCreated(underlying, address(wrapper), ratioNumerator, ratioDenominator);
        return address(wrapper);
    }

    /**
     @notice Deletes a pairing
     @notice requires supply of wrapped token to be 0
     @dev wrapper The address of the wrapper
    */
    function deletePairing(address wrapper) external onlyGovernance {
        require(ImpossibleWrappedToken(wrapper).totalSupply() == 0, 'IF: NONZERO_SUPPLY');
        address _underlying = wrappedTokensToTokens[wrapper];
        require(ImpossibleWrappedToken(wrapper).underlying() == IERC20(_underlying), 'IF: INVALID_TOKEN');
        require(_underlying != address(0x0), 'IF: Address must have pair');
        delete tokensToWrappedTokens[_underlying];
        delete wrappedTokensToTokens[wrapper];
        emit WrapDeleted(_underlying, address(wrapper));
    }
}

// SPDX-License-Identifier: GPL-3

pragma solidity =0.7.6;

import './libraries/TransferHelper.sol';
import './libraries/SafeMath.sol';
import './libraries/ReentrancyGuard.sol';

import './interfaces/IImpossibleWrappedToken.sol';
import './interfaces/IERC20.sol';

contract ImpossibleWrappedToken is IImpossibleWrappedToken, ReentrancyGuard {
    using SafeMath for uint256;

    string public override name;
    string public override symbol;
    uint8 public override decimals = 18;
    uint256 public override totalSupply;

    IERC20 public underlying;
    uint256 public underlyingBalance;
    uint256 public ratioNum;
    uint256 public ratioDenom;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(
        address _underlying,
        uint256 _ratioNum,
        uint256 _ratioDenom
    ) {
        underlying = IERC20(_underlying);
        ratioNum = _ratioNum;
        ratioDenom = _ratioDenom;
        string memory desc = string(abi.encodePacked(underlying.symbol()));
        name = string(abi.encodePacked('IF-Wrapped ', desc));
        symbol = string(abi.encodePacked('WIF ', desc));
    }

    // amt = amount of wrapped tokens
    function deposit(address dst, uint256 sendAmt) public override nonReentrant returns (uint256 wad) {
        TransferHelper.safeTransferFrom(address(underlying), msg.sender, address(this), sendAmt);
        uint256 receiveAmt = IERC20(underlying).balanceOf(address(this)).sub(underlyingBalance);
        wad = receiveAmt.mul(ratioNum).div(ratioDenom);
        balanceOf[dst] = balanceOf[dst].add(wad);
        totalSupply = totalSupply.add(wad);
        underlyingBalance = underlyingBalance.add(receiveAmt);
        emit Transfer(address(0), dst, wad);
    }

    // wad = amount of wrapped tokens
    function withdraw(address dst, uint256 wad) public override nonReentrant returns (uint256 transferAmt) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(wad);
        totalSupply = totalSupply.sub(wad);
        transferAmt = wad.mul(ratioDenom).div(ratioNum);
        TransferHelper.safeTransfer(address(underlying), dst, transferAmt);
        underlyingBalance = underlyingBalance.sub(transferAmt);
        emit Transfer(msg.sender, address(0), wad);
    }

    function amtToUnderlyingAmt(uint256 amt) public view override returns (uint256) {
        return amt.mul(ratioDenom).div(ratioNum);
    }

    function approve(address guy, uint256 wad) public override returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public override returns (bool) {
        require(dst != address(0x0), 'IF Wrapper: INVALID_DST');
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public override returns (bool) {
        require(balanceOf[src] >= wad, '');
        require(dst != address(0x0), 'IF Wrapper: INVALID_DST');

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, 'ImpossibleWrapper: INSUFF_ALLOWANCE');
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IImpossibleWrapperFactory {
    event WrapCreated(address, address, uint256, uint256);
    event WrapDeleted(address, address);

    function tokensToWrappedTokens(address) external view returns (address);

    function wrappedTokensToTokens(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import './IERC20.sol';

interface IImpossibleWrappedToken is IERC20 {
    function deposit(address, uint256) external returns (uint256);

    function withdraw(address, uint256) external returns (uint256);

    function amtToUnderlyingAmt(uint256) external returns (uint256);
}