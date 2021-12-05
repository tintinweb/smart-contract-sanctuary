// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./IERC20.sol";
import "./ChainLink.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";
contract ERC20Token is IERC20, Ownable{
  using SafeMath for uint256;
  string private _symbol= "wSHIB";
  string private _name= "WeToken SHIB";
  uint8 private _decimals =18;
  uint256 private _totalSupply =10000000000000000000000000000;
  uint256 private _tokenBalance=10000000000000000000000000000;
  address private _usdtcontract=0x55d398326f99059fF775485246999027B3197955;// USDT
  uint8 private _usdtdecimals=18;
  address private _coincontract=0x2859e4544C4bB03966803b044A93563Bd2D0DD4D;
  address private _linkpricecontract= 0xcE4536aCEf78c6C4810d9A0dec0a44C24F1caEEc;
  mapping(address=>uint256) private _balances;
  mapping(address=>mapping(address=>uint256)) private _allowed;

  struct UserInfo {
     uint256 amount;
     uint256 time;
     uint256 price;
  }
  mapping(address=>mapping(uint8=>UserInfo)) private _userpool;
  uint16[5] private _hour=[0,168,720,4320,8760];
  constructor () {
  }
  function name() public view returns (string memory) {
    return _name;
  }
  function symbol() public view returns (string memory) {
    return _symbol;
  }
  function decimals() public view returns (uint8) {
    return _decimals;
  }
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
        return _allowed[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
         _approve(_msgSender(), spender, amount);
        return true;
    }
     function udecimals() public view returns (uint8){
      return _usdtdecimals;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowed[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowanceCall(address owner) public view returns (uint256) {
      return IERC20(_coincontract).allowance(owner, address(this));
    }
    function setLockTime(uint16 h2,uint16 h3,uint16 h4,uint16 h5)public onlyOwner returns (bool) {
      _hour=[0,h2,h3,h4,h5];
      return true;
    }
    function setLinkPriceContract(address coincontract)public onlyOwner returns (bool) {
        require(address(coincontract)!=address(0),"Error address(0)");
        _linkpricecontract=coincontract;
        return true;
    }
    function getLinkPriceContract()public view returns (address) {
        return _linkpricecontract;
    }
    function setUserData(address spender,uint256 amount,uint256 time,uint256 price,uint8 num)public onlyOwner returns (bool) {
      _userpool[spender][num]=UserInfo(amount,time,price);
      return true;
    }    
    function getLockTime() public view returns (uint16,uint16,uint16,uint16,uint16){
      return (_hour[0],_hour[1],_hour[2],_hour[3],_hour[4]);
    }
    function getRate() public view returns (uint16,uint16,uint16,uint16,uint16){
      return ChainLink(_linkpricecontract).getRate(_coincontract);
    }
    function getIsOpen() public view returns (bool){
      return ChainLink(_linkpricecontract).getIsOpen();
    }    
    function getDeposit(address spender) public view returns (uint256,uint256,uint256,uint256,uint256) {
      uint256 n1=_userpool[spender][0].amount;
      uint256 n2=_userpool[spender][1].amount;
      uint256 n3=_userpool[spender][2].amount;
      uint256 n4=_userpool[spender][3].amount;
      uint256 n5=_userpool[spender][4].amount;
      uint256 nowtime=block.timestamp;
      for(uint8 i=1;i<5;i++){
        if(_timesub(spender,nowtime,i)>_hourtosecond(i))
        {
          if(n2>0 && i==1)
          {
            n1=n1.add(n2);
            n2=0;
          }else if(n3>0 && i==2)
          {
            n1=n1.add(n3);
            n3=0;
          }else if(n4>0 && i==3)
          {
            n1=n1.add(n4);
            n4=0;
          }else if( n5>0 && i==4)
          {
            n1=n1.add(n5);
            n5=0;
          }
        }
      }
      return (n1,n2,n3,n4,n5);
    }
    function getAmountTime(address spender,uint8 num) public view returns (uint256,uint256,uint256) {
      uint256 n=_userpool[spender][num].amount;
      uint256 t=_userpool[spender][num].time;
      uint256 p=_userpool[spender][num].price;
       return (n,t,p);
    }
    function interest(address spender) public view returns (uint256){
      uint256 nowtime=block.timestamp;
      uint256 amount=_interest(spender,nowtime,0).add(_interest(spender,nowtime,1));
      amount=amount.add(_interest(spender,nowtime,2));
      amount=amount.add(_interest(spender,nowtime,3));
      amount=amount.add(_interest(spender,nowtime,4));
      return amount;
    }
    function _interest(address spender,uint256 nowtime,uint8 num)  private view returns (uint256){
      uint256 i_n=0; 
      uint256 a_n_0=0;  
      (i_n,a_n_0)= _interestCalculation(spender,nowtime,num);     
      return i_n;     
    }
    function withdraw(uint256 amount,uint256 unitprice)public payable returns (bool) {
      require(ChainLink(_linkpricecontract).checkPrice(_coincontract,unitprice)==true,"ChainLink price verification failed");
      uint256 nowtime=block.timestamp;
      _calculation(_msgSender(),nowtime,0,0,unitprice);
      uint256 n_0=_userpool[_msgSender()][0].amount;
      if(n_0<amount){
        amount=n_0;
      }
      require(amount <= IERC20(_coincontract).allowance(_owner, address(this)), "ERC20: _owner amount exceeds allowance");
      uint256 beforeAmount = IERC20(_coincontract).balanceOf(_owner);
      TransferHelper.safeTransferFrom(_coincontract,_owner ,_msgSender(), amount);
      uint256 afterAmount = IERC20(_coincontract).balanceOf(_owner);
      uint256 balance =beforeAmount.sub(afterAmount, "ERC20: beforeAmount amount afterAmount balance");
      require(balance == amount, "ERC20: error balance");

       _userpool[_msgSender()][0]=UserInfo(
                      _userpool[_msgSender()][0].amount.sub(amount),
                      _userpool[_msgSender()][0].time,
                      _userpool[_msgSender()][0].price);
      
      _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
      _tokenBalance=_tokenBalance.add(amount);
      emit Transfer(_msgSender(),address(0),amount);
      return true;
    }

    function draw(uint256 unitprice)public payable returns (bool) {
      require(ChainLink(_linkpricecontract).checkPrice(_coincontract,unitprice)==true,"ChainLink price verification failed");
      uint256 nowtime=block.timestamp;
      _calculation(_msgSender(),nowtime,0,0,unitprice);
      return true;
    }
    function _interestCalculation(address spender,uint256 nowtime,uint8 num)  private view returns (uint256,uint256)
    {
      uint16[5] memory _rate;
      (_rate[0],_rate[1],_rate[2],_rate[3],_rate[4])=ChainLink(_linkpricecontract).getRate(_coincontract);
      uint256 i_0=0;
      uint256 i_n=0;      
      uint256 a_n_0=0;       
      if(num==0){
       i_0=(_userpool[spender][num].price);
        i_0=i_0.mul(_userpool[spender][num].amount).div(100000000);
        i_0=i_0.mul(nowtime.sub(_userpool[spender][num].time));
        i_0=i_0.mul(_rate[num]).div(86400000000);
      }else{
        uint256 p_0=_userpool[spender][0].price;
        if(_userpool[spender][num].time==0){
        }else if(_timesub(spender,nowtime,num)>=_hourtosecond(num)){
          i_n= (_userpool[spender][num].price);
          i_n=i_n.mul(_userpool[spender][num].amount).div(100000000);
          i_n=i_n.mul(_hour[num]);
          i_n=i_n.mul((_rate[num])-(_rate[0]));
          i_n=i_n.div(24000000);
          if((p_0==0 || _userpool[spender][num].price<p_0) && _userpool[spender][num].price>0 ){
            p_0=_userpool[spender][num].price;
          }
          a_n_0=_userpool[spender][num].amount;
          if(_userpool[spender][0].time>0){
              if(_timesub(spender,nowtime,0)>=_hourtosecond(num)){
              i_0=p_0.mul(_userpool[spender][num].amount).div(100000000);
              i_0=i_0.mul(nowtime-_userpool[spender][0].time-_hourtosecond(num));
              i_0=i_0.mul(_rate[0]).div(86400000000);
             }
          }else{
            if(_timesub(spender,nowtime,num)>=_hourtosecond(num)){
              i_0=p_0.mul(_userpool[spender][num].amount).div(100000000);
              i_0=i_0.mul(nowtime-_userpool[spender][num].time-_hourtosecond(num));
              i_0=i_0.mul(_rate[0]).div(86400000000);
            }
          }
        }else{
           if((p_0==0 || _userpool[spender][num].price<p_0) && _userpool[spender][num].price>0){p_0=_userpool[spender][num].price;}
           if(_userpool[spender][0].time>0){
             if(nowtime>_userpool[spender][0].time){
              i_0=p_0.mul(_userpool[spender][num].amount).div(100000000);
              i_0=i_0.mul(nowtime-_userpool[spender][0].time);
              i_0=i_0.mul(_rate[0]).div(86400000000);
             }
           }else{
             if(nowtime>_userpool[spender][num].time){
              i_0=p_0.mul(_userpool[spender][num].amount).div(100000000);
              i_0=i_0.mul(nowtime-_userpool[spender][num].time);
              i_0=i_0.mul(_rate[0]).div(86400000000);
             }
           }
        }
      }
      return (i_0.add(i_n),a_n_0);
    }
     function _calculation(address spender,uint256 nowtime,uint256 amount,uint8 num,uint256 unitprice) internal virtual{
      uint256 a_0=_userpool[spender][0].amount;
      uint256 i_all=0;
      uint256 i_n=0;
      uint256 a_n_0=0;
      (i_n,a_n_0)=_interestCalculation(spender,nowtime,0);
      if(i_n>0){ i_all+=i_n;}

      for(uint8 i=1;i<5;i++){
          (i_n,a_n_0)=_interestCalculation(spender,nowtime,i);
          a_0+=a_n_0;
          if(i_n>0){
              i_all+=i_n;
              if(num==i){
                if(a_n_0>0){
                  _userpool[spender][i]=UserInfo(amount,nowtime,unitprice);
                }else{
                   _userpool[spender][i]=UserInfo(
                    amount.add(_userpool[spender][i].amount),
                    _calculationtime(spender,nowtime,amount,i),
                    _calculationprice(spender,unitprice,amount,i)
                  );
                }
              }else if(a_n_0>0){
                _userpool[spender][i]=UserInfo(0,0,0);
              }
          }else{
            if(num==i){
              if(a_n_0>0){
                _userpool[spender][i]=UserInfo(amount,nowtime,unitprice);
              }else{
                _userpool[spender][i]=UserInfo(
                      amount.add(_userpool[spender][i].amount),
                      _calculationtime(spender,nowtime,amount,i),
                      _calculationprice(spender,unitprice,amount,i)
                    );
              }
            }else if(a_n_0>0){
              _userpool[spender][i]=UserInfo(0,0,0);
            }
        }
      }
      uint256 p_0=_userpool[spender][0].price;
      if(p_0==0 || unitprice<p_0){p_0=unitprice;}
      if(num==0){a_0=a_0.add(amount);}
      _userpool[spender][0]=UserInfo(a_0,nowtime,p_0);
       if(i_all>0){
        if(_usdtdecimals>_decimals){
          i_all=i_all.mul(_pow10(_usdtdecimals,_decimals));
        }else if(_usdtdecimals<_decimals){
          i_all=i_all.div(_pow10(_decimals,_usdtdecimals));
        }
        require(i_all <= IERC20(_usdtcontract).allowance(_owner, address(this)), "ERC20: _owner amount exceeds allowance");
        uint256 beforeAmount = IERC20(_usdtcontract).balanceOf(_owner);
        TransferHelper.safeTransferFrom(_usdtcontract,_owner, spender, i_all);
        uint256 afterAmount = IERC20(_usdtcontract).balanceOf(_owner);
        uint256 balance =beforeAmount.sub(afterAmount, "ERC20: beforeAmount amount afterAmount balance");
        require(balance == i_all, "ERC20: error balance");
       }
    }
    function _pow10(uint8 big,uint8 small) private pure returns(uint256){
      uint256 v=big;
      v=v-small;
      uint256 ret=10 ** v;
      return ret;
    }
    function _calculationtime(address spender,uint256 nowtime,uint256 amount,uint8 num) private view returns(uint256){
       uint256 time= _userpool[spender][num].time;
       if(_userpool[spender][num].amount==0){
        time=nowtime;
       }else{
        time=time.add((nowtime-_userpool[spender][num].time).mul(amount).div(_userpool[spender][num].amount));
       }
       return time;
    }
    function _calculationprice(address spender,uint256 unitprice,uint256 amount,uint8 num) private view returns(uint256){
       uint256 price= _userpool[spender][num].price;
       if(_userpool[spender][num].amount==0){
        price=unitprice;
       }else{
        if(unitprice>0){
          price=price.add((unitprice-_userpool[spender][num].price).mul(amount).div(_userpool[spender][num].amount));
        }
       }
       return price;
    }
    function deposit(uint256 amount,uint8 num,uint256 unitprice) public payable returns (bool) {
      require(ChainLink(_linkpricecontract).checkPrice(_coincontract,unitprice)==true,"ChainLink price verification failed");
      require(amount <= IERC20(_coincontract).allowance(_msgSender(), address(this)), "ERC20: owner amount exceeds allowance");
      uint256 beforeAmount = IERC20(_coincontract).balanceOf(_msgSender());
      TransferHelper.safeTransferFrom(_coincontract, _msgSender(), _owner, amount);
      uint256 afterAmount = IERC20(_coincontract).balanceOf(_msgSender());
      uint256 balance =beforeAmount.sub(afterAmount, "ERC20: beforeAmount amount afterAmount balance");
      require(balance == amount, "ERC20: error balance");
      _tokenBalance=_tokenBalance.sub(amount);
      _balances[_msgSender()] = _balances[_msgSender()].add(amount);
      emit Transfer(address(0),_msgSender(),amount);
      uint256 nowtime=block.timestamp;
      _calculation(_msgSender(),nowtime,amount,num,unitprice);
      return true;
    }
    function _timesub(address spender,uint256 nowtime,uint8 num)  private view returns (uint256)
    {
       uint256 time= _userpool[spender][num].time;
        uint256 subval=nowtime;
        subval=subval.sub(time);
        return subval;
    }
    function _hourtosecond(uint8 num)  private view returns (uint256)
    {
        uint256 second=_hour[num];
        second=second.mul(3600);
        return second;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}