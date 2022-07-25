/**
 *Submitted for verification at hecoinfo.com on 2022-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "add err");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub err");
    return a - b;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(a == 0 || c / a == b, "mul err");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "div 0 err");
    uint256 c = a / b;
    require(a == b * c + a % b, "div err"); // There is no case in which this doesn't hold
    return c;
  }
}

interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;
    constructor () {
        _owner = msg.sender;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface SwapHelp  {
    function buySwap() external;
}

contract TxRule is Ownable{
    using SafeMath for uint256;

    mapping(address => bool) public txWhiteList;
    bool public needGas = true; 
    bool public needApproveTx = true; 
    bool public needSendRed = true;
    uint256 public allTotalGas = 0;
    uint256 public lastAllTotalGas = 0;
    uint256[] public gasRedRatioList = [400,100,500]; // 1000/10000  
    // uint256 public sendGasMin = 1000 * (10**18);
    // uint256 public haveRedMin = 20 * (10**18);
    uint256 public sendGasMin = 10 * (10**18);
    uint256 public haveRedMin = 2 * (10**10);

    function needApproveTxOnOff(bool _bo) external onlyOwner {
        needApproveTx = _bo;
    }
    function needGasOnOff(bool _bo) external onlyOwner {
        needGas = _bo;
    }
    function updateGasRatioList(uint256[] memory _values) external onlyOwner {
        require(_values.length == 3, "_values len is 3");
        uint256 gasRedRatioAll = 0;
        for (uint i=0; i<_values.length; i++) {
            gasRedRatioAll += _values[i];
        }
        require(gasRedRatioAll > 0 && gasRedRatioAll <= 10000, "_values sum error");
        gasRedRatioList= _values;
    }
    function updateSendGasMin(uint256 _value) external onlyOwner {
        require(_value>0, "_value is 0");
        sendGasMin = _value;
    }
    function addTxWhiteLists(address[] memory _addressList) external onlyOwner {
        for (uint256 i=0; i < _addressList.length; i++) {
            txWhiteList[_addressList[i]] = true;
        } 
    }
    function subTxWhiteList(address _address) external onlyOwner {
        delete txWhiteList[_address];
    }
    function updateHaveRedMin(uint256 _value) external onlyOwner {
        require(_value>0, "_value is 0");
        haveRedMin = _value;
    }
    
    /**
     * 分红 
    */ 
    uint256 oneToken = (10**18);
    SwapHelp swapHelp;
    address public swapHelpAddress;
    uint256 public allTotalReward = 0;  
    uint256 public lastTotalReward = 0;
    uint256 public totalAccSushi = 0;
    mapping(address => uint256) public usersAccSushi;
    address[] public noNeedRedUsers;
    mapping(address => bool) public noNeedRedUsersDic;
    function needSendRedOnOff(bool _bo) external onlyOwner {
        needSendRed = _bo;
    }
    function addNoNeedRedUsers(address _address) external onlyOwner {
        noNeedRedUsers.push(_address);
        noNeedRedUsersDic[_address] = true;
    }
    function subNoNeedRedUsers(uint256 _index) external onlyOwner {
        delete noNeedRedUsersDic[noNeedRedUsers[_index]];
        delete noNeedRedUsers[_index];
    }
    function setSwapHelp(address _address) external onlyOwner {
        swapHelpAddress = _address;
        swapHelp = SwapHelp(_address);
        txWhiteList[_address] = true;
        noNeedRedUsers.push(_address);
        noNeedRedUsersDic[_address] = true;
    }
        
    /**
     * swap 
    */ 
    address public bTokenAddress;
    address usdt = 0xa71EdC38d189767582C38A3145b5873052c3e47a; // usdt 
    address swap = 0xED7d5F38C79115ca12fe6C0041abb22F0A06C300; // heco
    address public uniswapV2PairtokenB;
    ERC20Basic bToken;
    ERC20Basic usdtToken = ERC20Basic(usdt);

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    constructor () { 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swap); 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdt); //getPair, createPair
        uniswapV2Router = _uniswapV2Router;
    }
    function initBTokenAddress(address _address) external onlyOwner {
        bTokenAddress = _address;
        uniswapV2PairtokenB = IUniswapV2Factory(uniswapV2Router.factory()).getPair(bTokenAddress, address(this)); //getPair, createPair
        bToken = ERC20Basic(bTokenAddress);
        txWhiteList[bTokenAddress] = true;
        txWhiteList[uniswapV2PairtokenB] = true;
    }
}

contract StandardToken is ERC20Basic,TxRule {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  uint256 _totalSupply;

  modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {
      revert();
    }
    _;
  }

    function priceToToken(uint256 _amount) public view returns(uint256) {
        require(_amount > 0, "Amount is 0");
        uint256 betBalance = balances[uniswapV2Pair];
        uint256 usdtBalance = usdtToken.balanceOf(uniswapV2Pair);
        if (betBalance == 0 || usdtBalance == 0) {
            return 0;
        }
        uint256 res = uniswapV2Router.getAmountIn(_amount, betBalance, usdtBalance);
        return res.mul(oneToken).div(_amount);
    } 
    function priceToTokenB(uint256 _amount) public view returns(uint256) {
        require(_amount > 0, "Amount is 0");
        uint256 betBalance = balances[uniswapV2PairtokenB];
        uint256 usdtBalance = bToken.balanceOf(uniswapV2PairtokenB);
        if (betBalance == 0 || usdtBalance == 0) {
            return 0;
        }
        uint256 res = uniswapV2Router.getAmountOut(_amount, betBalance, usdtBalance);
        return res.mul(oneToken).div(_amount);
    } 
    function countGasRedRatioAll() public view returns(uint256){
        return gasRedRatioList[0]+gasRedRatioList[1]+gasRedRatioList[2];
    }

    function totalValidBalance() public view returns (uint256) {
        uint256 amount = _totalSupply;
        for (uint256 i=0; i < noNeedRedUsers.length; i++) {
            if (noNeedRedUsers[i] != address(0x0)) {
                amount = amount.sub(balances[noNeedRedUsers[i]]);
            }
        }  
        return amount.sub(balances[address(0x0)]);
    }
    function balanceRedOf(address _user) public view returns (uint256) {
        if (noNeedRedUsersDic[_user] || balances[_user] < haveRedMin.mul(priceToToken(haveRedMin)).div(oneToken)) {return 0;}    
        
        uint256 _totalRed = allTotalReward.sub(lastTotalReward);
        uint256 _nowSushi = totalAccSushi.add(_totalRed.mul(_totalSupply).div(totalValidBalance()));
        uint256 _userRed = balances[_user].mul(_nowSushi.sub(usersAccSushi[_user])).div(_totalSupply);
        return _userRed;
    }
    function handleSendRed(address _user) public{
        if (noNeedRedUsersDic[_user] || balances[_user] < haveRedMin.mul(priceToToken(haveRedMin)).div(oneToken)) {return;}

        uint256 _nowSushi = totalAccSushi.add(allTotalReward.sub(lastTotalReward).mul(_totalSupply).div(totalValidBalance()));
        uint256 _userRed = balances[_user].mul(_nowSushi.sub(usersAccSushi[_user])).div(_totalSupply);
        
        if (_userRed > 0) {
            // inTtransfer(address(this), _user, _userRed);
            bToken.transfer(_user, _userRed);
        }
        
        usersAccSushi[_user] = _nowSushi;
        totalAccSushi = _nowSushi;
        lastTotalReward = allTotalReward;
    }
    function inTtransfer(address _from, address _to, uint256 _value) private {
        // if (_value > 0) {
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(_from, _to, _value);
        // }
    }
    function handleTrasfer() public { // private
        uint256 subAmount = allTotalGas.sub(lastAllTotalGas);
        if (subAmount > sendGasMin) {
            lastAllTotalGas = allTotalGas;
            inTtransfer(address(this), swapHelpAddress, subAmount);
            swapHelp.buySwap();
        }
    }

    function handleSubGasBalance(address _to, uint256 _value) public{
        uint256 _gas = _value.mul(countGasRedRatioAll()).div(10000);
        uint256 peerGas = _value.div(10000);
        allTotalGas = allTotalGas.add(_gas.sub(gasRedRatioList[2].mul(peerGas))); 
        uint256 redAmount = gasRedRatioList[2].mul(peerGas).mul(priceToTokenB(gasRedRatioList[2].mul(peerGas))).div(oneToken);
        allTotalReward = allTotalReward.add(redAmount);
        inTtransfer(_to, address(this), _gas);
    }
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_value <= balances[_from], "_from balance low");
        if (_from == address(this) || _from == uniswapV2PairtokenB || _to == uniswapV2PairtokenB) {
            inTtransfer(_from, _to, _value);
            return; 
        }

        if (needSendRed && totalValidBalance() > 0) { 
            // handleSendRed(_from);
            handleSendRed(_to);
        }
        
        inTtransfer(_from, _to, _value);

        if (needGas) {
            address gasAddress = address(0x0);
            if (_from == uniswapV2Pair) {
                gasAddress = _to;
            } 
            if (_to == uniswapV2Pair) {
                gasAddress = _from;
            }
            // 买卖
            if (gasAddress != address(0x0) && !txWhiteList[gasAddress]) {
                handleSubGasBalance(_to, _value);
            }  
            // 转账
            if (_to != uniswapV2Pair && _from != uniswapV2Pair) {
                if (_to != address(0x0) && !txWhiteList[_from]) {
                    handleSubGasBalance(_from, _value);
                } 
                handleTrasfer();
            }
        }
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        
        if (!txWhiteList[owner] && needApproveTx) { 
            handleTrasfer();
        }
    }
    
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    // require(_to != address(0));
    _transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0), "to do not is 0x0");
    require(_value <= allowed[_from][msg.sender], "_from allowed low");
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    _transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return balances[_owner];
  }
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }
  function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view override returns (uint256) {
    return allowed[_owner][_spender];
  }
  function increaseApproval(address _spender, uint _addedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    // require(allowed[msg.sender][_spender].add(_addedValue) <= balances[msg.sender]);
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
contract AMyToken is StandardToken {
    // string public constant symbol = "BRT";
    // string public constant name = "Bitrentech";
    string public constant symbol = "AA6";
    string public constant name = "AA6";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** 8) * (10 ** uint256(decimals));
    // uint256 public constant INITIAL_SUPPLY = 21 * (10 ** 4) * (10 ** uint256(decimals));

    constructor() {
        _totalSupply = INITIAL_SUPPLY;
        address systemReceive = msg.sender;

        noNeedRedUsers = [address(0x0), address(this), uniswapV2Pair];
        for (uint256 i=0; i < noNeedRedUsers.length; i++) {
            noNeedRedUsersDic[noNeedRedUsers[i]] = true;
            txWhiteList[noNeedRedUsers[i]] = true;
        }
        
        address[6] memory txWhiteUsers = [address(0x0), address(0x01), address(this), uniswapV2Pair,
            msg.sender, systemReceive];
        for (uint256 i=0; i < txWhiteUsers.length; i++) {
            txWhiteList[txWhiteUsers[i]] = true;
        }

        setSystemAddressAndBalance(systemReceive, INITIAL_SUPPLY);
    }
    
    function setSystemAddressAndBalance(address _user, uint256 _value) private {
        txWhiteList[_user] = true;
        noNeedRedUsers.push(_user);
        noNeedRedUsersDic[_user] = true;
        balances[_user] = _value;
        emit Transfer(address(0x0), _user, _value);
    }
}