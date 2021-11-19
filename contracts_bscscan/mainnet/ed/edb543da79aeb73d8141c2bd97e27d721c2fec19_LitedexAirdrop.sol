/**
 *Submitted for verification at BscScan.com on 2021-11-19
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
contract LitedexAirdrop is Ownable {
    using SafeMath for uint256;
    
    address private ldxToken;
    uint256 private airdropAllocation;
    
    struct community{
        address account;
        uint256 get;
    }
    struct airdrop{
        uint id;
        uint256 allocation;
        uint256 totalDistributed;
        uint256 totalReceiver;
        uint256 timeDistributed;
    }
    mapping(uint256 => community) private communities;
    mapping(uint256 => airdrop) private airdrops;
    
    event SendAirdrop(address indexed account,uint256 amount);
    event SetAirdrop(uint256 id, uint256 supply, uint256 tpeople);
    event Add(address indexed account, uint256 amount, uint256 time);
    
    uint256 private eventid = 0;
    bool private alreadySet;
    uint256 private winner;
    
    constructor(address _ldxToken, uint256 _airdropAllocation) public {
        ldxToken = _ldxToken;
        airdropAllocation = _airdropAllocation;
    }
    function getAirdropSupply() external view returns(uint256){
        return airdropAllocation;
    }
    function checkdata(uint256 _eventid) external view returns(uint id, uint256 allocation, uint256 totalReceiver, uint256 timeDistributed){
        uint256 _id = airdrops[_eventid].id;
        uint256 _allocation = airdrops[_eventid].allocation;
        uint256 _totalReceiver = airdrops[_eventid].totalReceiver;
        uint256 _timeDistributed = airdrops[_eventid].timeDistributed;
        
        return(_id, _allocation, _totalReceiver, _timeDistributed);
    }
    
    function setAirdrop(uint256 _allocation, uint256 _tReceiver) external onlyAdmin returns (bool){
        require(_allocation > 0, 'Litedex: Allocation is 0');
        require(_tReceiver > 0, 'Litedex: Total winner is 0 person');
        eventid += 1;
        airdrops[eventid].id = eventid;
        airdrops[eventid].allocation = _allocation;
        airdrops[eventid].totalReceiver = _tReceiver;
        
        alreadySet = true;
        
        emit SetAirdrop(eventid, _allocation, _tReceiver);
        return true;
    }
    function addReceiver(address _account, uint256 _totalReceived) external onlyAdmin returns (bool){
        bool _alreadySet = alreadySet;
        require(_alreadySet, 'Litedex: u must set airdrop first');
        require(_account != address(0), 'Litedex: address is zero address');
        require(_totalReceived > 0, 'Litedex: totalReceived is 0');
        
        winner += 1;
        communities[winner].account = _account;
        communities[winner].get = _totalReceived;
        
        emit Add(_account, _totalReceived, block.timestamp);
        return true;
    }
    function sendAdditionalAirdrop(address _account, uint256 _amount) external onlyAdmin returns(bool) {
        require(_account != address(0), 'Litedex: there is no account win');
        require(_amount > 0, 'Litedex: amount is 0');
        IBEP20(ldxToken).transfer(_account, _amount);
        
        emit SendAirdrop(_account, _amount);
        return true;
    }
    function sendAirdrop() external onlyAdmin returns (bool){
        require(alreadySet, 'Litedex: set airdrop first');
        for(uint i=1;i<=winner;i++){
            address _account = communities[i].account;
            uint256 _amount = communities[i].get;
            
            require(_account != address(0), 'Litedex: there is no account win');
            require(_amount > 0, 'Litedex: amount is 0');
            IBEP20(ldxToken).transfer(_account, _amount);
            
            airdrops[eventid].totalDistributed += _amount;
            emit SendAirdrop(_account, _amount);
            communities[i].account = address(0);
            communities[i].get = 0;
            
            
        }
        winner = 0;
        alreadySet = false;
        airdrops[eventid].timeDistributed = block.timestamp;
        
        return true;
    }
    function recoverStuckToken(address _token, uint256 _amount) external onlyOwner returns(bool){
        require(_token != address(0), 'Litedex: _token is zero address');
        require(_amount > 0, 'Litedex: amount is 0');
        
        IBEP20(_token).transfer(msg.sender, _amount);
        
        return true;
    }
    function emergencyWithdraw(uint256 _amount) external onlyOwner returns(bool){
        require(_amount > 0, 'Litedex: amount is 0');
        
        IBEP20(ldxToken).transfer(msg.sender, _amount);
        
        return true;
    }
    
}