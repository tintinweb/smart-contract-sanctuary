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
    function users(uint256) external view returns (uint256,bytes32,bytes32,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function pros(bytes32) external view returns (uint256,address,uint256,uint256,uint256,uint256);
    function uorder() external view  returns (uint);
}
contract SwapFarm {

    // --- Auth ---
    uint256 public live;
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { require(live == 1, "SwapFarm/not-live"); wards[usr] = 1; }
    function deny(address usr) external  auth { require(live == 1, "SwapFarm/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "SwapFarm/not-authorized");
        _;
    }
    
    mapping (address => uint) public mint;
    uint256   public lastRewardBlock;
    uint256   public valuePerBlock;
    uint256   public norm;
    uint256   public intervaltime;
    uint256   public lastorder;
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
        else if (what == 3) norm = data;
        else if (what == 4) intervaltime = data;
        else revert("SwapFarm/file-unrecognized-param");
    } 
    //总挂单价值 
    function getvalue( ) public view returns (uint256) {
        uint256 max = dotc.uorder();
        uint256 totalvalue;
        for (uint i = max; i > lastorder ; --i) {
           (,,bytes32 pro,,,,,uint256 wad,,uint256 rel,,)= dotc.users(i);
           (uint256 uni,,,uint256 one,,)= dotc.pros(pro);
            if (rel>0) {
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
        uint256 max = dotc.uorder();
        uint256 lotReward=updateReward();
        for (uint i = max; i > lastorder ; --i) {
            (,,bytes32 pro,address uad,address mad,,,uint256 wad,,uint256 rel,,)= dotc.users(i);
            (uint256 uni,,,uint256 one,,)= dotc.pros(pro);
            if (rel>0) {
                uint256 value = mul(wad,uni)/10**one;
                uint256 amount = mul(value,lotReward)/1e6;
                mint[uad] += amount;
                mint[mad] += amount;
               }
            }
        uint256 _amount = mul(norm,sub(max,lastorder));
        lastorder = max;
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
    //预估每个订单的挖矿收益
    function befarm(uint256 i) public view returns (uint256){
        uint256 lpSupply = getvalue( );
        uint256 blocks = sub(block.timestamp,lastRewardBlock);
        uint256 lotReward = div(mul(mul(valuePerBlock,blocks),uint(1e6)),lpSupply);
        (,,bytes32 pro,,,,,uint256 wad,,,,)= dotc.users(i);
        (uint256 uni,,,uint256 one,,)= dotc.pros(pro);
        uint256 value = mul(wad,uni)/10**one;
        uint256 amount = mul(value,lotReward)/1e6;
        return  amount;
    }
 }