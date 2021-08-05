pragma solidity ^0.6.6;

import './Ownable.sol';
import './Address.sol';
import './ACOAssetHelper.sol';
import './IController.sol';
import './IControlled.sol';
import './IACOVault.sol';
import './IStrategy.sol';


contract Controller is Ownable, IController {
    using Address for address;
    
    event SetVault(address indexed newVault, address indexed newStrategy);
    event ChangeStrategy(address indexed vault, address indexed oldStrategy, address indexed newStrategy);
    event SetFeeDestination(address indexed oldFeeDestination, address indexed newFeeDestination);
    event SetOperator(address indexed operator, bool indexed previousPermission, bool indexed newPermission);

    address public feeDestination;

    mapping(address => address) public vaultsOfStrategy;
    mapping(address => address) public strategiesOfVault;

    mapping(address => bool) public operators;

    constructor(address _feeDestination) public {
        super.init();
        _setFeeDestination(_feeDestination);
        _setOperator(msg.sender, true);
    }
    
    function setVault(address newVault, address newStrategy) onlyOwner public {
        require(newVault.isContract(), "Controller:: Invalid vault");
        require(strategiesOfVault[newVault] == address(0), "Controller:: Vault already exists");
        require(newStrategy.isContract(), "Controller:: Invalid strategy");
        require(vaultsOfStrategy[newStrategy] == address(0), "Controller:: Strategy already exists");
        require(IACOVault(newVault).token() == IStrategy(newStrategy).token(), "Controller:: Asset does not match");
        
        emit SetVault(newVault, newStrategy);
        
        strategiesOfVault[newVault] = newStrategy;
        vaultsOfStrategy[newStrategy] = newVault;
    }
    
    function changeStrategy(address vault, address newStrategy) onlyOwner public {
        address oldStrategy = strategiesOfVault[vault];
        require(oldStrategy != address(0), "Controller:: Invalid vault");
        require(newStrategy.isContract(), "Controller:: Invalid strategy");
        require(vaultsOfStrategy[newStrategy] == address(0), "Controller:: Strategy already exists");
        address token = IACOVault(vault).token();
        require(token == IStrategy(newStrategy).token(), "Controller:: Asset does not match");
        
        IStrategy(oldStrategy).withdrawAll();
        
        emit ChangeStrategy(vault, strategiesOfVault[vault], newStrategy);
        
        strategiesOfVault[vault] = newStrategy;
        
        uint256 amount = IStrategy(oldStrategy).balanceOfWant();
        if (amount > 0) {
            ACOAssetHelper._callTransferFromERC20(token, oldStrategy, vault, amount);
        }
    }
    
    function setFeeDestination(address newFeeDestination) onlyOwner public {
        _setFeeDestination(newFeeDestination);
    }

    function setOperator(address operator, bool permission) onlyOwner public {
        _setOperator(operator, permission);
    }
    
    function withdrawStuckTokenOnControlled(address _contract, address token, address destination) onlyOwner public {
        IControlled(_contract).withdrawStuckToken(token, destination);
    }
    
    function withdrawStuckToken(address token, address destination) onlyOwner public {
        uint256 _balance = ACOAssetHelper._getAssetBalanceOf(token, address(this));
        if (_balance > 0) {
            ACOAssetHelper._transferAsset(token, destination, _balance);
        }
    }

    function buyAco(address vault, address acoPool, uint256 acoAmount, uint256 rewardAmount) external {
        require(operators[msg.sender], "Controller:: Invalid sender");
        require(strategiesOfVault[vault] != address(0), "Controller:: Invalid vault");
        ACOAssetHelper._callTransferFromERC20(IACOVault(vault).token(), strategiesOfVault[vault], vault, rewardAmount);
        IACOVault(vault).setReward(acoPool, acoAmount, rewardAmount);
    }
    
    function sendFee(uint256 amount) public override {
        require(strategiesOfVault[msg.sender] != address(0) || vaultsOfStrategy[msg.sender] != address(0), "Controller:: Invalid sender");
        if (amount > 0) {
            ACOAssetHelper._callTransferFromERC20(IControlled(msg.sender).token(), msg.sender, feeDestination, amount);
        }
    }
    
    function balanceOf(address vault) public view override returns(uint256) {
        return IStrategy(strategiesOfVault[vault]).balanceOf();
    }
    
    function actualAmount(address vault, uint256 amount) external view override returns(uint256) {
        return IStrategy(strategiesOfVault[vault]).actualBalanceFor(amount);
    }
    
    function earn(uint256 amount) public override {
        require(strategiesOfVault[msg.sender] != address(0), "Controller:: Invalid sender");
        IStrategy strategy = IStrategy(strategiesOfVault[msg.sender]);
        ACOAssetHelper._callTransferFromERC20(strategy.token(), msg.sender, address(strategy), amount);
        strategy.deposit(amount);
    }
    
    function withdraw(uint256 amount) public override returns(uint256) {
        require(strategiesOfVault[msg.sender] != address(0), "Controller:: Invalid sender");
        IStrategy strategy = IStrategy(strategiesOfVault[msg.sender]);
        uint256 _withdraw = strategy.withdraw(amount);
        ACOAssetHelper._callTransferFromERC20(strategy.token(), address(strategy), msg.sender, _withdraw);
        return _withdraw;
    }
    
    function _setFeeDestination(address newFeeDestination) internal {
        require(newFeeDestination != address(0), "Controller:: Invalid fee destination");
        emit SetFeeDestination(feeDestination, newFeeDestination);
        feeDestination = newFeeDestination;
    }

    function _setOperator(address operator, bool newPermission) internal {
        emit SetOperator(operator, operators[operator], newPermission);
        operators[operator] = newPermission;
    }
}