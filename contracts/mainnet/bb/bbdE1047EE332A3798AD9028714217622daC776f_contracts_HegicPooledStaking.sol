// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract HegicPooledStaking is Ownable, ERC20{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // HEGIC token
    IERC20 public immutable HEGIC;

    // Hegic Protocol Staking Contract 
    IHegicStaking public staking;

    // Parameters
    uint public LOCK_UP_PERIOD = 24 hours;
    uint public STAKING_LOT_PRICE = 888_000e18;
    uint public ACCURACY = 1e30;
    address payable public FALLBACK_RECIPIENT;
    address payable public FEE_RECIPIENT;
    uint public FEE;

    // Monitoring variables
    uint public numberOfStakingLots;
    uint public totalBalance;
    uint public lockedBalance;
    uint public totalProfitPerToken;
    bool public emergencyUnlockState;
    bool public depositsAllowed;

    // Staking lots mappings
    mapping(uint => mapping(address => uint)) stakingLotShares;
    mapping(uint => address[]) stakingLotOwners;
    mapping(uint => uint) stakingLotUnlockTime;
    mapping(uint => bool) stakingLotActive;
    mapping(uint => uint) startProfit;

    // Owners mappings
    mapping(address => uint[]) ownedStakingLots; 
    mapping(address => uint) savedProfit; 
    mapping(address => uint) lastProfit; 
    mapping(address => uint) ownerPerformanceFee;

    // Events
    event Deposit(address account, uint amount);
    event Withdraw(address account, uint amount);
    event AddLiquidity(address account, uint amount, uint lotId);
    event BuyLot(address account, uint lotId);
    event SellLot(address account, uint lotId);
    event PayProfit(address account, uint profit, uint fee);

    constructor(IERC20 _token, IHegicStaking _staking, string memory name, string memory symbol) public ERC20(name, symbol){
        HEGIC = _token;
        staking = _staking;
        totalBalance = 0;
        lockedBalance = 0;
        numberOfStakingLots = 0;
        totalProfitPerToken = 0;
        
        FALLBACK_RECIPIENT = msg.sender;
        FEE_RECIPIENT = msg.sender;
        FEE = 5;

        emergencyUnlockState = false;
        depositsAllowed = true;

        // Approving to Staking Lot Contract
        _token.approve(address(_staking), 888e30);
    }

    // Payable 
    receive() external payable {}

    /**
     * @notice Lets the owner deactivate lockUp period. This means that if set to true, 
     * staking lot owners will be able to exitFromStakingLot immediately. 
     * Reserved for emergency cases only (e.g. migration of liquidity).
     * OWNER WILL NOT BE ABLE TO WITHDRAW FUNDS; ONLY UNLOCK FUNDS FOR YOU TO WITHDRAW THEM.
     * @param _unlock true or false, default = false. If set to true, owners will be able to withdraw HEGIC
     * immediately
     */
    function emergencyUnlock(bool _unlock) external onlyOwner {
        emergencyUnlockState = _unlock;
    }

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
    function changeFee(uint _fee) external onlyOwner {
        require(_fee >= 0, "Fee too low");
        require(_fee <= 8, "Fee too high");
        
        FEE = _fee;
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
     * @notice Changes lock up period. This lock up period is used to lock funds in a staking for for at least some time
     * IMPORTANT: Changes only apply to new Staking Lots
     * @param _newLockUpPeriod New lock up period in seconds
     */
    function changeLockUpPeriod(uint _newLockUpPeriod) external onlyOwner {
        require(_newLockUpPeriod <= 2 weeks, "Lock up period too long");
        require(_newLockUpPeriod >= 24 hours, "Lock up period too short");
        LOCK_UP_PERIOD = _newLockUpPeriod;
    }

    /**
     * @notice Main EXTERNAL function. Deposits HEGIC for the next staking lot. 
     * If not enough, deposits will be stored until at least 888_000 HEGIC are available.
     * Then, the contract will buy a Hegic Staking Lot. 
     * Once a Staking Lot is bought, users have to wait LOCK_UP_PERIOD (default = 2 weeks) to withdraw funds.
     * @param _HEGICAmount Amount of HEGIC to deposit in next staking lot
     */
    function deposit(uint _HEGICAmount) external {
        require(_HEGICAmount > 0, "Amount too low");
        require(_HEGICAmount < STAKING_LOT_PRICE, "Amount too high, buy your own lot");
        require(depositsAllowed, "Deposits are not allowed at the moment");

        // set fee for that staking lot owner - this effectively sets the maximum FEE an owner can have
        // each time user deposits, this checks if current fee is higher or lower than previous fees
        // and updates it if it is lower
        if(ownerPerformanceFee[msg.sender] > FEE || balanceOf(msg.sender) == 0) 
            ownerPerformanceFee[msg.sender] = FEE;

        //receive deposit
        depositHegic(_HEGICAmount);

        // use new liquidity (either stores it for next purchase or purchases right away)
        useLiquidity(_HEGICAmount, msg.sender);

        emit Deposit(msg.sender, _HEGICAmount);
    }

    /**
     * @notice Internal function to transfer deposited HEGIC to the contract and mint sHEGIC (Staked HEGIC)
     * @param _HEGICAmount Amount of HEGIC to deposit // Amount of sHEGIC that will be minted
     */
    function depositHegic(uint _HEGICAmount) internal {
        totalBalance = totalBalance.add(_HEGICAmount); 

        _mint(msg.sender, _HEGICAmount);

        HEGIC.safeTransferFrom(msg.sender, address(this), _HEGICAmount);
    }

    /**
     * @notice Use certain amount of liquidity. Internal function in charge of buying a new lot if enough balance.
     * If there is not enough balance to buy a new lot, it will store the HEGIC
     * If available balance + _HEGICAmount is higher than STAKING_LOT_PRICE (888_000HEGIC), the remaining 
     * amount will be stored for the next staking lot purchase. This remaining amount can be withdrawed with no lock up period
     * 
     * @param _HEGICAmount Amount of HEGIC to be used 
     * @param _account Account that owns _HEGICAmount to which any purchase will be credited to
     */
    function useLiquidity(uint _HEGICAmount, address _account) internal {
        if(totalBalance.sub(lockedBalance) >= STAKING_LOT_PRICE){
            uint pendingAmount = totalBalance.sub(lockedBalance).sub(STAKING_LOT_PRICE);
            addToNextLot(_HEGICAmount.sub(pendingAmount), _account); 
            buyStakingLot();
            if(pendingAmount > 0) addToNextLot(pendingAmount, _account);
        } else {
            addToNextLot(_HEGICAmount, _account);
        }
    }

    /**
     * @notice Internal function in charge of buying a new Staking Lot from the Hegic Staking Contract
     * Also, it will set up the Lock up AND increase the number of staking lots
     */
    function buyStakingLot() internal {
        lockedBalance = lockedBalance.add(STAKING_LOT_PRICE);
        staking.buy(1);
        emit BuyLot(msg.sender, numberOfStakingLots);

        startProfit[numberOfStakingLots] = totalProfitPerToken;
        stakingLotUnlockTime[numberOfStakingLots] = now + LOCK_UP_PERIOD;
        stakingLotActive[numberOfStakingLots] = true;

        numberOfStakingLots = numberOfStakingLots + 1;
    }

        /**
     * @notice Internal function in charge of adding the _amount HEGIC to the next lot ledger.
     * User will be added as an owner of the lot and will be credited with _amount shares of that lot (total = 888_000 shares)
     * @param _amount Amount of HEGIC to be used 
     * @param _account Account to which _amount will be credited to
     */
    function addToNextLot(uint _amount, address _account) internal {
        if(stakingLotShares[numberOfStakingLots][_account] == 0) {
            ownedStakingLots[_account].push(numberOfStakingLots); // if first contribution in this lot: add to list
            stakingLotOwners[numberOfStakingLots].push(_account);
        }

        // add to shares in next Staking Lot
        stakingLotShares[numberOfStakingLots][_account] = stakingLotShares[numberOfStakingLots][_account].add(_amount);
        
        emit AddLiquidity(_account, _amount, numberOfStakingLots);
    }

    /**
     * @notice internal function that withdraws HEGIC deposited in exchange of sHEGIC
     * 
     * @param _amount Amount of sHEGIC to be burned // Amount of HEGIC to be received 
     */
    function exchangeStakedForReal(uint _amount) internal {
        totalBalance = totalBalance.sub(_amount);
        _burn(msg.sender, _amount);
        HEGIC.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Main EXTERNAL function. This function is called to exit from a certain Staking Lot
     * Calling this function will result in the withdrawal of allocated HEGIC for msg.sender
     * Owners that are not withdrawing funds will be credited with shares of the next lot to be purchased
     * 
     * @param _slotId Amount of HEGIC to be used 
     */
    function exitFromStakingLot(uint _slotId) external {
        require(stakingLotShares[_slotId][msg.sender] > 0, "Not participating in this lot");
        require(_slotId <= numberOfStakingLots, "Staking lot not found");

        // if HEGIC not yet staked
        if(_slotId == numberOfStakingLots){
            uint shares = stakingLotShares[_slotId][msg.sender];
            stakingLotShares[_slotId][msg.sender] = 0;
            exchangeStakedForReal(shares);
        } else {
            require((stakingLotUnlockTime[_slotId] <= now) || emergencyUnlockState, "Staking Lot is still locked");
            // it is important to withdraw unused funds first to avoid re-ordering attack
            require(stakingLotShares[numberOfStakingLots][msg.sender] == 0, "Please withdraw your non-staked liquidity first");        
            
            // sell lot
            staking.sell(1);
            emit SellLot(msg.sender, _slotId);
            stakingLotActive[_slotId] = false;

            address[] memory slOwners = stakingLotOwners[_slotId];

            // I unlock and withdraw msg.sender funds to avoid using her funds in the for loop
            uint shares = stakingLotShares[_slotId][msg.sender]; 
            stakingLotShares[_slotId][msg.sender] = 0;
            exchangeStakedForReal(shares);
            lockedBalance -= shares;

            address owner;
            for(uint i = 0; i < slOwners.length; i++) {
                owner = slOwners[i];
                shares = stakingLotShares[_slotId][owner];
                stakingLotShares[_slotId][owner] = 0; // put back to 0 the participation in this lot

                // put liquidity into next staking lot OR pay staked Hegic back if msg.sender
                if(owner != msg.sender) {
                    lockedBalance -= shares;
                    saveProfit(owner);
                    useLiquidity(shares, owner);
                }
            }
        }
    }

    /**
     * @notice Virtual function. To be called to claim Profit from Hegic Staking Contracts.
     * It will update profit of current staking lot owners
     */
    function updateProfit() public virtual;

    /**
     * @notice EXTERNAL function. Calling this function will result in receiving profits accumulated
     * during the time the HEGIC were deposited
     * 
     */
    function claimProfit() external {
        uint profit = saveProfit(msg.sender);
        savedProfit[msg.sender] = 0;
        _transferProfit(profit, msg.sender, ownerPerformanceFee[msg.sender]);
        emit PayProfit(msg.sender, profit, ownerPerformanceFee[msg.sender]);
    }

    /**
     * @notice Support function. Calculates how much of the totalProfitPerToken is not to be paid to an account
     * This may be because it was already paid, it was earned before HEGIC were staked, ...
     * 
     * @param _account Amount of HEGIC to be used 
     */
    function getNotPayableProfit(address _account) public view returns (uint notPayableProfit) {
        if(ownedStakingLots[_account].length > 0){
            uint lastStakingLot = ownedStakingLots[_account][ownedStakingLots[_account].length-1];
            uint accountLastProfit = lastProfit[_account];

            if(accountLastProfit <= startProfit[lastStakingLot]) {
                // previous lastProfit * number of shares excluding last contribution (Last Staking Lot) + start Profit of Last Staking Lot
                uint lastTakenProfit = accountLastProfit.mul(balanceOf(_account).sub(stakingLotShares[lastStakingLot][_account]));
                uint initialNotPayableProfit = startProfit[lastStakingLot].mul(stakingLotShares[lastStakingLot][_account]);
                notPayableProfit = lastTakenProfit.add(initialNotPayableProfit);
            } else {
                notPayableProfit = accountLastProfit.mul(balanceOf(_account).sub(getUnlockedTokens(_account)));
            }
        }
    }

    /**
     * @notice Support function. Calculates how many of the deposited tokens are not currently staked
     * These are not producing profits
     * 
     * @param _account Amount of HEGIC to be used 
     */
    function getUnlockedTokens(address _account) public view returns (uint lockedTokens){
         if(ownedStakingLots[_account].length > 0) {
            uint lastStakingLot = ownedStakingLots[_account][ownedStakingLots[_account].length-1];
            if(lastStakingLot == numberOfStakingLots) lockedTokens = stakingLotShares[lastStakingLot][_account];
         }
    }

    /**
     * @notice Support function. Calculates how many of the deposited tokens are not currently staked
     * These are not producing profits and will not be accounted for profit calcs.
     * 
     * @param _account Account 
     */
    function getUnsaved(address _account) public view returns (uint profit) {
        uint accountBalance = balanceOf(_account);
        uint unlockedTokens = getUnlockedTokens(_account);
        uint tokens = accountBalance.sub(unlockedTokens);
        profit = 0;
        if(tokens > 0) 
            profit = totalProfitPerToken.mul(tokens).sub(getNotPayableProfit(_account)).div(ACCURACY);
    }

    /**
     * @notice Support function. Calculates how much profit would receive each token if the contract claimed
     * profit accumulated in Hegic's Staking Lot contracts
     * 
     * @param _account Account to do the calculation to
     */
    function getUnreceivedProfit(address _account) public view returns (uint unreceived){
        uint accountBalance = balanceOf(_account);
        uint unlockedTokens = getUnlockedTokens(_account);
        uint tokens = accountBalance.sub(unlockedTokens);
        uint profit = staking.profitOf(address(this));
        if(lockedBalance > 0)
            unreceived = profit.mul(ACCURACY).div(lockedBalance).mul(tokens).div(ACCURACY);
        else
            unreceived = 0;
    }

    /**
     * @notice EXTERNAL View function. Returns profit to be paid when claimed for _account
     * 
     * @param _account Account 
     */
    function profitOf(address _account) external view returns (uint profit) {
        uint unreceived = getUnreceivedProfit(_account);
        return savedProfit[_account].add(getUnsaved(_account)).add(unreceived);
    }

    /**
     * @notice Internal function that saves unpaid profit to keep accounting.
     * 
     * @param _account Account to save profit to
     */
    function saveProfit(address _account) internal returns (uint profit) {
        updateProfit();
        uint unsaved = getUnsaved(_account);
        lastProfit[_account] = totalProfitPerToken;
        profit = savedProfit[_account].add(unsaved);
        savedProfit[_account] = profit;
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
     * @notice Virtual Internal function. It handles specific code to actually send the profits. 
     * 
     * @param _amount Profit (amount being transferred)
     * @param _account Account receiving profits
     * @param _fee Fee that is being paid to FEE_RECIPIENT (always less than 8%)
     */
    function _transferProfit(uint _amount, address _account, uint _fee) internal virtual;

    /**
     * @notice Public function returning the number of shares that an account holds per specific staking lot
     * 
     * @param _slotId Staking Lot Id
     * @param _account Account
     */
    function getStakingLotShares(uint _slotId, address _account) view public returns (uint) {
        return stakingLotShares[_slotId][_account];
    }

    /**
     * @notice Returns boolean telling if lot is still in lock up period or not
     * 
     * @param _slotId Staking Lot Id
     */
    function isInLockUpPeriod(uint _slotId) view public returns (bool) {
        return !((stakingLotUnlockTime[_slotId] <= now) || emergencyUnlockState);
    }

    /**
     * @notice Returns boolean telling if lot is active or not
     * 
     * @param _slotId Staking Lot Id
     */
    function isActive(uint _slotId) view public returns (bool) {
        return stakingLotActive[_slotId];
    }

    /**
     * @notice Returns list of staking lot owners
     * 
     * @param _slotId Staking Lot Id
     */
    function getLotOwners(uint _slotId) view public returns (address[] memory slOwners) {
        slOwners = stakingLotOwners[_slotId];
    }

    /**
     * @notice Returns performance fee for this specific owner
     * 
     * @param _account Account's address
     */
    function getOwnerPerformanceFee(address _account) view public returns (uint performanceFee) {
        performanceFee = ownerPerformanceFee[_account];
    }


}
