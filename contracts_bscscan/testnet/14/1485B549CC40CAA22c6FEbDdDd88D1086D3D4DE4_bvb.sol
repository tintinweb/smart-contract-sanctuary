/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// File: miner_flat.sol


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: miner.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;




contract bvb is ReentrancyGuard, Pausable {

    IERC20 token; 

    address constant private wal0 = 0x0000000000000000000000000000000000000000;
    uint constant private maxDiscount = 50*1e16; // 50%

    uint private _rewardRate = 347222222222; //rate per second
    uint private _compoundBonus = 1000; //1%
    uint private _referralBonus = 1000; //1%
    //uint public vaultBalance;

    mapping(address => uint) private lastUpdateTime;
    mapping(address => uint) public rewards;
    mapping(address => uint) public discount;
    mapping(address => uint) private _balances;
    mapping(address => address) public referrals;
    
    uint public lastSupply;
    uint public totalSupply;
    uint public tax;
    
    uint private _emergencyTax = 5*1e16;
    bool private _emergency = false;
    
    address private ceoWallet1=0x29540536e574F23E7749a4fACbAb3D496F78530E;
    address private ceoWallet2=0xbceb9f31a6BB34a969Db5247C2d476BeadAc408F;
    address private ceoWallet3=0x26eE92f9813b45344afCc908fBB37b4A615A5D5d;
    address private mktWallet=0xC813885ef57437EeC7Fc7E99F3Dcf5258f1C6d12;
    address private vaultAddress=0x6BE4741AB0aD233e4315a10bc783a7B923386b71;
    
    constructor(address _tokenAddress){
        
        token = IERC20(_tokenAddress);
        
    }
    
    function compound() external{
        _updateReward();
        uint rewardCompound = rewards[msg.sender];
        lastSupply=totalSupply;
        rewards[msg.sender] = 0;
        _updateDiscount(rewardCompound);
        _balances[msg.sender] += rewardCompound;
    }
    
    function _updateDiscount(uint _amount) private{
        uint _totalSupply = 1;
        uint _lastSupply = 1;
        if (totalSupply != 0){
            _totalSupply = totalSupply;
        }
        
        if (lastSupply != 0){
            _lastSupply = lastSupply;
        }
        
        discount[msg.sender] += _amount*_compoundBonus*1e18/_totalSupply;
        
        if (discount[msg.sender] > maxDiscount){
            discount[msg.sender] = maxDiscount;
        }
        
    }

    function earned(address account) public view returns (uint) {
        return
            (_balances[account] * _rewardRate * (block.timestamp - lastUpdateTime[account])/1e18) + rewards[account];
    }

    function _updateReward() private {
        rewards[msg.sender] = earned(msg.sender);
        lastUpdateTime[msg.sender] = block.timestamp;
    }

    function stake(address _referral, uint _amount) payable external {
        
        require(address(_referral) != (msg.sender), "You can't referral yourself.");
        
        _updateReward();
    
        if ((referrals[msg.sender] == wal0)) { // checks if there's a referral for this account
            referrals[msg.sender] = _referral; // register the new referral
        }
        
        uint _totalSupply = 1*1e18;
        uint _lastSupply = 1*1e18;
        
        if (totalSupply != 0){
            _totalSupply = totalSupply;
        }
        
        if (lastSupply != 0){
            _lastSupply = lastSupply;
        }
        
        lastSupply=totalSupply; // updates last supply for tax calculation
        
        if (referrals[msg.sender]!=wal0){ // if there is a referral i.e. referral not wal0
            discount[_referral] += ((_amount *_referralBonus) / _totalSupply) * 1e16; // updates referral discount
        if (discount[_referral] > maxDiscount) { // maximum discount equals 50%
            discount[_referral] = maxDiscount;
        }    
        }
        
        totalSupply += _amount;
        _balances[msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        //vaultBalance += msg.value; // atualiza o valor depositado na vault
        //beefyFinance(vaultAddress).deposit(msg.value); // deposita o valor na vault
    }

    function withdraw(uint _amount) external {
        _updateReward();
        require(_amount < rewards[msg.sender], "Insuficient balance");
        require(_amount < totalSupply*10/100, "Can't claim more than 10% of contract at once");
        
        tax = getTax();
        lastSupply=totalSupply;
        uint discountedTax = tax * (1e18-discount[msg.sender])/ 1e18;
        discount[msg.sender]=0;
        uint totalTax = _amount*discountedTax/1e18;
        uint restake = totalTax*60/100;
        uint mktFund = totalTax*10/100; 
        uint devTax = totalTax-restake-mktFund;
        totalSupply -= _amount;
        rewards[msg.sender] -= _amount;
        totalSupply += restake;
        //vaultBalance -= _amount; // atualiza o valor depositado na vault
        //beefyFinance(vaultAddress).withdraw(_amount); // deposita o valor na vault
        payable(ceoWallet1).transfer(devTax/3);
        payable(ceoWallet2).transfer(devTax/3);
        payable(ceoWallet3).transfer(devTax/3);
        payable(mktWallet).transfer(mktFund);
        token.transferFrom(address(this), msg.sender, _amount-totalTax);
    }
    
    function getBalance(address account) public view returns (uint) {
        return
        _balances[account];
    }
    
    function emergency() public {
        
        require(msg.sender == address(ceoWallet1), "Owner only");
        _emergency = true;
        
    }
    
    function getTax() public view returns (uint){
        uint _totalSupply = 1*1e18;
        uint _lastSupply = 1*1e18;
        
        if (_emergency) {
            return _emergencyTax;
        }
        
        if (totalSupply != 0){
            _totalSupply = totalSupply;
        }
        
        if (lastSupply != 0){
            _lastSupply = lastSupply;
        }
        
        uint delta = _totalSupply/_lastSupply; //delta supply
        uint _tax = 5*1e16;
        if (delta < 1e16){
            _tax = tax+(1e16-delta)/3;
        }else{
            _tax = tax-(1e16-delta)/4;
        }
        
        if (_tax < 5*1e16){
            _tax = 5*1e16;
        }
        
        if (_tax > 50*1e16){
            _tax = 50*1e16;
        }
        
        return _tax;
            
    }

}

//interface beefyFinance {
//    function deposit(uint _amount) external;
//    function withdraw(uint256 _amount) external;
//}