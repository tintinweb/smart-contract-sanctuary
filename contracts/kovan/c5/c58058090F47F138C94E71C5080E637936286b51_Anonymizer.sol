/**
 *Submitted for verification at Etherscan.io on 2021-04-23
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

    function init(
        address[TOKENS_NUMBER] calldata tokens,
        address _uniswap
    ) external {
        uniswap = IUniswap(_uniswap);
        _tokens = tokens;
    }

    function() external payable { }

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
                address token = _tokens[i-1];
                _doTokenDeposit(token, tokensAmounts[i]);
            }
        }
    }

    function processDeposit(uint256[] memory tokensAmounts) internal {
        _checkEthDeposit(tokensAmounts[0]);
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (tokensAmounts[i] != 0) {
                address token = _tokens[i-1];
                _doTokenDeposit(token, tokensAmounts[i]);
            }
        }
    }

    function processSwap(uint256 amountFrom, uint256 indexFrom, uint256 amountTo, uint256 indexTo) internal {
        require(indexFrom != indexTo, "Anonymizer: FROM and TO addresses should be different");
        emit log("start swap");
        if (indexFrom == 0 || indexTo == 0) {
            if(indexFrom == 0) {
                address tokenTo = _tokens[indexTo-1];
                _ethToToken(amountFrom, amountTo, tokenTo);
            } else {
                address tokenFrom = _tokens[indexFrom-1];
                _tokenToEth(amountFrom, amountTo, tokenFrom);
            }
        }
        else {
            address tokenFrom = _tokens[indexFrom-1];
            address tokenTo = _tokens[indexTo-1];
            _tokenToToken(amountFrom, tokenFrom, amountTo, tokenTo);
        }
    }

    function processWithdraw(uint256[] memory deltas, address recepient) internal {
        if (deltas[0] != 0) {
            TransferHelper.safeTransferETH(recepient, deltas[0]);
        }
        for (uint256 i = 1; i < CURRENCIES_NUMBER; i++) {
            if (deltas[i] != 0) {
                address token = _tokens[i-1];
                _doTokenWithdraw(token, deltas[i], recepient);
            }
        }
    }

    function _checkEthDeposit(uint256 value) private view {
        require(msg.value == value, "Attached ether amount does not correspond to the declared amount");
    }

    function _doTokenDeposit(address token, uint256 value) private {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            value
        );
    }

    function _doTokenWithdraw(address token, uint256 value, address recepient) private {
        TransferHelper.safeTransfer(
            token,
            recepient,
            value
        );
    }

    function _ethToToken(uint256 amountFrom, uint256 amountTo, address tokenTo) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = tokenTo;
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactETHForTokens.value(amountFrom)(amountTo, path, address(this), deadline);
    }

    function _tokenToEth (uint256 amountFrom, uint256 amountTo, address tokenFrom) private returns (uint256[] memory amounts){
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

    function _tokenToToken (uint256 amountFrom, address tokenFrom, uint256 amountTo, address tokenTo) private returns (uint256[] memory amounts) {
        TransferHelper.safeApprove(tokenFrom, address(uniswap), amountFrom);
        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenTo;
        uint256 deadline = block.timestamp + 15;
        amounts = uniswap.swapExactTokensForTokens(amountFrom, amountTo, path, address(this), deadline);
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
pragma solidity ^0.5.17;


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
                4383861016832059016386250726896800658632611600888942317876519217997584140916,
                14990251994136783751695049323682680887846206473595963594833539709630695322249
            ],
            [
                18976321729921211179117660057447666620752361081251436602239028881105533319806,
                11064661060318484569013844934915395881391234862624011164194189059041794493445
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
pragma solidity ^0.5.17;


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
                18814200626418426061282920015939359126275432286579877404880583119204846383625,
                19287834893022640948115154095581747482476406727915156348768910537347942630567
            ],
            [
                1190434996602393366993099025659883191646013834068715005244456305779836957137,
                20549053459825766787459354269264344797377064245240944913235442488706034663715
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
pragma solidity ^0.5.17 ;


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
                6591109781969371130681939356736690552149240822386987197388834543242399508420,
                13864023448314256270690380716148297242940478728930151719877378684744348370202
            ],
            [
                5074053149113783133666127988447661204186867094817315291375264862640149876681,
                11982031710998129728393352556487131230924999595568827981681662516725924973437
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
pragma solidity ^0.5.17;


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
                732204535633756750553707728093599432550464419576661956826118743618358720868,
                14861389349209067254948331450079698707557970247326853643771750701827141363416
            ],
            [
                16712121931581708182587590155958402285297774800953787815486028613569629039213,
                144120186636796836828040044925468325571332449217898069554491941212418534471
            ]
        );
        vk.IC = new Pairing.G1Point[](106);
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
            14858927061396133884784020294111548498516638220381378785022027560688007253094,
            20099125440492102114862299108902952978193715526989698906378878541797304251225
        );
        vk.IC[6] = Pairing.G1Point(
            2232824830998817277086847616563315088805389696361427055711284313122959199211,
            2026605202980327050070672341397160884897009885937384335788292996319267429357
        );
        vk.IC[7] = Pairing.G1Point(
            12677988441284447465230244960266652508999591796636508640047963936995941680839,
            7931964869044353834747636057808828361046234108756076354711199068952410366383
        );
        vk.IC[8] = Pairing.G1Point(
            14655733622296872390783544941041570883285294574850493763813813342416814427900,
            9405117317501825931484374590297051806248424192729397456138660975739794850515
        );
        vk.IC[9] = Pairing.G1Point(
            3825045398074246724940386046470629940526556052182920227048005587914023182175,
            11053003302199554030867474205938291858449270420772958378160940050630727494043
        );
        vk.IC[10] = Pairing.G1Point(
            13670990695323896268644219340484130445450922559696943377645713317322262932671,
            5692198431313417396916873554794798288838603700726648899601282923817711907734
        );
        vk.IC[11] = Pairing.G1Point(
            17671761384823492550852536068896289999657368091313498378130368540726369570908,
            9022552516247068406459512840184747784834915104113651476755972266936409641879
        );
        vk.IC[12] = Pairing.G1Point(
            6394404729408349650890452909335238634331696636799252085124298257832204963561,
            382855815683615935110486852954461491764460008482526687659184308159891695484
        );
        vk.IC[13] = Pairing.G1Point(
            3605924907687972199953008450238955343672137789894771395907853555771916894760,
            17391114794519361420476644797065539349163635733782675551765140393912265202200
        );
        vk.IC[14] = Pairing.G1Point(
            6866187779214154232189261691510168204265313546082443693261188776581913533060,
            17002694354709338936477166221205652838451390600128466556294173995822845967793
        );
        vk.IC[15] = Pairing.G1Point(
            17755140604687134912710989379979598912640618978492610974214045165865553497951,
            18760957719140011500137657149397902733231971060780070612412793567713193662437
        );
        vk.IC[16] = Pairing.G1Point(
            8433169499064440581751433170632626270025214278532571704215164673237041912566,
            19269462965294217068339850018223090747810359627122876748665304064774880868511
        );
        vk.IC[17] = Pairing.G1Point(
            19808057979168289048883601903949702369545925202962803810330623377933274878900,
            1844084201813542058860404218996171059723742462494206513165269856528701098149
        );
        vk.IC[18] = Pairing.G1Point(
            17064328213544230111334124957541308448872535186010278781267870520743295026466,
            6641484702895837228573426112919242248112022402011088010482881714164423440090
        );
        vk.IC[19] = Pairing.G1Point(
            9884993940674395120578438895190043435516595079823660141314836807821843366314,
            15352999093727349778613671917807553020674195119787784117859050292521847687090
        );
        vk.IC[20] = Pairing.G1Point(
            1587467235148049168097821401788538622220238570396920543638789912827431348127,
            9591623436619982562330170333905127536791755708623472622577040860948252313816
        );
        vk.IC[21] = Pairing.G1Point(
            8904458753418618564135929603529143273204672568671351242438072964878120061408,
            6477051006344580052745530685766754903024203501216623902194993492853881809840
        );
        vk.IC[22] = Pairing.G1Point(
            7545570048898470460500271189732837073554435513142987890155534293391393025429,
            19091214950832986304999903464374974099618388739471571245938633366949775860552
        );
        vk.IC[23] = Pairing.G1Point(
            6005892574633690130228085869918907989179586148917026699428192629454035505887,
            21848655862042902308838006313975174986108683031729337314256612791274226795583
        );
        vk.IC[24] = Pairing.G1Point(
            14569636036678529127048747813947823583737355347745047110669814199680419871137,
            4852275510693520620049133256799416580720483728517293117832387691135488919033
        );
        vk.IC[25] = Pairing.G1Point(
            4712165733645729052727066866727279898911263951148673275489782889403122351624,
            10051863800711838521247303827686076081115855815597139799403908023471285635093
        );
        vk.IC[26] = Pairing.G1Point(
            20594775084489870526574908683641743536423391687768160213977555902588031063418,
            16535742747676026758032596720140185376440446058943511477136658291052646934380
        );
        vk.IC[27] = Pairing.G1Point(
            8255093683605314867646038041673484125191867193587610522874791069506722315660,
            21039682238875554719645635499188094233834425000343224588816931424844046501202
        );
        vk.IC[28] = Pairing.G1Point(
            3008776922599077334593842485219605134189484941663759705871399470997960387584,
            21558697178324562033518086643863330059968593120810990733704642440779732310311
        );
        vk.IC[29] = Pairing.G1Point(
            900486115872644935742966885771459915635620303423162388586106317364879221013,
            19153591540451693415954664647073557917654177045438978697775021171053637276736
        );
        vk.IC[30] = Pairing.G1Point(
            4386395820331569064281320935081244160255612571182635311244666264931895353332,
            8881722377768281233823076789102530150743347321866989014025625872041059308154
        );
        vk.IC[31] = Pairing.G1Point(
            18252867236255614994056683242868298700764392767865280094649765460200887258569,
            8659745154613811403940687059005434042432021366669124193655367732769606914169
        );
        vk.IC[32] = Pairing.G1Point(
            8567376006441903294124657854488423380679597368395554214957330975688436090210,
            6212993056045629426173100048209760705527351817986104564579983997830830869791
        );
        vk.IC[33] = Pairing.G1Point(
            21633472661405682144009362629818954389444456407321094294891789546896498438497,
            10179303920173319340330662092237172795169091299210078133766712341964853285322
        );
        vk.IC[34] = Pairing.G1Point(
            10567780794203365124539781834527982987603341431807439875401180920112207652700,
            747212444217671318021673821265808600217626739953799909602252688927863731163
        );
        vk.IC[35] = Pairing.G1Point(
            17099041983212682441343696509375537022265608891688656756434540918426142762375,
            5439069081831392260133040952156528734861341532813255041410376210368001631368
        );
        vk.IC[36] = Pairing.G1Point(
            20945963068257844487839047450582474994953474368388048743353821046449810552803,
            9470288750995526785840265545297896365001047293839229089530555965283550567604
        );
        vk.IC[37] = Pairing.G1Point(
            1254659718333029851438615750100377593628502032002600218245533961750755227862,
            17274223026062135218831865840505246606378866208091884850844721975725101224151
        );
        vk.IC[38] = Pairing.G1Point(
            2628021241685624062479767212549418908869803719524831856669714488384501503703,
            21046279741918955229883014186584434974136216959484716789603621136802892060187
        );
        vk.IC[39] = Pairing.G1Point(
            18649011191925650755403303244265868224801693957573910946285514446695541041256,
            14307575541717614970941681721483965315519032002469481066075115773221369235880
        );
        vk.IC[40] = Pairing.G1Point(
            18879107474022743078568343485446030516870818792067838877882157426105620582160,
            1027284816263208980068023980147343400389651063287915689226961923492603726015
        );
        vk.IC[41] = Pairing.G1Point(
            14345857953384132340987651821224686059603071211493899697812204304813597322218,
            15365997593469540156998944081658607928700926548867767538648595021964240049183
        );
        vk.IC[42] = Pairing.G1Point(
            9306433216539063557825428342005377224308221205572803127161996119879823346650,
            16103542050886062864495952391867880406273954173030926163358661446433202931838
        );
        vk.IC[43] = Pairing.G1Point(
            13732136862505797274204884095708797500260160499595350457835241286715213130714,
            13626896653633236883091951077445321762020615930243986464174321052581203881560
        );
        vk.IC[44] = Pairing.G1Point(
            92860674724446979441063226893266277898211347946636960636122044820397422419,
            13563443709266723972480948194833123361638921215864975900546474814917509626146
        );
        vk.IC[45] = Pairing.G1Point(
            17994056553941190121961649490662927247372932096915371743275370579071944676495,
            13725198086022461305671942089520336066892174433703663093548077960049566446562
        );
        vk.IC[46] = Pairing.G1Point(
            2687613067001964310463329697644254294747503383040783927186154269008115828775,
            18826298775554656606188309396305858354719148767371347666170083720378986364864
        );
        vk.IC[47] = Pairing.G1Point(
            5728073834803361879004326431264058038779496720748013588631420583906612500120,
            6788616350183334674716698856177207015470136530986429318570209260333782031342
        );
        vk.IC[48] = Pairing.G1Point(
            11083116243652369868483189729383680341436338399929053034100373023995304417640,
            319412292619748767341306558980917103387200766154938696643492197044675402939
        );
        vk.IC[49] = Pairing.G1Point(
            7718111569907918124969420199568631468653693370511735561273329763524933999811,
            2879244389469108401218952748024640760428132971849638209368453229839729314766
        );
        vk.IC[50] = Pairing.G1Point(
            16158563835199064141482986718490689742049104815759894902974556185663565649296,
            20051863480008184736114141104440057445112054744476198479760929269242706556940
        );
        vk.IC[51] = Pairing.G1Point(
            17660678266230227078753136978961437119099162668148566045778509939284093377976,
            16008089796760380844530400623597305620196155257757001341795331403699537542860
        );
        vk.IC[52] = Pairing.G1Point(
            18023869615881217840810403147847535943862273790818910758797294050228290468823,
            6935282486633683947943477820462915686905225304121333773703987006762721955988
        );
        vk.IC[53] = Pairing.G1Point(
            2406977695004375178703239291283091249796224726112334559227079057504216636184,
            12592285386581054384737170896843303391739753438081125599767813614116553292117
        );
        vk.IC[54] = Pairing.G1Point(
            13415823602939625653227332346208127354406246984662504507347339191797042529251,
            1333684364272422702906755009390472577257015981223114677314747353747449096173
        );
        vk.IC[55] = Pairing.G1Point(
            8436526629674308415198761494248924023290511178326072110753461111805464479901,
            6413119637550724277245254114420016698579549335275104050154275830160687766684
        );
        vk.IC[56] = Pairing.G1Point(
            3772168555836954457641193653977088401008841594115621516995061685823049443197,
            20024320005215933253924509531440684559493777791046200843277329922845732870779
        );
        vk.IC[57] = Pairing.G1Point(
            3828899655977980628872484881904276149057983328937467157591596493207222589617,
            4404951109604056659504503946580742461810617613908247924493112745028750581550
        );
        vk.IC[58] = Pairing.G1Point(
            18704821733550979156354557524639005370086559181131229914397690064381297884736,
            2599801729191683837409303966407291164991178325199417819987985334095954864658
        );
        vk.IC[59] = Pairing.G1Point(
            12930091463877891237208571884890748694248252907519827619026416172155846072802,
            953941032526846088378871445461135217931675487787968339732212868188786329675
        );
        vk.IC[60] = Pairing.G1Point(
            18576864910824638894304971102035526840281204249180107141672945055637830725238,
            17205008020492229098907355844758133291298014843651584731487562093588052833176
        );
        vk.IC[61] = Pairing.G1Point(
            14067857706558405601927172543025076438996151045521045635564354692522451400930,
            16557323130126305073521756821238263045667529857878043854581490679937558031199
        );
        vk.IC[62] = Pairing.G1Point(
            5028766360813509808865914542652298042592214389299108032666619281629586857565,
            5316976921091935800213202370559270084446072796081665131944607170230281730381
        );
        vk.IC[63] = Pairing.G1Point(
            682348535979638464185642791613678175095199518896074275153223802600044689589,
            718566155979186858189832230075340382261709133644436297015302729155363535426
        );
        vk.IC[64] = Pairing.G1Point(
            17064159078684362437041118676177930813200924696514944742177492053225577296602,
            7197240127315580723813573883324552258083413921134379099879288093355460457603
        );
        vk.IC[65] = Pairing.G1Point(
            3632869577295305891536585998726912067417504120010081986109446055691842674194,
            4089780912434420635309718893051346714431346551583078340363445468409099950445
        );
        vk.IC[66] = Pairing.G1Point(
            15908857505614696863723208034718162776790037712920787796877432588321681295098,
            17844310928098476412511313985266222406210514568235882410883147401285932918720
        );
        vk.IC[67] = Pairing.G1Point(
            13739927528003126029359494579688980108219687365409183025155943948630058494610,
            15976961547394388896065609304111037047206761720510674328567566773421159566395
        );
        vk.IC[68] = Pairing.G1Point(
            1749377079948352369480434966070950714998053476538718926818027250496591906186,
            11379545883150880160198335468640281917156153598386082706866855819428035071993
        );
        vk.IC[69] = Pairing.G1Point(
            14391220679249757243358377044704816680155829016900453802721043040621287043475,
            17062173789965866976685514486666565816207490096345679511082048750862787606993
        );
        vk.IC[70] = Pairing.G1Point(
            13782160242249058461539152228692136192477679453377338252126679308214950705588,
            20716719071525611337330917864671901878250509368530988178888006547153648754297
        );
        vk.IC[71] = Pairing.G1Point(
            18485336380776823373883172590089670985250627893829455165898721656818546009578,
            20140615152376483154152167965390444013090202312608477045981874747123352787434
        );
        vk.IC[72] = Pairing.G1Point(
            19677503167498990530916082725625456297540119646480684949685345140331123049855,
            10978587889579349536648272748193920787508385115752298587593130371815687941034
        );
        vk.IC[73] = Pairing.G1Point(
            17947573310707070970744986658210970042629097331876356083032058101221934190374,
            14001291828596088119064544914582086255158742333742929203777682891447538688826
        );
        vk.IC[74] = Pairing.G1Point(
            474225909114485653774277264287324981673852307216166329139864566188379974795,
            21424067100783699058633343745659099573444213611417456967945746468390345830969
        );
        vk.IC[75] = Pairing.G1Point(
            1603936807258114354207396017256653316856934939757641580958773991442666987400,
            6168551148855251041265095571245595729909168280974995261638716889312775919508
        );
        vk.IC[76] = Pairing.G1Point(
            6609869491657677691010729303992178353153785557557347119352458190804905451927,
            18105570509810952867271523454704354071917796645196017429088743606741889011041
        );
        vk.IC[77] = Pairing.G1Point(
            14876402227481666467426732760049980595217023466647827463221237951454551136276,
            915720485249108626420417104110370496761990881808780953821853294479880435783
        );
        vk.IC[78] = Pairing.G1Point(
            16603244988681732807498186871493278579508557403436406966966029402778744715661,
            8139813769749039500004954164620570429701184487273135608454021285863896618638
        );
        vk.IC[79] = Pairing.G1Point(
            12604628497853273606274940673051142237487376332051123089204666334914526983799,
            17620435214639848215659812336929007791369362430577062553039356529367661492632
        );
        vk.IC[80] = Pairing.G1Point(
            18025480356028741109261439818555210580346145819132010537712439004714019539802,
            15315577094692636819123091878371702693628482640644062557844535659985217177064
        );
        vk.IC[81] = Pairing.G1Point(
            20103933740745087706512361326684870929588808515717371599934104215293095994987,
            14441923061781118943116991275406867072925780558992361735351507563234742325090
        );
        vk.IC[82] = Pairing.G1Point(
            6722692573041641985270738943905709535394324807140070132608649185602352937618,
            21857278740779537815286790174476419830040291402587091932617664298212957274729
        );
        vk.IC[83] = Pairing.G1Point(
            21664482518196606956478287102829788589351779584331500979188778713450044370099,
            1551960926087956012296097436241327356229572635719291317992904683599808902390
        );
        vk.IC[84] = Pairing.G1Point(
            20319597332932826376727858643424692550224060693346399523772395080899241408681,
            15042488623642248834612205063441778887897453214889028347524100006639639566042
        );
        vk.IC[85] = Pairing.G1Point(
            10254263575938711156161653000024981380345916017966493283409814609520363151076,
            14982717640191550365209500487431301118428176824080026801164364371607232778161
        );
        vk.IC[86] = Pairing.G1Point(
            4764997449564752779104587113595224515858960088481691419441849147163764058066,
            13421722203995325301597291808637932898323646889571573148538012995523923731915
        );
        vk.IC[87] = Pairing.G1Point(
            3934989117295881735740408564002061229288568006117076634734010481643113383470,
            2727505519828259105623456502969826208549042764507095280973065548099382791425
        );
        vk.IC[88] = Pairing.G1Point(
            1633385930254379476594617849260114256880634230830482894934588925226190306221,
            13430762242183303927030891635925788259396676169489934245330021830714116306856
        );
        vk.IC[89] = Pairing.G1Point(
            7890942107840484525841265892282306042192674215678185252218938246581926506470,
            7320460073498619739551230044194581667593216960626120913695588573791336129690
        );
        vk.IC[90] = Pairing.G1Point(
            13168290163129909001555586262073071013751605643736131989044670316977007567468,
            6610836382424647591590007829844492001250100284360127042972738051063327165069
        );
        vk.IC[91] = Pairing.G1Point(
            1544257547022580509676303719259043479294585199861221820845384356273958117796,
            13770200919650774015905513528723642181265438764322022536763147308221989426136
        );
        vk.IC[92] = Pairing.G1Point(
            5718785322510578291268737092658685905312606134375047621026225751023603717378,
            13681513215348268903144703004938499779754016443583316472185682135847532959592
        );
        vk.IC[93] = Pairing.G1Point(
            5869397855004135421447988147813102093813679398876316443247901880131074888656,
            15182847287040528232303447574377458963663158847116913798258969062966514499879
        );
        vk.IC[94] = Pairing.G1Point(
            518853804129550330564806975459499552432525179174974716141775068355285737918,
            657254866165761709987995062694806260709867620438423203371677022871101345500
        );
        vk.IC[95] = Pairing.G1Point(
            14556437157156575022417897620423289390055788165697020247011024597617444222364,
            10450577294965176682569774043528272267228685958471821276031086831422208703473
        );
        vk.IC[96] = Pairing.G1Point(
            1611842700371143036344245786491314143687069938750870348281530799656250498410,
            21646290833259426269340952154159281993852656341128324538665236492631074525477
        );
        vk.IC[97] = Pairing.G1Point(
            1331103953229953633136683996917042480889350645424951742959452566400395260667,
            20962150554216281576498623151372480618882479158601932710555853893031996740928
        );
        vk.IC[98] = Pairing.G1Point(
            10698358390715085507310972608931336828261430432335944061363221724621227096250,
            21391717259454842280689573696037629177282936056260755764496587932819168998165
        );
        vk.IC[99] = Pairing.G1Point(
            9576539666730439818910321320533034206869643772128460831441986472070582443413,
            14756211471842146145510897218455435918626009330556403522636571848953905589903
        );
        vk.IC[100] = Pairing.G1Point(
            386748534145557926809296273680062507333001016614763902913381998689812096733,
            13958532416318557274097878970897420006180469933457410666290602329803534516887
        );
        vk.IC[101] = Pairing.G1Point(
            4529034552698037910460606552879310214522932099494725387522810592558979391072,
            3729017507026049256419873258432566101904345831237403490310936650544152279067
        );
        vk.IC[102] = Pairing.G1Point(
            940515387328207678005498654831094967244265709992753823344131813324539224986,
            14764556700114585397280666992965740871917034279964276765946665176143286769655
        );
        vk.IC[103] = Pairing.G1Point(
            21846967930486185000676530139599937346415359078292169305742071623758462435863,
            20878914252787565564588287873524086356489654175468612021800002994544629321782
        );
        vk.IC[104] = Pairing.G1Point(
            18753907149875349688409956279324411118125055265369434141053697847003525483012,
            6257373260755635874670020486394496080309460144302684931185756212477753185797
        );
        vk.IC[105] = Pairing.G1Point(
            12504414417328603891518214409989167098527071011951112991320373024874049985047,
            18221277248958734269184007235156719850249663924232600584497857971360965080046
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
pragma solidity ^0.5.17;


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
                1393034571823783926936851936198323538559187028996963713362450497552850199717,
                7276558037910997296123293030198380832947665178252240413024004502053775837385
            ],
            [
                6055354409305330137839152881498780242448251596348700099128755358067839375451,
                15056742982352215513531447144872616932593712284321169355581448032113268406318
            ]
        );
        vk.IC = new Pairing.G1Point[](104);
        vk.IC[0] = Pairing.G1Point(
            6181597783339572518709688365042066378880789369550396417178453505625579433319,
            12123553893380551573227387523727670204202232737203253699142906752952369360710
        );
        vk.IC[1] = Pairing.G1Point(
            12653036590637638269162731080552519087313243166075526268082059850610295338310,
            21299261183501517132114418929794556832281250312921878023893858591282492159230
        );
        vk.IC[2] = Pairing.G1Point(
            3154534058731316865652779173815908718192760270342163700524003892843706846571,
            17709893909786183203947681633341799999258363349361028922593511927000375919246
        );
        vk.IC[3] = Pairing.G1Point(
            1165135163687007529663743149823220121223685390202247830007591260221798820990,
            11059255354502751592593508664548916767017171170645137148962012340808704903854
        );
        vk.IC[4] = Pairing.G1Point(
            6024366401942954572760908045173680136550401256436623655267635382031132682475,
            8580358115796266338793749178787949276746718562136038441811947904008258022824
        );
        vk.IC[5] = Pairing.G1Point(
            19781328146407607018344124642866018218752060383100805830822602292410840748995,
            16962793322280764800260632904948616572717388687571147720887610527079072440789
        );
        vk.IC[6] = Pairing.G1Point(
            20982619110729837473433279619931371427706869782545974884395520172284284782697,
            12022542972919113548521513621064984072754560887048021359528501942528730740067
        );
        vk.IC[7] = Pairing.G1Point(
            17600842308513921725471906541147741620214927157050050064660492108739789758673,
            18281220710027666056676176286662484575245275450674128170702646265322529828117
        );
        vk.IC[8] = Pairing.G1Point(
            218666938215363675014704096159903696131331954685109223422543613477177908656,
            7673245544149976381675008789535885193176770544638315859834024299141841152322
        );
        vk.IC[9] = Pairing.G1Point(
            9241535911516328939829892827188097204035826447694737048282290057353506831672,
            17349310527555884455206827507078576509295839707037169675458070829994672779048
        );
        vk.IC[10] = Pairing.G1Point(
            7871518885997305785400961165744579410156082478476152370341791269739350652804,
            10225866981890197275927369722929024053925837147993204557943476115369927290617
        );
        vk.IC[11] = Pairing.G1Point(
            18038345763121834797355596772985154633305082637704657024506181306148130071563,
            8618907012401474566331473192455988254042155165184206872719671091414426943316
        );
        vk.IC[12] = Pairing.G1Point(
            5566726428231464793342458646170365043362695748817888800232023357431240047550,
            9284374840357122133828482925411621488633434934742707396078953135147467063056
        );
        vk.IC[13] = Pairing.G1Point(
            1710111257383797574934506369145870574141013403729625681818816545695346824000,
            1314304378407124322173960088161079244314288382082872408793430857040225625651
        );
        vk.IC[14] = Pairing.G1Point(
            15392696160724670476441310092042995769310562847913784546642563250685057254970,
            16015804824200405696056580866311773769332284817177866580811017407045998726779
        );
        vk.IC[15] = Pairing.G1Point(
            696057075467387491159688055653240831756271271731772431693307315455977410217,
            4980311938356848855483269962553530679245410603174014466002643894025785472561
        );
        vk.IC[16] = Pairing.G1Point(
            5889285087681007155944966557149177671282301647763851513266391062935005210958,
            18245127443734441213560945310623800163778365371278518224900229186787246212755
        );
        vk.IC[17] = Pairing.G1Point(
            16265611369366377163025504764551865333604561178895041330067784078992669425126,
            9570855275517834712060272419481074031687957544734297587833948546270840053404
        );
        vk.IC[18] = Pairing.G1Point(
            13808864404572513953404605463815046602330317572480844275550608422060514831697,
            3758829667591264376966602282686018757584865181592552885957992829148158819687
        );
        vk.IC[19] = Pairing.G1Point(
            3959459875279211393810708970278018551701929164238984370749963746651518514227,
            15194597442213600674422010647943579555323763972500656638717015194175118913602
        );
        vk.IC[20] = Pairing.G1Point(
            6854315530714692443829568954426894431961290840248701327921800725792325344233,
            1193475816905148550151280623679395266052513776148429873960092241057184188144
        );
        vk.IC[21] = Pairing.G1Point(
            1211472044871320902447495531938317860419493923300959271965806280602858322557,
            12000385188754142194446787788833135510006037332528491874238692991789392035241
        );
        vk.IC[22] = Pairing.G1Point(
            3090848253754216348795760010575464338101737040845796414788647204346455950380,
            9028978275641853351654252421657296128978584857715594293721022187972329874658
        );
        vk.IC[23] = Pairing.G1Point(
            20953422982041781487421017649087337992288216098567810388155028651331243287269,
            17212473478379483311334344850820876220492441178290949245587063336476594645580
        );
        vk.IC[24] = Pairing.G1Point(
            12607689925212843686572249251642524955776137718182906687184257329213538028672,
            10295353774475506420731530159180111974719810938968215109019384814675274596604
        );
        vk.IC[25] = Pairing.G1Point(
            13624602493587604016945996410690607497664937154107522270340966095591548613751,
            11100917695698673568730463431863760685253463004350837417917328718105885881688
        );
        vk.IC[26] = Pairing.G1Point(
            11542908832036386720341593610912150683001246569062625004828561340087532638099,
            11992368502973231445942893176835976255299254684213708969159390684704974209112
        );
        vk.IC[27] = Pairing.G1Point(
            19489862340898771679161807291546909418368512300808611601155200980473040391040,
            18129165509173543476729094876552752829363447420772803889283797662483077380545
        );
        vk.IC[28] = Pairing.G1Point(
            7547906762782494143671170738935321823635727038952920686575935331819680271850,
            17897638339134904040605856636670789461605618255795513383609853692018063884671
        );
        vk.IC[29] = Pairing.G1Point(
            15762602523091021886154561250262918090423183167070567602626561038787861770606,
            21425396041708249547833774697484125532508581818375384110379224416946640896892
        );
        vk.IC[30] = Pairing.G1Point(
            7721083898982027523214785574193414929729088696151213390034446283969422376995,
            10228094698378727099486018412593995993331522223458942467600762887124144668223
        );
        vk.IC[31] = Pairing.G1Point(
            4968549198593475326721160456557041626426548381957915383037402109471177997607,
            581887069888598052933641683030986430940654727266135256719155777822940958847
        );
        vk.IC[32] = Pairing.G1Point(
            1056473146713440278938520367136920758456631516535590207691194319840612767854,
            8314821020874195606864772933897471803397798803520144708850425772409051724706
        );
        vk.IC[33] = Pairing.G1Point(
            2727133541094406690514351615183845129395259826036803337280525274567142446635,
            15687777834791799293398909191209095761215885810997868883732661328834337302417
        );
        vk.IC[34] = Pairing.G1Point(
            11391862344373471263154910875214396780523023829778970805949953773560247513744,
            21342776056431025244878372006663940073675782914965170711696798150764557945657
        );
        vk.IC[35] = Pairing.G1Point(
            8150159341541346169478393523432621160757501383714615135735113887938862216590,
            13825780085397657727599499152422512744320368579393775069917504005124673785974
        );
        vk.IC[36] = Pairing.G1Point(
            10551434655652503062580887262960090857778310433801705103758300271062142909264,
            17770710316403129459677124881147978683527842365657047129656869505302422209566
        );
        vk.IC[37] = Pairing.G1Point(
            2892613282111112182326676182781220080549311088465933759051022692179261313336,
            15866604536527439698574746676044692603054038976263383409715130669549958538018
        );
        vk.IC[38] = Pairing.G1Point(
            5248148737897931061626565767793666862577049865581328810989588163564088491543,
            19665510653448974661811785767069102881553180486502852344236344424607680794647
        );
        vk.IC[39] = Pairing.G1Point(
            3607489158488725101507938724588043357511898060388789767827210448937863140642,
            8740847517381333255840262904474674442600136094034473872966701337670720656852
        );
        vk.IC[40] = Pairing.G1Point(
            14968715396096428611659164941701408912198014336267651459396990939707110066077,
            14262637818210970890484051251641905345264552399291022984275994248999600635797
        );
        vk.IC[41] = Pairing.G1Point(
            10354774610043932055304524185518440433873796224501441291190285316377932659430,
            15672872759119420939692926904790086443576765934714571430896791798082028917968
        );
        vk.IC[42] = Pairing.G1Point(
            12799001119113479386552193612146627595115082554715758680027131456559831576404,
            21586114856201874682577555796576613121752710633888415057053981663523888268235
        );
        vk.IC[43] = Pairing.G1Point(
            15592132775157044586810859675424938138176233941215713602016774692306046201033,
            20239366184682907818597877492732208869885846375046165749580323614901674569844
        );
        vk.IC[44] = Pairing.G1Point(
            2664757877677014837415690828246327015682023815131179177245244962490416528994,
            16490154547632301894185804784475934975605511846894095815764867315124266504009
        );
        vk.IC[45] = Pairing.G1Point(
            15052447710326434915082265505252652178533776625660963422621870049269233961787,
            17765725964781337294432843419680017116153965018610387173880797155127967605636
        );
        vk.IC[46] = Pairing.G1Point(
            16051747302147287121799583854989496495670152805175070320395676692810881169217,
            12557491171387105828684142343798212884574257463056435280466818003518051900584
        );
        vk.IC[47] = Pairing.G1Point(
            15744834331358144640055700208716732630945116159368517183813012553736156409795,
            5805794086585098523373174117181643259415680453119555789923818511629919869884
        );
        vk.IC[48] = Pairing.G1Point(
            15990903385871831766891706158562057247445390101090247354795724931634181200018,
            10308116578161348646162152015063670862663632536553710678750347267062721205139
        );
        vk.IC[49] = Pairing.G1Point(
            17884750699834433951113928312736353874885471668601227725078756599297094513362,
            21406067108564966506684144938165199399000699525961132405535274896439447473874
        );
        vk.IC[50] = Pairing.G1Point(
            3460900615433499424796456087363152607200368588316992523451628503702368754226,
            17175666953411609686081863358928364981293125978212997433421453548186220478875
        );
        vk.IC[51] = Pairing.G1Point(
            14664822257063009445287807658304518889895842016747522263790505698177325767825,
            9688662385269985812781026362442404414596136447280362485656257240139935249247
        );
        vk.IC[52] = Pairing.G1Point(
            5014678554911810438932408712362682701483943620524733852732423131266734935336,
            13552678582585472657623674693715027148113976636880446443407660129567626776434
        );
        vk.IC[53] = Pairing.G1Point(
            6009677557347648632715835822299792350926591906459887170509097874746951508192,
            15936301064541629115938290753684020155973873311827939014442090451775726861566
        );
        vk.IC[54] = Pairing.G1Point(
            7356163313160496595878475111149284668823166188780079095427673482630283927812,
            16030692813120256488252371918522518927043195154432082684037435478791872374922
        );
        vk.IC[55] = Pairing.G1Point(
            13371415653522264036702987393291622519685747874132498809708875676279564389717,
            16256888553718807330928758210921020042404121436014303449124228957067167815710
        );
        vk.IC[56] = Pairing.G1Point(
            20679762001695125174088991652453770976379949078149376999716324909938189251927,
            13133377820917111019891106597331477271603657404720563724846492302807436381064
        );
        vk.IC[57] = Pairing.G1Point(
            16613124910005851763705855738726644033348276017938724459108110510153517682321,
            6002080328907573611763227960187535044775891827391821752374071830763667904792
        );
        vk.IC[58] = Pairing.G1Point(
            4173596530385320201799457196887842080856672878327049725978060030820541221386,
            4982978387264739381317175893226772176133937706883743637383747556503099116363
        );
        vk.IC[59] = Pairing.G1Point(
            14077347966763448187297941398598489964211880776837101741218366163905551794452,
            18308664361828776009669486696894926866251856521331808250719817169071219032107
        );
        vk.IC[60] = Pairing.G1Point(
            10279226234683703610763634061057534152304973947102575929701635833176444161306,
            19236111731338807993356196385923778329491447886164557389474538553126154716898
        );
        vk.IC[61] = Pairing.G1Point(
            3342015992983788638729433176039237791323625035339444393069402317981120045234,
            8257649600650253240589405685786127275527587888682895082324346477853990528442
        );
        vk.IC[62] = Pairing.G1Point(
            15909751526665533319516685800212298878261515520252430301781876760286510218855,
            6325895363020851370371532812026024540234697802894360470257352537069152807017
        );
        vk.IC[63] = Pairing.G1Point(
            3732775951431706565157049476533502954050362606428666931872674657255641057014,
            20486999908409808705815811928654095497411952677237899790923164341670146475510
        );
        vk.IC[64] = Pairing.G1Point(
            6831966901553771837051224682467996895569813956016182359579746907104700202022,
            20793147255284807915165950837145681487876832209481593253423058210513335462161
        );
        vk.IC[65] = Pairing.G1Point(
            3162084036747794505396197424606241500986345861776324342361391870647717075641,
            20445624059999144939044778892663336682950791815967571584662716586673945322935
        );
        vk.IC[66] = Pairing.G1Point(
            20048227094080782902500054194456608697757330292972372502516614426142829921014,
            18214453361738879919248221323087038151891322237604252997482064633302617870943
        );
        vk.IC[67] = Pairing.G1Point(
            715150888858751325229022006696828727675073478947414732116337155630809258529,
            17192167137624638733206889757130135692032794378416728382574507299204634112614
        );
        vk.IC[68] = Pairing.G1Point(
            3497311036606473192461260831335738650981432902752377194361468634989006775697,
            15066799643617957166620548425146859383764295815739857140628468986550022644906
        );
        vk.IC[69] = Pairing.G1Point(
            6864673079464990884330009028563575733406839980988139825737035633945547813110,
            10894581733205679397740609827846369402901431412124038630114070985587449156588
        );
        vk.IC[70] = Pairing.G1Point(
            4417961537063299438841248736950145986909084817949225864461265335424552542171,
            8308314538000974672757893497955956515136133880973831536164397823922224523711
        );
        vk.IC[71] = Pairing.G1Point(
            6636516112551572186337433245843516871229941392221251901792045266205741907129,
            17310067880049121042503690058838160385023106356337314941093925391625804892056
        );
        vk.IC[72] = Pairing.G1Point(
            6568932946805669918529533058546035769579191234631693612001250899817336782147,
            13552146405583604461405584477521110374375575218157786247649911695133349495129
        );
        vk.IC[73] = Pairing.G1Point(
            19684428931479138508848348105595525892899172274657012076565811326878140991824,
            8127797755544252717195139147073073825788246110313780747169008383428048788918
        );
        vk.IC[74] = Pairing.G1Point(
            3574059836033151044956244367589427273130954082062156835513210648727362922792,
            19628972014503099817314962775086978568418657377506780816991174459745706240376
        );
        vk.IC[75] = Pairing.G1Point(
            2186881360371631922627574267138623794606108536539612713437835251740083341881,
            4833359230629989863682845495550918910072263480348036225063450248340289039307
        );
        vk.IC[76] = Pairing.G1Point(
            997332324024570794764551641144948683788463320296932585243298706428136073577,
            9470844637247815355940114230473791325872823778742169280036706993380849317608
        );
        vk.IC[77] = Pairing.G1Point(
            5625310343143994140325095244867402617797451578194164066829804795646726039369,
            21684620300987782374056824471405053317672507077593099398990078218861733252466
        );
        vk.IC[78] = Pairing.G1Point(
            6085766305275551089767355775723867829408867922535238367867068739757246462391,
            3871716474079613467835298832094031948226406042287028521892234491147070860384
        );
        vk.IC[79] = Pairing.G1Point(
            3783007981892671465789925472870064937319228209068278350576494118414326437783,
            16361023126722651061970217815677035750486622084937467639312919702016725602987
        );
        vk.IC[80] = Pairing.G1Point(
            17865569904974353185981995113716951038079731235730126680929292818554523926085,
            5566832898309043965786669984240309071690628647823304698159411374642197051532
        );
        vk.IC[81] = Pairing.G1Point(
            18985715550904612117013972460823120329877391955370807261733895695178528309625,
            4314500896649267545996969822556773757910948471380742149796617435174644506050
        );
        vk.IC[82] = Pairing.G1Point(
            3646474512280819853267907449936046955160136868195604293492008888193885516124,
            3804676669060143627126078254000123971155071162630040519915805668549178229935
        );
        vk.IC[83] = Pairing.G1Point(
            6271307072073290443287735484096490811765921730563172828741271484605353741406,
            17638890858176756109577626558012248222026639389722630034646167332415195850329
        );
        vk.IC[84] = Pairing.G1Point(
            8838172115187254218729128425084716776802294585162438668621840695704338792844,
            19265713092736978607728356611597063032647998334017958680613923344337413817144
        );
        vk.IC[85] = Pairing.G1Point(
            10383251216456684676375666637900086527289746245385843650454660538404151866513,
            17790941479025750718641792999399803675805146949567585207881272051453885918055
        );
        vk.IC[86] = Pairing.G1Point(
            19428149929607200764435802087758056754060613145144150066683014465327553631861,
            18395252024056032074027845800984190372386267514807500378684644098368350804489
        );
        vk.IC[87] = Pairing.G1Point(
            1311833484166340419340796329991377600105600443110785499896849330594023195739,
            9463689761183328117100297981897187506601089735528339406301693396174378982424
        );
        vk.IC[88] = Pairing.G1Point(
            560920900938748354202036512200742076808792958753509506272094108576074288668,
            3520339832152454251491321227431119642195394155465271500447950622799339081074
        );
        vk.IC[89] = Pairing.G1Point(
            6303724067739289525502281595490876171766637890993807677226151965448038858703,
            19831480581061513482876928654096344640246919125567304091700948780404233371746
        );
        vk.IC[90] = Pairing.G1Point(
            10167712655937713563985329312667124434621566324949800275271627605556227778519,
            8583606191362047226547654275854338213203287864250590387574831791038581969178
        );
        vk.IC[91] = Pairing.G1Point(
            9382520638748524822574072861812202266912341537950555882529175796170555681273,
            9887860449531445569713780577631070910759402993018407222363800666836768107461
        );
        vk.IC[92] = Pairing.G1Point(
            14736298935893894942223886839462678457772087832428385951511123344834032178786,
            2908548702053211820240601960923333931654278214613225274115873685393486622518
        );
        vk.IC[93] = Pairing.G1Point(
            8281383441039695118678012428745529373697676449965600623270471225662408997354,
            13672428432134859036078970298577300344548247546917946690214031403980724109933
        );
        vk.IC[94] = Pairing.G1Point(
            6732998619345833010770795515328064170839927741381434333411899978643816488516,
            12540360122412585815669300847277465992489277091746492034644247576275113473075
        );
        vk.IC[95] = Pairing.G1Point(
            17398566542747493552248493723266981590435280953059299435477180112021135219905,
            19135535202747733986860095685171983734435750718177002315023659157987440656717
        );
        vk.IC[96] = Pairing.G1Point(
            16860750191786009162239765838583818514531490042469503286440943972059922583954,
            3670664994787419023444757812746667415338164120839208265059723434707635275590
        );
        vk.IC[97] = Pairing.G1Point(
            1976765161282682309488160540540699990763457150125664441959392965203978788979,
            8428181167227648813549680254718820633868384038126720071110704011204320334150
        );
        vk.IC[98] = Pairing.G1Point(
            9401371203570318400347397279771854414340904257811551082133799478885832161020,
            17347429727499218331690564741592041242046763353798273399191422357131121144526
        );
        vk.IC[99] = Pairing.G1Point(
            5231534209083104089000226261696838240668644999748711881512667609407153152571,
            14462988536411726689378137362904814271715740393639540280951554309651546718062
        );
        vk.IC[100] = Pairing.G1Point(
            10271345334835708386911699705309466633280068863833043458199043459898060761178,
            9858087028500648922660037729507373246056377431397413441590099084908641138762
        );
        vk.IC[101] = Pairing.G1Point(
            11859346518792537002378870160032988236150004855599014279857289985022088596779,
            11591334295958416959424928838297400198721902750433596743529223746842366595261
        );
        vk.IC[102] = Pairing.G1Point(
            3405076630003470165208885752793993163018018564054402154329961752739831093038,
            8570384014103130881176924254293742203102492390367430443899186832999248791767
        );
        vk.IC[103] = Pairing.G1Point(
            8955982500489070338756385220252111898119489024950003105949693178701351679709,
            11028680053793405257175545043748673262705043749102665677124921061226106926134
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
        require(input.length == 103);
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

    event Debug (
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

    event DropWallet(
        bytes32 indexed commitment,
        uint256 timestamp
    );

    constructor(
        CreateWalletVerifier _createWalletVerifier,
        DepositVerifier _depositVerifier,
        SwapVerifier _swapVerifier,
        WithdrawVerifier _withdrawVerifier,
        DropWalletVerifier _dropWalletVerifier,
        uint32 _merkleTreeHeight
    ) public MerkleTreeWithHistory(_merkleTreeHeight) {
        createWalletVerifier = _createWalletVerifier;
        depositVerifier = _depositVerifier;
        swapVerifier = _swapVerifier;
        withdrawVerifier = _withdrawVerifier;
        dropWalletVerifier = _dropWalletVerifier;
    }

    function createWallet(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external payable nonReentrant {
        require(input.length == CURRENCIES_NUMBER + 1, "Incorrect input length");
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
        require(input.length == CURRENCIES_NUMBER + 4, "Incorrect input length");
        require(
            depositVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 commitment_success = bytes32(input[0]);
        bytes32 commitment_fail = bytes32(input[1]);
        bytes32 root = bytes32(input[2]);
        bytes32 concealer_old = bytes32(input[3]);
        uint256[] memory tokens_amounts = sliceArray(input, 4);

        (bool success,) =
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

    function swap (
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external nonReentrant {
        require(input.length == CURRENCIES_NUMBER + 5, "Incorrect input length");
        require(
            swapVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 commitment_success = bytes32(input[0]);
        bytes32 commitment_fail = bytes32(input[1]);
        bytes32 root = bytes32(input[2]);
        bytes32 concealer_old = bytes32(input[3]);
        uint256 fee = uint256(input[4]);
        uint256[] memory tokens_deltas = sliceArray(input, 5);

        emit Log("before subcall");

        (bool success,) =
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

    function partialWithdraw (
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external nonReentrant {
        require(input.length == CURRENCIES_NUMBER + 105, "Incorrect input length");
        require(
            withdrawVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 commitment_success = bytes32(input[0]);
        bytes32 commitment_fail = bytes32(input[1]);
        bytes32 root = bytes32(input[2]);
        bytes32 concealer_old = bytes32(input[3]);
        uint256[] memory deltas = getDeltasArray(input, 4);
        address recepient = address(input[105]);

        (bool success,) =
        address(this).delegatecall(
            abi.encodeWithSignature(
                "_withdraw(bytes32, bytes32, uint256[] memory, address)",
                root,
                concealer_old,
                deltas,
                recepient
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

    function dropWallet (
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external nonReentrant {
        require(input.length == CURRENCIES_NUMBER + 103, "Incorrect input length");
        require(
            dropWalletVerifier.verifyProof(a, b, c, input),
            "Anonymizer: wrong proof"
        );
        bytes32 root = bytes32(input[0]);
        bytes32 concealer_old = bytes32(input[1]);
        uint256[] memory amounts = sliceArray(input, 3);
        address recepient = address(input[2]);

        address(this).delegatecall(
            abi.encodeWithSignature(
                "_withdraw(bytes32, bytes32, uint256[] memory, address)",
                root,
                concealer_old,
                amounts,
                recepient
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

        for (uint i = 0; i < CURRENCIES_NUMBER; i++) {
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
        require(amountFrom != 0 && amountTo != 0, "From amount and to amount must be not zeros");
        processSwap(amountFrom, indexFrom, amountTo, indexTo);
        emit Log("end swap");
    }

    function _withdraw(
        bytes32 root,
        bytes32 concealer_old,
        uint256[] memory deltas,
        address recepient
    ) private {
        require(isKnownRoot(root), "Root is not valid");
        require(!concealers[concealer_old], "Deposit has already withdrawn");
        processWithdraw(deltas, recepient);
    }
}