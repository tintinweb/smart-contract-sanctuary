/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ERC20Token {
    function totalSupply() external view returns(uint256);
    
    function budgetTotal() external view returns (uint256);
    
    function amountTokenAvaiable() external view returns (uint256);
    
    function getWalletAddress() external view returns (address);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    
    function getListBuyer() external view returns (address[] memory);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface IERC20{
    function totalSupply() external view returns(uint256);
    
    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function mint(uint256 _value) external returns (uint256);
    
    event DeployContract(address indexed admin, string name, uint256 totalSupply);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event SafeTransfer(address indexed token, address indexed seller, address indexed buyer, uint256 value);
}

contract Owner {
    address ownerAddress;

    constructor(){
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
        _;
    }
}

contract Parent is IERC20, Owner {
    
    struct NodeRes{
        address tmpAddress;
        uint256 tmpBalance;
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public _totalSupply;
    
    constructor() {
        decimals = 18;
        _totalSupply = 1000000000 * 10**decimals;
        balances[msg.sender] = _totalSupply;    
        name = "VKT";
        symbol = "VKT";
        emit DeployContract(msg.sender, name, _totalSupply);
    }
    
    function totalSupply() public override view returns(uint256){
        return _totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public onlyOwner override returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function balancesOf(address[] memory _owner) public view returns(NodeRes[] memory){
        uint256 length = _owner.length;
        NodeRes[] memory datas = new NodeRes[](length);
        for(uint256 i = 0; i < length; i++){
            datas[i].tmpAddress = _owner[i];
            datas[i].tmpBalance = balances[_owner[i]];
        }
        return datas;
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function mint(uint256 _value)public onlyOwner override returns (uint256){
        _totalSupply += _value;
        balances[msg.sender] += _value;
        return _totalSupply;
    }
    
    function getDetailToken(address token) public view returns (NodeRes[] memory){
        address[] memory buyers = ERC20Token(token).getListBuyer();
        uint256 length = buyers.length;
        NodeRes[] memory datas = new NodeRes[](length);
        for(uint256 i = 0; i < length; i++){
            datas[i].tmpAddress = buyers[i];
            datas[i].tmpBalance = ERC20Token(token).balanceOf(buyers[i]);
        }
        return datas;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function safeBalanceOf(address token, address owner) public view returns (uint256){
        return ERC20Token(token).balanceOf(owner);
    }
    
    function safeSender(address token) public view returns (address){
        bytes4 FUNC_SELECTOR = bytes4(keccak256("getMsgSender()"));
        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR);
        (bool status, bytes memory res) = address(token).staticcall(data);
        if(status){
            return abi.decode(res, (address));
        }
        return address(0);
    }
    
    function safeTransfer(address token, address buyer, uint256 amount) public returns (bool){
        require(token != address(0), "Parent: Contract not found");
        require(balances[buyer] > amount, "Please buy coin");
        uint256 budget = ERC20Token(token).budgetTotal();
        uint256 tmpValue = amount * 1000 / budget;
        uint256 balancesOwner = ERC20Token(token).amountTokenAvaiable();
        require(balancesOwner >= tmpValue, "So luong token con lai khong du cung cap cho ban");
        address walletAddress = ERC20Token(token).getWalletAddress();
        _transfer(buyer, walletAddress, amount);
        emit SafeTransfer(token, walletAddress, buyer, amount);
        return ERC20Token(token).transfer(buyer, tmpValue);
    }
}