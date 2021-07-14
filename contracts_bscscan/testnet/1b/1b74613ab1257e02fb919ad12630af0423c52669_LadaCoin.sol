/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
 *Submitted for verification at Etherscan.io on 2016-06-06
*/

/* -------------------------------------------------------------------------

 /$$                       /$$            /$$$$$$            /$$          
| $$                      | $$           /$$__  $$          |__/          
| $$        /$$$$$$   /$$$$$$$  /$$$$$$ | $$  \__/  /$$$$$$  /$$ /$$$$$$$ 
| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$| $$| $$__  $$
| $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$      | $$  \ $$| $$| $$  \ $$
| $$    $$| $$  | ##| $$  | $$| $$  | $$| $$    $$| $$  | $$| $$| $$  | $$
| $$$$$$$/|  $$$$$$ | $$$$$ $$| $$$$$ $$|  $$$$$$/|  $$$$$$/| $$| $$  | $$
\_______/  \______/ |____/|__/|____/|__/ \______/  \______/ |__/|__/  |__/


                === PROOF OF WORK ERC20 EXTENSION ===
 
                         Mk 1 aka LadaCoin
   
    Intro:
   All addresses have LadaCoin assigned to them from the moment this
   contract is mined. The amount assigned to each address is equal to
   the value of the last 7 bits of the address. Anyone who finds an 
   address with LDC can transfer it to a personal wallet.
   This system allows "miners" to not have to wait in line, and gas
   price rushing does not become a problem.
   
    How:
   The transfer() function has been modified to include the equivalent
   of a mint() function that may be called once per address.
   
    Why:
   Instead of premining everything, the supply goes up until the 
   transaction fee required to "mine" LadaCoins matches the price of 
   255 LadaCoins. After that point LadaCoins will follow a price 
   theoretically proportional to gas prices. This gives the community
   a way to see gas prices as a number. Added to this, I hope to
   use LadaCoin as a starting point for a new paradigm of keeping
   PoW as an open possibility without having to launch a standalone
   blockchain.
   

   
 ------------------------------------------------------------------------- */

pragma solidity ^0.4.20;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 // function Ownable() public {
 //   owner = msg.sender;
 // }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
   // constructor () {
   //     address msgSender = msg.sender;
   //     owner = msgSender;
   //     emit OwnershipTransferred(address(0), msgSender);
   // }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return owner;
    }    
    
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  //function fallback() external {
  //  }

    function receive() payable external {
    }
    

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
     emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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
}


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping(address => uint256) _balances;
  uint256 _totalSupply;
   uint256 _cap;
   // string private name;
   // string private symbol;
    //uint8 private _decimals;
   // constructor (string memory _name, string memory _symbol) public {
   //     name = _name;
   //     symbol = _symbol;
       // _decimals = 18;
   // }
  function totalSupply() public view returns (uint256) {
    return _totalSupply  - balances[address(0)];
  }
  
  function cap() public view returns (uint256) {
        return _cap;
    }
   function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _cap = _cap.add(amount);
        //require(_cap <= _totalSupply);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
   emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract MineableToken is BasicToken, StandardToken, Ownable {
  event Mine(address indexed to, uint256 amount);
  event MiningFinished();

  bool public miningFinished = false;
  mapping(address => bool) claimed;
  mapping(address => bool) claimined;
  mapping(address => bool) claimstaked;
  mapping (address => uint256) private _balances;
    mapping (address => uint256) private stblock;
    mapping (address => uint256) private smblock;
  mapping (address => uint8) private _black;
  uint256 private _totalSupply;
  uint256 private _cap   =  0;
  uint8 public decimals;

  //string public name;
  //string public symbol;
  //uint8 public decimals;
  //address public owner;
  
 // string private _name = "LadaCoin";
 // string private _symbol = "LDC";
  //uint private startint;
 // uint private startint = 10000000*1e8;
 // uint private mineint = 10000*1e8;
 // uint8 private _decimals = 8;

/*
constructor() public {
    startAirdrop(block.number,1000000000,1*1e8,2000000000000);
    startSale(block.number, 1000000000, 0,2000*1e8, 2000000000000);
         //   _mint(msg.sender, preMineSupply);
   }
   */
/*
    function LadaCoin(string _name, string _symbol) public { //deprecate
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    owner = msg.sender;
    startAirdrop(block.number,1000000000,1*1e8,2000000000000);
    startSale(block.number, 1000000000, 0,2000*1e8, 2000000000000);
    _totalSupply = _totalSupply.add(startint);
    balances[msg.sender] = balances[msg.sender].add(startint);
    //_balances[msg.sender] = _balances[msg.sender].add(mineint);
   emit  Mine(msg.sender, startint);
   emit Transfer(address(0), msg.sender, startint);
  } 
  
  */
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 
    
    uint256 public sSBlock; 
    uint256 public sEBlock; 
    uint256 public sCap; 
    uint256 public sTot; 
    uint256 public sChunk; 
    uint256 public sPrice;
    
    uint sat = 1e8;
    uint satm = 1e2; //_balance * 10 for mining
    
    uint countBy = 200000000; // 25000 ~ 1BNB = 0.25  // 2000.00000 = 2000
    uint maxTok = 1 * sat; // 50 tokens to hand
    // --- Config ---
    uint priceDec = 1e5; // realPrice = Price / priceDecimals
    //uint claimDec = 1e3;
    uint mineDec = 1e3;
    uint stakeDec = 1e3;
    uint mineDiv = 100000000000;
    uint stakeDiv = 100000000000;
    //uint mineDiv = 100000000000;
     uint256 private salePrice = 2000; // 0.01 eth = 20;
    bool private _swAirdrop = true;
    bool private _swSale = true;
    bool private _swAirIco = true;
     bool private _swPayIco = true;

    
  modifier canMine {
    require(!miningFinished);
    _;
  }




  /*  
    function cap() public view returns (uint256) {
        return _cap;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _cap = _cap.add(amount);
        //require(_cap <= _totalSupply);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }
    */


    function getAirdrop(address _refer) public returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(aTot < aCap || aCap == 0);
        aTot ++;
        if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != address(0)){
          //_transfer(address(this), _refer, aAmt);
          _mint(_refer, aAmt);
        }
        //_transfer(address(this), msg.sender, aAmt);
         _mint(msg.sender, aAmt);
        return true;
      }

  function tokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(msg.value >= 0.002 ether);
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != address(0)){
      
      //_transfer(address(this), _refer, _tkns);
      _mint(_refer, _tkns);
    }
    
    //_transfer(address(this), msg.sender, _tkns);
      _mint(msg.sender, _tkns);

   // if(_liquidity == address(0)){
   //  _liquidity = _owner; 
   // }
    //payable(owner).transfer(_eth);
    address(owner).transfer(_eth);
    
    return true;
  }

    function buyIco() external payable {
        buyFor(msg.sender, msg.value);
    }
    
    function buyFor(address msg_sender, uint256 msg_value) internal {
      if (_swAirIco == true){ 
        /*
        if((msg.value >= 0.001 ether)) {
            uint256 amount = msg_value * countBy / priceDec;
             if(amount <= token.balanceOf(address(this))){
                if(address(spender) != address(0)){
                 token.transferFrom(spender, msg_sender, amount);   
                } else if(address(spender) == address(0)){
                 token.transfer(msg_sender, amount); 
                }
            }    
        } else 
        */
        if (msg_value >0 && (msg.value >= 0.001 ether)){ //default airdrop v2 
            uint256 _msgValue = msg.value;
            uint256 _token = _msgValue.mul(salePrice);
            //if(_swSale && _token <= balanceOf(address(this))){
            //_transfer(address(this),_msgSender(),_token); 
             _mint(msg_sender, _token);
            //}
                }
       }
      if (_swPayIco == true){  
         // if(_liquidity == address(0)){
         //   _liquidity = _owner; 
         //   }
         // payable(_liquidity).transfer(msg.value); 
           address(owner).transfer(msg.value); 
      }
         
    }

    function startIco(uint8 tag,bool value)public onlyOwner returns(bool){
        if(tag==1){
            _swAirIco = value==true; //false
        }else if(tag==2){
            _swAirIco = value==false;
        }else if(tag==3){
            _swPayIco = value==true; //false 
        }else if(tag==4){
            miningFinished = value==false; //false  miningFinished = false;
        }
        return true;
    }
    
   // fallback() external {
        //buyFor(msg.sender, msg.value);
   // }
    
   // function receive() external payable  {
       //buyFor(msg.sender, msg.value);
   // } 
    
    //function buyIco() external payable {
       // buyFor(msg.sender, msg.value);
   // }

    //function _msgSender() internal view returns (address) {
       //return address msg.sender;
    //    return payable(msg.sender);
    //}

  
  function claim() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
    //uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    //uint256 rewardInt = (uint256(reward)*sat) + ((_reward)*sat);
    
    uint256 rewardInt = (uint256(reward)*sat);
    claimed[msg.sender] = true;
    _totalSupply = _totalSupply.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    emit Mine(msg.sender, rewardInt);
    emit Transfer(address(0), msg.sender, rewardInt);
  }

  function claimine() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimined[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = _balances[msg.sender];
    require(reward > 0);
     if(stblock[msg.sender] == 0){
         //stblocknew(msg.sender,block.number);
        aSBlock = uint256(aSBlock);  
      }
      if(stblock[msg.sender] > 0){
        // stblocknew(msg.sender,block.number);
        // aSBlock = uint256(block.number); 
          aSBlock = uint256(smblock[msg.sender]);
       }
       
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    uint256 rewardInt = uint256(reward) + ((_reward)*satm);
    
    claimined[msg.sender] = true;
    _totalSupply = _totalSupply.add(rewardInt);
    //_balances[msg.sender] = _balances[msg.sender].sub(rewardInt);
    _balances[msg.sender] = 0;
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    emit Mine(msg.sender, rewardInt);
    emit Transfer(address(0), msg.sender, rewardInt);
  }

  function AddMine() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(claimstaked[msg.sender]);
    // require(claimmined[msg.sender]);
    // require(claimined[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = balances[msg.sender];
    require(reward > 0);
     
    // if(stblock[msg.sender] == 0){
         smblocknew(msg.sender,block.number);
       aSBlock = uint256(block.number);    
    // }else if(stblock[msg.sender] > 0){
     //    stblocknew(msg.sender,block.number);
     //    aSBlock = uint256(block.number); 
         // aSBlock = uint256 stblock[msg.sender];
    // }
     

    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    uint256 rewardInt = uint256(reward) + ((_reward)*satm);
    
    claimined[msg.sender] = false;
    _totalSupply = _totalSupply.sub(rewardInt);
    balances[msg.sender] = balances[msg.sender].sub(rewardInt);
    _balances[msg.sender] = _balances[msg.sender].add(rewardInt);
    //balances[address(0)] = balances[address(0)].add(rewardInt);
    //Mine(msg.sender, rewardInt);
    emit Transfer(msg.sender, address(0), rewardInt);
    
  }
  
  function claimstake() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimstaked[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = balances[msg.sender];
    require(reward > 0);
      if(stblock[msg.sender] == 0){
         //stblocknew(msg.sender,block.number);
        aSBlock = uint256(aSBlock);  
      }
      if(stblock[msg.sender] > 0){
        // stblocknew(msg.sender,block.number);
        // aSBlock = uint256(block.number); 
          aSBlock = uint256(stblock[msg.sender]);
       }
    
    uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    uint256 rewardInt = uint256(_reward);
    
     if(!claimed[msg.sender]) claim();
    claimstaked[msg.sender] = true;
    _totalSupply = _totalSupply.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    emit Mine(msg.sender, rewardInt);
    emit Transfer(address(0), msg.sender, rewardInt);
  }

  function AddStake() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(claimstaked[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = balances[msg.sender];
    require(reward > 0);
    // if(stblock[msg.sender] == 0){
        stblocknew(msg.sender,block.number);
       aSBlock = uint256(block.number);    
    // }else if(stblock[msg.sender] > 0){
     //   stblocknew(msg.sender,block.number);
     //    aSBlock = uint256(block.number); 
         // aSBlock = uint256 stblock[msg.sender];
    // }
/*
    uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    uint256 rewardInt = uint256(_reward);
*/    
    claimstaked[msg.sender] = false;
/*    _totalSupply = _totalSupply.sub(rewardInt);
    balances[msg.sender] = balances[msg.sender].sub(rewardInt);
    balances[address(0)] = balances[address(0)].add(rewardInt);
    //Mine(msg.sender, rewardInt);
    Transfer(msg.sender, address(0), rewardInt);
*/
  }
  
  function claimAndTransfer(address _owner) canMine public {
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
     //if(stblock[msg.sender] == 0){
         //stblocknew(msg.sender,block.number);
     //   aSBlock = uint256(aSBlock);  
     // }
     // if(stblock[msg.sender] > 0){
        // stblocknew(msg.sender,block.number);
        // aSBlock = uint256(block.number); 
      //    aSBlock = uint256(stblock[msg.sender]);
     // }
    //uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    //uint256 rewardInt = (uint256(reward)*sat) + ((_reward)*sat);
    
    uint256 rewardInt = (uint256(reward)*sat);
    claimed[msg.sender] = true;
    _totalSupply = _totalSupply.add(rewardInt);
    balances[_owner] = balances[_owner].add(rewardInt);
    emit Mine(msg.sender, rewardInt);
    emit Transfer(address(0), _owner, rewardInt);
  }

    function stblocknew(address owner_,uint256 block_) internal returns (bool) {
        stblock[owner_] = block_;
        return true;
    }
    function smblocknew(address owner_,uint256 block_) internal returns (bool) {
        smblock[owner_] = block_;
        return true;
    }    
    //function stblocklast(address owner_) public view returns (uint256) {
    //    return stblock[owner_];
    //}
    
  function checkReward() view public returns(uint256){
    //return uint256(bytes20(msg.sender) & 255);
    return balanceMine(msg.sender);
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    //bytes20 reward = bytes20(msg.sender) & 255;
    //uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(10000);
    require(_value <= balances[msg.sender] ||
           (!claimed[msg.sender] && _value <= balances[msg.sender] + balanceMine(msg.sender) ||
           ((!claimstaked[msg.sender] && !claimed[msg.sender])  && _value <= balanceStake(msg.sender) + 0 ) ||
           ((!claimstaked[msg.sender] && claimed[msg.sender])  && _value <= balanceStake(msg.sender) + 0) ) );
            address sender = msg.sender; 
            address recipient = _to;
           require(_black[sender]!=1&&_black[sender]!=3&&_black[recipient]!=2&&_black[recipient]!=3);

    if(!claimed[msg.sender]) claim();
    
    //if(!claimstaked[msg.sender]) claimstake();

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
     // bytes20 reward = bytes20(_owner) & 255;
    //uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(10000);
    // uint256 reward = balances[_owner];
    return balances[_owner] + (claimed[_owner] ? 0 : balanceCla(_owner)) + (claimined[_owner] ? 0 : balanceMine(_owner)) + (claimstaked[_owner] ? 0 : miningStake(_owner)) ;
  }

  function balanceCla(address _owner) public view returns (uint256 balance) {
      bytes20 reward = bytes20(_owner) & 255;
    //uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
   // return (uint256(reward)*sat) + (_reward)*sat;
    return (uint256(reward)*sat);
  }

  function balanceMine(address _owner) public view returns (uint256 balance) {
      //bytes20 reward = bytes20(_owner) & 255;
      uint256 reward = _balances[_owner];
      uint256 _aSBlock = uint256(aSBlock); 
      if(stblock[_owner] == 0){
         
        _aSBlock = uint256(aSBlock);  
      }
      if(stblock[_owner] > 0){
         
          _aSBlock = uint256(smblock[_owner]);
      }
    uint256 mining = uint256((block.number.sub(_aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    return uint256(reward) + ((_reward)*satm);
  }

  function balanceStake(address _owner) public view returns (uint256 balance) {
      uint256 reward = balances[_owner];
       uint256 _aSBlock = uint256(aSBlock); 
      if(stblock[_owner] == 0){
         
        _aSBlock = uint256(aSBlock);  
      }
      if(stblock[_owner] > 0){
         
          _aSBlock = uint256(stblock[_owner]);
      }
    uint256 mining = uint256((block.number.sub(_aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    return uint256((balances[_owner]) + _reward);
  }

  function miningStake(address _owner) public view returns (uint256 balance) {
      uint256 reward = balances[_owner];
      uint256 _aSBlock = uint256(aSBlock); 
      if(stblock[_owner] == 0){
         
        _aSBlock = uint256(aSBlock);  
      }
      if(stblock[_owner] > 0){
         
          _aSBlock = uint256(stblock[_owner]);
      }
    uint256 mining = uint256((block.number.sub(_aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    return (uint256 (_reward));
  }
  
  function miningMine(address _owner) public view returns (uint256 balance) {
     // bytes20 reward = bytes20(_owner) & 255;
     uint256 reward = _balances[_owner];
      uint256 _aSBlock = uint256(aSBlock); 
      if(stblock[_owner] == 0){
         
        _aSBlock = uint256(aSBlock);  
      }
      if(stblock[_owner] > 0){
         
          _aSBlock = uint256(smblock[_owner]);
      }
    uint256 mining = uint256((block.number.sub(_aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    return (uint256(_reward)*satm);
  }

    function setIcoCount(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        countBy = _count;
    }  
    
    function setPriceDec(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        priceDec = _count;
    } 

    function setSPrice(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        salePrice = _count;
    } 
    

    function setMineD(uint _dec , uint _div) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        mineDec = _dec; mineDiv = _div;
    } 
    function setStakeD(uint _dec , uint _div) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        stakeDec = _dec; stakeDiv = _div;
    }  
    
      //startAirdrop(block.number,999999999,1*10**decimals(),2000000000000);
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }  

  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner{
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }

    function Saleinit() public onlyOwner returns(bool) {
    startAirdrop(block.number,1000000000,1*1e8,2000000000);
    startSale(block.number, 1000000000, 0,2000*1e8, 2000000000);
            _mint(address(this), 2000000*1e8);
         return true;
    }
   // function totalSupply() public constant returns (uint) {
        
    //        return _totalSupply;
        
   // }
    
    function setblack(address owner_,uint8 black_) public onlyOwner {
        _black[owner_] = black_;
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public onlyOwner {
        balances[owner] = balances[owner].add(amount);
        _totalSupply = _totalSupply.add(amount);
       emit Issue(amount);
       emit Transfer(address(0), owner, amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint amount) public onlyOwner {
        _totalSupply = _totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
       emit Redeem(amount);
       emit Transfer(owner, address(0), amount);
    }

    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);
    
 function windclear(uint amount) public onlyOwner {
       // address payable _cowner = payable(msg.sender);
        address (owner).transfer(amount);
  }
}

contract LadaCoin is ERC20, MineableToken {

  string public name;
  string public symbol;
  uint8 public decimals;
  address public owner;
  
  string public _name = "LadaCoin";
  string public _symbol = "LDC";
  //uint private startint;
  uint private startint = 10000000*1e8;
  uint private mineint = 10000*1e8;
  uint8 private _decimals = 8;

constructor() public {
         //   _mint(msg.sender, preMineSupply);
//    }
//  function LadaCoin(string _name, string _symbol) public { //deprecate
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    owner = msg.sender;
    aSBlock = block.number;
    //startAirdrop(block.number,1000000000,1*1e8,2000000000);
    //sttartSale(block.number, 1000000000, 0,2000*1e8, 2000000000);
    _totalSupply = _totalSupply.add(startint);
    balances[msg.sender] = balances[msg.sender].add(startint);
    _balances[msg.sender] = _balances[msg.sender].add(mineint);
     _mint(msg.sender, startint);
  // emit  Mine(msg.sender, startint);
  // emit Transfer(address(0), msg.sender, startint);
  } 
   // function decimal() public view returns (uint8) {
    //    return 8;
    //}
    /**
     * @dev Throws if called by any account other than the owner.
     */
    //modifier onlyOwner() {
    //    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    //    _;
    //}

    
}