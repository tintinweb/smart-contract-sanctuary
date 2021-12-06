/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT

// File: interfaces/IERC20.sol


pragma solidity >=0.6.0;

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
// File: interfaces/IStaking.sol


pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}
// File: interfaces/IOwnable.sol


pragma solidity >=0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}
// File: types/Ownable.sol


pragma solidity >=0.7.5;


abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPulled( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// File: interfaces/IPoseidon.sol


pragma solidity >=0.7.5;

interface IPoseidon {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function addCollateral(uint256 amount) external;

    function removeCollateral(uint256 amount) external;

    function open (
        uint256 pid,
        uint256[] calldata args 
    ) external returns (
        uint256 ohmAdded,
        uint256 tokenAdded,
        uint256 liquidity
    );

    function close(
        uint256 pid, 
        uint256[] calldata args
    ) external returns (
        uint256 ohmRemoved, 
        uint256 tokenRemoved
    );
    function harvest(uint256 _pid) external;

    function migrate() external;

    function emergencyWithdraw(uint256 _pid) external;

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function collectInterest(address user) external;

    function poolLength() external view returns (uint256);

    function pendingATL(uint256 _pid, address _user) external view returns (uint256);
    
    function equity(address user) external view returns (uint256);
}
// File: AtlantisPool.sol


pragma solidity 0.7.5;






contract AtlantisPool is Ownable {
    // pool is sole holder of this token.
    IERC20 public immutable mintRightToken;
    // handles adding liquidity
    IPoseidon public poseidon;
    // turns OHM into sOHM
    IStaking public immutable staking;
    // used as collateral for the other side of each pair
    IERC20 public immutable sOHM;

    constructor(
        address _sohm,
        address _staking,
        address _mintRightToken
    ) {
        require(_sohm != address(0));
        sOHM = IERC20(_sohm);
        require(_staking != address(0));
        staking = IStaking(_staking);
        require(_mintRightToken != address(0));
        mintRightToken = IERC20(_mintRightToken);
        _owner = tx.origin;
    }

    // pool is only holder of a token and deposits it to receive DRIP.
    function deposit() external onlyOwner {
        uint256 amount = mintRightToken.balanceOf(address(this));
        mintRightToken.approve(address(poseidon), amount);
        poseidon.deposit(0, amount);
    }

    // get DRIP tokens from Poseidon.
    function harvest() external onlyOwner {
        poseidon.withdraw(0, 0);
    }

    // stakes unstaked OHM
    function stake() external onlyOwner {
        staking.stake(
            address(this), 
            sOHM.balanceOf(address(this)),
            true,
            true
        );
    }

    // adds sOHM in contract as collateral in poseidon
    function addCollateral() external onlyOwner {
        uint256 balance = sOHM.balanceOf(address(this));
        sOHM.approve(address(poseidon), balance);
        poseidon.addCollateral(balance);
    }

    // adds OHM-TOKEN liquidity to poseidon
    function addLiquidity(
        uint256 pid,
        uint256[] memory args, 
        IERC20 token
    ) external onlyOwner {
        token.approve(address(poseidon), args[2]);
        poseidon.open(pid, args);
    }

    // removes OHM-TOKEN liquidity from poseidon
    function removeLiquidity(
        uint256 pid,
        uint256[] memory args,
        IERC20 token
    ) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        poseidon.close(pid, args);
        require(balance < token.balanceOf(address(this)));
    }

    // set poseidon contract
    function setPoseidon(address _poseidon) external onlyOwner {
        require(_poseidon != address(0));
        require(address(poseidon) == address(0));
        poseidon = IPoseidon(_poseidon);
    }
}