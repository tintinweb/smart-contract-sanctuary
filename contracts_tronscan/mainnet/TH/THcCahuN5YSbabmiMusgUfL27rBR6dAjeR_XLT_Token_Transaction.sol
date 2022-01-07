//SourceUnit: XLT_Token_Transaction.sol


pragma solidity ^0.5.10;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract XLT_Token_Transaction{
    
    
    
    address payable owner;
    address public tokenAddress;
    uint256 Totaldeposited;
    uint256 Totalwithdrawal;
    
    mapping(address => mapping (uint256 => address)) subOwner;
    
    
    constructor(address payable _owner,address _token) public 
    {
        
        owner = _owner;
        tokenAddress = _token;
        
    }
    
    event TransferAmount(address indexed from, address indexed to, uint256 value,uint256 time);
    event TransferFromOwner(address indexed SubOwneraddress,address indexed from, address indexed to, uint256 value,uint256 time);
    //========Modifiers========
    modifier SubOwner(){
    require(msg.sender==owner || msg.sender==subOwner[owner][1]|| msg.sender==subOwner[owner][2]|| msg.sender==subOwner[owner][3]|| msg.sender==subOwner[owner][4]|| msg.sender==subOwner[owner][5], "you are not subowner");
    _;
    }
    modifier onlyOwner(){
    require(msg.sender==owner,"you are not owner " );
    _;
    }
    
    
    
    
    
    
    
     function TransferCoin(address recipient,uint256 amount) public SubOwner
    {
        IERC20(tokenAddress).transfer(recipient,  amount);
        Totalwithdrawal = Totalwithdrawal +amount;
        emit TransferFromOwner(msg.sender,address(this),recipient,amount,block.timestamp);
        
    }


        function multisendToken( address[] calldata _contributors, uint256[] calldata _balances) external  SubOwner {
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
             IERC20(tokenAddress).transfer(_contributors[i], _balances[i]);
            }
        }
    
    
    
    
     function SetSubOwner(address sunowner,uint256 id) public onlyOwner
    {
        require(id > 0 && id < 6 ," wrong Id");
        subOwner[msg.sender][id] = sunowner;
    }
    
    
    
    
    
     function RemoveSubOwner(uint256 id) public onlyOwner
    {
        require(id > 0 && id < 6 ," wrong Id");
        subOwner[msg.sender][id] = owner;
    }
    
    
    
    
    function ChecksubOwner(uint256 _id) public view returns(address _subOwner){
        
        require(_id <= 5 && _id > 0,"wrong id");
        return subOwner[owner][_id];
    }
    
        
        
    
      function Deposite(uint256 amount) public
    {
        IERC20(tokenAddress).transferFrom(msg.sender,address(this),amount);
        Totaldeposited = Totaldeposited + amount;
        emit TransferAmount (msg.sender,address(this),amount,block.timestamp);
        
    }
    
    
    function CheckTotalwithdrawal() public view  returns(uint256)
    {
        return  Totalwithdrawal;
    }
    
    function CheckTotaldeposited() public view  returns(uint256)
    {
        return  Totaldeposited;
    }
    
    
    
    function CheckBalance(address account) public view  returns(uint256)
    {
        return  IERC20(tokenAddress).balanceOf( account);
    }
    
    
    function CheckContractBalanceofCoin() public view  returns(uint256)
    {
        return  IERC20(tokenAddress).balanceOf(address(this));
    }
    
    
     function CheckContractBalance() public view  returns(uint256)
    {
        return  address(this).balance;
    }
    
    
    function withdrawa(uint256 amount) public onlyOwner 
    {
        require(amount <= address(this).balance , "not have Balance");
        require(amount >= 0 , "not have Balance");
        owner.transfer(amount*(10**6));
    }
}