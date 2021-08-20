// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SwapInterfaces.sol";
import "./ReentrancyGuard.sol";
import "./MinorityShared.sol";


/**
 * NB: This contract MUST be exempted from any token transfer fees, else claiming tokens will fail for some users
 */
contract MinorityPresale is Context, ReentrancyGuard, Ownable, MinorityShared {
    using SafeMath for uint256;
    
    // Address with privileges to modify an existing presale;
    address public operator;

    // The token being sold
    IERC20 public token;
    // The token used to buy token
    IERC20 public paymentToken;

    // Address where funds are sent if the presale is unsuccessful
    address public wallet;

    // How many token units a buyer gets per wei (defined in this instance as the smallest unit of payment token).
    // The rate is the conversion between wei and the smallest token unit.
    // So, if you are using a rate of 1 with a token with 3 decimals called TOK 1 wei will give you 1 unit, or 0.001 TOK.
    // Setting the number of decimals of token to match paymentToken will give an easy rate calculation.
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;
    uint256 public contributionsToClaim;
    
    // Total cap of the presale - should be the same as number of tokens available for presale divided by the rate - this will be checked once users start depositing funds
    uint256 public hardcap;
    // Minimum goal that should be reached by closing time for the presale to be successful
    uint256 public softcap;
    // Cap per inidividual
    uint256 public individualCap;
    // Track individual contributions to ensure they're below the cap
    mapping(address => uint256) private contributions;
    
    uint256 public openingTime;
    uint256 public closingTime;
    
    uint256 public numTokensToAddToLP;
    uint256 public percentFundsToAddToLP;
    
    bool public finalised;
    bool public cancelled;

    ISwapRouter02 public immutable swapRouter;

    event TokensPurchased(address indexed purchaser, uint256 amountPaid, uint256 tokensReserved);
    event PresaleTimesChanged (uint256 oldOpeningTime, uint256 newOpeningTime, uint256 oldClosingTime, uint256 newClosingTime);
    event PresaleExtended (uint256 oldClosingTime, uint256 newClosingTime);
    event PresaleFinalised();
    event LiquidityAdded (uint256 expectedTokensAdded, uint256 actualTokensAdded, uint256 expectedPaymentTokensAdded, uint256 actualPaymentTokensAdded, uint256 liquidityCreated);
    
    modifier onlyWhileOpen {
        require(isOpen(), "MinorityPresale: not open");
        _;
    }
    
    modifier onlyOwnerOrOperator {
        require(msg.sender == operator || msg.sender == owner(), "MinorityPresale: only accessible by operator or owner");
        _;
    }

    // solhint-disable-next-line
    constructor (address _operator) {
        require (_operator != address(0), "MinorityPresale: Operator can't be the zero address");
        swapRouter = ISwapRouter02 (ROUTER);
        operator = _operator;
    }
    
    function setUpPresale (
        uint256 _rate, 
        address _wallet, 
        address _token, 
        uint256 _hardcap, 
        uint256 _softcap, 
        uint256 _individualCap, 
        address _paymentToken, 
        uint256 _openingTime, 
        uint256 _closingTime, 
        uint256 _numTokensToAddToLP, 
        uint256 _percentFundsToAddToLP) 
        external 
        onlyOwnerOrOperator 
    {
        setUpPresale (_rate, _wallet, _token, _hardcap, _softcap, _individualCap, _paymentToken, _openingTime, _closingTime, _numTokensToAddToLP, _percentFundsToAddToLP, true);
    }
    
    function setUpPresale (
        uint256 _rate, 
        address _wallet, 
        address _token, 
        uint256 _hardcap, 
        uint256 _softcap, 
        uint256 _individualCap, 
        address _paymentToken, 
        uint256 _openingTime, 
        uint256 _closingTime, 
        uint256 _numTokensToAddToLP, 
        uint256 _percentFundsToAddToLP,
        bool doSafetyCheck) 
        public 
        onlyOwner 
    {
        // solhint-disable-next-line not-rely-on-time
        require (openingTime == 0 || block.timestamp <= openingTime.sub(1 days), "MinorityPresale: Can't modify < 1 day before opening"); 
        require (!cancelled, "MinorityPresale: Can't re-use a cancelled presale contract"); 
        require (_rate > 0, "MinorityPresale: rate can't be 0");
        require (_wallet != address(0), "MinorityPresale: wallet can't be the zero address");
        require (_token != address(0), "MinorityPresale: token can't be the zero address");
        require (_paymentToken != address(0), "MinorityPresale: payment token can't be the zero address");
        require (_hardcap > 0, "MinorityPresale: hardcap can't be 0");
        require (_softcap > 0, "MinorityPresale: softcap can't be 0");
        require (_softcap < _hardcap, "MinorityPresale: softcap must be < hardcap");
        require (_individualCap > 0, "MinorityPresale: individual cap can't be 0");
        require (_openingTime >= block.timestamp, "MinorityPresale: opening time can't be in the past"); // solhint-disable-line not-rely-on-time
        require (_closingTime > _openingTime, "MinorityPresale: closing time can't be before opening time");
        require (_numTokensToAddToLP > 0, "MinorityPresale: must add > 0 tokens to LP");
        require (_percentFundsToAddToLP >= 70 && _percentFundsToAddToLP <= 100, "MinorityPresale: must add >= 70% and <= 100% of raised funds to LP");
    
        // Gets round the issues with atomicity when constructing the contract. Subsequent calls will be affected by this check (means token constructor needs to be carefully checked)
        if (doSafetyCheck) {
            require (IERC20(_token).balanceOf(address(this)) >= _hardcap.mul(_rate).add(_numTokensToAddToLP), 
                "MinorityPresale: Not enough tokens owned to complete presale. Deposit tokens before calling this function");
        }

        rate = _rate; // mapping of smallest possible payment token amount to smallest possible token amount. If the number of decimals are equal then the number of tokens per paymentToken
        wallet = _wallet; // address where funds will be paid to one the presale is complete
        token = IERC20(_token); // token to be sold
        paymentToken = IERC20(_paymentToken); // token to take payment in
        hardcap = _hardcap; // maximum amount of paymentToken that can be received by the contract
        softcap = _softcap; // minimum amount of paymentToken that needs to be received by the contract before the closing time for the presale to be successful
        individualCap = _individualCap; // maximum amount of payment token any individual address can send to the contract
        openingTime = _openingTime; // opening time of the presale in unix epoch time
        closingTime = _closingTime; // closing time of the presale in unix epoch time
        numTokensToAddToLP = _numTokensToAddToLP; // number of tokens to pair with earned funds and to add to LP
        percentFundsToAddToLP = _percentFundsToAddToLP; // percent of raised funds to add to LP
    }
    
    function cancelPresale() external onlyOwnerOrOperator {
        require (!finalised, "MinorityPresale: already finalised"); // If it's finalised then the payment token has already been used
        
        if ((isOpen() || hasClosed()) && weiRaised > 0) 
            cancelled = true; // if we've already received payment then we need to officially cancel so refunds can be claimed. Cancelled presale contracts can't be re-used.
        
        rate = 0; 
        wallet = address(0); 
        hardcap = 0; 
        softcap = 0; 
        individualCap = 0; 
        openingTime = 0;
        closingTime = 0;
        numTokensToAddToLP = 0; 
        percentFundsToAddToLP = 0; 
        forwardAllTokens();
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    receive() external payable {
        require (paymentInWeth(), "MinorityPresale: Can't buy by sending funds to this address");
        buyTokens (msg.value);
    }
    
    function paymentInWeth() public view returns (bool) {
        return (address(paymentToken) == swapRouter.WETH());
    }

    // Returns the amount contributed so far by a specific beneficiary.
    function getContribution(address beneficiary) public view returns (uint256) {
        return contributions[beneficiary];
    }
    

    // Checks whether the hardcap has been reached.
    function hardcapReached() public view returns (bool) {
        return weiRaised >= hardcap;
    }
    

    // Checks whether the softcap has been reached.
    function softcapReached() public view returns (bool) {
        return weiRaised >= softcap;
    }
    
    // Checks if the presale is open
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    // Checks whether the period in which the presale is open has already elapsed.
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return (block.timestamp > closingTime && closingTime != 0);
    }
    
    // Extends the closing time of the sale
    function extendTime (uint256 newClosingTime) external onlyOwnerOrOperator {
        require (!hasClosed(), "MinorityPresale: already closed");
        require (newClosingTime > closingTime, "MinorityPresale: new closing time is before current closing time");

        emit PresaleExtended (closingTime, newClosingTime);
        closingTime = newClosingTime;
    }
    
    function changePresaleTimings (uint256 newOpeningTime, uint256 newClosingTime) external onlyOwnerOrOperator {
        require (!hasClosed(), "MinorityPresale: already closed");
        require (!isOpen(), "MinorityPresale: already open, use extendTime to change the closing time");
        
        emit PresaleTimesChanged (openingTime, newOpeningTime, closingTime, newClosingTime);
        openingTime = newOpeningTime;
        closingTime = newClosingTime;
    }
    
     // Called once the presale ends - can be called by anyone
    function finalise() public {
        require (!finalised, "MinorityPresale: already finalised");
        require (hasClosed() || hardcapReached(), "MinorityPresale: not closed");
        
        contributionsToClaim = weiRaised.mul(rate);
        finalised = true;
        emit PresaleFinalised();
        
        if (hardcapReached() || softcapReached()){
            addLiquidity();
            
            if (percentFundsToAddToLP < 100)
                forwardFunds();
            
            if (!hardcapReached())
                forwardRemainingTokens();
        } else if (!softcapReached()) {
            forwardAllTokens();
        }
    }
    
    function addLiquidity() internal {
        // add percentage of tokens based on the amount raised. If hardcap met all tokens provided will be added
        uint256 tokenAmount = numTokensToAddToLP.mul(weiRaised).div(hardcap);
        // Approve transfer of token and paymentToken to router
        token.approve(address(swapRouter), tokenAmount);
        paymentToken.approve(address(swapRouter), weiRaised);

        // add the liquidity
        (uint256 tokenFromLiquidity, uint256 paymentTokenFromLiquidity, uint256 liquidityAmount) = swapRouter.addLiquidity(
            address(token),
            address(paymentToken),
            tokenAmount,
            weiRaised,
            0, // shouldn't suffer slippage as there should be no existing liquidity. We allow for slippage anyway so this doesn't fail if the LP exists
            0, // shouldn't suffer slippage as there should be no existing liquidity. We allow for slippage anyway so this doesn't fail if the LP exists
            wallet, 
            block.timestamp  // solhint-disable-line not-rely-on-time
        );
        
        emit LiquidityAdded (tokenAmount, tokenFromLiquidity, weiRaised, paymentTokenFromLiquidity, liquidityAmount);
    }


    // Buy tokens - if the payment is not in WETH spender needs to have approved the transfer of weiAmount of tokens to the presale contract prior to calling this function
    // Deals correctl with payment tokens that have transfer taxes - users should be aware the amount they receive will be affected by this
    function buyTokens (uint256 weiAmount) public nonReentrant payable {
        address beneficiary = _msgSender();
        uint256 paymentTransferred = preValidatePurchase (beneficiary, weiAmount);
        require (paymentTransferred > 0, "MinorityPresale: issue collecting payment");
        
        // calculate token amount to be created
        uint256 tokens = getTokenAmount (paymentTransferred);

        // update state
        weiRaised = weiRaised.add(paymentTransferred);
        contributions[beneficiary] = contributions[beneficiary].add(paymentTransferred);
        emit TokensPurchased (beneficiary, paymentTransferred, tokens);

        if (hardcapReached())
            finalise();
    }
    
    // Collects payment if not in WETH and handles tokens with transfer taxes
    function collectPayment (address beneficiary, uint256 weiAmount) private returns (uint256) {
        if (paymentInWeth())
            return weiAmount;
        else {
            uint256 initialBalance = paymentToken.balanceOf (address(this));
            paymentToken.transferFrom (beneficiary, address(this), weiAmount);
            return paymentToken.balanceOf(address(this)).sub(initialBalance);
        }
    }

    // Check the validity of receiving payment at this time - if valid then take payment (if required)
    function preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen returns (uint256) {
        require (beneficiary != address(0), "MinorityPresale: beneficiary is the zero address");
        require (weiAmount != 0, "MinorityPresale: 0 payment specified");
        require (weiRaised.add(weiAmount) <= hardcap, "MinorityPresale: hardcap would be exceeded with this purchase amount");
        require (contributions[beneficiary].add(weiAmount) <= individualCap, "MinorityPresale: individual cap exceeded");
        return collectPayment (beneficiary, weiAmount);
    }
    
    
    // Allows tokens to be withdrawn after the presale finishes, assuming the softcap has been met
    function claimTokens() public {
        require (finalised, "MinorityPresale: not finalised, call finalise before claiming tokens");
        require (softcapReached(), "MinorityPresale: Softcap not met, claim a refund of your payment");
        address beneficiary = msg.sender;
        uint256 tokenAmount = getTokenAmount (contributions[beneficiary]);
        require (tokenAmount > 0, "MinorityPresale: no tokens claimable for this address");
        contributions[beneficiary] = 0;
        contributionsToClaim = contributionsToClaim.sub(tokenAmount);
        require (token.transfer(beneficiary, tokenAmount), "MinorityPresale: issue with transferring tokens");
    }
    
    
    // Used to claim a refund if the presale is unsuccessful
    // Users should be aware that if the payment token has transfer taxes they will receive less than they sent by 2 x the transfer tax
    function claimRefund() public {
        require (finalised || cancelled, "MinorityPresale: not finalised or cancelled, try calling finalise before claiming refund");
        require (!softcapReached(), "MinorityPresale: softcap reached, refunds can't be claimed unless the presale is cancelled");
        address beneficiary = msg.sender;
        
        if (paymentInWeth())
            _msgSender().transfer (contributions[beneficiary]);
        else
            paymentToken.transfer (beneficiary, contributions[beneficiary]);
    }

    // Get the number of tokens given an amount of payment token
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate);
    }

    // Sends collected funds to wallet if presale is successful
    function forwardFunds () internal {
        uint256 fundsToForward = weiRaised.sub(weiRaised.mul(percentFundsToAddToLP).div(100));
        
        if (paymentInWeth())
            payable(wallet).transfer(fundsToForward);
        else
            paymentToken.transfer (wallet, fundsToForward);
    }
    
    // Returns unused tokens to the wallet if presale does not meet hardcap
    function forwardRemainingTokens() internal {
        uint256 tokensToReturnFromSaleAllocation = hardcap.sub(weiRaised).mul(rate);
        uint256 tokensToReturnFromLPAllocation = numTokensToAddToLP.sub(numTokensToAddToLP.mul(weiRaised).div(hardcap));
        token.transfer (wallet, tokensToReturnFromSaleAllocation.add(tokensToReturnFromLPAllocation));
    }
    
    // Returns all tokens to the wallet if the presale doesn't meet the softcap
    function forwardAllTokens() internal {
        uint256 tokensToReturn = token.balanceOf(address(this));
        token.transfer (wallet, tokensToReturn);
    }
}