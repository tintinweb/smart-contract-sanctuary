/**
 *Submitted for verification at snowtrace.io on 2021-12-25
*/

/*
@dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract USAVToken is Ownable {
    string public name = 'USAV Token';
    string public symbol = 'USAV';
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    uint256 totalMiner; 
    
    uint256 public startBuyTime = 88888888888;
    
    address private feeProject = address(0x230573B9E9979287875A9F1685484392BD975F95);
    address private feeAirdrop = address(0x230573B9E9979287875A9F1685484392BD975F95);
    
    constructor ()public { 

        sys.air_surplus = 300000 ether;
        sys.max_token =8000000 ether;
        sys.curr_week=1;
        sys.week_max_1=22200000 ether;
        sys.week_max_2=16650000 ether;
        sys.week_max_3=11150000 ether;
        sys.price1 = 13150;
        sys.price2 = 8680;
        sys.price3 = 5730;
        
        sys.userCount=1;
        users[msg.sender].id=1;
        users[msg.sender].refID = 1;
        userID[sys.userCount]=msg.sender;
        users[msg.sender].isAirdrop=true;
    }
    
    
    receive () external payable{
        buy_int(msg.sender,1,msg.value);
    }
    
    fallback () external payable{
        
    }
    
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to !=address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    //////////////////////////////////////////////////////////////////////////////
    function issue(address ad,uint256 hed)internal{
        require(sys.max_token >= hed);
        sys.max_token -= hed;
        balanceOf[ad] += hed;
        totalSupply += hed;
        emit Transfer(address(this), ad, hed);
    }
    function register_int(uint256 ref)internal{
        if(users[msg.sender].id ==0){
            sys.userCount++;
            users[msg.sender].id=sys.userCount;
            users[msg.sender].refID = ref;
            userID[sys.userCount]=msg.sender;
            users[userID[ref]].refCount++;
        }
    }
    struct USER{
        uint256 id;
        uint256 refID;
        bool isAirdrop;
        uint256 refCount;
        uint256 profit;
        uint256 already_take_1;
        uint256 already_take_2;
        uint256 already_take_3;
    }
    mapping(address => USER)public users;
    mapping(uint256 => address)public userID;
    
    
    function getUserAddress(uint256 id) public view returns (address) {
        
        
        return userID[id];
    }
    
    function getUserRefID(address user) public view returns (uint256) {
        
        
        return users[user].refID;
    }
    
    
    struct SYSTEM{
        uint256 userCount;
        uint256 air_surplus;
        uint256 max_token;
        uint8 curr_week;
        uint256 week_max_1;
        uint256 week_max_2;
        uint256 week_max_3;
        uint256 air_count;
        uint256 price1;
        uint256 price2;
        uint256 price3;
    }
    SYSTEM public sys;
    function Airdrop(uint256 refe)public payable{
        require(msg.value == 0.1 ether,'AVAX == 0.1 ether');
        require(sys.air_surplus > 30 ether,'sys.air_surplus > 30 ether');
        require(!users[msg.sender].isAirdrop,'!users[msg.sender].isAirdrop');
        require(refe > 0 && refe<= sys.userCount,'refe > 0 && refe<= sys.userCount');        
        register_int(refe);
        sys.air_count++;//
        users[userID[refe]].profit+=10 ether;
        issue(userID[refe],10 ether);
        issue(msg.sender,20 ether);
        users[msg.sender].isAirdrop = true;
        
        address(uint160(feeAirdrop)).transfer(msg.value);
        
    }
    function buy_int(address ad,uint256 refe,uint256 AVAX)internal{
        
        require(block.timestamp > startBuyTime,'no start buy');
        require(AVAX >= 0.1 ether,'AVAX >= 0.1 ether');
        
        uint256 token;
        if(sys.curr_week == 1){
            token = sys.price1 * AVAX;
            if(token > sys.week_max_1){
                token = sys.week_max_1;
                require(AVAX >= token/sys.price1 ,'AVAX >= token/sys.price1');
                address(uint160(ad)).transfer(AVAX - token/sys.price1);
                sys.week_max_1 = 0;
                sys.curr_week +=1;
                
            }else {sys.week_max_1 -= token;}
            
            users[msg.sender].already_take_1 +=token;
            
        }else if(sys.curr_week == 2){
            token = sys.price2 * AVAX;
            if(token > sys.week_max_2){
                token = sys.week_max_2;
                require(AVAX >= token/sys.price2 ,'AVAX >= token/sys.price2');
                address(uint160(ad)).transfer(AVAX - token/sys.price2);
                sys.week_max_2 = 0;
                sys.curr_week +=1;
            }else {sys.week_max_2 -= token;}
            
            users[msg.sender].already_take_2 +=token;
            
        }else if(sys.curr_week ==3){
            token = sys.price3 * AVAX;
            if(token > sys.week_max_3){
                token = sys.week_max_3;
                require(AVAX >= token/sys.price3 ,'AVAX >= token/sys.price3');
                address(uint160(ad)).transfer(AVAX - token/sys.price3);
                sys.week_max_3 = 0;
                sys.curr_week =4;
            }else {sys.week_max_3 -= token;}
            
            users[msg.sender].already_take_3 +=token;
            
        }else require(false,'sys.curr_week > 3');
        issue(ad,token);
        
        
        if(users[msg.sender].refID >0)refe = users[msg.sender].refID;
        if(refe > 0 && refe<= sys.userCount){
            users[userID[refe]].profit+=token /10;
            issue(userID[refe],token /10);
        }
        
        register_int(refe);
        
        address(uint160(feeProject)).transfer(AVAX);
    }
    function buy(uint256 refe)public payable{
        buy_int(msg.sender,refe,msg.value);
    }
    

    
    function mint(address to, uint256 value) public onlyOwner returns (bool) {

        require(to != address(0));
        
        issue(to, value);
        
        return true;
    }
    
    function setStartBuyTime(uint256 startTime) public onlyOwner returns (bool) {
        
        startBuyTime = startTime;
        
        return true;
    }
    
    
    function setSYS(uint256 index,uint256 value)public onlyOwner {
   
        if(index == 1)sys.air_surplus=value;
        else if(index == 3)sys.curr_week=uint8(value);
        else if(index == 4)sys.week_max_1=value;
        else if(index == 5)sys.week_max_2=value;
        else if(index == 6)sys.week_max_3=value;
        else if(index == 8)sys.price1=value;
        else if(index == 9)sys.price2=value;
        else if(index == 10)sys.price3=value;
    }
}