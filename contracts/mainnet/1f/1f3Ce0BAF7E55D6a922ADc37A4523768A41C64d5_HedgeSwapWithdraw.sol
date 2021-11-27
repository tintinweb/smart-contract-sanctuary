/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

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


// File contracts/libs/TransferHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/interfaces/IHedgeMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for Hedge builtin contract address mapping
interface IHedgeMapping {

    /// @dev Set the built-in contract address of the system
    /// @param dcuToken Address of dcu token contract
    /// @param hedgeDAO IHedgeDAO implementation contract address
    /// @param hedgeOptions IHedgeOptions implementation contract address
    /// @param hedgeFutures IHedgeFutures implementation contract address
    /// @param hedgeVaultForStaking IHedgeVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address dcuToken,
        address hedgeDAO,
        address hedgeOptions,
        address hedgeFutures,
        address hedgeVaultForStaking,
        address nestPriceFacade
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return dcuToken Address of dcu token contract
    /// @return hedgeDAO IHedgeDAO implementation contract address
    /// @return hedgeOptions IHedgeOptions implementation contract address
    /// @return hedgeFutures IHedgeFutures implementation contract address
    /// @return hedgeVaultForStaking IHedgeVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view returns (
        address dcuToken,
        address hedgeDAO,
        address hedgeOptions,
        address hedgeFutures,
        address hedgeVaultForStaking,
        address nestPriceFacade
    );

    /// @dev Get address of dcu token contract
    /// @return Address of dcu token contract
    function getDCUTokenAddress() external view returns (address);

    /// @dev Get IHedgeDAO implementation contract address
    /// @return IHedgeDAO implementation contract address
    function getHedgeDAOAddress() external view returns (address);

    /// @dev Get IHedgeOptions implementation contract address
    /// @return IHedgeOptions implementation contract address
    function getHedgeOptionsAddress() external view returns (address);

    /// @dev Get IHedgeFutures implementation contract address
    /// @return IHedgeFutures implementation contract address
    function getHedgeFuturesAddress() external view returns (address);

    /// @dev Get IHedgeVaultForStaking implementation contract address
    /// @return IHedgeVaultForStaking implementation contract address
    function getHedgeVaultForStakingAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by Hedge system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}


// File contracts/interfaces/IHedgeGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface IHedgeGovernance is IHedgeMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/interfaces/IHedgeDAO.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface IHedgeDAO {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable;

    /// @dev The function returns eth rewards of specified pool
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view returns (uint);

    /// @dev Settlement
    /// @param pool Destination pool. Indicates which pool to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable;
}


// File contracts/HedgeBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of Hedge
contract HedgeBase {

    /// @dev IHedgeGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IHedgeGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Hedge:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IHedgeGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IHedgeGovernance(governance).checkGovernance(msg.sender, 0), "Hedge:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to HedgeDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = IHedgeGovernance(_governance).getHedgeDAOAddress();
        if (tokenAddress == address(0)) {
            IHedgeDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IHedgeGovernance(_governance).checkGovernance(msg.sender, 0), "Hedge:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "Hedge:!contract");
        _;
    }
}


// File contracts/HedgeFrequentlyUsed.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of Hedge
contract HedgeFrequentlyUsed is HedgeBase {

    // Address of DCU contract
    address constant DCU_TOKEN_ADDRESS = 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF;

    // Address of NestPriceFacade contract
    address constant NEST_PRICE_FACADE_ADDRESS = 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A;
    
    // USDT代币地址
    address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // USDT代币的基数
    uint constant USDT_BASE = 1000000;
}


// File contracts/HedgeSwapWithdraw.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev DCU分发合约取出合约
contract HedgeSwapWithdraw is HedgeFrequentlyUsed {

    // NEST代币地址
    address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    // K值，初始化存入1500万nest，同时增发1500万dcu到资金池
    uint constant K = 15000000 ether * 15000000 ether;

    constructor() {
    }

    /// @dev 从资金池等比例取出一半资金，用于跨链到BSC
    function withdraw() external onlyGovernance {
        uint balance0 = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(this));
        uint balance1 = IERC20( DCU_TOKEN_ADDRESS).balanceOf(address(this));
        
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, balance0 >> 1);
        TransferHelper.safeTransfer( DCU_TOKEN_ADDRESS, msg.sender, balance1 >> 1);
        
        balance0 = IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(this));
        balance1 = IERC20( DCU_TOKEN_ADDRESS).balanceOf(address(this));
        
        require(balance0 * balance1 > K - 1 ether * 1 ether 
             && balance0 * balance1 < K + 1 ether * 1 ether, "HSW:balance error");
    }
}