/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

/**

Taxa para compra: 15% Total
7% Em recompensas BNB para titulares
5% para LP 
3% Para a carteira de Sorteio

Taxa para venda: 20%
7% Em recompensas BNB para titulares
7% para LP 
6% Para a carteira de Sorteio

* Total de Token: 1.000.000
* Maximo por carteira: 10.000
* Maximo por venda: 10.000
* Maximo por compra: 2500
* 
* https://t.me/
* 
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner()external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library EnumerableSet {

    struct Set {
        bytes32[] _values;

        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex; 
            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

//Nome do Contrato /////////////

contract StakeBNB is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromSellLock;
    EnumerableSet.AddressSet private _excludedFromStaking;
    
    //Informacao do Token
    string private constant _name = 'StakeBNB';
    string private constant _symbol = 'SKB';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 1000000 * 10**_decimals;//

    // Divisor para o MaxBalance com base no fornecimento circulante (1,5%)
    uint8 public constant BalanceLimitDivider=20;
    
    // Divisor para limite de venda com base no fornecimento em circulação (0,1%)
    uint16 public constant SellLimitDivider=60;
    
    // Os vendedores ficam bloqueados para MaxSellLockTime para que não possam despejar repetidamente
    uint16 public constant MaxSellLockTime= 0 minutes;
    
    //O tempo que a Liquidez é travada no início e prolongada quando é liberada
    uint256 private constant DefaultLiquidityLockTime= 30 minutes;
    
    //A carteira de sorteio é 
    address public constant TeamWallet=0xEa4fDAe732663c3b26Ac95B1792F018b8aA31B8F;
    
    //Mudar para TestNet
    address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    
    //MainNet
    //address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // variáveis que rastreiam balanceLimit e sellLimit, podem ser atualizadas com base na oferta circulante e Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
	uint256 private antiDump = 10000 * 10**_decimals;
    
    //Rastreia os impostos atuais, diferentes impostos podem ser aplicados para buy/sell/transfer
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;

    uint8 private _burnTax;
    uint8 private _liquidityTax;
    uint8 private _stakingTax;

       
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;
    
    //Verifica se o endereço está na equipe, é necessário para dar acesso à equipe mesmo se o contrato for renunciado. 
    //A equipe não tem acesso a funções críticas que poderiam transformar isso em um Rugpull (desbloqueios de liquidez exceto)
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==TeamWallet;
    }

    //Constructor///////////

    constructor () {
        // o criador do contrato obtém 90% do token para criar o LP-Pair
        uint256 deployerBalance=_circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        // Pancake Router
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        //Cria o Pancake Pair
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        
        // Define limites de compra e venda
        balanceLimit=InitialSupply/BalanceLimitDivider;
        sellLimit=InitialSupply/SellLimitDivider;

       // Define sellLockTime como máximo por padrão
        sellLockTime=MaxSellLockTime;

        //Definir taxa inicial
        
        _buyTax=15;
        _sellTax=20;
        _transferTax=30;

        _burnTax=0;
        _liquidityTax=34;
        _stakingTax=66;

        // A carteira da equipe e o implantador são excluídos dos impostos
        _excluded.add(TeamWallet);
        _excluded.add(msg.sender);
        
        // exclui Pancake Router, par, contrato e endereço de queima da Stake
        _excludedFromStaking.add(address(_pancakeRouter));
        _excludedFromStaking.add(_pancakePairAddress);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(0x000000000000000000000000000000000000dEaD);
    }

    //Funcionalidade de transferência///

    //função de transferência, toda transferência é executada por meio desta função
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        
        // Endereços excluídos manualmente estão transferindo impostos e sem bloqueio
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));
        
        // As transações de e para o contrato são sempre isentas de impostos e bloqueio
        bool isContractTransfer=(sender==address(this) || recipient==address(this));
        
        // as transferências entre PancakeRouter e PancakePair são livres de impostos e bloqueio
        address pancakeRouter=address(_pancakeRouter);
        bool isLiquidityTransfer = ((sender == _pancakePairAddress && recipient == pancakeRouter) 
        || (recipient == _pancakePairAddress && sender == pancakeRouter));

        // diferencie entre compra/venda/transferência para aplicar impostos / restrições diferentes
        bool isBuy=sender==_pancakePairAddress|| sender == pancakeRouter;
        bool isSell=recipient==_pancakePairAddress|| recipient == pancakeRouter;

        //Escolher transferência
        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{ 
            //uma vez que a negociação está habilitada, não pode ser desligada novamente
            require(tradingEnabled,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);
        }
    }
    //aplica taxas, verifica os limites, bloqueia gera autoLP e stakingBNB e autostakes
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            if(!_excludedFromSellLock.contains(sender)){
                 // Se o vendedor vendeu menos do que sellLockTime (2h 50m) atrás, a venda foi recusada e pode ser desabilitada pela equipe         
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Seller in sellLock");
                
                // Define o tempo que os vendedores ficam bloqueados (2 horas e 50 minutos por padrão)
                _sellLock[sender]=block.timestamp+sellLockTime;
            }
            // As vendas não podem exceder o limite de venda (21.000 tokens no início, podem ser atualizados para o estoque circulante)
            require(amount<=sellLimit,"Dump protection");
            tax=_sellTax;

        } else if(isBuy){
            // Verifica se o saldo do destinatário (excluindo impostos) ultrapassaria o limite de saldo
            require(recipientBalance+amount<=balanceLimit,"whale protection");
        
            require(amount<=antiDump,"Tx amount exceeding max buy amount");
            tax=_buyTax;

        } else {
            // Transferwithdraws BNB ao enviar menos ou igual a 1 Token dessa forma você pode retirar sem se conectar a qualquer dApp. pode precisar de um limite de gás mais alto
            if(amount<=10**(_decimals)) claimBTC(sender);
            
            //Verifica se o saldo do destinatário (excluindo impostos) ultrapassaria o limite de saldo
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            
            // As transferências estão desabilitadas no bloqueio de venda, isso não impede que alguém faça a transferência antes de vender, 
            //mas não há uma solução satisfatória para isso e você precisaria pagar um imposto adicional
            if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
            tax=_transferTax;

        }     
        // Trocar AutoLP e MarketingBNB só é possível se o remetente não for um par de panquecas, 
        //se não for desativado manualmente, se já não for trocado e se for uma Venda para evitar 
        //que as pessoas causem um grande impacto no preço de transferências repetidas quando há um grande acúmulo de Tokens
        if((sender!=_pancakePairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken();
            
        //Calcula o valor exato do token para cada imposto
        uint256 tokensToBeBurnt=_calculateFee(amount, tax, _burnTax);
        
        // Imposto de aposta e liquidez são tratados da mesma forma, apenas durante a conversão eles são divididos
        uint256 contractToken=_calculateFee(amount, tax, _stakingTax+_liquidityTax);
        
        // Subtraia os tokens tributados do valor
        uint256 taxedAmount=amount-(tokensToBeBurnt + contractToken);

       // Remove token e lida com piquetagem
        _removeToken(sender,amount);
        
        // Adiciona os tokens tributados à carteira do contrato
        _balances[address(this)] += contractToken;
        
        //Burns tokens
        _circulatingSupply-=tokensToBeBurnt;

        // Adiciona token e lida com piquetagem
        _addToken(recipient, taxedAmount);
        
        emit Transfer(sender,recipient,taxedAmount);

    }

    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender,amount);
        _addToken(recipient, amount);
        
        emit Transfer(sender,recipient,amount);

    }
    // Calcula o token que deve ser tributado
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }

     //BNB Autostake/////////////////////////////////////////////////////////////////////////////////////////
       //Aautostake usa os saldos de cada titular para redistribuir o BNB gerado automaticamente.
      //Cada transação _addToken e _removeToken é chamada para o valor da transação ithdrawBNB pode ser usado por 
      //qualquer titular para sacar BNB a qualquer momento, como o verdadeiro Staking, portanto, ao contrário dos 
      //clones MRAT, você pode deixar e esquecer seu Token e reivindicar depois de um tempo

    // bloqueio para retirada
    bool private _isWithdrawing;
    
    // Multiplicador para adicionar alguma precisão ao profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    
    // lucro para cada ação que um titular detém, uma ação é igual a um token.
    uint256 public profitPerShare;
    
    // a recompensa total distribuída por meio de aposta, para fins de rastreamento
    uint256 public totalStakingReward;
    
    // o pagamento total por meio de piquetagem, para fins de rastreamento
    uint256 public totalPayouts;
    
    // a participação de marketing começa em 80% para impulsionar o marketing inicial, 
    // após o início é limitada a 50% no máximo, a porcentagem da aposta que é usada para marketing / pagamento da equipe
    uint8 public marketingShare=80;
    
    // equilíbrio que pode ser reivindicado pela equipe
    uint256 public marketingBalance;

    // Mapeamento das ações já pagas (ou perdidas) de cada apostador
    mapping(address => uint256) private alreadyPaidShares;
    
    // Mapeamento de ações reservadas para pagamento
    mapping(address => uint256) private toBePaid;

    // Contrato, pancake e burnAddress são excluídos, outros endereços como CEX podem ser excluídos manualmente, 
    //lista excluída é limitada a 30 entradas para evitar uma exceção de falta de gás durante as vendas
    function isExcludedFromStaking(address addr) public view returns (bool){
        return _excludedFromStaking.contains(addr);
    }

    // Total de ações é igual a oferta circulante menos saldos excluídos
    function _getTotalShares() public view returns (uint256){
        uint256 shares=_circulatingSupply;
        // subtrai todos os excluídos dos compartilhamentos, a lista de excluídos é limitada a 
        // 30 para evitar a criação de um Honeypot por meio da exceção de OutOfGas
        for(uint i=0; i<_excludedFromStaking.length(); i++){
            shares-=_balances[_excludedFromStaking.at(i)];
        }
        return shares;
    }

    // adiciona token aos saldos, adiciona novo BNB ao mapeamento toBePaid e redefine a piquetagem
    function _addToken(address addr, uint256 amount) private {
        
        // a quantidade de token após a transferência
        uint256 newAmount=_balances[addr]+amount;
        
        if(isExcludedFromStaking(addr)){
           _balances[addr]=newAmount;
           return;
        }
        
        // recebe o pagamento antes da mudança
        uint256 payment=_newDividentsOf(addr);
        
        // redefine os dividendos para 0 para o novo valor
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        
        // adiciona dividendos ao mapeamento toBePaid
        toBePaid[addr]+=payment; 
        
        // define newBalance
        _balances[addr]=newAmount;
    }
    
    
   // remove o token, adiciona BNB ao mapeamento toBePaid e redefine a stake
    function _removeToken(address addr, uint256 amount) private {
        
        // a quantidade de token após a transferência
        uint256 newAmount=_balances[addr]-amount;
        
        if(isExcludedFromStaking(addr)){
           _balances[addr]=newAmount;
           return;
        }
        
        // recebe o pagamento antes da mudança
        uint256 payment=_newDividentsOf(addr);
        
        // define newBalance
        _balances[addr]=newAmount;
        
        // redefine os dividendos para 0 para o novo valor
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        
        // adiciona dividendos ao mapeamento toBePaid
        toBePaid[addr]+=payment; 
    }
    
    

    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * _balances[staker];
        if(fullPayout<alreadyPaidShares[staker]) return 0;
        return (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }

// distribui bnb entre ações de marketing e dividendos
    function _distributeStake(uint256 BNBamount) private {
        // Deduzir imposto de marketing
        uint256 marketingSplit = (BNBamount * marketingShare) / 100;
        uint256 amount = BNBamount - marketingSplit;

       marketingBalance+=marketingSplit;
       
        if (amount > 0) {
            totalStakingReward += amount;
            uint256 totalShares=_getTotalShares();
            // quando houver 0 compartilhamentos, adicione tudo ao orçamento de marketing
            if (totalShares == 0) {
                marketingBalance += amount;
            }else{
                // Aumenta o lucro por ação com base no total de ações atuais
                profitPerShare += ((amount * DistributionMultiplier) / totalShares);
            }
        }
    }
    event OnWithdrawBTC(uint256 amount, address recipient);
    
    // retira todos os dividendos do endereço
    function claimBTC(address addr) private{
        require(!_isWithdrawing);
        _isWithdrawing=true;
        uint256 amount;
        if(isExcludedFromStaking(addr)){
            // se excluído, basta retirar o restante para BePaid BNB
            amount=toBePaid[addr];
            toBePaid[addr]=0;
        }
        else{
            uint256 newAmount=_newDividentsOf(addr);
            // define o mapeamento de pagamento para o valor atual
            alreadyPaidShares[addr] = profitPerShare * _balances[addr];
            // o valor a ser pago
            amount=toBePaid[addr]+newAmount;
            toBePaid[addr]=0;
        }
        if(amount==0){
            _isWithdrawing=false;
            return;
        }
        totalPayouts+=amount;
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
        //
        //CAKE:  0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82
        //BTC:   0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c
        //USDT:   0x55d398326f99059ff775485246999027b3197955
        //ADA:   0x3ee2200efb3400fabb9aacf31297cbdd1d435d47
        //DOT:   0x7083609fce4d1d8dc0c979aab8c869ea2c873402
        //btt:  0xEbda2226511887fBAe97577aC73D93ac2b8d2827
        //wbnb: 0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        addr,
        block.timestamp);
        
        emit OnWithdrawBTC(amount, addr);
        _isWithdrawing=false;
    }

    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////

    //tracks auto generated BNB, useful for ticker etc
    uint256 public totalLPBNB;
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //swaps the token on the contract for Marketing BNB and LP Token.
    //always swaps the sellLimit of token to avoid a large price impact
    function _swapContractToken() private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_stakingTax;
        uint256 tokenToSwap=sellLimit;
        //only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
        if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;

        //swaps marktetingToken and the liquidity token half for BNB
        uint256 swapToken=liqBNBToken+tokenForMarketing;
        //Gets the initial BNB balance, so swap won't touch any staked BNB
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=(address(this).balance - initialBNBBalance);
        //calculates the amount of BNB belonging to the LP-Pair and converts them to LP
        uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
        _addLiquidity(liqToken, liqBNB);
        //Get the BNB balance after LP generation to get the
        //exact amount of token left for Staking
        uint256 distributeBNB=(address(this).balance - initialBNBBalance);
        //distributes remaining BNB between stakers and Marketing
        _distributeStake(distributeBNB);
    }
    //swaps tokens on the contract for BNB
    function _swapTokenForBNB(uint256 amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    //Adds Liquidity directly to the contract where LP are locked(unlike safemoon forks, that transfer it to the owner)
    function _addLiquidity(uint256 tokenamount, uint256 bnbamount) private {
        totalLPBNB+=bnbamount;
        _approve(address(this), address(_pancakeRouter), tokenamount);
        _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    //public functions /////////////////////////////////////////////////////////////////////////////////////

    function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime){
            return _liquidityUnlockTime-block.timestamp;
        }
        return 0;
    }

    function getBurnedTokens() public view returns(uint256){
        return (InitialSupply-_circulatingSupply)/10**_decimals;
    }

    function getLimits() public view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }

    function getTaxes() public view returns(uint256 burnTax,uint256 liquidityTax,uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax,_liquidityTax,_stakingTax,_buyTax,_sellTax,_transferTax);
    }

    //How long is a given address still locked from selling
    function getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
       uint256 lockTime=_sellLock[AddressToCheck];
       if(lockTime<=block.timestamp)
       {
           return 0;
       }
       return lockTime-block.timestamp;
    }
    function getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }
    
    //Functions every wallet can call
    //Resets sell lock of caller to the default sellLockTime should something go very wrong
    function AddressResetSellLock() public{
        _sellLock[msg.sender]=block.timestamp+sellLockTime;
    }
    //withdraws dividents of sender
    function BTCWithdraw() public{
        claimBTC(msg.sender);
    }
    function getDividents(address addr) public view returns (uint256){
        if(isExcludedFromStaking(addr)) return toBePaid[addr];
        return _newDividentsOf(addr)+toBePaid[addr];
    }

    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
 
     bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public manualConversion; 

    function TeamWithdrawMarketingBNB() public onlyOwner{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        (bool sent,) =TeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 
    function TeamWithdrawMarketingBNB(uint256 amount) public onlyOwner{
        require(amount<=marketingBalance);
        marketingBalance-=amount;
        (bool sent,) =TeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 

    //switches autoLiquidity and marketing BNB generation during transfers
    function TeamSwitchManualBNBConversion(bool manual) public onlyOwner{
        manualConversion=manual;
    }

    //Disables the timeLock after selling for everyone
    function TeamDisableSellLock(bool disabled) public onlyOwner{
        sellLockDisabled=disabled;
    }
    
    function TeamChangeAntiDump(uint256 newAntiDump) public onlyOwner{
      antiDump=newAntiDump * 10**_decimals;
    }

    //Sets SellLockTime, needs to be lower than MaxSellLockTime
    function TeamSetSellLockTime(uint256 sellLockSeconds)public onlyOwner{
            require(sellLockSeconds<=MaxSellLockTime,"Sell Lock time too high");
            sellLockTime=sellLockSeconds;
    } 

    //Define taxas, é limitado por MaxTax (20%) para tornar impossível a criação de um honeypot
    function TeamSetTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyOwner{
        uint8 totalTax=burnTaxes+liquidityTaxes+stakingTaxes;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");

        _burnTax=burnTaxes;
        _liquidityTax=liquidityTaxes;
        _stakingTax=stakingTaxes;
        
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
    }

    //How much of the staking tax should be allocated for marketing
    function TeamChangeMarketingShare(uint8 newShare) public onlyOwner{
        require(newShare<=50); 
        marketingShare=newShare;
    }
    //manually converts contract token to LP and staking BNB
    function TeamCreateLPandBNB() public onlyOwner{
    _swapContractToken();
    }
    
     //Limits need to be at least target, to avoid setting value to 0(avoid potential Honeypot)
    function TeamUpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit) public onlyOwner{
        //SellLimit needs to be below 1% to avoid a Large Price impact when generating auto LP
        require(newSellLimit<_circulatingSupply/100);
        //Adds decimals to limits
        newBalanceLimit=newBalanceLimit*10**_decimals;
        newSellLimit=newSellLimit*10**_decimals;
        //Calculates the target Limits based on supply
        uint256 targetBalanceLimit=_circulatingSupply/BalanceLimitDivider;
        uint256 targetSellLimit=_circulatingSupply/SellLimitDivider;

        require((newBalanceLimit>=targetBalanceLimit), 
        "newBalanceLimit needs to be at least target");
        require((newSellLimit>=targetSellLimit), 
        "newSellLimit needs to be at least target");

        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;     
    }

    
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    
    bool public tradingEnabled;
    address private _liquidityTokenAddress;
    //Enables trading for everyone
    function SetupEnableTrading() public onlyOwner{
        tradingEnabled=true;
    }
    //Sets up the LP-Token Address required for LP Release
    function SetupLiquidityTokenAddress(address liquidityTokenAddress) public onlyOwner{
        _liquidityTokenAddress=liquidityTokenAddress;
    }

    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;

    function TeamUnlockLiquidityInSeconds(uint256 secondsUntilUnlock) public onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    //Release Liquidity Tokens once unlock time is over
    function TeamReleaseLiquidity() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        
        IPancakeERC20 liquidityToken = IPancakeERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        //Liquidity release if something goes wrong at start
        liquidityToken.transfer(TeamWallet, amount);
        
    }
    //Removes Liquidity once unlock Time is over, 
    function TeamRemoveLiquidity(bool addToStaking) public onlyOwner{
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        IPancakeERC20 liquidityToken = IPancakeERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        liquidityToken.approve(address(_pancakeRouter),amount);
        //Removes Liquidity and either distributes liquidity BNB to stakers, or 
        // adds them to marketing Balance
        //Token will be converted
        //to Liquidity and Staking BNB again
        uint256 initialBNBBalance = address(this).balance;
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        uint256 newBNBBalance = address(this).balance-initialBNBBalance;
        if(addToStaking){
            _distributeStake(newBNBBalance);
        }
        else{
            marketingBalance+=newBNBBalance;
        }

    }
    //Releases all remaining BNB on the contract wallet, so BNB wont be burned
    function TeamRemoveRemainingBNB() public onlyOwner{
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        (bool sent,) =TeamWallet.call{value: (address(this).balance)}("");
        require(sent);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {}
    fallback() external payable {}
    // IBEP20

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IBEP20 - Helpers

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}