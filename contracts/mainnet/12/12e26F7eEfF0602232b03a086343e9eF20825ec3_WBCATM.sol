pragma solidity 0.5.16;

interface ERC20Interface {
    function balanceOf(address owner)  external view returns(uint256 balance);
    function transfer(address to, uint value) external returns(bool success);
    function transferFrom(address _from, address _to, uint256 value)  external returns(bool success);
    function Exchange_Price() external view returns(uint256 actual_Price);
}

contract WBCATM {

    address public _owner;
    address public TOKEN_SC;
    address public EXCHNG;
    
    uint8 public Provision;
    uint256 public TOKEN_PRICE;

    mapping ( address => uint256 ) public Token_Safe;
    mapping ( address => uint256 ) public ETH_Deposit;

    event Deposit(address user, uint256 amountETH);
    event Exchange(address buyer, uint256 amount, uint paid, uint provision);
    event withdrawBalance(address user, uint256 balanceETH );
    event calculatedAmount(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == _owner, "only Owner");
        _;
    }

   constructor() public {
        _owner = msg.sender;
        TOKEN_SC = 0x79C90021A36250BcE01f11CFd847Ba30E05488B1;
        TOKEN_PRICE = 0.001 ether;
        Provision = 10;
   }

    function () external payable {
        require(msg.value > 0);
        ETH_Deposit[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        require(amount > 0);
        ETH_Deposit[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function exchangeToken2ETH(uint256 _amountWei) payable public {  
        require(_amountWei > 0,"Value must more then 0 !");
        ERC20Interface ERC20Token = ERC20Interface(TOKEN_SC);
        ERC20Token.transferFrom(msg.sender, address(this), _amountWei);

        Token_Safe[TOKEN_SC] = Token_Safe[TOKEN_SC] + _amountWei ;
        
        uint256 Prov = ((_amountWei* TOKEN_PRICE)/(10**18)) * Provision / 100 ;
        uint256 amountWeiETH = ((_amountWei * TOKEN_PRICE)/(10**18)) - Prov ;
        msg.sender.transfer(amountWeiETH);
        emit Exchange ( msg.sender, _amountWei, amountWeiETH, Prov);
    }

    function withdrawETH(uint256 amountWeiETH) public payable onlyOwner {
        require(amountWeiETH > 0,"Value must more then 0 !");
        uint256 balanceETH;
        balanceETH = address(this).balance;
        require(balanceETH >= amountWeiETH);
        address(uint160(msg.sender)).transfer(amountWeiETH);
    }

    function withdrawQPON() public onlyOwner {
        require(Token_Safe[TOKEN_SC] > 0,"Token Safe is empty !");
        ERC20Interface ERC20Token = ERC20Interface(TOKEN_SC);
        ERC20Token.transfer(msg.sender, Token_Safe[TOKEN_SC]);
        Token_Safe[TOKEN_SC] = 0;
    }

    function balanceOf() public onlyOwner view returns(uint256 balanceETH) {
        balanceETH = address(this).balance;
    }

    function balanceOfToken() public view returns(uint256 balanceToken) {
        balanceToken = Token_Safe[TOKEN_SC];
    }

    function Exchange_Price() public view returns (uint256 actual_Price) {
        return TOKEN_PRICE;
    }

    function calcul(uint256 a, uint256 b, uint256 precision) internal pure returns (uint256 result) {
        result = a*(10**precision)/b;
    }

    function set_TOKEN_SCAddress (address _TOKEN_SCAddress) public onlyOwner { 
        TOKEN_SC = _TOKEN_SCAddress;
    }

    function set_EXCHNGAddress (address _exchngSCAddress) public onlyOwner { 
        EXCHNG = _exchngSCAddress;
    }

    function set_Exchange_Price() public onlyOwner {
        ERC20Interface ERC20Exchng = ERC20Interface(EXCHNG);
        TOKEN_PRICE = ERC20Exchng.Exchange_Price();
    }

    function set_TokenPrice (uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0);
        TOKEN_PRICE = _newPrice;
    }

    function set_Provision(uint8 setProvision) public onlyOwner {
        Provision = setProvision;
    }

    function get_ETHDeposit(address _user) public view onlyOwner returns (uint256 BalanceOfUser){
        BalanceOfUser = ETH_Deposit[_user];
    }
    function reset_ETHDeposit(address _user, uint256 BalanceOfUser) public onlyOwner {
        ETH_Deposit[_user] = BalanceOfUser;
    }
}