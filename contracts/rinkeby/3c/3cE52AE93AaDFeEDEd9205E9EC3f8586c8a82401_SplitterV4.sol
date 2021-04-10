/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// File contracts/SplitterV4.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

/**
 * @title SplitterV4
 * @author MirrorXYZ
 */
contract SplitterV4 {
    uint256 public constant PERCENTAGE_SCALE = 100;

    // Inherited Storage.
    bytes32 public merkleRoot;
    uint256 public currentWindow;
    address private wethAddress;
    address private _splitter;
    uint256[] private balanceForWindow;
    mapping(bytes32 => bool) private claimed;

    // The TransferETH event is emitted after each eth transfer in the split is attempted.
    event TransferETH(
        // The account to which the transfer was attempted.
        address account,
        // The amount for transfer that was attempted.
        uint256 amount,
        // The percent of the total balance that this amount represented.
        uint32 percent,
        // Whether or not the transfer succeeded.
        bool success
    );

    // The TransferToken event is emitted after each ERC20 transfer in the split is attempted.
    event TransferToken(
        // The address of the ERC20 token to which the transfer was attempted.
        address token,
        // The account to which the transfer was attempted.
        address account,
        // The amount for transfer that was attempted.
        uint256 amount,
        // The percent of the total balance that this amount represented.
        uint32 percent,
        // Whether or not the transfer succeeded.
        bool success
    );

    function incrementWindow() public {
        if (currentWindow == 0) {
            balanceForWindow.push(address(this).balance);
        } else {
            balanceForWindow.push(
                // Current Balance, subtract previous balance to get the
                // funds that were added for this window.
                address(this).balance - balanceForWindow[currentWindow - 1]
            );
        }

        currentWindow += 1;
    }

    function isClaimed(uint256 window, address account)
        public
        view
        returns (bool)
    {
        return claimed[getClaimHash(window, account)];
    }

    function _setClaimed(uint256 window, address account) private {
        claimed[getClaimHash(window, account)] = true;
    }

    function getClaimHash(uint256 window, address account)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(window, account));
    }

    function claimForAllWindows(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        // Make sure that the user has this allocation granted.
        bytes32 node =
            keccak256(abi.encodePacked(account, percentageAllocation));
        require(verifyProof(merkleProof, merkleRoot, node), "Invalid proof");

        uint256 amount = 0;
        for (uint256 i = 0; i < currentWindow; i++) {
            if (!isClaimed(i, account)) {
                amount += scaleAmountByPercentage(
                    balanceForWindow[i],
                    percentageAllocation
                );
            }
        }

        require(transferETHOrWETH(account, amount), "Transfer failed");
    }

    function scaleAmountByPercentage(uint256 amount, uint256 scaledPercent)
        public
        pure
        returns (uint256 scaledAmount)
    {
        /*
            Example:
                If there is 100 ETH in the account, and someone has 
                an allocation of 2%, we call this with 100 as the amount, and 200
                as the scaled percent.

                To find out the amount we use, for example: (100 * 200) / (100 * 100)
                which returns 2 -- i.e. 2% of the 100 ETH balance.
         */
        scaledAmount = (amount * scaledPercent) / (100 * PERCENTAGE_SCALE);
    }

    function claim(
        uint256 window,
        address account,
        uint256 scaledPercentageAllocation,
        bytes32[] calldata merkleProof
    ) external {
        require(currentWindow > window, "cannot claim for a future window");
        require(
            !isClaimed(window, account),
            "Account already claimed the given window"
        );

        _setClaimed(window, account);

        bytes32 node =
            keccak256(abi.encodePacked(account, scaledPercentageAllocation));
        require(verifyProof(merkleProof, merkleRoot, node), "Invalid proof");

        uint256 amount =
            scaleAmountByPercentage(
                balanceForWindow[window],
                scaledPercentageAllocation
            );

        require(transferETHOrWETH(account, amount), "Transfer failed");
    }

    function amountFromPercent(uint256 amount, uint32 percent)
        public
        pure
        returns (uint256)
    {
        // Solidity 0.8.0 lets us do this without SafeMath.
        return (amount * percent) / 100;
    }

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function transferETHOrWETH(address to, uint256 value)
        private
        returns (bool didSucceed)
    {
        // Try to transfer ETH to the given recipient.
        didSucceed = attemptETHTransfer(to, value);
        if (!didSucceed) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(wethAddress).deposit{value: value}();
            IWETH(wethAddress).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
        }
    }

    function attemptETHTransfer(address to, uint256 value)
        private
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }

    function attemptTokenTransfer(
        address token,
        address to,
        uint256 value
    ) private returns (bool) {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(IERC20.transfer.selector, to, value)
            );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    function verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}