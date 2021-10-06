/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface interfaceVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external  returns (uint256);

    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)  external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
   }

interface interfacePool {
    // stake funds
    function stake(uint256 amount) external;
    //Unstake funds
    function withdraw(uint256 amount) external;
    //Rewards
    function getReward() external;
    function exit() external;  //exit from pool and withdraw all along with this, get rewards
    //the rewards should be first transferred to this pool, then get "notified" by calling `notifyRewardAmount`
    function notifyRewardAmount(uint256 reward) external;
    function migrate() external;
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function balanceOfUnderlying(address account) external returns (uint);

    function exchangeRateCurrent() external returns (uint);
}


interface IOracle{
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

interface ComptrollerInterface {
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function isComptroller() external view returns (bool);

    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function claimComp(address holder) external;
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}



interface CEth {
    function mint() external payable;

    function balanceOf(address owner) external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function balanceOfUnderlying(address account) external returns (uint);

    function exchangeRateCurrent() external returns (uint);
}

contract poc is ERC20 {
    //mapping(address=>uint) userDeposits;
    CEth ceth;
    CErc20 cUSDC;
    IERC20 usdc; 
    IOracle oracle;
    ComptrollerInterface CompTroller;
    interfacePool pool;
    uint index = 1;
    address comp;
    IERC20 farm;
    IERC20 fUSDC = IERC20(0xa453A6753C8dA302CdcD81b25574E98e4b76E797);
    interfaceVault vault;
    uint min_depo = 1000000;
    struct harvestSnapshot{
        uint priceEth;
        uint lendingAmt;
        uint yieldAmt;
        uint supplyEth;
        uint blockNo;
        uint tLTV;
        uint rFactor;
        uint exchangeRate;
        uint totalBorrows;
        mapping(address => uint) userCSupply;
        mapping(address => uint) userBorrow; // scaled by 10**12 foor usdc/dai
        //mapping(address => uint) uLTV;
    }
    struct data{
        uint uptillHarvest;
        uint positionLender;
        uint positionYield;
    }
    mapping(address => data) public userData;
    harvestSnapshot[] public harvestData;
    constructor(address _ceth, address _oracle, address compt,address _cusdc,
                address _usdc,address _comp,address _harvest,address _pool,address _FARM) ERC20("MTFi","MTFI"){
        ceth = CEth(_ceth);
        oracle = IOracle(_oracle);
        CompTroller = ComptrollerInterface(compt);
        //CompTroller2 = ComptrollerInterface(compt2);
        address[] memory any = new address[](2);
        any[0] = _ceth;
        any[1] = _cusdc;
        cUSDC = CErc20(_cusdc);
        usdc = IERC20(_usdc);
        CompTroller.enterMarkets(any);
        harvestData.push();
        index = 0;
        comp = _comp;
        vault = interfaceVault(_harvest);
        pool = interfacePool(_pool);
        farm = IERC20(_FARM);
    }
    //receive () external payable {
    //    _deposit(msg.sender,msg.value);
   // }

    function deposit() public payable{
        _commitUser(msg.sender,index);
        _deposit(msg.sender, msg.value);
    }

    function _deposit(address account,uint amount) internal {
        ceth.mint{value:amount}();
        _mint(account,ceth.balanceOf(address(this))-totalSupply());
        harvestData[index].userCSupply[account] += ceth.balanceOf(address(this))-totalSupply(); 
    }
    function withdraw(uint cAmount)public{
        _commitUser(msg.sender,index);
        _burn(msg.sender, cAmount);
        ceth.redeem(cAmount);
        payable(msg.sender).transfer(address(this).balance);
        harvestData[index].userCSupply[msg.sender] -= cAmount;
    }

    function harvestwithPool()public {
        uint temp = IERC20(comp).balanceOf(address(this));
        CompTroller.claimComp(address(this));
        uint temp2 = farm.balanceOf(address(this));
        pool.getReward();
        capture(IERC20(comp).balanceOf(address(this))-temp,farm.balanceOf(address(this))-temp2);
    }
    
    function harvest()public {
        uint temp = IERC20(comp).balanceOf(address(this));
        CompTroller.claimComp(address(this));
        //uint temp2 = farm.balanceOf(address(this));
        //pool.getReward();
        capture(IERC20(comp).balanceOf(address(this))-temp,0);
    }
    function capture(uint comprewards,uint farmrewards) public{
        harvestData[index].priceEth = oracle.getUnderlyingPrice(address(cUSDC))/oracle.getUnderlyingPrice(address(ceth));
        harvestData[index].lendingAmt = comprewards;
        harvestData[index].yieldAmt = farmrewards;
        harvestData[index].supplyEth = ceth.balanceOfUnderlying(address(this));
        harvestData[index].blockNo = block.timestamp;
        harvestData[index].tLTV = 9000;
        harvestData[index].rFactor = 100;
        harvestData[index].exchangeRate = ceth.exchangeRateCurrent();
        index++;    // userSupply + LTV
        harvestData.push();
    }
    function claimUser() external{
        _commitUser(msg.sender,index);
    }

    function commitUsers(address[] memory users,uint tillHarvest) external {
        for(uint i = 0;i<users.length;i++){
            _commitUser(users[i], tillHarvest);
        }
        //rewards
    }

    function _commitUser(address user,uint tillH) internal{
        if(userData[user].uptillHarvest>tillH){
        uint dLender;
        uint dYield;
        
        for(uint i = userData[user].uptillHarvest;i<=tillH;i++){
            dLender +=  (harvestData[index].lendingAmt*(harvestData[i].userCSupply[user]*harvestData[i].exchangeRate))/harvestData[index].supplyEth; //scaling lef
            //uint factor = harvestData[index].priceEth*10**18/harvestData[i].exchangeRate; //scaled
            uint denom = harvestData[i].supplyEth*harvestData[i].tLTV-harvestData[index].totalBorrows*harvestData[i].priceEth;
            dYield += harvestData[index].yieldAmt*((harvestData[i].userCSupply[user]*harvestData[i].exchangeRate)*harvestData[i].tLTV*harvestData[i].userBorrow[user]*harvestData[i].priceEth)/denom;
            harvestData[i].userCSupply[user] = harvestData[i-1].userCSupply[user];
            harvestData[i].userBorrow[user] = harvestData[i-1].userBorrow[user];
        }
        userData[user].uptillHarvest = tillH;
        userData[user].positionLender = dLender;
        }
    }

    function borrow(uint amount) external{
        _commitUser(msg.sender,index);
        //checkborrow
        _borrow(msg.sender,amount);
    }

    function _borrow(address user,uint amount) internal returns(uint){ //input int 10^18
        (uint error,uint liquidity,uint shortfall)=CompTroller.getAccountLiquidity(address(this));
        require(error==0,'Error');
        require(shortfall==0,'nonHealthy LTV');
        require(liquidity>0,'No Liquidity available');
        uint price = oracle.getUnderlyingPrice(address(cUSDC));
        require((liquidity*10**30/price)>=amount,'Not Sufficient Liquidity');
        uint res = cUSDC.borrow(amount/10**12);
        usdc.transfer(user, amount/10**12);
        harvestData[index].userBorrow[user] +=amount;
        harvestData[index].totalBorrows += amount;
        return res;
    }

    function takeLoan(uint amountOut) external payable returns (uint){
        _commitUser(msg.sender,index);
        _deposit(msg.sender, msg.value);
        //userCheckBorrow
        return _borrow(msg.sender, amountOut);
    }

    function rebalance() external {
        uint bal = usdc.balanceOf(address(this));
        (uint error,uint liquidity,uint shortfall)=CompTroller.getAccountLiquidity(address(this));
        if(liquidity>0&&error==0&&shortfall==0){
        uint price = oracle.getUnderlyingPrice(address(cUSDC));
        uint borrowamt = (liquidity*10**18)/price;
        cUSDC.borrow(borrowamt*80/100);
        bal+=borrowamt*80/100;
        //require((liquidity*10**30/price)>=amount,'Not Sufficient Liquidity');
        }
        require(bal>min_depo,'Need more amount to rebalance');
        //require(bal>min_depo,"balance<min_deposit_amount");
        usdc.approve(address(vault), 0);
        usdc.approve(address(vault), bal);
        vault.deposit(bal);
        //_stake(fUSDC.balanceOf(address(this)));
        
    }
    function _stake() external{
        uint amt = fUSDC.balanceOf(address(this));
        fUSDC.approve(address(pool), 0);
        fUSDC.approve(address(pool), amt);
        pool.stake(amt);
    }
    function review() external view returns(uint) {
        uint bal = usdc.balanceOf(address(this));
        (uint error,uint liquidity,uint shortfall)=CompTroller.getAccountLiquidity(address(this));
        //check =error;
        if(liquidity>0&&error==0&&shortfall==0){
        uint price = oracle.getUnderlyingPrice(address(cUSDC));
        uint borrowamt = (liquidity*10**18)/price;
        //cUSDC.borrow(borrowamt);
        bal+=borrowamt;
        //require((liquidity*10**30/price)>=amount,'Not Sufficient Liquidity');
        }
        return bal;
    }
    function repay(uint amount) public returns(uint){
        return cUSDC.repayBorrow(amount);
    }
    function repayHarvest(uint amount) public{
        uint amountf = (amount * fUSDC.totalSupply())/vault.underlyingBalanceWithInvestment();
        pool.withdraw(amountf);
        fUSDC.approve(address(vault), 0);
        fUSDC.approve(address(vault), amountf);
        vault.withdraw(amountf);
        repay(amount);
    }
}