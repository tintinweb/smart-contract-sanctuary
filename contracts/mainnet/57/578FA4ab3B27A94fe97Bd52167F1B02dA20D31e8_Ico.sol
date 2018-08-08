pragma solidity 0.4.24;
contract Owned {
    /* Variables */
    address public owner = msg.sender;
    /* Constructor */
    constructor(address _owner) public {
        if ( _owner == 0x00 ) {
            _owner = msg.sender;
        }
        owner = _owner;
    }
    /* Externals */
    function replaceOwner(address _owner) external returns(bool) {
        require( isOwner() );
        owner = _owner;
        return true;
    }
    /* Internals */
    function isOwner() internal view returns(bool) {
        return owner == msg.sender;
    }
    /* Modifiers */
    modifier forOwner {
        require( isOwner() );
        _;
    }
}
library SafeMath {
    /* Internals */
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert( c >= a );
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a - b;
        assert( c <= a );
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a * b;
        assert( c == 0 || c / a == b );
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }
    function pow(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a ** b;
        assert( c % a == 0 );
        return a ** b;
    }
}
contract TokenDB is Owned {
    /* Externals */
    function transfer(address _from, address _to, uint256 _amount) external returns(bool _success) {}
    function bulkTransfer(address _from, address[] _to, uint256[] _amount) external returns(bool _success) {}
    function setAllowance(address _owner, address _spender, uint256 _amount) external returns(bool _success) {}
    /* Constants */
    function getAllowance(address _owner, address _spender) public view returns(bool _success, uint256 _remaining) {}
    function balanceOf(address _owner) public view returns(bool _success, uint256 _balance) {}
}
contract Token is Owned {
    /* Declarations */
    using SafeMath for uint256;
    /* Variables */
    string  public name = "Inlock token";
    string  public symbol = "ILK";
    uint8   public decimals = 8;
    uint256 public totalSupply = 44e16;
    address public libAddress;
    TokenDB public db;
    Ico public ico;
    /* Fallback */
    function () public { revert(); }
    /* Externals */
    function changeLibAddress(address _libAddress) external forOwner {}
    function changeDBAddress(address _dbAddress) external forOwner {}
    function changeIcoAddress(address _icoAddress) external forOwner {}
    function approve(address _spender, uint256 _value) external returns (bool _success) {}
    function transfer(address _to, uint256 _amount) external returns (bool _success) {}
    function bulkTransfer(address[] _to, uint256[] _amount) external returns (bool _success) {}
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success) {}
    /* Constants */
    function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {}
    function balanceOf(address _owner) public view returns (uint256 _balance) {}
    /* Events */
    event AllowanceUsed(address indexed _spender, address indexed _owner, uint256 indexed _value);
    event Mint(address indexed _addr, uint256 indexed _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract Ico is Owned {
    /* Declarations */
    using SafeMath for uint256;
    /* Enumerations */
    enum phaseType {
        pause,
        privateSale1,
        privateSale2,
        sales1,
        sales2,
        sales3,
        sales4,
        preFinish,
        finish
    }
    struct vesting_s {
        uint256 amount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 claimedAmount;
    }
    /* Variables */
    mapping(address => bool) public KYC;
    mapping(address => bool) public transferRight;
    mapping(address => vesting_s) public vesting;
    phaseType public currentPhase;
    uint256   public currentRate;
    uint256   public currentRateM = 1e3;
    uint256   public privateSale1Hardcap = 4e16;
    uint256   public privateSale2Hardcap = 64e15;
    uint256   public thisBalance = 44e16;
    address   public offchainUploaderAddress;
    address   public setKYCAddress;
    address   public setRateAddress;
    address   public libAddress;
    Token     public token;
    /* Constructor */
    constructor(address _owner, address _libAddress, address _tokenAddress, address _offchainUploaderAddress,
        address _setKYCAddress, address _setRateAddress) Owned(_owner) public {
        currentPhase = phaseType.pause;
        libAddress = _libAddress;
        token = Token(_tokenAddress);
        offchainUploaderAddress = _offchainUploaderAddress;
        setKYCAddress = _setKYCAddress;
        setRateAddress = _setRateAddress;
    }
    /* Fallback */
    function () public payable {
        buy();
    }
    /* Externals */
    function changeLibAddress(address _libAddress) external forOwner {
        libAddress = _libAddress;
    }
    function changeOffchainUploaderAddress(address _offchainUploaderAddress) external forOwner {
        offchainUploaderAddress = _offchainUploaderAddress;
    }
    function changeKYCAddress(address _setKYCAddress) external forOwner {
        setKYCAddress = _setKYCAddress;
    }
    function changeSetRateAddress(address _setRateAddress) external forOwner {
        setRateAddress = _setRateAddress;
    }
    function setVesting(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock) external {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function claimVesting() external {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function setKYC(address[] _on, address[] _off) external {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function setTransferRight(address[] _allow, address[] _disallow) external {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function setCurrentRate(uint256 _currentRate) external {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function setCurrentPhase(phaseType _phase) external {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function offchainUpload(address[] _beneficiaries, uint256[] _rewards) external {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function buy() public payable {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    /* Constants */
    function allowTransfer(address _owner) public view returns (bool _success, bool _allow) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x40)
            }
        }
    }
    function calculateReward(uint256 _input) public view returns (bool _success, uint256 _reward) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x40)
            }
        }
    }
    function calcVesting(address _owner) public view returns(bool _success, uint256 _reward) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x40)
            }
        }
    }
    /* Events */
    event Brought(address _owner, address _beneficiary, uint256 _input, uint256 _output);
    event VestingDefined(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock);
    event VestingClaimed(address _beneficiary, uint256 _amount);
}