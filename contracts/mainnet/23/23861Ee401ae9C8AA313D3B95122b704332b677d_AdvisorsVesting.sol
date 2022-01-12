// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AdvisorsVesting {

    uint256 immutable private tokens;
    address immutable private icomToken;
    address immutable private owner;

    uint256 constant private FIRST_STEP = 500000000000000000;
    uint256 constant private SECOND_STEP = 750000000000000000;
    uint256 constant private THIRD_STEP = 1000000000000000000;

    address[8] private advisorsWallet;
    uint16[8] private percentages;
    uint32 public listingDate;
    bool[3] private unlockedTranche;

    uint32 constant private MAX_LISTING_DATE = 1672441200;  // 2022/12/31 00:00:00

    event advisorTokensSent(uint256 _amount);

    constructor(address _icomToken, address[] memory _advisorsWallet, uint16[] memory _percentages, uint256 _tokens) {
        icomToken = _icomToken;
        tokens = _tokens;
        owner = msg.sender;

        for (uint256 i=0; i< _advisorsWallet.length; i++) {
            advisorsWallet[i] = _advisorsWallet[i];
            percentages[i] = _percentages[i];
        }
    }

    function setListingDate(uint32 _listingDate) external {
        require(msg.sender == owner, "OnlyOwner");
        require(_listingDate < MAX_LISTING_DATE, "CantDelayMoreListing");
        require(block.timestamp < _listingDate, "CantListInPast");

        listingDate = _listingDate;
    }

    function withdrawTokens(bytes calldata _params, bytes calldata _messageLength, bytes calldata _signature) external {
        uint256 unlockPercentage = _checkPrice(_params, _messageLength, _signature);
        require(block.timestamp >= listingDate + 150 days || unlockPercentage > 0, "CantWithdrawYet");

        if (block.timestamp >= listingDate + 150 days) {
            uint256 balance = IERC20(icomToken).balanceOf(address(this));
            _sendTokens(balance);
        } else {
            uint256 amount = tokens * unlockPercentage / 100;
            _sendTokens(amount);
        }
    }

    function _checkPrice(bytes calldata _params, bytes calldata _messageLength, bytes calldata _signature) internal returns(uint256) {
        address _signer = _decodeSignature(_params, _messageLength, _signature);
        require(_signer == owner, "BadSigner");
    
        (, uint256 _price) = abi.decode(_params, (uint256, uint256));
        return _unlockedPercentage(_price);
    }

    function _unlockedPercentage(uint256 _price) internal returns(uint256) {
        uint256 percentage = 0;
        if ((_price >= FIRST_STEP) && (unlockedTranche[0] == false)) {
            percentage += 35;
            unlockedTranche[0] = true;
        } else if ((_price >= SECOND_STEP) && (unlockedTranche[1] == false)) {
            percentage += 35;
            unlockedTranche[1] = true;
        } else if ((_price >= THIRD_STEP) && (unlockedTranche[2] == false)) {
            percentage += 30;
            unlockedTranche[2] = true;
        }

        return percentage;
    }

    function _sendTokens(uint256 _amount) internal {
        for (uint256 i = 0; i< advisorsWallet.length; i++) {
            IERC20(icomToken).transfer(advisorsWallet[i], _amount * percentages[i] / 1000);
        }
        
        emit advisorTokensSent(_amount);
    }

    function _decodeSignature(bytes memory _message, bytes memory _messageLength, bytes memory _signature) internal pure returns (address) {
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

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);

        if (v != 27 && v != 28) return address(0);
        
        return ecrecover(messageHash, v, r, s);
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