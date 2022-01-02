/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT


library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

}



struct Token {
    uint8 level;
    uint32 id;
    address payable owner;
}

struct Account {
    uint80 amount;
    uint8 withdrawn;
}

contract StakingWhale  {
    
    using SafeMath for uint80;

    address public owner;
    address payable reserveAddress;
    uint80 public treasury;
    uint80 public reserve;
    uint32 public poolIndex;
    uint8 public maxLevel;
    uint8 public zeroLevels;
    Token[] public tokens;
    uint80[] public levels;
    mapping(address=>Account) accounts;
    bool internal locked;

    event NewToken(uint32 index);
    event Bought(uint32 id, uint8 level);
    
    constructor(uint80[] memory _levels, uint8[] memory _tokenLevels, address payable _reserveAddress) {
        
        /* setup price levels */
        for (uint8 i=0; i<_levels.length; i++) {
            levels.push(_levels[i] * 1 gwei);
        }
        

        /* admin stuff */
        owner = msg.sender;
        address payable contractAddress = payable(address(this));
        reserveAddress = _reserveAddress;
        accounts[contractAddress] = Account(0, 0);

        /* initial tokens and max/zero levels cnt */
        uint8 _ml = 0;
        uint8 _zl = 0;
        for (uint8 i=0; i<_tokenLevels.length; i++) {
            uint8 _tokenLevel = _tokenLevels[i];
            if(_tokenLevel > _ml)
                _ml = _tokenLevel;

            if(_tokenLevel == 0)
                _zl++;
        
            tokens.push(Token(_tokenLevel, i, contractAddress));
        }
        maxLevel = _ml;
        poolIndex = 32767;
        zeroLevels = _zl;
        

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
    
    function buy(uint80 _idx) external payable {
        
        Token storage token = tokens[_idx];
        Token memory _token = token;
        require(_token.owner != address(0), 'Token for this index not found');
        require(_token.owner != msg.sender, "Can't buy your own token");

        /* checks */
        uint80 _amount = uint80(msg.value);
        uint80 _tokenPrice = levels[_token.level];
        require(_tokenPrice <=_amount, 'Insufficient amount');

        uint80 _salesTax;
        if(_token.level > 0) {
            /* calculate 5% sales tax */
            _salesTax = _tokenPrice * 5 / 100;

            /* credit previous owner, deduct withdrawal tax */
            Account storage ownerAccount = accounts[_token.owner];
            ownerAccount.amount = uint80(ownerAccount.amount.add(_tokenPrice - _salesTax));
        } else {
            /* sales tax is entire amount */
            _salesTax = _amount;
        }

        /* credit treasury (pool) */
        uint80 _treasuryPart = _salesTax / 100 * 80;
        treasury += _treasuryPart;
        reserve += _salesTax - _treasuryPart;

        /* update levels */
        if (_token.level == 0)
            zeroLevels--;

        uint8 _maxLevel = maxLevel;
       
        /* incentived token regularly bought, take incentive over  */
        if (_token.level > 0 && _maxLevel == token.level && poolIndex == 32767) {            
            poolIndex = _token.id;
        } 

         if(_maxLevel == _token.level) {
            maxLevel = _token.level + 1;
        }

        /* promote token and change owner */        
        token.level = _token.level + 1;
        token.owner = payable(msg.sender);

        emit Bought(_token.id, _token.level);
        
    }

    /* uses incentive to pay for selling the token */
    function sellToPool() external {

        require(poolIndex != 32767, "No token to sell");
        Token storage token = tokens[poolIndex];
        Token memory _token = token;

        require(_token.owner != address(0), "Token for this index not found");
        require(_token.level > 0, "Can't sell a basic level token to the pool");

        /* get the sell and buy price of the token */
        uint80 _tokenSellPrice = levels[_token.level];

        /* deduct 5% sales tax and credit the seller */        
        Account storage ownerAccount = accounts[_token.owner];
        ownerAccount.amount += _tokenSellPrice * 95 / 100;
    
        
        /* debit the treasury (pool) by token profit only, because the buy price is returned to the seller anyway
           21% profit of buy price minus 5% tax on sales price is net 14.95% profit  */        
        uint80 _tokenBuyPrice = levels[_token.level - 1];
        treasury = uint80(treasury.sub(_tokenBuyPrice * 1495 / 10000, "Not enough funds to sell token"));
        
        
        /* credit user account with price paid and profit earned */
        token.owner = payable(address(this));
        
        //token.level = 0;
        //zeroLevels++;

        poolIndex = 32767;

        
    }

    /* uses incentive to pay for selling the token */
    function cancelTrade(uint80 _idx) external {

        Token storage token = tokens[_idx];
        Token memory _token = token;
        require(_token.owner == msg.sender, "Not your token");
        require(_token.level > 0, "Token with lowest price can't be cancelled");
        
        /* get buy price */
        uint80 _tokenBuyPrice = levels[_token.level-1];

        /* refund price is buying price minus 5% tax */
        uint80 _tax = _tokenBuyPrice * 5 / 100;
        uint80 _refundPrice =  _tokenBuyPrice - _tax;

        Account storage ownerAccount = accounts[_token.owner];
        ownerAccount.amount = uint80(ownerAccount.amount.add(_refundPrice));

        /* credit treasury (pool) */
        treasury += _tax;

        token.level = 0;
        token.owner = payable(address(this));
        
         if (_token.id == poolIndex) {
            poolIndex = 32767;
        }
        zeroLevels++;

        /*
        if(_token.level >= maxLevel)
            setMaxLevel();
        */

    }


    function withdrawAccountFunds(uint80 _amount) public noReentrant {

        Account storage _senderAccount = accounts[msg.sender];
        require(_senderAccount.amount >= _amount, "Not enough funds");        
        _senderAccount.amount -= _amount;
        (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
        require(sent, "Withdrawal failed");
    }

    function getAccountBalance(address _account) view public returns (uint80){
        return accounts[_account].amount;
    }

    function getAllTokens() view public returns (Token[] memory) {
        return tokens;
    }

    function getAllLevels() view public returns (uint80[] memory) {
        return levels;   
    }

    
    /* admin methods */

    function addToken() external {

        if (zeroLevels <= 0) {
            tokens.push(Token(0, uint32(tokens.length), payable(address(this))));        
            zeroLevels = 1;
            emit NewToken(uint32(tokens.length));   
        }
    }

    function addLevel(uint80 price) external onlyOwner {
        levels.push(price * 1 gwei);        
    }
    
    fallback() external payable {

        (bool sent, bytes memory data) = msg.sender.call{value: msg.value}("");
        require(sent, "Return failed");
    }

    function withdrawReserve(uint80 _amount) public onlyOwner {

        reserve = uint80(reserve.sub(_amount, "Not enough funds to withdraw"));
        (bool sent, bytes memory data) = reserveAddress.call{value: _amount}("");
        require(sent, "Withdrawal failed");        
    }
    
    function addTreasury() public payable onlyOwner {
        treasury = uint80(treasury.add(msg.value));
    }

    function getContractBalance() view public returns (uint256){
        return address(this).balance;
    }


    function setMaxLevel() public {

        Token[] memory _tokens = tokens;
        uint8 _maxLevel = 0;

        /* setup price levels */
        for (uint32 i=0; i<_tokens.length; i++) {
            uint8 _level = _tokens[i].level;
            if (_level > _maxLevel)
                _maxLevel = _level;
        }
        maxLevel = _maxLevel;
        
    }
}