/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// File: ERC20Interface.sol

pragma solidity ^0.8.0;

interface ERC20Interface {

    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8 );
    function totalSupply() external view returns (uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    

}
// File: TokenCreate.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Rebecca_Config {
  struct cfg {
     bytes32 key;
     uint256 ActiveTime;
     uint256 ExpTime;
     bool hasKey;
     bool isValue;
   }
}
contract Rebecca_System_Dev_1 is ERC20Interface{
    using Rebecca_Config for Rebecca_Config.cfg;

    string public _name = "Reb_test";
    string public _symbol = "RBT";
    uint8 public _decimals = 2;  // 2 小數點後兩位
    bool public _is_init_done = false;
    address owner;
    uint256 public _totalSupply;
    mapping(address => uint) public balances;

    mapping (address => uint256) public _balanceOf;
    mapping (address => mapping (address => uint256)) _allowance;
    
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public _is_Node;
    mapping(address => Rebecca_Config.cfg) _Rebecca_Config_Map;
    mapping(address => bool) public _Rebecca_Actived;

    uint256 public Use_Rebecca_Token_Num = 3000*10**uint256(_decimals);

    uint256 Node_Staking_Value = 10000*10**uint256(_decimals);

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Active_Rebecca(address indexed from);
    event UnActive_Rebecca(address indexed from);

    constructor() {
        owner = msg.sender;
        Init_Contract();
    }


    //授權轉移
    function Active_Transfer(address fromAddr,address toAddr,string memory new_key) public {
         require(msg.sender != address(0));
         require(_Rebecca_Config_Map[msg.sender].isValue==false);
         _UnActive_Rebecca(fromAddr);
         _Active_Rebecca(toAddr,new_key);

    }

    //初始化合約 創建初始流通量
    function Init_Contract() public {
        require(msg.sender == owner);
        require(_is_init_done == false,"This Contract is InitDone!");
        uint256 init_value = 6000*10000*10**uint256(_decimals); 
        
        _totalSupply += init_value;
        _balanceOf[owner] += init_value;
        _is_init_done = true;
        // emit Transfer(address(0), owner, init_value);


    }
    //批次轉帳
    function Batch_Transfer(address[] memory  recv_address_list,uint256 send_value)public returns(bool){
        uint all_recv_leng = recv_address_list.length;
        uint256 total_value = all_recv_leng * send_value;
        require(_balanceOf[msg.sender ] >= total_value);
        require( recv_address_list.length >= 1);

        for(uint256 i = 0 ; i < recv_address_list.length; i++){
            _transfer(msg.sender, recv_address_list[i], send_value);
        }
    }

    //加入節點
    function Add_Node() public {
        require(msg.sender != address(0));
        require(_balanceOf[msg.sender ] >= Node_Staking_Value);
        Be_Staking(Node_Staking_Value);
        _is_Node[msg.sender] = true;
    }
    
      //離開節點
    function Remove_Node() public {
        require(msg.sender != address(0));
        require(_balanceOf[msg.sender ] >= Node_Staking_Value);
        Un_Staking(Node_Staking_Value);
        _is_Node[msg.sender] = false;

    }

    //質押函數
    function Be_Staking(uint256 _Staking_Value) internal {

        require(msg.sender != address(0));
        require(_balanceOf[msg.sender ] >= _Staking_Value);
        _balanceOf[msg.sender]-=_Staking_Value;
        stakingBalance[msg.sender]+=_Staking_Value;

    }

    //解質押函數
    function Un_Staking(uint256 _Staking_Value)internal {
        require(msg.sender != address(0));
        require(stakingBalance[msg.sender ] >= _Staking_Value);
        stakingBalance[msg.sender]-=_Staking_Value;
          _balanceOf[msg.sender]+=_Staking_Value;
    }

    //初始化服務
    function Init_Rebecca_Services(string memory key_seed) public{
        require(msg.sender != address(0));
        require(_balanceOf[msg.sender]>=Use_Rebecca_Token_Num);
        require(_Rebecca_Config_Map[msg.sender].isValue==false);

        // _Rebecca_Config_Map[msg.sender].ExpTime = now + 1 month;
        
        burn(Use_Rebecca_Token_Num);
        _Active_Rebecca(msg.sender,key_seed);
        
    }
    function _UnActive_Rebecca(address addr) internal {
        require(_Rebecca_Config_Map[addr].isValue==true);
        
        _Rebecca_Config_Map[addr].isValue = false;
        _Rebecca_Actived[addr] =false;
        emit UnActive_Rebecca(addr);

    }
    function _Active_Rebecca(address addr,string memory key_seed) internal{

        if(_Rebecca_Config_Map[addr].hasKey == false){
            bytes32 key = Gen_Only_Key(key_seed);
            _Rebecca_Config_Map[addr].key = key; 
            _Rebecca_Config_Map[addr].hasKey = true;
        }

        _Rebecca_Config_Map[addr].isValue = true;
   

        _Rebecca_Config_Map[addr].ActiveTime = block.timestamp;
        _Rebecca_Config_Map[addr].ExpTime = block.timestamp + 30 days;
        _Rebecca_Actived[addr] = true;

        emit Active_Rebecca(addr);
    }

    //取得自身設定檔
    function Get_Self_Config() public view returns(bytes32 ){
        require(msg.sender != address(0));
        
        require(_Rebecca_Actived[msg.sender]==true);

        Rebecca_Config.cfg memory User_CFG = _Rebecca_Config_Map[msg.sender];
        // string memory end = string(abi.encodePacked(User_CFG.ActiveTime,User_CFG.ExpTime));
        // string memory end = string(User_CFG.key);
        // return end;
        return User_CFG.key;

    }


    function Gen_Only_Key(string memory input) internal returns(bytes32 hash_id){
        
        bytes32 id = keccak256(abi.encodePacked(input,msg.sender));
        return id;
        // emit hashResult(id);
    }
   function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}
    function burn(uint256 _value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);
        _balanceOf[msg.sender] -= _value;
        _totalSupply -= _value;
        emit  Burn(msg.sender, _value);
        return true;
    }

    function is_init_Done()public view returns(bool is_init_done){
        return _is_init_done;
    }
    function name() public view virtual override returns (string memory){
        return _name;
    }

    function symbol() public view virtual override returns (string memory){
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8 ){
        return _decimals;
    }
    function totalSupply() public view virtual override returns (uint256 ){
        return _totalSupply;
    }
    function balanceOf(address _owner) public  view virtual override returns (uint256 balance){
        balance = _balanceOf[_owner];
    }
    function _transfer(address _from, address _to, uint256 _value) internal virtual {
        require(_from != address(0));
        require(_to != address(0));
        require(_balanceOf[_from] >= _value);
        _balanceOf[msg.sender]-=_value;
        _balanceOf[_to]+=_value;
        emit Transfer(_from, _to, _value);
    }
    function _approve(address _owner, address _spender, uint256 _value) internal virtual {
        require(_owner != address(0));
        require(_spender != address(0)); 
        _allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }
    function transfer(address _to, uint256 _value) public virtual override returns (bool success){
        _transfer(msg.sender, _to, _value);
        success = true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool success){
        _transfer(_from, _to, _value);
        uint256 allowanceNum = _allowance[_from][_to];
        require(allowanceNum >= _value);
        _approve(_from, _to, allowanceNum - _value);
        success = true;
    }
    function approve(address _spender, uint256 _value) public virtual override returns (bool success){
        _approve(msg.sender, _spender, _value);
        success = true;
    }
    function allowance(address _owner, address _spender) public view virtual override returns (uint256 remaining){
        return _allowance[_owner][_spender];
    }
    function _mint(address _account, uint256 _value) internal virtual{
        require(_account != address(0));
        _totalSupply += _value;
        _balanceOf[_account] += _value;
        emit Transfer(address(0), _account, _value);
    }
    
}