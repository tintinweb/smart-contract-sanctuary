//// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

contract AuraToken {

    string private _name = "AuraToken";
    string private _symbol = "AR";

    uint8 private _decimals = 2;
    uint256 private _totalSupply=0;
    uint256 private _MAX_SUPPLY = 21000 *10**_decimals;
    uint256 public price= 1100000000000; 
    
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

    address payable owner;

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
        require(sum<=_MAX_SUPPLY,"You cannot buy more than the maximum number of tokens is 21000 pieces"); 
        
        if (sum >= 1000* 10**_decimals && sum < 2000* 10**_decimals){
            price = price1;
            }
        else if (sum>=2000* 10**_decimals && sum<3000* 10**_decimals ){
            price = price2;
        } else if(sum>=3000* 10**_decimals && sum<4000* 10**_decimals ){
            price = price3;

        } else if(sum>=4000* 10**_decimals && sum<5000* 10**_decimals ){
            price = price4;

        } else if(sum>=5000* 10**_decimals&& sum<6000* 10**_decimals ){
            price = price5;

        } else if(sum>=6000 * 10**_decimals&& sum<7000 * 10**_decimals){
            price = price6;

        } else if(sum>=7000 * 10**_decimals&& sum<8000 * 10**_decimals ){
            price = price7;

        } else if(sum>=8000 * 10**_decimals && sum<9000 * 10**_decimals){
            price = price8;

        } else if(sum>=9000 * 10**_decimals&& sum<10000 * 10**_decimals){
            price = price9;

        } else if(sum>=10000 * 10**_decimals&& sum<11000 * 10**_decimals){
            price = price10;

        }else if(sum>=11000 * 10**_decimals&& sum<12000 * 10**_decimals){
            price = price12;

        }else if(sum>=13000 * 10**_decimals&& sum<14000 * 10**_decimals){
            price = price13;

        }else if(sum>=14000 * 10**_decimals&& sum<15000 * 10**_decimals){
            price = price14;

        }else if(sum>=15000 * 10**_decimals&& sum<16000 * 10**_decimals){
            price = price15;

        }else if(sum>=16000 * 10**_decimals&& sum<17000 * 10**_decimals){
            price = price16;

        }else if(sum>=17000 * 10**_decimals&& sum<18000 * 10**_decimals){
            price = price17;

        }else if(sum>=18000 * 10**_decimals&& sum<19000 * 10**_decimals){
            price = price18;

        }else if(sum>=19000 * 10**_decimals&& sum<20000 * 10**_decimals){
            price = price19;

        }else if(sum>=20000 * 10**_decimals&& sum<21000 * 10**_decimals){
            price = price20;
        }

        _balanceOf[msg.sender] +=amount;
        _totalSupply += amount;

        emit Buy(msg.sender, amount);
        emit Transfer(address(0),msg.sender,amount);
    } 
    // снять со счета
    function withdraw() public {
        
        owner.transfer(address(this).balance);
    }
    //разрушить
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