pragma solidity ^0.4.24;
pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
contract Base {

    using SafeMath for uint256;
    address public owner;
    
    struct Client {
        uint256 Tokens;
        address Owner;
        uint256 Category;
        uint256[] LoansID;
    }
    struct Bank {
        uint256 Tokens;
        address Owner;
     
        mapping (uint256=>strCateg) Category;
        uint256[] LoansID;
        Loan[] LoanPending;
        Portfolio[] Portfolios;
    }
    struct strCateg{
        mapping(uint256=>strAmount) Amount;
    }
    struct strAmount{
        mapping(uint256=>strInsta) Installment;
    }
    struct strInsta{
        uint256 value;
        bool enable;
    }
    struct Loan{
            uint256 Debt;

            uint256 Installment;
            uint256 Id;
            uint256 ForSale;
            address Client;
            address Owner;
            uint256 Category;
            uint256 Amount;
            uint256 StartTime;
            uint256 EndTime;
    }
    struct Portfolio{
        uint256[] idLoans;
        address Owner;
        uint256 forSale;
    }
    
    mapping(address => Client) clients;
    mapping(address => Bank) banks;
    Loan[] loans;
    
    function () public payable{
        require(false, "Should not go through this point");
    }

 
}
contract ClientFunctions is Base{
    // funciones del usuario
    modifier isClient(){
        require(clients[msg.sender].Owner == msg.sender, "not a client");
        _;
    }
    // esta funcion es llamada por el cliente para pedir un prestamo
    function askForALoan(address _bankAddress, uint256 _amount, uint256 _installment) isClient public  {
        
        require(banks[_bankAddress].Owner==_bankAddress, "not a valid bank");
        require(banks[_bankAddress].Category[clients[msg.sender].Category].Amount[_amount].Installment[_installment].enable, "you not apply for that loan");

        Loan memory _loan;
        _loan.Debt = _amount;
        _loan.Debt  = _loan.Debt.add(banks[_bankAddress].Category[clients[msg.sender].Category].Amount[_amount].Installment[_installment].value);
        
        _loan.Client = msg.sender;
        _loan.Owner = _bankAddress;
        _loan.Installment = _installment;
        _loan.Category = clients[msg.sender].Category;
        _loan.Amount = _amount;
        
        banks[_bankAddress].LoanPending.push(_loan);
        
        

    }
    
    function findOutInterestByClientCategory(address _bankAddress, uint256 _amount, uint256 _installment) isClient public view returns(uint256 _value, bool _enable){
        _value = banks[_bankAddress].Category[clients[msg.sender].Category].Amount[_amount].Installment[_installment].value;
        _enable = banks[_bankAddress].Category[clients[msg.sender].Category].Amount[_amount].Installment[_installment].enable;
    }
    // esta funcion es llamada por el cliente, cuando el banco central (estado) le otorga el dinero 
    function removeClientToken(uint256 _value) isClient public{
        require(clients[msg.sender].Tokens >= _value, "You don&#39;t have that many tokens");
        clients[msg.sender].Tokens = clients[msg.sender].Tokens.sub(_value);
    }
    // esta funcion es llamada por cliente para saber cuantos Tokens le quedan disponibles
    function getClientBalance() isClient public view returns (uint256 _value){
        _value = clients[msg.sender].Tokens;
    }
    

    function getLoansLengthByClient() isClient public view returns(uint256){
        return clients[msg.sender].LoansID.length;
    }
    function getLoanIDbyClient(uint256 _indexLoan) isClient public view returns (uint256){
        return clients[msg.sender].LoansID[_indexLoan];
    }
    function getClientCategory() isClient public view returns(uint256){

        return clients[msg.sender].Category;
    } 
}
contract BankFunctions is ClientFunctions{
    modifier isBank(){
        require(banks[msg.sender].Owner==msg.sender, "you are not a bank");
        _;
    }
    modifier isLoanOwner(uint256 _id) {
        require(banks[msg.sender].Owner==msg.sender, "you are not a bank");
        require(loans[_id].Owner == msg.sender, "not owner of loan");
        _;
    }
    
    function GetClientCategory(address _client) isBank public view returns(uint256){

        return clients[_client].Category;
    } 
    
    function removeBankToken(uint256 _value) isBank public{
        require(banks[msg.sender].Tokens >= _value, "You don&#39;t have that many tokens");
        banks[msg.sender].Tokens = banks[msg.sender].Tokens.sub(_value);
    }
    // funcion llamada por el banco owner del Loan, permite saldar la deuda
    function payOffClientDebt(uint256 _loanId, uint256 _value)  isLoanOwner(_loanId) public{

        // checkear datos
        require(loans[_loanId].Debt > 0);
        require(_value > 0);
        require(loans[_loanId].Debt>= _value);
        loans[loans.length-1].EndTime = now;
        loans[_loanId].Debt = loans[_loanId].Debt.sub(_value);
    

    }
    
    function ChangeInterest(uint256 _category, uint256 _amount, uint256 _installment, uint256 _value, bool _enable) isBank public{
        banks[msg.sender].Category[_category].Amount[_amount].Installment[_installment].value = _value;
        banks[msg.sender].Category[_category].Amount[_amount].Installment[_installment].enable = _enable;
    }
    // retorna el balance en tokens del banco
    function GetBankBalance() isBank public view returns (uint256 ){
        return banks[msg.sender].Tokens;
    }
    function findOutInterestByBank(uint256 _category, uint256 _amount, uint256 _installment) isBank public view returns(uint256 _value, bool _enable){
        _value = banks[msg.sender].Category[_category].Amount[_amount].Installment[_installment].value;
        _enable = banks[msg.sender].Category[_category].Amount[_amount].Installment[_installment].enable;
    }

    
}
contract LoansFunctions is BankFunctions{

    
    // asigna un valor al Loan para ser comprado por otro banco
    function SellLoan(uint256 _loanId, uint256 _value) isLoanOwner(_loanId)  public {
        loans[_loanId].ForSale = _value;
    }
    
    // permite comprar con Tokens un Loan
    function BuyLoan(address _owner, uint256 _loanId, uint256 _value)  isBank public{
        require(loans[_loanId].ForSale > 0, "not for sale");
        require(banks[msg.sender].Tokens>= _value, "you dont have money");
        // asignar Loan
        SwitchLoanOwner( _owner,  _loanId);        
        
        //intercambio de dinero
        banks[msg.sender].Tokens = banks[msg.sender].Tokens.sub(_value);
        banks[_owner].Tokens = banks[_owner].Tokens.add(_value);
    }
    //funcion interna para intercambiar el due&#241;o del Loan
    
    function SwitchLoanOwner(address _owner, uint256 _loanId) internal{
        //requisitos
        require(loans[_loanId].Debt> 0, "at least one of the loans is already paid");
        require(loans[_loanId].Owner == _owner);
        uint256 _indexLoan;
        for (uint256 i; i<banks[_owner].LoansID.length; i++){
            if (banks[_owner].LoansID[i] == _loanId){
                _indexLoan = i;
                i =  banks[_owner].LoansID.length.add(1);
            }
        }


        // asignar Loan
        banks[msg.sender].LoansID.push(_loanId);
        
        if (_indexLoan !=banks[_owner].LoansID.length - 1){
                banks[_owner].LoansID[_indexLoan] = banks[_owner].LoansID[banks[_owner].LoansID.length - 1];         
        }
        
        delete banks[_owner].LoansID[banks[_owner].LoansID.length -1];
        banks[_owner].LoansID.length --;
        
        loans[_loanId].ForSale = 0;
        loans[_loanId].Owner = msg.sender;
        
        
        
    }
    
    function aproveLoan(uint256 _loanIndex) public {
        require(banks[msg.sender].LoanPending[_loanIndex].Owner == msg.sender, "you are not the owner");
        require(banks[msg.sender].Tokens>=banks[msg.sender].LoanPending[_loanIndex].Amount, "the bank does not have that amount of tokens");

        banks[msg.sender].LoanPending[_loanIndex].Id =loans.length;
        loans.push(banks[msg.sender].LoanPending[_loanIndex]);
        loans[loans.length-1].StartTime = now;
        address _client = banks[msg.sender].LoanPending[_loanIndex].Client;
        uint256 _amount  = banks[msg.sender].LoanPending[_loanIndex].Amount;
        
        banks[msg.sender].LoansID.push(loans.length - 1);
        clients[_client].LoansID.push(loans.length - 1);
        
        clients[_client].Tokens =  clients[_client].Tokens.add(_amount);
        banks[msg.sender].Tokens =  banks[msg.sender].Tokens.sub(_amount);

        
        if(banks[msg.sender].LoanPending.length !=1){
            banks[msg.sender].LoanPending[_loanIndex] = banks[msg.sender].LoanPending [banks[msg.sender].LoanPending.length - 1];    
        }

        delete banks[msg.sender].LoanPending [banks[msg.sender].LoanPending.length - 1];
        banks[msg.sender].LoanPending.length--;

    }
    // en caso de pasar true como parametro revisa las deudas aun no aprobadas
    function GetLoansLenght(bool _pending) public isBank view returns (uint256) {
        if (_pending){
            return banks[msg.sender].LoanPending.length;    
        }else{
            return banks[msg.sender].LoansID.length;
        }
        
    }
    function GetLoanInfo(uint256 _indexLoan, bool _pending)  public view returns(uint256 _debt, address _client, uint256 _installment, uint256 _category , uint256 _amount, address _owner, uint256 _forSale, uint256 _StartTime, uint256 _EndTime){
        
        Loan memory _loan;
        if (_pending){
            require (_indexLoan < banks[msg.sender].LoanPending.length, "null value");
            _loan = banks[msg.sender].LoanPending[_indexLoan];
        }else{
            _loan = loans[_indexLoan];
        }
        
        _debt = _loan.Debt;
        _client =  _loan.Client;
        _installment =  _loan.Installment;
        _category = _loan.Category;
        _amount = _loan.Amount ;
        _owner = _loan.Owner ;
        _forSale = _loan.ForSale;
        _StartTime = _loan.StartTime;
        _EndTime = _loan.EndTime;
    }


    
}
contract PortfolioFunctions is LoansFunctions{
    modifier isOwnerPortfolio(uint256 _indexPortfolio)  {
        require(banks[msg.sender].Portfolios[_indexPortfolio].Owner== msg.sender, "not the owner of portfolio");
        _;
    }
    // crear Portolio
    function createPortfolio(uint256 _idLoan) isBank public  returns (uint256 )  {
            require(msg.sender== loans[_idLoan].Owner);
            Portfolio  memory  _portfolio;
            banks[msg.sender].Portfolios.push(_portfolio);
            banks[msg.sender].Portfolios[banks[msg.sender].Portfolios.length-1].idLoans.push(_idLoan);
            banks[msg.sender].Portfolios[banks[msg.sender].Portfolios.length-1].Owner= msg.sender;

            return banks[msg.sender].Portfolios.length-1;
    }
    function deletePortfolio(uint256 _indexPortfolio) isOwnerPortfolio(_indexPortfolio) public{
        uint256 _PortfolioLength = banks[msg.sender].Portfolios.length;
        banks[msg.sender].Portfolios[_indexPortfolio] = banks[msg.sender].Portfolios[_PortfolioLength -1];
        delete banks[msg.sender].Portfolios[_PortfolioLength -1];
        banks[msg.sender].Portfolios.length --;
        
    }
    // agregar Loan to Portfolio
    function addLoanToPortfolio(uint256 _indexPortfolio, uint256 _idLoan) isOwnerPortfolio (_indexPortfolio) public {
        for(uint256 i; i<banks[msg.sender].Portfolios[_indexPortfolio].idLoans.length;i++){
            if (banks[msg.sender].Portfolios[_indexPortfolio].idLoans[i]==_idLoan){
                require(false, "that loan already exists on the portfolio");
            }
        }
        banks[msg.sender].Portfolios[_indexPortfolio].idLoans.push(_idLoan);
    }
    
    function removeLoanFromPortfolio(uint256 _indexPortfolio, uint256 _idLoan) isOwnerPortfolio (_indexPortfolio) public returns (bool _result){
        
        uint256 Loanslength = banks[msg.sender].Portfolios[_indexPortfolio].idLoans.length;
        uint256 _loanIndex = Loanslength;
        for(uint256 i; i<Loanslength; i++){
            if(_idLoan ==banks[msg.sender].Portfolios[_indexPortfolio].idLoans[i]){
                _loanIndex = i;
                i= Loanslength;
            }
        }
        require(_loanIndex<Loanslength, "el Loan no se encuentra en el Portfolio");
        
        if (_loanIndex !=banks[msg.sender].Portfolios[_indexPortfolio].idLoans.length-1){
               banks[msg.sender].Portfolios[_indexPortfolio].idLoans[_loanIndex] = banks[msg.sender].Portfolios[_indexPortfolio].idLoans[Loanslength-1];
        }
        delete banks[msg.sender].Portfolios[_indexPortfolio].idLoans[Loanslength -1];
        banks[msg.sender].Portfolios[_indexPortfolio].idLoans.length --;
        
        if (banks[msg.sender].Portfolios[_indexPortfolio].idLoans.length == 0){
            deletePortfolio(_indexPortfolio);
        }
        _result = true;
    }    
    function getPortfolioInfo (address _bankAddress, uint256 _indexPortfolio) isBank  public view returns (uint256 _LoansLength, uint256 _forSale, address _owner){
        require(banks[_bankAddress].Portfolios[_indexPortfolio].Owner == _bankAddress, "not the owner of that portfolio");
        _LoansLength =    banks[_bankAddress].Portfolios[_indexPortfolio].idLoans.length;
        _forSale =    banks[_bankAddress].Portfolios[_indexPortfolio].forSale;
        _owner =    banks[_bankAddress].Portfolios[_indexPortfolio].Owner;
    }
    function sellPorftolio(uint256 _indexPortfolio, uint256 _value) isOwnerPortfolio (_indexPortfolio) public {
          require(banks[msg.sender].Portfolios[_indexPortfolio].idLoans.length>0);
          banks[msg.sender].Portfolios[_indexPortfolio].forSale = _value;
    }
    function buyPortfolio(address _owner, uint256 _indexPortfolio, uint256 _value) isBank public {
        
        require(banks[msg.sender].Tokens>=_value);
        require(banks[_owner].Portfolios[_indexPortfolio].idLoans.length > 0);
        require(banks[_owner].Portfolios[_indexPortfolio].forSale > 0);
        require(banks[_owner].Portfolios[_indexPortfolio].forSale == _value );
        

        banks[msg.sender].Tokens = banks[msg.sender].Tokens.sub(_value);
        banks[_owner].Tokens = banks[_owner].Tokens.add(_value);
        
        for(uint256 a;a< banks[_owner].Portfolios[_indexPortfolio].idLoans.length ;a++){
           SwitchLoanOwner(_owner,  banks[_owner].Portfolios[_indexPortfolio].idLoans[a]);
        }
        
        if (_indexPortfolio !=banks[_owner].Portfolios.length-1){
               banks[_owner].Portfolios[_indexPortfolio] = banks[_owner].Portfolios[banks[_owner].Portfolios.length-1];         
        }
        delete banks[_owner].Portfolios[banks[_owner].Portfolios.length -1];
        banks[_owner].Portfolios.length--;
    }
    function countPortfolios(address _bankAddress) isBank public view returns (uint256 _result){
        _result = banks[_bankAddress].Portfolios.length;
    }
    function GetLoanIdFromPortfolio(uint256 _indexPortfolio, uint256 _indexLoan)  isBank public view returns(uint256 _ID){
        return banks[msg.sender].Portfolios[_indexPortfolio].idLoans[_indexLoan];
    }
    

    
}
contract GobernanceFunctions is PortfolioFunctions{

    modifier IsOwner{
        require(owner == msg.sender, "not the owner");
        _;
    }

    function addBank(address _addressBank, uint256 _tokens) IsOwner public{
        require(banks[_addressBank].Owner==0);
        require(clients[_addressBank].Owner == 0);
        banks[_addressBank].Owner=_addressBank;
        banks[_addressBank].Tokens =  _tokens;

    }
    function addClient (address _addressClient, uint256 _category) IsOwner  public{
        require(banks[_addressClient].Owner!=_addressClient, "that addreess is a bank");
        require(clients[_addressClient].Owner!=_addressClient, "that client already exists");
        require (_category > 0);
        clients[_addressClient].Owner = _addressClient;
        clients[_addressClient].Category =  _category; 
        clients[_addressClient].Tokens =  0;
    }
    function addTokensToBank(address _bank, uint256 _tokens) IsOwner public{
        require(banks[_bank].Owner==_bank, "not a Bank");
        banks[_bank].Tokens = banks[_bank].Tokens.add(_tokens);
    }
    function changeClientCategory (address _client, uint256 _category) IsOwner public{
        require (clients[_client].Owner==_client, "not a client");
        //function
        clients[_client].Category = _category;
    
    }
}
// deployar el contrato "Deploy"  con el address del gobierno
contract Deploy is GobernanceFunctions{

    constructor() public {
        owner = msg.sender;
        forTesting();
    }
    function forTesting() internal{
        addBank(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c,1);
        addBank(0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db,1);
        addTokensToBank(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c,20000);
        addTokensToBank(0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db,40000);
        addClient(0x583031d1113ad414f02576bd6afabfb302140225, 1);
        addClient(0xdd870fa1b7c4700f2bd7f44238821c26f7392148, 1);     
        changeClientCategory(0x583031d1113ad414f02576bd6afabfb302140225, 5);
        changeClientCategory(0xdd870fa1b7c4700f2bd7f44238821c26f7392148, 5);
    }

}