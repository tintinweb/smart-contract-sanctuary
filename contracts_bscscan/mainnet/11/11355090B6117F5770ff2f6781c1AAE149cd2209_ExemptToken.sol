//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
import "./SafeMath.sol";
import "./XBridgeManager.sol";
import "./IXSurge.sol";
import "./ReentrantGuard.sol";
import "./FeeManager.sol";

/**
 * Contract: xSurge
 * Developed By: Markymark (SafemoonMark)
 *
 * Tax Exempt Token that is Pegged 1:1 to a Native Asset
 * To Be Transfered Tax Free, Exclude This Contract From Fees
 */
contract ExemptToken is ReentrancyGuard, IXSurge {

    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // Surge Contract Address
    address public nativeToken;
    // Contract To Burn Fees
    address public feeBurner;
    // Contract Verifier
    XBridgeManager public manager = XBridgeManager(0xCd9F362a8f239c3812a5d321Ad697ba98CA453d5);
    // Fee Manager
    FeeManager feeManager = FeeManager(0xD55bE063ffbD824488556B59c2d9700F3E3aE47f);
    // owner
    address _owner;
    modifier onlyOwner() {require(msg.sender == _owner, 'OnlyOwner Function'); _;}
    
    /** Ensures only the Contract Creator Contract can call certain functions */
    modifier fromVerifiedBridge() {
        require(manager.isXBridge(msg.sender), 'Only PersonalBridges Can Call This Function!!!');
        _;
    }

    // Fee for transfering native token
    uint256 public nativeTransferFee;
    
    // token data
    string _name = "xETHVault";
    string _symbol = "xETHVAULT";
    uint8 constant _decimals = 0;
    // 0 Total Supply
    uint256 _totalSupply = 0;
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Create xToken
    constructor ( address _nativeToken, string memory tName, string memory tSymbol, uint256 _nativetransferFee, address _feeBurner
    ) {
        _name = tName;
        _symbol = tSymbol;
        nativeToken = _nativeToken;
        nativeTransferFee = _nativetransferFee;
        feeBurner = _feeBurner;
        _owner = msg.sender;
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
        uint256 nativeTokenBal = IERC20(nativeToken).balanceOf(address(this));

        if (_totalSupply >= nativeTokenBal) return nativeTokenBal;
        
        // has Native been sent to xToken by mistake
        uint256 dif = nativeTokenBal.sub(_totalSupply);
        // if so burn native
        if (dif > 0) {
            IERC20(nativeToken).transfer(feeManager.getLiquidityProvider(), dif);
        }
        return _totalSupply;
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
        bool success = IERC20(nativeToken).transfer(destroyer, amountToBurn);
        // check if transfer succeeded
        require(success, 'NativeToken Transfer Failed');
        // enforce 1:1
        require(_totalSupply <= IERC20(nativeToken).balanceOf(address(this)), 'This tx would break the 1:1 ratio');
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
        require(_totalSupply <= IERC20(nativeToken).balanceOf(address(this)), 'This Transaction Would Break the 1:1 Ratio');
        // tell the blockchain
        emit Transfer(address(this), receiver, amountToSend);
        emit Transfer(address(this), liquidityProvider, taxAmount);
    }

    /** Returns the amount of Native Surge in this contract */
    function getNativeBalanceInContract() public view returns(uint256) {
        return IERC20(nativeToken).balanceOf(address(this));
    }

    /** Withdraw Tokens that are not native token that were mistakingly sent to this address */
    function withdrawTheMistakesOfOthers(address tokenAddress, uint256 nTokens) external onlyOwner {
        require(tokenAddress != nativeToken, 'CANNOT WITHDRAW NATIVE TOKENS');
        require(nTokens <= IERC20(tokenAddress).balanceOf(address(this)), 'Does not own this many tokens');
        IERC20(tokenAddress).transfer(msg.sender, nTokens);
        emit WithdrawTheMistakesOfOthers(tokenAddress, nTokens);
    }

    /** Withdraw BNB that was mistakingly sent to this address */
    function withdrawBNB(uint256 amount, address recipient) external nonReentrant onlyOwner {
        require(amount <= address(this).balance, 'Cannot withdraw more BNB than is owned');
        (bool success, ) = payable(recipient).call{ value: amount, gas: 26000 }("");
        require(success, 'unable to withdraw BNB');
        emit WithdrawTheMistakesOfOthersBNB(amount);
    }

    /** Incase Pancakeswap Upgrades To V3 */
    function changeFeeBurnerAddress(address newFeeBurner) external onlyOwner {
        feeBurner = newFeeBurner;
        emit UpdatedFeeBurner(newFeeBurner);
    }

    /** Transfers Ownership To New Address */
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
        emit TransferedOwnership(newOwner);
    }

    /** Updates the Native Transfer Fee */
    function updateNativeTransferFee(uint256 newFee) external onlyOwner {
        nativeTransferFee = newFee;
        emit UpdatedNativeTransferFee(newFee);
    }

    /** Caulcates Bridge Fee For Native Token */
    function calculateBridgeFee(uint256 amount) public view returns (uint256) {
        return feeManager.calculateTokenFeeAmount(nativeToken, amount);
    }
    
    /** Liquidity Provider */
    function getLiquidityProvider() public view returns (address) {
        address provider = feeManager.getLiquidityProvider();
        return provider == address(0) ? feeBurner : provider;
    }

    /** Returns the Native Surge Token */
    function getNativeAddress() public override view returns(address) {
        return nativeToken;
    }

    // EVENTS
    event UpdatedLiquidityProvider(address newProvider);
    event UpdatedFeeBurner(address newFeeBurner);
    event UpdatedPancakeswapRouter(address newRouter);
    event WithdrawTheMistakesOfOthers(address token, uint256 tokenAmount);
    event WithdrawTheMistakesOfOthersBNB(uint256 bnbAmount);
    event TransferedOwnership(address newOwner);
    event UpdatedNativeTransferFee(uint256 newFee);

}