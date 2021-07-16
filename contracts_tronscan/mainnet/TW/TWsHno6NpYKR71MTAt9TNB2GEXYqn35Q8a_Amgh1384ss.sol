//SourceUnit: airdrop.sol

pragma solidity ^ 0.5.10;
contract TRC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ITRC20 is TRC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Amgh1384ss{
    mapping(address=>bool) gat;
      mapping(address=>bool) shadmehr;
       mapping(address=>bool) dollararmy;
       mapping(uint256=>address) Token_Contract;
        mapping(address=>bool) ck;
        address Owner;
        address gat_address;
        constructor() public{
            Owner=msg.sender;
        }
        function transferOwnership(address _wallet) public{
            require(msg.sender==Owner);
            Owner=_wallet;
        }
        function Setcontract(uint256 _Token_Id,address _contract_address)  public{
            require(msg.sender==Owner,"only admin");
            Token_Contract[_Token_Id]=_contract_address;
            
        }
        function Get_Gat() public returns(string memory){
            require(gat[msg.sender] != true,"you get token before");
            ITRC20(Token_Contract[1]).transfer(msg.sender,msg.sender.balance*10);
            gat[msg.sender]=true;
                 return "token is on your wallet";
        }
                function Get_shadmehr() public returns(string memory){
            require(shadmehr[msg.sender] != true,"you get token before");
            ITRC20(Token_Contract[2]).transfer(msg.sender,msg.sender.balance*2);
            shadmehr[msg.sender]=true;
                 return "token is on your wallet";
        }
                        function Get_dollararmy() public returns(string memory){
            require(dollararmy[msg.sender] != true,"you get token before");
            ITRC20(Token_Contract[3]).transfer(msg.sender,msg.sender.balance*5);
            dollararmy[msg.sender]=true;
                 return "token is on your wallet";
        }
                        function Get_cryptoking() public returns(string memory){
            require(ck[msg.sender] != true,"you get token before");
            ITRC20(Token_Contract[4]).transfer(msg.sender,msg.sender.balance*5);
            ck[msg.sender]=true;
            return "token is on your wallet";
        }
        function withdraw_trc20(address _tokenconaddress,uint256 _Tokenamount) public{
            require(msg.sender==Owner,"only admin");
            ITRC20(_tokenconaddress).transfer(msg.sender,_Tokenamount);
        }
    
}