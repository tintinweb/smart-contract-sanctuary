/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/math/[email protected]

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File contracts/IBilling.sol

interface IBilling {
    /**
     * @dev Set the new gateway address
     * @param _newGateway  New gateway address
     */
    function setGateway(address _newGateway) external; // onlyGateway or onlyGovernor, or something

    /**
     * @dev Add tokens into the billing contract
     * @param _amount  Amount of tokens to add
     */
    function add(uint256 _amount) external;

    /**
     * @dev Add tokens into the billing contract for any user
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function addTo(address _to, uint256 _amount) external;

    /**
     * @dev Remove tokens from the billing contract
     * @param _to  Address that tokens are being removed from
     * @param _amount  Amount of tokens to remove
     */
    function remove(address _to, uint256 _amount) external;

    /**
     * @dev Gateway pulls tokens from the billing contract
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     * @param _to Destination to send pulled tokens
     */
    function pull(
        address _user,
        uint256 _amount,
        address _to
    ) external;

    /**
     * @dev Gateway pulls tokens from many users in the billing contract
     * @param _users  Addresses that tokens are being pulled from
     * @param _amounts  Amounts of tokens to pull from each user
     * @param _to Destination to send pulled tokens
     */
    function pullMany(
        address[] calldata _users,
        uint256[] calldata _amounts,
        address _to
    ) external;
}


// File contracts/Governed.sol

/**
 * @title Graph Governance contract
 * @dev Allows a contract to be owned and controlled by the 'governor'
 */
contract Governed {
    // -- State --

    // The address of the governor
    address public governor;
    // The address of the pending governor
    address public pendingGovernor;

    // -- Events --

    // Emit when the pendingGovernor state variable is updated
    event NewPendingOwnership(address indexed from, address indexed to);
    // Emit when the governor state variable is updated
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor with the _initGovernor param.
     * @param _initGovernor Governor address
     */
    constructor(address _initGovernor) {
        require(_initGovernor != address(0), "Governor must not be 0");
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(pendingGovernor != address(0) && msg.sender == pendingGovernor, "Caller must be pending governor");

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}


// File contracts/Billing.sol




/**
 * @title Billing Contract
 * @dev The billing contract allows for Graph Tokens to be added by a user. The token can then
 * be pulled by a permissioned user named 'gateway'. It is owned and controlled by the 'governor'.
 */

contract Billing is IBilling, Governed {
    // -- State --

    // The contract for interacting with The Graph Token
    IERC20 private immutable graphToken;
    // The gateway address
    address public gateway;

    // maps user address --> user billing balance
    mapping(address => uint256) public userBalances;

    // -- Events --

    /**
     * @dev User adds tokens
     */
    event TokensAdded(address indexed user, uint256 amount);
    /**
     * @dev User removes tokens
     */
    event TokensRemoved(address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Gateway pulled tokens from a user
     */
    event TokensPulled(address indexed user, uint256 amount);

    /**
     * @dev Gateway address updated
     */
    event GatewayUpdated(address indexed newGateway);

    /**
     * @dev Tokens rescued by the gateway
     */
    event TokensRescued(address indexed to, address indexed token, uint256 amount);

    /**
     * @dev Constructor function
     * @param _gateway   Gateway address
     * @param _token     Graph Token address
     * @param _governor  Governor address
     */
    constructor(
        address _gateway,
        IERC20 _token,
        address _governor
    ) Governed(_governor) {
        _setGateway(_gateway);
        graphToken = _token;
    }

    /**
     * @dev Check if the caller is the gateway.
     */
    modifier onlyGateway() {
        require(msg.sender == gateway, "Caller must be gateway");
        _;
    }

    /**
     * @dev Set the new gateway address
     * @param _newGateway  New gateway address
     */
    function setGateway(address _newGateway) external override onlyGovernor {
        _setGateway(_newGateway);
    }

    /**
     * @dev Set the new gateway address
     * @param _newGateway  New gateway address
     */
    function _setGateway(address _newGateway) internal {
        require(_newGateway != address(0), "Gateway cannot be 0");
        gateway = _newGateway;
        emit GatewayUpdated(gateway);
    }

    /**
     * @dev Add tokens into the billing contract
     * Ensure graphToken.approve() is called on the billing contract first
     * @param _amount  Amount of tokens to add
     */
    function add(uint256 _amount) external override {
        _add(msg.sender, msg.sender, _amount);
    }

    /**
     * @dev Add tokens into the billing contract for any user
     * Ensure graphToken.approve() is called on the billing contract first
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function addTo(address _to, uint256 _amount) external override {
        _add(msg.sender, _to, _amount);
    }

    /**
     * @dev Add tokens into the billing contract
     * Ensure graphToken.approve() is called on the billing contract first
     * @param _from  Address that is sending tokens
     * @param _user  User that is adding tokens
     * @param _amount  Amount of tokens to add
     */
    function _add(
        address _from,
        address _user,
        uint256 _amount
    ) private {
        require(_amount != 0, "Must add more than 0");
        require(_user != address(0), "user != 0");
        require(graphToken.transferFrom(_from, address(this), _amount), "Add transfer failed");
        userBalances[_user] = userBalances[_user] + _amount;
        emit TokensAdded(_user, _amount);
    }

    /**
     * @dev Remove tokens from the billing contract
     * @param _user  Address that tokens are being removed from
     * @param _amount  Amount of tokens to remove
     */
    function remove(address _user, uint256 _amount) external override {
        require(_amount != 0, "Must remove more than 0");
        require(userBalances[msg.sender] >= _amount, "Too much removed");
        userBalances[msg.sender] = userBalances[msg.sender] - _amount;
        require(graphToken.transfer(_user, _amount), "Remove transfer failed");
        emit TokensRemoved(msg.sender, _user, _amount);
    }

    /**
     * @dev Gateway pulls tokens from the billing contract
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     * @param _to Destination to send pulled tokens
     */
    function pull(
        address _user,
        uint256 _amount,
        address _to
    ) external override onlyGateway {
        uint256 maxAmount = _pull(_user, _amount);
        _sendTokens(_to, maxAmount);
    }

    /**
     * @dev Gateway pulls tokens from many users in the billing contract
     * @param _users  Addresses that tokens are being pulled from
     * @param _amounts  Amounts of tokens to pull from each user
     * @param _to Destination to send pulled tokens
     */
    function pullMany(
        address[] calldata _users,
        uint256[] calldata _amounts,
        address _to
    ) external override onlyGateway {
        require(_users.length == _amounts.length, "Lengths not equal");
        uint256 totalPulled;
        for (uint256 i = 0; i < _users.length; i++) {
            uint256 userMax = _pull(_users[i], _amounts[i]);
            totalPulled = totalPulled + userMax;
        }
        _sendTokens(_to, totalPulled);
    }

    /**
     * @dev Gateway pulls tokens from the billing contract. Uses Math.min() so that it won't fail
     * in the event that a user removes in front of the gateway pulling
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     */
    function _pull(address _user, uint256 _amount) internal returns (uint256) {
        uint256 maxAmount = Math.min(_amount, userBalances[_user]);
        if (maxAmount > 0) {
            userBalances[_user] = userBalances[_user] - maxAmount;
            emit TokensPulled(_user, maxAmount);
        }
        return maxAmount;
    }

    /**
     * @dev Allows the Gateway to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyGateway {
        require(_to != address(0), "Cannot send to address(0)");
        require(_amount != 0, "Cannot rescue 0 tokens");
        IERC20 token = IERC20(_token);
        require(token.transfer(_to, _amount), "Rescue tokens failed");
        emit TokensRescued(_to, _token, _amount);
    }

    /**
     * @dev Send tokens to a destination account
     * @param _to Address where to send tokens
     * @param _amount Amount of tokens to send
     */
    function _sendTokens(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            require(_to != address(0), "Cannot transfer to empty address");
            require(graphToken.transfer(_to, _amount), "Token transfer failed");
        }
    }
}