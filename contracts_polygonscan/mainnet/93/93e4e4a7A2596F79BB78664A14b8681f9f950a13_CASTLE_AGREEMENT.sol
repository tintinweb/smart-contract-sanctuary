/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/proxy/utils/[email protected]
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
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


// File contracts/interfaces/ICASTLE_IDO_Agreement.sol

interface ICASTLE_IDO_Agreement {
    function initialize(address _owner, address _IDOImplementation) external;
    function locked() external view returns (bool);
    function owner() external view returns (address);
    function percentDecimals() external view returns(uint);
    function IDOImplementation() external view returns(address);
    function saleToken() external view returns (address);
    function IDOToken() external view returns (address);
    function price()external view returns(uint);
    function totalAmount()external view returns(uint);
    function saleStart()external view returns(uint);
    function commission()external view returns(uint);
    function GFIcommission() external view returns(address);
    function treasury() external view returns(address);
    function GFISudoUser() external view returns(address);
    function clientSudoUser() external view returns(address);
    function roundDelay(uint i) external view returns(uint);
    function maxPerRound(uint i) external view returns(uint);
    function staggeredStart() external view returns(bool);
    function whaleStopper() external view returns(uint);
    function commissionCap() external view returns(uint);
}


// File contracts/LaunchPad/CASTLE_AGREEMENT.sol


/**
 * @title Basic IDO Agreement contract for NFTs that offers GFI Tier presale, and First Come First Serve Model
 * @author crispymangoes
 * @notice Actual IDO Agreement contract is a minimal proxy implementation deployed by the IDO Factory
 */
contract CASTLE_AGREEMENT is Initializable, ICASTLE_IDO_Agreement{
    bool public override locked; /// @dev bool used to irreversibly lock agreement once finalzed 
    address public override owner; /// @dev address of the owner of the agreement 
    uint constant public override percentDecimals = 10000; /// @dev shows percision

    address public override IDOImplementation; /// @dev address of the IDO implementation to use for IDO logic 
    address public override saleToken; /// @dev address of the token participants use to buy the IDO token 
    address public override IDOToken; /// @dev not used, but needed by the factory to create salt 
    uint public override price; /// @dev the price of the IDO token w/r/t the sale token ie 0.000025 wETH/GFI 
    uint public override totalAmount; /// @dev the total amount of tokens to be sold in the sale be mindful of decimals 
    uint public override saleStart; /// @dev timestamp for when sale starts 
    uint public override commission; /// @dev number from 0 -> 10000 representing 00.00% -> 100.00% commission for the sale s
    address public override GFIcommission; /// @dev where commission is sent 
    address public override treasury; /// @dev where sale procedes are sent
    address public override GFISudoUser; /// @dev Gravity Finance address with elevated IDO privelages 
    address public override clientSudoUser; /// @dev Client address with elevated IDO privelages 
    uint[4] public override roundDelay; /// @dev determines what times rounds start
    uint[4] public override maxPerRound; /// @dev max amount a tier can buy per round
    bool public override staggeredStart; /// @dev controls whether all gfi tiers can mint at the same time(if false), or if tier 3 is allowed to mint before tier 2 and so on(true)
    uint public override whaleStopper; /// @dev controls the max amount of tokens that can be bought per Tx
    uint public override commissionCap; /// @dev caps the amount of commission Gravity can take

    /**
     * @notice modifier used to make sure variables are immutable once locked
     */
    modifier checkLock() {
        require(!locked, 'Gravity Finance: Agreement locked');
        _;
    }

    /**
     * @notice modifier used to make all functions only callable by privelaged address
     */
    modifier onlyOwner(){
        require(msg.sender == owner, 'Gravity Finance: Caller not owner');
        _;
    }

    /**
     * @notice called by IDO factory upon creation
     * @dev only callable ONCE
     */
    function initialize(address _owner, address _IDOImplementation) external override initializer{
        owner = _owner;
        GFISudoUser = _owner; //make the owner of this contract a sudo for the IDO contract
        IDOImplementation = _IDOImplementation;
    }

    /****************** External Priviledged Functions ******************/
    /**
     * @notice used to lock variables as long as they pass several logic require checks
     */
    function lockVariables() external onlyOwner checkLock{
        require(GFIcommission != address(0), 'Gravity Finance: Commission address not set');
        require(saleToken != address(0), 'Gravity Finance: sale Token address not set');
        require(price > 0, 'Gravity Finance: Price not set');
        require(saleStart > 0, 'Gravity Finance: saleStart not set');
        require(commission > 0 && commission <= 10000, 'Gravity Finance: Comission not correct');
        require(clientSudoUser != address(0), 'Gravity Finance: Client Sudo User not set');
        require(treasury != address(0), 'Gravity Finance: Treasury not set');
        require(whaleStopper > 0, 'Gravity Finance: whaleStopper not set');
        require(commissionCap > 0, 'Gravity Finance: commissionCap not set');
        locked = true;
    }

    function setGFICommission(address _address) external onlyOwner checkLock{
        GFIcommission = _address;
    }

    function setSaleToken(address _saleToken) external onlyOwner checkLock{
        saleToken = _saleToken;
    }

    function setPrice(uint _price) external onlyOwner checkLock{
        price = _price;
    }

    function setTotalAmount(uint _totalAmount) external onlyOwner checkLock{
        totalAmount = _totalAmount;
    }

    function setSaleStart(uint _saleStart) external onlyOwner checkLock{
        saleStart = _saleStart;
    }

    function setCommission(uint _commission) external onlyOwner checkLock{
        commission = _commission;
    }

    function adjustClientSudoUsers(address _address) external onlyOwner checkLock{
        clientSudoUser = _address;
    }

    function setTreasury(address _address) external onlyOwner checkLock{
        treasury = _address;
    }

    function adjustRoundDelay(uint[4] memory _delay) external onlyOwner checkLock{
        require(_delay[3] <= _delay[2] && _delay[2] <= _delay[1] && _delay[1] <= _delay[0], "Delays must be equal or in descending order");
        roundDelay = _delay;
    }

    function adjustMaxPerRound(uint[4] memory _max) external onlyOwner checkLock{
        require(_max[3] >= _max[2] && _max[2] >= _max[1] && _max[1] >= _max[0], "Max must be equal or go in ascending order");
        maxPerRound = _max;
    }

    function adjustStaggeredStart(bool _state) external onlyOwner checkLock{
        staggeredStart = _state;
    }

    function setWhaleStopper(uint _amount) external onlyOwner checkLock{
        whaleStopper = _amount;
    }

    function setCommissionCap(uint _cap) external onlyOwner checkLock{
        commissionCap = _cap;
    }
}