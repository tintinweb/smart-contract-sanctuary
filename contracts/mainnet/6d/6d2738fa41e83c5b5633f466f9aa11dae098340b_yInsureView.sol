pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface Pool1  {
    function changeDependentContractAddress() external;
    function makeCoverBegin(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        payable;
    function makeCoverUsingCA(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;
    function getWei(uint amount) external view returns(uint);
    function sellNXMTokens(uint _amount) external  returns (bool);
}

contract INXMMaster {
    address public tokenAddress;
    address public owner;
    uint public pauseTime;
    function masterInitialized() external view returns(bool);
    function isPause() external view returns(bool check);
    function isMember(address _add) external view returns(bool);
    function getLatestAddress(bytes2 _contractName) external view returns(address payable contractAddress);
}

interface DSValue {
    function peek() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
}

interface PoolData {

    struct ApiId {
        bytes4 typeOf;
        bytes4 currency;
        uint id;
        uint64 dateAdd;
        uint64 dateUpd;
    }

    struct CurrencyAssets {
        address currAddress;
        uint baseMin;
        uint varMin;
    }

    struct InvestmentAssets {
        address currAddress;
        bool status;
        uint64 minHoldingPercX100;
        uint64 maxHoldingPercX100;
        uint8 decimals;
    }

    struct IARankDetails {
        bytes4 maxIACurr;
        uint64 maxRate;
        bytes4 minIACurr;
        uint64 minRate;
    }

    struct McrData {
        uint mcrPercx100;
        uint mcrEther;
        uint vFull; //Pool funds
        uint64 date;
    }

    function setCapReached(uint val) external;
    function getInvestmentAssetDecimals(bytes4 curr) external returns(uint8 decimal);
    function getCurrencyAssetAddress(bytes4 curr) external view returns(address);
    function getInvestmentAssetAddress(bytes4 curr) external view returns(address);
    function getInvestmentAssetStatus(bytes4 curr) external view returns(bool status);

}

interface QuotationData {

    enum HCIDStatus { NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover }
    enum CoverStatus { Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested }

    struct Cover {
        address payable memberAddress;
        bytes4 currencyCode;
        uint sumAssured;
        uint16 coverPeriod;
        uint validUntil;
        address scAddress;
        uint premiumNXM;
    }

    struct HoldCover {
        uint holdCoverId;
        address payable userAddress;
        address scAddress;
        bytes4 coverCurr;
        uint[] coverDetails;
        uint16 coverPeriod;
    }

    function getCoverLength() external returns(uint len);
    function getAuthQuoteEngine() external returns(address _add);
    function getAllCoversOfUser(address _add) external returns(uint[] memory allCover);
    function getUserCoverLength(address _add) external returns(uint len);
    function getCoverStatusNo(uint _cid) external returns(uint8);
    function getCoverPeriod(uint _cid) external returns(uint32 cp);
    function getCoverSumAssured(uint _cid) external returns(uint sa);
    function getCurrencyOfCover(uint _cid) external returns(bytes4 curr);
    function getValidityOfCover(uint _cid) external returns(uint date);
    function getscAddressOfCover(uint _cid) external view returns(uint, address);
    function getCoverMemberAddress(uint _cid) external returns(address payable _add);
    function getCoverPremiumNXM(uint _cid) external returns(uint _premiumNXM);
    function getCoverDetailsByCoverID1(
        uint _cid
    )
        external
        returns (
            uint cid,
            address _memberAddress,
            address _scAddress,
            bytes4 _currencyCode,
            uint _sumAssured,
            uint premiumNXM
        );
    function getCoverDetailsByCoverID2(
        uint _cid
    )
        external
        view
        returns (
            uint cid,
            uint8 status,
            uint sumAssured,
            uint16 coverPeriod,
            uint validUntil
        );
    function getHoldedCoverDetailsByID1(
        uint _hcid
    )
        external
        view
        returns (
            uint hcid,
            address scAddress,
            bytes4 coverCurr,
            uint16 coverPeriod
        );
    function getUserHoldedCoverLength(address _add) external returns (uint);
    function getUserHoldedCoverByIndex(address _add, uint index) external returns (uint);
    function getHoldedCoverDetailsByID2(
        uint _hcid
    )
        external
        returns (
            uint hcid,
            address payable memberAddress,
            uint[] memory coverDetails
        );
    function getTotalSumAssuredSC(address _add, bytes4 _curr) external returns(uint amount);

}

contract TokenData {
    function lockTokenTimeAfterCoverExp() external returns (uint);
}

interface Claims {
    function getClaimbyIndex(uint _claimId) external view returns (
        uint claimId,
        uint status,
        int8 finalVerdict,
        address claimOwner,
        uint coverId
    );
    function submitClaim(uint coverId) external;
}

contract ClaimsData {
    function actualClaimLength() external view returns(uint);
}

interface NXMToken {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

}

interface MemberRoles {
    function switchMembership(address) external;
}

interface yInsure {
    
    function tokens(uint) external view returns (uint expirationTimestamp,
        bytes4 coverCurrency,
        uint coverAmount,
        uint coverPrice,
        uint coverPriceNXM,
        uint expireTime,
        uint generationTime,
        uint coverId,
        bool claimInProgress,
        uint claimId);
}

contract yInsureView  {
    
    event ClaimRedeemed (
        address receiver,
        uint value,
        bytes4 currency
    );
    
    using SafeMath for uint;

    INXMMaster constant public nxMaster = INXMMaster(0x01BFd82675DBCc7762C84019cA518e701C0cD07e);
    yInsure constant public yIns = yInsure(0x181Aea6936B407514ebFC0754A37704eB8d98F91);
    
    enum CoverStatus {
        Active,
        ClaimAccepted,
        ClaimDenied,
        CoverExpired,
        ClaimSubmitted,
        Requested
    }
    
    enum ClaimStatus {
        PendingClaimAssessorVote, // 0
        PendingClaimAssessorVoteDenied, // 1
        PendingClaimAssessorVoteThresholdNotReachedAccept, // 2
        PendingClaimAssessorVoteThresholdNotReachedDeny, // 3
        PendingClaimAssessorConsensusNotReachedAccept, // 4
        PendingClaimAssessorConsensusNotReachedDeny, // 5
        FinalClaimAssessorVoteDenied, // 6
        FinalClaimAssessorVoteAccepted, // 7
        FinalClaimAssessorVoteDeniedMVAccepted, // 8
        FinalClaimAssessorVoteDeniedMVDenied, // 9
        FinalClaimAssessorVotAcceptedMVNoDecision, // 10
        FinalClaimAssessorVoteDeniedMVNoDecision, // 11
        ClaimAcceptedPayoutPending, // 12
        ClaimAcceptedNoPayout, // 13
        ClaimAcceptedPayoutDone // 14
    }
    
    function getMemberRoles() external view returns (address) {
        return nxMaster.getLatestAddress("MR");
    }
    
    function getCover(
        uint coverId
    ) public view returns (
        uint cid,
        uint8 status,
        uint sumAssured,
        uint16 coverPeriod,
        uint validUntil
    ) {
        QuotationData quotationData = QuotationData(nxMaster.getLatestAddress("QD"));
        return quotationData.getCoverDetailsByCoverID2(coverId);
    }
    
    function getscAddressOfCover(
        uint _coverId
    ) public view returns (
        uint coverId,
        address coverAddress
    ) {
        QuotationData quotationData = QuotationData(nxMaster.getLatestAddress("QD"));
        return quotationData.getscAddressOfCover(_coverId);
    }
    
    function getCurrencyAssetAddress(bytes4 currency) external view returns (address) {
        PoolData pd = PoolData(nxMaster.getLatestAddress("PD"));
        return pd.getCurrencyAssetAddress(currency);
    }
    
    function getLockTokenTimeAfterCoverExpiry() external returns (uint) {
        TokenData tokenData = TokenData(nxMaster.getLatestAddress("TD"));
        return tokenData.lockTokenTimeAfterCoverExp();
    }
    
    function getTokenAddress() external view returns (address) {
        return nxMaster.tokenAddress();
    }
    
    function payoutIsCompleted(uint claimId) public view returns (bool) {
        uint256 status;
        Claims claims = Claims(nxMaster.getLatestAddress("CL"));
        (, status, , , ) = claims.getClaimbyIndex(claimId);
        return status == uint(ClaimStatus.FinalClaimAssessorVoteAccepted)
            || status == uint(ClaimStatus.ClaimAcceptedPayoutDone);
    }
    
    uint public distributorFeePercentage;
    uint256 internal issuedTokensCount;
    
    struct Token {
        address coverContract;
        uint expirationTimestamp;
        bytes4 coverCurrency;
        uint coverAmount;
        uint expireTime;
        uint generationTime;
        uint coverId;
        bool claimInProgress;
        uint claimId;
        uint8 coverStatus;
        bool payoutCompleted;
    }
    
    function getToken(uint tokenId) public view returns (Token memory) {
        Token memory tkn;
        (
            tkn.expirationTimestamp, 
            tkn.coverCurrency, 
            tkn.coverAmount, 
            , 
            , 
            tkn.expireTime, 
            tkn.generationTime, 
            tkn.coverId, 
            tkn.claimInProgress, 
            tkn.claimId) = yIns.tokens(tokenId);
    }
    
    function tokens(uint tokenId) public view returns (Token memory) {
        Token memory tkn = getToken(tokenId);
        (, tkn.coverContract) = getscAddressOfCover(tkn.coverId);
        (, tkn.coverStatus, , , ) = getCover(tkn.coverId);
        tkn.payoutCompleted = payoutIsCompleted(tkn.claimId);
    }
}