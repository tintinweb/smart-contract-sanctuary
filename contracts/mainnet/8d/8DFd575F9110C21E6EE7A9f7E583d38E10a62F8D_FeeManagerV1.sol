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
pragma solidity ^0.8.0;

import "./../IRadarBridgeFeeManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeManagerV1 is IRadarBridgeFeeManager {
    mapping(address => uint256) private maxTokenFee;
    uint256 constant FEE_BASE = 1000000;
    address private owner;

    uint256 private percentageFee;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor (
        uint256 _percentageFee,
        address[] memory _tokens,
        uint256[] memory _maxFees
    ) {
        require(_percentageFee < FEE_BASE, "Fee too big");
        require(_tokens.length == _maxFees.length, "Invalid maxFees data");

        owner = msg.sender;
        percentageFee = _percentageFee;
        for(uint8 i = 0; i < _tokens.length; i++) {
            maxTokenFee[_tokens[i]] = _maxFees[i];
        }
    }

    // DAO Functions
    function passOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changePercentageFee(uint256 _newFee) external onlyOwner {
        require(_newFee < FEE_BASE, "Fee too big");
        percentageFee = _newFee;
    }

    function changeTokenMaxFee(address _token, uint256 _maxFee) external onlyOwner {
        maxTokenFee[_token] = _maxFee;
    }

    function withdrawTokens(address _token, uint256 _amount, address _receiver) external onlyOwner {
        uint256 _bal = IERC20(_token).balanceOf(address(this));
        uint256 _withdrawAmount = _amount;
        if (_withdrawAmount > _bal) {
            _withdrawAmount = _bal;
        }

        IERC20(_token).transfer(_receiver, _withdrawAmount);
    }

    // Fee Manager Functions

    function getBridgeFee(address _token, address, uint256 _amount, bytes32, address) external override view returns (uint256) {
        uint256 _percFee = percentageFee;

        if (((_amount * _percFee) / FEE_BASE) > maxTokenFee[_token]) {
            if (_amount != 0) {
                _percFee = (maxTokenFee[_token] * FEE_BASE) / _amount;
            } else {
                _percFee = 0;
            }
        }

        return _percFee;
    }

    function getFeeBase() external override view returns (uint256) {
        return FEE_BASE;
    }

    // State Getters
    function getFixedPercRate() external view returns (uint256) {
        return percentageFee;
    }

    function getMaxFeeForToken(address _token) external view returns (uint256) {
        return maxTokenFee[_token];
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRadarBridgeFeeManager {
    function getBridgeFee(address _token, address _sender, uint256 _amount, bytes32 _destChain, address _destAddress) external view returns (uint256);

    function getFeeBase() external view returns (uint256);
}