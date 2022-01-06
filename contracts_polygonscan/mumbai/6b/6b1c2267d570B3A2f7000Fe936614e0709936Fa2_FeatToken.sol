// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

import "./FeatStaking.sol";
import "./Vaults/FeatOwnerVault.sol";
import "./FeatSwap.sol";
import "./FeatFactory.sol";
import "./Vaults/FeatCoreVault.sol";

/**
  * @notice Feat is the governance Token project, mint tokens are sent directly to the Owner Vault contract
  */
contract FeatToken is ERC20Burnable, ERC20Capped {
    /**
      * @notice Create the token, deploy dependant contracts of the Feat project and calculate/mint respective part of the token supply
      */
    constructor() ERC20("Feat", "FEAT") ERC20Capped(100000000 * 10 ** 18) {
        bytes memory stakingBytecode = type(FeatStaking).creationCode;
        bytes memory ownerVaultBytecode = type(FeatOwnerVault).creationCode;
        bytes memory swapBytecode= type(FeatSwap).creationCode;
        bytes memory factoryBytecode = type(FeatFactory).creationCode;
        bytes memory coreVaultBytecode = type(FeatCoreVault).creationCode;
        uint stakingPart = cap() * 800 / 10000;
        bytes32 salt = keccak256("Feat");
        address staking;
        address ownerVault;
        address swap;
        address factory;
        address coreVault;
        assembly {
          staking := create2(0, add(stakingBytecode, 0x20), mload(stakingBytecode), salt)
          if iszero(extcodesize(staking)) {
                revert(0, 0)
            }
          ownerVault := create2(0, add(ownerVaultBytecode, 0x20), mload(ownerVaultBytecode), salt)
          if iszero(extcodesize(ownerVault)) {
                revert(0, 0)
            }
          swap := create2(0, add(swapBytecode, 0x20), mload(swapBytecode), salt)
          if iszero(extcodesize(ownerVault)) {
                revert(0, 0)
            }
          factory := create2(0, add(factoryBytecode, 0x20), mload(factoryBytecode), salt)
          if iszero(extcodesize(ownerVault)) {
                revert(0, 0)
            }
          coreVault := create2(0, add(coreVaultBytecode, 0x20), mload(coreVaultBytecode), salt)
          if iszero(extcodesize(ownerVault)) {
                revert(0, 0)
            }  
        }
        FeatStaking(staking).init(address(this), stakingPart);
        FeatOwnerVault(ownerVault).init(address(this));
        FeatOwnerVault(ownerVault).transferOwnership(msg.sender);
        FeatFactory(factory).init(address(this), swap);
        FeatFactory(factory).transferOwnership(msg.sender);
        FeatSwap(swap).init(factory, address(this), coreVault, 30);
        FeatCoreVault(coreVault).init(address(this), ownerVault, factory, swap);
        FeatCoreVault(coreVault).transferOwnership(msg.sender);
        _mint(staking, stakingPart);
        _mint(ownerVault, cap() * 9200 / 10000);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/** 
  * @notice The launching staking contract for rewarding $FEAT holders.
  *         Rewards are distributed on a period of 2 years from a fixed supply
  *         corresponding to 8% of the FEAT max supply.
  */
contract FeatStaking is ERC20Upgradeable {
    /** @notice the $FEAT token */
    ERC20Upgradeable public feat;

    /** 
      * @dev the number used to retrieve the amount of rewards 
      *      corresponding to a gived time window.
      *         prorata = total of rewards to distribute * full time window
      *         rewards = prorata * time window
      */
    uint private prorata;
    /** @notice the beginning of rewards distribution timestamp */
    uint public startTimestamp;
    /** @notice the total of rewards to distribute */
    uint public startRewards;
    /** @dev the total of distributed rewards */
    uint private givenRewards;
    /** @dev the sum of all locked $FEAT by holders */
    uint private totalStaked;

    /** @dev a ledger of the amount of $FEAT locked by users */
    mapping (address => uint) private staked;

    event Initialized(uint _startRewards, uint duringTimestamp, uint startTimestamp);
    event EnterStake(address _from, uint _givenFeat, uint _mintedShares, uint timestamp);
    event ExitStake(address _from, uint _receivedFeat, uint _burnedShares, uint timestamp);

    /** 
      * @dev initialize contract by setting up the staked token representating the shares,
      *      the amount of rewards to distribute, the window time and the prorata to calculate rewards
     */
    function init(address _feat, uint _startRewards) external initializer {
        feat = ERC20Upgradeable(_feat);
        __ERC20_init("Staked Feat", "sFEAT");
        startRewards = _startRewards;
        startTimestamp = block.timestamp;
        prorata = startRewards / (31556926 * 2);
        emit Initialized(startRewards, (31556926 * 2), startTimestamp);
    }

    /**
      * @notice Deposit FEAT in this contract and mint sFEAT in exchange
      *         which represents shares of deposited FEAT for
      *         withdrawing deposited FEAT + rewards later.
      *
      * @param _amount the amount of FEAT to deposit
      */
    function stake(uint _amount) external {
        // can't enter in pool if no more rewards is available
        require(givenRewards < startRewards, "FeatStaking: staking ended");
        uint totalFeatContract = totalStaked + getAvailableRewards();
        uint shares;
        if (totalSupply() == 0) {
            // first user to enter, get 100% of the shares
            shares = _amount;
            _mint(msg.sender, shares);
        }
        else {
            shares = _amount * totalSupply() / totalFeatContract;
            _mint(msg.sender, shares);
        }
        staked[msg.sender] += _amount;
        totalStaked += _amount;
        feat.transferFrom(msg.sender, address(this), _amount);
        emit EnterStake(msg.sender, _amount, shares, block.timestamp);
    }

    /**
      * @notice Withdraw deposited FEAT and new rewards by burning the shares.
      *
      * @param _shares the amount of shares to burn */
    function withdraw(uint _shares) external {
        (uint userStaked, uint waitingRewards, uint amount) = getActualAmounts();
        givenRewards += waitingRewards;
        totalStaked -= amount - (amount - userStaked);
        staked[msg.sender] -= amount - (amount - userStaked);
        _burn(msg.sender, _shares);
        feat.transfer(msg.sender, amount);
        emit ExitStake(msg.sender, amount, _shares, block.timestamp);
    }

    /**
      * @notice Retrieve how many FEAT the caller have deposited,
      *         how many new rewards he got, and the total available to withdraw
      *
      * @return isStaked the total amount of deposited FEAT 
      * @return waitingRewards the current rewards he got
      * @return total the sum of 'isStaked' and 'waitingRewards' 
      */
    function getActualAmounts() public view returns (uint isStaked, uint waitingRewards, uint total) {
        isStaked = staked[msg.sender];
        uint totalFeatContract = totalStaked + getAvailableRewards();
        uint totalUserShares = balanceOf(msg.sender);
        total = totalUserShares * totalFeatContract / totalSupply();
        waitingRewards = total - staked[msg.sender];
    }

    /** 
      * @notice Retrieve the current annual percentage rate (APR)
      * @dev This function basically just simulate a deposit and withdraw 1 year later
      *      to get how many FEAT we obtain after one year.
      *      Percentage calculation should be done on front with a divide on 100.
      *
      * @return the amount of received FEAT after one year (with a unit precision of 0,01)
      *         (i.e returned: 12345 -> 123%)
      */
    function getActualAPR() external view returns (uint){
        uint shares;
        if (totalSupply() == 0){
            shares = 1 ether;
        }
        else {
            uint totalFeatContract = totalStaked + getAvailableRewards();
            shares = 1 ether * totalSupply() / totalFeatContract;
        }
        uint timeSinceInit1yLater = block.timestamp + 31556926 - startTimestamp;
        uint unlockedIn1y = prorata * timeSinceInit1yLater;
        if(unlockedIn1y > startRewards){
            unlockedIn1y = startRewards;
        }
        uint totalFeatContractAfter1y = totalStaked + 1 ether + (unlockedIn1y - givenRewards);
        uint totalAfter1y = shares * totalFeatContractAfter1y / (totalSupply() + shares);
        return ((totalAfter1y * 10000 / 1 ether) - 10000);
    }

    /** @notice Retrieve the current unlocked rewards */
    function getUnlockedRewards() public view returns (uint) {
        uint timeSinceInit = (block.timestamp - startTimestamp);
        uint unlocked = prorata * timeSinceInit;
        if(unlocked > startRewards){
            return startRewards;
        }
        else return unlocked;
    }

    /** @notice Retrieve the unlocked and non-distributed rewards */
    function getAvailableRewards() public view returns (uint) {
        return getUnlockedRewards() - givenRewards;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** 
  * @notice Vault of the Feat Plateform, the officiel FEAT reserve
  */
contract FeatOwnerVault is Ownable {
    address public featToken;

    /** @dev false if not initialized, true if it is */
    bool private state;

    event Initalized(address _featToken);
    event OnOut(uint _amount, address _to, uint timestamp);

    /** 
      * @notice Initialize the vault to be used with the given address Token
      * 
      * @param _featToken the address of the governance token 
      * */
    function init(address _featToken) external onlyOwner {
        require(state == false, "FeatOwnerVault: already initialized");
        require(_featToken != address(0), "FeatOwnerVault: incorrect token address");
        state = true;
        featToken = _featToken;
        emit Initalized(_featToken);
    }

    modifier isInitialized() {
        require(state == true, "FeatOwnerVault: not initialized");
        _;
    }

    /**
      * @notice withdraw the given amount of the reserve to the caller
      * @param _amount the amount to withdraw
      */
    function withdraw(uint _amount) external onlyOwner isInitialized {
        IERC20(featToken).transfer(msg.sender, _amount);
        emit OnOut(_amount, msg.sender, block.timestamp);
    }

    /**
      * @notice withdraw the given amount of the reserve a specified address
      * @param _to the address to transfer funds
      * @param _amount the amount to withdraw
      */
    function transferTo(address _to, uint _amount) external onlyOwner isInitialized {
        IERC20(featToken).transfer(_to, _amount);
        emit OnOut(_amount, _to, block.timestamp);
    }

    /** @notice retrieve the amount of FEAT in the vault */
    function getReserve() external view returns (uint) {
        return IERC20(featToken).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IFeatToken.sol";
import "./interfaces/IFeatArtistToken.sol";
import "./interfaces/IFeatCoreVault.sol";

import "./Libraries/FeatLibrary.sol";

contract FeatSwap is Initializable {
    uint public feesRatio;
    address public featFactory;
    address public coreVault;

    IFeatToken public featToken;

    event Initialized(address _coreVault, uint _feesRatio);
    event ArtistTokensBought(address _buyer, uint _amountArtistToken, uint _amountFeat, uint _timestamp);

    function init(address _featFactory, address _featToken, address _coreVault, uint _fees) external initializer {
        require(_fees < 10000, "FeatSwap: incorrect fees ratio");
        featFactory = _featFactory;
        featToken = IFeatToken(_featToken);
        coreVault = _coreVault;
        feesRatio = _fees;
        emit Initialized(_coreVault, _fees);
    }

    /**
      * @notice @TODO
      *
      * @param _artistName the name of the artist to buy his token
      * @param _amountOut the amount of FEAT to spend
      */
    function swapFeatTokenForNewArtistToken(
        string memory _artistName,
        uint _amountOut
        ) external {
        require(_amountOut > 0, "FeatSwap: spending 0");
        // removing fees from the spending amount
        (uint fees, uint realAmount) = getAmountWithFees(_amountOut);
        // retrieve how much artist token the user should receive
        uint amountIn = getArtistTokenForFEAT(_artistName, realAmount);
        (address tokenAddress, uint notSalesAmount) = FeatLibrary.getTokensNotSalesFor(featFactory, _artistName);
        // checking if there still enough artist token to buy
        require(amountIn <= notSalesAmount, "FeatSwap: not enough available token");
        featToken.transferFrom(msg.sender, coreVault, _amountOut);
        // proccessing fees
        IFeatCoreVault(coreVault).setReceivedFeesFor(_artistName, fees);
        // proccessing sales
        IFeatCoreVault(coreVault).setReceivedSalesFor(_artistName, realAmount);
        // giving new artist token to user
        IFeatArtistToken(tokenAddress).mint(msg.sender, amountIn);
        emit ArtistTokensBought(msg.sender, amountIn, _amountOut, block.timestamp);
    }

    /** 
      * @notice compute the real amount with the actual fees of swap 
      *
      * @return fees is the amount of fees in '_amount" 
      * @return realAmount is the used amount of FEAT after the fees processing 
      */
    function getAmountWithFees(uint _amount) public view returns(uint fees, uint realAmount) {
        fees = _amount * feesRatio / 10000;
        realAmount = _amount - fees;
    }

    /** 
      * @notice retrieve the FEAT cost for a specific amount of an artist token
      *
      * @param _artistName the name of the artist for the wanted token 
      * @param _amount the wanted amount of artist token 
      *
      * @return the cost in FEAT for buying the '_amount' artist tokens
      */
    function getFEATForArtistToken(string memory _artistName, uint _amount) public view returns(uint) {
        require(_amount > 0, "FeatSwap: amount input is 0");
        address tokenAddress = FeatLibrary.getArtistTokenByName(featFactory, _artistName);
        uint tokenPrice = IFeatArtistToken(tokenAddress).getTokenPrice();
        return _amount * (tokenPrice / (10 ** 18));
    }

    /** 
      * @notice retrieve the amount of an artist token for a specific FEAT amount
      *
      * @param _artistName the name of the artist for the wanted token 
      * @param _amount the amount of FEAT to spend 
      *
      * @return the amount of artist token for the '_amount' of FEAT
      */
    function getArtistTokenForFEAT(string memory _artistName, uint _amount) public view returns(uint) {
        require(_amount > 0, "FeatSwap: amount input is 0");
        address tokenAddress = FeatLibrary.getArtistTokenByName(featFactory, _artistName);
        uint tokenPrice = IFeatArtistToken(tokenAddress).getTokenPrice();
        return _amount / (tokenPrice / (10 ** 18));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./FeatArtistToken.sol";
import "./Vaults/FeatArtistVault.sol";

import "./Libraries/FeatLibrary.sol";

/**
  * @notice The Factory is used to create and keep track of Artists
  *  
  * Creating a new artist is deploying two contracts:
  * - The Token of the Artist
  * - The vault of the Artist
  *
  * @dev Assembly CREATE2 is used to give the ability to pre-compute contracts address
  *  */
contract FeatFactory is Ownable, Initializable {
    address public featToken;
    address public featSwap;
    string[] public allArtists;

    /** @notice Store the name of the token for the specified artist name */
    mapping (string => string) public artistToToken;

    event onArtistCreated(string _artistName, address _token, address _vault);
    event SwapperChanged(address _newSwap);

    constructor() {}

    function init(address _featToken,address _featSwap) external initializer onlyOwner {
        featToken = _featToken;
        featSwap = _featSwap;
    }

    function setSwapper(address _featSwap) external onlyOwner {
        require(_featSwap != address(0), "FeatFactory: incorrect swap address");
        featSwap = _featSwap;
        emit SwapperChanged(_featSwap);
    }
    
    /** 
      * @notice Return all the artists created by the factory
      * @return An array containing artists name
      */
    function getAllArtists() external view returns (string[] memory) {
        return allArtists;
    }

    /** 
      * @notice Return the token name for a given artist name
      * @param _artistName the name of the artist
      * @return the token name of the artist
      */
    function getArtistTokenName(string memory _artistName) external view returns (string memory) {
        require(keccak256(abi.encode(artistToToken[_artistName])) != keccak256(abi.encode("")), "FeatFactory: artist don't exist");
        return artistToToken[_artistName];
    }

    /** 
      * @notice create an Artist by deploying his contract token and contract vault
      *
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist Token
      * @param _tokenSymbol the symbol of the artist Token
      * @param _artistAddress the address of the artist used for the vault
      *
      * @return artistToken address of the deployed artist token
      * @return artistVault address of the deployed arist vault contract
      * 
      * @dev salt correspond to a hash of the artist name and token name
      */
    function createArtist(
        string memory _artistName,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint _tokenPrice,
        address payable _artistAddress
        ) external onlyOwner returns (
        address artistToken,
        address artistVault
        ) {
        bytes memory bytecodeToken = type(FeatArtistToken).creationCode;
        bytes memory bytecodeVault = type(FeatArtistVault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_artistName, _tokenName));
        assembly {
            artistToken := create2(0, add(bytecodeToken, 0x20), mload(bytecodeToken), salt)
            artistVault := create2(0, add(bytecodeVault, 0x20), mload(bytecodeVault), salt)
            if iszero(extcodesize(artistToken)) {
                revert(0, 0)
            }
            if iszero(extcodesize(artistVault)) {
                revert(0, 0)
            }
        }
        FeatArtistToken(artistToken).init(artistVault, featSwap, _artistName, _tokenName, _tokenSymbol, _tokenPrice);
        FeatArtistVault(artistVault).init(_artistAddress, featToken, artistToken);
        allArtists.push(_artistName);
        artistToToken[_artistName] = _tokenName;

        emit onArtistCreated(_artistName, artistToken, artistVault);
    }

    /** 
      * @notice retrieve the artist Token address for a given artist
      * @param _artistName the name of the artist
      * @return tokenAddress the address of the artist Token contract 
      */
    function getArtistToken(string memory _artistName) external view returns (address tokenAddress) {
        string memory _tokenName = artistToToken[_artistName];
        tokenAddress = FeatLibrary.getArtistTokenFor(
            address(this),
            _artistName,
            _tokenName
        );
    }

    /** 
      * @notice retrieve the artist Vault address for a given artist
      * @param _artistName the name of the artist
      * @return vaultAddress the address of the artist Vault contract 
      */
    function getArtistVault(string memory _artistName) external view returns (address vaultAddress) {
        string memory _tokenName = artistToToken[_artistName];
        vaultAddress = FeatLibrary.getArtistVaultFor(
            address(this),
            _artistName,
            _tokenName
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IFeatToken.sol";

import "../Libraries/FeatLibrary.sol";


/** 
  * @notice The core vault manage all the funds received from artist token sales and transaction fees
  *         These funds are processed according a fees ratio, corresponding to the shares between artists and plateform
  *         
  *         Fees and sales are stored by artists to be able to distribute fairly the part of the artist 
  *         Funds can be proccessed only one time in a month 
  */
contract FeatCoreVault is Ownable, Initializable {
    /** 
      * @notice reference to the governance token
      *         this is token proccessed in this vault
      */
    IFeatToken public featToken;

    /** @notice address of the owner Vault */
    address public featVault;
    /** @notice address of the factory creating the artists to rewards */
    address public featFactory;
    /** @notice address of the swap contract */
    address public featSwap;

    /** @notice last execution of funds processing */
    uint public lastExecute; // timestamp -> one month check

    /** @notice the sum of all received fees per artist */
    uint public totalFees;
    /** @notice the sum of all received fees per artist */
    uint public totalSales;

    /** @notice correponds to the ratio Artist/Plateform of fees sharing */
    uint16 public feesRatio;
 

    /** @dev store how much fees was received for a specific artist */
    mapping (string => uint) private artistToFees; // track fees ratio per artist
    /** @dev stor how much sales was received for a specific arrist */
    mapping (string => uint) private artistToSales;

    event Executed(uint processedBalance, uint _amountToArtists, uint _amountToPlateform, uint _timestamp);



    constructor() {}

    function init(address _featToken, address _featVault, address _featFactory, address _swapper) external initializer onlyOwner {
        featToken = IFeatToken(_featToken);
        featVault = _featVault;
        featFactory = _featFactory;
        featSwap = _swapper;
        feesRatio = 200; // 2%, part take per artist
    }

    /** 
      * @notice Get the current FEAT balance of the vault
      * 
      * @return balance the total FEAT amount in the vault
      */
    function getAmounts() public view returns (uint balance) {
        balance = featToken.balanceOf(address(this));
    }

    /** 
      * @notice Get the current received fees balance on the specified artists
      *
      * @param _artistName the name of the artist 
      *
      * @return totalPart the total current fees balance 
      * @return artistPart the part that should be transfered to the artist 
      */
    function getFeesAmountFor(string memory _artistName) external view returns (uint totalPart, uint artistPart) {
        totalPart = artistToFees[_artistName];
        artistPart = totalPart * feesRatio / 10000;
    }

    function getSalesAmountFor(string memory _artistName) external view returns (uint artistSales) {
        artistSales = artistToSales[_artistName];
    }

    /**
      * @notice Process the funds in the vault and transfer funds as expected
      *         FEAT balance is empty at the end of the execution
      *          
      *         Order execution:
      *          1) Get all the artists on the plateform by calling the factory
      *          2) Get all the vaults address of these artists
      *          3) For each artist in the factory,
      *             - shares the fees between the artist and the plateform
      *             - transfer sales from token sale to the artist vault
      */
    function execute() external onlyOwner {
        require(block.timestamp >= lastExecute + 2592000, "FeatCoreVault: incorrect period");
        lastExecute = block.timestamp;
        (uint balance) = getAmounts();
        require(balance > 0, "FeatCoreVault: balance is empty");
        uint totalToArtists;
        uint totalToPlateform;
        string[] memory allArtists = FeatLibrary.getAllArtists(featFactory);
        address[] memory vaultsArtists = FeatLibrary.retrieveAllVaults(featFactory);
        for(uint i; i < vaultsArtists.length; i++) {
            // adding fees
            uint toArtist = (artistToFees[allArtists[i]] * feesRatio / 10000);
            uint toPlateform = artistToFees[allArtists[i]] - toArtist;
            // adding sales
            toArtist += artistToSales[allArtists[i]];
            totalToArtists += toArtist;
            totalToPlateform += toPlateform;
            artistToFees[allArtists[i]] = 0;
            artistToSales[allArtists[i]] = 0;
            featToken.transfer(vaultsArtists[i], toArtist);
            featToken.transfer(featVault, toPlateform);
        }
        totalFees = 0;
        totalSales = 0;
        // this part just check if some dust FEAT stay because of some compute imprecision
        uint dustAmount = featToken.balanceOf(address(this));
        if(dustAmount > 0){
            featToken.transfer(featVault, dustAmount);
        }
        emit Executed(balance, totalToArtists, totalToPlateform, block.timestamp);
    }

    /**
      * @notice keep track of the received fees for an artist and the total balance fees
      *
      * @param _artistName the name of the artist
      * @param _feesAmount the amount of the fees to add
      */
    function setReceivedFeesFor(string memory _artistName, uint _feesAmount) external {
        require(msg.sender == featSwap, "FeatCoreVault: forbidden");
        artistToFees[_artistName] += _feesAmount;
        totalFees += _feesAmount;
    }

    /**
      * @notice keep track of the received sales from token for an artist and the total balance sales
      *
      * @param _artistName the name of the artist
      * @param _saleAmount the amount of the sale to add
      */
    function setReceivedSalesFor(string memory _artistName, uint _saleAmount) external {
        require(msg.sender == featSwap, "FeatCoreVault: forbidden");
        artistToSales[_artistName] += _saleAmount;
        totalSales += _saleAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeatToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeatArtistToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function getTokenPrice() external view returns (uint);

    function cap() external view returns (uint256);
    function mint(address _to, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeatCoreVault {
    function getAmounts() external view returns (uint balance);
    function getFeesAmountFor(string memory _artistName) external view returns (uint totalPart, uint artistPart);
    function getSalesAmountFor(string memory _artistName) external view returns (uint artistSales);
    function execute() external;
    function setReceivedFeesFor(string memory _artistName, uint _feesAmount) external;
    function setReceivedSalesFor(string memory _artistName, uint _saleAmount) external;

    function setSwapper(address _featSwap) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IFeatArtistVault.sol";

import "../interfaces/IFeatFactory.sol";
import "../interfaces/IFeatArtistToken.sol";

/** @notice This library is used to help the interaction with the contracts of the FEAT plateform */
library FeatLibrary {

    /** 
      * @notice Compute the arist Token address for a given artistName and tokenName
      *
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist token
      *
      * @return the computed address
      */
    function getArtistTokenFor(
        address _featFactory,
        string memory _artistName,
        string memory _tokenName
        ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(
            hex'ff',
            _featFactory,
            keccak256(abi.encodePacked(_artistName, _tokenName)),
            hex'd09d1042be496fa4b56bb9bee0f040bbd4accf97995a21196e2627b7ba2ec304' // Artist Token bytecode hash
        ));
        return address(uint160(uint(hash)));
    }

    /** 
      * @notice Compute the arist Vault address for a given artistName and tokenName
      *
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist token
      *
      * @return the computed address
      */
    function getArtistVaultFor(
        address _featFactory,
        string memory _artistName,
        string memory _tokenName
        ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(
            hex'ff',
            _featFactory,
            keccak256(abi.encodePacked(_artistName, _tokenName)),
            hex'307504d4911dd131e056198ab6856e79308da733919a200e8b55e8c15a9581e8' // Artist Vault bytecode hash
        ));
        return address(uint160(uint(hash)));
    }

    function getArtistTokenByName(address _featFactory, string memory _artistName) internal view returns(address tokenAddress) {
        string memory tokenName = IFeatFactory(_featFactory).getArtistTokenName(_artistName);
        require(keccak256(abi.encode(tokenName)) != keccak256(abi.encode("")), "FeatLibrary: unknown artist");
        tokenAddress = getArtistTokenFor(_featFactory, _artistName, tokenName);
    }

    function getArtistVaultByName(address _featFactory, string memory _artistName) internal view returns(address vaultAddress) {
        string memory tokenName = IFeatFactory(_featFactory).getArtistTokenName(_artistName);
        require(keccak256(abi.encode(tokenName)) != keccak256(abi.encode("")), "FeatLibrary: unknown artist");
        vaultAddress = getArtistVaultFor(_featFactory, _artistName, tokenName);
    }

    /** 
      * @notice Get the balance of FEAT and artist token of an artist Vault
      *
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist token
      *
      * @return artistToken the balance of artist Token
      * @return featToken the balance of FEAT Token
      */
    function getArtistReserves(
        address _featFactory,
        string calldata _artistName,
        string calldata _tokenName
        ) internal view returns (uint artistToken, uint featToken) {
        address artistVault = getArtistVaultFor(_featFactory, _artistName, _tokenName);
        uint artistTokenAmount = IFeatArtistVault(artistVault).getArtistTokenReserves();
        uint featTokenAmount = IFeatArtistVault(artistVault).getFeatTokenReserves();
        return (artistTokenAmount, featTokenAmount);
    }

    /** 
      * @notice get all the artists created by the factory
      *
      * @param _featFactory the address of the factory
      *
      * @return an array containing all artists name
      */
    function getAllArtists(address _featFactory) internal view returns (string[] memory) {
        return IFeatFactory(_featFactory).getAllArtists();
    }

    /** 
      * @notice Get all the artists vault address for each artist in the factory
      * 
      * @param _featFactory the address of the factory
      *
      * @return an array containing all artists vault address
      */
    function retrieveAllVaults(address _featFactory) internal view returns (address[] memory) {
        string[] memory allArtists = getAllArtists(_featFactory);
        require(allArtists.length > 0, "FeatLibrary: no artist in factory");
        address[] memory vaultsArtists = new address[](allArtists.length);
        for(uint i; i < allArtists.length; i++) {
            string memory tokenName = IFeatFactory(_featFactory).getArtistTokenName(allArtists[i]);
            address artistVault = getArtistVaultFor(_featFactory, allArtists[i], tokenName);
            vaultsArtists[i] = artistVault;
        }
        return vaultsArtists;
    } 

    function getTokensNotSalesFor(address _featFactory, string memory _artistName) internal view returns (address tokenAddress, uint notSalesAmount) {
        tokenAddress = getArtistTokenByName(_featFactory, _artistName);
        uint circulating = IFeatArtistToken(tokenAddress).totalSupply();
        uint max = IFeatArtistToken(tokenAddress).cap();
        notSalesAmount = max - circulating;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeatArtistVault {
    function init(address payable _artist, address _featToken) external;

    function claimArtistTokens() external;
    function claimFeatTokens() external;
    
    function getArtistTokenReserves() external view returns (uint);
    function getFeatTokenReserves() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeatFactory {
    function createArtist(
        string memory _artistName,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _artistAddress
        ) external returns (
        address artistToken,
        address artistVault
        );

    function setSwapper(address _featSwap) external;

    function getAllArtists() external view returns (string[] memory);

    function getArtistTokenName(string memory _artistName) external view returns (string memory);
    

    function getArtistToken(string calldata _artistName, string calldata _tokenName) external view returns (address);
    function getArtistVault(string calldata _artistName, string calldata _tokenName) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";


/** 
  * @notice Contract that represent the ERC20 Token of an Artist
  *         Tokens are minted on each sales.
  *
  * @dev Using Initializable format contracts to be able to compute the address without constructor parameters
  */
contract FeatArtistToken is ERC20Upgradeable, ERC20CappedUpgradeable {
    /** 
      * @notice Contain the arist name of the token
      *         Used to be able to easily track who represents the token
      */
    string public artistName;

    /** 
      * @dev Contain the price in FEAT token for 1 token
      *      'salesPrice' FEAT = 1 artist token
      */
    uint private tokenPrice;
    
    /** @notice the contract were swap are effectued for buying this token */
    address public featSwap;

    /** 
      * @notice Init function work as a constructor and implements the datas of the token
      * 
      * @param _featSwap the address of the swap contract where tokens are bought
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist token
      * @param _tokenSymbol the symbol of the artist token
      *
      * @dev This function need to be called as early as possible after deployment !!!
      */
    function init(
        address _artistVault,
        address _featSwap,
        string memory _artistName,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint _tokenPrice
    ) external initializer {
        require(keccak256(abi.encode(_artistName)) != keccak256(abi.encode("")), "FeatArtistToken: invalid artist name");
        require(_featSwap != address(0), "FeatArtistToken: invalid swap address");
        require(_tokenPrice > 0, "FeatArtistToken: invalid token price");
        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Capped_init(1000000 * 10 ** 18);
        _mint(_artistVault, cap() * 2000 / 10000);
        artistName = _artistName;
        featSwap = _featSwap;
        tokenPrice = _tokenPrice;
    }

    function getTokenPrice() external view returns (uint) {
         return tokenPrice;
    }

    /** @notice allow mints from the swap contract */
    function mint(address _to, uint amount) external {
        require(msg.sender == featSwap, "FeatArtistToken: unauthorized mint");
        _mint(_to, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        require(ERC20Upgradeable.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IFeatArtistToken.sol";


/**
  * @notice Contract that represents the vault of an artist
  *         This vault is used to store the reserve of the Artist Tokens
  *         and the claimable fees rewards.
  *         
  *         Artist Tokens can be withdraw only at 30% the first and second year, and 40% the third year
  *         to ensure the security and the lifecycle of the token     
  *
  * @dev Using Initializable format contracts to be able to compute the address without constructor parameters     
  */
contract FeatArtistVault is Initializable {
    /** @dev timestamp of the last artist token claim */
    uint private lastTimestamp;
    uint private initTimestamp;

    uint private firstAndSecondYAmount;
    uint private thirdYAmount;

    /** @notice address of the artist authorized to withdraw funds */
    address payable public artist;

    /** @notice reference to the governance token of Feat */
    IERC20 public featToken;
    /** @notice reference to the token of the artist */
    IFeatArtistToken public artistToken;

    event FeatClaimed(uint _amount, uint _timestamp);
    event ArtistTokenClaimed(uint _amount, uint _timestamp);

    /** 
      * @notice Init function work as a constructor and implements the datas of the vault for artist
      * 
      * @param _artist the address of the artist
      * @param _featToken the address of the Feat Token contract
      * @param _artistToken the address of the artist Token contract
      *
      * @dev timestamps are also set to ensure the artist can't directly withdraw funds
      */
    function init(address payable _artist, address _featToken, address _artistToken) external initializer {
        artist = _artist;
        featToken = IERC20(_featToken);
        artistToken = IFeatArtistToken(_artistToken);
        initTimestamp = block.timestamp;
        lastTimestamp = block.timestamp;

        uint currentBalance = artistToken.balanceOf(address(this));
        firstAndSecondYAmount = currentBalance * 60 / 100;
        thirdYAmount = currentBalance * 40 / 100;
    }

    /** @notice ensure that the caller is the artist of the vault */
    modifier onlyArtist() {
        require(msg.sender == artist, "FeatVault: Unauthorized access");
        _;
    }

    function claimArtistTokens() external onlyArtist {
        (uint toWithdraw, uint year) = getClaimableArtistsTokens();
        require(toWithdraw > 0, "FeatArtistVault: nothing to claim");
        if(year <= 2){
            firstAndSecondYAmount -= toWithdraw;
        }
        else {
            uint amountThirdY = toWithdraw - firstAndSecondYAmount;
            firstAndSecondYAmount = 0;
            thirdYAmount -= amountThirdY;
        }
        lastTimestamp = block.timestamp;
        artistToken.transfer(msg.sender, toWithdraw);
        emit ArtistTokenClaimed(toWithdraw, block.timestamp);
    }

    function claimFeatTokens() external onlyArtist {
        uint amountToWithdraw = featToken.balanceOf(msg.sender);
        featToken.transfer(msg.sender, amountToWithdraw);
        emit FeatClaimed(amountToWithdraw, block.timestamp);
    }

    /**
      * @notice compute how many token the artist can claim at the current timestamp
      *
      *         As the artist have a vesting period for the reserve token of:
      *         1st and 2nd year: 60% of reserve (30% + 30%)
      *         3rd year: 40% of reserve
      *
      *         We first need to ensure in which year we actually are, so we can apply the correct prorata.
      *         prorata is used to retrieve the correct amount for a given timestamp passed since the last withdraw
      *
      *         prorata: MaxAmountToWithdraw / TimeWindow
      *             (where 'timeWindow' is the number of seconds in the year(s)
      *                    'MaxAmountToWithdraw' is the maximum amount that the artist would be able to withdraw on the timeWindow)
      * 
      * @return total the number of token available for withdraw
      * @return year an indication on the processed years
      */
    function getClaimableArtistsTokens() public view onlyArtist returns (uint total, uint year) {
        year = ((block.timestamp - initTimestamp) / 31556926) + 1;
        uint startTimestampThirdY = initTimestamp + (31556926 * 2);
        uint sinceLastTimePassed;

        // 1 year = 31556926
        if(year <= 2){
            // if we are in the first or second year => 3% per year
            uint prorata = firstAndSecondYAmount / (31556926 * 2);
            sinceLastTimePassed = block.timestamp - lastTimestamp;
            total = prorata * sinceLastTimePassed;
        }
        else if(year <= 3){
            // if we are in the third year => 4% per year
            uint prorata = thirdYAmount / 31556926;
            if(lastTimestamp < startTimestampThirdY){
                // case where the last withdraw was in the window of the first or second year
                // we need to be sure that we only count time since the beginning of this year
                sinceLastTimePassed = block.timestamp - startTimestampThirdY;    

            }
            else{
                sinceLastTimePassed = block.timestamp - lastTimestamp;
            }
            total = (sinceLastTimePassed * prorata) + firstAndSecondYAmount;
        }
        else {
            // if we are after the three years of vesting, in any case artist can claim all
            total = firstAndSecondYAmount + thirdYAmount;
        }
    }

    function getArtistTokenReserves() external view returns (uint) {
        return artistToken.balanceOf(address(this));
    }

    function getFeatTokenReserves() external view returns (uint) {
        return featToken.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    function __ERC20Capped_init(uint256 cap_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(uint256 cap_) internal onlyInitializing {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20Upgradeable.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
    uint256[50] private __gap;
}