/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity 0.8.4;

interface IOERC20 {

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

contract Whitelist {
    
    address public owner;
    uint public totalWhitelisted;
    uint public totalAmount;
    uint public batchIDs;
    uint public batchSize;
    
    struct User {
        bool isWhitelisted;
        uint amount;
    }
    
    struct Batch {
        uint nonce;
        address[] users;
    }
    
    mapping(address => User) private _users;
    mapping(uint => Batch) private _batches;
    
    event NewWhitelist(address user, uint amount);
    event NewBatchCreated(uint indexed ID);

    constructor(address _owner, uint _batchSize) {
        owner = _owner;
        batchSize = _batchSize;
    }
    
    modifier onlyOwner() {
        
        require(msg.sender == owner, "only owner can do this");
        _;
    }
    
    function _whitelist(address _user, uint _amount) internal {
        
        User storage user = _users[_user];
        user.isWhitelisted = true;
        user.amount = _amount;
        
        totalWhitelisted++;
        totalAmount += _amount;

        if (batchIDs == 0) {
            batchIDs++;
            emit NewBatchCreated(batchIDs);
        }
        
        if (_batches[batchIDs].nonce == batchSize) {
            batchIDs++;
            emit NewBatchCreated(batchIDs);
        }
        
        _batches[batchIDs].nonce++;
        _batches[batchIDs].users.push(_user);
        
        emit NewWhitelist(_user, _amount);
    }
    
    function batchWhitelist(address[] memory _user, uint[] memory _amount) external onlyOwner returns(bool) {
        
        require(_user.length == _amount.length, "user and min entry must have the same length");
        
        for (uint i = 0; i < _user.length; i++) {
            require(!_users[_user[i]].isWhitelisted, "user already whitelisted"); 
            _whitelist(_user[i], _amount[i]);
        }
        return true;
    }
    
    function whitelist(address _user, uint _amount) external onlyOwner returns(bool){
        
        require(!_users[_user].isWhitelisted, "user already whitelisted");
        
        _whitelist(_user, _amount);
        return true;
    }
    
    function isWhitelisted(address _user) external view returns(bool) {
        
        return _users[_user].isWhitelisted == true;
    }
    
    function getAmount(address _user) external view returns(uint) {
        
        return _users[_user].amount;
    }
    
    function getBatch(uint _batchId) external view returns(address[] memory batchList) { 
        
        if(_batchId == 0 || _batchId > batchIDs) revert("invalid batch ID");
        return _batches[_batchId].users;
    }

}

contract Airdrop {

    IOERC20 private LP;
    Whitelist private whitelist;
    
    address public admin;
    uint public pool;
    
    mapping(uint => bool) private _isPaid;
    mapping(address => uint) private _addressToAmount;

    event Deposited(address indexed sender, uint amount);
    event WorkedOutAirdrop(uint indexed batch, address indexed user, uint amount);
    event Dusted(address indexed sender, uint amount);

    constructor(address _LPAddress, address _whitelist, address _admin) {
        
        LP = IOERC20(_LPAddress);
        whitelist = Whitelist(_whitelist);
        admin = _admin;
    }

    modifier onlyValidID(uint _batchId) {
        
        uint ids = whitelist.batchIDs();
        if (_batchId == 0 || _batchId > ids) revert("invalid batch ID");
        _;
    }

    modifier onlyAdmin() {

        require(msg.sender == admin, "only admin can call");
        _;
    }
    
    function deposit(uint _amount) external onlyAdmin() returns(bool success) {
        
        require(_amount > 0, "invalid amount");
        require(LP.transferFrom(msg.sender, address(this), _amount));
        
        pool = _amount;
        
        emit Deposited(msg.sender, _amount);
        return true;
    }

    function distributeAirdrop(uint _batchId) external onlyAdmin() onlyValidID(_batchId) returns(bool success) {
        
        require(pool != 0, "deposit contract");
        require(!_isPaid[_batchId], "already paid batch");
        
        _isPaid[_batchId] = true;
        
        address[] memory users = whitelist.getBatch(_batchId);
        uint totalAmount = whitelist.totalAmount(); 
        
        for (uint i = 0; i < users.length; i++) {
            
            _addressToAmount[users[i]] = whitelist.getAmount(users[i]);
        }

        for (uint i = 0; i < users.length; i++) {
            
            LP.transfer(users[i], ((_addressToAmount[users[i]] * pool) / totalAmount));
            emit WorkedOutAirdrop(_batchId, users[i], _addressToAmount[users[i]]);
        }
        return true;
    }
    
    function clearDust() external onlyAdmin() {
        
        uint balance = LP.balanceOf(address(this));
        require(balance > 0, "no dust to clear");
        LP.transfer(msg.sender, balance);
        emit Dusted(msg.sender, balance);
    }
    
    function hasPaidBatch(uint _batchId) external view returns(bool) {
        
        return _isPaid[_batchId];
    }
}