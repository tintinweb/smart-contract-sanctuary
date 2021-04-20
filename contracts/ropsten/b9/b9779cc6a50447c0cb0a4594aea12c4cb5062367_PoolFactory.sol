/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return (a + m - 1) / m * m;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);

}
contract Pool {
    using SafeMath for uint256;
    
    /**Dynamic attributes set on deployment**/
    string public ContractName;
    uint256 public HardCap;
    uint256 public SoftCap;
    uint256 public MaxInvestment;
    uint256 public MinInvestment;
    address public ManagementAddress;
    address public DestinationAddress;
    address public TokenAddress;
    uint256 public OwnerBonus;
    mapping(address => bool) public Whitelisted;
    address[5] public whitelistedArr;
    uint256 public StartDate;
    uint256 public EndDate;
    enum SupportedPayments{ETH, USDT, USDC}
    address public InvestmentToken; // this would be marked address(0) if ether is supported
    uint256 public Status = 1;
    struct Investor{
        uint256 investment;
        bool claimed;
    }
    mapping (address => Investor) investors;
    uint256 public totalInvestments;
    uint256 public totalTokensReceived;
    uint256 public totalClaimed;
    uint256 private OwnerTokens;
    uint256 private tokenPerInvestment;
    
    address private constant USDT = 0x254fbAAd7488d8856f392bb602aA6b8A8a043327;//0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    constructor(string memory _contractName, uint256 _hardCap, uint256 _softCap,
    uint256 _maxInvestment, uint256 _minInvestment, address _managementAddress,
    address _destinationAddress, address _tokenAddress, uint256 _ownerBonus,
    uint256 _startDate, uint256 _endDate, address[5] memory _whitelisted, 
    uint256 _token
    ) public{
        ContractName = _contractName;
        HardCap = _hardCap;
        SoftCap = _softCap;
        MaxInvestment = _maxInvestment;
        MinInvestment = _minInvestment;
        ManagementAddress = _managementAddress;
        DestinationAddress = _destinationAddress;
        TokenAddress = _tokenAddress;
        OwnerBonus = _ownerBonus;
        StartDate = _startDate;
        EndDate = _endDate;
        for(uint256 i = 0; i < _whitelisted.length; i++){
            Whitelisted[_whitelisted[i]] = true;
            whitelistedArr[i] = _whitelisted[i];
        }
        
        if(SupportedPayments(_token) == SupportedPayments.ETH)
            InvestmentToken = address(0);
        else if(SupportedPayments(_token) == SupportedPayments.USDT)
            InvestmentToken = USDT;
        else if(SupportedPayments(_token) == SupportedPayments.USDC)
            InvestmentToken = USDC;
        
    }
    
    receive() external payable{
        if(InvestmentToken == address(0))
            _contribute(msg.value); // Eths will get inside the contract
        else
            revert();
    }
    
    function Contribute(uint256 _amount) external payable{
        require(IERC20(InvestmentToken).transferFrom(msg.sender, address(this), _amount), "Failed transfer"); // supported token will get inside the contract
        _contribute(_amount);
    }
    
    // Get contributions from whitelisted addresses 
    function _contribute(uint256 _amount) private onlyWhitelisted investmentOpen{
        require(investors[msg.sender].investment.add(_amount) >= MinInvestment, "investment lowered than min allowed");
        require(investors[msg.sender].investment.add(_amount) <= MaxInvestment, "investment exceeds the max allowed");
        require(totalInvestments.add(_amount) <= HardCap, "Hard cap is reached");
        
        totalInvestments = totalInvestments.add(_amount);
        investors[msg.sender].investment = investors[msg.sender].investment.add(_amount);
    }
    
    // pool manager will initiate this function to send investments to the project
    // tokens will be returned back from the project
    function SendFundsToProject() external onlyManagement softCapReached{
        if(InvestmentToken == address(0))
            payable(DestinationAddress).transfer(totalInvestments);
        else
            IERC20(InvestmentToken).transfer(DestinationAddress, totalInvestments);
        Status = 2;
    }
    
    function GetTokens() external softCapReached{
        require(investors[msg.sender].investment > 0 || msg.sender == ManagementAddress, "Not allowed");
        
        if(tokenPerInvestment == 0){
            totalTokensReceived = IERC20(TokenAddress).balanceOf(address(this));
            require(totalTokensReceived > 0, "Tokens not received");
            OwnerTokens = onePercent(totalTokensReceived).mul(OwnerBonus); // add owner's tokens
            tokenPerInvestment = totalTokensReceived.div(totalInvestments);
        }
        
        require(!investors[msg.sender].claimed, "Already Claimed");
        
        uint256 tokens;
        if(msg.sender == ManagementAddress)
            tokens = OwnerTokens;
        else
            tokens = tokenPerInvestment.mul(investors[msg.sender].investment);
        
        investors[msg.sender].claimed = true;
        IERC20(TokenAddress).transfer(msg.sender, tokens);
        Status = 3;
    }
    
    function Refund() external softCapNotReached{
        require(investors[msg.sender].investment > 0, "Not allowed");
        if(InvestmentToken == address(0))
            msg.sender.transfer(investors[msg.sender].investment);
        else
            IERC20(InvestmentToken).transfer(ManagementAddress, investors[msg.sender].investment);
        investors[msg.sender].investment = 0;
        Status = 4;
    }
    
    function CheckStatus() external view returns (uint256 status){
        if(block.timestamp >= StartDate && block.timestamp <= EndDate)
            return 1;
        else if(block.timestamp > EndDate && totalInvestments < SoftCap)
            return 4;
        else if(block.timestamp > EndDate && IERC20(TokenAddress).balanceOf(address(this)) == 0 && address(this).balance > 0) // tokens not added yet, funds also not sent yet
            return 2;
        else if(block.timestamp > EndDate && IERC20(TokenAddress).balanceOf(address(this)) == 0 && address(this).balance == 0) // tokens not added yet, funds sent to destination
            return 5;
        else if(block.timestamp > EndDate && IERC20(TokenAddress).balanceOf(address(this)) > 0) // tokens are sent by destination
            return 3;
        else 
            return Status;
        
    }
    
    modifier onlyWhitelisted(){
        require(Whitelisted[msg.sender], "UnAuthorized");
        _;
    }
    
    modifier investmentOpen(){
        require(block.timestamp > StartDate && block.timestamp <= EndDate, "Investment is close");
        _;
    }
    
    modifier onlyManagement(){
        require(msg.sender == ManagementAddress, "UnAuthorized");
        _;
    }
    
    modifier softCapNotReached(){
        require(block.timestamp >= EndDate, "Sale not ended");
        require(totalInvestments < SoftCap, "SoftCap is reached");
        _;
    }
    
    modifier softCapReached(){
        require(block.timestamp >= EndDate, "Sale not ended");
        require(totalInvestments >= SoftCap, "SoftCap not reached");
        _;
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid account address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract PoolFactory is Owned {
    using SafeMath for uint256;
    struct PoolInfo{
        uint256 poolId;
        string poolName;
        address poolAddress;
    }
    mapping(uint256 => PoolInfo) public pools; // public, list, get a child address at row #
    uint public totalPools;
    event PoolCreated(address child, uint poolId); // maybe listen for events

    function CreatePool (string memory _contractName, uint256 _hardCap, uint256 _softCap,
        uint256 _maxInvestment, uint256 _minInvestment, address _managementAddress,
        address _destinationAddress, address _tokenAddress, uint256 _ownerBonus,
        uint256 _startDate, uint256 _endDate, address[5] memory _whitelisted, 
        uint256 _token
    ) external onlyOwner{
        totalPools = totalPools.add(1);
        Pool child = new Pool(_contractName, _hardCap, _softCap, _maxInvestment, 
        _minInvestment, _managementAddress, _destinationAddress,_tokenAddress, 
        _ownerBonus, _startDate, _endDate, _whitelisted, _token);
        
        pools[totalPools].poolId = totalPools;
        pools[totalPools].poolName = _contractName;
        pools[totalPools].poolAddress = address(child);
        
        emit PoolCreated(address(child), totalPools); // emit an event - another way to monitor this
    }
}