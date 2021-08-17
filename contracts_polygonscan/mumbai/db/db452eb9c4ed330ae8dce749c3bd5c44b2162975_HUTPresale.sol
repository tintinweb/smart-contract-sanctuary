/**
 *Submitted for verification at polygonscan.com on 2021-08-17
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


interface IToken  {

    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


contract HUTPresale is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    address public tokenAddress = 0xC1a274546232a8c3c5c2DBe9C0A428fd6Db6d68f;
    uint256 public tokenDecimals = 9;
    
    
    uint256 public tokenRatePerEth = 100;
    uint256 public rateDecimals = 0;
    
    uint256 public minEthLimit = 1e16; // 0.01 BNB
    uint256 public maxEthLimit = 100e18; // 100 BNB
    
    uint256 public totalSupply;
    
    uint256 public soldTokens = 0;
    
    uint256 public intervalDays;
    
    uint256 public endTime = 2 days;
    
    bool public isClaimable = false;
    
    uint256 public poolLength = 0;
    
    mapping(address => uint256) public usersInvestments;
    
    mapping(address => mapping(address => uint256)) public usersCryptos;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(address => uint256) public _pool; 
    
    constructor() public {
        owner = msg.sender;
        _add(0xf351dEC13D2De0EE6d8192b7A56C544eAE5c1eF1,200); //BTC
    }
    
    function startPresale(uint256 numberOfdays) external onlyOwner{
        require(!isPresaleOpen, "Presale is open");
        intervalDays = numberOfdays.mul(1 days);
        endTime = block.timestamp.add(intervalDays);
        isPresaleOpen = true;
        isClaimable = false;
    }
    
    function closePresale() external onlyOwner{
        require(isPresaleOpen, "Presale is not open yet or ended.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        tokenAddress = token;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }
    
    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount;    
    }
    
    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;    
    }
    
    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }
    
    function getUserInvestments(address user) public view returns (uint256){
        return usersInvestments[user];
    }
    
    function getUserClaimbale(address user) public view returns (uint256){
        return balanceOf[user];
    }
    
    function addCrypto(address _crypto, uint256 _tokenRatePerCrypro) public onlyOwner{
        _add(_crypto,_tokenRatePerCrypro);
    }
    
    function _add(address _crypto, uint256 _tokenRatePerCrypro) internal{
        _pool[_crypto] = _tokenRatePerCrypro;
        poolLength = poolLength.add(1);
    }
    
    function _set(address _crypto, uint256 _tokenRatePerCrypro) public onlyOwner{
         _pool[_crypto] = _tokenRatePerCrypro;
    }

    
    
    receive() external payable{
        if(block.timestamp > endTime)
        isPresaleOpen = false;
        
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
        uint256 tokenAmount = getTokensPerEth(msg.value);
        require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) >= tokenAmount ,"No Presale Funds left");
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        
    }
    
    function buyToken(address _crypto,uint256 amount) public{
         if(block.timestamp > endTime)
        isPresaleOpen = false;
        
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersCryptos[msg.sender][_crypto].add(amount) <= maxEthLimit
                &&  usersCryptos[msg.sender][_crypto].add(amount) >= minEthLimit,
                "Installment Invalid."
            );
        require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
        uint256 tokenAmount = getTokenPerCrypto(_crypto,amount);
        require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) >= tokenAmount ,"No Presale Funds left");
        require(IToken(_crypto).transferFrom(msg.sender,address(this), amount),"Insufficient balance from User");
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        usersCryptos[msg.sender][_crypto] = usersCryptos[msg.sender][_crypto].add(amount);
    }
    
    function getTokenPerCrypto(address _crypto,uint256 _amount) public view returns (uint256){
         return _amount.mul(_pool[_crypto]).div(
            10**(uint256(IToken(_crypto).decimals()).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function claimTokens() public{
         require(!isPresaleOpen, "You cannot claim tokens until the presale is closed.");
        require(balanceOf[msg.sender] > 0 , "No Tokens left !");
        require(IToken(tokenAddress).transfer(msg.sender, balanceOf[msg.sender]), "Insufficient balance of presale contract!");
    }
    
    function finalizeSale() public onlyOwner{
       
        isClaimable = !(isClaimable);
    }
    
    function getTokensPerEth(uint256 amount) public view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function withdrawBNB() public onlyOwner{
        require(address(this).balance > 0 , "No Funds Left");
         owner.transfer(address(this).balance);
    }
    
    function withdrawCrypto(address _crypto) public onlyOwner{
         require(IToken(_crypto).transfer(msg.sender, IToken(_crypto).balanceOf(address(this))), "Insufficient balance of presale contract!");
    }
    
    function getUnsoldTokensBalance() public view returns(uint256) {
        return IToken(tokenAddress).balanceOf(address(this));
    }
    
    function getCryptoBalance(address _crypto) public view returns(uint256) {
        return IToken(_crypto).balanceOf(address(this));
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        IToken(tokenAddress).transfer(owner, (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) );
    }
}