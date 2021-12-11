/**
 *Submitted for verification at Etherscan.io on 2021-12-11
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

contract LitedexRoles {
    /***
     * Configurator Crowdsale Contract
     */
    address payable internal owner;
    address payable internal admin;

    struct admins {
        address account;
        bool isApproved;
    }

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

contract TimeCrowdsale is LitedexRoles {
    uint internal start;
    uint internal end;
    
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
        if(start > 0 && end > 0){
            require(getBlockTimestamp() < start || getBlockTimestamp() > end, 'Litedex: private sale is already started');
        }
        _;
    }
    
    modifier onlyWhileOpen {
        require(start > 0 && end > 0, 'Litedex: time is not initialized');
        require(getBlockTimestamp() >= start && getBlockTimestamp() <= end, 'Litedex: private sale is not started');
        _;
    }
    
    //Function to get started time
    function getStartedTime() external view returns(uint256){
        return start;
    }
    
    // Function to get ended time
    function getEndedTime() external view returns(uint256){
        return end;
    }
    
    // Function to get current block timestamp
    function getBlockTimestamp() internal view returns(uint256){
        return block.timestamp;
    }
    
    // Function to ger current block number
    function getBlockNumber() internal view returns(uint256){
        return block.number;
    }
    
    /**
     * function to set time for private sale
     */
    
    function setPresaleTime(uint256 _start, uint256 _end) external onlyOwner onlyWhileNotOpen returns(uint256 startTime, uint256 endTime){
        require(_end > start && _start > 0 && _end > 0, 'Litedex: time is invalid');
        start = _start;
        end = _end;
        
        emit openingTime(owner, _start);
        emit closingTime(owner, _end);
        return (start, end);
    }
    
    function setStartTime(uint256 _time) external onlyOwner returns(uint256){
        require(_time > 0, 'Litedex: time is invalid');
        require(_time < end, 'Litedex: time is higher than end time');
        start = _time;
        
        emit openingTime(owner, _time);
        return start;
    }
    
    function setEndTime(uint256 _time) external onlyOwner returns(uint256){
        require(_time > 0, 'Litedex: time is invalid');
        require(_time > start , 'Litedex: time is lower than start time');
        end = _time;
        
        emit closingTime(owner, _time);
        return end;
    }
}
interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
contract LitedexInitalOffering is TimeCrowdsale{
    using SafeMath for uint256;

    struct Token {
        address tokenAddress;
    }
    struct acc{
        bytes3 referralId;
        uint totalReferred;
        uint totalReferredUsd;
        uint usdPurchased;
        uint tokenPurchased;
        uint usdToConverted;
        uint points;
    }
    struct ref{
        address account;
    }
    struct bind{
        bool isBind;
    }
    
    mapping(address => acc) public accounts;
    mapping(bytes3 => ref) private referrals;
    mapping(address => mapping(address => bind)) private binding;
    
    address[] private allReferrer;
    address[] private rank;

    // Token Address for Crowdsale Contract
    IBEP20 private token;
    
    // Pre-require get price
    IBEP20 private wbnb;
    IFactory private factory;

    // Crowdsale Information for retail
    uint256 private min;
    uint256 private max;
    uint256 private total_cap;
    uint256 private price;
    uint256 private token_available;
    uint256 private total_received;
    uint256 private token_sold;
    uint256 private stakedUSD;
    uint256 private usdToConverted;

    uint256 private bonusPercentage;
    bool private bonusLocked = false;

    uint homePoints;
    uint purchasePoint = 1000;
    uint walletPoint = 5*1e17;

    bool private autoGenerateRefId = true;
    address payable private fundraiser;
    uint256 private minGetRefId = 175 * 1e18;
    
    //Participant Information
    mapping (uint256 => Token) public tokenApproved;

    address[] private tokenList;

    /**
     * Event for token purchase logging
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event purchased(address indexed purchaser, uint256 amount);

    //Constructor of Litedex Crowdsale Contract
    constructor(address _tokenAddress, address _pairAddress, address _factory, address _wbnb, uint256 _bonusPercentage) public {
        bonusPercentage = _bonusPercentage;
        token = IBEP20(_tokenAddress);
        wbnb = IBEP20(_wbnb);
        factory = IFactory(_factory);
        tokenApproved[0].tokenAddress = _pairAddress;
        tokenList.push(_pairAddress);
    }

    function initialize(uint _min, uint _max, uint _cap, uint _price, address payable _fundraiser) external onlyOwner returns(bool){
        min = _min;
        max = _max;
        total_cap = _cap;
        token_available = _cap;
        price = _price;

        fundraiser = _fundraiser;

        return true;
    }
    function setPurchasePoint(uint point) external onlyOwner returns(bool){
        purchasePoint = point;
        return true;
    }
    function setWalletPoint(uint point) external onlyOwner returns(bool){
        walletPoint = point;
        return true;
    }
    function getFactory() external view returns(address){
        return address(factory);
    }
    function WBNB_ADDRESS() external view returns(address){
        return address(wbnb);
    }
    function setMinGetRefId(uint256 minimum) external onlyOwner returns(bool){
        minGetRefId = minimum;
        return true;
    }
    function getMinGetRefId() external view returns(uint256){
        return minGetRefId;
    }
    function setFactory(address _factory) external onlyOwner returns(bool){
        require(_factory != address(0), 'Litedex: factory is zero address');
        factory = IFactory(_factory);
    }
    function setWBNB(address _wbnb) external onlyOwner returns(bool){
        require(_wbnb != address(0), 'Litedex: wbnb is zero address');
        wbnb = IBEP20(_wbnb);
    }
    function setBonusPercentage(uint256 _bonusPercentage) external onlyOwner returns(bool){
        bonusPercentage = _bonusPercentage;
    }
    
    //Function to add new stable coin pair
    function addNewPair(address tokenAddress) external onlyOwner returns(bool) {
        require(tokenAddress != address(0), 'Litedex: token is zero address');
        uint256 currentId = tokenList.length;
        tokenApproved[currentId].tokenAddress = tokenAddress;
        tokenList.push(tokenAddress);
        return true;
    }

    //Function to set fundraiser
    function setFundraiser(address payable _newFundraiser) external onlyOwner returns(bool){
        require(_newFundraiser != address(0));
        fundraiser = _newFundraiser;
        return true;
    }

    //Function to set bonus which locked or unlocked
    function setBonusLocked(bool _status) external onlyOwner returns(bool){
        bonusLocked = _status;
        return bonusLocked;
    }

    //Function to get fundraiser
    function getFundraiser() external view returns(address){
        return fundraiser;
    }

    function getBnbPrice() public view returns(uint256){
        uint256 bnbPrice;
        
        address lp = factory.getPair(address(wbnb), address(tokenApproved[0].tokenAddress));
        IPair Lp = IPair(lp);
        
        (uint256 _reserve0, uint256 _reserve1,) = Lp.getReserves(); // gas savings
        if(Lp.token0() == address(wbnb)){
            bnbPrice = ((_reserve1).mul(1e18).div(_reserve0));
        }else{
            bnbPrice = ((_reserve0).mul(1e18).div(_reserve1));
        }
        return bnbPrice;
    }

    //Function generate ref id
    function generateRefId(address _account) external onlyOwner returns(bytes3) {
        require(!autoGenerateRefId, 'Litedex: auto generate ref id');
        return _generateId(_account);
    }
    function _generateId(address _account) private returns(bytes3){
        if(accounts[_account].referralId == bytes3(0)){
            bytes3 _salt = bytes3(keccak256(abi.encodePacked(_account, block.number, address(this))));
            accounts[_account].referralId = _salt;
            referrals[_salt].account = _account;
            allReferrer.push(_account);
        }
        return accounts[_account].referralId;
    }

    //Function check ref id
    function checkRefId(bytes3 refId) public view returns(bool){
        return (referrals[refId].account != address(0)) ? true : false;
    }
    function getRefId(address _account) external view returns(bytes3){
        require(_account != address(0), 'Litedex: address is zero address');
        return accounts[_account].referralId;
    }
    function getAddressFromRefId(bytes3 _refId) external view returns(address){
        require(_refId != bytes3(0));
        return referrals[_refId].account;
    }

    function leaderboard() external view returns(address[] memory){
        return rank;
    }
    function leaderboardDetail(uint position) external view returns(bytes3 refid, address userAddress, uint tRef, uint tRefUsd, uint point){
        address _acc = rank[position - 1];
        bytes3 _refId = accounts[_acc].referralId;
        uint _tRef = accounts[_acc].totalReferred;
        uint _tRefUsd = accounts[_acc].totalReferred;
        uint _points = accounts[_acc].totalReferred;
        return (_refId, _acc, _tRef, _tRefUsd, _points);
    }
    function updateLeaderboard() public onlyOwner returns(address[] memory) {
        for (uint i = 0; i < allReferrer.length; i++) {     
            for (uint j = i+1; j < allReferrer.length; j++) {     
                if(accounts[rank[i]].totalReferredUsd < accounts[rank[j]].totalReferredUsd) {    
                    address _temp = rank[i];    
                    rank[i] = rank[j];    
                    rank[j] = _temp;    
                }     
            }     
        }    
        return rank;
    }

    /**
     * Function for Purchase Token on Crowdsale
     * @param pid : pair id which user spent to purchase
     * @param amount : amount which user purchase
     * 
     * return deliveryTokens
     */
    
    function purchase(uint256 pid, uint256 amount, bytes3 refId) external onlyWhileOpen returns(bool){
        require(tokenApproved[pid].tokenAddress != address(0), "Litedex: pid is not available");
        require(amount >= min, 'Litedex: amount exceed minimum contribution');
        IBEP20 _pair = IBEP20(tokenApproved[pid].tokenAddress);
        uint256 _decimals = _pair.decimals();

        uint256 _bonus = amount.mul(bonusPercentage).div(100);
        usdToConverted += _bonus;
        
        uint256 tokenReached = getEstimateToken(amount);
        uint256 amounts = tokenReached.mul(price).div(10 ** _decimals);
        
        stakedUSD += amounts;

        accounts[msg.sender].usdPurchased += amounts;
        accounts[msg.sender].tokenPurchased += tokenReached;
        accounts[msg.sender].usdToConverted += _bonus;

        if(accounts[msg.sender].usdPurchased >= minGetRefId){
            accounts[msg.sender].referralId = _generateId(msg.sender);
        }

        _pair.transferFrom(msg.sender, address(this), amounts);
        if(bonusLocked){
            _pair.transfer(fundraiser, amounts.sub(_bonus));
        }else{
            _pair.transfer(fundraiser, amounts);
        }

        total_received = stakedUSD;
        token_sold += tokenReached;
        token_available -= tokenReached;
        
        if(checkRefId(refId) && refId != bytes3(0)){
            address _acc = referrals[refId].account;
            if(!binding[_acc][msg.sender].isBind){
                binding[_acc][msg.sender].isBind = true;
                accounts[_acc].totalReferred += 1;
                accounts[_acc].points += walletPoint;
            }
            
            accounts[_acc].totalReferredUsd += amounts;
            accounts[_acc].points += amounts.div(purchasePoint);
        }
        //use default referral / others referral also get points 
        accounts[msg.sender].points += amounts.div(purchasePoint);
        homePoints += amounts.div(purchasePoint);

        token.transfer(msg.sender, tokenReached);

        emit purchased(msg.sender, tokenReached);
        return true;
    }

    /**
     * Function for Estimate token which user get on Crowdsale
     * @param _amount : amount which user purchase
     * return token_amount type uint256
     */
    function getEstimateToken(uint256 _amount) private view returns(uint256) {
        require(_amount >= min && _amount <= max, "Litedex: amount is lower than min contribution");
        require(price > 0, 'Litedex: Price is not initialized');
        require(token_sold< total_cap, 'Litedex: total cap has reached');

        uint256 _decimals = token.decimals(); //18
        
        uint256 estimateToken = _amount.mul(10 ** _decimals).div(price);
        if(estimateToken >= total_cap.sub(token_sold)){
            estimateToken = total_cap.sub(token_sold);
        }

        require(estimateToken > 0, "Litedex: calculating error!");
        return estimateToken;
    }

    //Function claim BNB
    function claimBonus() external returns(bool){
        require(block.timestamp > end, 'Litedex: Claim after Crowdsale');
        uint256 _bonus = accounts[msg.sender].usdPurchased;
        uint256 _bnbPrice = getBnbPrice();
        safeTransferBNB(msg.sender, _bonus/_bnbPrice);
        return true;
    }
    
    //Function to increase total cap - return cap (uint256)
    function increaseTotalCap(uint256 cap) external onlyOwner returns(uint256){
        total_cap += cap;
        token_available += cap; 
        return total_cap;
    }
    
    //Function to decrease total cap - return cap (uint256)
    function decreaseTotalCap(uint256 cap) external onlyOwner returns(uint256){
        total_cap -= cap;
        token_available = (token_available > cap) ? token_available.sub(cap) : 0;
        return total_cap;
    }
    
    //Function for setting current min contribution - return true
    function setMinContribution(uint256 _min) external onlyOwner returns(uint256){
        min = _min;
        return min;
    }

    //Function for setting current min contribution - return true
    function setMaxContribution(uint256 _max) external onlyOwner returns(uint256){
        max = _max;
        return max;
    }

    //Function for setting current price - return true
    function setPrice(uint256 _price) external onlyOwner returns(uint256){
        price = _price;
        return price; 
    }
    
    //Function for getting current price in usd - return price (uint256)
    function getCurrentPrice() external view returns(uint256){
        return price;
    }
    
    //Function for getting current total received - return total_received (uint256)
    function getTotalReceived() external view returns(uint256){
        return stakedUSD;
    }
    
    //Function for getting current min contribution - return min (uint256)
    function getMinContribution() external view returns(uint256){
        return min;
    }

    //Function for getting current max contribution - return max (uint256)
    function getMaxContribution() external view returns(uint256){
        return max;
    }
    
    //Function for getting current token available - return token_available (uint256)
    function getTokenAvailable() external view returns(uint256){
        return token_available;
    }
    
    //Function for getting current total cap - return cap (uint256)
    function getTotalCap() external view returns(uint256){
        return total_cap;
    }
    
    //Function for getting current token sold - return token sold (uint256)
    function getTokenSold() external view returns(uint256){
        return token_sold;
    }
    
    //Function to withdraw ldx token after private sale
    function emergencyWithdrawAll() external onlyOwner returns(bool) {
        token.transfer(owner, token.balanceOf(address(this)));
        return true;
    }
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner returns(bool){
        require(to != address(0), 'Litedex: zero address');
        token.transfer(to, amount);

        return true;
    }
 
    //Function to recover stuck tokens in contract
    function recoverStuckToken(address to, address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0) && to != address(0));
        IBEP20 _token = IBEP20(tokenAddress);
        _token.transfer(to, _token.balanceOf(address(this)));
    }
    
    //Function to recover stuck BNB in contract
    function recoverStuckBNB() external onlyOwner {
        return safeTransferBNB(owner, address(this).balance);
    }
    
    //Function to safeTransfer BNB
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'Litedex: BNB_TRANSFER_FAILED');
    }
}