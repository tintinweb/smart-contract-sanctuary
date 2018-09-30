pragma solidity ^0.4.24;

// SafeMath
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if(a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) external pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// Address library
library Address {
    function isContract(address account) internal view returns(bool) {
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// Token Receiver
interface IERC1155TokenReceiver {
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);
}

// Token
contract ERC1155TokenFtechiz {

    using SafeMath for uint256;
    using Address for address;

    // Items variables
    struct Items {
        string name;
        uint256 totalSupply;
        mapping (address => uint256) balances;
    }

    event Approval (address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    // Mappings
    mapping (uint256 => uint8) public decimals;
    mapping (uint256 => string) public symbols;
    mapping (uint256 => mapping(address => mapping(address => uint256))) allowances;
    mapping (uint256 => Items) public items;
    mapping (uint256 => string) public metadataURIs;

    // Constants
    bytes4 constant private ERC1155_RECEIVED = 0xf23a6e61;

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external {
        if(_from != msg.sender) {
            allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
        }

        items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

        emit Transfer(msg.sender, _from, _to, _id, _value);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external {
        this.transferFrom(_from, _to, _id, _value);

        require(_checkAndCallSafeTransfer(_from, _to, _id, _value, _data), "UNABLE TO CALL SAFE TRANSFER");
    }

    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external {
        require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValue, "UNABLE TO APPROVE");
        allowances[_id][msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _id, _currentValue, _value);
    }

    function balanceOf(uint256 _id, address _owner) external view returns (uint256) {
        return items[_id].balances[_owner];
    }

    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256) {
        return allowances[_id][_owner][_spender];
    }

    // Extended Functions
    function transfer(address _to, uint256 _id, uint256 _value) external {
        items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);
        emit Transfer(msg.sender, msg.sender, _to, _id, _value);
    }

    function safeTransfer(address _to, uint256 _id, uint256 _value, bytes _data) external {
        this.transfer(_to, _id, _value);

        require(_checkAndCallSafeTransfer(msg.sender, _to, _id, _value, _data), "UNABLE TO SAFE TRANSFER");
    }

    // Batch Transfer functions
    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        if(_from == msg.sender) {
            for(uint256 i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
        else {
            for (i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        this.batchTransferFrom(_from, _to, _ids, _values);

        for(uint256 i = 0; i < _ids.length; ++i) {
            require(_checkAndCallSafeTransfer(_from, _to, _ids[i], _values[i], _data), "UNABLE TO SAFE TRANSFER FROM");
        }
    }

    function batchApprove(address _spender, uint256[] _ids, uint256[] _currentValues, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for(uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValues[i], "UNABLE TO BATCH APPROVE");

            allowances[_id][msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _id, _currentValues[i], _value);
        }
    }

    // Batch Transfer Extended
    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for(uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

            emit Transfer(msg.sender, msg.sender, _to, _id, _value);
        }
    }

    function safeBatchTransfer(address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        this.batchTransfer(_to, _ids, _values);

        for(uint256 i = 0; i < _ids.length; ++i) {
            require(_checkAndCallSafeTransfer(msg.sender, _to, _ids[i], _values[i], _data), "UNABLE TO SAFE BATCH TRANSFER");
        }
    }

    // Optional Meta data
    function name(uint256 _id) external view returns (string) {
        return items[_id].name;
    }

    function symbol(uint256 _id) external view returns (string) {
        return symbols[_id];
    }

    function decimals(uint256 _id) external view returns (uint8) {
        return decimals[_id];
    }

    function totalSupply(uint256 _id) external view returns (uint256) {
        return items[_id].totalSupply;
    }

    function uri(uint256 _id) external view returns (string) {
        return metadataURIs[_id];
    }

    // Optionals
    function multicastTransfer(address[] _to, uint256[] _ids, uint256[] _values) external {
        for(uint256 i = 0; i < _to.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _value = _values[i];
            address _dst = _to[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_dst] = _value.add(items[_id].balances[_dst]);

            emit Transfer(msg.sender, msg.sender, _dst, _id, _value);
        }
    }

    function safeMulticastTransfer(address[] _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        this.multicastTransfer(_to, _ids, _values);

        for(uint256 i = 0; i < _ids.length; ++i) {
            require(_checkAndCallSafeTransfer(msg.sender, _to[i], _ids[i], _values[i], _data));
        }
    }

    // Internal
    function _checkAndCallSafeTransfer(address _from, address _to, uint256 _id, uint256 _value, bytes _data) internal returns(bool) {
        if(!_to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data);
        return (retval == ERC1155_RECEIVED);
    }
    
}