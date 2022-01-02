pragma solidity >=0.6.2;

interface ISwapper {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

		function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

pragma solidity >=0.8.9 <0.9.0;
//SPDX-License-Identifier: MIT

import "../node_modules/@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

import "./ISwapper.sol";
import "./XToken.sol";



/*
  Hello and welcome to the ShibaBurn burning portal.
    This is a contract that empowers developers to
    create incentive based deflation for all ERC20 tokens!

  ShibaBurn allows for an infinite number of burn pools
  to be created for any given token. By default, burn pools track the following data:
    - total tokens burnt by each user
    - total tokens burnt by all users

  ShibaBurn also allows for ETH to be "zapped" into burn pool ownershib by means of
  buying the specified token on ShibaSwap, and burning it in one transaction. This
  is only possible if eth-token liquidity is present on ShibaSwap.com


  If configured by the ShibaBurn owner wallet, burn pools can optionally:
    - Mint xTokens for users (e.g. burntSHIB in the case of burning SHIB to the default pool)
    - Keep track of the index at which any given address exceeds a burnt amount beyond an admin specified threshold

          _____                    _____                    _____                    _____                    _____          
         /\    \                  /\    \                  /\    \                  /\    \                  /\    \         
        /::\    \                /::\____\                /::\    \                /::\    \                /::\    \        
       /::::\    \              /:::/    /                \:::\    \              /::::\    \              /::::\    \       
      /::::::\    \            /:::/    /                  \:::\    \            /::::::\    \            /::::::\    \      
     /:::/\:::\    \          /:::/    /                    \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
    /:::/__\:::\    \        /:::/____/                      \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
    \:::\   \:::\    \      /::::\    \                      /::::\    \      /::::\   \:::\    \      /::::\   \:::\    \   
  ___\:::\   \:::\    \    /::::::\    \   _____    ____    /::::::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \  
 /\   \:::\   \:::\    \  /:::/\:::\    \ /\    \  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\ ___\  /:::/\:::\   \:::\    \ 
/::\   \:::\   \:::\____\/:::/  \:::\    /::\____\/::\   \/:::/  \:::\____\/:::/__\:::\   \:::|    |/:::/  \:::\   \:::\____\
\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /\:::\  /:::/    \::/    /\:::\   \:::\  /:::|____|\::/    \:::\  /:::/    /
 \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /  \:::\/:::/    / \/____/  \:::\   \:::\/:::/    /  \/____/ \:::\/:::/    / 
  \:::\   \:::\    \               \::::::/    /    \::::::/    /            \:::\   \::::::/    /            \::::::/    /  
   \:::\   \:::\____\               \::::/    /      \::::/____/              \:::\   \::::/    /              \::::/    /   
    \:::\  /:::/    /               /:::/    /        \:::\    \               \:::\  /:::/    /               /:::/    /    
     \:::\/:::/    /               /:::/    /          \:::\    \               \:::\/:::/    /               /:::/    /     
      \::::::/    /               /:::/    /            \:::\    \               \::::::/    /               /:::/    /      
       \::::/    /               /:::/    /              \:::\____\               \::::/    /               /:::/    /       
        \::/    /                \::/    /                \::/    /                \::/____/                \::/    /        
         \/____/                  \/____/                  \/____/                  ~~                       \/____/         
                                                                                                                             
                          _____                    _____                    _____                    _____                   
                         /\    \                  /\    \                  /\    \                  /\    \                  
                        /::\    \                /::\____\                /::\    \                /::\____\                 
                       /::::\    \              /:::/    /               /::::\    \              /::::|   |                 
                      /::::::\    \            /:::/    /               /::::::\    \            /:::::|   |                 
                     /:::/\:::\    \          /:::/    /               /:::/\:::\    \          /::::::|   |                 
                    /:::/__\:::\    \        /:::/    /               /:::/__\:::\    \        /:::/|::|   |                 
                   /::::\   \:::\    \      /:::/    /               /::::\   \:::\    \      /:::/ |::|   |                 
                  /::::::\   \:::\    \    /:::/    /      _____    /::::::\   \:::\    \    /:::/  |::|   | _____           
                 /:::/\:::\   \:::\ ___\  /:::/____/      /\    \  /:::/\:::\   \:::\____\  /:::/   |::|   |/\    \          
                /:::/__\:::\   \:::|    ||:::|    /      /::\____\/:::/  \:::\   \:::|    |/:: /    |::|   /::\____\         
                \:::\   \:::\  /:::|____||:::|____\     /:::/    /\::/   |::::\  /:::|____|\::/    /|::|  /:::/    /         
                 \:::\   \:::\/:::/    /  \:::\    \   /:::/    /  \/____|:::::\/:::/    /  \/____/ |::| /:::/    /          
                  \:::\   \::::::/    /    \:::\    \ /:::/    /         |:::::::::/    /           |::|/:::/    /           
                   \:::\   \::::/    /      \:::\    /:::/    /          |::|\::::/    /            |::::::/    /            
                    \:::\  /:::/    /        \:::\__/:::/    /           |::| \::/____/             |:::::/    /             
                     \:::\/:::/    /          \::::::::/    /            |::|  ~|                   |::::/    /              
                      \::::::/    /            \::::::/    /             |::|   |                   /:::/    /               
                       \::::/    /              \::::/    /              \::|   |                  /:::/    /                
                        \::/____/                \::/____/                \:|   |                  \::/    /                 
                         ~~                       ~~                       \|___|                   \/____/                  
                                                                                                                             




*/



contract ShibaBurn is Ownable {

  // ShibaSwap router:
  ISwapper public router = ISwapper(0x03f7724180AA6b939894B5Ca4314783B0b36b329);

  // Ledgendary burn address that holds tokens burnt of the SHIB ecosystem:
  address public burnAddress = 0xdEAD000000000000000042069420694206942069;
  address public wethAddress;

  // Addresses of SHIB ecosystem tokens:
  address public shibAddress = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
  address public boneAddress = 0x9813037ee2218799597d83D4a5B6F3b6778218d9;
  address public leashAddress = 0x27C70Cd1946795B66be9d954418546998b546634;
  address public ryoshiAddress = 0x777E2ae845272a2F540ebf6a3D03734A5a8f618e;

  event Burn(address sender, uint256 time, address tokenAddress, uint256 poolIndex, uint256 amount);

  //////////////
  // BURN POOLS:
  //////////////
  //
  // xTokens[tokenAddress][poolIndex]
  //   => address of pool's xToken
  mapping(address => mapping(uint256 => address)) public xTokens;

  // totalBurnt[tokenAddress][poolIndex]
  //   => total amount burnt for specified pool
  mapping(address => mapping(uint256 => uint256)) public totalBurnt;

  // totalTrackedBurners[tokenAddress][poolIndex]
  //    => total number of burners that have exceeded the trackBurnerIndexThreshold
  mapping(address => mapping(uint256 => uint256)) public totalTrackedBurners;

  // trackBurnerIndexThreshold[tokenAddress][poolIndex]
  //    => the burn threshold required to track user burn indexes of a specific pool
  mapping(address => mapping(uint256 => uint256)) public trackBurnerIndexThreshold;

  // burnerIndex[tokenAddress][poolIndex][userAddress]
  //    => the index at which a user exceeded the trackBurnerIndexThreshold for a specific pool
  mapping(address => mapping(uint256 => mapping(address => uint256))) public burnerIndex;


  // burnerIndex[tokenAddress][poolIndex][burnerIndex]
  //    => the address of the a specified tracked burner at a specified index
  mapping(address => mapping(uint256 => mapping(uint256 => address))) public burnersByIndex;

  // amountBurnt[tokenAddress][poolIndex][userAddress]
  //   => amount burnt by a specific user for a specified pool
  mapping(address => mapping(uint256 => mapping(address => uint256))) public amountBurnt;

  constructor(address _wethAddress) Ownable() {
    wethAddress = _wethAddress;
  }

 /** 
   * @notice Intended to be used for web3 interface, such that all data can be pulled at once
   * @param tokenAddress The address of the token for which the query will be made
   * @param currentUser The address used to query user-based pool info and ethereum balance
   * @return burnPool info for the default pool (0) of the specified token
	*/
  function getInfo(address currentUser, address tokenAddress) public view returns (uint256[] memory) {
    return getInfoForPool(0, currentUser, tokenAddress);
  }

  /**
   * @notice Intended to be used for web3 interface, such that all data can be pulled at once
   * @param poolIndex The index of which token-specific burn pool to be used
   * @param tokenAddress The address of the token for which the query will be made
   * @param currentUser The address used to query user-based pool info and ethereum balance
   *
   * @return burnPool info for the specified pool of the specified token as an  array of 11 integers indicating the following:
   *     (0) Number of decimals of the token associated with the tokenAddress
   *     (1) Total amount burnt for the specified burn-pool
   *     (2) Total amount burnt by the specified currentUser for the specified burn-pool
   *     (3) The amount of specified tokens in possession by the specified currentUser
   *     (4) The amount of eth in the wallet of the specified currentUser
   *     (5) The amount of specified tokens allowed to be burnt by this contract
   *     (6) The threshold of tokens needed to be burnt to track the index of a user for the specified pool (if zero, no indexes will be tracked)
   *     (7) Burn index of the current user with regards to a specified pool (only tracked if admin configured, and burn meets threshold requirements)
   *     (8) Total number of burners above the specified threshold for the specific pool
   *     (9) Decimal integer representation of the address of the 'xToken' of the specified pool
   *     (10) Total supply of the xToken associated with the specified pool
   *     (11) Specified pool's xToken balance of currentUser
  */
  function getInfoForPool(uint256 poolIndex, address currentUser, address tokenAddress) public view returns (uint256[] memory) {
    uint256[] memory info = new uint256[](10);
    IERC20Metadata token = IERC20Metadata(tokenAddress);
    info[0] = token.decimals();
    info[1] = totalBurnt[tokenAddress][poolIndex];
    info[2] = amountBurnt[tokenAddress][poolIndex][currentUser];
    info[3] = token.balanceOf(currentUser);
    info[4] = currentUser.balance;
    info[5] = token.allowance(currentUser, address(this));

    if (trackBurnerIndexThreshold[tokenAddress][poolIndex] != 0) {
			info[6] = trackBurnerIndexThreshold[tokenAddress][poolIndex];
			info[7] = burnerIndex[tokenAddress][poolIndex][currentUser];
			info[8] = totalTrackedBurners[tokenAddress][poolIndex];
		}

    if (xTokens[tokenAddress][poolIndex] != address(0)) {
      IERC20Metadata xToken = IERC20Metadata(xTokens[tokenAddress][poolIndex]);
      info[9] = uint256(uint160(address(xToken)));
      info[10] = xToken.totalSupply();
      info[11] = xToken.balanceOf(currentUser);
    }

    return info;
  }

  /**
   * @notice Intended to be used for web3 such that all necessary data can be requested at once
   * @param tokenAddress The address of the token to buy on shibaswap.
   * @return Name and Symbol metadata of specified ERC20 token.
  */
  function getTokenInfo(address tokenAddress) public view returns (string[] memory) {
    string[] memory info = new string[](2);
    IERC20Metadata token = IERC20Metadata(tokenAddress);
    info[0] = token.name();
    info[1] = token.symbol();

    return info;
  }

  /**
   * @param tokenAddress The address of the token to buy on shibaswap.
   * @param minOut specifies the minimum number of tokens to be burnt when buying (to prevent front-runner attacks)
   *
   * @notice Allows users to buy tokens (with ETH on ShibaSwap) and burn them in 1 tx for the
   *     "default" burn pool for the specified token. Based on the admin configuration of each pool,
   *     xTokens may be issued, and/or the burner's index will be tracked.
  */
  function buyAndBurn(address tokenAddress, uint256 minOut) public payable {
    buyAndBurnForPool(tokenAddress, minOut, 0);
  }

  /**
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param threshold the minimum amount of tokens required to be burnt for the burner's index to be tracked
   *
   * @dev This can only be set on pools with no burns
   * @notice Allows the admin address to mark a specific pool as tracking "indexes" of burns above a specific threshold.
   *     This allows for projects to reward users based on how early they burned more than the specified amount.
   *     Setting this threshold will cause each burn to require more gas.
  */
  function trackIndexesForPool(address tokenAddress, uint256 poolIndex, uint256 threshold) public onlyOwner {
    require (totalBurnt[tokenAddress][poolIndex] == 0, "tracking indexes can only be turned on for pools with no burns");
    trackBurnerIndexThreshold[tokenAddress][poolIndex] = threshold;
  }

  /**
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param xTokenAddress the address of the xToken that will be minted in exchange for burning
   *
   * @notice Allows the admin address to set an xToken address for a specific pool.
   * @dev It is required for this contract to have permission to mint the xToken
  */
  function setXTokenForPool(address tokenAddress, uint256 poolIndex, address xTokenAddress) public onlyOwner {
    require (totalBurnt[tokenAddress][poolIndex] == 0, "xToken can only be set on pools with no burns");
    xTokens[tokenAddress][poolIndex] = xTokenAddress;
  }

  /**
   * @notice Allows users to buy tokens (with ETH on ShibaSwap) and burn them in 1 tx.
   *         Based on the admin configuration of each pool, xTokens may be issued,
   *         and the burner's index will be tracked.
   *
   * @dev uses hard coded shibaswap router address
   *
   * @param tokenAddress The address of the token to buy on shibaswap.
   * @param minOut specifies the minimum number of tokens to be burnt when buying (to prevent front-runner attacks)
   * @param poolIndex the index of which token-specific burn pool to be used
   *
  */
  function buyAndBurnForPool(address tokenAddress, uint256 minOut, uint256 poolIndex) public payable {
    address[] memory ethPath = new address[](2);
    ethPath[0] = wethAddress; // WETH
    ethPath[1] = tokenAddress;
    IERC20Metadata token = IERC20Metadata(tokenAddress);

    uint256 balanceWas = token.balanceOf(burnAddress);
    router.swapExactETHForTokens{ value: msg.value }(minOut, ethPath, burnAddress, block.timestamp + 1000);
    uint256 amount = token.balanceOf(burnAddress) - balanceWas;

    _increaseOwnership(tokenAddress, poolIndex, amount);
  }

  /**
   * @dev internal method
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param amount the amount of tokens intended to be burnt
   *
   * @return boolean value which indicates whether or not the burner's burn index should be tracked for the current transaction.
  */
  function shouldTrackIndex(address tokenAddress, uint256 poolIndex, uint256 amount) internal returns (bool) {
    uint256 threshold = trackBurnerIndexThreshold[tokenAddress][poolIndex];
    uint256 alreadyBurnt = amountBurnt[tokenAddress][poolIndex][msg.sender];
    return threshold != 0 &&
      alreadyBurnt < threshold &&
      alreadyBurnt + amount >= threshold;
  }

  /**
   * @notice increases ownership of specified pool.
   * @dev tracks the user's burn Index if configured
   * @dev mints xTokens for the user if configured
   * @dev internal method
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param amount of tokens intended to be burnt
   *
  */
  function _increaseOwnership(address tokenAddress, uint256 poolIndex, uint256 amount) internal {
    if (shouldTrackIndex(tokenAddress, poolIndex, amount)) {
      burnerIndex[tokenAddress][poolIndex][msg.sender] = totalTrackedBurners[tokenAddress][poolIndex];
      burnersByIndex[tokenAddress][poolIndex][totalTrackedBurners[tokenAddress][poolIndex]] = msg.sender;
      totalTrackedBurners[tokenAddress][poolIndex] += 1;
    }

    if (xTokens[tokenAddress][poolIndex] != address(0))
      XToken(xTokens[tokenAddress][poolIndex]).mint(msg.sender, amount);

    amountBurnt[tokenAddress][poolIndex][msg.sender] = amountBurnt[tokenAddress][poolIndex][msg.sender] + amount;
    totalBurnt[tokenAddress][poolIndex] += amount;
    emit Burn(msg.sender, block.timestamp, tokenAddress, poolIndex, amount);
  }

  /**
   * @notice Burns SHIB to the default SHIB pool
   * @param amount the amount of SHIB to be burnt 
  */
  function burnShib(uint256 amount) public {
    burnToken(shibAddress, amount);
  }

  /**
   * @notice Burns RYOSHI to the default RYOSHI pool
   * @param amount the amount of RYOSHI to be burnt 
  */
  function burnRyoshi(uint256 amount) public {
    burnToken(ryoshiAddress, amount);
  }

  /**
   * @notice Burns LEASH to the default LEASH pool
   * @param amount the amount of LEASH to be burnt 
   *
  */
  function burnLeash(uint256 amount) public {
    burnToken(leashAddress, amount);
  }

  /**
   * @notice Burns BONE to the default BONE pool
   * @param amount the amount of BONE to be burnt 
   *
  */
  function burnBone(uint256 amount) public {
    burnToken(boneAddress, amount);
  }

  /**
   * @notice Burns any token to the default (0) pool for that token
   * @param tokenAddress the address of the token intended to be burnt
   * @param amount the amount of tokens to be burnt 
   *
  */
  function burnToken(address tokenAddress, uint256 amount) public {
    burnTokenForPool(tokenAddress, 0, amount);
  }

  /**
   * @notice Burns any token to the specified pool for that token
   * @param tokenAddress the address of the token intended to be burnt
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param amount the amount of tokens to be burnt 
   *
  */
  function burnTokenForPool(address tokenAddress, uint256 poolIndex, uint256 amount) public {
    IERC20Metadata token = IERC20Metadata(tokenAddress);
    require (token.balanceOf(msg.sender) >= amount, "insufficient token balance");

    token.transferFrom(msg.sender, burnAddress, amount);
    _increaseOwnership(tokenAddress, poolIndex, amount);
  }

}

pragma solidity >=0.8.9 <0.9.0;
//SPDX-License-Identifier: MIT

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract XToken is ERC20, Ownable {

  constructor(address shibaBurner, string memory name, string memory symbol)
  ERC20(name, symbol)
  Ownable()
  {
    transferOwnership(shibaBurner);
  }

  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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