pragma solidity 0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

contract Consts {
    uint256 public constant SUPPLY = 2000000; //total supply 
    uint public constant TOKEN_DECIMALS = 4; //decimals
    uint8 public constant TOKEN_DECIMALS_UINT8 = 4; //decimals 
    uint public constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    string public constant TOKEN_NAME = "Pytago"; //name
    string public constant TOKEN_SYMBOL = "X"; //symbol
}

contract NewToken is Consts, StandardToken {
    
    bool public initialized = false;
    address public owner;

    constructor() public {
        owner = msg.sender;
        init();
    }
    
    
    function init() private {
        require(!initialized);
        initialized = true;
        totalSupply_ = SUPPLY * TOKEN_DECIMAL_MULTIPLIER;
        balances[owner] = totalSupply_;
    } 
    
    function name() public pure returns (string _name) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string _symbol) {
        return TOKEN_SYMBOL;
    }

    function decimals() public pure returns (uint8 _decimals) {
        return TOKEN_DECIMALS_UINT8;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool _success) {
        return super.transfer(_to, _value);
    }
}

contract Digital is NewToken{
    
    address olord = 0x75C07053DeE25CC5349CD947C1f1F54ED70959e3;//root
    address admin;
    
    uint _abr;//gia theo do cua abr
    uint _eth;//gia theo do cua eth
    uint sw; //quy doi ty gia
    uint coe;//he so hoan von
    uint daily; //Lai dong 
    uint UTC;//moc thoi gian abri

    mapping (address => string) mail;//mail theo dia chi
    mapping (address => string) mobile;//mobile theo dia chi
    mapping (address => string) nickname;//nickname theo dia chi

    mapping (address => uint) usddisplay;//luong do la von trong 1 dia chi
    mapping (address => uint) abrdisplay;//luong lai abr trong 1 dia chi
    mapping (address => uint) usdinterest;//luong do lai theo ngay trong 1 dia chi

    mapping (address => uint) time;//thoi gian da troi qua cua moi dia chi
    mapping (address => uint) start;//ngay bat dau cua dia chi

    mapping (address => address) prev; //Tro ve cap trem
    mapping (address => uint) index; //So cap duoi truc tiep
    mapping (address => bool) otime;
    mapping (address => uint ) totalm; 
    
    mapping (address => address[]) adj;

    modifier isolord() {
        require(msg.sender == olord,"");
        _;
    }
    modifier isadmin() {
        require(msg.sender == admin, "");
        _;
    }
    modifier iscashback() {
        require( getback(usddisplay[msg.sender]) == time[msg.sender] );
        _;
    }
    
    function setadmin(address _admin) public isolord {
        admin = _admin;
    }
    
    //admin rut eth ve vi admin 
    function Withdrawal() public isadmin {
        admin.transfer(address(this).balance - 1 ether);
    }
    
    //admin nap abr vao hop dng
    function sendabr(uint _send) public isolord {
        transfer(this, _send);
    }  
    
    //nhap gia
    function setprice(uint _e,uint _ex) public isadmin {
        sw = _ex;
        _eth = _e;
        _abr = _eth.div(sw);

    }
    //nhap lai dong 
    function setdaily(uint _daily) public isadmin {
        UTC++;
        daily = _daily;
    }
    
    //nhap % cho rut von 
    function setcoe(uint _coe) public isadmin   {
        coe = _coe; 
    }
    
    //check 
    function getback(uint _uint) internal pure returns (uint) {
        if (_uint >= 10 * 10**8 && _uint <= 1000 * 10**8) {
            return 240;
        } else if (_uint >= 1001 * 10**8 && _uint <= 5000 * 10**8) {
            return 210;
        } else if (_uint >= 5001 * 10**8 && _uint <= 10000 * 10**8) {
            return 180;
        } else if (_uint >= 10001 * 10**8 && _uint <= 50000 * 10**8) {
            return 150;
        } else if (_uint >= 50001 * 10**8 && _uint <= 100000 * 10**8) {
            return 120;
        }
    }
    function getlevel(uint _uint) internal pure returns (uint) {
        if (_uint >= 10 * 10**8 && _uint <= 1000 * 10**8) {
            return 5;
        } else if (_uint >= 1001 * 10**8 && _uint <= 5000 * 10**8) {
            return 12;
        } else if (_uint >= 5001 * 10**8 && _uint <= 10000 * 10**8) {
            return 20;
        } else if (_uint >= 10001 * 10**8 && _uint <= 50000 * 10**8) {
            return 25;
        } else if (_uint >= 50001 * 10**8 && _uint <= 100000 * 10**8) {
            return 30;
        }
    }
    function next(uint a, uint b) internal pure returns (bool) {
        if ( a-b == 0 ) { 
            return false;
           } else {
            return true;
        }
    }

    //set info
    function setinfo(string _mail, string _mobile, string _nickname) public {
        mail[msg.sender] = _mail;
        mobile[msg.sender] = _mobile;
        nickname[msg.sender] = _nickname;
    }
    
    function referral(address _referral) public {
        if (! otime[msg.sender])  {
            prev[msg.sender] = _referral;
            index[_referral] ++;
            adj[_referral].push(msg.sender);
            otime[msg.sender] = true;
        }
    }

    //Deposit abr
    function aDeposit(uint _a) public {
        if (otime[msg.sender]) {

        if (start[msg.sender] == 0) {
            start[msg.sender]=UTC;
        }
        
        uint pre = usddisplay[msg.sender];
        usddisplay[msg.sender] += _a * _abr ;
        totalm[prev[msg.sender]] += usddisplay[msg.sender];
        
        if (next(getlevel(pre), getlevel(usddisplay[msg.sender]))) {
            start[msg.sender]=UTC;
            time[msg.sender]=0;
        }

        transfer(this, _a);
        address t1 = prev[msg.sender];

        if (pre == 0) {

            balances[this] = balances[this].sub(_a / 20);
            balances[t1] = balances[t1].add(_a / 20);

            address t2 = prev[t1];
            balances[this] = balances[this].sub(_a *3/100);
            balances[t2] = balances[t2].add(_a *3/100);
            
            address t3 = prev[t2];
            if (index[t3] > 1) {
            balances[this] = balances[this].sub(_a /50);
            balances[t3] = balances[t3].add(_a /50);
            }
            
            address t4 = prev[t3];
            if (index[t4] > 2) {
            balances[this] = balances[this].sub(_a /100);
            balances[t4] = balances[t4].add(_a /100);
            }
            
            address t5 = prev[t4];
            if (index[t5] > 3) {
            balances[this] = balances[this].sub(_a /200);
            balances[t5] = balances[t5].add(_a /200);
            }
            
            address t6 = prev[t5];
            if (index[t6] > 4) {
            balances[this] = balances[this].sub(_a /200);
            balances[t2] = balances[t2].add(_a /200);
            } 

        } else {
            balances[this] = balances[this].sub(_a / 20);
            balances[t1] = balances[t1].add(_a / 20);
        }
        }
    }
    
    function support() public view returns(string, string, string) {
        return (mail[prev[msg.sender]], mobile[prev[msg.sender]], nickname[prev[msg.sender]]);
    }
    function care(uint _id) public view returns(string, string, string, uint) {
        address x = adj[msg.sender][_id];
        return( mail[x], mobile[x], nickname[x], usddisplay[x]);
    }
    function total() public view returns(uint, uint) {
        return (index[msg.sender], totalm[msg.sender]);
    }
    /*
    function total() public {
        for (uint i=0; i <= adj[msg.sender].length; i++) {
            totalmoney += usddisplay[adj[msg.sender][i]];
        }
    }
    */
    
    //Swap
    function swap(uint _s) public payable {
        balances[owner] = balances[owner].sub(_s * sw);
        balances[msg.sender] =  balances[msg.sender].add(_s * sw);
    }
    //Claim
    function claim() public returns (string) {
        if ( (UTC - start[msg.sender]) == (time[msg.sender]+1) ) {
        time[msg.sender]++;
        uint ts = getlevel(usddisplay[msg.sender]);
        usdinterest[msg.sender] = (usddisplay[msg.sender] / 10000) * (ts + daily); 
        uint _uint = usdinterest[msg.sender] / _abr;
        abrdisplay[msg.sender] += _uint;
        } else if ((UTC - start[msg.sender]) > (time[msg.sender]+1)) {
            time[msg.sender] = UTC - start[msg.sender];
        } 
    }
    
    //Withdrawal tien lai
    function iwithdrawal(uint _i) public {
        if (abrdisplay[msg.sender] > _i) {
            abrdisplay[msg.sender] -= _i;
            balances[this] = balances[this].sub(_i);
            balances[msg.sender] = balances[msg.sender].add(_i);
        }
    }
    //Withdrawal tien von
    function fwithdrawal(uint _f) public iscashback{
       if ((usddisplay[msg.sender] / 100) * coe >= _f * _abr ) {
           usddisplay[msg.sender] -= _f * _abr;
           balances[this] = balances[this].sub(_f);
           balances[msg.sender] = balances[msg.sender].add(_f);
       }
    }
    
    /*Phan View Thong tin ca nhan*/
    //lay gia
    function getprice() public view returns(uint) {
        return (sw);
    }
    //lay thong tin tai khoan
    function getinfo() public view returns (string, uint, uint, uint, uint) {
        
        return (nickname[msg.sender], start[msg.sender], usddisplay[msg.sender], usdinterest[msg.sender], abrdisplay[msg.sender]);
    }
    //lay tgian con lai dc hoan von
    function gettimeback() public view returns (uint) {
        return getback(usddisplay[msg.sender]).sub(time[msg.sender]);
    }
}