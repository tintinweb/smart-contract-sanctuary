pragma solidity ^0.4.22;

contract Utils {
    /**
        constructor
    */
    function Utils() internal {
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


/*
    Owned contract interface
*/
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract YooStop is Owned{

    bool public stopped = true;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public ownerOnly{
        stopped = true;
    }
    function start() public ownerOnly{
        stopped = false;
    }

}


contract YoobaICO is  Owned,YooStop,Utils {
    IERC20Token public yoobaTokenAddress;
    uint256 public startICOTime = 0;  
    uint256 public endICOTime = 0;  
    uint256 public leftICOTokens = 0;
    uint256 public tatalEthFromBuyer = 0;
    uint256 public daysnumber = 0;
    mapping (address => uint256) public pendingBalanceMap;
    mapping (address => uint256) public totalBuyMap;
    mapping (address => uint256) public totalBuyerETHMap;
    mapping (uint256 => uint256) public daySellMap;
    mapping (address => uint256) public withdrawYOOMap;
    uint256 internal milestone1 = 4000000000000000000000000000;
    uint256 internal milestone2 = 2500000000000000000000000000;
       uint256 internal dayLimit = 300000000000000000000000000;
    bool internal hasInitLeftICOTokens = false;



    /**
        @dev constructor
        
    */
    function YoobaICO(IERC20Token _yoobaTokenAddress) public{
         yoobaTokenAddress = _yoobaTokenAddress;
    }
    

    function startICO(uint256 _startICOTime,uint256 _endICOTime) public ownerOnly {
        startICOTime = _startICOTime;
        endICOTime = _endICOTime;
    }
    
    function initLeftICOTokens() public ownerOnly{
        require(!hasInitLeftICOTokens);
       leftICOTokens = yoobaTokenAddress.balanceOf(this);
       hasInitLeftICOTokens = true;
    }
    function setLeftICOTokens(uint256 left) public ownerOnly {
        leftICOTokens = left;
    }
    function setDaySellAmount(uint256 _dayNum,uint256 _sellAmount) public ownerOnly {
        daySellMap[_dayNum] = _sellAmount;
    }
    
    function withdrawTo(address _to, uint256 _amount) public ownerOnly notThis(_to)
    {   
        require(_amount <= this.balance);
        _to.transfer(_amount); // send the amount to the target account
    }
    
    function withdrawERC20TokenTo(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));

    }
    
    function withdrawToBuyer(IERC20Token _token,address[] _to)  public ownerOnly {
        require(_to.length > 0  && _to.length < 10000);
        for(uint16 i = 0; i < _to.length ;i++){
            if(pendingBalanceMap[_to[i]] > 0){
                assert(_token.transfer(_to[i],pendingBalanceMap[_to[i]])); 
                withdrawYOOMap[_to[i]] = safeAdd(withdrawYOOMap[_to[i]],pendingBalanceMap[_to[i]]);
                pendingBalanceMap[_to[i]] = 0;
            }
         
        }
    }
    
      function withdrawToBuyer(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
        withdrawYOOMap[_to] = safeAdd(withdrawYOOMap[_to],_amount);
        pendingBalanceMap[_to] = safeSub(pendingBalanceMap[_to],_amount);

    }
    
    function refund(address[] _to) public ownerOnly{
        require(_to.length > 0  && _to.length < 10000 );
        for(uint16 i = 0; i < _to.length ;i++){
            if(pendingBalanceMap[_to[i]] > 0 && withdrawYOOMap[_to[i]] == 0 && totalBuyerETHMap[_to[i]] > 0 && totalBuyMap[_to[i]] > 0){
                 if(totalBuyerETHMap[_to[i]] <= this.balance){
                _to[i].transfer(totalBuyerETHMap[_to[i]]); 
                tatalEthFromBuyer = tatalEthFromBuyer - totalBuyerETHMap[_to[i]];
                leftICOTokens = leftICOTokens + pendingBalanceMap[_to[i]];
                totalBuyerETHMap[_to[i]] = 0;
                pendingBalanceMap[_to[i]] = 0; 
                totalBuyMap[_to[i]] = 0;
              
                 }
            }
         
        }
    }
  
    function buyToken() internal
    {
        require(!stopped && now >= startICOTime && now <= endICOTime );
        require(msg.value >= 0.1 ether && msg.value <= 100 ether);
        
        uint256  dayNum = ((now - startICOTime) / 1 days) + 1;
        daysnumber = dayNum;
         assert(daySellMap[dayNum] <= dayLimit);
         uint256 amount = 0;
        if(now < (startICOTime + 1 weeks) && leftICOTokens > milestone1){
               
                if(msg.value * 320000 <= (leftICOTokens - milestone1))
                { 
                     amount = msg.value * 320000;
                }else{
                   uint256 priceOneEther1 =  (leftICOTokens - milestone1)/320000;
                     amount = (msg.value - priceOneEther1) * 250000 + priceOneEther1 * 320000;
                }
        }else{
           if(leftICOTokens > milestone2){
                if(msg.value * 250000 <= (leftICOTokens - milestone2))
                {
                   amount = msg.value * 250000;
                }else{
                   uint256 priceOneEther2 =  (leftICOTokens - milestone2)/250000;
                   amount = (msg.value - priceOneEther2) * 180000 + priceOneEther2 * 250000;
                }
            }else{
               assert(msg.value * 180000 <= leftICOTokens);
            if((leftICOTokens - msg.value * 180000) < 18000 && msg.value * 180000 <= 100 * 180000 * (10 ** 18)){
                  amount = leftICOTokens;
            }else{
                 amount = msg.value * 180000;
            }
            }
        }
           if(amount >= 18000 * (10 ** 18) && amount <= 320000 * 100 * (10 ** 18)){
              leftICOTokens = safeSub(leftICOTokens,amount);
              pendingBalanceMap[msg.sender] = safeAdd(pendingBalanceMap[msg.sender], amount);
              totalBuyMap[msg.sender] = safeAdd(totalBuyMap[msg.sender], amount);
              daySellMap[dayNum] += amount;
              totalBuyerETHMap[msg.sender] = safeAdd(totalBuyerETHMap[msg.sender],msg.value);
              tatalEthFromBuyer += msg.value;
              return;
          }else{
               revert();
          }
    }

    function() public payable stoppable {
        buyToken();
    }
}