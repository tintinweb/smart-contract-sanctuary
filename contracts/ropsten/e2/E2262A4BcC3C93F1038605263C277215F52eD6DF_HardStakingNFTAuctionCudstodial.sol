/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity =0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ICollectionToken is IERC721Metadata {
    struct Collection {
        uint collectionId;
        string name;
        uint maxCollectionSize;
        bool isDigitalObject;
        uint[] tokens;
    }

    function tokenToCollection(uint tokenId) external view returns (uint);
    function collection(uint collectionId) external view returns (Collection memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20Permit is IERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

interface IAggregatorInterface {
  function latestAnswer() external view returns (int256);
  function decimals() external view returns (uint8);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract HardStakingNFTAuctionCudstodial is ReentrancyGuard, Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    struct Auction {
        uint tokenId;
        uint auctionEnd;
        uint topActualBid;
        uint topConvertedBid;
        uint allBids;
        address topBidder;
        bool isWithdrawn;
        address owner;
        string description;
        bool canceled;
        bool isCustodial;
        bool isDigitalObject;
    }

    struct TokenAuctionParams {
        uint auctionRoundDuration;
        uint successAuctionFeePercentage;
    }

    struct Stake {
        uint lockTime;
        uint actualStakeAmount;
        uint convertedStakeAmount;
        bool isWithdrawn;
        bool isCustodian;
    }

    ICollectionToken public immutable auctionToken;
    address public custodian;
    address public custodianAdmin;
    uint public constant MIN_AUCTION_DURATION = 1 minutes;
    uint public minAuctionStartPrice;
    uint public nextBidStepPercentage;

    uint public defaultAuctionDuration;
    uint public lastAuctionId;
    mapping(uint => Auction) public auctions;
    mapping(uint => TokenAuctionParams) public tokenAuctionParams;
    mapping(uint => uint) public tokenLastAuctionId;
    mapping(uint => bool) public approvedAuctionsForCustodian;

    IAggregatorInterface public priceFeed;
    uint public constant PRICE_FEED_DECIMALS = 8;
    mapping(address => mapping(uint => Stake)) public userStakes;
    mapping(address => uint[]) internal _userAuctions;
    mapping(address => uint[]) internal _userCustodianStakes;

    uint internal _totalSupply;
    mapping(address => uint) internal _balances;

    event Staked(address indexed user, uint stakeAmount, uint convertedAmount, uint indexed auctionId, uint indexed tokenId);
    event NewAuction(uint indexed auctionId, uint indexed tokenId, uint indexed collectionId, bool isCustodial, bool isDigitalObject);
    event AuctionInited(uint indexed auctionId, uint auctionEnd, uint indexed tokenId);
    event NewTopBid(uint indexed auctionId, uint indexed tokenId, uint actualBidAmount, uint convertedBidAmount, address indexed bidder);
    event Withdraw(address indexed user, uint amount);
    event AuctionTokenWithdraw(address indexed winner, address previousOwner, uint bidAmount, uint fee, uint indexed tokenId, uint indexed auctionId);
    event RescueAuctionToken(address indexed to, uint indexed auctionId, uint indexed tokenId, bool wasAuctionFinished);
    event ApproveAuctionForCustodian(uint indexed auctionId, bool indexed isApproved);
    event UpdateCustodianAdmin(address indexed oldCustodianAdmin, address indexed newCustodianAdmin);
    event UpdateTokenAuctionParams(uint indexed tokenId, uint indexed auctionRoundDuration, uint indexed successAuctionFeePercentage);
    event UpdatePriceFeed(address indexed priceFeed);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed to, address token, uint amount);

    constructor(
        address _auctionToken,
        address _custodian,
        address _custodianAdmin,
        address _priceFeed
    ) {
        require(Address.isContract(_auctionToken), "HardStakingNFTAuctionCudstodial: Not contract(s)");
        require(_custodian != address(0) && _custodianAdmin != address(0), "HardStakingNFTAuctionCudstodial: Zero custodian address");
        auctionToken = ICollectionToken(_auctionToken);
        custodian = _custodian;
        custodianAdmin = _custodianAdmin;
        nextBidStepPercentage = 1050e16; //5% or 1.05
        priceFeed = IAggregatorInterface(_priceFeed);
        require(priceFeed.decimals() == PRICE_FEED_DECIMALS, "HardStakingNFTAuctionCudstodial: Price feed decimals disagreement"); // using ETH / USD price feed with 8 decimals
        defaultAuctionDuration = 30 days;
    }

    modifier onlyCustodianAdmin {
        require(msg.sender == custodianAdmin, "HardStakingNFTAuctionCudstodial: Caller is not the custodian admin");
        _;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        //equal to return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return 0x150b7a02;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function userAuctions(address user) external view returns (uint[] memory auctionIds) {
        return _userAuctions[user];
    }

    function userCustodianStakes(address user) external view returns (uint[] memory auctionIds) {
        return _userCustodianStakes[user];
    }

    function userCustodianStakeCounts(address user) external view returns (uint) {
        return _userCustodianStakes[user].length;
    }

    function userUnwithdrawnAuctions(address user) external view returns (uint[] memory auctionIds) {
        uint unwithdrawnStakesCnt;
        for (uint i; i < _userAuctions[user].length; i++) {
            uint auctionId = _userAuctions[user][i];
            if (!isAuctionActive(auctionId) 
                && userStakes[user][auctionId].actualStakeAmount > 0 
                && auctions[auctionId].topBidder != user)
                unwithdrawnStakesCnt++;
        }
        auctionIds = new uint[](unwithdrawnStakesCnt);
        unwithdrawnStakesCnt = 0;
        for (uint i; i < _userAuctions[user].length; i++) {
            uint auctionId = _userAuctions[user][i];
            if (!isAuctionActive(auctionId) 
                && userStakes[user][auctionId].actualStakeAmount > 0 
                && auctions[auctionId].topBidder != user) {
                auctionIds[unwithdrawnStakesCnt] = _userAuctions[user][i];
                unwithdrawnStakesCnt++;
            }
        }
    }

    function availableForWithdraw(address user, uint auctionId) public view returns (uint actualStake) {
        if (!isAuctionActive(auctionId) && auctions[auctionId].topBidder != user) {
            actualStake = userStakes[user][auctionId].actualStakeAmount;
        }
    }

    function getNextBidMinAmount(uint auctionId) external view returns (uint actualBid, uint convertedBid) {
        Auction storage auction = auctions[auctionId];
        if (auction.auctionEnd != 0 && auction.auctionEnd > block.timestamp) {
            convertedBid = auction.topConvertedBid * nextBidStepPercentage / 1e20;
            actualBid = getAmountUsdToEth(convertedBid);
        } else if (auction.auctionEnd <= block.timestamp) {
            actualBid = 0;
            convertedBid = 0;
        } else {
            convertedBid = auction.topConvertedBid;
            actualBid = getAmountUsdToEth(convertedBid);
        }
    }

    function isAuctionActive(uint auctionId) public view returns (bool) {
        return block.timestamp < auctions[auctionId].auctionEnd;
    }

    function getRate() public view returns (uint) {
        int rate = priceFeed.latestAnswer();
        require(rate > 0, "HardStakingNFTAuctionCudstodial: unsopported rate format");
        return uint(rate);
    }

    function getAmountEthToUsd(uint amountEth) public view returns (uint) {
        return getAmountEthToUsd(amountEth, getRate());
    }
    
    function getAmountEthToUsd(uint amountEth, uint rate) public pure returns (uint) {
        //18 digits for ETH and 8 digits for USD
        return amountEth * rate / 1e18;
    }

    function getAmountUsdToEth(uint amountUsd) public view returns (uint) {
        return getAmountUsdToEth(amountUsd, getRate());
    }
    
    function getAmountUsdToEth(uint amountUsd, uint rate) public pure returns (uint) {
        //18 digits for ETH and 8 digits for USD
        return amountUsd * 1e18 / rate;
    }

    function getLastSalePrice(uint tokenId) external view returns (uint) {
        uint auctionId = tokenLastAuctionId[tokenId];
        if (auctionId == 0) return 0;
        if (auctions[auctionId].auctionEnd > block.timestamp) {
            return auctions[auctionId].topActualBid;
        } else {
            return 0;
        }
    }




    function stake(uint auctionId) external payable virtual {
        _stake(auctionId, msg.sender);
    }

    function stakeFor(uint auctionId, address user) external payable virtual {
        _stake(auctionId, user);
    }

    function withdraw(uint auctionId) public {
        _withdraw(auctionId);
    }

    function withdrawByTokenId(uint tokenId) external {
        uint auctionId = tokenLastAuctionId[tokenId];
        withdraw(auctionId);
    }

    function withdrawForAuctions(uint[] memory auctionIds) public {
        for (uint i; i < auctionIds.length; i++) {
            withdraw(auctionIds[i]);
        }
    }

    function processSuccesfullAuction(uint auctionId) external { 
        Auction storage auction = auctions[auctionId];
        require(auction.auctionEnd < block.timestamp, "HardStakingNFTAuctionCudstodial: Auction is not finished");
        bool isCustodial = auction.isCustodial;
        if (isCustodial) {
            require(msg.sender == custodianAdmin, "HardStakingNFTAuctionCudstodial: Caller is not the custodian admin");
            require(approvedAuctionsForCustodian[auctionId], "HardStakingNFTAuctionCudstodial: Not approved auction for processing by custodian");
        }

        address winner = auction.topBidder;        
        uint tokenId = auction.tokenId;
        if (winner == address(0)) {
            auctionToken.transferFrom(address(this), owner, tokenId);
            emit RescueAuctionToken(owner, auctionId, tokenId, true);
        } else {
            auctionToken.transferFrom(address(this), winner, tokenId);
            
            uint actualStakeAmount = auction.topActualBid;

            uint bidFinalAmount;
            uint successFee;
            uint successAuctionFeePercentage = tokenAuctionParams[auctionId].successAuctionFeePercentage;
            if (successAuctionFeePercentage != 0) {
                successFee = actualStakeAmount * successAuctionFeePercentage / 1e20;
                require(actualStakeAmount > successFee, "HardStakingNFTAuctionCudstodial: successFee is greater than actualStakeAmount");
                bidFinalAmount = actualStakeAmount - successFee;
                if (!isCustodial) _safeTransferETH(owner, successFee);
            } else {
                bidFinalAmount = actualStakeAmount;
            }

            (address author, uint royaltyAmount) = IERC2981(address(auctionToken)).royaltyInfo(tokenId, bidFinalAmount);
            if (royaltyAmount > 0 && royaltyAmount < bidFinalAmount) {
                if (!isCustodial) _safeTransferETH(author, royaltyAmount);
                bidFinalAmount -= royaltyAmount;
            }

            if (!isCustodial) {
                _safeTransferETH(auction.owner, bidFinalAmount);
                
                _totalSupply -= actualStakeAmount;
                _balances[winner] -= actualStakeAmount;
                userStakes[winner][auctionId].isWithdrawn = true;
            }

            emit AuctionTokenWithdraw(winner, auction.owner, bidFinalAmount, successFee, tokenId, auctionId);
        }
        auction.isWithdrawn = true;
    }

    function startNewAuctions(uint[] memory tokenIds, uint[] memory startBidAmounts, bool[] memory isAmountInEths, uint[] memory roundDurations, bool[] memory isCustodials, string[] memory descriptions) external { 
        require(tokenIds.length == startBidAmounts.length, "HardStakingNFTAuctionCudstodial: Wrong lengths");
        require(tokenIds.length == isAmountInEths.length, "HardStakingNFTAuctionCudstodial: Wrong lengths");
        require(tokenIds.length == roundDurations.length, "HardStakingNFTAuctionCudstodial: Wrong lengths");
        require(tokenIds.length == isCustodials.length, "HardStakingNFTAuctionCudstodial: Wrong lengths");
        require(tokenIds.length == descriptions.length, "HardStakingNFTAuctionCudstodial: Wrong lengths");
        for (uint i; i < tokenIds.length; i++) {
            startNewAuction(tokenIds[i], startBidAmounts[i], isAmountInEths[i], descriptions[i], isCustodials[i]);
        }
    }

    function startNewAuction(uint tokenId, uint startBidAmount, bool isAmountInEth, uint roundDuration, uint successAuctionFeePercentage, string memory description, bool isCustodial) onlyOwner public {
        _updateTokenAuctionParams(tokenId, roundDuration, successAuctionFeePercentage);
        startNewAuction(tokenId, startBidAmount, isAmountInEth, description, isCustodial);
    }

    function startNewAuction(uint tokenId, uint startBidAmount, bool isAmountInEth, string memory description, bool isCustodial) public {
        //require(tokenLastAuctionId[tokenId] > 0, "HardStakingNFTAuctionCudstodial: token was not in auction yet");
        auctionToken.transferFrom(msg.sender, address(this), tokenId);
        if(startBidAmount < minAuctionStartPrice) startBidAmount = minAuctionStartPrice;

        uint auctionId = ++lastAuctionId;
        tokenLastAuctionId[tokenId] = auctionId;
        uint collectionId = auctionToken.tokenToCollection(tokenId);
        bool isDigitalObject = auctionToken.collection(collectionId).isDigitalObject; 

        auctions[auctionId].tokenId = tokenId;
        auctions[auctionId].description = description;
        auctions[auctionId].topActualBid = isAmountInEth ? 
            startBidAmount : getAmountUsdToEth(startBidAmount);
        auctions[auctionId].topConvertedBid = isAmountInEth ? 
            getAmountEthToUsd(startBidAmount) : startBidAmount;
        auctions[auctionId].owner = msg.sender;
        auctions[auctionId].isCustodial = isCustodial;
        if (isDigitalObject)
            auctions[auctionId].isDigitalObject = true; 

        emit NewAuction(auctionId, collectionId, tokenId, isCustodial, isDigitalObject);
    }

    function rescueUnbiddenTokenByTokenId(uint tokenId) external {
        uint auctionId = tokenLastAuctionId[tokenId];
        rescueUnbiddenToken(auctionId);
    }

    function rescueUnbiddenToken(uint auctionId) public { 
        Auction storage auction = auctions[auctionId];
        require(auction.auctionEnd == 0, "HardStakingNFTAuctionCudstodial: Token is already bidden");
        require(auction.owner == msg.sender, "HardStakingNFTAuctionCudstodial: Not token owner");
        auction.canceled = true;
        auctionToken.transferFrom(address(this), msg.sender, auction.tokenId);
        emit RescueAuctionToken(msg.sender, auctionId, auction.tokenId, false);
    }





    function _stake(uint auctionId, address user) internal virtual nonReentrant {
        require(auctionId <= lastAuctionId, "HardStakingNFTAuctionCudstodial: No such auction Id");
        Auction storage auction = auctions[auctionId];
        require(!auction.canceled, "HardStakingNFTAuctionCudstodial: Auction is canceled");
        if (auction.auctionEnd == 0) _initAuction(auctionId);
        else require(auction.auctionEnd > block.timestamp, "HardStakingNFTAuctionCudstodial: Round is finished");
        
        uint nextMinBidConverted;
        uint rate = getRate();
        if (auction.topBidder != address(0)) {
            nextMinBidConverted = auction.topConvertedBid * nextBidStepPercentage / 1e20;
        } else {
            nextMinBidConverted = auction.topConvertedBid;
        }

        uint amount = msg.value;
        uint amountConverted = getAmountEthToUsd(amount, rate);

        uint totalAmountConverted = amountConverted;

        uint previousStakeForCurrentAuctionConverted = userStakes[user][auctionId].convertedStakeAmount;
        if (previousStakeForCurrentAuctionConverted == 0) {
            _userAuctions[user].push(auctionId);
            userStakes[user][auctionId].lockTime = auction.auctionEnd;
            if (auction.isCustodial) userStakes[user][auctionId].isCustodian = true;
        } else {
            totalAmountConverted += previousStakeForCurrentAuctionConverted;
        }
        require(totalAmountConverted >= nextMinBidConverted, "HardStakingNFTAuctionCudstodial: Not enough amount for a bid");
        
        uint totalAmount = userStakes[user][auctionId].actualStakeAmount + amount;
        userStakes[user][auctionId].actualStakeAmount = totalAmount;
        userStakes[user][auctionId].convertedStakeAmount = totalAmountConverted;

        if(auction.isCustodial) {
            _safeTransferETH(custodian, amount);
            _userCustodianStakes[user].push(auctionId);
        } else {
            _balances[user] += amount;
            _totalSupply += amount;
        }
        
        auction.topActualBid = totalAmount;
        auction.topConvertedBid = totalAmountConverted;
        auction.topBidder = user;
        auction.allBids += amount;
        emit NewTopBid(auctionId, auction.tokenId, totalAmount, totalAmountConverted, user);  
        emit Staked(user, amount, amountConverted, auctionId, auction.tokenId);
    }

    function _withdraw(uint auctionId) internal virtual nonReentrant {
        require(!auctions[auctionId].isCustodial, "HardStakingNFTAuctionCudstodial: Custodian return stakes on custodial auctions");
        address user = msg.sender;
        require(!userStakes[user][auctionId].isWithdrawn, "HardStakingNFTAuctionCudstodial: Already withdrawn");
        require(userStakes[user][auctionId].lockTime < block.timestamp, "HardStakingNFTAuctionCudstodial: Locked");
        require(auctions[auctionId].topBidder != user, "HardStakingNFTAuctionCudstodial: Cannot withdraw on won auction, use processSuccesfullAuction");

        uint amount = userStakes[user][auctionId].actualStakeAmount;
        _safeTransferETH(user, amount);
                
        _totalSupply -= amount;
        _balances[user] -= amount;
        userStakes[user][auctionId].isWithdrawn = true;
        emit Withdraw(user, amount);
    }

    function _initAuction(uint auctionId) internal {
        uint auctionRoundDuration = tokenAuctionParams[auctions[auctionId].tokenId].auctionRoundDuration;
        if (auctionRoundDuration == 0)
            auctionRoundDuration = defaultAuctionDuration;
        uint auctionEnd = block.timestamp + auctionRoundDuration;
        auctions[auctionId].auctionEnd = auctionEnd;
        emit AuctionInited(auctionId, auctionEnd, auctions[auctionId].tokenId);
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'HardStakingNFTAuctionCudstodial: ETH transfer failed');
    }



    /* === CUSTODIAN ACTIONS === */

    function updateCustodianAdmin(address newAdmin) external onlyCustodianAdmin {
        require(newAdmin != address(0), "HardStakingNFTAuctionCudstodial: Zero address");
        emit UpdateCustodianAdmin(custodianAdmin, newAdmin);
        custodianAdmin = newAdmin;
    }


    /* === OWNER ACTIONS === */

    function approveAuctionForCustodian(uint auctionId, bool isApproved) external onlyOwner { 
        require(auctionId <= lastAuctionId, "HardStakingNFTAuctionCudstodial: No such auction Id");
        require(auctions[auctionId].isCustodial, "HardStakingNFTAuctionCudstodial: Not a custodial auction");
        approvedAuctionsForCustodian[auctionId] = isApproved;
        emit ApproveAuctionForCustodian(auctionId, isApproved);
    }

    function updateMinAuctionStartPrice(uint newMinAuctionStartPrice) external onlyOwner {
        require(newMinAuctionStartPrice > 0, "HardStakingNFTAuctionCudstodial: New min stake amount must be greater than 0");
        minAuctionStartPrice = newMinAuctionStartPrice;
    }

    function updateDefaultAuctionDuration(uint newDefaultAuctionDuration) external onlyOwner {
        require(newDefaultAuctionDuration > 1 minutes, "HardStakingNFTAuctionCudstodial: New min stake amount must be greater than 0");
        defaultAuctionDuration = newDefaultAuctionDuration;
    }
    

    function updatePriceFeed(address newPriceFeed) external onlyOwner {
        require(newPriceFeed != address(0), "HardStakingNFTAuctionCudstodial: Zero address");
        priceFeed = IAggregatorInterface(newPriceFeed);
        require(priceFeed.decimals() == PRICE_FEED_DECIMALS, "HardStakingNFTAuctionCudstodial: Price feed decimals disagreement");
        emit UpdatePriceFeed(newPriceFeed);
    }

    

    function updateTokenAuctionParams(uint tokenId, uint auctionRoundDuration, uint successAuctionFeePercentage) external onlyOwner {
        _updateTokenAuctionParams(tokenId, auctionRoundDuration, successAuctionFeePercentage);
    }

    function _updateTokenAuctionParams(uint tokenId, uint auctionRoundDuration, uint successAuctionFeePercentage) private {
        require(auctionRoundDuration >= MIN_AUCTION_DURATION, "HardStakingNFTAuctionCudstodial: Auction duration is too short");
        if (successAuctionFeePercentage > 0) { //successAuctionFeePercentage can be a zero value
            require(successAuctionFeePercentage < 1e20, "HardStakingNFTAuctionCudstodial: successAuctionFeePercentage must be lower than 1e20");
        }
        tokenAuctionParams[tokenId].auctionRoundDuration = auctionRoundDuration;
        tokenAuctionParams[tokenId].successAuctionFeePercentage = successAuctionFeePercentage;
        emit UpdateTokenAuctionParams(tokenId, auctionRoundDuration, successAuctionFeePercentage);
    }
    
    function updateNextBidStepPercentage(uint newNextBidStepPercentage) external onlyOwner {
        require(newNextBidStepPercentage >= 1e20);
        nextBidStepPercentage = newNextBidStepPercentage;
    }

    function rescue(address to, address tokenAddress, uint amount) external onlyOwner {
        require(to != address(0), "HardStakingNFTAuctionCudstodial: Cannot rescue to the zero address");
        require(amount > 0, "HardStakingNFTAuctionCudstodial: Cannot rescue 0");
        
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    function updateCustodian(address newCustodian) external onlyOwner {
        require(newCustodian != address(0), "HardStakingNFTAuction: Address is zero");
        custodian = newCustodian;
    }

    function rescue(address payable to, uint amount) external onlyOwner {
        require(to != address(0), "HardStakingNFTAuctionCudstodial: Cannot rescue to the zero address");
        require(amount > 0, "HardStakingNFTAuctionCudstodial: Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
}