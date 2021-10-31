/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-11
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract bSHIBA_INU is IERC20, Ownable {

    string private constant _name = "bShiba INU";
    string private constant _symbol = "bShiba";
    uint8 private constant _decimals = 9 ;
    uint256 private _totalSupply = 0;
    uint256 private constant MAX_SUPPLY = 50000000 * 10**9;
    uint256 private constant MAX_BURN =    MAX_SUPPLY * 25 / 100;
    uint256 public constant Minter_Tokens =  MAX_SUPPLY * 25 / 100;
    uint256 constant public AIRDROP_TOKENS = MAX_SUPPLY * 5 / 100;
    uint private mintableTokens = MAX_SUPPLY - MAX_BURN - Minter_Tokens ;
    uint256 public totalAirdropTokens;
    uint256 public totalMintersTokens;
    uint256 private total_burned_tokens ;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private allowed;
    struct userfrozentokenInfo
    {
        uint256 _frozenbalances;
        uint _frozentimeout;
    }
    mapping(address => userfrozentokenInfo) public userInfo ;

    //uint256 private maxRestrictionAmount = 300 * 10**6 * 10**9;
    mapping (address => bool) private isWhitelisted;
    mapping (address => uint256) private lastTx;
    address public saleaddress;

    struct mintersInfo
    {
      //address minter;
      uint256 _frozenbalances;
      uint _frozentimeout;
    }
    address[] public minterusers ;
     mapping(address => mintersInfo) public minterInfo ;

    // end restrictions

    using SafeMath for uint256;

    enum StateBot {
        Locked,
        Restricted, // Bot protection for liquidity pool
        Unlocked
    }
    StateBot public state;

    constructor() {
        state = StateBot.Locked;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    receive() external payable {}
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
	    return _totalSupply;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return _balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override launchRestrict(msg.sender, receiver, numTokens) returns (bool) {
        require(numTokens > 0, "Transfer amount must be greater than zero");
        require(numTokens <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(numTokens);
        _balances[receiver] = _balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        _burn(receiver,numTokens.div(100));
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address receiver, uint256 numTokens) public override launchRestrict(owner, receiver, numTokens) returns (bool) {
        require(numTokens <= _balances[owner]);

        _balances[owner] = _balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        _balances[receiver] = _balances[receiver].add(numTokens);
        emit Transfer(owner, receiver, numTokens);
       
        _burn(receiver,numTokens.div(100));
        return true;
    }

   
    modifier ownerOrPresale {
       require(owner() == msg.sender || saleaddress == msg.sender, "Cannot burn tokens");
       _;
   }

    function burn(uint256 numTokens) ownerOrPresale public returns(bool) {

        _burn(msg.sender,numTokens);
        return true;
    }
    function _burn(address _from,uint256 numTokens) internal
    {
      require(numTokens <= _balances[_from],'Insufficient token balance to burn.');
      if(total_burned_tokens + numTokens < MAX_BURN)
      {
        _balances[_from] = _balances[_from].sub(numTokens);
        _totalSupply = _totalSupply.sub(numTokens);
        emit Transfer(_from, address(0), numTokens);
        total_burned_tokens = total_burned_tokens.add(numTokens);
      }
    }

    // Security from bots

    // enable/disable works only once, token never returns to Locked
    function setBotProtection(bool enable) public onlyOwner() {
        if (enable && state == StateBot.Locked) state = StateBot.Restricted;
        if (!enable) state = StateBot.Unlocked;
    }

    ///function setRestrictionAmount(uint256 amount) public onlyOwner() {
      //  maxRestrictionAmount = amount;
    //}
    function setSaleAddress(address saleaddress_) public onlyOwner() {
        saleaddress = saleaddress_;
    }

    function whitelistAccount(address account) public onlyOwner() {
        isWhitelisted[account] = true;
    }

    modifier launchRestrict(address sender, address recipient, uint256 amount) {
        if (state == StateBot.Locked) {
            require(sender == owner() || isWhitelisted[sender], "Tokens are locked");
        }
        if (state == StateBot.Restricted) {
            //require(amount <= maxRestrictionAmount, "bSHIBA_INU: amount greater than max limit in restricted mode");
            if (!isWhitelisted[sender] && !isWhitelisted[recipient]) {
                require(lastTx[sender].add(60) <= block.timestamp && lastTx[recipient].add(60) <= block.timestamp, "bSHIBA_INU: only one tx/min in restricted mode");
                lastTx[sender] = block.timestamp;
                lastTx[recipient] = block.timestamp;
            } else if (!isWhitelisted[recipient]) {
                require(lastTx[recipient].add(60) <= block.timestamp, "bSHIBA_INU: only one tx/min in restricted mode");
                lastTx[recipient] = block.timestamp;
            } else if (!isWhitelisted[sender]) {
                require(lastTx[sender].add(60) <= block.timestamp, "bSHIBA_INU: only one tx/min in restricted mode");
                lastTx[sender] = block.timestamp;
            }
        }
        _;
    }
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public onlyOwner returns(bool) {
      require(!isContract(msg.sender),  'No contract address allowed');
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          if(totalAirdropTokens + tokenAmount[i] <= AIRDROP_TOKENS){
            setuserinfo(recipients[i],tokenAmount[i],1200); //6 months
            totalAirdropTokens += tokenAmount[i];
          }
        }
        return true;
    }
    function mint(address _to, uint256 _amount) ownerOrPresale public returns (bool)
    {
      require((mintableTokens - _amount) > 0,'Mint limit has been reached');
      _mint(_to,_amount);
      return true;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "bSHIBA_INU: mint to the zero address");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function setminters(address[] memory _minters) onlyOwner public returns (bool)
    {
      require(_minters.length==5,"Set 5 minters");
      for(uint i=0;i<5;i++)
      {
          //minterInfo.push(mintersInfo(_minters[i],0,0));
          minterusers.push(_minters[i]);
          //minterInfo[_minters[i]]= mintersInfo(0,0);
      }
      return true;
    }
    function sendTokensToMinters() public onlyOwner returns(bool) {
      require(!isContract(msg.sender),  'No contract address allowed');
      uint256 tokenAmount = Minter_Tokens/5;
        for(uint i = 0; i < 5 ; i++)
        {
          if(totalMintersTokens + tokenAmount <= Minter_Tokens){

            if(minterInfo[minterusers[i]]._frozenbalances==0)
            {
              minterInfo[minterusers[i]]._frozentimeout = block.timestamp.add(1800) ;//6 months
            }
            minterInfo[minterusers[i]]._frozenbalances = minterInfo[minterusers[i]]._frozenbalances.add(tokenAmount);
            totalMintersTokens += tokenAmount;
          }
        }
        return true;
    }
    function setuserinfo(address _user,uint256 _amount,uint duration) public ownerOrPresale returns(bool)
    {
        if(userInfo[_user]._frozenbalances==0)
            {
              userInfo[_user]._frozentimeout = block.timestamp.add(duration) ; //6 months
            }
        userInfo[_user]._frozenbalances = userInfo[_user]._frozenbalances.add(_amount);
        return true;
    }
    function claimable(address _user) public view returns (uint256){
        if(userInfo[_user]._frozenbalances>0 && userInfo[_user]._frozentimeout <= block.timestamp)
        {
            return userInfo[_user]._frozenbalances;
        }
        else if(minterInfo[_user]._frozenbalances>0 && minterInfo[_user]._frozentimeout <= block.timestamp)
        {
           return  minterInfo[_user]._frozenbalances;
        }
        return 0;
    }
    event ClaimToken(address indexed _user,uint256 _amount);
    function Claim(uint256 _amount) external returns(bool)
    {
        require(userInfo[msg.sender]._frozenbalances > _amount ,"Not enough amount to claim");
        require(userInfo[msg.sender]._frozentimeout <= block.timestamp,'Your frozen duration has not been end');
        userInfo[msg.sender]._frozenbalances = userInfo[msg.sender]._frozenbalances.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        emit ClaimToken(msg.sender, _amount);
        return true;
    }
    event ClaimMinterToken(address indexed _user,uint256 _amount);
    function ClaimMinter(uint256 _amount) external returns(bool)
    {
        
        require(minterInfo[msg.sender]._frozenbalances >_amount  ,"Not enough amount to claim");
        require(minterInfo[msg.sender]._frozentimeout <= block.timestamp,'Your frozen duration has not been end');
        minterInfo[msg.sender]._frozenbalances = minterInfo[msg.sender]._frozenbalances.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        emit ClaimMinterToken(msg.sender, _amount);
        return true;
    }
     // Owner can drain tokens that are sent here by mistake
    function drainToken(uint256 _amount, address _to) external onlyOwner {
        transfer(_to, _amount);
    }
     // Owner can drain tokens that are sent here by mistake
    function drainBalamce(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}
contract bSHIBA_INU_SALE is Ownable {
    using SafeMath for uint256;
    uint256 private constant MAX_SUPPLY = 50000000 * 10**9;
    uint public Saledelay = 300;//1 days;

    uint256 constant public COMMSALE_PRICE = 0.000006 ether;
    uint256 constant public COMMSALE_TOKENS = MAX_SUPPLY * 5 / 100;
    uint256 constant public COMMSALE_DURATION = 600;//30 days;
    uint256 constant public COMMSALE_MIN_BUY = 0.000006 ether; //$500
    uint256 constant public COMMSALE_MAX_BUY = 10.29 ether;  //$100000


    uint256 constant public PRESALE_PRICE = 0.00008 ether ;
    uint256 constant public PRESALE_TOKENS = MAX_SUPPLY * 2 / 100;
    uint256 constant public PRESALE_DURATION =  600;//30 days;

    uint256 constant public PRIVATESALE_PRICE = 0.00012 ether ;
    uint256 constant public PRIVATESALE_TOKENS = MAX_SUPPLY * 3 / 100;
    uint256 constant public PRIVATESALE_DURATION = 600;// 30 days;

    uint256 constant public PUBLICSALE_PRICE = 0.00018 ether ;
    uint256 constant public PUBLICSALE_TOKENS = MAX_SUPPLY * 5 / 100;
    uint256 constant public PUBLICSALE_DURATION = 600;// 30 days;


    bSHIBA_INU public token;
    address payable public benificiary;
    uint256 public startTime;

    // Sales
    mapping (address => uint256) public salesAtCommsale;
    mapping (address => uint256) public salesAtPresale;
    mapping (address => uint256) public salesAtPrivatesale;
    mapping (address => uint256) public salesAtPublicsale;



    uint256 public totalCommTokensSold;
    uint256 public totalCommBnbCollected;

    uint256 public totalPresaleTokensSold;
    uint256 public totalPresaleBnbCollected;

    uint256 public totalPrivatesaleTokensSold;
    uint256 public totalPrivatesaleBnbCollected;

    uint256 public totalPublicsaleTokensSold;
    uint256 public totalPublicsaleBnbCollected;

    enum State {
        Pending,
        CommSale,
        Presale,
        PrivateSale,
        PublicSale,
        CommSaleCompleted,
        PresaleCompleted,
        PrivateSaleCompleted,
        Completed
    }
    constructor( address payable token_, address payable beneficiary_) {
       token = bSHIBA_INU(token_);
       benificiary = beneficiary_;
   }

    function setStartTime(uint256 time) public onlyOwner() {
      require(startTime==0,'Sale already started');
        startTime = time;
    }

    receive() external payable {
        buyTokens(address(0));
    }

    function getState() public view returns(State) {
        if (block.timestamp < startTime) return State.Pending;
        else if (block.timestamp >= startTime &&
                block.timestamp < startTime + COMMSALE_DURATION) {
            if (totalCommTokensSold * 100 >= 99 * COMMSALE_TOKENS) return State.CommSaleCompleted;
            else return State.CommSale;
        }
        else if (block.timestamp >= startTime + COMMSALE_DURATION + Saledelay &&
                block.timestamp < startTime + COMMSALE_DURATION + Saledelay + PRESALE_DURATION) {
            if (totalPresaleTokensSold * 100 >= 99 * PRESALE_TOKENS) return State.PresaleCompleted;
            else return State.Presale;
        }
        else if (block.timestamp >= startTime + COMMSALE_DURATION + PRESALE_DURATION + (Saledelay.mul(2)) &&
                block.timestamp < startTime + COMMSALE_DURATION + PRESALE_DURATION + PRIVATESALE_DURATION + (Saledelay.mul(2))) {
            if (totalPrivatesaleTokensSold * 100 >= 99 * PRIVATESALE_TOKENS) return State.PrivateSaleCompleted;
            else return State.PrivateSale;
        }
        else if (block.timestamp >= startTime + COMMSALE_DURATION + PRESALE_DURATION + PRIVATESALE_DURATION + (Saledelay.mul(3)) &&
                block.timestamp < startTime + COMMSALE_DURATION +  PRESALE_DURATION + PRIVATESALE_DURATION + PUBLICSALE_DURATION + (Saledelay.mul(3)) ) {
            if (totalPublicsaleTokensSold * 100 >= 99 * PUBLICSALE_TOKENS) return State.Completed;
            else return State.PublicSale;
        }
        else if (block.timestamp >= startTime + COMMSALE_DURATION + PRESALE_DURATION + PRIVATESALE_DURATION + PUBLICSALE_DURATION + (Saledelay.mul(3))) return State.Completed;
        else return State.Completed;
    }


    function getSalesAtPresale(address account) public view returns(uint256) {
        return salesAtPresale[account];
    }
    function getSalesAtPrivatesale(address account) public view returns(uint256) {
        return salesAtPrivatesale[account];
    }
    function getSalesAtPublicsale(address account) public view returns(uint256) {
        return salesAtPublicsale[account];
    }
    

    //function buyTokens(address _referrer) public payable {
    function buyTokens(address _referrer) public payable {
        State state1 = getState();
        require(state1 == State.CommSale || state1 == State.Presale || state1 == State.PrivateSale || state1 == State.PublicSale, "Sale is not active");
        
        uint256 tokenAmount;
        if (state1 == State.CommSale) {
            require(msg.value >= COMMSALE_MIN_BUY && msg.value <= COMMSALE_MAX_BUY, "Incorrect transaction amount");
            //require(_referrer!= address(0),'Referrer should not be address 0');
            tokenAmount = (msg.value * 10**9 ) / COMMSALE_PRICE;
            totalCommTokensSold += tokenAmount;
            totalCommBnbCollected += msg.value;
            salesAtCommsale[msg.sender] += msg.value;
            require(salesAtCommsale[msg.sender] <= COMMSALE_MAX_BUY, "Buy limit exceeded for account");
           
            uint256 reftokens =tokenAmount.mul(5).div(100);
            token.setuserinfo(msg.sender,tokenAmount,1200); //6 months
            token.setuserinfo(_referrer,reftokens,1200); //6 months


            payable(benificiary).transfer(msg.value);
        }
        else if (state1 == State.Presale) {
          //  require(msg.value >= PRESALE_MIN_BUY && msg.value <= PRESALE_MAX_BUY, "Incorrect transaction amount");
            tokenAmount = (msg.value * 10**9) / PRESALE_PRICE;
            totalPresaleTokensSold += tokenAmount;
            totalPresaleBnbCollected += msg.value;
            salesAtPresale[msg.sender] += msg.value;
            //require(salesAtPresale[msg.sender] <= PRESALE_MAX_BUY, "Buy limit exceeded for account");

            token.setuserinfo(msg.sender,tokenAmount,1200); //3 months

            payable(benificiary).transfer(msg.value);
        }
        else if (state1 == State.PrivateSale) {
          //  require(msg.value >= PRESALE_MIN_BUY && msg.value <= PRESALE_MAX_BUY, "Incorrect transaction amount");
            tokenAmount = (msg.value* 10**9 ) / PRIVATESALE_PRICE;
            totalPrivatesaleTokensSold += tokenAmount;
            totalPrivatesaleBnbCollected += msg.value;
            salesAtPrivatesale[msg.sender] += msg.value;
          //  require(salesAtPresale[msg.sender] <= PRESALE_MAX_BUY, "Buy limit exceeded for account");

            token.setuserinfo(msg.sender,tokenAmount,1200); //3 months

            payable(benificiary).transfer(msg.value);
        }
        else if (state1 == State.PublicSale) {
          //  require(msg.value >= PRESALE_MIN_BUY && msg.value <= PRESALE_MAX_BUY, "Incorrect transaction amount");
            tokenAmount = (msg.value * 10**9) / PUBLICSALE_PRICE;
            totalPublicsaleTokensSold += tokenAmount;
            totalPublicsaleBnbCollected += msg.value;
            salesAtPublicsale[msg.sender] += msg.value;
          //  require(salesAtPresale[msg.sender] <= PRESALE_MAX_BUY, "Buy limit exceeded for account");

            token.setuserinfo(msg.sender,tokenAmount,1200); //3 months

            payable(benificiary).transfer(msg.value);
        }

       // require(totalCommTokensSold >= COMMSALE_TOKENS && totalPresaleTokensSold >= PRESALE_TOKENS && totalPrivatesaleTokensSold >= PRIVATESALE_TOKENS && totalPublicsaleTokensSold >= PUBLICSALE_TOKENS , "Out of tokens");
       
    }

    function closeSale() public onlyOwner() {
        State state1 = getState();
        require(state1 == State.Completed, "Sale is not yet finished");
        uint256 remained_tokens = COMMSALE_TOKENS - totalCommTokensSold;
        remained_tokens += PRESALE_TOKENS - totalPresaleTokensSold;
        remained_tokens += PRIVATESALE_TOKENS - totalPrivatesaleTokensSold;
        remained_tokens += PRESALE_TOKENS - totalPublicsaleTokensSold;
        token.burn(remained_tokens);
        if (address(this).balance > 0) payable(benificiary).transfer(address(this).balance);
    }

}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}