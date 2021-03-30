pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../SErc20.sol";
import "../SToken.sol";
import "../PriceOracle.sol";
import "../EIP20Interface.sol";
import "../GovernorAlpha.sol";
import "../STRK.sol";

interface ComptrollerLensInterface {
    function markets(address) external view returns (bool, uint);
    function oracle() external view returns (PriceOracle);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (SToken[] memory);
    function claimStrike(address) external;
    function strikeAccrued(address) external view returns (uint);
}

contract StrikeLens {
    struct STokenMetadata {
        address sToken;
        uint exchangeRateCurrent;
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint reserveFactorMantissa;
        uint totalBorrows;
        uint totalReserves;
        uint totalSupply;
        uint totalCash;
        bool isListed;
        uint collateralFactorMantissa;
        address underlyingAssetAddress;
        uint sTokenDecimals;
        uint underlyingDecimals;
    }

    function sTokenMetadata(SToken sToken) public returns (STokenMetadata memory) {
        uint exchangeRateCurrent = sToken.exchangeRateCurrent();
        ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(sToken.comptroller()));
        (bool isListed, uint collateralFactorMantissa) = comptroller.markets(address(sToken));
        address underlyingAssetAddress;
        uint underlyingDecimals;

        if (compareStrings(sToken.symbol(), "sETH")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            SErc20 sErc20 = SErc20(address(sToken));
            underlyingAssetAddress = sErc20.underlying();
            underlyingDecimals = EIP20Interface(sErc20.underlying()).decimals();
        }

        return STokenMetadata({
            sToken: address(sToken),
            exchangeRateCurrent: exchangeRateCurrent,
            supplyRatePerBlock: sToken.supplyRatePerBlock(),
            borrowRatePerBlock: sToken.borrowRatePerBlock(),
            reserveFactorMantissa: sToken.reserveFactorMantissa(),
            totalBorrows: sToken.totalBorrows(),
            totalReserves: sToken.totalReserves(),
            totalSupply: sToken.totalSupply(),
            totalCash: sToken.getCash(),
            isListed: isListed,
            collateralFactorMantissa: collateralFactorMantissa,
            underlyingAssetAddress: underlyingAssetAddress,
            sTokenDecimals: sToken.decimals(),
            underlyingDecimals: underlyingDecimals
        });
    }

    function sTokenMetadataAll(SToken[] calldata sTokens) external returns (STokenMetadata[] memory) {
        uint sTokenCount = sTokens.length;
        STokenMetadata[] memory res = new STokenMetadata[](sTokenCount);
        for (uint i = 0; i < sTokenCount; i++) {
            res[i] = sTokenMetadata(sTokens[i]);
        }
        return res;
    }

    struct STokenBalances {
        address sToken;
        uint balanceOf;
        uint borrowBalanceCurrent;
        uint balanceOfUnderlying;
        uint tokenBalance;
        uint tokenAllowance;
    }

    function sTokenBalances(SToken sToken, address payable account) public returns (STokenBalances memory) {
        uint balanceOf = sToken.balanceOf(account);
        uint borrowBalanceCurrent = sToken.borrowBalanceCurrent(account);
        uint balanceOfUnderlying = sToken.balanceOfUnderlying(account);
        uint tokenBalance;
        uint tokenAllowance;

        if (compareStrings(sToken.symbol(), "sETH")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            SErc20 sErc20 = SErc20(address(sToken));
            EIP20Interface underlying = EIP20Interface(sErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(sToken));
        }

        return STokenBalances({
            sToken: address(sToken),
            balanceOf: balanceOf,
            borrowBalanceCurrent: borrowBalanceCurrent,
            balanceOfUnderlying: balanceOfUnderlying,
            tokenBalance: tokenBalance,
            tokenAllowance: tokenAllowance
        });
    }

    function sTokenBalancesAll(SToken[] calldata sTokens, address payable account) external returns (STokenBalances[] memory) {
        uint sTokenCount = sTokens.length;
        STokenBalances[] memory res = new STokenBalances[](sTokenCount);
        for (uint i = 0; i < sTokenCount; i++) {
            res[i] = sTokenBalances(sTokens[i], account);
        }
        return res;
    }

    struct STokenUnderlyingPrice {
        address sToken;
        uint underlyingPrice;
    }

    function sTokenUnderlyingPrice(SToken sToken) public returns (STokenUnderlyingPrice memory) {
        ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(sToken.comptroller()));
        PriceOracle priceOracle = comptroller.oracle();

        return STokenUnderlyingPrice({
            sToken: address(sToken),
            underlyingPrice: priceOracle.getUnderlyingPrice(sToken)
        });
    }

    function sTokenUnderlyingPriceAll(SToken[] calldata sTokens) external returns (STokenUnderlyingPrice[] memory) {
        uint sTokenCount = sTokens.length;
        STokenUnderlyingPrice[] memory res = new STokenUnderlyingPrice[](sTokenCount);
        for (uint i = 0; i < sTokenCount; i++) {
            res[i] = sTokenUnderlyingPrice(sTokens[i]);
        }
        return res;
    }

    struct AccountLimits {
        SToken[] markets;
        uint liquidity;
        uint shortfall;
    }

    function getAccountLimits(ComptrollerLensInterface comptroller, address account) public returns (AccountLimits memory) {
        (uint errorCode, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({
            markets: comptroller.getAssetsIn(account),
            liquidity: liquidity,
            shortfall: shortfall
        });
    }

    struct GovReceipt {
        uint proposalId;
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    function getGovReceipts(GovernorAlpha governor, address voter, uint[] memory proposalIds) public view returns (GovReceipt[] memory) {
        uint proposalCount = proposalIds.length;
        GovReceipt[] memory res = new GovReceipt[](proposalCount);
        for (uint i = 0; i < proposalCount; i++) {
            GovernorAlpha.Receipt memory receipt = governor.getReceipt(proposalIds[i], voter);
            res[i] = GovReceipt({
                proposalId: proposalIds[i],
                hasVoted: receipt.hasVoted,
                support: receipt.support,
                votes: receipt.votes
            });
        }
        return res;
    }

    struct GovProposal {
        uint proposalId;
        address proposer;
        uint eta;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
    }

    function setProposal(GovProposal memory res, GovernorAlpha governor, uint proposalId) internal view {
        (
            ,
            address proposer,
            uint eta,
            uint startBlock,
            uint endBlock,
            uint forVotes,
            uint againstVotes,
            bool canceled,
            bool executed
        ) = governor.proposals(proposalId);
        res.proposalId = proposalId;
        res.proposer = proposer;
        res.eta = eta;
        res.startBlock = startBlock;
        res.endBlock = endBlock;
        res.forVotes = forVotes;
        res.againstVotes = againstVotes;
        res.canceled = canceled;
        res.executed = executed;
    }

    function getGovProposals(GovernorAlpha governor, uint[] calldata proposalIds) external view returns (GovProposal[] memory) {
        GovProposal[] memory res = new GovProposal[](proposalIds.length);
        for (uint i = 0; i < proposalIds.length; i++) {
            (
                address[] memory targets,
                uint[] memory values,
                string[] memory signatures,
                bytes[] memory calldatas
            ) = governor.getActions(proposalIds[i]);
            res[i] = GovProposal({
                proposalId: 0,
                proposer: address(0),
                eta: 0,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                startBlock: 0,
                endBlock: 0,
                forVotes: 0,
                againstVotes: 0,
                canceled: false,
                executed: false
            });
            setProposal(res[i], governor, proposalIds[i]);
        }
        return res;
    }

    struct StrikeBalanceMetadata {
        uint balance;
        uint votes;
        address delegate;
    }

    function getStrikeBalanceMetadata(STRK strk, address account) external view returns (StrikeBalanceMetadata memory) {
        return StrikeBalanceMetadata({
            balance: strk.balanceOf(account),
            votes: uint256(strk.getCurrentVotes(account)),
            delegate: strk.delegates(account)
        });
    }

    struct StrikeBalanceMetadataExt {
        uint balance;
        uint votes;
        address delegate;
        uint allocated;
    }

    function getStrikeBalanceMetadataExt(STRK strk, ComptrollerLensInterface comptroller, address account) external returns (StrikeBalanceMetadataExt memory) {
        uint balance = strk.balanceOf(account);
        comptroller.claimStrike(account);
        uint newBalance = strk.balanceOf(account);
        uint accrued = comptroller.strikeAccrued(account);
        uint total = add(accrued, newBalance, "sum strk total");
        uint allocated = sub(total, balance, "sub allocated");

        return StrikeBalanceMetadataExt({
            balance: balance,
            votes: uint256(strk.getCurrentVotes(account)),
            delegate: strk.delegates(account),
            allocated: allocated
        });
    }

    struct StrikeVotes {
        uint blockNumber;
        uint votes;
    }

    function getStrikeVotes(STRK strk, address account, uint32[] calldata blockNumbers) external view returns (StrikeVotes[] memory) {
        StrikeVotes[] memory res = new StrikeVotes[](blockNumbers.length);
        for (uint i = 0; i < blockNumbers.length; i++) {
            res[i] = StrikeVotes({
                blockNumber: uint256(blockNumbers[i]),
                votes: uint256(strk.getPriorVotes(account, blockNumbers[i]))
            });
        }
        return res;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }
}