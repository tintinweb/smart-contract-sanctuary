/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// File: iface/IPTokenFactory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface IPTokenFactory {
    function getGovernance() external view returns(address);
    function getPTokenOperator(address contractAddress) external view returns(bool);
    function getPTokenAuthenticity(address pToken) external view returns(bool);
}
// File: iface/IParasset.sol

pragma solidity ^0.6.12;

interface IParasset {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function destroy(uint256 amount, address account) external;
    function issuance(uint256 amount, address account) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: lib/SafeMath.sol

pragma solidity ^0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-zero");
        z = x / y;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    }
}
// File: PToken.sol

pragma solidity ^0.6.12;




contract PToken is IParasset {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 public _totalSupply = 0;                                        
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 18;

    IPTokenFactory pTokenFactory;

    constructor (string memory _name, 
                 string memory _symbol) public {
    	name = _name;                                                               
    	symbol = _symbol;
    	pTokenFactory = IPTokenFactory(address(msg.sender));
    }

    //---------modifier---------

    modifier onlyGovernance() {
        require(address(msg.sender) == pTokenFactory.getGovernance(), "Log:PToken:!governance");
        _;
    }

    modifier onlyPool() {
    	require(pTokenFactory.getPTokenOperator(address(msg.sender)), "Log:PToken:!Pool");
    	_;
    }

    //---------view---------

    // Query factory contract address
    function getPTokenFactory() public view returns(address) {
        return address(pTokenFactory);
    }

    /// @notice The view of totalSupply
    /// @return The total supply of ntoken
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev The view of balances
    /// @param owner The address of an account
    /// @return The balance of the account
    function balanceOf(address owner) override public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowed[owner][spender];
    }

    //---------transaction---------

    function changeFactory(address factory) public onlyGovernance {
        pTokenFactory = IPTokenFactory(address(factory));
    }

    function transfer(address to, uint256 value) override public returns (bool) 
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) override public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override public returns (bool) 
    {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function destroy(uint256 amount, address account) override external onlyPool{
    	require(_balances[account] >= amount, "Log:PToken:!destroy");
    	_balances[account] = _balances[account].sub(amount);
    	_totalSupply = _totalSupply.sub(amount);
    	emit Transfer(account, address(0x0), amount);
    }

    function issuance(uint256 amount, address account) override external onlyPool{
    	_balances[account] = _balances[account].add(amount);
    	_totalSupply = _totalSupply.add(amount);
    	emit Transfer(address(0x0), account, amount);
    }
}
// File: PTokenFactory.sol

pragma solidity ^0.6.12;


contract PTokenFactory {

	// Governance address
	address public governance;
	// contract address => bool, ptoken operation permissions
	mapping(address=>bool) allowAddress;
	// ptoken address => bool, ptoken verification
	mapping(address=>bool) pTokenMapping;
    // ptoken list
	address[] pTokenList;

    event createLog(address pTokenAddress);
    event pTokenOperator(address contractAddress, bool allow);

	constructor () public {
        governance = msg.sender;
    }

    //---------modifier---------

    modifier onlyGovernance() {
        require(msg.sender == governance, "Log:PTokenFactory:!gov");
        _;
    }

    //---------view---------

    function strConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint s = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[s++] = _ba[i];
        } 
        for (uint i = 0; i < _bb.length; i++) {
            bret[s++] = _bb[i];
        } 
        return string(ret);
    }

    /// @dev View governance address
    /// @return governance address
    function getGovernance() public view returns(address) {
        return governance;
    }

    /// @dev View ptoken operation permissions
    /// @param contractAddress contract address
    /// @return bool
    function getPTokenOperator(address contractAddress) public view returns(bool) {
    	return allowAddress[contractAddress];
    }

    /// @dev View ptoken operation permissions
    /// @param pToken ptoken verification
    /// @return bool
    function getPTokenAuthenticity(address pToken) public view returns(bool) {
    	return pTokenMapping[pToken];
    }

    /// @dev View ptoken list length
    /// @return ptoken list length
    function getPTokenNum() public view returns(uint256) {
    	return pTokenList.length;
    }

    /// @dev View ptoken address
    /// @param index array subscript
    /// @return ptoken address
    function getPTokenAddress(uint256 index) public view returns(address) {
    	return pTokenList[index];
    }

    //---------governance----------

    /// @dev Set governance address
    /// @param add new governance address
    function setGovernance(address add) public onlyGovernance {
    	require(add != address(0x0), "Log:PTokenFactory:0x0");
    	governance = add;
    }

    /// @dev Set governance address
    /// @param contractAddress contract address
    /// @param allow bool
    function setPTokenOperator(address contractAddress, 
                               bool allow) public onlyGovernance {
        allowAddress[contractAddress] = allow;
        emit pTokenOperator(contractAddress, allow);
    }

    /// @dev Create PToken
    /// @param name token name
    function createPtoken(string memory name) public onlyGovernance {
    	PToken pToken = new PToken(strConcat("PToken_", name), strConcat("P", name));
    	pTokenMapping[address(pToken)] = true;
    	pTokenList.push(address(pToken));
    	emit createLog(address(pToken));
    }
}