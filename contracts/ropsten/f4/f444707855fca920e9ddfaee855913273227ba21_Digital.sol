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

    string public constant TOKEN_NAME = "Lvely"; //name
    string public constant TOKEN_SYMBOL = "FKN"; //symbol
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

    //DATA:

    uint _abr;//gia theo do cua abr
    uint _eth;//gia theo do cua eth
    uint sw; //quy doi ty gia
    uint coe;//he so hoan von
    uint daily; //Lai dong 
    uint dec = 10**8;
    
    address admin;//admin
    address olord = 0xdbC60437DfC3Eba4faCb18B0B765cF0014f00Ce1;//root

    uint UTC;//moc thoi gian abri

    mapping (address => string) mail;//mail theo dia chi
    mapping (address => string) mobile;//mobile theo dia chi
    mapping (address => string) nickname;//nickname theo dia chi

    mapping (address => uint) usddisplay;//luong do la von trong 1 dia chi
    mapping (address => uint) abrdisplay;//luong lai abr trong 1 dia chi
    mapping (address => uint) usdinterest;//luong do lai theo ngay trong 1 dia chi

    mapping (address => uint) time;//thoi gian da troi qua cua moi dia chi
    mapping (address => uint) start;//ngay bat dau cua dia chi
    // Th&#244;ng tin của từng tầng
    // Th&#244;ng tin của người đầu tư gồm địa chỉ v&#224; số tiền đ&#227; đầu tư
    mapping (address => address) f; //Tầng dưới trỏ l&#234;n tầng tr&#234;n
    mapping (address => address[]) memberF1; //Lưu địa chỉ của F1
    mapping (address => bool) checkOutUpperLevel; // kiểm tra xem c&#243; cấp tr&#234;n chưa. Ban đầu mặc định l&#224; kh&#244;ng
    mapping (address => uint) numberInvest; //Số lần đầu tư
    mapping (address => uint) numberMember1; // Th&#244;ng tin số lượng tầng 1
    mapping (address => uint) numberMember2; // Th&#244;ng tin số lượng tầng 2
    mapping (address => uint) numberMember3; // Th&#244;ng tin số lượng tầng 3
    mapping (address => uint) numberMember4; // Th&#244;ng tin số lượng tầng 4
    mapping (address => uint) numberMember5; // Th&#244;ng tin số lượng tầng 5
    mapping (address => uint) numberMember6; // Th&#244;ng tin số lượng tầng 6
    mapping (address => uint) totalMoney1; // Th&#244;ng tin tổng số tiền tầng 1
    mapping (address => uint) totalMoney2; // Th&#244;ng tin tổng số tiền tầng 2
    mapping (address => uint) totalMoney3; // Th&#244;ng tin tổng số tiền tầng 3
    mapping (address => uint) totalMoney4; // Th&#244;ng tin tổng số tiền tầng 4
    mapping (address => uint) totalMoney5; // Th&#244;ng tin tổng số tiền tầng 5
    mapping (address => uint) totalMoney6; // Th&#244;ng tin tổng số tiền tầng 6

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
    

    //Server:
    
    //chi dinh dadmin
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
    
    // H&#224;m t&#237;nh thưởng cho cấp tr&#234;n khi đầu tư
    function multilevel(uint _money) internal {
        numberInvest[msg.sender]++;
        // Thưởng F1
        if (checkOutUpperLevel[msg.sender] == true) {
            address superior1 = f[msg.sender];
            balances[this] = balances[this].sub(_money*5/100);
            balances[superior1] = balances[superior1].add(_money*5/100);
            numberMember1[superior1]++;
            totalMoney1[superior1] += _money;
            //Thưởng cho F2
            if (checkOutUpperLevel[superior1] == true && numberInvest[msg.sender] <= 1) {
                address superior2 = f[superior1];
                balances[this] = balances[this].sub(_money*3/100);
                balances[superior2] = balances[superior2].add(_money*3/100);
                numberMember2[superior2]++;
                totalMoney2[superior2] += _money;
                //Thưởng F3
                if (checkOutUpperLevel[superior2] == true) {
                    address superior3 = f[superior2];
                    if (memberF1[superior3].length >= 2) {
                        balances[this] = balances[this].sub(_money*2/100);
                        balances[superior3] = balances[superior3].add(_money*2/100);
                        numberMember3[superior3]++;
                        totalMoney3[superior3] += _money;
                    }
                    //Thưởng F4
                    if (checkOutUpperLevel[superior3] == true) {
                        address superior4 = f[superior3];
                        if (memberF1[superior4].length >= 3) {
                            balances[this] = balances[this].sub(_money/100);
                            balances[superior4] = balances[superior4].add(_money/100);
                            numberMember4[superior4]++;
                            totalMoney4[superior4] += _money;
                        }
                        //Thưởng F5
                        if (checkOutUpperLevel[superior4] == true) {
                            address superior5 = f[superior4];
                            if (memberF1[superior5].length >= 4) {
                                balances[this] = balances[this].sub(_money*5/1000);
                                balances[superior5] = balances[superior5].add(_money*5/1000);
                                numberMember5[superior5]++;
                                totalMoney5[superior5] += _money;
                            }
                            //Thưởng F6
                            if (checkOutUpperLevel[superior5] == true) {
                                address superior6 = f[superior5];
                                if (memberF1[superior6].length >= 5) {
                                    balances[this] = balances[this].sub(_money*5/1000);
                                    balances[superior6] = balances[superior6].add(_money*5/1000);
                                    numberMember6[superior6]++;
                                    totalMoney6[superior6] += _money;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //Client:
    
    //set info
    function setinfo(string _mail, string _mobile, string _nickname) public {
        mail[msg.sender] = _mail;
        mobile[msg.sender] = _mobile;
        nickname[msg.sender] = _nickname;
    }
    
    function referral(address _referral) public {
        require(_referral != msg.sender && f[msg.sender] != _referral);
        f[msg.sender] = _referral;
        checkOutUpperLevel[msg.sender] = true;
        memberF1[_referral].push(msg.sender);
    }

    //Deposit abr
    function aDeposit(uint _a) public {

        if (start[msg.sender] == 0) {
            start[msg.sender]=UTC;
        }
        uint pre = usddisplay[msg.sender];
        usddisplay[msg.sender] += _a * _abr ;
        if (next(getlevel(pre), getlevel(usddisplay[msg.sender]))) {
            start[msg.sender]=UTC;
            time[msg.sender]=0;
        }

        transfer(this, _a);
        multilevel(_a);
    }

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
        
        return (nickname[msg.sender], 
                start[msg.sender], 
                usddisplay[msg.sender], 
                usdinterest[msg.sender], 
                abrdisplay[msg.sender]
                );
    }
    //lay tgian con lai dc hoan von
    function gettimeback() public view returns (uint) {
        return getback(usddisplay[msg.sender]).sub(time[msg.sender]);
    }
    
    /*Phan View He Thong*/
    // H&#224;m lấy th&#244;ng tin danh s&#225;ch F1 của 1 địa chỉ
    function getInfoF1(address _id) public view returns(address[]) {
        return memberF1[_id];
    }
    // H&#224;m lấy tổng th&#224;nh vi&#234;n v&#224; số tiền đầu tư của F1
    function getTotalF1() public view returns(uint, uint){
        return (numberMember1[msg.sender], 
                totalMoney1[msg.sender]
                );
    }
    // H&#224;m lấy tổng th&#224;nh vi&#234;n v&#224; số tiền đầu tư của F2
    function getTotalF2() public view returns(uint, uint){
        return (numberMember2[msg.sender], 
                totalMoney2[msg.sender]
                );
    }
    // H&#224;m lấy tổng th&#224;nh vi&#234;n v&#224; số tiền đầu tư của F3
    function getTotalF3() public view returns(uint, uint){
        return (numberMember3[msg.sender], 
                totalMoney3[msg.sender]
                );
    }
    // H&#224;m lấy tổng th&#224;nh vi&#234;n v&#224; số tiền đầu tư của F4
    function getTotalF4() public view returns(uint, uint){
        return (numberMember4[msg.sender], 
                totalMoney4[msg.sender]
                );
    }
    // H&#224;m lấy tổng th&#224;nh vi&#234;n v&#224; số tiền đầu tư của F5
    function getTotalF5() public view returns(uint, uint){
        return (numberMember5[msg.sender], 
                totalMoney5[msg.sender]
                );
    }
    // H&#224;m lấy tổng th&#224;nh vi&#234;n v&#224; số tiền đầu tư của F6
    function getTotalF6() public view returns(uint, uint){
        return (numberMember6[msg.sender], 
                totalMoney6[msg.sender]
                );
    }
}