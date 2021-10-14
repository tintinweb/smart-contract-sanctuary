/**
 *Submitted for verification at arbiscan.io on 2021-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: MIXED

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
// License-Identifier: MIT
pragma solidity 0.8.4;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File @sushiswap/bentobox-sdk/contracts/[email protected]

interface IBentoBoxV1 {
    function balanceOf(IERC20 token, address user) external view returns (uint256 share);
    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
    
    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
    
    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// License-Identifier: MIT

interface Cauldron {
    function accrue() external;
    function withdrawFees() external;
    function accrueInfo() external view returns(uint64, uint128, uint64);
}

interface CauldronV1 {
    function accrue() external;
    function withdrawFees() external;
    function accrueInfo() external view returns(uint64, uint128);
}

contract AdvancedWithdrawer is BoringOwnable {
    
    Cauldron[] public cauldrons;
    IBentoBoxV1 public constant bentoBox = IBentoBoxV1(0x74c764D41B77DBbb4fe771daB1939B00b146894A);
    IERC20 public constant MIM = IERC20(0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A);
    
    constructor(Cauldron[] memory pools) {
        cauldrons = pools;
    }
    
    function withdraw() external {
        uint256 length = cauldrons.length;
        for(uint256 i = 0; i < length; i++) {
            cauldrons[i].accrue();
            (, uint256 feesEarned, ) = cauldrons[i].accrueInfo();
            if(feesEarned > (bentoBox.toAmount(MIM, bentoBox.balanceOf(MIM, address(cauldrons[i])), false))) {
                MIM.transferFrom(msg.sender, address(bentoBox), feesEarned);
                bentoBox.deposit(MIM, address(bentoBox), address(cauldrons[i]), feesEarned, 0);
            }
            cauldrons[i].withdrawFees();
        }
    }
    
    function addPool(Cauldron pool) external onlyOwner {
        cauldrons.push(pool);
    }
    
    function addPools(Cauldron[] memory pools) external onlyOwner {
        for(uint256 i = 0; i < pools.length; i++) {
            cauldrons.push(pools[i]);
        }
    }
    
}