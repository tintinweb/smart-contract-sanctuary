// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AggregatorV3Interface.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract BTIG is IERC20 {

    address admin;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 _decimal;

    constructor() {
        _name = "BTIG_Token";
        _symbol = "BTIG";
        _decimal = 0;
        _mint(address(this), 1000000000);
        admin = msg.sender; //deployer
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _changeAdmin(address _newaddr) internal onlyAdmin {
        admin = _newaddr;
    }
    modifier onlyAdmin {
        require( msg.sender == admin, " Only Admin");
        _;
    }

    function newOwner(address _newOwner) public onlyAdmin {
        _changeAdmin(_newOwner);
    }
    function mint(address _account, uint256 _qty) public onlyAdmin{
        _mint(_account, _qty);
    }
    function burn(address _account, uint256 _qty) public onlyAdmin {
        _burn(_account, _qty);
    }
    function bulkTransfer(address[] memory _recipient, uint256[] memory _amount) public {
        require(_recipient.length == _amount.length, "Different array length");
        for(uint i=0;i<_recipient.length;i++) {
            transfer(_recipient[i], _amount[i]);
        }
    }
}

contract AirdropBTIG is BTIG {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: Oil/USD
     * Address: 0x48c9FF5bFD7D12e3C511022A6E54fB1c5b8DC3Ea
     */

     // The token being sold
     //BTIG private token;

    // User registration
     uint256 public openingTime;
     uint256 public closingTime;

     constructor (/*BTIG _token*/) {
        
        (admin) = payable(msg.sender);
       // token = BTIG(_token);
        openingTime = 1;
        closingTime = 1672531198;   // 31st Dec 2022 2359hrs GMT
        isOpen = true;
        rate = 4000; // divide by 10 power 18
        priceFeed = AggregatorV3Interface(0x48c9FF5bFD7D12e3C511022A6E54fB1c5b8DC3Ea);

     }
         
     modifier onlyWhileOpen {
      require(block.timestamp >= openingTime && block.timestamp <= closingTime);
      _;
     }
     modifier onlyOwner{
      require (msg.sender == admin, "Only Admin");
      _;
     }
     function changeTimes(uint256 _openingTime, uint256 _closingTime) external onlyOwner {
        require( _openingTime<_closingTime, "Opening time must be lower than closing time");
        openingTime = _openingTime;
        closingTime = _closingTime;
     }
     
     bool public isOpen;
     function openClose() external onlyOwner {
         if( isOpen) {
             isOpen = false;
         } else {
             isOpen = true;
         }
     }
     
     uint256 tokenAmount;
     function setTokenAmount(uint256 _tokenamount) external onlyOwner {
         tokenAmount = _tokenamount;
     }
     
     mapping (address => uint256) registration;
     uint256 public count;
     event Register(address indexed User, uint256 Time);
     
     function register() external {
        require(registration[msg.sender]==0, "User already registered");
        require(isOpen, "Airdrop registration not yet open");
        count++;
        registration[msg.sender] = count;  
        emit Register(msg.sender, block.timestamp);
     }
     
     uint256 public indexClaimed;
     mapping (address => uint256) claimed;
     event Claimed(address indexed User, uint256 Time);

     function claimAirdrop() external payable onlyWhileOpen returns(bool success) {
         require(claimed[msg.sender]==0,"Already claimed tokens");
         _mint( msg.sender, tokenAmount);    
         indexClaimed++;
         claimed[msg.sender] = indexClaimed;
         emit Claimed(msg.sender, block.timestamp);
         return true;
     }
    
    /**
     *CROWSALE. 
     */

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser,uint256 value,uint256 amount);

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    fallback () external payable {
    }
    receive () external payable {
    }
    
    // This function could be set using an oracle
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    function checkRate() external returns(uint){
        //require( _rate<0, "Rate must be greater than Zero");
        uint rates = uint(getLatestPrice());
        rate = rates;
        return rates;
    }
    function viewRate() external view returns(uint){
        return rate;
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
    }

    /**
    if I want to issue "1 TKN for every Dollar (USD) in Ether", we would calculate it as follows:

    assume 1 ETH == USD 4,000

    therefore, 10^18 wei = USD 4,000

    therefore, 1 USD is 10^18 / 4000 , or 25 * 10^13 wei

    we have a decimals of 0, so we’ll use 10 ^ 0 TKNbits instead of 1 TKN

    therefore, if the participant sends the crowdsale 25 * 10^13 wei we should give them 10 ^ 0 TKNbits

    therefore the rate is 25 * 10^13 wei === 10^0 TKNbits, or 1 wei = 4000 * 10^-18 TKNbits

    therefore, our rate is 4000 * 10^-18
    
    */

    // Mint new token for buyers
    function buyTokens() public payable {
    
        uint256 weiAmount = msg.value;
        _preValidatePurchase(weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        
        // update state
        weiRaised += (weiAmount);
        _processPurchase( tokens);
        emit TokenPurchase(msg.sender,weiAmount,tokens);

        _updatePurchasingState(weiAmount);
        _forwardFunds();
        _postValidatePurchase( weiAmount);
    }

    uint256 public taxRate;    // 10x Percentage, If taxRate is 0.1%, input as 1
    function changeTaxRate(uint256 _taxIn10xOfPercentage) external onlyOwner{
        taxRate = _taxIn10xOfPercentage;
    }

    function sellTokens(uint256 tokens) public payable {
        require(balanceOf(msg.sender)>=tokens, "Not enough balance to sell");
        
        _burn(msg.sender, tokens);
        // Calculate weiAmount to be paid
        uint256 weiAmount = tokens*10**18*(1000-taxRate)/(rate*1000);
        require(address(this).balance >= weiAmount, "Not enough ETH in contract");
        payable(msg.sender).transfer(weiAmount);
    }

    function seeBalances()public returns(uint256, uint256) {
        uint x = balanceOf(msg.sender);
        uint y = (msg.sender).balance; 
        return (x,y);
    }
    // 1 eth = 4000 tokens, buy.
    // x tokens sell will get me x/4000eth, 
    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(uint256 _weiAmount)internal view onlyWhileOpen {
        require(_weiAmount != 0);
    }

    /**
    * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _postValidatePurchase(uint256 _weiAmount)internal{
        // optional override
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(uint256 _tokenAmount)internal{
        _mint(msg.sender, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(uint256 _tokenAmount)internal{
        _deliverTokens( _tokenAmount);
    }

    /**
    * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _updatePurchasingState(uint256 _weiAmount)internal {
        // optional override
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount)internal view returns (uint256){
            return _weiAmount*(rate)/(10**18);
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        payable(address(this)).transfer(msg.value);
    }  
    function viewContractBal() public view returns(uint256 balanceWEI, uint256 balanceBTIG) {
        return (address(this).balance, balanceOf(address(this)));
    }
    function withdrawFunds(uint256 _amount) public payable onlyOwner {
        uint256 bal = address(this).balance;
        require( _amount <= bal, "Not enough funds to withdraw");
        payable(admin).transfer(_amount);
    }
    function withdrawAllFunds() public payable onlyOwner {
        uint256 _amount =address(this).balance;
        payable(admin).transfer(_amount);
    }

}