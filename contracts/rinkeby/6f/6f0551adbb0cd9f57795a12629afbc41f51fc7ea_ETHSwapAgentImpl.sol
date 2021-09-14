/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// File: contracts/interfaces/IERC20Query.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20Query {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/erc20/TokenInterface.sol

pragma solidity >=0.4.21 <0.6.0;
contract TokenInterface{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

// File: contracts/utils/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() public view returns (address payable) {
        return msg.sender;
    }

    function _msgData() public view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/ETHSwapAgentImpl.sol

pragma solidity >=0.4.21 <0.6.0;





contract ETHSwapAgentImpl is Context, Initializable {

    mapping(address => bool) public registeredERC20;
    mapping(bytes32 => bool) public filledBSCTx;
    address payable public owner;
    uint256 public swapFee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapPairRegister(address indexed sponsor,address indexed erc20Addr, string name, string symbol, uint8 decimals);
    event SwapStarted(address indexed erc20Addr, address indexed fromAddr, uint256 amount, uint256 feeAmount);
    event SwapFilled(address indexed erc20Addr, bytes32 indexed bscTxHash, address indexed toAddress, uint256 amount);

    constructor() public {
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function initialize(uint256 fee, address payable ownerAddr) public initializer {
        swapFee = fee;
        owner = ownerAddr;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        require(msg.sender == tx.origin, "no proxy contract is allowed");
       _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Returns set minimum swap fee from ERC20 to BEP20
     */
    function setSwapFee(uint256 fee) onlyOwner external {
        swapFee = fee;
    }

    function registerSwapPairToBSC(address erc20Addr) external returns (bool) {
        require(!registeredERC20[erc20Addr], "already registered");

        string memory name = IERC20Query(erc20Addr).name();
        string memory symbol = IERC20Query(erc20Addr).symbol();
        uint8 decimals = IERC20Query(erc20Addr).decimals();

        require(bytes(name).length>0, "empty name");
        require(bytes(symbol).length>0, "empty symbol");

        registeredERC20[erc20Addr] = true;

        emit SwapPairRegister(msg.sender, erc20Addr, name, symbol, decimals);
        return true;
    }

    function fillBSC2ETHSwap(bytes32 bscTxHash, address erc20Addr, address toAddress, uint256 amount) onlyOwner external returns (bool) {
        require(!filledBSCTx[bscTxHash], "bsc tx filled already");
        require(registeredERC20[erc20Addr], "not registered token");

        filledBSCTx[bscTxHash] = true;
        TokenInterface(erc20Addr).generateTokens(toAddress, amount);

        emit SwapFilled(erc20Addr, bscTxHash, toAddress, amount);
        return true;
    }

    function swapETH2BSC(address erc20Addr, uint256 amount) payable external notContract returns (bool) {
        require(registeredERC20[erc20Addr], "not registered token");
        require(msg.value == swapFee, "swap fee not equal");

        TokenInterface(erc20Addr).destroyTokens(msg.sender, amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit SwapStarted(erc20Addr, msg.sender, amount, msg.value);
        return true;
    }
}