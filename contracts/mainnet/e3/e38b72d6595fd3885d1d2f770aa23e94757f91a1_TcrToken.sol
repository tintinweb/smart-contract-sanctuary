/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.2;

// interface need to claim rouge tokens from contract and handle upgraded functions
abstract contract IERC20 {
    function balanceOf(address owner) public view virtual returns (uint256);

    function transfer(address to, uint256 amount) public virtual;

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256);

    function totalSupply() public view virtual returns (uint256);
}

// interface to potential future upgraded contract,
// only essential write functions that need check that this contract is caller
abstract contract IUpgradedToken {
    function transferByLegacy(
        address sender,
        address to,
        uint256 amount
    ) public virtual returns (bool);

    function transferFromByLegacy(
        address sender,
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool);

    function approveByLegacy(
        address sender,
        address spender,
        uint256 amount
    ) public virtual;
}

//
// The ultimate ERC20 token contract for TecraCoin project
//
contract TcrToken {
    //
    // ERC20 basic information
    //
    uint8 public constant decimals = 8;
    string public constant name = "TecraCoin";
    string public constant symbol = "TCR";
    uint256 private _totalSupply;
    uint256 public constant maxSupply = 21000000000000000;

    string public constant version = "1";
    uint256 public immutable getChainId;

    //
    // other flags, data and constants
    //
    address public owner;
    address public newOwner;

    bool public paused;

    bool public deprecated;
    address public upgradedAddress;

    bytes32 public immutable DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    string private constant ERROR_DAS = "Different array sizes";
    string private constant ERROR_BTL = "Balance too low";
    string private constant ERROR_ATL = "Allowance too low";
    string private constant ERROR_OO = "Only Owner";

    //
    // events
    //
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Paused();
    event Unpaused();

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    //
    // data stores
    //
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    mapping(address => bool) public isBlacklisted;

    mapping(address => bool) public isBlacklistAdmin;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isPauser;

    mapping(address => uint256) public nonces;

    //
    // contract constructor
    //
    constructor() {
        owner = msg.sender;
        getChainId = block.chainid;
        // EIP712 Domain
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    //
    // "approve"
    //
    function approve(address spender, uint256 amount) external {
        if (deprecated) {
            return
                IUpgradedToken(upgradedAddress).approveByLegacy(
                    msg.sender,
                    spender,
                    amount
                );
        }
        _approve(msg.sender, spender, amount);
    }

    //
    // "burnable"
    //
    function burn(uint256 amount) external {
        require(_balances[msg.sender] >= amount, ERROR_BTL);
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        require(_allowances[msg.sender][from] >= amount, ERROR_ATL);
        require(_balances[from] >= amount, ERROR_BTL);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        _burn(from, amount);
    }

    //
    // "transfer"
    //
    function transfer(address to, uint256 amount) external returns (bool) {
        if (deprecated) {
            return
                IUpgradedToken(upgradedAddress).transferByLegacy(
                    msg.sender,
                    to,
                    amount
                );
        }
        require(_balances[msg.sender] >= amount, ERROR_BTL);
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        if (deprecated) {
            return
                IUpgradedToken(upgradedAddress).transferFromByLegacy(
                    msg.sender,
                    from,
                    to,
                    amount
                );
        }
        _allowanceTransfer(msg.sender, from, to, amount);
        return true;
    }

    //
    // non-ERC20 functionality
    //
    // Rouge tokens and ETH withdrawal
    function acquire(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner).transfer(address(this).balance);
        } else {
            uint256 amount = IERC20(token).balanceOf(address(this));
            require(amount > 0, ERROR_BTL);
            IERC20(token).transfer(owner, amount);
        }
    }

    //
    // "blacklist"
    //
    function addBlacklister(address user) external onlyOwner {
        isBlacklistAdmin[user] = true;
    }

    function removeBlacklister(address user) external onlyOwner {
        isBlacklistAdmin[user] = false;
    }

    modifier onlyBlacklister {
        require(isBlacklistAdmin[msg.sender], "Not a Blacklister");
        _;
    }

    modifier notOnBlacklist(address user) {
        require(!isBlacklisted[user], "Address on blacklist");
        _;
    }

    function addBlacklist(address user) external onlyBlacklister {
        isBlacklisted[user] = true;
        emit AddedToBlacklist(user);
    }

    function removeBlacklist(address user) external onlyBlacklister {
        isBlacklisted[user] = false;
        emit RemovedFromBlacklist(user);
    }

    function burnBlackFunds(address user) external onlyOwner {
        require(isBlacklisted[user], "Address not on blacklist");
        _burn(user, _balances[user]);
    }

    //
    // "bulk transfer"
    //
    // transfer to list of address-amount
    function bulkTransfer(address[] calldata to, uint256[] calldata amount)
        external
        returns (bool)
    {
        require(to.length == amount.length, ERROR_DAS);
        for (uint256 i = 0; i < to.length; i++) {
            require(_balances[msg.sender] >= amount[i], ERROR_BTL);
            _transfer(msg.sender, to[i], amount[i]);
        }
        return true;
    }

    // transferFrom to list of address-amount
    function bulkTransferFrom(
        address from,
        address[] calldata to,
        uint256[] calldata amount
    ) external returns (bool) {
        require(to.length == amount.length, ERROR_DAS);
        for (uint256 i = 0; i < to.length; i++) {
            _allowanceTransfer(msg.sender, from, to[i], amount[i]);
        }
        return true;
    }

    // send same amount to multiple addresses
    function bulkTransfer(address[] calldata to, uint256 amount)
        external
        returns (bool)
    {
        require(_balances[msg.sender] >= amount * to.length, ERROR_BTL);
        for (uint256 i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], amount);
        }
        return true;
    }

    // send same amount to multiple addresses by allowance
    function bulkTransferFrom(
        address from,
        address[] calldata to,
        uint256 amount
    ) external returns (bool) {
        require(_balances[from] >= amount * to.length, ERROR_BTL);
        for (uint256 i = 0; i < to.length; i++) {
            _allowanceTransfer(msg.sender, from, to[i], amount);
        }
        return true;
    }

    //
    // "mint"
    //
    modifier onlyMinter {
        require(isMinter[msg.sender], "Not a Minter");
        _;
    }

    function addMinter(address user) external onlyOwner {
        isMinter[user] = true;
    }

    function removeMinter(address user) external onlyOwner {
        isMinter[user] = false;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _balances[to] += amount;
        _totalSupply += amount;
        require(_totalSupply < maxSupply, "You can not mine that much");
        emit Transfer(address(0), to, amount);
    }

    //
    // "ownable"
    //
    modifier onlyOwner {
        require(msg.sender == owner, ERROR_OO);
        _;
    }

    function giveOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner, ERROR_OO);
        newOwner = address(0);
        owner = msg.sender;
    }

    //
    // "pausable"
    //
    function addPauser(address user) external onlyOwner {
        isPauser[user] = true;
    }

    function removePauser(address user) external onlyOwner {
        isPauser[user] = false;
    }

    modifier onlyPauser {
        require(isPauser[msg.sender], "Not a Pauser");
        _;
    }

    modifier notPaused {
        require(!paused, "Contract is paused");
        _;
    }

    function pause() external onlyPauser notPaused {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyPauser {
        require(paused, "Contract not paused");
        paused = false;
        emit Unpaused();
    }

    //
    // "permit"
    // Uniswap integration EIP-2612
    //
    function permit(
        address user,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "permit: EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            user,
                            spender,
                            value,
                            nonces[user]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == user,
            "permit: INVALID_SIGNATURE"
        );
        _approve(user, spender, value);
    }

    //
    // upgrade contract
    //
    function upgrade(address token) external onlyOwner {
        deprecated = true;
        upgradedAddress = token;
    }

    //
    // ERC20 view functions
    //
    function balanceOf(address account) external view returns (uint256) {
        if (deprecated) {
            return IERC20(upgradedAddress).balanceOf(account);
        }
        return _balances[account];
    }

    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        if (deprecated) {
            return IERC20(upgradedAddress).allowance(account, spender);
        }
        return _allowances[account][spender];
    }

    function totalSupply() external view returns (uint256) {
        if (deprecated) {
            return IERC20(upgradedAddress).totalSupply();
        }
        return _totalSupply;
    }

    //
    // internal functions
    //
    function _approve(
        address account,
        address spender,
        uint256 amount
    ) private notOnBlacklist(account) notOnBlacklist(spender) notPaused {
        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function _allowanceTransfer(
        address spender,
        address from,
        address to,
        uint256 amount
    ) private {
        require(_allowances[from][spender] >= amount, ERROR_ATL);
        require(_balances[from] >= amount, ERROR_BTL);

        // exception for Uniswap "approve forever"
        if (_allowances[from][spender] != type(uint256).max) {
            _approve(from, spender, _allowances[from][spender] - amount);
        }

        _transfer(from, to, amount);
    }

    function _burn(address from, uint256 amount) private notPaused {
        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private notOnBlacklist(from) notOnBlacklist(to) notPaused {
        require(to != address(0), "Use burn instead");
        require(from != address(0), "What a Terrible Failure");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}

// rav3n_pl was here