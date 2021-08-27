/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/*
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


// File @openzeppelin/contracts/access/[email protected]

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


// File contracts/interfaces/iGravityToken.sol

interface iGravityToken is IERC20 {

    function setGovernanceAddress(address _address) external;

    function changeGovernanceForwarding(bool _bool) external;

    function burn(uint256 _amount) external returns (bool);
}


// File contracts/core/GovernanceV2.sol





contract GovernanceV2 is Initializable, OwnableUpgradeable {
    mapping(address => uint256) public feeBalance;
    address public tokenAddress;
    struct FeeLedger {
        uint256 totalFeeCollected_LastClaim;
        uint256 totalSupply_LastClaim;
        uint256 userBalance_LastClaim;
    }
    mapping(address => FeeLedger) public feeLedger;

    mapping(address => uint[3]) public tierLedger;
    uint[3] public Tiers;
    uint256 public totalFeeCollected;
    iGravityToken GFI;
    IERC20 WETH;
    IERC20 WBTC;

    /**
    * @dev emitted when Fees are deposited into the Governance contract
    * @param weth the amount of wETH deposited into the governance contract
    * @param wbtc the amount of wBTC deposited into the governance contract
    **/
    event FeeDeposited(uint weth, uint wbtc);

    /**
    * @dev emitted when a wETH fee is claimed
    * @param claimer the address that had it's fees claimed
    * @param recipient the address the fees were sent to
    * @param amount the amount of wETH sent to the recipient
    **/
    event FeeClaimed(address claimer, address recipient, uint amount);

    /**
    * @dev emitted when GFI is burned for wBTC
    * @param claimer the address burning GFI for wBTC
    * @param GFIamount the amount of GFI burned
    * @param WBTCamount the amount of wBTC sent to claimer
    **/
    event WbtcClaimed(address claimer, uint GFIamount, uint WBTCamount);

    /**
    * @dev used to ensure only token contract can call govAuth functions lines 233 -> 268
    **/
    modifier onlyToken() {
        require(msg.sender == tokenAddress, "Only the token contract can call this function");
        _;
    }

    function initialize(
        address GFI_ADDRESS,
        address WETH_ADDRESS,
        address WBTC_ADDRESS
    ) public initializer {
        __Ownable_init();
        tokenAddress = GFI_ADDRESS;
        GFI = iGravityToken(GFI_ADDRESS);
        WETH = IERC20(WETH_ADDRESS);
        WBTC = IERC20(WBTC_ADDRESS);
    }

    function pendingEarnings(address _address) public view returns (uint256) {
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(_address);
        if (currentBalance > feeLedger[_address].userBalance_LastClaim) {
            balance = feeLedger[_address].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[_address].totalSupply_LastClaim) {
            supply = feeLedger[_address].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[_address].totalFeeCollected_LastClaim) * balance) /
                supply;
        //Add any extra fees they need to collect
        feeAllocation = feeAllocation + feeBalance[_address];
        return feeAllocation;
    }

    function viewBacking(uint amount) external view returns(uint backing){
        require(
            amount > 10**18,
            "Amount too small, must be greater than 1 GFI token!"
        );
        backing =
            (amount * WBTC.balanceOf(address(this))) / GFI.totalSupply();
    }

    function updateTiers(uint tier3, uint tier2, uint tier1) external onlyOwner{
        require(tier3 > tier2 && tier2 > tier1, 'Gravity Finance: Invalid Tier assignments');
        Tiers[0] = tier1;
        Tiers[1] = tier2;
        Tiers[2] = tier3;
    }

    /**
    * @dev internal function called when token contract calls govAuthTransfer or govAuthTransferFrom
    * Will update the recievers fee balance. This will not change the reward they would have got from this fee update
    * rather it updates the fee ledger to refelct the new increased amount of GFI in their wallet
    * @param _address the address of the address recieving GFI tokens
    * @param amount the amount of tokens the address is recieving
    * @return amount of wETH added to _address fee balance
    **/
    function _updateFeeReceiver(address _address, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(_address) + amount; //Add the amount they are getting transferred eventhough updateFee will use smaller pre transfer value
        if (currentBalance > feeLedger[_address].userBalance_LastClaim) {
            balance = feeLedger[_address].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[_address].totalSupply_LastClaim) {
            supply = feeLedger[_address].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[_address].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[_address].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[_address].totalSupply_LastClaim = currentSupply;
        feeLedger[_address].userBalance_LastClaim = currentBalance;
        feeBalance[_address] = feeBalance[_address] + feeAllocation;
        return feeAllocation;
    }
    /**
    * @dev updates the fee ledger info for the specified address
    * This function can be used to update the fee ledger info for any address, and is used to update the fee for the from address in transfer and transferFrom calls
    * @param _address the address you want to update the fee ledger info for
    * @return the amount of wETH added to _address feeBalance
    **/
    function updateFee(address _address) public returns (uint256) {
        require(GFI.balanceOf(_address) > 0, "_address has no GFI");
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(_address);
        if (currentBalance > feeLedger[_address].userBalance_LastClaim) {
            balance = feeLedger[_address].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[_address].totalSupply_LastClaim) {
            supply = feeLedger[_address].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[_address].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[_address].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[_address].totalSupply_LastClaim = currentSupply;
        feeLedger[_address].userBalance_LastClaim = currentBalance;
        feeBalance[_address] = feeBalance[_address] + feeAllocation;
        return feeAllocation;
    }

    /**
    * @dev updates callers fee ledger, and pays out any fee owed to caller
    * @return the amount of wETH sent to caller
    **/
    function claimFee() public returns (uint256) {
        require(GFI.balanceOf(msg.sender) > 0, "User has no GFI");
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(msg.sender);
        if (currentBalance > feeLedger[msg.sender].userBalance_LastClaim) {
            balance = feeLedger[msg.sender].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[msg.sender].totalSupply_LastClaim) {
            supply = feeLedger[msg.sender].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[msg.sender].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[msg.sender].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[msg.sender].totalSupply_LastClaim = currentSupply;
        feeLedger[msg.sender].userBalance_LastClaim = currentBalance;
        //Add any extra fees they need to collect
        feeAllocation = feeAllocation + feeBalance[msg.sender];
        feeBalance[msg.sender] = 0;
        require(WETH.transfer(msg.sender, feeAllocation),"Failed to delegate wETH to caller");
        emit FeeClaimed(msg.sender, msg.sender, feeAllocation);
        return feeAllocation;
    }

    /**
    * @dev updates callers fee ledger, and pays out any fee owed to caller to the reciever address
    * @param reciever the address to send callers fee balance to
    * @return the amount of wETH sent to reciever
    **/
    function delegateFee(address reciever) public returns (uint256) {
        require(GFI.balanceOf(msg.sender) > 0, "User has no GFI");
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(msg.sender);
        if (currentBalance > feeLedger[msg.sender].userBalance_LastClaim) {
            balance = feeLedger[msg.sender].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[msg.sender].totalSupply_LastClaim) {
            supply = feeLedger[msg.sender].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[msg.sender].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[msg.sender].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[msg.sender].totalSupply_LastClaim = currentSupply;
        feeLedger[msg.sender].userBalance_LastClaim = currentBalance;
        //Add any extra fees they need to collect
        feeAllocation = feeAllocation + feeBalance[msg.sender];
        feeBalance[msg.sender] = 0;
        require(WETH.transfer(reciever, feeAllocation), "Failed to delegate wETH to reciever");
        emit FeeClaimed(msg.sender, reciever, feeAllocation);
        return feeAllocation;
    }

    /**
    * @dev withdraws callers fee balance without updating fee ledger
    **/
    function withdrawFee() external {
        uint256 feeAllocation = feeBalance[msg.sender];
        feeBalance[msg.sender] = 0;
        require(WETH.transfer(msg.sender, feeAllocation), "Failed to delegate wETH to caller");
        emit FeeClaimed(msg.sender, msg.sender, feeAllocation);
    }

    /**
    * @dev update from and to address tier based on the amount.
    **/
    function _updateUsersTiers(address from, address to, uint amount) internal{
        uint fromNewBal = GFI.balanceOf(from) - amount;
        uint toNewBal = GFI.balanceOf(to) + amount;
        for (uint i = 0; i<3; i++){
            if(fromNewBal >= Tiers[i]){
                if(tierLedger[from][i] == 0){
                    tierLedger[from][i] = block.timestamp;
                }
            }
            else{
                tierLedger[from][i] = 0;
            }

            if(toNewBal >= Tiers[i]){
                if(tierLedger[to][i] == 0){
                    tierLedger[to][i] = block.timestamp;
                }
            }
            else{
                tierLedger[to][i] = 0;
            }
        }
    }

    /**
    * @dev when governance forwarding is enabled in the token contract, this function is called when users call transfer
    * @param caller address that originally called transfer
    * @param to address to transfer tokens to
    * @param amount the amount of tokens to transfer
    **/
    function govAuthTransfer(
        address caller,
        address to,
        uint256 amount
    ) external onlyToken returns (bool) {
        require(GFI.balanceOf(caller) >= amount, "GOVERNANCE: Amount exceedes balance!");
        require(caller != to, "Gravity Finance: Forbidden");
        updateFee(caller);
        _updateFeeReceiver(to, amount);
        _updateUsersTiers(caller, to, amount);
        return true;
    }

    /**
    * @dev when governance forwarding is enabled in the token contract, this function is called when users call transferFrom
    * @param caller address that originally called transferFrom used to check if caller is allowed to spend from's tokens
    * @param from address to transfer tokens from
    * @param to address to transfer tokens to
    * @param amount the amount of tokens to transfer
    **/
    function govAuthTransferFrom(
        address caller,
        address from,
        address to,
        uint256 amount
    ) external onlyToken returns (bool) {
        require(GFI.allowance(from, caller) >= amount, "GOVERNANCE: Amount exceedes allowance!");
        require(GFI.balanceOf(from) >= amount, "GOVERNANCE: Amount exceedes balance!");
        require(from != to, "Gravity Finance: Forbidden");
        updateFee(from);
        _updateFeeReceiver(to, amount);
        _updateUsersTiers(from, to, amount);
        return true;
    }

    /**
    * @dev used to deposit wETH fees into the contract
    * @param amountWETH the amount of wETH to be sent into the governance contract
    * @param amountWBTC the amount of wBTC to be sent into the governance contract
    **/
    function depositFee(uint256 amountWETH, uint256 amountWBTC) external {
        require(
            WETH.transferFrom(msg.sender, address(this), amountWETH),
            "Failed to transfer wETH into contract!"
        );
        require(
            WBTC.transferFrom(msg.sender, address(this), amountWBTC),
            "Failed to transfer wBTC into contract!"
        );
        totalFeeCollected = totalFeeCollected + amountWETH;
        emit FeeDeposited(amountWETH, amountWBTC);
    }

    /**
    * @dev used to burn GFI and convert it into wBTC
    * @param amount the amount of GFI to burn
    **/
    function claimBTC(uint256 amount) external {
        require(
            amount > 10**18,
            "Amount too small, must be greater than 1 GFI token!"
        );
        require(
            GFI.transferFrom(msg.sender, address(this), amount),
            "Failed to transfer GFI to governance contract!"
        );
        uint256 WBTCowed =
            (amount * WBTC.balanceOf(address(this))) / GFI.totalSupply();
        require(GFI.burn(amount), "Failed to burn GFI!");
        require(
            WBTC.transfer(msg.sender, WBTCowed),
            "Failed to transfer wBTC to caller!"
        );
        emit WbtcClaimed(msg.sender, amount, WBTCowed);
    }
}