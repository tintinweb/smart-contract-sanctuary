/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File contracts/interfaces/IERC20.sol

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


// File contracts/PPTreasury.sol

pragma solidity ^0.8.0;

/// @author Medici
/// @title Treasury contract for Pricing Protocol
contract PpTreasury{
    
    uint public tokensClaimed;
    address public pricingSessionFactory;
    address public admin;
    address public ppToken;
    //For testnet
    bool public checkMaxValue;

    /* ======== MAPPINGS ======== */
    //For testnet
    mapping(address => uint) public pointsLost;
    mapping(address => uint) public pointsGained;
    mapping(address => bool) public whitelist;

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setPPTokenAddress(address _ppToken) onlyAdmin external {
        require(ppToken == address(0));
        ppToken = _ppToken;
    }

    function withdraw(uint _amount) onlyAdmin external {
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function setAdmin(address _newAdmin) onlyAdmin external {
        admin = _newAdmin;
    }

    function setPricingFactory(address _pricingFactory) onlyAdmin external {
        pricingSessionFactory = _pricingFactory;
    }

    //For testnet
    function toggleMaxValue() onlyAdmin external {
        checkMaxValue = !checkMaxValue;
    }

    //For testnet
    function addToWhitelist(address user) onlyAdmin external {
        whitelist[user] = true;
    }

    //For testnet
    function removeFromWhiteList(address user) onlyAdmin external {
        whitelist[user] = false;
    }

    /* ======== VIEW FUNCTIONS ======== */
    
    function checkWhitelist(address user) view external returns (bool){
        return whitelist[user];
    }

    /* ======== CHILD FUNCTIONS ======== */
    
    function sendPPToken(address recipient, uint _amount) isFactory external {
        IERC20(ppToken).transfer(recipient, _amount);
        tokensClaimed += _amount;
    }

    //For testnet
    function updateUserPoints(address _user, uint _amountGained, uint _amountLost) isFactory external {
        require(!checkMaxValue);
        if(_amountGained > _amountLost) {
            pointsGained[_user] += _amountGained;
        }
        else {
            pointsLost[_user] += _amountLost;
        }
    }

    /* ======== FALLBACKS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    modifier onlyAdmin() {
        require(admin == msg.sender);
        _;
    }
    
    modifier isFactory() {
        require(msg.sender == pricingSessionFactory);
        _;
    }
}