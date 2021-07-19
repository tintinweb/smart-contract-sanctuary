//SourceUnit: nameTransferv1.sol

/* Designed And Developed By AmirHosseinGhadimiZadeh  https://t.me/amgh1384ss  */
pragma solidity 0.5.10;

contract NameService{
    uint256 constant RegisterFee=3000000;
    address payable Admin;
    mapping(string=>address payable) public Relation;
    mapping(address =>string) public RelationReverse;
    mapping(string=>bool) public IsRegisterd;
    mapping(address=>bool) public IsUsed;
    event RegisterName(string indexed,address);
    event TransferTron(string indexed,address,address);
    event ChangeName(string indexed,string indexed,address);
    constructor() public{
        Admin=msg.sender;
    }
    modifier onlyowner{
        require(msg.sender==Admin,"unauthorized access denied");
        _;
    }
    function Register(string memory Name,address payable Wallet) public payable returns(string memory){
        require(msg.tokenid==0 &&msg.value==RegisterFee&&IsRegisterd[Name]==false&&msg.sender==Wallet&&IsUsed[msg.sender]==false,"Just Set 3 Trx and UnRegisterd WalletName");
        Relation[Name]=Wallet;
        RelationReverse[Wallet]=Name;
        IsRegisterd[Name]=true;
        IsUsed[msg.sender]=true;
        emit RegisterName(Name,Wallet);
        return "Register Successfully";
    }
    function ShowName(address ReqAddress) public view returns(string memory){
        return RelationReverse[ReqAddress];
    }
    function ShowNameMsgSender() public view returns(string memory){
        return RelationReverse[msg.sender];
    }
    function TransferTrx(string memory WalletName) public payable returns(string memory){
        require(msg.tokenid==0&&IsRegisterd[WalletName]==true&&Relation[WalletName]!=address(0),"Just Tron and Correct Wallet");
        Relation[WalletName].transfer(msg.value);
        emit TransferTron(RelationReverse[Relation[WalletName]],msg.sender,Relation[WalletName]);
        return "transfer Compeleted";
    }
    function ChangeWalletName(string memory Name,address payable Wallet) public payable returns(string memory){
         require(msg.tokenid==0 &&msg.value==RegisterFee+7000000&&IsRegisterd[Name]==false&&IsUsed[msg.sender]==true&&msg.sender==Wallet,"transaction faild");
         string memory Pname=RelationReverse[msg.sender];
         IsRegisterd[RelationReverse[msg.sender]]=false;
         delete Relation[RelationReverse[msg.sender]];
         delete RelationReverse[msg.sender];
         Relation[Name]=Wallet;
         RelationReverse[Wallet]=Name;
         IsRegisterd[Name]=true;
         emit ChangeName(Pname,Name,Wallet);
         return "Name Changed Successfully";
    }
    function WithDrawFee(uint256 _amount) public onlyowner{
        Admin.transfer(_amount);
        /*just for withdraw 3trx fee users pay for registration and dont have any relation with transfertrx function*/
    }
}