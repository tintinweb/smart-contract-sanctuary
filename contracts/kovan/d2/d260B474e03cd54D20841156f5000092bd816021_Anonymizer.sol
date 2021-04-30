/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: contracts/lib/hasher.sol

pragma solidity ^0.5.17;

library Hasher {
    function MiMCSponge(uint256 xL_in, uint256 xR_in)
    public
    pure
    returns (uint256 xL, uint256 xR);
}

// File: contracts/merkle-tree.sol

pragma solidity ^0.5.17;

contract MerkleTreeWithHistory {
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public constant ZERO_VALUE =
        21663839004416932945382355908790599225266501822907911457504978515578255421292;

    uint32 public levels;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code
    bytes32[] public filledSubtrees;
    bytes32[] public zeros;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    uint32 public constant ROOT_HISTORY_SIZE = 100;
    bytes32[ROOT_HISTORY_SIZE] public roots;

    constructor(uint32 _treeLevels) public {
        require(_treeLevels > 0, "_treeLevels should be greater than zero");
        require(_treeLevels < 32, "_treeLevels should be less than 32");
        levels = _treeLevels;

        bytes32 currentZero = bytes32(ZERO_VALUE);
        zeros.push(currentZero);
        filledSubtrees.push(currentZero);

        for (uint32 i = 1; i < levels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        roots[0] = hashLeftRight(currentZero, currentZero);
    }

    /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
    function hashLeftRight(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32)
    {
        require(
            uint256(_left) < FIELD_SIZE,
            "_left should be inside the field"
        );
        require(
            uint256(_right) < FIELD_SIZE,
            "_right should be inside the field"
        );
        uint256 R = uint256(_left);
        uint256 C = 0;
        (R, C) = Hasher.MiMCSponge(R, C);
        R = addmod(R, uint256(_right), FIELD_SIZE);
        (R, C) = Hasher.MiMCSponge(R, C);
        return bytes32(R);
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 currentIndex = nextIndex;
        require(
            currentIndex != uint32(2)**levels,
            "Merkle tree is full. No more leafs can be added"
        );
        nextIndex += 1;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros[i];

                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);

            currentIndex /= 2;
        }

        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = currentLevelHash;
        return nextIndex - 1;
    }

    /**
    @dev Whether the root is present in the root history
  */
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint32 i = currentRootIndex;
        do {
            if (_root == roots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != currentRootIndex);
        return false;
    }

    /**
    @dev Returns the last root
  */
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }
}

// File: contracts/lib/TransferHelper.sol

pragma solidity 0.5.17;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/lib/IUniswap.sol

pragma solidity 0.5.17;

interface IUniswap {
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external
    returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external
    returns (uint[] memory amounts);
}

// File: contracts/operations-processor.sol

pragma solidity 0.5.17;



contract OperationsProcessor {
    event log(string message);

    uint256 constant CURRENCIES_NUMBER = 100;
    uint256 constant TOKENS_NUMBER = CURRENCIES_NUMBER - 1;
    address[TOKENS_NUMBER] private _tokens;
    IUniswap uniswap;

    function _init(address[TOKENS_NUMBER] memory tokens, address _uniswap)
        internal
    {
        uniswap = IUniswap(_uniswap);
        _tokens = tokens;
    }

    function() external payable {}

    function tokens() public view returns (address[TOKENS_NUMBER] memory) {
        return _tokens;
    }

    function getUniswapAddress() public view returns (address) {
        return address(uniswap);
    }

    function processCreateWallet(uint256[] memory tokensAmounts) internal {
        _checkEthDeposit(tokensAmounts[0]);
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (tokensAmounts[i] != 0) {
                address token = _tokens[i - 1];
                _doTokenDeposit(token, tokensAmounts[i]);
            }
        }
    }

    function processDeposit(uint256[] memory tokensAmounts) internal {
        _checkEthDeposit(tokensAmounts[0]);
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (tokensAmounts[i] != 0) {
                address token = _tokens[i - 1];
                _doTokenDeposit(token, tokensAmounts[i]);
            }
        }
    }

    function processSwap(
        uint256 amountFrom,
        uint256 indexFrom,
        uint256 amountTo,
        uint256 indexTo
    ) internal {
        require(
            indexFrom != indexTo,
            "Anonymizer: FROM and TO addresses should be different"
        );
        emit log("start swap");
        if (indexFrom == 0 || indexTo == 0) {
            if (indexFrom == 0) {
                address tokenTo = _tokens[indexTo - 1];
                _ethToToken(amountFrom, amountTo, tokenTo);
            } else {
                address tokenFrom = _tokens[indexFrom - 1];
                _tokenToEth(amountFrom, amountTo, tokenFrom);
            }
        } else {
            address tokenFrom = _tokens[indexFrom - 1];
            address tokenTo = _tokens[indexTo - 1];
            _tokenToToken(amountFrom, tokenFrom, amountTo, tokenTo);
        }
    }

    function processWithdraw(uint256[] memory deltas, address recepient)
        internal
    {
        if (deltas[0] != 0) {
            TransferHelper.safeTransferETH(recepient, deltas[0]);
        }
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (deltas[i] != 0) {
                address token = _tokens[i - 1];
                _doTokenWithdraw(token, deltas[i], recepient);
            }
        }
    }

    function _checkEthDeposit(uint256 value) private view {
        require(
            msg.value == value,
            "Attached ether amount does not correspond to the declared amount"
        );
    }

    function _doTokenDeposit(address token, uint256 value) private {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            value
        );
    }

    function _doTokenWithdraw(
        address token,
        uint256 value,
        address recepient
    ) private {
        TransferHelper.safeTransfer(token, recepient, value);
    }

    function _ethToToken(
        uint256 amountFrom,
        uint256 amountTo,
        address tokenTo
    ) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = tokenTo;
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactETHForTokens.value(amountFrom)(
            amountTo,
            path,
            address(this),
            deadline
        );
    }

    function _tokenToEth(
        uint256 amountFrom,
        uint256 amountTo,
        address tokenFrom
    ) private returns (uint256[] memory amounts) {
        TransferHelper.safeApprove(tokenFrom, address(uniswap), amountFrom);
        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = uniswap.WETH();
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactTokensForETH(
            amountFrom,
            amountTo,
            path,
            address(this),
            deadline
        );
    }

    function _tokenToToken(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) private returns (uint256[] memory amounts) {
        TransferHelper.safeApprove(tokenFrom, address(uniswap), amountFrom);
        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenTo;
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactTokensForTokens(
            amountFrom,
            amountTo,
            path,
            address(this),
            deadline
        );
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/utils.sol

pragma solidity ^0.5.17;

contract Utils {
    using SafeMath for uint256;

    function sliceArray(uint256[] memory array, uint256 indexFrom)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory sliced = new uint256[](array.length.sub(indexFrom));
        uint256 k = 0;
        for (uint256 i = 0; i < array.length; i++) {
            if (i < indexFrom) {
                continue;
            }
            sliced[k] = array[i];
            k++;
        }
        return sliced;
    }

    function getDeltasArray(uint256[] memory array, uint256 indexFrom)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory sliced =
            new uint256[](array.length.sub(indexFrom + 1));
        uint256 k = 0;
        for (uint256 i = 0; i < array.length; i++) {
            if (i < indexFrom) {
                continue;
            }
            sliced[k] = array[i];
            k++;
        }
        return sliced;
    }
}

// File: contracts/lib/Pairing.sol

pragma solidity ^0.5.17;

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
            10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
            8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

        /*
                // Changed by Jordi point
                return G2Point(
                    [10857046999023057135944570762232829481370756359578518086990519993285655852781,
                     11559732032986387107991004021392285783925812861821192530917403151452391805634],
                    [8495653923123431417604973247489272438418190587263600148770280649306958101930,
                     4082367875863433681332203403145435568316851327593401208105741076214120093531]
                );
        */
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1, G2Point memory a2,
        G1Point memory b1, G2Point memory b2,
        G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1, G2Point memory a2,
        G1Point memory b1, G2Point memory b2,
        G1Point memory c1, G2Point memory c2,
        G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// File: contracts/verifiers/CreateWalletVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;


contract CreateWalletVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            1771803850637306749800466300966890222280039134550481730657648180471997291522,
            11800472751839748659650349358211532227099362921031879363430672904217981024437
        );
        vk.beta2 = Pairing.G2Point(
            [
                995215446090931096336940657631783902649485898595741265469025449931195839598,
                11363622625384518481727294294443424083008623795863829276653732336580356878886
            ],
            [
                19642873852370555374089051127429987351548805919898762685348579024777103959882,
                17735705485621792211387653759833854505887515847819815495130627208901820336926
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                7598077052565285230378160725072775296196554454112291142668620106356591481005,
                8241652282396985752730583187382627840176405901364676115576585033322987248377
            ],
            [
                16657569023921545507172556735180421378331284680643072382349814056107811827076,
                9695333279838700448755966410400472500572061147236263899435146413406770837811
            ]
        );
        vk.IC = new Pairing.G1Point[](102);
        vk.IC[0] = Pairing.G1Point(
            16433933339322576372652172880038528779178255324364494342359051366767814627377,
            6967197266495704229982460074679125245933834856365827014008696295002785222576
        );
        vk.IC[1] = Pairing.G1Point(
            9760311529156406809610491565029183957236030627305541454724902212479969371686,
            8230561947341564656700111294912933053586095414204567961330090534159236708812
        );
        vk.IC[2] = Pairing.G1Point(
            3384376398726502172859624792696576166757900823765348480031197903190736898794,
            12334513220154494115710025596786961775779926318074347690124887934780687117766
        );
        vk.IC[3] = Pairing.G1Point(
            11018635196901199889197941120938973059119057963645079594864648791811441223404,
            18918566991511172324628723633312471503704974288312959154449481817167475007449
        );
        vk.IC[4] = Pairing.G1Point(
            19804367568431868135910425925532619204912962089754965613622750184365172633914,
            9503202049521424189467012939243613211427186819343677371623810323733127841665
        );
        vk.IC[5] = Pairing.G1Point(
            9508803103207557486745233228809308628729613463164378982568466013737676551771,
            17514737677236507410944237672191132693610334160656146207050654339135405052735
        );
        vk.IC[6] = Pairing.G1Point(
            10849694471830772020445646656934576251776172554249868581093575491348688003478,
            5412384709941592252560707120613528937073063037065576372454566667747259002745
        );
        vk.IC[7] = Pairing.G1Point(
            8391001378920879079338554052723327717012968563278569261760336189140572297999,
            4321444922528589923319837533754794282493725612060986505399794734479990265038
        );
        vk.IC[8] = Pairing.G1Point(
            7948246937958238707711733221554565557035480332882641735064926709181318839935,
            2786427013632055269964548137938244473342968720690311681916220851276090517487
        );
        vk.IC[9] = Pairing.G1Point(
            9859566556486125372842235075749172126260470269352957793369575832557524973522,
            17124166098880327741964996173825139010211875520001233863542763932141876674959
        );
        vk.IC[10] = Pairing.G1Point(
            13341778824877695923448173548523284178610494869480502030376258415304847160456,
            21833582269256632355419070259773887824245784743706336279859123339747370968055
        );
        vk.IC[11] = Pairing.G1Point(
            6841444433778421488505974113707828953160194615416936734766923839570718154381,
            6412575079832783030120178754036419459213602530919217396930171424648990524476
        );
        vk.IC[12] = Pairing.G1Point(
            5505752772128718051831730637489936715236652702403470997248876527871249700192,
            16604300453342870463786176059003223625869037913872665008699357940965203987903
        );
        vk.IC[13] = Pairing.G1Point(
            7791738626136559658710890569462227277829692684927284699357624995140434997069,
            10844136346085639353281154554083400594958939617649373355369793888102182574176
        );
        vk.IC[14] = Pairing.G1Point(
            4576018936765674225834639167855148625693083220296968320058290873506530069272,
            11398716622770750102939322692155072076638659943841015283968546068658010804718
        );
        vk.IC[15] = Pairing.G1Point(
            17698737257332648201623545507446057137822724984811625213371078900368638086735,
            17363240983120204378732503562768850342673306823424221375839183274938691643961
        );
        vk.IC[16] = Pairing.G1Point(
            6958814490523531879369531098242381648542969582927086282478444976875669659945,
            15734713883472432743911707350364358875994370286278793865169911774592071285541
        );
        vk.IC[17] = Pairing.G1Point(
            20712710347573748924756005849617740309720876907101208310707521605750974552752,
            16721117126476501708581089962679057713394925906190939280131681981581752842206
        );
        vk.IC[18] = Pairing.G1Point(
            16176392752863271462686530199060201298966040205750563276376445131450120427564,
            21832341750885765554752825592656643052863576672229335491875009015551968143133
        );
        vk.IC[19] = Pairing.G1Point(
            15383968547116409293945573425402948504051923053380580417941236631759201031822,
            14950504554342007541100110797004215766231264770396027313420220974213875578867
        );
        vk.IC[20] = Pairing.G1Point(
            17634682837094761626546915489266003117104821813305339839164723815490899634196,
            17303388265734199840415392187872586434255900188067852684329636597858739523870
        );
        vk.IC[21] = Pairing.G1Point(
            16182626976756120403431395214202945383158594595137714186085935830732912228294,
            1397789404056257511607845955306971607103657511184273883976347253244777496470
        );
        vk.IC[22] = Pairing.G1Point(
            13320060228483309633111655329791907732333278562983167757669043659314268475791,
            14977189308700993184000254065103086645483649084398465363806357040420783647364
        );
        vk.IC[23] = Pairing.G1Point(
            17031854360339457210143256973185098648185222306879517605205069327329822073755,
            14953345086444719871822935354409713293710681684101616381648412542104828075685
        );
        vk.IC[24] = Pairing.G1Point(
            19260387055279026793235085198618350413553609733075474273549207209155727926039,
            7257760896531494543894776847517564381362275504925132147657800076553783594458
        );
        vk.IC[25] = Pairing.G1Point(
            4134926226512596124232737120922409399410233604109090105911699258873742609131,
            7796271233884780487642727495114463614397697926296000296698313012939342174982
        );
        vk.IC[26] = Pairing.G1Point(
            3091668179123885215107549372569014169220404713915090572040743555812795012725,
            3873645484463769507480302636607866439782437900540261364650166909141493180574
        );
        vk.IC[27] = Pairing.G1Point(
            10971536237216966612401276088445188607611832123791979462444663737426399686166,
            6242481633072191282366175571565389316640174159081253398533033794619602319778
        );
        vk.IC[28] = Pairing.G1Point(
            15893899878388991584604692798294987022315596866148655882819951536204659278487,
            13311960565831214272984861772631464069431078327722669028250794883845828565267
        );
        vk.IC[29] = Pairing.G1Point(
            3538462043408980821881038261935928359891665319301718497613258579147495260581,
            10834981434048985011784698311951341858151813372482396146874126066324079260154
        );
        vk.IC[30] = Pairing.G1Point(
            19980252196780993877089243893568568025385909981047213815836527323204668249929,
            8981814363151403103046906960430355009443839186667353428506124725771424144054
        );
        vk.IC[31] = Pairing.G1Point(
            12940093460763746400155991142251184069655653740376258588253876394102882099839,
            2116148027207000445903627418144055989149342924695385505876986203866186414433
        );
        vk.IC[32] = Pairing.G1Point(
            4693143795423566645034816294305156545926213018371990725591533269704134869210,
            6950649670259373048301929674529831573795374591480708091810884959046249883081
        );
        vk.IC[33] = Pairing.G1Point(
            20860684244961377594491108442050844404007403984497048799554013153209071075050,
            6113091522626101340606615281488286461632026420140520961879308215352467923702
        );
        vk.IC[34] = Pairing.G1Point(
            241093845682533493339791748950633550152322233219717431259545150447211277895,
            8732161225394530264909196976936691559123429028206080510800674911975600564721
        );
        vk.IC[35] = Pairing.G1Point(
            21542349189347306788003309742532065744257080538680539910684964678249087199169,
            20339614378966121355812817244368836324035192635594666622679921624514125293403
        );
        vk.IC[36] = Pairing.G1Point(
            8435673608518321078527219053986552479658714253684473490815803956605448388542,
            1090648829278488622091815520260305901391041588468332826971349192870048673470
        );
        vk.IC[37] = Pairing.G1Point(
            18484247435856400791854606344870679187320432807563104137466436656265121037910,
            360011778612367289610156941272956288669606350612953897222367787665378182957
        );
        vk.IC[38] = Pairing.G1Point(
            19307459744667318395048757731616823381032874194825105774398556432098960686182,
            16608138711070537694303401413261605742541308664800711806297176349973842280229
        );
        vk.IC[39] = Pairing.G1Point(
            12386226468872579777221316294858115037068567284409034994355355726181901365099,
            7210579967117241179795020503746123789758492505472610926953884220885017920317
        );
        vk.IC[40] = Pairing.G1Point(
            16306662307596739878228454887369319211171719828620856823024905445613251498718,
            845510707537094111313435217378883814303363813822948996639083171470764588004
        );
        vk.IC[41] = Pairing.G1Point(
            12616448083533397003438715732904455985598029203280419017103906462106332312009,
            10396585774570882691471308478652107961814350050857560795242150298326625405610
        );
        vk.IC[42] = Pairing.G1Point(
            18034587310905019474534413552060954735141309487604069559808557164501678679301,
            3098775230295733897367145249454280876244795769935495667629135323178242097048
        );
        vk.IC[43] = Pairing.G1Point(
            7301907030416212151185610475171418716584126478324845158174041389172220703149,
            2021144230576723695421862394282615074855290838167758037559986441529085426329
        );
        vk.IC[44] = Pairing.G1Point(
            2972493671611483881906203486912963446566196572803734895521895239217289238394,
            20949746820248533933113797650621887452866731328674757223949163299685003868036
        );
        vk.IC[45] = Pairing.G1Point(
            3468187826236262822607854641673847359333093656938603190330389727665438363223,
            6194697353212368117093843098026785720750828744319303728183819855392513656544
        );
        vk.IC[46] = Pairing.G1Point(
            9776923723241172967393580410340551106952065693637831022560934531799587694300,
            368785329283157610907016830574408164165791217984721435966019130810015008317
        );
        vk.IC[47] = Pairing.G1Point(
            20243063225248738028259853977536961550980521690340642315818689755210943497541,
            16535971272947565510006174090606990571163518124501659765754696266986414540607
        );
        vk.IC[48] = Pairing.G1Point(
            17481897751556957912262823055800977411571118368151904751832579538456883497116,
            18424326750902958190894652325170079522733946250376004173039810558696630062642
        );
        vk.IC[49] = Pairing.G1Point(
            8091383902690017253918483249819385972159408977510767765915482662588640973444,
            8845848970824900600742712590311171466534267718066111895231809927995942216358
        );
        vk.IC[50] = Pairing.G1Point(
            9825317495347882734256384631448747018684804906681145563541512371904081347997,
            21152612592316093788594598546204209100478543849689110800422740900778746474414
        );
        vk.IC[51] = Pairing.G1Point(
            20417717705908993236349918481682910707160297111829058587950767273831606757352,
            10092405472684176244070065594904937917960454172232846302104802220583323361042
        );
        vk.IC[52] = Pairing.G1Point(
            16644401389454755080645312056246073945292934121978088405824970805195479269744,
            19401027620668224984365967646454337058646512501117410808772864012424463072040
        );
        vk.IC[53] = Pairing.G1Point(
            1568750547813981030743938323633543809414361706496410687686291861146397342563,
            14546273761940240552747788775904349900467047437941981198989143497955104973671
        );
        vk.IC[54] = Pairing.G1Point(
            20994097086120297225731898277264193321260411328712878731876929400905700583398,
            19433431718651208217553955419665425894542897509250078623529645518441224782696
        );
        vk.IC[55] = Pairing.G1Point(
            7069908267276630034168313726450289390228013959207013180152017201176000663532,
            10078222698793121488825881438684600946842015093135947478245621458750999926433
        );
        vk.IC[56] = Pairing.G1Point(
            5297982532672647354060922115681186327024711598972500607100478205783463583024,
            7180713055102148913851540620615282927986768927293694450097157628857248235200
        );
        vk.IC[57] = Pairing.G1Point(
            1765011231985706975417343627502156144985640920026642135182579260906952701886,
            13708861901197098630050175826672833645741462495073327621786393219975770656285
        );
        vk.IC[58] = Pairing.G1Point(
            7118305900259882338364379701327737796099162874485634229599816709854274166522,
            1314704696234875754099433534886264276844794220678555023137349717094804856567
        );
        vk.IC[59] = Pairing.G1Point(
            10067087200722469154155673143689465211603731673477207033424004786671148408456,
            9686592265449433364390787784024187263596407553439399423317210644807769602704
        );
        vk.IC[60] = Pairing.G1Point(
            3017280199304169861943009530686501140329653114298390568158646777878296819605,
            18283556365788120594877929924868236112264350981618885822265675290639371266689
        );
        vk.IC[61] = Pairing.G1Point(
            14319608299006747473122185667379216241184915758604660573141652862012251247670,
            14864967217383509100792704614971501558084616913816748565606167728359748880013
        );
        vk.IC[62] = Pairing.G1Point(
            8011892491411254706458422714012885192550204117522243488629838743277934645574,
            8203086795206902945216450676210859591443004100586399442441330300362419290133
        );
        vk.IC[63] = Pairing.G1Point(
            3492203002299677720442500503959409310768160036590859229988527321355195254770,
            12698928631847175703793572503220312422932906486552103639767343975074591699879
        );
        vk.IC[64] = Pairing.G1Point(
            8238128456421888754081775367438215650418883887968891470044058887250382007080,
            20279803682081538348869586862771208850503916931333281538598522727728644718798
        );
        vk.IC[65] = Pairing.G1Point(
            6094601348670287894506816962061833360957403237255762239460292225560416730918,
            4321786990322671591604251145578549180850807777754458968568285015306446179535
        );
        vk.IC[66] = Pairing.G1Point(
            18676564149765351684957517043179656260269019789300511487583652718141921100451,
            7927940157080084601780845770728626324666793817911921950792190747265488900973
        );
        vk.IC[67] = Pairing.G1Point(
            16591000205698551056115175397157904205496561670186635214072588658176976409993,
            4931794472122236178436271051201403004431947407781221631398741499487882658752
        );
        vk.IC[68] = Pairing.G1Point(
            6558044597879691446831840683698772143962973010573400138975147637638859620243,
            11042909122207537018986083307515430492492343857242068951931996265501786496495
        );
        vk.IC[69] = Pairing.G1Point(
            19317218793212065462262772914890377563636107838860032485675061366241979092592,
            21180147979666578058797214145409142581131250488660932069771415240419812780669
        );
        vk.IC[70] = Pairing.G1Point(
            17798066771313655495444501577869332520571937563692936157691484394341172444083,
            15622692242529936687287856710548003161306708802234752043984504641466328490209
        );
        vk.IC[71] = Pairing.G1Point(
            2446803600104418379826378605376127234805342795477743562298826090311353820656,
            10185813757328806659334678234715768198608960881274571810591655134268364622769
        );
        vk.IC[72] = Pairing.G1Point(
            3185978739871470696815258887113447409247954325235123896783097567867836445538,
            13405186327493600049669212138119165811953041780260843087231246243632622275999
        );
        vk.IC[73] = Pairing.G1Point(
            10311444578054575718925106282442011473435365419556801947734782849190906680813,
            14520777599663144926745541069353236058702851959868678055803721060335582031985
        );
        vk.IC[74] = Pairing.G1Point(
            18910847557631783869960380049248948124710271061949717498180203740413178942426,
            3752609960950618424801616017904625009817109913996799561340303020214910675989
        );
        vk.IC[75] = Pairing.G1Point(
            12602521231109289089410400113683750745775031290252689225580663032172460847069,
            7256679445193570732655534117820069436735843366088247466811711744226442772912
        );
        vk.IC[76] = Pairing.G1Point(
            17626531059831310249378779278169139046021533328182158518397939627321219728597,
            16793846540984420440739368484767664397620716076157903598718394197730517188743
        );
        vk.IC[77] = Pairing.G1Point(
            20865068941242889364260431705487732438366524778668408476662616414959204431251,
            2157259334715716415583118921481014484363881189598243028655778819773535400881
        );
        vk.IC[78] = Pairing.G1Point(
            19187000069595511970533335696161786298201785020711711537383548039191323098412,
            2706232173333065832786971249268088252409793952487701257980284308810601670302
        );
        vk.IC[79] = Pairing.G1Point(
            11571863911581967698587429028344507955301924873838892176130101944476556384420,
            11523640893311093629025258867501416416476235172773252015813160377519713160720
        );
        vk.IC[80] = Pairing.G1Point(
            9951806427172275554784843854328543807449299537566413327865551371843595392627,
            5619212128684896444674076875960793721360378572273374283954398633095008519455
        );
        vk.IC[81] = Pairing.G1Point(
            8015929035825822336107861327516999212563839761967904349580653271409801772673,
            15755492091913339797333170696186776341855424364638200140072833610338729634947
        );
        vk.IC[82] = Pairing.G1Point(
            556793192543412287978057014964443124869932059719319746993824945246751835443,
            1830669340577026414983258656895563108934114218558162558844456136281138429488
        );
        vk.IC[83] = Pairing.G1Point(
            591648731232483206760453286025248992479739171613980071685247889512110244099,
            7699100174421795149913556102027145902819812469741921166327373204227851564453
        );
        vk.IC[84] = Pairing.G1Point(
            17318767733013998561873925354608421731881508736752970318727442437686029814631,
            20223697082805368006457656927136555400246805684398695177011030225386951061801
        );
        vk.IC[85] = Pairing.G1Point(
            11105686371379775375958938721421315188145785706392265725072654121667358598538,
            2714646283313669531650684742860198815273881239019766383263566701662638165057
        );
        vk.IC[86] = Pairing.G1Point(
            2899891628393134183495685670704225025289558345762796108939580219100481635986,
            16716027160956137427766014367908426126794251084650845360706005563239247196508
        );
        vk.IC[87] = Pairing.G1Point(
            3172050325253300363141962274181685960334447585587199954668044131666284544855,
            20738354509046548269067966437531591658742994062791532467101180353165573839362
        );
        vk.IC[88] = Pairing.G1Point(
            12772506605078816267230553082513198440293372764000747367432420112717778004891,
            4877497447036400331355235650438037691088908204385042726449709740841998901842
        );
        vk.IC[89] = Pairing.G1Point(
            18994446726459849404735988666564827901960851335615598814057970759630683459061,
            18357751612491747953996745309074883131585841216269849388678626147561934994667
        );
        vk.IC[90] = Pairing.G1Point(
            13657904284072712272041024995272357197880368267050370121969888332554094130394,
            11030977042392537602098236759696119030486124275942511590865811717454135175341
        );
        vk.IC[91] = Pairing.G1Point(
            10195320083742888469399724966115770618786239456079698062907589045999042346630,
            7372708600936312498514450502317672212724977989837475489478541190827801202581
        );
        vk.IC[92] = Pairing.G1Point(
            15336831189496327481621580584883981907790551896362003618066666175344432353913,
            15052689493311241917336747270323741039976621783488701028514621185066714944331
        );
        vk.IC[93] = Pairing.G1Point(
            20029460927073247271943095705374278997400356421115508839997985715719081633328,
            18742587064587127745131229638648532674098023822612037478208589940765887078517
        );
        vk.IC[94] = Pairing.G1Point(
            3023311815533774240826993303016212883936292278942397115208283471378383151262,
            13794124090697475756797122136423753554273986266252813224895343059897914198667
        );
        vk.IC[95] = Pairing.G1Point(
            12258589029954791199931606520851600352470173901742482373039647739822802402019,
            18595358704147616435529575428410664347282303410985770065835266536915536397009
        );
        vk.IC[96] = Pairing.G1Point(
            15980760223756195272973912951850968945445681433072970906753595095701754204540,
            12333814004713996679431906460975133255441666408284722217228030878840518533642
        );
        vk.IC[97] = Pairing.G1Point(
            6538185899122546052668772889511337486737773143301809037157147208823594431487,
            11784685088613095661911457078586941625614654592864826816327871725828308038637
        );
        vk.IC[98] = Pairing.G1Point(
            4305213826596844254423070831061697703775813262812910460154082411708125657920,
            18409524772769937678350303418992655713697380008545416025286505774813330826507
        );
        vk.IC[99] = Pairing.G1Point(
            13815581565791417847883396888212035184217847949237290915520475048055693825760,
            10081984087049336435592536477613039296503498619458964619541544087743397827881
        );
        vk.IC[100] = Pairing.G1Point(
            11272667113968978380671709076019005999726337306487561849114518535977916882293,
            10029990425615510809146979402781197726077501890095204422036993786124143249082
        );
        vk.IC[101] = Pairing.G1Point(
            18039329166019873220716764319181987369683685968975102174065272282565330580596,
            13574821673675593844638175936459713370367589200158754584135278638962904701104
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool r) {
        require(input.length == 101);
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/verifiers/DepositVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;


contract DepositVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            1771803850637306749800466300966890222280039134550481730657648180471997291522,
            11800472751839748659650349358211532227099362921031879363430672904217981024437
        );
        vk.beta2 = Pairing.G2Point(
            [
                995215446090931096336940657631783902649485898595741265469025449931195839598,
                11363622625384518481727294294443424083008623795863829276653732336580356878886
            ],
            [
                19642873852370555374089051127429987351548805919898762685348579024777103959882,
                17735705485621792211387653759833854505887515847819815495130627208901820336926
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                18233454083295927618508347624063546955045898772154038919936721911175501781464,
                20032385759060950330508639201988003072891202144205636917426308154159508459877
            ],
            [
                4303212193999766805916066870023516272478674149256146499133145887130161203033,
                16356880964635768636026323002543875590314558322805373777878323737119185820873
            ]
        );
        vk.IC = new Pairing.G1Point[](105);
        vk.IC[0] = Pairing.G1Point(
            8079210150947782706157154104093077714267966072211872883617254883786442632342,
            12169015737391420077978499515008035110798735662566269643585900211799319184914
        );
        vk.IC[1] = Pairing.G1Point(
            18921315990886829637859539991019006204773016140024386124992340383959137724977,
            20250520709528388324965008719210658041502605236435294191119781726979754566083
        );
        vk.IC[2] = Pairing.G1Point(
            19893225075782265172584694097437563125938999224651823178232148514367886993112,
            15952155738749883328067400918750225958496065619055863953473647480483579046125
        );
        vk.IC[3] = Pairing.G1Point(
            6672515889484662868452554230853483977596622727578970198759743195353879200506,
            13905464024470936830033610039922949197410719046878567364512822513634370637616
        );
        vk.IC[4] = Pairing.G1Point(
            21146744166585342282678728692311745025836808872184480325616982292280332346652,
            12413791136953538579626597039101350654170848607053701821032919106557132561710
        );
        vk.IC[5] = Pairing.G1Point(
            15419273466652412024134560761558749838135345425531370967072060209897666042356,
            12335909153554842848903577144072967650562578105051208428313437266081429692653
        );
        vk.IC[6] = Pairing.G1Point(
            18326187581895335283382019798514983117884440690299787116595991329137012494979,
            9379794879665147177071871102488844705214268333594496740232061247331946898533
        );
        vk.IC[7] = Pairing.G1Point(
            17200266094511956570505930764146873000063002982282466599962891848717130656652,
            4706214599066840066673349644053231206907206887304545063687512112217282323677
        );
        vk.IC[8] = Pairing.G1Point(
            19181274439895111680045761550764539643120571108594958710143958282657245858122,
            13486831271836116205231617474404080980750324684415643086904313191653725676884
        );
        vk.IC[9] = Pairing.G1Point(
            15427706930822503100040635006789521527811801740317507987347507554551821023117,
            4133319377077957010873981189012635300493067883738337473089579984425823583412
        );
        vk.IC[10] = Pairing.G1Point(
            19318017108643442993791608970191503982462785269778229860703885449388878922765,
            21158474885606353245095243394741258888331439258351612416768898491194463661091
        );
        vk.IC[11] = Pairing.G1Point(
            19187518124296135568602091222935354146194192128803609340916761603890576522850,
            6063882774018832929761248033312032631739648791553066577998267426286757138098
        );
        vk.IC[12] = Pairing.G1Point(
            13324289390487133992685697118935962507744960822305702371801020302188550580166,
            18817919373615824436547102314916975149621958690058975158135023020791728531673
        );
        vk.IC[13] = Pairing.G1Point(
            17452035195333438124547030857904432328841099868016593295628149900251183280565,
            15804145301879333251126178141309369519813315606075942920156416567427544576310
        );
        vk.IC[14] = Pairing.G1Point(
            17719399795412428122212916501297767225378319884371650821437432886825117509272,
            17882310868718646792112302255149252073554437645523504418219938449908502976606
        );
        vk.IC[15] = Pairing.G1Point(
            7478041659978371418036600714154494362739238619918776617671960248170475971325,
            5901676961512479745385281628315574187023418538085522282858335053795958719573
        );
        vk.IC[16] = Pairing.G1Point(
            6067835645845143872746514730126921254352804468457575326093033544892787762012,
            19578808735093776787969434224088929726238874721149677427097922143693721318612
        );
        vk.IC[17] = Pairing.G1Point(
            10203680906104437742062608043602800165932028922823582154408606949283121972335,
            16509011864494321645791183038765584050552830895098509273425574635834236432291
        );
        vk.IC[18] = Pairing.G1Point(
            2357233052941919754980705285620219921331358883407817523696777371153345148062,
            19669249283299513551671802354138141793344125145804801254101654829125801458696
        );
        vk.IC[19] = Pairing.G1Point(
            20953167633505842657796560617232942576045544208688132016583608111940278285505,
            6922940741291140761375565308025679953163024623213618011744118936711619153508
        );
        vk.IC[20] = Pairing.G1Point(
            9650272798438466362719625437425763472415418364450397758155356052251047921102,
            1249262056204251648710897814608229888512992172275474889384657278884275846029
        );
        vk.IC[21] = Pairing.G1Point(
            17601049159318607177252218756242657302800477669213396645638946124406617501565,
            4771393485498876195894210198848619610584643281775921431950951239221524223849
        );
        vk.IC[22] = Pairing.G1Point(
            11628637528487933987014921461007451351279037169496823487195233377115112276013,
            21100673061245926427270611806073612193756269103317452781535481299571750952993
        );
        vk.IC[23] = Pairing.G1Point(
            6363422075566200581617487271291061378838903140222154893114539579236218091129,
            9875518817489412953095600083688071466068741121803771509310573228871941954790
        );
        vk.IC[24] = Pairing.G1Point(
            12424567555522419463925977483310365767706990713323227233241278868442855468681,
            3097087515420224990159790571425951257139636863289680270047139955210243762036
        );
        vk.IC[25] = Pairing.G1Point(
            1014262068461984453433486423855410880122491706066143935320463634811226329941,
            7164580839194853708432370325339636087740241966554262814488809692860256750181
        );
        vk.IC[26] = Pairing.G1Point(
            6176038281505085461004665277636357935246181973438218252689215011078222284276,
            1316284000361611357512713365803821659492134730967666602099978563876254256623
        );
        vk.IC[27] = Pairing.G1Point(
            4111336781977490244491736196960054141798930563497139006514884068946258216856,
            12619607386361226907101532889534790617344993698790673785739871383044971757834
        );
        vk.IC[28] = Pairing.G1Point(
            11443558273487856621048098727609685997801343040039874055048946716998472656292,
            5254277978693420818119629213197931108631776513602499842952115960085276797262
        );
        vk.IC[29] = Pairing.G1Point(
            21148788622670982705477240987311984050218372782495108732972739220728172999781,
            20134253040849504578872463556106720079692753627470061710857832356155203266885
        );
        vk.IC[30] = Pairing.G1Point(
            17875234771590538989093321932413423875161259200525753927143388662798684416902,
            7593934992147416160260818649942207816703345696476470050315901128341471815405
        );
        vk.IC[31] = Pairing.G1Point(
            8345827786134455241245033392230908920746515532413583987243777677711224411539,
            14484641666258712515348235606463808262077593658937638800383718708185060046084
        );
        vk.IC[32] = Pairing.G1Point(
            17162303454817422106941310178187855561694809322793589450540921954567064874175,
            11594171152110670468418179118949681038403566899112541483801777129932528638790
        );
        vk.IC[33] = Pairing.G1Point(
            11661381692653425300196092544343335110100398678437905823571852413734324384375,
            16343236289004295021068878973361113967231471848715393096225805847184754614163
        );
        vk.IC[34] = Pairing.G1Point(
            3147676088957156812088313436896970258603958143120052397071843077620873358158,
            14685578872838685739355698458909083007411892446756243934965955612037172165286
        );
        vk.IC[35] = Pairing.G1Point(
            11139801758053641285064369219503934983971008602724572774465388106632920404668,
            4730561363801959596062911131198898970160149593513826985821566544086087395123
        );
        vk.IC[36] = Pairing.G1Point(
            1068527475527024078095980853671717594144737671942868599686711246106397192268,
            18009932138821054816090187165117082279238660735010119597700431132133414933128
        );
        vk.IC[37] = Pairing.G1Point(
            589978367088212985616178130233208992924828581304258105650968424428591055889,
            7520185372974823190742067006958394971115100177982567068894546083112090968367
        );
        vk.IC[38] = Pairing.G1Point(
            5928950679715679434043568427102446480639815822010048983553305089880672588159,
            12943980043279002995275696921777202690987503409452700257082403411333996207007
        );
        vk.IC[39] = Pairing.G1Point(
            795893051853020952951937277530458505584981293467521959636447089932088975448,
            10081125175687376377900743067812171651096958806398779681531938429079798977475
        );
        vk.IC[40] = Pairing.G1Point(
            8976340851828810223118705903091935176849022931511463131988976856681515402698,
            1691519048725359339010280307189570217365481551332519378964681768271515238643
        );
        vk.IC[41] = Pairing.G1Point(
            13866778483399129730198743934213933731197003114039045956352858911695824180961,
            14392937055661592123453892826858400115954457325458226736949871268320711357758
        );
        vk.IC[42] = Pairing.G1Point(
            18356813529005265358322922400593029854665909268107453589808345796623020137207,
            6535187322982398993087750233313542657229872353030074245864843003729351087496
        );
        vk.IC[43] = Pairing.G1Point(
            7466297604724728287988990579862624805893853161304617992214221934580853835880,
            21095419884448885176222441604752285761058131508943125127196340172333980620587
        );
        vk.IC[44] = Pairing.G1Point(
            21047608725906796340682598497279583723754772320645804316401032937629057380588,
            15831994399266102871477435943570988352228165008085393804693988314912066276316
        );
        vk.IC[45] = Pairing.G1Point(
            10739485964489991960224340267840589601389109141204745765253432310193779210711,
            12947646891231984630836494357271447808140842989013123805510311911035065031797
        );
        vk.IC[46] = Pairing.G1Point(
            13336825963264805227761240693795595150106484319979746110576102920113843672059,
            15899429518721526301575310328476040230714246615666138766479107739919008784098
        );
        vk.IC[47] = Pairing.G1Point(
            8509889141770197944768738989138864314817477678586058117997332541435418373783,
            20987491431147790663597921925574648219304500217389541800739893388857513581980
        );
        vk.IC[48] = Pairing.G1Point(
            5019167348456176388543964519232317839651158632847219250316932616595329993346,
            10276602348606304760919339183049734270765583178821376694926081680910016226483
        );
        vk.IC[49] = Pairing.G1Point(
            12999201488972199315884552910206971853622807209267955637647872350006497229535,
            17400827840742320384228885946410972883839487281389992025176730272690029016035
        );
        vk.IC[50] = Pairing.G1Point(
            11331035194535888481361904347635345792395358636211847378181238973985622396610,
            9475095465581038340715490412529410447502113236123480350034988146416500438593
        );
        vk.IC[51] = Pairing.G1Point(
            6184803200751800268086715401034836562945821626002224969941800531568058584254,
            3288628528203989916974402268152322100753475014221562724765567947192490922284
        );
        vk.IC[52] = Pairing.G1Point(
            17132455834938671772155596533795280298133448614639194583474071411105498696478,
            4438854585890991688756660126252661578019193200863497408769007688524465937695
        );
        vk.IC[53] = Pairing.G1Point(
            20986181338472165329435710131650836819997353914715177854560685802139018541179,
            1011017542403510153003706968244923878341128569332658826959745938221828190866
        );
        vk.IC[54] = Pairing.G1Point(
            7807939502289246967827855507903198709148091549361564366616305415230913938501,
            7968871530377686541819447297907443334176977492354340051588622548128025224248
        );
        vk.IC[55] = Pairing.G1Point(
            18905048234161016417853406927494958099243291019671160154368969031661471259894,
            5135494345636543592120893066529412130330616668143408370604162577940770327662
        );
        vk.IC[56] = Pairing.G1Point(
            13742684129444584472595793920583822251473394723096633886290239066364527763187,
            13559506410516488744384472039301332330485205770409223251550978730424076669764
        );
        vk.IC[57] = Pairing.G1Point(
            17961082183874638257376971524502746742462228280537245583582290158203008124040,
            16317158920327344826630496111367199454194390287590378655126357796185680068770
        );
        vk.IC[58] = Pairing.G1Point(
            13187777547859421915999122656948825361338256433824280973666115324469110064574,
            5797610180606962096641006048307738822096620089579626999550069683525527446489
        );
        vk.IC[59] = Pairing.G1Point(
            13909561947889572848876964178081850617529671527654674558815879288080399771105,
            7273634379234210532403096110278786348924832378545476617761733396087003241852
        );
        vk.IC[60] = Pairing.G1Point(
            17642543779224132513801412751512595031803491768030972507848166351747088026898,
            2771378876387556167863667710397973055035790921327136237533996416775711787031
        );
        vk.IC[61] = Pairing.G1Point(
            9494263314941107981565528220378584340399398792810797886329050081415581037949,
            14246708339408354034321596177718603353118803467676038647824204503961153386668
        );
        vk.IC[62] = Pairing.G1Point(
            162255504360078265593523612301610138673040298260980767565612583007365689662,
            20495122737189064346471904806891056583437400135227465393188353777161112225099
        );
        vk.IC[63] = Pairing.G1Point(
            8458676374304520114166166766821213451693437958848453085837804720081655761422,
            20982968048662091861495087901170383923555032679051626983607926792799613522765
        );
        vk.IC[64] = Pairing.G1Point(
            11590229159789711541089133153724044289012213803056200557914449847343344213552,
            10943990618349164767932391073125508027317187879563363689086267142642136221862
        );
        vk.IC[65] = Pairing.G1Point(
            1392708563732004225858358118718224453922735794229053516829293490407275315483,
            7547091966173510789468898511648197668443375525173437149929372332893949064017
        );
        vk.IC[66] = Pairing.G1Point(
            4613249346758698595705769876728666573933067450045453180144201931336515984722,
            9704281267943945593475945792186584750135871694565719001848752565677976468195
        );
        vk.IC[67] = Pairing.G1Point(
            21473649055364084771880512608368607913778479811266576669475708295520262392673,
            11005132221453134535096457619380446797833984079960039265548071678355859341126
        );
        vk.IC[68] = Pairing.G1Point(
            14272087071741575758972130511333016889294904477863331100034664492917175525808,
            4369915127820735642970675308199326741761700166307760684862532722814644727725
        );
        vk.IC[69] = Pairing.G1Point(
            11895849121155643466834931712480774153525916446103121541926104414607870946039,
            20021312068628366544877446567776889821334287893012613650176105803535221696775
        );
        vk.IC[70] = Pairing.G1Point(
            20938426143090271895021798579018888822498885800606758072324189709106381561347,
            7853260387394569988542621647017961028962935603965374538105022501409033900305
        );
        vk.IC[71] = Pairing.G1Point(
            14215292435962910333047892856403666252737681363062033526772430959401612265370,
            16123687317433118005594593546174183818052118036667132850924545264299212391726
        );
        vk.IC[72] = Pairing.G1Point(
            10439322445764358296352981322802207011999048249260910711205842539566893908554,
            1028532676882350398751858303213320612334809421582499311724171862283943143913
        );
        vk.IC[73] = Pairing.G1Point(
            11986362949242918230808037895808555804752930173735521789120742756610081653090,
            5070233614654827852026421479688353882240056150538681440698041258520288369329
        );
        vk.IC[74] = Pairing.G1Point(
            15532923033071801640800077264000062418274114092577013382692037395059043292456,
            15205783883710860368789419109825964674313176738760102715046803304369203243715
        );
        vk.IC[75] = Pairing.G1Point(
            9567028037929148960067599192247421092334642950337194569489909104573911598007,
            352855857028309597558689606885392923921274135394166973892809608234790146407
        );
        vk.IC[76] = Pairing.G1Point(
            14397036646099892750483344663375672984576866948482880031504165876637648082819,
            12047417468452407729752167150497073218796035368717267651437369779461012999790
        );
        vk.IC[77] = Pairing.G1Point(
            12747291054823435885757344508455039980679553744410040723551122165886549078313,
            5937232546555160996652528471214742032274021591847129978653778794129728350487
        );
        vk.IC[78] = Pairing.G1Point(
            21451652797787019181202260701104931602575232541091175908571767548162622480477,
            17561670400334387253660584388688714040192641154947952068197981101296012955119
        );
        vk.IC[79] = Pairing.G1Point(
            11554161749682365600129680410670654034601897433226424393215982517478281536956,
            2315048296795388158398778658488316268064420626582722526526127185297019895063
        );
        vk.IC[80] = Pairing.G1Point(
            5927171441412757668935727139669820269305443967445880321490676952082308460398,
            14506696039778438698139252684322255381050234375148249357722184304892461101773
        );
        vk.IC[81] = Pairing.G1Point(
            3786461711671592977927786904949637176789758332976100609664955356392661589477,
            12833095769115746065058269629291528639164374376492762113907263676366935102087
        );
        vk.IC[82] = Pairing.G1Point(
            12946639311436065133692893004938460427555512892534825244766906592892275168087,
            15258778334049999257713404974738705808218712383353242263575182317860305620763
        );
        vk.IC[83] = Pairing.G1Point(
            12024351235781609234935197514840506436407511031186383335057615227082827593949,
            19875499979935891317746760502815020393246244100400892660291760317974092758945
        );
        vk.IC[84] = Pairing.G1Point(
            142103905797581570454925868260447474050638936185835652538853937551014303950,
            1136562262368349430627183474801867201401953738652632787997687494544140849004
        );
        vk.IC[85] = Pairing.G1Point(
            17129421352038419329460474472109816806206569423584514036406858842665949938102,
            21517787435266001996018507514239606200862698294998350723010193843505718245107
        );
        vk.IC[86] = Pairing.G1Point(
            14543728562893000131960881317946633791826877774731085403117871282022132945192,
            17701201249821662979530510730456038948608907105804212192564648627312367454740
        );
        vk.IC[87] = Pairing.G1Point(
            21665430375034534263492650589113825675478859790099580987856347327628489278866,
            17906402195681911580508208966252236902358368571257178879592801561433662445354
        );
        vk.IC[88] = Pairing.G1Point(
            3826737955545949451835244980433944092512300422472631918217556763532309108191,
            1030796040279404903853241263149454316839657782658809234385973294049716733209
        );
        vk.IC[89] = Pairing.G1Point(
            12551943107661104389857044087524176024537767584314600000281649346330216570680,
            18814188408596519538476508844861273465437737435550243353337561584228617749118
        );
        vk.IC[90] = Pairing.G1Point(
            11016521761279765861736543493748455918908861423479501481439181107908109492010,
            11251030116924360426577499556017183643670050699432812852478678963482672306712
        );
        vk.IC[91] = Pairing.G1Point(
            2709949880697023508492990301462077852212132587030088183437745400245516307747,
            11772806435994483187938838863248855271632826172130489139894039720859376432908
        );
        vk.IC[92] = Pairing.G1Point(
            702023043080920916599804290043981145891678549069507709370287187047815028342,
            11519245170200656867194574626780258785848728368708579023850179683407924406554
        );
        vk.IC[93] = Pairing.G1Point(
            5530903696106184307454280847047228091822093690504770415997926167812036751406,
            17147359004395608909389867041083683260274236549479312906693378743099814502510
        );
        vk.IC[94] = Pairing.G1Point(
            263953439809309598531674167784999812028620932519406868574745253571458948537,
            13480808153402398120325978002907745212816224598230197499356648007669245953288
        );
        vk.IC[95] = Pairing.G1Point(
            3143925525698135698850759990264045740756987309728986808062585232734620620708,
            14378435496062859993860600110330448258664287991378870640364756358350218430007
        );
        vk.IC[96] = Pairing.G1Point(
            5103491276047305799051691315138911789635861932125099623557525215694369943098,
            19971055042712579387658147499943191619713355100129975111331192613884205818107
        );
        vk.IC[97] = Pairing.G1Point(
            9891393051465499571344712716262408615552247587847461511004243638926747926830,
            12193082722744758719034126520807894946817539881798247250332279471797042618199
        );
        vk.IC[98] = Pairing.G1Point(
            14697172919652128680698045075293683090143826937191965767126869439818900423143,
            1357149019228425674923332778627857617558350122828725222556013663652205508438
        );
        vk.IC[99] = Pairing.G1Point(
            14048819072321513197741457703403812868448999276759811770893168958631358012017,
            3913769971810841874407384071381016573143428309371747864157242954491618240678
        );
        vk.IC[100] = Pairing.G1Point(
            5849342789571721543189228885936077205434068440858462292973788167395565922626,
            13657084063072725209108764543723293644630143750120544059018483840445448909097
        );
        vk.IC[101] = Pairing.G1Point(
            6786634069635916237988727646153919647026662759258015654443803720154070149401,
            872605317898607529800565635839250433701068081443951702678763875462857170431
        );
        vk.IC[102] = Pairing.G1Point(
            10727226588594902389619271724948059239086085465035928418494634741787484983779,
            20709100730691674787147558895047495874191032257506768840773674130657277092642
        );
        vk.IC[103] = Pairing.G1Point(
            12556265490293309793609135673847566557164908465419261109584745465023250420499,
            194798180494678052944798391315233365201230041383551674282575140781872931326
        );
        vk.IC[104] = Pairing.G1Point(
            2647764137112883936741998662744573912429194006678868792053896059218193942653,
            16685445638304119825996270708299349414839386581309311200094156010471149931552
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool r) {
        require(input.length == 104);
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/verifiers/SwapVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;


contract SwapVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            1771803850637306749800466300966890222280039134550481730657648180471997291522,
            11800472751839748659650349358211532227099362921031879363430672904217981024437
        );
        vk.beta2 = Pairing.G2Point(
            [
                995215446090931096336940657631783902649485898595741265469025449931195839598,
                11363622625384518481727294294443424083008623795863829276653732336580356878886
            ],
            [
                19642873852370555374089051127429987351548805919898762685348579024777103959882,
                17735705485621792211387653759833854505887515847819815495130627208901820336926
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                19349779829153194097570750848983765563383251736588908074316912820720445213159,
                4787669940682051578187038525347110819282349667490377343788705293147841769979
            ],
            [
                11312640185541887820906893910429339071755896418430311259908543197139495054783,
                12570180307626840269748387153449693520312345938690283728908645240858575142402
            ]
        );
        vk.IC = new Pairing.G1Point[](106);
        vk.IC[0] = Pairing.G1Point(
            1361543409347031025713932581627647596070013354164564246868091481443406812112,
            3858884487857638790367711770716194965548783301668428915737143843047571857456
        );
        vk.IC[1] = Pairing.G1Point(
            9884947209691021990037147476914050591284758193127532785648128931611828308591,
            13330366004353762410471161090018961077924333507043739339222283559550162644289
        );
        vk.IC[2] = Pairing.G1Point(
            9119387953020989658470412385206490054834927258953291436698827718727586859562,
            6604060710151151121530621875453004486433423812435685864769177415789139705135
        );
        vk.IC[3] = Pairing.G1Point(
            2149254646927919556205948026412264243387970279361419379098338226242314989018,
            20875147394521037096156621687747207432585626139870390127580699825381204112074
        );
        vk.IC[4] = Pairing.G1Point(
            16591859234223688595560070741362064258643616175500337655174372809238064060125,
            490868634002324206410542189438788885718602354603674000916648093741856294878
        );
        vk.IC[5] = Pairing.G1Point(
            8122177742914498889072801425041010859312650387842918477808445518438223449044,
            10028918565966997177946106042713768127335603796735962190218797671101257929733
        );
        vk.IC[6] = Pairing.G1Point(
            1078430139241533321281809956122139611276317307649317995391362473943590321876,
            12402949989351070761957570739245051972613933504048462636577177087214537926181
        );
        vk.IC[7] = Pairing.G1Point(
            18045475798869577996798358302058900832048429768614295596287304885965426458514,
            19564323173816976418534046809213943156495549038440693321908357367491713861490
        );
        vk.IC[8] = Pairing.G1Point(
            4804241148325673339779396350935627546587506102393651051770536538196360694309,
            8575841792952683667656756559004420195608244068840221161586555642438824550213
        );
        vk.IC[9] = Pairing.G1Point(
            11479035136508850180402915623079395963939999789335049759507889184165810446530,
            20561945005537797640902771083236214956098502763598924408249000735146882168065
        );
        vk.IC[10] = Pairing.G1Point(
            18169598569762722678425562275829205951157696538981930145410757724331234328856,
            6865276931515740720275239768800480844357911191124769162167539812838924375466
        );
        vk.IC[11] = Pairing.G1Point(
            6368694875376832396292377411686561233867926779723272827343295360141926308210,
            16941927654163259462063777708904755171716204339674771441746637212645520250634
        );
        vk.IC[12] = Pairing.G1Point(
            1486127576029510036823744584800817720056240144311531900361414300814717403060,
            1648050241393282998619453743154153251268657032232260408487210937356045573207
        );
        vk.IC[13] = Pairing.G1Point(
            12166874407322466652914902787487836869067643214934174927497007200751697059745,
            20106967515964573508643987896663203356025945290457175734706957944053005982812
        );
        vk.IC[14] = Pairing.G1Point(
            19627968881495868545697154481971860706219883972429959623731815108177546140677,
            10282078994913395095743153383789186312771684278011485395069769352227354174892
        );
        vk.IC[15] = Pairing.G1Point(
            2806645566960016523288415414275732788327006628695120764437521050779293441486,
            16277041102183258165851967312613856341143293025724816403225124688439397926348
        );
        vk.IC[16] = Pairing.G1Point(
            7087801746213379360024396748383596147117132237091870753721516026337034538289,
            13395296791127258444469203395017368824710698105110261894919952608078519931988
        );
        vk.IC[17] = Pairing.G1Point(
            18603366021726915748963325440965365013005007099594724780275695897178137739522,
            8945973931014494131759165085395357480124141324933204747933657415428234924508
        );
        vk.IC[18] = Pairing.G1Point(
            13505539803125627806858355549570236539086857436006718282452591374109742651483,
            12182352339990046907078619881522462884621591773848671504407677494219686512029
        );
        vk.IC[19] = Pairing.G1Point(
            9950628286285988980870196814358596494145366307205835238212204924369064647969,
            10944489629760858349012439348116563212434509614613369574324645233706009638617
        );
        vk.IC[20] = Pairing.G1Point(
            17212981870706511344945077856561668940867117061636543422473315537686196161990,
            14386861016069554904483902061202395430620854635858125907645953669830893938231
        );
        vk.IC[21] = Pairing.G1Point(
            3597820866342771069480593131093823347918991435483052172790339300298000317621,
            21094497882312581514808381269914493130453398245255299605323457680953193517203
        );
        vk.IC[22] = Pairing.G1Point(
            14922004235848273324091314059066876074929422971443653459681503762687505353102,
            6355710975450684711164236376473767612959009214314646871353123859164603120854
        );
        vk.IC[23] = Pairing.G1Point(
            20972568903525154071590405007675105797859496759920447512228980800977712358583,
            6427431730764986126547418111250960132011075088906167844638067826274680161239
        );
        vk.IC[24] = Pairing.G1Point(
            10905221083820356089330772054507722909328575140652615636245920788886182323200,
            6526122621081530652597885059011054461790819625553459817728443063058968786628
        );
        vk.IC[25] = Pairing.G1Point(
            16884317565658420462095238412221552687719203950376875510941321642013863991590,
            5771917215206725109355007651792866863369498835524527242433565310924309305766
        );
        vk.IC[26] = Pairing.G1Point(
            20447788580829191544772507084636597645176212927822836821994279007555639655780,
            3008292723190192000385216108741491553163128909915055738629293140404946116921
        );
        vk.IC[27] = Pairing.G1Point(
            15020493249423635638632122218521139426309349330325357871506649747480942488890,
            6458775136664077695056794607038551355602597344496114741506459764171486822695
        );
        vk.IC[28] = Pairing.G1Point(
            7783326985774889921296394663654650611473227726362715803326255223160603745808,
            3787946339828349909828504743097004783719688024028064045109608434144306722475
        );
        vk.IC[29] = Pairing.G1Point(
            20538510843891565137536997063356251815209024051292075597702159596050723924143,
            13711006244904629988736440558334983448416163444549471717828185516303017608249
        );
        vk.IC[30] = Pairing.G1Point(
            5898433613339466281196724801656514497386299007746624836579648735637927716222,
            15920134795173396260126611699624734413367743060573907324370768944048754514112
        );
        vk.IC[31] = Pairing.G1Point(
            14792264264552987607926940238670707918325962370970826888804398040978560475411,
            4871906904402977646035687976696670791342144086084047717336456404125836200584
        );
        vk.IC[32] = Pairing.G1Point(
            6720889594997860035539205311168779890360185546564389841375717830073573311695,
            17007095955250663436298041411426899283747032995575209424112017196277138228178
        );
        vk.IC[33] = Pairing.G1Point(
            5900763188020696470882570950754010815849187538193036366087558362221292809626,
            7766417253001597524561549004519042886723469488685561194875160136276927858284
        );
        vk.IC[34] = Pairing.G1Point(
            12753102375734406908191826170346464235174437013651461786764610060722601102254,
            875352475041704862204472878136085525284231491584702924183657386333651517974
        );
        vk.IC[35] = Pairing.G1Point(
            12733160823264357112854017045817692310710696399573537325538946352453900827977,
            21033420531206594921913930528667613357591684407646995364266907457481944713317
        );
        vk.IC[36] = Pairing.G1Point(
            359724783136967873576322984101382611307080469880186979158593593309433454497,
            12940226066015714429482275106878613890070875224001052684328757616250067053775
        );
        vk.IC[37] = Pairing.G1Point(
            11114700255514323200676258487878074560395111130428809933338272355740064426772,
            1712007563326133846483586097807338966491262258042464152367791225133021442375
        );
        vk.IC[38] = Pairing.G1Point(
            18905853721792517201997400559133231185855342562046585520031832165876491418400,
            3408362477794992495461177247472464975029984945357719603616759914816481637471
        );
        vk.IC[39] = Pairing.G1Point(
            3882857916011582953513197703509627193454724385327514490410257221146897294150,
            7617428781302052013125984408418763458772247789941038269835328134903159572328
        );
        vk.IC[40] = Pairing.G1Point(
            1680462157159444658642758911667764165307951775237398964071746424319894225136,
            2512516438746799493777465585961011243917522071955512628423116240159653946100
        );
        vk.IC[41] = Pairing.G1Point(
            5010281375059826258024952368287604491688663225663276664552798478949479519652,
            2834192870235556348735349525656661373238513663195861266547281215696016196293
        );
        vk.IC[42] = Pairing.G1Point(
            18752998437696949146186294214172561861288490227392291643481807723592072944512,
            13213375887096712555531583650650794601273511268508249244329258026082283983656
        );
        vk.IC[43] = Pairing.G1Point(
            17941483262849150313483614698978923132270596518355548602532295364937763976643,
            12485215353396167808620298985942478624264062099007101523208053712591147815900
        );
        vk.IC[44] = Pairing.G1Point(
            10967838362087581563039318943437598301475216483288357863982167694454393068949,
            8017602372022934903364270810182580649808215446050397146826014512661554877181
        );
        vk.IC[45] = Pairing.G1Point(
            20697435683898284903249889173351024789238416828499449861413308421643862114081,
            14949056854794459078757809315405922332863969961956477534565774289061454387822
        );
        vk.IC[46] = Pairing.G1Point(
            5233095002636104843878968122863704851111792719884534124017801921952750386989,
            15824220062255472641137409601131981875076474891638512336578775913251764832227
        );
        vk.IC[47] = Pairing.G1Point(
            22799642713789053772756607165057165662366546126101566763312772934571770889,
            10759731534096006662827410986269459601317540679544825998122958193479371981985
        );
        vk.IC[48] = Pairing.G1Point(
            8200881315494758592636303720006285607794736677221820000345585377439100606970,
            3435328161713420127335271448545748010112990635037157493657180555693567009014
        );
        vk.IC[49] = Pairing.G1Point(
            14265905816222863186399766165639058542717160883904442449566521852971911304348,
            9441464075339309939935012060789074821583090385638659549138771820914869817698
        );
        vk.IC[50] = Pairing.G1Point(
            2544340143283839696575834115626920251166047475103938933075657753792154547889,
            13543841829438688219733460893893569897467170604967291810099223308470049228075
        );
        vk.IC[51] = Pairing.G1Point(
            3181123308228935040909987903710756796469273164240138770030911447747869041959,
            19764243651477136545853083065525251256419246056113726216833785716611657884400
        );
        vk.IC[52] = Pairing.G1Point(
            8441001549657513930254988844211194713139873616081324657228533487616281938478,
            1787880301881233158404634013658249019030956132958631907822510455381854965196
        );
        vk.IC[53] = Pairing.G1Point(
            20400409627114519805101562927009663979797297188660672127959556269628833163475,
            13191586843828445926732013708207123951952631822025630730026822723461741856088
        );
        vk.IC[54] = Pairing.G1Point(
            14895825198436935844665285711397221649917171399217353199990321195650830650172,
            21869469394701190904351028863114813267897105902031410225517409511718241678113
        );
        vk.IC[55] = Pairing.G1Point(
            2590738705604592584712863592400270598409298831317961608916251267924125281254,
            1119660559033013472721713602468221119024704555779657523342589771208666848738
        );
        vk.IC[56] = Pairing.G1Point(
            16045245082953629165588904002150084933000763465964941136671365390659051154940,
            1260926271734909322958867095992908683323671902342871306610790283323857295406
        );
        vk.IC[57] = Pairing.G1Point(
            13442632096755782441793087875230594830070645646946920187052530041881827310876,
            12061637284954372002911256761134761025589270206898984804657498882980040636734
        );
        vk.IC[58] = Pairing.G1Point(
            18600709018851720078738912315916415350364693380027256046396540273800454604527,
            14911751983685099882195252212156539383980022745165124528462076657039953549772
        );
        vk.IC[59] = Pairing.G1Point(
            13712721135941273770576320572850566241349504077104770065637148930438984906791,
            11229899169293631914576494678233895114231232708472451943005876265217798013103
        );
        vk.IC[60] = Pairing.G1Point(
            8820468164286892021158296376505128481625933868122081718123591685411440909740,
            9714470022989060928660184289244843722907888316691714947669216109530217452988
        );
        vk.IC[61] = Pairing.G1Point(
            10152494903781852069824831215815282454995293634341350870132252264296074688196,
            19297743392969074431410005778033522452050722262008311067358750201364120645071
        );
        vk.IC[62] = Pairing.G1Point(
            13130725154144286911602848960338497767661690834541295828378132114493301692962,
            9610372673534037972998838311041888657337982736409051246499597166801157902889
        );
        vk.IC[63] = Pairing.G1Point(
            20204753010451216204657054178586767202202055480080930556661122112578616568363,
            3506526676513335091397578479636690409350754307702894794076752910090312461064
        );
        vk.IC[64] = Pairing.G1Point(
            7972181706993890256602320274657288357061379179908991470617092727172120510694,
            10933263192960693627490301036708889206376466634856342424599840905456107328366
        );
        vk.IC[65] = Pairing.G1Point(
            21756950867455070647286324045893219273200149284085317954588474266735944210663,
            3510169293780464049507702999734868732529690494992240143447078341263164970289
        );
        vk.IC[66] = Pairing.G1Point(
            1173495954070454287049607462300717082835155693277169291376969040178122013005,
            20429883412636521083888450254573889054750665358039764045630887900672053898748
        );
        vk.IC[67] = Pairing.G1Point(
            12834306704647449789971515680871428012694410660107586938671313994749641841770,
            21614749369531664147353811137397810926338424395989042623419385116774532614243
        );
        vk.IC[68] = Pairing.G1Point(
            4675790979836791710777074197152502923644790272227122628115887439405620197081,
            1892279732674978444738326034889029457714073912708287506304265030286671502094
        );
        vk.IC[69] = Pairing.G1Point(
            1942903434261654008834895054690555628032442182588425257770179744232843780235,
            21005287123493289037960651313678885980395764128202142330863564725570166566261
        );
        vk.IC[70] = Pairing.G1Point(
            3625478837578781115455659249924899207639261900194575995337775125358830745441,
            20891888208994981350968627592979589549673533187270183771433155817492394352354
        );
        vk.IC[71] = Pairing.G1Point(
            9913826284478872334374770165473631486552229601543560469967368181832144826931,
            8909823490718924211124118533571016321393252957946973776014047579486916794675
        );
        vk.IC[72] = Pairing.G1Point(
            20322722753009164962520523688997345821211913252728715230598908926551146460361,
            6290721532629898670602581483089679528847862162971851938618931678548536651167
        );
        vk.IC[73] = Pairing.G1Point(
            20098113867039317769189477098202515970679151551916572877966587828280953199541,
            5428114016488094569531379081234655050371621434293725315754233134316491122876
        );
        vk.IC[74] = Pairing.G1Point(
            5892661926682365978326949497725520523441541886752455408113965033589267714067,
            9221738414395912522864485740417174555003911965703056065115670377410002326752
        );
        vk.IC[75] = Pairing.G1Point(
            10606639857782735478199651996491007531658845547256124584672901262371536648196,
            11781350775814549428208625793929041614793540813911278944967487249510125361946
        );
        vk.IC[76] = Pairing.G1Point(
            6951021823093196402842066884598338132278623207508392869400691947378906159456,
            21677182984562385278329878163275728105168379810394308744309535064376901959575
        );
        vk.IC[77] = Pairing.G1Point(
            21153565550078674126818080014786391025696840007103220917778003350122286524430,
            12729589833169540737796139260573493942270924637438997801581938601868176582569
        );
        vk.IC[78] = Pairing.G1Point(
            700391203575335236619321632022186851513715065986730746622755517606413951020,
            16297303881710860289788062150239704670481784294965404316666193387463059873646
        );
        vk.IC[79] = Pairing.G1Point(
            5607669696044718031908070717368147941383415277390147605239096276588589350758,
            2933345261623653775290708960793113919559231313945013642797509166686082915603
        );
        vk.IC[80] = Pairing.G1Point(
            3519513105023303384915730841369841128394551486284222853830489079599906956502,
            17912440500801560164710688717145077127148259667869246663754752196074415823163
        );
        vk.IC[81] = Pairing.G1Point(
            13240711607307865151577115748426302490183235927985514245845637159959712100788,
            7328697180450511291816888350932317008149241624051688008888771017549394227259
        );
        vk.IC[82] = Pairing.G1Point(
            9360953870591366930587055132638699425001213045515419027956682790893409064043,
            17721683900705486686300220391419100301313565936614116373428770099885642479163
        );
        vk.IC[83] = Pairing.G1Point(
            254965430428605145205589403334695227478530747026607168297950672317163771685,
            14701534854198031356445260733242294399386758745263139256412976705420012067801
        );
        vk.IC[84] = Pairing.G1Point(
            21623250375260945034683790422179480067813862262847830503289570938743148061003,
            19926649903771473178004159430638207736404188781206247307075841615373665771331
        );
        vk.IC[85] = Pairing.G1Point(
            15230488460528496835877440076146906117825692748611105609808372686695766065347,
            15937159526205577147010988903003623647955334991690279423868995128867433826262
        );
        vk.IC[86] = Pairing.G1Point(
            11795268135152095898933070652954576053641414859891399998322942615319709113785,
            11970107517099311732680862158958495018571407675239331201193461627655865060055
        );
        vk.IC[87] = Pairing.G1Point(
            3579506630607532815945700512485150286716343783916498324466051862671696940214,
            916720463240111513604127699476112195281983332735343295359306885203946181942
        );
        vk.IC[88] = Pairing.G1Point(
            12082296290635949366274004007649711915455981599553794521080002831391892831582,
            3355360151176028889154768279935913908781970404365782375424650261839382041167
        );
        vk.IC[89] = Pairing.G1Point(
            7451013605011293339480441112820903557716237894210303630132507673106688463479,
            16296755656773457598287211746293079210007607446689434658344377767410549664003
        );
        vk.IC[90] = Pairing.G1Point(
            8738458207763474699585873015674309218504584471188090484438099725032918976378,
            8870030311802268314061260044862963329539170862005292975481109944163311117607
        );
        vk.IC[91] = Pairing.G1Point(
            13203591103775310619480302515149391225353572802690687749897873419621986873470,
            3677437106937894755392795580048823679132493133243644269101745026931339776791
        );
        vk.IC[92] = Pairing.G1Point(
            28733610654502992587194858136534205096480968995064789379439865893519177666,
            3018104173909392351958587497814175989052808007217477165841899319293099565391
        );
        vk.IC[93] = Pairing.G1Point(
            2832818483542828184050256090262917373817539594456251162396331042822002933,
            12547862766873352341477097014700203099187110568962297807603778375330098532345
        );
        vk.IC[94] = Pairing.G1Point(
            46955762081940255103165711943957401845691706593211951137137165918781491417,
            20910403541682558098879926656149666970140005576419138577975489865203792310086
        );
        vk.IC[95] = Pairing.G1Point(
            12486846145994100883646024174014224634206432297414227059431582278649527767491,
            475506976211766291597733710665996532118608446105216532881164921510935338971
        );
        vk.IC[96] = Pairing.G1Point(
            21705531564898215554566826365082973996342395924250347678438362299121409910406,
            98712326790854487666643965264710939545321561522016062187442845273962107249
        );
        vk.IC[97] = Pairing.G1Point(
            3509942701244678005881271188847371109866313507577255418187555127089177114577,
            12082051435460430032413736047925844848887134621122290872565808167917911029111
        );
        vk.IC[98] = Pairing.G1Point(
            19183927226917567670243963437733987611002921372054087392102501844867934332477,
            4796576226699872995942978158755147263837072056442180988292232354959495525095
        );
        vk.IC[99] = Pairing.G1Point(
            2424686130627787037916684620153026002556174109683755253043295469932581298395,
            3092660629928560549936176445759824982912300975504916969407984846540091517273
        );
        vk.IC[100] = Pairing.G1Point(
            9661877295464914627727873426038860516753131106690211963154739509682710221093,
            19944521885819039191494630213065589536435492062375659889594051937026558214722
        );
        vk.IC[101] = Pairing.G1Point(
            17100931601953861983530999188436681428083347064302183870282538651276017739310,
            19852590522653489820376758109165101610300149551219470790685328842983374260027
        );
        vk.IC[102] = Pairing.G1Point(
            18388648758229527907491036540623882176718356334190537088698587960576280254789,
            19960756620975363317017103435035445121591224426239394779905749697927265784015
        );
        vk.IC[103] = Pairing.G1Point(
            7976483100235748088390984968381791192164452125736498295908669656324960534946,
            10318678308321439554694852034890062543943157227267277319134977725892336742795
        );
        vk.IC[104] = Pairing.G1Point(
            9729581851088884788899353941611591038285625394696365348109829199985360686071,
            16747920570030771052307060324806008999408376464967059469956651633196371596878
        );
        vk.IC[105] = Pairing.G1Point(
            681680173908387069146350702783396068306604808733576426496979174126533799099,
            18150793977161403947165641278590037820511068933156034176960857129512229834769
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool r) {
        require(input.length == 105);
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/verifiers/WithdrawVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;


contract WithdrawVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            1771803850637306749800466300966890222280039134550481730657648180471997291522,
            11800472751839748659650349358211532227099362921031879363430672904217981024437
        );
        vk.beta2 = Pairing.G2Point(
            [
                995215446090931096336940657631783902649485898595741265469025449931195839598,
                11363622625384518481727294294443424083008623795863829276653732336580356878886
            ],
            [
                19642873852370555374089051127429987351548805919898762685348579024777103959882,
                17735705485621792211387653759833854505887515847819815495130627208901820336926
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                13405164848439935328921348958804606809778700022299725361598750009754168054384,
                17968494511835339926555138442914488501147624112625554302166531536850801499437
            ],
            [
                16095537234891532589851146057032194367856746338904599148149193851777703910212,
                12687299438656266383930524834123297178498574079481138168216782085813151147110
            ]
        );
        vk.IC = new Pairing.G1Point[](107);
        vk.IC[0] = Pairing.G1Point(
            19349122439872066543138486808161410042199831543153471077256924789250202366218,
            946410956973128765194281167644570138989233088728989774952111840057968467094
        );
        vk.IC[1] = Pairing.G1Point(
            19660402691424177102257747776955455412779417767325655968328846679090491939020,
            5024591432624740040333451149175956621247519844944108692217091228350246794044
        );
        vk.IC[2] = Pairing.G1Point(
            15822482349929278771937788030482086745790243459428727797694835726867621067916,
            15953739587424595897280811890644877223994940401150490914078068607875664583692
        );
        vk.IC[3] = Pairing.G1Point(
            11987283154369719843535607175679100632255609707317285313845290621118181945254,
            5171154599427692996560026314684902385888934930213900032727700167836946980142
        );
        vk.IC[4] = Pairing.G1Point(
            11610293050189643501719117803559206638348535288210767024919202775105221784251,
            14372284370630008916286298857302204055102407695536412882207993331614592028180
        );
        vk.IC[5] = Pairing.G1Point(
            14380617165349494921506527382058353800266249697314237128989796630663076322764,
            19950172083613499821110089956785981453269694216130924125961805898379016803500
        );
        vk.IC[6] = Pairing.G1Point(
            14552614105818679996854193984345227007749156946588090911463101930900627732558,
            5310770390240448760978246445112627584347063176891461031440075389161472740630
        );
        vk.IC[7] = Pairing.G1Point(
            7114056533031100259201695238546816719151623403003669323074600957967048015171,
            3375155295576200338357694300203405958497225314542538503699724373996060209404
        );
        vk.IC[8] = Pairing.G1Point(
            12655189527661584477070678267141934467967779102733246068247828215760390283621,
            16610671262161332604897723686755064398984473104771987404496734283496088631596
        );
        vk.IC[9] = Pairing.G1Point(
            10043201157679778798465289681059985726498183530949279000275990141337181304737,
            4796096212388342675104359279116165772636986136114390339948874943595628803265
        );
        vk.IC[10] = Pairing.G1Point(
            21436650385855500783347169258838911539517144476376410594834098677324828521770,
            10785125526730393961709301251196821085540828320097207342565954699775027120085
        );
        vk.IC[11] = Pairing.G1Point(
            12026598169933308623087649664233861186579944767708957036215546479917222062059,
            5534688655423646009183628355702467389764126471378302423794511958746510011136
        );
        vk.IC[12] = Pairing.G1Point(
            1800111341319678310923248702657298910019673690428424639592452096361140833487,
            18797892189670474925120861336605508293873096890974981933837029304020882029903
        );
        vk.IC[13] = Pairing.G1Point(
            21738253334500519230849982544423111347599950834160508179674529530155364025441,
            5076650431980236896608638104522976150811639355221743301324565321011291974267
        );
        vk.IC[14] = Pairing.G1Point(
            260423596311824077610786731756905082748404969471004671278380179289971997721,
            4060561112742168002458795987843633061652393153832046825552502007773427501391
        );
        vk.IC[15] = Pairing.G1Point(
            19193447566434755162118719355925885247309505497445075025307227497067172734926,
            19657550461131958830659882478204044817138340629260396676404432357928987671821
        );
        vk.IC[16] = Pairing.G1Point(
            4154253364699153529776273302531053568037198447806501139853554584490322264619,
            19000167253015077827805179334835838060882177075259675933803211268647820035291
        );
        vk.IC[17] = Pairing.G1Point(
            17924336596096193237121992630874492502264099240807164793922133089520825012913,
            18013051042794697425789148192609843197141332040909529713191855661013517154484
        );
        vk.IC[18] = Pairing.G1Point(
            14727055023728890598131646693148573811879132189179018058964957801320319123226,
            9475170431143862111694270228146132356960143749444257860444102309075483984180
        );
        vk.IC[19] = Pairing.G1Point(
            6084214538701089472263143248838812591762107393061052846757500830067838690969,
            4633680499010189819131029204104510007715327661374966019269400211220713394550
        );
        vk.IC[20] = Pairing.G1Point(
            16631637541821479881515000640979261725662386986486597853079800613557623828920,
            7801992340174225671832824671342778845208919584738699092483109455003449022766
        );
        vk.IC[21] = Pairing.G1Point(
            14581460475149574567414085414384898332901719762006414483837546989268329307350,
            2725930060523669590341529220695183668143800146676271271574795671054598200863
        );
        vk.IC[22] = Pairing.G1Point(
            17075308287637750926241871937504366830415023914830796655576470936888768896870,
            4152189321764827769097101682191333867166377001714376613761121163016517365541
        );
        vk.IC[23] = Pairing.G1Point(
            6527664217151204022987318173574600588217977577128471607870358818849945194846,
            4052938218568840100897881093649076336241674560858831561840396564608264236332
        );
        vk.IC[24] = Pairing.G1Point(
            21354081710583396441978985753808496399192478486627201969472331775006347906892,
            2442483104721487643084104526749530100381353472692870278150285908495653650138
        );
        vk.IC[25] = Pairing.G1Point(
            13431744211234067371032791286726664976860567610983342634059098868610947692475,
            17161273797428395086035824758777351636129767435753521801456884432255966615722
        );
        vk.IC[26] = Pairing.G1Point(
            14218119220650493630393044329893047763875623493352091148905104509302562891532,
            1448586346067011051087327492381150988429143550250524644146381377677581931573
        );
        vk.IC[27] = Pairing.G1Point(
            15043729164200608098647336316149403642457725798700853532754652782651578237815,
            19601918548563489121386042735835852310632464822631060611699313727030236414333
        );
        vk.IC[28] = Pairing.G1Point(
            9828363595131071098221770638482023895598006624123604378051696153869829035312,
            5645009980817947036998598662045959803271136330106550936937303080150612590460
        );
        vk.IC[29] = Pairing.G1Point(
            3838629009910243041103541860804229438761489655452899632868293575647346001227,
            1682849060793441668333099843369554022997190016529692872570612222123415947867
        );
        vk.IC[30] = Pairing.G1Point(
            11263672241719461236813845214302483359523724262816976677665386567877600724724,
            7284417993802721484630725181843429246182849211593279330005360381876668429286
        );
        vk.IC[31] = Pairing.G1Point(
            17456390386082223169455087586411308257163373731341082868921315993279406694069,
            1936846315177505014251041531278980793389686195917673139622963637376602510747
        );
        vk.IC[32] = Pairing.G1Point(
            11971930712865923849784223523451854171921197315057025146602152310138952135634,
            1921709727105135075848649847068407248645534832920103713540484520911837443898
        );
        vk.IC[33] = Pairing.G1Point(
            6157751816646349824878689023512806219460553656909745998484013202566024010945,
            18497415994095369283221515313851825603054546425483836193360577334926931498730
        );
        vk.IC[34] = Pairing.G1Point(
            14039662556147661816247347363008252953438747008159670319404917432707470139844,
            9179718982162561940555759359903233146428801013656887899360571739401317520348
        );
        vk.IC[35] = Pairing.G1Point(
            635825345078676514584368732540246852235596941655917907618273592332511935592,
            14726709912960064529417237697548078919747680538312891774208223553502985109727
        );
        vk.IC[36] = Pairing.G1Point(
            8706119786676051251740914039943336507768602289638212885788129216785109383169,
            2183137385021868937224812248626894312013089961120113902412941198793770467427
        );
        vk.IC[37] = Pairing.G1Point(
            8153415578664693847515053488760165164693713945721691592600538778491858856181,
            16867628095308362651313168602546469673309469459438228295765139380225846188270
        );
        vk.IC[38] = Pairing.G1Point(
            15988723553720125540213593838826025164984190112415403240953412437422385587354,
            6940054195471022432363103022518497881553974570576894927328944294032719632262
        );
        vk.IC[39] = Pairing.G1Point(
            1613049386380824492063482301554735879472777539965296044090853205555987066886,
            14245961797120991123305174856721449034948547639299856669965638114125997839334
        );
        vk.IC[40] = Pairing.G1Point(
            15535058915410226295249867309983873963343322476716775987155519882794820095152,
            17205250309147139298278071193033834486021612753041350475529466650273539636568
        );
        vk.IC[41] = Pairing.G1Point(
            12661130000607346348716974206703019414510677540330130628554862190207060835100,
            16030381980835759371524054744414098310272247908531556195564119435919801231690
        );
        vk.IC[42] = Pairing.G1Point(
            11544803153612079257383818220556927443266742839361621947257117627280483849296,
            17802724452024541594807354898685067230119718633567496538658524352327510837031
        );
        vk.IC[43] = Pairing.G1Point(
            1257184936206130897926717436989660596567008319285874363913933702387057738160,
            20296237943681920230260908880026556020147742424155258261305786685984356096180
        );
        vk.IC[44] = Pairing.G1Point(
            18697064893121825881894944059164771307145133007657639714175135655898678925812,
            16336054108968334887744301715915526954044905064926047043425451096810371044966
        );
        vk.IC[45] = Pairing.G1Point(
            18880764041520633992857817421406855330403293750797422194329464706603351305231,
            676457887270477963394669837289178846664954965402281812694443039981690949396
        );
        vk.IC[46] = Pairing.G1Point(
            19982315433048352025536053970587722315302181152018594640399574958702698185043,
            7769505796690036433469967708169863282122297499107417705833541690903034438760
        );
        vk.IC[47] = Pairing.G1Point(
            3951582142797184059071197221509978781702039536961693410601510455671595860030,
            10088634507012437285839131401593868552467143042778846692490959451699214110493
        );
        vk.IC[48] = Pairing.G1Point(
            3601339179351682405183439622509303935047706596837045369158810421728564002991,
            19630026032402682316106112933322100919687958947795679801598220584791514103305
        );
        vk.IC[49] = Pairing.G1Point(
            15801168196133284475580651622828724336677611069113393800143969493583599627732,
            8138833280941670877192195275388639420059794563561675885198269199341397069474
        );
        vk.IC[50] = Pairing.G1Point(
            4048233726590600406944855781679442088928143427008453351670172788299434283201,
            20274412294522812873162142831887955979829224856865717536773034614689365987385
        );
        vk.IC[51] = Pairing.G1Point(
            374012545604591820227329040541597895992512468743954517373714884619542709929,
            380619237045925660419904436543336161691874995333557758993832301188185881804
        );
        vk.IC[52] = Pairing.G1Point(
            2443002921523724639218325106200875158346293550186666796019924391564207303028,
            21507135713209600303917757745816036311644946447522783151410080847512337343662
        );
        vk.IC[53] = Pairing.G1Point(
            20916540527067004314523768893602700234180600286603424809033196178685663974699,
            20081714325246346999024027221292109682393792598730182504652338166620620681411
        );
        vk.IC[54] = Pairing.G1Point(
            21353498713935171003984475512049178363767269828924469756754066891146323323613,
            14160460740919640157714602048700805432732673007193732508580528590456721492774
        );
        vk.IC[55] = Pairing.G1Point(
            6771905979945749615917826528296454468855790955249620771775591799398246446554,
            18595217049865201470001253361278082617294937371647224756372933602622784379985
        );
        vk.IC[56] = Pairing.G1Point(
            7178626447263016089438706013974645855825774372795890152286167460076046845051,
            4175109742158092857855508348158088863954009598038519042862224028686890192670
        );
        vk.IC[57] = Pairing.G1Point(
            21527709343198049038471919855714751673254852130598476275017023460665006463297,
            16096721258851458246676983590103602855890351850609696554491781079273399856485
        );
        vk.IC[58] = Pairing.G1Point(
            10381249318236923208858223276754428292490376557222569091198473167452124415847,
            5856337200327777187410270188194761960836199442408616212088050367548379764356
        );
        vk.IC[59] = Pairing.G1Point(
            6740486919766891029052705971398506930248825005630299260080605642170259107138,
            12396971509115256739901872995664200605143455120131091727841863695077779284794
        );
        vk.IC[60] = Pairing.G1Point(
            1994798788606162065347111272333313336140884819493784326886012235494314184807,
            5145504354096699749465851900800073127569650119213355871630940481894354633639
        );
        vk.IC[61] = Pairing.G1Point(
            7683148536466579362558650429219768031315788788807454634120548480206557597374,
            20905129373752433381404306991006911581760141383151718622062058864720676045396
        );
        vk.IC[62] = Pairing.G1Point(
            10040750051520907372507706679611486829368867847974776985382291585631019161462,
            4885651823241581587690379727848969853606417689288234118935177646378917088753
        );
        vk.IC[63] = Pairing.G1Point(
            13977982891014843826371096281851819817016286239362550496224859783574261017544,
            4148199312881208494604202708587196126954638861324844229442156120011848676212
        );
        vk.IC[64] = Pairing.G1Point(
            16984715332213073118995352966473006096166223937542455460922429412992480492183,
            226093796715818114929179376172302541906718428870012736324762538350380912997
        );
        vk.IC[65] = Pairing.G1Point(
            12757524597827366400545477336950222680500835584286276291718540355686011609918,
            20933199661648172885574547457690095883354515263042156591567597894604201773382
        );
        vk.IC[66] = Pairing.G1Point(
            8913851458094091256453199698192923892330561063544106077762718715919652868438,
            16408651286857139471369632394077056163010741335650016022197471899959884682849
        );
        vk.IC[67] = Pairing.G1Point(
            8101157861618441782214666829747280258742013507509514422117190060774560251155,
            18883876667940000497085051516291859163220766622147520139596139662227551587384
        );
        vk.IC[68] = Pairing.G1Point(
            2302882056887445010936773202914593431302085415719966638119029186815454623469,
            14206921004514630745911828917996185144737082504322696549695037013397170831077
        );
        vk.IC[69] = Pairing.G1Point(
            6449626343332113977154752729168149377757525025339164815706664529530737709812,
            18749748957925215842172849573441166320658180853118222988950456874198946753480
        );
        vk.IC[70] = Pairing.G1Point(
            7737666051027294869431034502306932821710576932638330597338201127474376204646,
            15337166699884430614908788022504186514410556809614682932088198999339930255003
        );
        vk.IC[71] = Pairing.G1Point(
            4751511326598645023297422421301965599388230827313156889052524744443717461899,
            6169813183179027899969269002937902106348411347802548299855988995678699355686
        );
        vk.IC[72] = Pairing.G1Point(
            1892336617657657957504580326319509466752351335389598507525916018577011214902,
            20297236191003800259459616371875473822191631136126929258116332595135941503968
        );
        vk.IC[73] = Pairing.G1Point(
            6060384147558809399193950489178564995693048238191186044281989624687930421058,
            20054844884133037779295240038719350678184187229051092499203611146972597106198
        );
        vk.IC[74] = Pairing.G1Point(
            19059885051440370849928272323067513207745380425374438347739450331198892598134,
            3196654081046128327082666042905714697064521408886752689439786501623522481904
        );
        vk.IC[75] = Pairing.G1Point(
            17019632765017582369423749459687950222616005013739996521325321508271448222334,
            20403764408989527957139697467718697885345441115377839969473370870998143208209
        );
        vk.IC[76] = Pairing.G1Point(
            3054196097086954979491837473834635944277808420949739445192846986366504159337,
            12535434708236488567247879382318422410011966449384911066561636397453200218302
        );
        vk.IC[77] = Pairing.G1Point(
            6453198411628016200643403381908941546101709360940376604760722012864621689683,
            14760529612596360989145341504187951597718303516193586054236733166853465323240
        );
        vk.IC[78] = Pairing.G1Point(
            5782315673849963894134020089423248581027509560163405459478079866552815528892,
            955487421426564445658791086645945763568977601381598817411543552112514390225
        );
        vk.IC[79] = Pairing.G1Point(
            16195459621014688381093803069846734840072448562853645552080967486439328998772,
            6094841910360455444041935397644906848649828787004819404435031977405530779595
        );
        vk.IC[80] = Pairing.G1Point(
            4049327342246787019678970814407546350647776518271447779153582761408350786719,
            14891837447453264398384751756735198754913358592083167145141558956991380246316
        );
        vk.IC[81] = Pairing.G1Point(
            15209113944798595972009762026742321623990720685096103402602174651059165105960,
            10896033541938285949022907718508649969101963969572247404204188688645499253218
        );
        vk.IC[82] = Pairing.G1Point(
            4002018558962340967535711369854620305571591232788999608511912929013494970112,
            949016576952571814760522179415016952044492825923418791317300498964106102737
        );
        vk.IC[83] = Pairing.G1Point(
            2797373956846563339191786037596176113875162219122245289259095773381571093800,
            14507400671600182312348375965844429030993223935394776277927362282556025365698
        );
        vk.IC[84] = Pairing.G1Point(
            2861426930750446191839808423283213923016726563170938304197970417041120504438,
            8002429575452141822611702458907700833513743865837707503619146430873032541991
        );
        vk.IC[85] = Pairing.G1Point(
            2437025381201629998903640669461622986032662645213272028143341867484968868525,
            3599058902496747739909157870200495378642807124129849960768365674736224686066
        );
        vk.IC[86] = Pairing.G1Point(
            10584572880098660778827012698737189214434598607230736575985906303643602892018,
            4146953823436497456467775425148459667103093555206026371248246778303310249186
        );
        vk.IC[87] = Pairing.G1Point(
            18243665577081791962973595751140286027355799707589470193644141890613874957300,
            1994758305902240181471396349867229199093332248339092095987821751183134146021
        );
        vk.IC[88] = Pairing.G1Point(
            16865868992067369953981434903246931272652105089797408570107616775457302517365,
            14841520508571443132358138296153741598659169718473768909727213736118049501232
        );
        vk.IC[89] = Pairing.G1Point(
            7917356409523465287560447100162346743359295364055315779294285571593871245158,
            18875705656212944805537951142011802143516551248731664923144837709466938210409
        );
        vk.IC[90] = Pairing.G1Point(
            12490906445413602001864404465043417424002723961958669901418661435591133307162,
            7751352715076692239400045041989174517823274696283993987333478007696332247365
        );
        vk.IC[91] = Pairing.G1Point(
            20905176275553067688082472615286032861495126876816242482082605085029829140597,
            7803471958429630196013912876659152912781787811884621144369289617793458027498
        );
        vk.IC[92] = Pairing.G1Point(
            10708879299244167978576647481626841258385998923321689077549461439666611191894,
            12911793126425061341619170663194017100269185310832161594396202662377749846503
        );
        vk.IC[93] = Pairing.G1Point(
            10300555319764158140979214715630541711568771900233952677533129067313623950540,
            14331540223113631137455496702876937149376281255501613400667263746412563035436
        );
        vk.IC[94] = Pairing.G1Point(
            5702820805656768109569498900844251811118784695705192130999111631512499395428,
            9801839013613502735883783600336403601041780102118232291298437293508802642042
        );
        vk.IC[95] = Pairing.G1Point(
            16395870322339902096083496135976821362861792447708816485733273044024883144103,
            13523111499004896898067822737690120802874424204919314355996812603069829883774
        );
        vk.IC[96] = Pairing.G1Point(
            7046217861259284547053100304377282264029607485308427872821609106328977593929,
            18573382040814841555055745085898301567861411350432349556257523661122095407931
        );
        vk.IC[97] = Pairing.G1Point(
            16849085585021362112702038381413998048117364711996265340172515046256420805144,
            4769682695766015835766492615568277498152493476227295613328389670944911909363
        );
        vk.IC[98] = Pairing.G1Point(
            17697902107767186441693982422585643913536673690962857282164220734038968147217,
            6664808165392769375635164714806475732673268416287314626031940199783266218015
        );
        vk.IC[99] = Pairing.G1Point(
            20082315446325248746222565357530135495083351256478356987668997142003284921958,
            1377338708636947877445142049931305346709187119996897792536155954521416773989
        );
        vk.IC[100] = Pairing.G1Point(
            8133177270366191966058657057345162708755024507626683339736363332662349387179,
            11443097855059829055233242163942174842382824747446649303026656178475106975732
        );
        vk.IC[101] = Pairing.G1Point(
            3936602229132115738487625487929942746401175875443562691895083479118688216617,
            20703988983383416545770717254314023618501781499541059548687449195802322506530
        );
        vk.IC[102] = Pairing.G1Point(
            21835279409368140834624635445767470661896045696864962423277769119904303540840,
            9137152821979831819629449213916383400391928358263932922573518008335252899912
        );
        vk.IC[103] = Pairing.G1Point(
            18411276607878572539282294327207705199622007516147803532489052030535953437031,
            1480170066037832033982494249720086579966785421428847280547076907755005218213
        );
        vk.IC[104] = Pairing.G1Point(
            235414009048956452554354545704361166112312567614761798923871106136710037073,
            3474325101023281844854465705547518663569949985541335832961248233786144160273
        );
        vk.IC[105] = Pairing.G1Point(
            5072924594141692610574577123807988626568154915466449403275249114444663245183,
            19061469222989335635361368182860023340637645006040641363325974358354291511022
        );
        vk.IC[106] = Pairing.G1Point(
            6024633247182300528494222626729747402704414326348299684836564916261038867611,
            18540845511876008092691065967490035128439085627462741113198123443327875617294
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool r) {
        require(input.length == 106);
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/verifiers/DropWalletVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;


contract DropWalletVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            1771803850637306749800466300966890222280039134550481730657648180471997291522,
            11800472751839748659650349358211532227099362921031879363430672904217981024437
        );
        vk.beta2 = Pairing.G2Point(
            [
                995215446090931096336940657631783902649485898595741265469025449931195839598,
                11363622625384518481727294294443424083008623795863829276653732336580356878886
            ],
            [
                19642873852370555374089051127429987351548805919898762685348579024777103959882,
                17735705485621792211387653759833854505887515847819815495130627208901820336926
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                8093806760460880683445845246184998553016619650921431428030373553874171121928,
                1809002014744055115962576646705164749807084790312375694603043237563430832763
            ],
            [
                5516716752885854945336315242840816922509282263622383823291439026243782489034,
                4961640405518572135207600555718601702054265343467077836896183137595738047297
            ]
        );
        vk.IC = new Pairing.G1Point[](105);
        vk.IC[0] = Pairing.G1Point(
            2392630521739057991015410467410187129637215568565979502514067616695685548446,
            12464379130311462781613823401104737818519469902689688325777307005950719570513
        );
        vk.IC[1] = Pairing.G1Point(
            6463257369549689612573806590586582457483296589421220964793843876317405514478,
            1508875689320408784679429103094694089696438074750994035198801064042744880780
        );
        vk.IC[2] = Pairing.G1Point(
            9191957177547624702408865346481412655629219100809508164795255996721655763735,
            2916822253982915633487941267885464582484016036277140027799288149530158839082
        );
        vk.IC[3] = Pairing.G1Point(
            4250281862584438626833940921245303146508629854989019927860058562532038766665,
            20541668848445692185873529325608529089680224877200055116801793318347826727556
        );
        vk.IC[4] = Pairing.G1Point(
            8499637772006331417498601942921386331801689295166178077054428554775463625455,
            11256883345328512117926967469272802918482877619559987591823684268891814860701
        );
        vk.IC[5] = Pairing.G1Point(
            11128089786066950386065492522932914200634758680198298871872777568027952856986,
            4073587221302034350869222938115574271669783735404023792469240302506878119535
        );
        vk.IC[6] = Pairing.G1Point(
            10817220910652258135631037276582545677856947300733680843961718736470576518707,
            2072752248939341801426422829972139207311816762517744238324545369712719527346
        );
        vk.IC[7] = Pairing.G1Point(
            20394611018038562166632447015823029155399247322456181978711109826359592600959,
            3868228775175686332560821061083200169824108254088295702645494314342144275943
        );
        vk.IC[8] = Pairing.G1Point(
            18927790729503986598314197649220856809238180412172730640289767746023302661158,
            11454188298095223029539527883254326446301488832458651560845327277250982830986
        );
        vk.IC[9] = Pairing.G1Point(
            19253984242266627844330620278093688501668773483284913329518392930642813575412,
            14942685995335129910359410369919540613098620161160265420916934095349261161287
        );
        vk.IC[10] = Pairing.G1Point(
            19617058073382533842414566453619616324435964536298864236343526028352000701550,
            5802255059204544155688710241163018808669263431549232979131313376612843267677
        );
        vk.IC[11] = Pairing.G1Point(
            17761820983779641899331506560329117643014823568814563557281539493518810329415,
            2901313212801777266127881633384686848945971815645474485400738657222792888340
        );
        vk.IC[12] = Pairing.G1Point(
            3013806197737450446477750162827159282453345562793126439916368978305242721173,
            20914361204398875496973604445996845733074658997476410180253244770178872032874
        );
        vk.IC[13] = Pairing.G1Point(
            1377679401024376065311498113642083200296860346396066870578193188774153870095,
            4199722831306682342792639258538470515157611293155455812577967648141279502120
        );
        vk.IC[14] = Pairing.G1Point(
            4439596571947179705947065762975184335708571897801129490363189485909149252630,
            3225782089809717189408991763589930624763002494713219453137970375556398092745
        );
        vk.IC[15] = Pairing.G1Point(
            15467291338686243397151965297324793303310616863278123594644260796418950497301,
            4750109946482311790388800973641435560236279329465718280420133604898486301789
        );
        vk.IC[16] = Pairing.G1Point(
            14659487940980642682448178864709353471288345117367326453471501339746697610120,
            10300367634831854872307756961904991496586519272416936445675016760331702114689
        );
        vk.IC[17] = Pairing.G1Point(
            7267682471617109141601406445007997289752043777031046896339262075225279585783,
            10504074673382735445750391949353236603375441301362916332669364809546098214173
        );
        vk.IC[18] = Pairing.G1Point(
            12124858645307136302974845119650271091288485450596848542819832491694725288813,
            143347749944078833192071361720841335171973097075444273275865787984630039197
        );
        vk.IC[19] = Pairing.G1Point(
            17635192305811966062974828783874965293500082739636202951626784488063783383159,
            1020080987529632500615168661322135359289115744259657528798241151823108686595
        );
        vk.IC[20] = Pairing.G1Point(
            6486940420008163693970919475124060939682875508337283333644214245355179473290,
            13399536704973022306016486552013422122951202636109237825868694440362732662834
        );
        vk.IC[21] = Pairing.G1Point(
            15262438083746661660987008171039778299805188962490532071507570227139067325830,
            3403230713978727239482854892337044742023689763542514896569140308413973207164
        );
        vk.IC[22] = Pairing.G1Point(
            3534364912875205686786936316864047963505058584854964721727451096490764203231,
            9116925393087754863135917932562555795504012379422709234164548665269246094153
        );
        vk.IC[23] = Pairing.G1Point(
            10681684466469438280729882566818033228354986903776488901885398068065504214103,
            1080868051383572428459614323626579217103788226325992956151262603719209779460
        );
        vk.IC[24] = Pairing.G1Point(
            736962300737676567003039784000289530552368196525013343311211768730749568157,
            1747495036734170537904917762061896145543955896248291723179059528558395295111
        );
        vk.IC[25] = Pairing.G1Point(
            3613369123913252737198473792136794617236153103037237877398849372078896079776,
            10487579952889910642854132062759999541344344924260550004062475556823070403067
        );
        vk.IC[26] = Pairing.G1Point(
            426085310942756331788356280339216505693907390309611380699834604449854823390,
            2001035444039663638559399235375217266617183283871885429846894696611009184881
        );
        vk.IC[27] = Pairing.G1Point(
            3806473388375654110404659059818191447648136508197869290180051499879837939456,
            459589680055945942699901307681103404755695942969631401706170203996112827037
        );
        vk.IC[28] = Pairing.G1Point(
            13843988985749605562787593487686093831052229549411845619930482570475863399578,
            3274597785565181307343546852914785688891511920191037986663017112720935001994
        );
        vk.IC[29] = Pairing.G1Point(
            17662651952943449661301137015060946886993554506241307957694444792554311697427,
            21482487571310053109682416622657978681544730045855011221799108841275606597044
        );
        vk.IC[30] = Pairing.G1Point(
            16143248479430498370557519779807052385939395708357330517421354401877917690162,
            21354868553315171136216692793007028011081223071464099131288160087521506852328
        );
        vk.IC[31] = Pairing.G1Point(
            1990493807051014904169222532524173853307333328075434213755532456208218175217,
            1490431314873034515562792486542640415678028373427138109513905613751530120623
        );
        vk.IC[32] = Pairing.G1Point(
            21442847685138812261839385273845932270566571820489709709969974481707199238757,
            12833446470319924261365440286177499760783708530111717079508668877056703661206
        );
        vk.IC[33] = Pairing.G1Point(
            1788513982674890243126802236771457706855058858610932673492813469626974158679,
            14247512890822128857348481576400212841614326306516599531710516071864456489779
        );
        vk.IC[34] = Pairing.G1Point(
            21769493836025989637504139825147234868787380013534004843106271640669133182004,
            15799347455733427892931583435058082303661546866389729838472425108734992204046
        );
        vk.IC[35] = Pairing.G1Point(
            14517887902629113816055325476798646413932149548364537064026597893238248408799,
            7580182249048326392468443902537063656792482912371218562692948123476039975647
        );
        vk.IC[36] = Pairing.G1Point(
            14372264805561486323578640681513364809552762908636297395027842597203106454944,
            805099726491407210389654639239619983084423120723044629446393616866211035214
        );
        vk.IC[37] = Pairing.G1Point(
            1138831931207873349752821194542003051511482041768075947003293006273910151908,
            20259195920829197765010695018007068813407825064366553514643640295266625302781
        );
        vk.IC[38] = Pairing.G1Point(
            11387884404813443066340540668258371348095962053185266977873628953510996770293,
            17408318572489585139447881759560396826691374530484163438446519478708824690039
        );
        vk.IC[39] = Pairing.G1Point(
            3584756930911360514601978182848829263289356733537286654873072741026428103387,
            945163029161077789493835802836581495074766550408602271128747062859450603146
        );
        vk.IC[40] = Pairing.G1Point(
            18649238257006537987542535317271288685360235431597501915872794282527008594783,
            10172513620313309092686204284873466074473413172205151906892913071207406660949
        );
        vk.IC[41] = Pairing.G1Point(
            8972650830468096014394783980997478194132998397098766249165500208785898872164,
            4313048095643425365870415466431418770563784026825438772880781197617575171777
        );
        vk.IC[42] = Pairing.G1Point(
            2190462729547735239336776300465048693210627461071799855538057378177414594939,
            20782799061968551673598527741842622976681626259333015867900890772390510595342
        );
        vk.IC[43] = Pairing.G1Point(
            3776242855128623786215153128059642995743934325709312373485347882990836268672,
            2889958421100662418440697561443595100354307199854070849989184199872895262943
        );
        vk.IC[44] = Pairing.G1Point(
            5184932440846900487390164786047633067278688215030281898770591671006947106373,
            10048404052224025885261949543336019371515435871580138916857835990039687135452
        );
        vk.IC[45] = Pairing.G1Point(
            18611605059659352841088932335591182544535486236338156793913424311848250218522,
            16725551965075584226331772401342763602909702694458473423441381806883527754153
        );
        vk.IC[46] = Pairing.G1Point(
            3665538233823415313283581807631528103944022217885618038478058565962351223457,
            8985019756849375392651810048555472308397156477985390298612053505418626654442
        );
        vk.IC[47] = Pairing.G1Point(
            7403167162170034368785495748758271343354385120109283242921575633203153067335,
            20623888837551830195881791328065957309355037256972852652118610984521023275299
        );
        vk.IC[48] = Pairing.G1Point(
            6737598357564572897806775719620980427461210702202168854798272992085374930060,
            667407253301476522718621888010274981595648894160806974051879962910316306911
        );
        vk.IC[49] = Pairing.G1Point(
            5575919321821159721439210658526882873466753278601050484531981206107003515984,
            19745530151771232661719475083917700862170937583576116118176950185755691849143
        );
        vk.IC[50] = Pairing.G1Point(
            11359342590571817077047834895220245356674320287091784884440506056518172211492,
            14070759496109247619304848479308270405369603492291342935451065111964062253559
        );
        vk.IC[51] = Pairing.G1Point(
            18124206032314653629876774516899170667045888410190224022189530970633209520033,
            9259518527690048569808566585804126745368026763446124820786676746855699451300
        );
        vk.IC[52] = Pairing.G1Point(
            4112317109038159166976292126902799427116265365172980677645037268403988006845,
            8585699396763368184546008458572077016055419384145742786201192241564410526321
        );
        vk.IC[53] = Pairing.G1Point(
            10383196179594878788307822089840221133934617325689585185102459354573489625200,
            16233995600981541668545236739841072764746838842072283588755184287533683494106
        );
        vk.IC[54] = Pairing.G1Point(
            15706791489437710620067746836057969902230718043683255017080891959143158997228,
            20461395955792646013542375834244323600973552584664767616361530691146926888971
        );
        vk.IC[55] = Pairing.G1Point(
            14528310220219911640929385071851416363224947608777851376325258842716711191964,
            2635116789173738364724007495444103869590189071056785209510724920952077365249
        );
        vk.IC[56] = Pairing.G1Point(
            18221675727397682753239458381616834730307868148161566418645152563682405702372,
            18158410543375418554366741100348769351136957401339453919030032908497282896718
        );
        vk.IC[57] = Pairing.G1Point(
            8826170582016272176053880356933926917229542426025320333881414948807331794470,
            10501020982414594301448309821067677385118382629776704477764540593920980135519
        );
        vk.IC[58] = Pairing.G1Point(
            15901833569625900076717846064446519696239021865064854878892553150071239512133,
            13377927305401013554500503544110992581903923819714145730033817310887109525741
        );
        vk.IC[59] = Pairing.G1Point(
            2259021055853121086761510613398244243840460883001919565957296506051668063251,
            7937389165824152706299093792071721347569068171996367823164723824950775615833
        );
        vk.IC[60] = Pairing.G1Point(
            10482224303561376478259412680899454354572503871014240349413078841281029027091,
            3444188600089693238633708674993115799319037670632805298784956720680471791160
        );
        vk.IC[61] = Pairing.G1Point(
            9206412205461150281919846835652473695347787897827966850764202299671587336491,
            14837309403029544010531188018476805529378648609485534844995412828495879363598
        );
        vk.IC[62] = Pairing.G1Point(
            3511385562208006420391963114532340014680118515362276820070004618697015062223,
            16415123386729786013142882935544101859266937391493507569505309299346625704041
        );
        vk.IC[63] = Pairing.G1Point(
            16644222769831156908309793127536864422043309651333509331006052779960325366134,
            3417721199676272992454354348408775331208945161411962156523879346353582260596
        );
        vk.IC[64] = Pairing.G1Point(
            13302704778503266608960083889069203166915770290546080602495665485281109218637,
            20908938136796858038590186952680569114152103645992560108720518745570498418556
        );
        vk.IC[65] = Pairing.G1Point(
            5492993496576653221969905559691058970217598065118938301160325114382250345874,
            14075515228987227100138677372840417380050799784384049752628980486240771374643
        );
        vk.IC[66] = Pairing.G1Point(
            23549012544170997168131179550990217557692248779517658720462473822606293723,
            2413787265840205061623860138519646618087890800832836843638803985109377384586
        );
        vk.IC[67] = Pairing.G1Point(
            5461249089509247655707369457416362266053526787341998559250189811306512457438,
            3138384902817073344835326102711254927388543794537332856851293601361587457572
        );
        vk.IC[68] = Pairing.G1Point(
            14079155339460468979572997260702601423110635142457696952449454452370320672374,
            14907041135085445875764219564860094879287329696413895304998799833892567284287
        );
        vk.IC[69] = Pairing.G1Point(
            19374715522690786842943194817075332227304268938632136011341104501417819103096,
            10657465007051522776339121929577432670482944119316459165404641793859365790276
        );
        vk.IC[70] = Pairing.G1Point(
            313740563598388760191771992171378436797141967115091601856639979575661877863,
            17015440920997072662143202586574798598233273844459076250208639739127244407580
        );
        vk.IC[71] = Pairing.G1Point(
            18618504539395140872957623948816281277601295905377615375843807903437709628455,
            19707038421045298285934755536001689673171051240757988629557395842152930202451
        );
        vk.IC[72] = Pairing.G1Point(
            21419793847133328022277269980928223459329660336564249774662267318461591238763,
            11101368323491973774991020718178439934341198062962922609845862185948027800363
        );
        vk.IC[73] = Pairing.G1Point(
            19028309488434661574378923868991253306246587412267061332017937131859957006440,
            14295389720011240262779861401988880051564421285369644562721947279663299801661
        );
        vk.IC[74] = Pairing.G1Point(
            17216077290351919697353874206868329086320772000889917858791956417950349151734,
            5359591992195145790195785076038983132295158698251234185861449836411152125631
        );
        vk.IC[75] = Pairing.G1Point(
            18062532095918979940658570868139908209536407645974435763153669490776234581804,
            14355472294473461688816162188649711234926328951880884790915290905456074001544
        );
        vk.IC[76] = Pairing.G1Point(
            21611077318235008173142162988042851106560188242149788302201334889460332121040,
            20593100119007025035923945734131216497777695354168130104665014890980465695283
        );
        vk.IC[77] = Pairing.G1Point(
            21829302080324506880182449386564539544872151869254266605832760658851987606969,
            14073961956761407034892231953231110230160862380288678455628832677697469611160
        );
        vk.IC[78] = Pairing.G1Point(
            18689303458619011891623372071194680458340147257152959991570943497851152674656,
            8887618162831811253403154237932456995433006673149766420400767258356227261793
        );
        vk.IC[79] = Pairing.G1Point(
            17584765242253918568019682023363106301830187076315230331969818716056995909019,
            18326656768036990011492927344245460563483224609756263355618893353854511952946
        );
        vk.IC[80] = Pairing.G1Point(
            19296627543075743764999625982283874925124350450126552572222538854699180995404,
            8661570615475300979148546726362114072526796665994555576354171965879145194138
        );
        vk.IC[81] = Pairing.G1Point(
            10478639695075699295191466629939052727090597484983619587970517617181269165508,
            4135551092184136882017359957383013220100696147719201546091620213482538739974
        );
        vk.IC[82] = Pairing.G1Point(
            7579216661769865787917676566424970778546101674362126957685759760243019967601,
            2734959736120212585162974360182971168498136386679871116840537925898893948983
        );
        vk.IC[83] = Pairing.G1Point(
            19676352250368797680623731819542061661283358313292824568239328468081894468158,
            11961242912152684767053360260170194096518414826815033262001118511474923356580
        );
        vk.IC[84] = Pairing.G1Point(
            4351845474566028139710222927259923355019989954351718733182044867706238579810,
            2332326438036587168419179849533264274999689061089032721327701156941007585254
        );
        vk.IC[85] = Pairing.G1Point(
            12791625509061292176775612681314233192517847301938002810615243281589450226412,
            6788611948424321390547101008864468804998670105866518337358631918439472837561
        );
        vk.IC[86] = Pairing.G1Point(
            1349293218122938691310267908628277392023674679628945457220683639525332258716,
            4592129303139727455769936100209883129731572985015980995655879355001272651360
        );
        vk.IC[87] = Pairing.G1Point(
            15660042857207604849848137561744904553888231778600762383399036318560389623536,
            4626537354214831173165415382510051509198621560051091308309417463603644951814
        );
        vk.IC[88] = Pairing.G1Point(
            4596693567813916108541114305157021494694304767739117821559238223397649341046,
            12255314609127054977598695449423787190313148870208090436022326578539341430367
        );
        vk.IC[89] = Pairing.G1Point(
            7676260119125766950489305328829629548719618293477118637359030857676649522800,
            5651455850723667985787117232697216246989653404771420500505535028297330982406
        );
        vk.IC[90] = Pairing.G1Point(
            861529171380712953442601934629978151021637332502102914478063379715790814538,
            14068879259109462317349596516374354768591566466293021085845487695075721362477
        );
        vk.IC[91] = Pairing.G1Point(
            2184964470336133980293862171580944260744396885168435884481107078870041058951,
            20546358469486664693872048321293661503461373714391505780142591847563203967592
        );
        vk.IC[92] = Pairing.G1Point(
            2772794783537123512982503214577154679633470827518269274823575965197396010479,
            1342144052569410487373981329570687589785457916930587124212077269117658329948
        );
        vk.IC[93] = Pairing.G1Point(
            6514881722123488026442915729428795799590186108888705582176962296061440548684,
            13878853835451924788104172621171610583389754584080546760618881142075032163060
        );
        vk.IC[94] = Pairing.G1Point(
            5075523302464161529563012590287458445223168867610904264623676564098393693038,
            19286000575493070720967162475822203386403988648634100677773724789523298856912
        );
        vk.IC[95] = Pairing.G1Point(
            4265701361461316073139853731669859702076687893033779853710479514261903447391,
            2190480977539461107160352794820770833434289443124412118022953861425741818398
        );
        vk.IC[96] = Pairing.G1Point(
            8880075081436111366031458912737453634889787541332969811794506601080074627425,
            21404095235168660383200296153094020447184016934745088424915436621533703978477
        );
        vk.IC[97] = Pairing.G1Point(
            9024986062545236487821787221898186280644800815884021419413872217019389558267,
            17894974547312572343624385975506235490967800062855399390343587502266046642623
        );
        vk.IC[98] = Pairing.G1Point(
            19725090251912959877189675135985108312667514296868976127303314652274987288691,
            3704391613400558752916842523615705119413725159858905363420825090194280206076
        );
        vk.IC[99] = Pairing.G1Point(
            12046281132722851176740703218797032291798085288409431566598760115473090437227,
            5343714112675296757656115957205940062357393460912896585850093762365392840556
        );
        vk.IC[100] = Pairing.G1Point(
            7507961801227947579239776414828018479790274406987721895309021577193824548557,
            17623261799373267437756121432208024038038646662688027511193127856370003866731
        );
        vk.IC[101] = Pairing.G1Point(
            18845208761457559365690864497322172443246436178332065935343763244599499516795,
            14209115037915908933899101592773807143806037698494141720917009620824932947657
        );
        vk.IC[102] = Pairing.G1Point(
            4351244183678417719327068662380543209855563620982998548403022395321601662567,
            8683752331832046939160340547798590511690703631628870338808490248599928254627
        );
        vk.IC[103] = Pairing.G1Point(
            14996230152788865890968449232875132854988068753040481408783274965832600894288,
            9520980891098925858413676639684202783444178113510738593179564708711485964016
        );
        vk.IC[104] = Pairing.G1Point(
            18781259283892364217097009271019062531855579068044975417507303286882207386623,
            21074066201706755078247678564462063327344429078700053131183585656036916479558
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool r) {
        require(input.length == 104);
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/main.sol

pragma solidity 0.5.17;










contract Anonymizer is
    OperationsProcessor,
    MerkleTreeWithHistory,
    Utils,
    ReentrancyGuard
{
    CreateWalletVerifier public createWalletVerifier;
    DepositVerifier public depositVerifier;
    SwapVerifier public swapVerifier;
    WithdrawVerifier public withdrawVerifier;
    DropWalletVerifier public dropWalletVerifier;

    mapping(bytes32 => bool) concealers;

    uint256 public constant MAX_VALUE = 2**170;

    event Commitment(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );

    event Debug(
        uint256 tokenFrom,
        uint256 tokenTo,
        uint256 indexFrom,
        uint256 indexTo
    );

    event Log(string message);

    event LogAddress(address message);

    event CreateWallet(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );

    event DropWallet(bytes32 indexed commitment, uint256 timestamp);

    constructor(uint32 _merkleTreeHeight)
        public
        MerkleTreeWithHistory(_merkleTreeHeight)
    {}

    bool private isInitiated = false;
    function init(
        address[TOKENS_NUMBER] calldata tokens,
        address _uniswap,
        CreateWalletVerifier _createWalletVerifier,
        DepositVerifier _depositVerifier,
        SwapVerifier _swapVerifier,
        WithdrawVerifier _withdrawVerifier,
        DropWalletVerifier _dropWalletVerifier
    ) external {
        require(
            isInitiated == false,
            "Already initiated"
        );

        _init(tokens, _uniswap);
        createWalletVerifier = _createWalletVerifier;
        depositVerifier = _depositVerifier;
        swapVerifier = _swapVerifier;
        withdrawVerifier = _withdrawVerifier;
        dropWalletVerifier = _dropWalletVerifier;

        isInitiated = true;
    }

    function createWallet(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external payable nonReentrant {
        require(
            input.length == CURRENCIES_NUMBER + 1,
            "Incorrect input length"
        );
        require(
            createWalletVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        uint256[] memory tokensAmounts = sliceArray(input, 1);
        processCreateWallet(tokensAmounts);

        uint32 index = _insert(bytes32(input[0]));
        emit Commitment(bytes32(input[0]), index, block.timestamp);
        emit CreateWallet(bytes32(input[0]), index, block.timestamp);
    }

    function deposit(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external payable nonReentrant {
        require(
            input.length == CURRENCIES_NUMBER + 4,
            "Incorrect input length"
        );
        require(
            depositVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 commitment_success = bytes32(input[0]);
        bytes32 commitment_fail = bytes32(input[1]);
        bytes32 root = bytes32(input[2]);
        bytes32 concealer_old = bytes32(input[3]);
        uint256[] memory tokens_amounts = sliceArray(input, 4);

        (bool success, ) =
            address(this).delegatecall(
                abi.encodePacked(
                    this._deposit.selector,
                    abi.encode(root, concealer_old, tokens_amounts)
                )
            );

        bytes32 commitment;

        if (success) {
            commitment = commitment_success;
        } else {
            commitment = commitment_fail;
        }

        uint32 index = _insert(commitment);
        emit Commitment(commitment, index, block.timestamp);
    }

    function swap(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external nonReentrant {
        require(
            input.length == CURRENCIES_NUMBER + 5,
            "Incorrect input length"
        );
        require(
            swapVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 commitment_success = bytes32(input[0]);
        bytes32 commitment_fail = bytes32(input[1]);
        bytes32 root = bytes32(input[2]);
        bytes32 concealer_old = bytes32(input[3]);
        //uint256 fee = uint256(input[4]);
        uint256[] memory tokens_deltas = sliceArray(input, 5);

        emit Log("before subcall");

        (bool success, ) =
            address(this).delegatecall(
                abi.encodePacked(
                    this._swap.selector,
                    abi.encode(root, concealer_old, tokens_deltas)
                )
            );

        concealers[concealer_old] = true;

        bytes32 commitment;

        if (success) {
            commitment = commitment_success;
        } else {
            commitment = commitment_fail;
        }

        uint32 index = _insert(commitment);
        emit Commitment(commitment, index, block.timestamp);
    }

    function partialWithdraw(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external nonReentrant {
        require(
            input.length == CURRENCIES_NUMBER + 6,
            "Incorrect input length"
        );
        require(
            withdrawVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 commitment_success = bytes32(input[0]);
        bytes32 commitment_fail = bytes32(input[1]);
        bytes32 root = bytes32(input[2]);
        bytes32 concealer_old = bytes32(input[3]);
        address recipient = address(input[4]);
        //uint256 fee = uint256(input[5]);
        uint256[] memory deltas = sliceArray(input, 6);

        (bool success, ) =
            address(this).delegatecall(
                abi.encodePacked(
                    this._withdraw.selector,
                    abi.encode(root, concealer_old, deltas, recipient)
                )
            );

        concealers[concealer_old] = true;

        bytes32 commitment;

        if (success) {
            commitment = commitment_success;
        } else {
            commitment = commitment_fail;
        }

        uint32 index = _insert(commitment);
        emit Commitment(commitment, index, block.timestamp);
    }

    function dropWallet(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external nonReentrant {
        require(
            input.length == CURRENCIES_NUMBER + 4,
            "Incorrect input length"
        );
        require(
            dropWalletVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 root = bytes32(input[0]);
        bytes32 concealer_old = bytes32(input[1]);
        address recipient = address(input[2]);
        //uint256 fee = uint256(input[3]);
        uint256[] memory amounts = sliceArray(input, 4);

        address(this).delegatecall(
            abi.encodePacked(
                this._withdraw.selector,
                abi.encode(root, concealer_old, amounts, recipient)
            )
        );

        concealers[concealer_old] = true;
        emit DropWallet(concealer_old, block.timestamp);
    }

    function _deposit(
        bytes32 root,
        bytes32 concealer_old,
        uint256[] memory currenciesAmounts
    ) public payable {
        require(isKnownRoot(root), "Root is not valid");
        require(!concealers[concealer_old], "Deposit has already withdrawn");
        processDeposit(currenciesAmounts);
    }

    function _swap(
        bytes32 root,
        bytes32 concealer_old,
        uint256[] memory token_deltas
    ) public payable {
        emit Log("inside _swap");
        require(isKnownRoot(root), "Root is not valid");
        require(!concealers[concealer_old], "Deposit has already withdrawn");
        emit Log("start extract");

        uint256 amountFrom;
        uint256 amountTo;
        uint256 indexFrom;
        uint256 indexTo;

        for (uint256 i = 0; i < CURRENCIES_NUMBER; i++) {
            if (token_deltas[i] != 0) {
                if (amountFrom != 0 && amountTo != 0) {
                    revert("You can swap only one tokens pair");
                }
                if (token_deltas[i] > MAX_VALUE) {
                    amountFrom = FIELD_SIZE - token_deltas[i];
                    indexFrom = i;
                    if (amountTo > MAX_VALUE) {
                        revert("Max swap value is 170");
                    }
                } else {
                    amountTo = token_deltas[i];
                    indexTo = i;
                }
            }
        }
        emit Log("end extract");
        emit Debug(amountFrom, amountTo, indexFrom, indexTo);
        require(
            amountFrom != 0 && amountTo != 0,
            "From amount and to amount must be not zeros"
        );
        processSwap(amountFrom, indexFrom, amountTo, indexTo);
        emit Log("end swap");
    }

    function _withdraw(
        bytes32 root,
        bytes32 concealer_old,
        uint256[] memory deltas,
        address recipient
    ) public payable {
        require(isKnownRoot(root), "Root is not valid");
        require(!concealers[concealer_old], "Deposit has already withdrawn");
        processWithdraw(deltas, recipient);
    }
}