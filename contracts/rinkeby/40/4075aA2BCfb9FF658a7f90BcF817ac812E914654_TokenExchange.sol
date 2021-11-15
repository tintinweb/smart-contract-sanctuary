// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./utils/IERC20.sol";

contract TokenExchange {
    address private _owner;
    address private _newToken;
    IERC20 private _oldToken;
    address[] private _exchangeList;
    constructor (address buffToken, address oldToken, address[] memory exchangeList) {
        require(buffToken != address(0), "Zero address");
        _owner = msg.sender;
        _newToken = buffToken;
        _oldToken = IERC20(oldToken);
        _exchangeList = exchangeList;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function exchangeOldToken() external onlyOwner returns (bool) {
        require(_exchangeList.length > 0, "ERR: no exchange list");
        for(uint k = 0; k < _exchangeList.length; k++) {
            uint balances = _oldToken.balanceOf(_exchangeList[k]);
            if(balances > 0) {
                bool transferCheck = IERC20(_newToken).transferFrom(_newToken, _exchangeList[k], balances);
                require(transferCheck, "Official BuffDoge transfer failed");
            }
        }
        return true;
    }

    function checkList() external view returns (address, address, IERC20) {
        return (_owner, _newToken, _oldToken);
    }

    function checkBalanceOldBuff(address oldHolders) external view returns (uint) {
        uint balances = _oldToken.balanceOf(oldHolders);
        return balances;
    }

    function checkOldList() external view returns (address[] memory) {
        return _exchangeList;
    }

    function destroySmartContract(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

