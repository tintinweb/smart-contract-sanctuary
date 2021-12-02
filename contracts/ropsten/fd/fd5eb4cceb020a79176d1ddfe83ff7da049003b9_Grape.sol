/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity 0.8.7;

contract Grape {

    string private _name = "GrapeToken";
    string private _symbol = "GRP";
    uint8 private _decimals = 2;
    uint256 private _totalSupply=0;
    uint256 private _MAX_SUPPLY = 21000 *10**_decimals;
    uint256 public price = 1100000000000; 
    address payable owner;

    uint256 price1=1210000000000;
        uint256 price2=price1+price1/10;
        uint256 price3=price2 +price2/10;
        uint256 price4=price3+ price3/10;
        uint256 price5=price4+ price4/10;
        uint256 price6=price5+ price5/10;
        uint256 price7=price6 + price6/10;
        uint256 price8=price7 + price7/10;
        uint256 price9=price8 + price8/10;
        uint256 price10=price9 + price9/10;
        uint256 price11=price10 + price10/10;
        uint256 price12=price11 + price11/10;
        uint256 price13=price12 + price12/10;
        uint256 price14=price13 + price13/10;
        uint256 price15=price14 + price14/10;
        uint256 price16=price15 + price15/10;
        uint256 price17=price16 + price16/10;
        uint256 price18=price17 + price17/10;
        uint256 price19= price18 + price18/10;
        uint256 price20= price19 + price19/10;
    

    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
    event Buy(address indexed _buyer, uint256 _value);

    //проверка максимального колличества которое можно выпустить
    function MAX_SUPPLY () public view returns (uint256){
        return _MAX_SUPPLY;
    }        
    

    
    //продажа токенов
    function buy() public payable {
        uint256 amount= (msg.value / price) * 10**_decimals;
        uint256 sum = _totalSupply + amount;

        if (sum >= 1000 && sum < 2000){
            price = price1 ;
            }
        else if (sum>=2000 && sum<3000 ){
            price = price2;
        } else if(sum>=3000 && sum<4000 ){
            price = price3;
        }
        
         
        
        require(_totalSupply + amount <=_MAX_SUPPLY,"You cannot buy more than the maximum number of tokens is 21000 pieces"); 
        _balanceOf[msg.sender] +=amount;
        _totalSupply += amount;
        emit Buy(msg.sender, amount);
        emit Transfer(address(0),msg.sender,amount);
    } 

    function withdraw() public {
        
        owner.transfer(address(this).balance);
    }

    function destroy() public {
        require(msg.sender ==owner, "Only owner can call this function");
        selfdestruct(owner);
    }

    //позволяет прочесть имя
    function name () public view returns (string memory){
    return _name;
    }
    //позволяет прочесть тикер токена
    function symbol() public view returns (string memory){
        return _symbol;
    }
    //определяет колличество знаков после запятой, в данном случает два знака 
    function decimals() public view returns(uint8){
        return _decimals;
    }
    //колличество токенов которое может быть выпущено
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }
    
    //получение баланса пользователя 
    function balanceOf (address _owner) public view returns (uint256){
        return _balanceOf[_owner];
    }
    //передача токенов (кому и количества токенов) 
    function transfer(address _to, uint256 _value) public returns (bool){
        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    //возможность доверить определенное колличество токенов 
    function approve (address _spender, uint256 _value) public returns (bool){
        _allowances[msg.sender][_spender] = _value;
        emit Approval (msg.sender,_spender, _value);
        return true;
    }

    function allowance (address _owner, address _spender) public view returns (uint256 remaining){
        return _allowances[_owner][_spender];
    }
    //передавать с определенного кошелька кем то (как трансфер но нужно проверять позволи ли переводить)
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool){
        require(_allowances[_from][msg.sender]>=_value, "You are not allowed to spend this emount of token");
        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;
         _allowances[_from][msg.sender] -= _value;
        emit Transfer (_from, _to, _value);
        return true;
    }
}