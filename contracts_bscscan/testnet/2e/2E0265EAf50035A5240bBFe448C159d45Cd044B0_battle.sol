/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

pragma solidity ^0.8.0;
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


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface hero{
  function getHeroData(uint256 tokenId) external view returns (uint256[] memory);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
interface equipment{
  function getEquipmentData(uint256 tokenId) external returns (uint256[] memory);
  function battleClaim(address userAddress) external returns(uint256,uint256[] memory);
  
}
interface token{
  function mint(address account, uint256 amount) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract battle is IERC721Receiver{
    using SafeMath for uint256;
    event SceneBattle(bool status,uint256 gold,uint256 equipmentId,uint256[] equipmentInfo);
    event TeamInfo(address user,uint256[] team);
    event ArenaBattle(bool status,uint256 gold,uint256 honor,address attack,uint256 attackHonor,address defense,uint256 defenseHonor);
    mapping(address => uint256[]) public teamData;
    hero heroContract;
    equipment equipmentContract;
    token tokenContract;

    address public heroAddress;
    address public equipmentAddress;
    address public tokenAddress;
    
    mapping(string=>bool) public arenaRecord;
    mapping(address=>uint256) public honorRecord;
    
    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
    }
    PoolInfo[] public poolInfo;
    
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    uint256 public tokenPerBlock;
    address public devaddr;
    uint256 public lpSupply;

    constructor(address hero_address,address equipment_address,address tokena_ddress) public {
        heroAddress = hero_address;
        equipmentAddress = equipment_address;
        tokenAddress = tokena_ddress;
        heroContract = hero(heroAddress);
        equipmentContract = equipment(equipmentAddress);
        tokenContract = token(tokenAddress);
        devaddr = msg.sender;
        poolInfo.push(PoolInfo({
            lpToken: tokena_ddress,
            allocPoint: 1000,
            lastRewardBlock: block.number,
            accCakePerShare: 0
        }));
    }
    
    modifier onlyUser(uint256[] memory token){
        require(token.length >= 1 && token.length <= 3, "Token Insufficient");
        for (uint256 i = 0; i < token.length; i++) {
            require( token[i]!=0 && (heroContract.ownerOf(token[i]) == msg.sender || teamHeroCheck(msg.sender,token[i]) ), "Token Invalid");
        }
        _;
    }

    function scene(uint256[] memory token,uint256 sceneId) public onlyUser(token){
        if(sceneId==2){
            uint256[] memory equipmentInfo;
            emit SceneBattle(false,0,0,equipmentInfo);
        }
        (uint256 equipmentId,uint256[] memory equipmentInfo) = equipmentContract.battleClaim(msg.sender);
        uint256 gold = 1000*1e18;
        tokenContract.mint(msg.sender,gold);
        emit SceneBattle(true,gold,equipmentId,equipmentInfo);
    }

    // function score(uint256 tokenId) public view returns(uint256){
    //     uint256[] memory heroInfo = heroContract.getHeroData(tokenId);
    //     return heroInfo[1];
    //     // uint256[] memory equipmentInfo = equipmentContract.getEquipmentData(tokenId);
    // }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function team(uint256[] memory token) public onlyUser(token){
        uint256[] memory team = teamData[msg.sender];
        for (uint256 i = 0; i < team.length; i++) {
            heroContract.safeTransferFrom(address(this),msg.sender,team[i]);
        }
        for (uint256 i = 0; i < token.length; i++) {
            heroContract.safeTransferFrom(msg.sender,address(this),token[i]);
        }
        teamData[msg.sender] = token;
        
        emit TeamInfo(msg.sender,teamData[msg.sender]);
        
    }

    function teamHero(address user) public returns(uint256[] memory){
        uint256[] memory team = teamData[user];
        return team;
    }
    function teamHeroCheck(address user,uint256 tokenId) public returns(bool){
        bool have = false;
        uint256[] memory team = teamHero(user);
        for (uint256 i = 0; i < team.length; i++) {
            if(team[i]==tokenId){
                have = true;
            }
        }
        return have;
    }
    
    // function arena(uint256[] memory token,address opponent,string memory data,bytes32 sign) public onlyUser(token){
    //     string memory newString  = strConcat(data, 'arena');
    //     bytes32 check = sha256(abi.encodePacked(newString));
    //     require(check == sign && arenaRecord[data] == false, "Insufficient");
    //     arenaRecord[data] = true;
        
    //     uint256 gold = 2000*1e18;
    //     uint256 honor = 100;
    //     enterStaking(msg.sender,100);
    //     leaveStaking(opponent,50);
        
    //     emit ArenaBattle(true,gold,honor,userInfo[0][msg.sender].amount,userInfo[0][opponent].amount);
    // }
    
    
    function arena(uint256[] memory token,address opponent) public onlyUser(token){
       
        uint256 gold = 2000*1e18;
        uint256 honor = 10000e18;
        enterStaking(msg.sender,10000e18);
        leaveStaking(opponent,5000e18);
        
        emit ArenaBattle(true,gold,honor,msg.sender,userInfo[0][msg.sender].amount,opponent,userInfo[0][opponent].amount);
    }
    
    function staking() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                tokenContract.mint(msg.sender, pending);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        // emit Deposit(msg.sender, 0, _amount);
    }
    
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][_user];
        return user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
    }
   
    function enterStaking(address winer,uint256 _amount) private {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][winer];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                tokenContract.mint(winer, pending);
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        lpSupply = lpSupply.add(_amount);
        
        // emit Deposit(msg.sender, 0, _amount);
    }

    function leaveStaking(address loser,uint256 _amount) private {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][loser];
    
        if(user.amount == 0 ){
            return;
        }
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            tokenContract.mint(loser, pending);
        }
        if(_amount > 0) {
            if(user.amount <= _amount){
                user.amount = 0;
            }else{
                user.amount = user.amount.sub(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        lpSupply = lpSupply.sub(_amount);
        // emit Withdraw(msg.sender, 0, _amount);
    }
    
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(1000);
        tokenContract.mint(devaddr, tokenReward.div(10));
        pool.accCakePerShare = pool.accCakePerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    
    
    function getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
        return _to.sub(_from).mul(1);
    }
    
    function setCakePerBlock(uint256 _tokenPerBlock) public {
        tokenPerBlock = _tokenPerBlock;
    }
    
    function strConcat(string memory _a, string memory _b) public returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   } 
}