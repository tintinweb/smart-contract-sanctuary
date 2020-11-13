// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract HegicStakingPool is Ownable, ERC20{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // Tokens
    IERC20 public immutable HEGIC;
    IERC20 public immutable WBTC;

    mapping(Asset => IHegicStaking) public staking; 

    uint public STAKING_LOT_PRICE = 888_000e18;
    uint public ACCURACY = 1e32;

    address payable public FALLBACK_RECIPIENT;
    address payable public FEE_RECIPIENT;
    
    uint public DISCOUNTED_LOTS = 10;
    uint public DISCOUNT_FIRST_LOTS = 20000; // 25%
    uint public DISCOUNT_FIRST_LOT = 50000; // 50%

    uint public performanceFee = 5000;
    bool public depositsAllowed = true;
    uint public lockUpPeriod = 15 minutes;

    uint public totalBalance;
    uint public lockedBalance;
    uint public totalNumberOfStakingLots;
    mapping(Asset => uint) public numberOfStakingLots;
    mapping(Asset => uint) public totalProfitPerToken;

    enum Asset {WBTC, ETH}

    address[] owners;
    mapping(address => uint) public ownerPerformanceFee;
    mapping(address => bool) public isNotFirstTime;
    mapping(address => uint) public lastDepositTime;
    mapping(address => mapping(Asset => uint)) lastProfit;
    mapping(address => mapping(Asset => uint)) savedProfit;

    event Deposit(address account, uint amount);
    event Withdraw(address account, uint amount);
    event BuyLot(uint id, Asset asset, address account);
    event SellLot(uint id, Asset asset, address account);
    event ClaimedProfit(address account, Asset asset, uint netProfit, uint fee);

    constructor(IERC20 _HEGIC, IERC20 _WBTC, IHegicStaking _stakingWBTC, IHegicStaking _stakingETH) public ERC20("Staked HEGIC", "sHEGIC"){
        HEGIC = _HEGIC;
        WBTC = _WBTC;
        staking[Asset.WBTC] = _stakingWBTC;
        staking[Asset.ETH] = _stakingETH;

        FEE_RECIPIENT = msg.sender;
        FALLBACK_RECIPIENT = msg.sender;

        // Approving to Staking Lot Contract
        _HEGIC.approve(address(staking[Asset.WBTC]), 888e30);
        _HEGIC.approve(address(staking[Asset.ETH]), 888e30);
    }

    // Payable 
    receive() external payable {}

    /**
     * @notice Stops the ability to add new deposits
     * @param _allow If set to false, new deposits will be rejected
     */
    function allowDeposits(bool _allow) external onlyOwner {
        depositsAllowed = _allow;
    }

    /**
     * @notice Changes Fee paid to creator (only paid when taking profits)
     * @param _fee New fee
     */
    function changePerformanceFee(uint _fee) external onlyOwner {
        require(_fee >= 0, "Fee too low");
        require(_fee <= 8000, "Fee too high");
        
        performanceFee = _fee;
    }

    /**
     * @notice Changes Fee Recipient address
     * @param _recipient New address
     */
    function changeFeeRecipient(address _recipient) external onlyOwner {
        FEE_RECIPIENT = payable(_recipient);
    }

    /**
     * @notice Changes Fallback Recipient address. This is only used in case of unexpected behavior
     * @param _recipient New address
     */
    function changeFallbackRecipient(address _recipient) external onlyOwner {
        FALLBACK_RECIPIENT = payable(_recipient);
    }

    /**
     * @notice Toggles effect of lockup period by setting lockUpPeriod to 0 (disabled) or to 15 minutes(enabled)
     * @param _unlock Boolean: if true, unlocks funds
     */
    function unlockAllFunds(bool _unlock) external onlyOwner {
        if(_unlock) lockUpPeriod = 0;
        else lockUpPeriod = 15 minutes;
    }

    /**
     * @notice Deposits _amount HEGIC in the contract. 
     * 
     * @param _amount Number of HEGIC to deposit in the contract // number of sHEGIC that will be minted
     */
    function deposit(uint _amount) external {
        require(_amount > 0, "Amount too low");
        require(depositsAllowed, "Deposits are not allowed at the moment");
        // set fee for that staking lot owner - this effectively sets the maximum FEE an owner can have
        // each time user deposits, this checks if current fee is higher or lower than previous fees
        // and updates it if it is lower
        if(ownerPerformanceFee[msg.sender] > performanceFee || !isNotFirstTime[msg.sender]) {
            ownerPerformanceFee[msg.sender] = performanceFee;
            // those that deposit in first DISCOUNTED_LOTS lots get a discount
            if(!isNotFirstTime[msg.sender] && totalNumberOfStakingLots < 1){
                ownerPerformanceFee[msg.sender] = ownerPerformanceFee[msg.sender].mul(uint(100000).sub(DISCOUNT_FIRST_LOT)).div(100000);
            } else if(!isNotFirstTime[msg.sender] && totalNumberOfStakingLots < DISCOUNTED_LOTS){
                ownerPerformanceFee[msg.sender] = ownerPerformanceFee[msg.sender].mul(uint(100000).sub(DISCOUNT_FIRST_LOTS)).div(100000);
            }
            isNotFirstTime[msg.sender] = true;
        }
        lastDepositTime[msg.sender] = block.timestamp;
        // receive deposit
        depositHegic(_amount);

        while(totalBalance.sub(lockedBalance) >= STAKING_LOT_PRICE){
            buyStakingLot();
        }
    }

    /**
     * @notice Withdraws _amount HEGIC from the contract. 
     * 
     * @param _amount Number of HEGIC to withdraw from contract // number of sHEGIC that will be burnt
     */
    function withdraw(uint _amount) public {
        require(_amount <= balanceOf(msg.sender), "Not enough balance");
        require(lastDepositTime[msg.sender].add(lockUpPeriod) <= block.timestamp, "You deposited less than 15 mins ago. Your funds are locked");

        while(totalBalance.sub(lockedBalance) < _amount){
            sellStakingLot();
        }

        withdrawHegic(_amount);
    }

    /**
     * @notice Withdraws _amount HEGIC from the contract and claims all profit pending in contract
     * 
     */
    function claimProfitAndWithdraw() external {
        claimAllProfit();
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @notice Claims profit for both assets. Profit will be paid to msg.sender
     * This is the most gas-efficient way to claim profits (instead of separately)
     * 
     */
    function claimAllProfit() public {
        claimProfit(Asset.WBTC);
        claimProfit(Asset.ETH);
    }

    /**
     * @notice Claims profit for specific _asset. Profit will be paid to msg.sender
     * 
     * @param _asset Asset (ETH or WBTC)
     */
    function claimProfit(Asset _asset) public {
        uint profit = saveProfit(msg.sender, _asset);
        savedProfit[msg.sender][_asset] = 0;
        
        _transferProfit(profit, _asset, msg.sender, ownerPerformanceFee[msg.sender]);
    }

    /**
     * @notice Returns profit to be paid when claimed
     * 
     * @param _account Account to get profit for
     * @param _asset Asset (ETH or WBTC)
     */
    function profitOf(address _account, Asset _asset) public view returns (uint profit) {
        return savedProfit[_account][_asset].add(getUnsaved(_account, _asset));
    }

    /**
     * @notice Returns address of Hegic's ETH Staking Lot contract
     */
    function getHegicStakingETH() public view returns (IHegicStaking HegicStakingETH){
        return staking[Asset.ETH];
    }

    /**
     * @notice Returns address of Hegic's WBTC Staking Lot contract
     */
    function getHegicStakingWBTC() public view returns (IHegicStaking HegicStakingWBTC){
        return staking[Asset.WBTC];
    }

    /**
     * @notice Support function. Gets profit that has not been saved (either in Staking Lot contracts)
     * or in this contract
     * 
     * @param _account Account to get unsaved profit for
     * @param _asset Asset (ETH or WBTC)
     */
    function getUnsaved(address _account, Asset _asset) public view returns (uint profit) {
        profit = totalProfitPerToken[_asset].sub(lastProfit[_account][_asset]).add(getUnreceivedProfitPerToken(_asset)).mul(balanceOf(_account)).div(ACCURACY);
    }

    /**
     * @notice Internal function. Update profit per token for _asset
     * 
     * @param _asset Underlying asset (ETH or WBTC)
     */
    function updateProfit(Asset _asset) internal {
        uint profit;
        profit = staking[_asset].profitOf(address(this));
        if(profit > 0) staking[_asset].claimProfit();
        
        if(totalBalance <= 0) {
            if(_asset == Asset.ETH) FALLBACK_RECIPIENT.transfer(profit);
            else if(_asset == Asset.WBTC) WBTC.safeTransfer(FALLBACK_RECIPIENT, profit);
        } else totalProfitPerToken[_asset] = totalProfitPerToken[_asset].add(profit.mul(ACCURACY).div(totalBalance));
    }

    /**
     * @notice Internal function. Transfers net profit to the owner of the sHEGIC. 
     * 
     * @param _amount Amount of Asset (ETH or WBTC) to be sent
     * @param _asset Asset to be sent (ETH or WBTC)
     * @param _account Receiver of the net profit
     * @param _fee Fee % to be applied to the profit (100% = 100000)
     */
    function _transferProfit(uint _amount, Asset _asset, address _account, uint _fee) internal {
        uint netProfit = _amount.mul(uint(100000).sub(_fee)).div(100000);
        uint fee = _amount.sub(netProfit);

        if(_asset == Asset.ETH){
            payable(_account).transfer(netProfit);
            FEE_RECIPIENT.transfer(fee);
        } else if (_asset == Asset.WBTC) {
            WBTC.safeTransfer(_account, netProfit);
            WBTC.safeTransfer(FEE_RECIPIENT, fee);
        }
        emit ClaimedProfit(_account, _asset, netProfit, fee);
    }

    /**
     * @notice Internal function to transfer deposited HEGIC to the contract and mint sHEGIC (Staked HEGIC)
     * @param _amount Amount of HEGIC to deposit // Amount of sHEGIC that will be minted
     */
    function depositHegic(uint _amount) internal {
        totalBalance = totalBalance.add(_amount); 

        HEGIC.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount);
    }

    /**
     * @notice Internal function. Moves _amount HEGIC from contract to user
     * also burns staked HEGIC (sHEGIC) tokens
     * @param _amount Amount of HEGIC to withdraw // Amount of sHEGIC that will be burned
     */
    function withdrawHegic(uint _amount) internal {

        emit Withdraw(msg.sender, _amount);

        _burn(msg.sender, _amount);
        HEGIC.safeTransfer(msg.sender, _amount);
        totalBalance = totalBalance.sub(_amount);
    }

    /**
     * @notice Internal function. Chooses which lot to buy (ETH or WBTC) and buys it
     *
     */
    function buyStakingLot() internal {
        // we buy 1 ETH staking lot, then 1 WBTC staking lot, then 1 eth, ...
        Asset asset = Asset.ETH;
        if(numberOfStakingLots[Asset.ETH] > numberOfStakingLots[Asset.WBTC]){
            asset = Asset.WBTC;
        }

        if(staking[asset].totalSupply() == staking[asset].MAX_SUPPLY()){
            if(asset == Asset.ETH) asset = Asset.WBTC;
            else asset = Asset.ETH;
        }

        require(staking[asset].totalSupply() < staking[asset].MAX_SUPPLY(), "There are no more available lots for purchase");

        lockedBalance = lockedBalance.add(STAKING_LOT_PRICE);
        staking[asset].buy(1);
        emit BuyLot(block.timestamp, asset, msg.sender);
        totalNumberOfStakingLots++;
        numberOfStakingLots[asset]++;
    }

    /**
     * @notice Internal function. Chooses which lot to sell (ETH or WBTC) and sells it
     *
     */
    function sellStakingLot() internal {
        Asset asset = Asset.ETH;
        if(numberOfStakingLots[Asset.ETH] < numberOfStakingLots[Asset.WBTC]){
            asset = Asset.WBTC;
        }

        // I check if the staking lot to be sold is locked by HEGIC.
        // if it is, I try switching underlying asset (which should be the previously bought lot). 
        if(staking[asset].lastBoughtTimestamp(address(this))
                .add(staking[asset].lockupPeriod()) > block.timestamp){
            if(asset == Asset.ETH) asset = Asset.WBTC;
            else asset = Asset.ETH;
        }
        
        if(staking[asset].balanceOf(address(this)) == 0){
            if(asset == Asset.ETH) asset = Asset.WBTC;
            else asset = Asset.ETH;
        }

        require(
            staking[asset].lastBoughtTimestamp(address(this))
                .add(staking[asset].lockupPeriod()) <= block.timestamp,
             "Lot sale is locked by Hegic. Funds should be available in less than 24h"
        );

        lockedBalance = lockedBalance.sub(STAKING_LOT_PRICE);
        staking[asset].sell(1);
        emit SellLot(block.timestamp, asset, msg.sender);
        totalNumberOfStakingLots--;
        numberOfStakingLots[asset]--;
    }

    /**
     * @notice Support function. Calculates how much profit would receive each token if the contract claimed
     * profit accumulated in Hegic's Staking Lot contracts
     * 
     * @param _asset Asset (WBTC or ETH)
     */
    function getUnreceivedProfitPerToken(Asset _asset) public view returns (uint unreceivedProfitPerToken){
        uint profit = staking[_asset].profitOf(address(this));
        
        unreceivedProfitPerToken = profit.mul(ACCURACY).div(totalBalance);
    }

    /**
     * @notice Saves profit for a certain _account. This profit is absolute in value
     * this function is called before every token transfer to keep the state of profits correctly
     * 
     * @param _account account to save profit to
     */
    function saveProfit(address _account) internal {
        saveProfit(_account, Asset.WBTC);
        saveProfit(_account, Asset.ETH);
    }

    /**
     * @notice Internal function that saves unpaid profit to keep accounting.
     * 
     * @param _account Account to save profit to
     * @param _asset Asset (WBTC or ETH)     
     */
    function saveProfit(address _account, Asset _asset) internal returns (uint profit) {
        updateProfit(_asset);
        uint unsaved = getUnsaved(_account, _asset);
        lastProfit[_account][_asset] = totalProfitPerToken[_asset];
        profit = savedProfit[_account][_asset].add(unsaved);
        savedProfit[_account][_asset] = profit;
    }

    /**
     * @notice Support function. Relevant to the profit system. It will save state of profit before each 
     * token transfer (either deposit or withdrawal)
     * 
     * @param from Account sending tokens 
     * @param to Account receiving tokens
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (from != address(0)) saveProfit(from);
        if (to != address(0)) saveProfit(to);
    }

    /**
     * @notice Returns a boolean indicating if that specific _account can withdraw or not
     * (due to lockupperiod reasons)
     * @param _account Account to check withdrawal status 
     */
    function canWithdraw(address _account) public view returns (bool) {
        return (lastDepositTime[_account].add(lockUpPeriod) <= block.timestamp);
    }
}
