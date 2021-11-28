//SourceUnit: pnPledge.sol

pragma solidity 0.6.0;

library SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // require(a == b * c + a / b, "SafeMath: division overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b, "SafeMath: addition overflow");
        return c;
    }
}

interface TRC20Interface {
    
    function scale() external view returns (uint256 theNdwScale);
    
    function totalSupply() external view returns (uint256 theTotalSupply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

library SafeTRC20 {
    using SafeMath for uint256;
   
    
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        TRC20Interface token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        TRC20Interface token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        TRC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            SafeMath.safeAdd(token.allowance(address(this), spender), value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        TRC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            SafeMath.safeSub(token.allowance(address(this), spender), value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(TRC20Interface token, bytes memory data)
        private
    {
        //require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}


pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract pnPledge  is Ownable {
    using SafeMath for uint256;
    using SafeTRC20 for TRC20Interface;
    
    TRC20Interface private pnToken;
	TRC20Interface private ndwToken;
	
    address private team;
    
    address private _awardAddress;
    
    bool isPledge = true; 
    uint256 public size; 
    uint256 public totalPledgeAmount; 
    uint256 public totalProfixAmount; 
	uint256 public pledgeFee = 20;
	
    uint256 public pnScale = 50000;
    uint256 public minPledge = 12500000000;
    struct PledgeOrder {
        bool isExist; 
        uint256 token; 
		uint256 tokenValue;//token 价值 
    }
    
    mapping(address => PledgeOrder) public orders;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event Issure(uint256 _value);
    event pnPledge(address _user,uint256 _price, uint256 _value);
    event TakePN(address _user, uint256 _value,uint256 _tokenValue);


    constructor(
        address _team,
        address awardAddress,
        TRC20Interface pn,
		TRC20Interface ndw
    ) public {
        _awardAddress=awardAddress;
        team = _team;
        pnToken = pn;
		ndwToken = ndw;
    }
    
	function changePnToken(TRC20Interface pn) public onlyOwner {
          pnToken = pn;
    }
	function changeNdwToken(TRC20Interface ndw) public onlyOwner {
          ndwToken = ndw;
    }
    
    function changeAwardAddress(address awardAddress) public onlyOwner {
        _awardAddress = awardAddress;
    }

	function changeTeamAddress(address _teamAddress) public onlyOwner {
        team = _teamAddress;
    }
    
	
    function changeMinPledge(uint256 _minPledge) public onlyOwner {
        minPledge = _minPledge;
    }
    
    function createOrder(uint256 amount,uint256 tokenValue) private {
        orders[msg.sender] = PledgeOrder(
            true,
            amount,
			tokenValue
        );
    }
    
    function getNdwScale() public  view  returns (uint256) {
       return ndwToken.scale();
    }
	
	function changeScale(uint256 _scale) public onlyOwner {
        pnScale = _scale;
    }
   
    function pledge(uint256 amount) public {
        require(address(msg.sender) == address(tx.origin) && msg.sender != address(0x0),"invalid address");
        require(isPledge, "is disable");
		uint256 ndwScale = ndwToken.scale();
		uint256 pnPrice = ndwScale.safeMul(10**2).safeDiv(pnScale);
		uint256 pnvalue = amount.safeMul(pnPrice).safeDiv(10**2);
		require(pnvalue >= minPledge, "less pledge");
		uint256 fee = amount.safeMul(pledgeFee).safeDiv(100);
		uint256 realAmouunt = amount.safeSub(fee);
		uint256 realTokenValue = realAmouunt.safeMul(pnPrice).safeDiv(10**2);
        if (orders[msg.sender].isExist == false) {
            createOrder(realAmouunt,realTokenValue);
        } else {
            PledgeOrder storage order = orders[msg.sender];
            order.token = SafeMath.safeAdd(order.token, realAmouunt);
			order.tokenValue = SafeMath.safeAdd(order.tokenValue, realTokenValue);
        }
        pnToken.safeTransferFrom(msg.sender,address(this),amount);
        totalPledgeAmount = SafeMath.safeAdd(totalPledgeAmount, realAmouunt);
        totalProfixAmount = SafeMath.safeAdd(totalProfixAmount,fee);
        emit pnPledge(msg.sender,  pnPrice  , amount);
    }    
    function sharePN() public onlyOwner {
          require(totalProfixAmount > 0, "no pn gas");
          SafeTRC20.safeTransfer(address(pnToken),address(0x0),SafeMath.safeDiv(totalProfixAmount, 4));
          SafeTRC20.safeTransfer(address(pnToken), team, SafeMath.safeDiv(totalProfixAmount, 4));
          SafeTRC20.safeTransfer(address(pnToken), _awardAddress, SafeMath.safeDiv(totalProfixAmount, 2));
          totalProfixAmount = 0;
     }
     
    function takePN() public {
        require(address(msg.sender) == address(tx.origin) && msg.sender != address(0x0),"invalid address");
        PledgeOrder storage order = orders[msg.sender];
        require(order.token > 0, "no order");
		require(orders[msg.sender].isExist ,"no pn pledge");
		pnToken.transfer(msg.sender, order.token);
		totalPledgeAmount = SafeMath.safeSub(totalPledgeAmount, order.token);
		uint256 amount=order.token ;
		uint256 tokenAmount=order.tokenValue ;
		order.token = 0;
		order.tokenValue = 0;
		emit TakePN(msg.sender, amount,tokenAmount);
    }
}