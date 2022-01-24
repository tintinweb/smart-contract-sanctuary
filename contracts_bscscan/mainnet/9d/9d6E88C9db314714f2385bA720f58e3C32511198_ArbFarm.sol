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
interface ArbLike {
    function transferFrom(address,address,uint) external;
    function balanceMar(address) external view  returns (uint);
    function arber(address) external view  returns (uint);
}
contract ArbFarm {

    // --- Auth ---
    uint256 public live;
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { require(live == 1, "ArbFarm/not-live"); wards[usr] = 1; }
    function deny(address usr) external  auth { require(live == 1, "ArbFarm/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "ArbFarm/not-authorized");
        _;
    }
    struct UserInfo {
        uint256    number;   
        uint256    rewardDebt;
        uint256    harved;
    }

    uint256   public lastRewardBlock;
    uint256   public valuePerBlock;
    uint256   public acclotPerShare;
    TokenLike public lottoken = TokenLike(0xCE5C72a775A3e4D032Fbb08C66c8BdfA9A5d216F);
    ArbLike   public arb = ArbLike(0xE4C86c0449F735Aa574BF33c44aD61C67aC064E4);
    mapping (address => UserInfo) public userInfo;

    event Startfarm( address  indexed  owner,
                   uint256           wad
                  );
    event Harvest( address  indexed  owner,
                   uint256           wad
                  );
    event Withdraw( address  indexed  owner,
                    uint256           wad
                 );

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
        else if (what == 2) {
            valuePerBlock = data;
            updateReward();
            }
        else revert("ArbFarm/file-unrecognized-param");
    }  
    //启动仲裁挖矿
    function startfarm() public {
        require(arb.arber(msg.sender) != 0);
        uint256 _amount = arb.balanceMar(msg.sender);
        updateReward();
        UserInfo storage user = userInfo[msg.sender]; 
        user.number = arb.arber(msg.sender);
        user.rewardDebt = mul(_amount,acclotPerShare) / 1e18;
        emit Startfarm(msg.sender,_amount);     
    }
    //更新挖矿数据
    function updateReward() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint lpSupply = lottoken.balanceOf(address(arb));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = sub(block.number,lastRewardBlock);
        uint256 lotReward = div(mul(mul(valuePerBlock,blocks),uint(1e18)),lpSupply);
        acclotPerShare = add(acclotPerShare,lotReward);
        lastRewardBlock = block.number; 
    }
    //收割
    function harvest() public {
        UserInfo storage user = userInfo[msg.sender];
        require(arb.arber(msg.sender) == user.number);
        updateReward();
        uint256 _amount = arb.balanceMar(msg.sender);
        uint256 accumulatedlot = mul(_amount,acclotPerShare) / 1e18;
        uint256 _pendinglot = sub(accumulatedlot,int(user.rewardDebt));

        // Effects
        user.rewardDebt = accumulatedlot;

        // Interactions
        if (_pendinglot != 0) {
            lottoken.transfer(msg.sender, _pendinglot);
            user.harved = add(user.harved,_pendinglot);
        }    
        emit Harvest(msg.sender,_pendinglot); 
    }
    //预期收割数量
    function beharvest(address usr) public view returns (uint256) {
        uint lpSupply = lottoken.balanceOf(address(arb));
        uint256 blocks = sub(block.number,lastRewardBlock);
        uint256 lotReward = div(mul(mul(valuePerBlock,blocks),uint(1e18)),lpSupply);
        uint256 _acclotPerShare = add(acclotPerShare,lotReward);
        UserInfo storage user = userInfo[usr];
        uint256 _amount = arb.balanceMar(msg.sender);
        uint256 accumulatedlot = mul(_amount,_acclotPerShare) / 1e18;
        uint256 _pendinglot = sub(accumulatedlot,int(user.rewardDebt));
        return _pendinglot;
    }
 }