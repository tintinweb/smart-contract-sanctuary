//SourceUnit: HKT_Falsh_Exchange.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./tool.sol";

interface DECIMALS {
    function decimals() external view returns (uint);

    function symbol() external view returns (string memory);
}
//

contract HKT_Exchange is Ownable {
    bool public initialization;
    address public USD;
    address public bank;
    uint public refreshTime;
    uint public constant Acc = 1e18;
    uint public no0;
    uint[] public no;
    string[] internal t0List;

    struct CoinList {
        string[] token1List;
    }

    struct PairInfo {
        uint id;
        string symbol;
        bool status;
        bool tradeSwitch;
        address token0;
        address token1;
        uint price;
        uint fee;

        uint lastTime;
        uint quota;
        uint dailyQuota;
    }

    struct RefreshforSell {
        uint lastTime;
        uint quota;
        uint dailyQuota;
    }

    struct TokenId {
        uint ID;
        uint price;
        address coinAddr;
    }

    mapping(uint => address) public token0Address;
    mapping(uint => CoinList) internal coinList;

    mapping(uint => mapping(uint => address)) public token1Address;

    mapping(uint => PairInfo) public pairInfo;
    mapping(address => TokenId) public tokenId;
    mapping(address => mapping(address => uint)) public findID;
    mapping(uint => RefreshforSell) public quota1to0;

    event SetUsdPair(uint indexed __Id, string indexed _symbol);
    event SetTokenPair(uint indexed __Id, string indexed _symbol);
    event ClosePair(uint indexed __id);
    event RebotPair(uint indexed __id);
    event SwapExactToken0to1(address indexed sender_, uint indexed ID_, uint indexed amount_);
    event SwapExactToken1to0(address indexed sender_, uint indexed ID_, uint indexed amount_);

    modifier checkRefrech (){
        if (block.timestamp > refreshTime) {
            uint x = 86400 - (block.timestamp % 86400);
            refreshTime = block.timestamp + x;
        }
        _;
    }

    function initCon(address bank_, address USDT_) public onlyOwner {
        setAddToken0(USDT_);
        bank = bank_;
        initialization = true;
        USD = USDT_;
        uint x = 86400 - (block.timestamp % 86400);
        refreshTime = block.timestamp + x;
    }

    function setAddToken0(address t0_) public onlyOwner {
        no.push(0);
        token0Address[no0] = t0_;
        no0 += 1;
        t0List.push(DECIMALS(t0_).symbol());
    }

    function setPairSwitch(uint id_, bool com_, uint quota_) public onlyOwner {
        pairInfo[id_].tradeSwitch = com_;
        quota1to0[id_].lastTime = refreshTime;
        quota1to0[id_].quota = quota_;
    }

    function setPairFee(uint id_, uint fee_) public onlyOwner {
        pairInfo[id_].fee = fee_;
    }

    function setPairPriceWithUSDT(uint id_, uint price_) public onlyOwner {
        pairInfo[id_].price = price_;
        address _token = pairInfo[id_].token1;
        tokenId[_token].price = price_;
    }

    function setPairPriceWithToken(uint id_, uint price_) public onlyOwner {
        pairInfo[id_].price = price_;
    }

    function setPairWithU(string memory symbol_, address token0_, address token1_, uint price_, uint quota_) public onlyOwner returns (bool){
        uint id_ = no[0];
        if (id_ == 0){
            no[0] += 1;
            id_ += 1;
        }
        require(!pairInfo[id_].status, "the slot is used");
        require(token0_ != token1_, 'same address');
        token1Address[0][id_] = token1_;
        coinList[0].token1List.push(DECIMALS(token1_).symbol());

        pairInfo[id_].status = true;
        pairInfo[id_].token0 = token0_;
        pairInfo[id_].token1 = token1_;
        pairInfo[id_].price = price_;
        pairInfo[id_].symbol = symbol_;
        pairInfo[id_].id = id_;
        pairInfo[id_].quota = quota_;
        pairInfo[id_].lastTime = refreshTime;

        tokenId[token1_].ID = id_;
        tokenId[token1_].price = price_;
        tokenId[token1_].coinAddr = token1_;

        findID[token0_][token1_] = id_;
        findID[token1_][token0_] = id_;
        no[0] += 1;

        emit SetUsdPair(id_, symbol_);
        return true;
    }

    function setPairWithToken(uint t0_id_, string memory symbol_, address token0_, address token1_, uint price_, uint quota_) public onlyOwner checkRefrech returns (bool){
        uint id_ = (t0_id_ * 100) + no[t0_id_];

        require(!pairInfo[id_].status, "the slot is used");
        token1Address[t0_id_][id_] = token1_;
        coinList[t0_id_].token1List.push(DECIMALS(token1_).symbol());

        pairInfo[id_].status = true;
        pairInfo[id_].token0 = token0_;
        pairInfo[id_].token1 = token1_;
        pairInfo[id_].price = price_;
        pairInfo[id_].symbol = symbol_;
        pairInfo[id_].id = id_;
        pairInfo[id_].quota = quota_;
        pairInfo[id_].lastTime = refreshTime;

        findID[token0_][token1_] = id_;
        findID[token1_][token0_] = id_;
        no[t0_id_] += 1;
        emit SetTokenPair(id_, symbol_);
        return true;
    }

    function removePair(uint id_) public onlyOwner checkRefrech returns (bool){
        require(pairInfo[id_].status, "the slot is null");
        pairInfo[id_].status = false;

        emit ClosePair(id_);
        return true;
    }

    function rebotPair(uint id_) public onlyOwner checkRefrech returns (bool){
        require(!pairInfo[id_].status, "the slot still alive");
        require(pairInfo[id_].price != 0, "slot null");
        pairInfo[id_].status = true;

        emit RebotPair(id_);
        return true;
    }

    function _swap(uint inAmount_, address pathIn, address pathOut, address addr_, uint id_, uint direction_) internal {
        uint outAmount;
        uint deIn = DECIMALS(pathIn).decimals();
        if (deIn != 18) {
            uint x = Acc / 10 ** deIn;
            inAmount_ = inAmount_ * x;
        }
        
        if (direction_ == 1) {
            outAmount = (inAmount_ * Acc) / pairInfo[id_].price;
        } else if (direction_ == 2) {
            outAmount = (inAmount_ * pairInfo[id_].price) / Acc;
        }
        
        uint deOut = DECIMALS(pathOut).decimals();
        if (deOut != 18) {
            uint x = Acc / 10 ** deOut;
            outAmount = outAmount / x;
        }

        IERC20(pathOut).transfer(addr_, outAmount);
    }

    function swapExactToken(uint amount_, address[] calldata path, address addr_) public checkRefrech {
        require(amount_ > 0, 'no amount');
        require(path[0] != path[1], 'Exchange: INVALID_PATH');
        uint _inAmount;
        uint outAmount;
        address input;
        address output;
        for (uint i; i < path.length - 1; i++) {
            (input, output) = (path[i], path[i + 1]);
        }

        uint id = findID[input][output];
        require(id != 0,'worng tokenpair');
        if (block.timestamp > pairInfo[id].lastTime) {
            pairInfo[id].dailyQuota = 0;
        }

        if (input == pairInfo[id].token0) {
            if (block.timestamp > pairInfo[id].lastTime) {
                pairInfo[id].dailyQuota = 0;
            }

            if (pairInfo[id].lastTime < refreshTime) {
                pairInfo[id].lastTime = refreshTime;
                pairInfo[id].dailyQuota = 0;
            }
            _inAmount = amount_ * (100 - pairInfo[id].fee) / 100;
            outAmount = (_inAmount * Acc) / pairInfo[id].price;
            require(pairInfo[id].dailyQuota + outAmount < pairInfo[id].quota, 'out of quota');
            require(pairInfo[id].status, "null pair");
            require(calculate0to1(amount_, path) < IERC20(output).balanceOf(bank), 'out of Reserve');
            uint de = DECIMALS(input).decimals();
            if (de != 18) {
                uint x = Acc / 10 ** de;
                _inAmount = _inAmount / x;
            }
            uint buy = 1;
            IERC20(input).transferFrom(addr_, bank, _inAmount);
            _swap(_inAmount, input, output, addr_, id, buy);
            pairInfo[id].dailyQuota += outAmount;
            emit SwapExactToken0to1(msg.sender, id, amount_);

        } else if (input == pairInfo[id].token1) {
            if (block.timestamp > quota1to0[id].lastTime) {
                quota1to0[id].dailyQuota = 0;
            }
            if (quota1to0[id].lastTime < refreshTime) {
                quota1to0[id].lastTime = refreshTime;
                quota1to0[id].dailyQuota = 0;
            }
            _inAmount = amount_ * (100 - pairInfo[id].fee) / 100;
            outAmount = (_inAmount * pairInfo[id].price) / Acc;
            require(quota1to0[id].dailyQuota + outAmount  < quota1to0[id].quota, 'out of quota');
            require(pairInfo[id].tradeSwitch, "not open");
            require(pairInfo[id].status, "null pair");
            require(calculate1to0(amount_, path) < IERC20(output).balanceOf(bank), 'out of Reserve');
            uint de = DECIMALS(input).decimals();
            if (de != 18) {
                uint x = Acc / 10 ** de;
                _inAmount = _inAmount / x;
            }
            uint sell = 2;
            IERC20(input).transferFrom(addr_, bank, _inAmount);
            _swap(_inAmount, input, output, addr_, id, sell);
            quota1to0[id].dailyQuota += outAmount;
            emit SwapExactToken1to0(msg.sender, id, amount_);
        }
    }

    function calculate0to1(uint amount_, address[] calldata path) public view returns (uint) {
        address input;
        address output;
        for (uint i; i < path.length - 1; i++) {
            (input, output) = (path[i], path[i + 1]);
        }
        uint id = findID[input][output];
        uint temp = amount_ * (100 - pairInfo[id].fee) / 100;
        uint _amount1 = (temp * Acc) / pairInfo[id].price;

        return _amount1;
    }

    function calculate1to0(uint amount_, address[] calldata path) public view returns (uint) {
        address input;
        address output;
        for (uint i; i < path.length - 1; i++) {
            (input, output) = (path[i], path[i + 1]);
        }

        uint id = findID[input][output];
        uint temp = amount_ * (100 - pairInfo[id].fee) / 100;
        uint _amount0 = (temp * pairInfo[id].price) / Acc;

        return _amount0;

    }


    function y(address token1_) external view returns (uint) {
        uint id = findID[USD][token1_];
        require(pairInfo[id].status, "null pair");
        uint _y = pairInfo[id].price;
        return _y;
    }

    function checkQuota(address[] calldata path) public view returns (uint _quota, uint _remainingAmount, uint _price, uint _fee){
        address input;
        address output;
        for (uint i; i < path.length - 1; i++) {
            (input, output) = (path[i], path[i + 1]);
        }
        uint id = findID[input][output];
        if (input == pairInfo[id].token0) {
            if (block.timestamp > pairInfo[id].lastTime) {
                _quota = pairInfo[id].quota;
                _remainingAmount = _quota;
            } else {
                _quota = pairInfo[id].quota;
                _remainingAmount = _quota - pairInfo[id].dailyQuota;
            }
        } else if (input == pairInfo[id].token1) {
            if (block.timestamp > quota1to0[id].lastTime) {
                _quota = quota1to0[id].quota;
                _remainingAmount = _quota;
            } else {
                _quota = quota1to0[id].quota;
                _remainingAmount = _quota - quota1to0[id].dailyQuota;
            }
        }

        _price = pairInfo[id].price;
        _fee = pairInfo[id].fee;
    }

    function getCoinList(uint t0_) public view returns (string[] memory _list){
        _list = coinList[t0_].token1List;
    }

    function getCoinAddress(uint token0id_, uint token1id_) public view returns (address _address){
        _address = token1Address[token0id_][token1id_];
    }

    function getToken0Address(uint token0id_) public view returns (address _address){
        _address = token0Address[token0id_];

    }

    function checkt0() public view returns (string[] memory _list){
        _list = t0List;
    }
    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

    function checkReserves(uint id_) public view returns (bool _status, string memory _symbol, uint _reserve0, uint _reserve1, uint _price, uint _timeTamps){
        address _token0 = pairInfo[id_].token0;
        address _token1 = pairInfo[id_].token1;
        _status = pairInfo[id_].status;
        _symbol = pairInfo[id_].symbol;
        _reserve0 = IERC20(_token0).balanceOf(bank);
        _reserve1 = IERC20(_token1).balanceOf(bank);
        _price = pairInfo[id_].price;
        _timeTamps = block.timestamp;
    }

}

//SourceUnit: tool.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


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

contract ERC20 is Context, IERC20 {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

library Address {
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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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