pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../DErc20.sol";
import "../DToken.sol";
import "../PriceOracle.sol";
import "../EIP20Interface.sol";
import "../GovernorAlpha.sol";
import "../Dank.sol";

interface DanktrollerLensInterface {
    function markets(address) external view returns (bool, uint);
    function oracle() external view returns (PriceOracle);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (DToken[] memory);
    function claimDank(address) external;
    function dankAccrued(address) external view returns (uint);
    function dankSpeeds(address) external view returns (uint);
    function borrowCaps(address) external view returns (uint);
}

interface GovernorBravoInterface {
    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint96 votes;
    }
    struct Proposal {
        uint id;
        address proposer;
        uint eta;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        uint abstainVotes;
        bool canceled;
        bool executed;
    }
    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas);
    function proposals(uint proposalId) external view returns (Proposal memory);
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory);
}

contract DankLens {
    struct DTokenMetadata {
        address dToken;
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
        uint dTokenDecimals;
        uint underlyingDecimals;
        uint dankSpeed;
        uint borrowCap;
    }

    function dTokenMetadata(DToken dToken) public returns (DTokenMetadata memory) {
        uint exchangeRateCurrent = dToken.exchangeRateCurrent();
        DanktrollerLensInterface danktroller = DanktrollerLensInterface(address(dToken.danktroller()));
        (bool isListed, uint collateralFactorMantissa) = danktroller.markets(address(dToken));
        address underlyingAssetAddress;
        uint underlyingDecimals;

        if (dankareStrings(dToken.symbol(), "dETH")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            DErc20 dErc20 = DErc20(address(dToken));
            underlyingAssetAddress = dErc20.underlying();
            underlyingDecimals = EIP20Interface(dErc20.underlying()).decimals();
        }

        uint dankSpeed = 0;
        (bool dankSpeedSuccess, bytes memory dankSpeedReturnData) =
        address(danktroller).call(
            abi.encodePacked(
                danktroller.dankSpeeds.selector,
                abi.encode(address(dToken))
            )
        );
        if (dankSpeedSuccess) {
            dankSpeed = abi.decode(dankSpeedReturnData, (uint));
        }

        uint borrowCap = 0;
        (bool borrowCapSuccess, bytes memory borrowCapReturnData) =
        address(danktroller).call(
            abi.encodePacked(
                danktroller.borrowCaps.selector,
                abi.encode(address(dToken))
            )
        );
        if (borrowCapSuccess) {
            borrowCap = abi.decode(borrowCapReturnData, (uint));
        }

        return DTokenMetadata({
            dToken: address(dToken),
            exchangeRateCurrent: exchangeRateCurrent,
            supplyRatePerBlock: dToken.supplyRatePerBlock(),
            borrowRatePerBlock: dToken.borrowRatePerBlock(),
            reserveFactorMantissa: dToken.reserveFactorMantissa(),
            totalBorrows: dToken.totalBorrows(),
            totalReserves: dToken.totalReserves(),
            totalSupply: dToken.totalSupply(),
            totalCash: dToken.getCash(),
            isListed: isListed,
            collateralFactorMantissa: collateralFactorMantissa,
            underlyingAssetAddress: underlyingAssetAddress,
            dTokenDecimals: dToken.decimals(),
            underlyingDecimals: underlyingDecimals,
            dankSpeed: dankSpeed,
            borrowCap: borrowCap
            });
    }

    function dTokenMetadataAll(DToken[] calldata dTokens) external returns (DTokenMetadata[] memory) {
        uint dTokenCount = dTokens.length;
        DTokenMetadata[] memory res = new DTokenMetadata[](dTokenCount);
        for (uint i = 0; i < dTokenCount; i++) {
            res[i] = dTokenMetadata(dTokens[i]);
        }
        return res;
    }

    struct DTokenBalances {
        address dToken;
        uint balanceOf;
        uint borrowBalanceCurrent;
        uint balanceOfUnderlying;
        uint tokenBalance;
        uint tokenAllowance;
    }

    function dTokenBalances(DToken dToken, address payable account) public returns (DTokenBalances memory) {
        uint balanceOf = dToken.balanceOf(account);
        uint borrowBalanceCurrent = dToken.borrowBalanceCurrent(account);
        uint balanceOfUnderlying = dToken.balanceOfUnderlying(account);
        uint tokenBalance;
        uint tokenAllowance;

        if (dankareStrings(dToken.symbol(), "dETH")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            DErc20 dErc20 = DErc20(address(dToken));
            EIP20Interface underlying = EIP20Interface(dErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(dToken));
        }

        return DTokenBalances({
            dToken: address(dToken),
            balanceOf: balanceOf,
            borrowBalanceCurrent: borrowBalanceCurrent,
            balanceOfUnderlying: balanceOfUnderlying,
            tokenBalance: tokenBalance,
            tokenAllowance: tokenAllowance
            });
    }

    function dTokenBalancesAll(DToken[] calldata dTokens, address payable account) external returns (DTokenBalances[] memory) {
        uint dTokenCount = dTokens.length;
        DTokenBalances[] memory res = new DTokenBalances[](dTokenCount);
        for (uint i = 0; i < dTokenCount; i++) {
            res[i] = dTokenBalances(dTokens[i], account);
        }
        return res;
    }

    struct DTokenUnderlyingPrice {
        address dToken;
        uint underlyingPrice;
    }

    function dTokenUnderlyingPrice(DToken dToken) public returns (DTokenUnderlyingPrice memory) {
        DanktrollerLensInterface danktroller = DanktrollerLensInterface(address(dToken.danktroller()));
        PriceOracle priceOracle = danktroller.oracle();

        return DTokenUnderlyingPrice({
            dToken: address(dToken),
            underlyingPrice: priceOracle.getUnderlyingPrice(dToken)
            });
    }

    function dTokenUnderlyingPriceAll(DToken[] calldata dTokens) external returns (DTokenUnderlyingPrice[] memory) {
        uint dTokenCount = dTokens.length;
        DTokenUnderlyingPrice[] memory res = new DTokenUnderlyingPrice[](dTokenCount);
        for (uint i = 0; i < dTokenCount; i++) {
            res[i] = dTokenUnderlyingPrice(dTokens[i]);
        }
        return res;
    }

    struct AccountLimits {
        DToken[] markets;
        uint liquidity;
        uint shortfall;
    }

    function getAccountLimits(DanktrollerLensInterface danktroller, address account) public returns (AccountLimits memory) {
        (uint errorCode, uint liquidity, uint shortfall) = danktroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({
            markets: danktroller.getAssetsIn(account),
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

    struct GovBravoReceipt {
        uint proposalId;
        bool hasVoted;
        uint8 support;
        uint96 votes;
    }

    function getGovBravoReceipts(GovernorBravoInterface governor, address voter, uint[] memory proposalIds) public view returns (GovBravoReceipt[] memory) {
        uint proposalCount = proposalIds.length;
        GovBravoReceipt[] memory res = new GovBravoReceipt[](proposalCount);
        for (uint i = 0; i < proposalCount; i++) {
            GovernorBravoInterface.Receipt memory receipt = governor.getReceipt(proposalIds[i], voter);
            res[i] = GovBravoReceipt({
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

    struct GovBravoProposal {
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
        uint abstainVotes;
        bool canceled;
        bool executed;
    }

    function setBravoProposal(GovBravoProposal memory res, GovernorBravoInterface governor, uint proposalId) internal view {
        GovernorBravoInterface.Proposal memory p = governor.proposals(proposalId);

        res.proposalId = proposalId;
        res.proposer = p.proposer;
        res.eta = p.eta;
        res.startBlock = p.startBlock;
        res.endBlock = p.endBlock;
        res.forVotes = p.forVotes;
        res.againstVotes = p.againstVotes;
        res.abstainVotes = p.abstainVotes;
        res.canceled = p.canceled;
        res.executed = p.executed;
    }

    function getGovBravoProposals(GovernorBravoInterface governor, uint[] calldata proposalIds) external view returns (GovBravoProposal[] memory) {
        GovBravoProposal[] memory res = new GovBravoProposal[](proposalIds.length);
        for (uint i = 0; i < proposalIds.length; i++) {
            (
            address[] memory targets,
            uint[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
            ) = governor.getActions(proposalIds[i]);
            res[i] = GovBravoProposal({
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
                abstainVotes: 0,
                canceled: false,
                executed: false
                });
            setBravoProposal(res[i], governor, proposalIds[i]);
        }
        return res;
    }

    struct DankBalanceMetadata {
        uint balance;
        uint votes;
        address delegate;
    }

    function getDankBalanceMetadata(Dank dank, address account) external view returns (DankBalanceMetadata memory) {
        return DankBalanceMetadata({
            balance: dank.balanceOf(account),
            votes: uint256(dank.getCurrentVotes(account)),
            delegate: dank.delegates(account)
            });
    }

    struct DankBalanceMetadataExt {
        uint balance;
        uint votes;
        address delegate;
        uint allocated;
    }

    function getDankBalanceMetadataExt(Dank dank, DanktrollerLensInterface danktroller, address account) external returns (DankBalanceMetadataExt memory) {
        uint balance = dank.balanceOf(account);
        danktroller.claimDank(account);
        uint newBalance = dank.balanceOf(account);
        uint accrued = danktroller.dankAccrued(account);
        uint total = add(accrued, newBalance, "sum dank total");
        uint allocated = sub(total, balance, "sub allocated");

        return DankBalanceMetadataExt({
            balance: balance,
            votes: uint256(dank.getCurrentVotes(account)),
            delegate: dank.delegates(account),
            allocated: allocated
            });
    }

    struct DankVotes {
        uint blockNumber;
        uint votes;
    }

    function getDankVotes(Dank dank, address account, uint32[] calldata blockNumbers) external view returns (DankVotes[] memory) {
        DankVotes[] memory res = new DankVotes[](blockNumbers.length);
        for (uint i = 0; i < blockNumbers.length; i++) {
            res[i] = DankVotes({
                blockNumber: uint256(blockNumbers[i]),
                votes: uint256(dank.getPriorVotes(account, blockNumbers[i]))
                });
        }
        return res;
    }

    function dankareStrings(string memory a, string memory b) internal pure returns (bool) {
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