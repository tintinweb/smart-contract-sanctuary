// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStarknetCore.sol";

contract GatewayERC20 {
    address public initialEndpointGatewaySetter;
    uint256 public endpointGateway;
    IStarknetCore public starknetCore;
    uint256 constant ENDPOINT_GATEWAY_SELECTOR = 1738423374452994793145864788013146788518531877200292826651981332061687045062;
    uint256 constant BRIDGE_MODE_DEPOSIT = 0;
    uint256 constant BRIDGE_MODE_WITHDRAW = 1;

    // Bootstrap
    constructor(address _starknetCore) {
        require(
            _starknetCore != address(0),
            "Gateway/invalid-starknet-core-address"
        );
    
        starknetCore = IStarknetCore(_starknetCore);
        initialEndpointGatewaySetter = msg.sender;
    }

    function setEndpointGateway(uint256 _endpointGateway) external {
        require(
            msg.sender == initialEndpointGatewaySetter,
            "Gateway/unauthorized"
        );
        require(endpointGateway == 0, "Gateway/endpoint-gateway-already-set");
        endpointGateway = _endpointGateway;
    }

    // Utils
    function addressToUint(address value)
        internal
        pure
        returns (uint256 convertedValue)
    {
        convertedValue = uint256(uint160(address(value)));
    }

    // Bridging to Starknet
    function bridgeToStarknet(
        IERC20 _l1TokenContract,
        uint256 _l2TokenContract,
        uint256 _amount,
        uint256 _account
    ) external {
        uint256[] memory payload = new uint256[](4);
        require(endpointGateway != 0, "Gateway unset");
    
        // optimistic transfer, should revert if no approved or not owner
        _l1TokenContract.transferFrom(msg.sender, address(this), _amount);

        // build deposit message payload
        payload[0] = _account;
        payload[1] = addressToUint(address(_l1TokenContract));
        payload[2] = _l2TokenContract;
        payload[3] = _amount;

        // send message
        starknetCore.sendMessageToL2(
            endpointGateway,
            ENDPOINT_GATEWAY_SELECTOR,
            payload
        );
    }

    // Bridging back from Starknet
    function bridgeFromStarknet(
        IERC20 _l1TokenContract,
        uint256 _l2TokenContract,
        uint256 _amount
    ) external {
        uint256[] memory payload = new uint256[](5);
        require(endpointGateway != 0, "Gateway unset");

        // build withdraw message payload
        payload[0] = BRIDGE_MODE_WITHDRAW;
        payload[1] = addressToUint(msg.sender);
        payload[2] = addressToUint(address(_l1TokenContract));
        payload[3] = _l2TokenContract;
        payload[4] = _amount;

        // consum withdraw message
        starknetCore.consumeMessageFromL2(endpointGateway, payload);

        // optimistic transfer, should revert if gateway is not token owner
        _l1TokenContract.transferFrom(address(this), msg.sender, _amount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external;

    /**
      Consumes a message that was sent from an L2 contract.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external;
}