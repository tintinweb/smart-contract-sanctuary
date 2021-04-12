/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity ^0.5.17;

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    //mapping(address => uint256) internal backBala;
    mapping(address => uint256) internal outBala;
    mapping(address => uint256) internal inBala;
    mapping(address => bool) internal isLockAddress;
    mapping(address => bool) internal isLockAddressMoreSix;
    mapping(address => uint256) internal startLockTime;
    mapping(address => uint256) internal releaseScale;

    uint256 internal totalSupply_ = 2100000000e18;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        //require(isLockAddress[msg.sender], "fsdfdsfdfdsfcccccccc");

        if(isLockAddress[msg.sender]){
            if(isLockAddressMoreSix[msg.sender]){
                require(now >= (startLockTime[msg.sender] + 180 days));
            }
            uint256 nRelease = getCurrentBalance(msg.sender);
            require(_value <= nRelease);
            outBala[msg.sender] = outBala[msg.sender].add(_value);
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        if(isLockAddress[_to]){
            inBala[_to] = inBala[_to].add(_value);
        }
        return true;
    }

    function getCurrentBalance(address _owner) public view returns (uint256) {
        uint256 curRelease = now.sub(startLockTime[_owner]).div(1 weeks).mul(releaseScale[_owner]);
        curRelease = curRelease.add(inBala[_owner]);
        return curRelease.sub(outBala[_owner]);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function setAddressInitValue(address _to, uint256 _value, uint256 _scal, bool _bsixmore) internal {
        balances[_to] = balances[_to].add(_value);
        //backBala[_to] = balances[_to];
        isLockAddress[_to] = true;
        isLockAddressMoreSix[_to] = _bsixmore;
        startLockTime[_to] = now;
        releaseScale[_to] = _scal;
        emit Transfer(address(0), _to, _value);
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        if(isLockAddress[_from]){
            if(isLockAddressMoreSix[_from]){
                require(now >= (startLockTime[_from] + 180 days));
            }

            uint256 nRelease = getCurrentBalance(_from);
            require(_value <= nRelease);
            outBala[_from] = outBala[_from].add(_value);
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        if(isLockAddress[_to]){
            inBala[_to] = inBala[_to].add(_value);
        }

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool){
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _amount) public hasMintPermission canMint returns (bool){
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool){
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool){
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success){
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success){
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract Claimable is Ownable {
    address public pendingOwner;

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

library SafeERC20 {
    function safeTransfer(ERC20Basic _token, address _to, uint256 _value) internal {
        require(_token.transfer(_to, _value));
    }

    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _value) internal {
        require(_token.transferFrom(_from, _to, _value));
    }

    function safeApprove(ERC20 _token, address _spender, uint256 _value) internal {
        require(_token.approve(_spender, _value));
    }
}

contract CanReclaimToken is Ownable {
    using SafeERC20 for ERC20Basic;

    function reclaimToken(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(owner, balance);
    }
}

//Aom token
contract AOM is StandardToken, MintableToken, PausableToken, CanReclaimToken, Claimable {

    string public name = "A lot of money";
    string public symbol = "AOM";
    uint8 public decimals = 18;

    constructor() public {
        setAddressInitValue(0x8D3d68C945309c37cF2229a76015CBEE616CCB53, 84042000e18, 491322e18, false);
        setAddressInitValue(0x396811e07211e4A241fC7F04023A3Bc1ad0F4Ba6, 62790000e18, 367080e18, false);
        setAddressInitValue(0x65FB99A819EF06949F6E910Fe70FE3cA28181F3b, 42021000e18, 245661e18, false);
        setAddressInitValue(0x6d5d7781D320f2550C70bE1f9F93e2590201f1f0, 21010500e18, 122830e18, false);
        setAddressInitValue(0x385A42aA7426ff5FE3649a2e843De6A5920F5825, 15818250e18, 92476e18, false);
        setAddressInitValue(0x43bF99849fDFc48CD0152Cf79DaBB05795606fF9, 15818250e18, 92476e18, false);

        setAddressInitValue(0xF6B8A480196363Bde2395851c7764D6B5B361963, 199500000e18, 404115e18, false);

        setAddressInitValue(0x8338f947274F5eD84D69D49Ab03FB949225B63f0, 125832000e18, 1035694e18, true);
        setAddressInitValue(0x4bc3D53f8DFd969293DF00B97b2beF3C70D46471, 84084000e18, 692076e18, true);
        setAddressInitValue(0x2f5DA0660dD59e3Afc1292201C2d1c4e403b5Cad, 84084000e18, 692076e18, true);

        balances[0x0fa82DDD35E88E6d154aa0a31fB30E2B1ca0D161] = 21000000e18;
        emit Transfer(address(0), 0x0fa82DDD35E88E6d154aa0a31fB30E2B1ca0D161, 21000000e18);

        balances[msg.sender] = balances[msg.sender].add(1344000000e18);
        emit Transfer(address(0), msg.sender, 1344000000e18);
    }

    function setReleaseScale(address _adr, uint256 _scaleValue) public onlyOwner returns (bool) {
        releaseScale[_adr] = _scaleValue;
        return true;
    }

    function finishMinting() public onlyOwner returns (bool) {
        return false;
    }

    function renounceOwnership() public onlyOwner {
        revert("renouncing ownership is blocked");
    }
}