/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity =0.8.3;

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

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IAuctionReferralProgram {
    function processStake(address user, uint amount, bool isRewardToken) external;
}

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20Permit is IERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IBurnable is IERC20Permit {
    function burnTokens(uint amount) external returns (bool success);
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

contract HardStakingNFTAuction is ReentrancyGuard, Ownable, IERC721Receiver {
    using SafeERC20 for IBurnable;
    using SafeERC20 for IERC20;

    struct Auction {
        uint tokenId;
        uint auctionEnd;
        uint topRelativeBid;
        uint topActualBid;
        address topBidder;
        bool isWithdrawn;
        address owner;
        string title;
        string description;
        string tokenURI;
        bool canceled;
    }

    IERC20Permit public immutable stakeToken;
    IBurnable public immutable burnToken;
    IERC721Metadata public immutable auctionToken;
    IAuctionReferralProgram public auctionReferralManager;
    uint public rewardRate; 
    uint public immutable auctionRoundDuration; 
    uint public constant rewardDuration = 365 days; 
    uint public minStakeAmount;
    uint public nextBidStepPercentage;
    uint public successAuctionFeePercentage;

    uint public lastAuctionId;
    mapping(uint => Auction) public auctions;
    mapping(uint => uint) public auctionTokenId;
    mapping(uint => uint) public tokenLastAuctionId;

    mapping(address => uint) public userWeightedStakeDate;
    mapping(address => mapping(uint => uint)) public userStakeLocks;
    mapping(address => mapping(uint =>  uint)) public userActualStakeAmounts;
    mapping(address => mapping(uint =>  uint)) public userRelativeBidAmounts;
    mapping(address => uint[]) private _userAuctions;

    IRouter public swapRouter;
    bool public isSetPrice;
    uint public discountRate; 
    uint public stakeTokenToBurnTokenRate;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    event Staked(address indexed user, uint stakeAmount, uint totalRelativeBid, uint indexed auctionId, uint indexed tokenId, bool isRestake);
    event NewAuction(uint indexed auctionId, uint indexed tokenId);
    event NewTopBid(uint indexed auctionId, uint indexed tokenId, uint relativeBidAmount, uint actualBidAmount, address indexed bidder);
    event Withdraw(address indexed user, uint burnAmount);
    event BurnForToken(uint burnAmount, uint receiveAmount);
    event AuctionTokenWithdraw(address indexed winner, address previousOwner, uint bidAmount, uint fee, uint indexed tokenId, uint indexed auctionId);
    event RewardPaid(address indexed user, uint reward);
    event RewardUpdated(uint reward);
    event UpdateStakeTokenToBurnTokenRate(uint newRate);
    event TogglePricePolicy(bool indexed isSetPrice);
    event RescueAuctionToken(address indexed to, uint indexed auctionId, uint indexed tokenId, bool wasAuctionFinished);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed to, address token, uint amount);



    constructor(
        address _burnToken,
        address _stakeToken,
        address _auctionToken,
        address _auctionReferralManager,
        uint _rewardRate,
        uint _auctionRoundDuration,
        uint _inititalStakeToBurnRate,
        uint _minStakeAmount
    ) {
        require(_stakeToken != _burnToken, "HardStakingNFTAuction: stake and burn tokens are equal");
        require(_inititalStakeToBurnRate > 0, "HardStakingNFTAuction: rate should be greater than 0");
        burnToken = IBurnable(_burnToken);
        stakeToken = IERC20Permit(_stakeToken);
        auctionToken = IERC721Metadata(_auctionToken);
        auctionReferralManager = IAuctionReferralProgram(_auctionReferralManager);
        rewardRate = _rewardRate;
        auctionRoundDuration = _auctionRoundDuration;
        isSetPrice = true;
        stakeTokenToBurnTokenRate = _inititalStakeToBurnRate;
        minStakeAmount = _minStakeAmount;
        nextBidStepPercentage = 110;
        successAuctionFeePercentage = 5;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        //equal to return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return 0x150b7a02;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function earned(address account) public view returns (uint) {
        return (_balances[account] * (block.timestamp - userWeightedStakeDate[account]) * rewardRate) / (uint(100) * rewardDuration);
    }

    function relativeBidAmount(uint auctionId, uint bid) public view returns (uint) {
        require(isAuctionActive(auctionId), "HardStakingNFTAuction: Auction is ended or not started");
        return bid * (auctions[auctionId].auctionEnd - block.timestamp) / auctionRoundDuration;
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function userAuctions(address user) external view returns (uint[] memory auctionIds) {
        return _userAuctions[user];
    }

    function userUnwithdrawnAuctions(address user) external view returns (uint[] memory auctionIds) {
        uint unwithdrawnStakesCnt;
        for (uint i; i < _userAuctions[user].length; i++) {
            uint auctionId = _userAuctions[user][i];
            if (!isAuctionActive(auctionId) 
                && userActualStakeAmounts[user][auctionId] > 0 
                && auctions[auctionId].topBidder != user)
                unwithdrawnStakesCnt++;
        }
        auctionIds = new uint[](unwithdrawnStakesCnt);
        unwithdrawnStakesCnt = 0;
        for (uint i; i < _userAuctions[user].length; i++) {
            uint auctionId = _userAuctions[user][i];
            if (!isAuctionActive(auctionId) 
                && userActualStakeAmounts[user][auctionId] > 0 
                && auctions[auctionId].topBidder != user) {
                auctionIds[unwithdrawnStakesCnt] = _userAuctions[user][i];
                unwithdrawnStakesCnt++;
            }
        }
    }

    function availableForWithdraw(address user, uint auctionId) public view returns (uint actualStake) {
        if (!isAuctionActive(auctionId) && auctions[auctionId].topBidder != user) {
            actualStake = userActualStakeAmounts[user][auctionId];
        }
    }

    function getNextBidMinAmount(uint auctionId) external view returns (uint) {
        Auction storage auction = auctions[auctionId];
        if (auction.auctionEnd != 0 && auction.auctionEnd > block.timestamp) {
            uint nextBid = auction.topRelativeBid * nextBidStepPercentage / 100;
            return nextBid * auctionRoundDuration / (auction.auctionEnd - block.timestamp);
        } else if (auction.auctionEnd <= block.timestamp) {
            return 0; 
        } else {
            return auction.topRelativeBid;
        }
    }

    function getStakeTokenEquivalentAmount(uint burnTokenAmount) public view returns (uint) { 
        if (isSetPrice) {
            return burnTokenAmount * stakeTokenToBurnTokenRate / 1e18;
        } else {
            return getTokenEquivalentAmountFromRouter(burnTokenAmount, true);
        }
    }

    function getBurnTokenEquivalentAmount(uint stakeTokenAmount) public view returns (uint) { 
        if (isSetPrice) {
            return stakeTokenAmount * 1e18 / stakeTokenToBurnTokenRate;
        } else {
            return getTokenEquivalentAmountFromRouter(stakeTokenAmount, false);
        }
    }

    function getTokenEquivalentAmountFromRouter(uint amount, bool isBurnToStake) public view returns (uint) {
        address[] memory path = new address[](2);

        if (isBurnToStake) {
            path[0] = address(burnToken);            
            path[1] = address(stakeToken);
            return swapRouter.getAmountsOut(amount, path)[1] * (1000 + discountRate) / 1000;
        } else {
            path[0] = address(stakeToken);
            path[1] = address(burnToken);            
            return swapRouter.getAmountsOut(amount, path)[1] * 1000 / (1000 + discountRate);
        }
    }

    function isAuctionActive(uint auctionId) public view returns (bool) {
        return block.timestamp < auctions[auctionId].auctionEnd;
    }




    function stakeWithPermit(uint amount, uint auctionId, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        stakeToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(amount, auctionId, msg.sender, false, false);
    }

    function stake(uint amount, uint auctionId) external {
        _stake(amount, auctionId, msg.sender, false, false);
    }

    function stakeFor(uint amount, uint auctionId, address user) external {
        _stake(amount, auctionId, user, false, false);
    }

    function stakeAndBurnWithPermit(uint amount, uint auctionId, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(amount >= 0, "HardStakingNFTAuction: Cannot stake 0");
        burnToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        uint stakeTokenAmount = _burnTokenForStakeToken(amount);
        _stake(stakeTokenAmount, auctionId, msg.sender, true, false);
    }

    function stakeAndBurn(uint amount, uint auctionId) external {
        require(amount >= 0, "HardStakingNFTAuction: Cannot stake 0");
        uint stakeTokenAmount = _burnTokenForStakeToken(amount);
        _stake(stakeTokenAmount, auctionId, msg.sender, true, false);
    }

    function stakeAndBurnFor(uint amount, uint auctionId, address user) external {
        require(amount >= 0, "HardStakingNFTAuction: Cannot stake 0");
        uint stakeTokenAmount = _burnTokenForStakeToken(amount);
        _stake(stakeTokenAmount, auctionId, user, true, false);
    }


    function restake(uint previousAuctionId, uint currentAuctionId) external {
        Auction storage auction = auctions[previousAuctionId];
        require(block.timestamp > auction.auctionEnd, "HardStakingNFTAuction: Locked");
        uint previousAmount = userActualStakeAmounts[msg.sender][previousAuctionId];
        require(previousAmount >= minStakeAmount, "HardStakingNFTAuction: Amount is less than minimal allowed stake amount"); //minStakeAmount may have been increased from the previous stake, so we need to recheck it
        require(auction.topBidder != msg.sender, "HardStakingNFTAuction: Cannot withdraw on won auction, use processSuccesfullAuction"); 
        
        if (address(auctionReferralManager) != address(0)) 
            auctionReferralManager.processStake(msg.sender, previousAmount, false);

        userActualStakeAmounts[msg.sender][previousAuctionId] = 0;
        _stake(previousAmount, currentAuctionId, msg.sender, false, true);
    }

    function withdraw(uint auctionId) public {
        _withdraw(auctionId);
    }

    function getReward() public nonReentrant {
        _getReward(msg.sender);
    }

    function withdrawAndGetRewardByTokenId(uint tokenId) external {
        uint auctionId = tokenLastAuctionId[tokenId];
        getReward();
        withdraw(auctionId);
    }

    function withdrawByTokenId(uint tokenId) external {
        uint auctionId = tokenLastAuctionId[tokenId];
        withdraw(auctionId);
    }

    function withdrawAndGetReward(uint auctionId) external {
        getReward();
        withdraw(auctionId);
    }

    function withdrawForAuctionsAndGetReward(uint[] memory auctionIds) external {
        getReward();
        withdrawForAuctions(auctionIds);
    }

    function withdrawForAuctions(uint[] memory auctionIds) public {
        for (uint i; i < auctionIds.length; i++) {
            withdraw(auctionIds[i]);
        }
    }

    function processSuccesfullAuction(uint auctionId) public { 
        Auction storage auction = auctions[auctionId];
        require(auction.auctionEnd < block.timestamp, "HardStakingNFTAuction: Auction is not finished");
        address winner = auction.topBidder;
        
        auction.isWithdrawn = true;
        uint tokenId = auction.tokenId;
        if (winner == address(0)) {
            auctionToken.transferFrom(address(this), winner, tokenId);
            emit RescueAuctionToken(winner, auctionId, tokenId, true);
        } else {
            _getReward(winner);

            auctionToken.transferFrom(address(this), auction.topBidder, tokenId);
            uint actualStakeAmount = auction.topActualBid;

            uint bidFinalAmount;
            uint successFee;
            if (successAuctionFeePercentage != 0) {
                successFee = actualStakeAmount * successAuctionFeePercentage / 100;
                bidFinalAmount = actualStakeAmount - successFee;
                stakeToken.transfer(owner, successFee);
            } else {
                bidFinalAmount = actualStakeAmount;
            }
            stakeToken.transfer(auction.owner, bidFinalAmount);
            
            if (address(auctionReferralManager) != address(0)) 
                auctionReferralManager.processStake(winner, actualStakeAmount, false);
            _totalSupply -= actualStakeAmount;
            _balances[winner] -= actualStakeAmount;
            userActualStakeAmounts[winner][auctionId] = 0;

            emit AuctionTokenWithdraw(auction.topBidder, auction.owner, bidFinalAmount, successFee, tokenId, auctionId);
        }
    }

    function startNewAuctions(uint[] memory tokenIds, uint[] memory startBidAmounts, string[] memory titles, string[] memory descriptions) external { 
        require(tokenIds.length == startBidAmounts.length, "HardStakingNFTAuction: Wrong lengths");
        require(tokenIds.length == titles.length, "HardStakingNFTAuction: Wrong lengths");
        require(tokenIds.length == descriptions.length, "HardStakingNFTAuction: Wrong lengths");
        for (uint i; i < tokenIds.length; i++) {
            startNewAuction(tokenIds[i], startBidAmounts[i], titles[i], descriptions[i]);
        }
    }

    function startNewAuction(uint tokenId, uint startBidAmount, string memory title, string memory description) public {
        require(bytes(title).length > 0, "HardStakingNFTAuction: Empty title");
        auctionToken.transferFrom(msg.sender, address(this), tokenId);
        if(startBidAmount < minStakeAmount) startBidAmount = minStakeAmount;

        uint auctionId = ++lastAuctionId;
        auctionTokenId[auctionId] = tokenId;
        tokenLastAuctionId[tokenId] = auctionId;
        
        auctions[auctionId].tokenId = tokenId;
        auctions[auctionId].title = title;
        auctions[auctionId].description = description;
        auctions[auctionId].topRelativeBid = startBidAmount;
        auctions[auctionId].owner = msg.sender;
        auctions[auctionId].tokenURI = auctionToken.tokenURI(tokenId);

        emit NewAuction(auctionId, tokenId);
    }

    function rescueUnbiddenTokenByTokenId(uint tokenId) external {
        uint auctionId = tokenLastAuctionId[tokenId];
        rescueUnbiddenToken(auctionId);
    }

    function rescueUnbiddenToken(uint auctionId) public { 
        Auction storage auction = auctions[auctionId];
        require(auction.auctionEnd == 0, "HardStakingNFTAuction: Token is already bidden");
        require(auction.owner == msg.sender, "HardStakingNFTAuction: Not token owner");
        auction.canceled = true;
        auctionToken.transferFrom(address(this), msg.sender, auction.tokenId);
        emit RescueAuctionToken(msg.sender, auctionId, auction.tokenId, false);
    }



    function _burnTokenForStakeToken(uint amount) private returns (uint) {
        burnToken.safeTransferFrom(msg.sender, address(this), amount);

        burnToken.burnTokens(amount);
        uint convertibleTokenAmount = getStakeTokenEquivalentAmount(amount);
        emit BurnForToken(amount, convertibleTokenAmount);
        return convertibleTokenAmount;
    }


    function _stake(uint amount, uint auctionId, address user, bool isBurnToken, bool isRestake) private nonReentrant {
        require(auctionId <= lastAuctionId, "HardStakingNFTAuction: No such auction Id");
        require(amount >= minStakeAmount, "HardStakingNFTAuction: Amount is less than minimal allowed stake amount");
        Auction storage auction = auctions[auctionId];
        require(!auction.canceled, "HardStakingNFTAuction: Auction is canceled");
        if (auction.auctionEnd == 0) _initAuction(auctionId);
        else require(auction.auctionEnd > block.timestamp, "HardStakingNFTAuction: Round is finished");
        
        if(!isRestake && !isBurnToken) {
            stakeToken.transferFrom(msg.sender, address(this), amount);
        }

        if(!isRestake) {
            uint previousAmount = _balances[user];
            uint newAmount = previousAmount + amount;
            userWeightedStakeDate[user] = (userWeightedStakeDate[user] * previousAmount / newAmount) + (block.timestamp * amount / newAmount);
            _balances[user] = newAmount;
            _totalSupply += amount;
        } 

        uint currentRelativeBid = amount * (auction.auctionEnd - block.timestamp) / auctionRoundDuration;
        uint totalRelativeBid = userRelativeBidAmounts[user][auctionId] + currentRelativeBid;
        userRelativeBidAmounts[user][auctionId] = totalRelativeBid;

        emit Staked(user, amount, totalRelativeBid, auctionId, auction.tokenId, isRestake);
        
        uint previousStakeForCurrentAuction = userActualStakeAmounts[user][auctionId];
        if (previousStakeForCurrentAuction == 0) {
            _userAuctions[user].push(auctionId);
            userStakeLocks[user][auctionId] = auction.auctionEnd;
        } else {
            amount += previousStakeForCurrentAuction;
        }
        userActualStakeAmounts[user][auctionId] = amount;    

        uint nextBid = auction.topBidder != address(0)
            ? auction.topRelativeBid * nextBidStepPercentage / 100
            : auction.topRelativeBid;
        
        if (totalRelativeBid >= nextBid ) {
            auction.topRelativeBid = totalRelativeBid;
            auction.topActualBid = amount;
            auction.topBidder = user;
            emit NewTopBid(auctionId, auction.tokenId, totalRelativeBid, amount, user);
        }
    }

    function _getReward(address user) private {
        uint reward = earned(user);
        if (reward > 0) {
            userWeightedStakeDate[user] = block.timestamp;
            stakeToken.transfer(user, reward);
            emit RewardPaid(user, reward);
        }
    }

    function _withdraw(uint auctionId) private nonReentrant {
        Auction storage auction = auctions[auctionId];
        address user = msg.sender;
        uint amount = userActualStakeAmounts[user][auctionId];
        require(amount > 0, "HardStakingNFTAuction: This auction stake was withdrawn");
        require(userStakeLocks[user][auctionId] < block.timestamp, "HardStakingNFTAuction: Locked");

        require(auction.topBidder != user, "HardStakingNFTAuction: Cannot withdraw on won auction, use processSuccesfullAuction");
        stakeToken.transfer(user, amount);
        if (address(auctionReferralManager) != address(0)) 
            auctionReferralManager.processStake(msg.sender, amount, false);
                
        _totalSupply -= amount;
        _balances[user] -= amount;
        userActualStakeAmounts[user][auctionId] = 0;
        //userRelativeBidAmounts is not cleared on withdrawal and stay in contract for history
        emit Withdraw(user, amount);
    }

    function _initAuction(uint auctionId) private {
        uint auctionEnd = block.timestamp + auctionRoundDuration;
        auctions[auctionId].auctionEnd = auctionEnd;
    }





    function togglePricePolicy() external onlyOwner {
        isSetPrice = !isSetPrice;
        emit TogglePricePolicy(isSetPrice);
    }

    function updateStakeTokenToBurnTokenRate(uint newRate) external onlyOwner {
        require(newRate > 0, "HardStakingNFTAuction: New rate is must be greater than 0");
        stakeTokenToBurnTokenRate = newRate;
        emit UpdateStakeTokenToBurnTokenRate(newRate);
    }    
    
    function updateDiscountRate(uint newDiscountRate) external onlyOwner {
        require(newDiscountRate < 1000, "HardStakingNFTAuction: New discount rate must be less than 1000");
        discountRate = newDiscountRate;
    }

    function updateRewardRate(uint newRewardRate) external onlyOwner {
        rewardRate = newRewardRate;
        emit RewardUpdated(newRewardRate);
    }

    function updateMinStakeAmount(uint newMinStakeAmount) external onlyOwner {
        require(newMinStakeAmount > 0, "HardStakingNFTAuction: New min stake amount must be greater than 0");
        minStakeAmount = newMinStakeAmount;
    }
    
    function updateSuccessAuctionFee(uint newSuccessAuctionFeePercentage) external onlyOwner {
        successAuctionFeePercentage = newSuccessAuctionFeePercentage;
    }    
    
    function updateNextBidStepPercentage(uint newNextBidStepPercentage) external onlyOwner {
        nextBidStepPercentage = newNextBidStepPercentage;
    }
    
    function updateSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "HardStakingNFTAuction: Address is zero");
        swapRouter = IRouter(newSwapRouter);
    }

    function updateAuctionReferralManager(address newAuctionReferralManager) external onlyOwner {
        //auction referral manager can be set to zero address, it means referral distribution is turned off
        auctionReferralManager = IAuctionReferralProgram(newAuctionReferralManager);
    }

    function rescue(address to, address tokenAddress, uint amount) external onlyOwner {
        require(to != address(0), "HardStakingNFTAuction: Cannot rescue to the zero address");
        require(amount > 0, "HardStakingNFTAuction: Cannot rescue 0");
        require(tokenAddress != address(stakeToken), "HardStakingNFTAuction: Cannot rescue stake token");
        
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    function rescue(address payable to, uint amount) external onlyOwner {
        require(to != address(0), "HardStakingNFTAuction: Cannot rescue to the zero address");
        require(amount > 0, "HardStakingNFTAuction: Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
    
    function changeAuctionEnd(uint auctionId, uint deadline) external onlyOwner {
        require(auctionId <= lastAuctionId, "HardStakingNFTAuction: No such auction Id");
        auctions[auctionId].auctionEnd = deadline; 
    }
}