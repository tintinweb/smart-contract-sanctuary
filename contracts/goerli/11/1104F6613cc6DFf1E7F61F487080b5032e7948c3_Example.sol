pragma solidity 0.7.6;

import "./RocketStorageInterface.sol";
import "./RocketDepositPoolInterface.sol";
import "./RocketTokenRETHInterface.sol";

contract Example {

    RocketStorageInterface rocketStorage = RocketStorageInterface(0);
    RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(0);
    mapping(address => uint256) private rethHeld;

    constructor(address _rocketStorageAddress) {
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
        address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
        rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);
    }

    receive() external payable {
        // Load contracts
        address rocketDepositPoolAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketDepositPool")));
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(rocketDepositPoolAddress);
        // Forward deposit to RP & get amount of rETH minted
        uint256 rethBalance1 = rocketTokenRETH.balanceOf(address(this));
        rocketDepositPool.deposit{value: msg.value}();
        uint256 rethBalance2 = rocketTokenRETH.balanceOf(address(this));
        require(rethBalance2 > rethBalance1, "No rETH was minted");
        uint256 rethMinted = rethBalance2 - rethBalance1;
        rethHeld[msg.sender] = rethHeld[msg.sender] + rethMinted;
    }

    function withdraw(uint256 amount) external {
        require(amount > rethHeld[msg.sender], "requesting too much to withdraw");
        // Transfer rETH to caller
        rethHeld[msg.sender] = rethHeld[msg.sender] - amount;
        uint256 ethBalance1 = address(this).balance;
        rocketTokenRETH.burn(amount);
        uint256 ethBalance2 = address(this).balance;
        uint256 ethReleased = ethBalance2 - ethBalance1;
        msg.sender.transfer(ethReleased);
    }

}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketStorageInterface {

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDepositPoolInterface {
    function getBalance() external view returns (uint256);
    function getExcessBalance() external view returns (uint256);
    function deposit() external payable;
    function recycleDissolvedDeposit() external payable;
    function recycleWithdrawnDeposit() external payable;
    function recycleLiquidatedStake() external payable;
    function assignDeposits() external;
    function withdrawExcessBalance(uint256 _amount) external;
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RocketTokenRETHInterface is IERC20 {
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
    function getExchangeRate() external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getCollateralRate() external view returns (uint256);
    function depositRewards() external payable;
    function depositExcess() external payable;
    function mint(uint256 _ethAmount, address _to) external;
    function burn(uint256 _rethAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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