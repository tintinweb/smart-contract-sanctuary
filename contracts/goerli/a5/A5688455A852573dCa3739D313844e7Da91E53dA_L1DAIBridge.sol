// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.7.6;

interface TokenLike {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function balanceOf(address account) external view returns (uint256);
}

interface StarkNetLike {
    function sendMessageToL2(
        uint256 to,
        uint256 selector,
        uint256[] calldata payload
    ) external;

    function consumeMessageFromL2(
        uint256 from,
        uint256[] calldata payload
    ) external;
}

contract L1DAIBridge {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "L1DAIBridge/not-authorized");
        _;
    }

    event Rely(address indexed usr);
    event Deny(address indexed usr);


    uint256 public isOpen = 1;

    modifier whenOpen() {
        require(isOpen == 1, "L1DAIBridge/closed");
        _;
    }

    function close() external auth {
        isOpen = 0;
        emit Closed();
    }

    event Closed();

    address public immutable starkNet;
    address public immutable dai;
    uint256 public immutable l2Dai;
    address public immutable escrow;
    uint256 public immutable l2DaiBridge;

    uint256 public ceiling = 0;

    uint256 constant HANDLE_WITHDRAW = 0;

    // src/starkware/cairo/lang/cairo_constants.py
    //  2 ** 251 + 17 * 2 ** 192 + 1;
    uint256 constant SN_PRIME =
        3618502788666131213697322783095070105623107215331596699973092056135872020481;

    //  from starkware.starknet.compiler.compile import get_selector_from_name
    //  print(get_selector_from_name('handle_deposit'))
    uint256 constant DEPOSIT =
        1285101517810983806491589552491143496277809242732141897358598292095611420389;

    //  print(get_selector_from_name('handle_force_withdrawal'))
    uint256 constant FORCE_WITHDRAW =
        1137729855293860737061629600728503767337326808607526258057644140918272132445;

    event LogCeiling(uint256 ceiling);
    event LogDeposit(address indexed l1Sender, uint256 amount, uint256 l2Recipient);
    event LogWithdrawal(address indexed l1Recipient, uint256 amount);
    event LogForceWithdrawal(
        address indexed l1Recipient,
        uint256 amount,
        uint256 indexed l2Sender
    );

    constructor(
        address _starkNet,
        address _dai,
        uint256 _l2Dai,
        address _escrow,
        uint256 _l2DaiBridge
    ) {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);

        starkNet = _starkNet;
        dai = _dai;
        l2Dai = _l2Dai;
        escrow = _escrow;
        l2DaiBridge = _l2DaiBridge;
    }

    function setCeiling(uint256 _ceiling) external auth whenOpen {
        ceiling = _ceiling;
        emit LogCeiling(_ceiling);
    }

    // slither-disable-next-line similar-names
    function deposit(
        uint256 amount,
        uint256 l2Recipient
    ) external whenOpen {
        emit LogDeposit(msg.sender, amount, l2Recipient);

        require(l2Recipient != 0 && l2Recipient != l2Dai && l2Recipient < SN_PRIME, "L1DAIBridge/invalid-address");

        TokenLike(dai).transferFrom(msg.sender, escrow, amount);

        require(
            TokenLike(dai).balanceOf(escrow) <= ceiling,
            "L1DAIBridge/above-ceiling"
        );

        uint256[] memory payload = new uint256[](3);
        payload[0] = l2Recipient;
        (payload[1], payload[2]) = toSplitUint(amount);

        StarkNetLike(starkNet).sendMessageToL2(l2DaiBridge, DEPOSIT, payload);
    }

    function toSplitUint(uint256 value) internal pure returns (uint256, uint256) {
      uint256 low = value & ((1 << 128) - 1);
      uint256 high = value >> 128;
      return (low, high);
    }

    // slither-disable-next-line similar-names
    function withdraw(uint256 amount, address l1Recipient) external {
        emit LogWithdrawal(l1Recipient, amount);

        uint256[] memory payload = new uint256[](4);
        payload[0] = HANDLE_WITHDRAW;
        payload[1] = uint256(uint160(msg.sender));
        (payload[2], payload[3]) = toSplitUint(amount);

        StarkNetLike(starkNet).consumeMessageFromL2(l2DaiBridge, payload);
        TokenLike(dai).transferFrom(escrow, l1Recipient, amount);
    }

    function forceWithdrawal(uint256 amount, uint256 l2Sender) external whenOpen {
        emit LogForceWithdrawal(msg.sender, amount, l2Sender);

        uint256[] memory payload = new uint256[](4);
        payload[0] = l2Sender;
        payload[1] = uint256(uint160(msg.sender));
        (payload[2], payload[3]) = toSplitUint(amount);

        StarkNetLike(starkNet).sendMessageToL2(l2DaiBridge, FORCE_WITHDRAW, payload);
    }
}