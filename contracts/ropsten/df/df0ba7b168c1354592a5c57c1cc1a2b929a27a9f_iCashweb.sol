pragma solidity ^0.4.24;
///////////////////////////////////////////////////
//  
//  `iCashweb` ICW Token Contract
//
//  Total Tokens: 300,000,000.000000000000000000
//  Name: iCashweb
//  Symbol: ICWeb
//  Decimal Scheme: 18
//  
//  by Nishad Vadgama
///////////////////////////////////////////////////

library iMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract iCashwebToken {
    
    address public iOwner;
    mapping(address => bool) iOperable;
    bool _mintingStarted;
    bool _minted;
    
    constructor () public {
        iOwner = address(0);
    }

    modifier notMinted() {
        require(_minted == false);
        _;
    }

    modifier mintingStarted() {
        require(_mintingStarted == true);
        _;
    }
    
    modifier iOnlyOwner() {
        require(address(0) == iOwner || iOperable[address(0)] == true);
        _;
    }
    
    function manageOperable(address _from, bool _value) public returns(bool) {
        require(address(0) == iOwner);
        iOperable[_from] = _value;
        emit Operable(address(0), _from, _value);
        return true;
    }

    function isOperable(address _addr) public view returns(bool) {
        return iOperable[_addr];
    }

    function manageMinting(bool _val) public {
        require(address(0) == iOwner);
        _mintingStarted = _val;
        emit Minting(_val);
    }

    function destroyContract() public {
        require(address(0) == iOwner);
        selfdestruct(iOwner);
    }
    
    event Operable(address _owner, address _from, bool _value);
    event Minting(bool _value);
    event OwnerTransferred(address _from, address _to);
}

contract iCashweb is iCashwebToken {
    using iMath for uint256;
    
    string public constant name = &quot;iCashweb&quot;;
    string public constant symbol = &quot;ICWeb&quot;;
    uint256 public constant decimal = 18;
    uint256 _totalSupply;
    uint256 _rate;
    uint256 _totalMintSupply;
    uint256 _maxMintable;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _approvals;
    
    constructor (uint256 _price, uint256 _val) public {
        _mintingStarted = true;
        _minted = false;
        _rate = _price;
        _totalSupply = _val.mul(2);
        _maxMintable = _val;
        _balances[iOwner] = _val;
        emit Transfer(0x0, iOwner, _val);
    }

    function getMinted() public view returns(bool) {
        return _minted;
    }

    function isOwner(address _addr) public view returns(bool) {
        return _addr == iOwner;
    }

    function getMintingStatus() public view returns(bool) {
        return _mintingStarted;
    }

    function getRate() public view returns(uint256) {
        return _rate;
    }

    function totalMintSupply() public view returns(uint256) {
        return _totalMintSupply;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _addr) public view returns (uint256) {
        return _balances[_addr];
    }
    
    function allowance(address _from, address _to) public view returns (uint256) {
        return _approvals[_from][_to];
    }
    
    function transfer(address _to, uint _val) public returns (bool) {
        assert(_balances[address(0)] >= _val && address(0) != _to);
        _balances[address(0)] = _balances[address(0)].sub(_val);
        _balances[_to] = _balances[_to].add(_val);
        emit Transfer(address(0), _to, _val);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _val) public returns (bool) {
        assert(_balances[_from] >= _val);
        assert(_approvals[_from][address(0)] >= _val);
        _approvals[_from][address(0)] = _approvals[_from][address(0)].sub(_val);
        _balances[_from] = _balances[_from].sub(_val);
        _balances[_to] = _balances[_to].add(_val);
        emit Transfer(_from, _to, _val);
        return true;
    }
    
    function approve(address _to, uint256 _val) public returns (bool) {
        _approvals[address(0)][_to] = _val;
        emit Approval(address(0), _to, _val);
        return true;
    }
    
    function () public mintingStarted payable {
        assert(msg.value > 0);
        uint tokens = msg.value.mul(_rate);
        uint totalToken = _totalMintSupply.add(tokens);
        assert(_maxMintable >= totalToken);
        _balances[address(0)] = _balances[address(0)].add(tokens);
        _totalMintSupply = _totalMintSupply.add(tokens);
        iOwner.transfer(msg.value);
        emit Transfer(0x0, address(0), tokens);
    }
    
    function moveMintTokens(address _from, address _to, uint256 _value) public iOnlyOwner returns(bool) {
        require(_to != _from);
        require(_balances[_from] >= _value);
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transferMintTokens(address _to, uint256 _value) public iOnlyOwner returns(bool) {
        uint totalToken = _totalMintSupply.add(_value);
        require(_maxMintable >= totalToken);
        _balances[_to] = _balances[_to].add(_value);
        _totalMintSupply = _totalMintSupply.add(_value);
        emit Transfer(0x0, _to, _value);
        return true;
    }

    function releaseMintTokens() public notMinted returns(bool) {
        require(address(0) == iOwner);
        uint256 releaseAmount = _maxMintable.sub(_totalMintSupply);
        uint256 totalReleased = _totalMintSupply.add(releaseAmount);
        require(_maxMintable >= totalReleased);
        _totalMintSupply = _totalMintSupply.add(releaseAmount);
        _balances[address(0)] = _balances[address(0)].add(releaseAmount);
        _minted = true;
        emit Transfer(0x0, address(0), releaseAmount);
        emit Release(address(0), releaseAmount);
        return true;
    }

    function changeRate(uint256 _value) public returns (bool) {
        require(address(0) == iOwner && _value > 0);
        _rate = _value;
        return true;
    }

    function transferOwnership(address _to) public {
        require(address(0) == iOwner && _to != address(0));  
        address oldOwner = iOwner;
        uint256 balAmount = _balances[oldOwner];
        _balances[_to] = _balances[_to].add(balAmount);
        _balances[oldOwner] = 0;
        iOwner = _to;
        emit Transfer(oldOwner, _to, balAmount);
        emit OwnerTransferred(oldOwner, _to);
    }
    
    event Release(address _addr, uint256 _val);
    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _from, address _to, uint256 _value);
}