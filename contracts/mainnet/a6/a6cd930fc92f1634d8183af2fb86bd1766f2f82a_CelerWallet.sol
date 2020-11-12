// File: contracts/lib/interface/ICelerWallet.sol

pragma solidity ^0.5.1;

/**
 * @title CelerWallet interface
 */
interface ICelerWallet {
    function create(address[] calldata _owners, address _operator, bytes32 _nonce) external returns(bytes32);

    function depositETH(bytes32 _walletId) external payable;

    function depositERC20(bytes32 _walletId, address _tokenAddress, uint _amount) external;
    
    function withdraw(bytes32 _walletId, address _tokenAddress, address _receiver, uint _amount) external;

    function transferToWallet(bytes32 _fromWalletId, bytes32 _toWalletId, address _tokenAddress, address _receiver, uint _amount) external;

    function transferOperatorship(bytes32 _walletId, address _newOperator) external;

    function proposeNewOperator(bytes32 _walletId, address _newOperator) external;

    function drainToken(address _tokenAddress, address _receiver, uint _amount) external;

    function getWalletOwners(bytes32 _walletId) external view returns(address[] memory);

    function getOperator(bytes32 _walletId) external view returns(address);

    function getBalance(bytes32 _walletId, address _tokenAddress) external view returns(uint);

    function getProposedNewOperator(bytes32 _walletId) external view returns(address);

    function getProposalVote(bytes32 _walletId, address _owner) external view returns(bool);

    event CreateWallet(bytes32 indexed walletId, address[] indexed owners, address indexed operator);

    event DepositToWallet(bytes32 indexed walletId, address indexed tokenAddress, uint amount);

    event WithdrawFromWallet(bytes32 indexed walletId, address indexed tokenAddress, address indexed receiver, uint amount);

    event TransferToWallet(bytes32 indexed fromWalletId, bytes32 indexed toWalletId, address indexed tokenAddress, address receiver, uint amount);

    event ChangeOperator(bytes32 indexed walletId, address indexed oldOperator, address indexed newOperator);

    event ProposeNewOperator(bytes32 indexed walletId, address indexed newOperator, address indexed proposer);

    event DrainToken(address indexed tokenAddress, address indexed receiver, uint amount);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: contracts/CelerWallet.sol

pragma solidity ^0.5.1;






/**
 * @title CelerWallet contract
 * @notice A multi-owner, multi-token, operator-centric wallet designed for CelerChannel.
 *   This wallet can run independetly and doesn't rely on trust of any external contracts
 *   even CelerLedger to maximize its security.
 */
contract CelerWallet is ICelerWallet, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    enum MathOperation { Add, Sub }

    struct Wallet {
        // corresponding to peers in CelerLedger
        address[] owners;
        // corresponding to CelerLedger
        address operator;
        // adderss(0) for ETH
        mapping(address => uint) balances;
        address proposedNewOperator;
        mapping(address => bool) proposalVotes;
    }

    uint public walletNum;
    mapping(bytes32 => Wallet) private wallets;

    /**
     * @dev Throws if called by any account other than the wallet's operator
     * @param _walletId id of the wallet to be operated
     */
    modifier onlyOperator(bytes32 _walletId) {
        require(msg.sender == wallets[_walletId].operator, "msg.sender is not operator");
        _;
    }

    /**
     * @dev Throws if given address is not an owner of the wallet
     * @param _walletId id of the wallet to be operated
     * @param _addr address to be checked
     */
    modifier onlyWalletOwner(bytes32 _walletId, address _addr) {
        require(_isWalletOwner(_walletId, _addr), "Given address is not wallet owner");
        _;
    }

    /**
     * @notice Create a new wallet
     * @param _owners owners of the wallet
     * @param _operator initial operator of the wallet
     * @param _nonce nonce given by caller to generate the wallet id
     * @return id of created wallet
     */
    function create(
        address[] memory _owners,
        address _operator,
        bytes32 _nonce
    )
        public
        whenNotPaused
        returns(bytes32)
    {
        require(_operator != address(0), "New operator is address(0)");

        bytes32 walletId = keccak256(abi.encodePacked(address(this), msg.sender, _nonce));
        Wallet storage w = wallets[walletId];
        // wallet must be uninitialized
        require(w.operator == address(0), "Occupied wallet id");
        w.owners = _owners;
        w.operator = _operator;
        walletNum++;

        emit CreateWallet(walletId, _owners, _operator);
        return walletId;
    }

    /**
     * @notice Deposit ETH to a wallet
     * @param _walletId id of the wallet to deposit into
     */
    function depositETH(bytes32 _walletId) public payable whenNotPaused {
        uint amount = msg.value;
        _updateBalance(_walletId, address(0), amount, MathOperation.Add);
        emit DepositToWallet(_walletId, address(0), amount);
    }

    /**
     * @notice Deposit ERC20 tokens to a wallet
     * @param _walletId id of the wallet to deposit into
     * @param _tokenAddress address of token to deposit
     * @param _amount deposit token amount
     */
    function depositERC20(
        bytes32 _walletId,
        address _tokenAddress,
        uint _amount
    )
        public
        whenNotPaused
    {
        _updateBalance(_walletId, _tokenAddress, _amount, MathOperation.Add);
        emit DepositToWallet(_walletId, _tokenAddress, _amount);

        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Withdraw funds to an address
     * @dev Since this withdraw() function uses direct transfer to send ETH, if CelerLedger
     *   allows non externally-owned account (EOA) to be a peer of the channel namely an owner
     *   of the wallet, CelerLedger should implement a withdraw pattern for ETH to avoid
     *   maliciously fund locking. Withdraw pattern reference:
     *   https://solidity.readthedocs.io/en/v0.5.9/common-patterns.html#withdrawal-from-contracts
     * @param _walletId id of the wallet to withdraw from
     * @param _tokenAddress address of token to withdraw
     * @param _receiver token receiver
     * @param _amount withdrawal token amount
     */
    function withdraw(
        bytes32 _walletId,
        address _tokenAddress,
        address _receiver,
        uint _amount
    )
        public
        whenNotPaused
        onlyOperator(_walletId)
        onlyWalletOwner(_walletId, _receiver)
    {
        _updateBalance(_walletId, _tokenAddress, _amount, MathOperation.Sub);
        emit WithdrawFromWallet(_walletId, _tokenAddress, _receiver, _amount);

        _withdrawToken(_tokenAddress, _receiver, _amount);
    }

    /**
     * @notice Transfer funds from one wallet to another wallet with a same owner (as the receiver)
     * @dev from wallet and to wallet must have one common owner as the receiver or beneficiary
     *   of this transfer
     * @param _fromWalletId id of wallet to transfer funds from
     * @param _toWalletId id of wallet to transfer funds to
     * @param _tokenAddress address of token to transfer
     * @param _receiver beneficiary who transfers her funds from one wallet to another wallet
     * @param _amount transferred token amount
     */
    function transferToWallet(
        bytes32 _fromWalletId,
        bytes32 _toWalletId,
        address _tokenAddress,
        address _receiver,
        uint _amount
    )
        public
        whenNotPaused
        onlyOperator(_fromWalletId)
        onlyWalletOwner(_fromWalletId, _receiver)
        onlyWalletOwner(_toWalletId, _receiver)
    {
        _updateBalance(_fromWalletId, _tokenAddress, _amount, MathOperation.Sub);
        _updateBalance(_toWalletId, _tokenAddress, _amount, MathOperation.Add);
        emit TransferToWallet(_fromWalletId, _toWalletId, _tokenAddress, _receiver, _amount);
    }

    /**
     * @notice Current operator transfers the operatorship of a wallet to the new operator
     * @param _walletId id of wallet to transfer the operatorship
     * @param _newOperator the new operator
     */
    function transferOperatorship(
        bytes32 _walletId,
        address _newOperator
    )
        public
        whenNotPaused
        onlyOperator(_walletId)
    {
        _changeOperator(_walletId, _newOperator);
    }

    /**
     * @notice Wallet owners propose and assign a new operator of their wallet
     * @dev it will assign a new operator if all owners propose the same new operator.
     *   This does not require unpaused.
     * @param _walletId id of wallet which owners propose new operator of
     * @param _newOperator the new operator proposal
     */
    function proposeNewOperator(
        bytes32 _walletId,
        address _newOperator
    )
        public
        onlyWalletOwner(_walletId, msg.sender)
    {
        require(_newOperator != address(0), "New operator is address(0)");

        Wallet storage w = wallets[_walletId];
        if (_newOperator != w.proposedNewOperator) {
            _clearVotes(w);
            w.proposedNewOperator = _newOperator;
        }

        w.proposalVotes[msg.sender] = true;
        emit ProposeNewOperator(_walletId, _newOperator, msg.sender);

        if (_checkAllVotes(w)) {
            _changeOperator(_walletId, _newOperator);
            _clearVotes(w);
        }
    }

    /**
     * @notice Pauser drains one type of tokens when paused
     * @dev This is for emergency situations.
     * @param _tokenAddress address of token to drain
     * @param _receiver token receiver
     * @param _amount drained token amount
     */
    function drainToken(
        address _tokenAddress,
        address _receiver,
        uint _amount
    )
        public
        whenPaused
        onlyPauser
    {
        emit DrainToken(_tokenAddress, _receiver, _amount);

        _withdrawToken(_tokenAddress, _receiver, _amount);
    }

    /**
     * @notice Get owners of a given wallet
     * @param _walletId id of the queried wallet
     * @return wallet's owners
     */
    function getWalletOwners(bytes32 _walletId) external view returns(address[] memory) {
        return wallets[_walletId].owners;
    }

    /**
     * @notice Get operator of a given wallet
     * @param _walletId id of the queried wallet
     * @return wallet's operator
     */
    function getOperator(bytes32 _walletId) public view returns(address) {
        return wallets[_walletId].operator;
    }

    /**
     * @notice Get balance of a given token in a given wallet
     * @param _walletId id of the queried wallet
     * @param _tokenAddress address of the queried token
     * @return amount of the given token in the wallet
     */
    function getBalance(bytes32 _walletId, address _tokenAddress) public view returns(uint) {
        return wallets[_walletId].balances[_tokenAddress];
    }

    /**
     * @notice Get proposedNewOperator of a given wallet
     * @param _walletId id of the queried wallet
     * @return wallet's proposedNewOperator
     */
    function getProposedNewOperator(bytes32 _walletId) external view returns(address) {
        return wallets[_walletId].proposedNewOperator;

    }

    /**
     * @notice Get the vote of an owner for the proposedNewOperator of a wallet
     * @param _walletId id of the queried wallet
     * @param _owner owner to be checked
     * @return the owner's vote for the proposedNewOperator
     */
    function getProposalVote(
        bytes32 _walletId,
        address _owner
    )
        external
        view
        onlyWalletOwner(_walletId, _owner)
        returns(bool)
    {
        return wallets[_walletId].proposalVotes[_owner];
    }

    /**
     * @notice Internal function to withdraw out one type of token
     * @param _tokenAddress address of token to withdraw
     * @param _receiver token receiver
     * @param _amount withdrawal token amount
     */
    function _withdrawToken(address _tokenAddress, address _receiver, uint _amount) internal {
        if (_tokenAddress == address(0)) {
            // convert from address to address payable
            // TODO: latest version of openzeppelin Address.sol provide this api toPayable()
            address payable receiver  = address(uint160(_receiver));
            receiver.transfer(_amount);
        } else {
            IERC20(_tokenAddress).safeTransfer(_receiver, _amount);
        }
    }

    /**
     * @notice Update balance record
     * @param _walletId id of wallet to update
     * @param _tokenAddress address of token to update
     * @param _amount update amount
     * @param _op update operation
     */
    function _updateBalance(
        bytes32 _walletId,
        address _tokenAddress,
        uint _amount,
        MathOperation _op
    )
        internal
    {
        Wallet storage w = wallets[_walletId];
        if (_op == MathOperation.Add) {
            w.balances[_tokenAddress] = w.balances[_tokenAddress].add(_amount);
        } else if (_op == MathOperation.Sub) {
            w.balances[_tokenAddress] = w.balances[_tokenAddress].sub(_amount);
        } else {
            assert(false);
        }
    }

    /**
     * @notice Clear all votes of new operator proposals of the wallet
     * @param _w the wallet
     */
    function _clearVotes(Wallet storage _w) internal {
        for (uint i = 0; i < _w.owners.length; i++) {
            _w.proposalVotes[_w.owners[i]] = false;
        }
    }

    /**
     * @notice Internal function of changing the operator of a wallet
     * @param _walletId id of wallet to change its operator
     * @param _newOperator the new operator
     */
    function _changeOperator(bytes32 _walletId, address _newOperator) internal {
        require(_newOperator != address(0), "New operator is address(0)");

        Wallet storage w = wallets[_walletId];
        address oldOperator = w.operator;
        w.operator = _newOperator;
        emit ChangeOperator(_walletId, oldOperator, _newOperator);
    }

    /**
     * @notice Check if all owners have voted for the same new operator
     * @param _w the wallet
     * @return true if all owners have voted for a same operator; otherwise false
     */
    function _checkAllVotes(Wallet storage _w) internal view returns(bool) {
        for (uint i = 0; i < _w.owners.length; i++) {
            if (_w.proposalVotes[_w.owners[i]] == false) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Check if an address is an owner of a wallet
     * @param _walletId id of wallet to check
     * @param _addr address to check
     * @return true if this address is an owner of the wallet; otherwise false
     */
    function _isWalletOwner(bytes32 _walletId, address _addr) internal view returns(bool) {
        Wallet storage w = wallets[_walletId];
        for (uint i = 0; i < w.owners.length; i++) {
            if (_addr == w.owners[i]) {
                return true;
            }
        }
        return false;
    }
}