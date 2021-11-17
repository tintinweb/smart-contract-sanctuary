/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: none
pragma solidity ^0.6.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "SafeMath: subtraction overflow");
    }

    function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return _div(a, b, "SafeMath: division by zero");
    }

    function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mod(a, b, "SafeMath: modulo by zero");
    }

    function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.5.0;


interface ILitedexTimelockVIP {
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
        
        function initialize(address _lockToken, uint256 _vestingPeriod, address _lastVIP) external returns(bool);
        function setTimeForUnlocked(uint256 time) external returns(bool);
        function locked(address account, uint256 amount) external returns(bool);
        function unlocked() external returns(bool);
        function setVestingPeriod(uint256 _vesting) external returns (bool);
        function setUnlockPeriod(uint256 uid, uint256 time) external returns (uint256);
        function setWithdrawPercentage(uint256 uid, uint256 percentage) external returns (uint256);
        function emergencyWithdraw() external returns (bool);
        function setConfig(string memory names, string memory symbols) external returns(bool);
        function setVestingTime(uint256 time) external returns (bool);
        function setTokenVIP(address _lastVIP) external returns (bool);
        function setMigrateOn(bool status) external returns(bool);
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns(uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating wether the operation succeeded.
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
     * Returns a boolean value indicating wether the operation succeeded.
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

contract Ownable {
    /***
     * Configurator Crowdsale Contract
     */
    address payable internal owner;
    address payable internal admin;

    struct userData {
        bool isApproved;
        uint256 totalPurchased;
    }
    struct admins {
        address account;
        bool isApproved;
    }

    mapping (uint256 => mapping (address => userData)) public userInfo;
    mapping (address => admins) private roleAdmins;

    modifier onlyOwner {
        require(msg.sender == owner, 'Litedex: Only Owner'); 
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == roleAdmins[msg.sender].account && roleAdmins[msg.sender].isApproved == true || msg.sender == owner, 'Litedex: Only Owner or Admin');
        _;
    }
    
    /**
     * Event for Transfer Ownership
     * @param previousOwner : owner Crowdsale contract
     * @param newOwner : New Owner of Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 time);
    

    function setAdmin(address payable account, bool status) external onlyOwner returns(bool){
        require(account != address(0), 'Litedex: account is zero address');
        roleAdmins[account].account = account;
        roleAdmins[account].isApproved = status;
    }
    /**
     * Function to change Crowdsale contract Owner
     * Only Owner who could access this function
     * 
     * return event OwnershipTransferred
     */
    
    function transferOwnership(address payable _owner) onlyOwner external returns(bool) {
        owner = _owner;
        
        emit OwnershipTransferred(msg.sender, _owner, block.timestamp);
        return true;
    }

    constructor() internal{
        owner = msg.sender;
    }
}

contract TimeCrowdsale is Ownable {
    uint internal _start;
    uint internal _end;
    
    /**
     * Event shown after change Opening Time 
     * @param owner : who owner this contract
     * @param openingtime : time when the Crowdsale started
     */
    event openingTime(address indexed owner, uint256 openingtime);
    
    /**
     * Event shown after change Closing Time
     * @param owner : who owner this contract
     * @param closingtime : time when the Crowdsale Ended
     */
    event closingTime(address indexed owner, uint256 closingtime);
    
    modifier onlyWhileNotOpen {
        if(getStartedTime() > 0 && getEndedTime() > 0){
            require(getBlockTimestamp() < getStartedTime() || getBlockTimestamp() > getEndedTime(), 'Litedex: private sale is already started');
        }
        _;
    }
    
    modifier onlyWhileOpen {
        require(getStartedTime() > 0 && getEndedTime() > 0, 'Litedex: time is not initialized');
        require(getBlockTimestamp() >= getStartedTime() && getBlockTimestamp() <= getEndedTime(), 'Litedex: private sale is not started');
        _;
    }
    
    /**
     * function to get started time
     */
    
    function getStartedTime() public view returns(uint256){
        return _start;
    }
    
    /**
     * function to get ended time
     */
    
    function getEndedTime() public view returns(uint256){
        return _end;
    }
    
    /**
     * function to get current time
     */
    
    function getBlockTimestamp() internal view returns(uint256){
        return block.timestamp;
    }
    
    /**
     * function to set time for private sale
     */
    
    function setPresaleTime(uint256 start_time, uint256 end_time) external onlyOwner onlyWhileNotOpen returns(uint256 startTime, uint256 endTime){
        require(end_time > getStartedTime() && start_time > 0 && end_time > 0, 'Litedex: time is invalid');
        _start = start_time;
        _end = end_time;
        
        emit openingTime(owner, start_time);
        emit closingTime(owner, end_time);
        return (_start, _end);
    }
    
    function setStartTime(uint256 time) external onlyOwner returns(uint256){
        require(time > 0, 'Litedex: time is invalid');
        require(time < getEndedTime(), 'Litedex: time is higher than end time');
        _start = time;
        
        emit openingTime(owner, time);
        return _start;
    }
    
    function setEndTime(uint256 time) external onlyOwner returns(uint256){
        require(time > 0, 'Litedex: time is invalid');
        require(time > getStartedTime() , 'Litedex: time is lower than start time');
        _end = time;
        
        emit closingTime(owner, time);
        return _end;
    }
}
interface IPrivateSale {
    function getTokenSold(uint groupid) external view returns(uint256);
    function getTokenAvailable(uint256 groupid) external view returns(uint256);
    function getTotalReceived(uint groupid) external view returns(uint256);
    function getTotalRoles() external view returns(uint256);
}

contract UpgradedLitedexPrivatesale is TimeCrowdsale{
    using SafeMath for uint256;

    struct Token {
        address tokenAddress;
    }

    /***
     * Token Address for Crowdsale Contract
     */
    IBEP20 private token;
    uint private rolesid;
    address private tl;
    
    /***
     * Crowdsale Information for retail
     */
    
    struct parameters{
        uint256 min_contribution;
        uint256 max_contribution;
        uint256 total_cap;
        uint256 price;
        uint256 token_available;
        uint256 total_received;
        uint256 token_sold;
        uint256 stakedUSD;
        address payable fundraiser;
        bool useLot;
        bool isLocked;
    }
    
    /***
     * Participant Information
     */
    mapping (uint256 => parameters) private Param;
    mapping (uint256 => Token) public tokenApproved;

    address[] private tokenList;
    mapping (uint256 => uint256) private useLot;

    /**
     * Event for token purchase logging
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event purchased(address indexed purchaser, uint256 amount);
    /***
     * Event for Initializing Crowdsale Contract
     * @param min_contribution : min contribution for retails in Crowdsale
     * @param minContributionForLock : min contribution for locking investor
     * @param cap : goals for the private sale for retails
     * @param capForLock: goals for the locking private sale
     * @param price : initial price of Crowdsale for retails
     * @param priceForLock : initial price for locking investor
     */
    event addRoleTransactor(
        uint256 roleid,
        uint256 min_contribution, 
        uint256 max_contribution,
        uint256 cap,
        uint256 price
    );

    /**
     * Constructor of Litedex Crowdsale Contract
     */
    
    constructor(address _tokenAddress, address _pairAddress, address lastVip) public {
        token = IBEP20(_tokenAddress);
        tokenApproved[0].tokenAddress = _pairAddress;
        tokenList.push(_pairAddress);
        
        bytes memory bytecode = type(LitedexTimelockVVIP).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_tokenAddress,_pairAddress));
        address timelock;
        assembly {
            timelock := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ILitedexTimelockVIP(timelock).initialize(_tokenAddress, 9, lastVip);
        
        tl = timelock;
    }
    function setLastTokenVIP(address _lastVIP) external returns (bool){
        require(_lastVIP != address(0), 'address is zero address');
        ILitedexTimelockVIP(tl).setTokenVIP(_lastVIP);
        return true;
    }
    function getUsingLot(uint256 gid) external view returns(bool){
        return Param[gid].useLot;
    }
    function setUsingLot(uint256 gid, bool status) external onlyOwner returns(bool){
        Param[gid].useLot = status;
        return Param[gid].useLot;
    }
    function setMigrateOns(bool status) external onlyOwner returns(bool){
        ILitedexTimelockVIP(tl).setMigrateOn(status);
        return true;
    }
    function emergencyWithdraws() external onlyOwner returns(bool){
        ILitedexTimelockVIP(tl).emergencyWithdraw();
        return true;
    }
    function getTotalRoles() external view returns(uint256){
        return rolesid;
    }
    function setWhitelist(uint groupid, address account, bool status) external onlyAdmin returns(bool){
        require(account != address(0), 'Litedex: account is zero address');
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        
        userInfo[groupid][account].isApproved = status;
        
        return true;
    }
    function setUnlockedTimeForVIP(uint256 time) external onlyOwner returns(bool){
        require(time > block.timestamp, 'Litedex: Time was gone');
        ILitedexTimelockVIP(tl).setTimeForUnlocked(time);
        return true;
    }
    
    function setVestingPeriodForVIP(uint256 _vesting) external onlyOwner returns (bool){
        ILitedexTimelockVIP(tl).setVestingPeriod(_vesting);
        return true;
    }
    function setUnlockPeriodForVIP(uint256 uid, uint256 time) external onlyOwner returns (bool){
        ILitedexTimelockVIP(tl).setUnlockPeriod(uid,time);
        return true;
    }
    function setWithdrawPercentageForVIP(uint256 uid, uint256 percentage) external onlyOwner returns (bool){
        ILitedexTimelockVIP(tl).setWithdrawPercentage(uid,percentage);
        return true;
    }
    function setConfigs(string memory names, string memory symbols) external onlyOwner returns(bool){
        ILitedexTimelockVIP(tl).setConfig(names, symbols);
        return true;
    }
    function setVestingTime(uint256 time) external onlyOwner returns(uint256){
        ILitedexTimelockVIP(tl).setVestingTime(time);
        return time;
    }
    
    function getTimelockVIP() external view returns(address){
        return tl;
    }
    
    /**
     * Function for Initialize default configuration of Crowdsale
     */
    function addRolesTransactor(
        uint256 minContribution,
        uint256 maxContribution,
        uint256 initialCap,
        uint256 initialPrice,
        address payable fundraiser,
        bool isLocked
    ) external onlyOwner returns(bool) {
        require(minContribution > 0, "Litedex: min_contribution must higher than 0");
        rolesid += 1;
        Param[rolesid].min_contribution = minContribution;
        Param[rolesid].max_contribution = maxContribution;
        
        require(initialPrice > 0, "Litedex: initial price must higher than 0");
        Param[rolesid].price = initialPrice;

        require(initialCap > 0, "Litedex: total cap must higher than 0");
        Param[rolesid].total_cap = initialCap;
        Param[rolesid].token_available += initialCap;
        Param[rolesid].fundraiser = fundraiser;
        Param[rolesid].useLot = false;
        Param[rolesid].isLocked = isLocked;
        
        emit addRoleTransactor(rolesid, minContribution, maxContribution, initialCap, initialPrice);
        return true;
    }
    
    /**
     * function to add new stable coin pair
     */

    function addNewPair(address tokenAddress) external onlyOwner returns(bool) {
        require(tokenAddress != address(0), 'Litedex: token is zero address');
        uint256 currentId = tokenList.length;
        tokenApproved[currentId].tokenAddress = tokenAddress;
        tokenList.push(tokenAddress);
        return true;
    }
    /**
     * Function to set fundraiser
     */
    
    function setFundraiser(uint groupid, address payable _newFundraiser) external onlyOwner returns(bool){
        require(_newFundraiser != address(0));
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        Param[groupid].fundraiser = _newFundraiser;
        return true;
    }
    
    /**
     * Function for Purchase Token on Crowdsale
     * @param pid : pair id which user spent to purchase
     * @param amount : amount which user purchase
     * 
     * return deliveryTokens
     */
    
    function purchase(uint gid, uint256 pid, uint256 amount) external onlyWhileOpen returns(bool){
        require(tokenApproved[pid].tokenAddress != address(0), "Litedex: pid is not available");
        require(gid >= 1 && gid <= rolesid, 'Litedex: groupid is not found');
        require(userInfo[gid][msg.sender].isApproved == true, 'Litedex: you dont have authority to purchase');
        
        require(userInfo[gid][msg.sender].totalPurchased < getMaxContribution(gid) , 'Litedex: your account has reached limit of presale');
        uint256 tokenReached;
        uint256 amounts;
        
        IBEP20 _pair = IBEP20(tokenApproved[pid].tokenAddress);
        uint256 _tokendecimals = _pair.decimals();
        
        tokenReached = getEstimateToken(gid, amount);
        if(userInfo[gid][msg.sender].totalPurchased.add(amount) > getMaxContribution(gid)){
            tokenReached = getMaxContribution(gid).sub(userInfo[gid][msg.sender].totalPurchased).div(getCurrentPrice(gid)).mul(1e18);
        }
        amounts = tokenReached.mul(getCurrentPrice(gid)).div(10 ** _tokendecimals);
        
        
        if(Param[gid].useLot == true){
            uint256 denom = amounts % (20000 * 1e18);
            amounts -= denom;
        }
        
        Param[gid].stakedUSD = Param[gid].stakedUSD.add(amounts);
        _pair.transferFrom(msg.sender, address(this), amounts);
        _pair.transfer(Param[gid].fundraiser, amounts);

        Param[gid].total_received = Param[gid].stakedUSD;
        Param[gid].token_sold = getTokenSold(gid).add(tokenReached);
        Param[gid].token_available = getTokenAvailable(gid).sub(tokenReached);
        
        if(Param[gid].isLocked != true){
            token.transfer(msg.sender, tokenReached);
        }else{
            if(Param[gid].useLot == true){
                uint256 denom = tokenReached % (400000 * 1e18);
                tokenReached -= denom;
            }
            
            ILitedexTimelockVIP(tl).locked(msg.sender, tokenReached);
            token.transfer(tl, tokenReached);
        }
        
        userInfo[gid][msg.sender].totalPurchased = userInfo[gid][msg.sender].totalPurchased.add(amounts);
        
        emit purchased(msg.sender, tokenReached);
        return true;
    }

    /**
     * Function for Estimate token which user get on Crowdsale
     * @param _amount : amount which user purchase
     * return token_amount type uint256
     */
    function getEstimateToken(uint groupid, uint256 _amount) public view returns(uint256) {
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        require(_amount >= getMinContribution(groupid) && _amount <= getMaxContribution(groupid), "Litedex: amount is lower than min contribution");
        require(getCurrentPrice(groupid) > 0, 'Litedex: Price is not initialized');
        require(getTokenSold(groupid)< getTotalCap(groupid), 'Litedex: total cap has reached');

        uint256 tokendecimal = token.decimals(); //18
        uint256 estimateToken;
        
        estimateToken = _amount.mul(10 ** tokendecimal).div(getCurrentPrice(groupid));
        if(estimateToken >= getTotalCap(groupid).sub(getTokenSold(groupid))){
            estimateToken = getTotalCap(groupid).sub(getTokenSold(groupid));
        }
        
        require(estimateToken > 0, "Litedex: calculating error!");
        return estimateToken;
    }

    
    /**
     * function to increase total cap
     */
    function increaseTotalCap(uint groupid, uint256 cap) onlyOwner external returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        Param[groupid].total_cap = Param[groupid].total_cap.add(cap);
        Param[groupid].token_available = Param[groupid].token_available.add(cap); 
        
        return Param[groupid].total_cap;
    }
    
    /**
     * function to decrease total cap
     */
    function decreaseTotalCap(uint groupid, uint256 cap) onlyOwner external returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        Param[groupid].total_cap = Param[groupid].total_cap.sub(cap);
        Param[groupid].token_available = (Param[groupid].token_available > cap) ? Param[groupid].token_available.sub(cap) : 0;
        
        return Param[groupid].total_cap;
    }
    
    /**
     * Function for setting current min contribution
     * 
     * return true
     */
    function setMinContribution(uint groupid, uint256 minContribution) onlyOwner external returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        Param[groupid].min_contribution = minContribution;
        
        return minContribution;
    }
    /**
     * Function for setting current price
     * 
     * return true
     */
    function setPrice(uint groupid, uint256 newPrice) onlyOwner external returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        Param[groupid].price = newPrice;
        
        return Param[groupid].price; 
    }
    
    /**
     * Function for getting current price in usd
     * 
     * return price (uint256)
     */
    
    function getCurrentPrice(uint groupid) public view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].price;
    }
    
    /**
     * Function for get total stable coin (BUSD,USDT,etc) received in contract
     */

    function getTotalUSDReceived(uint groupid) external view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].stakedUSD;
    }
    
    /**
     * Function for getting current total received
     * 
     * return total_received (uint256)
     */
    
    function getTotalReceived(uint groupid) public view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].stakedUSD;
    }
    
    /**
     * Function for getting current min contribution
     * 
     * return min_contribution (uint256)
     */
    
    function getMinContribution(uint groupid) public view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].min_contribution;
    }

    /**
     * Function for getting current max contribution
     * 
     * return max_contribution (uint256)
     */
    
    function getMaxContribution(uint256 groupid) public view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].max_contribution;
    }
    
    /**
     * Function for getting current token available
     * 
     * return token_available (uint256)
     */
    
    function getTokenAvailable(uint256 groupid) public view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].token_available;
    }
    
    /**
     * Function for getting current total cap
     * 
     * return cap (uint256)
     */
    
    function getTotalCap(uint groupid) public view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].total_cap;
        
    }
    
    /**
     * Function for getting current token told
     * 
     */
    
    function getTokenSold(uint groupid) public view returns(uint256){
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        return Param[groupid].token_sold;
    }
    
    /**
     * Function to withdraw ldx token after private sale
     */
    
    function withdrawLDX(uint groupid) external onlyOwner {
        require(groupid >= 1 && groupid <= rolesid, 'Litedex: groupid is not found');
        if(token.balanceOf(address(this)) > getTokenAvailable(groupid)){
            token.transfer(owner, token.balanceOf(address(this)).sub(getTokenAvailable(groupid)));
        }else{
            require(getBlockTimestamp() > getEndedTime(), 'Litedex: private sale is already started');
            token.transfer(owner, token.balanceOf(address(this)));
        }
    }
    
    /**
     * Function to recover stuck tokens in contract
     */
    
    function recoverStuckToken(address to, address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0) && to != address(0));
        IBEP20 _token = IBEP20(tokenAddress);
        _token.transfer(to, _token.balanceOf(address(this)));
    }
    
    /**
     * Function to recover stuck BNB in contract
     */

    function recoverStuckBNB() external onlyOwner {
        return safeTransferBNB(owner, address(this).balance);
    }
    
    /**
     * Functions safeTransfer BNB
     * 
     */
    
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'Litedex: BNB_TRANSFER_FAILED');
    }
}

abstract contract BEP20 is IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }
    function _setName(string memory name) internal returns (string memory){
        _name = name;
    }
    function _setSymbol(string memory symbol) internal returns (string memory){
        _symbol = symbol;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

}

contract LitedexTimelockVVIP is BEP20("Litedex VVIP","LDX-VVIP") {
        using SafeMath for uint;
        address private presaleFactory;
        address private lockToken;
        uint256 private unlockedTime;
        uint256 private defaultPercentage = 20;
        uint256 private vestingPeriod;
        uint256 private currentPhasePeriod;
        uint256 private vestingTime = 30 days;
        address private lastVIP;
        bool private migrateStatus = true;
        
        struct vestingRules{
            uint256 timeUnlock;
            uint256 wdPercentage;
        }
        
        struct userData{
            uint256 totalLock;
            uint256 alreadyRedeem;
            uint256 lastRedeem;
        }
        
        mapping (uint256 => vestingRules) public vesting;
        mapping (address => userData) public user;
    
        event Mint(address indexed sender, uint amountLocked);
        event Burn(address indexed sender, uint amountLocked, address indexed to);
        
        modifier whileOpen {
            require(block.timestamp > unlockedTime);
            _;
        }
        modifier whenMigrateOn {
            require(migrateStatus = true, "litedex: migrate doesnt on");
            _;
        }
        constructor() public {
            presaleFactory = msg.sender;
        }
        function setConfig(string memory _names, string memory _symbols) external returns (bool) {
            require(msg.sender == presaleFactory, "Litedex: Forbidden");
            _setName(_names);
            _setSymbol(_symbols);
            
            return true;
        }
        function setVestingTime(uint256 time) external returns (bool){
            require(msg.sender == presaleFactory, "Litedex: Forbidden");
            vestingTime = time;
            for(uint i = 1; i<=vestingPeriod;i++){
                vesting[i].timeUnlock = (i==1) ? unlockedTime : unlockedTime.add(i.mul(vestingTime));
            }
            return true;
        }
        
        function getCurrentPhasePeriod() public view returns(uint256){
            if(block.timestamp >= unlockedTime){
                for(uint i=1;i<=vestingPeriod;i++){
                    if(block.timestamp >= unlockedTime && block.timestamp <= unlockedTime.add(i.mul(vestingTime))){
                        return i;
                    }else if(block.timestamp >= unlockedTime.add(i.mul(vestingTime)) && block.timestamp <= unlockedTime.add((i.add(1)).mul(vestingTime))){
                        return i++;
                    }
                }
            }else{
                return 0;
            }
        }
        
        function getFactory() external view returns(address){
            return presaleFactory;
        }
        function getLockedToken() external view returns(address){
            return lockToken;
        }
        function getUnlockedTime() external view returns(uint256){
            return unlockedTime;
        }
        function getVestingPeriod() public view returns(uint256){
            return vestingPeriod;
        }
        function getMaxVesting() public view returns(uint256){
            uint256 _acc;
            for(uint i=1;i<=getCurrentPhasePeriod();i++){
                _acc += vesting[i].wdPercentage;
            }
            
            return _acc;
        }
        function getTotalPercentage() public view returns(uint256){
            uint256 acc;
            for(uint256 i=1;i<=vestingPeriod;i++){
                acc+=vesting[i].wdPercentage;
            }
            return acc;
        }
    
        // called once by the factory at time of deployment
        function initialize(address _lockToken, uint256 _vestingPeriod, address _lastVIP) external returns(bool){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden'); // sufficient check
            lastVIP = _lastVIP;
            vestingPeriod = _vestingPeriod;
            unlockedTime = 1658682000;
            lockToken = _lockToken;
            
            for(uint i = 1; i<=vestingPeriod;i++){
                vesting[i].timeUnlock = (i==1) ? unlockedTime : unlockedTime.add((i.sub(1)).mul(vestingTime));
                vesting[i].wdPercentage = (i==1) ? defaultPercentage : 10; 
            }
            return true;
        }
        function emergencyWithdraw() external returns(bool){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            IBEP20(lockToken).transfer(presaleFactory, balanceOf(address(this)));
            return true;
        }
        function setVestingPeriod(uint256 _vesting) external returns (bool){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            vestingPeriod = _vesting;
            return true;
        }
        function setUnlockPeriod(uint256 uid, uint256 time) external returns (uint256){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            require(time > block.timestamp, 'Litedex: time was gone');
            vesting[uid].timeUnlock = time;
            return time;
        }
        function setWithdrawPercentage(uint256 uid, uint256 percentage) external returns (uint256){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            vesting[uid].wdPercentage = percentage;
            return percentage;
        }
        function setTimeForUnlocked(uint256 time) external returns(bool){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            require(time > block.timestamp, 'Litedex: time was gone');
            unlockedTime = time;
            return true;
        }
        function setTokenVIP(address _lastVIP) external returns(bool){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            lastVIP = _lastVIP;
            return true;
        }
        function migrate() external whenMigrateOn returns(bool){
            IBEP20(lastVIP).transferFrom(msg.sender, address(this), IBEP20(lastVIP).balanceOf(msg.sender));
            user[msg.sender].totalLock = IBEP20(lastVIP).balanceOf(msg.sender);
            _mint(msg.sender, IBEP20(lastVIP).balanceOf(msg.sender));
            
            emit Mint(msg.sender, IBEP20(lastVIP).balanceOf(msg.sender));
            return true;
        }
        function setMigrateOn(bool status) external returns(bool){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            migrateStatus = status;
            return migrateStatus;
        }
        
        function locked(address account, uint256 amount) external returns(bool){
            require(msg.sender == presaleFactory, 'Litedex: Forbidden');
            user[account].totalLock = amount;
            _mint(account, amount);
            
            emit Mint(account, amount);
            return true;
        }
        
        function unlocked(uint256 amount) external whileOpen returns(bool){
            uint256 _userTotalLock = user[msg.sender].totalLock;
            uint256 _tokenReached;
            uint256 maxReedeem = getMaxVesting().mul(_userTotalLock).div(getTotalPercentage());
            if(user[msg.sender].alreadyRedeem.add(amount) > maxReedeem){
                _tokenReached = maxReedeem.sub(user[msg.sender].alreadyRedeem);
            }else{
                _tokenReached = amount;
            }
        
            IBEP20(lockToken).transfer(msg.sender, _tokenReached);
            _burn(msg.sender, _tokenReached);
            
            user[msg.sender].alreadyRedeem += _tokenReached;
            user[msg.sender].lastRedeem = block.timestamp;
            
            emit Burn(msg.sender, _tokenReached, address(0));
            return true;
        }
}