pragma solidity 0.4.25;
library SMTH{
    function safeMul(uint256 a, uint256 b)internal pure returns(uint256){if(a==0){return 0;}uint256 c=a*b;assert(c/a==b);return c;}
    function safeDiv(uint256 a, uint256 b)internal pure returns(uint256){uint256 c=a/b;return c;}
    function safeSub(uint256 a, uint256 b)internal pure returns(uint256){assert(b<=a);return a-b;}
    function safeAdd(uint256 a, uint256 b)internal pure returns(uint256){uint256 c=a+b;assert(c>=a);return c;}}
contract ERC20{
    function totalSupply()public constant returns(uint256);
    function balanceOf(address tokenOwner)public constant returns(uint256 balance);
    function allowance(address tokenOwner,address spender)public returns(uint256 remaining);
    function transfer(address to,uint256 tokens)public returns(bool success);
    function approve(address spender,uint256 tokens)public returns(bool success);
    function transferFrom(address from,address to,uint256 tokens)public returns(bool success);
    event Transfer(address indexed from,address indexed to,uint256 tokens);
    event Approval(address indexed tokenOwner,address indexed spender,uint256 tokens);}
contract ApproveAndCallFallBack{
    function receiveApproval(address from,uint256 tokens,address token,bytes data)public;}
contract OWN{
    address public owner;address public newOwner;
    event OwnershipTransferred(address indexed _from,address indexed _to);
    modifier onlyOwner{require(msg.sender==owner);_;}
    function transferOwnership(address _newOwner)public onlyOwner{newOwner = _newOwner;}
    function acceptOwnership()public{require(msg.sender==newOwner);
    emit OwnershipTransferred(owner,newOwner);owner=newOwner;newOwner=address(0);}}
contract ALFA is ERC20, OWN{
    using SMTH for uint256;
    string public constant name="HIDDEN ETHEREUM WALLET";
    string public constant symbol="HETH";
    uint8  public constant decimals=18;
    uint256 internal constant IcoSup=20000000*10**18;
    uint256 internal constant StdSup=50000000*10**18;
    uint256 internal constant IcoM=300;
    uint256 internal constant IcoP=330;
    uint256 internal constant SecM=200;
    uint256 internal constant SecP=220;
    uint256 internal constant EndM=100;
    uint256 internal constant EndP=110;
    uint256 internal        CoSup=10000000*10**18;
    uint256 internal _totalSupply=100000000*10**18;
    mapping(address => mapping(address => uint256))allowed;
    mapping(address => uint256)public btreg;
    mapping(address => uint256)internal balances;
    uint256 public stage0;
    uint256 public stage1;
    uint256 public stage2;
    uint256 public stage3;
    constructor()public payable{
        owner=msg.sender;
        balances[owner]=10000000*10**18;
        balances[address(this)]=90000000*10**18;
        stage0=1551398400; //Friday, March 1, 2019
        stage1=1552176000; //Sunday, March 10, 2019
        stage2=1554076800; //Monday, April 1, 2019
        stage3=1556668800; //Wednesday, May 1, 2019
        
        emit Transfer(address(0),owner,balances[owner]);
        emit Transfer(address(0),address(this),balances[address(this)]);}

    function totalSupply()public constant returns(uint){return _totalSupply;}
    function ownedSupply()public constant returns(uint){return CoSup;}
    
    function balanceOf(address tokenOwner)public constant returns(uint256 balance){return balances[tokenOwner];}
    
    function transfer(address to, uint256 tokens)public returns(bool success){
        require( block.timestamp>stage0); 
        
        require(CoSup>=_totalSupply || block.timestamp>stage3);require(to!=address(0));
        
        balances[msg.sender]=balances[msg.sender].safeSub(tokens);
        balances[to]=balances[to].safeAdd(tokens);
        
        emit Transfer(msg.sender,to,tokens);return true;}
    
    function transferFrom(address from, address to, uint256 tokens)public returns (bool success){
        require( block.timestamp>stage0); 
        require(CoSup>=_totalSupply || block.timestamp>stage3);require(to!=address(0));
        require(allowed[from][msg.sender]>=tokens);
        allowed[from][msg.sender]=allowed[from][msg.sender].safeSub(tokens);
        balances[from]=balances[from].safeSub(tokens);
        balances[to]=balances[to].safeAdd(tokens);
        emit Transfer(from,to,tokens);return true;}
        
    function approve(address spender, uint256 tokens)public returns(bool success){
        require( block.timestamp>stage0);require(CoSup>=_totalSupply || block.timestamp>stage3);
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender,spender,tokens);return true;}
    
    function allowance(address tokenOwner, address spender)public returns(uint256 remaining){
        return allowed[tokenOwner][spender];}

    function approveAndCall(address spender, uint256 tokens, bytes data)public returns(bool success){
        require( block.timestamp>stage0);require(CoSup>=_totalSupply || block.timestamp>stage3);
        allowed[msg.sender][spender]=tokens;emit Approval(msg.sender,spender,tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender,tokens,this,data);return true;}
    
    function timeStamp()public view returns(uint256){
        return block.timestamp;}
    
    function Th_stage0(uint256 value)public onlyOwner{stage0=value;}
    function Th_stage1(uint256 value)public onlyOwner{stage1=value;}
    function Th_stage2(uint256 value)public onlyOwner{stage2=value;}
    function Th_stage3(uint256 value)public onlyOwner{stage3=value;}
    
    function bytesToAddress(bytes source)internal pure returns(address addr){assembly{addr:=mload(add(source,0x14))}return addr;}
    function isContract(address addr)internal view returns(bool){uint size;assembly{size:=extcodesize(addr)}return size>0;} 
    function transferAnyERC20Token(address tokenAddress, uint256 tokens)public onlyOwner returns(bool success){
        require(tokenAddress!=address(this));
        return ERC20(tokenAddress).transfer(owner, tokens);}
        
    function register()public{btreg[msg.sender]=1;}

    function()public payable
    {
        require( block.timestamp>stage0); 
        if(CoSup<_totalSupply || block.timestamp<stage3){
            
            btreg[msg.sender]=1;
            require(msg.value>10**16); 
            
            address ref = bytesToAddress(msg.data);
            uint256 CoFw;
            CoFw=EndM;
            
            if(ref!=address(0)){
                CoFw=EndP;
                require(ref!=msg.sender);
                require(isContract(ref)==false);
                require(btreg[ref]==1);
                if(CoSup<StdSup || block.timestamp<stage2){
                    CoFw=SecP;
                }
                if(CoSup<IcoSup || block.timestamp<stage1){
                    CoFw=IcoP;
                }
            }
            else
            {
                if(CoSup<StdSup || block.timestamp<stage2){
                    CoFw=SecM;
                }
                if(CoSup<IcoSup || block.timestamp<stage1){
                    CoFw=IcoM;
                }
            }
            uint256 tokens=msg.value.safeMul(CoFw);
            require(tokens>0);
            if(ref!=address(0)){
                require(ref!=msg.sender);
                require(isContract(ref)==false);
                require(btreg[ref]==1);
                uint256 bounty=tokens.safeDiv(10);
                
                assert(balances[ref].safeAdd(bounty)>balances[ref]);
                require(balances[address(this)]>=(bounty+tokens));
                
                CoSup=CoSup.safeAdd(bounty);
                emit Transfer(address(0), ref, bounty);
                
                balances[ref]=balances[ref].safeAdd(bounty);
                balances[address(this)]=balances[address(this)].safeSub(bounty);
            }
            
            assert(balances[msg.sender].safeAdd(tokens)>balances[msg.sender]);
            require(balances[address(this)]>=tokens);
            CoSup=CoSup.safeAdd(tokens);
            emit Transfer(address(0), msg.sender, tokens);
            
            balances[msg.sender]=balances[msg.sender].safeAdd(tokens);
            
            balances[address(this)]=balances[address(this)].safeSub(tokens);
            
            owner.transfer(msg.value);
        }
        
        else {revert();}}
}