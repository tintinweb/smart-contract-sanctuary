pragma solidity 0.6.12;

import "./PausableUpgradeable.sol";
import "./HordUpgradable.sol";

import "./HPool.sol";


/**
 * HPoolFactory contract.
 * @author Nikola Madjarevic
 * Date created: 29.7.21.
 * Github: madjarevicn
 */
contract HPoolFactory is PausableUpgradeable, HordUpgradable {
    address public hPoolManager;
    address[] deployedHPools;

    modifier onlyHPoolManager() {
        require(msg.sender == hPoolManager);
        _;
    }

    /**
     * @notice          Initializer function, can be called only once, replacing constructor
     */
    function initialize(address _hordCongress, address _maintainersRegistry)
        external
        initializer
    {
        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);
    }

    /**
     * @notice          Function to set HPoolManager contract address during the deployment.
     * @param           _hPoolManager is the address of HPoolManager smart-contract.
     */
    function setHPoolManager(address _hPoolManager) external {
        require(hPoolManager == address(0));
        require(_hPoolManager != address(0));

        hPoolManager = _hPoolManager;
    }

    /**
     * @notice          Function to deploy hPool, only callable by HPoolManager
     */
    function deployHPool(uint256 hPoolId, address championAddress) external onlyHPoolManager returns (address) {
        // Deploy the HPool contract
        HPool hpContract = new HPool(
            hPoolId,
            hordCongress,
            address(maintainersRegistry),
            hPoolManager,
            championAddress
        );

        // Add deployed pool to array of deployed pools
        deployedHPools.push(address(hpContract));

        // Return deployed hPool address
        return address(hpContract);
    }

    /**
     * @notice          Function to get array of deployed pool addresses
     * @param           startIndex is the start index for query
     * @param           endIndex is the end index for query
     *                  As an example to fetch [2,3,4,5] elements in array input will be (2,6)
     */
    function getDeployedHPools(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (address[] memory)
    {
        address[] memory hPools = new address[](endIndex - startIndex);
        uint256 counter;

        for (uint256 i = startIndex; i < endIndex; i++) {
            hPools[counter] = deployedHPools[i];
            counter++;
        }

        return hPools;
    }
}