pragma solidity ^0.8.7;

import * as wrap from "./../commons/Wrap.sol";
import * as ownable from "./../commons/Ownable.sol";
import * as pausable from "./../commons/Pauseable.sol";
import * as whitelist from "./../commons/WhitelistAdminRole.sol";
import * as safeMath from "./../commons/SafeMath.sol"; 
import * as ERC1155TradableSol from "./../commons/ERC1155Tradeable.sol";
import * as IERC20Sol from "./../commons/IERC20.sol";
import * as DetailedERC20Sol from "./../commons/DetailedERC20.sol";
import * as multiBalance from "./../commons/IMultiTokenBalanceOfContract.sol";
import * as rewardsHolder from "./../staking/PendingRewardsProvider.sol";
import * as vaultInterface from "./../staking/interface/IVault.sol";
import * as stakingInterface from "./../staking/interface/IStaking.sol";
import * as routerInterface from "./../utility/interface/IRouter.sol";
import * as buybackContract from "./../utility/AdvancedBuyBack.sol";
import * as uniswapRouter from "./../swap/interface/IUniswapV2Router02.sol";

contract Stopelon_NFTFarm_v2 is ownable.Ownable, pausable.Pausable, whitelist.WhitelistAdminRole,
	rewardsHolder.PendingRewardsProvider, buybackContract.AdvancedBuyBack {
	using safeMath.SafeMath for uint256;

	struct CardRedeemLevel {
		uint256 points;
		uint256 fee;	
		uint256 limit;
		uint256 redeemed;
		bool enabled;	
	}

	struct Card {			
		uint256 releaseTime;
		address erc1155;
		uint256 number;
		bool nsfw;
		bool shadowed;
		uint256 supply;
		uint256 redeemed;
		mapping(address => uint256) customRewardAddressList;
		address[] customRewardAddressArray;
		CardRedeemLevel[] cardRedeemLevels;
		uint256 activeLevels;
	} 

	struct RewardShareReceiver {
		address receiver;
		uint256 share;
		uint256 buybackShare;
		bool interactedWith;
		bool enabled;
	}

	struct UserFarming {
		uint256 lastClaimedTime;
		uint256 totalEarned;
		uint256 totalSpent;
		address userAddress;
	}

	struct CardCache {
		address erc1155;
		uint256 number;
	}

	struct FarmingRound {
		uint256 number;
		uint256 startTime;
		uint256 closedTime;
		mapping(address => mapping (uint256 => Card)) cards;
		CardCache[] availableCards;
	}

	uint256 private constant scaling = uint256(10) ** 12;
	uint256 private constant defaultRewardRate = 86400;
	bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
    bytes4 constant internal ERC1155_RECEIVED_ERR_VALUE = 0x0;

	uint256 private periodStart;
	uint256 public minStake;
	uint256 public maxStake;
	uint256 public rewardRate; // 1 point per day per staked token, multiples of this lowers time per staked token
	uint256 public totalFeesCollected;
	address public controller;

	uint256 public currentRound;
	
	mapping(uint256 => FarmingRound) private rounds;
	mapping(address => UserFarming) private userFarming;

	mapping(address => RewardShareReceiver) private rewardReceivers;
	address[] private interactedRewardReceivers;

	address public tokenContractAddress;
	routerInterface.IRouter public routerContract;

    bool public constructed = false;
    
	event CardAdded(address indexed erc1155, uint256 indexed card, uint256 points, uint256 mintFee, uint256 releaseTime);
	event Removed(address indexed erc1155, uint256 indexed card, address indexed recipient, uint256 amount);
	event Redeemed(address indexed user, address indexed erc1155, uint256 indexed id, uint256 amount);
	
	modifier updateReward(address account) {
		if (account != address(0)) {
			_updatePointsInternal(account);
		}
		_;
	}
	
	constructor(address _tokenContract, routerInterface.IRouter _routerContract, 
		address _uniSwapRouterContract, 
		uint256 _periodStart,
		uint256 _minStake,
		uint256 _maxStake,
		address _controller) buybackContract.AdvancedBuyBack(_uniSwapRouterContract, IERC20Sol.IERC20(_tokenContract)) {
		require(_minStake > 0, "Min stake should be greater than 0");
		require(_maxStake >= _minStake, "Max stake should be greater than min stake!");

		periodStart = _periodStart;
		minStake = _minStake;
		maxStake = _maxStake;
		controller = _controller;
		rewardRate = defaultRewardRate;
		routerContract = _routerContract;
		tokenContractAddress = _tokenContract;
	}	

	// VIEWS [PUBLIC]
	function balanceOf(address account) public view returns (uint256) {
		return getAccountHoldings(account);
	}

	function lastClaimTime(address account) public view returns (uint256) {
		return userFarming[account].lastClaimedTime;
	}

	function roundRunning() external view returns (bool){
	    return rounds[currentRound].closedTime == 0 && currentRound > 0;
	}

	function supply(uint256 round, address _erc1155Address, uint256 _id) external view returns (uint256){
	    return rounds[round].cards[_erc1155Address][_id].supply;
	}

	function redeemed(uint256 round, address _erc1155Address, uint256 _id) external view returns (uint256){
	    return rounds[round].cards[_erc1155Address][_id].redeemed;
	}

	function cardReleaseTime(uint256 round, address erc1155Address, uint256 id) external view returns (uint256) {
		return rounds[round].cards[erc1155Address][id].releaseTime;
	}

	function cardERC1155Address(uint256 round, uint256 position) external view returns (address) {
		return rounds[round].availableCards[position].erc1155;
	}

	function cardTokenId(uint256 round, uint256 position) external view returns (uint256) {
		return rounds[round].availableCards[position].number;
	}
	
	function availableCardCount(uint256 round) external view returns (uint256) {
		return rounds[round].availableCards.length;
	}

	function cardRedeemLevels(address erc1155Address, uint256 id) external view returns (uint8[] memory) {
		uint8[] memory levelList = new uint8[](rounds[currentRound].cards[erc1155Address][id].activeLevels);
		uint8 k = 0;
		for (uint8 i = 0; i < rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels.length; i++) {
			if (rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[i].enabled) {				
				levelList[k] = i;	
				k = k + 1;		
			}
		}
		return levelList;
	}

	function rewardReceiversList() external view returns (address[] memory) {
		address[] memory list = new address[](interactedRewardReceivers.length);
		for (uint8 i = 0; i < interactedRewardReceivers.length; i++) {
			list[i] = interactedRewardReceivers[i];		
		}
		return list;
	}

	function rewardReceiverShare(address receiver) external view returns (uint256) {
		return rewardReceivers[receiver].share;
	}

	function rewardReceiverBuyBackShare(address receiver) external view returns (uint256) {
		return rewardReceivers[receiver].buybackShare;
	}

	function cardRedeemLevelFee(address erc1155Address, uint256 id, uint256 level) external view returns (uint256) {
		return rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].fee;
	}

	function cardRedeemLevelPoints(address erc1155Address, uint256 id, uint256 level) external view returns (uint256) {
		return rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].points;
	}

	function totalEarned(address account) public view returns (uint256) {		
		return userFarming[account].totalEarned;
	}	

	function totalSpend(address account) public view returns (uint256) {		
		return userFarming[account].totalSpent;
	}	

	function points(address account) public view returns (uint256) {		
		return userFarming[account].totalEarned
			.add(getUnclaimedPoints(account, scaling))
			.sub(userFarming[account].totalSpent);
	}	
	
	// VIEWS [INTERNAL]
	function getUnclaimedPoints(address account, uint256 pow) internal view returns(uint256){
		if (userFarming[account].lastClaimedTime == 0)
			return 0;
		uint256 holdings = getAccountHoldings(account);
		uint256 timePassed = block.timestamp - userFarming[account].lastClaimedTime; 
		return timePassed.mul(pow).div(rewardRate).mul(holdings).div(pow);
	}

	function getAccountHoldings(address account) internal view returns(uint256){
		address vaultAddress = routerContract.vaultImplementation();
		uint256 balance = vaultInterface.IVault(vaultAddress).balanceOf(account);
		return filterAccountHoldings(balance);
	}

	function filterAccountHoldings(uint256 balance) internal view returns(uint256){
		if (balance < minStake)
			return 0;
		else if (balance > maxStake)
			return maxStake;
	    return balance;
	}

	function getTotalRewardShare() internal view returns(uint256){
		uint256 share = 0;
		for (uint256 i = 0; i < interactedRewardReceivers.length; i++) { 
			if (rewardReceivers[interactedRewardReceivers[i]].enabled) {      				
				share = share.add(rewardReceivers[interactedRewardReceivers[i]].share);			        		
			}
		} 
		return share;
	}

	// SETTERS

	function addRewardReceiver(address addressOfContract, uint256 share, uint256 buybackShare) external onlyWhitelistAdmin {
		require(getTotalRewardShare() + share <= 100, "Total shares sent out cannot be more than 100%");
		require(buybackShare >= 0 && buybackShare <= 100, "Buyback cannot be more than 100%");

		if (!rewardReceivers[addressOfContract].interactedWith) {
			interactedRewardReceivers.push(addressOfContract);
		}
	    rewardReceivers[addressOfContract].receiver = addressOfContract;
		rewardReceivers[addressOfContract].interactedWith = true;
		rewardReceivers[addressOfContract].enabled = true;		
		rewardReceivers[addressOfContract].share = share;		
		rewardReceivers[addressOfContract].buybackShare = buybackShare;
	}	  

	function setRewardReceiverShare(address addressOfContract, uint256 share) external onlyWhitelistAdmin {
		require(rewardReceivers[addressOfContract].enabled, "This address is not enabled as a reward receiver!");
		require(getTotalRewardShare() - rewardReceivers[addressOfContract].share + share <= 100, "Total shares sent out cannot be more than 100%");
		
				
		rewardReceivers[addressOfContract].share = share;		
	}	  

	function setRewardReceiverBuybackShare(address addressOfContract, uint256 buybackShare) external onlyWhitelistAdmin {
		require(rewardReceivers[addressOfContract].enabled, "This address is not enabled as a reward receiver!");
		require(buybackShare >= 0 && buybackShare <= 100, "Buyback cannot be more than 100%");
				
		rewardReceivers[addressOfContract].buybackShare = buybackShare;		
	}	  

	function removeRewardReceiver(address addressOfContract) external onlyWhitelistAdmin{
	    require(rewardReceivers[addressOfContract].enabled, "Receiver is already removed");
	    rewardReceivers[addressOfContract].enabled = false;
	}	
		
	function setRewardRate(uint256 _rewardRate) external onlyWhitelistAdmin{
		require(_rewardRate > 0, "Reward rate too low");
		rewardRate = _rewardRate;
	}	   
	
	function setMinMaxStake(uint256 _minStake, uint256 _maxStake) external onlyWhitelistAdmin{
		require(_minStake >= 0 && _maxStake > 0 && _maxStake >= _minStake, "Problem with min and max stake setup");
		minStake = _minStake;
	    maxStake = _maxStake;
	}		

	function setController(address _controller) external onlyWhitelistAdmin {
		movePendingRewards(address(0), controller, _controller);
		controller = _controller;
	}	

	function startRound() external onlyWhitelistAdmin {
		require(rounds[currentRound].closedTime > 0 || currentRound == 0, "Rounds is currently running! Close it and then create new one.");
		currentRound++;
		rounds[currentRound].startTime = block.timestamp;
		rounds[currentRound].number = currentRound;
	}

	function endRound() external onlyWhitelistAdmin {
		require(rounds[currentRound].closedTime == 0 && currentRound > 0, "No round running right now");

		for (uint256 i = 0; i < rounds[currentRound].availableCards.length; i++) { 
			CardCache storage cache = rounds[currentRound].availableCards[i];
			uint256 remainingHoldings = ERC1155TradableSol.ERC1155Tradable(cache.erc1155).balanceOf(address(this), cache.number);
			if (remainingHoldings > 0) {
				ERC1155TradableSol.ERC1155Tradable(cache.erc1155).burn(address(this), cache.number, remainingHoldings);
			}
		}

		rounds[currentRound].closedTime = block.timestamp;
	}

	function addCardRedeemLevel(address _erc1155Address, uint256 _id, uint256 _points, uint256 fee, uint256 limit) external onlyWhitelistAdmin {
		require(_points >= 0, "Points cannot be negative");
		require(_id > 0, "Invalid token id");
		require(fee > 0, "Fee cannot be 0");
		require(rounds[currentRound].closedTime == 0 && currentRound > 0, "No round running right now");

		CardRedeemLevel memory level = CardRedeemLevel({fee: fee, points: _points, enabled: true, limit: limit, redeemed: 0});
		level.fee = fee;
		level.enabled = true;
		level.points = _points;
		rounds[currentRound].cards[_erc1155Address][_id].cardRedeemLevels.push(level);
		rounds[currentRound].cards[_erc1155Address][_id].activeLevels = rounds[currentRound].cards[_erc1155Address][_id].activeLevels.add(1);
	}

	function removeCardRedeemLevel(address _erc1155Address, uint256 _id, uint256 number) external onlyWhitelistAdmin {
		require(rounds[currentRound].closedTime == 0 && currentRound > 0, "No round running right now");
		require(_id > 0, "Invalid token id");
		require(number >= 0 && rounds[currentRound].cards[_erc1155Address][_id].cardRedeemLevels[number].enabled, "Id is not valid or level is already disabled");
		rounds[currentRound].cards[_erc1155Address][_id].cardRedeemLevels[number].enabled = false;
		rounds[currentRound].cards[_erc1155Address][_id].activeLevels = rounds[currentRound].cards[_erc1155Address][_id].activeLevels.sub(1);
	}
	
	function addNfts(		
		uint256 _initialPoints,
		uint256 _initialFee,
		uint256 _releaseTime,
		address _erc1155Address,
		uint256 _tokenId,
		uint256 _cardAmount
	) external onlyWhitelistAdmin returns (uint256) {
		require(rounds[currentRound].closedTime == 0 && currentRound > 0, "No round running right now");
		require(_tokenId > 0, "Invalid token id");
		require(_cardAmount > 0, "Invalid card amount");

		Card storage c = rounds[currentRound].cards[_erc1155Address][_tokenId];

		if (c.supply == 0){ 
			CardCache memory newCard = CardCache({erc1155: _erc1155Address, number: _tokenId});
			rounds[currentRound].availableCards.push(newCard);
		}

		CardRedeemLevel memory level = CardRedeemLevel({fee: _initialFee, points: _initialPoints, enabled: true, limit: 0, redeemed: 0});
		level.points = _initialPoints;
		level.fee = _initialFee;
		level.enabled = true;
		c.releaseTime = _releaseTime;
		c.erc1155 = _erc1155Address;
		c.number = _tokenId;
		c.supply = c.supply.add(_cardAmount);
		rounds[currentRound].cards[_erc1155Address][_tokenId].cardRedeemLevels.push(level);
		rounds[currentRound].cards[_erc1155Address][_tokenId].activeLevels = 1;

		ERC1155TradableSol.ERC1155Tradable(_erc1155Address).safeTransferFrom(msg.sender, address(this), _tokenId, _cardAmount, "");

		emit CardAdded(_erc1155Address, _tokenId, _initialPoints, _initialFee, _releaseTime);
		return _tokenId;
	}

	// FUNCTIONS [PUBLIC] 
	function redeem(address erc1155Address, uint256 id, uint256 level) external payable {
		require(rounds[currentRound].closedTime == 0 && currentRound > 0, "No round running right now");
		require(rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].enabled, "Card not found");
		require(block.timestamp >= rounds[currentRound].cards[erc1155Address][id].releaseTime, "Card not released");
		require(points(msg.sender) >= rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].points, "Redemption exceeds point balance");
		require(rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].limit == 0 || rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].redeemed < rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].limit, "Cannot redeem on this level more than limit");
		
		uint256 fees = rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].fee;
        bool enableFees = fees > 0;
        
        require(msg.value == fees, "Send the proper ETH for the fees");

		if (enableFees) {
			totalFeesCollected = totalFeesCollected.add(fees);	
			_processRewards(fees);
		}

		userFarming[msg.sender].totalSpent = userFarming[msg.sender].totalSpent.add(rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].points);
		ERC1155TradableSol.ERC1155Tradable(rounds[currentRound].cards[erc1155Address][id].erc1155).safeTransferFrom(address(this), msg.sender, id, 1, "");		
		rounds[currentRound].cards[erc1155Address][id].redeemed = rounds[currentRound].cards[erc1155Address][id].redeemed.add(1);
		rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].redeemed = rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].redeemed.add(1);

		emit Redeemed(msg.sender, rounds[currentRound].cards[erc1155Address][id].erc1155, id, rounds[currentRound].cards[erc1155Address][id].cardRedeemLevels[level].points);
	}

	function updatePointsFor(address account) external onlyWhitelistAdmin {
		_updatePointsInternal(account);
	}
	
	function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4){	
	    if(ERC1155TradableSol.ERC1155Tradable(_operator) == ERC1155TradableSol.ERC1155Tradable(address(this))){	    
	        return ERC1155_RECEIVED_VALUE;	    
	    }	    
	    return ERC1155_RECEIVED_ERR_VALUE;
	}
	
	function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4){	      
        if(ERC1155TradableSol.ERC1155Tradable(_operator) == ERC1155TradableSol.ERC1155Tradable(address(this))){    
            return ERC1155_BATCH_RECEIVED_VALUE;    
        }    
        return ERC1155_RECEIVED_ERR_VALUE;
    }

	function _processRewards(uint256 feesAmount) internal {	
		uint256 remaining = feesAmount;
		for (uint256 i = 0; i < interactedRewardReceivers.length; i++) { 
			if (rewardReceivers[interactedRewardReceivers[i]].enabled) {      				
				uint256 share = rewardReceivers[interactedRewardReceivers[i]].share;	
				uint256 buybackShare = rewardReceivers[interactedRewardReceivers[i]].buybackShare;	
				address receiver = rewardReceivers[interactedRewardReceivers[i]].receiver;
				uint256 amountToSend = feesAmount.mul(share).div(100);
				if (amountToSend > 0) {
					if (buybackShare > 0) {
						uint256 buybackAmount = amountToSend.mul(buybackShare).div(100);
						uint256 beforeBuy = IERC20Sol.IERC20(tokenContractAddress).balanceOf(address(this));
						uint256 beforeBuyETH = address(this).balance;
						buyback(buybackAmount);
						uint256 afterBuy = IERC20Sol.IERC20(tokenContractAddress).balanceOf(address(this));
						uint256 afterBuyETH = address(this).balance;
						uint256 reflections = afterBuy.sub(beforeBuy);
						uint256 remainingETH = amountToSend.sub(beforeBuyETH.sub(afterBuyETH));

						addPendingRewards(tokenContractAddress, receiver, reflections);
						addPendingRewards(address(0), receiver, remainingETH);
					} else {
						addPendingRewards(address(0), receiver, amountToSend);						
					}
					remaining = remaining.sub(amountToSend);
				}	        		
			}
		} 
		if (remaining > 0) {
			addPendingRewards(address(0), controller, remaining);
		}
	}	

	function _updatePointsInternal(address account) internal {
		if (userFarming[account].lastClaimedTime > 0) {
			userFarming[account].totalEarned = userFarming[account].totalEarned.add(getUnclaimedPoints(account, scaling));
		} else {
			userFarming[account].totalEarned = 0;
			userFarming[account].totalSpent = 0;
		}
		userFarming[account].lastClaimedTime = block.timestamp;
	}
}

pragma solidity ^0.8.7;

interface IRouter {
    function vaultImplementation() external view returns (address);
    function stakingImplementation() external view returns (address);
    function nftFarmingImplementation() external view returns (address);
    function rewardProviders() external view returns (address[] memory);

    function vaultSync(address account) external;
}

pragma solidity ^0.8.7;

import * as IERC20Sol from "./../commons/IERC20.sol";
import * as uniswapRouter from "./../swap/interface/IUniswapV2Router02.sol";
import * as uniswapFactory from "./../swap/interface/IUniswapV2Factory.sol";
import * as uniswapPair from "./../swap/interface/IUniswapV2Pair.sol";
import * as safeMath from "./../commons/SafeMath.sol";

contract AdvancedBuyBack {
    using safeMath.SafeMath for uint256;

    uniswapRouter.IUniswapV2Router02 public uniswapV2Router;
    IERC20Sol.IERC20 public tokenContract;

    /**
     * routerContract - basically means pancakeswap/uniswap contract
     * priceMakerContract - WETH or WBNB or BUSD etc
     */
    constructor(address routerContract, IERC20Sol.IERC20 _tokenContract) {
        tokenContract = _tokenContract;
        uniswapV2Router = uniswapRouter.IUniswapV2Router02(routerContract);
    }

    function buyback(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(tokenContract);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
            0,
            path,
            address(this),
            block.timestamp);
    }
}

pragma solidity >=0.6.2;

import * as router from "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is router.IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity ^0.8.7;

import * as balanceOf from "./../../commons/IBalanceOfContract.sol";
import * as rewards from "./IPendingRewardProvider.sol";
interface IVault is balanceOf.IBalanceOfContract, rewards.IPendingRewardProvider {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function lock(uint256 amount, uint256 rounds) external;

    function totalSupply() external view returns (uint256);

    function vaultSharesOf(address account) external view returns (uint256);
    function totalVaultShares() external view returns (uint256);
}

pragma solidity ^0.8.7;

interface IStaking {
    function roundCanBeIncremented() external view returns (bool); 
    function incrementRound() external;
    function currentRound() external view returns (uint256);

    function getLastClaimedRound(address token) external view returns (uint256);
    function pendingReflections(address token, address account) external view returns (uint256);
    function claimPendingReflectionsFor(address account) external;
}

pragma solidity ^0.8.7;

interface IPendingRewardProvider {
    function getRewardTokens() external view returns(address[] memory);
    function getPendingRewards(address rewardToken, address receiver) external view returns(uint256);
    function withdrawTokenRewards(address rewardToken) external;
}

pragma solidity ^0.8.7;

import * as context from "./../commons/Context.sol";
import * as whitelist from "./../commons/WhitelistAdminRole.sol";
import * as IERC20Sol from "./../commons/IERC20.sol";
import * as safeERC20 from "./../commons/SafeERC20.sol";
import * as math from "./../commons/SafeMath.sol";
import * as rewardsInterface from "./interface/IPendingRewardProvider.sol";

contract PendingRewardsProvider is whitelist.WhitelistAdminRole, rewardsInterface.IPendingRewardProvider {
    using safeERC20.SafeERC20 for IERC20Sol.IERC20;
    using math.SafeMath for uint256;

    struct RewardToken {
        bool enabled;
        bool interactedWith;
        address tokenContract;
        mapping(address => uint256) pendingWithdrawals;
    }

    mapping(address => RewardToken) pendingTokenRewards;        
    address[] interactedRewardTokens;

    function getRewardTokens() external view returns(address[] memory) {
        return interactedRewardTokens;
    }

    function getPendingRewards(address rewardToken, address receiver) external view returns(uint256) {
        return pendingTokenRewards[rewardToken].pendingWithdrawals[receiver];
    }

    function addPendingRewards(address rewardToken, address receiver, uint256 amount) internal {
        if (!pendingTokenRewards[rewardToken].interactedWith) {
            interactedRewardTokens.push(rewardToken);
            pendingTokenRewards[rewardToken].interactedWith = true;
        }
        pendingTokenRewards[rewardToken].enabled = true;
        pendingTokenRewards[rewardToken].pendingWithdrawals[receiver] = pendingTokenRewards[rewardToken].pendingWithdrawals[receiver].add(amount);
    }

    function movePendingRewards(address rewardToken, address original, address newOwner) internal {
        pendingTokenRewards[rewardToken].pendingWithdrawals[newOwner] =
            pendingTokenRewards[rewardToken].pendingWithdrawals[newOwner].add(pendingTokenRewards[rewardToken].pendingWithdrawals[original]);
        pendingTokenRewards[rewardToken].pendingWithdrawals[original] = 0;
    }

    function withdrawTokenRewards(address rewardToken) external {
        require(pendingTokenRewards[rewardToken].pendingWithdrawals[_msgSender()] > 0, "No pending rewards for you in selected token!");
        withdrawTokenRewardsInternal(rewardToken, _msgSender());		  
    }

    function withdrawAllRewards() external {
        for (uint256 i = 0; i < interactedRewardTokens.length; i++) { 
			if (pendingTokenRewards[interactedRewardTokens[i]].enabled && pendingTokenRewards[interactedRewardTokens[i]].pendingWithdrawals[_msgSender()] > 0) {      		
                withdrawTokenRewardsInternal(interactedRewardTokens[i], _msgSender());		  		
			}
		}
    }

    function withdrawTokenRewardForReceiver(address rewardToken, address receiver) external onlyWhitelistAdmin {
        require(pendingTokenRewards[rewardToken].pendingWithdrawals[receiver] > 0, "No pending rewards for receiver in selected token!");
        withdrawTokenRewardsInternal(rewardToken, receiver);		  		
    }

    function withdrawTokenRewardsInternal(address rewardToken, address receiver) internal {
        uint256 amount = pendingTokenRewards[rewardToken].pendingWithdrawals[receiver];
        if (rewardToken == address(0)) {
            payable(receiver).transfer(amount);
        } else {
            IERC20Sol.IERC20(rewardToken).safeTransfer(receiver, amount);
        }
        pendingTokenRewards[rewardToken].pendingWithdrawals[receiver] = 0;
    }
}

pragma solidity ^0.8.7;

import * as safemath from "./SafeMath.sol";
import * as safeERC20 from "./SafeERC20.sol";
import * as IERC20Sol from "./IERC20.sol";
import * as balanceOfContact from "./IBalanceOfContract.sol";

contract Wrap is balanceOfContact.IBalanceOfContract {
	using safemath.SafeMath for uint256;
	using safeERC20.SafeERC20 for IERC20Sol.IERC20;
	IERC20Sol.IERC20 public token;

	constructor(IERC20Sol.IERC20 _tokenAddress) {
		token = IERC20Sol.IERC20(_tokenAddress);
	}

	uint256 internal _totalSupply;
	mapping(address => uint256) internal _balances;

	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public override virtual view returns (uint256) {
		return _balances[account];
	}

	function stake(uint256 amount) virtual public {
		_totalSupply = _totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
		IERC20Sol.IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
	}

	function withdraw(uint256 amount) virtual public {
		_totalSupply = _totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
		IERC20Sol.IERC20(token).safeTransfer(msg.sender, amount);
	}

	function _rescueScore(address account) internal {
		uint256 amount = _balances[account];

		_totalSupply = _totalSupply.sub(amount);
		_balances[account] = _balances[account].sub(amount);
		IERC20Sol.IERC20(token).safeTransfer(account, amount);
	}
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";
import * as roles from "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
abstract contract WhitelistAdminRole is context.Context {
    using roles.Roles for roles.Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    roles.Roles.Role private _whitelistAdmins;

    function initWhiteListAdmin() internal{
        _addWhitelistAdmin(_msgSender());
    }

    constructor () {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity ^0.8.7;

library Strings {
	// via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d,
		string memory _e
	) internal pure returns (string memory) {
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		bytes memory _bd = bytes(_d);
		bytes memory _be = bytes(_e);
		string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
		bytes memory babcde = bytes(abcde);
		uint256 k = 0;
		for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
		for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
		for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
		for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
		for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
		return string(babcde);
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, _d, "");
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, "", "");
	}

	function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
		return strConcat(_a, _b, "", "", "");
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len - 1;
		while (_i != 0) {
			bstr[k--] = bytes1(uint8(48 + (_i % 10)));
			_i /= 10;
		}
		return string(bstr);
	}
}

pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

pragma solidity ^0.8.7;


import * as safemath from "./SafeMath.sol";
import * as addressSol from "./Address.sol";
import * as ierc20 from "./IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using safemath.SafeMath for uint256;
    using addressSol.Address for address;

    function safeTransfer(ierc20.IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ierc20.IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(ierc20.IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ierc20.IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ierc20.IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ierc20.IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.7;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";
import * as roles from "./Roles.sol";

abstract contract PauserRole is context.Context {
    using roles.Roles for roles.Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    roles.Roles.Role private _pausers;

    function initPauserRole() internal{
        _addPauser(_msgSender());
    }

    constructor () {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

pragma solidity ^0.8.7;

import * as puserRole from "./PauserRole.sol";
import * as context from "./Context.sol";


abstract contract Pausable is context.Context, puserRole.PauserRole {

    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor ()  {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is context.Context {
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

pragma solidity ^0.8.7;

import * as context from "./Context.sol";
import * as roles from "./Roles.sol";

abstract contract MinterRole is context.Context {
    using roles.Roles for roles.Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    roles.Roles.Role private _minters;

    function initMinter() internal{
        _addMinter(_msgSender());
    }

    constructor () {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

pragma solidity ^0.8.7;

interface IMultiTokenBalanceOfContract {
    function multiBalanceOf(address token, address account) external view returns (uint256);
}

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.7;

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

pragma solidity ^0.8.7;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IBalanceOfContract {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

pragma solidity ^0.8.7;

import * as ERC1155MetadataSol from "./ERC1155Metadata.sol";
import * as ERC1155MintBurnSol from "./ERC1155MintBurn.sol";
import * as ERC1155Sol from "./ERC1155.sol";
import * as strings from "./Strings.sol";
import * as ownable from "./Ownable.sol";
import * as minterRole from "./MinterRole.sol";
import * as whitelistAdminRole from "./WhitelistAdminRole.sol";
import * as safeMath from "./SafeMath.sol";

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, 
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155Sol.ERC1155, ERC1155MintBurnSol.ERC1155MintBurn, ERC1155MetadataSol.ERC1155Metadata, 
        ownable.Ownable, minterRole.MinterRole, whitelistAdminRole.WhitelistAdminRole {
	using strings.Strings for string;
	using safeMath.SafeMath for uint256;

	address proxyRegistryAddress;
	uint256 private _currentTokenID = 0;
	mapping(uint256 => address) public creators;
	mapping(uint256 => uint256) public tokenSupply;
	mapping(uint256 => uint256) public tokenMaxSupply;
	// Contract name
	string public name;
	// Contract symbol
	string public symbol;

    mapping(uint256 => string) private uris;

    bool private constructed = false;

    function init(
		string memory _name,
		string memory _symbol,
		address _proxyRegistryAddress
	) public {
	    
	    require(!constructed, "ERC155 Tradeable must not be constructed yet");
	    
	    constructed = true;
	    
		name = _name;
		symbol = _symbol;
		proxyRegistryAddress = _proxyRegistryAddress;
		
		super.initMinter();
		super.initWhiteListAdmin();
	}

	constructor(
		string memory _name,
		string memory _symbol,
		address _proxyRegistryAddress
	) {
	    constructed = true;
		name = _name;
		symbol = _symbol;
		proxyRegistryAddress = _proxyRegistryAddress;
	}

	function removeWhitelistAdmin(address account) public onlyOwner {
		_removeWhitelistAdmin(account);
	}

	function removeMinter(address account) public onlyOwner {
		_removeMinter(account);
	}

	function uri(uint256 _id) public view override returns (string memory) {
		require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
		//return super.uri(_id);
		
		if(bytes(uris[_id]).length > 0){
		    return uris[_id];
		}
		return strings.Strings.strConcat(baseMetadataURI, strings.Strings.uint2str(_id));
	}

	/**
	 * @dev Returns the total quantity for a token ID
	 * @param _id uint256 ID of the token to query
	 * @return amount of token in existence
	 */
	function totalSupply(uint256 _id) public view returns (uint256) {
		return tokenSupply[_id];
	}

	/**
	 * @dev Returns the max quantity for a token ID
	 * @param _id uint256 ID of the token to query
	 * @return amount of token in existence
	 */
	function maxSupply(uint256 _id) public view returns (uint256) {
		return tokenMaxSupply[_id];
	}

	/**
	 * @dev Will update the base URL of token's URI
	 * @param _newBaseMetadataURI New base URL of token's URI
	 */
	function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
		_setBaseMetadataURI(_newBaseMetadataURI);
	}

	/**
	 * @dev Creates a new token type and assigns _initialSupply to an address
	 * @param _maxSupply max supply allowed
	 * @param _initialSupply Optional amount to supply the first owner
	 * @param _uri Optional URI for this token type
	 * @param _data Optional data to pass if receiver is contract
	 * @return tokenId The newly created token ID
	 */
	function create(
		uint256 _maxSupply,
		uint256 _initialSupply,
		string calldata _uri,
		bytes calldata _data
	) external onlyWhitelistAdmin returns (uint256 tokenId) {
		require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
		uint256 _id = _getNextTokenID();
		_incrementTokenTypeId();
		creators[_id] = msg.sender;

		if (bytes(_uri).length > 0) {
		    uris[_id] = _uri;
			emit URI(_uri, _id);
		}
		else{
		    emit URI(string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json")), _id);
		}

		if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
		tokenSupply[_id] = _initialSupply;
		tokenMaxSupply[_id] = _maxSupply;
		return _id;
	}
	
	function updateUri(uint256 _id, string calldata _uri) external onlyWhitelistAdmin{
	    if (bytes(_uri).length > 0) {
		    uris[_id] = _uri;
			emit URI(_uri, _id);
		}
		else{
		    emit URI(string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json")), _id);
		}
	}
	
	function burn(address _address, uint256 _id, uint256 _amount) external {
	    require((msg.sender == _address) || isApprovedForAll(_address, msg.sender), "ERC1155#burn: INVALID_OPERATOR");
	    require(balances[_address][_id] >= _amount, "Trying to burn more tokens than you own");
	    _burn(_address, _id, _amount);
	}
	
	function updateProxyRegistryAddress(address _proxyRegistryAddress) external onlyWhitelistAdmin{
	    require(_proxyRegistryAddress != address(0), "No zero address");
	    proxyRegistryAddress = _proxyRegistryAddress;
	}

	/**
	 * @dev Mints some amount of tokens to an address
	 * @param _id          Token ID to mint
	 * @param _quantity    Amount of tokens to mint
	 * @param _data        Data to pass if receiver is contract
	 */
	function mint(
		uint256 _id,
		uint256 _quantity,
		bytes memory _data
	) public onlyMinter {
		uint256 tokenId = _id;
		require(tokenSupply[tokenId].add(_quantity) <= tokenMaxSupply[tokenId], "Max supply reached");
		_mint(msg.sender, _id, _quantity, _data);
		tokenSupply[_id] = tokenSupply[_id].add(_quantity);
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
	 */
	 /*
	function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator) {
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(_owner)) == _operator) {
			return true;
		}

		return ERC1155.isApprovedForAll(_owner, _operator);
	}*/

	/**
	 * @dev Returns whether the specified token exists by checking to see if it has a creator
	 * @param _id uint256 ID of the token to query the existence of
	 * @return bool whether the token exists
	 */
	function _exists(uint256 _id) internal view returns (bool) {
		return creators[_id] != address(0);
	}

	/**
	 * @dev calculates the next token ID based on value of _currentTokenID
	 * @return uint256 for the next token ID
	 */
	function _getNextTokenID() private view returns (uint256) {
		return _currentTokenID.add(1);
	}

	/**
	 * @dev increments the value of _currentTokenID
	 */
	function _incrementTokenTypeId() private {
		_currentTokenID++;
	}
}

pragma solidity ^0.8.7;

import * as erc1155 from "./ERC1155.sol";
import * as safeMath from "./SafeMath.sol";

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is erc1155.ERC1155 {
  using safeMath.SafeMath for uint256;
  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nBurn = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }

}

pragma solidity ^0.8.7;

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {

  // URI's default URI prefix
  string internal baseMetadataURI;
  event URI(string _uri, uint256 indexed _id);


  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) public view virtual returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  /**
   * @notice Will emit a specific URI log event for corresponding token
   * @param _tokenIDs IDs of the token corresponding to the _uris logged
   * @param _URIs    The URIs of the specified _tokenIDs
   */
  function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
    require(_tokenIDs.length == _URIs.length, "ERC1155Metadata#_logURIs: INVALID_ARRAYS_LENGTH");
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit URI(_URIs[i], _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

  /**
   * @notice Convert uint256 to string
   * @param _i Unsigned integer to convert to string
   */
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = bytes1(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }

}

pragma solidity ^0.8.7;

import * as safemath from "./SafeMath.sol";
import * as addressSol from "./Address.sol";
import * as IERC165Sol from "./IERC165.sol";
import * as ierc1155TokenReceiver from "./IERC1155TokenReceiver.sol";


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165Sol.IERC165 {
  using safemath.SafeMath for uint256;
  using addressSol.Address for address;


  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;

  // Events
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = ierc1155TokenReceiver.IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = ierc1155TokenReceiver.IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

  /**
   * INTERFACE_SIGNATURE_ERC1155 =
   * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
   * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
   * bytes4(keccak256("balanceOf(address,uint256)")) ^
   * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
   * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
   * bytes4(keccak256("isApprovedForAll(address,address)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
        _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }
    return false;
  }

}

pragma solidity ^0.8.7;

interface DetailedERC20 {
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

pragma solidity ^0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.7;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value:value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}