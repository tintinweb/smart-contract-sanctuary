//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './IERC20.sol';
import './ERC20.sol';
import './SafeMath.sol';
import './Address.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';

contract ArkyciaToken is ERC20{

    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // token data
    string constant _name = "Arkycia Token";
    string constant _symbol = "ARKY";
    
    // 100 Billion Max Supply
    uint256 _totalSupply = 100 * 10**9 * (10 ** 18);
    uint256 public _maxTxAmount = _totalSupply.div(100); // 1% or 10 Billion
    address public admin;

    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Token Lock Structure
    struct TokenLock {
        bool isLocked;
        //Time when the lock is initialized
        uint256 startTime;
        //Duration of lock
        uint256 duration;
        //No of Tokens that can be used before the lock period is over
        uint256 nTokens;
    }
    //Address that are exempt of tx limit
    mapping(address => bool) _isTxLimitExempt;

    // Token Lockers
    mapping (address => TokenLock) tokenLockers;
    
    //Blacklisted wallets 
    mapping (address => bool) _blacklisted;

    // Pancakeswap V2 Router
    IUniswapV2Router02 router;

    // matic -> storageToken
    address[] buyPath;

    //Price in USD
    uint256 price = 13000000000000000;

    //Price decimal
    uint256 constant priceDecimal = 10**18;
    
    // swapper info
    bool public _manualSwapperDisabled = true;

    //usdc address
    address usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    


    constructor(address _router, address _admin) 
    ERC20(_name, _symbol){
        //Setting admin
        admin = _admin;
        // exempt deployer and contract from max limit
        _isTxLimitExempt[admin] = true;
        _isTxLimitExempt[address(this)] = true;

        //Setting router and  busd address
        router = IUniswapV2Router02(_router);

        //Setting buyPath
        buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = usdc;

        //Minting 100% of total supply to admin
        _balances[admin] = _totalSupply;
        emit Transfer(address(0), admin, _totalSupply, block.timestamp);
    }


    receive() external payable {

        require(!isBlacklisted(msg.sender), "Blacklisted");
        require(!_manualSwapperDisabled, "Swapper is disabled");

        if (msg.sender == address(this)){
                return;
            } 
        uint256 arkyciaTokenOut = getAmountsOut(msg.value);
        require(arkyciaTokenOut > 0, "Must buy atleast 1 token");
        require(arkyciaTokenBalance() >= arkyciaTokenOut, "Insufficient balance of Arkycia in contract");

        bool sent = transferFrom(
            address(this), 
            msg.sender, 
            arkyciaTokenOut
            );
        require(sent, "Failure on purchase");
    }

    //Approving others to spend on our behalf
    function approve(address spender, uint256 amount) 
    public 
    override 
    returns (bool) {
        require(
            balanceOf(msg.sender) >= amount,
            "Balance too low"
        );
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Removes Tokens From Circulation */
    function _burn(uint256 tokenAmount) public returns (bool) {
        if (tokenAmount == 0) {
            return false;
        }
        
        // update balance of contract
        _balances[msg.sender] = _balances[msg.sender]
                                .sub(tokenAmount, "Balance too low");
        // update Total Supply
        _totalSupply = _totalSupply.sub(tokenAmount);
        // emit Transfer to Blockchain
        emit Transfer(msg.sender, address(0), tokenAmount);
        return true;
    }

    
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) 
    public 
    override 
    returns (bool) 
    {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    /** Transfer Function */
    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
        ) public 
        override 
        returns (bool) 
    {
        if(sender == address(this)){
            return _transferFrom(sender, recipient, amount);
        }
        _allowances[sender][msg.sender] = 
                        _allowances[sender][msg.sender]
                            .sub(amount, "Insufficient Allowance");

        return _transferFrom(sender, recipient, amount);
    }

    ////////////////////////////////////
    /////    INTERNAL FUNCTIONS    /////
    ////////////////////////////////////
    
    /** Internal Transfer */
    function _transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
        ) internal 
        returns (bool) 
        {
            // make standard checks
            require(recipient != address(0), "BEP20: Invalid Transfer");
            require(amount > 0, "Zero Amount");
            // check if we have reached the transaction limit
            require(
                amount <= _maxTxAmount || 
                _isTxLimitExempt[sender],
                "TX Limit is breached"
                );
            //Check if the wallet is blacklisted
            require(
                !isBlacklisted(sender) && !isBlacklisted(recipient), 
                "Blacklisted"
                );
            // For Time-Locking Tokens
            if (tokenLockers[sender].isLocked) {
                if (tokenLockers[sender].startTime
                        .add(tokenLockers[sender].duration) > block.timestamp) 
                {
                    tokenLockers[sender].nTokens = tokenLockers[sender].nTokens
                                                    .sub(amount, 'Exceeds Token Lock Allowance');
                } 
                else {
                    delete tokenLockers[sender];
                }
            }
            // subtract balance from sender
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            
            // add amount to recipient
            _balances[recipient] = _balances[recipient].add(amount);
            
            // set shares for distributors 
            emit Transfer(sender, recipient, amount, block.timestamp);
            return true;
    }

   
   
   
   
    ////////////////////////////////////////////////////////
    //////////////////// View Functions ///////////////////
    ///////////////////////////////////////////////////////

    function totalSupply() public view 
    override returns (uint256) { 
        return _totalSupply; 
    }

    function balanceOf(address account) public view 
    override returns (uint256) { 
        return _balances[account]; 
    }

    function allowance(address holder, address spender) public 
    view override returns (uint256) { 
        return _allowances[holder][spender]; 
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function isTxLimitExempt(
        address beneficiary
        ) public 
        view 
        returns(bool){
        return _isTxLimitExempt[beneficiary];
    }

    /** True If Tokens Are Locked For Target, False If Unlocked */
    function isTokenLocked(address target) 
    external 
    view 
    returns 
    (bool) {
        return tokenLockers[target].isLocked;
    }

    /** Time until Tokens Unlock For Target User */    
    function timeLeftUntilTokensUnlock(address target) 
    public 
    view 
    returns (uint256) {
        if (tokenLockers[target].isLocked) {
            uint256 endTime = tokenLockers[target].startTime.add(tokenLockers[target].duration);
            if (endTime <= block.timestamp)
            {
                return 0;
            }   
            return endTime.sub(block.timestamp);
        } else {
            return 0;
        }
    }
    
    /** Number Of Tokens A Locked Wallet Has Left To Spend Before Time Expires */
    function nTokensLeftToSpendForLockedWallet(
        address wallet) 
        external 
        view 
        returns 
        (uint256) {
        return tokenLockers[wallet].nTokens;
    }

    /** Address is blacklisted */
    function isBlacklisted(address wallet) public view returns(bool){
        return _blacklisted[wallet];
    }

    /** Function to view balance of this contract */
    function balanceOfTokens(address token) public view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }

    /** Function to view matic balance of this contract */
    function maticBalance() public view returns (uint256){
        return address(this).balance;
    }

    /** Arkycia Token balance of contract */
    function arkyciaTokenBalance() public view returns(uint256){
        return IERC20(address(this)).balanceOf(address(this));
    }

    /** Get tokens amount out */
    function getAmountsOut(uint256 maticAmt) public view returns(uint256){
        uint256 amountInUSD = router.getAmountsOut(maticAmt, buyPath)[1];
        uint256 arkyciaTokenOut = (amountInUSD.mul(priceDecimal)
                                    .div(price.mul(10**6))).mul(10**18);
        return arkyciaTokenOut;
    }

    //////////////////////////////////////////////////////////
    ///////////////// Admin Functions ////////////////////////
    //////////////////////////////////////////////////////////
    
    //Function to change the admin
    function changeAdmin(address newAdmin) 
    external 
    onlyAdmin{
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminChanged(oldAdmin, newAdmin, block.timestamp);
    }


    //Function to update router address
    function updateRouterAddress(address _router) 
    external 
    onlyAdmin
    returns(bool){
        require(
            _router != address(router) && 
            _router != address(0), 
            'Invalid Address'
            );

        router = IUniswapV2Router02(_router);
        buyPath[0] = router.WETH();
        emit UpdatePancakeswapRouter(_router);
        return true;
    }
    
    /**Change max transaction amount */
    function changeMaxTxLimit(uint256 amount) external onlyAdmin{
        _maxTxAmount = amount; 
    }

    /** Lock Tokens For A User Over A Set Amount of Time */
    function lockTokens(
        address target, 
        uint256 lockDurationInSeconds, 
        uint256 tokenAllowance
        ) 
        external 
        onlyAdmin 
        returns(bool){
            require(
                lockDurationInSeconds <= 31536000, 
                'Duration must be less than or equal to 1 year'
                );
            //86400 seconds = 1 day 
            require(
                timeLeftUntilTokensUnlock(target) <= 86400, 
                'Not Time'
                );
            tokenLockers[target] = TokenLock({
                isLocked: true,
                startTime: block.timestamp,
                duration: lockDurationInSeconds,
                nTokens: tokenAllowance
            });
            emit TokensLockedForWallet(target, lockDurationInSeconds, tokenAllowance);
            return true;
        }


    //Function to exempt an address from tx limit
    function changeTxLimitPermission(address target, bool isExempt) 
    external 
    onlyAdmin{
        _isTxLimitExempt[target] = isExempt;
    }

    function changeUsdcAddress(address _usdc) external onlyAdmin{
        usdc = _usdc;
    }


    /** Function to withdraw tokens from contract */
    function withdrawToken(address token, address to, uint256 amount) 
    public 
    onlyAdmin 
    returns(bool){
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Balance in the contract too low"
            );
        require(to != address(0), "Cannot withdraw to address(0)");
        bool sent = IERC20(token).transfer(to, amount);
        require(sent, "Failure in token transfer");
        emit TokenTransfer(token, amount, to);
        return true;
    }

    /** Function to withdraw Arkycia tokens from contract */
    function withdrawArkyciaToken(address to, uint256 amount) external onlyAdmin returns(bool){
        bool sent = withdrawToken(address(this), to, amount);
        require(sent, "Failure in withdrawl");
        return true;
    }

    /** Function to withdraw Matic from contract */
    function withdrawMatic(address payable to, uint256 amount) external onlyAdmin returns(bool){
        require(address(this).balance >= amount, "Matic balance too low in contract");
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failure on Matic transfer");
        emit MaticTransfer(to, amount);
        return true;
    }

    //Changes maticSwapRatio 
    function changePriceWithEighteenDecimals(uint256 _price) external onlyAdmin{
        price = _price;
    }


    /** Disables or Enables the swapping mechanism inside of Arkycia Tokens */
    function setManualSwapperDisabled(bool manualSwapperDisabled) 
    external 
    onlyAdmin {
        _manualSwapperDisabled = manualSwapperDisabled;
        emit UpdatedManualSwapperDisabled(manualSwapperDisabled);
    }

    /** Function to change blacklist */
    function blacklistWallet(address wallet, bool blacklist) external onlyAdmin{
        _blacklisted[wallet] = blacklist;
    }

    
   //////////////////////////////////////////////////////////
   ///////////////////// Modifiers //////////////////////////
   ///////////////////////////////////////////////////////// 
   
   
    modifier onlyAdmin{
        require(msg.sender == admin, "Only admin");
        _;
    }


    //////////////////////////////////////////////////////////
    /////////////////////// Events ///////////////////////////
    //////////////////////////////////////////////////////////

    event AdminChanged(
        address oldAdmin, 
        address newAdmin, 
        uint256 time
        );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 indexed date
    );

    event StorageTokenChanged(address oldStorageToken, address newStorageToken);

    event TokenTransfer(address indexed token, uint256 amount, address indexed to);

    event MaticTransfer(address recipient, uint256 amount);

    event UpdatedManualSwapperDisabled(bool manualSwapperDisabled);

    event UpdatePancakeswapRouter(address router);

    event TokensLockedForWallet(
        address indexed target, 
        uint256 lockDurationInSeconds, 
        uint256 tokenAllowance
        );

}