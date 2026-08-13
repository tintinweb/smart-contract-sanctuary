/**
 *Submitted for verification at cronoscan.com on 2022-05-24
*/

/**
 *Submitted for verification at cronoscan.com on 2022-05-21
*/

// SPDX-License-Identifier: GPL-3.0

/*
Devloper: bricklerex
Email: [email protected]
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

interface ICronaSwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract Nodes {

    struct Node {
        string nodeName;
        uint timeCreated;
        uint nodeRewardRate;
        uint lastClaimed;
        uint pricePaid;
    }


    address public owner;
    address dev_address;
    bool public paused;
    bool public affiliatePaused;
    bool public extraNodesProgramPaused;
    uint public rewardRateGlobal;
    uint public nodePriceInUSD;
    uint public taxRateGlobal;
    uint public timeLockInDays;
    uint public totalNodes;
    uint public minWithdraw;
    uint public referralRate;
    uint public extraNodeRate;
    address treasuryWallet;
    address marketingWallet;
    address devWallet;
    address[] public buyers;

    //0x873c905681Fb587cc12a29DA5CD3c447bE61F146 Testnet
    //0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23 mainnet
    ERC20 erctoken = ERC20(0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23);

    mapping (address=>Node[]) public balances;
    mapping (address=>uint) public referralNodesCurrent;
    mapping (address=>uint) public referralNodesTotal;
    mapping (address=>uint) public boughtNodesCurrent;


    constructor() {
        owner = msg.sender;
        paused = false;
        affiliatePaused = false;
        extraNodesProgramPaused = false;
        rewardRateGlobal = 3;//3
        nodePriceInUSD = 100;//100
        taxRateGlobal = 10;
        timeLockInDays = 3;//3
        minWithdraw = 1;
        extraNodeRate = 10;//10
        referralRate = 10;//10
        treasuryWallet = 0x9B66E15ACc9f6E194Ad1cf1Ea5f68035aF7bd701;
        marketingWallet = 0x4d334707D731F6F2f1F4C92AAE60d5D20032Bf98;
        devWallet = 0xD683793Ac867f5D4539E498D25ecb4B94c88ea7A;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(paused == false, "Contract Paused");
        _;
    }

    function getBalanceOf(address user) public view returns (uint){
        return balances[user].length;
    }

    function getReferralNodesCount(address user) public view returns (uint){
        return referralNodesTotal[user];
    }

    function setOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function togglePaused() onlyOwner public {
        paused = !paused;
    }

    function toggleAffiliatePaused() onlyOwner public {
        affiliatePaused = !affiliatePaused;
    }

    function toggleExtraNodePaused() onlyOwner public {
        extraNodesProgramPaused = !extraNodesProgramPaused;
    }

    function setRewardRate(uint rewardRate) onlyOwner public {
        rewardRateGlobal = rewardRate;
    }

    function setTaxRate(uint taxRate) onlyOwner public {
        taxRateGlobal = taxRate;
    }

    function setNodePriceInUSD(uint nodePrice) onlyOwner public {
        nodePriceInUSD = nodePrice;
    }

    function setMinWithdrawal(uint minReward) onlyOwner public {
        minWithdraw = minReward;
    }

    function setReferralRate(uint newReferralRate) onlyOwner public {
        referralRate = newReferralRate;
    }

    function setExtraNodeRate(uint newRate) onlyOwner public {
        extraNodeRate = newRate;
    }

    function setTimelock(uint timelock) onlyOwner public {
        timeLockInDays = timelock;
    }

    function setMarketingWallet(address newMarketingWallet) onlyOwner public {
        marketingWallet = newMarketingWallet;
    }

    function setTreasuryWallet(address newTreasuryWallet) onlyOwner public {
        treasuryWallet = newTreasuryWallet;
    }

    function getUnclaimedNonTimeLockedRewards(address user) public view returns (uint) {
        Node[] memory allNodes = balances[user];
        uint totalRewards = 0;
        uint daysElapsed;
        uint nodeReward;

        for (uint i = 0; i < allNodes.length; i++) {
            if(block.timestamp > allNodes[i].timeCreated + timeLockInDays * 1 days) {//days
                daysElapsed = (block.timestamp - allNodes[i].lastClaimed)/86400;//86400
                nodeReward = (rewardRateGlobal * nodePriceInUSD * daysElapsed)/100;
                totalRewards = totalRewards + nodeReward;
            }
        }

        return totalRewards;
    }

    function reverse(Node[] storage a) internal returns (bool) {
        Node memory t;
        for (uint i = 0; i < a.length / 2; i++) {
            t = a[i];
            a[i] = a[a.length - i - 1];
            a[a.length - i - 1] = t;
        }
        return true;
    }

    function cancelNodes(address user, uint numNodes) onlyOwner public returns (bool) {
        require(numNodes <= balances[user].length, "You are cancelling more nodes than the user owns");
        reverse(balances[user]);
        
        for(uint i = 0; i < numNodes; i++) {
            balances[user].pop();
            totalNodes--;
        }

        reverse(balances[user]);

        return true;
    }

    function getNodePriceInCRO(uint paidUSD) public view returns (uint) {
        uint croperusd = getCROUSD();
        return croperusd*paidUSD;
    }

    function getCROUSD() public view returns (uint) {
        // 0x0625A68D25d304aed698c806267a4e369e8Eb12a WCRO/USDC
        //0x91B94Fd50F764a8A607F1cb59Bb3D0c9B240425a Testnet
        (uint112 reserve0, uint112 reserve1,) = ICronaSwapPair(0x0625A68D25d304aed698c806267a4e369e8Eb12a).getReserves();

        uint quote = ((reserve0)/reserve1)*1000000;//reserve0/reserve1

        return quote;
    }

    function buyNode(string memory nameForNode, address referralAddr) notPaused public returns (bool) {

        uint bal = erctoken.balanceOf(msg.sender);

        uint priceInCRO = getNodePriceInCRO(nodePriceInUSD);

        require(bal >= priceInCRO, "Not enough balance");
        require(erctoken.allowance(msg.sender, address(this)) >= priceInCRO, "Need higher approvals");

        erctoken.transferFrom(msg.sender, treasuryWallet, priceInCRO);

        balances[msg.sender].push(Node({nodeName: nameForNode, timeCreated: block.timestamp, nodeRewardRate: rewardRateGlobal, lastClaimed: block.timestamp, pricePaid: getNodePriceInCRO(nodePriceInUSD)}));

        if(balances[msg.sender].length < 1) {
            buyers.push(msg.sender);
        }
        
        totalNodes = totalNodes + 1;

        if(!affiliatePaused) {
            referralNodesCurrent[referralAddr] = referralNodesCurrent[referralAddr] + 1;
            referralNodesTotal[referralAddr] = referralNodesTotal[referralAddr] + 1;
        }

        if(!extraNodesProgramPaused) {
            referralNodesCurrent[msg.sender] = referralNodesCurrent[msg.sender] + 1;
            referralNodesTotal[msg.sender] = referralNodesTotal[msg.sender] + 1;
        }

        if(!affiliatePaused) {
            while(referralNodesCurrent[referralAddr] >= referralRate) {
                if(balances[referralAddr].length < 1) {
                    buyers.push(referralAddr);
                }

                balances[referralAddr].push(Node({nodeName: nameForNode, timeCreated: block.timestamp, nodeRewardRate: rewardRateGlobal, lastClaimed: block.timestamp, pricePaid: getNodePriceInCRO(nodePriceInUSD)}));
                totalNodes++;
                referralNodesCurrent[referralAddr] = referralNodesCurrent[referralAddr] - referralRate;
            }
        }

        if(!extraNodesProgramPaused) {
            while(referralNodesCurrent[msg.sender] >= extraNodeRate) {
                if(balances[msg.sender].length < 1) {
                    buyers.push(msg.sender);
                }

                balances[msg.sender].push(Node({nodeName: nameForNode, timeCreated: block.timestamp, nodeRewardRate: rewardRateGlobal, lastClaimed: block.timestamp, pricePaid: getNodePriceInCRO(nodePriceInUSD)}));
                totalNodes++;
                referralNodesCurrent[msg.sender] = referralNodesCurrent[msg.sender] - extraNodeRate;
            }
        }

        return true;
    }

    fallback() external payable { revert(); }
    receive() external payable { revert(); }

    function claimRewards() notPaused public returns (bool) {
        uint totalRewards = getNodePriceInCRO(getUnclaimedNonTimeLockedRewards(msg.sender));
        uint taxAmount = totalRewards/10;

        uint devTax = (taxAmount*3)/10;
        uint marketingTax = taxAmount - devTax;

        totalRewards = totalRewards - taxAmount;

        require(totalRewards >= minWithdraw*(10**18), "Less than minimum withdrawal. Please wait until the rewards accumulate more.");

        erctoken.transferFrom(treasuryWallet, msg.sender, totalRewards);
        erctoken.transferFrom(treasuryWallet, marketingWallet, marketingTax);
        erctoken.transferFrom(treasuryWallet, devWallet, devTax);

        Node[] memory allNodes = balances[msg.sender];

        for (uint i = 0; i < allNodes.length; i++) {
            if(block.timestamp > allNodes[i].timeCreated + timeLockInDays * 1 days) {//days
                balances[msg.sender][i].lastClaimed = block.timestamp;
            }
        }

        return true;
    }

    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,' ',b));
    }

    function awardNodes(address recv, uint numOfNodes, uint nodeTimeCreated, uint nodeTimeClaimed) onlyOwner public returns (bool) {
        if(balances[recv].length < 1) {
            buyers.push(recv);
        }

        for (uint i = balances[recv].length; i < numOfNodes; i++) {
            balances[recv].push(Node({nodeName: concatenate("Node ", uintToString(i+1)), timeCreated: nodeTimeCreated, nodeRewardRate: rewardRateGlobal, lastClaimed: nodeTimeClaimed, pricePaid: getNodePriceInCRO(nodePriceInUSD)}));
            totalNodes = totalNodes + 1;
        }

        return true;
    }

    function getNodeStats(address sender) public view returns (string memory) {
        string memory obj = "[{";

        Node[] memory allNodes = balances[sender];

        for (uint i = 0; i < allNodes.length; i++) {
            string memory nameString = string(abi.encodePacked("'name'",":","'Node ", uintToString(i+1),"',"));
            string memory timeCreatedString = string(abi.encodePacked("'created'",":", uintToString(allNodes[i].timeCreated),","));
            string memory nodePricePaid = string(abi.encodePacked("'pricePaid'",":", uintToString(allNodes[i].pricePaid), ","));
            string memory lastClaimedString;

            if(allNodes[i].timeCreated == allNodes[i].lastClaimed) {
                lastClaimedString = string(abi.encodePacked("'claimed'",":", "false",","));
            } else {
                lastClaimedString = string(abi.encodePacked("'claimed'",":", uintToString(allNodes[i].lastClaimed),","));
            }

            string memory locked;

            if(block.timestamp >= (allNodes[i].timeCreated + timeLockInDays * 1 days)) {//days
                locked = "false";
            } else {
                locked = "true";
            }

            string memory lockedString = string(abi.encodePacked("'locked'",":","'", locked,"'}"));

            obj = string(abi.encodePacked(obj, nameString, timeCreatedString, nodePricePaid, lastClaimedString, lockedString));

            if(i != allNodes.length-1) {
                obj = string(abi.encodePacked(obj,",{"));
            } else {
                obj = string(abi.encodePacked(obj,"]"));
            }
        }

        return obj;
    }
}