/**
 *Submitted for verification at BscScan.com on 2021-10-18
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
    
    bytes32                                           public  symbol = "pGAZ";
    uint256                                           public  decimals = 18;         
    bytes32                                           public  name = "prip_gaz";  
    mapping (address => mapping (address => uint256)) public  allowance;     
    mapping (address => uint256)                      public  balanceOf;             //User lock balance
    uint256                                           public  totalSupply = 63000000 * 10 ** 18;
    
    mapping (address =>mapping(uint256 => uint256))   public  balanceLo;             //User's private placement amount per round
    TokenLike                                         public  gaz;                   //Platform currency address
    address                                           public  fund;                  //Private token storage address
    mapping (address => uint256)                      public  bud;                   //White list address
    uint256                                           public  ltim;                  //Private placement release start time
    mapping (address => uint256)                      public  order;                 //Number of each round of private placement
    mapping (address => mapping(uint256 => uint256))  public  eta;                   //Lock up time of each round of private placement
    
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    
    
    constructor(address _gaz) public {
        gaz = TokenLike(_gaz);
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
    
    //--- ERC20 ---
    function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(bud[dst] == 1 || bud[msg.sender] == 1, "prip/not-white");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "prip/insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        require(balanceOf[src] >= wad, "prip/insufficient-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    
    //--- Pripla ---
    // Set private token storage address
    function setust(address ust) external auth {
        fund = ust;
    } 
    
    //Private token distribution, @ _ETA closing time of this round of private placement
    function prip(address dst, uint256 wad, uint256 _eta) external auth returns (bool)
    {
        gaz.transferFrom(fund, address(this), wad);
        order[dst] +=1;
        eta[dst][order[dst]] = _eta;
        balanceLo[dst][order[dst]] = wad;
        balanceOf[dst] += wad;
        emit Transfer(address(this), dst, wad);
        return true;
    }
    //Withdrawal amount must be less than the withdrawable balance
    function withdraw(uint wad) external returns (bool) {
        require(ltim != 0, "prip/Release has not been activated yet");
        require(balanceOf[msg.sender] >= wad, "prip/insufficient-balance");
        require(wad <= callfree(msg.sender),"prip/insufficient-lock");
        balanceOf[msg.sender] = sub(balanceOf[msg.sender],wad);
        gaz.transfer(msg.sender, wad);
        emit Transfer(msg.sender, address(this), wad);
        return true;
    }
    //Query withdrawable balance
    function callfree(address usr) public view returns (uint256) {
        if (ltim == 0 )  return 0;
        uint256 lock ; 
        //Calculate the sum of the number of locks in each round of private placement  
        for (uint i = order[usr]; i >0; i--) {
            uint256  lti = eta[usr][i]; 
            int256  lte = int256(lti-sub(now,ltim));
            if (lte > 0 )
            {   uint256 unc = mul(uint256(lte),balanceLo[usr][i])/lti;
                lock = add(lock,unc);
            }
        }   
        if (balanceOf[usr] > lock) return sub(balanceOf[usr],lock);
        if (balanceOf[usr] <= lock) return 0;   
    }
    //Set release start time
    function cage() external  auth returns (bool) {
        if (ltim == 0) ltim = now;
        else if (ltim != 0) ltim = 0;
        return true;
    }
    //Set white list
    function kiss(address a) external  auth returns (bool) {
        require(a != address(0), "prip/no-contract-0");
        bud[a] = 1;
        return true;
    }
    //Cancel white list
    function diss(address a) external  auth returns (bool) {
         bud[a] = 0;
         return true;
    }
}