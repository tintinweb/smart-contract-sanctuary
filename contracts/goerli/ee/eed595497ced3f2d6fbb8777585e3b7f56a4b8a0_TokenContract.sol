/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}


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


contract TokenContract is ReentrancyGuard{
    
    using SafeMath for uint256;
    
    
    string private _name;
    
    string private _symbol;
    
    address private _owner;
    
    string private _hash;

    mapping(address => bool) private _isWhitelisted;

    mapping(address => uint256) private _amountDeposited;
    
    mapping(address => uint256) private _amountWithdrawn;
    
    event Deposit(address indexed account, uint256 value);
    
    event Withdraw(address indexed account, uint256 value);
    
    modifier onlyOwner(){
        require(msg.sender == _owner, "Sender is not the owner.");
        _;
    }
    
    
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
    }
    
    fallback() external payable {
        deposit();
    }
    
    function deposit() public payable nonReentrant {
        
        require(msg.value > 0, "Amount should be greater than 0.");
        
        processDeposit(msg.sender, msg.value);
        
        emit Deposit(msg.sender, msg.value);
    }
    
    function processDeposit(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount > 0);
        _amountDeposited[account] += amount;
        _isWhitelisted[account] = true;
    }
    
    function withDraw(uint256 amount, string memory hash_) public {
        
        require(keccak256(bytes(_hash)) == keccak256(bytes(hash_)), "Hash mismatched.");
        
        require(_amountDeposited[msg.sender] > 0, "Wallet has no deposit.");
        
        require(_isWhitelisted[msg.sender]);
                
        _amountWithdrawn[msg.sender] += amount;
        
        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }
    
    function checkBalance() public view returns(uint256) {
        return _amountDeposited[msg.sender];
    }
    
    function checkWithdrawnAmount(address account) public view returns(uint256){
        return _amountWithdrawn[account];
    }
    
    
    function name() public view returns(string memory){
        return _name;
    }
    
    function symbol() public view returns(string memory){
        return _symbol;
    }
    
    function removeWhitelist(address account) public onlyOwner {
        _isWhitelisted[account] = false;
    }
    
    function destroy() public onlyOwner {
        selfdestruct(payable(_owner));
    }
    
    function createHash(string memory hash_) public onlyOwner {
        _hash = hash_;
    }
    
    function changeAdmin(address admin) public onlyOwner {
        _owner = admin;
    }

    function owner() public view returns(address) {
        return _owner;
    }
    
}