/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.5;

interface IdZeroShift {
    function mint(address account_, uint256 amount_) external;
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = "0";
        _addr[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
        keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

interface IERC2612Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 _hash = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(_hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ZeroSwapPermit: Invalid signature"
        );

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract ZeroShiftPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount; // Amount USDC deposited by user
        uint256 debt; // total ZRST claimed thus dZRST debt
        bool claimed; // True if a user has claimed ZRST
    }

    struct TeamInfo {
        uint256 numWhitelist; // number of whitelists
        uint256 amount; // Amout USDC deposited by team
        uint256 debt; // total ZRST claimed thus dZRST debt
        bool claimed; // True if a team member has claimed ZRST
    }

    // Tokens to raise (USDC) & (DAI.E) and for offer (dZRST) which can be swapped for (ZRST)
    IERC20 public USD; // for user deposits
    IERC20 public DAI; // for team deposits
    IERC20 public dZeroShift;
    IERC20 public zeroShift;

    address public DAO; // Multisig treasury to send proceeds to

    address public WARCHEST; // Multisig to send team proceeds to

    uint256 public price = 5 * 1e6; // 5 USD per ZRST. USD token has 6 decimals.

    uint256 public cap = 500 * 1e6; // 500 USD cap per whitelisted user

    uint256 public totalRaisedUSD; // total USD raised by sale
    uint256 public totalRaisedDAI; // total DAI raised by sale

    uint256 public totalDebt; // total dZRST and thus ZRST owed to users

    bool public started; // true when sale is started

    bool public ended; // true when sale is ended

    bool public claimable; // true when sale is claimable

    bool public claimDZRST; // true when dZRST is claimable

    bool public contractPaused; // circuit breaker

    mapping(address => UserInfo) public userInfo;

    mapping(address => TeamInfo) public teamInfo;

    mapping(address => bool) public whitelisted; // True if user is whitelisted

    mapping(address => bool) public whitelistedTeam; // True if team member is whitelisted

    mapping(address => uint256) public zrstClaimable; // amount of ZRST claimable by address

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address token, address indexed who, uint256 amount);
    event Mint(address token, address indexed who, uint256 amount);
    event SaleStarted(uint256 block);
    event SaleEnded(uint256 block);
    event ClaimUnlocked(uint256 block);
    event ClaimDZeroShiftUnlocked(uint256 block);
    event AdminWithdrawal(address token, uint256 amount);

    constructor(
        address _dZeroShift,
        address _zeroShift,
        address _USD,
        address _DAI,
        address _DAO,
        address _WARCHEST
    ) {
        require(_dZeroShift != address(0));
        dZeroShift = IERC20(_dZeroShift);
        require(_zeroShift != address(0));
        zeroShift = IERC20(_zeroShift);
        require(_USD != address(0));
        USD = IERC20(_USD);
        require(_DAI != address(0));
        DAI = IERC20(_DAI);
        require(_DAO != address(0));
        DAO = _DAO;
        require(_WARCHEST != address(0));
        WARCHEST = _WARCHEST;
    }

    //* @notice modifer to check if contract is paused
    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }

    /**
     *  @notice adds a single whitelist to the sale
     *  @param _address: address to whitelist
     */
    function addWhitelist(address _address) external onlyOwner {
        require(!started, "Sale has already started");
        whitelisted[_address] = true;
    }

    /**
     *  @notice adds multiple whitelist to the sale
     *  @param _addresses: dynamic array of addresses to whitelist
     */
    function addMultipleWhitelist(address[] calldata _addresses)
        external
        onlyOwner
    {
        require(!started, "Sale has already started");
        require(_addresses.length <= 333, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    /**
     *  @notice removes a single whitelist from the sale
     *  @param _address: address to remove from whitelist
     */
    function removeWhitelist(address _address) external onlyOwner {
        require(!started, "Sale has already started");
        whitelisted[_address] = false;
    }

    /**
     *  @notice adds a team member from sale
     *  @param _address: address to whitelist
     *  @param _numWhitelist: number of whitelists for address
     */
    function addTeam(address _address, uint256 _numWhitelist)
        external
        onlyOwner
    {
        require(!started, "Sale has already started");
        require(_numWhitelist != 0, "cannot set zero whitelists");
        whitelistedTeam[_address] = true;
        teamInfo[_address].numWhitelist = _numWhitelist;
    }

    /**
     *  @notice removes a team member from sale
     *  @param _address: address to remove from whitelist
     */
    function removeTeam(address _address) external onlyOwner {
        require(!started, "Sale has already started");
        whitelistedTeam[_address] = false;
        delete teamInfo[_address];
    }

    // @notice Starts the sale
    function start() external onlyOwner {
        require(!started, "Sale has already started");
        started = true;
        emit SaleStarted(block.number);
    }

    // @notice Ends the sale
    function end() external onlyOwner {
        require(started, "Sale has not started");
        require(!ended, "Sale has already ended");
        ended = true;
        emit SaleEnded(block.number);
    }

    // @notice lets users claim ZRST
    // @dev send sufficient ZRST before calling
    function claimUnlock() external onlyOwner {
        require(ended, "Sale has not ended");
        require(!claimable, "Claim has already been unlocked");
        require(
            zeroShift.balanceOf(address(this)) >= totalDebt,
            "not enough ROME in contract"
        );
        claimable = true;
        emit ClaimUnlocked(block.number);
    }

    // @notice lets users claim dZRST
    function claimDZeroShiftUnlock() external onlyOwner {
        require(claimable, "Claim has not been unlocked");
        require(!claimDZRST, "Claim DZeroShift has already been unlocked");
        claimDZRST = true;
        emit ClaimDZeroShiftUnlocked(block.number);
    }

    // @notice lets owner pause contract
    function togglePause() external onlyOwner returns (bool) {
        contractPaused = !contractPaused;
        return contractPaused;
    }

    /**
     *  @notice transfer ERC20 token to DAO multisig
     *  @param _token: token address to withdraw
     *  @param _amount: amount of token to withdraw
     */
    function adminWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(address(msg.sender), _amount);
        emit AdminWithdrawal(_token, _amount);
    }

    /**
     *  @notice it deposits USD for the sale
     *  @param _amount: amount of USD to deposit to sale (6 decimals)
     */
    function deposit(uint256 _amount) external checkIfPaused {
        require(started, "Sale has not started");
        require(!ended, "Sale has ended");
        require(
            whitelisted[msg.sender] == true,
            "msg.sender is not whitelisted user"
        );

        UserInfo storage user = userInfo[msg.sender];

        require(cap >= user.amount.add(_amount), "new amount above user limit");

        user.amount = user.amount.add(_amount);
        totalRaisedUSD = totalRaisedUSD.add(_amount);

        uint256 payout = _amount.mul(1e6).div(price).mul(1e12);

        totalDebt = totalDebt.add(payout);

        USD.safeTransferFrom(msg.sender, DAO, _amount);

        IdZeroShift(address(dZeroShift)).mint(msg.sender, payout);

        emit Deposit(msg.sender, _amount);
    }

    /**
     *  @notice it deposits USD for the sale
     *  @param _amount: amount of USD to deposit to sale (6 decimals)
     *  @dev only for team members
     */
    function depositTeam(uint256 _amount) external checkIfPaused {
        require(started, "Sale has not started");
        require(!ended, "Sale has ended");
        require(
            whitelistedTeam[msg.sender] == true,
            "msg.sender is not whitelisted team"
        );

        TeamInfo storage team = teamInfo[msg.sender];

        require(
            cap.mul(team.numWhitelist) >= team.amount.add(_amount),
            "new amount above team limit"
        );

        team.amount = team.amount.add(_amount);
        totalRaisedDAI = totalRaisedDAI.add(_amount);

        uint256 payout = _amount.mul(1e6).div(price).mul(1e12); // ZRST debt to claim

        totalDebt = totalDebt.add(payout);

        DAI.safeTransferFrom(msg.sender, DAO, _amount);

        IdZeroShift(address(dZeroShift)).mint(WARCHEST, payout);

        emit Deposit(msg.sender, _amount);
    }

    /**
     *  @notice it deposits dZRST to withdraw ZRST from the sale
     *  @param _amount: amount of dZRST to deposit to sale ( decimals)
     */
    function withdraw(uint256 _amount) external checkIfPaused {
        require(claimable, "ZeroShift is not yet claimable");
        require(_amount > 0, "_amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];

        user.debt = user.debt.add(_amount);

        totalDebt = totalDebt.sub(_amount);

        dZeroShift.safeTransferFrom(msg.sender, address(this), _amount);

        zeroShift.safeTransfer(msg.sender, _amount);

        emit Mint(address(dZeroShift), msg.sender, _amount);
        emit Withdraw(address(zeroShift), msg.sender, _amount);
    }

    // @notice it checks a users USD allocation remaining
    function getUserRemainingAllocation(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_user];
        return cap.sub(user.amount);
    }

    // @notice it claims dZRST back from the sale
    function claimDZeroShift() external checkIfPaused {
        require(claimDZRST, "dZRST is not yet claimable");

        UserInfo storage user = userInfo[msg.sender];

        require(user.debt > 0, "msg.sender has not participated");
        require(!user.claimed, "msg.sender has already claimed");

        user.claimed = true;

        uint256 payout = user.debt;
        user.debt = 0;

        dZeroShift.safeTransfer(msg.sender, payout);

        emit Withdraw(address(dZeroShift), msg.sender, payout);
    }
}