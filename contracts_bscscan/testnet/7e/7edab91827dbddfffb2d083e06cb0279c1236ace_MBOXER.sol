/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity ^0.5.16;

//----------------------------
// Biblioteca SafeMath
//----------------------------
library SafeMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, 'ds-math-div-overflow');
        z = x / y;
    }
}


//----------------------------
// Interface ERC20
//----------------------------
interface iERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


//----------------------------
// Contrato Proprietário
//----------------------------
contract Ownable {
	address public owner;

	constructor() public{
		owner = msg.sender;
	}

	modifier onlyOwner(){
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address payable newOwner) public onlyOwner {
		if(newOwner != address(0)){
			owner = newOwner;
		}
	}
}



//----------------------------
// ShibushiToken
//----------------------------
contract MBOXER is iERC20, Ownable {
    using SafeMath for uint;
    
    string public symbol = "MBOXER";
    string public  name = "MINI BOXER INU";
    uint8 public decimals = 18;
    uint public totalSupply = 100000000000000000000000000;
    
    uint public totalBurnt = 0;
    uint private _burnFee = 500; // Porcentagem que será queimada de cada transação * 100
    uint private _distFee = 0; // Porcentagem que será distribuida entre os holders em cada transação * 100
    
    address[] public holders;
    mapping(address => bool) public isHolder;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor() public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    //Obtém o valor da taxa que será queimada
    function getBurnValue(uint amount) public view returns (uint value){
        require(amount >= 100000, 'O valor mínimo para transferência é de 0.00000000000001');
        uint div = amount.div(10000);
        value = div.mul(_burnFee);
    }
    
    //Obtém o valor da taxa que será distribuida
    function getDistValue(uint amount) public view returns (uint value){
        require(amount >= 100000, 'O valor mínimo para transferência é de 0.00000000000001');
        uint div = amount.div(10000);
        value = div.mul(_distFee);
    }
    
    //Seta a taxa de queima em porcentagem (multiplicada por 100)
    function setBurnFee(uint fee) public onlyOwner returns(bool success){
        require(fee <= 1000);
        _burnFee = fee;
        success = true;
    }
    
    //Seta a taxa de distribuição em porcentagem (multiplicada por 100)
    function setDistFee(uint fee) public onlyOwner returns(bool success){
        require(fee <= 1000);
        _distFee = fee;
        success = true;
    }
    
    
    //Obtém a quantidade de holders
    //Para contar como holder deve ter pelo menos 10 tokens
    function countHolders() public view returns(uint){
        uint len = 0;
        for(uint i = 0; i < holders.length; i++){
            if(balanceOf[holders[i]] >= (10*10^decimals))
                len = len.add(1);
        }
        
        return len;
    }
    
    
    function _transfer(address from, address to, uint amount) private{
        require(balanceOf[from] >= amount, 'Saldo insuficiente');
        
        uint feeBurn = getBurnValue(amount);
        uint feeDist = getDistValue(amount);
        uint totalFee = feeBurn.add(feeDist);
        
        if(countHolders() <= 1){
            totalFee = totalFee.sub(feeDist);
        }
        
        uint transferAmount = amount.sub(totalFee);
        
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(transferAmount);
        
        totalSupply = totalSupply.sub(totalFee);
        totalBurnt = totalBurnt.add(feeBurn);
        
        emit Transfer(from, to, amount);
        
        if(!isHolder[to]){
            holders.push(to);
            isHolder[to] = true;
        }
        
        if(_distFee > 0){
            uint hLen = countHolders();
            hLen = hLen.sub(2);  // ignora 'msg.sender' e 'to' como holder
            
            if(hLen > 0){
                uint valuePerHold = feeDist.div(hLen);
                
                for(uint i = 0; i< holders.length; i++){
                    if(balanceOf[holders[i]] >= (10*10^decimals) && holders[i] != from && holders[i] != to){
                        balanceOf[holders[i]] = balanceOf[holders[i]].add(valuePerHold);
                        totalSupply = totalSupply.add(valuePerHold);
                    }
                }
            }
        }
    }
    
    function _transferStandard(address from, address to, uint amount) private{
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from, to, amount);
        
        if(!isHolder[to]){
            holders.push(to);
            isHolder[to] = true;
        }
    }
    
    
    
    
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount, 'Saldo insuficiente');
        
        if(msg.sender == owner || to == owner){
            _transferStandard(msg.sender, to, amount);
        }
        else{
            _transfer(msg.sender, to, amount);
        }
        
        success = true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        require(balanceOf[from] >= amount, 'Saldo Insuficiente');
        require(allowance[from][msg.sender] >= amount, 'Valor não aprovado');
        
        allowance[from][msg.sender] = (allowance[from][msg.sender]).sub(amount);
        
        if(from == owner || to == owner){
            _transferStandard(from, to, amount);
        }
        else{
            _transfer(from, to, amount);
        }
        
        success = true;
    }
    
    // Queimar tokens
    function burn(uint tokens) public onlyOwner returns(bool success){
        require(balanceOf[msg.sender] >= tokens);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        
        emit Transfer(msg.sender, address(0), tokens);
        
        success = true;
    }
    
    //Emite novos tokens para uma conta específica
    function mint(address to, uint tokens) public onlyOwner returns(bool success){
        balanceOf[to] = balanceOf[to].add(tokens);
        totalSupply = totalSupply.add(tokens);
        
        emit Transfer(address(0), to, tokens);
        
        success = true;
    }


    //Don't accept ETH
    function () external payable {
        revert();
    }
    
    
    
    
    
}