// SPDX-License-Identifier: MPL

pragma solidity ~0.8.4;

import "./ERC777.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./Counters.sol";

//interface IERC20 comes from openzeppelin
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/draft-IERC20Permit.sol
interface IERC20Permit {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

//the function transferFromAndCall was added so that with a permit, also a function can be called
interface IERC677ish {
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
    function transferFromAndCall(address sender, address to, uint256 value, bytes calldata data) external returns (bool success);
    event TransferWithData(address indexed from, address indexed to, uint256 value, bytes data);
}

interface IERC677Receiver {
  function onTokenTransfer(address sender, uint value, bytes calldata data) external;
}

contract TGT is IERC20Metadata, IERC20Permit, IERC677ish, EIP712 {

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint96 private _totalEmitted;
    uint64 private _live = 0;
    address private _owner;
    address private _reserve;
    uint64 private _lastEmitMAt;
    uint64 private _lastEmitYAt;
    uint8[] private _curveHalvingYears = [5,5,4,4,3,3,2,2,1]; //1 year has 360 days -> 1 month = 30 days
    uint96 private _curveSupply = INIT_SUPPLY;

    uint96 constant MAX_SUPPLY  = 1000000000 * (10**18); //1 billion
    uint96 constant INIT_SUPPLY =  750000000 * (10**18); //460 + 290(locked) million
    uint64 constant MAX_INT = 2**64 - 1;
    uint64 constant MONTH_IN_S = 60 * 60 * 24 * 30;

    constructor() EIP712(symbol(), "1") {
        _owner = msg.sender;
        _reserve = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, "TGT: not the owner");
        _;
    }

    function setCurve(uint8[] calldata curveHalvingYears) public virtual onlyOwner {
        require(curveHalvingYears.length >= 5, 'TGT: curveHalvingYears not >= 5');
        require(curveHalvingYears[curveHalvingYears.length - 1] == 1, 'TGT: last value must be 1');
        for(uint256 i=0;i<curveHalvingYears.length-1;i++) {
            require(curveHalvingYears[i] > 1, 'TGT: values must be > 1');
        }
        _curveHalvingYears = curveHalvingYears;
    }

    function transferOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "TGT: transfer owner the zero address");
        require(newOwner != address(this), "TGT: transfer owner to this contract");

        _owner = newOwner;
    }

    function setReserve(address reserve) public virtual onlyOwner {
        require(reserve != address(0), "TGT: set reserve to zero address");
        require(reserve != address(this), "TGT: set reserve to this contract");

        _reserve = reserve;
    }

    function live() public view returns (uint64) {
        return _live;
    }

    function name() public view virtual override returns (string memory) {
        return "THORWallet Governance Token";
    }

    function symbol() public view virtual override returns (string memory) {
        return "TGT";
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(recipient != address(this), "ERC20: transfer to this contract");

        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(recipient != address(this), "ERC20: transfer to this contract");

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function burn(uint256 amount) public virtual {
        _transfer(msg.sender, address(0), amount);
        _totalSupply -= amount;
    }

    function mint(address[] calldata account, uint96[] calldata amount) public virtual onlyOwner {
        require(account.length == amount.length, "TGT: accounts and amounts length must match");
        require(_live == 0, "TGT: contract already live. It should be not live (live==false)");

        for(uint256 i=0;i<account.length;i++) {
            require(account[i] != address(0), "ERC20: mint to the zero address");
            require(account[i] != address(this), "TGT: sender is this contract");

            _totalSupply += amount[i];
            _balances[account[i]] += amount[i];
            emit Transfer(address(0), account[i], amount[i]);
        }
        require(_totalSupply <= INIT_SUPPLY, "TGT: surpassing INIT_SUPPLY");
    }

    function emitTokens() public virtual {
        require(_live != 0, "TGT: contract not live yet. It should be live (live==true)");

        uint64 timeInM = uint64((block.timestamp - _live) / MONTH_IN_S);
        if (timeInM <= _lastEmitMAt) {
            return;
        }
        // timeInM at the start will be 1, so subtract 1 so that we start after one
        // month with the emission from 0, to emit the full amount.
        uint64 timeInY = (timeInM - 1) / 12;
        if (timeInY >= _curveHalvingYears.length) {
            _lastEmitMAt = MAX_INT;
            //now we mint all the tokens, also if we forgot a monthly emit
            uint96 toBeMintedFinal = (MAX_SUPPLY - INIT_SUPPLY) - _totalEmitted;
            _totalSupply += toBeMintedFinal;
            _balances[_reserve] += toBeMintedFinal;
            if (isContract(_reserve)) {
                IERC677Receiver(_reserve).onTokenTransfer(address(this), toBeMintedFinal, "");
            }
            emit Transfer(address(0), _reserve, toBeMintedFinal);
            return;
        }

        if (timeInY > _lastEmitYAt) {
            uint96 toBeMintedOld = MAX_SUPPLY - _curveSupply;
            uint96 lastYearlyMint = toBeMintedOld / _curveHalvingYears[_lastEmitYAt];
            _curveSupply += lastYearlyMint;
            _lastEmitYAt = timeInY;
        }

        uint96 toBeMinted = MAX_SUPPLY - _curveSupply;
        uint96 yearlyMint = toBeMinted / _curveHalvingYears[timeInY];
        uint96 additionalAmountM = yearlyMint / 12;

        _totalSupply += additionalAmountM;
        _totalEmitted += additionalAmountM;
        _balances[_reserve] += additionalAmountM;
        _lastEmitMAt = timeInM;

        if (isContract(_reserve)) {
            IERC677Receiver(_reserve).onTokenTransfer(address(this), additionalAmountM, "");
        }
        emit Transfer(address(0), _reserve, additionalAmountM);
    }

    function mintFinish() public virtual onlyOwner {
        require(_totalSupply == INIT_SUPPLY, "TGT: supply mismatch");
        require(_live == 0, "TGT: contract is live already. It should be not live (live==false)");

        _live = uint64(block.timestamp);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferAndCall(address to, uint value, bytes calldata data) public virtual override returns (bool success) {
        transferFromAndCall(msg.sender, to, value, data);
        return true;
    }

    function transferFromAndCall(address sender, address to, uint value, bytes calldata data) public virtual override returns (bool success) {
        transferFrom(sender, to, value);
        emit TransferWithData(sender, to, value, data);
        if (isContract(to)) {
            IERC677Receiver(to).onTokenTransfer(sender, value, data);
        }
        return true;
    }

    function isContract(address addr) private view returns (bool hasCode) {
        uint length;
        assembly { length := extcodesize(addr) }
        return length > 0;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        //the recipient is checked by the callee, as this is also used for token burn, which
        //goes to address 0
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(sender != address(this), "TGT: sender is this contract");
        require(_live != 0, "TGT: contract not live yet. It should be live (live==true)");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(owner != address(this), "TGT: owner is this contract");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(spender != address(this), "TGT: spender is this contract");
        require(_live != 0, "TGT: contract not live yet. It should be live (live==true)");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    // ************ ERC777 ********************
    using Counters for Counters.Counter;
    mapping (address => Counters.Counter) private _nonces;
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}