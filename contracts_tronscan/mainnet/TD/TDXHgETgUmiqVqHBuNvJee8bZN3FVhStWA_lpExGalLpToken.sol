//SourceUnit: galexc.sol

pragma solidity ^0.5.8;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function mint(address account, uint amount) external;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract lpExGalLpToken{
    using SafeMath for *;
    
    address public _Owner;
    
    IERC20 public gal_TrxLp;
    IERC20 public galLp;
    
    
    
    uint256 internal _totalGal_TrxLp;
    mapping(address => uint256) private _balances;
    mapping(address => bool) public _withdrawWhiteList;
    bool public _withdrawFlage;
    
    constructor(IERC20 g_tLp,IERC20 glp) public{
        gal_TrxLp = g_tLp;
        galLp = glp;
        _Owner = msg.sender;
        
    }
    
    function Exchange(uint256 amount) public{
        require(gal_TrxLp.allowance(msg.sender,address(this))>=amount,"not eng allowance");
        gal_TrxLp.transferFrom(msg.sender,address(this),amount);
        galLp.mint(msg.sender,amount);
        _totalGal_TrxLp = _totalGal_TrxLp.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }
    
    
    function withdraw(uint256 amount) public{
        require(_balances[msg.sender]>=amount,"not eng balance");
        if(!_withdrawFlage){
            require(_withdrawWhiteList[msg.sender],"not within white list");
        }
        _totalGal_TrxLp = _totalGal_TrxLp.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        gal_TrxLp.transfer(msg.sender,amount);
        
    }
    
    function setWhiteList(address account,bool isAdd) public{
        require(msg.sender == _Owner,"not owner");
        _withdrawWhiteList[account] = isAdd;
    }
    
    function setWhiteFlage(bool isOpen) public{
        require(msg.sender == _Owner,"not owner");
        _withdrawFlage = isOpen;
    }
    
    function withTRC20(address tokenAddr, address recipient,uint256 amount) public {
        require(msg.sender == _Owner,"not owner");
        require(tokenAddr != address(0),"DPAddr: tokenAddr is zero");
        require(recipient != address(0),"DPAddr: recipient is zero");
        IERC20  tkCoin = IERC20(tokenAddr);
        if(tkCoin.balanceOf(address(this)) >= amount){
            tkCoin.transfer(recipient,amount);
        }else{
            tkCoin.transfer(recipient,tkCoin.balanceOf(address(this))) ;
        }
    }
    function withdrawLp(address recipient,uint256 amount) public {
        require(msg.sender == _Owner,"not owner");
        require(_totalGal_TrxLp >= amount,"not enght galTRX LP");
        gal_TrxLp.transfer(recipient,amount);
        _totalGal_TrxLp = _totalGal_TrxLp.sub(amount);
    }

    function totalSupply() view public returns(uint256){
        return _totalGal_TrxLp;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
}