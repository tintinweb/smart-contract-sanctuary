/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Metadata optional
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/**
 * @title MBDA_token is a template for MB Digital Asset token
 * */
contract MBDA_token is IERC20{

    //
    // events
    //

    // mint/burn events
    event Mint(address indexed to  , uint256 amount, uint256 newTotalSupply);
    event Burn(address indexed from, uint256 amount, uint256 newTotalSupply);

    // admin events
    event BlockLockSet(uint256 value);
    event NewAdmin(address newAdmin);
    event NewCold(address newCold);

    modifier onlyAdmin {
        require(msg.sender == admin, 'Only admin can perform this operation');
        _;
    }

    modifier adminOrCold {
        require(msg.sender == admin || msg.sender == cold, 'Only admin or cold can perform this operation');
        _;
    }

    modifier onlyCold {
        require(msg.sender == cold, 'Only cold can perform this operation');
        _;
    }

    modifier blockLock(address _sender) {
        if(msg.sender != admin)
            require(lockedUntilBlock <= block.number, 'Contract is locked except for the admin');
        _;
    }

    uint256 public totalSupply;
    string  public name;
    uint8   public decimals;
    string  public symbol;
    address public admin;
    address public cold;
    uint256 public lockedUntilBlock;
    string  public financialDetails;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /**
     * @dev Constructor
     * @param _admin - Fund admin
     * @param _cold - Fund admin
     * @param _name - Detailed ERC20 token name
     * @param _symbol - Detailed ERC20 token symbol
     * @param _decimals - Detailed ERC20 decimal units
     * @param _totalSupply - Total Supply owned by the contract itself, only Manager can move
     * @param _lockedUntilBlock - Block lock
     * @param _financialDetails - json, at least link and jash of a document
     */
    constructor(
        address _admin,
        address _cold,
        string memory _name,
        string memory _symbol,
        uint8   _decimals,
        uint256 _totalSupply,
        uint256 _lockedUntilBlock,
        string memory _financialDetails
    ) {
        require(_decimals <= 18, 'Decimal units should be 18 or lower');
        require(_admin != address(0), 'Invalid admin  null address');
        require(_cold  != address(0), 'Invalid cold null address');
        require(_admin != _cold, 'Admin and Cold cannot be the same address');

        // Metadata
        name = _name;
        decimals = _decimals;
        symbol = _symbol;

        // Addresses
        admin = _admin;
        cold  = _cold;
        
        // Balances
        totalSupply = _totalSupply;
        balanceOf[_admin] = _totalSupply;
        
        // Last details
        lockedUntilBlock = _lockedUntilBlock;
        financialDetails = _financialDetails;

        emit Transfer(address(0), _admin, _totalSupply);
        emit Mint(_admin, _totalSupply, _totalSupply);
        emit NewAdmin(_admin);
        emit NewCold(_cold);
        emit BlockLockSet(_lockedUntilBlock);
    }

    /**
     * @dev ERC20 Transfer
     * @param _to - destination address
     * @param _value - value to transfer
     * @return True if success
     */
    function transfer(address _to, uint256 _value)
        external
        blockLock(msg.sender)
        returns (bool)
    {
        require(_to != address(0), 'Invalid receiver null address');
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to]        += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev ERC20 Approve
     * @param _spender - destination address
     * @param _value - value to be approved
     * @return True if success
     */
    function approve(address _spender, uint256 _value)
        external
        blockLock(msg.sender)
        returns (bool)
    {
        require(_spender != address(0), 'Invalid spender null address');

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev ERC20 TransferFrom
     * @param _from - source address
     * @param _to - destination address
     * @param _value - value
     * @return True if success
     */
    function transferFrom(address _from, address _to, uint256 _value)
        external
        blockLock(_from)
        returns (bool)
    {
        require(_to != address(0), 'Invalid receiver null address');
        
        uint256 _allowance = allowance[_from][msg.sender] - _value;
        allowance[_from][msg.sender] = _allowance;
        emit Approval(_from, msg.sender, _allowance);

        balanceOf[_from] -= _value;
        balanceOf[_to  ] += _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Burn tokens
     * @param _account - address
     * @param _value - value
     * @return True if success
     */
    function burn(address payable _account, uint256 _value)
        external
        onlyAdmin
        returns (bool)
    {
        totalSupply -= _value;
        balanceOf[_account] -= _value;
        emit Transfer(_account, address(0), _value);
        emit Burn(_account, _value, totalSupply);
        return true;
    }

    /**
     * @dev Set block lock. Until that block (exclusive) transfers are disallowed
     * @param _lockedUntilBlock - Block Number
     * @return True if success
     */
    function setBlockLock(uint256 _lockedUntilBlock)
        external
        onlyAdmin
        returns (bool)
    {
        lockedUntilBlock = _lockedUntilBlock;
        emit BlockLockSet(_lockedUntilBlock);
        return true;
    }

    /**
     * @dev Replace current admin with new one
     * @param _newAdmin New token admin
     * @return True if success
     */
    function replaceAdmin(address _newAdmin)
        external
        adminOrCold
        returns (bool)
    {
        require(_newAdmin != address(0), 'Invalid admin null address');
        require(_newAdmin != cold, 'Admin and Cold cannot be the same address');
        admin = _newAdmin;
        emit NewAdmin(_newAdmin);
        return true;
    }

    function replaceCold(address _newCold)
        external
        onlyCold
        returns (bool)
    {
        require(_newCold != address(0), 'Invalid cold null address');
        require(_newCold != admin, 'Admin and Cold cannot be the same address');
        cold = _newCold;
        emit NewCold(_newCold);
        return true;
    }
}