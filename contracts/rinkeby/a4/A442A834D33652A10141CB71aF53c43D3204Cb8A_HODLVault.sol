/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: None
pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @title ERC Token Standard #20 Interface
 * @dev Github: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
abstract contract ERC20 {
    
    uint8 public decimals;
    string public name;
    string public symbol;
    
    function allowance(address owner, address spender) virtual public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    function approve(address spender, uint256 value) virtual public returns (bool);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address who) virtual public view returns (uint256);
    function transfer(address to, uint256 value) virtual public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title HODLVault Contract
 * @author Achala Dissanayake - [email protected]
*/
contract HODLVault {

    enum DepositStatus { CREATED, PARTIALLY_WITHDRAWN, EARLY_WITHDRAWN, WITHDRAWN }
    enum DepositPeriod { WEEK, MONTH, HALF, ONE, THREE, FIVE, TEN}
    uint[] depositPeriodDays = [7, 30, 180, 360, 1080, 1800, 3600];
        
    struct Deposit {
        uint id;
        address owner;
        address token;
        string tokenName;
        uint originalAmount;
        uint depositFee;
        uint depositAmount;
        uint startDate;
        uint maturityDate;
        bool earlyWithdrawal;
        uint withdrawalFee;
        DepositPeriod period;
        DepositStatus status;
    }
    
    struct Withdrawal {
        uint id;
        uint depositId;
        address owner;
        uint startBalance;
        uint withdrawAmount;
        uint withdrawalFee;
        uint endBalance;
        uint bonusAmount;
        uint withdrawDate;
        bool earlyWithdrawal;
        bool partialWithdrawal;
        DepositStatus status; 
    }
    
    uint private depositCount; // Keeps the track of numbers of deposits and decides the id of new deposit
    uint private withdrawalCount; // Keeps the track of numbers of all withdrawals and decides the id of new withdrawal
    uint[] private allDepoistIds; // All deposit ids
    address private feeCollector; // The address to which all the fees are transfered
    address[] private hodlAdminsAddressList; // Address list of current HODL admins
    mapping(address => uint) private hodlAdminsAddressListIndices; // Address to list index mapping for admin - To optimize remove admins
    mapping(uint => Deposit) private deposits; // Maps deposit id to the deposit
    mapping(uint => Withdrawal) private withdrawals; // Maps withdrawal id to the withdrawal
    mapping(address => uint[]) private userWiseDepoistIds; // Maps user address to an array of his deposit ids
    mapping(uint => uint[]) private depositWiseWithdrawalIds; // Maps deposit id to an array of it's withdrawal ids
    mapping(address => uint) private penaltyFeesTokenBalances; // Maps token address to the number of penalty fees pool amount available
    mapping(address => uint) private tokenWiseDepositCount;  // Maps token address to the number of active deposits
    mapping(address => uint) private tokenWiseDepositValue;  // Maps token address to the total value of the active deposits
    mapping(address => uint) private tokenWiseCollectedDepositFees;  // Maps token address to the total value of deposit fees collected
    mapping(address => uint) private tokenWiseCollectedWithdrawalFees;  // Maps token address to the total value of withdrawal fees collected
    mapping(address => uint[]) private tokenWiseDepositIds;  // Maps token address to an array of it's deposit ids
    mapping(address => bool) private hodlAdmins; // HODL admins are the addresses that have the access to HODL Admin DApp
    
    ERC20 SXUTToken  = ERC20(0xDEA27e682Ec1Cc0Ba057D4634010BEc01b0ed6E3);
    uint private bonusEligibleSXUTMinBalance = 1000000000000000000;
    

    event feeCollectorChanged(address indexed oldFeeCollector, address indexed newFeeCollector);
    event newAdminAdded(address indexed newAdmin, address indexed initiator);
    event adminRemoved(address indexed admin, address indexed initiator);
    event depositFeeTranfered(address indexed tokenAdress, address indexed depositer, address indexed feeCollector, uint depositFee);
    event depositCreated(address indexed tokenAdress, address indexed depositer, uint amount);
    event depositPartiallyWithdarwn(uint depositId, address indexed depositer, uint amount);
    event depositWithdarwn(uint depositId, address indexed depositer);
    event bonusEligibleSXUTMinBalanceChanged(uint previousValue, uint newValue, address indexed intiator);

    constructor() {
        depositCount = 0;
        withdrawalCount = 0;
        feeCollector = msg.sender; // Set the contract creator as the fee collector
        hodlAdmins[msg.sender] = true; // Make the contract creator an admin
        hodlAdminsAddressList.push(msg.sender); // Add to the admins list
    }
    
    /**
     * @notice This methood returns the fee collector of the HODLVault
     */
    function getFeeCollector() external view returns (address currentFeeCollector) {
        currentFeeCollector = feeCollector;
    }
    
    
    /**
     * @notice This methood is to change the fee collector of the HODLVault
     * @param newFeeCollector address of the new fee collector
     * @dev requires the function initiator to be the current fee collector and new fee collector should be added as an admin
     */
    function changeFeeCollector(address newFeeCollector) external {
        require(msg.sender == feeCollector, "Only the current fee collector can change the fee collector!");
        address oldFeeCollector = feeCollector;
        feeCollector = newFeeCollector;
        hodlAdmins[newFeeCollector] = true; // Make the new fee collector an admin
        
        emit feeCollectorChanged(oldFeeCollector, newFeeCollector);
        
    }
    
    /**
     * @notice This methood is to add a new admin
     * @param newAdmin address of the new admin
     * @dev requires the function initiator to be an admin
     */
    function addAdmin(address newAdmin) external {
        require(hodlAdmins[msg.sender] == true, "Only a current admin can add a new admin");
        hodlAdmins[newAdmin] = true;
        hodlAdminsAddressList.push(newAdmin);
        hodlAdminsAddressListIndices[newAdmin] = hodlAdminsAddressList.length-1;
        
        emit newAdminAdded(newAdmin, msg.sender);
        
    }
    
    /**
     * @notice This methood is to remove an existing admin
     * @param admin address of the admin to be removed
     * @dev requires the function initiator to be an admin and the admin being removed must not be the fee collector
     */
    function removeAdmin(address admin) external {
        require(hodlAdmins[msg.sender] == true, "Only a current admin can remove an admin");
        require(hodlAdmins[admin] == true, "The address doesn't have admin privilleges"); // This is checked as in indices mapping default is zero which is a valid index
        require(admin != feeCollector, "Current fee collector can't be removed from the admin list");
        hodlAdmins[admin] = false;
        // Remove from the admins list
        uint adminIndex = hodlAdminsAddressListIndices[admin];
        hodlAdminsAddressList[adminIndex] = hodlAdminsAddressList[hodlAdminsAddressList.length-1];
        hodlAdminsAddressList.pop();
        hodlAdminsAddressListIndices[admin] = 0;
        
        emit adminRemoved(admin, msg.sender);
        
    }
    
    /**
     * @notice This methood is to check if an address is an admin
     * @return hodlAdminsList if the address is an admin
     */
    function getAllAdmins() external view returns (address[] memory hodlAdminsList) {
        return hodlAdminsAddressList;
        
    }
    
    /**
     * @notice This methood is to check if an address is an admin
     * @param checkAddress address to be checked
     * @return isAdmin if the address is an admin
     */
    function checkAdmin(address checkAddress) external view returns (bool isAdmin) {
        return hodlAdmins[checkAddress];
        
    }
    
    // TODO: Improvement - Get all Admin (Add admins to a list)

    /**
     * @notice This methood is to change the minimum number of SXUT tokens to be eligible to get bonus tokens
     * @param newValue new value for bonusEligibleSXUTMinBalance
     * @dev requires the function initiator to be the current fee collector
     */
    function changeBonusEligibleSXUTMinBalance(uint newValue) external {
        // require(msg.sender == feeCollector, "Only the current fee collector can change the  minimum number of SXUT tokens to be eligible to get bonus tokens!"); -- changed as any admin can
        require(hodlAdmins[msg.sender] == true, "Only a current admin can change the  minimum number of SXUT tokens to be eligible to get bonus tokens!");
        uint previousValue = bonusEligibleSXUTMinBalance;
        bonusEligibleSXUTMinBalance = newValue;
        
        emit bonusEligibleSXUTMinBalanceChanged(previousValue, bonusEligibleSXUTMinBalance, msg.sender);
        
    }
    
    /**
     * @notice This methood is to get the minimum number of SXUT tokens to be eligible to get bonus tokens
     * @return eligibleBalance minumum amount to be bonus eligible
     */
    function getBonusEligibleSXUTBalance() external view returns (uint eligibleBalance) {
        eligibleBalance = bonusEligibleSXUTMinBalance;
        
    }
    
    /**
     * @notice This methood is to create a deposit in the HODLVault
     * @param tokenAddress address of the ERC20 token of the deposit
     * @param amount no of tokens to be deposited (converted to uint without decimals)
     * @param period the uint value that represent the number of years in DepositPeriod
     * @dev requires the mentioned amount of specified tokens to be transfered from msg.sender to the HODLVault contract and
     *               amount should be equal or higher than 100   
     */
    function createDeposit(address tokenAddress, uint amount, uint period ) external {
        uint depositFee;
        bool accept;
        (depositFee, accept) = calculateDepositFee(amount);
        require(accept, "Token amount is too low!");
        
        ERC20 depositToken  = ERC20(tokenAddress);
        require(depositToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed!");
        depositToken.transfer(feeCollector, depositFee);
        // Add deposit fee value to the token's total deposit fees
        tokenWiseCollectedDepositFees[tokenAddress] += depositFee;
        emit depositFeeTranfered(tokenAddress, msg.sender, feeCollector, depositFee);
        //update all deposit count
        depositCount +=1;
        Deposit memory deposit;
        
        DepositPeriod depositPeriod =  DepositPeriod(period);
        uint startDate = block.timestamp;
        uint periodInDays = depositPeriodDays[uint(depositPeriod)]; // TODO get the value directly from int
        uint maturityDate = startDate + periodInDays * 1 days;
        
        deposit.id = depositCount;
        deposit.owner = msg.sender;
        deposit.token = tokenAddress;
        deposit.tokenName = depositToken.name();
        deposit.originalAmount = amount;
        deposit.depositFee = depositFee;
        deposit.depositAmount = SafeMath.sub(amount, depositFee);
        deposit.startDate = startDate;
        deposit.maturityDate = maturityDate;
        deposit.period = DepositPeriod(period);
        deposit.status = DepositStatus.CREATED;
        
        deposits[depositCount] = deposit;
        userWiseDepoistIds[msg.sender].push(deposit.id);
        //update tokenwise active deposit count
        tokenWiseDepositCount[tokenAddress] +=1;
        //update total active deposits value
        tokenWiseDepositValue[tokenAddress] += deposit.depositAmount;
        //add deposit to the all deposit list
        allDepoistIds.push(deposit.id);
        //add deposit to the token's deposit list
        tokenWiseDepositIds[tokenAddress].push(deposit.id);
        
        emit depositCreated(tokenAddress, msg.sender, amount);
 
    }
    
    /**
     * @notice This methood is to withdraw a deposit in the HODLVault
     * @param depositId id of the deposit to withdraw
     * @param partialWithdraw whether the withdraw is partial or not
     * @param amount no of tokens to be withdrawn if a partial withdraw, 
     *          for full withdrawal this is ignored, but should pass some value to initiate the function
     * @dev requires msg.sender equals to the deposit owner, 
     *               deposit in the CREATED or PARTIALLY_WITHDRAWN status,
     *               partial amounts should not exceed the deposit amount or should not be less than 100
     *               withdrawal Fee and the withdraw amount transfer deposit owner should be successful
     */
    function withdrawDeposit(uint depositId, bool partialWithdraw, uint amount) external {
        Deposit memory deposit = deposits[depositId];
        ERC20 token  = ERC20(deposit.token);
        // uint withdrawAmount;
        uint startBalance = deposit.depositAmount;
        
        require(deposit.owner == msg.sender, "Only the owner can withdraw a deposit");
        require((deposit.status == DepositStatus.CREATED || deposit.status == DepositStatus.PARTIALLY_WITHDRAWN), "Deposit is already withdrawn");
        
        
        if (partialWithdraw) {  
            require((deposit.depositAmount >= amount && amount >= 100), "Amount exceeds deposit amount or amount is too low"); // higher fee precentages will be charged if > 100
            amount = amount;
            deposit.depositAmount -= amount;
        } else {
            amount = deposit.depositAmount;
            deposit.depositAmount = 0;
        }
        (bool earlyWithdrawal, uint fee) = _checkWithdrawal(deposit.maturityDate, deposit.period, amount);
        
        //update total active deposits value
        tokenWiseDepositValue[deposit.token] -= amount;
        
        if (fee <= 0) fee = 1; // To avoid user withdraw without paying any fee by making the withdraw amount low - case  100 < amount < 200
        uint withdrawalFee = fee;
        uint poolFee = 0;
        uint bonusTokens = 0;
        deposit.withdrawalFee += fee;
        
        if (earlyWithdrawal) {
            if  (partialWithdraw && deposit.depositAmount > 0 ) { deposit.status = DepositStatus.PARTIALLY_WITHDRAWN; }
            else { deposit.status = DepositStatus.EARLY_WITHDRAWN; }
            poolFee = fee/2; 
            withdrawalFee = fee - poolFee;
            penaltyFeesTokenBalances[deposit.token] += poolFee;
        } else {
            if  (partialWithdraw && deposit.depositAmount > 0) { deposit.status = DepositStatus.PARTIALLY_WITHDRAWN; }
            else { // bonus tokens are only for full withdrawals
                deposit.status = DepositStatus.WITHDRAWN;
                // uint allBonusTokens = penaltyFeesTokenBalances[deposit.token];
                // uint TotalTokenValue = tokenWiseDepositValue[deposit.token];
                
                if (tokenWiseDepositCount[deposit.token] > 0) {
                    // bonusTokens = SafeMath.div(penaltyFeesTokenBalances[deposit.token], tokenUsers); --- based on number of deposits
                    // bonus Tokens according to amount of tokens withdrawing
                    if(SXUTToken.balanceOf(msg.sender) >= bonusEligibleSXUTMinBalance) { // Check if the user have min SXUT required to get bonus Tokens
                        bonusTokens = SafeMath.div(SafeMath.mul(penaltyFeesTokenBalances[deposit.token], amount) , tokenWiseDepositValue[deposit.token]);
                    }
                    tokenWiseDepositCount[deposit.token] -=1;
                }
                if (penaltyFeesTokenBalances[deposit.token] > 0) {
                    penaltyFeesTokenBalances[deposit.token] -= bonusTokens;
                }
                token.transfer(deposit.owner, bonusTokens); // Transfer eligble bonus amount to the deposit owner
            }
        }
        withdrawalCount +=1;
        Withdrawal memory withdrawal;
        withdrawal.id = withdrawalCount;
        withdrawal.depositId = deposit.id;
        withdrawal.owner = deposit.owner;
        withdrawal.startBalance = startBalance;
        withdrawal.withdrawAmount = amount;
        withdrawal.withdrawalFee = fee;
        withdrawal.endBalance = deposit.depositAmount;
        withdrawal.bonusAmount = bonusTokens;
        withdrawal.withdrawDate = block.timestamp;
        withdrawal.earlyWithdrawal = earlyWithdrawal;
        withdrawal.partialWithdrawal = partialWithdraw;
        withdrawal.status = deposit.status; 
        
        
        require(token.transfer(feeCollector, withdrawalFee), "Couldn't transfer the withdrawal fee"); // Transfer withdrawal fee to the fee collector
        // Add deposit fee value to the token's total deposit fees
        tokenWiseCollectedWithdrawalFees[deposit.token] += withdrawalFee;
        require(token.transfer(deposit.owner, amount - fee), "Deposit token transfer to the owner failed"); // Transfer the remainig deposit amount the deposit owner
        
        deposits[depositId] = deposit;
        withdrawals[withdrawal.id] = withdrawal;
        depositWiseWithdrawalIds[deposit.id].push(withdrawal.id);
    }
    
    /** 
     * @notice This methood is to get the list of all deposit ids
     * @return depositList id list of the msg.sender's deposits
     * @dev requires msg.sender to be an admin
     */
    function getAllDeposits() public view returns (uint[] memory depositList) {
        require(hodlAdmins[msg.sender] == true, "Only a current admin can get all deposits");
        depositList = allDepoistIds;
    }
    
    /** 
     * @notice This methood is to get the value of deposit fees of a token
     * @param  tokenAddress address of the token that need to get the value of collected deposit fees
     * @return collectedDepositFees total value of collected deposit fees of the token
     * @dev requires msg.sender to be an admin
     */
    function getTokenCollectedDepositFees(address tokenAddress) public view returns (uint collectedDepositFees) {
        require(hodlAdmins[msg.sender] == true, "Only a current admin can get all deposits");
        collectedDepositFees = tokenWiseCollectedDepositFees[tokenAddress];
    }
    
    /** 
     * @notice This methood is to get the value of withdrawal fees of a token
     * @param  tokenAddress address of the token that need to get the value of collected withdrawal fees
     * @return collectedWithdrawalFees total value of collected withdrawal fees of the token
     * @dev requires msg.sender to be an admin
     */
    function getTokenCollectedWithdrawalFees(address tokenAddress) public view returns (uint collectedWithdrawalFees) {
        require(hodlAdmins[msg.sender] == true, "Only a current admin can get all deposits");
        collectedWithdrawalFees = tokenWiseCollectedWithdrawalFees[tokenAddress];
    }
    
    /** 
     * @notice This methood is to get the list of deposit ids of a token
     * @param  tokenAddress address of the token that need to get the deposit id list
     * @return depositList id list of the token's deposits
     * @dev requires msg.sender to be an admin
     */
    function getTokenDeposits(address tokenAddress) public view returns (uint[] memory depositList) {
        require(hodlAdmins[msg.sender] == true, "Only a current admin can get token deposits");
        depositList = tokenWiseDepositIds[tokenAddress];
    }
    
    /** 
     * @notice This methood is to get the list of deposit ids of a user
     * @param  userAddress address of the user that need to get the deposit id list
     * @return depositList id list of the user's deposits
     * @dev requires msg.sender to be an admin
     */
    function getUserDeposits(address userAddress) public view returns (uint[] memory depositList) {
        require(hodlAdmins[msg.sender] == true, "Only a current admin can get user deposits");
        depositList = userWiseDepoistIds[userAddress];
    }
    
    /** 
     * @notice This methood is to get the list of deposit ids of the function caller
     * @return depositList id list of the msg.sender's deposits
     */
    function getMyDeposits() public view returns (uint[] memory depositList) {
        depositList = userWiseDepoistIds[msg.sender];
    }
    
    /** 
     * @notice This methood is to get the list of withdrawal of a deposit
     * @param  depositId id of the deposit that need to get the withdrawal list
     * @return withdrawalList id list of the withdrawals of the deposit
     */
    function getWithdrawals(uint depositId) public view returns (uint[] memory withdrawalList) {
        withdrawalList = depositWiseWithdrawalIds[depositId];
    }
    
    /** 
     * @notice This methood is to get the penalties and fees of a deposit
     * @param  depositId id of the deposit that need to get the penalty and fee details
     * @return id of the deposit
     * @return status of the deposit
     * @return depositFee of the deposit
     * @return withdrawalFee of the deposit
     */
    function getFeesAndPenalties(uint depositId) public view returns (uint id, DepositStatus status, uint depositFee, uint withdrawalFee) {
        Deposit memory  deposit = deposits[depositId];
        
        id = deposit.id;
        status = deposit.status;
        depositFee = deposit.depositFee;
        withdrawalFee = deposit.withdrawalFee;
    }
    
    /** 
     * @notice This methood is to get the details of a deposit
     * @param  depositId id of the deposit
     * @return id of the deposit
     * @return owner of the deposit
     * @return token of the deposit
     * @return tokenName of the deposit
     * @return originalAmount of the deposit
     * @return depositAmount of the deposit
     * @return startDate of the deposit
     * @return maturityDate of the deposit
     * @return earlyWithdrawal flag status of the deposit
     * @return period of the deposit
     * @return status of the deposit
     */  
    function getDeposit(uint depositId) external view
        returns(
            uint id,
            address owner,
            address token,
            string memory tokenName,
            uint originalAmount,
            uint depositAmount,
            uint startDate,
            uint maturityDate,
            bool earlyWithdrawal,
            DepositPeriod period,
            DepositStatus status
        ) 
    {
        Deposit memory  deposit = deposits[depositId];
        
        id = deposit.id;
        owner = deposit.owner;
        token = deposit.token;
        tokenName = deposit.tokenName;
        originalAmount = deposit.originalAmount;
        depositAmount = deposit.depositAmount;
        startDate = deposit.startDate;
        maturityDate = deposit.maturityDate;
        earlyWithdrawal = deposit.earlyWithdrawal;
        period = deposit.period;
        status = deposit.status;
    }
    
    /** 
     * @notice This methood is to get the details of a deposit
     * @param  withdrawalId id of the withdrawal
     * @return id of the withdrawal
     * @return owner of the withdrawal
     * @return startBalance of the deposit when withdrawal initiated
     * @return withdrawAmount of the withdrawal
     * @return withdrawalFee of the withdrawal
     * @return endBalance of the withdrawal
     * @return bonusAmount of the withdrawal
     * @return withdrawDate of the withdrawal
     * @return earlyWithdrawal flag status of the withdrawal
     * @return partialWithdrawal flag status of the withdrawal
     * @return status of the deposit when withdrawal finished
     */  
    function getWithdrawal(uint withdrawalId) external view
        returns(
            uint id,
            address owner,
            uint startBalance,
            uint withdrawAmount,
            uint withdrawalFee,
            uint endBalance,
            uint bonusAmount,
            uint withdrawDate,
            bool earlyWithdrawal,
            bool partialWithdrawal,
            DepositStatus status
        ) 
    {
        Withdrawal memory  withdrawal = withdrawals[withdrawalId];
        
        id = withdrawal.id;
        owner = withdrawal.owner;
        startBalance = withdrawal.startBalance;
        withdrawAmount = withdrawal.withdrawAmount;
        withdrawalFee = withdrawal.withdrawalFee;
        endBalance = withdrawal.endBalance;
        bonusAmount = withdrawal.bonusAmount;
        withdrawDate = withdrawal.withdrawDate;
        earlyWithdrawal = withdrawal.earlyWithdrawal;
        partialWithdrawal = withdrawal.partialWithdrawal;
        status = withdrawal.status;
    }
    
    /** 
     * @notice This methood is to calculate the deposit fee at the creation of a deposit
     * @param  tokenAmount number of tokens to be deposited
     * @return fee deposit fee of the deposit to be created
     * @return accept whether to accept the deposit
     */
    function calculateDepositFee(uint tokenAmount) public pure returns (uint fee, bool accept) {
        accept = true;
        if (tokenAmount < 100) { // In this case getting 1 token as the fee would make the fee more than 1% -- setting the upperbound here for fee percenatge here
            accept = false;
            fee = 0;
        } else if ( 100 <= tokenAmount && tokenAmount < 200) { // Fee percentage will be between 0.5% and 1%, charging the minimum amount i.e. 1
            fee = 1;
        } else { // Fee percenatge is 0.5%
            fee = SafeMath.div(tokenAmount, 200); 
            if(SafeMath.mod(tokenAmount, 200) != 0) {
                fee = SafeMath.add(fee, 1);
            }
        }
    }
    
    /** 
     * @notice This method is to check the withdrawal status before withdrawing
     * @param  maturityDate maturity date of the deposit
     * @param  depositPeriod deposit period of the deposit
     * @param  depositAmount amount of the 
     * @return earlyWithdrawal deposit fee of the deposit to be created
     * @return fee whether to accept the deposit
     * @return remainingDays whether to accept the deposit
     */  
    function checkWithdrawal(uint maturityDate, DepositPeriod depositPeriod, uint depositAmount) public view returns (bool earlyWithdrawal, uint fee, uint remainingDays) {
        //TODO use SafeMath
        //TODO take deposit id as input only and get details from it- tried to make the function pure without reading the deposit, couldn't do it as block.timestamp - pass block.timestamp as a parameter?
        earlyWithdrawal = false;
        remainingDays = 0;
        uint today = block.timestamp;
        uint periodInDays = depositPeriodDays[uint(depositPeriod)];
        
        if ( maturityDate > today) {
            earlyWithdrawal = true;
            remainingDays = SafeMath.sub(maturityDate, today)/(60*60*24);
        }
        uint heldDays = SafeMath.sub(periodInDays, remainingDays);
        
        fee = (depositAmount * (500 * periodInDays - 495 * heldDays))/(1000 * periodInDays) ;
    }
    
    /** 
     * @notice This method is to check the withdrawal status before withdrawing
     * @param  maturityDate maturity date of the deposit
     * @param  depositPeriod deposit period of the deposit
     * @param  depositAmount amount of the 
     * @return earlyWithdrawal deposit fee of the deposit to be created
     * @return fee whether to accept the deposit
     */  
    function _checkWithdrawal(uint maturityDate, DepositPeriod depositPeriod, uint depositAmount) private view returns (bool earlyWithdrawal, uint fee) {
        //TODO use SafeMath
        //TODO take deposit id as input only and get details from it- tried to make the function pure without reading the deposit, couldn't do it as block.timestamp - pass block.timestamp as a parameter?
        earlyWithdrawal = false;
        uint remainingDays = 0;
        uint today = block.timestamp;
        uint periodInDays = depositPeriodDays[uint(depositPeriod)];
        
        if ( maturityDate > today) {
            earlyWithdrawal = true;
            remainingDays = SafeMath.sub(maturityDate, today)/(60*60*24);
        }
        uint heldDays = SafeMath.sub(periodInDays, remainingDays);
        
        fee = (depositAmount * (500 * periodInDays - 495 * heldDays))/(1000 * periodInDays) ;
    }

    /** 
     * @notice This method is to get the fees and penalty pool of a token
     * @param  tokenAdress address of the token
     * @return amount penalty pool value of the token
     * @return noOfActiveDeposits no of deposits of the token
     */  
    function getPenaltyPoolDetails(address tokenAdress) public view returns (uint amount, uint noOfActiveDeposits) {
        amount = penaltyFeesTokenBalances[tokenAdress];
        noOfActiveDeposits = tokenWiseDepositCount[tokenAdress];
    }
}