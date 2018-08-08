pragma solidity ^0.4.16;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}

contract owned {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    event SelfMessage(address backer1, address backer2);
    
    modifier isOwner {
        emit SelfMessage(msg.sender, owner);
        require(msg.sender == owner);
        _;
    }
}


contract GAMTToken is owned{
    string public constant name = "ga-me.io token";
    string public constant symbol = "GAMT";
    uint8 public constant decimals = 18;  // 18 是建议的默认值
    uint256 public totalSupply;
    uint256 amountRaised = 0;
    bool public crowdSale = false;

    mapping (address => uint256) public balanceOf;  // 
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public airDropAccount;
    event FreezeAccount(address target, bool frozen);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event CrowdSaleTransfer(address backer, uint256 crowdNum,  uint256 amount, bool indexed isContribution);
    

    constructor() public {
        totalSupply = 1000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        require(!frozenAccount[msg.sender]);
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function () payable public{
        require(crowdSale);
        uint256 amountETH = msg.value;
        uint256 count = amountETH / 10 ** uint256(15);
        uint256 tokenNum = 0;
        if (0 == amountETH){
            require(!airDropAccount[msg.sender]);
            tokenNum  = 200* 10 ** uint256(decimals);
            _transfer(address(this), msg.sender, tokenNum);

            airDropAccount[msg.sender] = true;
            emit CrowdSaleTransfer(msg.sender, amountETH, tokenNum, true);
        } else if (0 <amountETH && amountETH <5 * 10 **uint256(16)) {
            //0~0.05
            tokenNum  = 1000*count*10 ** uint256(decimals);
            amountRaised += amountETH;
            _transfer(address(this), msg.sender, tokenNum);
            emit CrowdSaleTransfer(msg.sender, amountETH, tokenNum, true);
        } else if (5 * 10 **uint256(16) <=amountETH && amountETH < 5 * 10 **uint256(17)) {
            //0.05~0.05
            tokenNum  = 1250*count*10 ** uint256(decimals);
            amountRaised += amountETH;
            _transfer(address(this), msg.sender, tokenNum);
            emit CrowdSaleTransfer(msg.sender, amountETH, tokenNum, true);
        } else {
            //0.5~
            tokenNum  = 1500*count*10 ** uint256(decimals);
            amountRaised += amountETH;
            _transfer(address(this), msg.sender, tokenNum);
            emit CrowdSaleTransfer(msg.sender, amountETH, tokenNum, true);
        }
    }

    function drawEther() isOwner public {
            if (owner.send(amountRaised)) {
                amountRaised = 0;
            }
    }

    function onOffCrowdSale(bool onOff) isOwner public {
        crowdSale = onOff;
        if(false == crowdSale){
            uint256 restToken = balanceOf[this];
            if (restToken > 0){
                _transfer(address(this), owner, restToken);
            } else {
            }
        }
    }

    function freezeAccount(address target, bool freeze) isOwner public{
        frozenAccount[target] = freeze;
        emit FreezeAccount(target, freeze);
    }
}