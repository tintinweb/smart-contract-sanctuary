/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IFortMapping.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for Fort builtin contract address mapping
interface IFortMapping {

    /// @dev Set the built-in contract address of the system
    /// @param fortToken Address of fort token contract
    /// @param fortDAO IFortDAO implementation contract address
    /// @param fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @param fortLever IFortLever implementation contract address
    /// @param fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return fortToken Address of fort token contract
    /// @return fortDAO IFortDAO implementation contract address
    /// @return fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @return fortLever IFortLever implementation contract address
    /// @return fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view returns (
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    );

    /// @dev Get address of fort token contract
    /// @return Address of fort token contract
    function getFortTokenAddress() external view returns (address);

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getFortDAOAddress() external view returns (address);

    /// @dev Get IFortEuropeanOption implementation contract address for Fort
    /// @return IFortEuropeanOption implementation contract address for Fort
    function getFortEuropeanOptionAddress() external view returns (address);

    /// @dev Get IFortLever implementation contract address
    /// @return IFortLever implementation contract address
    function getFortLeverAddress() external view returns (address);

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getFortVaultForStakingAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by Fort system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}


// File contracts/interfaces/IFortGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface IFortGovernance is IFortMapping {

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


// File contracts/interfaces/IFortDAO.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface IFortDAO {

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


// File contracts/FortBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// Router contract to interact with each FortPair, no owner or governance
/// @dev Base contract of Fort
contract FortBase {

    /// @dev IFortGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Fort:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IFortGovernance(governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to FortDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = IFortGovernance(_governance).getFortDAOAddress();
        if (tokenAddress == address(0)) {
            IFortDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IFortGovernance(_governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "Fort:!contract");
        _;
    }
}


// File contracts/FortMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev The contract is for Fort builtin contract address mapping
abstract contract FortMapping is FortBase, IFortMapping {

    /// @dev Address of fort token contract
    address _fortToken;

    /// @dev IFortDAO implementation contract address
    address _fortDAO;

    /// @dev IFortEuropeanOption implementation contract address for Fort
    address _fortEuropeanOption;

    /// @dev IFortLever implementation contract address
    address _fortLever;

    /// @dev IFortVaultForStaking implementation contract address
    address _fortVaultForStaking;

    /// @dev INestPriceFacade implementation contract address
    address _nestPriceFacade;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param fortToken Address of fort token contract
    /// @param fortDAO IFortDAO implementation contract address
    /// @param fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @param fortLever IFortLever implementation contract address
    /// @param fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    ) external override onlyGovernance {

        if (fortToken != address(0)) {
            _fortToken = fortToken;
        }
        if (fortDAO != address(0)) {
            _fortDAO = fortDAO;
        }
        if (fortEuropeanOption != address(0)) {
            _fortEuropeanOption = fortEuropeanOption;
        }
        if (fortLever != address(0)) {
            _fortLever = fortLever;
        }
        if (fortVaultForStaking != address(0)) {
            _fortVaultForStaking = fortVaultForStaking;
        }
        if (nestPriceFacade != address(0)) {
            _nestPriceFacade = nestPriceFacade;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return fortToken Address of fort token contract
    /// @return fortDAO IFortDAO implementation contract address
    /// @return fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @return fortLever IFortLever implementation contract address
    /// @return fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view override returns (
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    ) {
        return (
            _fortToken,
            _fortDAO,
            _fortEuropeanOption,
            _fortLever,
            _fortVaultForStaking,
            _nestPriceFacade
        );
    }

    /// @dev Get address of fort token contract
    /// @return Address of fort token contract
    function getFortTokenAddress() external view override returns (address) { return _fortToken; }

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getFortDAOAddress() external view override returns (address) { return _fortDAO; }

    /// @dev Get IFortEuropeanOption implementation contract address for Fort
    /// @return IFortEuropeanOption implementation contract address for Fort
    function getFortEuropeanOptionAddress() external view override returns (address) { return _fortEuropeanOption; }

    /// @dev Get IFortLever implementation contract address
    /// @return IFortLever implementation contract address
    function getFortLeverAddress() external view override returns (address) { return _fortLever; }

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getFortVaultForStakingAddress() external view override returns (address) { return _fortVaultForStaking; }

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view override returns (address) { return _nestPriceFacade; }

    /// @dev Registered address. The address registered here is the address accepted by Fort system
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


// File contracts/FortGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Fort governance contract
contract FortGovernance is FortMapping, IFortGovernance {

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public override {

        // While initialize FortGovernance, newGovernance is address(this),
        // So must let newGovernance to 0
        require(governance == address(0), "FortGovernance:!address");

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
    function checkGovernance(address addr, uint flag) external view override returns (bool) {
        return _governanceMapping[addr].flag > flag;
    }
}