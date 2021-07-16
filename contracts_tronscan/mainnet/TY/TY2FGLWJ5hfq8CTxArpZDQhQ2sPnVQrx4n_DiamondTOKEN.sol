//SourceUnit: dmdt.sol

pragma solidity ^0.5.8;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call.value(amount)("");
        require(success);
    }
}

contract Ownable {
    using Address for address;
    address payable public Owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(Owner, _newOwner);
        Owner = _newOwner.toPayable();
    }
}

interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    // function mint(address owner, uint value) external returns(bool);
    // function burn(uint value) external returns(bool);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint amount, address token, bytes calldata extraData) external;
}

contract TRC20 is ITRC20, Ownable {
    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "insufficient allowance!");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function burn(uint amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    
    // approveAndCall
    function approveAndCall(address spender, uint amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        require(_balances[sender] >= amount, "insufficient balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint amount) internal {
        require(account != address(0));
        require(_balances[account] >= amount, "insufficient balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract TRC20Detailed is ITRC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeTRC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract());

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)));
        }
    }
}

contract DiamondTOKEN is TRC20Detailed, TRC20 {
    using SafeTRC20 for ITRC20;
    using Address for address;
    using SafeMath for uint;
    
    uint internal BURN_PERCENT = 50;
    
    uint public decimalVal = 1e18;
    
    uint internal FOMO_LEVEL1_PERCENT = 10;
    uint internal FOMO_LEVEL2_PERCENT = 2;
    uint internal FOMO_MAX_USER = 10;
    uint internal fomoRewardOpenInterval = 30 * 60; // 1800s, 30 minute
    
    uint public fomoIdx;
    uint public fomoUserCnt;
    uint public fomoTS;
    mapping (uint => address) public fomoUserList;
    uint public fomoAmountLimit = 1 * decimalVal;
    uint internal fomoIncAmount = 1 * decimalVal;
    uint internal fomoMinTransferAmount = 1 * decimalVal;
    uint internal fomoMaxTransferAmount = 20 * decimalVal;
    
    uint public FomoRewardPool;
    
    bool public burnFlag;
    bool public mineFlag;
    bool public fomoFlag;
    address public mineCtxAddr;
    
    constructor () public TRC20Detailed("Diamond TOKEN", "DMDT", 18) {
        _mint(msg.sender, 30000*decimalVal);
    }
    
    function setMineCtx(address addr) public onlyOwner {
        require(address(0) != addr);
        mineCtxAddr = addr;
    }
    
    function setMineFlag(bool flag) public onlyOwner {
        mineFlag = flag;
        if (mineFlag) {
            require(address(0) != mineCtxAddr, "invalid mine contract address");
        }
    }
    
    function setFomoFlag(bool flag) public onlyOwner {
        fomoFlag = flag;
    }
    
    function setBurnFlag(bool flag) public onlyOwner {
        burnFlag = flag;
    }
    
    function getBurnRate() public view returns(uint) {
        if (burnFlag == false) {
            return 0;
        }
        uint burnRate = 6;
        if (_totalSupply > 20000 * decimalVal) {
            burnRate = 6;
        } else if (_totalSupply > 10000 * decimalVal) {
            burnRate = 5;
        } else {
            burnRate = 1;
        }
        return burnRate;
    }
    
    function _transferBurn(address from, uint amount) internal {
        require(from != address(0));

        // burn
        uint burnAmount = amount.mul(BURN_PERCENT).div(100);
        _burn(from, burnAmount);
        
        // fomo reward pool
        uint burnLeft = amount.sub(burnAmount);
        super._transfer(from, address(this), burnLeft);
        
        FomoRewardPool = FomoRewardPool.add(burnLeft);
    }
    
    function cleanFomoPool() internal {
        if (FomoRewardPool == 0) {
            return;
        }
        
        if (address(0) != mineCtxAddr) {
            super._transfer(address(this), mineCtxAddr, FomoRewardPool);
        } else {
            super._transfer(address(this), Owner, FomoRewardPool);
        }
        FomoRewardPool = 0;
    }
    
    function sendFomoReward(uint startIdx) internal {
        if (fomoUserCnt > FOMO_MAX_USER) {
            fomoUserCnt = FOMO_MAX_USER;
        }
        
        uint topReward = FomoRewardPool.mul(FOMO_LEVEL1_PERCENT).div(100);
        uint normalReward = FomoRewardPool.mul(FOMO_LEVEL2_PERCENT).div(100);
        
        // send top reward
        if (topReward > 0) {
            super._transfer(address(this), fomoUserList[startIdx], topReward); // do not burn
            fomoUserCnt = fomoUserCnt.sub(1);
            FomoRewardPool = FomoRewardPool.sub(topReward);
        }
        
        // send normal reward
        if (normalReward > 0) {
            for (uint idx = startIdx; fomoUserCnt > 0; fomoUserCnt--) {
                idx = idx.sub(1);
                if (0 == idx) {
                    idx = FOMO_MAX_USER;
                }
                super._transfer(address(this), fomoUserList[idx], normalReward);
                FomoRewardPool = FomoRewardPool.sub(normalReward);
            }
        }
        
        // clean fomo reward pool
        cleanFomoPool();
        
        // clean idx
        fomoIdx = 0;
        fomoUserCnt = 0;
        fomoTS = block.timestamp;
        fomoAmountLimit = fomoMinTransferAmount;
    }
    
    function checkFomoSendReward() internal view returns (bool) {
        if (fomoTS > 0 && block.timestamp.sub(fomoTS) > fomoRewardOpenInterval) {
            return true;
        }
        return false;
    }

    function fomoLogic(address to, uint amount) internal {
        if (fomoFlag == false) {
            return;
        }
        
        if (to.isContract()) {
            return;
        }
        
        if (amount < fomoAmountLimit) {
            return;
        }
        
        // fomo logic
        uint newFomoIdx = fomoIdx.add(1);
        if (newFomoIdx > FOMO_MAX_USER) {
            newFomoIdx = 1;
        }
        fomoUserList[newFomoIdx] = to;
        fomoUserCnt = fomoUserCnt.add(1);
        
        // check reward
        if (checkFomoSendReward()) {
            sendFomoReward(newFomoIdx);
            return;
        }

        // record fomo info, increase fomo amount limit
        fomoIdx = newFomoIdx;
        fomoTS = block.timestamp;
        if (fomoAmountLimit.add(fomoIncAmount) <= fomoMaxTransferAmount) {
            fomoAmountLimit = fomoAmountLimit.add(fomoIncAmount);
        } else {
            fomoAmountLimit = fomoMaxTransferAmount;
        }
    }
    
    function burn(uint amount) public returns (bool) {
        super._burn(msg.sender, amount);
    }
    
    function transfer(address to, uint value) public returns (bool) {
        uint burnRate = getBurnRate();
        uint transferAmount = value;
        
        if (burnRate > 0) {
            uint burnAmount = value.mul(burnRate).div(100);
            transferAmount = value.sub(burnAmount);
    
            _transferBurn(msg.sender, burnAmount);
        }

        super.transfer(to, transferAmount);
        
        fomoLogic(to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        uint burnRate = getBurnRate();
        uint transferAmount = value;
        
        if (burnRate > 0) {
            uint burnAmount = value.mul(burnRate).div(100);
            transferAmount = value.sub(burnAmount);
    
            _transferBurn(from, burnAmount);
        }

        super._transfer(from, to, transferAmount);
        super._approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
        
        fomoLogic(to, value);
        return true;
    }
    
    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(address(this).balance >= amount, "insufficient balance");

        to.transfer(amount);
    }

    function rescue(address to, ITRC20 token, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(token.balanceOf(address(this)) >= amount, "insufficent token balance");
        
        token.transfer(to, amount);
    }
}