/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity ^0.8.0;


interface IERC20{
    function getTotalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function transferFrom(address _owner, address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _sender) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function approveFrom(address _owner, address _sender, uint256 amount) external returns (bool);
    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
}

abstract contract Context{
    function _msgSender() internal view returns(address){
        return msg.sender;
    }
    
    function _msgData() internal view returns(bytes calldata){
        return msg.data;
    }
}

contract Order {
    
    struct Node {
        address owner;
        address[] members;
        uint256 budget;
        mapping(address => uint256) child;
        bool status;
    }
    
    struct NodeRes {
        uint256 tmpId;
        address tmpAddress;
        uint256 tmpAmount;
    }
    
    mapping(uint256 => Node) orders;
    
    function test(uint[] calldata _ids) public view returns (uint[] memory){
        return _ids;
    }
    
    function addOwnerInOrder(uint256 _idOrder, address _buyer, uint256 _amount) public returns (bool){
        address owner = orders[_idOrder].owner;
        require(orders[_idOrder].child[_buyer] == 0, "");
        require(orders[_idOrder].child[owner] > _amount, "Total token khong du");
        orders[_idOrder].members.push(_buyer);
        orders[_idOrder].child[_buyer] = _amount;
        return true;
    }
    
    function createOrder(uint256 _idOrder, address _owner, uint256 _budget) public returns (bool){
        require(orders[_idOrder].budget == 0, "Order is exists");
        orders[_idOrder].members.push(_owner);
        orders[_idOrder].owner = _owner;
        orders[_idOrder].budget = _budget;
        orders[_idOrder].child[_owner] = _budget;
        return true;
    }
    
    function detailOrder(uint256 _idOrder) public view returns (NodeRes[] memory){
        uint256 length = orders[_idOrder].members.length;
        
        NodeRes[] memory datas = new NodeRes[](length);
        for(uint i = 0; i < length; i++){
            address key = orders[_idOrder].members[i];
            
            datas[i].tmpId = _idOrder;
            datas[i].tmpAmount = orders[_idOrder].child[key];
            datas[i].tmpAddress = key;
        }
        return datas;
    }
    
    function getListOwnerForProduct(uint256 _id) public view returns (address[] memory){
        return orders[_id].members;
    }
}

contract ERC20 is IERC20, Context{
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private totalSupply;
    string private name;
    string private symbol;
    uint8 private decimals;
    address public adminAddress;
    
    constructor(){
        name = "VIETKO";
        symbol = "VKC";
        totalSupply = 10000000;
        decimals = 0;
        balances[msg.sender] = totalSupply;
        adminAddress = msg.sender;
    }
    
    function getTotalSupply() public view override returns (uint256){
        return balances[msg.sender];
    }
    
    function balanceOf(address _owner) public view override returns (uint256){
        return balances[_owner];
    }
    
    function transfer(address _recipient, uint256 _amount) public override returns (bool){
        if (balances[adminAddress] >= _amount && _amount > 0) {
            balances[adminAddress] -= _amount;
            balances[_recipient] += _amount;
            emit Transfer(adminAddress, _recipient, _amount);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool){
        _transfer(_sender, _recipient, _amount);
        uint256 currentAllowance = allowances[_sender][_msgSender()];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_sender, _msgSender(), currentAllowance - _amount);
        }
        return true;
    }
    
    function allowance(address _owner, address _sender) public override returns (uint256){
        return allowances[_owner][_sender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function approveFrom(address _owner, address _sender, uint256 amount) public override returns (bool){
        _approve(_owner, _sender, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer (from) from the zero address");
        require(to != address(0), "ERC20: transfer (to) from the zero address");
        
        require(balances[from] >= value, "ERC20: transfer amount exceeds balance");
        unchecked {
            balances[from] -= value;
        }
        balances[to] += value;
        emit Transfer(from, to, value);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract MapMain is ERC20, Order{
    struct BalanceUser{
        address mAddress;
        uint256 mAmount;
    }
    
    function buyOrder(uint256 _idOrder, address _sender, uint256 _amount) public returns(bool){
        uint256 balanceUser = balanceOf(_sender);
        require(balanceUser > _amount, "Sorry !!! Your balance is not enough to trade");
        require(_idOrder != 0, "Id order is not define");
        require(_sender != address(0), "Address is not define");
        addOwnerInOrder(_idOrder, _sender, _amount);
        uint256 tmpAllowances = allowance(_sender, adminAddress) + _amount;
        approveFrom(adminAddress, _sender, tmpAllowances);
        transferFrom(_sender, adminAddress, _amount);
        return true;
    }
    
    //Registry for Admin
    function registryTokenForUser(address[] calldata _owners) public returns(bool){
        for(uint i = 0; i < _owners.length; i++){
            transfer(_owners[i], 1000);
        }
        return true;
    }
    
    function getBalancesByUsers(address[] memory _owners) public returns (BalanceUser[] memory){
        uint length = _owners.length;
        BalanceUser[] memory result = new BalanceUser[](length);
        for(uint i = 0; i < _owners.length; i++){
            result[i].mAddress = _owners[i];
            result[i].mAmount = balanceOf(_owners[i]);
        }
        return result;
    }
    
    function buyToken(address admin, address owner, uint256 amount) public returns (bool){
        approveFrom(admin, owner, amount);
        transferFrom(admin, owner, amount);
        return true;
    }
}