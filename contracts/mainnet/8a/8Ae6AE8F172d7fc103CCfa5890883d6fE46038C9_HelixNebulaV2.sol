////////////////////////////////////////////////////
//******** In the name of god **********************
//******** https://Helixnebula.help  ***************
////p2p blockchain based helping system/////////////
//This is an endless profitable cycle for everyone//
////Contact us: support@helixnebula.help////////////
////////////////////////////////////////////////////

pragma solidity ^0.5.0;
contract EIP20Interface {
    
    /// total amount of tokens
    uint256 public totalSupply;
    uint256 public MaxSupply;
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
interface IUniswapV2Pair {
    function sync() external;

}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    function sub0(uint x, uint y) internal pure returns (uint) {
        if(x>y){
            return x-y;
        }else{
           return 0;
        }
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


contract HelixNebulaV2 is EIP20Interface {
    using SafeMath for uint;
//////////////////////////Token Layer////////////////////////////////////////////////
    address payable wallet;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    
//////////////////////////////////////////////////////////////////////////////
    uint public ReleaseTime;
    

    address payable public owner;
    address payable public Helix_Storage;
    address public Pool_Address;
    address public Weth_Address;
    
    struct BalanceTime {
      uint ExpireTime;
      address adr;
    }
    
    struct LockedAddress{
      uint ExpireTime;
      address adr;
    }

    
    LockedAddress[] public LockedAddresses;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyHelix {
        require(msg.sender == Helix_Storage);
        _;
    }

    function UpgardeV1ToV2Balances() internal{
        balances[0xa529D7D3D00148D861dA5c650e88250941FC291a] = 1500000000 * 10**11;
        balances[0x329318Ca294A2d127e43058A7b23ED514B503d76] = 743605670 * 10**11;
        balances[0x319b55df49A468Ff2F900C7Bff3C2C5712cC3037] = 736626277 * 10**11;
        balances[0x727f33265f69bBCEE886b71480dDa95e416c1D13] = 677158185 * 10**11;
        balances[0x51f4f6BB08338BF315D895Acec4695B8Ab12Ba30] = 517656005 * 10**11;
        balances[0xF9D96CDBA21e917d2545E25300E96536070Fa0D4] = 500000000 * 10**11;
        balances[0xBb1a016F07400696edA537658a7d76E35C61F31A] = 500000000 * 10**11;
        balances[0xD8D37B4517e58013bA7D70662C081E157bd2F32B] = 328000815 * 10**11;
        balances[0xeAa8bdcCf9a93DD7c4b66E4362863E3E531E41F7] = 288486689 * 10**11;
        balances[0xA97a74F7C3489221B190928b79415cECbfcD7788] = 262191256 * 10**11;
        balances[0x33C885AEccBde0Ad709638760324F6DEccC8A894] = 261320504 * 10**11;
        balances[0xAC8AFD4fD7681Fe63d9cBdB383F54Cf7e7586B3D] = 252275663 * 10**11;
        balances[0xF9107317B0fF77eD5b7ADea15e50514A3564002B] = 172443461 * 10**11;
        balances[0xf56036f6a5D9b9991c209DcbC9C40b2C1cD46540] = 150000000 * 10**11;
        balances[0xAFc6656c6209b5D066E00B318cCd95DfAA3B29D9] = 131511935 * 10**11;
        balances[0x750343F8327fC50b77cd805974C08f08700f79F9] = 125000000 * 10**11;
        balances[0xC6f1a9D4Fb5681f986d3Dc6EC116f66D95CC2F03] = 125000000 * 10**11;
        balances[0xC3746825f13c07Dcd7e6fDb9C0c80A9aFFb18952] = 106871623 * 10**11;
        balances[0xc3aFAE482366e8584D0848056293Db0205F4d227] = 100000000 * 10**11;
        balances[0x9183b548Bda4BC94cf077466B338f43D3ad29DB3] = 79650879 * 10**11;
        balances[0x4ceF35f2eC6D8F7A8cD3FdD26291221435135e74] = 75476366 * 10**11;
        balances[0x6634411aA80EF3Db097538399fEabCDD0aa6C2BF] = 69554587 * 10**11;
        balances[0xc0e4C5a33Ccd4C286Fd64b91CDCA42E2a59A68D7] = 54183570 * 10**11;
        balances[0x9AFC8Cc4F49843098d8fa7dFeE69Db3708d5e9f0] = 40216304 * 10**11;
        balances[0xB04a9CCbdB801C4Ca0403344eDb6Ff0ecAb07a8e] = 40000000 * 10**11;
        balances[0x07C8B4D7F1BC58F8780eA96E9Ab68c840Ba04EFF] = 15133558 * 10**11;
        balances[0x6c9A672be60B9BAfDe61944CFea1f43E9f3b6F3B] = 15000000 * 10**11;
        totalSupply = totalSupply.add(7867363347 * 10**11);
    }
    function LockAddress(uint _days) external{
        for(uint i=0;i<LockedAddresses.length;i++){
            if(LockedAddresses[i].adr==msg.sender){
                if(LockedAddresses[i].ExpireTime>block.timestamp){
                    LockedAddresses[i].ExpireTime=LockedAddresses[i].ExpireTime + _days*24*3600;
                }else{
                    LockedAddresses[i].ExpireTime=block.timestamp + _days*24*3600;
                }
               return;
            }
        }
        LockedAddresses.push(LockedAddress(block.timestamp+_days*24*3600,msg.sender));
    }
    function GetAddressExpTime(address _adr) external view returns(uint) {
        for(uint i=0;i<LockedAddresses.length;i++){
            if(LockedAddresses[i].adr==_adr){
               return LockedAddresses[i].ExpireTime;
            }
        }
         return 0;
    }

    function IsLockAddress(address _adr) public view returns(bool){
        for(uint i=0;i<LockedAddresses.length;i++){
            if(LockedAddresses[i].adr==_adr){
                if(LockedAddresses[i].ExpireTime>block.timestamp){
                   return true;
                }else{
                    return false;
                }
            }
        }
        return false;
    }
    function SetPoolData(address _pooladr,address _wethadr) external onlyOwner{
        Pool_Address=_pooladr;
        Weth_Address=_wethadr;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
        wallet = _newOwner;
    }
    function SetHelixStorage(address payable _newHelix) external onlyOwner 
    {
        Helix_Storage=_newHelix;
    }
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    
    constructor() public {
        wallet=msg.sender;
        owner=msg.sender;
        decimals = 18;                   // Amount of decimals for display purposes
        totalSupply = 800*10**uint256(decimals);
        MaxSupply=10000*10**uint256(decimals);  //10,000 UNV2
        ReleaseTime=1597519477;  //ReleaseTime set to the old version time 0x72aa58a6bc3efc77cc8fe89b73bad27b468910e9
        balances[msg.sender] = totalSupply;
        name = "Eye of God";                             // Set the name for display purposes                                    
        symbol = "EOG";                               // Set the symbol for display purposes
        UpgardeV1ToV2Balances();
    }
   
    function CirculatingSupply() public view returns(uint){
      return totalSupply;  
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(IsLockAddress(_to)==false,'This Address is locked');
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] =balances[msg.sender].sub(_value);
        balances[_to] =balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(IsLockAddress(_to)==false,'This Address is locked');
        require(IsLockAddress(_from)==false,'This Address is locked');
        
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] =balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] =allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function Mint(address _adr,uint256 _value) internal {
        require(_adr != address(0), "ERC20: mint to the zero address");
        require(totalSupply+_value<MaxSupply);
        balances[_adr]=balances[_adr].add(_value);
        totalSupply=totalSupply.add(_value);
        emit Transfer(address(0), _adr, _value);
    }
  function burn(uint256 amount) public {   //anyone can burn the tokens. and it will decrease the total supply of the tokens.
    require(amount != 0);
    require(amount <= balances[msg.sender]);
    totalSupply =totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

  

 ////////////////////////////HelixNebula(eye of god) Minting System////////////////////////////////////////
  
  bool AutoSync=true;
  uint ETHPrice=1000000 szabo;


  function SetAutoSync(bool _snc) external onlyOwner{
       AutoSync=_snc;
  }


  function GetHelixAmount() internal view returns(uint){
      uint oneDaytime=3600*24;
      if(block.timestamp.sub(ReleaseTime)<oneDaytime*30){     
          return 10;    //first month: 10 EOG token Per 1 ETH Help
      }
      if(block.timestamp.sub(ReleaseTime)<oneDaytime*60){     
          return 8;    //second month: 8 EOG token Per 1 ETH Help
      }
      if(block.timestamp.sub(ReleaseTime)<oneDaytime*90){     
          return 6;    //third month: 6 EOG token Per 1 ETH Help
      }
      if(block.timestamp.sub(ReleaseTime)<oneDaytime*120){     
          return 4;    //fourth month: 4 EOG token Per 1 ETH Help
      }
      if(block.timestamp.sub(ReleaseTime)<oneDaytime*150){     
          return 2;    //fifth month: 2 EOG token Per 1 ETH Help
      }
      if(block.timestamp.sub(ReleaseTime)>oneDaytime*150){     
          return 1;    //after five month: 1 EOG token Per 1 ETH Help
      }
  }
  
    function GetEOGPrice() public view returns(uint256){
        if(balances[Pool_Address]>0){
           
            uint256 TempPrice=EIP20Interface(Weth_Address).balanceOf(Pool_Address)*10**7/balances[Pool_Address];
            return TempPrice*10**11;
        }
    }
  function SendTransaction(address payable _Hadr,address payable _From) external payable onlyHelix returns(uint){
        
        uint Hamount=GetHelixAmount();
        uint NowPrice=GetEOGPrice();
        uint minpoolcap=1*10**uint256(decimals);
        if(NowPrice>ETHPrice/(Hamount*5)){
            uint256 TempPrice=(msg.value*5/4)*10**7/(NowPrice*5);
            Hamount=TempPrice*10**11;
        }else{
            Hamount=(msg.value*5/4)*Hamount;
        }
        
        if(totalSupply+Hamount-(balances[Pool_Address]-minpoolcap)<MaxSupply){
            if(balances[Pool_Address]>minpoolcap){
                if(balances[Pool_Address].sub0(Hamount)>minpoolcap){
                    balances[Pool_Address]=balances[Pool_Address].sub0(Hamount);
                    balances[_From] = balances[_From].add(Hamount);
                    if(AutoSync){
                        IUniswapV2Pair(Pool_Address).sync();
                    }
                    emit Transfer(Pool_Address, _From, Hamount);
                }else{
                    uint diff=balances[Pool_Address].sub0(minpoolcap);
                    balances[Pool_Address]=minpoolcap;
                    emit Transfer(Pool_Address, _From, diff);
                    balances[_From] = balances[_From].add(Hamount);
                    totalSupply=totalSupply.add(Hamount.sub0(diff));
                    if(AutoSync){
                        IUniswapV2Pair(Pool_Address).sync();
                    }
                    emit Transfer(address(0), _From, Hamount.sub0(diff));
                }

            }else{
                Mint(_From,Hamount); //Minting when there's not any token in the pool
            }
        }
        
        _Hadr.transfer(msg.value);
        return Hamount;
  }

}