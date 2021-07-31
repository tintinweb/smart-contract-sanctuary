/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

pragma solidity ^0.5.0;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IMCS {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint (address to, uint256 quantity) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract Governance is Context{
    address internal _governance;
    mapping (address => bool) private _isRelayer;
    mapping (address => uint256) internal _supplyByRelayer;
    mapping (address => uint256) internal _burnByAddress;
    
    event GovernanceChanged(address oldGovernance, address newGovernance);
    event RelayerAdmitted(address target);
    event RelayerExpelled(address target);
    
    modifier GovernanceOnly () {
        require (_msgSender() == _governance, "Only Governance can do");
        _;
    }
    
    modifier RelayerOnly () {
        require (_isRelayer[_msgSender()], "Only Relayer can do");
        _;
    }
    
    function governance () external view returns (address) {
        return _governance;
    }
    
    function isRelayer (address target) external view returns (bool) {
        return _isRelayer[target];
    }
    
    function admitRelayer (address target) external GovernanceOnly {
        require (!_isRelayer[target], "Target is relayer already");
        _isRelayer[target] = true;
        emit RelayerAdmitted(target);
    }
    
    function expelRelayer (address target) external GovernanceOnly {
        require (_isRelayer[target], "Target is not relayer");
        _isRelayer[target] = false;
        emit RelayerExpelled(target);
    }
    
    function succeedGovernance (address newGovernance) external GovernanceOnly {
        _governance = newGovernance;
        emit GovernanceChanged(_msgSender(), newGovernance);
    }
}

contract Bridge is Governance {
    using SafeMath for uint256;
    address public TOKEN_ADDRESS;
    
    event Deposit(address indexed sender, uint256 quantity, uint256 targetChain, address indexed receiverAddress);
    event Release(address indexed receiver, uint256 quantity, uint256 originChain, address indexed senderAddress);
    event MintToken(address relayer, uint256 mintQuantity, uint256 originBalance, uint256 relayDemand);
  
    constructor (address tokenAddress) public {
        TOKEN_ADDRESS = tokenAddress;
        _governance = _msgSender();
    }

    function depositToken (uint256 quantity, uint256 targetChain, address receiverAddress) public {
        IMCS tokenObj = IMCS(TOKEN_ADDRESS);
        
        uint256 balanceBefore = tokenObj.balanceOf(address(this));
        tokenObj.transferFrom(_msgSender(), address(this), quantity);
        uint256 balanceAfter = tokenObj.balanceOf(address(this));
        require(balanceBefore + quantity == balanceAfter, "Old token isnt arrived");
        
        emit Deposit(_msgSender(), quantity, targetChain, receiverAddress);
    }
    
    function releaseTokens (address[] memory to, uint256[] memory quantity, uint256[] memory originChain, address[] memory senderAddress) public RelayerOnly {
        uint256 totalDemand = 0;
        for(uint8 i=0; i < to.length; i++){
            totalDemand = totalDemand.add(quantity[i]);
        }
        
        IMCS tokenObj = IMCS(TOKEN_ADDRESS);
        uint256 tokenBalance = tokenObj.balanceOf(address(this));
        if(tokenBalance < totalDemand){
            uint256 mintQuantity = totalDemand - tokenBalance;
            tokenObj.mint(address(this), mintQuantity);
            emit MintToken(_msgSender(), mintQuantity, tokenBalance, totalDemand);
        }
        
        for(uint8 i=0; i < to.length; i++){
            tokenObj.transfer(to[i], quantity[i]);
            emit Release(to[i], quantity[i], originChain[i], senderAddress[i]);
        }
    }
}