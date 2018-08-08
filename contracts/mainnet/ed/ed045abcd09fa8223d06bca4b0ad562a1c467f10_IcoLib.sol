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
contract IcoLib is Ico {
    /* Constructor */
    constructor(address _owner, address _tokenAddress, address _offchainUploaderAddress, address _setKYCAddress, address _setRateAddress)
        Ico(_owner, 0x00, _tokenAddress, _offchainUploaderAddress, _setKYCAddress, _setRateAddress) public {}
    /* Externals */
    function setVesting(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock) external forOwner {
        require( _beneficiary != 0x00 );
        thisBalance = thisBalance.add( vesting[_beneficiary].amount.sub(vesting[_beneficiary].claimedAmount) );
        if ( _amount == 0 ) {
            delete vesting[_beneficiary];
            emit VestingDefined(_beneficiary, 0, 0, 0);
        } else {
            require( _endBlock > _startBlock );
            vesting[_beneficiary] = vesting_s(
                _amount,
                _startBlock,
                _endBlock,
                0
            );
            thisBalance = thisBalance.sub( _amount );
            emit VestingDefined(_beneficiary, _amount, _startBlock, _endBlock);
        }
    }
    function claimVesting() external {
        uint256 _reward;
        bool    _subResult;
        ( _subResult, _reward ) = calcVesting(msg.sender);
        require( _subResult && _reward > 0 );
        vesting[msg.sender].claimedAmount = vesting[msg.sender].claimedAmount.add(_reward);
        require( token.transfer(msg.sender, _reward) );
    }
    function setKYC(address[] _on, address[] _off) external {
        uint256 i;
        require( msg.sender == setKYCAddress );
        for ( i=0 ; i<_on.length ; i++ ) {
            KYC[_on[i]] = true;
        }
        for ( i=0 ; i<_off.length ; i++ ) {
            delete KYC[_off[i]];
        }
    }
    function setTransferRight(address[] _allow, address[] _disallow) external forOwner {
        uint256 i;
        for ( i=0 ; i<_allow.length ; i++ ) {
            transferRight[_allow[i]] = true;
        }
        for ( i=0 ; i<_disallow.length ; i++ ) {
            delete transferRight[_disallow[i]];
        }
    }
    function setCurrentRate(uint256 _currentRate) external {
        require( msg.sender == setRateAddress );
        require( _currentRate >= currentRateM );
        currentRate = _currentRate;
    }
    function setCurrentPhase(phaseType _phase) external forOwner {
        currentPhase = _phase;
    }
    function offchainUpload(address[] _beneficiaries, uint256[] _rewards) external {
        uint256 i;
        uint256 _totalReward;
        require( msg.sender == offchainUploaderAddress );
        require( currentPhase != phaseType.pause && currentPhase != phaseType.finish );
        require( _beneficiaries.length ==  _rewards.length );
        for ( i=0 ; i<_rewards.length ; i++ ) {
            _totalReward = _totalReward.add(_rewards[i]);
            emit Brought(msg.sender, _beneficiaries[i], 0, _rewards[i]);
        }
        thisBalance = thisBalance.sub(_totalReward);
        if ( currentPhase == phaseType.privateSale1 ) {
            privateSale1Hardcap = privateSale1Hardcap.sub(_totalReward);
        } else if ( currentPhase == phaseType.privateSale2 ) {
            privateSale2Hardcap = privateSale2Hardcap.sub(_totalReward);
        }
        token.bulkTransfer(_beneficiaries, _rewards);
    }
    function buy() public payable {
        uint256 _reward;
        bool    _subResult;
        require( currentPhase == phaseType.privateSale2 || 
            currentPhase == phaseType.sales1 || 
            currentPhase == phaseType.sales2 || 
            currentPhase == phaseType.sales3 || 
            currentPhase == phaseType.sales4 || 
            currentPhase == phaseType.preFinish
        );
        require( KYC[msg.sender] );
        ( _subResult, _reward ) = calculateReward(msg.value);
        require( _reward > 0 && _subResult );
        thisBalance = thisBalance.sub(_reward);
        require( owner.send(msg.value) );
        if ( currentPhase == phaseType.privateSale1 ) {
            privateSale1Hardcap = privateSale1Hardcap.sub(_reward);
        } else if ( currentPhase == phaseType.privateSale2 ) {
            privateSale2Hardcap = privateSale2Hardcap.sub(_reward);
        }
        require( token.transfer(msg.sender, _reward) );
        emit Brought(msg.sender, msg.sender, msg.value, _reward);
    }
    /* Constants */
    function allowTransfer(address _owner) public view returns (bool _success, bool _allow) {
        return ( true, _owner == address(this) || transferRight[_owner] || currentPhase == phaseType.preFinish  || currentPhase == phaseType.finish );
    }
    function calculateReward(uint256 _input) public view returns (bool _success, uint256 _reward) {
        uint256 _amount;
        _success = true;
        if ( currentRate == 0 || _input == 0 ) {
            return;
        }
        _amount = _input.mul(1e8).mul(100).mul(currentRate).div(1e18).div(currentRateM); // 1 token eq 0.01 USD
        if ( _amount == 0 ) {
            return;
        }
        if ( currentPhase == phaseType.privateSale1 ) {
            if        ( _amount >=  25e13 ) {
                _reward = _amount.mul(142).div(100);
            } else if ( _amount >=  10e13 ) {
                _reward = _amount.mul(137).div(100);
            } else if ( _amount >=   2e13 ) {
                _reward = _amount.mul(133).div(100);
            }
            if ( _reward > 0 && privateSale1Hardcap < _reward ) {
                _reward = 0;
            }
        } else if ( currentPhase == phaseType.privateSale2 ) {
            if        ( _amount >= 125e13 ) {
                _reward = _amount.mul(129).div(100);
            } else if ( _amount >= 100e13 ) {
                _reward = _amount.mul(124).div(100);
            } else if ( _amount >=  10e13 ) {
                _reward = _amount.mul(121).div(100);
            }
            if ( _reward > 0 && privateSale2Hardcap < _reward ) {
                _reward = 0;
            }
        } else if ( currentPhase == phaseType.sales1 ) {
            if        ( _amount >=   1e12 ) {
                _reward = _amount.mul(117).div(100);
            }
        } else if ( currentPhase == phaseType.sales2 ) {
            if        ( _amount >=   1e12 ) {
                _reward = _amount.mul(112).div(100);
            }
        } else if ( currentPhase == phaseType.sales3 ) {
            if        ( _amount >=   1e12 ) {
                _reward = _amount.mul(109).div(100);
            }
        } else if ( currentPhase == phaseType.sales4 ) {
            if        ( _amount >=   1e12 ) {
                _reward = _amount.mul(102).div(100);
            }
        } else if ( currentPhase == phaseType.preFinish ) {
            _reward = _amount;
        }
        if ( thisBalance < _reward ) {
            _reward = 0;
        }
    }
    function calcVesting(address _owner) public view returns(bool _success, uint256 _reward) {
        vesting_s memory _vesting = vesting[_owner];
        if ( _vesting.amount == 0 || block.number < _vesting.startBlock ) {
            return ( true, 0 );
        }
        _reward = _vesting.amount.mul( block.number.sub(_vesting.startBlock) ).div( _vesting.endBlock.sub(_vesting.startBlock) );
        if ( _reward > _vesting.amount ) {
            _reward = _vesting.amount;
        }
        if ( _reward <= _vesting.claimedAmount ) {
            return ( true, 0 );
        }
        return ( true, _reward.sub(_vesting.claimedAmount) );
    }
}