/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/interfaces/ICoFiXMapping.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for CoFiX builtin contract address mapping
interface ICoFiXMapping {

    /// @dev Set the built-in contract address of the system
    /// @param cofiToken Address of CoFi token contract
    /// @param cofiNode Address of CoFi Node contract
    /// @param cofixDAO ICoFiXDAO implementation contract address
    /// @param cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @param cofixController ICoFiXController implementation contract address
    /// @param cofixVaultForStaking ICoFiXVaultForStaking implementation contract address
    function setBuiltinAddress(
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return cofiToken Address of CoFi token contract
    /// @return cofiNode Address of CoFi Node contract
    /// @return cofixDAO ICoFiXDAO implementation contract address
    /// @return cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @return cofixController ICoFiXController implementation contract address
    function getBuiltinAddress() external view returns (
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    );

    /// @dev Get address of CoFi token contract
    /// @return Address of CoFi Node token contract
    function getCoFiTokenAddress() external view returns (address);

    /// @dev Get address of CoFi Node contract
    /// @return Address of CoFi Node contract
    function getCoFiNodeAddress() external view returns (address);

    /// @dev Get ICoFiXDAO implementation contract address
    /// @return ICoFiXDAO implementation contract address
    function getCoFiXDAOAddress() external view returns (address);

    /// @dev Get ICoFiXRouter implementation contract address for CoFiX
    /// @return ICoFiXRouter implementation contract address for CoFiX
    function getCoFiXRouterAddress() external view returns (address);

    /// @dev Get ICoFiXController implementation contract address
    /// @return ICoFiXController implementation contract address
    function getCoFiXControllerAddress() external view returns (address);

    /// @dev Get ICoFiXVaultForStaking implementation contract address
    /// @return ICoFiXVaultForStaking implementation contract address
    function getCoFiXVaultForStakingAddress() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by CoFiX system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}


// File contracts/interfaces/ICoFiXGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface ICoFiXGovernance is ICoFiXMapping {

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// MIT

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


// File contracts/interfaces/ICoFiXDAO.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface ICoFiXDAO {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Configuration structure of CoFiXDAO contract
    struct Config {
        // Redeem status, 1 means normal
        uint8 status;

        // The number of CoFi redeem per block. 100
        uint16 cofiPerBlock;

        // The maximum number of CoFi in a single redeem. 30000
        uint32 cofiLimit;

        // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
        uint16 priceDeviationLimit;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Set the exchange relationship between the token and the price of the anchored target currency.
    /// For example, set USDC to anchor usdt, because USDC is 18 decimal places and usdt is 6 decimal places. 
    /// so exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token Address of origin token
    /// @param target Address of target anchor token
    /// @param exchange Exchange rate of token and target
    function setTokenExchange(address token, address target, uint exchange) external;

    /// @dev Get the exchange relationship between the token and the price of the anchored target currency.
    /// For example, set USDC to anchor usdt, because USDC is 18 decimal places and usdt is 6 decimal places. 
    /// so exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token Address of origin token
    /// @return target Address of target anchor token
    /// @return exchange Exchange rate of token and target
    function getTokenExchange(address token) external view returns (address target, uint exchange);

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

    /// @dev Redeem CoFi for ethers
    /// @notice Eth fee will be charged
    /// @param amount The amount of CoFi
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    function redeem(uint amount, address payback) external payable;

    /// @dev Redeem CoFi for Token
    /// @notice Eth fee will be charged
    /// @param token The target token
    /// @param amount The amount of CoFi
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    function redeemToken(address token, uint amount, address payback) external payable;

    /// @dev Get the current amount available for repurchase
    function quotaOf() external view returns (uint);
}


// File contracts/CoFiXBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// Router contract to interact with each CoFiXPair, no owner or governance
/// @dev Base contract of CoFiX
contract CoFiXBase {

    // Address of CoFiToken contract
    address constant COFI_TOKEN_ADDRESS = 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1;

    // Address of CoFiNode contract
    address constant CNODE_TOKEN_ADDRESS = 0x558201DC4741efc11031Cdc3BC1bC728C23bF512;

    // Genesis block number of CoFi
    // CoFiToken contract is created at block height 11040156. However, because the mining algorithm of CoFiX1.0
    // is different from that at present, a new mining algorithm is adopted from CoFiX2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the CoFi begins to decay. According to the circulation when CoFi2.0 is online, the new mining
    // algorithm is used to deduce and convert the CoFi, and the new algorithm is used to mine the CoFiX2.1
    // on-line flow, the actual block is 11040688
    uint constant COFI_GENESIS_BLOCK = 11040688;

    /// @dev ICoFiXGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance ICoFiXGovernance implementation contract address
    function initialize(address governance) virtual public {
        require(_governance == address(0), "CoFiX:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || ICoFiXGovernance(governance).checkGovernance(msg.sender, 0), "CoFiX:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to CoFiXDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = ICoFiXGovernance(_governance).getCoFiXDAOAddress();
        if (tokenAddress == address(0)) {
            ICoFiXDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(ICoFiXGovernance(_governance).checkGovernance(msg.sender, 0), "CoFiX:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "CoFiX:!contract");
        _;
    }
}


// File contracts/CoFiXMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev The contract is for CoFiX builtin contract address mapping
abstract contract CoFiXMapping is CoFiXBase, ICoFiXMapping {

    /// @dev Address of CoFi token contract
    address _cofiToken;

    /// @dev Address of CoFi Node contract
    address _cofiNode;

    /// @dev ICoFiXDAO implementation contract address
    address _cofixDAO;

    /// @dev ICoFiXRouter implementation contract address for CoFiX
    address _cofixRouter;

    /// @dev ICoFiXController implementation contract address
    address _cofixController;

    /// @dev ICoFiXVaultForStaking implementation contract address
    address _cofixVaultForStaking;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param cofiToken Address of CoFi token contract
    /// @param cofiNode Address of CoFi Node contract
    /// @param cofixDAO ICoFiXDAO implementation contract address
    /// @param cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @param cofixController ICoFiXController implementation contract address
    /// @param cofixVaultForStaking ICoFiXVaultForStaking implementation contract address
    function setBuiltinAddress(
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    ) external override onlyGovernance {

        if (cofiToken != address(0)) {
            _cofiToken = cofiToken;
        }
        if (cofiNode != address(0)) {
            _cofiNode = cofiNode;
        }
        if (cofixDAO != address(0)) {
            _cofixDAO = cofixDAO;
        }
        if (cofixRouter != address(0)) {
            _cofixRouter = cofixRouter;
        }
        if (cofixController != address(0)) {
            _cofixController = cofixController;
        }
        if (cofixVaultForStaking != address(0)) {
            _cofixVaultForStaking = cofixVaultForStaking;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return cofiToken Address of CoFi token contract
    /// @return cofiNode Address of CoFi Node contract
    /// @return cofixDAO ICoFiXDAO implementation contract address
    /// @return cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @return cofixController ICoFiXController implementation contract address
    function getBuiltinAddress() external view override returns (
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    ) {
        return (
            _cofiToken,
            _cofiNode,
            _cofixDAO,
            _cofixRouter,
            _cofixController,
            _cofixVaultForStaking
        );
    }

    /// @dev Get address of CoFi token contract
    /// @return Address of CoFi Node token contract
    function getCoFiTokenAddress() external view override returns (address) { return _cofiToken; }

    /// @dev Get address of CoFi Node contract
    /// @return Address of CoFi Node contract
    function getCoFiNodeAddress() external view override returns (address) { return _cofiNode; }

    /// @dev Get ICoFiXDAO implementation contract address
    /// @return ICoFiXDAO implementation contract address
    function getCoFiXDAOAddress() external view override returns (address) { return _cofixDAO; }

    /// @dev Get ICoFiXRouter implementation contract address for CoFiX
    /// @return ICoFiXRouter implementation contract address for CoFiX
    function getCoFiXRouterAddress() external view override returns (address) { return _cofixRouter; }

    /// @dev Get ICoFiXController implementation contract address
    /// @return ICoFiXController implementation contract address
    function getCoFiXControllerAddress() external view override returns (address) { return _cofixController; }

    /// @dev Get ICoFiXVaultForStaking implementation contract address
    /// @return ICoFiXVaultForStaking implementation contract address
    function getCoFiXVaultForStakingAddress() external view override returns (address) { return _cofixVaultForStaking; }

    /// @dev Registered address. The address registered here is the address accepted by CoFiX system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external override onlyGovernance {
        _registeredAddress[key] = addr;
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view override returns (address) {
        return _registeredAddress[key];
    }
}


// File contracts/CoFiXGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev CoFiX governance contract
contract CoFiXGovernance is CoFiXMapping, ICoFiXGovernance {

    /// @dev To support open-zeppelin/upgrades
    /// @param governance ICoFiXGovernance implementation contract address
    function initialize(address governance) public override {

        // While initialize CoFiXGovernance, newGovernance is address(this),
        // So must let newGovernance to 0
        require(governance == address(0), "CoFiXGovernance:!address");

        // newGovernance is address(this)
        super.initialize(address(this));

        // Add msg.sender to governance
        _governanceMapping[msg.sender] = GovernanceInfo(msg.sender, uint96(0xFFFFFFFFFFFFFFFFFFFFFFFF));
    }

    /// @dev Structure of governance address information
    struct GovernanceInfo {
        address addr;
        uint96 flag;
    }

    /// @dev Governance address information
    mapping(address=>GovernanceInfo) _governanceMapping;

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external override onlyGovernance {
        
        if (flag > 0) {
            _governanceMapping[addr] = GovernanceInfo(addr, uint96(flag));
        } else {
            _governanceMapping[addr] = GovernanceInfo(address(0), uint96(0));
        }
    }

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view override returns (uint) {
        return _governanceMapping[addr].flag;
    }

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this 
    /// weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) public view override returns (bool) {
        return _governanceMapping[addr].flag > flag;
    }
}