/**
 * @author https://github.com/Dmitx
 */

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @title ViviCoinDistributor
 * @dev Distributor of ViviCoin Tokens.
 */
contract ViviCoinDistributor is Pausable {
    using SafeMath for uint256;


    // ** PUBLIC STATE VARIABLES **

    // ViviCoin token
    IERC20 public viviCoin;


    // ** PRIVATE STATE VARIABLES **

    // Fee in wei for token distribution
    uint256 private _fee;

    // Token balances of investors
    mapping(address => uint256) private _tokenBalances;


    // ** CONSTRUCTOR **

    /**
    * @dev Constructor of ViviCoinDistributor Contract
    *
    * @param tokenAddress address of ViviCoin
    * @param fee payment in wei for distribution
    */
    constructor(
        address tokenAddress,
        uint256 fee
    )
        public
    {
        _setToken(tokenAddress);
        _fee = fee;
    }


    // ** ONLY OWNER FUNCTIONS **

    // Set the address of ViviCoin Token
    function setToken(address tokenAddress)
        external
        onlyOwner
    {
        _setToken(tokenAddress);
    }

    // Set Fee in wei for token distribution
    function setFee(uint256 newFee)
        external
        onlyOwner
    {
        _fee = newFee;
    }

    // Transfer tokens to owner
    function getTokensBack(uint256 amount)
        external
        onlyOwner
    {
        require(amount <= totalTokensOfThisContract(), "not enough tokens on this contract");
        require(viviCoin.transfer(owner, amount), "tokens are not transferred");
    }

    /**
    * @dev Withdrawal eth from contract to owner address
    */
    function withdrawEth()
        external
        onlyOwner
    {
        // withdrawal all eth from contract to owner address
        _forwardFunds(owner, address(this).balance);
    }

    /**
    * @dev Increase tokens balance of beneficiary
    * @param beneficiary The address for tokens withdrawal
    * @param amount The token amount for increase
    */
    function increaseBeneficiaryBalance(
        address beneficiary,
        uint256 amount
    )
        external
        onlyOwner
    {
        _increaseBalance(beneficiary, amount);
    }

    /**
    * @dev Increase tokens the balance of the array of beneficiaries
    * @param beneficiaries The array of addresses for tokens withdrawal
    * @param amounts The array of tokens amount for increase
    */
    function increaseArrayOfBeneficiariesBalances(
        address[] beneficiaries,
        uint256[] amounts
    )
        external
        onlyOwner
    {
        require(beneficiaries.length == amounts.length, "array lengths have to be equal");
        require(beneficiaries.length > 0, "array lengths have to be greater than zero");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _increaseBalance(beneficiaries[i], amounts[i]);
        }
    }

    /**
    * @dev Decrease tokens balance of beneficiary
    * @param beneficiary The address for tokens withdrawal
    * @param amount The token amount for decrease
    */
    function decreaseBeneficiaryBalance(
        address beneficiary,
        uint256 amount
    )
        external
        onlyOwner
    {
        _decreaseBalance(beneficiary, amount);
    }

    /**
    * @dev Decrease tokens the balance of the array of beneficiaries
    * @param beneficiaries The array of addresses for tokens withdrawal
    * @param amounts The array of tokens amount for decrease
    */
    function decreaseArrayOfBeneficiariesBalances(
        address[] beneficiaries,
        uint256[] amounts
    )
        external
        onlyOwner
    {
        require(beneficiaries.length == amounts.length, "array lengths have to be equal");
        require(beneficiaries.length > 0, "array lengths have to be greater than zero");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _decreaseBalance(beneficiaries[i], amounts[i]);
        }
    }


    // ** EXTERNAL FUNCTIONS **

    // Withdrawal tokens from this contract
    // Available when the contract is not paused
    function withdrawTokens()
        external
        payable
        whenNotPaused
    {
        // fee check
        require(msg.value >= _fee, "insufficient funds for withdrawal fee");

        uint256 amount = _tokenBalances[msg.sender];
        require(amount > 0, "no tokens for withdrawal");

        // update state
        _tokenBalances[msg.sender] = 0;

        require(viviCoin.transfer(msg.sender, amount), "tokens are not transferred");
    }


    // ** PUBLIC VIEW FUNCTIONS **

    /**
    * @return total tokens of this contract.
    */
    function totalTokensOfThisContract()
        public
        view
        returns(uint256)
    {
        return viviCoin.balanceOf(this);
    }

    /**
    * @dev Gets the token balance of the specified address
    * @param beneficiary The address to query the balance of
    * @return An uint256 representing the amount owned by the passed address
    */
    function tokenBalanceOf(address beneficiary)
        public
        view
        returns (uint256)
    {
        return _tokenBalances[beneficiary];
    }

    /**
    * @return actual Fee for token distribution.
    */
    function getActualFee()
        public
        view
        returns(uint256)
    {
        return _fee;
    }


    // ** PRIVATE HELPER FUNCTIONS **

    // Helper: Set the address of ViviCoin Token
    function _setToken(address tokenAddress)
        internal
    {
        viviCoin = IERC20(tokenAddress);
        require(totalTokensOfThisContract() >= 0, "The token being added is not ERC20 token");
    }

    // Helper: Send weis to the wallet
    function _forwardFunds(
        address wallet,
        uint256 amount
    )
        internal
    {
        wallet.transfer(amount);
    }

    // Helper: increase balance of beneficiary
    function _increaseBalance(
        address beneficiary,
        uint256 amount
    )
        internal
    {
        require(beneficiary != address(0), "Address cannot be 0x0");
        require(amount > 0, "Amount cannot be zero");

         // update state
        _tokenBalances[beneficiary] = _tokenBalances[beneficiary].add(amount);
    }

    // Helper: decrease balance of beneficiary
    function _decreaseBalance(
        address beneficiary,
        uint256 amount
    )
        internal
    {
        require(beneficiary != address(0), "Address cannot be 0x0");
        require(amount > 0, "Amount cannot be zero");

         // update state
        _tokenBalances[beneficiary] = _tokenBalances[beneficiary].sub(amount);
    }
}