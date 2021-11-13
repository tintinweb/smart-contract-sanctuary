/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// Part: Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: IERC20

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Part: SafeMath

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// Part: Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: IBSToken.sol

/**
    @title Bare-bones Token implementation
    @notice Based on the ERC-20 token standard as defined at
            https://eips.ethereum.org/EIPS/eip-20
 */
contract IBSToken is Ownable {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint256 public decimals;
    uint256 public totalSupply;

    //Custom data structures -------------------
    //we set the whiteList
    address[] public whiteList;
    //we make a mapping to iterate with less gas.
    mapping(address => bool) whiteListedMap;

    //we set the AdminList
    address[] public adminList;
    //we make a mapping to iterate with less gas.
    mapping(address => bool) adminListedMap;

    address public IBOwner;

    address public burner;

    address public zeroAddress = 0x0000000000000000000000000000000000000000;

    uint256 public initialPriceUSD = 100;

    // This is the mock USDT contract address that we created, on Polygon.
    // We can change the stablecoin easily by changing the address (and the name to avoid confusion.
    IERC20 usdt = IERC20(address(0xc72b01DF644dD7b6299fda3512660F968c166287));
    //------------------------------------------

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _totalSupply
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        // We can decide if the tokens are sent to the owner or they stay in the SC.
        // balances[msg.sender] = _totalSupply;
        balances[address(this)] = _totalSupply;
        // emit Transfer(address(0), msg.sender, _totalSupply);
        whiteList.push(msg.sender);
        whiteListedMap[msg.sender] = true;

        burner = 0x5B0276e89137b52F4B913A7C0182f27E1E1A9AF8;

        IBOwner = msg.sender;
    }

    /**
        @notice Getter to check the current balance of an address
        @param _owner Address to query the balance of
        @return Token balance
     */

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
        @notice Getter to check the amount of tokens that an owner allowed to a spender
        @param _owner The address which owns the funds
        @param _spender The address which will spend the funds
        @return The amount of tokens still available for the spender
     */

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
        @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
        @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
             and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
             race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
             https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        @param _spender The address which will spend the funds.
        @param _value The amount of tokens to be spent.
        @return Success boolean
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender == IBOwner);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        //we change the original function. You can only send them to a whitelisted address.
        require(whiteListedMap[_to] == true, "Not in Whitelist");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        //we change the original function. You can only send them to a whitelisted address.
        require(whiteListedMap[_to] == true, "Not in Whitelist");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function payRent(uint256 _USDT) public onlyAdmin {
        //IMPORTANT! how we know we are checking (balanceOf) the balance of the IB token? now we have two erc20 tokens around this contract. Maybe we need to separate them.
        // Send USDT to the Smart Contract(address(this)) from an Admin account.
        sendUSDT(address(this), _USDT);

        // We iterate over the whitelisted and we check the balanceOf the IB token.
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (balanceOf(whiteList[i]) > 0) {
                //here we have a problem. We have to transfer from the SC addres: address(this) but in USDT.
                sendUSDTFrom(
                    address(this),
                    whiteList[i],
                    (_USDT * balanceOf(whiteList[i])) / totalSupply
                );
            }
        }
    }

    function endOfLife(uint256 _USDT) public onlyBurner {
        //IMPORTANT! how we know we are checking (balanceOf) the balance of the IB token? now we have two erc20 tokens around this contract. Maybe we need to separate them.
        // Send USDT to the Smart Contract from an Admin account.
        sendUSDT(address(this), _USDT);

        // We iterate over the whitelisted and we check the balanceOf the IB token.
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (balanceOf(whiteList[i]) > 0) {
                sendUSDTFrom(
                    address(this),
                    whiteList[i],
                    (_USDT * balanceOf(whiteList[i])) / totalSupply
                );
                //we burn the IB tokens sending them to the zero address. We have allowance and approval since day 1 from the client to the burner.
                transferFrom(
                    whiteList[i],
                    zeroAddress,
                    balanceOf(whiteList[i])
                );
            }
        }
    }

    function abortProcess(uint256 _USDT) public onlyBurner {
        // We require to cover the value sold to the clients.
        require(
            _USDT >=
                ((totalSupply - balanceOf(address(this))) * initialPriceUSD)
        );

        // Send USDT to the Smart Contract from the burner account.
        sendUSDT(address(this), _USDT);

        // We iterate over the whitelisted and we check the balanceOf the IB token.
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (balanceOf(whiteList[i]) > 0) {
                sendUSDTFrom(
                    address(this),
                    whiteList[i],
                    (initialPriceUSD * balanceOf(whiteList[i]))
                );
                //we burn the IB tokens sending them to the zero address. We have allowance and approval since day 1 from the client to the burner.
                transferFrom(
                    whiteList[i],
                    zeroAddress,
                    balanceOf(whiteList[i])
                );
            }
        }
    }

    function addWhiteList(address _newWhiteListed) public onlyOwner onlyAdmin {
        whiteList.push(_newWhiteListed);
        whiteListedMap[_newWhiteListed] = true;
    }

    function removeWhiteList(address _removeWhiteListed)
        public
        onlyOwner
        onlyAdmin
    {
        whiteListedMap[_removeWhiteListed] = false;
    }

    function addAdminList(address _newAdminListed) public onlyOwner {
        adminList.push(_newAdminListed);
        adminListedMap[_newAdminListed] = true;
    }

    function removeAdminList(address _removeWhiteListed) public onlyOwner {
        whiteListedMap[_removeWhiteListed] = false;
    }

    modifier onlyAdmin() {
        require(
            adminListedMap[msg.sender] == true,
            "Admin: caller is not an Admin"
        );
        _;
    }

    // When a client makes the purchase of the IB tokens, he allows to the burner to transfer all the
    // IB tokens to the zero address (burn) when the end of life is reached and the
    modifier onlyBurner() {
        require(msg.sender == burner, "Burner: caller is not the burner");
        _;
    }

    modifier onlyWhitelisted() {
        require(
            whiteListedMap[msg.sender] == true,
            "WhiteList: caller is not in the Whitelist"
        );
        _;
    }

    function sendUSDT(address _to, uint256 _amount) private onlyAdmin {
        // transfers USDT that belong to your contract to the specified address
        usdt.transfer(_to, _amount);
    }

    function sendUSDTFrom(
        address _from,
        address _to,
        uint256 _amount
    ) private onlyAdmin {
        // transferFrom USDT
        usdt.transferFrom(_from, _to, _amount);
    }

    function checkUSDTContract(address _account)
        private
        view
        onlyAdmin
        onlyOwner
        returns (uint256)
    {
        // checks USDT balance
        uint256 usdtBalance = usdt.balanceOf(_account);
        return (usdtBalance);
    }

    function buyIBTokensInitial(uint256 _USDT)
        public
        onlyWhitelisted
        onlyAdmin
        onlyOwner
    {
        // We send the desired amount to the SC
        sendUSDT(address(this), _USDT);

        // The SC sends the IB tokens. We have to be careful with the divisions. Maybe we have a problem with gas? Gas have to be consumed in matic so maybe not.
        emit Transfer(address(0), msg.sender, (_USDT / initialPriceUSD));
    }

    function getFundsSmartContract(uint256 _USDT) public onlyOwner {
        require(
            _USDT <= checkUSDTContract(address(this)),
            "There is not enough balance in the Smart Contract"
        );
        sendUSDTFrom(address(this), msg.sender, _USDT);
    }
}