/**
 *Submitted for verification at Etherscan.io on 2021-04-26
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
                14684549204778542878868885653917102488118747595241950992999610792842904714734,
                15793918986784663305400672045466935296057604467892306416320956605639446279426
            ],
            [
                8876947703056269339022540899615007415749555026312840481131615733782731994455,
                19736753667721288801503010780711927485490100444367180952022186023842213987733
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
                1402995255918614280544164014887821037123004957591509986600727819464354831339,
                4409842612288107311726599982010568175298886492412262758515493831139179043169
            ],
            [
                17694278912701698476600940089194256962397623686185569545909909262861243594913,
                1543512834018895305208256487374820337730710362568645108406448417158467694044
            ]
        );
        vk.IC = new Pairing.G1Point[](105);
        vk.IC[0] = Pairing.G1Point(
            4643468953403276870735353581175291979481319825759771044345155354885802230152,
            7641553782318794671154762914154909966934555991877187036008831539395707167408
        );
        vk.IC[1] = Pairing.G1Point(
            7743058329305761443093730327366393296583803646256749649975828024809086969094,
            15270003025476615626904525960754641785606032300902922545992027124832071828406
        );
        vk.IC[2] = Pairing.G1Point(
            308671487644236711591551531956398318340093278478131257408480709668834956640,
            2650289956469643432975248712849572910481321732141450557135214997731522649407
        );
        vk.IC[3] = Pairing.G1Point(
            16290787673704891946771861981815348274148330557001923268100508241810161279458,
            17398775257396551005083342371198249704759640111070536001908628819264926281965
        );
        vk.IC[4] = Pairing.G1Point(
            15294388983935849320838093173271088304180141244179667094355449609308946197630,
            3485785514268829485433647149771200090734147593813960790249148577734501446758
        );
        vk.IC[5] = Pairing.G1Point(
            8357820714896164759326524941277599700126044916541439249964380846994976182522,
            16590929961071360827502394388471237382797796785097301456873808899601523008282
        );
        vk.IC[6] = Pairing.G1Point(
            6001725427312060018630912329516760300191302412710059941740129011985731687090,
            8592300760669673150405650995434807349016631452805888831144486058491714672334
        );
        vk.IC[7] = Pairing.G1Point(
            20403479254072111864377774031410715393206680489407732106944494747139864914572,
            5032032703884729848062601893060660584403230126543391411557148437581914459982
        );
        vk.IC[8] = Pairing.G1Point(
            20700105527567700688462772395941900261842003223329089021682349010938127128395,
            174996875792403743287746461459374377808288970247938382273197651661560717564
        );
        vk.IC[9] = Pairing.G1Point(
            976166864562803326796136054600173091380395208899421473951728511723304722347,
            5462881442481865764923025199541129217118784415642586547460740627841526953271
        );
        vk.IC[10] = Pairing.G1Point(
            2063500622532529308142847498711387454677583512717878938211441856786873070295,
            9390244193073177261686869968047198056776493426516104091288797142553584745430
        );
        vk.IC[11] = Pairing.G1Point(
            21613196357178967971531844222869839978257274950263623663575344352375704652931,
            19311674525583268757750935145679938768125729871143506197076853735209552107977
        );
        vk.IC[12] = Pairing.G1Point(
            15878625977958355715205539793126275220004593563846269775230936246796688282551,
            21246161883536590291773142257122414940654627260373434050306587116275801350557
        );
        vk.IC[13] = Pairing.G1Point(
            17088688943510401443939158997920936752919688053168581595821377634404880930669,
            20066686174656601640994864091455609904897504123601214275650726246670062755744
        );
        vk.IC[14] = Pairing.G1Point(
            21566659996443418217300084817912385530016779917651361391051173092030132821744,
            14560592578060500114770152814448421192741126463912203229324026264218628891133
        );
        vk.IC[15] = Pairing.G1Point(
            18592612189302709191698088741897771598172667285528883656331857919635282374085,
            5772976485630809021763973075186254930562145837195056769226203298525944596483
        );
        vk.IC[16] = Pairing.G1Point(
            12500332507730135480261074997782601231023993013672542201226044389724070184811,
            4427714194848272701431036270555543631010486206995663809756686542198877720692
        );
        vk.IC[17] = Pairing.G1Point(
            18066453174593514508697139526838002211179435635828263807008888967499038308497,
            12196137570644406058581947973401637025335132576020284634247525387241795407369
        );
        vk.IC[18] = Pairing.G1Point(
            5779532265696534711017230311456294764563998168740444470595444755093229645906,
            10770779630024161376288082402096638741133215274156728652204334239814667290776
        );
        vk.IC[19] = Pairing.G1Point(
            20261553339463336957062997096523539860595608857343676748578693279966274619525,
            10346450383849924378840773877402314701178136330378778824557281569460125101246
        );
        vk.IC[20] = Pairing.G1Point(
            4828573378662777464005559594045974230964784462965893988566261147885845256017,
            13061902001843651415975870019728685369746877051946496221641211517089953257218
        );
        vk.IC[21] = Pairing.G1Point(
            6264532422356340776699265043860552918875650819226355440412214905890358166943,
            11839933382537856533609231633011600670180582721087471525748854940746323128841
        );
        vk.IC[22] = Pairing.G1Point(
            8569795034674153247923080854589667077259207747483227323928806012016733602032,
            15844152803111299629329110865249886560953370684267123961976897535341786452820
        );
        vk.IC[23] = Pairing.G1Point(
            3268975594160096515575200746297202537551573591734362033531263614306337984494,
            7254950712042741988038818495782846460735652325610429538922381490669406760751
        );
        vk.IC[24] = Pairing.G1Point(
            14455754770883246904293713615124126276943334872688503166447991078254652585192,
            16228949419543227775360334837272690169537824068711777263175574102418250336677
        );
        vk.IC[25] = Pairing.G1Point(
            13479927591031001818958521381600641977476252856477920944765079412824496291543,
            18322237388511082218856730022100190941802087979731885019245427325865094536997
        );
        vk.IC[26] = Pairing.G1Point(
            5575106415886779364250505682156996239218892013024352907955019714128593669982,
            18277433975947205877728500532787294474440288972420408823770723715261968627794
        );
        vk.IC[27] = Pairing.G1Point(
            7460608698748577422169805146056221308816778776075023552332720162895828340289,
            11352590767055490401010023933103283146266520164354090170811151803998970881536
        );
        vk.IC[28] = Pairing.G1Point(
            12386713789614333644513193864170500496949669740578975808300554423476550383580,
            18576806159458166585493321347934416305437308538155438060496131884307307846124
        );
        vk.IC[29] = Pairing.G1Point(
            9673249153374805402767399986423479040896581644376330271011161717275725837511,
            12184486489733044096925127788819061678333085136697214632272514023785121841744
        );
        vk.IC[30] = Pairing.G1Point(
            9683415451434082007970880725965102833349944927248924412378188849796483376907,
            1361134852570703802171544734354611381405066852248124439180350246184328025310
        );
        vk.IC[31] = Pairing.G1Point(
            1610653041395451275321247640345343580301946045728915036452257022070767543158,
            13941330997085663089270729995178661085695623736509889561212212585002193866131
        );
        vk.IC[32] = Pairing.G1Point(
            9522892240933510135712941766718186681029661971704707208743740778775629359240,
            20590224192039310735595114880408260989460340104463580359583418941830115592069
        );
        vk.IC[33] = Pairing.G1Point(
            21589220886564077735112002915542210854234716333056610802656389054178400792312,
            13646370115138181398041482627440042776383926255892969989068617060735413867508
        );
        vk.IC[34] = Pairing.G1Point(
            5386410562263062630503379769462785688179575855855318991016012067474538585014,
            2651839122018345773868709462185512788505111550635719654071600999516638134857
        );
        vk.IC[35] = Pairing.G1Point(
            4553654757173467681434872155944865451575145019325881910130502472707855680767,
            7149548500291610064525981761504166267036763770484678383768330340318871026046
        );
        vk.IC[36] = Pairing.G1Point(
            19846104045124347840491576499337734726469840543851613401384766049305470358065,
            15868746622597675993412848669628659385387610660339206910130777816818271349825
        );
        vk.IC[37] = Pairing.G1Point(
            15455197963479298945517052501474964933676268515110185427778634111906710720405,
            16393444688282005819409595105622499251166569383132887107446278240992816238986
        );
        vk.IC[38] = Pairing.G1Point(
            2024803120371302539632587804568084399504346529502855370544971391573938450178,
            14162749998778843114210044319375725030425982594409709013979782704455873672335
        );
        vk.IC[39] = Pairing.G1Point(
            7543778456008796034880936827778933545882360971332257644426861575514803924115,
            4715823924815937592837323940653737380955572400091853614668508811854180577417
        );
        vk.IC[40] = Pairing.G1Point(
            19342970965872544216717683346739597226659552643044801454166318663933371857160,
            19387803623967452724996828913269858684873073520492518266431379798615727127511
        );
        vk.IC[41] = Pairing.G1Point(
            2221212811921469811250530356678338373077076622263906550041943474295615096216,
            1763841821617623771907661132880749111279224689519818387565993746921080786848
        );
        vk.IC[42] = Pairing.G1Point(
            9754603556165813661078221478629911371223404766298373227890206301255126418338,
            3101395857884709384026420573666824240753478413916709622307279183413921041727
        );
        vk.IC[43] = Pairing.G1Point(
            8006224465200813758081098464347995213443352765995502128126169294368288573551,
            20466512160114946779733409594727041294043061220356374930077885400693688159671
        );
        vk.IC[44] = Pairing.G1Point(
            12216475049573696707148281212654747547437157107688631352478407250127760685607,
            8214190113564740326460042225719898987911483296510090394970576918617356070611
        );
        vk.IC[45] = Pairing.G1Point(
            731911442317745614089011969529050401566358713273819236246682146160351022959,
            90174076073025292115604758383625935956246733813304092350368976371442503631
        );
        vk.IC[46] = Pairing.G1Point(
            1517610648653133815747153901926649500555182207140446359257378811623479894285,
            12268702455185177861855970093848259150730174557403833635256702240665017171292
        );
        vk.IC[47] = Pairing.G1Point(
            14322342831292903644276010863108630241800894005681310401447006279576080780790,
            21820190954053177620043519994983904737718640252930050748348276582826393696166
        );
        vk.IC[48] = Pairing.G1Point(
            937367864647737296443502009785491846449088406714194730394833598963366894482,
            2051264246222857721593890349880082284509587430450506157019759348466552858006
        );
        vk.IC[49] = Pairing.G1Point(
            18419955237844452736766945773992942894632716330430184597963111722871158477468,
            15887698184365535158289001587981239915419413009175907151431209298917375999900
        );
        vk.IC[50] = Pairing.G1Point(
            18769909269764085223370066054846839413485104500140941675566570694868892774424,
            4306221401184335529399745899589893710116894895773199470871831537241518609802
        );
        vk.IC[51] = Pairing.G1Point(
            16756927699323862637015262679502181226063515961701257716025265387851687537308,
            9029003187345479344152287050220570005098288559127173390522416379601131316017
        );
        vk.IC[52] = Pairing.G1Point(
            6765764085695969213303825350257035865859376099074116073726749856892936004354,
            9082238515374607358155812391818651366485226311352276058737701632500376224812
        );
        vk.IC[53] = Pairing.G1Point(
            4763586248900285832314972564754522670700837159486207903765234443430916114107,
            19877670598515860511955181947819687860819382878058669508517544485924380816961
        );
        vk.IC[54] = Pairing.G1Point(
            17948663472848135193517423001832304172312918228385369208048761905176612527920,
            1065904076806550556830819609942399929793320387422782644336129682450503638766
        );
        vk.IC[55] = Pairing.G1Point(
            4932669348623651699454712983044792663161003944305501840860229382363079692414,
            21048015953077933424970865763823070753347297748655847440785704542787473628656
        );
        vk.IC[56] = Pairing.G1Point(
            15623033111259529671366965065259773307643317452402499436963191586007681139593,
            2802517476257541264631388452950544738831744542791661864491559910561363157642
        );
        vk.IC[57] = Pairing.G1Point(
            14693073474352828685864161401882754347237904531522994933592392837093583420199,
            11903227613336475436316563707566581106494986609726925067109085465661062715947
        );
        vk.IC[58] = Pairing.G1Point(
            18678026143596111773616479457187343487251007022508748118163166912680881725832,
            4520934040491692016913485838816218220484778248405291649938399524474424907700
        );
        vk.IC[59] = Pairing.G1Point(
            11660471700291674107574332343268393915671820500780933231008451486820734578625,
            21438951617338636784446120971890675185299679532012331518997971567337284698685
        );
        vk.IC[60] = Pairing.G1Point(
            21499757950848578999134764526268278411673593205468722567145434749515644405495,
            18574128813073299581057430135262647865970149475254016029469638241977268882651
        );
        vk.IC[61] = Pairing.G1Point(
            2681595796327893682388578124062475956380296807680872033627224386955997326699,
            6745832594678334948341568433652909946686364881614101491808702026279172821752
        );
        vk.IC[62] = Pairing.G1Point(
            5315149170655613273234494594457727192316049871113023762662392347077340732112,
            6324784257910342373241869849158046336599566415358228457532484948352935198332
        );
        vk.IC[63] = Pairing.G1Point(
            18515258581797431867933315400597828057079019028084609160046768560076799423596,
            206234484383607512150167462952031445247252776488543691681761331952562379815
        );
        vk.IC[64] = Pairing.G1Point(
            12188617513567232684598703496861413255106117660088655402643211919257057631184,
            14377181460646771876539127561817356054269333660486518171780099639955130917662
        );
        vk.IC[65] = Pairing.G1Point(
            3462440626337701560942946280409998084996905793404057218961256007618577648079,
            9152521396099185804856214787104199925419646471226900882418897303845218421062
        );
        vk.IC[66] = Pairing.G1Point(
            954370885049931152210953536384827860516560718191803264910572066830078302874,
            12639657568379913468416454480843022594604288814854164739677974346452175618324
        );
        vk.IC[67] = Pairing.G1Point(
            10174406928255017322275231161078545531683938109163636152249933956193055165093,
            16606713236667784097832308531434605783775362974444898154245009337122043738213
        );
        vk.IC[68] = Pairing.G1Point(
            1998828755360959544808579353313001125615835769485988570077944895253018016772,
            2987764443136129814938299401544571388494846607933762759568885520322969748279
        );
        vk.IC[69] = Pairing.G1Point(
            14114291178545370102912428447650403943368520465284802531445795794477652164832,
            5690840923824057539193813026417758510953759745646466094657262408320072221689
        );
        vk.IC[70] = Pairing.G1Point(
            19612225689265971576599085937221113003557591909390814108450618072261867015029,
            11794169165811351787985222650858561064842944505963654260713071383145715714589
        );
        vk.IC[71] = Pairing.G1Point(
            19321417289998684470917149307378117446335823871248525401271100397628906633392,
            19044981915686046884742567237826720851106898290311631336326220194332312999689
        );
        vk.IC[72] = Pairing.G1Point(
            18748870546929385478644095377900010278408092724673890476791767579108450219146,
            5230131061888569101001240701801167111148548126013868748572292328810013895890
        );
        vk.IC[73] = Pairing.G1Point(
            458730188081925514929521840250276466626746740925030720272342352410052275015,
            19599392757129459230207525835255987834822220241392208124024959433806444899168
        );
        vk.IC[74] = Pairing.G1Point(
            5335759648189660775630100999903726525823056595579713261019658549103459401117,
            15147841165055595903429634934130177408536814498749028653858501709362652543400
        );
        vk.IC[75] = Pairing.G1Point(
            13341983798762351798264485297540956254777548565241528031904443795122594630994,
            10293831628475528904959750474972963685720670586435193360470126012577416564375
        );
        vk.IC[76] = Pairing.G1Point(
            21120815242680520006285383004621991963071603731519137512984438473004496621507,
            15168626807189727043631323279045659117198837287880811389044195942048229707509
        );
        vk.IC[77] = Pairing.G1Point(
            19314446641490558089772144552200618870632050530212442847428839219214870351281,
            20750978388742324100156332395884476175534108474581278470703704191919357874451
        );
        vk.IC[78] = Pairing.G1Point(
            19585912714923439725068082156227836899715103018840088559343720329244795597029,
            10027731701764794220035063760022708560909430946863357487756454929434941289496
        );
        vk.IC[79] = Pairing.G1Point(
            1027759753514481528222186830965826121368960549228407156541991122199658144970,
            8078908093260085141559213638026638182239108164406315375778729033606535150390
        );
        vk.IC[80] = Pairing.G1Point(
            1698785917417752470673943249438502653589000962326760530464902691427018002468,
            8335858078417327936753608288665460669645187499500584660229550983167284050887
        );
        vk.IC[81] = Pairing.G1Point(
            3046900823122860828863205552453897835747824863406897573973648818194096490096,
            8236411315462277071150210305503561934971530575427341081134786001370996082185
        );
        vk.IC[82] = Pairing.G1Point(
            8786521617622140516894102344330631764314089643512465642032735829793317239461,
            7612094208423100466061632536827544595234287360496835294978597593375097480474
        );
        vk.IC[83] = Pairing.G1Point(
            4823131327605508806581727691366927505840268638944771003574047073161027755471,
            14831700636572613818457751014409926205279459764827380468818703573853390867479
        );
        vk.IC[84] = Pairing.G1Point(
            15056473405283689006025516342051067630229369568025437187428776893548531663255,
            2570222038179673475036234689820136038120014335745530937630186795166561588032
        );
        vk.IC[85] = Pairing.G1Point(
            21479443323976840084569783721995374131244839150563829192280009050944057150982,
            19899993530105627027958113751480720143806461024252558999275017959378051077941
        );
        vk.IC[86] = Pairing.G1Point(
            3953792166139660104110848470343255876175328424138621459856297041912436669820,
            14716370565878039818582723968426066137176009545647747092679461532859717149512
        );
        vk.IC[87] = Pairing.G1Point(
            4306224460296710998336615168387343717593241670936701263169101376179490985533,
            18133102452108967321547550230754734234240475194604515023106138034950328439380
        );
        vk.IC[88] = Pairing.G1Point(
            2887990340074912993601991329797826835232307986915711979218674326111618308077,
            13500401531028954736940160711299907919929008601455068999054535844837417583747
        );
        vk.IC[89] = Pairing.G1Point(
            16673489817062150338234322242667483287818373186549173105688596198803365612421,
            12660507946773807266796437522332778214102361723277741767294142130429586576569
        );
        vk.IC[90] = Pairing.G1Point(
            19583704221609693892878672055114078522659378836777426074283457258894980389774,
            7208312860618744874784581627379990574129308721241625219787681445124151360675
        );
        vk.IC[91] = Pairing.G1Point(
            5400823825530299723076088254109322179519325205819609566665459944179929836598,
            12090666815986126849310451761786834914050646655359860904327890728563547847040
        );
        vk.IC[92] = Pairing.G1Point(
            1580404667241105056944467915840256461080109103798284016004625057277487879599,
            18127372887633402227808042048798646462523138591639154688180975834789521748219
        );
        vk.IC[93] = Pairing.G1Point(
            21389488055193254176504603487446537154848853254823927673996269039879291346380,
            37892370851626651709815000518481213228517597619226898579639794802488334593
        );
        vk.IC[94] = Pairing.G1Point(
            89432948381110996350860733509502856014982477939855990068958650595385382594,
            15212239529716744369770984883299160548497257822368976777186357117361012948331
        );
        vk.IC[95] = Pairing.G1Point(
            18256498568635015210926290166745042458133149527507222613996958899277369679124,
            15919203831326040653495897516554998949855185234877656629169075714134416971599
        );
        vk.IC[96] = Pairing.G1Point(
            14153479138250762728578713460115057767200439632916730570670111147696856606325,
            16580207901840032154064400852249152073290858134873832063720855038225944239486
        );
        vk.IC[97] = Pairing.G1Point(
            15306894280402008560728528140922129026901113368502704357571859035684651419779,
            19951715087665953183313665189650841023807669008789843892640599976858295071114
        );
        vk.IC[98] = Pairing.G1Point(
            7216712788438507697256081134375275601749302009556621509476743685774088867059,
            7737336055288101554332794614368864769857979238038785585729596370054601368551
        );
        vk.IC[99] = Pairing.G1Point(
            19292460025140859188170319905255060286899881621423050550150066400774598726442,
            19631538949132723083181348481038637593669372439581602781386275394947957377525
        );
        vk.IC[100] = Pairing.G1Point(
            8506544558020184656198370526371467553775665191188476810766342095186620947817,
            3800142300223614885492475082918596668988307867971689564271845446453930431497
        );
        vk.IC[101] = Pairing.G1Point(
            986117097487446489824592162394496836034135570010227895721930854386675818866,
            10350628371657863648182859021934005676706802104775819159900711343405057268904
        );
        vk.IC[102] = Pairing.G1Point(
            17977415680191308830329894911128017088638788955817727385018243613337233628321,
            11670614138547730558005378065196374467365173439949353669719345009914968634931
        );
        vk.IC[103] = Pairing.G1Point(
            5514770604481634772234338996367040390095909188538734936998473956463885496623,
            3180648168847440832983820506222367849383863579720883937348741974208378914278
        );
        vk.IC[104] = Pairing.G1Point(
            14331753603007925643032259613780675831232119366723594994377943855107700633374,
            18968588046204954683263990812945854010735699121756823104382359093456095902539
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
                1722359634668261413574443527415212970502158292366716779106316822229471669245,
                19281639504165650791717046028331415781702867747361821659593491835491077900457
            ],
            [
                91015938797718151639415723336282887776858826355195306836917182381101947786,
                10362228608420034846281654386447276155629491138664363116727068658842590086127
            ]
        );
        vk.IC = new Pairing.G1Point[](106);
        vk.IC[0] = Pairing.G1Point(
            19906084614053852808500540196782398344132899248713681571334405128726316136302,
            8561331413552142946223776493356394961951249813840476720155659556106922473583
        );
        vk.IC[1] = Pairing.G1Point(
            7804537108753187314285186513018130639545017274467295632399838583662312321403,
            3059428244289795354821462202035427041627818673772965159070968644347249439979
        );
        vk.IC[2] = Pairing.G1Point(
            6294375504856778642337679057172835929767868343009395654360444850784912362636,
            18628857766264109339589867121314727299775375676742339262272668135822593905584
        );
        vk.IC[3] = Pairing.G1Point(
            20278046535287088526950046737367765506400153716734351347747256692191582622204,
            11216265481856060581963840695387247040634438908773557080935783004735767435112
        );
        vk.IC[4] = Pairing.G1Point(
            15880635367081241126213064420953828254345101281043599575660655451808713552749,
            6886720120168667431824856076112792227213703527080921850323956914723362609759
        );
        vk.IC[5] = Pairing.G1Point(
            12264357856790371372527546874501481408813500729475296469990420029221835816075,
            650193547598947429242176393073557415431124002981797145252325429634581287295
        );
        vk.IC[6] = Pairing.G1Point(
            14666597553665497248834356339428779108341935778087566252839785533618229797980,
            9531703076111433622432844801290398697206054544705677526905386585178845962318
        );
        vk.IC[7] = Pairing.G1Point(
            5913539100179135674485754801205114951513807134127600319164885283505603766609,
            7186405990742904980716470585633546846552095574685112793163005120867527314138
        );
        vk.IC[8] = Pairing.G1Point(
            12051249146959532878280910759703281774766507717614911805089561889643691582243,
            15732371561113606308445162995113323149072501912823891219182207373392327626446
        );
        vk.IC[9] = Pairing.G1Point(
            7982526003255855236528598242780820492407300372714112127786328584751421367419,
            4025359531739666364210196071361086241925666602783455434560681568828062777814
        );
        vk.IC[10] = Pairing.G1Point(
            17116903680721402487782666873468736913691264592860528484525942619727159290073,
            19223060992374976195389488595664506526439548793416407455944039307512029514928
        );
        vk.IC[11] = Pairing.G1Point(
            14158337761752955338377746670811509244993188704980659444421320026687991642130,
            4225297567854553325901111746186696505318799393183979767038069091572626783251
        );
        vk.IC[12] = Pairing.G1Point(
            9478725451381068746832252529999914582986396902101520117278318466796380140329,
            3529609521907122191132424774218644729943501319594487721842626007604858733254
        );
        vk.IC[13] = Pairing.G1Point(
            14476881842317280999269315784751471475939637174194328397253712129124333963164,
            2876306041854431606780703143342605271501760017703136095000945333890717225826
        );
        vk.IC[14] = Pairing.G1Point(
            20394959591997930009765849353842966208561563300597851940227516375326304633816,
            1918982097636661921561913859560591599405770590538876270923966023041780699806
        );
        vk.IC[15] = Pairing.G1Point(
            16626641820264368846914612027651355612785146353193914250248941675183286063092,
            6596225676037079263913355972227124048159191140965090993373689314211341399442
        );
        vk.IC[16] = Pairing.G1Point(
            9335960610975269939464770500437472192430674597425482860713415699416195555096,
            18410336510113364367091549314826025715790543094376491118982976203408231955048
        );
        vk.IC[17] = Pairing.G1Point(
            16151342349801897325751824844226747293383535448194585489715100766263563429318,
            2838197758517926623403105987588020660918826197338604056324670324049229341926
        );
        vk.IC[18] = Pairing.G1Point(
            20823691080692055548507015474476279008778825875283461326909386539428406290896,
            3701688345079550029263259320955349086915351712195931788666976084120797553388
        );
        vk.IC[19] = Pairing.G1Point(
            3434037151724014637272926695659090694396656059013450759951580231858974850881,
            3000414560847593803164603380525759548211493880963388813244665011379901641517
        );
        vk.IC[20] = Pairing.G1Point(
            20200406976715462419872096482434089513301018375605478044828658294788759203311,
            9539664541318718828950781571651681579064392532044796436659438330483006183770
        );
        vk.IC[21] = Pairing.G1Point(
            20582326868794103780093967739927262808815886065740992964005145932798422909587,
            20327270558647520455835073603770298079330455608680552145708092740490727533288
        );
        vk.IC[22] = Pairing.G1Point(
            13003970813170912043995424337865893402182538987545374691188594241661737715669,
            3330919740791283218926650692654024365268356801678635034777070104367867687725
        );
        vk.IC[23] = Pairing.G1Point(
            12893582077108206380350671002784015930071407232786228547786305266629080591773,
            6539995271580358327618111217027819838940154225837537704834144061165234543194
        );
        vk.IC[24] = Pairing.G1Point(
            12059470999774662386395997590015789684826753977894706546221075207170249389330,
            13033847051798561872591478633002991378153476733908550312383510966722279862608
        );
        vk.IC[25] = Pairing.G1Point(
            15257511810575955779742517719193962017865238634460508263137452005403395128896,
            15371405525676267765753267866152551045570457163602308018262633098493535973429
        );
        vk.IC[26] = Pairing.G1Point(
            1080228633344965133855996262984893321432379904517202513605450257982173978237,
            14255449540192514429666603501007422646574077599112146521152276178374066294955
        );
        vk.IC[27] = Pairing.G1Point(
            7139559125672258883804278562294682791761293132572452363557057547111404571009,
            16003342546617352345471186347917340372635406022805858843232882435534951405906
        );
        vk.IC[28] = Pairing.G1Point(
            11574181797160469371984553394910635287930520633264506608116324705476933814427,
            20533212596687571122496331318314452303706680052384925086788623759812718459125
        );
        vk.IC[29] = Pairing.G1Point(
            11223727027764897987413239891208210021229239411186322127201964967602923975593,
            19317117965832240447762555142521109003187186975331801936891350042363623540315
        );
        vk.IC[30] = Pairing.G1Point(
            3121868941019316572109186857905245459642959917877194093289450633481317427716,
            11794061432267506521658706610699463217353635566023730901764386670977752383279
        );
        vk.IC[31] = Pairing.G1Point(
            15309036743332083661104607565404349210347976180878404908824181581407663014876,
            21571697442706804162060039044080309299833025247183624240295281309356595039860
        );
        vk.IC[32] = Pairing.G1Point(
            3364377938760893460115402733874908315659945608848958135369741059090666549307,
            13644660785255749068060860393657058154851370423081077629525817144782715595500
        );
        vk.IC[33] = Pairing.G1Point(
            9993625312111530882200657784112430319630601721710586258511721853568227973361,
            13037464968552241152401259132454287435441364068890654863446811022883780535313
        );
        vk.IC[34] = Pairing.G1Point(
            11535386348368381924065722754355931049325434524699214740293300803960358106588,
            21398253826232665686882433573463657716063143248973788759773172959423112151878
        );
        vk.IC[35] = Pairing.G1Point(
            18451370367738506120965007894366658624214716316085260525673971021432472197293,
            19101417489148907606211081022387849857480904287520249699894260948536123077855
        );
        vk.IC[36] = Pairing.G1Point(
            17778976142809120640916793716510901317798727650030951253589409592596569421083,
            3609841200268568601876004235818424154443409076584149412058157751496814922026
        );
        vk.IC[37] = Pairing.G1Point(
            2641803373831486662109078076356418053820812154954848799586660464527150280163,
            13876514899637998832703166652953490113248119762841190436765717527653257311418
        );
        vk.IC[38] = Pairing.G1Point(
            2958805585239092324278267285334124001527525396408427790889262477558347092817,
            14738218639574093115487073824028100040189995016890814282359242312524939678754
        );
        vk.IC[39] = Pairing.G1Point(
            3390992439713490993206248014690168697781377335892162574565796374982996630682,
            11952535532340137372146913420032583577575643409408526408052005165984842311452
        );
        vk.IC[40] = Pairing.G1Point(
            16953776787403774169096293080417707066576044885144409041621062195764398982083,
            20699726619201240557620111391670313715093760271771308830127038634916566335498
        );
        vk.IC[41] = Pairing.G1Point(
            9107352588608117042107447017128951736161010067385391485079069044004458857141,
            4449917119004491723632434167759745942046159011014320825889742278212284690382
        );
        vk.IC[42] = Pairing.G1Point(
            10725430078372518844925716212823264267635140552856789567190957018610034302958,
            5121413390234188033967817404942972338937497262690014172470269194631808979728
        );
        vk.IC[43] = Pairing.G1Point(
            10565429417044738428997827344486528114362694549779509928151955242818397498310,
            20297913453711554694587540228757074369297730233981928177229439792179539752121
        );
        vk.IC[44] = Pairing.G1Point(
            7366573227330466639960875981193535159898769045244093675492285372231156590835,
            9935748721816471984978278456813606589892509391703841958402020724187741122797
        );
        vk.IC[45] = Pairing.G1Point(
            341338383791071933464432080422461300126030195125982100441253970147730942929,
            21424290652842520769815989534312945583408764705034470298872605103957579343128
        );
        vk.IC[46] = Pairing.G1Point(
            8629914149590326708180725142073921928024066539180077831389189040905193332696,
            21744562632672271386355762387921715760509077990698751288171282593517897884170
        );
        vk.IC[47] = Pairing.G1Point(
            15052080507794603271534786036950634605296977406774539468807555451901648016051,
            702968765516049236308060386755609061441797986759572685844612870171869747424
        );
        vk.IC[48] = Pairing.G1Point(
            14850277541933502651957056554723264617858317757582491325875017380499860730837,
            10905422059712109950612196565010824471111572609160762756744222054821610464616
        );
        vk.IC[49] = Pairing.G1Point(
            6574788796740719992518701633099377159452331675727898121764872125434319627729,
            11956641381355637176668573452392297393132986569445804998860468992002232039643
        );
        vk.IC[50] = Pairing.G1Point(
            247057951385800885684879808271301671946554750316997438752794894751222522131,
            15017373806085864151569383407001969093171881971529593529166785604931149876615
        );
        vk.IC[51] = Pairing.G1Point(
            17029278804292943436034429989193580563454676443215681578256129644041596407651,
            19996892332235187725168369799588929808567670448449521626042174334373870060745
        );
        vk.IC[52] = Pairing.G1Point(
            16657911952746835852172569190424207759445714521916036389182246555038720621800,
            946753181518765639245108758734061567305005995001999186769062924398615568561
        );
        vk.IC[53] = Pairing.G1Point(
            19550425437032732705570148032072553042381835439888538185201927591817688082518,
            7225412581504934765618613248299018852653929573163994182428705826916404682656
        );
        vk.IC[54] = Pairing.G1Point(
            539297671971385379354117821516888331885017115342311681888943736988511661731,
            10052470809623056405346611241920856076836688509850299290587985019615317092207
        );
        vk.IC[55] = Pairing.G1Point(
            13499068293125807818734411661795560885164621459326333680406092636700256161433,
            4049854458178386256511756502826837365729276790127470400423661435142629224498
        );
        vk.IC[56] = Pairing.G1Point(
            21552339470019273248721923825888578240109326611089738757991236277298153692244,
            15232849253418249557445022150342805104434306514583691881537676688065933867403
        );
        vk.IC[57] = Pairing.G1Point(
            12026878565105215744748240374629714417093836680660631437398885356110407568488,
            20270430284405652609862627280356751215003387688999585802260605572113859610052
        );
        vk.IC[58] = Pairing.G1Point(
            15387332065262923311984357475552025713175298291130677398674119662576479476796,
            10384485705773328427139334445997504218136463724944083340296616338513635440698
        );
        vk.IC[59] = Pairing.G1Point(
            20426825480925250419112371100344763690912619134931265636823838780338530509202,
            8879092638290469595210146599185289601086272045919109646800230419177566247806
        );
        vk.IC[60] = Pairing.G1Point(
            2022776887960219863886928413371123464786078743092633544565181786691435602949,
            9680433865936171472464752281573445925365415041021004674416322534172534064550
        );
        vk.IC[61] = Pairing.G1Point(
            21112238076760531668592188895466860702782132889294720328835653344236830803496,
            16852645863656398802907185704129794680686526741241295403802514361794781269544
        );
        vk.IC[62] = Pairing.G1Point(
            19944062718539285413489259076801265139799427945994082085680390441208892442850,
            14293919020341464952915798470274247080528917318461554719062411274204801655398
        );
        vk.IC[63] = Pairing.G1Point(
            10430385838271845865232898874621044080502729144213427970719768420763713637774,
            2378966300934954817142290330047546680954866170499801441933827112405078841914
        );
        vk.IC[64] = Pairing.G1Point(
            993976196047448179271076424163557520654610603108020889176161923533681678532,
            1934066985311171379825031855230961797774075296386528844414236076690116868703
        );
        vk.IC[65] = Pairing.G1Point(
            6667329899805526676742832477230795505290027238157337863417940472323764348311,
            13045459534559057963855964646305626907179134291078744302295810661920839320254
        );
        vk.IC[66] = Pairing.G1Point(
            13930378722182230947150854335844868887184910676517316034769727641826017253357,
            4113541040113335894787399352217177250418592536137906120109309836138561544095
        );
        vk.IC[67] = Pairing.G1Point(
            16380035952061040059828995949577756039213229807774947660788231386157376654485,
            1025382510946899403172898281069524781268266031543909400164823731462973850015
        );
        vk.IC[68] = Pairing.G1Point(
            2857567402118356408876135028999607753244776855887744971735717162641633064660,
            12924113103734244770055476974528368403246237305746270936233012890861230078437
        );
        vk.IC[69] = Pairing.G1Point(
            5962386988390775538952903869339935737017770143266148175095799858328363694635,
            10563357132838552186869524248900526079987744454147251790223709652882309356649
        );
        vk.IC[70] = Pairing.G1Point(
            7518181461946324977242107991627343708960408032853587633911774982708761759830,
            4138168318759530873871277811103160431385140911720899656114977552708318453025
        );
        vk.IC[71] = Pairing.G1Point(
            8040803700239376129466201702289026660307729814953277573937600170765045532084,
            16929900065440281000765323857488293768516149878840491170821982709469408538761
        );
        vk.IC[72] = Pairing.G1Point(
            10631123896151667145006852008621266014960094150077443893566541035333013824886,
            20523102914409462076050365890156730249876242559270998800867088023069033741977
        );
        vk.IC[73] = Pairing.G1Point(
            1358000236104812220728784900077115115003044797276108527134953323902937434615,
            18213991679855299940210990975563414242226276524934199343854593233248383324570
        );
        vk.IC[74] = Pairing.G1Point(
            15589140404748973956179059761756855726607540766065807247552554512402571176898,
            14378305236080680585395710614243026585442519712248905439661810753725980022459
        );
        vk.IC[75] = Pairing.G1Point(
            17368301675365602348598518386808096206218897440759099682641886062685371725829,
            1129609095528172736444599689282252700572148215228822052071852258630282169651
        );
        vk.IC[76] = Pairing.G1Point(
            20571875036400644352717627570744433625866186664760316507015031051187977018602,
            5378858385062039139637092084540667310883035746087927289087346386317187691327
        );
        vk.IC[77] = Pairing.G1Point(
            12486543157028915681817415480679854924797012869599866808275474012144448749390,
            10461849819251345292264679431623005570703755850454392503695366402076604882856
        );
        vk.IC[78] = Pairing.G1Point(
            10363343315604949950969609436348862452046286349605290834456782133667385608303,
            3738527551072605272603369317728990754565341097355136578008939183225382848161
        );
        vk.IC[79] = Pairing.G1Point(
            1987624301984091208765321482368578260070437830706569628423042179281230237654,
            2335674275237973322650527407613610451243536585154718661738782340343121819968
        );
        vk.IC[80] = Pairing.G1Point(
            2442351114496765285764978551673486622125334900991231077782111226818854469119,
            3470171584035997173529715854825858127910648020949969107414395814088842416354
        );
        vk.IC[81] = Pairing.G1Point(
            21100997715377147277995015382989190956787454297874696308184230588608585243325,
            21260573319181392385422562447171262388751400951821232574331447537406559027647
        );
        vk.IC[82] = Pairing.G1Point(
            14202500881829565319555693953038809815745066964472551377137304252419737891438,
            658382451313406854223504891615552621514797661166262312412658392806482305667
        );
        vk.IC[83] = Pairing.G1Point(
            12232930950584947216077862265426391375792847185812652600356965439857557744480,
            9411891576100009651600954054305870342993184691859074262278268950704955364965
        );
        vk.IC[84] = Pairing.G1Point(
            1721887317756405951897919888385153887222924942350506907734841218129242967860,
            7373188733353648973993411437499142331149425898769650430931547526812581074618
        );
        vk.IC[85] = Pairing.G1Point(
            4097034057915745931201190693947141367125681993141758842233758036277023343259,
            9599365090124417012891416183000480117893598370785206051864459919981098065517
        );
        vk.IC[86] = Pairing.G1Point(
            18599106229266257427645498876273463919887954521596241080616612333432995585938,
            20654766320892646421708808797059879484933661224893206512239518243138841678105
        );
        vk.IC[87] = Pairing.G1Point(
            14105370095638274234551692006935274992208816262029284956360524855667606176065,
            4031542760447224313948769532164747661789469942308858690309687655751322839628
        );
        vk.IC[88] = Pairing.G1Point(
            3536713037860490959217457800726964097103396971472637530837864473442956715188,
            4166615481113141206794779621104778259086320933349862747208092943136669623124
        );
        vk.IC[89] = Pairing.G1Point(
            14745411627395045880998497964544825282945725792224950456124583126494639910543,
            3644908417538099322691699157624297722742212868865553431882592438964099213338
        );
        vk.IC[90] = Pairing.G1Point(
            5362159189551162952690304722532845813848952557234624088281573852440383797086,
            16030525587091938389790366311326005218362998478521548515953165588903380049424
        );
        vk.IC[91] = Pairing.G1Point(
            2978637476190722318266326257356493228050968466134224194483299255925575594562,
            11036187659584012912935709665917752077633410078428440941043130023520841718543
        );
        vk.IC[92] = Pairing.G1Point(
            12328925924631157245021932516034549830030585385817041439189685235251911835654,
            7847821893848840718763411220524836850433753620626543720963481114247851237487
        );
        vk.IC[93] = Pairing.G1Point(
            9591411343881477733190976303447954788496236179245585326788333242328001922038,
            3077754687254873782389581132817692530402679921733561439392579309466149887552
        );
        vk.IC[94] = Pairing.G1Point(
            20814863667574332130883449434046844877404489116717645622899395329667065983090,
            18812864671484473818539242000048282845765289909384900789067895672133650915304
        );
        vk.IC[95] = Pairing.G1Point(
            6333767269271100378618420376898679789977563087955945658203501535846406467690,
            10590789586800803545728579809638562913141033088184130587248802584118581461832
        );
        vk.IC[96] = Pairing.G1Point(
            18618656612694887128507841767810008268381119835553150303382032284802198737577,
            11644114306770764822462054176283434920208505228868684974256740054605881444665
        );
        vk.IC[97] = Pairing.G1Point(
            17800607081518628458319610739787535046067282111842134022144602824276450587197,
            20869526816508621346356273459941624010389344847165226401017237210934097812683
        );
        vk.IC[98] = Pairing.G1Point(
            9574637486721398420049251435375449719150884620942748128910068571538834938609,
            3666474208448401788328154542271433132620194053788181118576286369807277505379
        );
        vk.IC[99] = Pairing.G1Point(
            7910060900036588262960561887871072533258613094258645783137215622179446479974,
            9799739163117835561010803730567185667930459627808850415998870982018945140584
        );
        vk.IC[100] = Pairing.G1Point(
            16339302326415538363760030803504588999371197437177567465416125741178845897060,
            10674531603274107289270325500344570621377560272001370928239766642423310670856
        );
        vk.IC[101] = Pairing.G1Point(
            6812760338779129842132166055140843567649641933685413688321073883524708371048,
            16304030346790898788946042259267653259922506837271151710085982134649156876921
        );
        vk.IC[102] = Pairing.G1Point(
            11406252315257298612449582951509499537162916657090782054618936494457225847972,
            826749612571437524193871748824316870077769990838213789412479560762882899484
        );
        vk.IC[103] = Pairing.G1Point(
            428498273069186988236474419649238661089316111720590429303361382965977081107,
            11582951735586489877360812812742658505756378786675524077649646411749579841156
        );
        vk.IC[104] = Pairing.G1Point(
            21232815460012051207233113853120688848721974886324224819163358544160468564801,
            8378225657237750204188373870410282466091390920841113910846184247563578370271
        );
        vk.IC[105] = Pairing.G1Point(
            5728230943427191277156737690916386221512214920266255721780182032316408982429,
            8807769085331495004075856359000386968394939034004564275997451137005465557209
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
                7096410242873466601321623090691718141750102718617195660829820265143941309159,
                11880134873988840061809662774909958568320656324734986533066066709297107950531
            ],
            [
                18993338516649861502406199614541665567343350864564378857489440979688819594436,
                5835195051669566033138563286636307980001648263302603619507788235737400215182
            ]
        );
        vk.IC = new Pairing.G1Point[](107);
        vk.IC[0] = Pairing.G1Point(
            1062362341537085593708871369027446624278984382529161754805144237602133347850,
            12658220149099109329635008902054313550556689113171631741180712034156806916719
        );
        vk.IC[1] = Pairing.G1Point(
            3144075715733819893470974747840733119261429375737019069202347540317549049162,
            2495146751209351837041060427956777444615049616846854917231165631408469201943
        );
        vk.IC[2] = Pairing.G1Point(
            488603420372433411166991450791419802371086202826484976778912593193639717919,
            2664132466862180201788266203678029444725710656548563775276894010897149238013
        );
        vk.IC[3] = Pairing.G1Point(
            10701188589589794452040052310594962923492271845128956119845098555341399869689,
            3312336484099160577589089626288100189182916014108065428206911741066278569442
        );
        vk.IC[4] = Pairing.G1Point(
            9028052606067769655627345057863754113841538472428672778369513562111049159078,
            8165625714094810007938319143917063309680636076813589212449780603426615456199
        );
        vk.IC[5] = Pairing.G1Point(
            9474455886463126391001010895129759597417838427675001759518147713354296320115,
            9974412455012198892857516912134139292784657467420084949614429258211812395109
        );
        vk.IC[6] = Pairing.G1Point(
            18796878703670607230615706973107040883381587233752602783960457726503645918914,
            3217509355477378844431409469002929427494219585578470877268827807979426510856
        );
        vk.IC[7] = Pairing.G1Point(
            18577576076590089925566270478739259514387445976302332550313416192318725517428,
            3547723748992976485531005785276596804413844542273196853616619224639886579824
        );
        vk.IC[8] = Pairing.G1Point(
            17492806244283495505440300623897389416285312444130283869860767855660374936800,
            276378449845484409526503727526068513940653392715444401186698609759889369782
        );
        vk.IC[9] = Pairing.G1Point(
            6888958378737666634152622294969076469005916559972496452149360885554940993503,
            4426009670331455013390997820888642010697440337959598537625018573334758942999
        );
        vk.IC[10] = Pairing.G1Point(
            2018707226120526118452522686242819462407856073432863398118857547517298732359,
            18180295213466229191669231555483494374412009868772086328001259915439950525882
        );
        vk.IC[11] = Pairing.G1Point(
            1278807414509970751262619084703764444728901476193141701816625648877705803293,
            1056804690004578324692039461807562232297466402962614676203751190042728708181
        );
        vk.IC[12] = Pairing.G1Point(
            18226529166724226489921102650682475668860768965249753407884444417317709544389,
            15362610672974854976875168276462862321586501922398079935568604721028268985402
        );
        vk.IC[13] = Pairing.G1Point(
            2491536394761603708751953453609192645935100908857956232641061940908353089937,
            20011930657701587692145733378774657839063909475575242279625459592789796742601
        );
        vk.IC[14] = Pairing.G1Point(
            18117981920012823978751588629110372868970180526804090261571675096676264594058,
            4446085492537538109478390757505479492794872267917896374664807612082145533179
        );
        vk.IC[15] = Pairing.G1Point(
            9259891892935134445484315221911904535347887571486231124084071018432531651487,
            17373741036346926249009262972773180883556004866082698332058960393892383234215
        );
        vk.IC[16] = Pairing.G1Point(
            5777052538294019607467835021512029457868910980779748915130305880383206501551,
            16896884883278952569987683549325265753192108941822268229115257141920650598060
        );
        vk.IC[17] = Pairing.G1Point(
            1039025758957884537772084059229977809569526593829724996858182994428963550813,
            20292097264491316545801524982956960352408023883424510376038110230844866323528
        );
        vk.IC[18] = Pairing.G1Point(
            4898276547621508618086367710152018083406504190606664203136257874091694501990,
            10331963582276360953732902266039682086202801611258233650246571636888149194576
        );
        vk.IC[19] = Pairing.G1Point(
            9341617295699355072235204844086200234178455915692073258093036139117024953175,
            14770230341993239996468156313412159453553590748059749373994482204160402806619
        );
        vk.IC[20] = Pairing.G1Point(
            16652042181707494355702439950438923917636141848539215193464174293764237497853,
            19534351690182481944907602913142700612108967468059452219243656369062466289314
        );
        vk.IC[21] = Pairing.G1Point(
            9374682315345204714136727969164014240001809692790278977146419817056048541344,
            21498676307987898673344399227513487647354949104890654965820523247249873897801
        );
        vk.IC[22] = Pairing.G1Point(
            8220574930963336896090723428784992397679892473061365245901783941872528917445,
            3288218154614648333313401130502804237436358057597525289717734436971588415653
        );
        vk.IC[23] = Pairing.G1Point(
            1569789350674870562970655117638293715237038544972628819597383186459899664037,
            17772965462929148472284712298834076866620392183333529725970508977906788513789
        );
        vk.IC[24] = Pairing.G1Point(
            16136227500057579861919398497487024051619940046373875919545645972898877198567,
            11616763799676219464388517651233713785467826752995696826573847997776906346970
        );
        vk.IC[25] = Pairing.G1Point(
            10534980649493413255296425033329217192568665610301895557463519096690802536501,
            9127261058197686407252943303208821043897368460640251949222442586554341692108
        );
        vk.IC[26] = Pairing.G1Point(
            18003227331265287301387721040800298279165309815578454546550673909770115071778,
            17372223165827526503136054160338811229550984345403985633168564293861287330355
        );
        vk.IC[27] = Pairing.G1Point(
            18198475291923368341283225236202599252014154121133366691526555531193603014107,
            1583454961724635657155255611858931003148300773765647919341462219033911907900
        );
        vk.IC[28] = Pairing.G1Point(
            17422055153951640944887146861449752992208020593417393932948218858559153592184,
            13802662780532308367233509520391656513524834256729286565055644682280860837761
        );
        vk.IC[29] = Pairing.G1Point(
            15341181100254342117140970880717979837635084622877134682292117598582781486485,
            12941717313685515450174989027196234273580470381290932276226780452285213223419
        );
        vk.IC[30] = Pairing.G1Point(
            10359979830466330293287491458674777168406036876042114914340125750588969847921,
            16450754477632762446911780703625387810902833256222528206809864895401989622796
        );
        vk.IC[31] = Pairing.G1Point(
            19713978825877443117356025092720362486557162721904528945208502510381859749573,
            18033305539728965748769938651606972651691482696716255275710949532455012297625
        );
        vk.IC[32] = Pairing.G1Point(
            9992365221924608427740335667948901231672089007215228734572611440451712738831,
            6775990278622680086470181567092650960713287586866900439003322832496569573512
        );
        vk.IC[33] = Pairing.G1Point(
            2822516839954118456811487700678978345748254436407164551942070147635232067018,
            9975119006573550683203268508507262046592207552015041985578786497733065101639
        );
        vk.IC[34] = Pairing.G1Point(
            20379534882074320652116838664082834124277005512900222763311682158969237589944,
            9351052061965919202586008295791871072058069015146517895055890017034844995743
        );
        vk.IC[35] = Pairing.G1Point(
            10911477965479526718500915778606810950177433397111456869272331527685445828753,
            717148585258803360105779916479265251958213104784639473142435605590405957857
        );
        vk.IC[36] = Pairing.G1Point(
            1471215964291590523086092076867606835751318453702228572995116520522923567529,
            17366676964719240271541650200025627920126894451923930534479258690294275644885
        );
        vk.IC[37] = Pairing.G1Point(
            8890344582239423297901552549634859307565173012453037644240445246217632273185,
            1205919700845611150112816379875968837544016778035087410019856728129528979424
        );
        vk.IC[38] = Pairing.G1Point(
            18558843075737005101327927217262289358433670763472550831924324768811396209338,
            10490301974048153123763125039434064111083535598417208470314676689781807638051
        );
        vk.IC[39] = Pairing.G1Point(
            2325256984833461911125757484457800416207210523149990826414043079281226847476,
            21492940174469853646932468368089364615463541064892390840692998028666011426056
        );
        vk.IC[40] = Pairing.G1Point(
            11669704046568900344404368136160008371320958540898089606524257389851061873560,
            835849295146786891721222996205532634068617903849364372674627620106579574632
        );
        vk.IC[41] = Pairing.G1Point(
            9399761633545768196755310058854500088288357088745053629379880541327657573491,
            2415872948486055463987663343995767181282133674141326785693013200905857221801
        );
        vk.IC[42] = Pairing.G1Point(
            15928842864378838912036148706499418768415518966680062249394032603642481070795,
            13915430763184381611827630760524046957006422672574216302030816053114944741098
        );
        vk.IC[43] = Pairing.G1Point(
            12586091592040550815747978316316943508315796384394213735777212524339028553312,
            5392787765099199906272237349834458723202964532869011980769218136117711002481
        );
        vk.IC[44] = Pairing.G1Point(
            2171542734436375095892093540824380368589131399285383228110895320150684111158,
            9855095154570083172903275839434872342693583995636069613714123964956491922372
        );
        vk.IC[45] = Pairing.G1Point(
            17326875833603005028322446138446276485323350936638078755375096540982291192484,
            6100267258770355814919661562646584821907274768125364468018809678880405948842
        );
        vk.IC[46] = Pairing.G1Point(
            871346290050382619735288250467293710613892506251021110173291336949239633938,
            13375447752502321327463587571365627285792160974520149500537296624469975298589
        );
        vk.IC[47] = Pairing.G1Point(
            11977140317787908456375780314174240298826396016632742064688284463099414456539,
            14054342352720462522023083622362833161899052662276817214811834106519288266526
        );
        vk.IC[48] = Pairing.G1Point(
            14566347677357880527825507102359183382653475091980672731238868649350072348049,
            8031541820867374151219064832672647764654728479144887760053104242829498602030
        );
        vk.IC[49] = Pairing.G1Point(
            362415249345720765806762184259581121825796322262042888579133066027180497311,
            2046118883934916205024883673189253100365829653404910903955724686698077572330
        );
        vk.IC[50] = Pairing.G1Point(
            14179469598726204433882495375388974009747589739778518633050049509212049297823,
            6163296527397787128597506838112464201967866874548606736939217773833272864032
        );
        vk.IC[51] = Pairing.G1Point(
            13114796413307512389523726548766844754875240524104314264411217367044297397239,
            16485865890937408757414410058793439705772983229493430282622786698722973983440
        );
        vk.IC[52] = Pairing.G1Point(
            21786139697328554312278170341971098714619752013874859147192808936949232127954,
            17869239179665328193116322230734211898230349690529185693832906539637615125342
        );
        vk.IC[53] = Pairing.G1Point(
            20385327971096349327831207464463256916575528805952833615289335931615479248556,
            9799364537474188700491555067593334948782293872620857685689969719228826838298
        );
        vk.IC[54] = Pairing.G1Point(
            11285141528235837307603852521865827175194486049260498809413199734348456699896,
            7391142763328959328877591615675442113843939212447027036905788419467295975960
        );
        vk.IC[55] = Pairing.G1Point(
            10444196762684935633410458943386070954693467769219099191772429815424058084948,
            19212913180141442598150829056348709977896961411107581342855889029709562326243
        );
        vk.IC[56] = Pairing.G1Point(
            3215408221223250560363665923093427336831573357281261379996846369201331525239,
            19115628865616240945157671324225579313517565461244866343310899041151420554200
        );
        vk.IC[57] = Pairing.G1Point(
            16394705260730314796476921530643405153159782231746016413059430456649552752272,
            18864492868840559285942955007823277944876807272760330468308423742218597274036
        );
        vk.IC[58] = Pairing.G1Point(
            10205707503405825276010219918175720552045326980904272164826225047796351276309,
            5278589986939998558241429865526126252089814126596053253374217059697225315870
        );
        vk.IC[59] = Pairing.G1Point(
            12796421865920165004741748976903250103158569574981177941288236658808269434974,
            1175120284538973063513684523944575666301131826126746878820343115324213326458
        );
        vk.IC[60] = Pairing.G1Point(
            7103549468981158809513799203505329079264533823534608178878933153316344955544,
            6526763187711930722722084455391195032254581417940454635410871823140716748042
        );
        vk.IC[61] = Pairing.G1Point(
            6736280481074623843782966135028254611535198222132189471808380440735310640822,
            6878429996003294475149998593379974672828881507179328571646383314778459509393
        );
        vk.IC[62] = Pairing.G1Point(
            11483297169699179955883368387261844815947342801062828645745172067027510667901,
            21581758588488470275820691713182542401489876539838174294235121050523222507369
        );
        vk.IC[63] = Pairing.G1Point(
            3275967551082216465396426743404047545234143078826917399650330311212480660472,
            14381506906434029716161869436544339463669252178691888931820068392441880365218
        );
        vk.IC[64] = Pairing.G1Point(
            11566355621745179161512808197211039965144620805293824296613789780405094988404,
            7998139533790228480248232141071269034737500145553441088109593584976525080919
        );
        vk.IC[65] = Pairing.G1Point(
            19582781282176521110077485539699953298904465273289555571994185750220503121929,
            17926054783815211732930542355823711103995600273704781530255245108065701452880
        );
        vk.IC[66] = Pairing.G1Point(
            18662421486374677421433584753074728124319189704872196999437880081196837144225,
            16402227606548206530457345371872832892715247761059166211820039929522299551350
        );
        vk.IC[67] = Pairing.G1Point(
            6623091397923282286990407467488602939957157075616416124499866300635478454254,
            20481239805390136616243905609524635306610757230307048901352845822790244550476
        );
        vk.IC[68] = Pairing.G1Point(
            19123134391936320421737500283249765669797071059632425261044085163964761284251,
            8764862513414136755659291065709904392343495197733279000914304042444926652228
        );
        vk.IC[69] = Pairing.G1Point(
            12026647582032424632366927383406438947970455252367531971162406402114908741735,
            5153664917974104025844560039010998343829457809728104297736127537474456117399
        );
        vk.IC[70] = Pairing.G1Point(
            6182355148474410418483676062579709311991891588767973006594988936370135130923,
            10661692714214231516454923476430110826709783000821375952290837346735506253164
        );
        vk.IC[71] = Pairing.G1Point(
            1132926691145831875227376208083972108699980283345460101151072818028057443054,
            8989381840028494315624869383038675195297184470080894405279978500027700182857
        );
        vk.IC[72] = Pairing.G1Point(
            19505324202415532572699313036949328281339784598126856032646505376285637337715,
            18849711734487632870799520820756058792170325388992458532473625662166483233666
        );
        vk.IC[73] = Pairing.G1Point(
            17606583875799115920536565389367277984001848829462014236325931759511039022055,
            386445645650827875424144103964652270408743967581345583029920192128233232507
        );
        vk.IC[74] = Pairing.G1Point(
            2798305416721124715200421136320852242081945302355590573759520064763442580191,
            19498640752493070368141027457560650002512571557496148404388236355943976507932
        );
        vk.IC[75] = Pairing.G1Point(
            463718855077777802314116425934913914570988537091920543783988194583372570569,
            10730858545278380923043828280587382793768990097641166767077778652188779978579
        );
        vk.IC[76] = Pairing.G1Point(
            10869799220769344509624669180268924598909504011935495465940105551468870155251,
            3060272054021182359578268716240557563255423109942768092806808954329062283563
        );
        vk.IC[77] = Pairing.G1Point(
            8218296800744154526115156187582474747960895103633881039238541162538789831760,
            17088858822278870817299037905408218703428203966604314478776096118596831402530
        );
        vk.IC[78] = Pairing.G1Point(
            578290987016342197514386862377754126449493640825990632100952053747533867406,
            18894219266365520025576164898227575297427084762215403203534389012432709110331
        );
        vk.IC[79] = Pairing.G1Point(
            20759395644755688883680267652912113556629232751006144063389034836920581307364,
            3041869541704053037701450874132707876091411813215431839749148881732127648692
        );
        vk.IC[80] = Pairing.G1Point(
            4180138123411146079937246379683794539171376767798212467419436061315426240319,
            16791289977628166562376459758906735271909723226168849967807817399289847335906
        );
        vk.IC[81] = Pairing.G1Point(
            15252105449803640756891953727216639282443195481413100054292750588301937719145,
            18093120765184032808777744387645087166762633967411877612871265789397171912131
        );
        vk.IC[82] = Pairing.G1Point(
            3998831688335807186229067421149179300413537193331357418642642728424431738132,
            17795110700721012946547157195595376853635379381864865809502469973780674638606
        );
        vk.IC[83] = Pairing.G1Point(
            2182917333795098348335213003653840498918103592809228575204523885618502906215,
            15230377056072372732063795184487334402650028840723202168173127398905680866720
        );
        vk.IC[84] = Pairing.G1Point(
            17215903263148272098310022752832415859906396238320647414068614397797138672831,
            18942082588448938084483306698192130830619382675495594051374670238781812816695
        );
        vk.IC[85] = Pairing.G1Point(
            2070526543105051667484873398930978873440755023584960203126350899404969638432,
            2413448227006638597936768082656835046896642438310543171248058394884874443948
        );
        vk.IC[86] = Pairing.G1Point(
            18522898013309444610416770784593789686918127584607436538358253606699129401837,
            1570329298679840519484462023439863194417044419159767015941216598890182151208
        );
        vk.IC[87] = Pairing.G1Point(
            13584925425224802345460684027961551787767605182857164696097977523257464679047,
            19548218842288898039562067662406982552788677881725540092316708945668004063172
        );
        vk.IC[88] = Pairing.G1Point(
            11428804221538707359352319290043292290186145438846707630414011175489716152591,
            9421994240451103054097935425252845493941603571855927487635826748872876364207
        );
        vk.IC[89] = Pairing.G1Point(
            8398898062351405062131784078663038781327953552910187439618089076591789578225,
            1686646980463296089895176663331240721007235191831045733579379669957152678909
        );
        vk.IC[90] = Pairing.G1Point(
            19526656596674717580456451981101411811177782232846123692763017972039293197885,
            14386782238326878063112473881186520610302497835156692824421544327696616012688
        );
        vk.IC[91] = Pairing.G1Point(
            15901789594835096096437633066675551267070188241724620483121553561514818012061,
            3976358078037281208839152121273964009730092169776442222732967540080317436370
        );
        vk.IC[92] = Pairing.G1Point(
            4997024632422265083323440975768469403191478571672665929754566829963765176126,
            3100000424083041272784709551858664036836348014485018720874667947573306722644
        );
        vk.IC[93] = Pairing.G1Point(
            5486699581383073424512315197062196021318871230744005894304401321888151647823,
            4423347668511090607895971820716676299752680036471929002629229905097206506728
        );
        vk.IC[94] = Pairing.G1Point(
            21243015300533064315816561632460724945243486973090645107497081350847278083364,
            7728789315279407097949215283283736295196294188231172060632461720426032904719
        );
        vk.IC[95] = Pairing.G1Point(
            4567144095592299478609389486759292662619975141796690145262101935022413209082,
            13348205515485875268116024078365103636409080790436825291378825765676929179704
        );
        vk.IC[96] = Pairing.G1Point(
            12081167848422270448330617673223570551546081457619520992175378123557246644849,
            13627796001252247609156433218057794519752326880961464053506637022114844739787
        );
        vk.IC[97] = Pairing.G1Point(
            12593376018970596686003936782604727598650521986507082477721019168255496403351,
            5344196477949564762417226175306568374146400665305895183432756739696799201251
        );
        vk.IC[98] = Pairing.G1Point(
            7346355628202918702505812069658003142908022347844743378848482629004376281260,
            14524251097098769766539683234102716795402714241519227396660046107848510265321
        );
        vk.IC[99] = Pairing.G1Point(
            18521490764418036756564479864588178917807698523537967596815180624609026091387,
            4319215117631850445359917219909694199415136788335014324237531891006579000056
        );
        vk.IC[100] = Pairing.G1Point(
            2083141307246868875828181106809967374514902433689192407914721741623338134118,
            19419068196785963964445429538207651926932819112211121964456850309979589263411
        );
        vk.IC[101] = Pairing.G1Point(
            13575841269963971411101258701285703254235493058958650123584415556171000796592,
            1042214653682867924018254063468220602957104506881091363470971686917046740803
        );
        vk.IC[102] = Pairing.G1Point(
            4988331570864684067268039509821461641757282515860485719429576462556640566566,
            18973106920056920663940189535864402221414378492767956396230438630272322538001
        );
        vk.IC[103] = Pairing.G1Point(
            5808897521035394588501081419224151841975800974716803180741275060542698873191,
            2290340510735319996730177997043818786420513031170609362907248895657994432666
        );
        vk.IC[104] = Pairing.G1Point(
            16837731629910111880525628701249308706041924034686916105880318326636215137205,
            2976945915913738710332323168707780748764600850056095512279861944726068853992
        );
        vk.IC[105] = Pairing.G1Point(
            12519525766997618207301208724671471630124730057847566146274514484722199358442,
            5447531897451756151598331371363572119105374208997762656569313889383810499534
        );
        vk.IC[106] = Pairing.G1Point(
            9302462426726599360832869199433748598092211318038653253760592541291633578517,
            4877121757824659201427677131933047114079577341483035828125682438110902123793
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
                19950323297112686189028556420522028632638628372644134985718209997604368104840,
                18180989499101473046711733239411446761543593300294862094531374584804788996098
            ],
            [
                9083496207319286817035092912346792815787990626292432997575178162422531286010,
                12765443138068492847143133611178768718801736483538727795757648195251657834574
            ]
        );
        vk.IC = new Pairing.G1Point[](105);
        vk.IC[0] = Pairing.G1Point(
            20351024206541391489257237366493613267502358984459312556613003226443403410995,
            3645158317459121884948154946754967161045013248295902726600692868397459633363
        );
        vk.IC[1] = Pairing.G1Point(
            7616172385840983275379810090562537592390703129558584824985389703956079847321,
            16009484939453098359966937436868344752621904713665392557409242561992009987747
        );
        vk.IC[2] = Pairing.G1Point(
            4654299811401495606165578790930370353523375433323995532128953495211080279366,
            11083755355148710787855355313797976679382953406637269598185920744582303210172
        );
        vk.IC[3] = Pairing.G1Point(
            641394584216772941328419555613616871143953489025551767304823529213173475744,
            6661241773011856657624068108751344761678356831531961513552220420131706078178
        );
        vk.IC[4] = Pairing.G1Point(
            10927195898947186856473020587137826517147581720167181165642169397734378781664,
            19831592869415415591141047128439898629554702779462963642000513205876678707523
        );
        vk.IC[5] = Pairing.G1Point(
            21853007931717109561612435118222905124176655750839764934704075236905594474939,
            3905422232358813591203871854292425513035176232832000297799744538265110414708
        );
        vk.IC[6] = Pairing.G1Point(
            19526418074245226891896873630622087739285157454183628388798695009360330707551,
            9681538128907174017910258666672375364842301509830905357636822551304911915156
        );
        vk.IC[7] = Pairing.G1Point(
            8289272588301628071628559185982850439382040901000084199228450580202320123899,
            4167842716494176144711111277395637598310793698475429772118929255633018041891
        );
        vk.IC[8] = Pairing.G1Point(
            10310112009193990945108416365391558664143250774030783918665872542286913737508,
            7817263836166293807439876002632628624795335092920801521344443867652557074467
        );
        vk.IC[9] = Pairing.G1Point(
            9810934904269697831711133432533959956159742295716903557348343558557382607875,
            18885252720043982351131728990666556887188463375888891305957449668302681871852
        );
        vk.IC[10] = Pairing.G1Point(
            17510525976938143802745912517632930892625004590836837713590750109397463853415,
            5486312391648966739859555665236255420438266825142643882844772278396182241301
        );
        vk.IC[11] = Pairing.G1Point(
            2111206535033986561599161517427570990595621259459649415018880517510523545263,
            3702806349145910618787745859383749151051808912980162707681890544127763300349
        );
        vk.IC[12] = Pairing.G1Point(
            21139790060846059161525006521770124054713126998248113445101420496996706571284,
            16527907264324343079351114365396578561590582262488470510188800920589688087769
        );
        vk.IC[13] = Pairing.G1Point(
            9757210104715050505743855533084508343097201147575603207595500038256562381119,
            11570461292971986606265543360003365221144856907039980439276022728480438516176
        );
        vk.IC[14] = Pairing.G1Point(
            19763976229039556307180663500967738388582521800805906836866104904548246428313,
            21323126137368774883463015564847931554231104180785526370303890083587952995555
        );
        vk.IC[15] = Pairing.G1Point(
            13076837706147008037024958939706726009668394894018693833530675909924859540445,
            19121750720563817807787738026613532924539117372356406661878580315315226646634
        );
        vk.IC[16] = Pairing.G1Point(
            17947919438995177755127279395705591980765601677236768540758225499468877762976,
            17106542084011036371065083988907914167825847293051040486337412601685950157844
        );
        vk.IC[17] = Pairing.G1Point(
            14608845661713355379658214809916235145320110759063323041017245742524779028144,
            15853057666538355466924336463246685408230636077611786888034514919292758502584
        );
        vk.IC[18] = Pairing.G1Point(
            19594385271208296624510839215245511599272427578580570139359219844329148772470,
            12263458701001371000593045474642609008872905952022769824312372168549628292543
        );
        vk.IC[19] = Pairing.G1Point(
            10897222079908768447362420463421217997794688658409397233411485404222347957423,
            10592569930169639744483351098851212575171797416188065424559065057616487054110
        );
        vk.IC[20] = Pairing.G1Point(
            18221529809823445738160872336773056312112299127204055147902864533924847870405,
            2627363085480780625402915853647784569174352745407722656283589259840012928380
        );
        vk.IC[21] = Pairing.G1Point(
            20106993013409835411432515417585712873068173665913018744149758818400312385642,
            16896244956563260000727679666785656723138996735694575392566880367955703921075
        );
        vk.IC[22] = Pairing.G1Point(
            19942475945060725879878419265652589070827693769679749623500046335053178822292,
            4556963831034371084464589893808199594153263021932774621496078591037301702330
        );
        vk.IC[23] = Pairing.G1Point(
            4872504087321650800001320602782156242245136583479366721511310354970474099172,
            1920450023001425563213965323239574681398308347106088894279209312036323560148
        );
        vk.IC[24] = Pairing.G1Point(
            19237067871336119969099727273579627268363860625412380812948312052420643574701,
            16576199904160886518845493076683742319880321535036148290951190345031544886743
        );
        vk.IC[25] = Pairing.G1Point(
            16292443090364224690556939503481084586225835310073500949763576274155693647342,
            7398793333285458386673370820609195490290200069040972971505803494972398291378
        );
        vk.IC[26] = Pairing.G1Point(
            17885597785768269404784779697184659311898025407417002700235796605269275644809,
            12907665915554083483308118621023066133541460723226560686619448067488895992218
        );
        vk.IC[27] = Pairing.G1Point(
            12463782925257942888195147045333162524878549876351322531280502734880140543329,
            21686597615922220383275222929388380667090230720888913155229690799883866403295
        );
        vk.IC[28] = Pairing.G1Point(
            21375196904436176897982881636248037200910003488874397155661126881073146037326,
            12682226995205814945488891591030118424918027470008764369455453635907769033935
        );
        vk.IC[29] = Pairing.G1Point(
            3050233119070733626512897066447268285843991579994202877250692540965004855535,
            4490843452734452966350652584045913206335821838707372671974650265160690293041
        );
        vk.IC[30] = Pairing.G1Point(
            2003444793719219330163313604695756596530412816522123498300175637893495448758,
            18229599749517459863482026941773417543816999685719087910538306553547992185511
        );
        vk.IC[31] = Pairing.G1Point(
            1479376874726658297849931665985983252775996847093278986548539494117161393545,
            17880733995068319913143481616861156096266841803893691077678104673531409608200
        );
        vk.IC[32] = Pairing.G1Point(
            15839195755974902467784215965638589698283876916962844692544278689974133549608,
            11460346013637722807594290118681584650116711939499286402863468058828270563999
        );
        vk.IC[33] = Pairing.G1Point(
            1923993155036609393403293131673509203635165488101547595058539464188179539491,
            14319435518368779519691504834012799475226557540976373998259897337808647605233
        );
        vk.IC[34] = Pairing.G1Point(
            1436597175114928122064176287582443784182378011486996159145920437613828266235,
            9985686474860834762619212750927056790784060588437784229324567915299119167764
        );
        vk.IC[35] = Pairing.G1Point(
            14760673613560458543231912424287509378423301742287742415946907516799634539078,
            14589931874615487332880820990974517010861739741670577030023631031316593068995
        );
        vk.IC[36] = Pairing.G1Point(
            20798991903238322157081780086060503207608253129432006264393999205713368684963,
            7824321161676196127811217218829574884226244683259909970540146454192826971015
        );
        vk.IC[37] = Pairing.G1Point(
            11496796430752736745817261021762981635314298050570132768685897520790079299209,
            12768096130516013300623174283724244832936390377464916092326459758377616031359
        );
        vk.IC[38] = Pairing.G1Point(
            19360255455766595043532766100709540754823018798070757778753647442491412056765,
            16602263746973925823913299320512135545244602380576169406391564418133309156317
        );
        vk.IC[39] = Pairing.G1Point(
            18570326742245544509672752212265287284706435622943310727387691156835711222734,
            7279921681916485085668618878839309811757872893320509522504097842601744711879
        );
        vk.IC[40] = Pairing.G1Point(
            9387722602846466779588685419668670555892940842994893323695211888061753285837,
            2105894230762888191174515857158051662724469594061639645505873625846591398480
        );
        vk.IC[41] = Pairing.G1Point(
            3066931281197431026969370906865294570607144631864164786160352012757267038647,
            2207645814698113255574131785738125702003380500371976419572094080732272033031
        );
        vk.IC[42] = Pairing.G1Point(
            10643221815328144124728253338161527898223968703017985077764650819329969520284,
            2430917680826234213649681943365701928469814796258841419805463389483776565016
        );
        vk.IC[43] = Pairing.G1Point(
            7777305953729717167224717552812576870684506832639637296896848349313734579650,
            19546341569478449958910176321726703637406743453670224479616943086826041802466
        );
        vk.IC[44] = Pairing.G1Point(
            8029770253769490216585681559595133622897064950864242060660095724448473146171,
            20988515363359252729372867569569173034029046897508339301079808788208624049699
        );
        vk.IC[45] = Pairing.G1Point(
            2678377727518894980534681107495482879380991351970348979763880995886346550623,
            7281945111454478808289004853409625554184611695263887237727961883177065602115
        );
        vk.IC[46] = Pairing.G1Point(
            21432033777302108000363487973110924309836666044936764434471733333217350447753,
            10983587870184921385775932999268935534647963330873435209530969744122878464749
        );
        vk.IC[47] = Pairing.G1Point(
            21034768798040082649376094296518581377746079908228350525807322658846445937748,
            7700305362423751199305672815976828515396241595387450252396234486768593362955
        );
        vk.IC[48] = Pairing.G1Point(
            1896859659727316513959247190316727635226329410498662284267894085143529725759,
            368058541573159044940171376208411986221531057122424096630032384751541691697
        );
        vk.IC[49] = Pairing.G1Point(
            13590423095042508420151610707469530717716333274931422099463756227641462707526,
            1018819930092304690351356026323506199182738473331924345666751616553218188054
        );
        vk.IC[50] = Pairing.G1Point(
            20539743469925396757128751974348482129226654399095134627706098739523066382476,
            17085664182263437906084405414397261058197181270398699297548902016254662665506
        );
        vk.IC[51] = Pairing.G1Point(
            681423251821487369366763116457327726520015546091619076267985957440858688638,
            10093156561957887403655512211807949116147493626355973503841068827339440270876
        );
        vk.IC[52] = Pairing.G1Point(
            5014279645052126040532794161756122168072674556551296124531053469237454502043,
            19275208951712378872755708100061386879129122556472587182227026802327872148606
        );
        vk.IC[53] = Pairing.G1Point(
            6227710885883814353983749871413860889451615675830453825688203830215122126868,
            16718308487286682787794182873235180371712753037861480863401984821548950431834
        );
        vk.IC[54] = Pairing.G1Point(
            3227815555123802846537744100729823013599074356007857517430885673813672816960,
            13117084470462041746507706689797696655448335752598609186505723043615545342236
        );
        vk.IC[55] = Pairing.G1Point(
            20343913160099751007598389712712589633929281810812175050325726249845029133171,
            18416497665372064118959314496192048524996770906207648556436450455044394336478
        );
        vk.IC[56] = Pairing.G1Point(
            14806926806486156827039389053217140528942734685375820220678994406987651394409,
            17335306663865094055630044168272639070014148012149812456262742870303344418965
        );
        vk.IC[57] = Pairing.G1Point(
            10427536746554076828150295450743375862995331107140736795991742707588860034210,
            18070145065729973259540275420974016954026519129725618892406091126068391015299
        );
        vk.IC[58] = Pairing.G1Point(
            17106238602761602827436582571666319084522972305635012688383067502534334649887,
            2033438971061952235182133101442418965830023428118244594744169650543091334649
        );
        vk.IC[59] = Pairing.G1Point(
            13360368157087830278966850911124831567501234241515235241237455233852051613167,
            15577566182323102844933296550168636007317009384032254500167097167008014879520
        );
        vk.IC[60] = Pairing.G1Point(
            18392039456955531519258172626870347571184676624679087214165179232073389455734,
            15508833536412891672880188159645469744832797700063097983786309252225298483786
        );
        vk.IC[61] = Pairing.G1Point(
            7079266927811781492284081663360193609057977319765434948775404225685759359354,
            6976037856925742828812599768258747095226844367178856038701888938448816943471
        );
        vk.IC[62] = Pairing.G1Point(
            16257305768531014378081833208354947928856510586704426463463530139283342386597,
            7210075050886537330987372181584115890289047582505770288572390406175413233796
        );
        vk.IC[63] = Pairing.G1Point(
            4627296004159187024884975182995720493864146685546866019664115407604708112136,
            2042800859153367769703016499647062792165589391959821663513279596502007244337
        );
        vk.IC[64] = Pairing.G1Point(
            2333899400852945582256430465204262026787178927117538267787676489137833208105,
            15756908184733637767658940187348088924232914410554488673546705240188592097591
        );
        vk.IC[65] = Pairing.G1Point(
            17593870544658076723593694809878856700283099408612085812854168300704472583957,
            4910251501031757964989882372196501094784687325641969068345718510783140504178
        );
        vk.IC[66] = Pairing.G1Point(
            5514831375884930548738737963155825081048392730053256699305278920333677368209,
            20088999384266041818340490450729025071591199670049902037526595084057647193764
        );
        vk.IC[67] = Pairing.G1Point(
            598316892590229586516620128009562066226390067228443001949487661476372451238,
            20843237472183674081544048451140095677085252097768303542073637140598464016730
        );
        vk.IC[68] = Pairing.G1Point(
            875911028443436796169626044208950148979578892869091989416209488851810703508,
            19823795900568126826619636987550651928087181140730233720496550960285434034806
        );
        vk.IC[69] = Pairing.G1Point(
            13646304991619708978970569015320600099036880728599004564528294998163571455129,
            11706464694659466519471754615339222903598643042792373922079557624800359942364
        );
        vk.IC[70] = Pairing.G1Point(
            3747748871975556720686664201474605983201096387612575422101733747536666782206,
            19539185592480921505064176451766115718581279789169754045686780043613384581676
        );
        vk.IC[71] = Pairing.G1Point(
            15162987693130650971173748096338564542527495732408862724403051783250712496175,
            16217071976226639560170354851343573937691232170306059307056136028173946123772
        );
        vk.IC[72] = Pairing.G1Point(
            16492513538087115879151258998701627199832818662125179130713646124853520015536,
            13882449920746097216565435261164570744479374719805528173437522647715976440594
        );
        vk.IC[73] = Pairing.G1Point(
            7713060169507422582185854259008661117076016025041101966481764286581334175016,
            12911293632439987540500883520329634330295254425377641964118159135570031343351
        );
        vk.IC[74] = Pairing.G1Point(
            8609085713814696566495433207237656090663383088432060550267930967811809713692,
            10288227421712176067443662973190797470592064790782792983236414245893080350095
        );
        vk.IC[75] = Pairing.G1Point(
            14680963071955413602106892205231107042035378042820529392577563117856402490132,
            9478408974426300638179623590717990595709981900895219024859680918735248447044
        );
        vk.IC[76] = Pairing.G1Point(
            15321974468683615523636373381047435008110872586824468218484606730182651954873,
            16962000396101127415810448435322560405711463080995461506828657919525515148144
        );
        vk.IC[77] = Pairing.G1Point(
            16240334231052126945027795773297595893296727753225356074934425740981603821032,
            14141991343402718604166102395106709115621812848155131385190950793295346253550
        );
        vk.IC[78] = Pairing.G1Point(
            14051410715937917045261709241672827451954281850658600037032583665029734924106,
            13349399087453196908857618946357215060440168273682324594391354117695007129513
        );
        vk.IC[79] = Pairing.G1Point(
            6198567131986061296051973684946976571809740220442369070424539141575262780571,
            7153870856181553618762489695461641526829698619579032449895557490865479567558
        );
        vk.IC[80] = Pairing.G1Point(
            5507724697569144137428670598611667206405486838072386574320786285530729005516,
            20667215961973652017147565443774216203993261816499291493250712845496624770842
        );
        vk.IC[81] = Pairing.G1Point(
            6794036718944414977066099766200920643413686408916976632230682689762719786340,
            15124430725984531687983034830715701216752065604408242270224326752922934392363
        );
        vk.IC[82] = Pairing.G1Point(
            21344277906789853364659074422202797434840938077591492434262068943492663083002,
            21360247883461923912214526985258673723768704130848955818663099969803786825657
        );
        vk.IC[83] = Pairing.G1Point(
            4986547634405196711162410216277809858808414253560561246569692881129613078009,
            11775674985462088064887707838795012625320099833903418662949358980726512263694
        );
        vk.IC[84] = Pairing.G1Point(
            20666075831103571972497924916623785562693977677685089260071398281061549953885,
            3422642860839009373677719430127949705671939412636702522934534132391955465108
        );
        vk.IC[85] = Pairing.G1Point(
            1955025155527260842017963869340629822312326864771387617504389094381423292800,
            8532532701550565806225365020852787951304689519600298051034708962376385209827
        );
        vk.IC[86] = Pairing.G1Point(
            11256260953877925298950838100676446345094520329015876408930437892170988147170,
            11171116578942337563335197255223292692057253044252505642648868316886600609897
        );
        vk.IC[87] = Pairing.G1Point(
            2680033339402334155434453502472120113271451433603120735035394997307381717881,
            19786783493497535405149962089468882307910275046296045258862914936402301755704
        );
        vk.IC[88] = Pairing.G1Point(
            6793700645550392274200269952907959782043992334782329553440423175160376674566,
            6313889563513620628948364599798180111387060836363886020637202896638011704930
        );
        vk.IC[89] = Pairing.G1Point(
            17964233428545953850485510547459374115480895025655781215506930385634709421843,
            15349070961408554947241106031869085511675208917883085181426532734141578037092
        );
        vk.IC[90] = Pairing.G1Point(
            21681930416642840655383241099275723116677577204104223583348754638874592659927,
            16228566580338344098559766964577296883080711304003207029602208890333338260245
        );
        vk.IC[91] = Pairing.G1Point(
            17482136462453767318580221560971402056407190382525898417037119516948295630974,
            12105528511333173789013594105419360844897972347520429177778341143828635014307
        );
        vk.IC[92] = Pairing.G1Point(
            21143303940340826072738754726721053883694903668994823015486623705400453823806,
            7092009613734629620671869888970447036740221978099693121192578492122489304197
        );
        vk.IC[93] = Pairing.G1Point(
            16786138021266659080203277848272843956994165257113600179822155618925181885765,
            17638828916577351468227568780237019807752703930575374145224269742105612013128
        );
        vk.IC[94] = Pairing.G1Point(
            13726552368400745669648320137950331533286713289400312506063731478406508834218,
            9328836712212365161233776538031906636330094898548606938961924293277905903281
        );
        vk.IC[95] = Pairing.G1Point(
            16199082792003528486182507883789467696505138738884505402861937351826601949236,
            20040524437426087650017294788574752913119313155977929395544440838508866917598
        );
        vk.IC[96] = Pairing.G1Point(
            13460436350443649589210907394276978338212164406694288340964750748843183957916,
            6258924143599977670693782816205781884354921986929684712545169373248862215050
        );
        vk.IC[97] = Pairing.G1Point(
            18792944386893525759186849402996640636347622979974638784910903702569482993131,
            4146911180087166456633159951141838402997882001994579912423933336526889825103
        );
        vk.IC[98] = Pairing.G1Point(
            5168884467024342499335742301788380375186996525317332836818312320036027876917,
            8593830500243089393436851994749667767454383000070747853547990751582157787916
        );
        vk.IC[99] = Pairing.G1Point(
            18348525893691021383162029408165378729413875497533141155637888130379716473489,
            17947955987685279994578173468341646540684585080655372243115747380259685508553
        );
        vk.IC[100] = Pairing.G1Point(
            1209893008975975582565183367270114371593028188971111353358642325084644387859,
            4496044205559274315965744628034392431604436910583742240464055787170143752331
        );
        vk.IC[101] = Pairing.G1Point(
            17890794499597994437274540477699680259495448143352162293235262735249671252,
            3318080742092880831767460063692671999917157273051979775312181504956913680679
        );
        vk.IC[102] = Pairing.G1Point(
            781197095302102015497818483468537304530592002579598322381991486900502432619,
            2481462765266187027737682499958712498304753086926831682891310103391093155988
        );
        vk.IC[103] = Pairing.G1Point(
            1157032882050556923856931418956665649835754971708395611726399341586093542170,
            12277463919974239721645303403680307545281879684120978981011738233256140952736
        );
        vk.IC[104] = Pairing.G1Point(
            18416115841974014369173199365742656968249880153140246419106835447603499260367,
            20651467440249688097229319671850781323084006116974569506645487278471901758970
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