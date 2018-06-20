pragma solidity 0.4.23;

contract Asset {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256 supply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

contract Owned {
    bool public isConstructedOwned;
    address public contractOwner;
    address public pendingContractOwner;

    constructor() public {
        constructOwned();
    }

    function constructOwned() public returns(bool) {
        if (isConstructedOwned) {
            return false;
        }
        isConstructedOwned = true;
        contractOwner = msg.sender;
        return true;
    }

    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

    function changeContractOwnership(address _to) public onlyContractOwner() returns(bool) {
        pendingContractOwner = _to;
        return true;
    }

    function claimContractOwnership() public returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }
        contractOwner = pendingContractOwner;
        delete pendingContractOwner;
        return true;
    }

    function forceChangeContractOwnership(address _to) public onlyContractOwner() returns(bool) {
        contractOwner = _to;
        return true;
    }
}

contract Graceful {
    event Error(bytes32 message);

    // Only for functions that return bool success before any changes made.
    function _softRequire(bool _condition, bytes32 _message) internal {
        if (_condition) {
            return;
        }
        emit Error(_message);
        bool result = false;
        assembly {
            return(result, 32)
        }
    }

    // Generic substitution for require().
    function _hardRequire(bool _condition, bytes32 _message) internal pure {
        if (_condition) {
            return;
        }
        assembly {
            revert(_message, 32)
        }
    }

    function _not(bool _condition) internal pure returns(bool) {
        return !_condition;
    }
}

contract ERC20MigrationTestable is Graceful, Owned {
    Asset public oldToken;
    Asset public newToken;

    event Migrated(address user, uint value);

    constructor(Asset _oldToken, Asset _newToken) public {
        require(address(_oldToken) != 0x0);
        require(address(_newToken) != 0x0);

        oldToken = _oldToken;
        newToken = _newToken;
    }

    function migrate(uint _value) public returns(bool) {
        _softRequire(oldToken.transferFrom(msg.sender, address(this), _value), &#39;Old token transfer failed&#39;);
        _hardRequire(newToken.transfer(msg.sender, _value), &#39;New token transfer failed&#39;);
        emit Migrated(msg.sender, _value);
        return true;
    }

    function migrateAll() public returns(bool) {
        return migrate(oldToken.balanceOf(msg.sender));
    }

    function withdrawAllFundsFromContract() public onlyContractOwner() returns(bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }

    function withdrawAllTokensFromContract(Asset _contract) public onlyContractOwner() returns(bool) {
        return _contract.transfer(msg.sender, _contract.balanceOf(address(this)));
    }
}