//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
import "./SafeMath.sol";
import "./XBridgeManager.sol";
import "./IUniswapV2Router02.sol";
import "./IXSurge.sol";
import "./ReentrantGuard.sol";
import "./Ownable.sol";
import "./FeeManager.sol";


/**
 * Contract: Surge Token
 * Developed By: Markymark (SafemoonMark)
 *
 * Tax Exempt Token that is Pegged 1:1 to a Native Asset
 * To Be Transfered Tax Free, Exclude This Contract From Fees
 *
 */
contract ExemptSurge is Ownable, ReentrancyGuard, IXSurge {

    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // Surge Contract Address
    address public nativeSurge;
    // Contract To Burn Fees
    address public feeBurner;
    // Contract Verifier
    XBridgeManager public manager = XBridgeManager(0x9Ae1630066DF94b27f3281Ad080f360aa6BDCc21);
    // Fee Manager
    FeeManager feeManager = FeeManager(0xD55bE063ffbD824488556B59c2d9700F3E3aE47f);

    /** Ensures only the Contract Creator Contract can call certain functions */
    modifier fromVerifiedBridge() {
        require(manager.isXBridge(msg.sender), 'Only PersonalBridges Can Call This Function!!!');
        _;
    }
    // Fee for transfering native token
    uint256 public nativeTransferFee;

    // Address for Pancakeswap Router V2
    IUniswapV2Router02 router;

    // token data
    string _name = "xSurge";
    string _symbol = "XSURGE";
    uint8 constant _decimals = 0;
    // 0 Total Supply
    uint256 _totalSupply = 0;
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Create xSurge initialize stuff
    constructor ( address _nativeSurge, string memory tName, string memory tSymbol, uint256 _nativetransferFee, address _feeBurner
    ) {
        _name = tName;
        _symbol = tSymbol;
        nativeSurge = _nativeSurge;
        nativeTransferFee = _nativetransferFee;
        feeBurner = _feeBurner;
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }
    // basic IERC20 Functions
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Approves Router For Total Supply For Contract */
    function internalApproval() internal {
        _allowances[address(this)][address(router)] = _totalSupply;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        // take a 0.1% tax
        uint256 tax = amount.div(1000);
        // add to Fee Burner
        _balances[feeBurner] = _balances[feeBurner].add(tax);
        // receiver gets amount sub tax
        amount = amount.sub(tax);
        // give amount to receiver
        _balances[recipient] = _balances[recipient].add(amount);
        // Transfer Event
        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, feeBurner, tax);
        return true;
    }

    /** Creates xSurge Tokens based on how many it has received */
    function mintXToken(address receiver, uint256 numXSurge) external fromVerifiedBridge override returns(bool) {
        // liquidity provider
        address liquidityProvider = getLiquidityProvider();
        // amount of tokens to mint after native transfer fee
        uint256 tokensToMint = numXSurge.mul(nativeTransferFee).div(10**2);
        // mint tokens to receiver
        _mint(receiver, tokensToMint, liquidityProvider);
        return true;
    }
    
    /** Enforces the 1:1 ratio of Tokens -> xTokens*/
    function enforceOneToOne() private returns(uint256){
        
        // check balance of Native
        uint256 nativeSurgeBal = IERC20(nativeSurge).balanceOf(address(this));

        if (_totalSupply > nativeSurgeBal) return nativeSurgeBal;
        
        // has Native been sent to xToken by mistake
        uint256 dif = nativeSurgeBal.sub(_totalSupply);
        // if so burn native
        if (dif > 0) {
            IERC20(nativeSurge).transfer(nativeSurge, dif);
            return _totalSupply;
        } else {
            return nativeSurgeBal;
        }
    }

    /** Destroys xSurge Tokens based on how many it is sending back */
    function redeemNative(address destroyer, uint256 amount) external fromVerifiedBridge override returns(bool) {
        // Enforce 1:1 and retrieve balance
        uint256 nativeSurgeBal = enforceOneToOne();
        // make sure we have enough native surge to transfer
        require(nativeSurgeBal >= amount, 'Cannot Destroy More xSurge than Surge that is owned');
        // liquidity provider
        address liquidityProvider = getLiquidityProvider();
        // allocate bridge fee to go toward dynamic liquidity
        uint256 taxAmount = calculateBridgeFee(amount);
        // how much should we send without the tax
        uint256 amountToBurn = amount.sub(taxAmount);
        // subtract full amount from sender
        _balances[destroyer] = _balances[destroyer].sub(amount, 'sender does not have this amount to sell');
        // add xSurge to dynamic liquidity receiver
        _balances[liquidityProvider] = _balances[liquidityProvider].add(taxAmount);
        // if successful, remove tokens from supply
        _totalSupply = _totalSupply.sub(amountToBurn, 'total supply cannot be negative');
        // transfer SURGE from this contract to destroyer
        bool success = IERC20(nativeSurge).transfer(destroyer, amountToBurn);
        // check if transfer succeeded
        require(success, 'NativeSurge Transfer Failed');
        // enforce 1:1
        require(_totalSupply <= IERC20(nativeSurge).balanceOf(address(this)), 'This tx would break the 1:1 ratio');
        // approve the new total supply
        internalApproval();
        // Transfer from seller to address
        emit Transfer(destroyer, address(this), amount);
        emit Transfer(address(this), liquidityProvider, taxAmount);
        return true;
    }

    /** Mints Tokens to the Receivers Address */
    function _mint(address receiver, uint amount, address liquidityProvider) private {
        // allocate bridge fee to go toward dynamic liquidity
        uint256 taxAmount = calculateBridgeFee(amount);
        // how much should we send without the tax
        uint256 amountToSend = amount.sub(taxAmount);
        // add xSurge to receiver's wallet
        _balances[receiver] = _balances[receiver].add(amountToSend);
        // add tax to the Liquidity Provider
        _balances[liquidityProvider] = _balances[liquidityProvider].add(taxAmount);
        // Increase total supply
        _totalSupply = _totalSupply.add(amount);
        // make sure this won't break the 1:1
        require(_totalSupply <= IERC20(nativeSurge).balanceOf(address(this)), 'This Transaction Would Break the 1:1 Ratio');
        // approve the new total supply
        internalApproval();
        // tell the blockchain
        emit Transfer(address(this), receiver, amountToSend);
        emit Transfer(address(this), liquidityProvider, taxAmount);
    }

    /** Returns the amount of Native Surge in this contract */
    function getSurgeBalanceInContract() public view returns(uint256) {
        return IERC20(nativeSurge).balanceOf(address(this));
    }

    /** Withdraw Tokens that are not native token that were mistakingly sent to this address */
    function withdrawTheMistakesOfOthers(address tokenAddress, address recipient, uint256 nTokens) public onlyOwner {
        require(tokenAddress != nativeSurge, 'CANNOT WITHDRAW SURGE TOKENS');
        require(nTokens <= IERC20(tokenAddress).balanceOf(address(this)), 'Does not own this many tokens');
        IERC20(tokenAddress).transfer(recipient, nTokens);
        emit WithdrawTheMistakesOfOthers(tokenAddress, nTokens);
    }

    /** Withdraw BNB that was mistakingly sent to this address */
    function withdrawBNB(uint256 amount, address recipient) public nonReentrant onlyOwner {
        require(amount <= address(this).balance, 'Cannot withdraw more BNB than is owned');
        (bool success, ) = payable(recipient).call{ value: amount, gas: 26000 }("");
        require(success, 'unable to withdraw BNB');
        emit WithdrawTheMistakesOfOthers(router.WETH(), amount);
    }

    /** Incase Pancakeswap Upgrades To V3 */
    function changePancakeswapRouterAddress(address newPCSAddress) public onlyOwner {
        router = IUniswapV2Router02(newPCSAddress);
        emit UpdatedPancakeswapRouter(newPCSAddress);
    }

    /** Caulcates Bridge Fee For Native Token */
    function calculateBridgeFee(uint256 amount) public view returns (uint256) {
        return feeManager.calculateTokenFeeAmount(nativeSurge, amount);
    }
    
    function getLiquidityProvider() public view returns (address) {
        address provider = feeManager.getLiquidityProvider();
        return provider == address(0) ? feeBurner : provider;
    }

    /** Returns the Native Surge Token */
    function getNativeAddress() external override view returns(address) {
        return nativeSurge;
    }

    // EVENTS
    event UpdatedLiquidityProvider(address newProvider);
    event UpdatedPancakeswapRouter(address newRouter);
    event WithdrawTheMistakesOfOthers(address token, uint256 tokenAmount);
}