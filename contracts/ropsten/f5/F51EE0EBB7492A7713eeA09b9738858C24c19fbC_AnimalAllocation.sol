/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

/******************************************/
/*       AnimalAllocation starts here     */
/******************************************/

contract AnimalAllocation {

    IERC20 public ANIMAL; 

    bool initialized;
    address internal deployer;
    uint256 public startBlock;

    mapping (address => Allocation[]) public allocations;

    struct Allocation {
        uint256 tokensAtTGE;
        bool tokensAtTGEWithdrawn;
        uint256 sharePerBlock;
        uint256 lastWithdrawalBlock;
        uint256 unlockBlock;
        uint256 endBlock;
        uint256 endPeriod;
    }

    /**
     * @dev Populate allocations.
     */
    constructor() {
        
        deployer = msg.sender;

        uint256[] memory unlockBlocks = new uint[](6);
        uint256[] memory endPeriods = new uint[](6);
        uint256[] memory endBlocks = new uint[](6);

        // Cliff: 0 , Vest: 0
        unlockBlocks[0] = block.number;
        endPeriods[0] = 0;
        endBlocks[0] = block.number + 0;

        // Cliff: 0 , Vest: 0.01
        unlockBlocks[1] = block.number;
        endPeriods[1] = 2100;
        endBlocks[1] = block.number + 2100;

        // Cliff: 0 , Vest: 12
        unlockBlocks[2] = block.number;
        endPeriods[2] = 2340000;
        endBlocks[2] = block.number + 2340000;

        // Cliff: 0 , Vest: 18
        unlockBlocks[3] = block.number;
        endPeriods[3] = 3510000;
        endBlocks[3] = block.number + 3510000;
        
        // Cliff: 0 , Vest: 24
        unlockBlocks[4] = block.number;
        endPeriods[4] = 4680000;
        endBlocks[4] = block.number + 4680000;

        // Cliff: 3 , Vest: 18
        unlockBlocks[5] = block.number + 585000;
        endPeriods[5] = 3510000;
        endBlocks[5] = block.number + 3510000;

/******************************************/
/*            Cliff: 0 , Vest: 0          */
/******************************************/

        allocations[0x298EDb6b8312A2730d9f15ff7bAF95a87F4f320D].push(Allocation({
            tokensAtTGE: 625000000 * 1e18,
            tokensAtTGEWithdrawn: false,
            sharePerBlock: 0,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[0],
            endPeriod: endPeriods[0],
            endBlock: endBlocks[0]
        }));

        allocations[0x0Dc54B2Ab4B8a98a25371aB93e678B2423F8c390].push(Allocation({
            tokensAtTGE: 195555559 * 1e18,
            tokensAtTGEWithdrawn: false,
            sharePerBlock: 0,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[0],
            endPeriod: endPeriods[0],
            endBlock: endBlocks[0]
        }));

        allocations[0xA77364249507F3e55cFb1143e139F931dCC00E9e].push(Allocation({
            tokensAtTGE: 88 * 1e18,
            tokensAtTGEWithdrawn: false,
            sharePerBlock: 0,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[0],
            endPeriod: endPeriods[0],
            endBlock: endBlocks[0]
        }));

/******************************************/
/*           Cliff: 0 , Vest: 0.01        */
/******************************************/

        allocations[0x2c0894ef51CC89f8CB30d6C77e5eF7d65E9807E7].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 476190476190476190476,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[1],
            endPeriod: endPeriods[1],
            endBlock: endBlocks[1]
        }));

        allocations[0xA77364249507F3e55cFb1143e139F931dCC00E9e].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 1000,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[1],
            endPeriod: endPeriods[1],
            endBlock: endBlocks[1]
        }));

/******************************************/
/*            Cliff: 0 , Vest: 12         */
/******************************************/

        allocations[0x71611F86B3009F3F8a38BFc527e993F10c77AAbE].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 1068376068376068376068,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[2],
            endPeriod: endPeriods[2],
            endBlock: endBlocks[2]
        }));

        allocations[0xA77364249507F3e55cFb1143e139F931dCC00E9e].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 1000000,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[2],
            endPeriod: endPeriods[2],
            endBlock: endBlocks[2]
        }));

/******************************************/
/*            Cliff: 0 , Vest: 18         */
/******************************************/

        allocations[0x0Dc54B2Ab4B8a98a25371aB93e678B2423F8c390].push(Allocation({
            tokensAtTGE: 7142857 * 1e18,
            tokensAtTGEWithdrawn: false,
            sharePerBlock: 18315018233618233618,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[3],
            endPeriod: endPeriods[3],
            endBlock: endBlocks[3]
        }));

        allocations[0x72E394C2d3Fba26224a5f9aBBD7d244ec3bfC56e].push(Allocation({
            tokensAtTGE: 714286 * 1e18,
            tokensAtTGEWithdrawn: false,
            sharePerBlock: 1831501709401709401,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[3],
            endPeriod: endPeriods[3],
            endBlock: endBlocks[3]
        }));

        allocations[0xA77364249507F3e55cFb1143e139F931dCC00E9e].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 1000000000,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[3],
            endPeriod: endPeriods[3],
            endBlock: endBlocks[3]
        }));

/******************************************/
/*            Cliff: 0 , Vest: 24         */
/******************************************/

        allocations[0xec750181f18C09C32185814904adf44d7470E0a7].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 975866873931623931623,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[4],
            endPeriod: endPeriods[4],
            endBlock: endBlocks[4]
        }));

        allocations[0xA77364249507F3e55cFb1143e139F931dCC00E9e].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 1000000000000,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[4],
            endPeriod: endPeriods[4],
            endBlock: endBlocks[4]
        }));

/******************************************/
/*            Cliff: 3 , Vest: 18         */
/******************************************/

        allocations[0x364DA3fa069c3910A08490f54D1b3A2fCe5af585].push(Allocation({
            tokensAtTGE: 1000000 * 1e18,
            tokensAtTGEWithdrawn: false,
            sharePerBlock: 5413105413105413105,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[5],
            endPeriod: endPeriods[5],
            endBlock: endBlocks[5]
        }));

        allocations[0x72E394C2d3Fba26224a5f9aBBD7d244ec3bfC56e].push(Allocation({
            tokensAtTGE: 500000 * 1e18,
            tokensAtTGEWithdrawn: false,
            sharePerBlock: 2706552706552706552,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[5],
            endPeriod: endPeriods[5],
            endBlock: endBlocks[5]
        }));

        allocations[0x3ba3Ae05d90437a431352758D51171AF2f6D7Cdd].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 89031339031339031339,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[5],
            endPeriod: endPeriods[5],
            endBlock: endBlocks[5]
        }));

        allocations[0xA77364249507F3e55cFb1143e139F931dCC00E9e].push(Allocation({
            tokensAtTGE: 0,
            tokensAtTGEWithdrawn: true,
            sharePerBlock: 1000000000000000,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[5],
            endPeriod: endPeriods[5],
            endBlock: endBlocks[5]
        }));
        
        startBlock = block.number;
    }

    function initialize(IERC20 _ANIMAL) external {
        require(initialized == false, "Already initialized.");
        require(msg.sender == deployer, "Only deployer.");
        initialized = true;
        ANIMAL = _ANIMAL;
    }

    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() external {
        uint256 unlockedShares;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            if (allocations[msg.sender][i].tokensAtTGEWithdrawn == false) {
                allocations[msg.sender][i].tokensAtTGEWithdrawn = true;
                unlockedShares += allocations[msg.sender][i].tokensAtTGE;
            } 
            if (allocations[msg.sender][i].lastWithdrawalBlock < allocations[msg.sender][i].endBlock && block.number >= allocations[msg.sender][i].unlockBlock) {
                uint256 distributionBlock;
                if (block.number > allocations[msg.sender][i].endBlock) {
                    distributionBlock = allocations[msg.sender][i].endBlock;
                } else {
                    distributionBlock = block.number;
                }
                uint256 tempLastWithdrawalBlock = allocations[msg.sender][i].lastWithdrawalBlock;
                allocations[msg.sender][i].lastWithdrawalBlock = distributionBlock;                    // Avoid reentrancy
                unlockedShares += allocations[msg.sender][i].sharePerBlock * (distributionBlock - tempLastWithdrawalBlock);
            }
        }
        require(unlockedShares > 0, "No shares unlocked.");
        ANIMAL.transfer(msg.sender, unlockedShares);
    }

    /**
     * @dev Get the remaining balance of a shareholder's total outstanding shares.
     */
    function getOutstandingShares() external view returns(uint256) {
        uint256 outstandingShare;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            outstandingShare += allocations[msg.sender][i].sharePerBlock * (allocations[msg.sender][i].endBlock - allocations[msg.sender][i].lastWithdrawalBlock);
            if (allocations[msg.sender][i].tokensAtTGEWithdrawn == false) {
                outstandingShare += allocations[msg.sender][i].tokensAtTGE;
            }
        }
        return outstandingShare;
    }

    /**
     * @dev Get the balance of a shareholder's claimable shares.
     */
    function getUnlockedShares() external view returns(uint256) {
        uint256 unlockedShares;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            if (allocations[msg.sender][i].lastWithdrawalBlock < allocations[msg.sender][i].endBlock && block.number >= allocations[msg.sender][i].unlockBlock) {
                uint256 distributionBlock;
                if (block.number > allocations[msg.sender][i].endBlock) {
                    distributionBlock = allocations[msg.sender][i].endBlock;
                } else {
                    distributionBlock = block.number;
                }
                unlockedShares += allocations[msg.sender][i].sharePerBlock * (distributionBlock - allocations[msg.sender][i].lastWithdrawalBlock);
            }
            if (allocations[msg.sender][i].tokensAtTGEWithdrawn == false) {
                unlockedShares += allocations[msg.sender][i].tokensAtTGE;
            }
        }
        return unlockedShares;
    }

    /**
     * @dev Get the withdrawn shares of a shareholder.
     */
    function getWithdrawnShares() external view returns(uint256) {
        uint256 withdrawnShare;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            withdrawnShare += allocations[msg.sender][i].sharePerBlock * (allocations[msg.sender][i].lastWithdrawalBlock - startBlock);
            if (allocations[msg.sender][i].tokensAtTGEWithdrawn == true) {
                withdrawnShare += allocations[msg.sender][i].tokensAtTGE;
            }
        }
        return withdrawnShare;
    }

    /**
     * @dev Get the total shares of shareholder.
     */
    function getTotalShares(address shareholder) external view returns(uint256) {
        uint256 totalShare;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            totalShare += allocations[shareholder][i].sharePerBlock * allocations[shareholder][i].endPeriod;
            totalShare += allocations[msg.sender][i].tokensAtTGE;
        }
        return totalShare;
    }
}