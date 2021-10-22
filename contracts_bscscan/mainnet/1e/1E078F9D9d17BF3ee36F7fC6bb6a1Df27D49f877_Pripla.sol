/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

pragma solidity >=0.4.23;

interface TokenLike {
    function transferFrom(address,address,uint) external;
    function transfer(address,uint) external;
}

contract Pripla  {
    
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "prip/not-authorized");
        _;
    }

    mapping (address => uint256)                      public  order;                 //每次质押编号
    mapping (address =>mapping(uint256 => uint256))   public  balanceLo;             //用户每次质押金额
    mapping (address =>mapping(uint256 => uint256))   public  ptime;                 //每次质押开始时间
    mapping (address => mapping(uint256 => uint256))  public  eta;                   //每次质押锁仓时间
    mapping (uint256 => mapping(uint256 => uint256))  public  arr;                   //年化收益率
    uint256                                           public  interest;              //利息总余额
    uint256                                           public  date1;                 //第一次减半时间
    uint256                                           public  date2;                 //第二次减半时间
    TokenLike                                         public  sx;                    //sx地址
    
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    
    
    constructor(address _sx) public {
        sx = TokenLike(_sx);
        wards[msg.sender] = 1;
    }

    // --- Math ---
    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    
    //--- Pripla ---
     // 设置年化收益率
    function setarr(uint256 stage, uint256 cycle,uint256 _arr) public auth {
        arr[cycle][stage] = _arr;
    }
     // 设置减半周期
    function halve(uint256 _date1, uint256 _date2) public auth {
        date1=_date1;
        date2=_date2;
    }
     // 利息转入
    function deposit(uint256 wad) public auth {
        sx.transferFrom(msg.sender, address(this), wad);
        interest += wad;
    }
    //质押转入，@_eta质押锁仓时间
    function pledge(uint256 wad, uint256 _eta) external returns (bool)
    {
        sx.transferFrom(msg.sender, address(this), wad);
        order[msg.sender] +=1;
        eta[msg.sender][order[msg.sender]] = _eta;
        ptime[msg.sender][order[msg.sender]] = block.timestamp;
        balanceLo[msg.sender][order[msg.sender]] = wad;
        emit Transfer(msg.sender, address(this), wad);
        return true;
    }
    //用户提现
    function withdraw(uint i) external returns (bool) {
        uint256  _eta = eta[msg.sender][i]; 
        uint256  _ptime = ptime[msg.sender][i];
        uint256  lte = sub(block.timestamp, _ptime);
        uint256  _wad = balanceLo[msg.sender][i];
        if (lte > _eta) {
            uint256 unc = profit(msg.sender, i);
            balanceLo[msg.sender][i] = 0;
            interest = sub(interest,unc);
            sx.transfer(msg.sender, add(_wad,unc));
            emit Transfer(address(this), msg.sender, add(_wad,unc));
            return true;
        }else return false;       
    }
    //利息查询
    function profit(address usr, uint i) public view returns (uint256) {
        uint256  _eta = eta[usr][i]; 
        uint256  _ptime = ptime[usr][i];
        uint256  lte = sub(block.timestamp, _ptime);
        uint256  _wad = balanceLo[usr][i];
        uint256 unc = 0;
        if (_ptime < date1)
            {if (block.timestamp< date1) {   
                unc = mul(mul(_wad,arr[_eta][0]),lte)/uint256(31536000000);
            }if (block.timestamp > date1 && block.timestamp < date2) {
                uint256 unc1 = mul(mul(_wad,arr[_eta][0]),sub(date1, _ptime))/uint256(31536000000);
                uint256 unc2 = mul(mul(_wad,arr[_eta][1]),sub(block.timestamp, date1))/uint256(31536000000);
                unc = add(unc1, unc2);
            }if (block.timestamp > date2) {
                uint256 unc1 = mul(mul(_wad,arr[_eta][0]),sub(date1, _ptime))/uint256(31536000000);
                uint256 unc2 = mul(mul(_wad,arr[_eta][1]),sub(date2,date1))/uint256(31536000000);
                uint256 unc3 = mul(mul(_wad,arr[_eta][2]),sub(block.timestamp, date2))/uint256(31536000000);
                unc = add(add(unc1, unc2), unc3);
            }
        } 
        if (_ptime > date1 && _ptime < date2)
            {if (block.timestamp< date2) {   
                unc = mul(mul(_wad,arr[_eta][1]),lte)/uint256(31536000000);
            }if (block.timestamp > date2) {
                uint256 lte1 = sub(date2, _ptime);
                uint256 lte2 = sub(block.timestamp, date2);
                uint256 unc1 = mul(mul(_wad,arr[_eta][1]),lte1)/uint256(31536000000);
                uint256 unc2 = mul(mul(_wad,arr[_eta][2]),lte2)/uint256(31536000000);
                unc = add(unc1, unc2);
            }
        }
        if (_ptime > date2)
            {if (block.timestamp< date2) {   
                unc = mul(mul(_wad,arr[_eta][2]),lte)/uint256(31536000000);
            }
        }        
        return unc;   
    }
}