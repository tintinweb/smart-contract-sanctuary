//SourceUnit: HKT_NFT_Deposit.sol

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "./tool.sol";

interface HKT721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function cardIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface Box {
    function price() external view returns (uint);

    function getPrice() external view returns (uint);

    function U() external view returns (address);

    function NFT() external view returns (address);

    function HKT() external view returns (address);
}

interface Mining {
    function checkUserValue(address addr_) external view returns (uint);
}

contract HKT_NFT_Deposit is Ownable, ERC721Holder {
    address public NFT;
    address public HKT;
    address public U;
    Box public box;
    uint public n = 5;
    uint public catFood = 1000;
    uint[] private walletLimit = [5e16, 1e17, 3e17];

    struct StakeInfo {
        bool staking;
        uint claimTime;
        uint endTime;
        uint rate;
        uint cardId;
        uint toClaim;
    }

    struct CardInfo {
        uint rate;
        uint cycle;
        uint cost;
    }

    struct UserInfo {
        uint claimed;
        uint toClaim;
        uint[] cardList;
    }

    mapping(address => UserInfo)public userInfo;
    mapping(address => mapping(uint => StakeInfo))public stakeInfo;
    mapping(uint => CardInfo)public cardInfo;

    event Deposit(address indexed sender_, uint indexed tokenId_);
    event UnDeposit(address indexed sender_, uint indexed tokenId_);
    event Claim(address indexed sender_, uint indexed amount_);
    event ReNew(address indexed sender_, uint indexed tokenId_);
    constructor(){
        cardInfo[20001] = CardInfo({
        rate : 1500,
        cycle : 7 days,
        cost : 1
        });
        cardInfo[20002] = CardInfo({
        rate : 2500,
        cycle : 15 days,
        cost : 2
        });
        cardInfo[20003] = CardInfo({
        rate : 12000,
        cycle : 30 days,
        cost : 5
        });
    }


    function setAddress(address box_) external onlyOwner {
        box = Box(box_);
        U = box.U();
        HKT = box.HKT();
        NFT = box.NFT();
    }

    function setN(uint n_) external onlyOwner {
        n = n_;
    }

    function setCard(uint ID_, uint rate_, uint cycle_, uint cost_) public onlyOwner {
        cardInfo[ID_] = CardInfo({
        rate : rate_,
        cycle : cycle_,
        cost : cost_
        });
    }

    function setWalletLimit(uint[] calldata com_) public onlyOwner {
        walletLimit = com_;
    }

    function coutingCard(uint cardId_, address addr_) public view returns (uint[] memory){
        uint k = HKT721(NFT).balanceOf(addr_);
        uint tokenId;
        uint cardId;
        uint out;

        if (k == 0) {

        }
        for (uint i = 0; i < k; i++) {
            tokenId = HKT721(NFT).tokenOfOwnerByIndex(addr_, i);
            cardId = HKT721(NFT).cardIdMap(tokenId);
            if (cardId == cardId_) {
                out ++;
            }
        }
        uint[] memory list = new uint[](out);
        uint cout;
        for (uint i = 0; i < k; i++) {
            tokenId = HKT721(NFT).tokenOfOwnerByIndex(addr_, i);
            cardId = HKT721(NFT).cardIdMap(tokenId);
            if (cardId == cardId_) {
                list[cout] = tokenId;
                cout ++;
            }
        }
        return list;

    }

    function deposit(uint tokenId_) external {

        if (block.timestamp > stakeInfo[msg.sender][tokenId_].endTime
        + cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle
            && stakeInfo[msg.sender][tokenId_].staking == true)
        {
            stakeInfo[msg.sender][tokenId_].staking = false;
        }
        require(!stakeInfo[msg.sender][tokenId_].staking, 'already staked');
        uint id = HKT721(NFT).cardIdMap(tokenId_);
        uint balance = IERC20(HKT).balanceOf(msg.sender);
        require(id > 20000, 'wrong card');
        require(balance >= walletLimit[id - 20001], 'not enough HKT');
        uint tempRate = box.price() * n * 1e18 / box.getPrice() * cardInfo[id].rate / 100 / 365 days;
        stakeInfo[msg.sender][tokenId_].rate = tempRate;
        stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        stakeInfo[msg.sender][tokenId_].endTime = block.timestamp + cardInfo[id].cycle;
        stakeInfo[msg.sender][tokenId_].staking = true;
        stakeInfo[msg.sender][tokenId_].cardId = id;
        userInfo[msg.sender].cardList.push(tokenId_);
        HKT721(NFT).safeTransferFrom(msg.sender, address(this), tokenId_);
        emit Deposit(msg.sender, tokenId_);
    }

    function coutingClaim(address addr_, uint tokenId_) public view returns (uint rew_){
        if (!stakeInfo[addr_][tokenId_].staking) {
            return 0;
        }
        if (stakeInfo[addr_][tokenId_].claimTime >= stakeInfo[addr_][tokenId_].endTime) {
            return 0;
        }

        if (block.timestamp > stakeInfo[addr_][tokenId_].endTime && stakeInfo[addr_][tokenId_].claimTime <= stakeInfo[addr_][tokenId_].endTime) {
            rew_ = (stakeInfo[addr_][tokenId_].endTime - stakeInfo[addr_][tokenId_].claimTime) * stakeInfo[addr_][tokenId_].rate;
        } else {
            rew_ = (block.timestamp - stakeInfo[addr_][tokenId_].claimTime) * stakeInfo[addr_][tokenId_].rate;
        }

    }

    function checkCardInfo(address addr_, uint tokenId_) public view returns (uint time, uint cardId_){
        time = stakeInfo[addr_][tokenId_].endTime;
        cardId_ = stakeInfo[addr_][tokenId_].cardId;

    }

    function claim(uint tokenId_) internal {
        require(stakeInfo[msg.sender][tokenId_].staking, 'no staked');
        uint rew = coutingClaim(msg.sender, tokenId_);
        // require(rew > 0, 'none to claim');
        if (rew == 0) {
            return;
        }
        if (block.timestamp > stakeInfo[msg.sender][tokenId_].endTime + cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle) {
            stakeInfo[msg.sender][tokenId_].staking = false;
        }
        IERC20(HKT).transfer(msg.sender, rew + userInfo[msg.sender].toClaim);
        userInfo[msg.sender].claimed += rew + userInfo[msg.sender].toClaim;
        stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        userInfo[msg.sender].toClaim = 0;

    }

    function coutingAll(address addr_) public view returns (uint){
        uint rew;
        for (uint i = 0; i < userInfo[addr_].cardList.length; i++) {
            rew += coutingClaim(addr_, userInfo[addr_].cardList[i]);
        }
        return rew + userInfo[addr_].toClaim;
    }

    function claimAll() public {
        require(userInfo[msg.sender].cardList.length > 0, 'no card');
        uint rew;
        uint big;
        for (uint i = 0; i < userInfo[msg.sender].cardList.length; i++) {
            rew += coutingClaim(msg.sender, userInfo[msg.sender].cardList[i]);
            stakeInfo[msg.sender][userInfo[msg.sender].cardList[i]].claimTime = block.timestamp;
            if (stakeInfo[msg.sender][userInfo[msg.sender].cardList[i]].cardId > big) {
                big = stakeInfo[msg.sender][userInfo[msg.sender].cardList[i]].cardId;
            }
            uint token = userInfo[msg.sender].cardList[i];
            if (stakeInfo[msg.sender][token].endTime + cardInfo[stakeInfo[msg.sender][token].cardId].cycle <= block.timestamp) {
                for (uint k = 0; k < userInfo[msg.sender].cardList.length; k ++) {
                    if (userInfo[msg.sender].cardList[k] == token) {
                        userInfo[msg.sender].cardList[k] = userInfo[msg.sender].cardList[userInfo[msg.sender].cardList.length - 1];
                        userInfo[msg.sender].cardList.pop();
                    }
                }
            }
        }
        uint balance = IERC20(HKT).balanceOf(msg.sender);
        require(balance >= walletLimit[big - 20001], 'not enough HKT');
        IERC20(HKT).transfer(msg.sender, rew + userInfo[msg.sender].toClaim);
        userInfo[msg.sender].claimed += rew + userInfo[msg.sender].toClaim;
        uint rews = rew + userInfo[msg.sender].toClaim;
        userInfo[msg.sender].toClaim = 0;


        emit Claim(msg.sender, rews);
    }

    function coutingCatFood(address addr_) public view returns (uint){
        uint k = HKT721(NFT).balanceOf(addr_);
        uint tokenId;
        uint cardId;
        uint out;
        if (k == 0) {
            return 0;
        }
        for (uint i = 0; i < k; i++) {
            tokenId = HKT721(NFT).tokenOfOwnerByIndex(addr_, i);
            cardId = HKT721(NFT).cardIdMap(tokenId);
            if (cardId == catFood) {
                out ++;
            }
        }
        return out;
    }


    function reNew(uint tokenId_) external {
        require(stakeInfo[msg.sender][tokenId_].staking, 'no staked');
        require(block.timestamp < stakeInfo[msg.sender][tokenId_].endTime + cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle, 'overdue');
        uint temp = coutingCatFood(msg.sender);
        uint need = cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cost;
        StakeInfo storage aa = stakeInfo[msg.sender][tokenId_];
        require(need <= temp, 'not enough');
        uint tokenId;
        uint cardId;
        uint k = HKT721(NFT).balanceOf(_msgSender());
        uint amount;
        for (uint i = 0; i < k; i++) {
            tokenId = HKT721(NFT).tokenOfOwnerByIndex(_msgSender(), i - amount);
            cardId = HKT721(NFT).cardIdMap(tokenId);

            if (cardId == catFood) {
                HKT721(NFT).safeTransferFrom(_msgSender(), address(this), tokenId);
                amount += 1;
                if (amount == need) {
                    break;
                }
            }
        }
        if (block.timestamp > aa.endTime && aa.claimTime < aa.endTime) {
            uint tempRew = (aa.endTime - aa.claimTime) * aa.rate;
            userInfo[msg.sender].toClaim += tempRew;
            stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        }
        if (aa.claimTime >= aa.endTime) {
            stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        }

        stakeInfo[msg.sender][tokenId_].endTime += cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle;
        emit ReNew(msg.sender, tokenId_);

    }


    function unDeposit(uint tokenId_) external {
        StakeInfo storage aa = stakeInfo[msg.sender][tokenId_];
        require(aa.staking, 'no staked');
        uint tokenId;
        uint cardId;
        uint temp = coutingCatFood(msg.sender);
        uint need = cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cost;
        require(need <= temp, 'not enough');
        uint k = HKT721(NFT).balanceOf(_msgSender());
        uint amount;
        for (uint i = 0; i < k; i++) {
            tokenId = HKT721(NFT).tokenOfOwnerByIndex(_msgSender(), i - amount);
            cardId = HKT721(NFT).cardIdMap(tokenId);
            if (cardId == catFood) {
                HKT721(NFT).safeTransferFrom(_msgSender(), address(this), tokenId);
                amount += 1;
                if (amount == need) {
                    break;
                }
            }
        }

        claim(tokenId_);
        stakeInfo[msg.sender][tokenId_].staking = false;
        if (block.timestamp < aa.endTime) {
            HKT721(NFT).safeTransferFrom(address(this), msg.sender, tokenId_);
        }

        for (uint i = 0; i < userInfo[msg.sender].cardList.length; i ++) {
            if (userInfo[msg.sender].cardList[i] == tokenId_) {
                userInfo[msg.sender].cardList[i] = userInfo[msg.sender].cardList[userInfo[msg.sender].cardList.length - 1];
                userInfo[msg.sender].cardList.pop();
            }
        }
        stakeInfo[msg.sender][tokenId_].cardId = 0;
        emit UnDeposit(msg.sender, tokenId_);
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

    function safePullCard(address wallet_, uint tokenId_) public onlyOwner {
        HKT721(NFT).safeTransferFrom(address(this), wallet_, tokenId_);
    }

    function checkUserList(address addr_) public view returns (uint[] memory){
        uint[] memory list = userInfo[addr_].cardList;
        uint count;
        uint index;
        for(uint i = 0; i < list.length; i ++){
            StakeInfo storage info = stakeInfo[msg.sender][list[i]];
            if (info.endTime + cardInfo[info.cardId].cycle > block.timestamp){
                count ++;
            } 
        }
        uint[] memory out = new uint[](count);
        for(uint i = 0; i < list.length; i ++){
            StakeInfo storage info = stakeInfo[msg.sender][list[i]];
            if (info.endTime + cardInfo[info.cardId].cycle > block.timestamp){
                out[index] = list[i];
                index ++;
            } 
        }
            
        return out;
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