/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IStakingRewards {
    function stakingToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
}

interface IBalancerLPT {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (address);
}

interface IQuickswapLPT {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface IBalanceOf {
    function balanceOf(address account) external view returns (uint256);
}

interface IBalancerVault {
    function getPoolTokenInfo(bytes32 poolId, address token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );
}

contract SnapshotLPStrategy is Ownable {
    address public tokenAddress;
    
    address[] public balancerStakingContracts;
    address[] public quickswapStakingContracts;

    address[] public noStakeBalancerLpts;
    address[] public noStakeQuickswapLpts;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function addBalancerStakingContracts(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            balancerStakingContracts.push(addrs[i]);
        }
    }

    function addQuickswapStakingContracts(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            quickswapStakingContracts.push(addrs[i]);
        }
    }

    function addNoStakeBalancerPools(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            noStakeBalancerLpts.push(addrs[i]);
        }
    }

    function addNoStakeQuickswapPools(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            noStakeQuickswapLpts.push(addrs[i]);
        }
    }

    function _isSorted(uint256[] memory arr) private pure returns (bool) {
        for (uint256 i = 0; i < arr.length-1; i++) {
            if (arr[i] < arr[i+1]) {
                return false;
            }
        }
        return true;
    }

    function _removeIndiciesFromArray(address[] storage arr, uint256[] memory indicies) private {
        require(_isSorted(indicies), "Input must be sorted in descending order");

        for (uint256 i = 0; i < indicies.length; i++) {
            if (indicies[i] == arr.length-1) {
                arr.pop();
            }
            else {
                arr[indicies[i]] = arr[arr.length - 1];
                arr.pop();
            }
        }
    }

    function removeBalancerStakingContracts(uint256[] calldata indicies) external onlyOwner {
        _removeIndiciesFromArray(balancerStakingContracts, indicies);
    }

    function removeQuickswapStakingContracts(uint256[] calldata indicies) external onlyOwner {
        _removeIndiciesFromArray(quickswapStakingContracts, indicies);
    }

    function removeNoStakeBalancerLpts(uint256[] calldata indicies) external onlyOwner {
        _removeIndiciesFromArray(noStakeBalancerLpts, indicies);
    }

    function removeNoStakeQuickswapLpts(uint256[] calldata indicies) external onlyOwner {
        _removeIndiciesFromArray(noStakeQuickswapLpts, indicies);
    }

    function getValueOfBalancerLp(IBalancerLPT lpt, uint256 amount) public view returns (uint256) {
        uint256 totalSupply = lpt.totalSupply();

        bytes32 poolId = lpt.getPoolId();

        IBalancerVault vault = IBalancerVault(lpt.getVault());
        uint256 tokensInThisPool;
        (tokensInThisPool, , , ) = vault.getPoolTokenInfo(
            poolId,
            tokenAddress
        );

        return (tokensInThisPool * amount) / totalSupply;
    }

    function getValueOfQuickswapLp(IQuickswapLPT lpt, uint256 amount) public view returns (uint256) {
        uint256 totalSupply = lpt.totalSupply();

        uint112 reserves;

        if (lpt.token0() == tokenAddress) {
            (reserves,,) = lpt.getReserves();
        }
        else if (lpt.token1() == tokenAddress) {
            (,reserves,) = lpt.getReserves();
        }
        else {
            revert("this pool doesn't have the desired token");
        }

        return reserves * amount / totalSupply;
    }

    function getTotalStakedBalancerValue(address account) public view returns (uint256) {
        return getTotalValueFromCategory(account, "stakedBalancer");
    }

    function getTotalStakedQuickswapValue(address account) public view returns (uint256) {
        return getTotalValueFromCategory(account, "stakedQuickswap");
    }

    function getTotalNoStakeBalancerValue(address account) public view returns (uint256) {
        return getTotalValueFromCategory(account, "noStakeBalancer");
    }

    function getTotalNoStakeQuickswapValue(address account) public view returns (uint256) {
        return getTotalValueFromCategory(account, "noStakeQuickswap");
    }

    function getTotalValueOfAccount(address account) public view returns (uint256) {
        return getTotalStakedBalancerValue(account)
            + getTotalStakedQuickswapValue(account)
            + getTotalNoStakeBalancerValue(account)
            + getTotalNoStakeQuickswapValue(account);
    }

    function getTotalValueFromCategory(address account, string memory category) private view returns (uint256) {
        address[] memory arr;

        if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("stakedBalancer"))) {
            arr = balancerStakingContracts;
        }
        else if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("stakedQuickswap"))) {
            arr = quickswapStakingContracts;
        }
        else if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("noStakeBalancer"))) {
            arr = noStakeBalancerLpts;
        }
        else if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("noStakeQuickswap"))) {
            arr = noStakeQuickswapLpts;
        }
        else {
            revert("Invalid Category");
        }

        uint256 totalValue = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            uint256 lpBalance;
            address lptAddress;
            if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("stakedBalancer"))
            || keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("stakedQuickswap"))) {
                IStakingRewards sr = IStakingRewards(arr[i]);
                lptAddress = sr.stakingToken();
                lpBalance = sr.balanceOf(account) + IBalanceOf(lptAddress).balanceOf(account);
            }
            else {
                lptAddress = arr[i];
                lpBalance = IBalanceOf(lptAddress).balanceOf(account);
            }      

            if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("stakedBalancer"))
            || keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("noStakeBalancer"))) {
                totalValue += getValueOfBalancerLp(IBalancerLPT(lptAddress), lpBalance);
            }
            else {
                totalValue += getValueOfQuickswapLp(IQuickswapLPT(lptAddress), lpBalance);
            }
        }

        return totalValue;
    }
}