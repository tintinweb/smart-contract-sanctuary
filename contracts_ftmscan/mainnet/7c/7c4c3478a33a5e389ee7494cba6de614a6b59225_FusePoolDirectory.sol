// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./Comptroller.sol";
import "./Unitroller.sol";
import "./PriceOracle.sol";

/**
 * @title FusePoolDirectory
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice FusePoolDirectory is a directory for Fuse interest rate pools.
 */
contract FusePoolDirectory is OwnableUpgradeable {
    /**
     * @dev Initializes a deployer whitelist if desired.
     * @param _enforceDeployerWhitelist Boolean indicating if the deployer whitelist is to be enforced.
     * @param _deployerWhitelist Array of Ethereum accounts to be whitelisted.
     */
    function initialize(bool _enforceDeployerWhitelist, address[] memory _deployerWhitelist) public initializer {
        __Ownable_init();
        enforceDeployerWhitelist = _enforceDeployerWhitelist;
        for (uint256 i = 0; i < _deployerWhitelist.length; i++) deployerWhitelist[_deployerWhitelist[i]] = true;
    }

    /**
     * @dev Struct for a Fuse interest rate pool.
     */
    struct FusePool {
        string name;
        address creator;
        address comptroller;
        uint256 blockPosted;
        uint256 timestampPosted;
    }

    /**
     * @dev Array of Fuse interest rate pools.
     */
    FusePool[] public pools;

    /**
     * @dev Maps Ethereum accounts to arrays of Fuse pool indexes.
     */
    mapping(address => uint256[]) private _poolsByAccount;

    /**
     * @dev Maps Fuse pool Comptroller addresses to bools indicating if they have been posted to the directory.
     */
    mapping(address => bool) public poolExists;

    /**
     * @dev Emitted when a new Fuse pool is added to the directory.
     */
    event PoolRegistered(uint256 index, FusePool pool);

    /**
     * @dev Booleans indicating if the deployer whitelist is enforced.
     */
    bool public enforceDeployerWhitelist;

    /**
     * @dev Maps Ethereum accounts to booleans indicating if they are allowed to deploy pools.
     */
    mapping(address => bool) public deployerWhitelist;

    /**
     * @dev Controls if the deployer whitelist is to be enforced.
     * @param _enforceDeployerWhitelist Boolean indicating if the deployer whitelist is to be enforced.
     */
    function _setDeployerWhitelistEnforcement(bool _enforceDeployerWhitelist) external onlyOwner {
        enforceDeployerWhitelist = _enforceDeployerWhitelist;
    }

    /**
     * @dev Adds Ethereum accounts to the deployer whitelist.
     * @param deployers Array of Ethereum accounts to be whitelisted.
     */
    function _whitelistDeployers(address[] memory deployers) external onlyOwner {
        require(deployers.length > 0, "No deployers supplied.");
        for (uint256 i = 0; i < deployers.length; i++) deployerWhitelist[deployers[i]] = true;
    }

    /**
     * @dev Adds a new Fuse pool to the directory.
     * @param name The name of the pool.
     * @param comptroller The pool's Comptroller proxy contract address.
     * @return The index of the registered Fuse pool.
     */
    function registerPool(string memory name, address comptroller) external returns (uint256) {
        require(msg.sender == Comptroller(comptroller).admin(), "Pool admin is not the sender.");
        return _registerPool(name, comptroller);
    }

    /**
     * @dev Adds a new Fuse pool to the directory (without checking msg.sender).
     * @param name The name of the pool.
     * @param comptroller The pool's Comptroller proxy contract address.
     * @return The index of the registered Fuse pool.
     */
    function _registerPool(string memory name, address comptroller) internal returns (uint256) {
        require(!poolExists[comptroller], "Pool already exists in the directory.");
        require(!enforceDeployerWhitelist || deployerWhitelist[msg.sender], "Sender is not on deployer whitelist.");
        FusePool memory pool = FusePool(name, msg.sender, comptroller, block.number, block.timestamp);
        pools.push(pool);
        _poolsByAccount[msg.sender].push(pools.length - 1);
        poolExists[comptroller] = true;
        emit PoolRegistered(pools.length - 1, pool);
        return pools.length - 1;
    }

    /**
     * @dev Deploys a new Fuse pool and adds to the directory.
     * @param name The name of the pool.
     * @param implementation The Comptroller implementation contract address.
     * @param enforceWhitelist Boolean indicating if the pool's supplier/borrower whitelist is to be enforced.
     * @param closeFactor The pool's close factor (scaled by 1e18).
     * @param maxAssets Maximum number of assets in the pool.
     * @param liquidationIncentive The pool's liquidation incentive (scaled by 1e18).
     * @param priceOracle The pool's PriceOracle contract address.
     * @return The index of the registered Fuse pool and the Unitroller proxy address.
     */
    function deployPool(string memory name, address implementation, bool enforceWhitelist, uint256 closeFactor, uint256 maxAssets, uint256 liquidationIncentive, address priceOracle) external returns (uint256, address) {
        // Input validation
        require(implementation != address(0), "No Comptroller implementation contract address specified.");
        require(priceOracle != address(0), "No PriceOracle contract address specified.");

        // Deploy Unitroller using msg.sender, name, and block.number as a salt
        bytes memory unitrollerCreationCode = hex"60806040526001805460ff60a81b1960ff60a01b19909116600160a01b1716600160a81b17905534801561003257600080fd5b50600080546001600160a01b031916331790556107c6806100546000396000f3fe6080604052600436106100a75760003560e01c8063c1e8033411610064578063c1e8033414610208578063dcfbc0c71461021d578063e16d2c3214610232578063e992a04114610247578063e9c714f21461027a578063f851a4401461028f576100a7565b80630a755ec21461012a57806326782247146101535780632f1069ba14610184578063b71d1a0c14610199578063bb82aa5e146101de578063bf0f1d7b146101f3575b6002546040516000916001600160a01b031690829036908083838082843760405192019450600093509091505080830381855af49150503d806000811461010a576040519150601f19603f3d011682016040523d82523d6000602084013e61010f565b606091505b505090506040513d6000823e818015610126573d82f35b3d82fd5b34801561013657600080fd5b5061013f6102a4565b604080519115158252519081900360200190f35b34801561015f57600080fd5b506101686102b4565b604080516001600160a01b039092168252519081900360200190f35b34801561019057600080fd5b5061013f6102c3565b3480156101a557600080fd5b506101cc600480360360208110156101bc57600080fd5b50356001600160a01b03166102d3565b60408051918252519081900360200190f35b3480156101ea57600080fd5b5061016861035f565b3480156101ff57600080fd5b506101cc61036e565b34801561021457600080fd5b506101cc6103e6565b34801561022957600080fd5b506101686104d9565b34801561023e57600080fd5b506101cc6104e8565b34801561025357600080fd5b506101cc6004803603602081101561026a57600080fd5b50356001600160a01b0316610557565b34801561028657600080fd5b506101cc6105d6565b34801561029b57600080fd5b506101686106bc565b600154600160a81b900460ff1681565b6001546001600160a01b031681565b600154600160a01b900460ff1681565b60006102dd6106cb565b6102f4576102ed6001600e610724565b905061035a565b600180546001600160a01b038481166001600160a01b0319831681179093556040805191909216808252602082019390935281517fca4f2f25d0898edd99413412fb94012f9e54ec8142f9b093e7720646a95b16a9929181900390910190a160005b9150505b919050565b6002546001600160a01b031681565b60006103786106cb565b61038f5761038860016004610724565b90506103e3565b600154600160a81b900460ff166103a7576000610388565b6001805460ff60a81b191690556040517fc8ed31b431dd871a74f7e15bc645f3dbdd94636e59d7633a4407b044524eb45990600090a160005b90505b90565b6003546000906001600160a01b03163314158061040c57506003546001600160a01b0316155b1561041c57610388600180610724565b60028054600380546001600160a01b038082166001600160a01b031980861682179687905590921690925560408051938316808552949092166020840152815190927fd604de94d45953f9138079ec1b82d533cb2160c906d1076d1f7ed54befbca97a92908290030190a1600354604080516001600160a01b038085168252909216602083015280517fe945ccee5d701fc83f9b8aa8ca94ea4219ec1fcbd4f4cab4f0ea57c5c3e1d8159281900390910190a160005b9250505090565b6003546001600160a01b031681565b60006104f26106cb565b6105025761038860016004610724565b600154600160a01b900460ff1661051a576000610388565b6001805460ff60a01b191690556040517f9f60987413d3c28e8232c3eec2559453cc8c6805ff81501e344a133944113e3590600090a160006103e0565b60006105616106cb565b610571576102ed6001600f610724565b600380546001600160a01b038481166001600160a01b0319831617928390556040805192821680845293909116602083015280517fe945ccee5d701fc83f9b8aa8ca94ea4219ec1fcbd4f4cab4f0ea57c5c3e1d8159281900390910190a16000610356565b6001546000906001600160a01b0316331415806105f1575033155b156106025761038860016000610724565b60008054600180546001600160a01b038082166001600160a01b031980861682179687905590921690925560408051938316808552949092166020840152815190927ff9ffabca9c8276e99321725bcb43fb076a6c66a54b7f21c4e8146d8519b417dc92908290030190a1600154604080516001600160a01b038085168252909216602083015280517fca4f2f25d0898edd99413412fb94012f9e54ec8142f9b093e7720646a95b16a99281900390910190a160006104d2565b6000546001600160a01b031681565b600080546001600160a01b0316331480156106ef5750600154600160a81b900460ff165b806103e057503373a731585ab05fc9f83555cf9bff8f58ee94e18f851480156103e0575050600154600160a01b900460ff1690565b60007f45b96fe442630264581b197e84bbada861235052c5a1aadfff9ea4e40a969aa083601481111561075357fe5b83601581111561075f57fe5b604080519283526020830191909152600082820152519081900360600190a182601481111561078a57fe5b939250505056fea265627a7a723158201722092063f5443fefa34106ef6ffc478ecda488ff039bdba53a48a8b868b8a064736f6c63430005110032";
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, name, block.number));
        address proxy;

        assembly {
            proxy := create2(0, add(unitrollerCreationCode, 32), mload(unitrollerCreationCode), salt)
        }

        // Setup Unitroller
        Unitroller unitroller = Unitroller(proxy);
        unitroller._setPendingImplementation(implementation);
        Comptroller comptrollerImplementation = Comptroller(implementation);
        comptrollerImplementation._become(unitroller);
        Comptroller comptrollerProxy = Comptroller(proxy);

        // Set pool parameters
        comptrollerProxy._setCloseFactor(closeFactor);
        comptrollerProxy._setMaxAssets(maxAssets);
        comptrollerProxy._setLiquidationIncentive(liquidationIncentive);
        comptrollerProxy._setPriceOracle(PriceOracle(priceOracle));

        // Whitelist
        if (enforceWhitelist) require(comptrollerProxy._setWhitelistEnforcement(true) == 0, "Failed to enforce supplier/borrower whitelist.");

        // Make msg.sender the admin
        unitroller._setPendingAdmin(msg.sender);

        // Register the pool with this FusePoolDirectory
        return (_registerPool(name, proxy), proxy);
    }

    /**
     * @notice Returns arrays of all Fuse pools' data.
     * @dev This function is not designed to be called in a transaction: it is too gas-intensive.
     */
    function getAllPools() external view returns (FusePool[] memory) {
        return pools;
    }

    /**
     * @notice Returns arrays of all public Fuse pool indexes and data.
     * @dev This function is not designed to be called in a transaction: it is too gas-intensive.
     */
    function getPublicPools() external view returns (uint256[] memory, FusePool[] memory) {
        uint256 arrayLength = 0;

        for (uint256 i = 0; i < pools.length; i++) {
            try Comptroller(pools[i].comptroller).enforceWhitelist() returns (bool enforceWhitelist) {
                if (enforceWhitelist) continue;
            } catch { }

            arrayLength++;
        }

        uint256[] memory indexes = new uint256[](arrayLength);
        FusePool[] memory publicPools = new FusePool[](arrayLength);
        uint256 index = 0;

        for (uint256 i = 0; i < pools.length; i++) {
            try Comptroller(pools[i].comptroller).enforceWhitelist() returns (bool enforceWhitelist) {
                if (enforceWhitelist) continue;
            } catch { }

            indexes[index] = i;
            publicPools[index] = pools[i];
            index++;
        }

        return (indexes, publicPools);
    }

    /**
     * @notice Returns arrays of Fuse pool indexes and data created by `account`.
     */
    function getPoolsByAccount(address account) external view returns (uint256[] memory, FusePool[] memory) {
        uint256[] memory indexes = new uint256[](_poolsByAccount[account].length);
        FusePool[] memory accountPools = new FusePool[](_poolsByAccount[account].length);

        for (uint256 i = 0; i < _poolsByAccount[account].length; i++) {
            indexes[i] = _poolsByAccount[account][i];
            accountPools[i] = pools[_poolsByAccount[account][i]];
        }

        return (indexes, accountPools);
    }

    /**
     * @dev Maps Ethereum accounts to arrays of Fuse pool Comptroller proxy contract addresses.
     */
    mapping(address => address[]) private _bookmarks;

    /**
     * @notice Returns arrays of Fuse pool Unitroller (Comptroller proxy) contract addresses bookmarked by `account`.
     */
    function getBookmarks(address account) external view returns (address[] memory) {
        return _bookmarks[account];
    }

    /**
     * @notice Bookmarks a Fuse pool Unitroller (Comptroller proxy) contract addresses.
     */
    function bookmarkPool(address comptroller) external {
        _bookmarks[msg.sender].push(comptroller);
    }
}