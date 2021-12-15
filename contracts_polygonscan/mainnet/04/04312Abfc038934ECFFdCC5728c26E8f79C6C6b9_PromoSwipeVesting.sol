// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author Jorge Gomes Durán ([email protected])
/// @title A vesting contract to lock tokens for PromoSwipe

contract PromoSwipeVesting {

    struct TokenWithdraw {
        uint256 amount;
        uint32 lastDate;
    }

    address immutable private promoSwipeToken;
    address payable immutable private owner;

    uint32 internal constant LISTING_DATE = 1639522800;    // 15 December 2021 00:00:00

    uint256 internal constant MIN_COINS_FOR_VESTING = 200000 * 10 ** 18;    // 0.10€ token initial price
    uint256 internal constant YEAR_1_AFTER_LISTING_AMOUNT = 78000000 * 10 ** 18;
    uint256 internal constant YEAR_2_AFTER_LISTING_AMOUNT = 97500000 * 10 ** 18;
    uint256 internal constant YEAR_3_AFTER_LISTING_AMOUNT = 97500000 * 10 ** 18;

    uint32 internal lastTokenWithdrawn;
    uint256 internal newTokensUnlockedAmount;

    uint256 internal nonces1;
    uint256 internal nonces2;
    uint256 internal nonces3;
    uint256 internal nonces4;
    uint256 internal nonces5;

    constructor(address _token) {
        promoSwipeToken = _token;
        owner = payable(msg.sender);
    }

    /**
     * @notice unlock the ICO tokens sold according to the PromoSwipe whitepaper
     */
    function withdrawICOTokens(bytes[] calldata _params, bytes[] calldata _messageLength, bytes[] calldata _signature) external {
        require(block.timestamp >= LISTING_DATE, "TooEarly");

        for (uint256 i=0; i<_params.length; i++) {
            if ((block.timestamp >= LISTING_DATE) && (block.timestamp < LISTING_DATE + 60 days)) {
                _sendICOTokens(1, 20, _params[i], _messageLength[i], _signature[i]);
            } else if ((block.timestamp >= LISTING_DATE + 60 days) && (block.timestamp < LISTING_DATE + 120 days)) {
                _sendICOTokens(2, 20, _params[i], _messageLength[i], _signature[i]);
            } else if ((block.timestamp >= LISTING_DATE + 120 days) && (block.timestamp < LISTING_DATE + 180 days)) {
                _sendICOTokens(3, 10, _params[i], _messageLength[i], _signature[i]);
            } else if ((block.timestamp >= LISTING_DATE + 180 days) && (block.timestamp < LISTING_DATE + 240 days)) {
                _sendICOTokens(4, 25, _params[i], _messageLength[i], _signature[i]);
            } else if (block.timestamp >= LISTING_DATE + 240 days) {
                _sendICOTokens(5, 25, _params[i], _messageLength[i], _signature[i]);
            }
        }
    }

    function unlockNewTokens(uint256 _amount) external {
        require(block.timestamp >= LISTING_DATE + 365 days, "NoTokensToUnlock");

        if ((block.timestamp >= LISTING_DATE + 365 days) && (block.timestamp < LISTING_DATE + 730 days)) {
            require(newTokensUnlockedAmount + _amount <= YEAR_1_AFTER_LISTING_AMOUNT, "RunOutYear1");
            _sendNewTokens(_amount);
        } else if ((block.timestamp >= LISTING_DATE + 730 days) && (block.timestamp < LISTING_DATE + 1095 days)) {
            require(newTokensUnlockedAmount + _amount <= YEAR_1_AFTER_LISTING_AMOUNT + YEAR_2_AFTER_LISTING_AMOUNT, "RunOutYear2");
            _sendNewTokens(_amount);
        } else if (block.timestamp >= LISTING_DATE + 1095 days) {
            require(newTokensUnlockedAmount + _amount <= YEAR_1_AFTER_LISTING_AMOUNT + YEAR_2_AFTER_LISTING_AMOUNT + YEAR_3_AFTER_LISTING_AMOUNT, "RunOutYear3");
            _sendNewTokens(_amount);
        }
    }

    function _sendICOTokens(uint256 _round, uint256 _percentage, bytes calldata _message, bytes calldata _messageLength, bytes calldata _signature) internal {
        address _signer = _decodeSignature(_message, _messageLength, _signature);
        require(_signer == owner, "BadOwner");

        (address _user, uint256 _amount, uint8 _nonce) = abi.decode(_message, (address, uint256, uint8));
        require(_amount > 0, "BadQuantity");
        if (_round == 1) {
            require(_getNonceValue(nonces1, _nonce) == false, "Round1PaidYet");
            nonces1 = _setNonceValue(nonces1, _nonce, true);
            if (_amount > MIN_COINS_FOR_VESTING) {
                IERC20(promoSwipeToken).transfer(_user, _amount * _percentage / 100);
            } else {
                IERC20(promoSwipeToken).transfer(_user, _amount);
            }
        } else if (_round == 2) {
            require(_getNonceValue(nonces2, _nonce) == false, "Round2PaidYet");
            if (_amount > MIN_COINS_FOR_VESTING) {
                nonces2 = _setNonceValue(nonces2, _nonce, true);
                IERC20(promoSwipeToken).transfer(_user, _amount * _percentage / 100);
            }
        } else if (_round == 3) {
            require(_getNonceValue(nonces3, _nonce) == false, "Round3PaidYet");
            if (_amount > MIN_COINS_FOR_VESTING) {
                nonces3 = _setNonceValue(nonces3, _nonce, true);
                IERC20(promoSwipeToken).transfer(_user, _amount * _percentage / 100);
            }
        } else if (_round == 4) {
            require(_getNonceValue(nonces4, _nonce) == false, "Round4PaidYet");
            if (_amount > MIN_COINS_FOR_VESTING) {
                nonces4 = _setNonceValue(nonces4, _nonce, true);
                IERC20(promoSwipeToken).transfer(_user, _amount * _percentage / 100);
            }
        } else if (_round == 5) {
            require(_getNonceValue(nonces5, _nonce) == false, "Round5PaidYet");
            if (_amount > MIN_COINS_FOR_VESTING) {
                nonces5 = _setNonceValue(nonces5, _nonce, true);
                IERC20(promoSwipeToken).transfer(_user, _amount * _percentage / 100);
            }
        }
    }

    function _sendNewTokens(uint256 _amount) internal {
        require(block.timestamp > lastTokenWithdrawn + 30 days, "Wait1Month");

        newTokensUnlockedAmount += _amount;
        lastTokenWithdrawn = uint32(block.timestamp);
        IERC20(promoSwipeToken).transfer(owner, _amount);
    }

    function _decodeSignature(bytes memory _message, bytes memory _messageLength, bytes memory _signature) internal pure returns (address) {
        // Check the signature length
        if (_signature.length != 65) return (address(0));

        bytes32 messageHash = keccak256(abi.encodePacked(hex"19457468657265756d205369676e6564204d6573736167653a0a", _messageLength, _message));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);

        if (v != 27 && v != 28) return address(0);
        
        return ecrecover(messageHash, v, r, s);
    }

    function _getNonceValue(uint256 _packBoolean, uint256 _boolNumber) internal pure returns(bool) {
        uint256 flag = (_packBoolean >> _boolNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function _setNonceValue(uint256 _packBoolean, uint256 _boolNumber, bool _value) internal pure returns(uint256) {
        if (_value)
            return _packBoolean | uint256(1) << _boolNumber;
        else
            return _packBoolean & ~(uint256(1) << _boolNumber);
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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