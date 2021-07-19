//SourceUnit: RPA.sol

pragma solidity ^0.5.9;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Balances {
    function move(mapping(address => uint256) storage balances, address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        require(balances[to] + amount >= balances[to]);
        balances[from] -= amount;
        balances[to] += amount;
    }
}

contract RPA {
    
    /// @notice EIP-20 token name for this token
    string public constant name = "Robot Process Automation";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "RPA";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 6;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 1600000; // 1 billion RPA
    
    //address owner
    address payable public owner;
    
    uint public adminCommission;
    uint public commissionedPrice;
    
    //price of each token after caps
    uint public tokenPrice = 25 trx;
    
    address[] public referralAddresses;
    uint private commission = 6;
    
    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);


    constructor(address payable account) public {
        owner= account;
        referralAddresses.push(msg.sender);
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }
    
    modifier onlyadmin() {
        require(msg.sender == owner);
        _;
    }    

    function changeOwnership(address payable _newAdmin)public onlyadmin returns(address){
        owner = _newAdmin;
        return owner;
    }

    function setTokenPrice(uint _newPrice) public onlyadmin returns(uint){
        tokenPrice = _newPrice; 
        return tokenPrice;
    }
    
    function onlyReferral (address _refferalAddress) private view returns(bool){
      bool matchedAddress = false;
        for(uint i=0; i < referralAddresses.length; i++){
            if(_refferalAddress == referralAddresses[i]){
                matchedAddress = true;
            }
        }
        return matchedAddress;
    }
    
    function investmentUser(uint _tokenAmount, address payable refAddress) payable public{
        uint totalInvestmentAmount = SafeMath.mul(_tokenAmount, tokenPrice);
            _commissionedCalc(totalInvestmentAmount, refAddress);
    }


    function _commissionedCalc(uint _investmentAmount, address payable _refferalAddress) private{
    require(onlyReferral(_refferalAddress) == true, "User NOt FOund");
        commissionedPrice = SafeMath.mul(commission, _investmentAmount);
        commissionedPrice = SafeMath.div(commissionedPrice, 100);
        _refferalAddress.transfer(commissionedPrice);
        adminCommission = SafeMath.sub(_investmentAmount, commissionedPrice);
        owner.transfer(adminCommission);
        referralAddresses.push(msg.sender);        
    }

    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "RPA::approve: amount exceeds 96 bits");
        }
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }


    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "RPA::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }
    
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "RPA::approve: amount exceeds 96 bits");
        
        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "RPA::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }
        _transferTokens(src, dst, amount);
        return true;
    }
 
    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "RPA::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "RPA::_transferTokens: cannot transfer to the zero address");
        balances[src] = sub96(balances[src], amount, "RPA::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "RPA::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

}