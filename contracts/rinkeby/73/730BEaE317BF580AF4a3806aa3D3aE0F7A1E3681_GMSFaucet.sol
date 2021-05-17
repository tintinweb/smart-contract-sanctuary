// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./libraries/SafeERC20.sol";

contract GMSFaucet {
    using SafeERC20 for IERC20;

    address private owner;
    address[] public stableMocks;

    constructor(address _owner, address[] memory _stableCoins) {
        require(_owner != address(0), "GMSFouset: Owner is a zero address");
        owner = _owner;
        stableMocks = _stableCoins;
    }

    function midasTouch(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            for (uint256 j = 0; j < stableMocks.length; j++) {
                address stableCoin = address(stableMocks[j]);
                uint8 decimals = IERC20(stableCoin).safeDecimals();
                uint256 stableCoinUnits = 150000 * (10**(decimals));

                IERC20(stableCoin).safeTransfer(address(accounts[i]), stableCoinUnits);
            }

            //payable(address(accounts[i])).transfer(150000000000000000);
        }
    }

    function recoverErc20(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount > 0) {
            IERC20(token).safeTransfer(owner, amount);
        }
    }

    function recoverEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "GMSSeedSaleTest: Only for contract Owner");
        _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}