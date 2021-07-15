/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT


abstract contract ERC20 {
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function transfer(address _to, uint256 _amount) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) virtual public returns (bool success); 
}


interface StoreInterface {
    function getExtensionStake(uint _option) external view returns(uint256, address);
    function getExtensionCollateral(uint _option) external view returns(uint256, address);
    function updateCollateral(uint256 _amount, uint256 _option) external;
}


interface StoreExtension {
    function processPayment(address _customer, uint256 _tokenID, uint256 _amount) external;
}


interface StoreHubInterface {
    function initBalance(address _store) external;
    function withdraw(address _to) external;
}


interface StoreProxy {
    function init(address _owner, address usdtHub, address daiHub) external;
}


contract StoreHub {
    event CollateralTransfer(address indexed store, address to, uint256 amount, uint256 rate, bool didTrade);
    event CollateralReliefUpdated(address indexed store, uint256 amount, uint256 rate, bool didAdd);
    event StoreCreated(address indexed store, address owner, uint256 creationDate); 
    event AtokenTransfer(address indexed store, address to, uint256 amount);
    event ExtensionUpdated(address indexed store, address extension);
    event OwnerUpdated(address indexed store, address newOwner);
    event StakeUpdated(address indexed store, uint256 stake);
    
    ERC20 public usdcContract;
    address public usdtStoreHub;
    address public daiStoreHub;
    address public storeImplementation;
    uint256 public totalSupply;
    
    mapping(address => bool) public isValidStore;
    mapping(address => uint256) public storeBalance;
    
    function deployStore() external {
        address newStore;
        bytes20 targetBytes = bytes20(storeImplementation);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStore := create(0, clone, 0x37)
        }
        StoreProxy(newStore).init(msg.sender, usdtStoreHub, daiStoreHub);
        isValidStore[newStore] = true;
        storeBalance[newStore] = 1;
        StoreHubInterface(usdtStoreHub).initBalance(newStore);
        StoreHubInterface(daiStoreHub).initBalance(newStore);
        emit StoreCreated(newStore, msg.sender, block.timestamp);
    }
    
    function withdraw(uint256 _collateral) external {
        require(isValidStore[msg.sender] == true);
        uint256 balance = storeBalance[msg.sender] - 1;
        storeBalance[msg.sender] = 1;
        totalSupply += _collateral;
        usdcContract.transfer(msg.sender, balance);
        emit CollateralTransfer(address(0), msg.sender, _collateral, 0, false);
    }
    
    function callEvent(
        address _value1,
        uint256 _value2, 
        uint256 _value3, 
        bool _value4,
        uint _option
    ) external {
        require(isValidStore[msg.sender] == true);
        
        if(_option == 0) {
            emit StakeUpdated(msg.sender, _value2);
        }
        else if(_option == 1) {
            emit CollateralReliefUpdated(msg.sender, _value2, _value3, _value4);
        }
        else if(_option == 2) {
            emit CollateralTransfer(msg.sender, _value1, _value2, _value3, _value4);
        }
        else if(_option == 3) {
            emit AtokenTransfer(msg.sender, _value1, _value2);
        }
        else if(_option == 4) {
            emit ExtensionUpdated(msg.sender, _value1);
        }
        else {
            emit OwnerUpdated(msg.sender, _value1);
        }
    }
}


contract mUSDC is StoreHub {
    
    string public name = "Malus USDC Token";
    string public symbol = "mUSDC";
    uint public decimals = 6;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    constructor(address _usdcContract, address _usdtStoreHub, address _daiStoreHub, address _implementation) {
        usdcContract = ERC20(_usdcContract);
        usdtStoreHub = _usdtStoreHub;
        daiStoreHub = _daiStoreHub;
        storeImplementation = _implementation;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(balances[msg.sender] >= _amount);
        
        if(isValidStore[_to] == true) {
            StoreInterface store = StoreInterface(_to);
            burn(store, msg.sender, 0, _amount); 
            return true;
        }
        
        balances[_to] += _amount;
        balances[msg.sender] -= _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(balances[_from] >= _amount);
        
        if(isValidStore[_to] == true) {
            StoreInterface store = StoreInterface(_to);
            burn(store, _from, 0, _amount); 
            return true;
        }
        
        if (_from != msg.sender && allowed[_from][msg.sender] < (2**256 - 1)) {
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        
        balances[_to] += _amount;
        balances[_from] -= _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
   
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    function mint(StoreInterface _store, uint256 _tokenID, uint256 _amount) external {
        (uint256 stake, address extensionAddress) = _store.getExtensionStake(0);
        uint256 cashbackAmount = ((_amount * 700) / 10000);
        uint256 prevStoreBalance = (storeBalance[address(_store)] += _amount) - _amount;
        require(cashbackAmount >= 1);
        require((stake - (((prevStoreBalance - 1) * 700) / 10000)) >= cashbackAmount); 
        balances[msg.sender] += cashbackAmount;
        usdcContract.transferFrom(msg.sender, address(this), _amount);
        
        if(extensionAddress != address(0)) {
            StoreExtension(extensionAddress).processPayment(msg.sender, _tokenID, _amount);
        }
        emit Transfer(address(_store), msg.sender, cashbackAmount);
    }
    
    function burn(StoreInterface _store, address _from, uint256 _tokenID, uint256 _amount) public {
        (uint256 collateral, address extensionAddress) = _store.getExtensionCollateral(0);
        require(isValidStore[address(_store)] == true);
        require(collateral >= _amount);
        require(balances[_from] >= _amount);
        
        if (_from != msg.sender && allowed[_from][msg.sender] < (2**256 - 1)) {
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        
        _store.updateCollateral(_amount, 0);
        balances[_from] -= _amount; 
        totalSupply -= _amount;
        
        if(extensionAddress != address(0)) {
            StoreExtension(extensionAddress).processPayment(msg.sender, _tokenID, _amount);
        }
        emit Transfer(msg.sender, address(_store), _amount);
    }
}