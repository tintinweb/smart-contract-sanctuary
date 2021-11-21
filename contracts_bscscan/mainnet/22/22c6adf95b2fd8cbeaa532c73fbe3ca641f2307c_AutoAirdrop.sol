/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract GasReward {
    mapping(address => uint) private start;

    function gasRewardStart() internal {
        start[msg.sender] = gasleft();
    }

    function gasRewardEnd() internal returns (uint count) {
        count = start[msg.sender] - gasleft();
        start[msg.sender] = 0;
    }
}

pragma solidity >=0.8.0 <0.9.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity >=0.8.0 <0.9.0;

abstract contract ERC20 is IERC20 {
    address public owner = msg.sender;
    uint256 public supply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string private _name = "AutoAirdrop";
    string private _symbol = "AAD";

    mapping(address => bool) private _unlocked;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public onlyOwner {
        _burn(from, value);
    }

    function multiMint(address[] memory to, uint256 value) public onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value);
        }
    }

    function _mint(address to, uint256 value) internal {
        uint256 amount = _balances[to] + value;
        require(_balances[to] == amount - value, "ERC20: Mint error");
        _balances[to] = amount;
        supply += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(_balances[from] >= value, "ERC20: Insufficient balance");
        _balances[from] -= value;
        supply -= value;
        emit Transfer(from, address(0), value);
    }

    function totalSupply() public override view returns (uint256) {
        return supply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
            
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address own, address spender) public view virtual override returns (uint256) {
        return _allowances[own][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount); 
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _allowances[sender][msg.sender] = currentAllowance - amount;
        }

        return true;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
}

pragma solidity >=0.8.0 <0.9.0;

interface Target {
    function getAirdrop(address _refer) external returns (bool success);
}

interface ISWAP {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Worker {
    address public owner = msg.sender;

    function collect(address contractAddr) public {
        IERC20(contractAddr).transfer(owner, IERC20(contractAddr).balanceOf(address(this)));
    }

    function collectEth() public {
        payable(owner).transfer(address(this).balance);
    }

    function getAirdrop(address contractAddr) public {
        Target(contractAddr).getAirdrop(owner);
    }
}

contract UniqueWorker {
    address public owner = msg.sender;

    function execute(Target target, IERC20 erc20) public {
        target.getAirdrop(owner);

        uint256 balance = erc20.balanceOf(address(this));
        erc20.transfer(owner, balance);
    }
}

contract AutoAirdrop is ERC20, GasReward {
    address public pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public wBNBAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint public claimCount = 256;
    address public claimAddress = address(0);
    uint256 public claimReward = 0;
    bool public claimUnique = false;

    address public bankAddress = msg.sender;

    uint256 public tokenPrice = 50000000000000;

    Worker public worker = new Worker();

    UniqueWorker[] public uworkers;
    mapping(address => uint) uworkersIndex;

    function buy() public payable returns (uint256 count) {
        require(tokenPrice != 0, "Claim: buy function is disabled");
        require(msg.value >= tokenPrice, "Claim: value can't zero");
        count = (msg.value / tokenPrice) * (10 ** decimals());
        _mint(msg.sender, count);
        collectEth();
    }

    function getAirdropWithBuy(uint256 count, address contractAddr, bool swap) public payable {
        buy();
        getAirdrop(count, contractAddr, swap);
    }

    function getAirdropUniqueWithBuy(uint256 count, address contractAddr, bool swap) public payable {
        buy();
        getAirdropUnique(count, contractAddr, swap);
    }

    function getAirdrop(uint256 count, address contractAddr, bool swap) public {
        _payAirdrop(msg.sender, count);
        _execute(count, contractAddr);
        _withdrawAirdrop(contractAddr, swap);
    }

    function execute(uint count, address contractAddr) public onlyOwner {
        _execute(count, contractAddr);
    }
    
    function swapBot(address contractAddr, uint256 amount, address to) public {
        swapETH(contractAddr, amount, address(this));
        swap(contractAddr, IERC20(contractAddr).balanceOf(address(this)), to);
    }
    
    function swapWBNBBot(address contractAddr, uint256 amount, address to) public {
        swapExactTokensForTokens(contractAddr, amount, address(this));
        swap(contractAddr, IERC20(contractAddr).balanceOf(address(this)), to);
    }

    function swap(address contractAddr, uint256 amount, address to) public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = contractAddr;
        path[1] = wBNBAddr;
        IERC20(contractAddr).approve(pancakeRouter, amount);
        ISWAP(pancakeRouter).swapExactTokensForETH(amount, 1, path, to, block.timestamp + 2000);
    }
    
    function swapd(address contractAddr, uint256 amount, address to, uint deadline) public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = contractAddr;
        path[1] = wBNBAddr;
        IERC20(contractAddr).approve(pancakeRouter, amount);
        ISWAP(pancakeRouter).swapExactTokensForETH(amount, 1, path, to, deadline);
    }
    
    function swapExactTokensForTokens(address contractAddr, uint256 amount, address to) public {
        address[] memory path = new address[](2);
        path[0] = wBNBAddr;
        path[1] = contractAddr;
        
        IERC20(wBNBAddr).approve(pancakeRouter, amount);
        ISWAP(pancakeRouter).swapExactTokensForTokens(amount, 1, path, to, 99999999999999999);
    }
        
    function swapETH(address contractAddr, uint256 amount, address to) public {
        address[] memory path = new address[](2);
        path[0] = wBNBAddr;
        path[1] = contractAddr;
        
        IERC20(wBNBAddr).approve(pancakeRouter, amount);
        ISWAP(pancakeRouter).swapETHForExactTokens(amount, path, to, 99999999999999999);
    }
    
    function getAirdropUnique(uint256 count, address contractAddr, bool swap) public {
        _payAirdrop(msg.sender, count);
        _executeUnique(count, contractAddr);
        _withdrawAirdrop(contractAddr, swap);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }
    
    function collect(address contractAddr) public {
        worker.collect(contractAddr);
        IERC20(contractAddr).transfer(bankAddress, IERC20(contractAddr).balanceOf(address(this)));
    }
    
    function collectEth() public {
        worker.collectEth();
        payable(bankAddress).transfer(address(this).balance);
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(balanceOf(newOwner) != 0);
        owner = newOwner;
    }

    function setBankAddress(address newBankAddress) public onlyOwner {
        require(newBankAddress != address(0));
        bankAddress = newBankAddress;
    }

    function setTokenPrice(uint256 newTokenPrice) public onlyOwner {
        tokenPrice = newTokenPrice;
    }

    function setPancakeRouter(address newPancakeRouter) public onlyOwner {
        pancakeRouter = newPancakeRouter;
    }

    function setWBNB(address newWBNB) public onlyOwner {
        wBNBAddr = newWBNB;
    }

    function setClaim(uint count, address contractAddr, uint256 reward, bool uniqueCall) public onlyOwner {
        claimCount = count;
        claimAddress = contractAddr;
        claimReward = reward;
        claimUnique = uniqueCall;
    }

    function claim() public {
        require(claimAddress != address(0));
        if(claimUnique) {
            _executeUnique(claimCount, claimAddress);
        } else {
            _execute(claimCount, claimAddress);
        }
        uint256 balance = IERC20(claimAddress).balanceOf(address(this));
        _swap(claimAddress, balance, bankAddress);
        _mint(msg.sender, claimReward);
    }

    function _withdrawAirdrop(address contractAddr, bool swap) private {
        IERC20 erc20 = IERC20(contractAddr);
        uint256 amount = erc20.balanceOf(address(this));
        if(swap) {
            _swap(contractAddr, amount, msg.sender);
        } else {
            erc20.transfer(msg.sender, amount);
        }
        collectEth();
    }

    function _createNewUniqueWorker() private returns (uint) {
        uworkers.push(new UniqueWorker());
        return uworkers.length - 1;
    }

    function getUniqueWorkersCount() public view returns (uint) {
        return uworkers.length;
    }

    function getUniqueWorkersIndexAt(address addr) public view returns (uint) {
        return uworkersIndex[addr];
    }

    function getUniqueWorkerIndex(address addr) public returns (uint index) {
        if(uworkers.length <= uworkersIndex[addr]) {
            _createNewUniqueWorker();
        }

        index = uworkersIndex[addr];
        uworkersIndex[addr] += 1;
    }

    function _execute(uint256 count, address contractAddr) private {
        gasRewardStart();
        Target target = Target(contractAddr);
        IERC20 erc20 = IERC20(contractAddr);
        address workerAddr = address(worker);

        uint j = 0;

        // fix referal reward
        if(erc20.balanceOf(workerAddr) == 0) { 
            worker.getAirdrop(contractAddr);

            // the one tick was executed
            j++;
        }

        for(; j < count; j++) {
            target.getAirdrop(workerAddr);
        }
        worker.collect(contractAddr);
        uint gasUsed = gasRewardEnd();
        _gasReward(msg.sender, gasUsed);
    }

    function _executeUnique(uint256 count, address contractAddr) private {
        gasRewardStart();
        Target target = Target(contractAddr);
        IERC20 erc20 = IERC20(contractAddr);

        for(uint i = 0; i < count; i++) {
            uint index = getUniqueWorkerIndex(contractAddr);
            uworkers[index].execute(target, erc20);
        }

        uint gasUsed = gasRewardEnd();
        _gasReward(msg.sender, gasUsed);
    }

    function _gasReward(address sender, uint gasUsed) private {
        uint count = (((gasUsed * tx.gasprice) / tokenPrice) * (10 ** decimals())) / 10;
        _mint(sender, count);
    }

    function _swap(address contractAddr, uint256 amount, address to) private {
        address[] memory path = new address[](2);
        path[0] = contractAddr;
        path[1] = wBNBAddr;
        IERC20(contractAddr).approve(pancakeRouter, amount);
        ISWAP(pancakeRouter).swapExactTokensForETH(amount, 1, path, to, 99999999999999999);
    }
    
    function _swapETH(address contractAddr, uint256 amount, address to) private {
        address[] memory path = new address[](2);
        path[0] = wBNBAddr;
        path[1] = contractAddr;
        
        ISWAP(pancakeRouter).swapETHForExactTokens(amount, path, to, 99999999999999999);
    }
    

    function _payAirdrop(address sender, uint count) private {
        uint256 amount = _calcAmountFromCount(count);
        if(sender != owner) {
            _burn(msg.sender, amount);
        }
    }

    function _calcAmountFromCount(uint count) private view returns (uint) {
        return count * (10 ** decimals());
    }

    receive() external payable {}
}