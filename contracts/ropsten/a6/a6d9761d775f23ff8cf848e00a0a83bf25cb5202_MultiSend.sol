pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title Send Util Token
 * @dev Token that for send.
 */
contract MultiSend is Ownable{
    
    event SendEvent(string methodName, address indexed contractAddr, address indexed from, address indexed to, uint256 value, bool status);
    event DebugLog(string info, address from, address to);
    
    function balanceOf(address _who) public view returns (uint256) {
        return _who.balance;
    }
    
    function multiTransferEth(address[] _tos, uint256[] _values) public onlyOwner returns (bool){
        require(_tos.length == _values.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            bool status = _tos[i].send(_values[i]);
            emit SendEvent("multiTransferEth", address(this), address(this), _tos[i], _values[i], status);
        }
        return true;
    }

    function multiBalanceOf(address _contractAddr, address[] _whos) public view returns (uint256[]){
        uint256 [] memory values;
        for (uint256 i = 0; i < _whos.length; i++) {
            uint256 balance = ERC20(_contractAddr).balanceOf(_whos[i]);
            values[values.length] = uint256(_whos[i]);
            values[values.length] = balance;
        }
        return values;
    }

    function multiAllowance(address _contractAddr, address[] _owners, address[] _spenders) public view returns (uint256[]){
        uint256 [] memory values;
        if (_owners.length != _spenders.length) {
            return values;
        }
        for (uint256 i = 0; i < _owners.length; i++) {
            uint256 allowance = ERC20(_contractAddr).allowance(_owners[i], _spenders[i]);
            values[values.length] = uint256(_owners[i]);
            values[values.length] = uint256(_spenders[i]);
            values[values.length] = allowance;
        }
        return values;
    }

    function multiTransfer(address _contractAddr, address[] _tos, uint256[] _values) public onlyOwner returns (bool){
        require(_tos.length == _values.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            bool status = ERC20(_contractAddr).transfer(_tos[i], _values[i]);
            emit SendEvent("multiTransfer", _contractAddr, address(this), _tos[i], _values[i], status);
        }
        return true;
    }

    function multiApprove(address _contractAddr, address[] _spenders, uint256[] _values) public onlyOwner returns (bool){
        require(_spenders.length == _values.length);
        for (uint256 i = 0; i < _spenders.length; i++) {
            bool status = ERC20(_contractAddr).approve(_spenders[i], _values[i]);
            emit SendEvent("multiApprove", _contractAddr, address(this), _spenders[i], _values[i], status);
        }
        return true;
    }

    function multiTransferFrom(address _contractAddr, address[] _froms, address[] _tos, uint256[] _values) public onlyOwner returns (bool){
        emit DebugLog("before require", address(this), address(this));
        require(_froms.length == _tos.length && _froms.length == _values.length);
        emit DebugLog("after require", address(this), address(this));
        for (uint256 i = 0; i < _froms.length; i++) {
            emit DebugLog("before transferFrom", _froms[i], _tos[i]);
            bool status = ERC20(_contractAddr).transferFrom(_froms[i], _tos[i], _values[i]);
            emit DebugLog("after transferFrom", _froms[i], _tos[i]);
            emit SendEvent("multiTransferFrom", _contractAddr, _froms[i], _tos[i], _values[i], status);
        }
        return true;
    }

    function multiInvokeWith2Args(address _contractAddr, string methodName, address[] _tos, uint256[] _values) public onlyOwner returns (bool){
        require(_tos.length == _values.length);
        bytes memory methodNameWithSign = concat(methodName, "(address,uint256)");
        bytes4 methodId = bytes4(keccak256(methodNameWithSign));
        for (uint256 i = 0; i < _tos.length; i++) {
            bool status = _contractAddr.call(methodId, _tos[i], _values[i]);
            emit SendEvent(methodName, _contractAddr, address(this), _tos[i], _values[i], status);
        }
        return true;
    }

    function multiInvokeWith3Args(address _contractAddr, string methodName, address[] _froms, address[] _tos, uint256[] _values) public onlyOwner returns (bool){
        //require(_tos.length == _values.length);
        emit DebugLog("before require", address(this), address(this));
        emit DebugLog("after require", address(this), address(this));
        emit DebugLog("before concat", address(this), address(this));
        bytes memory methodNameWithSign = concat(methodName , "(address,address,uint256)");
        emit DebugLog("after concat", address(this), address(this));
        emit DebugLog("before methodId", address(this), address(this));
        bytes4 methodId = bytes4(keccak256(methodNameWithSign));
        emit DebugLog("after methodId", address(this), address(this));
        for (uint256 i = 0; i < _froms.length; i++) {
            emit DebugLog("before call", _froms[i], _tos[i]);
            //bool status = _contractAddr.call(methodId, _froms[i], _tos[i], _values[i]);
            emit DebugLog("after call", _froms[i], _tos[i]);
            emit SendEvent(methodName, _contractAddr, _froms[i], _tos[i], _values[i], true);
        }
        return true;
    }
    
    function test3Args() public onlyOwner returns (bool){
        address _contractAddr = 0xcb3160b4f894e6a090aaeb9985697d83beecff5b;
        string memory methodName = "transferFrom";
        address[] memory _froms = new address[](2);
        address[] memory _tos = new address[](2);
        uint256[] memory _values = new uint256[](2);
        _froms[0] = 0x58A93C5bA738AC70e7BCD482B172572f923A3226;
        _froms[1] = 0x58A93C5bA738AC70e7BCD482B172572f923A3226;
        _tos[0] = 0xf69FD88635e70Feb845ad89087Bb6202F72cB35b;
        _tos[1] = 0x236aD1C1846B3eEB2BbAE8B304e79a1c5B1Af1dc;
        _values[0] = uint256(1000000);
        _values[1] = uint256(1000000);
        return multiInvokeWith3Args(_contractAddr, methodName, _froms, _tos, _values);
    }
    
    function concat(string _base, string _value) internal pure returns (bytes) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);
        // if _base is methodName(type1,type2) like then return _base. 
        if(_baseBytes[_baseBytes.length-1] == _valueBytes[_valueBytes.length-1]){
            return _baseBytes;
        }

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i++];
        }

        return _newValue;
    }
    
    function() public payable {
    }
}