// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface DaiPartialToken {
    function allowance(
        address holder,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address spender,
        uint256 value
    )
        external
        returns (bool);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function transfer(
        address to,
        uint256 value
    )
        external
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        returns (bool);
}

interface DaiPartialBridge {
    function relayTokens(
        address from,
        address receiver,
        uint256 amount
    )
        external;
}

contract DaiBridgeProxy {
    uint256 constant private DAI_TOKEN_MAX_ALLOWANCE = uint(-1);

    DaiPartialToken public daiToken;
    DaiPartialBridge public daiBridge;

    constructor(address daiToken_, address daiBridge_) public {
        daiToken = DaiPartialToken(daiToken_);
        daiBridge = DaiPartialBridge(daiBridge_);
    }

    function depositWithPermit(
        uint amount,
        address recipient,
        uint256 permitNonce,
        uint256 permitExpiry,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external {
        if (daiToken.allowance(msg.sender, address(this)) < amount) {
            daiToken.permit(
                msg.sender,
                address(this),
                permitNonce,
                permitExpiry,
                true,
                permitV,
                permitR,
                permitS
            );
        }
        depositFor(amount, recipient);
    }

    function depositFor(uint amount, address recipient) public {
        daiToken.transferFrom(msg.sender, address(this), amount);
        if (daiToken.allowance(address(this), address(daiBridge)) < amount) {
            daiToken.approve(address(daiBridge), DAI_TOKEN_MAX_ALLOWANCE);
        }
        daiBridge.relayTokens(address(this), recipient, amount);
    }
}