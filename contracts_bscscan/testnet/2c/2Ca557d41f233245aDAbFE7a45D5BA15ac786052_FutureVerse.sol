/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

pragma solidity >=0.5.0 <0.8.6;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;
        return c;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}


contract FutureVerse {
    using SafeMath for uint;
    uint private constant MAIN_DECIMAL = 10**18;
    
    address payable public owner;
    address payable GENESIS;        // 001
    address payable FUNDATION;      // Team
    uint internal depositRateDecimal = 10**2;     
    uint internal bonusRate = 60;        // bonus distributed level 
    uint internal luanchPoolRate = 20;
    uint internal vipPoolRate = 12;
    uint internal fundationRate = 5;
    uint internal insurancePoolRate = 3;
    uint internal luanchPoolBalance = 0;
    uint internal vipPoolBalance = 0;
    uint internal insurancePoolBalance = 0;
    uint internal rewardMaxDepth = 8;          // bonus distributed level   
    uint[] internal bonusRateList = [35, 5, 5, 3, 3, 3, 3, 3];

    uint ALLLEVEL = 8;
    uint VIPLEVEL = 8;
    uint levelExpiredRate = 4;                  // max times of bouns balance member can reward

    // launch params address of the uniswap v2 router
    // address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // testnet


    struct Token {
        address tokenAddress;
        bool available;
        uint index;
    }
    mapping (address => Token) token;
    address[] TokenList;

    struct Manager {
        address managerAddress;
        string permission;
        bool available;
        uint index;
    }
    mapping (address => Manager) manager;
    address[] ManagerList;

    struct Member {
        address payable memberAddress;
        uint timestamp;
        uint level;
        address referrerAddress;
        uint affiliateCount;
        uint bonusCount;
        bool levelExpired;
    }
    mapping (address => Member) member;
    address[] memberList;

    struct Wallet {
        address tokenAddress;
        uint totalDeposit;
        uint totalRecived;
        uint totalBonus;
        uint currentBonus;
    }
    mapping (address => mapping (address => Wallet)) wallet;
    
    struct BonusRecord {
        uint index;
        address affiliateAddress;
        address tokenAddress;
        uint amount;
        uint bonus;
        uint timestamp;
    }
    mapping (address => mapping(uint => BonusRecord)) bonusRecord;

    
    struct Level {
        uint index;
        uint amount;
        uint maxBonusBalance;
        uint rewardDepth; // 3 5 7 9 
        bool available;
        // string title;
        // uint subscriptionLimit;
        // uint redeemPercent; // 70 -> 30 re-invest
    }
    mapping(address => mapping(uint => Level)) level;
    

    struct Project {
        IERC20 tokenAddress;
        uint distributeAmount;
        bool distributed;
        uint subscriptionTime;
        uint distributionTime;
        uint distributedCount;
        bool available;
    }
    mapping(IERC20 => Project) project;
    IERC20[] projectList;

    struct DistributeRecord {
        address project;
    }

    struct UserProject {
        IERC20 tokenAddress;
        uint amount;
        bool redeemed;
    }
    mapping(address => mapping(IERC20 => UserProject)) userProject;

    constructor() public {
        owner = msg.sender;
        GENESIS = 0x8Ff48A92eA8f3153821b218c4EC1f7214aAC3f6B;
        FUNDATION = 0x0637C3a654B9A3E8213304a1e12632E77Cd89c0F;

        
        // 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08
        address USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
        for(uint i = 1; i <= ALLLEVEL; i++) {
            level[address(0)][i].index = i;
            level[address(0)][i].available = true;
            level[address(0)][i].amount = 1 * i * MAIN_DECIMAL / 100 ;
            level[address(0)][i].maxBonusBalance = level[address(0)][i].amount * levelExpiredRate ;
            level[address(0)][i].rewardDepth = 1 * i * MAIN_DECIMAL / 100 ;
            level[USDT][i].index = i;
            level[USDT][i].available = true;
            level[USDT][i].amount = 1 * i * MAIN_DECIMAL / 100 ;
            level[USDT][i].maxBonusBalance = level[USDT][i].amount * levelExpiredRate ;
            level[USDT][i].rewardDepth = 1 * i * MAIN_DECIMAL / 100 ;
        }

        member[GENESIS].memberAddress = GENESIS;
        member[GENESIS].timestamp = block.timestamp;
        member[GENESIS].level = 1;
        member[GENESIS].referrerAddress = GENESIS;
    }

    // auth
    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    modifier ownerOrManager() {
        require(msg.sender == owner || manager[msg.sender].available, "Permission denied");
        _;
    }

    // manage contract global vairable 
    function getParams() public view returns(uint _depositRateDecimal, uint _bonusRate, uint _luanchPoolRate, uint _vipPoolRate, uint _fundationRate, uint _insurancePoolRate, uint _luanchPoolBalance, uint _vipPoolBalance, uint _insurancePoolBalance, uint _rewardMaxDepth, uint[] memory _bonusRateList) {
        return(depositRateDecimal, bonusRate, luanchPoolRate, vipPoolRate, fundationRate, insurancePoolRate, luanchPoolBalance, vipPoolBalance, insurancePoolBalance, rewardMaxDepth, bonusRateList);
    }

    function setParams(uint _depositRateDecimal, uint _bonusRate, uint _luanchPoolRate, uint _vipPoolRate, uint _fundationRate, uint _insurancePoolRate, uint _rewardMaxDepth, uint[] memory _bonusRateList) public onlyOwner { //uint _luanchPoolBalance, uint _vipPoolBalance, uint _insurancePoolBalance,
        require(_depositRateDecimal % 10 == 0, "Must be 10s base");
        require(_bonusRate + _luanchPoolRate + _vipPoolRate + _fundationRate + _insurancePoolRate == _depositRateDecimal, "Total rate should be equle depositRateDecimal");
        depositRateDecimal = _depositRateDecimal;
        bonusRate = _bonusRate;
        luanchPoolRate = _luanchPoolRate;
        vipPoolRate = _vipPoolRate;
        fundationRate = _fundationRate;
        insurancePoolRate = _insurancePoolRate;
        // luanchPoolBalance = _luanchPoolBalance;
        // vipPoolBalance = _vipPoolBalance;
        // insurancePoolBalance = _insurancePoolBalance;
        rewardMaxDepth = _rewardMaxDepth;
        
        uint allRwardRate = 0;
        for(uint i = 0; i < _bonusRateList.length; i++) {
            allRwardRate += _bonusRateList[i];
        }
        require(allRwardRate <= bonusRate, "Over bonusRate");
        bonusRateList = _bonusRateList;
    }
    
    // permission manage todo : add permission check
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isManager(address managerAddr) public view returns(bool) {
        return (manager[managerAddr].available);
    }

    function getManagerList() ownerOrManager public view returns(address[] memory){
        return (ManagerList);
    }

    // function getManager(address managerAddr) ownerOrManager public view returns(address managerAddress, bool available, string memory permission, uint index) {
    function getManager(address managerAddr) ownerOrManager public view returns(address managerAddress, bool available, uint index) {
        Manager memory m = manager[managerAddr];
        // return (m.managerAddress, m.available, m.permission, m.index);
        return (m.managerAddress, m.available, m.index);
    }

    // function setManager(address managerAddr, string memory _permission) ownerOrManager public returns(address managerAddress, bool available, string memory permission, uint index) { 
    function setManager(address managerAddr) ownerOrManager public returns(address managerAddress, bool available, uint index) { 
        Manager memory m = manager[managerAddr];
        // if(m.available) {
        //     manager[managerAddr].permission = _permission;
        //     return (m.managerAddress, m.available, m.permission, m.index);
        // } else {
        //     manager[managerAddr].managerAddress = managerAddr;
        //     manager[managerAddr].available = true;
        //     manager[managerAddr].permission = _permission;
        //     manager[managerAddr].index = ManagerList.length;
        //     ManagerList.push(managerAddr);
        //     return (manager[managerAddr].managerAddress, manager[managerAddr].available, manager[managerAddr].permission, manager[managerAddr].index);
        // }
        require(!m.available, "Already set");
        manager[managerAddr].managerAddress = managerAddr;
        manager[managerAddr].available = true;
        manager[managerAddr].index = ManagerList.length;
        ManagerList.push(managerAddr);
        return (manager[managerAddr].managerAddress, manager[managerAddr].available, manager[managerAddr].index);
    }

    function deleteManager(address managerAddr) ownerOrManager public returns(address[] memory){
        Manager memory m = manager[managerAddr];
        if(m.available) {
            for(uint i = m.index; i<ManagerList.length; i++) {
                ManagerList[i] = ManagerList[i+1];
            }
            ManagerList.pop();
            delete manager[managerAddr];
        }
        return (ManagerList);
    }
    
    // pool balance manage
    
    function poolMainBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function poolTokenBalance(address tokenAddr) public view returns (uint) {
        return IERC20(tokenAddr).balanceOf(address(this));
    }

    function withdrawPool(address[] memory assetList) public onlyOwner { //
        for(uint i=0;i<assetList.length;i++){
            if(poolTokenBalance(assetList[i]) > 0) {
                IERC20(assetList[i]).transfer(msg.sender, poolTokenBalance(assetList[i]));
            }
        }
        require(msg.sender.send(address(this).balance));
    }

    // token list manage
    function allToken() public view returns (address[] memory){
        return (TokenList);
    }

    function addToken(address tokenAddr) ownerOrManager public returns (address[] memory){
        Token memory t = token[tokenAddr];
        if(t.available) {
            return (TokenList);
        } else {
            token[tokenAddr].tokenAddress = tokenAddr;
            token[tokenAddr].available = true;
            token[tokenAddr].index = TokenList.length;
            TokenList.push(tokenAddr);
            return (TokenList);
        }
    }

    function deleteToken(address tokenAddr) ownerOrManager public returns (address[] memory){
        Token memory t = token[tokenAddr];
        if(!t.available) {
            return (TokenList);
        } else {
            for(uint i = t.index - 1 ;i < TokenList.length; i++) {
                TokenList[i] = TokenList[i+1];
            }
            TokenList.pop();
            delete token[tokenAddr];
            return (TokenList);
        }
    }

    function _availableToken(address tokenAddr) internal returns(bool) {
        Token memory t = token[tokenAddr];
        return t.available || tokenAddr == address(0);
    }


    // manage level method
    function getLevel(address tokenAddr, uint lvl) public view returns(address tokenAddress, uint index, uint amount, uint rewardDepth, uint maxBonusBalance, bool available) {
        Level memory l = level[tokenAddr][lvl];
        return (tokenAddr, l.index, l.amount, l.rewardDepth, l.maxBonusBalance, l.available);
    }

    function setLevel(address tokenAddr, uint lvl, uint amount, uint rewardDepth) ownerOrManager public {
        require(_availableToken(tokenAddr), "Unavailable token");
        require(rewardDepth <= rewardMaxDepth, "Reward depth must <= reward max depth");
        if(level[tokenAddr][lvl].available) {
            level[tokenAddr][lvl].amount = amount;
            level[tokenAddr][lvl].rewardDepth = rewardDepth;
            level[tokenAddr][lvl].maxBonusBalance = amount * levelExpiredRate;
        } else {
            level[tokenAddr][lvl].amount = amount;
            level[tokenAddr][lvl].rewardDepth = rewardDepth;
            level[tokenAddr][lvl].maxBonusBalance = amount * levelExpiredRate;
            level[tokenAddr][lvl].available = true;
        }
    }


    function _checkLevel(address tokenAddr, uint amount) internal returns(uint){
        for(uint i = 1; i <= ALLLEVEL; i++) {
            if(level[tokenAddr][i].amount == amount) {
                return level[tokenAddr][i].index;
            }
        }
        return 0;
    }


    // manage bonus method
    function calculateBonus(address userAddr, address tokenAddr, uint amount, address refAddr) internal {
        uint referrerRewardDepth = level[tokenAddr][member[refAddr].level].rewardDepth;
        for(uint i = 0; i < rewardMaxDepth; i++) {
            if(member[refAddr].levelExpired || referrerRewardDepth < i + 1) {
                address upperLine = member[refAddr].referrerAddress;
                uint upperLineLevel = member[upperLine].level;
                uint upperLineRewardDepth = level[tokenAddr][member[upperLine].level].rewardDepth;
                if(member[upperLine].levelExpired || upperLineRewardDepth < i + 1) {
                    uint bonus = amount * bonusRate / depositRateDecimal;
                    setBonusRecord(GENESIS, member[GENESIS].bonusCount, userAddr, tokenAddr, amount, bonus);
                } else {
                    uint leftBonus = level[tokenAddr][upperLineLevel].maxBonusBalance - wallet[upperLine][tokenAddr].currentBonus; 
                    uint bonus = amount * bonusRateList[i] / depositRateDecimal;
                    if(bonus > leftBonus) {
                        setBonusRecord(upperLine, member[upperLine].bonusCount, userAddr, tokenAddr, amount, leftBonus);
                    } else {
                        setBonusRecord(upperLine, member[upperLine].bonusCount, userAddr, tokenAddr, amount, bonus);
                    }
                }
                i += rewardMaxDepth;
            } else {
                uint leftBonus = level[tokenAddr][member[refAddr].level].maxBonusBalance - wallet[refAddr][tokenAddr].currentBonus; 
                uint bonus = amount * bonusRateList[i] / depositRateDecimal;
                if(bonus > leftBonus) {
                    setBonusRecord(refAddr, member[refAddr].bonusCount, userAddr, tokenAddr, amount, leftBonus);
                } else {
                    setBonusRecord(refAddr, member[refAddr].bonusCount, userAddr, tokenAddr, amount, bonus);
                }
                refAddr = member[refAddr].referrerAddress;
                referrerRewardDepth = level[tokenAddr][member[refAddr].level].rewardDepth;
            }
        }
    }
    
    function setBonusRecord(address memberAddr, uint index, address newMember, address tokenAddr, uint amount, uint bonus) internal {
        require(tokenAddr == address(0) ? member[memberAddr].memberAddress.send(bonus) : IERC20(tokenAddr).transfer(memberAddr, bonus));
        
        wallet[memberAddr][tokenAddr].totalBonus += bonus;
        wallet[memberAddr][tokenAddr].currentBonus += bonus;
        member[memberAddr].bonusCount++;
        bonusRecord[memberAddr][index].index = member[memberAddr].bonusCount;
        bonusRecord[memberAddr][index].affiliateAddress = newMember;
        bonusRecord[memberAddr][index].amount = amount;
        bonusRecord[memberAddr][index].bonus = bonus;
        bonusRecord[memberAddr][index].tokenAddress = tokenAddr;
        bonusRecord[memberAddr][index].timestamp = block.timestamp;
        if(wallet[memberAddr][tokenAddr].currentBonus == level[tokenAddr][member[memberAddr].level].maxBonusBalance) {
            member[memberAddr].levelExpired = true;
            wallet[memberAddr][tokenAddr].currentBonus = 0;
        }
    }

    function getBonusRecord(address memberAddr, uint ind) public ownerOrManager view returns(uint index, address affiliateAddress, uint amount, uint bonus, uint timestamp) {
        BonusRecord memory br = bonusRecord[memberAddr][ind];
        return (br.index, br.affiliateAddress, br.amount, br.bonus, br.timestamp);
    }


    // manage project method
    function addProject(IERC20 tokenAddr) public ownerOrManager{ // , uint subscriptionStart, uint subscriptionEnd, uint distributionStart, uint distributionEnd
        Project memory p = project[tokenAddr];
        require(!p.available, "Project already set");
        project[tokenAddr].available = true;
        project[tokenAddr].tokenAddress = tokenAddr;
        project[tokenAddr].subscriptionTime = block.timestamp;
        // project[swapRouter].distributionTime = distributionStart;
        projectList.push(tokenAddr);
    }

    function allProject() public view returns(IERC20[] memory){
        return projectList;
    }

    function getProject(IERC20 tokenAddr) public view returns(IERC20 tokenAddress, uint distributeAmount, uint subscriptionTime, uint distributionTime, uint distributedCount, bool distributed){ //, uint subscriptionStart, uint subscriptionEnd, uint distributionStart, uint distributionEnd
        Project memory p = project[tokenAddr];
        return (p.tokenAddress, p.distributeAmount, p.subscriptionTime, p.distributionTime, p.distributedCount, p.distributed); //, p.subscriptionStart, p.subscriptionEnd, p.distributionStart, p.distributionEnd, p.stakeToken, p.stakeAmount, p.stakeCount
    }

    // manage member method
    function setMemberLevel(address addr, uint lvl) ownerOrManager public {
        require(member[addr].timestamp > 0, "Member not registed");
        member[addr].level = lvl;
    }

    function _isMemberExist(address addr) internal returns(bool) {
        return member[addr].timestamp > 0;
    }

    function memberInfo(address userAddr) public view returns(address memberAddress, uint timestamp, uint level, address referrerAddress, uint affiliateCount, uint bonusCount, bool expired) {
        Member memory m = member[userAddr];
        require(m.timestamp > 0, "Member not registed");
        return (userAddr, m.timestamp, m.level, m.referrerAddress, m.affiliateCount, m.bonusCount, m.levelExpired);
    }

    function memberWallet(address userAddr, address tokenAddr) public view returns(address tokenAddress, uint totalDeposit, uint totalRecived, uint totalBonus, uint currentBonus) {
        Wallet memory w = wallet[userAddr][tokenAddr];
        return (tokenAddr, w.totalDeposit, w.totalRecived, w.totalBonus, w.currentBonus);
    }

    // member method
    function join(address tokenAddr, uint amount, address referrerAddr) public payable{              
        address payable userAddr = msg.sender;
        require(_availableToken(tokenAddr), "Unavailable token");

        if(tokenAddr == address(0)) {
            amount == msg.value;
        }
        require(_isMemberExist(referrerAddr), "Referrer not exist");

        uint depositLuanchAmount = amount * luanchPoolRate / depositRateDecimal;
        luanchPoolBalance += depositLuanchAmount;
        
        uint depositVipPoolAmount = amount * vipPoolRate / depositRateDecimal;
        vipPoolBalance += depositVipPoolAmount;

        uint depositInsurancePoolAmount = amount * insurancePoolRate / depositRateDecimal;
        insurancePoolBalance += depositInsurancePoolAmount;

        uint depositFundationAmount = amount * fundationRate / depositRateDecimal;
        require(FUNDATION.send(depositFundationAmount));
        // check level up or not
        if(_isMemberExist(userAddr)) {
            Member memory m = member[userAddr];
            uint currentLevel = m.level;
            uint nextLevel = _checkLevel(tokenAddr, amount);
            if(!m.levelExpired) { 
                require(nextLevel > currentLevel, "Only accept deposit upper level");
            } else {
                require(nextLevel >= currentLevel, "Only accept deposit same or upper level");
            }
            member[userAddr].level = nextLevel;
            member[userAddr].levelExpired = false;
            wallet[userAddr][tokenAddr].currentBonus = 0;
        } else {
            uint joinLevel = _checkLevel(tokenAddr, amount);
            require(joinLevel > 0, "Must join at least level 1");
            member[userAddr].memberAddress = userAddr;
            member[userAddr].timestamp = block.timestamp;
            member[userAddr].level = joinLevel;
            member[userAddr].referrerAddress = referrerAddr;

            wallet[userAddr][tokenAddr].totalDeposit += amount;
            memberList.push(userAddr);
        }

        calculateBonus(userAddr, tokenAddr, amount, referrerAddr);
        
    }

    fallback() external payable {
        address payable userAddr = msg.sender;
        require(member[userAddr].referrerAddress != address(0), "You are new one, join first");
        uint amount = msg.value;

    }

    function me() public view returns(address memberAddress, uint timestamp, uint level, address referrerAddress, uint affiliateCount, uint bonusCount, bool expired) {
        address userAddr = msg.sender;
        Member memory m = member[userAddr];
        require(m.timestamp > 0, "Member not registed");
        return (userAddr, m.timestamp, m.level, m.referrerAddress, m.affiliateCount, m.bonusCount, m.levelExpired);
    }

    function myWallet(address tokenAddr) public view returns(address tokenAddress, uint totalDeposit, uint totalRecived, uint totalBonus, uint currentBonus) {
        address userAddr = msg.sender;
        Wallet memory w = wallet[userAddr][tokenAddr];
        return (tokenAddr, w.totalDeposit, w.totalRecived, w.totalBonus, w.currentBonus);
    }

    function myBonusRecord(uint ind) public view returns(uint index, address affiliateAddress, address tokenAddress, uint amount, uint bonus, uint timestamp) {
        address userAddr = msg.sender;
        BonusRecord memory br = bonusRecord[userAddr][ind];
        return (br.index, br.affiliateAddress, br.tokenAddress, br.amount, br.bonus, br.timestamp);
    }

    function myDistributedRecord(IERC20 projectAddr) public view returns(IERC20 projectAddress, uint amount, bool redeemed) {
        address userAddr = msg.sender;
        UserProject memory up = userProject[userAddr][projectAddr];
        return (projectAddr, up.amount, up.redeemed);
    }

    function redeemToken() public { // 領取token
        address userAddr = msg.sender;
        for(uint i = 0; i < projectList.length; i++) {
            IERC20 projectAddr = projectList[i];
            Project memory p = project[projectAddr];
            uint redeemAmount = userProject[userAddr][projectAddr].amount;
            if(!userProject[userAddr][projectAddr].redeemed && redeemAmount > 0) {
                p.tokenAddress.transfer(userAddr, redeemAmount);
            }
        }
    }
    
    function _totalInvolve(address tokenAddr) internal returns(uint) {
        uint totalInvolve = 0;
        for(uint i = 0; i < memberList.length; i++) {
            if(!member[memberList[i]].levelExpired) {
                totalInvolve += level[tokenAddr][member[memberList[i]].level].amount;
            }
        }
        return totalInvolve;
    }

    function distribute(address tokenAddr, uint amount, bool vip) public ownerOrManager {
        IERC20 projectAddr = IERC20(tokenAddr);
        Project memory p = project[projectAddr];
        require(p.available, "Unavailable project");
        require(p.distributed, "Project already distributed");
        require(amount >= projectAddr.balanceOf(address(this)));
        project[projectAddr].distributeAmount = amount;
        uint totalInvolve = _totalInvolve(tokenAddr);

        
        for(uint i = 0; i < memberList.length; i++) {
            if(!member[memberList[i]].levelExpired) {
                uint distributAmountRate = level[tokenAddr][member[memberList[i]].level].amount / totalInvolve ;
                uint distributAmount = distributAmountRate * amount;
                if(!vip || vip && member[memberList[i]].level >= VIPLEVEL) {
                    userProject[memberList[i]][projectAddr].tokenAddress = projectAddr;
                    userProject[memberList[i]][projectAddr].amount = distributAmount;
                    project[projectAddr].distributedCount++;
                    if(p.tokenAddress.transfer(memberList[i], distributAmount)) userProject[memberList[i]][projectAddr].redeemed = true;
                }
            }
        }
        project[projectAddr].distributed = true;
        project[projectAddr].distributionTime = block.timestamp;

        if(vip) vipPoolBalance = 0;
        else luanchPoolBalance = 0;
    }

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
    function launch(address _tokenIn, uint _amountIn, address _tokenOut, address _to, bool vip) external payable {
        require(_tokenIn == address(0) ? poolMainBalance() >= _amountIn : poolTokenBalance(_tokenIn) >= _amountIn, "Insufficient balance");
        
        // require(luanchPoolBalance > 0, "Invalid luanch pool balance");

        address WETH = IUniswapV2Router(UNISWAP_V2_ROUTER).WETH();
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);

        if(_tokenIn != address(0)) {
            IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, amountOutMins[path.length -1], path, _to, block.timestamp);
        } else {
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokens(amountOutMins[path.length -1], path, _to, block.timestamp);
        }
    }
    
}