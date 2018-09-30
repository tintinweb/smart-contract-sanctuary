pragma solidity "0.4.20";

contract Erc20 {
    /** ERC20 Interface **
    * Source: https://github.com/ethereum/EIPs/issues/20
    * Downloaded: 2018.08.16
    * Version without events and comments
    * The full version can be downloaded at the source link
    */

    string public name;
    string public symbol;
    uint8 public decimals;
    
    function approve(address, uint256) public returns (bool _success);
    function allowance(address, address) constant public returns (uint256 _remaining);
    function balanceOf(address) constant public returns (uint256 _balance);
    function totalSupply() constant public returns (uint256 _totalSupply);
    function transfer(address, uint256) public returns (bool _success);
    function transferFrom(address, address, uint256) public returns (bool _success);
}

contract Erc20Test is Erc20 {
    /** ERC20 Test Contract with dummy data **/

    string public name;
    string public symbol;
    uint8 public decimals;

    function Erc20Test(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function approve(address, uint256) public returns (bool) {return true;}
    function allowance(address, address) constant public returns (uint256) {return 42;}
    function balanceOf(address) constant public returns (uint256) {return 42;}
    function totalSupply() constant public returns (uint256) {return 42;}
    function transfer(address, uint256) public returns (bool) {return true;}
    function transferFrom(address, address, uint256) public returns (bool) {return true;}
}

contract Accessible {
    /** Access Right Management **
    * Copyright 2018
    * Florian Weigand
    * Synalytix UG, Munich
    * florian(at)synalytix.de
    * Created at: 2018.03.22
    * Last modified at: 2018.09.17
    */

    // emergency stop
    bool                                private stopped = false;
    bool                                private accessForEverybody = false;
    address                             public owner;
    mapping(address => bool)            public accessAllowed;

    function Accessible() public {
        owner = msg.sender;
    }

    modifier ownership() {
        require(owner == msg.sender);
        _;
    }

    modifier accessible() {
        require(accessAllowed[msg.sender] || accessForEverybody);
        require(!stopped);
        _;
    }

    function allowAccess(address _address) ownership public {
        if (_address != address(0)) {
            accessAllowed[_address] = true;
        }
    }

    function denyAccess(address _address) ownership public {
        if (_address != address(0)) {
            accessAllowed[_address] = false;
        }
    }

    function transferOwnership(address _address) ownership public {
        if (_address != address(0)) {
            owner = _address;
        }
    }

    function toggleContractStopped() ownership public {
        stopped = !stopped;
    }

    function toggleContractAccessForEverybody() ownership public {
        accessForEverybody = !accessForEverybody;
    }
}

contract Erc20SummaryStorage is Accessible {
    /** Data Storage Contract **
    * Copyright 2018
    * Florian Weigand
    * Synalytix UG, Munich
    * florian(at)synalytix.de
    * Created at: 2018.08.02
    * Last modified at: 2018.08.16
    */
       
    /**** smart contract storage ****/
    address[]                           public smartContracts;
    mapping(address => bool)            public smartContractsAdded;
    
    /**** general storage of non-struct data which might 
    be needed for further development of main contract ****/
    mapping(bytes32 => uint256)         public uIntStorage;
    mapping(bytes32 => string)          public stringStorage;
    mapping(bytes32 => address)         public addressStorage;
    mapping(bytes32 => bytes)           public bytesStorage;
    mapping(bytes32 => bool)            public boolStorage;
    mapping(bytes32 => int256)          public intStorage;

    /**** CRUD for smart contract storage ****/
    function getSmartContractByPosition(uint position) external view returns (address) {
        return smartContracts[position];
    }

    function getSmartContractsLength() external view returns (uint) {
        return smartContracts.length;
    }
    
    function addSmartContractByAddress(address _contractAddress) accessible external {           
        // empty address not allow
        require(_contractAddress != address(0));
        // address was not added before
        require(!smartContractsAdded[_contractAddress]);
        
        // add new address
        smartContractsAdded[_contractAddress] = true;
        smartContracts.push(_contractAddress);
    }
    
    function removeSmartContractByAddress(address _contractAddress) accessible external {
        uint256 endPointer = smartContracts.length;
        uint256 startPointer = 0;
        
        while(endPointer > startPointer) {
            // swap replace
            if(smartContracts[startPointer] == _contractAddress) {              
                // as long as the last element is target delete it before swap
                while(smartContracts[endPointer - 1] == _contractAddress) {
                    endPointer = endPointer - 1;
                    // stop if no element left
                    if(endPointer == 0) break;
                }
                
                if(endPointer > startPointer) {
                    smartContracts[startPointer] = smartContracts[endPointer - 1];
                    endPointer = endPointer - 1;
                }
            }
            startPointer = startPointer + 1;
        }
        smartContracts.length = endPointer;
        // reset, so it can be added again
        smartContractsAdded[_contractAddress] = false;
    }

    /**** Get Methods for additional storage ****/
    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    function getUint(bytes32 _key) external view returns (uint) {
        return uIntStorage[_key];
    }

    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }

    /**** Set Methods for additional storage ****/
    function setAddress(bytes32 _key, address _value) accessible external {
        addressStorage[_key] = _value;
    }

    function setUint(bytes32 _key, uint _value) accessible external {
        uIntStorage[_key] = _value;
    }

    function setString(bytes32 _key, string _value) accessible external {
        stringStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes _value) accessible external {
        bytesStorage[_key] = _value;
    }
    
    function setBool(bytes32 _key, bool _value) accessible external {
        boolStorage[_key] = _value;
    }
    
    function setInt(bytes32 _key, int _value) accessible external {
        intStorage[_key] = _value;
    }

    /**** Delete Methods for additional storage ****/
    function deleteAddress(bytes32 _key) accessible external {
        delete addressStorage[_key];
    }

    function deleteUint(bytes32 _key) accessible external {
        delete uIntStorage[_key];
    }

    function deleteString(bytes32 _key) accessible external {
        delete stringStorage[_key];
    }

    function deleteBytes(bytes32 _key) accessible external {
        delete bytesStorage[_key];
    }
    
    function deleteBool(bytes32 _key) accessible external {
        delete boolStorage[_key];
    }
    
    function deleteInt(bytes32 _key) accessible external {
        delete intStorage[_key];
    }
}

contract Erc20SummaryLogic is Accessible {
    /** Logic Contract (updatable) **
    * Copyright 2018
    * Florian Weigand
    * Synalytix UG, Munich
    * florian(at)synalytix.de
    * Created at: 2018.08.02
    * Last modified at: 2018.08.16
    */

    Erc20SummaryStorage erc20SummaryStorage;

    function Erc20SummaryLogic(address _erc20SummaryStorage) public {
        erc20SummaryStorage = Erc20SummaryStorage(_erc20SummaryStorage);
    }

    function addSmartContract(address _contractAddress) accessible public {
        // TODO: sth like EIP-165 would be nice
        // see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
        // require(erc20Contract.totalSupply.selector ^ erc20Contract.balanceOf.selector ^ erc20Contract.allowance.selector ^ erc20Contract.approve.selector ^ erc20Contract.transfer.selector ^ erc20Contract.transferFrom.selector);

        // as EIP-165 is not available check for the most important functions of ERC20 to be implemented
        Erc20 erc20Contract = Erc20(_contractAddress);
        erc20Contract.name();
        erc20Contract.symbol();
        erc20Contract.decimals();
        erc20Contract.totalSupply();
        erc20Contract.balanceOf(0x281055Afc982d96fAB65b3a49cAc8b878184Cb16);

        // if it did not crash (because of a missing function) it should be an ERC20 contract
        erc20SummaryStorage.addSmartContractByAddress(_contractAddress);
    }

    function addSmartContracts(address[] _contractAddresses) accessible external {
        for(uint i = 0; i < _contractAddresses.length; i++) {
            addSmartContract(_contractAddresses[i]);
        }
    }

    function removeSmartContract(address _contractAddress) accessible external {
        erc20SummaryStorage.removeSmartContractByAddress(_contractAddress);
    }

    function erc20BalanceForAddress(address _queryAddress) external view returns (address[], uint[], uint8[]) {
        uint amountOfSmartContracts = erc20SummaryStorage.getSmartContractsLength();
        address[] memory contractAddresses = new address[](amountOfSmartContracts);
        uint[] memory balances = new uint[](amountOfSmartContracts);
        uint8[] memory decimals = new uint8[](amountOfSmartContracts);
        address tempErc20ContractAddress;
        Erc20 tempErc20Contract;

        for (uint i = 0; i < amountOfSmartContracts; i++) {
            tempErc20ContractAddress = erc20SummaryStorage.getSmartContractByPosition(i);
            tempErc20Contract = Erc20(tempErc20ContractAddress);
            contractAddresses[i] = tempErc20ContractAddress;
            balances[i] = tempErc20Contract.balanceOf(_queryAddress);
            decimals[i] = tempErc20Contract.decimals();
        }
        return (contractAddresses, balances, decimals);
    }
}