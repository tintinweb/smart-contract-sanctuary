/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

//"SPDX-License-Identifier: NO-LISENCE"

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }


    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {

        if (uint(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }


    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

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

    function burn(uint256 amount) external returns (bool);
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

pragma solidity ^0.8.0;

contract stakeOrcsV2{

    using SafeMath for uint;
    using ECDSA for bytes32;
    enum matchStatus {Initiate, Start, Running, End}
    struct matchUps {
        matchStatus where;
        address player1;
        address player2;
        uint player1stakedAmount;
        uint player2stakedAmount;
        uint totalBetValue;
        bool matchStarted;
    }
    string private constant Sig_WORD = "private";
    address private _signerAddress = 0x956231B802D9494296acdE7B3Ce3890c8b0438b8;
    event challengeInitiator(address challenger, address visitor, bool matchStarter,  uint gameNumber);
    event matchStart(bool matchStart, uint gameId, uint betValue);
    event withDrawBefore (bool withDrawlStatus);

    matchUps[] public matchLists;

    IERC20 internal token;
    mapping (uint => bool) public isValid;
    mapping (address => uint) public fundsDeposited;

    constructor (address tokenAddress) {
        token =  IERC20(tokenAddress);
    }

    function storeFunds(uint _amount) external { //player1 => $10,000
        token.transferFrom (msg.sender, address(this), _amount);
        fundsDeposited[msg.sender]+=_amount;
    }

    function startGame(address secondPlayer, uint _amount, address tokenAddress) external { // player1 => $1,000
        uint _stakedAmountChallenger = stakeZug(_amount, tokenAddress);
        matchLists.push(matchUps(matchStatus.Start,msg.sender,secondPlayer,_stakedAmountChallenger,0,_stakedAmountChallenger,false));
        uint gameNumber = matchLists.length -1;
        isValid[gameNumber] = true;
        emit challengeInitiator(msg.sender, secondPlayer, false, gameNumber);
    }

    function joinGame( uint gameNumber, uint _amount, address tokenAddress) external {
        require(isValid[gameNumber] == true,'Incorrect GameId');
        require (msg.sender == matchLists[gameNumber].player2, 'You are not allowed to enter the match. Please initiate another match or join the correct one');
        require(token.balanceOf(msg.sender) >= _amount);
        require (matchLists[gameNumber].where == matchStatus.Start, "The match isn't yet initiated");
        matchLists[gameNumber].where = matchStatus.Running;
        uint _stakeAmountSecondPlayer = stakeZug( _amount, tokenAddress);
        uint _totalBetValue = matchLists[gameNumber].totalBetValue+_stakeAmountSecondPlayer;
        matchLists[gameNumber].player2stakedAmount = _stakeAmountSecondPlayer;
        matchLists[gameNumber].totalBetValue = _totalBetValue;
        matchLists[gameNumber].matchStarted = true;
        emit matchStart(matchLists[gameNumber].matchStarted, gameNumber, _totalBetValue);
    }

    function isGameStarted(uint gameNumber) external view returns(bool,matchStatus) {
        if (matchLists[gameNumber].where != matchStatus.Running){
            return (false,matchLists[gameNumber].where);
        }else {
            return (true, matchLists[gameNumber].where);
        }
    }

    function withdrawFundsIfNotInitialized(uint gameNumber) external  {
        require (isValid[gameNumber] == true, 'Invalid GameId');
        require (matchLists[gameNumber].where == matchStatus.Start, 'Match started');
        require (matchLists[gameNumber].matchStarted == false,'Match already started you cannot withdraw funds now');
        require (matchLists[gameNumber].player1 == msg.sender,'You are not authorized to withdraw the funds');
        bool withDrawStatus = withDrawStakedValue(gameNumber);
        require (withDrawStatus == true, 'Error in withdrawl');
        emit withDrawBefore(true);
    }


    function stakeZug(uint _amount, address tokenAddress) internal returns(uint) {
        uint burn = burnFunc( _amount);
        uint resend = reSend(_amount, tokenAddress);
        uint _finalAmount = _amount-(burn+resend);
        fundsDeposited[msg.sender] = fundsDeposited[msg.sender] - _amount;
        return _finalAmount;
    }

    function burnFunc(uint _amount) internal returns(uint) {
        uint burnConvert = convertValue(_amount);
        token.burn(burnConvert);
        return burnConvert;
    }

    function reSend(uint _amount, address tokenAddress) internal returns(uint) {
        uint resendVal = convertValue(_amount);
        token.transfer(tokenAddress,resendVal);
        return resendVal;
    }

    function convertValue(uint _amount) internal view returns(uint) {
        uint value = (_amount*25)/1000;
        return value;
    }

    function withDrawStakedValue(uint gameNumber) internal returns(bool) {
        uint _amount = matchLists[gameNumber].player1stakedAmount;
        matchLists[gameNumber].player1stakedAmount = 0;
        matchLists[gameNumber].totalBetValue = 0;
        fundsDeposited[msg.sender] += _amount;
        return true;
    }

    function isGameEnded(uint gameNumber) external view returns(matchStatus) {
        return matchLists[gameNumber].where;
    }

    function matchAddresSigner(bytes memory signature) internal view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender, Sig_WORD)))
        );
        return _signerAddress == hash.recover(signature);
    }

    function endGameandClaimAward(bytes memory signature,address receiver, uint gameNumber) external returns (matchStatus){
        require (isValid[gameNumber] == true, 'The game number provided is not correct');
        require (matchLists[gameNumber].where == matchStatus.Running, 'Match not yet running');
        require (msg.sender == matchLists[gameNumber].player1 || msg.sender == matchLists[gameNumber].player2, 'Caller not one of the players');
        require (matchAddresSigner(signature), "Caller not authorized");
        matchLists[gameNumber].where = matchStatus.End;
        claimAward(receiver,gameNumber);
        return matchLists[gameNumber].where;
    }

    function claimAward(address _receiver, uint gameNumber) internal {
        require (isValid[gameNumber] == true, 'The game number provided is not correct');
        require (matchLists[gameNumber].matchStarted == true, 'Match has not start');
        require (matchLists[gameNumber].where == matchStatus.End, 'Match not yet end');
        require (msg.sender == matchLists[gameNumber].player1 || msg.sender == matchLists[gameNumber].player2, 'Caller not one of the players');
        require (token.balanceOf(address(this))>= matchLists[gameNumber].totalBetValue, 'Insufficient Balance');
        uint _amount = matchLists[gameNumber].totalBetValue;
        matchLists[gameNumber].totalBetValue = 0;
        fundsDeposited[_receiver] += _amount;
    }

    function withDrawAllFunds() external {
        require (fundsDeposited[msg.sender]>0, "The balance is 0" );
        uint fundsToTransfer = fundsDeposited[msg.sender];
        fundsDeposited[msg.sender] = 0;
        token.transfer(msg.sender,fundsToTransfer);
    }
}