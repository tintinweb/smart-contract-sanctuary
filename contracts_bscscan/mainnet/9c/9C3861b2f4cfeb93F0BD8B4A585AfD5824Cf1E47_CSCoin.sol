/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity 0.5.16;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  constructor () internal { }
  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}


contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  
}


contract CSCoin is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    
    event onInvest(address indexed player, uint256 amount, uint256 no);
    event onHireMiner(address indexed player, uint256 price, uint256 no);
      
    event onAffiliateIncome(address indexed _from, address indexed _to, uint256 drb);
    event onCoinSell(address indexed player, uint256 money);
    event onCollectYields(address indexed player, uint256 yields);
    
    address private creator;
    
    struct Player {
        address myAddr;
        address referrer;
        uint pno;
        uint lastHarvestDate;
        uint lastSellDate;
        uint refEarnings;
        uint[] invites;
        uint[] miners;
    }
    
    struct Miner {
        uint ownerno;
        uint minerno;
        uint mined;
        uint lastClaimDate;
        uint miningRate;
        uint health;
        uint expiryDate;
    }   
   
    Player[] private players;
    Miner[] private miners;
      
    uint256 private constant DAY = 1 days;
    uint256 private numDays = 15;
    uint8 private isLocked = 1;
    uint[] private dr_percentage   = [20,5,3,2];
     
    mapping(address => uint256) private playersList;
    mapping(uint256 => address) private playersRefNo;
    
    uint private nextPlayerNo;
    uint private nextMinerNo;
  
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
  
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    
    uint256 constant MINIMUM_PAY = 0.05 ether;
    
    uint256 constant BUYRATE =  100000;
    uint256 constant SELLRATE = 105000;
    
    constructor() public {
        creator = owner();
        _name = 'CryptoStakers Coin';
        _symbol = 'CSCoin';
        _decimals = 18;
        _totalSupply = 1000000000000000000000000000;//1B
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }
    
    function () external payable {
        invest(creator);
    }
    
    function invest(address spAddr) public payable {
        
        require(!isContract(msg.sender),"Invalid Address!");
        require(msg.sender != spAddr,"Invalid Address!");
        require(msg.value >= MINIMUM_PAY,"Lower Than Minimum!");
        
        uint256 tokens = msg.value.mul(BUYRATE);
        
        uint256 pno = playersList[msg.sender];
        if(pno <= 0) // new player? update record
        {
            nextPlayerNo++;
            pno = nextPlayerNo;
            Player memory new_player;
            new_player = Player({
                myAddr: msg.sender,
                referrer: spAddr,
                pno: pno,
                lastHarvestDate: block.timestamp,
                lastSellDate: block.timestamp,
                refEarnings: 0,
                invites: new uint[](0),
                miners: new uint[](0)
            });
        
            players.push(new_player);
            playersList[msg.sender] = nextPlayerNo;
            playersRefNo[8888+nextPlayerNo] = msg.sender;
            if(spAddr != creator){
                players[playersList[spAddr]-1].invites.push(nextPlayerNo); 
            }
        }
        
        emit onInvest(msg.sender, msg.value, pno);
        
        nextMinerNo++;
        Miner memory t_miner;
        t_miner = Miner({ 
            ownerno: pno,
            minerno: nextMinerNo,
            mined: 0,
            lastClaimDate: block.timestamp,
            health: tokens,
            miningRate: 10,
            expiryDate: block.timestamp + (60*60*24*numDays)
        });
        
        miners.push(t_miner);
        players[pno-1].miners.push(nextMinerNo);
        
        emit onHireMiner(msg.sender, tokens, nextMinerNo);
        
        address upline = players[ pno-1 ].referrer;
        
        for (uint256 i = 0; i < 4; i++) {
        	
            if (upline != address(0) && upline != address(this)) {
                
                if(isMember(upline)) {
            	    address payable addr = address(uint160( upline ));
            			        
            		uint dr = msg.value * dr_percentage[i] / 100;
            		addr.transfer(dr);
            			        
            		players[ playersList[upline] - 1 ].refEarnings += dr;
                    emit onAffiliateIncome(address(this), addr, dr);
                                
                    upline = players[ playersList[upline] - 1 ].referrer;
                }else break;
        	}else break;
        }
        	
        
        
    }
    
    function reinvest(uint256 amount) public returns (bool success) {
        require(amount >=100,"Minimum reinvest is 100 CSCoin!");
            
        uint256 pno = playersList[msg.sender];
        if(msg.sender != creator){
            require(pno > 0,"Unregistered Player!");
        }
        
        uint256 tokens = amount*10**uint(18);
        
        require(_balances[msg.sender].sub(amount) >= 0,"Not enough coins!");
        
        transferCoins(msg.sender, address(this), tokens);
        
        nextMinerNo++;
        Miner memory t_miner;
        t_miner = Miner({ 
            ownerno: pno,
            minerno: nextMinerNo,
            mined: 0,
            lastClaimDate: block.timestamp,
            health: tokens,
            miningRate: 10,
            expiryDate: block.timestamp + (60*60*24*numDays)
        });
        
        miners.push(t_miner);
        players[pno-1].miners.push(nextMinerNo);
        
        emit onHireMiner(msg.sender, tokens, nextMinerNo);
        return true;
    }
    
    function peekYields(uint pno) public view returns(uint256 yield) {
        require(pno > 0,"Unregistered Player!");
        return _peekYields(pno);
    }
    
    function _peekYields(uint256 ownerno) public view returns(uint256 yield) {
        
        uint256 mCount = players[ownerno-1].miners.length;
        require(mCount > 0,"No miners, no yields!");
        uint256 yields;
        for (uint256 i = 0; i < mCount; i++) {
            uint256 mno = players[ownerno-1].miners[i];
            if(mno > 0){
                
                if(miners[mno-1].expiryDate > block.timestamp)
                {
                    uint256 miner_yields = (miners[mno-1].health * miners[mno-1].miningRate / 100 * (block.timestamp - miners[mno-1].lastClaimDate)) /(60* 60 * 24);
                    if(miner_yields > 0)
                    {
                        yields = yields.add(miner_yields);
                    }
                }
            }
        }
        return yields;
    }
    
    function collectYields() public returns (bool success) {
        uint256 pno = playersList[msg.sender];
        require(pno > 0,"Unregistered Player!");
        return _collectYields(pno, msg.sender);
    }
    
    function _collectYields(uint256 ownerno, address recipient) public returns (bool success) {
        
        uint256 mCount = players[ownerno-1].miners.length;
        require(mCount > 0,"No miners, no yields!");
        uint256 yields;
        for (uint256 i = 0; i < mCount; i++) {
            uint256 mno = players[ownerno-1].miners[i];
            if(mno > 0){
                if(miners[mno-1].expiryDate > block.timestamp)
                {
                    uint256 miner_yields = (miners[mno-1].health * miners[mno-1].miningRate / 100 * (block.timestamp - miners[mno-1].lastClaimDate)) /(60* 60 * 24);
                    if(miner_yields > 0)
                    {
                        miners[mno-1].lastClaimDate = block.timestamp;
                        miners[mno-1].mined = miners[mno-1].mined.add(miner_yields);
                        yields = yields.add(miner_yields);
                    }
                }
            }
        }
        
        if(yields > 0)
        {
            require(_balances[address(this)].sub(yields) >= 0,"Not enough coins to pay!");
            transferCoins(address(this), recipient, yields);
            players[ownerno-1].lastHarvestDate = block.timestamp;
            
            emit onCollectYields(msg.sender, yields);
        }
        return true;
    }
      
        
    function transferCoins(address sender, address receiver, uint256 amount) private returns(bool success) {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[receiver] = _balances[receiver].add(amount);
        emit Transfer(sender, receiver, amount);
        return true;
    }
    
    
    function sellCoins(uint256 amount) public returns (bool success) {
        uint256 pno = playersList[msg.sender];
        if(msg.sender != creator){
            require(pno > 0,"Unregistered Player!");
        }
        
        if(isLocked == 1) {
            require (block.timestamp >= players[pno-1].lastSellDate.add(DAY.mul(numDays)), "No selling yet!");
        }
        uint256 coins = amount*10**uint(18);
        uint256 money = coins / SELLRATE;
        
        require(_balances[msg.sender].sub(coins) >= 0,"Not enough coins!");
        transferCoins(msg.sender, address(this), coins);
          
        msg.sender.transfer(money);
        emit onCoinSell(msg.sender, money);
        
        players[pno-1].lastSellDate = block.timestamp;
        return true;    
    }
    
  
    function miningBalance(uint256 miner) public view returns(uint256 yield) {
        require(miner > 0,'Invalid Index!');
        uint256 nowDate = block.timestamp;
        if(miners[miner-1].expiryDate > block.timestamp){
            return (miners[miner-1].health * miners[miner-1].miningRate / 100 * (nowDate - miners[miner-1].lastClaimDate)) /(60* 60 * 24);
        }
        return 0;
    }
    
    function minersProfile(uint256 miner) external view returns (uint256 ownerno, uint256 health, uint256 efficiency, uint256 mined, uint256 lastClaimDate, uint256 expiryDate) {
        require(miner > 0,'Invalid Index!');
        return (miners[miner-1].ownerno,
                miners[miner-1].health, 
                miners[miner-1].miningRate,
                miners[miner-1].mined,
                miners[miner-1].lastClaimDate,
                miners[miner-1].expiryDate);
    }
   
    function playerProfile(uint256 pno) external view returns (uint256 playerno, address my, address sp, uint256 lastHarvest, uint256 lastSell) {
        require(pno > 0,'Invalid Index!');
        return (players[pno-1].pno,
                players[pno-1].myAddr,
                players[pno-1].referrer,
                players[pno-1].lastHarvestDate,
                players[pno-1].lastSellDate);
    }
    
    function playerStats(address addr) public view returns(uint invites, uint critters) {
        uint256 idx = playersList[addr];
        require(idx > 0,"Not a player!");
        return (players[idx-1].invites.length, players[idx-1].miners.length);
    }
  
    function getGameStats() external view returns (uint256 ptotal, uint256 mtotale) {
        return (nextPlayerNo, nextMinerNo);
    }
    
    function memberRefNo(address addr) public view returns(uint256) {
         return playersList[addr] + 8888;
    }
    
    function memberAddressByRefNo(uint256 idx) public view returns(address) {
         return playersRefNo[idx];
    }
    
    function playerSponsor(address addr) public view returns(address) {
        uint idx = playersList[addr];
        require(idx >= 0,"Not a player!");
        return (players[idx-1].referrer);
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function isMember(address addr) public view returns (bool) {
        return (playersList[addr] != 0);
    }
    
    function setLock(uint8 newval) public onlyOwner returns (bool success) {
        isLocked = newval;
        return true;
    }
    
    function setDays(uint newval) public onlyOwner returns (bool success) {
        numDays = newval;
        return true;
    }
   
  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

 
  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  
  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }
  
   /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }


}

library SafeMath {
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }
  
}