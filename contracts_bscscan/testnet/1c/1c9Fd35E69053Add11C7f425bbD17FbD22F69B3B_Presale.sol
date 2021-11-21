/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed
interface PrezaleInterface {
    function getPresaleState(address tokenAddress)
        external
        view
        returns (uint256);

    function getTokenInfo2(address tokenAddress)
        external
        view
        returns (
            uint256 decimals,
            uint256 pancakeSwapAmount,
            uint256 totalRaised,
            uint256 totalPurchases,
            uint256 referralTokenAmount,
            uint256 referralTokenPaid,
            uint256 tokensSold,
            bool reachedMinimum,
            address pancakeSwapAddress,
            uint256 lockid
        );

    function getTokenInfo(address tokenAddress)
        external
        view
        returns (
            address ownerAddress,
            bool burnTokensAfterPresale,
            uint256 totalTokensForSale,
            uint256 minCapETH,
            uint256 maxCapETH,
            uint256 minInvestmentETH,
            uint256 maxInvestmentETH,
            uint256 liquidityPercentage,
            uint256 lockedUntil,
            uint256 startDate,
            uint256 endDate,
            uint256 whitelisted
        );

    function getTokenWallet(uint256 projectID, address walletAddress)
        external
        view
        returns (
            uint256 amountTokensBought,
            uint256 amountBNBPaid,
            uint256 amountRefunded,
            uint256 amountReferred,
            uint256 amountClaimed,
            bool whitelisted,
            bool claimed,
            bool refunded
        );

    function finalizePresale(address tokenAddress)
        external
        returns (
            uint256 amountOwnerBNBFee,
            uint256 amountPancakeBNBFee,
            uint256 totalBurn,
            uint256 amountTokenBurnPresale,
            uint256 amountTokenToBurnPancakeSwap,
            uint256 amountToSendToPancakeSwap
        );

    function cancelPresale(address tokenAddress) external;

    function claimTokens(address tokenAddress) external;

    function claimRefunds(address tokenAddress) external;

    function buyTokensForBnb(address tokenAddress, address referrerAddress)
        external
        payable;

    function whitelistTogglePresale(address tokenAddress, bool whitelist)
        external;

    function whitelistAddress(address tokenAddress, address[] memory _wallets)
        external;

    function unWhitelistAddress(address tokenAddress, address[] memory _wallets)
        external;
}

contract Presale {
    address public tokenAddress;
    address public parentContract;
    address public presaleOwner;
    uint256 public presaleid;

    constructor(
        address tokenAddress_,
        uint256 presaleid_,
        address parentContract_
    ) public {
        parentContract = parentContract_;
        presaleid = presaleid_;
        tokenAddress = tokenAddress_;
        (address ownerAddress, , , , , , , , , , , ) = PrezaleInterface(
            parentContract_
        ).getTokenInfo(tokenAddress_);
        presaleOwner = ownerAddress;
    }

    function finalizePresale() public {
        PrezaleInterface(parentContract).finalizePresale(tokenAddress);
    }

    function cancelPresale() public {
        PrezaleInterface(parentContract).cancelPresale(tokenAddress);
    }

    function claimTokens() public {
        PrezaleInterface(parentContract).claimTokens(tokenAddress);
    }

    function claimRefunds() public {
        PrezaleInterface(parentContract).claimRefunds(tokenAddress);
    }

    function buyTokensForBnb(address referrerAddress) public payable {
        PrezaleInterface(parentContract).buyTokensForBnb{value: msg.value}(
            tokenAddress,
            referrerAddress
        );
    }

    function toggleWhitelist(bool toggle) public {
        PrezaleInterface(parentContract).whitelistTogglePresale(
            tokenAddress,
            toggle
        );
    }

    function whitelistAddress(address[] memory _wallets) public {
        PrezaleInterface(parentContract).whitelistAddress(
            tokenAddress,
            _wallets
        );
    }

    function unWhitelistAddress(address[] memory _wallets) public {
        PrezaleInterface(parentContract).unWhitelistAddress(
            tokenAddress,
            _wallets
        );
    }

    function presaleState() public view returns (string memory STATE) {
        uint256 state = PrezaleInterface(parentContract).getPresaleState(
            tokenAddress
        );
        // 1 - ENDED (FINISHED SUCCESSFULLY, BUT NOT YET FINALIZED)
        // 2 - CANCELLED = USER CAN NOW CLAIM REFUNDS!
        // 3 - FINALIZED = USER CAN NOW CLAIM TOKENS!
        // 4 - WHITELISTED = ONLY WHITELISTED PEOPLE CAN BUY!
        // 5 - LIVE = EVERYONE CAN BUY!
        // 6 - NOT_YET_BUYABLE
        if (state == 1) {
            return "ENDED";
        } else if (state == 2) {
            return "CANCELlED";
        } else if (state == 3) {
            return "FINALIZED";
        } else if (state == 4) {
            return "WHITELISTED";
        } else if (state == 5) {
            return "LIVE";
        } else if (state == 6) {
            return "UPCOMING";
        }
    }

    function presaleInformationPart1()
        public
        view
        returns (
            address ownerAddress,
            bool burnTokensAfterPresale,
            uint256 totalTokensForSale,
            uint256 minCapETH,
            uint256 maxCapETH,
            uint256 minInvestmentETH,
            uint256 maxInvestmentETH,
            uint256 liquidityPercentage,
            uint256 lockedUntil,
            uint256 startDate,
            uint256 endDate,
            uint256 whitelisted
        )
    {
        (
            ,
            ,
            ,
            ,
            maxCapETH,
            minInvestmentETH,
            maxInvestmentETH,
            liquidityPercentage,
            lockedUntil,
            startDate,
            endDate,
            whitelisted
        ) = PrezaleInterface(parentContract).getTokenInfo(tokenAddress);
        (
            ownerAddress,
            burnTokensAfterPresale,
            totalTokensForSale,
            minCapETH,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = PrezaleInterface(parentContract).getTokenInfo(tokenAddress);
        return (
            ownerAddress,
            burnTokensAfterPresale,
            totalTokensForSale,
            minCapETH,
            maxCapETH,
            minInvestmentETH,
            maxInvestmentETH,
            liquidityPercentage,
            lockedUntil,
            startDate,
            endDate,
            whitelisted
        );
    }

    function getWalletDetails(address wallet)
        public
        view
        returns (
            uint256 amountTokensBought,
            uint256 amountBNBPaid,
            uint256 amountRefunded,
            uint256 amountReferred,
            uint256 amountClaimed,
            bool whitelisted,
            bool claimed,
            bool refunded
        )
    {
        (
            amountTokensBought,
            amountBNBPaid,
            amountRefunded,
            amountReferred,
            amountClaimed,
            whitelisted,
            claimed,
            refunded
        ) = PrezaleInterface(parentContract).getTokenWallet(presaleid, wallet);
        return (
            amountTokensBought,
            amountBNBPaid,
            amountRefunded,
            amountReferred,
            amountClaimed,
            whitelisted,
            claimed,
            refunded
        );
    }

    function presaleInformationPart2()
        public
        view
        returns (
            uint256 decimals,
            uint256 pancakeSwapAmount,
            uint256 totalRaised,
            uint256 totalPurchases,
            uint256 referralTokenAmount,
            uint256 referralTokenPaid,
            uint256 tokensSold,
            bool reachedMinimum,
            address pancakeSwapAddress,
            uint256 lockid
        )
    {
        PrezaleInterface presaleInfo2 = PrezaleInterface(parentContract);

        //   PrezaleInterface = PrezaleInterface(parentContract).getTokenInfo2(tokenAddress);
        (
            ,
            ,
            ,
            totalPurchases,
            referralTokenAmount,
            referralTokenPaid,
            tokensSold,
            reachedMinimum,
            pancakeSwapAddress,
            lockid
        ) = presaleInfo2.getTokenInfo2(tokenAddress);

        (decimals, pancakeSwapAmount, totalRaised, , , , , , , ) = presaleInfo2
            .getTokenInfo2(tokenAddress);
        return (
            decimals,
            pancakeSwapAmount,
            totalRaised,
            totalPurchases,
            referralTokenAmount,
            referralTokenPaid,
            tokensSold,
            reachedMinimum,
            pancakeSwapAddress,
            lockid
        );
    }
}