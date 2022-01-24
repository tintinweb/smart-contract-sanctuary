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
contract LpFarm {

    // --- Auth ---
    uint256 public live;
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { require(live == 1, "LpFarm/not-live"); wards[usr] = 1; }
    function deny(address usr) external  auth { require(live == 1, "LpFarm/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "LpFarm/not-authorized");
        _;
    }
    struct UserInfo {
        uint256    amount;   
        uint256    rewardDebt;
        uint256    harved;
    }

    uint256   public lastRewardBlock;
    uint256   public valuePerBlock;
    uint256   public acclotPerShare;
    uint256   public mindepo;
    TokenLike public token;
    TokenLike public lptoken;

    mapping (address => UserInfo) public userInfo;


    event Deposit( address  indexed  owner,
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
        else if (what == 3) mindepo = data;
        else revert("LpFarm/file-unrecognized-param");
    }  
    function setToken(uint what, address _token) external auth {
        if (what == 1) token = TokenLike(_token);
        else if (what == 2) lptoken = TokenLike(_token);
        else revert("LpFarm/file-unrecognized-param");
    } 
    //质押
    function deposit(uint _amount) public {
        require(_amount >= mindepo);
        updateReward();
        lptoken.transferFrom(msg.sender, address(this), _amount);
        UserInfo storage user = userInfo[msg.sender]; 
        user.amount = add(user.amount,_amount); 
        user.rewardDebt = add(user.rewardDebt,int256(mul(_amount,acclotPerShare) / 1e18));
        emit Deposit(msg.sender,_amount);     
    }
    //更新挖矿数据
    function updateReward() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint lpSupply = lptoken.balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = sub(block.number,lastRewardBlock);
        uint256 lotReward = div(mul(mul(valuePerBlock,blocks),uint(1e18)),lpSupply);
        acclotPerShare = add(acclotPerShare,lotReward);
        lastRewardBlock = block.number; 
    }
    //收割挖矿所得
    function harvest() public {
        updateReward();
        UserInfo storage user = userInfo[msg.sender];
        uint256 accumulatedlot = mul(user.amount,acclotPerShare) / 1e18;
        uint256 _pendinglot = sub(accumulatedlot,int(user.rewardDebt));

        // Effects
        user.rewardDebt = accumulatedlot;

        // Interactions
        if (_pendinglot != 0) {
            token.transfer(msg.sender, _pendinglot);
            user.harved = add(user.harved,_pendinglot);
        }    
        emit Harvest(msg.sender,_pendinglot); 
    }
    //提现质押币
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender]; 
        require(_amount >= mindepo || _amount==user.amount && _amount>0);
        updateReward();
        user.rewardDebt = sub(user.rewardDebt,int(mul(_amount,acclotPerShare) / 1e18));
        user.amount = sub(user.amount,_amount);
        lptoken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender,_amount);     
    }
    //预估收割
    function beharvest(address usr) public view returns (uint256) {
        uint lpSupply = lptoken.balanceOf(address(this));
        uint256 blocks = sub(block.number,lastRewardBlock);
        uint256 lotReward = div(mul(mul(valuePerBlock,blocks),uint(1e18)),lpSupply);
        uint256 _acclotPerShare = add(acclotPerShare,lotReward);
        UserInfo storage user = userInfo[usr];
        uint256 accumulatedlot = mul(user.amount,_acclotPerShare) / 1e18;
        uint256 _pendinglot = sub(accumulatedlot,int(user.rewardDebt));
        return _pendinglot;
    }
 }