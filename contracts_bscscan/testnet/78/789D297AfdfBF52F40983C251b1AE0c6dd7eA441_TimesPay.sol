/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity >=0.5.0 <0.8.6;
// pragma experimental ABIEncoderV2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract TimesPay {

    using SafeMath for uint256;
    
    address payable public owner;
    
    uint public defaultFee = 5;
    uint public feeDecimal = 10**3;
    
    struct TokenList {
        address tokenAddress;
        bool available;
        uint index;
    }
    
    struct Member {
        uint256 index;
        address payable memberAddress;
        string brandkey;
        uint256 fee;
        uint256 userCount;
        uint256 totalRecived;
        uint256 totalPayout;
        uint256 totalFee;
        uint256 timestamp;
        bool banned;
    }

    struct MemberWallet {
        address tokenAddress;
        uint256 totalRecived;
        uint256 totalPayout;
        uint256 totalFee;
    }
    
    struct MemberUser {
        address userAddress;
        // string brandkey;
        uint256 balance;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalFee;
        uint256 timestamp;
    }

    struct MemberUserWallet {
        address tokenAddress;
        uint256 balance;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalFee;
    }

    struct User {
        address payable userAddress;
        uint256 timestamp;
        uint256 balance;
        uint256 totalDeposit;
        uint256 totalWithdraw;
    }
    
    mapping (string => Member) member;
    mapping (address => Member) memberByAddress;
    mapping (address => mapping(address => MemberWallet)) memberWallet;
    mapping (string => mapping(address => MemberUser)) memberUser;
    mapping (string => mapping(address => mapping(address => MemberUserWallet))) memberUserWallet;
    mapping (address => User) user;
    mapping (address => TokenList) tokenList;
    
    address[] availableTokenList;
    address[] manager;
    address[] poolTokenList;
    string[] brandList;
    address[] brandUserList;

    constructor() public {
        
        owner = msg.sender;
    }

    event MemberEvent(
        uint256 index,
        address memberAddress,
        string memberBrandkey,
        uint256 memberFee,
        uint256 userCount,
        uint256 timestamp
    );

    event UserDepositEvent(
        bool trc20,
        address contractAddress,
        address userAddress,
        string userBrandkey,
        uint256 userDeposit,
        uint256 fee,
        string clientId,
        uint256 timestamp
    );
    
    event UserWithdrawEvent(
        address userAddress,
        string userBrandkey,
        uint256 totalDeposit,
        uint256 userWithdraw,
        uint256 timestamp
    );
    
    // auth
    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    modifier ownerOrManager() {
        bool isManager = false;
        for(uint i = 0; i < manager.length; i++) {
            if(!isManager) {
                isManager = manager[i] == msg.sender ;
            }
        }
        require(msg.sender == owner || isManager, "Permission denied");
        _;
    }

    modifier memberMustExist() {
        bool isMember = false;
        isMember = memberByAddress[msg.sender].memberAddress == msg.sender;
        require(msg.sender == owner || isMember, "Permission denied");
        _;
    }
    
    // permission manage
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function getManagerList() public view returns(address[] memory){
        return manager;
    }

    function setManagerList(address _manager) ownerOrManager public returns(string memory exist){
        bool exist = false;
        for(uint i=0; i<manager.length; i++){
            if(manager[i] == _manager) {
                exist = true;
            }
        }
        if(!exist) {
            manager.push(_manager);
            return 'Added';
        }
        return 'Already exist';
    }

    function deleteManagerList(address _manager) ownerOrManager public returns(string memory exist){
        bool exist = false;
        uint index = 0;
        for(uint i=0; i<manager.length; i++){
            if(manager[i] == _manager) {
                exist = true;
                index = i;
            }
        }
        if(exist) {
            delete manager[index];
            return 'Deleted';
        }
        return 'No exist';
    }
    
    // pool balance manage
    
    function getPoolMainBalance() public view returns (uint PoolBalance) {
        return address(this).balance;
    }
    
    function getPoolTokenBalance(address _tokenAddress) view public returns (uint) {
        return ERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdrawPool() public onlyOwner { //
        for(uint i=0;i<poolTokenList.length;i++){
            ERC20(poolTokenList[i]).transfer(msg.sender, getPoolTokenBalance(poolTokenList[i]));
        }
        require(msg.sender.send(address(this).balance));
    }

    function setPoolTokenList(address __tokenAddress) ownerOrManager public returns (address[] memory){
        bool isExist = false;
        for(uint i=0;i<poolTokenList.length;i++){
           if(!isExist) {
             isExist = poolTokenList[i] == __tokenAddress;
           }
        }
        if(!isExist) poolTokenList.push(__tokenAddress);
        return (poolTokenList);
    }

    function getPoolTokenList() public view returns (address[] memory){
        return (poolTokenList);
    }
    
    // token list manage
    function getTokenList() public view returns (address[] memory){
        return (availableTokenList);
    }

    function getTokenInfo(address __tokenAddress) public view returns (address _tokenAddress, bool _available){
        TokenList memory c = tokenList[__tokenAddress];
        return (c.tokenAddress, c.available);
    }

    function deleteTokenList(address __tokenAddress) ownerOrManager public returns (address[] memory){
        require(tokenList[__tokenAddress].available, 'Token not exist');
        delete availableTokenList[tokenList[__tokenAddress].index];// = address(0);
        delete tokenList[__tokenAddress];
        
        return (availableTokenList);
    }

    function setTokenList(address __tokenAddress) ownerOrManager public returns (address[] memory){
        require(!tokenList[__tokenAddress].available, 'Token exist');
        tokenList[__tokenAddress].tokenAddress = __tokenAddress;
        tokenList[__tokenAddress].available = true;
        tokenList[__tokenAddress].index = availableTokenList.length;
        availableTokenList.push(__tokenAddress);
        
        return (availableTokenList);
    }


    // manage member method
    // function getBrandList() public view returns (string[] memory){
    //     return (brandList);
    // }

    function setMemberFee(string memory _brandkey, uint _fee) public returns (uint index, address memberAddress, string memory brandkey, uint fee, uint userCount){
        member[_brandkey].fee = _fee;
        Member memory b = member[_brandkey];
        return (b.index, b.memberAddress, b.brandkey, b.fee, b.userCount);
    }

    function bannedMember(string memory _brandkey, bool _banned) ownerOrManager public returns (string memory brandkey, bool banned){
        require(member[_brandkey].banned != _banned, 'Already');
        member[_brandkey].banned = _banned;
        return (member[_brandkey].brandkey, member[_brandkey].banned);
    }

    // member method
    function getMemberInfoByBrandKey(string memory _brandkey) public view returns (uint index, address memberAddress, string memory brandkey, uint fee, uint userCount){
        Member memory b = member[_brandkey];
        return (b.index, b.memberAddress, b.brandkey, b.fee, b.userCount);
    }

    function getMemberInfoByAddress(address _memberAddress) public view returns (uint index, address memberAddress, string memory brandkey, uint fee, uint userCount){
        Member memory b = memberByAddress[_memberAddress];
        return (b.index, b.memberAddress, b.brandkey, b.fee, b.userCount);
    }
    
    function registerMember(string memory _brandkey) public returns (uint index, address memberAddress, string memory brandkey, uint fee, uint userCount, uint timestamp) {
        require(!compareStrings(member[_brandkey].brandkey, _brandkey), 'Brandkey has already exist');
        address payable _memberAddress = msg.sender;
        
        member[_brandkey].brandkey = _brandkey;
        member[_brandkey].memberAddress = _memberAddress;
        member[_brandkey].fee = defaultFee;
        member[_brandkey].userCount = 0;
        member[_brandkey].banned = false;
        member[_brandkey].timestamp = block.timestamp;
        member[_brandkey].totalRecived = 0;
        member[_brandkey].totalPayout = 0;
        brandList.push(_brandkey);
        member[_brandkey].index = brandList.length-1;
        emit MemberEvent(member[_brandkey].index, _memberAddress, _brandkey, defaultFee, 0, block.timestamp);
        return (index, _memberAddress, _brandkey, defaultFee, 0, block.timestamp);
    }
    
    function getMemberUser(address _userAddress) memberMustExist public view returns (address useraddress, uint totalDeposit, uint balance, uint totalWithdraw){
        require(user[_userAddress].userAddress == _userAddress, "User not exist");
        string memory brandkey = memberByAddress[msg.sender].brandkey;
        MemberUser memory user = memberUser[brandkey][_userAddress];
        require(user.userAddress == _userAddress, "User not exist in your brand");
        return (_userAddress, user.totalDeposit, user.balance, user.totalWithdraw);
    }

    function getMemberUserWallet(address _userAddress, address _tokenAddress) memberMustExist public view returns (address useraddress, address tokenAddress, uint totalDeposit, uint balance, uint totalWithdraw){
        require(user[_userAddress].userAddress == _userAddress, "User not exist");
        string memory brandkey = memberByAddress[msg.sender].brandkey;
        MemberUser memory user = memberUser[brandkey][_userAddress];
        require(user.userAddress == _userAddress, "User not exist in your brand");
        MemberUserWallet memory muw = memberUserWallet[brandkey][_userAddress][_tokenAddress];

        return (_userAddress, tokenAddress, muw.totalDeposit, muw.balance, muw.totalWithdraw);
    }
    
    function setUserBalance(address userAddress) public payable {
        address payable memberAddress = msg.sender;
        require(user[userAddress].userAddress == userAddress, "User not exist");
        string memory brandkey = memberByAddress[memberAddress].brandkey;
        require(memberUser[brandkey][userAddress].userAddress == userAddress, "User not exist in your brand");
        memberUser[brandkey][userAddress].balance += msg.value;
        memberByAddress[memberAddress].totalPayout += msg.value;
    }

    function setUserTokenBalance(address userAddress, address tokenAddress, uint amount) public payable {
        require(tokenList[tokenAddress].available,"Invalid token address");
        address payable memberAddress = msg.sender;
        require(user[userAddress].userAddress == userAddress, "User not exist");
        string memory brandkey = memberByAddress[memberAddress].brandkey;
        require(memberUser[brandkey][userAddress].userAddress == userAddress, "User not exist in your brand");
        memberUserWallet[brandkey][userAddress][tokenAddress].tokenAddress = tokenAddress;
        memberUserWallet[brandkey][userAddress][tokenAddress].balance += amount;
        memberWallet[memberAddress][tokenAddress].totalPayout += amount;
    }

    // user method
    function getUserInfo(address _userAddress) public view returns (address useraddress, uint totalDeposit, uint balance, uint totalWithdraw){
        // address _userAddress = msg.sender;
        require(user[_userAddress].userAddress == _userAddress, "User not exist");

        return (_userAddress, user[_userAddress].totalDeposit, user[_userAddress].balance, user[_userAddress].totalWithdraw);
    }

    function getUserWallet(string memory _brandkey, address _tokenAddress) public view returns (address useraddress, string memory brandkey, address tokenAddress, uint totalDeposit, uint balance, uint totalWithdraw){
        address _userAddress = msg.sender;
        require(user[_userAddress].userAddress == _userAddress, "User not exist");

        return (_userAddress, _brandkey, _tokenAddress, memberUserWallet[_brandkey][_userAddress][_tokenAddress].totalDeposit, memberUserWallet[_brandkey][_userAddress][_tokenAddress].balance, memberUserWallet[_brandkey][_userAddress][_tokenAddress].totalWithdraw);
    }
    
    function createUserOrder(string memory brandkey, string memory clientId) public payable {
        address payable userAddress = msg.sender;
        uint amount = msg.value;

        require(compareStrings(member[brandkey].brandkey, brandkey), "Brand not exist");
        Member memory brand = member[brandkey];
        
        user[userAddress].userAddress = userAddress;
        // user[userAddress].totalDeposit += amount;

        uint _fee = amount.mul(brand.fee).div(feeDecimal);
        uint _userDeposit = amount - _fee;

        if (memberUser[brandkey][userAddress].userAddress != userAddress) {
            memberUser[brandkey][userAddress].userAddress = userAddress;
            memberUser[brandkey][userAddress].balance = 0;
            memberUser[brandkey][userAddress].totalWithdraw = 0;
            memberUser[brandkey][userAddress].timestamp = block.timestamp;
            member[brandkey].userCount += 1;
        } 
        memberUser[brandkey][userAddress].totalDeposit += _userDeposit;
        memberUser[brandkey][userAddress].totalFee += _fee;
        
        member[brandkey].totalRecived += _userDeposit;
        member[brandkey].totalFee += _fee;

        // owner.transfer(_fee);
        address payable memberAddress = member[brandkey].memberAddress;
        memberAddress.transfer(_userDeposit);
        
        emit UserDepositEvent(false, address(0), userAddress, brandkey, _userDeposit, _fee, clientId, block.timestamp);
    }
    
    function createUserTokenOrder(string memory brandkey, address tokenAddress, uint amount, string memory clientId) public payable {
        
        address payable userAddress = msg.sender;
        
        TokenList memory token = tokenList[tokenAddress];
        require (token.available, "Invalid token contract.");
        require (ERC20(tokenAddress).transferFrom(userAddress, address(this), amount), "Cannot transfer token.");
        
        require(compareStrings(member[brandkey].brandkey, brandkey), "Brand not exist");
        Member memory brand = member[brandkey];
        user[userAddress].userAddress = userAddress;
        // user[userAddress].totalDeposit += amount;

        uint _fee = amount.mul(brand.fee).div(feeDecimal);
        uint _userDeposit = amount - _fee;

        if (memberUser[brandkey][userAddress].userAddress != userAddress) {
            member[brandkey].userCount += 1;
            memberUser[brandkey][userAddress].userAddress = userAddress;
            memberUser[brandkey][userAddress].balance = 0;
            memberUser[brandkey][userAddress].totalWithdraw = 0;
            memberUser[brandkey][userAddress].totalDeposit = 0;
            memberUser[brandkey][userAddress].totalFee = 0;
            memberUser[brandkey][userAddress].timestamp = block.timestamp;            
        } 

        memberUserWallet[brandkey][userAddress][tokenAddress].tokenAddress = tokenAddress;
        memberUserWallet[brandkey][userAddress][tokenAddress].totalDeposit += _userDeposit;
        memberUserWallet[brandkey][userAddress][tokenAddress].totalFee += _fee;
        

        memberWallet[brand.memberAddress][tokenAddress].tokenAddress = tokenAddress;
        memberWallet[brand.memberAddress][tokenAddress].totalRecived += _userDeposit;
        
        address payable memberAddress = member[brandkey].memberAddress;
        require (ERC20(tokenAddress).transfer(memberAddress, _userDeposit), "Error occurred while tranferring token to member.");
        // require (ERC20(tokenAddress).transfer(owner, _fee), "Error occurred while tranferring token to platform.");
        
        emit UserDepositEvent(true, tokenAddress, userAddress, brandkey, _userDeposit, _fee, clientId, block.timestamp);
        // return (userAddress, _userBrandkey, brandMemberUser[userAddress].totalDeposit, _userDeposit, block.timestamp);
    }
    
    function userWithdraw(string memory brandKey) public {
        address payable _userAddress = msg.sender;
        require(user[_userAddress].userAddress == _userAddress, "User not exist");
        require(memberUser[brandKey][_userAddress].userAddress == _userAddress, "User not exist in this brandkey");
        if(memberUser[brandKey][_userAddress].balance > 0) {
            require(_userAddress.send(memberUser[brandKey][_userAddress].balance));
            memberUser[brandKey][_userAddress].balance = 0;
        }

        for(uint i = 0; i< availableTokenList.length; i++) {
            if(memberUserWallet[brandKey][_userAddress][availableTokenList[i]].balance > 0) {
                require(ERC20(availableTokenList[i]).transfer(_userAddress, memberUserWallet[brandKey][_userAddress][availableTokenList[i]].balance), "Fail withdraw token");
                memberUserWallet[brandKey][_userAddress][availableTokenList[i]].totalWithdraw += memberUserWallet[brandKey][_userAddress][availableTokenList[i]].balance;
                memberUserWallet[brandKey][_userAddress][availableTokenList[i]].balance = 0;
            }
        }
        
        
        // emit UserWithdrawEvent(_userAddress, brandKey, brandMemberUser[_userAddress].totalDeposit, _amount, block.timestamp);

    }
    
    // utils
    function compareStrings(string memory a, string memory b) internal view returns (bool) {
       return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    
    
    // function bytesToAddress(bytes memory bys) internal pure returns (address payable addr) {
    //     return address(bytesToUint(bys));
    // }
    
    // function bytesToUint(bytes memory b) internal pure returns (uint256){
    //     uint256 number;
    //     for(uint i=0;i<b.length;i++){
    //         number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
    //     }
    //     return number;
    // }
    
    // function getBlockHash() internal view returns (bytes32 BlockHash) {
    //     uint _blockNumber;
    //     bytes32 _blockHash;
    //     _blockNumber = uint(block.number - 1);
    //     _blockHash = blockhash(_blockNumber); 
    //     return _blockHash;
    // }
    
    
}