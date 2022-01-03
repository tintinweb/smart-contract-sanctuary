//SourceUnit: vetacoin.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract owned {
    address public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(payable(msg.sender) == owner);
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract LockBox {
    struct Deposit {
        uint256 time;
        uint256 amount;
        uint256 at;
    }

    struct Investor {
        uint256 id;
        uint256 ingresed;
        uint256 out;
        Deposit[] deposits;
        uint256 paidAt;
    }

    mapping(address => Investor) public investors;
    mapping(address => bool) public ids;

    function changeIdAcount(address user, uint256 id) internal {
        investors[user].id = id;
    }

    function frezzAmount(uint256 _value, uint256 _unlockTime)
        internal
        returns (uint256)
    {
        investors[payable(msg.sender)].ingresed += _value;
        investors[payable(msg.sender)].deposits.push(
            Deposit(_unlockTime, _value, block.timestamp)
        );

        return (_value);
    }

    function viewDeposits(address any_user, uint256 gpxinvid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        uint256 desde;
        uint256 hasta;
        uint256 cantidad;
        bool completado;

        Investor storage investor = investors[any_user];
        Deposit storage dep = investor.deposits[gpxinvid];

        uint256 largo = investor.deposits.length;

        desde = dep.at;
        hasta = dep.at + dep.time;
        cantidad = dep.amount;

        uint256 tiempoD = dep.time;

        uint256 finish = dep.at + tiempoD;
        uint256 since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
        uint256 till = block.timestamp > finish ? finish : block.timestamp;

        if (since < till) {
            completado = true;
        } else {
            completado = false;
        }

        return (desde, hasta, cantidad, completado, largo);
    }

    function withdrawable(address any_user)
        public
        view
        returns (uint256 amount)
    {
        Investor storage investor = investors[any_user];

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            uint256 tiempoD = dep.time;

            uint256 finish = dep.at + tiempoD;
            uint256 since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
            uint256 till = block.timestamp > finish ? finish : block.timestamp;

            if (since < till && block.timestamp >= finish) {
                amount += dep.amount;
            }
        }
    }

    function MYwithdrawable() public view returns (uint256 amount) {
        Investor storage investor = investors[payable(msg.sender)];

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            uint256 tiempoD = dep.time;

            uint256 finish = dep.at + tiempoD;
            uint256 since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
            uint256 till = block.timestamp > finish ? finish : block.timestamp;

            if (since < till && block.timestamp >= finish) {
                amount += dep.amount;
            }
        }
    }

    function withdraw() internal returns (uint256) {
        Investor storage investor = investors[payable(msg.sender)];
        investor.out += MYwithdrawable();
        investor.paidAt = block.timestamp;
        return MYwithdrawable();
       
        
    }
}

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

contract GpxTech is LockBox {
    using SafeMath for uint256;
    string public name;
    string public symbol;

    uint8 public decimals = 8;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        totalSupply = initialSupply * 10**uint256(decimals);
        balanceOf[payable(msg.sender)] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function balanceFrozen(address _from) public view returns (uint256) {
        return investors[_from].ingresed - investors[_from].out;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[payable(msg.sender)] >= _value); // Revisa si el enviador tiene suficientes
        balanceOf[payable(msg.sender)] -= _value; // Resta los token del enviador
        totalSupply -= _value; // Actualiza el total totalSupply
        emit Burn(payable(msg.sender), _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[_from] >= _value); // Revisa si la direccion objetivo tiene el balance suficiente
        require(_value <= allowance[_from][payable(msg.sender)]); // Comprueba lo asignado
        balanceOf[_from] -= _value; // Resta los token de la direccion objetivo
        allowance[_from][payable(msg.sender)] -= _value; // Resta el valor asignado
        totalSupply -= _value; // Actualiza el total supply
        emit Burn(_from, _value);
        return true;
    }
}

contract vetacoin is owned, GpxTech {
    using SafeMath for uint256;
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public MinTime;

    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) GpxTech(initialSupply, tokenName, tokenSymbol) {}

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(
            balanceOf[msg.sender] >= _value &&
                balanceOf[_to] + _value >= balanceOf[_to]
        );

        require(
            balanceOf[_from] - balanceFrozen(msg.sender) >= _value,
            "fondos insuficientes por congelacion"
        );
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        _transfer(payable(msg.sender), _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][payable(msg.sender)]); // Comprueba lo asignado
        allowance[_from][payable(msg.sender)] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(payable(msg.sender), _spender, _value);
        return true;
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                payable(msg.sender),
                _value,
                address(this),
                _extraData
            );
            return true;
        }
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

    function claimAcount(uint256 id) public {
        require(!ids[payable(msg.sender)]);
        changeIdAcount(payable(msg.sender), id);
        ids[payable(msg.sender)] = true;
    }

    function changeIdUserAcount(
        address user,
        uint256 id,
        bool status
    ) public onlyOwner {
        changeIdAcount(user, id);
        ids[user] = status;
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function freezveta(uint256 _value, uint256 _unlockTime) public {
        require(ids[payable(msg.sender)]);
        require(balanceOf[payable(msg.sender)] >= _value);
        require(_unlockTime >= MinTime);
        frezzAmount(_value, _unlockTime);
    }

    function unFreezveta() public {
        require(MYwithdrawable() > 0);
        withdraw();
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice)
        public
        onlyOwner
    {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function setMinTime(uint256 newMinTime) public onlyOwner {
        MinTime = newMinTime;
    }

    function buy() public payable {
        uint256 amount = msg.value / buyPrice;
        _transfer(address(this), payable(msg.sender), amount);
    }

    function sell(uint256 amount) public {
        address myAddress = address(this);
        require(myAddress.balance >= amount * sellPrice);
        _transfer(payable(msg.sender), address(this), amount);
        payable(msg.sender).transfer(amount * sellPrice);
    }
}