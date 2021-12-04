// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IMyNFT.sol";


contract ERC20 is Context, IERC20, Ownable {
    using Address for address;

    struct Vesting {
        uint256 amount;
        uint256 deadline;
    }

    mapping (address => Vesting) public vestings;
    mapping (address => Vesting[]) public vestingsLock;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(uint256 => bool) private usedNonces;

    uint256 private _totalSupply;
    uint8 private _decimals = 18;
    string private _name;
    string private _symbol;

    MyNFT private _mainContract;

    address private _verifier;

    uint256 public _totalTreasuryBalance;
    Vesting[] public treasuryBalanceLock;
    uint8 public indexTreasuryLock;
    bool private _isInitTreasure = false;

    uint256 public _totalLiquidityBalance;
    Vesting[] public liquidityBalanceLock;
    uint8 public indexLiquidityLock;

    address public _IDOWallet = 0xf23EA396D1Ee6eCB82677CDF820e4e3C23350a67;
    address public _marketingWallet = 0xE72E3D8017064934F054290E8eDb2E321cE62Da5;
    address public _teamWallet = 0x3fD8B95f2dB23B17C4c2275E04A73803390f1482;
    address public _seedWallet = 0x2991CD5c95B089dFb09B44D2f8687C9dEA2C4aDd;
    address public _privateWallet = 0xAA58939a62ACb293e152E59F21Ce3b7aAADa9707;
    uint256 private _IDOAmount;
    uint256 public _treasuryBalance;
    uint256 public _liquidityBalance;
    uint256 public _vestingBalance;

    event ItemBought(address indexed buyer, uint256 _nftID, uint256 _amount, string args);

    constructor(address cOwner, address verifier) Ownable (cOwner) {
        _name = "TestERC20";
        _symbol = "TERC20";
        _verifier = verifier;
        _totalSupply = 100000000 * 10 ** _decimals;
        _totalLiquidityBalance = 9000000 * 10 ** _decimals;
        _liquidityBalance = 3000000 * 10 ** _decimals;
        _totalTreasuryBalance = 36000000 * 10 ** _decimals;

        _balances[_marketingWallet] = 0;
        _balances[_teamWallet] = 0;
        _balances[_seedWallet] = 0;
        _balances[_privateWallet] = 36000000 * 10 ** _decimals;
        emit Transfer(address(0), _privateWallet, _balances[_privateWallet]);
        _balances[address(this)] = _totalSupply - _balances[_privateWallet];

        _IDOAmount = 500000 * 10 ** _decimals;
        _balances[_IDOWallet] = _IDOAmount;
        emit Transfer(address(0), _IDOWallet, _IDOAmount);
        _balances[address(this)] = _balances[address(this)] -_IDOAmount;

        emit Transfer(address(0), address(this), _totalSupply - (_balances[_IDOWallet] + _balances[_privateWallet]));

        _vestingBalance = _balances[_privateWallet] + _balances[_IDOWallet];

        addVestingLock(_marketingWallet, 1000000 * 10 ** _decimals, block.timestamp + 4 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 5 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 6 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 7 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 8 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 9 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 10 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 11 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 12 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 13 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 14 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 15 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 16 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 17 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 18 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 19 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 20 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 21 * 30 days);
        addVestingLock(_marketingWallet, 500000 * 10 ** _decimals, block.timestamp + 22 * 30 days);
        
        addVestingLock(_teamWallet, 1200000 * 10 ** _decimals, block.timestamp + 12 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 15 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 18 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 21 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 24 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 27 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 30 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 33 * 30 days);
        addVestingLock(_teamWallet, 600000 * 10 ** _decimals, block.timestamp + 36 * 30 days);
        
        addVestingLock(_seedWallet, 750000 * 10 ** _decimals, block.timestamp + 3 * 30 days);
        addVestingLock(_seedWallet, 750000 * 10 ** _decimals, block.timestamp + 6 * 30 days);
        addVestingLock(_seedWallet, 750000 * 10 ** _decimals, block.timestamp + 9 * 30 days);
        addVestingLock(_seedWallet, 750000 * 10 ** _decimals, block.timestamp + 12 * 30 days);
        addVestingLock(_seedWallet, 750000 * 10 ** _decimals, block.timestamp + 15 * 30 days);
        addVestingLock(_seedWallet, 750000 * 10 ** _decimals, block.timestamp + 18 * 30 days);
        addVestingLock(_seedWallet, 500000 * 10 ** _decimals, block.timestamp + 21 * 30 days);

        addVestingLock(_privateWallet, 3600000 * 10 ** _decimals, block.timestamp + 3 * 30 days);
        addVestingLock(_privateWallet, 3600000 * 10 ** _decimals, block.timestamp + 6 * 30 days);
        addVestingLock(_privateWallet, 3600000 * 10 ** _decimals, block.timestamp + 9 * 30 days);
        addVestingLock(_privateWallet, 3600000 * 10 ** _decimals, block.timestamp + 12 * 30 days);
        addVestingLock(_privateWallet, 3600000 * 10 ** _decimals, block.timestamp + 15 * 30 days);
        addVestingLock(_privateWallet, 2400000 * 10 ** _decimals, block.timestamp + 18 * 30 days);

        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 1 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 2 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 3 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 4 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 5 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 6 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 7 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 8 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 9 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 10 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 11 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 12 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 13 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 14 * 30 days);
        addLiquidityLock(600000 * 10 ** _decimals, block.timestamp + 15 * 30 days);

    }


    function setMainNFT(address _contract) external onlyOwner {
        require(_contract != address(0), "Zero address for NFT contract is not acceptable");
        _mainContract = MyNFT(_contract);

    }

    function addLiquidityLock(uint _amount, uint256 deadline) internal {
        Vesting memory vst = Vesting({
                                    amount: _amount,
                                    deadline: deadline
                                });
        liquidityBalanceLock.push(vst);
    }

    function addVestingLock(address _wallet, uint256 _ammount, uint256 _deadline) internal {
        Vesting memory vst = Vesting({
                                    amount: _ammount,
                                    deadline: _deadline
                                });
                                
        vestingsLock[_wallet].push(vst);
    }

    function releaseVesting(address _wallet) private {
        if (vestingsLock[_wallet][0].deadline <= block.timestamp && vestingsLock[_wallet][0].amount > 0) {            
            vestings[_wallet].amount += vestingsLock[_wallet][0].amount;
            _vestingBalance += vestingsLock[_wallet][0].amount;
            emit Transfer(address(0), _wallet, vestingsLock[_wallet][0].amount);
            for (uint i = 0; i < vestingsLock[_wallet].length - 1; i++) {
                vestingsLock[_wallet][i] = vestingsLock[_wallet][i+1];
            }
            delete vestingsLock[_wallet][vestingsLock[_wallet].length - 1];
        }
    }

    function initTreasure() external onlyOwner {
        require(!_isInitTreasure, "Treasury initialized");

        uint256 total = 1 days / 2;
        uint256 interval = 10 minutes;

        uint256 period = total / interval;

        uint256 partAmmount = _totalTreasuryBalance / period;

        for (uint256 i = 1; i <= period; i++) {
            Vesting memory vst = Vesting({
                                    amount: partAmmount,
                                    deadline: block.timestamp + i * interval
                                });
            treasuryBalanceLock.push(vst);
        }

        _isInitTreasure = true;
    }

    function releaseTreasure() internal {
        if (_isInitTreasure && indexTreasuryLock < treasuryBalanceLock.length && block.timestamp > treasuryBalanceLock[indexTreasuryLock].deadline) { 
            _treasuryBalance += treasuryBalanceLock[indexTreasuryLock].amount;
            _totalTreasuryBalance -= treasuryBalanceLock[indexTreasuryLock].amount;
            treasuryBalanceLock[indexTreasuryLock].amount = 0;
            indexTreasuryLock++;
        }
    }

    function releaseLiquidity() internal {
        if (indexLiquidityLock < liquidityBalanceLock.length && block.timestamp > liquidityBalanceLock[indexLiquidityLock].deadline) { 
            _liquidityBalance += liquidityBalanceLock[indexLiquidityLock].amount;
            _totalLiquidityBalance -= liquidityBalanceLock[indexLiquidityLock].amount;
            liquidityBalanceLock[indexLiquidityLock].amount = 0;
            indexLiquidityLock++;
        }
    }

    function claimVesting() external {
        releaseVesting(_msgSender());
        require(vestings[_msgSender()].amount > 0, "Insufficient token amount to claim");
                
        _balances[address(this)] = _balances[address(this)] - vestings[_msgSender()].amount;
        _balances[_msgSender()] = _balances[_msgSender()] + vestings[_msgSender()].amount;
        _vestingBalance -= vestings[_msgSender()].amount;
        emit Transfer(address(this), _msgSender(), vestings[_msgSender()].amount);
        vestings[_msgSender()].amount = 0;
    }

    function claim(uint256 _amount, uint8 _mode, uint256 nonce, bytes memory sig) external {
        require((_mode == 1 || _mode == 2), "Invalid mode. Use '1' for treasury claim and '2' for liquidity claim");
        require(!usedNonces[nonce]);
        bytes32 message = prefixed(keccak256(abi.encodePacked(nonce, address(this))));
        address signer = recoverSigner(message, sig);
        require(signer ==_verifier, "Unauthorized transaction");
        usedNonces[nonce] = true;
        if (_mode == 1 ) {
            releaseTreasure();
            require(_treasuryBalance >= _amount, "Insufficient amount to claim");
            _balances[address(this)] = _balances[address(this)] - _amount;
            _balances[_msgSender()] = _balances[_msgSender()] + _amount;
            _treasuryBalance -= _amount;
            emit Transfer(address(this), _msgSender(), _amount);
        } else {
            releaseLiquidity();
            require(_liquidityBalance >= _amount, "Insufficient amount to claim");
            _balances[address(this)] = _balances[address(this)] - _amount;
            _balances[_msgSender()] = _balances[_msgSender()] + _amount;
            _liquidityBalance -= _amount;
            emit Transfer(address(this), _msgSender(), _amount);
        }
    }


    function buyItem(uint256 _amount, uint256 _category, bool  _mode, string memory args) external {
        require(_amount > 0, "Token amount cannot be zero");
        require(_balances[_msgSender()] >= _amount, "Insufficient token balance to buy item");
        _balances[_msgSender()] = _balances[_msgSender()] - _amount;
        _balances[address(this)] = _balances[address(this)] + _amount;
        _treasuryBalance += _amount;
        emit Transfer(_msgSender(), address(this), _amount);
        if (!_mode) {
            uint256 result = _mainContract.createFromERC20(_msgSender(), _category);
            emit ItemBought(_msgSender(), result, _amount, args);
        } else {
            emit ItemBought(_msgSender(), 0, _amount, args);

        }

    }



    function recoverSigner(bytes32 message, bytes memory sig) public pure
    returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
    public
    pure
    returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }



    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


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


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


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


        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

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

}