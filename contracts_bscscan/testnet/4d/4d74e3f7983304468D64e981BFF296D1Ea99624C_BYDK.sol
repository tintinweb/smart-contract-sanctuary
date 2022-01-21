// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BYDK is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => Relation) private _relation;

    address[] private _holders;

    uint8 private decimal;
    uint256 private _totalSupply;
    uint256 private _modifyShareLimit;

    string private _name;
    string private _symbol;

    // 白名单地址
    address private _owner;  // 总地址
    address private _addrA;  // 预售地址
    address private _addrB;  // 技术地址
    address private _addrC;  // 风投地址
    address private _addrD;  // 空投地址
    address private _addrE;  // 社区地址
    address private _addrF;  // D池地址
    address private _addrG;  // 预售地址
    address private _addrH;  // 基金地址
    address private _addrI;  // 竞拍地址

    struct Relation {
        address first;  // 直推
        address second; // 间推
    }

    constructor(
        address owner_,
        address addrA_,
        address addrB_,
        address addrC_,
        address addrD_,
        address addrE_,
        address addrF_,
        address addrG_,
        address addrH_,
        address addrI_) {
        _owner = owner_;
        _name = "BY DK TOKEN";
        _symbol = "BYDK";
        decimal = 18;
        _totalSupply = 2000000000*10**decimal;
        _balances[owner_] = _totalSupply;
        _modifyShareLimit = 400000*10**decimal;
        _addrA = addrA_;
        _addrB = addrB_;
        _addrC = addrC_;
        _addrD = addrD_;
        _addrE = addrE_;
        _addrF = addrF_;
        _addrG = addrG_;
        _addrH = addrH_;
        _addrI = addrI_;
    }

    function name() public view virtual  returns (string memory) {
        return _name;
    }

    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual  returns (uint8) {
        return decimal;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function modifyShareLimit(uint256 limit) external {
        require(msg.sender == _owner, "ERC20: No permission");
        _modifyShareLimit = limit*10**decimal;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (senderBalance == amount) {
            amount -= 10;
        }
        _balances[sender] = senderBalance.sub(amount);

        if (
            sender != _owner &&
            sender != _addrA &&
            sender != _addrB &&
            sender != _addrC &&
            sender != _addrD &&
            sender != _addrE &&
            sender != _addrF &&
            sender != _addrG &&
            sender != _addrH &&
            sender != _addrI
        ){
           if (_relation[recipient].first == address(0) && _balances[recipient] <= 0){
                _relation[recipient].first = sender;
                _relation[recipient].second = _relation[sender].first;
            }
            uint256 directPushFree = amount.div(50);        // 直推 2%
            uint256 indirectPushFree = amount.div(100);     // 间推 1%
            uint256 blackHoleFree = amount.mul(3).div(100); // 黑洞 3%
            uint256 shareFree = amount.div(50);             // 持币分红 2%
            uint256 fundFree = amount.div(25);              // 基金地址 4%
            uint256 biddingFree = amount.mul(3).div(100);   // 竞拍地址 3%
            
            _balances[_addrH] = fundFree;
            _balances[_addrI] = biddingFree;

            uint256 holdersTotal;
            for(uint i = 0; i < _holders.length; i++){
                if (_balances[_holders[i]] <= 0){
                    delete _holders[i];
                }
                holdersTotal += _balances[_holders[i]];
            }

            if (_balances[recipient] <= 0) {
                _holders.push(recipient);
            }
            _balances[recipient] = _balances[recipient].add(amount).sub(directPushFree + indirectPushFree + blackHoleFree + shareFree + fundFree + biddingFree);
            _totalSupply = _totalSupply.sub(blackHoleFree);
            
            address first = _relation[sender].first;
            address second = _relation[sender].second;

            if (first != address(0)){
                _balances[first] = _balances[first].add(directPushFree);
            }
            if (second != address(0)){
                _balances[second] = _balances[second].add(indirectPushFree);
            }
            
            if (second == address(0)){
                _totalSupply = _totalSupply.sub(indirectPushFree);
            } else if (first == address(0)){
                _totalSupply -= _totalSupply.add(directPushFree).add(indirectPushFree);
            }

            for(uint i = 0; i < _holders.length; i++){
                if (_balances[_holders[i]] < 400000*10**decimal){
                    continue;
                }
                _balances[_holders[i]] = _balances[_holders[i]].add(_balances[_holders[i]].div(holdersTotal).mul(shareFree));
            }
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
        }
        
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}