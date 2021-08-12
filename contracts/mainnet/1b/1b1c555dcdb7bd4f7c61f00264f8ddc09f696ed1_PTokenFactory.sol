/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// File: iface/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: iface/IParassetGovernance.sol

pragma solidity ^0.8.4;

/// @dev This interface defines the governance methods
interface IParassetGovernance {
    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}
// File: ParassetBase.sol

pragma solidity ^0.8.4;

contract ParassetBase {

    // Lock flag
    uint256 _locked;

	/// @dev To support open-zeppelin/upgrades
    /// @param governance IParassetGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Log:ParassetBase!initialize");
        _governance = governance;
        _locked = 0;
    }

    /// @dev IParassetGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IParassetGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IParassetGovernance(governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _governance = newGovernance;
    }

    /// @dev Uniform accuracy
    /// @param inputToken Initial token
    /// @param inputTokenAmount Amount of token
    /// @param outputToken Converted token
    /// @return stability Amount of outputToken
    function getDecimalConversion(
        address inputToken, 
        uint256 inputTokenAmount, 
        address outputToken
    ) public view returns(uint256) {
    	uint256 inputTokenDec = 18;
    	uint256 outputTokenDec = 18;
    	if (inputToken != address(0x0)) {
    		inputTokenDec = IERC20(inputToken).decimals();
    	}
    	if (outputToken != address(0x0)) {
    		outputTokenDec = IERC20(outputToken).decimals();
    	}
    	return inputTokenAmount * (10**outputTokenDec) / (10**inputTokenDec);
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IParassetGovernance(_governance).checkGovernance(msg.sender, 0), "Log:ParassetBase:!gov");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 0, "Log:ParassetBase:!_locked");
        _locked = 1;
        _;
        _locked = 0;
    }
}
// File: iface/IPTokenFactory.sol

pragma solidity ^0.8.4;

interface IPTokenFactory {
    /// @dev View governance address
    /// @return governance address
    function getGovernance() external view returns(address);

    /// @dev View ptoken operation permissions
    /// @param contractAddress contract address
    /// @return bool
    function getPTokenOperator(address contractAddress) external view returns(bool);

    /// @dev View ptoken operation permissions
    /// @param pToken ptoken verification
    /// @return bool
    function getPTokenAuthenticity(address pToken) external view returns(bool);
    function getPTokenAddress(uint256 index) external view returns(address);
}
// File: iface/IParasset.sol

pragma solidity ^0.8.4;

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
// File: PToken.sol

pragma solidity ^0.8.4;

contract PToken is IParasset {

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

    function rename(string memory _name, 
                    string memory _symbol) public onlyGovernance {
        name = _name;                                                               
        symbol = _symbol;
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
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] - subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(from, to, value);
    }

    function destroy(uint256 amount, address account) override external onlyPool{
    	require(_balances[account] >= amount, "Log:PToken:!destroy");
    	_balances[account] = _balances[account] - amount;
    	_totalSupply = _totalSupply - amount;
    	emit Transfer(account, address(0x0), amount);
    }

    function issuance(uint256 amount, address account) override external onlyPool{
    	_balances[account] = _balances[account] + amount;
    	_totalSupply = _totalSupply + amount;
    	emit Transfer(address(0x0), account, amount);
    }
}
// File: PTokenFactory.sol

pragma solidity ^0.8.4;

contract PTokenFactory is ParassetBase, IPTokenFactory {

    // Governance contract
    address public _owner;
	// contract address => bool, PToken operation permissions
	mapping(address=>bool) _allowAddress;
	// PToken address => bool, PToken verification
	mapping(address=>bool) _pTokenMapping;
    // PToken address list
    address[] public _pTokenList;

    event createLog(address pTokenAddress);
    event pTokenOperator(address contractAddress, bool allow);

    //---------view---------

    /// @dev Concatenated string
    /// @param _a previous string
    /// @param _b after the string
    /// @return full string
    function strSplicing(string memory _a, string memory _b) public pure returns (string memory){
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
    /// @return governance address for PToken
    function getGovernance() external override view returns(address) {
        return _owner;
    }

    /// @dev View PToken operation permissions
    /// @param contractAddress contract address
    /// @return bool
    function getPTokenOperator(address contractAddress) external override view returns(bool) {
    	return _allowAddress[contractAddress];
    }

    /// @dev View PToken operation permissions
    /// @param pToken PToken verification
    /// @return bool
    function getPTokenAuthenticity(address pToken) external override view returns(bool) {
    	return _pTokenMapping[pToken];
    }

    /// @dev Query PToken address through index
    /// @param index array subscript
    /// @return pToken address
    function getPTokenAddress(uint256 index) external override view returns(address) {
        return _pTokenList[index];
    }

    //---------governance----------

    /// @dev Set owner address
    /// @param add new owner address
    function setOwner(address add) external onlyGovernance {
    	_owner = add;
    }

    /// @dev Set governance address
    /// @param contractAddress contract address
    /// @param allow bool
    function setPTokenOperator(address contractAddress, 
                               bool allow) external onlyGovernance {
        _allowAddress[contractAddress] = allow;
        emit pTokenOperator(contractAddress, allow);
    }

    /// @dev Add data to the PToken array
    /// @param add pToken address
    function addPTokenList(address add) external onlyGovernance {
        _pTokenList.push(add);
    }

    /// @dev set PToken mapping
    /// @param add pToken address
    /// @param isTrue pToken authenticity
    function setPTokenMapping(address add, bool isTrue) external onlyGovernance {
        _pTokenMapping[add] = isTrue;
    }

    /// @dev Create PToken
    /// @param name token name
    function createPToken(string memory name) external onlyGovernance {
    	PToken pToken = new PToken(strSplicing("PToken_", name), strSplicing("P", name));
    	_pTokenMapping[address(pToken)] = true;
        _pTokenList.push(address(pToken));
    	emit createLog(address(pToken));
    }
}