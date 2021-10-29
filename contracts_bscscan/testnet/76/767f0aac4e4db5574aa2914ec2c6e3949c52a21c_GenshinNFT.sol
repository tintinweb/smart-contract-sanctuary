pragma solidity ^0.5.0;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol" ;

contract GenshinNFT is Ownable {
    using SafeMath for uint256;

    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    // TradeFee
    uint256 private tradeFeeTotal;
    address private shareAddress;
    address private marketingAddress;
    address private destroyAddress;
    uint256 private shareFeeRate;// 2.5%
    uint256 private marketingFeeRate;// 2%
    uint256 private destroyFeeRate;// 0.5%

    mapping(address => bool) private pancakePairAddress;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event AddressList(address indexed _account, address _shareAddress, address _marketingAddress, address _destroyAddress);
    event FeeRateList(address indexed _account, uint256 _shareFeeRate, uint256 _marketingFeeRate, uint256 _destroyFeeRate);
    event PancakePairAddress(address indexed _account, address _pancakePairAddress, bool _value);
    event TradeFee(address indexed _account, uint256 _tradeFee);

    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "Genshin NFT";
        _symbol = "GENSHIN";
        _decimals = 18;
        _totalSupply = 10000000000 * 10 ** 18;// 10000000000.mul(10 ** uint256(18));
        balances[_initial_account] = _totalSupply;
        emit Transfer(address(this), _initial_account, _totalSupply);
    }

    // ================= Special transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");

        if(pancakePairAddressOf(_sender)){
            balances[_sender] -= _amount;// _sender 100%

            uint256 tradeFeeRate = shareFeeRate.add(marketingFeeRate).add(destroyFeeRate);
            uint256 recipientFeeRate = 1000 - tradeFeeRate;

            balances[_recipient] += _amount.mul(recipientFeeRate).div(1000);// _recipient 100%-5%
            emit Transfer(_sender, _recipient, _amount.mul(recipientFeeRate).div(1000));

            balances[shareAddress] += _amount.mul(shareFeeRate).div(1000);// shareFeeRate 2.5%
            emit Transfer(_sender, shareAddress, _amount.mul(shareFeeRate).div(1000));

            balances[marketingAddress] += _amount.mul(marketingFeeRate).div(1000);// marketingAddress 2%
            emit Transfer(_sender, marketingAddress, _amount.mul(marketingFeeRate).div(1000));

            balances[destroyAddress] += _amount.mul(destroyFeeRate).div(1000);// destroyAddress 0.5%
            emit Transfer(_sender, destroyAddress, _amount.mul(destroyFeeRate).div(1000));

            tradeFeeTotal += _amount.mul(tradeFeeRate).div(1000);
            emit TradeFee(_sender, _amount.mul(tradeFeeRate).div(1000));// tradeFee 5%

        }else if(pancakePairAddressOf(_recipient)){
            uint256 tradeFeeRate = shareFeeRate.add(marketingFeeRate).add(destroyFeeRate);

            require(_amount.add(_amount.mul(tradeFeeRate).div(1000)) <= balances[_sender],"ERC20: transfer amount exceeds balance");
            balances[_sender] -= _amount.add(_amount.mul(tradeFeeRate).div(1000));// _sender 101.5%

            balances[_recipient] += _amount;// _recipient 100%
            emit Transfer(_sender, _recipient, _amount);

            balances[shareAddress] += _amount.mul(shareFeeRate).div(1000);// shareFeeRate 2.5%
            emit Transfer(_sender, shareAddress, _amount.mul(shareFeeRate).div(1000));

            balances[marketingAddress] += _amount.mul(marketingFeeRate).div(1000);// marketingAddress 2%
            emit Transfer(_sender, marketingAddress, _amount.mul(marketingFeeRate).div(1000));

            balances[destroyAddress] += _amount.mul(destroyFeeRate).div(1000);// destroyAddress 0.5%
            emit Transfer(_sender, destroyAddress, _amount.mul(destroyFeeRate).div(1000));

            tradeFeeTotal += _amount.mul(tradeFeeRate).div(1000);
            emit TradeFee(_sender, _amount.mul(tradeFeeRate).div(1000));// tradeFee 5%

        }else{
            balances[_sender] -= _amount;
            balances[_recipient] += _amount;
            emit Transfer(_sender, _recipient, _amount);
        }
    }

    function getFeeBasic() public view returns (uint256 TradeFeeTotal,address ShareAddress,address MarketingAddress,address DestroyAddress,uint256 ShareFeeRate,uint256 MarketingFeeRate,uint256 DestroyFeeRate) {
        return (tradeFeeTotal,shareAddress,marketingAddress,destroyAddress,shareFeeRate,marketingFeeRate,destroyFeeRate);
    }

    function setAddressList(address _shareAddress,address _marketingAddress,address _destroyAddress) public onlyOwner returns (bool) {
        shareAddress = _shareAddress;
        marketingAddress = _marketingAddress;
        destroyAddress = _destroyAddress;
        emit AddressList(msg.sender, _shareAddress, _marketingAddress, _destroyAddress);
        return true;
    }

    function setFeeRate(uint256 _shareFeeRate,uint256 _marketingFeeRate,uint256 _destroyFeeRate) public onlyOwner returns (bool) {
        shareFeeRate = _shareFeeRate;
        marketingFeeRate = _marketingFeeRate;
        destroyFeeRate = _destroyFeeRate;
        emit FeeRateList(msg.sender, _shareFeeRate, _marketingFeeRate, _destroyFeeRate);
        return true;
    }

    function addPancakePairAddress(address _pancakePairAddress,bool _value) public onlyOwner returns (bool) {
        pancakePairAddress[_pancakePairAddress] = _value;
        emit PancakePairAddress(msg.sender, _pancakePairAddress, _value);
        return true;
    }

    function pancakePairAddressOf(address _pancakePairAddress) public view returns (bool) {
        return pancakePairAddress[_pancakePairAddress];
    }

    // ================= ERC20 Basic Write ===============

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // ================= ERC20 Basic Query ===============

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

}