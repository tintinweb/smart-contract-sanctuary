/**
 *Submitted for verification at snowtrace.io on 2021-12-17
*/

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BlizzardFinancialPresale {

    address public _owner;

    address public _inputToken;

    bool public _investingEnabled = false;

    uint8 _raiseIndex;

    mapping (address => bool) private _whitelistAddresses;

    uint256 public round = 0;

    mapping(address => bool) public _existingUser;
    mapping(address => uint256) public _userInvested;
    address[] public _investors;

    uint256 public _minInvestment = 500 * 10**18;
    uint256 public _maxInvestment = 1000 * 10**18;


    uint256 public _raiseTarget = 250000 * 10**18;


    uint256 public receivedFund;


    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    constructor() {
        _owner = msg.sender;
        _inputToken = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    }


    function Investing(uint256 _amount) public {
        
        require(_investingEnabled == true, "Raise is not in progress");

        if (round == 0) {
            bool iswhitelisted = checkWhitelist(msg.sender);
            require(iswhitelisted == true, "Not whitelisted address");
        }


        require(
            _raiseTarget >= receivedFund + _amount,
            "Target Achieved. Investment not accepted"
        );


        require(_amount > 0, "min Investment not zero");

        uint256 checkamount = _userInvested[msg.sender] + _amount;

        require(
            checkamount <= _maxInvestment,
            "Investment not in allowed range"
        );

        if (_existingUser[msg.sender] == false) {
            _existingUser[msg.sender] = true;
            _investors.push(msg.sender);
        }

        _userInvested[msg.sender] += _amount;
        receivedFund = receivedFund + _amount;

        IERC20(_inputToken).transferFrom(msg.sender, address(this), _amount);
    }

    function remainingContribution(address owner) public view returns (uint256) {
        uint256 remaining = _maxInvestment - _userInvested[owner];
        return remaining;
    }

    function checkRaiseAmount() public view returns (uint256 _balance) {

        return IERC20(_inputToken).balanceOf(address(this));
    }

    function withdrawinputToken(address _admin) public onlyOwner {
        uint256 raisedAmount = IERC20(_inputToken).balanceOf(address(this));
        IERC20(_inputToken).transfer(_admin, raisedAmount);
    }

    function startRaise() external onlyOwner {
        require(_raiseIndex == 0, "Cannot restart raise");
        _investingEnabled = true;
        _raiseIndex = _raiseIndex + 1;
    }

    function changeMaxInvestment(uint256 limit) public onlyOwner {
        _maxInvestment = limit;
    }

    function changeMinInvestment(uint256 limit) public onlyOwner {
        _minInvestment = limit;
    }

    function startWhitelistingRound() public onlyOwner {
        round = 0;
    }

    function startNormalRound() public onlyOwner {
        round = 1;
    }

    function addWhitelist(address[] memory whitelistAddresses) public onlyOwner {
        for (uint i = 0; i < whitelistAddresses.length; i++) {
            _whitelistAddresses[whitelistAddresses[i]] = true;
        }
    }

    function removeWhitelist(address notWhitelistAddress) public onlyOwner {
        _whitelistAddresses[notWhitelistAddress] = false;
    }

    function checkWhitelist(address user) public view returns (bool) {
        return _whitelistAddresses[user];
    }

    function initializeRaise( address inputToken, uint256 minInvestment, uint256 maxinvestment, uint256 raiseTarget) public onlyOwner {
        
        require(raiseTarget > maxinvestment, "Incorrect max investment value");

        _inputToken = inputToken;
        _raiseTarget = raiseTarget;
        _maxInvestment = maxinvestment;
        _minInvestment = minInvestment;
    }
}