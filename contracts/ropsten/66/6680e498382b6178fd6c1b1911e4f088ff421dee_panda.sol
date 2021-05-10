/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

//SPDX-License-Identifier: Apache-2.0
//Submitted for verification at BscScan.com on 2021-05-20
//@title SafeMath @notice Math operations with safety checks that revert on error
 pragma solidity 0.6.9;



//    *****             *              *****              ****                    *                          
//    **  ****         ***             ** ***             **  **                 ***                               
//    **     ***      ** **            **  ***            **    **              ** **                             
//    **        **   **   **           **    **           **      **           **   **                        
//    **         ** **     **          **     **          **        **        **     **                           
//    **          ***       **         **      **         **         **      **       **                       
//    **         ***         **        **       **        **           **   **         **                            
//    **        ***           **       **        **       **            ** **           **                      
//    **      ****             **      **         **      **            ****             **                    
//    **   **  *******************     **          **     **            ********************                    
//    *****   **                 **    **           **    **           ****                **                  
//    **     **                   **   **            **   **          ****                  **
//    **    **                     **  **             **  **        ** **                    **     
//    **   **                       ** **              ** **      **  **                      **                   
//    **  **                         ****               ****     **  **                        **                          
//    ** **                           ***                ***  **    **                          **        
//    ****                             **                 ****     **                            **     

 
//    *****              *               *****             ****                     *                          
//    **  ****         ***             ** ***             **  **                 ***                               
//    **     ***      ** **            **  ***            **    **              ** **                             
//    **        **   **    **           **    **           **      **           **   **                        
//    **         ** **      **          **     **          **        **        **     **                           
//    **          ***        **         **      **         **         **      **       **                       
//    **         ***          **        **       **        **           **   **         **                            
//    **        ***            **       **        **       **            ** **           **                      
//    **      ****              **      **         **      **            ****             **                    
//    **   **  ***************     **         **     **             ***************                  
//    ****   **                   **    **           **    **           ****                **                  
//    **     **                     **   **            **   **          ****                  **
//    **    **                       **  **             **  **        ** **                    **     
//    **   **                         ** **              ** **      **  **                      **                   
//    **  **                           ****               ****     **  **                        **                          
//    ** **                             ***                ***  **    **                          **        
//    ****                               **                 ****      **                            **  


//    *****              *               *****             ****                     *                          
//    **  ****         ***             ** ***             **  **                 ***                               
//    **     ***      ** **            **  ***            **    **              ** **                             
//    **        **   **    **           **    **           **      **           **   **                        
//    **         ** **      **          **     **          **        **        **     **                           
//    **          ***        **         **      **         **         **      **       **                       
//    **         ***          **        **       **        **           **   **         **                            
//    **        ***            **       **        **       **            ** **           **                      
//    **      ****              **      **         **      **            ****             **                    
//    **   **  ** * * * * * * **      **         **     **             *** * * * * * * **              
//    ****   **                   **    **           **    **           ****                **                  
//    **     **                     **   **            **   **          ****                  **
//    **    **                       **  **             **  **        ** **                    **     
//    **   **                         ** **              ** **      **  **                      **                   
//    **  **                           ****               ****     **  **                        **                          
//    ** **                             ***                ***  **    **                          **        
//    ****                               **                 ****      **                            **     
 
 
 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}



contract panda {
    
    using SafeMath for uint256;

    string   public name;
    uint256  public decimals;
    string   public symbol;
    uint256  public totalSupply;
    bool     public initialized;
    address  public creator;
    address  public Foundation;
    
    mapping(address => uint256)   balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => address)   public UserInviter;
    mapping(address => bool)      public UserRegistered;
    mapping(address => uint256)   public MyInviteMining;
    mapping(address => uint256)   public MyBalanceMining;
    mapping(address => uint256)   public MyId;
    mapping(address => address[]) public MyDirectReferences;
    mapping(address => uint256)   public mine_lock_block;
    mapping(address => uint256)   public transfer_lock_block;//
    mapping(address => uint256)   public transfer_area;//
    mapping(address => uint256)   public total_area;//
    mapping(address => uint256)   public Valid_balance;//
    
    //uint256 public min_mining_balances;
    //uint256 public max_mining_balances;
    uint256 public Whole_network_totalSupply;
    uint256 public Whole_network_burn;
    uint256 public Whole_network_mine;
    uint256 public Whole_network_UserID;
    
    event Transfer(address indexed from,  address indexed to,      uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function init(address _creator,address _Foundation) public {
        
        require(!initialized, "TOKEN_INITIALIZED");
        initialized = true;
        UserRegistered[_creator]      = true;
        creator = _creator;
        Foundation = _Foundation;
        balances[_creator]            = 210000    * 10**18;
        balances[_Foundation]         = 2100000   * 10**18;
        totalSupply                   = 2310000   * 10**18;
        Whole_network_totalSupply     = 210000000 * 10**18;
        //min_mining_balances           = totalSupply / 100000;//1000      * 10**18;
        //max_mining_balances           = totalSupply / 1000;//100000    * 10**18;
        name                          = "coin";
        symbol                        = "COINTEST";
        decimals                      = 18;
        emit Transfer(address(0), _creator, balances[creator]);
        emit Transfer(address(0), _Foundation, balances[_Foundation]);
    }
    
    function Mine() public returns(bool){
        //会员第一次挖矿有一个余额为零的区块时间段，注册后，挖矿时间间隔越久，损失越大，
        //所以最好是注册后及时第一次挖矿更新挖矿的区块时间，以后挖矿就正常了
        uint256 mine_block_interval = block.number.sub(mine_lock_block[msg.sender]);
        
        Valid_balance[msg.sender] = (total_area[msg.sender] 
        + balances[msg.sender] * block.number.sub(transfer_lock_block[msg.sender]))/mine_block_interval;//
        
        require(totalSupply <= Whole_network_totalSupply,"FALSE_totalSupply > Whole_network_totalSupply");
        require(UserRegistered[msg.sender],"NOT_UserRegistered");
        require(Valid_balance[msg.sender] >= totalSupply /100000,"Valid_balance_NOT_IN_MAX_MIN"); //
        require(Valid_balance[msg.sender] <= totalSupply / 1000,"Valid_balance_NOT_IN_MAX_MIN");//
        //挖矿必须在100万个区块内挖一次，超过就不能挖矿了，但交易转账正常，如果想继续挖矿，转账到新注册的地址挖矿
        require(mine_block_interval <= 1000000,"ERROR_mine_block_interval>1000000");
        //按照bsc链100万个区块大概一个月的时间，月化30%计算而来
        uint256  mine_m = Valid_balance[msg.sender] / 10000000 * 3 * mine_block_interval;//
        uint256  mine_c = mine_m / 20;
        uint256  mine_t = mine_m + mine_c;
        
        mine_lock_block[msg.sender] = block.number;
        transfer_lock_block[msg.sender] = block.number;//
        total_area[msg.sender] = 0;//
        
        balances[msg.sender] = balances[msg.sender].add(mine_m);
        balances[creator] = balances[creator].add(mine_c);
        totalSupply = totalSupply.add(mine_t);
        Whole_network_mine = Whole_network_mine.add(mine_t);
        MyBalanceMining[msg.sender] = MyBalanceMining[msg.sender].add(mine_m);
        emit Transfer(msg.sender,address(0),0);
        emit Transfer(address(0),msg.sender,mine_m);
        emit Transfer(address(0),creator,mine_c);
        RewardInvitees(msg.sender,0,mine_m/10);
        return true;
        
    }
    
    function get_mine_info() view public returns(uint256 _min_mining_balances,uint256 _Valid_balance,uint256 _max_mining_balances){
        uint256 mine_block_interval = block.number.sub(mine_lock_block[msg.sender]);
        
        _Valid_balance = (total_area[msg.sender] 
        + balances[msg.sender] * block.number.sub(transfer_lock_block[msg.sender]))/mine_block_interval;
        _min_mining_balances = totalSupply / 100000;
        _max_mining_balances = totalSupply / 1000;
        return (_min_mining_balances,Valid_balance[msg.sender],_max_mining_balances);
    }
    function Register(address to) public returns(bool){
        if(!isContract(to)){
            require(UserRegistered[msg.sender],"FALSE_UserRegistered_MSG.SENDER");
            require(!UserRegistered[to],"FALSE_UserRegistered_TO");
            UserInviter[to] = msg.sender;
            UserRegistered[to] = true;
            mine_lock_block[to] = block.number;
            transfer_lock_block[to] = block.number;
            Whole_network_UserID = Whole_network_UserID.add(1);
            MyId[to] = Whole_network_UserID;
            MyDirectReferences[msg.sender].push(to);
            emit Transfer(msg.sender, to, 0);
            return true;
        }
    }
    
    function isContract(address addr) view public returns (bool) {
    //extcodesize获取地址关联代码长度 合约地址大于0 外部账户地址为0
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        
        
        if(msg.sender == to || to == address(0)){
            Mine();
            return true;
        }else if(amount == 0){
            Register(to);
            return true; 
        }else if(isContract(msg.sender)){
            
            require(amount <= balances[msg.sender],"AMOUNT_NOT_ENOUGH");
            
            uint256 Transfer_block_interval = block.number - transfer_lock_block[to];
            transfer_area[to] = Transfer_block_interval * balances[to];
            total_area[to] = total_area[to] + transfer_area[to];
            transfer_lock_block[to] = block.number;
            
            balances[msg.sender] = balances[msg.sender].sub(amount);
            balances[to] = balances[to].add(amount);
            emit Transfer(msg.sender, to, amount);
            return true;
        }else{
            require(amount <= balances[msg.sender],"AMOUNT_NOT_ENOUGH");
            
            uint256 Transfer_block_interval = block.number - transfer_lock_block[to];
            transfer_area[to] = Transfer_block_interval * balances[to];
            total_area[to] = total_area[to] + transfer_area[to];
            transfer_lock_block[to] = block.number;
            
            Transfer_block_interval = block.number - transfer_lock_block[msg.sender];
            transfer_area[msg.sender] = Transfer_block_interval * balances[msg.sender];
            total_area[msg.sender] = total_area[msg.sender] + transfer_area[msg.sender];
            transfer_lock_block[msg.sender] = block.number;
            
            uint256 _Burn = amount / 10;
            require(amount.add(_Burn) <= balances[msg.sender], "BURN_AMOUNT_NOT_ENOUGH");
        
            balances[msg.sender] = balances[msg.sender].sub(amount.add(_Burn));
            balances[to] = balances[to].add(amount);
            totalSupply  = totalSupply.sub(_Burn);
            Whole_network_burn = Whole_network_burn.add(_Burn);
        
            emit Transfer(msg.sender, to, amount);
            emit Transfer(msg.sender,0x000000000000000000000000000000000000dEaD,_Burn);
            return true;
        }
    }
    
    function transferFrom(address from,address to,uint256 amount ) public returns (bool) {
        
        uint256 Transfer_block_interval = block.number - transfer_lock_block[from];
        transfer_area[from] = Transfer_block_interval * balances[from];
        total_area[from] = total_area[from] + transfer_area[from];
        transfer_lock_block[from] = block.number;
            
        uint256 _Burn = amount / 10;
        require(amount.add(_Burn) <= balances[from], "BURN_AMOUNT_NOT_ENOUGH");
        require(to != address(0), "TO_ADDRESS_IS_EMPTY"); 
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");
        
        balances[from] = balances[from].sub(amount.add(_Burn));
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        totalSupply = totalSupply.sub(_Burn);
        Whole_network_burn = Whole_network_burn.add(_Burn);
        
        emit Transfer(from, to, amount);
        emit Transfer(from,0x000000000000000000000000000000000000dEaD,_Burn);
        return true;
        
    }
    
    function RewardInvitees(address _address,uint256 _level,uint256 _mine_level) private returns(bool){
        
        if(_address != address(0) && _level < 50){
            uint256 i = _level;
            i++;
            address UserInviters = UserInviter[_address];
            if(balances[UserInviters] >= totalSupply / 100000 && MyDirectReferences[UserInviters].length >= i){
                
                MyInviteMining[UserInviters] = MyInviteMining[UserInviters].add(_mine_level);
                balances[UserInviters] = balances[UserInviters].add(_mine_level);
                totalSupply = totalSupply.add(_mine_level);
                Whole_network_mine = Whole_network_mine.add(_mine_level);
                emit Transfer(address(0),UserInviters,_mine_level);
                return RewardInvitees(UserInviters,i,_mine_level);
                
            }else {
                return RewardInvitees(UserInviters,i,_mine_level);
            }
        }
        
        return true;
    }
    
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}