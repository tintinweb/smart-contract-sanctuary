/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

//// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;

contract LUX8 {

    string private _name = "Lux8Token";
    string private _symbol = "LUX8";
    uint8 private _decimals = 4;
    uint256 private _totalSupply;
    uint256 public price = 0.00001 ether;
    address payable owner;
    uint256 immutable public MAX_SUPPLY = 21000 *10**_decimals;

    mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Buy(address indexed _buyer, uint256 _value);

    constructor() {
        //uint256 supply = 100000000 * 10** _decimals;
        //_balances[msg.sender] = supply;
        //_totalSupply = supply;
        owner = payable(msg.sender);
        //emit Transfer(address(0), msg.sender, supply);
    }

    function buy() public payable {
        uint256 value = msg.value;
        uint256 amount = (value / price) * 10**_decimals;
        uint256 reminder = _totalSupply % 1000 * 10 ** _decimals;
        uint256 purchasedAmount = 0;
        uint256 totalPurchased = 0;

        while (amount >= reminder) {
            purchasedAmount = (price * reminder) * 10 ** _decimals;
            require(_totalSupply + purchasedAmount <= MAX_SUPPLY, "You can't buy tokens, emission exceeded.");
            _balances[msg.sender] += purchasedAmount;
            value = value - (price*reminder);
            _totalSupply += purchasedAmount;
            totalPurchased += purchasedAmount;
            price = price * 110 /100;
            amount = (value/price) *10**_decimals;
            reminder = 1000 * 10 ** _decimals;
        }

        require(_totalSupply + amount <= MAX_SUPPLY, "You can't buy tokens, emission exceeded.");
        _balances[msg.sender] += amount;
        _totalSupply += amount;
        totalPurchased += amount;
        emit Buy(msg.sender, totalPurchased);
        emit Transfer(address(0), msg.sender, totalPurchased);
    }

    function withdraw() public {
        owner.transfer(address(this).balance);
    }

    function maxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function destroy() public{
        require(msg.sender == owner, 'Only owner can call this function.');
        selfdestruct(owner);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol; 
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return _balances[_owner];
        }

    function transfer(address _to, uint256 _value) public returns(bool) {
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return _allowances[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_allowances[_from][msg.sender] >= _value, "XYI VAM");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}