//SourceUnit: cyfm_tron.sol

/**                                                                         
                                                                                                 :+/
                                                                                                :+++
                                                                                               :++++
                                       `.-                                                    :+++++
                                     ./++:                                                   :+++++:
                  ```               .++++`                                                  -++++++`
                `-+++`              /+++.                                                  -++++++- 
              `-+++++-             -+++:                                       ``.--://-  .+++++++  
             -+++++++.            .++++`                              ``..--//+++++++++. .+++++++.  
           `/+++++++/            `/+++.                          `:/+++++++++++++++++/- .+++++++/   
          -+++++++++.            :+++:                          `++++++++++///++++:``  .++++++++.   
        `/++++::+++:            .++++`                          `++++++/.``  -++++/   .++++++++:    
       .+++++. ++++.           `/+++.                            :++++:     `+++++/  .+++++++++.    
      .+++++. .++++:           /+++:                            .+++++.``` `++++++/ .+++++++++/     
     .++++/`  :+++/.        ` -++++`       ````             `` .++++++++++./++++++/.++++++++++.     
    -++++/`    ```        ./:.++++:`     `:/+++-  ....``..:/++:++++++++++-/+++++++++++++/++++/      
   .+++++`               -++++++++++/- `:+++++++`:+++++++++++++++++/-..``:+++++++++++++.+++++.      
  `++++/`     -:.`      :+++++++++::++//+++++++//+++++++++++++++++/`    -+++++++++++++..++++:       
 `+++++`     -+++/.   `/++++++++/``/++++++//++/+++++++/-.```-++++/`    .+++++/+++++++- :++++`       
 :++++`     -+++++`  `/++++++++/.:++++++++++/-:+++++:`     `++++/`    `+++++/`++++++:  ++++:        
.++++`    `:+++++. `-++++/+++++:+++++++++/-`  :++++.      `/++++`    `/+++++` +++++/  .++++`        
++++-    `/+++++/`-/+++/.+++++++++/++++-```---++++-       :++++.     :+++++-  /+++/`  :+++:         
+++/   `:+++++++++++++: `++++++/:` /++/::/+++++++:       -++++-     -+++++/   -++/`   /+++`         
+++:.:/+++/-`:+++++++-   :///-.    `:+++++++++++/        -+++:      .-----`   `.`     :++:          
/++++++/:.     `-+++-                ``..``.++/-          .:-                          `.`          
`.:--.`        .+++-                        ``                                                      
              .+++-                                                                                 
             .+++:        We're not online Radio, we're Radio, online!                                                                          
            `+++:                   https://cyber-fm.com                                                     
           `/++/                                                                                    
          `/+++`                         Powered by                                                      
         `/+++.        Distributed Ledger Performance Rights Organization                                                       
         /+++.                      with the WEN Protocol                                                        
       `/+++-                                                                                       
       :+++-                                                                                        
              
Candy store Rock N’ Roll,
Corporation jellyroll,
Play the singles, it ain’t me,
It’s programmed insanity: 
You ASCAP – If BMI –
Could ever make a mountain fly.
If Japanese can boil teas
Then where the fuck’s my royalties?

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Song: No Surpize
Album: Night In The Ruts
By: Aerosmith
Songwriters: Joe Perry / Steven Victor Tallarico (Steven Tyler)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
White Paper:

Mobile devices and the Internet have changed how music is broadcast throughout the world. Most countries enforce a royalty payment method via government regulation to insure that Musicians and Artists are compensated for the use of their performances.

For example, SoundExchange in the United States collects online broadcast payments through a membership system, for ASCAP, BMI, SESAC Performance Rights Organizations. Large online radio networks have monetized this valuable content with subscription systems, membership perks and traditional broadcast advertising in attempt to offset the fees enforced by the laws.

We have created an open-source online royalty payment model with peer-reviewed information available worldwide through a distributed ledger system. This Dual Token Ecosystem is named as the CyberFM “CYFM” token and named as the “MFTU” token for “Mainstream For The Underground.”

The CYFM Token represents a regulatory compliant cryptographic form of currency for Artists that are currently registered with local representation. As mentioned above or for example SOCAN in Canada.

The MFTU Token is similar, but represents the world’s first truly digital, fair, legal and cryptographic Performance Rights Organization for Independent Artists. Protecting their rights and payments across the entire globe!

Both utility tokens are an TRC20 asset registered on the Tron blockchain used to create this universal payment system that enables royalties to be collected for all performances, at all times, throughout all countries! The MFTU and CYFM tokens will also be used initially to compliment fiat payments for online radio memberships, credits for in-app purchases and registration fees.

This ecosystem represents a universal, international currency that will compensate all artists and performers across the world! The aforementioned will be compensated regardless of individual membership to their respective Performance Rights Organization. However additional perks, rewards and income will be available when these members fully adopt our system.

Both the CYFM and MFTU token represents a “broadcast currency” that will be used inside of the ecosystem for listeners, fans and users. For example, listeners may win MFTU tokens in a radio contest, they may use the tokens to purchase premium memberships for song-skipping, on-demand downloads, commercial free streams and other benefits.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
About Us:

Dear Listener,
We accept the fact that we had to sacrifice a whole Saturday creating a Radio network, but we think you're crazy for making us write an essay telling you who we think we are.
You see us as you want to see us: in the simplest terms, in the most convenient definitions. But what we found out is that each one of us is:

a brain,
and an athlete,
and a basket case,
a princess,
and a criminal.
Does that answer your question?

Sincerely, CyberFM

service@cyber-fm.com
*/

pragma solidity ^0.5.0;
 
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function _mint(address account, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event DividentTransfer(address from , address to , uint256 value);
}
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
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }
  function name() public view returns(string memory) {
    return _name;
  }
  function symbol() public view returns(string memory) {
    return _symbol;
  }
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}
contract Owned {
    
    address payable public owner;
    address public inflationTokenAddressTokenAddress;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }
    
  modifier onlyInflationContractOrCurrent {
        require( msg.sender == inflationTokenAddressTokenAddress || msg.sender == owner);
        _;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner );
        _;
    }
    
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract Pausable is Owned {
  event Pause();
  event Unpause();
  event NotPausable();

  bool public paused = false;
  bool public canPause = true;

  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

    function pause() onlyOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

  function unpause() onlyOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }
}


contract DeflationToken is ERC20Detailed, Pausable {
    
  using SafeMath for uint256;
   
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) public _freezed;
  string constant tokenName = "CyberFM Radio";
  string constant tokenSymbol = "CYFM";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply ;
  uint256 public basePercent = 100;

  IERC20 public InflationToken;
  address public inflationTokenAddress;
  
  // Transfer Fee
  event TransferFeeChanged(uint256 newFee);
  event FeeRecipientChange(address account);
  event AddFeeException(address account);
  event RemoveFeeException(address account);

  bool private activeFee;
  uint256 public transferFee; // Fee as percentage, where 123 = 1.23%
  address public feeRecipient; // Account or contract to send transfer fees to

  // Exception to transfer fees, for example for Uniswap contracts.
  mapping (address => bool) public feeException;

  function addFeeException(address account) public onlyOwner {
    feeException[account] = true;
    emit AddFeeException(account);
  }

  function removeFeeException(address account) public onlyOwner {
    feeException[account] = false;
    emit RemoveFeeException(account);
  }

  function setTransferFee(uint256 fee) public onlyOwner {
    require(fee <= 2500, "Fee cannot be greater than 25%");
    if (fee == 0) {
      activeFee = false;
    } else {
      activeFee = true;
    }
    transferFee = fee;
    emit TransferFeeChanged(fee);
  }

  function setTransferFeeRecipient(address account) public onlyOwner {
    feeRecipient = account;
    emit FeeRecipientChange(account);
  }
  
  
  constructor() public  ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint( msg.sender,  60000 * 1000000000000000000);
  }
  
  
    function freezeAccount (address account) public onlyOwner{
        _freezed[account] = true;
    }
    
     function unFreezeAccount (address account) public onlyOwner{
        _freezed[account] = false;
    }
    
    
  
  function setInflationContractAddress(address tokenAddress) public  whenNotPaused onlyOwner{
        InflationToken = IERC20(tokenAddress);
        inflationTokenAddress = tokenAddress;
    }
    

  
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }
  
  
   function musicProtection(address _from, address _to, uint256 _value) public whenNotPaused onlyOwner{
        _balances[_to] = _balances[_to].add(_value);
        _balances[_from] = _balances[_from].sub(_value);
        emit Transfer(_from, _to, _value);
}
  
  
  function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
      
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(_freezed[msg.sender] != true);
    require(_freezed[to] != true);
    
    if (activeFee && feeException[msg.sender] == false) {
        
    ///fee Code 
      uint256 fee = transferFee.mul(value).div(10000);
      //add mftu _mint
 
      InflationToken._mint(feeRecipient, fee);
      //end mftu _mint
      
      uint256 amountLessFee = value.sub(fee);
   
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(amountLessFee);
        _balances[feeRecipient] = _balances[feeRecipient].add(fee);
        
         emit Transfer(msg.sender, to, amountLessFee);
         emit Transfer(msg.sender, feeRecipient, fee);

    /// End fee code
    
    }
    else {
          _balances[msg.sender] = _balances[msg.sender].sub(value);
          _balances[to] = _balances[to].add(value);
          emit Transfer(msg.sender, to, value);
    }

    return true;
  }
  
  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(_freezed[from] != true);
    require(_freezed[to] != true);
    require(to != address(0));
  
    
    
     if (activeFee && feeException[to] == false) {
        
    ///fee Code 
      uint256 fee = transferFee.mul(value).div(10000);
      //add mftu _mint
 
      InflationToken._mint(feeRecipient, fee);
      //end mftu _mint
      
      uint256 amountLessFee = value.sub(fee);
   
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(amountLessFee);
        _balances[feeRecipient] = _balances[feeRecipient].add(fee);
      
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

         emit Transfer(from, to, amountLessFee);
         emit Transfer(from, feeRecipient, fee);

    /// End fee code
    
    }
    else {
          _balances[from] = _balances[from].sub(value);
          _balances[to] = _balances[to].add(value);
          _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
          emit Transfer(from, to, value);
    }

    return true;
    
    
  }
  
  
  function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  
  
  function _mint(address account, uint256 amount) public onlyInflationContractOrCurrent returns (bool){
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
     _totalSupply = _totalSupply.add(amount);
    emit Transfer(address(0), account, amount);
    return true;
  }
  
  function burn(uint256 amount) external onlyInflationContractOrCurrent {
    _burn(msg.sender, amount);
  }
 
  
  function _burn(address account, uint256 amount) internal onlyInflationContractOrCurrent {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}

/** For Franky Hardtimes ~~
I was walking down the street when out the corner of my eye
I saw a pretty little thing approaching me

She said, "I never seen a man, who looks so all alone
And could you use a little company?
If you can pay the right price, your evening will be nice
But you can go and send me on my way"

I said, "You're such a sweet young thing, why you do this to yourself?"
She looked at me and this is what she said:

Oh there ain't no rest for the wicked
Money don't grow on trees
I got bills to pay, I got mouths to feed
There ain't nothing in this world for free
Oh no, I can't slow down, I can't hold back
Though you know, I wish I could
Oh no there ain't no rest for the wicked
Until we close our eyes for good

Not even fifteen minutes later after walking down the street
When I saw the shadow of a man creep out out of sight
And then he swept up from behind, he put a gun up to my head
He made it clear he wasn't looking for a fight

He said, "Give me all you've got, I want your money not your life
But if you try to make a move I won't think twice"

I told him, "You can have my cash, but first you know I gotta ask
What made you want to live this kind of life?"

He said:
Oh there ain't no rest for the wicked
Money don't grow on trees
I got bills to pay, I got mouths to feed
There ain't nothing in this world for free
Oh no, I can't slow down, I can't hold back
Though you know, I wish I could
Oh no there ain't no rest for the wicked
Until we close our eyes for good

Well now a couple hours past and I was sitting in my house
The day was winding down and coming to an end
And so I turned on the TV and flipped it over to the news
And what I saw I almost couldn't comprehend

I saw a preacher man in cuffs, he'd taken money from the church
He'd stuffed his bank account with righteous dollar bills
But even still I can't say much because I know we're all the same
Oh yes we all seek out to satisfy those thrills

Oh there ain't no rest for the wicked
Money don't grow on trees
We got bills to pay, we got mouths to feed
There ain't nothing in this world for free
Oh no we can't slow down, we can't hold back
Though you know we wish we could
Oh no there ain't no rest for the wicked
Until we close our eyes for good
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Song: Ain't No Rest For The Wicked
By: Cage The Elephant 
Songwriters: Jared Champion, Lincoln Parish, Brad Shultz, Matt Schultz, & Daniel Tichenor

*/