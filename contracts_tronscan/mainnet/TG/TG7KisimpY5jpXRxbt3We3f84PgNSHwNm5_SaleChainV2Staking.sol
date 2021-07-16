//SourceUnit: SaleChainV2Staking.sol

pragma solidity ^0.5.8;

/**
 * @title Math
 * @dev Math operations
 */
library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract StakingEnumerable {
    using SafeMath for uint256;

    // Array with all holders addresses, used for enumeration
    address[] private _allHolders;

    // Mapping from holder address to position in the allHolders array
    mapping(address => uint256) private _allHoldersIndex;

    /**
     * @dev Gets the total amount of holders stored by the contract.
     * @return uint256 representing the total amount of holders
     */
    function totalHolder() public view returns (uint256) {
        return _allHolders.length;
    }

    /**
     * @dev Gets the account address at a given index of all the holders in this contract
     * Reverts if the index is greater or equal to the total number of holders.
     * @param index uint256 representing the index to be accessed of the holders list
     * @return account address at the given index of the holders list
     */
    function holderByIndex(uint256 index) public view returns (address) {
        require(index < totalHolder(), "Global index out of bounds");
        return _allHolders[index];
    }

    /**
     * @dev Gets the account address at a given index of all the holders in this contract
     * Reverts if the index is greater or equal to the total number of holders.
     * @return account address at the given index of the holders list
     */
    function allHolders() public view returns (address[] memory) {
        return _allHolders;
    }

    /**
     * @dev Internal function to add a holder to holders List.
     * @param account address of tokens to be emitted
     */
    function addHolder(address account) internal {
        if (_allHoldersIndex[account] == 0){
            _addAccountToAllAccountsEnumeration(account);
        }
    }

    /**
     * @dev Internal function to add a holder to holders List.
     * @param account address of tokens to be emitted
     */
    function removeHolder(address account) internal {
        if (_allHoldersIndex[account] != 0){
            _removeAccountFromAllAccountsEnumeration(account);
        }
    }

    /**
     * @dev Private function to add a holder to this extension's holder tracking data structures.
     * @param account address of the holder to be added to the tokens list
     */
    function _addAccountToAllAccountsEnumeration(address account) private {
        _allHoldersIndex[account] = _allHolders.length;
        _allHolders.push(account);
    }

    /**
     * @dev Private function to remove a holder from this extension's holder tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allHolders array.
     * @param account address of the holder to be removed from the tokens list
     */
    function _removeAccountFromAllAccountsEnumeration(address account) private {
        // To prevent a gap in the tokens array, we store the last holder in the index of the holder to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastAccountIndex = _allHolders.length.sub(1);
        uint256 accountIndex = _allHoldersIndex[account];

        address lastAccount = _allHolders[lastAccountIndex];

        _allHolders[accountIndex] = lastAccount; // Move the last holder to the slot of the to-unfreeze token
        _allHoldersIndex[lastAccount] = accountIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allHolders.length--;
        _allHoldersIndex[account] = 0;
    }
}

contract SaleChainV2Staking is StakingEnumerable {
    using SafeMath for uint256;
    using Address for address payable;

    // The token being stake
    ITRC20 private _token;

    uint256 private _totalShares;

    mapping(address => uint256) private _deposits;
    mapping(address => uint256) private _depositsTime;
    mapping(address => uint256) private _unfreezeAmount;
    mapping(address => uint256) private _unfreezeTime;

    address public oldPool;

    /**
     * Event for token Staking logging
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens staked
     */
    event StakeWin(address indexed payee, uint256 tokenAmount);

    /**
     * Event for token unfreeze logging
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens staked
     */
    event Unfreeze(address indexed payee, uint256 tokenAmount);
    
    /**
     * Event for withdraw unfreezed tokens logging
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens staked
     */
    event WithdrawUnfreeze(address indexed payee, uint256 tokenAmount);
    
    /**
     * Event for cancel unfreezed tokens logging
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens staked
     */
    event CancelUnfreeze(address indexed payee, uint256 tokenAmount);

    constructor(address _trc20, address _pool) public{
        _token = ITRC20(_trc20);
        oldPool = _pool;
    }

    modifier onlyOldPool(){
        require(msg.sender == oldPool, "Not oldPool");
        _;
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    function depositsTime(address payee) public view returns (uint256) {
        return _depositsTime[payee];
    }

    function unfreezeAmountOf(address payee) public view returns (uint256) {
        return _unfreezeAmount[payee];
    }

    function unfreezeTime(address payee) public view returns (uint256) {
        return _unfreezeTime[payee];
    }

    function stat(address payee) public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (_deposits[payee], _depositsTime[payee], _unfreezeAmount[payee], _unfreezeTime[payee], _totalShares);
    }

    function withdrawTo(address to, uint256 amount) internal {   
        address payee = msg.sender;     
        _unfreezeAmount[payee] = 0;
        _token.transfer(to, amount);        
        if (_deposits[payee] == 0){
            super.removeHolder(payee);
        }
        emit WithdrawUnfreeze(payee, amount);
    }

    /**
     * @dev freeze amount Of tokens to get staking fund.
     * @param payee The destination address of the tokens.
     * @param tokenAmount amount of tokens to be freeze
     */
    function stakeWin(address payee, uint256 tokenAmount) public returns (bool){
        _token.transferFrom(payee, address(this), tokenAmount);
        _deposits[payee] = _deposits[payee].add(tokenAmount);
        _depositsTime[payee] = block.timestamp;
        _totalShares = _totalShares.add(tokenAmount);
        super.addHolder(payee);
        emit StakeWin(payee, tokenAmount);
        return true;
    }

    /**
     * @dev unfreeze amount Of tokens
     * @param tokenAmount amount of tokens to be freeze
     */
    function unfreeze(uint256 tokenAmount) public {
        address payee = msg.sender;
        _deposits[payee] = _deposits[payee].sub(tokenAmount, "Unfreeze amount exceeds balance");
        _unfreezeAmount[payee] = _unfreezeAmount[payee].add(tokenAmount);
        _unfreezeTime[payee] = block.timestamp; 
        _totalShares = _totalShares.sub(tokenAmount);
        emit Unfreeze(payee, tokenAmount);
    }

    /**
     * @dev claim unfreezed amount Of tokens
     */
    function withdrawUnfreeze() public{
        address payee = msg.sender;
        require(_unfreezeTime[payee] < block.timestamp.sub(48 hours), "Unfreeze must after 48 hours");
        uint256 tokenAmount = _unfreezeAmount[payee];
        require(tokenAmount >= 0, "Unfreeze request amount must be greater than zero!");
        _unfreezeAmount[payee] = 0;
        _token.transfer(payee, tokenAmount);
        if (_deposits[payee] == 0){
            super.removeHolder(payee);
        }
        emit WithdrawUnfreeze(payee, tokenAmount);
    }

    /**
     * @dev cancel unfreeze amount Of tokens
     */
    function cancelUnfreeze() public{
        address payee = msg.sender;
        uint256 tokenAmount = _unfreezeAmount[payee];
        require(tokenAmount >= 0, "Unfreeze request amount must be greater than zero!");
        _deposits[payee] = _deposits[payee].add(tokenAmount);
        _unfreezeAmount[payee] = 0;
        emit CancelUnfreeze(payee, tokenAmount);
    }

    function stakeTo(address user, uint256 amount) public onlyOldPool returns (bool){
        require(amount > 0, "Cannot stake 0");
        require(stakeWin(user, amount), "Stake to failed");
        return true;
    }

    function migrate(address nextPool) public returns (bool){
        uint256 userBalance = _unfreezeAmount[msg.sender];
        require(userBalance > 0, "Must gt 0");

        require(SaleChainV2Staking(nextPool).stakeTo(msg.sender, userBalance), "StakeTo failed");
        withdrawTo(nextPool, userBalance);

        return true;
    }

}