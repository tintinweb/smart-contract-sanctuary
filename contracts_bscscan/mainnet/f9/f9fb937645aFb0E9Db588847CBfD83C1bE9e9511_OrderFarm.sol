/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
interface TokenLike {
    function transferFrom(address,address,uint) external;
    function transfer(address,uint) external;
    function balanceOf(address) external view  returns (uint);
}
interface DotcLike {
    function merch(uint256) external view returns (uint256,bytes32,bytes32,address,uint256,uint256,uint256,bytes32,uint256,uint256,uint256);
    function pros(bytes32) external view returns (uint256,address,uint256,uint256,uint256,uint256);
    function lockpro(address,address) external view  returns (uint);
    function order() external view  returns (uint);
}
contract OrderFarm {

    // --- Auth ---
    uint256 public live;
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { require(live == 1, "OrderFarm/not-live"); wards[usr] = 1; }
    function deny(address usr) external  auth { require(live == 1, "OrderFarm/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "OrderFarm/not-authorized");
        _;
    }
    
    mapping (address => uint) public mint;
    uint256   public lastRewardBlock;
    uint256   public length;
    uint256   public valuePerBlock;
    uint256   public norm;
    uint256   public intervaltime;
    TokenLike public gaz = TokenLike(0xCE5C72a775A3e4D032Fbb08C66c8BdfA9A5d216F);
    DotcLike   public dotc = DotcLike(0xe11c7fFac8A33a504bAaA2f9A6eF56C9B8980B0A);

    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
        return c;
      }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function file(uint what, uint256 data) external auth {
        if (what == 1) lastRewardBlock = data;
        else if (what == 2) valuePerBlock = data;
        else if (what == 3) length = data;
        else if (what == 4) norm = data;
        else if (what == 5) intervaltime = data;
        else revert("OrderFarm/file-unrecognized-param");
    } 
    //总挂单价值 
    function getvalue( ) public view returns (uint256) {
        uint256 max = dotc.order();
        uint256 totalvalue;
        for (uint i = max; i >= max-length ; --i) {
           (,bytes32 mark,bytes32 pro,,uint256 wad,,,,,,)= dotc.merch(i);
           (uint256 uni,,,uint256 one,,)= dotc.pros(pro);
            if (wad>0 && mark =="sale") {
                uint256 value = mul(wad,uni)/10**one;
                totalvalue += value;
            }
        }
        return totalvalue;
    }
    //收割，为每个挂单分配收益，并获取收割奖励
    function harvest() public{
        require (live ==1);
        require (block.timestamp >= lastRewardBlock + intervaltime);
        uint256 max = dotc.order();
        uint256 lotReward=updateReward();
        uint256 j;
        for (uint i = max; i >= max-length ; --i) {
            (,bytes32 mark,bytes32 pro,address mad,uint256 wad,,,,,,)= dotc.merch(i);
            (uint256 uni,,,uint256 one,,)= dotc.pros(pro);
            if (wad>0 && mark =="sale") {
                uint256 value = mul(wad,uni)/10**one;
                uint256 amount = mul(value,lotReward)/1e6;
                mint[mad] += amount;
                j +=1;
               }
            }
        uint256 _amount = mul(norm,j);
        gaz.transfer(msg.sender, _amount);
    }
    //计算单位价值挖矿收益
    function updateReward() internal returns (uint256) {
        uint lpSupply = getvalue( );
        uint256 blocks = sub(block.timestamp,lastRewardBlock);
        uint256 lotReward = div(mul(mul(valuePerBlock,blocks),uint(1e6)),lpSupply);
        lastRewardBlock = block.timestamp; 
        return lotReward;
    }
    function withdraw() public {
        uint256 amount = mint[msg.sender];
        mint[msg.sender] = 0;
        gaz.transfer(msg.sender, amount);   
    }
    function cage() external auth {
       if (live == 0) live = 1;
       else live = 0;
    }
    //预估账户每个币种的当前收益
    function befarm(bytes32[] calldata pro, address ust) public view returns (uint256[] memory){
        uint256 lpSupply = getvalue( );
        uint256 blocks = sub(block.timestamp,lastRewardBlock);
        uint256 lotReward = div(mul(mul(valuePerBlock,blocks),uint(1e6)),lpSupply);
        uint256[] memory farm = new uint256[](pro.length);
        for (uint i = 0; i < pro.length ; ++i) {
            bytes32 _pro = pro[i];
            (uint256 uni,address token,,uint256 one,,)= dotc.pros(_pro);
            uint256 wad = dotc.lockpro(ust,token);
            uint256 value = mul(wad,uni)/10**one;
            uint256 amount = mul(value,lotReward)/1e6;
            farm[i] = amount;
        }
       return farm;
    }
    //预估合格的订单数
    function beorder() public view returns (uint256) {
        uint256 max = dotc.order();
        uint256 j;
        for (uint i = max; i >= max-length ; --i) {
            (,bytes32 mark,,,uint256 wad,,,,,,)= dotc.merch(i);
            if (wad>0 && mark =="sale") {
                j +=1;
            }
        }
        return j;
    }
 }