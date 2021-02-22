// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../common/GSN/Context.sol";

interface IERC20Permit {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
        bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

interface IDaiBridge {
    function relayTokens(address _from, address _receiver, uint256 _amount) external;
}

contract DaiBridgeProxy is Context {
    address private _daiToken;
    address private _daiBridge;

    constructor(address daiToken_, address daiBridge_) public {
        _daiToken = daiToken_;
        _daiBridge = daiBridge_;
    }

    function daiToken() public view returns (address) {
        return _daiToken;
    }

    function daiBridge() public view returns (address) {
        return _daiBridge;
    }

    function depositFor(
        uint amount,
        address recipient,
        uint256 permitNonce,
        uint256 permitExpiry,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IERC20Permit(_daiToken).permit(_msgSender(), _daiBridge, permitNonce, permitExpiry, true, v, r, s);
        IDaiBridge(_daiBridge).relayTokens(_msgSender(), recipient, amount);
    }
}