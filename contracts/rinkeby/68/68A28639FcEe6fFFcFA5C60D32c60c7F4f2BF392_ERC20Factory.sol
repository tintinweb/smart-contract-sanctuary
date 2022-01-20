// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./MutahhirERC20.sol";

contract ERC20Factory {
    uint8 salt = 2;
    
    function getSaltValue() external view returns (uint8) {
        return salt;
    } 
    
    function changeSaltValue(uint8 newSalt) external {
        salt = newSalt;
    }
    
    event Deployed(address deployedContract, uint salt);

    // 1. Get bytecode of contract to be deployed
    // NOTE: _name, _symbol, _decimals and _totalSupply are arguments of the MutahhirERC20's constructor
    function getBytecode(string memory _name, string memory _symbol) public pure returns (bytes memory) {
        bytes memory bytecode = type(MutahhirERC20).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_name, _symbol));
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(bytes memory bytecode)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    // 3. Deploy the contract
    // NOTE:
    // Check the event log Deployed which contains the address of the deployed MutahhirERC20.
    // The address in the log should equal the address computed from above.
    //make sure the salt is same as getAddress function
    function deploy(string memory _name, string memory _symbol) external payable {
        bytes memory encodedByteCode = getBytecode(_name, _symbol);
        address contractAddress = getAddress(encodedByteCode);
        address addr;

        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(encodedByteCode, 0x20),
                mload(encodedByteCode), // Load the size of code contained in the first 32 bytes
                sload(salt.slot) // Salt from state variable
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MutahhirERC20  is IERC20{
      string public symbol;
    string public  name;
    uint8 public decimals = 18;
    uint public override totalSupply = 10000000000;
    uint public _totalTokens;

 
    mapping(address => uint) balance;

    // one coin owner allows another user to spend coins on its behalf
    // owner => recipient => remaining
    mapping(address => mapping(address => uint)) allowed;

    // event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferFrom(address indexed from, address indexed to, uint256 value);

    // event Approval(address indexed from, address indexed to, uint256 value);

    constructor (string memory  _name, string memory _symbol) {
        symbol = _symbol;
        name=_name;
        balance[msg.sender] = totalSupply; 
    }

    function balanceOf(address _owner) public view override returns (uint256){
        return balance[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(_to != address(0), "Mutahhir:: invalid address");
        require(balance[msg.sender] >= _value, "Mutahhir:: insufficient balance");
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        
        require(_to != address(0), "Mutahhir:: invalid address");
        require(balance[_from] >= _value, "Mutahhir:: insufficient balance");
        require(allowance(_from, _to) >= _value, "Mutahhir:: not allowaed");
        balance[_from] -= _value;
        balance[_to] += _value;
        emit TransferFrom(_from, _to, _value);
        return true;
    }

    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        require(_spender != address(0), "Mutahhir:: invalid address");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return allowed[_owner][_spender];

    }

    function _mint(address _account, uint256 _amount) public 
    {
        require(_account!=address(0));
        require(_totalTokens + _amount <= totalSupply,"Mutahhir: mint limt reached");
        _totalTokens += _amount;
        balance[_account] += _amount;
        // emit Transfer(address(0), _account, _amount);
    } 



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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