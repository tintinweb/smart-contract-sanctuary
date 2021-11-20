/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Owned {
    bool internal paused;
    mapping(address => bool) internal _owners;
    uint8 internal _amountOwners = 0;

    constructor() {
        _owners[msg.sender] = true;
        _amountOwners++;
        paused = false;
    }

    function isOwner(address account) public view returns (bool) {
        return _owners[account];
    }

    modifier onlyOwner() {
        require(_owners[msg.sender], "Owned: caller is not an owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: Contract is not paused");
        _;
    }
}

contract Multisignature is Owned {
    string private _topic = "";

    event EnableMultisign(address account);
    event DisableMultisign(address account);

    mapping(address => bool) internal _haveVoted;
    uint8 private _voteCount;
    address[] _listOfvoters = new address[](0);

    bool _multisignVoteGiven = false;
    bool _multisignEnabled = false;

    function requireMultisignVote(string memory topic) internal returns (bool) {
        if (
            !_multisignEnabled ||
            _amountOwners == 1 ||
            _multisignVoteGiven ||
            (keccak256(abi.encodePacked((topic))) ==
                keccak256(abi.encodePacked((_topic))))
        ) {
            resetVoting();
            return true;
        }
        return false;
    }

    function enableMultisign() public onlyOwner {
        _multisignEnabled = false;
        emit EnableMultisign(msg.sender);
    }

    function disableMultisign() public onlyOwner {
        require(
            requireMultisignVote("DISABLE_MULTISIGN"),
            "Multi: do not meet multisign requirements"
        );
        _multisignEnabled = true;
        emit DisableMultisign(msg.sender);
    }

    function resetVoting() public onlyOwner {
        _multisignVoteGiven = false;
        _voteCount = 0;
        _topic = "";
        for (uint256 voter = 0; voter < _listOfvoters.length; voter++) {
            _haveVoted[_listOfvoters[voter]] = false;
        }
        _listOfvoters = new address[](0);
    }

    function vote() public onlyOwner {
        require(
            _amountOwners > 1 && _amountOwners <= 3,
            "Owned: voting requires > 1 and <=3 owners"
        );
        require(!_haveVoted[msg.sender], "Owned: account has voted already");

        _haveVoted[msg.sender] = true;
        _listOfvoters.push(msg.sender);
        _voteCount++;

        if (_voteCount >= 2) {
            _multisignVoteGiven = true;
        }
    }

    function setTopic(string memory topic) public onlyOwner {
        require(
            keccak256(abi.encodePacked((topic))) ==
                keccak256(abi.encodePacked((""))),
            "Multisign: topic cannot be change during voting."
        );
        _topic = topic;
    }
}

contract OwnedExtended is Multisignature {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function addNewOwner(address newOwner) public onlyOwner {
        require(
            requireMultisignVote("ADD_NEW_OWNER"),
            "Multi: do not meet multisign requirements"
        );
        require(newOwner != address(0), "Owned: cannot be a zero address");
        require(!_owners[newOwner], "Owned: account is already an owner");
        require(
            _amountOwners < 3,
            "Owned: amount of owners equal and less than three"
        );

        _owners[newOwner] = true;
        _amountOwners++;
    }

    function removeOwner(address account) public onlyOwner {
        require(
            requireMultisignVote("REMOVE_OWNER"),
            "Multi: do not meet multisign requirements"
        );
        require(_owners[account], "Owned: account is not owner");
        require(account != msg.sender, "Owned: owner cannot remove himself");
        require(
            _amountOwners > 1 && _amountOwners <= 3,
            "Owned: amount of owners equal and less than three"
        );
        _owners[account] = false;
        _amountOwners--;
    }
}

contract Pausable is OwnedExtended {
    event PausedEvt(address account);
    event UnpausedEvt(address account);

    function pause() public onlyOwner whenNotPaused {
        require(
            requireMultisignVote("PAUSE"),
            "Multi: do not meet multisign requirements"
        );
        paused = true;
        emit PausedEvt(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        require(
            requireMultisignVote("UNPAUSE"),
            "Multi: do not meet multisign requirements"
        );
        paused = false;
        emit UnpausedEvt(msg.sender);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract FI25 is Pausable, IERC20 {
    address private _owner;
    address private _commissionHolder;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    string private _name = "FIDIS FI25 Crypto Index";
    string private _symbol = "FI25";

    uint256 private _totalSupply = 0;
    uint256 _minTxAmount = 100;
    uint8 private _decimals = 8;

    event ReduceTokenSupply(address from, uint256 value);
    event CommissionHolderChange(address from, address to);

    constructor() {
        _owner = msg.sender;
        _isExcludedFromFee[_owner] = true;
        _commissionHolder = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function increaseTokenSupply(address account, uint256 amount)
        public
        whenNotPaused
        onlyOwner
    {
        require(
            requireMultisignVote("INCREASE_TOKEN_SUPPLY"),
            "Multi: do not meet multisign requirements"
        );
        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function reduceTokenSupply(address account, uint256 amount)
        public
        whenNotPaused
        onlyOwner
    {
        require(
            requireMultisignVote("REDUCE_TOKEN_SUPPLY"),
            "Multi: do not meet multisign requirements"
        );
        require(account != address(0), "ERC20: burn from the zero address");
        require(
            account != address(this),
            "ERC20: burn from the contract's address"
        );
        require(_owners[account], "ERC20: tokens are burned from an owner");
        uint256 accountBalance = _balances[account];

        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit ReduceTokenSupply(account, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            recipient != address(this),
            "ERC20: transfer to the contract's address"
        );

        require(
            amount >= _minTxAmount || _isExcludedFromFee[sender],
            "Transfer amount must be greater than 100 or excluded from fees"
        );

        uint256 fee = 0;
        if (_isExcludedFromFee[sender]) {
            fee = 0;
        } else {
            fee = amount / 100;
            _balances[_commissionHolder] += fee;
            emit Transfer(msg.sender, _commissionHolder, fee);
        }

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += (amount - fee);
        emit Transfer(msg.sender, recipient, amount - fee);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(
            spender != address(this),
            "ERC20: approve to the contract's address"
        );

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        whenNotPaused
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenNotPaused
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        whenNotPaused
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function excludeAddrFromTxFee(address account) public whenNotPaused onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeAddrInTxFee(address account) public whenNotPaused onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setAccountAsCommissionHolder(address account) public onlyOwner {
        require(
            requireMultisignVote("SET_COMMISSION_HOLDER"),
            "Multi: do not meet multisign requirements"
        );
        require(
            account != address(0),
            "Owned: account cannot be zero address."
        );
        require(
            _owners[account],
            "Owned: account must be one of the current owners."
        );
        require(
            _commissionHolder != account,
            "Owned: account is commission holder."
        );

        uint256 _balanceCommissionHolder = _balances[_commissionHolder];
        _balances[_commissionHolder] = 0;
        _balances[account] = _balanceCommissionHolder;

        emit CommissionHolderChange(_commissionHolder, account);
        _commissionHolder = account;
    }

    function commissionHolder() public view onlyOwner returns (address) {
        return _commissionHolder;
    }

    function transferOwnership(address newOwner) public onlyOwner {

	//Check for multisig vote eligibility
        require(
            requireMultisignVote("TRANSFER_OWNERSHIP"),
            "Multi: do not meet multisign requirements"
        );

	//Check to make sure that new owner is not the caller
        require(newOwner != msg.sender, "Owner Transfer Error: New owner is the same as caller");

	//Check to make sure that new owner is not already an owner
        require(!_owners[newOwner], "Owner Transfer Error: New owner is already owner");

	//Check to make sure that new owner's address is not zero
        require(newOwner != address(0), "Owner Transfer Error: New owner's address cannot be zero");

	//Check to make sure that new owner's address is not the contract address
        require(newOwner != address(this), "Owner Transfer Error: Address cannot be contract's address");

	//Transfer FI25 tokens to new contract owner's address
        uint256 _balanceCaller = _balances[msg.sender];
        _balances[msg.sender] = 0;
        _balances[newOwner] = _balanceCaller;

	//Transfer commission holder to new contract owner's address
        if (_commissionHolder == msg.sender) {
            _commissionHolder = newOwner;
        }

	//Previous contract owner is removed from array
        _owners[msg.sender] = false;
	//New contract owner is added to array
        _owners[newOwner] = true;

	//Emit event log
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}