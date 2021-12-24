pragma solidity ^0.5.10;

import "./Management.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Invalid value");
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "Invalid value");
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "Invalid value");
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "Invalid value");
        c = a / b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Symma is IERC20 {
    using SafeMath for uint256;

    Management management;
    address owner;

    //SYMMA EVENTS
    event Transfer( address indexed _from, address indexed _to, uint256 _value );
    event Approval( address indexed _tokenOwner, address indexed _spender, uint256 _tokens);

    //SYMMA PROPERTIES
    struct Quotation {
        uint256 numerator;
        uint256 denominator;
    }

    Quotation public currencyRate;
    Quotation public fee;

    //ERC20 PROPERTIES
    string public name = "SYMMA";
    string public symbol = "SYM";
    string public standard = "SYM Token v4.0";
    uint8 public decimals = 2;
    uint256 private supply;

    mapping(address => uint256) symmaToken;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(address _addressManagement) public payable {
        owner = msg.sender;
        management = Management(_addressManagement);
        currencyRate.numerator = 1;
        currencyRate.denominator = 100;
        fee.numerator = 5;
        fee.denominator = 1000;
    }

    //MODIFIERS MANAGEMENTS
    modifier onlyOwner {
        require(owner == msg.sender, "Sender must be a child");
        _;
    }

    modifier onlyOperator {
        require(management.getGenealogy(address(this), msg.sender) == 2, "Sender must be a child");
        _;
    }

    modifier onlyDirector {
        require(management.seeDirector(msg.sender), "Sender must be director");
        _;
    }

    modifier onlyPermitted{
        require(management.seeDirector(msg.sender) || management.getGenealogy(msg.sender, address(this)) > 0,
            "Sender must be director or a child");
        _;
    }

    //REQUESTS PROPERTIES
    struct DirectorsApprove{
        address director;
        bool voted;
    }

    mapping(uint256 => mapping(uint256 => uint8)) countApproveQuotations;
    mapping(uint256 => mapping(uint256 => DirectorsApprove[])) quotationApprove;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) countQuotationDirectorsApprove;

    //MANAGEMENT FUNCTIONS
    function setPermission(address _address, uint8 _permission) public onlyDirector returns (bool success){
        management.setPermission(_address, _permission);
        return true;
    }

    function getPermission(address _address) public view onlyDirector returns (uint256 permission){
        return management.getPermission(_address);
    }

    //OPERATOR FUNCTION
    function deposit(address  _address, address _addressOperator) public payable onlyOperator returns (bool success){
        uint256 _taxValue = msg.value * fee.numerator / fee.denominator;
        uint256 _userValue = msg.value - _taxValue;
        symmaToken[_address] = symmaToken[_address].add(_userValue);
        symmaToken[_addressOperator] = symmaToken[_addressOperator].add(_taxValue);
        supply = supply.add(msg.value);

        return true;
    }

    function batchDeposit(address[] memory  _address, address _addressOperator, uint256[] memory _value)
        public payable onlyOperator returns (bool success){
        uint256 _taxValue;
        uint256 _userValue;

        for(uint8 i = 0; i < _address.length; i++) {
            _taxValue = _value[i] * fee.numerator / fee.denominator;
            _userValue = _value[i] - _taxValue;
            symmaToken[_address[i]] = symmaToken[_address[i]].add(_userValue);
            symmaToken[_addressOperator] = symmaToken[_addressOperator].add(_taxValue);
        }

        supply = supply.add(msg.value);

        return true;
    }

    function withdraw(address payable _address, address _addressOperator, uint256 _symmaValue, uint256 _estimateGas,
        bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) public  onlyOperator returns (bool success) {
        require(_symmaValue >= 100, "Must be more than one symma");
        require(verifyAssignature(_address, _hash, _v, _r, _s), "Invalid signature");
        require(symmaToken[_address] >= toEther(_symmaValue), "Sender insufficient funds");

        uint256 _etherValue = toEther(_symmaValue);

        uint256 _taxValue = _etherValue * fee.numerator / fee.denominator + _estimateGas;
        uint256 _userValue = _etherValue - _taxValue;

        symmaToken[_address] = symmaToken[_address].sub(_etherValue);
        supply = supply.sub(_etherValue);

        symmaToken[_addressOperator] = symmaToken[_addressOperator].add(_taxValue);
        _address.transfer(_userValue);

        emit Transfer(address(this), _address, _userValue);

        return true;
    }

    function transferFromOperator(address _from, address _to, address _addressOperator, uint256 _symmaValue)
        public onlyOperator returns(bool success){
        require(symmaToken[_from] >= toEther(_symmaValue) && _symmaValue > 0, "Invalid values");

        uint256 _etherValue = toEther(_symmaValue);

        uint256 _taxValue = _etherValue * fee.numerator / fee.denominator;
        uint256 _userValue = _etherValue + _taxValue;

        symmaToken[_from] = symmaToken[_from].sub(_userValue);

        symmaToken[_to] = symmaToken[_to].add(_etherValue);
        symmaToken[_addressOperator] = symmaToken[_addressOperator].add(_taxValue);

        emit Transfer(_from, _to, _etherValue);

        return true;
    }

    //ERC20
    function transfer(address _to, uint256 _symmaValue) public returns(bool success){
        require(symmaToken[msg.sender] >= toEther(_symmaValue) && _symmaValue > 0, "Invalid values");

        uint256 ethValue = toEther(_symmaValue);

        symmaToken[msg.sender] = symmaToken[msg.sender].sub(ethValue);
        symmaToken[_to] = symmaToken[_to].add(ethValue);

        emit Transfer(msg.sender, _to, ethValue);

        return true;
    }

    function balanceOf(address _address) public view returns(uint256 balance){
        return toSymma(symmaToken[_address]);
    }

    function totalSupply() public view returns(uint256 symmaValue){
        return toSymma(supply);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _symmaValue) public returns (bool success){
        require(symmaToken[msg.sender] >= _symmaValue && _spender != address(0x0), "Invalid values");

        allowed[msg.sender][_spender] = _symmaValue;

        emit Approval(msg.sender, _spender, _symmaValue);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _symmaValue) public returns (bool success){
        require(symmaToken[_from] >= _symmaValue && allowed[_from][msg.sender] >= _symmaValue &&
            _symmaValue > 0 && _to != address(0x0), "Invalid values");

        uint256 ethValue = toEther(_symmaValue);

        symmaToken[_from] = symmaToken[_from].sub(ethValue);
        symmaToken[_to] = symmaToken[_to].add(ethValue);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_symmaValue);

        emit Transfer(msg.sender, _to, _symmaValue);

        return true;
    }

    //AUXILIARY FUNCTIONS
    function toSymma(uint256 _value) private view returns(uint256 symma){
        uint256 result = (_value * currencyRate.denominator / currencyRate.numerator) / 10**15;
        require(result >= 0, "Result can't be zero");
        return result;
    }

    function toEther(uint256 _symma) private view returns(uint256 value){
        uint256 result = (_symma * currencyRate.numerator / currencyRate.denominator) * 10**15;
        require(result >= 0, "Result can't be zero");
        return result;
    }

    function verifyAssignature(address _address, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) private pure returns(bool success){
        require(_address != address(0x0) && _hash.length > 0 && _r.length > 0 && _s.length > 0, "Invalid values");
        return (ecrecover(_hash, _v, _r, _s) == _address);
    }

    //REQUEST CURRENCY RATE AND TAX VALUES
    function resetFee(uint256 _numerator, uint256 _denominator) private returns(bool success){
        fee.numerator = _numerator;
        fee.denominator = _denominator;
        return true;
    }

    function resetCurrencyRate(uint256 _numerator, uint256 _denominator) private returns(bool success){
        currencyRate.numerator = _numerator;
        currencyRate.denominator = _denominator;
        return true;
    }

    function currencyRateRequest(uint256 _numerator, uint256 _denominator) public onlyDirector returns(bool success){
        require(!countQuotationDirectorsApprove[_numerator][_denominator][msg.sender] && _numerator > 0 && _denominator > 0, "Invalid values");

        DirectorsApprove memory newRequest = DirectorsApprove({
            director: msg.sender,
            voted: true
        });

        quotationApprove[_numerator][_denominator].push(newRequest);
        countQuotationDirectorsApprove[_numerator][_denominator][msg.sender] = true;
        countApproveQuotations[_numerator][_denominator]++;

        if(countApproveQuotations[_numerator][_denominator] > management.getTotalDirectors()/2) {
            resetCurrencyRate(_numerator, _denominator);
            countApproveQuotations[_numerator][_denominator] = 0;
            for(uint8 i = 0; i < quotationApprove[_numerator][_denominator].length; i++){
                quotationApprove[_numerator][_denominator][i].voted = false;
                countQuotationDirectorsApprove[_numerator][_denominator][quotationApprove[_numerator][_denominator][i].director] = false;
            }
        }

        return true;
    }

    function feeRequest(uint256 _numerator, uint256 _denominator) public onlyDirector returns(bool success){
        require(!countQuotationDirectorsApprove[_numerator][_denominator][msg.sender] && _numerator > 0 && _denominator > 0, "Invalid values");

        DirectorsApprove memory newRequest = DirectorsApprove({
            director: msg.sender,
            voted: true
        });

        quotationApprove[_numerator][_denominator].push(newRequest);
        countQuotationDirectorsApprove[_numerator][_denominator][msg.sender] = true;
        countApproveQuotations[_numerator][_denominator]++;

        if(countApproveQuotations[_numerator][_denominator] > management.getTotalDirectors()/2){
            resetFee(_numerator, _denominator);
            countApproveQuotations[_numerator][_denominator] = 0;
            for(uint8 i = 0; i < quotationApprove[_numerator][_denominator].length; i++){
                quotationApprove[_numerator][_denominator][i].voted = false;
                countQuotationDirectorsApprove[_numerator][_denominator][quotationApprove[_numerator][_denominator][i].director] = false;
            }
        }

        return true;
    }

    function verifyContractBalance() public view returns(uint256 balance) {
        return address(this).balance;
    }

    function changeManagement(address _address) public onlyOwner returns(bool success){
        management = Management(_address);
        return true;
    }
}