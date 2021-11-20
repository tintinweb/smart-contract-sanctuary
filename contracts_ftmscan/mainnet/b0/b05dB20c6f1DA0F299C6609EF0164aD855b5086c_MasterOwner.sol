import "Ownable.sol";
import "IVaultRegistry.sol";

interface IFarmRegistry {
    function refill(address vault, uint256 amount) external;
}
interface IOracle {
    function getPrice(address asset) external view returns (uint);
    function USDToGovToken(uint usd) external view returns (uint);
}

interface IGovToken {
    function mint(address _to, uint _amount) external;
}
interface IVault {
    function profitUncovered() external view returns (uint);
    function totalProfits() external view returns (uint);
    function token() external view returns (address);
    function recordProfitIncentiveCovered(uint) external;
}

//@title MasterOwner
//@license MIT
//@author akshaynexus
//@version 1.0

//@dev This contract is used to manage the inflation rate and the total supply of the gov token.
contract MasterOwner is Ownable {
    IOracle oracle;

    IGovToken token;

    IVaultRegistry vaultRegistry;
    IFarmRegistry farmRegistry;

    //Total USD worth of incentives minted
    uint incentivesMinted;

    /**
    * @notice Sets the vault registry contract,only the owner can call the setter
    * @param _registry Vault registry contract address
    */
    function setRegistry(address _registry) public onlyOwner {
        vaultRegistry = IVaultRegistry(_registry);
    }

    /**
    * @notice Sets the oracle contract,only the owner can call the setter
    * @param _oracle Oracle contract address
    */
    function setOracle(IOracle _oracle) public onlyOwner {
        oracle = _oracle;
    }

    /**
    * @notice Sets the gov token contract,only the owner can call the setter
    * @param _token Gov token contract address
    */
    function setToken(IGovToken _token) public onlyOwner {
        token = _token;
    }

    /**
    * @notice gets the total profits in usd
    * @return total profits in usd
    */
    function getTotalProfits() public view returns (uint256 total) {
        for(uint i=0;i<vaultRegistry.numReleases();i++){
            IVault vault = IVault(vaultRegistry.releases(i));
            uint profits = vault.totalProfits();
            uint profitsInUSD = ((profits * 1e18) * oracle.getPrice(vault.token())) / 1e18;
            total += profitsInUSD;
        }
    }

    /**
    * @notice gets the total incentives budget in usd
    * @return total incentives budget in usd
    */
    function getTotalIncentivesBudget() public view returns (uint256) {
        return getTotalProfits() / 10;
    }

    /**
    * @notice gets the price of hyl token in usd
    * @return uint price of hyl token in usd
    */
    function getPriceInUSD() public view returns (uint256) {
        oracle.getPrice(address(token));
    }

    /**
    * @notice Refills the hyl incentives for production vaults
    */
    function refillRewards() external onlyOwner {
        //This function is called by the owner to refill the incentives budget
        for(uint i=0;i<vaultRegistry.numReleases();i++){
            IVault vault = IVault(vaultRegistry.releases(i));

            uint profits = vault.profitUncovered();
            uint profitsInUSD = ((profits * 1e18) * oracle.getPrice(vault.token())) / 1e18;
            // total += profitsInUSD;

            uint incentivesToMint = oracle.USDToGovToken(profitsInUSD / 10);
            //Dev fee
            token.mint(owner(),incentivesToMint);
            // Incentives farm gets the rest
            token.mint(address(farmRegistry),incentivesToMint);
            farmRegistry.refill(address(vault),incentivesToMint);
            vault.recordProfitIncentiveCovered(profits);
        }
    }

    function getTotalRewards() public view returns (uint256) {
        //This returns the total rewards in HYL Tokens
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.4;

interface IVaultRegistry {
    function setGovernance(address governance) external;

    function acceptGovernance() external;

    function latestRelease() external view returns (string memory);

    function latestVault(address token) external view returns (address);

    function newRelease(address vault) external;

    function newVault(
        address token,
        address guardian,
        address rewards,
        string memory name,
        string memory symbol
    ) external returns (address);

    function newVault(
        address token,
        address guardian,
        address rewards,
        string memory name,
        string memory symbol,
        uint256 releaseDelta
    ) external returns (address);

    function newExperimentalVault(
        address token,
        address governance,
        address guardian,
        address rewards,
        string memory name,
        string memory symbol
    ) external returns (address);

    function newExperimentalVault(
        address token,
        address governance,
        address guardian,
        address rewards,
        string memory name,
        string memory symbol,
        uint256 releaseDelta
    ) external returns (address);

    function endorseVault(address vault) external;

    function endorseVault(address vault, uint256 releaseDelta) external;

    function setBanksy(address tagger) external;

    function setBanksy(address tagger, bool allowed) external;

    function tagVault(address vault, string memory tag) external;

    function numReleases() external view returns (uint256);

    function releases(uint256 arg0) external view returns (address);

    function numVaults(address arg0) external view returns (uint256);

    function vaults(address arg0, uint256 arg1) external view returns (address);

    function tokens(uint256 arg0) external view returns (address);

    function numTokens() external view returns (uint256);

    function isRegistered(address arg0) external view returns (bool);

    function governance() external view returns (address);

    function pendingGovernance() external view returns (address);

    function tags(address arg0) external view returns (string memory);

    function banksy(address arg0) external view returns (bool);
}