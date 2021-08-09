/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}


contract Token is Context, IERC20 {
    address public owner;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 public _totalSupply = 1000000000*10**18;
    string public _name = "X coin";
    string public _symbol= "X";

    bool public allowanceEnabled = true;
    uint256 public marketingPercent = 2;
    uint256 public marketingAmount;
    address payable public marketingAddress = payable(0x9C97D623254c2588a2F7fB8F1755d7049a3b097f);
    uint256 public burnPercent = 8;
    uint256 public burnAmount;
    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD; // ❓ почему не все нули 000?



    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function owned() public payable {
        owner = msg.sender;
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

    function SetMarketingAddress(address payable  _marketingAddress) onlyOwner public {
        marketingAddress = _marketingAddress;
    }

    function SetMarketingPercent(uint256 _marketingPercent) onlyOwner public {
        marketingPercent = _marketingPercent;
    }

    function SetBurnPercent(uint256 _burnPercent) onlyOwner public {
        burnPercent = _burnPercent;
    }



    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // ❓ пробовать - кошели любые - возвращает их сумму?
    function balanceOf(address _account) public view virtual override returns (uint256) {
        return _balances[_account];
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    // от вызывающего - передаю кому-то
    function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    // ❓ кто вызывает, когда? что в _sender?
    // передаем от любого-любому
    // ❓ unchecked передает вызывателю (от же sender, не?) - зачем?
    function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool) {
        _transfer(_sender, _recipient, _amount);

        uint256 currentAllowance = _allowances[_sender][_msgSender()];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        require(allowanceEnabled == true, "BEP20: transfer disabled.");
        unchecked {
            _approve(_sender, _msgSender(), currentAllowance - _amount);
        }

        return true;
    }


    function ChangeAllowanceEnabled(bool _allowanceEnabled) onlyOwner public {
        allowanceEnabled = _allowanceEnabled;
    }

    // ❓ кто вызывает, когда? = увеличить "сколько можешь перевести"
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender] + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][_spender];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), _spender, currentAllowance - _subtractedValue);
        }
        return true;
    }



    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    // ❓ здесь комса снимается! дальше переопределили в 0?
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(_sender, _recipient, _amount);

        uint256 senderBalance = _balances[_sender];


        burnAmount = _amount * burnPercent / 100 ;
        marketingAmount = _amount * marketingPercent / 100;

        require(senderBalance >= _amount, "BEP20: transfer amount exceeds balance");
        require(allowanceEnabled == true, "BEP20: transfer disabled");
        unchecked {
            _balances[_sender] = senderBalance - _amount;
        }
        _amount =  _amount - marketingAmount - burnAmount;
        _balances[_recipient] += _amount;

        emit Transfer(_sender, _recipient, _amount);


        if (marketingPercent > 0){
            _balances[_recipient] += marketingAmount; // ❓ получателю тому же записываем баланс ++? это ж не верные цифры
            emit Transfer(_sender, marketingAddress, marketingAmount);
        }

        if (burnPercent > 0){
            _totalSupply -= burnAmount;
            emit Transfer(_sender, burnAddress, burnAmount);
        }

    }


    // ❓ нигде не вызывается, почему? в потомке?
    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), _account, _amount);

        _totalSupply += _amount;
        _balances[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    // ❓ нигде не вызывается, почему? в потомке?
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(_account, address(0), _amount);

        uint256 accountBalance = _balances[_account];
        require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[_account] = accountBalance - _amount;
        }
        _totalSupply -= _amount;

        emit Transfer(_account, address(0), _amount);
    }

    // ❓ как используется? вызывается везде
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

}






contract TokenX10 is Token {
    address public CrowdAddress = address(this);    // ❓ это адрес контракта? 2) или msg.sender?
    uint256 public CrowdSupply   = 200000000*10**18;
    uint256 public AirdropSupply = 200000000*10**18;
    uint256 public AirdropAmount =    25000*10**18; // Airdrop amount
    uint256 public Price         =    10000*10**18; // ❓ заменить - и постоянно потом менять - 2) или в контракт прописать
    uint256 public SoftCap       =         0*10**18;
    uint256 public balancesOwner = _totalSupply - CrowdSupply - AirdropSupply;
    uint256 public PresaleBalance = 0;

    bool public PresaleStart = false;
    bool public AirdropStart = false;
    bool public PresaleBayback = false;



    constructor ()  {
        owned();
        _balances[CrowdAddress] = CrowdSupply+ AirdropSupply;
        _balances[owner] = balancesOwner;
        emit Transfer(CrowdAddress, owner, balancesOwner); // ❓ почему переводим
    }


    fallback() external payable {
        require(CrowdSupply > 0);
        require(PresaleStart == true, "PreSale is not active."); // ❓где ошибку увижу?
        uint256 tokensPerOneEther = Price;
        uint256 tokens = tokensPerOneEther * msg.value / 10**18;
        if (tokens > _balances[CrowdAddress]) {
            tokens = _balances[CrowdAddress];
            uint valueWei = tokens * 10**18 / tokensPerOneEther;
            //emit Transfer(CrowdAdress, msg.sender, msg.value - valueWei);
            payable(msg.sender).transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        _balances[msg.sender] += tokens;
        _balances[CrowdAddress] -= tokens; //списываем токены с баланса контракта
        CrowdSupply -= tokens; //списываем токены с условного баланса пресейла
        PresaleBalance += msg.value;// считаем сборы
        emit Transfer(CrowdAddress, msg.sender, tokens);
        //payable(owner).transfer(CrowdAdress.balance);
    }

    receive() external payable {}

    function bayback() public payable  {
        require(PresaleBayback == true, "PresaleBayback is not active.");//выкуп токенов если не набран софткап

        uint256 tokensBNB =  _balances[msg.sender] * 10 ** 18 / Price; //узнаем сколько выплатить BNB по балансу запросившего
        _balances[address(this)] += _balances[msg.sender];
        emit Transfer(msg.sender, address(this), _balances[msg.sender]);
        _balances[msg.sender]  = 0;
        payable(msg.sender).transfer(tokensBNB);
    }



    function AirdropOnOf(bool _AirdropStart) onlyOwner public {
        AirdropStart = _AirdropStart;
    }

    function PresaleOnOf(bool _PresaleStart) onlyOwner public {
        PresaleStart = _PresaleStart;
    }

    function PresaleBaybackOnOf(bool _PresaleBayback) onlyOwner public {
        PresaleBayback = _PresaleBayback;
    }



    function getAirdrop(address _refferal) public returns (bool success){

        require(AirdropSupply > 0);
        require(AirdropStart == true, "Airdrop is not active.");

        // ❓ не находит balanceOf
        if(msg.sender != _refferal && balanceOf(_refferal) != 0 && _refferal != 0x0000000000000000000000000000000000000000){
            _balances[address(this)] -= AirdropAmount / 2; // ❓ почему не конкретный адрес контракта? owner? а adress(this)
            _balances[_refferal] += AirdropAmount / 2;
            emit Transfer(address(this), _refferal, AirdropAmount);
        }

        _balances[address(this)] -= AirdropAmount;
        _balances[msg.sender]  += AirdropAmount;  // ❓ почему уже не _msgSender() ?
        AirdropSupply -= AirdropAmount;
        emit Transfer(address(this), msg.sender, AirdropAmount);
        return true;
    }


    // ❓ зачем? вызвал-выплатил всем?
//    function withdraw() public payable onlyOwner {
//        //require(PresaleBalance > SoftCap);//проверяем набран ли софткап
//        payable(owner).transfer(CrowdAddress.balance);
//    }
    // ❓ как работает?
//    function killMe() public onlyOwner {
//        selfdestruct(payable(owner));
//    }


}