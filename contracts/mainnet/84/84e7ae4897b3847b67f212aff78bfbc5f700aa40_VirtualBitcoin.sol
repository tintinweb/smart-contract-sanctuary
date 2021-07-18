// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VirtualBitcoinInterface.sol";

contract VirtualBitcoin is VirtualBitcoinInterface {

    string  constant public NAME = "Virtual Bitcoin";
    string  constant public SYMBOL = "VBTC";
    uint256 constant public COIN = 10 ** uint256(DECIMALS);
    uint8   constant public DECIMALS = 8;
    uint32  constant public SUBSIDY_HALVING_INTERVAL = 210000 * 20;
    uint256 constant public MAX_COIN = 21000000 * COIN;
    uint256 constant public PIZZA_POWER_PRICE = 10000 * COIN;
    uint256 constant public PRECISION = 1e4;

    uint256 immutable public genesisEthBlock;

    uint256 private _totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    struct Pizza {
        address owner;
        uint256 power;
        uint256 accSubsidy;
    }
    Pizza[] public pizzas;

    uint256 public accSubsidyBlock;
    uint256 public accSubsidy;
    uint256 public totalPower;

    constructor() {
        genesisEthBlock = block.number;

        accSubsidy = 0;
        accSubsidyBlock = block.number;

        pizzas.push(Pizza({
            owner: msg.sender,
            power: 1,
            accSubsidy: 0
        }));

        totalPower = 1;
    }

    function name() external pure override returns (string memory) { return NAME; }
    function symbol() external pure override returns (string memory) { return SYMBOL; }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }

    function balanceOf(address user) external view override returns (uint256 balance) {
        return balances[user];
    }

    function transfer(address to, uint256 amount) public override returns (bool success) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address user, address spender) external view override returns (uint256 remaining) {
        return allowed[user][spender];
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool success) {
        uint256 _allowance = allowed[from][msg.sender];
        if (_allowance != type(uint256).max) {
            allowed[from][msg.sender] = _allowance - amount;
        }
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) internal {
        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function collect(address to, uint256 amount) internal {
        balances[address(this)] -= amount;
        balances[to] += amount;
        emit Transfer(address(this), to, amount);
    }

    function pizzaPrice(uint256 power) external pure override returns (uint256) {
        return power * PIZZA_POWER_PRICE;
    }

    function pizzaCount() external view override returns (uint256) {
        return pizzas.length;
    }

    function subsidyAt(uint256 blockNumber) public view override returns (uint256 amount) {
        uint256 era = (blockNumber - genesisEthBlock) / SUBSIDY_HALVING_INTERVAL;
        amount = 25 * COIN / 10 / (2 ** era);
    }

    function calculateAccSubsidy() internal view returns (uint256) {
        uint256 _accSubsidyBlock = accSubsidyBlock;
        uint256 subsidy = 0;
        uint256 era1 = (_accSubsidyBlock - genesisEthBlock) / SUBSIDY_HALVING_INTERVAL;
        uint256 era2 = (block.number - genesisEthBlock) / SUBSIDY_HALVING_INTERVAL;

        if (era1 == era2) {
            subsidy = (block.number - _accSubsidyBlock) * subsidyAt(block.number);
        } else {
            uint256 boundary = (era1 + 1) * SUBSIDY_HALVING_INTERVAL + genesisEthBlock;
            subsidy = (boundary - _accSubsidyBlock) * subsidyAt(_accSubsidyBlock);
            uint256 span = era2 - era1;
            for (uint256 i = 1; i < span; i += 1) {
                boundary = (era1 + 1 + i) * SUBSIDY_HALVING_INTERVAL + genesisEthBlock;
                subsidy += SUBSIDY_HALVING_INTERVAL * subsidyAt(_accSubsidyBlock + SUBSIDY_HALVING_INTERVAL * i);
            }
            subsidy += (block.number - boundary) * subsidyAt(block.number);
        }

        return accSubsidy + subsidy * PRECISION / totalPower;
    }

    function makePizza(uint256 power) internal returns (uint256) {
        require(power > 0);

        uint256 pizzaId = pizzas.length;
        uint256 _accSubsidy = update();

        pizzas.push(Pizza({
            owner: msg.sender,
            power: power,
            accSubsidy: _accSubsidy * power / PRECISION
        }));

        totalPower += power;
        return pizzaId;
    }

    function buyPizza(uint256 power) external override returns (uint256) {
        transfer(address(this), power * PIZZA_POWER_PRICE);
        uint256 pizzaId = makePizza(power);
        emit BuyPizza(msg.sender, pizzaId, power);
        return pizzaId;
    }

    function changePizza(uint256 pizzaId, uint256 power) external override {
        Pizza storage pizza = pizzas[pizzaId];
        require(pizzaId != 0);
        require(pizza.owner == msg.sender);

        uint256 currentPower = pizza.power;
        require(currentPower != power);

        uint256 _accSubsidy = update();
        uint256 subsidy = _accSubsidy * currentPower / PRECISION - pizza.accSubsidy;
        if (subsidy > 0) {
            mint(msg.sender, subsidy);
        }
        emit Mine(msg.sender, pizzaId, subsidy);

        if (currentPower < power) { // upgrade
            uint256 diff = power - currentPower;
            transfer(address(this), diff * PIZZA_POWER_PRICE);
            totalPower += diff;
        } else { // downgrade
            uint256 diff = currentPower - power;
            collect(msg.sender, diff * PIZZA_POWER_PRICE);
            totalPower -= diff;
        }

        pizza.accSubsidy = _accSubsidy * power / PRECISION;
        pizza.power = power;

        emit ChangePizza(msg.sender, pizzaId, power);
    }

    function sellPizza(uint256 pizzaId) external override {
        Pizza storage pizza = pizzas[pizzaId];
        require(pizzaId != 0);
        require(pizza.owner == msg.sender);

        uint256 power = pizza.power;
        mine(pizzaId);
        pizza.owner = address(0);
        totalPower -= power;

        collect(msg.sender, power * PIZZA_POWER_PRICE);
        emit SellPizza(msg.sender, pizzaId);
    }

    function powerOf(uint256 pizzaId) external view override returns (uint256) {
        return pizzas[pizzaId].power;
    }

    function subsidyOf(uint256 pizzaId) external view override returns (uint256) {
        Pizza memory pizza = pizzas[pizzaId];
        if (pizza.owner == address(0)) {
            return 0;
        }
        return calculateAccSubsidy() * pizza.power / PRECISION - pizza.accSubsidy;
    }

    function mine(uint256 pizzaId) public override returns (uint256) {
        Pizza storage pizza = pizzas[pizzaId];
        require(pizza.owner == msg.sender);
        uint256 power = pizza.power;

        uint256 _accSubsidy = update();
        uint256 subsidy = _accSubsidy * power / PRECISION - pizza.accSubsidy;
        if (subsidy > 0) {
            mint(msg.sender, subsidy);
        }

        pizza.accSubsidy = _accSubsidy * power / PRECISION;
        emit Mine(msg.sender, pizzaId, subsidy);
        return subsidy;
    }

    function update() internal returns (uint256 _accSubsidy) {
        if (accSubsidyBlock != block.number) {
            _accSubsidy = calculateAccSubsidy();
            accSubsidy = _accSubsidy;
            accSubsidyBlock = block.number;
        } else {
            _accSubsidy = accSubsidy;
        }
    }
}