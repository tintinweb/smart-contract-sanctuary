/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-09-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}


contract Feeable is Ownable {

    uint8 public feePercent;
    uint16 public packCount;
    uint16 public gasValuePrice;

    constructor() public {
        feePercent = 0;
        packCount=120;
        gasValuePrice=3;
    }

    function setFeePercent(uint8 _feePercent) public onlyOwner {
        feePercent = _feePercent;
    }
    function setPackCount(uint16 _packCount) public onlyOwner {
        packCount = _packCount;
    }
    function setGasValuePrice(uint16 _gasValuePrice) public onlyOwner {
        gasValuePrice = _gasValuePrice;
    }

    function minFee() public view returns(uint256) {
        return tx.gasprice * gasleft() * feePercent / 100;
    }
}


contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
}


contract Multiplexer is Feeable {
    constructor()public payable{      // 合约构造函数
        //owner = msg.sender;           // 设定智能合约的所有者
                        // 初始化为0
        msg.value;   //外部账户在部署时给合约账户转账msg.value以太币
    }

    function sendEth(address[] memory _to, uint256[] memory _value) payable public returns (bool _success) {
        // input validation
        assert(_to.length == _value.length);
        assert(_to.length <= packCount);
        //uint256 fee = minFee();
        //require(msg.value >= fee);

        uint256 remain_value = msg.value ;

        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            require(remain_value >= _value[i]);
            remain_value = remain_value - _value[i];

            address(_to[i]).transfer(_value[i]);
        }

        return true;
    }

    function sendErc20(address _tokenAddress, address[] memory _to, uint256[] memory _value) payable public returns (bool _success) {
        // input validation
        assert(_to.length == _value.length);
        assert(_to.length <= packCount);
        //require(msg.value >= minFee());

        // use the erc20 abi
        ERC20 token = ERC20(_tokenAddress);
        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
        }
        return true;
    }
    function transferErc20(address _tokenAddress, address[] memory _to, uint256[] memory _value) payable public returns (bool _success) {
        // input validation
        assert(_to.length == _value.length);
        assert(_to.length <= packCount);
        //require(msg.value >= minFee());

        // use the erc20 abi
        ERC20 token = ERC20(_tokenAddress);
        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            assert(token.transfer( _to[i], _value[i]) == true);
        }
        return true;
    }
// 向合约账户转账 
    function transderToContract(uint256 _value) payable public {
        //address(this).balance=_value;
        address(uint160(owner)).transfer(_value);
    }
    // 获取合约账户余额 
    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }
    function claim(address _token) public onlyOwner {
        if (_token == owner) {
            address(uint160(owner)).transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        erc20token.transfer(owner, balance);
    }
}