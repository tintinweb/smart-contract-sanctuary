// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * DIFERENCA PERMISSAO
 * PUBLIC - Todos os contratos tem acesso
 * PRIVATE - So contrato e contrato FILHO tem acesso
 * INTERNAL - SO o propio contrato tem acesso
 * External - So aceita chamadas externas
*/

/*
INTERFACE PADRAO ERC20
*/
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event TransferFrom(address indexed from, address indexed to, uint256 value);
}

/**
 * CONTRATO ABSTRADO DE CONTEXT DO OpenZeppelin
*/
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SAFE MATH
library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//ABSTRACAO DO OWNABLE
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //CONSTRUTOR ONDE MARCA O DONO
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    //RETORNA O DONO
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // MODIFIER (OU MIDDLEWARE) QUAL VERIFICA APENAS O DONO
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    //RENUNCIA PROPIEDADE, ENVIANDO PARA O UNIVERSO SEM DONO DEPOIS
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    //TRANSFERE A PROPIEDADE
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//ABSTRACAO DO PAUSABLE
abstract contract Pausable is Ownable {
    //EVENTO
    event Paused(address account);
    event Unpaused(address account);
    
    // VAR
    bool private _paused;

    constructor () {
        _paused = false;
    }

    //VERIFICA SE ESTA PAUSADO OU N
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    //MODIFIER Q RODA QND N ESTIVER PAUSADO
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    //MODIFIER RODA QUANDO ESTIVER PAUSADO
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    // FUNCA INTERNA Q PAUSA O CONTRATO
    function pause() public virtual whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    // FUNCA INTERNA Q DESPAUSA O CONTRATO
    function unpause() public virtual whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}



/**
 * TOKEN ERC20 com padrao ERC20 
*/
contract PRECATORIOA is Context, IERC20, Pausable {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _urlData; // Tem uma url para detalhe dos precatorios
    
    //## Salva o dono que fez a retirada pois pode mudar o dono
    event Redeem(address owner,  uint amount);
    
    event ChangeUrlData(address owner,  string newUrl);

    constructor () {
        _name = "Precatorio A"; // NOME DA COIN
        _symbol = "PRCA"; // SIMBOLO DA MOEDA
        _totalSupply = 0; // Quantidade de token
        _urlData = "https://google.com";
        
         _mint(_msgSender(), 100);
    }
    
    //FUNCA QUE BLOQUEIA O ENVIO DE ETH PARA O CONTRATO - O contrato ira devolver
    function pay() public payable {}

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function urlData() public view virtual returns (string memory) {
        return _urlData;
    }

    function decimals() public view virtual returns (uint8) {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function changeUrlData(string memory newUrl) public virtual onlyOwner {
        _urlData = newUrl;
        emit ChangeUrlData(_msgSender(), newUrl);
    }
    
    //OK
    function transfer(address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    //VERIFICA SE TEM A PROCURACAO - OK
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    

    //CRIA A PROCURACAO PARA O CARA PODER GASTAR - USA MUITO EM EXCHANGE - QUEM EXECUTA - OK
    function approve(address spender, uint256 amount) public whenNotPaused virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    //EXECUTA A TRANSFERENCIA VIA A PROCURACAO - OK
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        currentAllowance = currentAllowance.sub(amount);
        
        _approve(sender, _msgSender(), currentAllowance);
        
        //EVENT - PEGA QUEM EXECUTOU A PROCURACAO
        /**
         * sender - QUEM aprovou a PROCURACAO
         * _msgSender() - Quem esta executando a funcao
        */
        emit TransferFrom(sender, recipient, amount);
        
        return true;
    }
    
    //ALTERA A QUANTIDADE (SOMANDO) DA PROCURACAO - JA QUE ALTERAR VALOR GASTA MENOS GAS Q SUBSTITUIR - OK
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    //ALTERA A QUANTIDADE (SUBTRAINDO) DA PROCURACAO - JA QUE ALTERAR VALOR GASTA MENOS GAS Q SUBSTITUIR - OK
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        currentAllowance = currentAllowance.sub(subtractedValue);
        _approve(_msgSender(), spender, currentAllowance);

        return true;
    }
    //##
    //FUNCAO DE BURN - COMO STABLE COIN N PODE USAR BURN = ok
    function burn(uint amount) external whenNotPaused returns (bool) {
        require(amount > 0, "ERC20: Amount maior que 0");
        _burn(_msgSender(), amount);
        return true;
    }
    
    //FUNCAO Redeem - OK
    // function redeem(uint256 amount) external onlyOwner whenNotPaused returns (bool) {
    //     require(_totalSupply >= amount, "TPTAL SUPLY MENOR Q QUANTIDADE");
    //     require(_balances[_msgSender()] >= amount, "NAO TEM QUANTIDADE SUFICENTE");
        
    //     _totalSupply = _totalSupply.sub(amount);
        
    //     _balances[_msgSender()] = _balances[_msgSender()].sub(amount);

    //     emit Redeem(_msgSender(), amount);
        
    //     return true;
    // }
    

    //EXATAMENTE A FUNCAO QUE TRANSFERE - POR TER _ NA FRENTE É INTERNAL
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        //SAFEMATH - Subtrai do cara que envia
        senderBalance = senderBalance.sub(amount);
        _balances[sender] = senderBalance;
        
        //Soma do cara que recebe
        _balances[recipient] = _balances[recipient].add(amount);
        
        
        emit Transfer(sender, recipient, amount);
    }
    
    
    //FUNCAO INTERNA SO 'É INVOCADA PELO CONTRATO, OU SEJA ESSE _MINT TEM QUE SER CRIADA UMA OUTRA FUNCAO PARA INVOCAR'
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        
        //SAFE MATH
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    //FUNCAO INTERNA SO 'É INVOCADA PELO CONTRATO, OU SEJA ESSE _BURN TEM QUE SER CRIADA UMA OUTRA FUNCAO PARA INVOCAR'
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}