/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.12;

interface IArmorMaster {
    function registerModule(bytes32 _key, address _module) external;
    function getModule(bytes32 _key) external view returns(address);
    function keep() external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev Completely default OpenZeppelin.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private __gap;
}

library Bytes32 {
    function toString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

/**
 * @dev Each arCore contract is a module to enable simple communication and interoperability. ArmorMaster.sol is master.
**/
contract ArmorModule {
    IArmorMaster internal _master;

    using Bytes32 for bytes32;

    modifier onlyOwner() {
        require(msg.sender == Ownable(address(_master)).owner(), "only owner can call this function");
        _;
    }

    modifier doKeep() {
        _master.keep();
        _;
    }

    modifier onlyModule(bytes32 _module) {
        string memory message = string(abi.encodePacked("only module ", _module.toString()," can call this function"));
        require(msg.sender == getModule(_module), message);
        _;
    }

    /**
     * @dev Used when multiple can call.
    **/
    modifier onlyModules(bytes32 _moduleOne, bytes32 _moduleTwo) {
        string memory message = string(abi.encodePacked("only module ", _moduleOne.toString()," or ", _moduleTwo.toString()," can call this function"));
        require(msg.sender == getModule(_moduleOne) || msg.sender == getModule(_moduleTwo), message);
        _;
    }

    function initializeModule(address _armorMaster) internal {
        require(address(_master) == address(0), "already initialized");
        require(_armorMaster != address(0), "master cannot be zero address");
        _master = IArmorMaster(_armorMaster);
    }

    function changeMaster(address _newMaster) external onlyOwner {
        _master = IArmorMaster(_newMaster);
    }

    function getModule(bytes32 _key) internal view returns(address) {
        return _master.getModule(_key);
    }
}

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

interface IARNXMVault {
    function unwrapWnxm() external;
    function buyNxmWithEther(uint256 _minAmount) external payable;
}

interface IClaimManager {
    function initialize(address _armorMaster) external;
    function transferNft(address _to, uint256 _nftId) external;
    function exchangeWithdrawal(uint256 _amount) external;
}

/**
 * @dev Quick interface for the Nexus Mutual contract to work with the Armor Contracts.
 **/

// to get nexus mutual contract address
interface INXMMaster {
    function tokenAddress() external view returns(address);
    function owner() external view returns(address);
    function pauseTime() external view returns(uint);
    function masterInitialized() external view returns(bool);
    function isPause() external view returns(bool check);
    function isMember(address _add) external view returns(bool);
    function getLatestAddress(bytes2 _contractName) external view returns(address payable contractAddress);
}

interface INXMPool {
    function buyNXM(uint minTokensOut) external payable;
}

interface IBFactory {
    function isBPool(address _pool) external view returns(bool);
}

interface IBPool {
    function swapExactAmountIn(address tokenin, uint256 inamount, address out, uint256 minreturn, uint256 maxprice) external returns(uint tokenAmountOut, uint spotPriceAfter);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint256 minReturn, address[] calldata path, address to, uint256 deadline) external payable returns(uint256[] memory);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/**
 * ExchangeManager contract enables us to slowly exchange excess claim funds for wNXM then transfer to the arNXM vault. 
**/
contract ExchangeManager is ArmorModule {
    
    address public exchanger;
    IARNXMVault public constant ARNXM_VAULT = IARNXMVault(0x1337DEF1FC06783D4b03CB8C1Bf3EBf7D0593FC4);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant WNXM = IERC20(0x0d438F3b5175Bebc262bF23753C1E53d03432bDE);
    INXMMaster public constant NXM_MASTER = INXMMaster(0x01BFd82675DBCc7762C84019cA518e701C0cD07e);
    IBFactory public constant BALANCER_FACTORY = IBFactory(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);
    IUniswapV2Router02 public constant UNI_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 public constant SUSHI_ROUTER = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    // Address allowed to exchange tokens.
    modifier onlyExchanger {
        require(msg.sender == exchanger, "Sender is not approved to exchange.");
        _;
    }

    // ClaimManager will be sending Ether to this contract.
    receive() external payable { }
    
    /**
     * @dev Initialize master for the contract. Owner must also add module for ExchangeManager to master upon deployment.
     * @param _armorMaster Address of the ArmorMaster contract.
    **/
    function initialize(address _armorMaster, address _exchanger)
      external
    {
        initializeModule(_armorMaster);
        exchanger = _exchanger;
    }
    
    /**
     * @dev Main function to withdraw Ether from ClaimManager, exchange, then transfer to arNXM Vault.
     * @param _amount Amount of Ether (in Wei) to withdraw from ClaimManager.
     * @param _minReturn Minimum amount of wNXM we will accept in return for the Ether exchanged.
    **/
    function buyWNxmUni(uint256 _amount, uint256 _minReturn, address[] memory _path)
      external
      onlyExchanger
    {
        _requestFunds(_amount);
        _exchangeAndSendToVault(address(UNI_ROUTER), _minReturn, _path);
    }
    
    /**
     * @dev Main function to withdraw Ether from ClaimManager, exchange, then transfer to arNXM Vault.
     * @param _amount Amount of Ether (in Wei) to withdraw from ClaimManager.
     * @param _minReturn Minimum amount of wNXM we will accept in return for the Ether exchanged.
    **/
    function buyWNxmSushi(uint256 _amount, uint256 _minReturn, address[] memory _path)
      external
      onlyExchanger
    {
        _requestFunds(_amount);
        _exchangeAndSendToVault(address(SUSHI_ROUTER), _minReturn, _path);
    }

    function buyWNxmBalancer(uint256 _amount, address _bpool, uint256 _minReturn, uint256 _maxPrice)
      external
      onlyExchanger
    {
        require(BALANCER_FACTORY.isBPool(_bpool), "NOT_BPOOL");
        _requestFunds(_amount);
        uint256 balance = address(this).balance;
        IWETH(address(WETH)).deposit{value:balance}();
        WETH.approve(_bpool, balance);
        IBPool(_bpool).swapExactAmountIn(address(WETH), balance, address(WNXM), _minReturn, _maxPrice);
        _transferWNXM();
        ARNXM_VAULT.unwrapWnxm();
    }
    
    /**
     * @dev Main function to withdraw Ether from ClaimManager, exchange, then transfer to arNXM Vault.
     * @param _ethAmount Amount of Ether (in Wei) to withdraw from ClaimManager.
     * @param _minNxm Minimum amount of NXM we will accept in return for the Ether exchanged.
    **/
    function buyNxm(uint256 _ethAmount, uint256 _minNxm)
      external
      onlyExchanger
    {
        _requestFunds(_ethAmount);
        ARNXM_VAULT.buyNxmWithEther{value:_ethAmount}(_minNxm);
    }

    /**
     * @dev Call ClaimManager to request Ether from the contract.
     * @param _amount Ether (in Wei) to withdraw from ClaimManager.
    **/
    function _requestFunds(uint256 _amount)
      internal
    {
        IClaimManager( getModule("CLAIM") ).exchangeWithdrawal(_amount);
    }
 
    /**
     * @dev Exchange all Ether for wNXM on uniswap-like exchanges
     * @param _router router address of uniswap-like protocols(uni/sushi)
     * @param _minReturn Minimum amount of wNXM we wish to receive from the exchange.
    **/
    function _exchangeAndSendToVault(address _router, uint256 _minReturn, address[] memory _path)
      internal
    {
        uint256 ethBalance = address(this).balance;
        IUniswapV2Router02(_router).swapExactETHForTokens{value:ethBalance}(_minReturn, _path, address(ARNXM_VAULT), uint256(~0) );
        ARNXM_VAULT.unwrapWnxm();
    }
    
    /**
     * @dev Transfer all wNXM directly to arNXM. This will not mint more arNXM so it will add value to arNXM.
    **/
    function _transferWNXM()
      internal
    {
        uint256 wNxmBalance = WNXM.balanceOf( address(this) );
        WNXM.transfer(address(ARNXM_VAULT), wNxmBalance);
    }

    /**
     * @dev Transfer all NXM directly to arNXM. This will not mint more arNXM so it will add value to arNXM.
    **/
    function _transferNXM()
      internal
    {
        IERC20 NXM = IERC20(NXM_MASTER.tokenAddress());
        uint256 nxmBalance = NXM.balanceOf( address(this) );
        NXM.transfer(address(ARNXM_VAULT), nxmBalance);
    }
    
    /**
     * @dev Owner may change the address allowed to exchange tokens.
     * @param _newExchanger New address to make exchanger.
    **/
    function changeExchanger(address _newExchanger)
      external
      onlyOwner
    {
        exchanger = _newExchanger;
    }
    
}